#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
publish_script="$script_dir/publish-if-new.sh"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
export MOON_LOG="$test_root/moon.log"
module_dir="$test_root/module"
module="test-owner/test-module"
version="1.2.3"
index="$HOME/.moon/registry/index/user/$module.index"

mkdir -p "$test_root/bin" "$module_dir" "$(dirname "$index")"
printf 'version = "%s"\n' "$version" > "$module_dir/moon.mod"
printf '%s\n' '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'printf "%s\n" "$*" >> "$MOON_LOG"' \
  'if [ "${1:-}" = "update" ]; then exit 0; fi' \
  'if [ "${1:-}" = "-C" ] && [ "${3:-}" = "publish" ]; then' \
  '  jq -e '\''(.username == "test-owner") and (.token == "valid-token")'\'' "$HOME/.moon/credentials.json" > /dev/null' \
  '  exit 0' \
  'fi' \
  'exit 1' > "$test_root/bin/moon"
chmod +x "$test_root/bin/moon"
export PATH="$test_root/bin:$PATH"

jq -n --arg name "$module" --arg version "$version" \
  '{ name: $name, version: $version }' > "$index"
: > "$MOON_LOG"
env -u MOONCAKES_CREDENTIALS "$publish_script" "$module_dir" "$module"
grep -Fxq "update" "$MOON_LOG"
if grep -q "publish" "$MOON_LOG"; then
  echo "already-published module unexpectedly invoked publish" >&2
  exit 1
fi

rm "$index"
: > "$MOON_LOG"
if env -u MOONCAKES_CREDENTIALS \
  "$publish_script" "$module_dir" "$module" > /dev/null 2>&1; then
  echo "missing credentials unexpectedly succeeded" >&2
  exit 1
fi

if MOONCAKES_CREDENTIALS='{"token":""}' \
  "$publish_script" "$module_dir" "$module" > /dev/null 2>&1; then
  echo "invalid credentials unexpectedly succeeded" >&2
  exit 1
fi
test ! -e "$HOME/.moon/credentials.json"

: > "$MOON_LOG"
MOONCAKES_CREDENTIALS='{"username":"test-owner","token":"valid-token"}' \
  "$publish_script" "$module_dir" "$module"
grep -Fxq -- "-C $module_dir publish" "$MOON_LOG"
test ! -e "$HOME/.moon/credentials.json"
