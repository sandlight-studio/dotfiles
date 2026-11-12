#!/usr/bin/env bash

detect_platform() {
  local kernel proc_version distro
  kernel="${DOTFILES_TEST_UNAME:-$(uname -s)}"
  DOTFILES_DISTRO=""

  case "$kernel" in
    Darwin)
      DOTFILES_PLATFORM=macos
      ;;
    Linux)
      proc_version="${DOTFILES_TEST_PROC_VERSION:-}"
      if [[ -z "$proc_version" && -r /proc/version ]]; then
        proc_version="$(cat /proc/version)"
      fi
      if [[ -n "${WSL_INTEROP:-}" || -n "${WSL_DISTRO_NAME:-}" || "$proc_version" == *Microsoft* || "$proc_version" == *microsoft* ]]; then
        DOTFILES_PLATFORM=wsl
      else
        DOTFILES_PLATFORM=linux
      fi
      distro="${DOTFILES_TEST_OS_ID:-}"
      if [[ -z "$distro" && -r /etc/os-release ]]; then
        distro="$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"' | head -n 1)"
      fi
      case "$distro" in
        ubuntu|debian) DOTFILES_DISTRO="$distro" ;;
        *) die "unsupported Linux distribution: ${distro:-unknown}" ;;
      esac
      ;;
    *) die "unsupported operating system: $kernel" ;;
  esac

  export DOTFILES_PLATFORM DOTFILES_DISTRO
  log_info "Detected platform: $DOTFILES_PLATFORM${DOTFILES_DISTRO:+/$DOTFILES_DISTRO}"
}

install_brew_packages() {
  local module="$1"
  local brewfile="$REPO_ROOT/packages/macos/$module.Brewfile"
  [[ -s "$brewfile" ]] || return 0
  command -v brew >/dev/null 2>&1 || die "Homebrew is required for --with-packages on macOS"
  PACKAGE_FIX_HINT="brew bundle install --file=$(printf '%q' "$brewfile")"
  run_command brew bundle install --file="$brewfile" || return 1
}

append_apt_manifest() {
  local manifest="$1" package
  [[ -f "$manifest" ]] || return 0
  while IFS= read -r package || [[ -n "$package" ]]; do
    package="${package%%#*}"
    package="${package//[[:space:]]/}"
    [[ -n "$package" ]] || continue
    [[ "$package" =~ ^[a-zA-Z0-9.+-]+$ ]] || die "invalid apt package name: $package"
    APT_PACKAGES="${APT_PACKAGES:+$APT_PACKAGES }$package"
  done <"$manifest"
}

install_apt_packages() {
  local module="$1"
  APT_PACKAGES=""
  append_apt_manifest "$REPO_ROOT/packages/linux/$module.txt"
  if [[ "$DOTFILES_PLATFORM" == "wsl" ]]; then
    append_apt_manifest "$REPO_ROOT/packages/wsl/$module.txt"
  fi
  [[ -n "$APT_PACKAGES" ]] || return 0
  PACKAGE_FIX_HINT="sudo apt-get install -y $APT_PACKAGES"
  if [[ "${DOTFILES_APT_UPDATED:-0}" != "1" ]]; then
    run_command sudo apt-get update || return 1
    DOTFILES_APT_UPDATED=1
  fi
  # Package names are validated before intentional word splitting.
  # shellcheck disable=SC2086
  run_command sudo apt-get install -y $APT_PACKAGES || return 1
}

# Returns non-zero when the package manager fails, leaving the command that
# would finish the job in PACKAGE_FIX_HINT. Missing prerequisites still die.
install_packages_for_module() {
  local module="$1"
  # Read by install.sh for the end-of-run summary.
  # shellcheck disable=SC2034
  PACKAGE_FIX_HINT=""
  case "$DOTFILES_PLATFORM" in
    macos) install_brew_packages "$module" ;;
    linux|wsl) install_apt_packages "$module" ;;
    *) die "no package adapter for $DOTFILES_PLATFORM" ;;
  esac
}
