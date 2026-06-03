# Goldenpond and Strudel: principled integration

This note is for anyone maintaining the Goldenpond fork of Strudel or preparing work to upstream. It sits beside the cloned Strudel tree under `for-distribution/strudel/strudel/`.

**Masters and patching:** integration source files live in **`gp4strudel/`**. Run `gp4strudel/patch.sh` after cloning Strudel into `for-distribution/strudel/strudel/` (see `gp4strudel/README.md`).

**Static deploy bundle:** from `for-distribution/strudel/`, after **`current/haxe/makeall.sh`** has produced **`goldenpond.js`** here, run **`./build-strudel.sh`** to patch, copy **`goldenpond.js` → `website/src/repl/goldenpond-runtime.js`**, build the site, and produce **`./strudel-dist/`** for rsync. The patched **`website/astro.config.mjs`** sets **`vite.ssr.noExternal: ['superdough']`** so Astro can finish static generation (see `gp4strudel/README.md`).

## What “principled” means here

1. **Goldenpond stays a separate library** (Haxe → JS). Strudel does not reimplement chord theory; the REPL loads it via **`goldenpond-runtime.js`** (same bits as **`goldenpond.js`**, copied next to **`goldenpond.mjs`** — see **`build-strudel.sh`**).

2. **The adapter is a thin Strudel layer**: build `Pattern` values that implement Strudel’s query model (`queryArc` → `Hap`s with correct `whole` / `part` / `Fraction` timing). No long mini-notation stringification for sequences.

3. **Editor and clock behaviour** follow Strudel rules: tempo from Strudel CPS; highlighting from `miniLocations` + `hap.context.locations` when we choose to implement it (see `highlights.md`).

## Extension points Strudel already provides

### REPL / global scope (`evalScope`)

The website REPL loads a list of ES modules and exposes their exports to user code. Adding `import('./goldenpond.mjs')` in `website/src/repl/util.mjs` is the same mechanism Strudel uses for other user-facing packages. That is the **primary** hook for “make `gpond` / `gpline` available in the editor.” In this repo, the patched `util.mjs` is mastered under `gp4strudel/strudel/website/src/repl/util.mjs` and copied in by `gp4strudel/patch.sh`.

### Transpiler plugins

`packages/transpiler/transpiler.mjs` supports `registerTranspilerPlugin`. Plugins walk the ESTree AST and can:

- Rewrite nodes (as `plugin-mini.mjs` does for backticks and strings).
- Accumulate `miniLocations`, widgets, etc. on the transpiler `context`.

This is the right place for **chord-string highlighting** and any future syntax sugar that must know source positions.

### Pattern / Hap API

Strudel’s `Pattern`, `Hap`, `TimeSpan`, and `Fraction` are public building blocks. A third-party adapter that returns ordinary `Pattern` instances composes with `.sound()`, `stack()`, etc. No fork of the scheduler is required if timing is implemented correctly.

### Optional package layout (monorepo style)

A clean long-term shape would be:

- `packages/goldenpond-adapter/` (or publish `@goldenpond/strudel` on npm): depends on `@strudel/core`, imports or receives `goldenpond.js` as a file dependency.
- Website `util.mjs` imports that package instead of a relative `./goldenpond.mjs`.

Today the adapter is mastered as **`gp4strudel/strudel/website/src/repl/goldenpond.mjs`** and patched into the Strudel tree; moving it to `packages/` later is packaging hygiene, not a behaviour change.

## Is there a formal “plugin architecture”?

There is **no single plugin manifest** (like VS Code’s `package.json` contributions) for arbitrary third-party music libraries. In practice, integration uses:

- **Module list** → `evalScope` (REPL surface).
- **Transpiler plugins** → AST and `miniLocations`.
- **Optional**: separate npm package consumed by the website.

That is enough for Goldenpond to remain modular without core Strudel knowing about chord progressions.

## Should we try to get this into upstream Strudel?

**Arguments for proposing upstream inclusion (or an official “contrib” path):**

- Discoverability: users get Goldenpond without patching a fork.
- CI: adapter stays compatible with Strudel releases.
- Could ship as an **optional** dependency (dynamic `import()`) so default bundle size is unchanged until the user loads a tutorial or enables Goldenpond.

**Arguments for keeping it out of core and in a package or fork:**

- Maintainer load: another domain (Haxe releases, chord semantics, support surface).
- Bundle size and policy: upstream may resist shipping a large prebuilt `goldenpond.js` in the default REPL.
- Release cadence: Goldenpond and Strudel versions would need a clear compatibility matrix.

**Reasonable middle path**

1. Publish **`@goldenpond/strudel`** (or `strudel-goldenpond`) on npm with peer dependency on `@strudel/core` and documented import of `goldenpond.js`.
2. Open an issue or small PR on the Strudel repo: **document** the `evalScope` + optional package pattern, or add a **single dynamic import** behind a feature flag / “experimental modules” list if maintainers want one-click enable without vendoring Haxe output in the main repo.
3. Keep the **Haxe-generated `goldenpond.js`** owned by the Goldenpond project; upstream only references versioned URLs or npm if they accept that.

## Summary

| Question | Answer |
|----------|--------|
| Formal plugin API? | **Partial:** `evalScope` modules + transpiler plugins + standard `Pattern` API. |
| Principled integration? | **Yes:** Haxe bundle + thin adapter + no clock ownership from Goldenpond. |
| Upstream? | **Worth asking** with an optional package / dynamic import story; expect **fork or external package** unless maintainers explicitly want it in-tree. |

For chord highlighting specifically, see **`highlights.md`** in this directory.

**Using GoldenPond in the browser REPL:** see **`GOLDENPOND_STRUDEL_REPL.md`** (`gpond`, `gpline`, and related exports).
