#!/usr/bin/env bash
# Publish the workspace module in directory $1 (registry name $2) unless the
# version in its moon.mod is already on mooncakes.io. Requires
# MOONCAKES_USERNAME and MOONCAKES_TOKEN; skips with a notice when the token
# is absent so each namespace can be gated on its own repository secret.
set -euo pipefail

dir="$1"
module="$2"

if [ -z "${MOONCAKES_TOKEN:-}" ]; then
  echo "::notice::MOONCAKES_TOKEN for $module is not configured; skipping publish"
  exit 0
fi

version=$(sed -n 's/^version = "\(.*\)"$/\1/p' "$dir/moon.mod")
if [ -z "$version" ]; then
  echo "::error::could not read version from $dir/moon.mod"
  exit 1
fi

# Refresh the registry index so a module published by an earlier step (or by
# hand moments ago) is visible to both the skip check and dependency
# resolution.
moon update
index="$HOME/.moon/registry/index/user/$module.index"
if [ -f "$index" ] && grep -q "\"version\": \"$version\"" "$index"; then
  echo "$module@$version is already on mooncakes.io; nothing to publish"
  exit 0
fi

mkdir -p "$HOME/.moon"
printf '{"username": "%s", "token": "%s"}\n' \
  "$MOONCAKES_USERNAME" "$MOONCAKES_TOKEN" > "$HOME/.moon/credentials.json"
trap 'rm -f "$HOME/.moon/credentials.json"' EXIT

echo "publishing $module@$version"
moon -C "$dir" publish
