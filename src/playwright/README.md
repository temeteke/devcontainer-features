# Playwright Agent CLI Feature

This Feature installs Microsoft's Playwright Agent CLI for AI coding agents.

## What it installs

- `npm install -g @playwright/cli@latest`
- `playwright-cli install-browser --with-deps`

## What it does not install

- `@playwright/test`
- `npx playwright install`
- `playwright-cli install --skills`

`@playwright/test` is expected to be managed in each project’s `package.json` and lockfile.
This Feature only installs the agent-facing CLI and the browser runtime it uses.

## Command meaning

- `playwright-cli install-browser --with-deps`
  - Installs the browser binary used by the agent CLI and the required Linux dependencies

## About skills

`playwright-cli install --skills` is intentionally out of scope for this Feature.
If your agent ecosystem uses skills, install them using that agent’s own conventions.
This Feature does not assume `.claude` or any other shared agent directory layout.

## Using Playwright Test in a normal E2E project

If you want to use Playwright Test in a project, install dependencies in the project first and then
install the browser binary you need.

```bash
npm ci
npx playwright install chromium
```

`npx playwright install` is for browser binaries that match the project’s Playwright / `@playwright/test`
version. This Feature does not use it.
