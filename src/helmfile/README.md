# Helmfile Feature

Installs [helmfile](https://github.com/helmfile/helmfile) together with the tools it requires:
[Helm](https://helm.sh/) and the [helm-diff](https://github.com/databus23/helm-diff) plugin.

## What it installs

- `helmfile` from GitHub Releases
- `helm` from `https://get.helm.sh/`
- `helm-diff` from GitHub Releases
- SHA-256 checksums for all three are verified against the upstream checksum files

Supported architectures: `amd64`, `arm64`.

Helm is installed to `/usr/local/bin/helm` and replaces any existing Helm binary from the
base image.

## Why Helm and helm-diff are included

Helmfile delegates to Helm, and `helmfile diff` / `helmfile apply` use the `helm-diff`
plugin. Without both, helmfile is installed but most workflows fail.

Helm 4 verifies plugin signatures during `helm plugin install`. To keep the installation
deterministic and avoid per-user plugin installation at build time, this Feature extracts
the official helm-diff release archive to
`/usr/local/share/helm/plugins/diff` and links it into the directory reported by
`helm env HELM_PLUGINS` in `postCreateCommand` (falling back to `HELM_PLUGINS`,
`HELM_DATA_HOME`, `XDG_DATA_HOME`, or `~/.local/share/helm/plugins`). If you already have a
valid `diff` plugin installed, it is left untouched. Broken symlinks are replaced. If the plugin
directory is on a mount other than the container root (for example a home volume or bind mount),
the link is skipped and a warning is logged.

This path does not run Helm's plugin provenance verification. Checksum verification is
performed against the upstream release checksums instead. Checksums are fetched from the
same upstream over HTTPS, so this detects transport corruption but does not protect against
a compromised upstream.

## Options

| Option | Default | Description |
|---|---|---|
| `install` | `true` | Install helmfile, Helm, and helm-diff. |
| `version` | `latest` | helmfile version (e.g., `1.8.2`). |
| `helmVersion` | `latest` | Helm version (e.g., `4.3.1`). Helmfile supports Helm 3.18.6+ and Helm 4.x. |
| `helmDiffVersion` | `latest` | helm-diff plugin version (e.g., `3.15.15`). Use `3.15.10` or later for `--server-side`. |

## helmfile init

`helmfile diff` and `helmfile apply` work with the bundled `helm-diff` plugin; running
`helmfile init` is not required. If you run it, helmfile checks its other recommended
plugins (`secrets`, `s3`, `helm-git`, `unittest`) and may prompt to install them.

## Persistence

This Feature does not persist Helm or helmfile state. Helm repository configuration,
caches, and user-installed plugins are not persisted. The bundled helm-diff plugin is baked
into the image and linked into the user's plugin directory at `postCreateCommand`. Use the
`kubectl` Feature if you also want to persist `~/.kube`.
