"""Executable rule for launching a Doom engine with a WAD.

`doom_launch` computes argv dynamically during rule analysis, so it uses the
low-level hermetic-launcher `launcher` struct (not `launcher_binary`).
Runtime display-backend policy and arbitrary env injection are intentionally
outside this Bazel API.
"""

load("@hermetic_launcher//launcher:lib.bzl", "launcher")
load(
    "//doom/private:constants.bzl",
    "MAP_NAMESPACE_STYLE_EPISODE",
    "MAP_NAMESPACE_STYLE_MAPXX",
    "MAP_NAMESPACE_STYLE_UNKNOWN",
    "START_MAP_STYLE_MAP",
    "START_MAP_STYLE_WARP",
    "START_MODE_DEFERRED",
    "START_MODE_IMMEDIATE",
    "START_MODE_MENU",
    "START_MODE_VALUES",
)
load("//doom/private:providers.bzl", "DoomEngineInfo", "DoomWadInfo")

_ARG_EXEC = "+exec"
_ARG_FILE = "-file"
_ARG_IWAD = "-iwad"
_ARG_MAP = "+map"
_ARG_WARP = "-warp"

_DEFAULT_EPISODE_START_MAP = "E1M1"
_DEFAULT_MAPXX_START_MAP = "MAP01"

_DEFAULT_START_MAPS = {
    MAP_NAMESPACE_STYLE_EPISODE: _DEFAULT_EPISODE_START_MAP,
    MAP_NAMESPACE_STYLE_MAPXX: _DEFAULT_MAPXX_START_MAP,
}

def _known_map_styles(iwad, pwads):
    styles = [pwad.map_namespace_style for pwad in pwads if pwad.map_namespace_style != MAP_NAMESPACE_STYLE_UNKNOWN]
    if styles:
        if iwad.map_namespace_style != MAP_NAMESPACE_STYLE_UNKNOWN:
            styles.append(iwad.map_namespace_style)
        return styles

    if iwad.map_namespace_style != MAP_NAMESPACE_STYLE_UNKNOWN:
        return [iwad.map_namespace_style]

    return []

def _select_map_style(iwad, pwads):
    styles = _known_map_styles(iwad, pwads)
    if not styles:
        return MAP_NAMESPACE_STYLE_UNKNOWN

    style = styles[0]
    for candidate in styles[1:]:
        if candidate != style:
            fail("doom_launch requires one map namespace style; got {}".format(styles))
    return style

def _default_start_map(style):
    if style in _DEFAULT_START_MAPS:
        return _DEFAULT_START_MAPS[style]
    fail("doom_launch cannot infer a default start_map without a known map namespace style")

def _resolve_start_map(start_mode, requested_start_map, iwad, pwads):
    if start_mode == START_MODE_MENU:
        if requested_start_map:
            fail("doom_launch does not allow start_map when start_mode = 'menu'")
        return None

    if requested_start_map:
        return requested_start_map.upper()

    if not requested_start_map and pwads:
        return _default_start_map(_select_map_style(iwad, pwads))

    return None

def _warp_args(start_map):
    # Translate canonical Doom map names into the engine's `-warp` CLI shape.
    if start_map.startswith("MAP"):
        return [_ARG_WARP, start_map[3:]]

    if len(start_map) == 4 and start_map[0] == "E" and start_map[2] == "M":
        return [_ARG_WARP, start_map[1], start_map[3]]

    return [_ARG_WARP, start_map]

def _start_map_args(start_map_style, start_map):
    if not start_map:
        return []

    if start_map_style == START_MAP_STYLE_MAP:
        return [_ARG_MAP, start_map]

    if start_map_style == START_MAP_STYLE_WARP:
        return _warp_args(start_map)

    fail("Unsupported start_map_style '{}'".format(start_map_style))

def _deferred_startup_cfg(start_map_style, start_map):
    if not start_map:
        return ""

    if start_map_style == START_MAP_STYLE_MAP:
        # Some UZDoom runs render a black first frame when autostarting directly
        # into gameplay via startup map handling. Deferring the map command by one
        # tick reproduces the working "boot to menu, then enter map" path.
        return "wait 1; map {}\n".format(start_map)

    fail("doom_launch start_mode = 'deferred' is not supported for start_map_style '{}'".format(start_map_style))

def _engine_args_and_startup_cfg(start_mode, engine, start_map, launch_args):
    if start_mode == START_MODE_IMMEDIATE:
        return _start_map_args(engine.start_map_style, start_map) + launch_args, None

    if start_mode == START_MODE_DEFERRED:
        if not start_map:
            fail("doom_launch start_mode = 'deferred' requires a start_map")
        return launch_args, _deferred_startup_cfg(engine.start_map_style, start_map)

    if start_mode == START_MODE_MENU:
        return launch_args, None

    fail("Unsupported start_mode '{}'".format(start_mode))

