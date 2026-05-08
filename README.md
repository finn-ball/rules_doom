# rules_doom

## What it does

`rules_doom` provides Bazel rules for launching Doom engines, packaging IWADs
and PWADs, and generating PWADs from supported source formats.

## Quick start

```starlark
load("@rules_doom//doom:defs.bzl", "doom_launch")

doom_launch(
    name = "play",
)
```

```bash
bazel run //:play
bazel run --@rules_doom//config/engine=uzdoom //:play
bazel run --@rules_doom//config/iwad=freedoom1 //:play
```

## Selecting engines and IWADs

`doom_launch(...)` defaults to `//doom/engine` and `//doom/wads:iwad`.
The selected targets are controlled by:

```bash
--@rules_doom//config/engine=uzdoom
--@rules_doom//config/engine=crispy
--@rules_doom//config/engine=ascii
--@rules_doom//config/iwad=freedoom1
--@rules_doom//config/iwad=freedoom2
```

## Adding PWADs / mods

```starlark
load("@rules_doom//doom:defs.bzl", "doom_launch")

doom_launch(
    name = "play_mod",
    pwads = ["//path/to:my_mod"]
)
```

## Local IWADs

Commercial IWADs such as `DOOM2.WAD` are not bundled. If you legally own one,
point Bazel at your local file from your root `MODULE.bazel`:

```starlark
doom_local_iwad_repository = use_repo_rule(
    "@rules_doom//doom:repositories.bzl",
    "doom_local_iwad_repository",
)

doom_local_iwad_repository(
    name = "doom2_iwad",
    path = "/absolute/path/to/DOOM2.WAD",
    map_namespace_style = "mapxx",
)
```

Then pass `iwad = "@doom2_iwad//:iwad"` to `doom_launch(...)`.

## Generated PWADs

Generated PWAD helpers use the bundled tool repositories directly:

- `doom_udmf_pwad(...)` builds a playable PWAD from UDMF text.
- `doom_wadc_pwad(...)` builds a playable PWAD from WadC source.

### WadC example

The repository includes a generated WadC example that builds an upstream WadC
source file from [`jmtd/wadc`](https://github.com/jmtd/wadc) into a PWAD and
runs it through the normal `doom_launch(...)` path:

```bash
bazel run //examples/wadc:entryway
```

## Terminal Doom

`rules_doom` can run doom in the bazel terminal
[`doom-ascii`](https://github.com/wojciech-graj/doom-ascii) inspired by
[`snazel`](https://github.com/TheGrizzlyDev/snazel).

```bash
bazel fetch --force --repo=@doom_terminal
```

## License

`rules_doom` itself is Apache-2.0. Downloaded engines, tools, IWADs, and PWADs
keep their own licenses. Commercial IWADs are not bundled.
