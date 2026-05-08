"""Rule for compiling a WadC source file into a raw Doom PWAD."""

load("@bazel_skylib//lib:paths.bzl", "paths")

def _stage_wadc_inputs(ctx, src_file, include_files):
    stage_dir = ctx.label.name + "_wadc_stage"

    staged_src = ctx.actions.declare_file(paths.join(stage_dir, ctx.label.name + ".wl"))
    ctx.actions.symlink(output = staged_src, target_file = src_file)

    staged_files = [staged_src]
    seen = {}
    for include_file in include_files:
        basename = include_file.basename
        if basename in seen:
            fail("doom_wadc_compile includes contain duplicate basename '{}': {} and {}".format(
                basename,
                seen[basename].short_path,
                include_file.short_path,
            ))
        seen[basename] = include_file

        staged_include = ctx.actions.declare_file(paths.join(stage_dir, basename))
        ctx.actions.symlink(output = staged_include, target_file = include_file)
        staged_files.append(staged_include)

    out = ctx.actions.declare_file(paths.join(stage_dir, ctx.label.name + ".wad"))
    return staged_src, out, staged_files

def _doom_wadc_compile_impl(ctx):
    src_file = ctx.file.src

    staged_src, out, staged_files = _stage_wadc_inputs(
        ctx = ctx,
        src_file = src_file,
        include_files = ctx.files.includes,
    )
    prefs_dir = ctx.actions.declare_directory(ctx.label.name + "_java_prefs")

    args = ctx.actions.args()
    if ctx.attr.no_source_lump:
        args.add("-nosrc")
    args.add("--seed", ctx.attr.seed)
    args.add_all(ctx.attr.extra_args)
    args.add(staged_src.path)

    ctx.actions.run(
        executable = ctx.executable._raw_wadc,
        arguments = [args],
        inputs = staged_files,
        outputs = [out, prefs_dir],
        env = {
            # WadC is a Java binary. Point prefs at a declared writable output
            # directory so the action stays self-contained without noisy warnings.
            "JAVA_TOOL_OPTIONS": "-Djava.util.prefs.userRoot=" + prefs_dir.path +
                                 " -Djava.util.prefs.systemRoot=" + prefs_dir.path,
        },
        mnemonic = "DoomWadCCompile",
        progress_message = "Compiling WadC source %{label}",
    )

    return DefaultInfo(files = depset([out]))

doom_wadc_compile = rule(
    implementation = _doom_wadc_compile_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = [".wl"],
            doc = "Input WadC source file.",
        ),
        "seed": attr.int(
            default = 1337,
            doc = "Deterministic seed passed to WadC.",
        ),
        "no_source_lump": attr.bool(
            default = False,
            doc = "If true, suppresses the WADCSRC lump in the output.",
        ),
        "extra_args": attr.string_list(
            doc = "Extra CLI arguments forwarded to WadC.",
        ),
        "includes": attr.label_list(
            allow_files = [".h", ".wl"],
            default = ["@wadc//:includes"],
            doc = "WadC include files staged next to the source before compilation.",
        ),
        "_raw_wadc": attr.label(
            default = "@wadc//:wadc",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Compiles a WadC source file into a raw PWAD.",
)
