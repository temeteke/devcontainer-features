# Git Config Feature

Inherits the host `~/.gitconfig` into the container with host-specific settings filtered out, and
configures the GitHub CLI (`gh`) and GitLab CLI (`glab`) as git credential helpers.

This Feature is intended to be used directly or as a dependency from the `github-cli` and
`gitlab-cli` Features.

## What it does

1. Reads the mounted host `~/.gitconfig` (`/mnt/devcontainer-features/git-config/gitconfig`).
2. Drops settings that do not make sense inside a Linux container.
3. Writes a managed `~/.gitconfig` that contains the remaining host settings.
4. Preserves an existing container `~/.gitconfig` as `~/.gitconfig.devcontainer` and includes it
   **after** the host settings, so container-specific settings take precedence.
5. Appends `gh auth git-credential` and `glab auth git-credential` to the credential helper chain
   when the corresponding CLI is installed.

The generated file looks like this:

```ini
[devcontainer]
    gitConfig = true

# Host settings (filtered)

[include]
    path = /home/vscode/.gitconfig.devcontainer

[credential]
    helper = !/usr/local/bin/gh auth git-credential
    helper = !/usr/local/bin/glab auth git-credential
```

## Precedence

From lowest to highest priority:

1. `/etc/gitconfig`
2. Host `~/.gitconfig` (filtered)
3. Container `~/.gitconfig` (preserved as `~/.gitconfig.devcontainer`)
4. Commands added by `postCreateCommand` (run after Feature commands)
5. Repository `.git/config`

If the container config already defines a credential helper, it is tried before the `gh` / `glab`
helpers. The host config's credential helpers are never inherited.

## Filtered settings

Host settings that depend on the host OS, host paths, or host credentials are not inherited.

- Credentials: `credential.*`, `http.extraHeader`, `http.*.extraHeader`, `sendemail.*`
- Host paths and programs: `core.hooksPath`, `core.sshCommand`, `core.editor`, `core.pager`,
  `core.askPass`, `core.excludesFile`, `core.attributesFile`, `core.fsmonitor`, `core.gitProxy`,
  `core.alternateRefsCommand`, `gpg.*`, `user.signingKey`, `commit.gpgSign`, `tag.gpgSign`,
  `push.gpgSign`, `diff.tool`, `diff.external`, `diff.*.command`, `diff.*.textconv`,
  `merge.tool`, `merge.*.driver`, `difftool.*`, `mergetool.*`, `pager.*`,
  `interactive.diffFilter`, `sequence.editor`, `filter.*`, `lfs.*`, `web.browser`, `browser.*`
- OS and network: `core.autocrlf`, `core.eol`, `core.symlinks`, `core.fileMode`,
  `core.ignoreCase`, `core.precomposeUnicode`, `core.protectNTFS`, `core.protectHFS`,
  `core.fscache`, `core.longpaths`, `http.proxy`, `http.*.proxy`, `http.sslBackend`,
  `http.sslVerify`, `http.sslKey`, `http.sslCert`, `http.sslCAInfo`, `http.sslCookieFile`,
  `http.cookieFile`, `http.schannelUseSSLCAInfo`, `http.sslCertPasswordProtected`,
  `http.*.sslCert`, `http.*.sslKey`, `http.*.sslCAInfo`, `http.*.sslVerify`,
  `http.*.cookieFile`, `http.*.sslCookieFile`, `http.*.sslBackend`,
  `http.*.schannelUseSSLCAInfo`, `http.*.sslCertPasswordProtected`
- Paths and repository state: `include.path`, `includeIf.*`, `core.worktree`,
  `core.repositoryFormatVersion`, `safe.directory`, `remote.*`, `submodule.*`
- `url.*` entries whose URL contains embedded credentials (for example
  `https://user:token@host/`) are skipped.

Settings such as `user.name`, `user.email`, `alias.*`, `init.*`, `pull.*`, `push.*`, `fetch.*`,
`merge.*`, `rebase.*`, `url.*.insteadOf`, and most other `core.*` values are inherited.

## Host requirements

The host `~/.gitconfig` must exist before the container starts. In the standard single-container
Dev Containers path, a missing bind-mount source can prevent the container from starting. With
Docker Compose it may instead create a directory on the host. Create the file first:

```sh
touch ~/.gitconfig
```

If the container does start but the mounted path is not a regular file, this Feature logs a
warning and configures only the credential helpers.

Only `~/.gitconfig` is mounted. Files referenced by `include.path` are inherited only when they
resolve to an existing path inside the container (for example, when separately mounted at the
container's `$HOME`). `~/.gitconfig.local` is not inherited by default.

## Credential helper notes

`gh` and `glab` store tokens in the OS keyring by default. A container cannot read the host
keyring. If the host stores tokens in the OS keyring, run `gh auth login` or `glab auth login`
inside the container once; the mounted configuration directory keeps the authentication for
later rebuilds.

Alternatively, set `GH_TOKEN` or `GITLAB_TOKEN` in `containerEnv`.

SSH remotes do not use git credential helpers. Use SSH agent forwarding or a separate Feature for
SSH authentication.

## Security

The host `~/.gitconfig` is mounted read-write. Even though this Feature filters sensitive keys
from the generated `~/.gitconfig`, container processes can read **and modify** the original
mounted file. Modifications can add host-executed settings such as `core.sshCommand`,
`core.hooksPath`, or aliases that later run on the host. Feature metadata cannot declare
read-only mounts. If you need inheritance without write access, use a Docker Compose volume with
the `:ro` option or mount a host-generated config read-only.

Do not enable this Feature for untrusted projects if your host git config contains tokens or
other secrets. Any container process can also read `~/.config/gh` and `~/.config/glab-cli`, and
can extract their tokens with `git credential fill`.

The generated `~/.gitconfig` is recreated when the container is created. Changes made with
`git config --global` inside the container are not preserved across rebuilds. The container
config (`~/.gitconfig.devcontainer`) is also container-local. For durable container-specific
settings, use a container image-level `/etc/gitconfig` or a separate bind mount.

## Options

This Feature has no options.
