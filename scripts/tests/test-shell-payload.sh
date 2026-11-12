#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
FILES="$ROOT_DIR/modules/shell/files"

# Token-shaped fixtures are assembled at runtime so secret scanners do not
# mistake this file for a leak.
filler="abcdefghijklmnopqrstuvwxyz0123456789"
github_token="gh""p_$filler"
openai_key="s""k-proj-$filler"

# Commands that mention secret-sounding words but carry no value.
kept=(
  "ssh-keygen -t ed25519 -C me"
  "ssh-add -l"
  "cat ~/.ssh/id-key-auth.pub"
  "git commit --author=\"A B <a@b.c>\" -m msg"
  "kubectl get secret web -o yaml"
  "echo \$GITHUB_TOKEN | wc -c"
  "cd task-management-dashboard-v2-final"
  "rg token src/"
)
# Commands that carry a secret value.
dropped=(
  "export API_KEY=abc123"
  "GITHUB_TOKEN=abc gh api user"
  "curl -H \"X-Api-Key: abc\" https://example.com"
  "curl -H \"Authorization: Bearer abc\" https://example.com"
  "curl -d \"{\\\"password\\\": \\\"hunter2\\\"}\" https://example.com"
  "mytool --token abc123 run"
  "mytool --password=hunter2"
  "echo $openai_key"
  "git clone https://$github_token@example.com/a/b"
  "op read vault/item/field"
)

# —— zsh: full filter ——
if command -v zsh >/dev/null 2>&1; then
  zsh -f -c '
    source "$1"
    shift
    mode=kept
    for line in "$@"; do
      if [[ $line == --dropped-- ]]; then mode=dropped; continue; fi
      if _sandlight_history_filter "$line"$'"'"'\n'"'"'; then
        [[ $mode == kept ]] || { print -u2 "zsh wrongly kept: $line"; exit 1 }
      else
        [[ $mode == dropped ]] || { print -u2 "zsh wrongly dropped: $line"; exit 1 }
      fi
    done
    SANDLIGHT_HISTORY_FILTER=0
    _sandlight_history_filter "export API_KEY=abc" || { print -u2 "opt-out ignored"; exit 1 }
  ' _ "$FILES/history.zsh" "${kept[@]}" --dropped-- "${dropped[@]}"

  # A bare interactive zsh with the payload starts quietly and gets completion.
  ZSH_HOME="$TMP_DIR/zsh-home"
  mkdir -p "$ZSH_HOME/.config/sandlight-dotfiles"
  for name in common.sh history.zsh; do
    ln -s "$FILES/$name" "$ZSH_HOME/.config/sandlight-dotfiles/$name"
  done
  out="$(env -i HOME="$ZSH_HOME" ZDOTDIR="$ZSH_HOME" PATH=/usr/bin:/bin TERM=xterm-256color \
    zsh -dic "source '$FILES/zshrc'; (( \$+functions[compdef] )) && print started" 2>&1)"
  assert_equal "$out" started 'zsh payload is not quiet or compinit did not run'
  ls "$ZSH_HOME/.cache/sandlight-dotfiles"/zcompdump-* >/dev/null 2>&1 ||
    { printf 'completion dump not written to the cache directory\n' >&2; exit 1; }
else
  printf 'skipped: zsh payload checks (zsh is not installed)\n'
fi

# —— bash: approximate filter through HISTIGNORE ——
bash_ignored() {
  local line="$1" pattern
  local IFS=':'
  # shellcheck disable=SC2086
  set -f
  for pattern in $HISTIGNORE; do
    # shellcheck disable=SC2053
    if [[ "$line" == $pattern ]]; then
      set +f
      return 0
    fi
  done
  set +f
  return 1
}

HISTCONTROL="" HISTIGNORE=""
# shellcheck source=/dev/null
source "$FILES/history.bash"
assert_contains "$HISTCONTROL" ignorespace
for line in "${kept[@]}"; do
  if bash_ignored "$line"; then
    printf 'bash wrongly dropped: %s\n' "$line" >&2
    exit 1
  fi
done
for line in "export API_KEY=abc123" "GITHUB_TOKEN=abc gh api user" \
  "curl -H \"Authorization: Bearer abc\" https://example.com" \
  "mytool --token abc123 run" "mytool --password=hunter2" \
  "git clone https://$github_token@example.com/a/b" "op read vault/item/field"; do
  if ! bash_ignored "$line"; then
    printf 'bash wrongly kept: %s\n' "$line" >&2
    exit 1
  fi
done
# Sourcing twice must not grow HISTIGNORE.
before="$HISTIGNORE"
# shellcheck source=/dev/null
source "$FILES/history.bash"
assert_equal "$HISTIGNORE" "$before" 'history.bash is not idempotent'

# —— tmux: the configuration parses ——
if command -v tmux >/dev/null 2>&1; then
  socket="sandlight-test-$$"
  if ! tmux -L "$socket" -f "$ROOT_DIR/modules/terminal/files/tmux.conf" start-server \; \
    show -gv escape-time >/dev/null 2>"$TMP_DIR/tmux.err"; then
    command cat "$TMP_DIR/tmux.err" >&2
    tmux -L "$socket" kill-server 2>/dev/null || true
    exit 1
  fi
  tmux -L "$socket" kill-server 2>/dev/null || true
  [[ ! -s "$TMP_DIR/tmux.err" ]] || { command cat "$TMP_DIR/tmux.err" >&2; exit 1; }
else
  printf 'skipped: tmux configuration check (tmux is not installed)\n'
fi
