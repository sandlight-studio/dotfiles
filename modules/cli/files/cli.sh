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
