# Design: highlight the active chord in the `gpond` progression string

## Goal

When a pattern built with `gpline` / Goldenpond is playing in the Strudel REPL, the editor should visually indicate **which chord** in the progression string (the third argument to `gpond`, e.g. `"1,5,6,4"`) is active at each moment—using the same mechanism Strudel already uses for mini-notation: **registered source spans** plus **`hap.context.locations`**.

## How Strudel highlighting works (minimal recap)

1. **On evaluate**, a list of `[from, to]` character ranges in the document is stored in CodeMirror (`updateMiniLocations`). Each range gets a decoration id `"from:to"`.

2. **Each animation frame**, active haps are passed to `highlightMiniLocations`. For each hap that has `hap.context.locations` as `{ start, end }` objects matching those ids, the corresponding range is outlined in the editor.

3. **On buffer edits**, decorations are remapped with document changes; **semantic** alignment with the running pattern only refreshes when the user evaluates again.

## What we need to add

### A. Source ranges for each chord token (eval time)

We must ensure every span we might want to flash exists in the `miniLocations` list passed to `updateMiniLocations`.

**Recommended approach:** add a **transpiler plugin** (same registration style as `packages/transpiler/plugin-mini.mjs`) that:

- Detects `CallExpression` where `callee` is `gpond` (identifier name).
- Requires the **third argument** to be a string `Literal` with known `node.start` / `node.end` (or use `node.raw` to skip quote characters when computing inner offsets).
- Parses the progression string with **Goldenpond’s rules** (comma-separated tokens, trim whitespace), not the mini parser. For each token, compute absolute `[from, to)` in the document for the characters inside the quotes.
- Appends those ranges to `context.miniLocations` (or whatever field the transpiler merges into `meta.miniLocations`).

**Why not reuse the existing `doublequotes` plugin alone?** That path runs the **mini** language over arbitrary `"..."` literals. A chord degree string is not mini notation; ranges could be wrong or misleading. Dedicated `gpond` handling keeps semantics aligned with Goldenpond.

**Alternative:** post-process `meta` after transpile (e.g. in `afterEval`) by re-parsing the editor text to find `gpond` calls. More fragile (must match what was evaluated); a transpiler walk is cleaner.

### B. Attach locations to Goldenpond haps (query time)

In `goldenpond.mjs`, when constructing each `Hap`, set context so Strudel merges locations like other patterns:

- Determine **chord index** (and thus which token range applies) from Goldenpond time / tick position relative to `chordDuration` and the progression length.
- Set `context.locations` to `[{ start, end }]` for that token’s span (same numbers as in step A).

If the core `Hap` constructor does not accept context in the object you build today, use `Pattern.withLoc(start, end)` on the pattern returned by `lineFromGoldenData`, or attach context in the same way other Strudel patterns do after `queryArc` (prefer the smallest change that preserves `hasOnset()` and scheduler behaviour).

### C. Optional: styling

Haps can carry `value.color` or `value.markcss` so chord highlights differ from note-level mini highlights if both coexist.

## Edge cases

| Case | Suggestion |
|------|------------|
| Third argument is a variable, not a literal | No per-chord spans; optionally highlight the identifier only (one span) or skip chord highlighting. |
| Multiple `gpond` calls | Each literal gets its own ranges; haps must carry locations for the **instance** that produced them (may require disambiguation if one `GoldenData` is reused—usually one progression per eval block is enough for v1). |
| User edits code without re-eval | Decorations move; audio may be stale until re-eval—same as normal Strudel. |

## Implementation order

1. Transpiler plugin: emit `miniLocations` entries for `gpond` progression tokens only (feature-flag if desired).
2. Extend `goldenpond.mjs` to compute active chord index per event and attach `context.locations` (or `.withLoc` on the pattern).
3. Manual test in REPL: `gpond(48,"Major","1,5,6,4",4)` + `gpline(...)` and confirm the outline tracks chord changes.
4. Add a short note to user-facing docs when stable.

---

## Reference: original files added or touched for Goldenpond + Strudel

**Canonical masters** for integration JS and patched Strudel files live under **`gp4strudel/`**. After editing, run `gp4strudel/patch.sh` to copy into a checkout at `strudel/` (see `gp4strudel/README.md`).

This lists what exists **in this repo** for the Goldenpond Strudel integration (chord highlighting would extend this set).

### New files (authored for integration)

| Path | Role |
|------|------|
| `gp4strudel/strudel/website/src/repl/goldenpond.mjs` (master) → `strudel/website/src/repl/goldenpond.mjs` | Strudel-native adapter: `gpond`, `gpline`, tick/Fraction-based `Pattern` construction; side-effect import `./goldenpond-runtime.js`. |
| `gp4strudel/standalone/goldenpond-strudel.js` (master) → `goldenpond-strudel.js` | Standalone adapter + global `goldenpondStrudel` for the older Goldenpond `index.html` demo (no monorepo bundler). |

### Generated / copied artifact (not hand-edited)

| Path | Role |
|------|------|
| `goldenpond.js` | Output from **`current/haxe/makeall.sh`** in `for-distribution/strudel/`. **`build-strudel.sh`** copies it to `strudel/website/src/repl/goldenpond-runtime.js` so `goldenpond.mjs` can `import './goldenpond-runtime.js'`. |

### Modified upstream files (fork / local Strudel tree)

| Path | Role |
|------|------|
| `gp4strudel/strudel/website/src/repl/util.mjs` (master) → `strudel/website/src/repl/util.mjs` | `modules.push(import('./goldenpond.mjs'))` so `gpond` / `gpline` enter `evalScope`. Re-merge when upgrading Strudel. |
| `gp4strudel/strudel/jsdoc/jsdoc.config.json` (master) → `strudel/jsdoc/jsdoc.config.json` | JSDoc `excludePattern` / `plugins` fixes so `pnpm run jsdoc-json` works in this path layout (dev ergonomics). |

### Goldenpond distribution web shell (separate from monorepo)

| Path | Role |
|------|------|
| `index.html` | Loads `goldenpond.js`, `goldenpond-strudel.js`, Strudel; uses `goldenpondStrudel.lineFromGoldenData` for playback. |

### Build script (Haxe tree)

| Path | Role |
|------|------|
| `current/haxe/makeall.sh` | Copies `out/js/goldenpond.js` to `for-distribution/strudel/goldenpond.js` (and other targets). |
| `build-strudel.sh` | **Deploy helper**: patch Strudel, vendor `goldenpond-runtime.js`, build website, emit `./strudel-dist/` for rsync. Lives next to `gp4strudel/`. |
| `gp4strudel/patch.sh` | Copies masters from `gp4strudel/` into `for-distribution/strudel/strudel/` (**`goldenpond.mjs`**, **`util.mjs`**, **`website/astro.config.mjs`**, **`jsdoc.config.json`**) and `goldenpond-strudel.js` beside it. Run after editing integration files (also invoked by `build-strudel.sh`). |

Chord highlighting would add at least **one new transpiler plugin file** (under `strudel/packages/transpiler/` or loaded from the website bundle if you keep patches minimal) and **edits to `gp4strudel/strudel/website/src/repl/goldenpond.mjs`** (then run `gp4strudel/patch.sh`; and possibly `registerTranspilerPlugin` wiring in the transpiler entry).
