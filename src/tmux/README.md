# tmux Feature

Installs tmux on Debian/Ubuntu and exposes the **host** `~/.tmux.conf`
file in the container, read-only. A symlink at the container user's
`~/.tmux.conf` points to the mounted file.

## Host configuration

This matches [temeteke/tmux-config](https://github.com/temeteke/tmux-config):
its Makefile assembles `~/.tmux.conf` and installs it in the host HOME.
There is **no need to migrate** to `~/.config/tmux/tmux.conf`.

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

Only the configuration file is shared; tmux server/socket/session state
belongs to the temporary container. The container startup script refuses
to overwrite an existing `~/.tmux.conf` file or unrelated symlink.
