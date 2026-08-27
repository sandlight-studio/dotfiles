# Contributing

Contributions should remain portable, identity-free, and safe to publish.

## Development workflow

1. Create a focused branch.
2. Add or update pure-Bash tests using a temporary `HOME`.
3. Run `bash scripts/tests/run-all.sh` and `bash scripts/check-public-safety.sh`.
4. Run ShellCheck on changed shell scripts.
5. Open a pull request describing supported platforms and manual verification.

Use Conventional Commit messages. Version numbers and release tags use bare `x.y.z` form without a `v` prefix.

Do not contribute real user identities, credentials, SSH material, private network details, or company-specific configuration. Use local override files instead.

