# shellcheck shell=bash
# Aliases activate only when their backing command exists.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first'
  alias la='eza -la --group-directories-first'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa --group-directories-first'
  alias ll='exa -l --group-directories-first'
  alias la='exa -la --group-directories-first'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# fzf key bindings and completion. fzf 0.48+ prints its own integration;
# older Debian and Ubuntu packages ship the same scripts as examples.
if command -v fzf >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    _sandlight_shell=zsh
  elif [ -n "${BASH_VERSION:-}" ]; then
    _sandlight_shell=bash
  else
    _sandlight_shell=""
  fi
  if [ -n "$_sandlight_shell" ]; then
    if _sandlight_fzf_init="$(fzf "--$_sandlight_shell" 2>/dev/null)"; then
      eval "$_sandlight_fzf_init"
    else
      for _sandlight_fzf_file in \
        "/usr/share/doc/fzf/examples/key-bindings.$_sandlight_shell" \
        "/usr/share/doc/fzf/examples/completion.$_sandlight_shell"; do
        # shellcheck source=/dev/null
        [ -r "$_sandlight_fzf_file" ] && . "$_sandlight_fzf_file"
      done
    fi
  fi
  unset _sandlight_shell _sandlight_fzf_init _sandlight_fzf_file
fi
