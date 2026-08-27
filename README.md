# Sandlight Dotfiles

A small, public-safe dotfiles toolkit for macOS, Ubuntu/Debian Linux, and WSL2. It uses defensive Bash, opt-in modules, and local overrides instead of machine-specific profiles.

## Platform support

| Platform | Status | Package manager |
| --- | --- | --- |
| macOS | Supported | Homebrew |
| Ubuntu 24.04+ | Supported | apt |
| Debian 12+ | Supported | apt |
| WSL2 with Ubuntu/Debian | Supported | apt |
| Native Windows | Not supported in 0.1.0 | — |

## Quick start

```bash
git clone https://github.com/sandlight-studio/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
./install.sh
```

Configuration is optional. To customize modules or proxy endpoints:

```bash
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles"
cp config/config.env.example "${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/config.env"
${EDITOR:-vi} "${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/config.env"
./install.sh --dry-run
./install.sh
```

Package installation is always explicit:

```bash
./install.sh --with-packages
```

The installer does not bootstrap Homebrew. Install Homebrew first on macOS if package installation is requested.

## Modules

The default module set is `shell,git,cli`.

| Module | Behavior |
| --- | --- |
| `shell` | Adds managed Bash and Zsh source blocks with portable PATH helpers and local extension hooks. |
| `git` | Adds an identity-free Git include without changing name, email, signing, or credentials. |
| `cli` | Provides aliases and integration for portable command-line tools when installed. |
| `terminal` | Installs neutral tmux and Starship configuration. |
| `proxy` | Provides opt-in, provider-neutral `proxy_on`, `proxy_off`, and `proxy_status` helpers. |

Select modules in `config.env` or for one installation:

```bash
./install.sh --modules shell,git,cli,terminal,proxy
```

## Safe ownership and rollback

Conflicting managed files are backed up below `${XDG_STATE_HOME:-$HOME/.local/state}/sandlight-dotfiles/backups/`. The state manifest records every managed link, shell block, and Git include.

```bash
./uninstall.sh --dry-run
./uninstall.sh
```

Uninstall removes only content still owned by this project. It does not remove packages.

## Development

```bash
bash scripts/tests/run-all.sh
bash scripts/check-public-safety.sh
```

See [configuration](docs/CONFIGURATION.md), [architecture](docs/ARCHITECTURE.md), and [security](SECURITY.md) for details.

## License

Apache-2.0

