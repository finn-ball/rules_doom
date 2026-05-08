"""Rule for exposing a Doom WAD file."""

load(
    "//doom/private:constants.bzl",
    "MAP_NAMESPACE_STYLE_UNKNOWN",
    "MAP_NAMESPACE_STYLE_VALUES",
)
load("//doom/private:providers.bzl", "DoomWadInfo")

def _doom_wad_impl(ctx):
    wad = ctx.file.wad

    return [
        DefaultInfo(
            files = depset([wad]),
            runfiles = ctx.runfiles(files = [wad]),
        ),
        DoomWadInfo(
            wad = wad,
            map_namespace_style = ctx.attr.map_namespace_style,
        ),
    ]

doom_wad = rule(
    implementation = _doom_wad_impl,
    attrs = {
        "wad": attr.label(
            doc = "A single .wad file.",
            mandatory = True,
            allow_single_file = [".wad", ".WAD"],
        ),
        "map_namespace_style": attr.string(
            doc = "Launch-time map naming style metadata for logical map resolution and validation.",
            default = MAP_NAMESPACE_STYLE_UNKNOWN,
            values = MAP_NAMESPACE_STYLE_VALUES,
        ),
    },
    doc = "Packages a single Doom WAD file for downstream use.",
)

def doom_iwad(name, wad, map_namespace_style = MAP_NAMESPACE_STYLE_UNKNOWN, **kwargs):
    """Packages a single IWAD file plus map naming metadata for launch semantics."""
    doom_wad(
        name = name,
        wad = wad,
        map_namespace_style = map_namespace_style,
        **kwargs
    )

def doom_pwad(name, wad, map_namespace_style = MAP_NAMESPACE_STYLE_UNKNOWN, **kwargs):
    """Packages a single PWAD file plus map naming metadata for launch semantics."""
    doom_wad(
        name = name,
        wad = wad,
        map_namespace_style = map_namespace_style,
        **kwargs
    )
