# Configuration

The installer reads `${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/config.env` by default. Pass `--config FILE` to use another location. The file is sourced by Bash and must be owned and reviewed by the current user.

## Modules

`DOTFILES_MODULES` is a comma-separated list containing only `shell`, `git`, `cli`, `terminal`, and `proxy`. Unknown and duplicate modules are rejected.

Command-line `--modules` takes precedence over the configuration file.

## Local shell extensions

The shell module loads these optional, untracked files:

- `${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/local.bash`
- `${XDG_CONFIG_HOME:-$HOME/.config}/sandlight-dotfiles/local.zsh`

Use them for aliases, environment variables, SDK initialization, and machine-specific PATH entries.

## Proxy settings

The proxy module configures environment variables only. It does not install a proxy client or change operating-system network settings.

| Variable | Meaning |
| --- | --- |
| `DOTFILES_PROXY_AUTO_ENABLE` | Set to `1` to call `proxy_on` when a shell starts; default `0`. |
| `DOTFILES_PROXY_HTTP_URL` | HTTP proxy URL, for example `http://127.0.0.1:8080`. |
| `DOTFILES_PROXY_HTTPS_URL` | HTTPS proxy URL; it may use the same local HTTP endpoint. |
| `DOTFILES_PROXY_ALL_URL` | Optional SOCKS/all-proxy URL. |
| `DOTFILES_NO_PROXY` | Comma-separated bypass list. |

At least one endpoint must be configured before `proxy_on` succeeds.

