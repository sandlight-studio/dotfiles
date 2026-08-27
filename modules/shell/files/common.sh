# shellcheck shell=bash
# Shared interactive shell configuration for Bash and Zsh.

path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
  export PATH
}

path_prepend "$HOME/.local/bin"

export EDITOR="${EDITOR:-vi}"
export PAGER="${PAGER:-less}"

if command -v zoxide >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(zoxide init zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(zoxide init bash)"
  fi
fi

if command -v starship >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(starship init zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$(starship init bash)"
  fi
fi

_sandlight_config_home="${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles"
# shellcheck source=/dev/null
[ -r "$_sandlight_config_home/cli.sh" ] && . "$_sandlight_config_home/cli.sh"
# shellcheck source=/dev/null
[ -r "$_sandlight_config_home/proxy.sh" ] && . "$_sandlight_config_home/proxy.sh"
unset _sandlight_config_home
