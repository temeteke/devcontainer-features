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
- GitLab CLI

**Claude Code** has an [official Dev Container Feature](https://github.com/anthropics/devcontainer-features). This repository provides a companion Feature that adds persistence on top of the official installation.

## Shared Features

- Shared agents directory

## Usage

Publish the Features to GHCR first, then paste the following into your **VS Code User Settings**.
This keeps the setting out of each project's `.devcontainer/devcontainer.json`.

```json
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/temeteke/devcontainer-features/claude-code:0": {},
    "ghcr.io/temeteke/devcontainer-features/codex:0": {},
    "ghcr.io/temeteke/devcontainer-features/opencode:0": {},
    "ghcr.io/temeteke/devcontainer-features/cline:0": {},
    "ghcr.io/temeteke/devcontainer-features/roo-code:0": {},
    "ghcr.io/temeteke/devcontainer-features/playwright:0": {},
    "ghcr.io/temeteke/devcontainer-features/gitlab-cli:0": {}
  }
}
```

**Claude Code** automatically pulls in the official Feature via `dependsOn`, so only the companion Feature needs to be listed.

**OpenCode** also pulls in the shared `agents` Feature via `dependsOn`, so you do not need to list
`agents` separately unless you want `~/.agents` without OpenCode.

If you want only the shared `~/.agents` directory, add this feature by itself:

```json
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/temeteke/devcontainer-features/agents:0": {}
  }
}
```

This collection is still in `0.x`, so pin the major channel with `:0`. When the collection reaches `1.0`, switch the references to `:1`.

## Design

Each Feature either installs and persists a coding agent, or adds persistence on top of an
official installation. All Features use a **bind mount** to mount the tool's standard directories
from the host home directory directly into the container, then create symlinks from the container's
home directory to the mounted paths.

The symlink approach avoids hard-coding `/home/vscode`, `/home/node`, `/home/coder`, or `/root`.

**Platform:** These Features use `${localEnv:HOME}` for bind mounts, so they work on any platform
where Docker can access the host filesystem (Linux, macOS, Windows with Docker Desktop, WSL2, etc.).

## Security note

These directories may contain API keys, OAuth tokens, session files, prompts, task histories, and
other sensitive data. Since they are stored directly in your host home directory (`~/.claude`,
`~/.codex`, `~/.agents`, `~/.config/opencode`, `~/.config/glab-cli`, etc.), you can access and edit them directly from the host.

## Included Features

| Feature ID | Installs | Persists |
|---|---|---|
| `claude-code` | Coding tool via official Feature | `~/.claude` |
| `codex` | Coding tool: `@openai/codex` via npm, VS Code extension `openai.chatgpt` | `~/.codex` |
| `opencode` | Coding tool: `opencode-ai` via npm, VS Code extension `sst-dev.opencode` | `~/.config/opencode`, `~/.local/share/opencode`, `~/.agents` via `agents` |
| `cline` | Coding tool: VS Code extension `saoudrizwan.claude-dev` | `~/Documents/Cline`, `~/.cline` |
| `roo-code` | Coding tool: VS Code extension `rooveterinaryinc.roo-cline` | `~/.roo`, VS Code globalStorage |
| `playwright` | AI agent tool: Playwright Agent CLI and browser runtime only | none |
| `gitlab-cli` | Coding tool: `glab` CLI from GitLab releases | `~/.config/glab-cli` |
| `agents` | Shared feature for agent skills/state only | `~/.agents` |

## Publishing

This repo is compatible with the Dev Container Feature publishing flow. A minimal GitHub Actions
workflow is included under `.github/workflows/release.yaml`; adjust the registry owner/repo if you
fork the repository.

## Disclaimer

This repository is an unofficial collection of Dev Container Features.
It is not affiliated with, endorsed by, or maintained by OpenAI, Anthropic,
Roo Code, Cline, OpenCode, or GitLab.
