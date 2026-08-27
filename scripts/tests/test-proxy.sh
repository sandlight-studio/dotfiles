#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/config/sandlight-dotfiles"
cat >"$TMP_DIR/proxy.env" <<'CONFIG'
DOTFILES_PROXY_AUTO_ENABLE=0
DOTFILES_PROXY_HTTP_URL="http://127.0.0.1:8080"
DOTFILES_PROXY_HTTPS_URL="http://127.0.0.1:8443"
DOTFILES_PROXY_ALL_URL="socks5://127.0.0.1:1080"
DOTFILES_NO_PROXY="localhost,127.0.0.1"
CONFIG
printf '%s\n' "$TMP_DIR/proxy.env" >"$TMP_DIR/config/sandlight-dotfiles/active-config"

http_proxy=""
https_proxy=""
all_proxy=""
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY || true
export XDG_CONFIG_HOME="$TMP_DIR/config"
# shellcheck source=/dev/null
source "$ROOT_DIR/modules/proxy/files/proxy.sh"

assert_equal "${http_proxy:-}" ''
proxy_on
assert_equal "$http_proxy" 'http://127.0.0.1:8080'
assert_equal "$https_proxy" 'http://127.0.0.1:8443'
assert_equal "$all_proxy" 'socks5://127.0.0.1:1080'
assert_equal "$NO_PROXY" 'localhost,127.0.0.1'
proxy_off
assert_equal "${http_proxy:-}" ''
assert_equal "${NO_PROXY:-}" ''
