"""Rule for selecting a Bazel-managed Doom engine."""

load("//doom/private:constants.bzl", "START_MAP_STYLE_VALUES")
load("//doom/private:providers.bzl", "DoomEngineInfo")

def _doom_engine_impl(ctx):
    runner = ctx.executable.runner
    default_info = ctx.attr.runner[DefaultInfo]

    return [
        DefaultInfo(
            files = depset([runner]),
            runfiles = default_info.default_runfiles,
        ),
        DoomEngineInfo(
            runner = runner,
            start_map_style = ctx.attr.start_map_style,
        ),
    ]

doom_engine = rule(
    implementation = _doom_engine_impl,
    attrs = {
        "runner": attr.label(
            doc = "Selected engine executable.",
            mandatory = True,
            executable = True,
            cfg = "target",
            allow_single_file = True,
        ),
        "start_map_style": attr.string(
            doc = "How the engine accepts a logical start map.",
            mandatory = True,
            values = START_MAP_STYLE_VALUES,
        ),
    },
    doc = "Selects a Bazel-managed Doom engine executable and map-start style. Runtime assets must be provided by the runner target's runfiles.",
)
