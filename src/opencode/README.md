# OpenCode Feature

Installs OpenCode 2 via the `@opencode/cli` npm package and persists its configuration and data directories.

This Feature also depends on the shared `agents` Feature, which makes `~/.agents` available for
skills and related state.

## Options

- `install`: default `true`
- `persist`: default `true`
- `cache`: default `true`
- `warmup`: default `true`
- `version`: `@opencode/cli` npm package version, default `latest`

## Persisted paths

- `~/.config/opencode`
- `~/.local/share/opencode`

Both directories are bind-mounted from the host. The data directory is shared so provider
authentication is reused across containers.

The plugin cache is stored in the Docker volume `devcontainer-opencode-npm-cache` and linked at
`~/.cache/opencode/npm`. The volume is shared by every Dev Container on the Docker host that uses
this Feature. `~/.cache/opencode/bin` is not shared.

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

## Startup warm-up

Plugins declared in `opencode.jsonc` are installed and loaded when the OpenCode service starts.
During that period `/api/provider`, `/api/model`, and `/api/agent` can return 503. A TUI that starts
immediately can time out before models become available.

When `warmup` is enabled, the Feature waits for `/api/provider` to return successfully in both
`postCreateCommand` and `postStartCommand`. The timeout is 120 seconds by default. Set
`OPENCODE_WARMUP_TIMEOUT` in `containerEnv` to change it. This is useful
for `dcs opencode` and other setups that run `opencode` immediately after `devcontainer up`: the
Feature lifecycle command finishes before the container command starts.

Set `warmup: false` to skip the wait. In that case, run `opencode models` once before opening the
TUI, or reopen the TUI after the service becomes ready.

## Plugin cache

`~/.cache/opencode/npm` is shared through the fixed Docker volume
`devcontainer-opencode-npm-cache`. This avoids downloading and extracting the plugin packages
again when a new container is created.

- The volume is shared across all containers on the Docker host, including different projects.
- Concurrent containers can install or load plugins at the same time.
- The cache can grow across plugin and OpenCode versions. Remove it when needed:

```sh
docker volume rm devcontainer-opencode-npm-cache
```

The Feature creates the volume target with the container user as owner (falling back to mode 0777).
If the volume already exists with the wrong ownership, remove it once and recreate the container.

The cache keeps downloaded plugin code. Any container with access to the volume can read and
modify it, so treat the cache as trusted input. Do not share it with untrusted projects.

Set `cache: false` to skip the symlink. The volume mount itself is still applied by the Feature;
only `~/.cache/opencode/npm` is left container-local.

## Security

Containers with access to these directories can read and modify credentials, settings, and cached
plugin code. Enable this Feature only for projects you trust.

## Shared dependency

- `agents` -> `~/.agents`
