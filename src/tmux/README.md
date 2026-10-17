# tmux Feature

Installs tmux on Debian/Ubuntu and shares the **host** `~/.config/tmux` directory
with the container **read-only**. The container's `~/.config/tmux` is a symlink
to that bind mount. tmux reads `~/.config/tmux/tmux.conf` natively.

## One-time host setup

Run this on the host **before** creating the dev container (Docker bind mounts
require their source directory to exist):

```sh
mkdir -p ~/.config/tmux
```

If you currently use `~/.tmux.conf`, move it to
`~/.config/tmux/tmux.conf` after checking the destination does not already
exist. The legacy dotfile itself is deliberately *not* bind-mounted: a bind mount
of a missing host file can fail, and mounting the host HOME would expose unrelated
data. If your configuration references plugins in `~/.tmux`, relocate or configure
those references under `~/.config/tmux` as well.

## Usage

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/tmux:0": {}
  }
}
```

Only configuration is shared: tmux servers, sockets and sessions are not
persisted when the container is removed. Host configuration is read-only from
inside the container; plugins that need to update themselves must be managed on
the host. If the image already has a nonempty `~/.config/tmux`, setup fails
rather than destroying that container-side data.
