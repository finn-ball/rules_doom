"""Rule for packing a UDMF TEXTMAP into a PWAD via WadMerge."""

def _wadmerge_script_content(textmap, map_name, out, behavior = None):
    behavior_block = ""
    if behavior:
        behavior_block = 'MERGEFILE outwad "{}" BEHAVIOR\n'.format(behavior.path)

    return """CREATE outwad
MARKER outwad {map_name}
MERGEFILE outwad "{textmap}" TEXTMAP
{behavior_block}MARKER outwad ENDMAP
FINISH outwad "{out}"
END
""".format(
        map_name = map_name,
        textmap = textmap.path,
        behavior_block = behavior_block,
        out = out.path,
    )

def _doom_udmf_compile_impl(ctx):
    textmap = ctx.file.src
    out = ctx.actions.declare_file(ctx.label.name + ".raw.wad")
    behavior_inputs = []
    if ctx.file.behavior:
        behavior_inputs = [ctx.file.behavior]
    script_content = _wadmerge_script_content(
        textmap = textmap,
        map_name = ctx.attr.map_name,
        out = out,
        behavior = ctx.file.behavior,
    )

    script = ctx.actions.declare_file(ctx.label.name + "_wadmerge.txt")
    ctx.actions.write(output = script, content = script_content)

    ctx.actions.run(
        executable = ctx.executable._tool,
        inputs = [textmap, script] + behavior_inputs,
        outputs = [out],
        arguments = [script.path],
        mnemonic = "DoomUdmfPack",
        progress_message = "Packing UDMF TEXTMAP %{label}",
    )

    return DefaultInfo(files = depset([out]))

doom_udmf_compile = rule(
    implementation = _doom_udmf_compile_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = [".textmap", ".udmf", ".txt"],
        ),
        "map_name": attr.string(default = "MAP01"),
        "behavior": attr.label(
            allow_single_file = True,
            doc = "Optional compiled ACS script (BEHAVIOR lump).",
        ),
        "_tool": attr.label(
            default = "@doomtools//:wadmerge",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Packages UDMF TEXTMAP plus optional BEHAVIOR into a raw PWAD via WadMerge.",
)
