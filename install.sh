#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/core.sh
source "$REPO_ROOT/lib/core.sh"
# shellcheck source=lib/config.sh
source "$REPO_ROOT/lib/config.sh"
# shellcheck source=lib/platform.sh
source "$REPO_ROOT/lib/platform.sh"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --config FILE       Read configuration from FILE.
  --modules CSV       Override configured modules.
  --with-packages     Install enabled modules' package manifests.
  --strict-packages   With --with-packages, stop at the first package failure.
  --dry-run           Print changes without applying them.
  -h, --help          Show this help.
USAGE
}

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/config.env"
CLI_MODULES=""
WITH_PACKAGES=0
STRICT_PACKAGES=0
DRY_RUN=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --config)
      [[ "$#" -ge 2 ]] || die "--config requires a path"
      CONFIG_FILE="$2"
      shift 2
      ;;
    --modules)
      [[ "$#" -ge 2 ]] || die "--modules requires a comma-separated list"
      CLI_MODULES="$2"
      shift 2
      ;;
    --with-packages)
      WITH_PACKAGES=1
      shift
      ;;
    --strict-packages)
      STRICT_PACKAGES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
done

load_config "$CONFIG_FILE"
if [[ -n "$CLI_MODULES" ]]; then
  normalize_modules "$CLI_MODULES"
fi
detect_platform
init_state
write_generated_file "$DOTFILES_CONFIG_HOME/active-config" "$CONFIG_FILE"

declare -a enabled_modules
IFS=',' read -r -a enabled_modules <<<"$DOTFILES_MODULES"

# A failed package install does not stop configuration from being applied:
# every module guards its optional tools, so a partial bootstrap still yields
# a working shell. The summary at the end lists what to re-run.
PACKAGE_FAILURES=""
if [[ "$WITH_PACKAGES" == "1" ]]; then
  for module in "${enabled_modules[@]}"; do
    if ! install_packages_for_module "$module"; then
      [[ "$STRICT_PACKAGES" == "0" ]] || die "package installation failed for $module: $PACKAGE_FIX_HINT"
      log_warn "package installation failed for $module; continuing"
      PACKAGE_FAILURES="${PACKAGE_FAILURES}${module}"$'\t'"${PACKAGE_FIX_HINT}"$'\n'
    fi
  done
fi

for module in "${enabled_modules[@]}"; do
  module_script="$REPO_ROOT/modules/$module/install.sh"
  [[ -f "$module_script" ]] || die "module implementation is missing: $module"
  # shellcheck source=/dev/null
  source "$module_script"
  "install_$module"
done

log_info "Installation complete: $DOTFILES_MODULES"
if [[ "$DRY_RUN" == "0" ]]; then
  log_info "State manifest: $DOTFILES_STATE_FILE"
fi
if [[ -n "$PACKAGE_FAILURES" ]]; then
  log_warn "some packages were not installed; re-run:"
  while IFS=$'\t' read -r module hint; do
    [[ -n "$module" ]] || continue
    printf '  %s: %s\n' "$module" "$hint" >&2
  done <<<"$PACKAGE_FAILURES"
  exit 2
fi
