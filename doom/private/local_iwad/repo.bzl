"""Repository rule for exposing a user-owned local Doom IWAD."""

def _doom_local_iwad_repository_impl(repo_ctx):
    src = repo_ctx.path(repo_ctx.attr.path)
    filename = repo_ctx.attr.filename or src.basename

    if not src.exists:
        fail("doom_local_iwad_repository path does not exist: %s" % repo_ctx.attr.path)

    repo_ctx.symlink(src, filename)

    repo_ctx.file("BUILD.bazel", """
load("@rules_doom//doom:defs.bzl", "doom_iwad")

package(default_visibility = ["//visibility:public"])

exports_files(["{filename}"])

doom_iwad(
    name = "iwad",
    wad = "{filename}",
    map_namespace_style = "{map_namespace_style}",
)
""".format(
        filename = filename,
        map_namespace_style = repo_ctx.attr.map_namespace_style,
    ))

    repo_ctx.file("README.md", "This repository exposes a user-provided local IWAD. Do not commit proprietary IWADs.\n")

doom_local_iwad_repository = repository_rule(
    implementation = _doom_local_iwad_repository_impl,
    local = True,
    configure = True,
    attrs = {
        "path": attr.string(mandatory = True),
        "filename": attr.string(),
        "map_namespace_style": attr.string(
            default = "mapxx",
            values = ["unknown", "episode", "mapxx"],
        ),
    },
)
