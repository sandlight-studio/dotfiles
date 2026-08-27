#!/usr/bin/env bash

install_proxy() {
  link_managed "$REPO_ROOT/modules/proxy/files/proxy.sh" "$DOTFILES_CONFIG_HOME/proxy.sh"
}

