#!/usr/bin/env bash

install_shell() {
  local name
  for name in common.sh bashrc zshrc history.bash history.zsh; do
    link_managed "$REPO_ROOT/modules/shell/files/$name" "$DOTFILES_CONFIG_HOME/$name"
  done
  ensure_shell_block "$HOME/.bashrc" bash
  ensure_shell_block "$HOME/.zshrc" zsh
}
