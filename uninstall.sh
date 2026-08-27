#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/core.sh
source "$REPO_ROOT/lib/core.sh"

usage() {
  cat <<'USAGE'
Usage: ./uninstall.sh [--dry-run]

Removes configuration still owned by this project and restores available
backups. Installed packages are not removed.
USAGE
}

DRY_RUN=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

set_state_paths
if [[ ! -f "$DOTFILES_STATE_FILE" ]]; then
  log_info "Nothing to uninstall"
  exit 0
fi

UNINSTALL_INCOMPLETE=0
while IFS=$'\t' read -r kind target detail; do
  case "$kind" in
    link)
      if [[ -L "$target" && "$(readlink "$target")" == "$detail" ]]; then
        run_command rm "$target"
        log_info "Removed link $target"
      elif [[ -e "$target" || -L "$target" ]]; then
        log_warn "preserving target no longer owned by the project: $target"
        UNINSTALL_INCOMPLETE=1
      fi
      ;;
    block)
      remove_shell_block "$target"
      ;;
    generated)
      if [[ -f "$target" && "$(cat "$target")" == "$detail" ]]; then
        run_command rm "$target"
        log_info "Removed generated file $target"
      elif [[ -e "$target" ]]; then
        log_warn "preserving modified generated file: $target"
        UNINSTALL_INCOMPLETE=1
      fi
      ;;
    git_include)
      if git config --global --fixed-value --get-all include.path "$detail" >/dev/null 2>&1; then
        run_command git config --global --fixed-value --unset-all include.path "$detail"
        log_info "Removed Git include $detail"
      fi
      ;;
  esac
done <"$DOTFILES_STATE_FILE"

while IFS=$'\t' read -r kind target detail; do
  [[ "$kind" == "backup" ]] || continue
  if [[ ! -e "$target" && ! -L "$target" && -e "$detail" ]]; then
    run_command mkdir -p "$(dirname "$target")"
    run_command mv "$detail" "$target"
    log_info "Restored backup $target"
  fi
done <"$DOTFILES_STATE_FILE"

if [[ "$DRY_RUN" == "0" && "$UNINSTALL_INCOMPLETE" == "0" ]]; then
  history_file="$DOTFILES_STATE_HOME/uninstalled-$(date +%Y%m%d-%H%M%S).tsv"
  mv "$DOTFILES_STATE_FILE" "$history_file"
  rmdir "$DOTFILES_CONFIG_HOME" 2>/dev/null || true
  log_info "Uninstall complete; state archived at $history_file"
elif [[ "$UNINSTALL_INCOMPLETE" == "1" ]]; then
  log_warn "uninstall was incomplete; the state manifest was preserved"
fi

