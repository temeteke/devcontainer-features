# devcontainer-features

Personal Dev Container Features for coding agents.

This repository is organized as a generic Dev Container Feature collection, not only as an
agent-specific repository. The initial Features install and persist configuration for:

- Claude Code
- Codex
- OpenCode
- Cline
- Roo Code

**Claude Code** has an [official Dev Container Feature](https://github.com/anthropics/claude-code). This repository provides a companion Feature that adds persistence on top of the official installation.

## Usage

Publish the Features to GHCR, then add them to your **VS Code User Settings** so the setting
does not live in each project's `.devcontainer/devcontainer.json`.

```json
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/<owner>/devcontainer-features/claude-code:1": {},
    "ghcr.io/<owner>/devcontainer-features/codex:1": {},
    "ghcr.io/<owner>/devcontainer-features/opencode:1": {},
    "ghcr.io/<owner>/devcontainer-features/cline:1": {},
    "ghcr.io/<owner>/devcontainer-features/roo-code:1": {}
  }
}
```

**Claude Code** automatically pulls in the official Feature via `dependsOn`, so only the companion Feature needs to be listed.

## Design

Each Feature either installs and persists a coding agent, or adds persistence on top of an
official installation. All Features use a **bind mount** to mount the tool's standard directories
from the host home directory directly into the container, then create symlinks from the container's
home directory to the mounted paths.

The symlink approach avoids hard-coding `/home/vscode`, `/home/node`, `/home/coder`, or `/root`.

**Platform:** These Features are designed for WSL2 + Docker Desktop environments.

## Security note

These directories may contain API keys, OAuth tokens, session files, prompts, task histories, and
other sensitive data. Since they are stored directly in your host home directory (`~/.claude`,
`~/.codex`, `~/.config/opencode`, etc.), you can access and edit them directly from WSL.

## Included Features

| Feature ID | Installs | Persists |
|---|---|---|
| `claude-code` | via official Feature | `~/.claude` |
| `codex` | `@openai/codex` via npm, VS Code extension `openai.chatgpt` | `~/.codex` |
| `opencode` | `opencode-ai` via npm, VS Code extension `sst-dev.opencode` | `~/.config/opencode`, `~/.local/share/opencode` |
| `cline` | VS Code extension `saoudrizwan.claude-dev` | `~/Documents/Cline`, `~/.cline`, VS Code globalStorage |
| `roo-code` | VS Code extension `rooveterinaryinc.roo-cline` | `~/.roo`, VS Code globalStorage |

## Publishing

This repo is compatible with the Dev Container Feature publishing flow. A minimal GitHub Actions
workflow is included under `.github/workflows/release.yaml`; adjust the registry owner/repo as needed.

## Disclaimer

This repository is an unofficial collection of Dev Container Features.
It is not affiliated with, endorsed by, or maintained by OpenAI, Anthropic,
Roo Code, Cline, or OpenCode.
