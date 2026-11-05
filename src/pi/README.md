# Pi Coding Agent Feature

Installs the [Pi Coding Agent](https://pi.dev/) CLI with npm (command: `pi`).

## Options

- `install`: default `true`
- `persist`: default `true`
- `version`: npm version for `@earendil-works/pi-coding-agent`, default `latest`

## Persistence

The default `~/.pi/agent` directory is bind-mounted from the host and linked into
the container's user home. This includes authentication, settings, installed
extensions, and sessions. Project-local `.pi/` files remain in the workspace.
The feature uses the default agent directory; custom `PI_CODING_AGENT_DIR`
locations are not automatically mounted.

**Before creating the container**, run `mkdir -p ~/.pi/agent` on the
Docker/Dev Container host so the bind-mount source exists. Data is writable
from within the container and survives deletion of a disposable container.

The feature depends on the upstream Node.js feature (LTS). It uses the
upstream-recommended `npm install -g --ignore-scripts` form.

## Usage

Add this Feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/temeteke/devcontainer-features/pi:0": {}
  }
}
```

Then open the Dev Container and run `pi` in its terminal.

First configure your preferred provider with `/login` or supply an API key
through your chosen environment configuration. Host credentials in
`~/.pi/agent` are exposed to the container.

The independent upstream project is not affiliated with this Feature.