def _materialize_startup_cfg(ctx, startup_cfg_contents):
    # Deferred startup needs a real file because UZDoom consumes +exec <path>.
    if not startup_cfg_contents:
        return None
    startup_cfg = ctx.actions.declare_file(ctx.label.name + "_startup.cfg")
    ctx.actions.write(output = startup_cfg, content = startup_cfg_contents)
    return startup_cfg

def _append_arg(embedded_args, transformed_args, arg):
    return launcher.append_embedded_arg(
        arg = arg,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
    )

def _append_runfile(embedded_args, transformed_args, file):
    return launcher.append_runfile(
        file = file,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
    )

def _build_embedded_args(engine_runner, iwad_file, pwad_files, engine_args, startup_cfg):
    embedded_args, transformed_args = launcher.args_from_entrypoint(
        executable_file = engine_runner,
    )

    embedded_args, transformed_args = _append_arg(embedded_args, transformed_args, _ARG_IWAD)
    embedded_args, transformed_args = _append_runfile(embedded_args, transformed_args, iwad_file)

    if pwad_files:
        embedded_args, transformed_args = _append_arg(embedded_args, transformed_args, _ARG_FILE)
        for pwad_file in pwad_files:
            embedded_args, transformed_args = _append_runfile(embedded_args, transformed_args, pwad_file)

    for arg in engine_args:
        embedded_args, transformed_args = _append_arg(embedded_args, transformed_args, arg)

    if startup_cfg:
        embedded_args, transformed_args = _append_arg(embedded_args, transformed_args, _ARG_EXEC)
        embedded_args, transformed_args = _append_runfile(embedded_args, transformed_args, startup_cfg)

    return embedded_args, transformed_args

def _doom_launch_impl(ctx):
    engine = ctx.attr.engine[DoomEngineInfo]
    iwad = ctx.attr.iwad[DoomWadInfo]
    pwad_infos = [target[DoomWadInfo] for target in ctx.attr.pwads]

    start_map = _resolve_start_map(
        start_mode = ctx.attr.start_mode,
        requested_start_map = ctx.attr.start_map,
        iwad = iwad,
        pwads = pwad_infos,
    )
    engine_args, startup_cfg_contents = _engine_args_and_startup_cfg(
        start_mode = ctx.attr.start_mode,
        engine = engine,
        start_map = start_map,
        launch_args = ctx.attr.launch_args,
    )
    startup_cfg = _materialize_startup_cfg(ctx, startup_cfg_contents)

    pwad_files = [pwad.wad for pwad in pwad_infos]
    embedded_args, transformed_args = _build_embedded_args(
        engine_runner = engine.runner,
        iwad_file = iwad.wad,
        pwad_files = pwad_files,
        engine_args = engine_args,
        startup_cfg = startup_cfg,
    )

    executable = ctx.actions.declare_file(ctx.label.name)
    launcher.compile_stub(
        ctx = ctx,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
        output_file = executable,
    )

    launch_files = [engine.runner, iwad.wad] + pwad_files + ([startup_cfg] if startup_cfg else [])
    runfiles = ctx.runfiles(files = launch_files)
    runfiles = runfiles.merge(ctx.attr.engine[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr.iwad[DefaultInfo].default_runfiles)
    for pwad in ctx.attr.pwads:
        runfiles = runfiles.merge(pwad[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = executable,
            files = depset([executable]),
            runfiles = runfiles,
        ),
    ]

doom_launch = rule(
    implementation = _doom_launch_impl,
    executable = True,
    attrs = {
        "launch_args": attr.string_list(
            doc = "Extra arguments passed to the engine before user-supplied bazel run arguments.",
        ),
        "start_map": attr.string(
            doc = "Logical map name to start, translated according to engine launch semantics.",
        ),
        "start_mode": attr.string(
            doc = "How the launcher should enter gameplay: directly, via a deferred command, or at the menu.",
            default = START_MODE_IMMEDIATE,
            values = START_MODE_VALUES,
        ),
        "engine": attr.label(
            doc = "A doom_engine target.",
            default = "//doom/engine",
            providers = [DoomEngineInfo],
        ),
        "iwad": attr.label(
            doc = "A doom_iwad target used as the base game data.",
            default = "//doom/wads:iwad",
            providers = [DoomWadInfo],
        ),
        "pwads": attr.label_list(
            doc = "Optional Doom PWADs layered on top of the IWAD.",
            providers = [DoomWadInfo],
        ),
    },
    doc = "Launches a Doom engine with an IWAD and optional PWADs.",
    toolchains = [
        launcher.template_toolchain_type,
        launcher.finalizer_toolchain_type,
    ],
)
