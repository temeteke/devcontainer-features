# OpenCode Feature

Installs OpenCode 2 via the `@opencode/cli` npm package and persists its configuration and data directories.

This feature also depends on the shared `agents` feature, which makes `~/.agents` available for
skills and related state.

## Options

- `install`: default `true`
- `persist`: default `true`
- `version`: `@opencode/cli` npm package version, default `latest`

## Persisted paths

- `~/.config/opencode`
- `~/.local/share/opencode`

Both directories are bind-mounted from the host and shared with the Dev Container.
The data directory contains the OpenCode 2 SQLite session database and saved credentials.
Containers with access to this directory can read and modify that sensitive data.
Use compatible OpenCode versions on the host and in containers; avoid running a
version upgrade or database migration concurrently in both environments.

## Shared dependency

- `agents` -> `~/.agents`
