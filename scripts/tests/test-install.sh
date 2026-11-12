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
chmod 644 "$TEST_HOME/.bashrc"
original_bashrc="$(cksum <"$TEST_HOME/.bashrc")"
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
# A value the user chose must survive the project's include.
HOME="$TEST_HOME" git config --global merge.conflictStyle diff3

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
assert_equal "$(file_mode "$TEST_HOME/.bashrc")" 644 'install changed the bashrc mode'

# Git: project defaults apply, user values win, and the ignore list is offered
# at Git's native XDG path without setting core.excludesFile.
git_get() {
  HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_CONFIG_HOME" git config --global --includes --get "$1"
}
assert_equal "$(git_get fetch.prune)" true 'project Git default not applied'
assert_equal "$(git_get user.useConfigOnly)" true 'useConfigOnly not applied'
assert_equal "$(git_get merge.conflictStyle)" diff3 'project include overrode a user value'
if git_get core.excludesFile >/dev/null; then
  printf 'core.excludesFile must not be set by the project\n' >&2
  exit 1
fi
[[ -L "$TEST_CONFIG_HOME/git/ignore" ]] || { printf 'Git ignore list is not linked\n' >&2; exit 1; }
assert_equal "$(readlink "$TEST_CONFIG_HOME/git/ignore")" "$ROOT_DIR/modules/git/files/ignore"

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
assert_equal "$(file_mode "$TEST_HOME/.bashrc")" 644 'uninstall changed the bashrc mode'
assert_equal "$(cksum <"$TEST_HOME/.bashrc")" "$original_bashrc" 'bashrc not restored byte-for-byte'
assert_equal "$(grep -c '^\[include\]' "$TEST_HOME/.gitconfig" || true)" 0 'empty [include] section left behind'
assert_equal "$(HOME="$TEST_HOME" git config --global merge.conflictStyle)" diff3
[[ ! -e "$TEST_CONFIG_HOME/git/ignore" ]] || { printf 'Git ignore link left behind\n' >&2; exit 1; }
[[ ! -e "$TEST_CONFIG_HOME/git" ]] || { printf 'empty Git config directory left behind\n' >&2; exit 1; }

# Repeated install/uninstall cycles must not accumulate blank lines.
for _ in 1 2 3; do
  run_install >/dev/null
  HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_CONFIG_HOME" XDG_STATE_HOME="$TEST_STATE_HOME" \
    bash "$ROOT_DIR/uninstall.sh" >/dev/null
done
assert_equal "$(cksum <"$TEST_HOME/.bashrc")" "$original_bashrc" 'install cycles changed bashrc'

# An ignore file the user already owns is kept, not backed up or replaced.
OWN_HOME="$TMP_DIR/own-ignore"
mkdir -p "$OWN_HOME/.config/git"
printf '%s\n' 'my-own-pattern' >"$OWN_HOME/.config/git/ignore"
output="$(
  HOME="$OWN_HOME" XDG_CONFIG_HOME="$OWN_HOME/.config" XDG_STATE_HOME="$OWN_HOME/state" \
    DOTFILES_TEST_UNAME=Linux DOTFILES_TEST_OS_ID=ubuntu DOTFILES_TEST_PROC_VERSION='Linux generic' \
    bash "$ROOT_DIR/install.sh" --modules git 2>&1
)"
assert_contains "$output" 'keeping existing'
[[ ! -L "$OWN_HOME/.config/git/ignore" ]] || { printf 'user ignore file was replaced\n' >&2; exit 1; }
assert_file_contains "$OWN_HOME/.config/git/ignore" 'my-own-pattern'
