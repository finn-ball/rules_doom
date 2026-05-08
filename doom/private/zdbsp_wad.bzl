"""Rule for finishing a Doom WAD with ZDBSP."""

def _doom_zdbsp_wad_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".wad")
    args = ctx.actions.args()
    args.add("-o", out.path)
    args.add(ctx.file.src.path)

    ctx.actions.run(
        executable = ctx.executable._tool,
        inputs = [ctx.file.src],
        outputs = [out],
        arguments = [args],
        mnemonic = "DoomZdbsp",
        progress_message = "Building Doom nodes %{input} -> %{output}",
    )

    return DefaultInfo(files = depset([out]))

doom_zdbsp_wad = rule(
    implementation = _doom_zdbsp_wad_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = [".wad"],
            doc = "Input WAD file to finish with ZDBSP.",
        ),
        "_tool": attr.label(
            default = "@zdbsp//:zdbsp",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Runs ZDBSP over a WAD file to produce the final playable output.",
)
