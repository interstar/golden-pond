# gp4strudel — master copy of Goldenpond ↔ Strudel integration

This directory is the **source of truth** for JavaScript (and related) changes that patch into a **separate** checkout of the [Strudel](https://strudel.cc/) monorepo.

## Layout

| Path | Purpose |
|------|---------|
| `patch.sh` | Copies the new files below into the Strudel checkout, and makes small **anchored insertions** into existing Strudel files (and copies the standalone adapter beside this folder). Safe to re-run. |
| `strudel_patch.py` | The insertion helper (`insert-before` / `insert-after` an exact anchor line, `json-set`). Idempotent; stops with an error if an anchor is missing, i.e. upstream Strudel changed. Other integrations (e.g. World of Cake's `wocstrudel`) reuse it. |
| `strudel/website/src/repl/goldenpond.mjs` | `gpond` / `gpline` / `gpfit` adapter (imports `./goldenpond-runtime.js`, a copy of `goldenpond.js` beside this file). |
| `strudel/packages/transpiler/plugin-goldenpond-vis.mjs` | Transpiler plugin for chord/rhythm highlighting. |
| `standalone/goldenpond-strudel.js` | IIFE adapter for the legacy `index.html` stack (global `strudel` + `goldenpondStrudel`). |

Paths under `strudel/` are **relative to the Strudel monorepo root** (the directory that contains `website/` and `package.json`).

### Insertions into upstream files

Existing Strudel files are never replaced, so upstream changes to them are kept and other integrations can patch the same files. `patch.sh` inserts:

| File | Insertion | Anchor |
|------|-----------|--------|
| `website/src/repl/util.mjs` | `modules.push(import('./goldenpond.mjs'));` | before `return evalScope(settingPatterns, ...modules);` |
| `packages/transpiler/index.mjs` | `import './plugin-goldenpond-vis.mjs';` | after `import './plugin-widgets.mjs';` |
| `website/astro.config.mjs` | `noExternal: ['superdough'],` (Astro's static build must bundle superdough: Node rejects named imports through its `export *` barrel) | after `ssr: {` |
| `jsdoc/jsdoc.config.json` | `source.excludePattern` and `plugins` set for this layout (`doc.json` generation) | JSON keys |

If upstream ever sets `ssr.noExternal` itself, `patch.sh` stops and asks for a manual merge.

## Prerequisites

1. Clone Strudel next to this folder so you have:

   `for-distribution/strudel/strudel/package.json`

2. **`goldenpond.js`** must exist at **`for-distribution/strudel/goldenpond.js`**. In the usual workflow **`current/haxe/makeall.sh`** has already been run and placed it there before you build Strudel.

## One-shot static site (`strudel-dist/`) for your web server

From **`for-distribution/strudel/`** (parent of `gp4strudel/`):

```bash
chmod +x build-strudel.sh    # once
# Requires goldenpond.js here (from current/haxe/makeall.sh)
./build-strudel.sh
# Optional if deps missing:
# ./build-strudel.sh --install
```

This runs **`gp4strudel/patch.sh`**, copies **`goldenpond.js` → `strudel/website/src/repl/goldenpond-runtime.js`**, runs **`pnpm run build`** (or **`npm run build`**) in the Strudel monorepo, then copies **`strudel/website/dist`** to **`./strudel-dist/`**. Upload **`strudel-dist/`** to the directory your server exposes as the site root, or behind a subdirectory path (see below).

Override output directory: **`STRUDEL_DIST_DIR=/path/to/out ./build-strudel.sh`**

For **local dev only** (`pnpm dev`), after patching you still need **`goldenpond-runtime.js`** beside **`goldenpond.mjs`** — either copy manually or run **`build-strudel.sh`** once (you can interrupt after the copy step if you only wanted the runtime file).

### Serving under a subdirectory (not the site root)

If the static site lives at **`https://your-domain.example/path/`** instead of **`https://your-domain.example/`**, build with path and origin variables (see `website/astro.config.mjs`). The build script forwards them:

Prefer flags (nothing to export):

```bash
./build-strudel.sh --site-url https://your-domain.example --base-path /path
```

Or set **`SITE_URL`** / **`BASE_PATH`** for the subprocess; **`--site-url`** / **`--base-path`** override those when both are given.

Easier to tune locally: copy **`build-strudel-site.example.sh`** → **`build-strudel-site.sh`** (gitignored), edit the placeholders, run **`./build-strudel-site.sh`** (**`--install`** is forwarded).

- **`BASE_PATH`** is the URL path segment only (leading `/`; a bare `subdir` becomes `/subdir`; trailing slashes are trimmed).
- **`SITE_URL`** is the canonical origin **without** a path (RSS, manifests, OG metadata).

Deploy **`strudel-dist/`** so your web server serves it at **`/path/`** (for example nginx **`location /path/`** with **`alias`** to the uploaded directory — mind trailing-slash conventions). Generated HTML uses a `<base>` tag scoped to **`/path`** plus asset URLs like **`/path/_astro/...`**.

A few ancillary links may still point at **`/`** (for example **`/rss.xml`**); core REPL bundles follow **`BASE_PATH`**.

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
