# Vim Feature

Installs the full `vim` package on Debian/Ubuntu. Exposes the **host**
`~/.vimrc` **read-only** and `~/.vim/` **read-write** and links both
paths into the container user's HOME.

## Host configuration

This matches [temeteke/vim-config](https://github.com/temeteke/vim-config):
its Makefile installs `~/.vimrc` and populates `~/.vim/` with scripts,
plugin configuration and an undo directory. No configuration migration
is required.

Make sure both `~/.vimrc` (file) and `~/.vim/` (directory) exist on the
host before starting a container. Missing bind sources may prevent startup.

**Why is `~/.vim` writable?** The current `vim-config/plugin.vim`
bootstraps vim-jetpack and synchronizes plugins on startup; the Makefile
also creates `~/.vim/undo`. Read-only sharing would break that workflow.
This means code running inside the container can modify host Vim plugins
and other files under `~/.vim`. Do not use this Feature with untrusted
agents unless you accept that exception to workspace isolation.

The optional `~/.vimrc.local` is not mounted, so Vim skips it unless
another mount provides it.

## Usage

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/vim:0": {}
  }
}
```

The setup script refuses to overwrite existing nonempty container-side
configuration. Use a base image with an empty/default Vim HOME.
