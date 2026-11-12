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

The zsh payload runs `compinit` unless a framework earlier in `~/.zshrc` already did, and keeps the completion dump in `${XDG_CACHE_HOME:-$HOME/.cache}/sandlight-dotfiles/`.

## History filter

The shell module keeps commands that carry a secret value out of shell history. It is on by default. In zsh, a command is dropped when it contains:

- a name ending in `key`, `token`, `secret`, `password`, `credential`, or `auth` followed by `=` or `:` (`API_KEY=...`, `--token=...`, `X-Api-Key: ...`);
- a secret-taking flag followed by a value (`--password hunter2`);
- an `Authorization: Bearer` or `Basic` header;
- a well-known token prefix such as `ghp_`, `github_pat_`, `glpat-`, `xoxb-`, `AKIA`, `AIza`, or `sk-`;
- `docker login`, `npm login`, `op read`, or `op item get`.

Commands that only mention such words, like `ssh-keygen` or `rg token src/`, are kept. Bash uses a smaller, case-sensitive `HISTIGNORE` list and adds `ignorespace` to `HISTCONTROL`. In both shells a command typed with a leading space is not recorded.

Set `SANDLIGHT_HISTORY_FILTER=0` to turn the filter off: in `local.zsh` for zsh, or in `~/.bashrc` before the managed block for Bash.

## Git

The managed include is added at the top of the global Git config, so a value you set there overrides the project default. It sets `init.defaultBranch`, `user.useConfigOnly`, `pull.ff=only`, `fetch.prune`, `push.autoSetupRemote`, `merge.conflictStyle=zdiff3`, and delta as pager with `less` as the fallback. It never sets an identity, signing, or credentials.

The project ignore list is linked to `${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore`, which Git reads when `core.excludesFile` is unset. An existing file at that path is kept as it is.

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

