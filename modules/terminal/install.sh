#!/usr/bin/env bash

install_terminal() {
  link_managed "$REPO_ROOT/modules/terminal/files/starship.toml" "$HOME/.config/starship.toml"
  link_managed "$REPO_ROOT/modules/terminal/files/tmux.conf" "$HOME/.tmux.conf"
}

