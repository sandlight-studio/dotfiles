#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_wsl() {
  [[ -n "${WSL_INTEROP:-}" ]] || { [[ -r /proc/version ]] && grep -qi microsoft /proc/version; }
}

for test_file in "$TEST_DIR"/test-*.sh; do
  name="$(basename "$test_file")"
  if [[ "$name" == "test-wsl-smoke.sh" ]] && ! is_wsl; then
    printf 'skipped: %s (not running under WSL)\n' "$name"
    continue
  fi
  started="$SECONDS"
  printf 'Running %s\n' "$name"
  bash "$test_file"
  printf '  ok (%ss)\n' "$((SECONDS - started))"
done

printf 'All tests passed.\n'
