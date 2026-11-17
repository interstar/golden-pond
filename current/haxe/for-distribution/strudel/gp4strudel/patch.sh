#!/usr/bin/env bash
# Patch a checked-out Strudel monorepo with the Goldenpond integration.
# Usage (from this directory):
#   ./patch.sh
# Or with an explicit Strudel root:
#   STRUDEL_ROOT=/path/to/strudel ./patch.sh
#
# New files (the adapter and transpiler plugin) are copied in. Existing Strudel
# files are changed only by small anchored insertions (strudel_patch.py), never
# replaced, so upstream changes elsewhere in those files are kept and other
# integrations (e.g. World of Cake) can patch the same files. Re-running is safe.
# If an anchor is missing, upstream Strudel changed: the script stops so the
# insertion can be updated.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STRUDEL="${STRUDEL_ROOT:-$ROOT/../strudel}"
EDIT="python3 $ROOT/strudel_patch.py"

if [[ ! -f "$STRUDEL/package.json" ]]; then
  echo "error: Strudel monorepo not found at: $STRUDEL" >&2
  echo "  Clone Strudel so package.json exists at for-distribution/strudel/strudel/package.json" >&2
  echo "  or set STRUDEL_ROOT to your checkout." >&2
  exit 1
fi

copy() {
  local rel="$1"
  local src="$ROOT/strudel/$rel"
  local dst="$STRUDEL/$rel"
  if [[ ! -f "$src" ]]; then
    echo "error: missing master file: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  cp -> $dst"
}

echo "Goldenpond → Strudel patch"
echo "  STRUDEL_ROOT=$STRUDEL"

# New files.
copy "website/src/repl/goldenpond.mjs"
copy "packages/transpiler/plugin-goldenpond-vis.mjs"

# REPL: load the adapter so gpond / gpline / gpfit are globals in the editor.
$EDIT insert-before "$STRUDEL/website/src/repl/util.mjs" \
  "return evalScope(settingPatterns, ...modules);" \
  "  modules.push(import('./goldenpond.mjs'));\n"

# Transpiler: register the chord/rhythm highlighting plugin.
$EDIT insert-after "$STRUDEL/packages/transpiler/index.mjs" \
  "import './plugin-widgets.mjs';" \
  "import './plugin-goldenpond-vis.mjs';"

# Astro static build: bundle superdough for SSR (Node's static import validation
# mishandles its export-* barrel). If upstream ever sets ssr.noExternal itself,
# merge by hand rather than inserting a second key.
if grep -q "noExternal" "$STRUDEL/website/astro.config.mjs" && ! grep -q "noExternal: \['superdough'\]" "$STRUDEL/website/astro.config.mjs"; then
  echo "error: upstream astro.config.mjs now sets noExternal; merge 'superdough' into it by hand" >&2
  exit 1
fi
$EDIT insert-after "$STRUDEL/website/astro.config.mjs" \
  "ssr: {" \
  "      // Bundle superdough for SSR — Node's static import validation mishandles its export-* barrel.\n      noExternal: ['superdough'],"

# JSDoc (doc.json generation in prebuild): exclude only real dist/ directories,
# and resolve plugins from this layout.
$EDIT json-set "$STRUDEL/jsdoc/jsdoc.config.json" source.excludePattern \
  '"node_modules|shift-parser|shift-reducer|shift-traverser|(?:^|[\\\\/])dist(?:[\\\\/]|$)"'
$EDIT json-set "$STRUDEL/jsdoc/jsdoc.config.json" plugins \
  '["node_modules/jsdoc/plugins/markdown", "jsdoc/jsdoc-synonyms.js"]'

STANDALONE_DST="$ROOT/../goldenpond-strudel.js"
cp "$ROOT/standalone/goldenpond-strudel.js" "$STANDALONE_DST"
echo "  cp -> $STANDALONE_DST (standalone adapter next to this Goldenpond distribution folder)"

echo "Done. goldenpond.js should already exist here from current/haxe/makeall.sh. For the REPL, copy it beside goldenpond.mjs:"
echo "  cp \"$(cd "$ROOT/.." && pwd)/goldenpond.js\" \"$STRUDEL/website/src/repl/goldenpond-runtime.js\""
echo "  Or run ../build-strudel.sh (patch + copy + build → strudel-dist/)."
