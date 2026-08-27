# shellcheck shell=bash
# Provider-neutral proxy environment helpers for Bash and Zsh.
_sandlight_proxy_config_home="${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles"
_sandlight_proxy_config="$_sandlight_proxy_config_home/config.env"
if [ -r "$_sandlight_proxy_config_home/active-config" ]; then
  IFS= read -r _sandlight_active_config <"$_sandlight_proxy_config_home/active-config"
  [ -n "$_sandlight_active_config" ] && _sandlight_proxy_config="$_sandlight_active_config"
fi
if [ -r "$_sandlight_proxy_config" ]; then
  # The configuration file is user-owned shell syntax by design.
  # shellcheck source=/dev/null
  . "$_sandlight_proxy_config"
fi

: "${DOTFILES_PROXY_AUTO_ENABLE:=0}"
: "${DOTFILES_PROXY_HTTP_URL:=}"
: "${DOTFILES_PROXY_HTTPS_URL:=}"
: "${DOTFILES_PROXY_ALL_URL:=}"
: "${DOTFILES_NO_PROXY:=localhost,127.0.0.1,::1}"

proxy_on() {
  if [ -z "$DOTFILES_PROXY_HTTP_URL$DOTFILES_PROXY_HTTPS_URL$DOTFILES_PROXY_ALL_URL" ]; then
    printf 'proxy endpoints are not configured\n' >&2
    return 1
  fi

  [ -n "$DOTFILES_PROXY_HTTP_URL" ] && export http_proxy="$DOTFILES_PROXY_HTTP_URL" HTTP_PROXY="$DOTFILES_PROXY_HTTP_URL"
  [ -n "$DOTFILES_PROXY_HTTPS_URL" ] && export https_proxy="$DOTFILES_PROXY_HTTPS_URL" HTTPS_PROXY="$DOTFILES_PROXY_HTTPS_URL"
  [ -n "$DOTFILES_PROXY_ALL_URL" ] && export all_proxy="$DOTFILES_PROXY_ALL_URL" ALL_PROXY="$DOTFILES_PROXY_ALL_URL"
  export no_proxy="$DOTFILES_NO_PROXY" NO_PROXY="$DOTFILES_NO_PROXY"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY
}

proxy_status() {
  printf 'http_proxy=%s\n' "${http_proxy:-off}"
  printf 'https_proxy=%s\n' "${https_proxy:-off}"
  printf 'all_proxy=%s\n' "${all_proxy:-off}"
  printf 'no_proxy=%s\n' "${no_proxy:-off}"
}

if [ "$DOTFILES_PROXY_AUTO_ENABLE" = "1" ]; then
  proxy_on
fi

unset _sandlight_active_config _sandlight_proxy_config _sandlight_proxy_config_home
