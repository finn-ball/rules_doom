"""Repository rules for rules_doom Bzlmod users."""

load("//doom/private/local_iwad:repo.bzl", _doom_local_iwad_repository = "doom_local_iwad_repository")
load("//doom/private/terminal:repo.bzl", _doom_terminal_repository = "doom_terminal_repository")

doom_local_iwad_repository = _doom_local_iwad_repository
doom_terminal_repository = _doom_terminal_repository
