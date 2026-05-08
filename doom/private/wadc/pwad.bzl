"""Macros for composing the WadC and ZDBSP pipeline."""

load("//doom/private:wad.bzl", "doom_pwad")
load("//doom/private:zdbsp_wad.bzl", "doom_zdbsp_wad")
load("//doom/private/wadc:compile.bzl", "doom_wadc_compile")

def doom_wadc_pwad(
        name,
        src,
        seed = 1337,
        no_source_lump = False,
        extra_args = None,
        map_namespace_style = "mapxx",
        visibility = None,
        **kwargs):
    """Builds a Doom PWAD from a WadC source file.

    Defaults to mapxx because the bundled WadC example and the normal Doom II
    workflow produce/play MAP01-style maps. Override for a known E#M# source.
    """
    extra_args = extra_args or []

    raw_name = name + "_raw_wad_file"
    final_name = name + "_wad_file"

    doom_wadc_compile(
        name = raw_name,
        src = src,
        seed = seed,
        no_source_lump = no_source_lump,
        extra_args = extra_args,
        visibility = ["//visibility:private"],
    )

    doom_zdbsp_wad(
        name = final_name,
        src = ":" + raw_name,
        visibility = ["//visibility:private"],
    )

    doom_pwad(
        name = name,
        wad = ":" + final_name,
        map_namespace_style = map_namespace_style,
        visibility = visibility,
        **kwargs
    )
