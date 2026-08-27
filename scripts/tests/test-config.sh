#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/config.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

load_config "$TMP_DIR/missing.env"
assert_equal "$DOTFILES_MODULES" shell,git,cli
assert_equal "$DOTFILES_PROXY_AUTO_ENABLE" 0

cat >"$TMP_DIR/custom.env" <<'CONFIG'
DOTFILES_MODULES="shell,proxy"
DOTFILES_PROXY_AUTO_ENABLE=1
DOTFILES_PROXY_HTTP_URL="http://127.0.0.1:8080"
CONFIG
load_config "$TMP_DIR/custom.env"
assert_equal "$DOTFILES_MODULES" shell,proxy
assert_equal "$DOTFILES_PROXY_AUTO_ENABLE" 1

cat >"$TMP_DIR/duplicate.env" <<'CONFIG'
DOTFILES_MODULES="shell,shell"
CONFIG
if (load_config "$TMP_DIR/duplicate.env") >/dev/null 2>&1; then
  printf 'duplicate modules unexpectedly succeeded\n' >&2
  exit 1
fi

cat >"$TMP_DIR/unknown.env" <<'CONFIG'
DOTFILES_MODULES="shell,unknown"
CONFIG
if (load_config "$TMP_DIR/unknown.env") >/dev/null 2>&1; then
  printf 'unknown module unexpectedly succeeded\n' >&2
  exit 1
fi
