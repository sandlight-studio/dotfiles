#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TEST_HOME="$TMP_DIR/home"
mkdir -p "$TEST_HOME"

output="$(
  HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/config" \
    XDG_STATE_HOME="$TEST_HOME/state" \
    DOTFILES_TEST_UNAME=Linux \
    DOTFILES_TEST_OS_ID=ubuntu \
    DOTFILES_TEST_PROC_VERSION='Linux generic' \
    bash "$ROOT_DIR/install.sh" --modules cli --with-packages --dry-run
)"

assert_contains "$output" 'sudo apt-get update'
assert_contains "$output" 'sudo apt-get install -y'
if [[ -e "$TEST_HOME/config" || -e "$TEST_HOME/state" ]]; then
  printf 'dry-run created files\n' >&2
  exit 1
fi
