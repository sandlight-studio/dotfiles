# Architecture

## Installation flow

1. Parse command-line flags and load safe configuration defaults.
2. Detect macOS, supported Linux, or WSL2 before making changes.
3. Validate and normalize the module list.
4. Optionally install each module's package manifest.
5. Apply module configuration and record ownership in the state manifest.

The installer is compatible with Bash 3.2 and uses no associative arrays.

## Ownership model

Managed configuration files are symlinked to the repository. Existing targets are moved into timestamped backups before replacement. Shell startup files use marked blocks so existing user content remains intact. Git uses a single include entry and does not own the user's global identity.

The state manifest uses tab-separated records for links, backups, shell blocks, and the Git include. Uninstall consults that manifest and refuses to remove targets that are no longer owned by the project.

## Package model

Package manifests are separated by platform and module. macOS uses module-specific Brewfiles. Ubuntu, Debian, and WSL2 use newline-separated apt package lists. WSL2 applies the Linux manifest and then an optional WSL-specific supplement.

Package changes are intentionally not rolled back by `uninstall.sh`.

