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

# A failing package manager does not stop configuration by default: the run
# finishes, exits 2, and names the command to re-run. --strict-packages stops
# before any configuration is applied.
STUB_BIN="$TMP_DIR/bin"
mkdir -p "$STUB_BIN"
printf '#!/bin/sh\nexit 100\n' >"$STUB_BIN/sudo"
chmod +x "$STUB_BIN/sudo"
run_with_failing_apt() {
  HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_HOME/config" \
    XDG_STATE_HOME="$TEST_HOME/state" \
    PATH="$STUB_BIN:$PATH" \
    DOTFILES_TEST_UNAME=Linux \
    DOTFILES_TEST_OS_ID=ubuntu \
    DOTFILES_TEST_PROC_VERSION='Linux generic' \
    bash "$ROOT_DIR/install.sh" --modules cli --with-packages "$@" 2>&1
}

status=0
output="$(run_with_failing_apt --strict-packages)" || status=$?
assert_equal "$status" 1 'strict package failure should exit 1'
assert_contains "$output" 'package installation failed for cli'
[[ ! -e "$TEST_HOME/config/sandlight-dotfiles/cli.sh" ]] || { printf 'strict mode applied configuration\n' >&2; exit 1; }

status=0
output="$(run_with_failing_apt)" || status=$?
assert_equal "$status" 2 'non-strict package failure should exit 2'
assert_contains "$output" 'cli: sudo apt-get install -y'
[[ -L "$TEST_HOME/config/sandlight-dotfiles/cli.sh" ]] || { printf 'configuration not applied after package failure\n' >&2; exit 1; }
