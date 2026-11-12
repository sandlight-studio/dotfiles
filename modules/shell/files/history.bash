# shellcheck shell=bash
# Bash history hygiene. HISTIGNORE holds colon-separated whole-line globs, so
# this is a smaller, case-sensitive version of history.zsh: it catches NAME=value
# assignments, secret-taking flags, and well-known token prefixes. Set
# SANDLIGHT_HISTORY_FILTER=0 before this file is read to turn it off.
if [ "${SANDLIGHT_HISTORY_FILTER:-1}" != 0 ]; then
  case ":${HISTCONTROL:-}:" in
    *:ignorespace:*|*:ignoreboth:*) ;;
    *) HISTCONTROL="${HISTCONTROL:+$HISTCONTROL:}ignorespace" ;;
  esac
  _sandlight_hist_ignore='*[A-Z_]KEY=*:*[A-Z_]TOKEN=*:*[A-Z_]SECRET=*:*PASSWORD=*'
  _sandlight_hist_ignore+=':*_key=*:*_token=*:*_secret=*:*password=*'
  _sandlight_hist_ignore+=':*--password[= ]*:*--token[= ]*:*--secret[= ]*:*--api-key[= ]*'
  _sandlight_hist_ignore+=':*[Aa]uthorization*[Bb]earer *:*[Aa]uthorization*[Bb]asic *'
  _sandlight_hist_ignore+=':*ghp_*:*github_pat_*:*glpat-*:*xox[abps]-*'
  _sandlight_hist_ignore+=':*docker login*:*npm login*:*op read*:*op item get*'
  case ":${HISTIGNORE:-}:" in
    *":$_sandlight_hist_ignore:"*) ;;
    *) HISTIGNORE="${HISTIGNORE:+$HISTIGNORE:}$_sandlight_hist_ignore" ;;
  esac
  unset _sandlight_hist_ignore
fi
