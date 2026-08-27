#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
TEST_HOME="$TMP_DIR/home with spaces"
TEST_CONFIG_HOME="$TEST_HOME/config root"
TEST_STATE_HOME="$TEST_HOME/state root"
mkdir -p "$TEST_HOME" "$TEST_CONFIG_HOME/sandlight-dotfiles" "$TEST_STATE_HOME"

printf '%s\n' 'export EXISTING_BASH=1' >"$TEST_HOME/.bashrc"
printf '%s\n' 'export EXISTING_ZSH=1' >"$TEST_HOME/legacy-zshrc"
ln -s "$TEST_HOME/legacy-zshrc" "$TEST_HOME/.zshrc"
mkdir -p "$TEST_HOME/.config"
printf '%s\n' 'existing-starship-config' >"$TEST_HOME/.config/starship.toml"

cat >"$TEST_CONFIG_HOME/sandlight-dotfiles/config.env" <<'CONFIG'
DOTFILES_MODULES="shell,git,cli,terminal,proxy"
DOTFILES_PROXY_AUTO_ENABLE=0
DOTFILES_PROXY_HTTP_URL="http://127.0.0.1:8080"
DOTFILES_PROXY_HTTPS_URL="http://127.0.0.1:8080"
DOTFILES_PROXY_ALL_URL="socks5://127.0.0.1:1080"
DOTFILES_NO_PROXY="localhost,127.0.0.1,::1"
CONFIG

HOME="$TEST_HOME" git config --global user.name 'Example User'
HOME="$TEST_HOME" git config --global user.email 'developer@example.com'

run_install() {
  HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$TEST_CONFIG_HOME" \
    XDG_STATE_HOME="$TEST_STATE_HOME" \
    DOTFILES_TEST_UNAME=Linux \
    DOTFILES_TEST_OS_ID=ubuntu \
    DOTFILES_TEST_PROC_VERSION='Linux generic' \
    bash "$ROOT_DIR/install.sh"
}

run_install >/dev/null
STATE_FILE="$TEST_STATE_HOME/sandlight-dotfiles/install-state.tsv"
assert_file_contains "$TEST_HOME/.bashrc" '# >>> sandlight-dotfiles >>>'
assert_file_contains "$TEST_HOME/.bashrc" 'export EXISTING_BASH=1'
assert_file_contains "$TEST_HOME/.zshrc" '# >>> sandlight-dotfiles >>>'
[[ -L "$TEST_HOME/.config/starship.toml" ]] || { printf 'starship config is not linked\n' >&2; exit 1; }
assert_equal "$(HOME="$TEST_HOME" git config --global user.name)" 'Example User'
assert_equal "$(HOME="$TEST_HOME" git config --global user.email)" 'developer@example.com'
assert_equal "$(HOME="$TEST_HOME" git config --global --get-all include.path | wc -l | tr -d ' ')" 1

first_state="$(cksum "$STATE_FILE")"
first_bashrc="$(cksum "$TEST_HOME/.bashrc")"
run_install >/dev/null
assert_equal "$(cksum "$STATE_FILE")" "$first_state" 'state changed after idempotent install'
assert_equal "$(cksum "$TEST_HOME/.bashrc")" "$first_bashrc" 'bashrc changed after idempotent install'
assert_equal "$(grep -Fc '# >>> sandlight-dotfiles >>>' "$TEST_HOME/.bashrc")" 1
assert_equal "$(HOME="$TEST_HOME" git config --global --get-all include.path | wc -l | tr -d ' ')" 1

HOME="$TEST_HOME" \
  XDG_CONFIG_HOME="$TEST_CONFIG_HOME" \
  XDG_STATE_HOME="$TEST_STATE_HOME" \
  bash "$ROOT_DIR/uninstall.sh" >/dev/null

assert_file_contains "$TEST_HOME/.bashrc" 'export EXISTING_BASH=1'
assert_not_contains "$(cat "$TEST_HOME/.bashrc")" '# >>> sandlight-dotfiles >>>'
[[ -L "$TEST_HOME/.zshrc" ]] || { printf 'original zshrc symlink was not restored\n' >&2; exit 1; }
assert_equal "$(readlink "$TEST_HOME/.zshrc")" "$TEST_HOME/legacy-zshrc"
assert_file_contains "$TEST_HOME/.config/starship.toml" 'existing-starship-config'
assert_equal "$(HOME="$TEST_HOME" git config --global user.name)" 'Example User'
if HOME="$TEST_HOME" git config --global --get-all include.path >/dev/null 2>&1; then
  printf 'managed Git include still exists after uninstall\n' >&2
  exit 1
fi
