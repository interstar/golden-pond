#!/usr/bin/env bash
# Copy Goldenpond Strudel integration files into a checked-out Strudel monorepo.
# Usage (from this directory):
#   ./patch.sh
# Or with an explicit Strudel root:
#   STRUDEL_ROOT=/path/to/strudel ./patch.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STRUDEL="${STRUDEL_ROOT:-$ROOT/../strudel}"

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
copy "website/src/repl/goldenpond.mjs"
copy "website/src/repl/util.mjs"
copy "website/astro.config.mjs"
copy "jsdoc/jsdoc.config.json"
copy "packages/transpiler/plugin-goldenpond-vis.mjs"

STANDALONE_DST="$ROOT/../goldenpond-strudel.js"
cp "$ROOT/standalone/goldenpond-strudel.js" "$STANDALONE_DST"
echo "  cp -> $STANDALONE_DST (standalone adapter next to this Goldenpond distribution folder)"


if ! grep -q "plugin-goldenpond-vis.mjs" "$STRUDEL/packages/transpiler/index.mjs"; then
  python3 - "$STRUDEL/packages/transpiler/index.mjs" <<'PYEDIT'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
needle = "import './plugin-widgets.mjs';\n"
text = text.replace(needle, needle + "import './plugin-goldenpond-vis.mjs';\n")
path.write_text(text)
PYEDIT
  echo "  patched -> $STRUDEL/packages/transpiler/index.mjs"
fi

echo "Done. goldenpond.js should already exist here from current/haxe/makeall.sh. For the REPL, copy it beside goldenpond.mjs:"
echo "  cp \"$(cd "$ROOT/.." && pwd)/goldenpond.js\" \"$STRUDEL/website/src/repl/goldenpond-runtime.js\""
echo "  Or run ../build-strudel.sh (patch + copy + build → strudel-dist/)."
