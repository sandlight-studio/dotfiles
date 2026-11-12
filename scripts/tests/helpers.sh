#!/usr/bin/env bash

# Name the failing command and line instead of exiting silently under set -e.
set -E
trap 'printf "test failed: %s:%s: %s (exit %s)\n" "${BASH_SOURCE[0]}" "$LINENO" "$BASH_COMMAND" "$?" >&2' ERR

assert_equal() {
  local actual="$1" expected="$2" message="${3:-values differ}"
  if [[ "$actual" != "$expected" ]]; then
    printf 'assertion failed: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'assertion failed: output does not contain %s\n%s\n' "$needle" "$haystack" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file="$1" needle="$2"
  [[ -f "$file" ]] || { printf 'missing file: %s\n' "$file" >&2; exit 1; }
  grep -Fq "$needle" "$file" || { printf '%s does not contain %s\n' "$file" "$needle" >&2; exit 1; }
}

assert_not_contains() {
  local haystack="$1" needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'assertion failed: output unexpectedly contains %s\n%s\n' "$needle" "$haystack" >&2
    exit 1
  fi
}


# Permission bits of a file, portable across GNU and BSD stat.
file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}
