#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Bash files include the extensionless rc payloads, which a *.sh glob misses.
BASH_FILES=()
while IFS= read -r script; do
  BASH_FILES+=("$script")
done < <(rg --files -g '*.sh' -g '*.bash' | sort)
BASH_FILES+=(modules/shell/files/bashrc)
ZSH_FILES=(modules/shell/files/zshrc modules/shell/files/history.zsh)

for script in "${BASH_FILES[@]}"; do
  bash -n "$script"
done
if command -v zsh >/dev/null 2>&1; then
  for script in "${ZSH_FILES[@]}"; do
    zsh -n "$script"
  done
else
  printf 'skipped: zsh syntax check (zsh is not installed)\n'
fi
printf 'Syntax checks passed.\n'

# ShellCheck has no zsh dialect, so zsh payloads are covered by zsh -n only.
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x "${BASH_FILES[@]}"
  printf 'ShellCheck passed.\n'
else
  printf 'warning: shellcheck is not installed; skipping lint\n' >&2
fi

bash scripts/tests/run-all.sh
bash scripts/check-public-safety.sh
