# devcontainer-features

Personal Dev Container Features for coding agents and developer tools.

This repository is organized as a generic Dev Container Feature collection, not only as an
agent-specific repository. It provides the following features:

## Coding Tools

- Claude Code
- Codex
- OpenCode
- Cline
- Roo Code
- Playwright Agent CLI
- GitHub CLI
- GitLab CLI
- tmux
- Vim

**Claude Code** has an [official Dev Container Feature](https://github.com/anthropics/devcontainer-features). This repository provides a companion Feature that adds persistence on top of the official installation.

## Kubernetes Tools

- kubectl
- Helmfile (installs Helm and helm-diff)

## Shared Features

- Shared agents directory
- Git config (host inheritance and `gh` / `glab` credential helpers)

## Usage

Add Features to `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/codex:0": {},
    "ghcr.io/temeteke/devcontainer-features/github-cli:0": {},
    "ghcr.io/temeteke/devcontainer-features/gitlab-cli:0": {
      "version": "1.126.0"
    }
  }
}
```

Persistence Features mount the corresponding directory from your host home. Create it
before opening the container if it does not exist (for example,
`mkdir -p ~/.codex ~/.config/gh ~/.config/glab-cli`). The `git-config` Feature also requires
`~/.gitconfig` on the host; create an empty file with `touch ~/.gitconfig` if needed.

In the standard single-container Dev Containers path, a missing bind-mount source can prevent the
container from starting. With Docker Compose it may instead create a directory on the host. Create
the host paths before opening the container.

## Design

Each Feature either installs a tool, persists a coding agent, or adds persistence on top of an
official installation. Features that persist state use a **bind mount** to mount the tool's
standard directories from the host home directory into the container, then create symlinks from
the container's home directory to the mounted paths.

If the container already has a directory, file, or symlink at the link destination (and it is
not already the expected link), it is moved to `<path>.devcontainer-backup` (or a numbered name
such as `<path>.devcontainer-backup.1` if that exists) before the symlink is created. Empty
directories are removed. Container data is never copied into the host directory. Mount points
and paths under non-root mounts are left untouched, and no symlink is created for them. If the
mount cannot be determined, the symlink is skipped rather than risking host data.

Backups are created inside the container and are not preserved across rebuilds. Copy them
elsewhere first if you need to keep them.

The `tmux` and `vim` Features are stricter: they refuse to replace existing container
configuration instead of moving it aside.

If `$HOME` itself is a volume or bind mount, the target is treated as a mount and the symlink
is skipped. `persist: false` only skips the symlink; Feature mounts are always applied, so the
host directory is still visible inside the container.

The symlink approach avoids hard-coding `/home/vscode`, `/home/node`, `/home/coder`, or `/root`.

**Platform:** Persistence Features use `${localEnv:HOME}` for bind mounts. They work where
`HOME` is set and Docker can access the host filesystem (Linux, macOS, and WSL2). Native Windows
requires `HOME` to be set explicitly.

## Git configuration inheritance

The `git-config` Feature (installed automatically by `github-cli` and `gitlab-cli`) mounts the
host `~/.gitconfig` and writes a managed container `~/.gitconfig`:

- Host settings are inherited except for host-specific credentials, paths, editors, signing,
  hooks, filters, and OS/network settings. See
  [`src/git-config/README.md`](src/git-config/README.md) for the full list.
- An existing container `~/.gitconfig` is preserved as `~/.gitconfig.devcontainer` and included
  after the host settings, so container-specific settings take precedence.
- `gh` and `glab` are appended as credential helpers when installed. Existing container helpers
  are tried first; host credential helpers are never inherited.
- The host `~/.gitconfig` must exist. In the standard single-container Dev Containers path, a
  missing bind-mount source can prevent the container from starting; create it with
  `touch ~/.gitconfig`. Only that file is mounted, so `~/.gitconfig.local` and other includes are
  inherited only when they resolve to existing paths inside the container.
- `gh` and `glab` tokens stored in a host OS keyring cannot be read from the container. Run the
  login command inside the container once, or provide `GH_TOKEN` / `GITLAB_TOKEN` via
  `containerEnv`.

## Security note

These directories may contain API keys, OAuth tokens, session files, prompts, task histories, and
other sensitive data. Since they are stored directly in your host home directory (`~/.claude`,
`~/.codex`, `~/.agents`, `~/.config/opencode`, `~/.config/gh`, `~/.config/glab-cli`, `~/.gitconfig`,
`~/.kube`, etc.), you can access and edit them directly from the host.

In particular, `~/.kube` can contain cluster credentials and client certificates. It is mounted
read-write so `kubectl` can update contexts and caches. Enable the `kubectl` Feature only for
projects you trust.

The host `~/.gitconfig` is mounted read-write. The `git-config` Feature filters sensitive keys
from the generated `~/.gitconfig`, but container processes can read **and modify** the original
mounted file. Modifications can add host-executed settings such as `core.sshCommand`,
`core.hooksPath`, or aliases. Feature mounts cannot be read-only. If you need inheritance without
write access, use a Docker Compose volume with the `:ro` option or mount a host-generated config
read-only. Do not enable it for untrusted projects if your host git config contains tokens or
other secrets.

Container processes can also read `~/.config/gh`, `~/.config/glab-cli`, and the host
`.gitconfig`, and can extract tokens (for example with `git credential fill`). Enable these
Features only for projects you trust.

## Included Features

| Feature ID | Installs | Persists |
|---|---|---|
| `claude-code` | Coding tool via official Feature | `~/.claude` |
| `codex` | Coding tool: `@openai/codex` via npm, VS Code extension `openai.chatgpt` | `~/.codex` |
| `opencode` | Coding tool: `@opencode/cli` (OpenCode 2) via npm, VS Code extension `sst-dev.opencode` | `~/.config/opencode`, `~/.local/share/opencode`, `~/.agents` via `agents` |
| `cline` | Coding tool: VS Code extension `saoudrizwan.claude-dev` | `~/Documents/Cline`, `~/.cline` |
| `roo-code` | Coding tool: VS Code extension `rooveterinaryinc.roo-cline` | `~/.roo`, VS Code globalStorage |
| `playwright` | AI agent tool: Playwright Agent CLI and browser runtime only | none |
| `github-cli` | Coding tool: official GitHub CLI Feature | `~/.config/gh` |
| `gitlab-cli` | Coding tool: `glab` CLI from GitLab releases | `~/.config/glab-cli` |
| `kubectl` | Kubernetes tool: `kubectl` from Kubernetes releases | `~/.kube` |
| `helmfile` | Kubernetes tool: `helmfile`, Helm, and `helm-diff` | none |
| `agents` | Shared feature for agent skills/state only | `~/.agents` |
| `git-config` | Shared feature: host `~/.gitconfig` inheritance and `gh` / `glab` credential helpers | none (inherits host `~/.gitconfig`) |
| `tmux` | `tmux` via apt (Debian/Ubuntu) | read-write `~/.tmux.conf` |
| `vim` | `vim` via apt (Debian/Ubuntu) | read-write `~/.vimrc`, `~/.vim` |

## Publishing

This repo is compatible with the Dev Container Feature publishing flow. A minimal GitHub Actions
workflow is included under `.github/workflows/release.yaml`; adjust the registry owner/repo if you
fork the repository.

## Disclaimer

This repository is an unofficial collection of Dev Container Features.
It is not affiliated with, endorsed by, or maintained by OpenAI, Anthropic,
Roo Code, Cline, OpenCode, GitHub, or GitLab.

## Terminal Features

The `tmux` Feature installs tmux and shares the host's `~/.tmux.conf`
file. The `vim` Feature installs Vim and shares `~/.vimrc` and `~/.vim/`.
These mounts are read-write because Feature metadata does not support
read-only bind mount properties. This supports standard dotfile layouts,
including Vim configurations that install plugins or write undo data under
`~/.vim/`.

Before starting a Dev Container, ensure the corresponding host paths exist.
A missing bind-mount source may prevent the container from starting.
These Features do not mount the entire host HOME directory.

All shared configuration paths are writable by container processes, including
`~/.tmux.conf`, `~/.vimrc`, and `~/.vim/`. Review this security tradeoff
before using these Features with untrusted code.

See [`src/tmux/README.md`](src/tmux/README.md) and
[`src/vim/README.md`](src/vim/README.md) for details.
