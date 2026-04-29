# gp4strudel — master copy of Goldenpond ↔ Strudel integration

This directory is the **source of truth** for JavaScript (and related) changes that patch into a **separate** checkout of the [Strudel](https://strudel.cc/) monorepo.

## Layout

| Path | Purpose |
|------|---------|
| `patch.sh` | Copies masters into the Strudel checkout (and the standalone adapter beside this folder). |
| `strudel/website/src/repl/goldenpond.mjs` | `gpond` / `gpline` adapter (imports `../../../../goldenpond.js`). |
| `strudel/website/src/repl/util.mjs` | Fork of Strudel’s `util.mjs` including `modules.push(import('./goldenpond.mjs'))`. **Re-merge when upgrading Strudel.** |
| `strudel/jsdoc/jsdoc.config.json` | JSDoc config fix for this path layout (`doc.json` generation). |
| `standalone/goldenpond-strudel.js` | IIFE adapter for the legacy `index.html` stack (global `strudel` + `goldenpondStrudel`). |

Paths under `strudel/` are **relative to the Strudel monorepo root** (the directory that contains `website/` and `package.json`).

## Prerequisites

1. Clone Strudel next to this folder so you have:

   `for-distribution/strudel/strudel/package.json`

2. Build or copy **goldenpond.js** (Haxe output) to:

   `for-distribution/strudel/goldenpond.js`

   e.g. run `current/haxe/makeall.sh`, which copies `out/js/goldenpond.js` there.

## Apply patches

```bash
cd current/haxe/for-distribution/strudel/gp4strudel
chmod +x patch.sh   # once
./patch.sh
```

Optional:

```bash
STRUDEL_ROOT=/elsewhere/strudel ./patch.sh
```

Then use `pnpm i` / `pnpm dev` inside the Strudel repo as usual.

## Workflow

1. Edit files only under `gp4strudel/` (masters).
2. Run `./patch.sh` after changes to refresh the Strudel tree.
3. Commit `gp4strudel/` in the Goldenpond repo; the Strudel clone can stay untracked or be a git submodule.

See also `../highlights.md`, `../GOLDENPOND_STRUDEL_INTEGRATION.md`.

## Adding more patched files

1. Place the master under `gp4strudel/strudel/<path-relative-to-strudel-repo-root>`.
2. Add a `copy "<path>"` line to `patch.sh` (same path string).
