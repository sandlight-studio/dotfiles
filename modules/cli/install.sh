#!/usr/bin/env bash

install_cli() {
  link_managed "$REPO_ROOT/modules/cli/files/cli.sh" "$DOTFILES_CONFIG_HOME/cli.sh"
}

