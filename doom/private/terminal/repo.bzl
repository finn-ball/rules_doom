"""Repository rule for launching terminal Doom during repository fetch."""

load("@bazel_skylib//lib:shell.bzl", "shell")

# Inspired by snazel: https://github.com/TheGrizzlyDev/snazel
#
# It launches terminal Doom as a repository-fetch side effect
# when Bazel has a real terminal, and otherwise leaves behind
# a harmless empty target.

def _empty_repo(repo_ctx):
    repo_ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

filegroup(name = "doom_terminal")
""")

def _bazel_tty(repo_ctx, bash):
    for process_name in ["bazel", "bazelisk"]:
        pid = repo_ctx.execute(
            [bash, "-c", "pidof -s {}".format(shell.quote(process_name))],
            quiet = True,
        ).stdout.strip()
        if not pid:
            continue

        tty = repo_ctx.execute(
            [bash, "-c", "ps -o tty= -q {}".format(shell.quote(pid))],
            quiet = True,
        ).stdout.strip()
        if tty and tty != "?":
            return "/dev/{}".format(tty)

    tty = repo_ctx.execute(
        [bash, "-c", """ps -eo tty=,comm=,args= | while read -r tty comm args; do
  if [[ -z "$tty" || "$tty" == "?" ]]; then
    continue
  fi
  case "$comm $args" in
    *bazel*|*bazelisk*) printf '%s' "$tty"; exit 0 ;;
  esac
done"""],
        quiet = True,
    ).stdout.strip()
    if not tty:
        return ""

    return "/dev/{}".format(tty)

def _doom_terminal_repository_impl(repo_ctx):
    if "linux" not in repo_ctx.os.name.lower():
        _empty_repo(repo_ctx)
        return

    bash = repo_ctx.which("bash")
    script = repo_ctx.which("script")
    if not bash or not script:
        _empty_repo(repo_ctx)
        return

    tty = _bazel_tty(repo_ctx, bash)
    if not tty:
        _empty_repo(repo_ctx)
        return

    repo_ctx.download_and_extract(
        url = repo_ctx.attr.binary_url,
        sha256 = repo_ctx.attr.binary_sha256,
    )

    doom = str(repo_ctx.path("doom-ascii"))
    wad = str(repo_ctx.path(repo_ctx.attr.iwad))

    args = [
        "-iwad",
        wad,
        "-scaling",
        str(repo_ctx.attr.scaling),
        "-kpsmooth",
        str(repo_ctx.attr.kpsmooth),
    ]

    if repo_ctx.attr.nocolor:
        args.append("-nocolor")
    if repo_ctx.attr.nograd:
        args.append("-nograd")
    if repo_ctx.attr.nobold:
        args.append("-nobold")
    if repo_ctx.attr.erase:
        args.append("-erase")
    if repo_ctx.attr.fixgamma:
        args.append("-fixgamma")
    if repo_ctx.attr.chars:
        args.extend(["-chars", repo_ctx.attr.chars])

    command = "exec " + " ".join([shell.quote(doom)] + [shell.quote(arg) for arg in args])

    cmd = """
TTY={tty}
SCRIPT={script}
COMMAND={command}
"$SCRIPT" -qf -c "$COMMAND" /dev/null <"$TTY" >"$TTY" 2>&1
""".format(
        tty = shell.quote(tty),
        script = shell.quote(str(script)),
        command = shell.quote(command),
    )

    result = repo_ctx.execute(
        [bash, "-c", cmd],
        quiet = False,
    )
    if result.return_code != 0:
        fail("doom_terminal_repository exited with code {}".format(result.return_code))

    repo_ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "doom_terminal",
    srcs = ["doom-ascii"],
)
""")

doom_terminal_repository = repository_rule(
    implementation = _doom_terminal_repository_impl,
    local = True,
    configure = True,
    attrs = {
        "binary_url": attr.string(mandatory = True),
        "binary_sha256": attr.string(mandatory = True),
        "iwad": attr.label(allow_single_file = True, mandatory = True),
        "scaling": attr.int(default = 5),
        "kpsmooth": attr.int(default = 50),
        "nocolor": attr.bool(default = False),
        "nograd": attr.bool(default = False),
        "nobold": attr.bool(default = False),
        "erase": attr.bool(default = False),
        "fixgamma": attr.bool(default = False),
        "chars": attr.string(
            default = "",
            values = ["", "ascii", "block", "braille"],
        ),
    },
)
