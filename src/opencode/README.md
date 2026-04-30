# OpenCode Feature

Installs OpenCode and persists its configuration and data directories.

This feature also depends on the shared `agents` feature, which makes `~/.agents` available for
skills and related state.

## Options

- `install`: default `true`
- `persist`: default `true`
- `version`: npm package version, default `latest`

## Persisted paths

- `~/.config/opencode`
- `~/.local/share/opencode`

## Shared dependency

- `agents` -> `~/.agents`
