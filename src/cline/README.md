# Cline Feature

Installs the Cline VS Code extension and persists its VS Code globalStorage directory.

## Options

- `install`: kept for consistency. The VS Code extension is added via `customizations.vscode.extensions`.
- `persist`: default `true`
- `persistMode`: `all` (default), `configs`, or `state`

## Persisted paths

The directories persisted depend on the `persistMode` option:

- **`all`** (default): `~/Documents/Cline`, `~/.cline`, `~/.vscode-server/data/User/globalStorage/saoudrizwan.claude-dev`
- **`configs`**: `~/Documents/Cline`, `~/.cline`
- **`state`**: `~/.vscode-server/data/User/globalStorage/saoudrizwan.claude-dev`
