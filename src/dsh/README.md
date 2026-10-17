# DeepSeek Harness (dsh) Feature

Installs the official [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
CLI (command: `dsh`) using npm.

## Options

- `install`: default `true`
- `persist`: default `true`
- `version`: npm version for `@deepseek-ai/dsh`, default `latest`

## Persistence

The default `~/.dsh` directory is bind-mounted from the host and linked into
the container home. It includes profiles, session state, and configuration.
The feature does not override `DSH_HOME`; a custom home must be managed
separately.

**Before creating the container**, run `mkdir -p ~/.dsh` on the
Docker/Dev Container host so the bind-mount source exists. This directory is
writable inside the container; protect credentials and session data.

The feature depends on the upstream Node.js feature (LTS). DSH is in
developer preview; new versions can introduce breaking changes. Pin
`version` when reproducible behavior is important. Native dependencies may
require a compiler toolchain if suitable prebuilt modules are unavailable.

## Usage

Examples inside a running Dev Container:

```sh
dsh --help
dsh --profile headless "Summarize this repository"
dsh web --no-open
```

With the disposable `dcs` wrapper:

```sh
dcs dsh --help
dcs dsh dsh --profile headless "Summarize this repository"
```

Official DSH is a launcher for profiles, including Web and headless modes,
not a Pi-style built-in terminal chat. The Web UI requires a reachable
container port and appropriate listening/forwarding configuration; `dcs`
does not publish Web UI ports automatically. Use a properly configured
persistent Dev Container for Web mode.

Provider/model credentials are configured separately; installing the CLI
does not automatically configure an API provider. Third-party TUI profiles
are not installed by this Feature.

This is an unofficial Feature, not a DeepSeek-maintained distribution.
