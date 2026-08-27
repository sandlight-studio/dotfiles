#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/scripts/tests/run-all.sh"
bash "$ROOT_DIR/scripts/check-public-safety.sh"

if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r script; do
    shellcheck -x "$script"
  done < <(rg --files "$ROOT_DIR" -g '*.sh')
else
  printf 'warning: shellcheck is not installed; skipping lint\n' >&2
fi

