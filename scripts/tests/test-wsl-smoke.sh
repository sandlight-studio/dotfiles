#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/platform.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

detect_platform >/dev/null
assert_equal "$DOTFILES_PLATFORM" wsl
assert_equal "$DOTFILES_DISTRO" ubuntu

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TEST_HOME="$TMP_DIR/home"
TEST_CONFIG_HOME="$TMP_DIR/config"
TEST_STATE_HOME="$TMP_DIR/state"
mkdir -p "$TEST_HOME" "$TEST_CONFIG_HOME/sandlight-dotfiles"

cat >"$TEST_CONFIG_HOME/sandlight-dotfiles/config.env" <<'CONFIG'
DOTFILES_MODULES="shell,git,cli,proxy"
DOTFILES_PROXY_AUTO_ENABLE=0
DOTFILES_PROXY_HTTP_URL="http://127.0.0.1:8080"
CONFIG

run_install() {
  HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_CONFIG_HOME" \
    XDG_STATE_HOME="$TEST_STATE_HOME" \
    bash "$ROOT_DIR/install.sh"
}

run_install >/dev/null
run_install >/dev/null
assert_equal "$(grep -Fc '# >>> sandlight-dotfiles >>>' "$TEST_HOME/.bashrc")" 1
assert_equal "$(HOME="$TEST_HOME" git config --global --get-all include.path | wc -l | tr -d ' ')" 1
[[ -L "$TEST_CONFIG_HOME/sandlight-dotfiles/proxy.sh" ]] || {
  printf 'proxy module was not linked under WSL2\n' >&2
  exit 1
}

HOME="$TEST_HOME" \
  XDG_CONFIG_HOME="$TEST_CONFIG_HOME" \
  XDG_STATE_HOME="$TEST_STATE_HOME" \
  bash "$ROOT_DIR/uninstall.sh" >/dev/null

if [[ -e "$TEST_HOME/.bashrc" ]]; then
  printf 'generated bashrc still exists after WSL2 uninstall\n' >&2
  exit 1
fi

