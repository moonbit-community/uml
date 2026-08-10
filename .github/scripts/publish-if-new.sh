#!/usr/bin/env bash
# Publish the workspace module in directory $1 (registry name $2) unless the
# version in its moon.mod is already on mooncakes.io. When publishing is
# needed, MOONCAKES_CREDENTIALS must contain a complete credentials.json.
set -euo pipefail

dir="$1"
module="$2"

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
if [ -f "$index" ]; then
  published=$(jq -sr --arg version "$version" 'any(.[]; .version == $version)' "$index")
  if [ "$published" = "true" ]; then
    echo "$module@$version is already on mooncakes.io; nothing to publish"
    exit 0
  fi
fi

if [ -z "${MOONCAKES_CREDENTIALS:-}" ]; then
  echo "::error::credentials for $module are not configured"
  exit 1
fi

mkdir -p "$HOME/.moon"
credentials_file="$HOME/.moon/credentials.json"
umask 077
printf '%s\n' "$MOONCAKES_CREDENTIALS" > "$credentials_file"
trap 'rm -f "$credentials_file"' EXIT
if ! jq -e '(.token | type == "string") and (.token | length > 0)' \
  "$credentials_file" > /dev/null; then
  echo "::error::credentials for $module are not valid credentials JSON"
  exit 1
fi

echo "publishing $module@$version"
moon -C "$dir" publish
