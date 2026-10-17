# Vim Feature

Installs the full `vim` package (not `vim-tiny`) on Debian/Ubuntu and shares
the **host** `~/.vim` directory with the container **read-only**. The
container's `~/.vim` is a symlink to that bind mount.

Vim reads `~/.vim/vimrc` and loads plugins from this directory.

## One-time host setup

Run this on the host **before** creating the dev container (Docker bind mounts
require their source directory to exist):

```sh
mkdir -p ~/.vim
```

If you currently use `~/.vimrc`, move it to `~/.vim/vimrc` after checking
that the destination does not already exist. The legacy dotfile itself is
deliberately *not* bind-mounted: a bind mount of a missing host file can fail,
and mounting the host HOME would expose unrelated data.

## Usage

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/vim:0": {}
  }
}
```

Configuration and installed plugins under `~/.vim` are shared read-only.
Buffer files in a mounted workspace persist normally; container-local runtime
state is discarded with the container. Installing plugins or writing state
**inside** `~/.vim` is not supported; do those operations on the host. If the
image already has a nonempty `~/.vim`, setup fails instead of overwriting it.
