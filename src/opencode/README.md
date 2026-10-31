# OpenCode Feature

Installs OpenCode 2 via the `@opencode/cli` npm package and persists its configuration and data directories.

This Feature also depends on the shared `agents` Feature, which makes `~/.agents` available for
skills and related state.

## Options

- `install`: default `true`
- `persist`: default `true`
- `version`: `@opencode/cli` npm package version, default `latest`

## Persisted paths

- `~/.config/opencode`
- `~/.local/share/opencode`

Both directories are bind-mounted from the host. The data directory is shared so provider
authentication is reused across containers.

## Config directory handling

The Feature sets `OPENCODE_CONFIG_DIR` to the mounted config path:

```text
OPENCODE_CONFIG_DIR=/mnt/devcontainer-features/opencode/config
```

OpenCode reads the real mounted directory instead of the `~/.config/opencode` symlink. This avoids
the config watcher failure when the config directory is a symlink:
https://github.com/anomalyco/opencode/issues/54933

It also makes the config available from container startup, before `postCreateCommand` creates the
symlink. The `~/.config/opencode` symlink is still created for tools and extensions that expect it.

## Security

Containers with access to these directories can read and modify credentials and settings. Enable
this Feature only for projects you trust.

## Shared dependency

- `agents` -> `~/.agents`
