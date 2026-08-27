# Repository Working Agreement

## Scope

Keep this repository portable across macOS, Ubuntu/Debian, and WSL2. Store machine-specific behavior in untracked local overrides.

## Shell conventions

- Use `#!/usr/bin/env bash` and `set -euo pipefail` for executable scripts.
- Remain compatible with Bash 3.2; do not use associative arrays or newer-only syntax.
- Quote expansions and prefer small, testable helpers.
- Preserve dry-run, idempotency, backup, and ownership guarantees.

## Verification

Run `bash scripts/tests/run-all.sh`, `bash scripts/check-public-safety.sh`, and ShellCheck before merging.

## Public-safety rule

Never commit real identities, credentials, SSH material, internal endpoints, absolute machine paths, or local overrides. Documentation and comments are written in English.

