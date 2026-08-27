#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/core.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/platform.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/tests/helpers.sh"

DOTFILES_TEST_UNAME=Darwin
detect_platform >/dev/null
assert_equal "$DOTFILES_PLATFORM" macos

DOTFILES_TEST_UNAME=Linux
DOTFILES_TEST_OS_ID=ubuntu
DOTFILES_TEST_PROC_VERSION='Linux version 6.8.0 generic'
unset WSL_INTEROP WSL_DISTRO_NAME || true
detect_platform >/dev/null
assert_equal "$DOTFILES_PLATFORM" linux
assert_equal "$DOTFILES_DISTRO" ubuntu

DOTFILES_TEST_OS_ID=debian
DOTFILES_TEST_PROC_VERSION='Linux version 5.15.0-microsoft-standard-WSL2'
detect_platform >/dev/null
assert_equal "$DOTFILES_PLATFORM" wsl
assert_equal "$DOTFILES_DISTRO" debian

if (
  export DOTFILES_TEST_UNAME=Linux
  export DOTFILES_TEST_OS_ID=fedora
  export DOTFILES_TEST_PROC_VERSION='Linux generic'
  detect_platform
) >/dev/null 2>&1; then
  printf 'unsupported distribution unexpectedly succeeded\n' >&2
  exit 1
fi
