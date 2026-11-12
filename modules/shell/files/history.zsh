# Zsh history hygiene: keep commands that carry a secret value out of the
# history file. Set SANDLIGHT_HISTORY_FILTER=0 (for example in local.zsh) to
# turn the filter off.
#
# A command is dropped when it carries a value, not when it merely mentions a
# word like "key" -- ssh-keygen and `rg token src/` stay. Shapes that count:
#   1. a name ending in key/token/secret/password/... followed by = or :
#      (API_KEY=..., --token=..., "password": "...", X-Api-Key: ...)
#   2. a secret-taking flag followed by its value (--password hunter2)
#   3. an Authorization header with a Bearer or Basic credential
#   4. a well-known token prefix (GitHub, GitLab, Slack, AWS, Google, OpenAI
#      style) at a word boundary, so "task-..." does not count
#   5. login and secret-reading commands
setopt HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_EXPIRE_DUPS_FIRST

_sandlight_hist_name='(key|token|secret|password|passwd|credential|auth)'
# (#i) sits outside the group: inside, it would reach only the first branch.
_sandlight_history_secret_pattern="(#i)("
# The quote class includes a backslash for JSON typed inside a quoted string.
_sandlight_history_secret_pattern+="*${_sandlight_hist_name}[\\\\\"']#[[:space:]]#[=:]?*"
_sandlight_history_secret_pattern+="|*--(password|passwd|token|secret|api-key|apikey|client-secret)[[:space:]]##[^-[:space:]]*"
_sandlight_history_secret_pattern+="|*authorization:*(bearer|basic)*"
_sandlight_history_secret_pattern+="|(|*[^a-z0-9])(sk-|ghp_|gho_|ghs_|github_pat_|glpat-|xox[abps]-|AKIA|AIza)[a-z0-9_-](#c16,)*"
_sandlight_history_secret_pattern+="|*docker login*|*npm login*|*op read*|*op item get*)"
unset _sandlight_hist_name

_sandlight_history_filter() {
  [[ "${SANDLIGHT_HISTORY_FILTER:-1}" == 0 ]] && return 0
  emulate -L zsh
  setopt extendedglob
  local line=${1%%$'\n'}
  [[ $line != ${~_sandlight_history_secret_pattern} ]]
}

autoload -Uz add-zsh-hook
add-zsh-hook zshaddhistory _sandlight_history_filter
