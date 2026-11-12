#!/usr/bin/env bash

# The global file `git config --global` writes to: ~/.gitconfig when it
# exists, otherwise an existing XDG config, otherwise a new ~/.gitconfig.
global_git_config_file() {
  local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
  if [[ -e "$HOME/.gitconfig" || -L "$HOME/.gitconfig" ]]; then
    printf '%s\n' "$HOME/.gitconfig"
  elif [[ -f "$xdg_config" ]]; then
    printf '%s\n' "$xdg_config"
  else
    printf '%s\n' "$HOME/.gitconfig"
  fi
}

# Put the include at the top of the global file. Git applies settings in
# order, so the project's defaults come first and anything the user has
# configured in the same file still wins. `git config --add` would append the
# include instead and silently override the user's own values.
prepend_git_include() {
  local config_file="$1" managed_config="$2" escaped tmp
  if is_dry_run; then
    printf 'dry-run: prepend include.path to %q\n' "$config_file"
    return 0
  fi
  escaped="${managed_config//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  mkdir -p "$(dirname "$config_file")" "$DOTFILES_STATE_HOME"
  tmp="$(mktemp "$DOTFILES_STATE_HOME/gitconfig.XXXXXX")"
  {
    printf '[include]\n'
    printf '\tpath = "%s"\n' "$escaped"
    if [[ -f "$config_file" ]]; then
      cat "$config_file"
    fi
  } >"$tmp"
  replace_file_content "$tmp" "$config_file"
}

install_git() {
  local managed_config="$DOTFILES_CONFIG_HOME/gitconfig"
  local legacy_ignore="$DOTFILES_CONFIG_HOME/gitignore"
  local ignore_source="$REPO_ROOT/modules/git/files/ignore"
  local config_file

  link_managed "$REPO_ROOT/modules/git/files/gitconfig" "$managed_config"

  # Git reads $XDG_CONFIG_HOME/git/ignore when core.excludesFile is unset, so
  # the project ignore list is offered there and never overrides a user's own
  # excludes file. Releases before 0.2.0 linked it elsewhere and set
  # core.excludesFile; that link is retired once it is confirmed to be ours.
  link_managed_if_free "$ignore_source" "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
  if [[ -L "$legacy_ignore" && "$(readlink "$legacy_ignore")" == "$ignore_source" ]]; then
    run_command rm "$legacy_ignore"
    log_info "Removed legacy link $legacy_ignore"
  fi
  if git config --global --get core.excludesFile >/dev/null 2>&1; then
    log_warn "core.excludesFile is set, so Git will not read the project ignore list"
  fi

  config_file="$(global_git_config_file)"
  if git config --global --fixed-value --get-all include.path "$managed_config" >/dev/null 2>&1; then
    record_state git_include "$config_file" "$managed_config"
    log_info "Git include already configured"
    return 0
  fi

  prepend_git_include "$config_file" "$managed_config"
  record_state git_include "$config_file" "$managed_config"
  log_info "Added identity-free Git include"
}
