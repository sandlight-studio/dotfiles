#!/usr/bin/env bash

install_git() {
  local managed_config="$DOTFILES_CONFIG_HOME/gitconfig"
  link_managed "$REPO_ROOT/modules/git/files/gitconfig" "$managed_config"
  link_managed "$REPO_ROOT/modules/git/files/ignore" "$DOTFILES_CONFIG_HOME/gitignore"

  if git config --global --fixed-value --get-all include.path "$managed_config" >/dev/null 2>&1; then
    record_state git_include "$HOME/.gitconfig" "$managed_config"
    log_info "Git include already configured"
    return 0
  fi

  run_command git config --global --add include.path "$managed_config"
  record_state git_include "$HOME/.gitconfig" "$managed_config"
  log_info "Added identity-free Git include"
}

