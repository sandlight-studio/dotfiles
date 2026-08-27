#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  printf 'public-safety check requires a Git work tree\n' >&2
  exit 1
}

failed=0

if git ls-files | rg '(^|/)(authorized_keys|allowed_signers|id_(rsa|dsa|ecdsa|ed25519)(\.pub)?|.*\.pem)$'; then
  printf 'unsafe identity or key filename is tracked\n' >&2
  failed=1
fi

if git grep -nI -E '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|op://|/Users/|/home/[A-Za-z0-9._-]+/)' -- . ':(exclude)scripts/check-public-safety.sh'; then
  printf 'private material or a machine-specific absolute path was found\n' >&2
  failed=1
fi

email_matches="$(git grep -nI -E '[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' -- . ':(exclude)LICENSE' || true)"
unsafe_emails="$(printf '%s\n' "$email_matches" | rg -v '@example\.(com|org|net)' || true)"
if [[ -n "$unsafe_emails" ]]; then
  printf '%s\n' "$unsafe_emails"
  printf 'tracked contact data was found; use reserved placeholders or GitHub issues\n' >&2
  failed=1
fi

if git ls-files | rg '(^|/)(config\.local\.env|[^/]*\.local\.env|\.env)$'; then
  printf 'a local override file is tracked\n' >&2
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

printf 'Public-safety checks passed.\n'
