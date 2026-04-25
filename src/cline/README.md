# Cline Feature

Installs the Cline VS Code extension and persists its VS Code globalStorage directory.

## Options

- `install`: kept for consistency. The VS Code extension is added via `customizations.vscode.extensions`.
- `persist`: default `true`
- `persistMode`: `all` (default) or `configs`

## Persisted paths

The directories persisted depend on the `persistMode` option:

- **`all`** (default): `~/Documents/Cline`, `~/.cline`
- **`configs`**: `~/Documents/Cline`, `~/.cline`
