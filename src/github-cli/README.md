# GitHub CLI Feature

Installs the official [GitHub CLI Dev Container Feature](https://github.com/devcontainers/features/tree/main/src/github-cli)
and persists `gh` authentication by linking `~/.config/gh` to the host home directory.

The shared `git-config` Feature is installed automatically as a dependency. It inherits the host
`~/.gitconfig` and configures `gh` as a git credential helper, so HTTPS git operations can use the
same authentication as `gh`.

## Options

- `persist`: default `true`

  When enabled, links `~/.config/gh` (or `$XDG_CONFIG_HOME/gh`) to the mounted host directory.
  The bind mount is always applied, even when persistence is disabled.

## Persisted paths

- `~/.config/gh` (or `$XDG_CONFIG_HOME/gh`)

## Host requirements

Create the host directory before opening the container:

```sh
mkdir -p ~/.config/gh
```

The host `~/.gitconfig` must also exist because the `git-config` dependency mounts it:

```sh
touch ~/.gitconfig
```

In the standard single-container Dev Containers path, a missing bind-mount source can prevent the
container from starting. With Docker Compose it may instead create a directory on the host. Create
both host paths before opening the container.

## Authentication notes

`gh` stores tokens in the OS keyring by default. A container cannot read the host keyring. If the
host stores the token in the OS keyring, run `gh auth login` inside the container once. The
mounted `~/.config/gh` keeps the authentication for later rebuilds.

Alternatively, set `GH_TOKEN` in `containerEnv`.

## Example

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/github-cli:0": {}
  }
}
```

## Security

`~/.config/gh` may contain OAuth tokens. It is mounted read-write so `gh auth login` and token
refresh can update the host configuration. Enable this Feature only for projects you trust.
