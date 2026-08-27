#!/usr/bin/env bash

if [[ -n "${SANDLIGHT_CORE_LOADED:-}" ]]; then
  return 0
fi
SANDLIGHT_CORE_LOADED=1

log_info() {
  printf '==> %s\n' "$*"
}

log_warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

is_dry_run() {
  [[ "${DRY_RUN:-0}" == "1" ]]
}

print_command() {
  local arg
  printf 'dry-run:'
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

run_command() {
  if is_dry_run; then
    print_command "$@"
    return 0
  fi
  "$@"
}

set_state_paths() {
  DOTFILES_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles"
  DOTFILES_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/sandlight-dotfiles"
  DOTFILES_STATE_FILE="$DOTFILES_STATE_HOME/install-state.tsv"
  DOTFILES_RUN_TIMESTAMP="${DOTFILES_RUN_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
  DOTFILES_BACKUP_HOME="$DOTFILES_STATE_HOME/backups/$DOTFILES_RUN_TIMESTAMP"
}

init_state() {
  set_state_paths
  if is_dry_run; then
    return 0
  fi
  mkdir -p "$DOTFILES_STATE_HOME"
  touch "$DOTFILES_STATE_FILE"
}

state_has() {
  local wanted_kind="$1" wanted_target="$2"
  local kind target rest
  [[ -f "$DOTFILES_STATE_FILE" ]] || return 1
  while IFS=$'\t' read -r kind target rest; do
    if [[ "$kind" == "$wanted_kind" && "$target" == "$wanted_target" ]]; then
      return 0
    fi
  done <"$DOTFILES_STATE_FILE"
  return 1
}

record_state() {
  local kind="$1" target="$2" detail="${3:-}"
  local line
  is_dry_run && return 0
  line="$(printf '%s\t%s\t%s' "$kind" "$target" "$detail")"
  if ! grep -Fqx "$line" "$DOTFILES_STATE_FILE" 2>/dev/null; then
    printf '%s\n' "$line" >>"$DOTFILES_STATE_FILE"
  fi
}

home_relative_path() {
  local target="$1"
  case "$target" in
    "$HOME"/*) printf '%s\n' "${target#"$HOME"/}" ;;
    *) die "refusing to manage a path outside HOME: $target" ;;
  esac
}

backup_move() {
  local target="$1" relative backup
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi
  relative="$(home_relative_path "$target")"
  backup="$DOTFILES_BACKUP_HOME/$relative"
  if is_dry_run; then
    print_command mkdir -p "$(dirname "$backup")"
    print_command mv "$target" "$backup"
    return 0
  fi
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  record_state backup "$target" "$backup"
  log_info "Backed up $target"
}

backup_copy_once() {
  local target="$1" relative backup
  if [[ ! -e "$target" || -L "$target" ]] || state_has block "$target"; then
    return 0
  fi
  relative="$(home_relative_path "$target")"
  backup="$DOTFILES_BACKUP_HOME/$relative"
  if is_dry_run; then
    print_command mkdir -p "$(dirname "$backup")"
    print_command cp -p "$target" "$backup"
    return 0
  fi
  mkdir -p "$(dirname "$backup")"
  cp -p "$target" "$backup"
  record_state backup "$target" "$backup"
  log_info "Backed up $target"
}

link_managed() {
  local source="$1" target="$2"
  [[ -e "$source" ]] || die "managed source does not exist: $source"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    record_state link "$target" "$source"
    log_info "Already linked $target"
    return 0
  fi

  backup_move "$target"
  run_command mkdir -p "$(dirname "$target")"
  run_command ln -s "$source" "$target"
  record_state link "$target" "$source"
  log_info "Linked $target"
}

write_generated_file() {
  local target="$1" content="$2"
  if [[ -f "$target" && "$(cat "$target")" == "$content" ]]; then
    record_state generated "$target" "$content"
    return 0
  fi
  backup_move "$target"
  if is_dry_run; then
    print_command mkdir -p "$(dirname "$target")"
    printf 'dry-run: write %q\n' "$target"
  else
    mkdir -p "$(dirname "$target")"
    printf '%s\n' "$content" >"$target"
    record_state generated "$target" "$content"
  fi
}

strip_managed_block() {
  local source="$1" destination="$2"
  local begin='# >>> sandlight-dotfiles >>>'
  local end='# <<< sandlight-dotfiles <<<'
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skipping = 1; next }
    $0 == end { skipping = 0; next }
    !skipping { print }
  ' "$source" >"$destination"
}

ensure_shell_block() {
  local target="$1" shell_name="$2" managed_file tmp
  local begin='# >>> sandlight-dotfiles >>>'
  local end='# <<< sandlight-dotfiles <<<'
  managed_file="$DOTFILES_CONFIG_HOME/${shell_name}rc"
  local source_line="[ -r \"$managed_file\" ] && . \"$managed_file\""

  if [[ -f "$target" && ! -L "$target" ]] && grep -Fq "$begin" "$target" && grep -Fq "$source_line" "$target" && grep -Fq "$end" "$target"; then
    record_state block "$target" "$begin"
    log_info "Shell hook already configured in $target"
    return 0
  fi

  if [[ -L "$target" ]]; then
    backup_move "$target"
  else
    backup_copy_once "$target"
  fi
  if is_dry_run; then
    printf 'dry-run: update managed block in %q\n' "$target"
    return 0
  fi

  mkdir -p "$(dirname "$target")" "$DOTFILES_STATE_HOME"
  tmp="$(mktemp "$DOTFILES_STATE_HOME/block.XXXXXX")"
  if [[ -f "$target" ]]; then
    strip_managed_block "$target" "$tmp"
  fi
  if [[ -s "$tmp" ]]; then
    printf '\n' >>"$tmp"
  fi
  {
    printf '%s\n' "$begin"
    printf '%s\n' "$source_line"
    printf '%s\n' "$end"
  } >>"$tmp"
  mv "$tmp" "$target"
  record_state block "$target" "$begin"
  log_info "Updated shell hook in $target"
}

remove_shell_block() {
  local target="$1" tmp
  [[ -f "$target" && ! -L "$target" ]] || return 0
  if ! grep -Fq '# >>> sandlight-dotfiles >>>' "$target"; then
    return 0
  fi
  if is_dry_run; then
    printf 'dry-run: remove managed block from %q\n' "$target"
    return 0
  fi
  tmp="$(mktemp "$DOTFILES_STATE_HOME/unblock.XXXXXX")"
  strip_managed_block "$target" "$tmp"
  if grep -q '[^[:space:]]' "$tmp"; then
    mv "$tmp" "$target"
  else
    rm -f "$tmp" "$target"
  fi
  log_info "Removed shell hook from $target"
}
