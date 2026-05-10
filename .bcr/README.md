# Bazel Central Registry

This directory contains metadata used by `bazel-contrib/publish-to-bcr` to open
pull requests against the Bazel Central Registry after a GitHub release is
published.

The current repository is configured to publish to the existing fork at:

- `finn-ball/bazel-central-registry`

Publishing is inert until the `BCR_PUBLISH_TOKEN` GitHub Actions secret is set.
