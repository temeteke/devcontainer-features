# Vim Feature

Installs the full `vim` package on Debian/Ubuntu. Exposes the **host**
`~/.vimrc` and `~/.vim/` via **read-write** bind mounts and links both
paths into the container user's HOME.

## Host configuration

The Feature uses Vim's conventional `~/.vimrc` and `~/.vim/` paths.
Configurations that use different locations must arrange those paths on
the host before starting the container.

Make sure both `~/.vimrc` (file) and `~/.vim/` (directory) exist on the
host before starting a container. Missing bind sources may prevent startup.

**Why is `~/.vim` writable?** Some Vim configurations install or update
plugins and store undo or other runtime data inside `~/.vim/`. A read-only
mount would prevent these operations. This also means processes running
inside the container can modify host Vim configuration, plugins and state.
Review this exception to workspace isolation before using the Feature
with untrusted code.

The `~/.vimrc` file is also writable from inside the container because
Dev Container Feature metadata does not provide a read-only mount property.
This is an explicit exception to workspace-only isolation.

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
