"""Macros for composing the UDMF TEXTMAP, assembly, and ZDBSP pipeline."""

load("//doom/private:wad.bzl", "doom_pwad")
load("//doom/private:zdbsp_wad.bzl", "doom_zdbsp_wad")
load("//doom/private/udmf:compile.bzl", "doom_udmf_compile")

def doom_udmf_pwad(
        name,
        src,
        map_name = "MAP01",
        behavior = None,
        map_namespace_style = "mapxx",
        visibility = None,
        **kwargs):
    """Builds a Doom PWAD from a UDMF TEXTMAP source.

    map_namespace_style defaults to "mapxx" because this project's UDMF maps
    use MAP## naming. Override only when a concrete need exists.

    Args:
      name: Target name.
      src: UDMF TEXTMAP source file to compile.
      map_name: Map lump name to emit into the WAD.
      behavior: Optional BEHAVIOR lump input.
      map_namespace_style: Map naming style exposed by the final PWAD.
      visibility: Visibility to apply to the exported PWAD target.
      **kwargs: Additional arguments forwarded to `doom_pwad`.
    """
    raw_name = name + "_raw_wad_file"
    final_name = name + "_wad_file"

    doom_udmf_compile(
        name = raw_name,
        src = src,
        map_name = map_name,
        behavior = behavior,
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
