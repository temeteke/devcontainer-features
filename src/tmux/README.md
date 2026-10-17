# tmux Feature

Installs tmux on Debian/Ubuntu and exposes the **host** `~/.tmux.conf`
file in the container (read-write bind mount). A symlink at the container user's
`~/.tmux.conf` points to the mounted file.

## Host configuration

The Feature uses tmux's conventional `~/.tmux.conf` configuration file.
It does not mount `~/.config/tmux/` or other host configuration paths.

Before building/starting the Dev Container, make sure `~/.tmux.conf`
is a regular file or a resolvable symlink to a file on the host. A missing
file bind mount cannot be skipped dynamically; the container may fail to start.

## Usage

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/tmux:0": {}
  }
}
```

Dev Container Feature metadata cannot declare read-only bind mounts, so
container processes can also **modify the host's** `~/.tmux.conf`.

Only the configuration file is shared; tmux server/socket/session state
belongs to the temporary container. The container startup script refuses
to overwrite an existing `~/.tmux.conf` file or unrelated symlink.
