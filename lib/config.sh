#!/usr/bin/env bash

set_config_defaults() {
  DOTFILES_MODULES="shell,git,cli"
  DOTFILES_PROXY_AUTO_ENABLE=0
  DOTFILES_PROXY_HTTP_URL=""
  DOTFILES_PROXY_HTTPS_URL=""
  DOTFILES_PROXY_ALL_URL=""
  DOTFILES_NO_PROXY="localhost,127.0.0.1,::1"
}

is_supported_module() {
  case "$1" in
    shell|git|cli|terminal|proxy) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_modules() {
  local raw="$1" module normalized="" seen=","
  local -a modules
  IFS=',' read -r -a modules <<<"$raw"
  [[ "${#modules[@]}" -gt 0 ]] || die "at least one module must be selected"

  for module in "${modules[@]}"; do
    module="${module//[[:space:]]/}"
    [[ -n "$module" ]] || die "empty module name in: $raw"
    is_supported_module "$module" || die "unsupported module: $module"
    case "$seen" in
      *",$module,"*) die "duplicate module: $module" ;;
    esac
    seen="${seen}${module},"
    if [[ -n "$normalized" ]]; then
      normalized="$normalized,$module"
    else
      normalized="$module"
    fi
  done
  DOTFILES_MODULES="$normalized"
}

validate_proxy_url() {
  local name="$1" value="$2"
  [[ -z "$value" ]] && return 0
  case "$value" in
    http://*|https://*|socks://*|socks5://*) return 0 ;;
    *) die "$name must be empty or a supported proxy URL" ;;
  esac
}

load_config() {
  local config_file="$1"
  set_config_defaults
  if [[ -f "$config_file" ]]; then
    # The configuration file is user-owned shell syntax by design.
    # shellcheck source=/dev/null
    source "$config_file"
  fi
  normalize_modules "$DOTFILES_MODULES"
  case "$DOTFILES_PROXY_AUTO_ENABLE" in
    0|1) ;;
    *) die "DOTFILES_PROXY_AUTO_ENABLE must be 0 or 1" ;;
  esac
  validate_proxy_url DOTFILES_PROXY_HTTP_URL "$DOTFILES_PROXY_HTTP_URL"
  validate_proxy_url DOTFILES_PROXY_HTTPS_URL "$DOTFILES_PROXY_HTTPS_URL"
  validate_proxy_url DOTFILES_PROXY_ALL_URL "$DOTFILES_PROXY_ALL_URL"
  export DOTFILES_MODULES DOTFILES_PROXY_AUTO_ENABLE DOTFILES_PROXY_HTTP_URL
  export DOTFILES_PROXY_HTTPS_URL DOTFILES_PROXY_ALL_URL DOTFILES_NO_PROXY
}

module_is_enabled() {
  local wanted="$1" module
  local -a modules
  IFS=',' read -r -a modules <<<"$DOTFILES_MODULES"
  for module in "${modules[@]}"; do
    if [[ "$module" == "$wanted" ]]; then
      return 0
    fi
  done
  return 1
}
