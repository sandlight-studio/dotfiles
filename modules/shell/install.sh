#!/usr/bin/env bash

install_shell() {
  link_managed "$REPO_ROOT/modules/shell/files/common.sh" "$DOTFILES_CONFIG_HOME/common.sh"
  link_managed "$REPO_ROOT/modules/shell/files/bashrc" "$DOTFILES_CONFIG_HOME/bashrc"
  link_managed "$REPO_ROOT/modules/shell/files/zshrc" "$DOTFILES_CONFIG_HOME/zshrc"
  ensure_shell_block "$HOME/.bashrc" bash
  ensure_shell_block "$HOME/.zshrc" zsh
}

