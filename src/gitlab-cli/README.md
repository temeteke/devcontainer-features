# GitLab CLI Feature

Installs the GitLab CLI (`glab`) from GitLab releases and persists `~/.config/glab-cli` by
linking it to the host home directory.

The shared `git-config` Feature is installed automatically as a dependency. It inherits the host
`~/.gitconfig` and configures `glab` as a git credential helper, so HTTPS git operations can use
the same authentication as `glab`.

## Options

- `install`: default `true`

  Set to `false` when `glab` is already installed by another Feature or the base image.

- `persist`: default `true`

  When enabled, links `~/.config/glab-cli` to the mounted host directory. The bind mount is always
  applied, even when persistence is disabled.

- `version`: default `latest`

  GitLab CLI version to install (for example, `1.126.0`).

## Persisted paths

- `~/.config/glab-cli`

## Host requirements

Create the host directories before opening the container:

```sh
mkdir -p ~/.config/glab-cli
touch ~/.gitconfig
```

`gitlab-cli` 0.3.0 and later require the host `~/.gitconfig` because of the `git-config`
dependency. In the standard single-container Dev Containers path, a missing bind-mount source can
prevent the container from starting. With Docker Compose it may instead create a directory on the
host. Create both host paths before opening the container.

## Authentication notes

`glab` stores tokens in the OS keyring by default. A container cannot read the host keyring. If
the host stores the token in the OS keyring, run `glab auth login` inside the container once. The
mounted `~/.config/glab-cli` keeps the authentication for later rebuilds.

Alternatively, set `GITLAB_TOKEN` in `containerEnv`.

## Example

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/gitlab-cli:0": {
      "version": "1.126.0"
    }
  }
}
```

## Security

`~/.config/glab-cli` may contain OAuth tokens. It is mounted read-write so `glab auth login` and
token refresh can update the host configuration. Enable this Feature only for projects you trust.
