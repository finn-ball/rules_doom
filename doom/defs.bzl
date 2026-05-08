"""Public entrypoints for rules_doom."""

load("//doom/private:engine.bzl", _doom_engine = "doom_engine")
load("//doom/private:launch.bzl", _doom_launch = "doom_launch")
load(
    "//doom/private:wad.bzl",
    _doom_iwad = "doom_iwad",
    _doom_pwad = "doom_pwad",
)
load("//doom/private/local_iwad:repo.bzl", _doom_local_iwad_repository = "doom_local_iwad_repository")
load("//doom/private/terminal:repo.bzl", _doom_terminal_repository = "doom_terminal_repository")
load("//doom/private/udmf:pwad.bzl", _doom_udmf_pwad = "doom_udmf_pwad")
load(
    "//doom/private/wadc:pwad.bzl",
    _doom_wadc_pwad = "doom_wadc_pwad",
)

doom_engine = _doom_engine
doom_launch = _doom_launch
doom_iwad = _doom_iwad
doom_pwad = _doom_pwad
doom_terminal_repository = _doom_terminal_repository
doom_local_iwad_repository = _doom_local_iwad_repository
doom_udmf_pwad = _doom_udmf_pwad
doom_wadc_pwad = _doom_wadc_pwad
