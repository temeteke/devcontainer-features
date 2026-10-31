# kubectl Feature

Installs [kubectl](https://kubernetes.io/docs/reference/kubectl/) and mounts the host
`~/.kube` directory.

## What it installs

- `kubectl` from the official Kubernetes release binaries
  (`https://dl.k8s.io/release/v<version>/bin/linux/<arch>/kubectl`)
- The SHA-256 checksum is verified against the release's `kubectl.sha256` file.

Supported architectures: `amd64`, `arm64`.

## Persistence

The Feature bind-mounts `${localEnv:HOME}/.kube` to
`/mnt/devcontainer-features/kubectl/kube`, then links `~/.kube` to the mounted path in
`postCreateCommand`.

This means kubeconfig, contexts, and credentials written by `kubectl config` or
`aws eks update-kubeconfig` and similar tools are stored in your host home directory and
survive container rebuilds.

If `~/.kube` already exists in the container:

- An empty directory is removed.
- A non-empty directory, file, or symlink is moved to `~/.kube.devcontainer-backup` (or a
  numbered name such as `~/.kube.devcontainer-backup.1` if that exists).
- Mount points and paths under other mounts are left untouched, and no symlink is created
  for them.

Container data is never copied into the host directory.

Set `persist: false` to skip the symlink step. The bind mount is still applied because
Feature mounts cannot be disabled by an option.

## Options

| Option | Default | Description |
|---|---|---|
| `install` | `true` | Install kubectl. |
| `persist` | `true` | Create the `~/.kube` symlink. |
| `version` | `latest` | kubectl version (e.g., `1.37.2`). `latest` follows the stable release. |

## Notes

- Create the host directory before enabling the Feature:

  ```sh
  mkdir -p "$HOME/.kube"
  ```

  Docker's `--mount type=bind` does not create a missing source directory and the
  container creation fails if `~/.kube` does not exist on the host.
- On Linux, the container user needs read, write, and execute access to the host `~/.kube`.
  If `kubectl` reports permission errors, adjust ownership on the host or enable
  `updateRemoteUserUID`.
- Only `~/.kube` is mounted. Kubeconfig files that reference client certificates outside
  `~/.kube` (for example `~/.minikube`), absolute host paths, or host-specific `exec`
  credential plugins may not work. Mount those paths separately or adjust `KUBECONFIG` if
  needed.
- `~/.kube` is mounted read-write. `~/.kube/config` can contain cluster credentials and
  client certificates. Treat it as sensitive data.
- Checksums are fetched from the same upstream over HTTPS. This detects transport
  corruption but does not protect against a compromised upstream.
