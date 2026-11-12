# Changelog

All notable changes to this project are documented here.

## [0.2.0] - 2026-11-12

### Fixed

- Shell blocks are written through the existing rc file, so `~/.bashrc` and `~/.zshrc` keep their mode and hard links instead of becoming mode 0600.
- Removing the managed block also removes the blank line added before it, so install and uninstall cycles leave rc files byte-for-byte unchanged.
- The Git include no longer sets `core.excludesFile`, which replaced any global ignore file the user had and ignored `XDG_CONFIG_HOME`. The ignore list is linked to `$XDG_CONFIG_HOME/git/ignore` only when that path is free, and the old link is removed.
- The Git include is prepended to the global config, so user values win over project defaults. Existing installs keep their appended include until reinstalled with `./uninstall.sh && ./install.sh`. Uninstall removes the empty `[include]` header it used to leave.

### Added

- History filter for secret values in zsh, with a smaller `HISTIGNORE` version for Bash. On by default; `SANDLIGHT_HISTORY_FILTER=0` disables it.
- zsh completion through `compinit`, skipped when a framework already ran it, with a duplicate-free, shell-local `FPATH`.
- fzf key bindings and completion, with a fallback for the older fzf in Debian 12 and Ubuntu 24.04.
- Git defaults: `user.useConfigOnly`, `merge.conflictStyle=zdiff3`, and delta as pager with a `less` fallback. `git-delta` joins the macOS Brewfile.
- tmux: vi copy mode with pbcopy, xclip, wl-copy, or clip.exe, OSC 52 clipboard, splits in the current directory, pane navigation, and `escape-time 0`.
- `--strict-packages`. Without it, a failed package install is summarized and the run exits 2 after configuration is applied.

### Changed

- CI pins `actions/checkout` to a commit, cancels superseded runs, sets job timeouts, and lints the extensionless shell payloads.

## [0.1.1] - 2026-08-27

### Changed

- Replaced the README Mermaid diagram with a real terminal screenshot.

## [0.1.0] - 2026-08-27

### Added

- Public-safe modular Bash installer and rollback support.
- macOS, Ubuntu/Debian, and WSL2 platform adapters.
- Shell, Git, CLI, terminal, and provider-neutral proxy modules.
- Automated portability, idempotency, privacy, and secret-scanning checks.

