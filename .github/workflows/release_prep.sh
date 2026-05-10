#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

TAG=$1
PREFIX="rules_doom-${TAG:1}"
ARCHIVE="rules_doom-$TAG.tar.gz"

git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip > "${ARCHIVE}"

cat <<EOF
## Using Bzlmod

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_doom", version = "${TAG:1}")
\`\`\`
EOF
