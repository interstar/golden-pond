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
copy "jsdoc/jsdoc.config.json"

STANDALONE_DST="$ROOT/../goldenpond-strudel.js"
cp "$ROOT/standalone/goldenpond-strudel.js" "$STANDALONE_DST"
echo "  cp -> $STANDALONE_DST (standalone adapter next to this Goldenpond distribution folder)"

echo "Done. Ensure goldenpond.js is present (run current/haxe/makeall.sh) at:"
echo "  $(cd "$ROOT/.." && pwd)/goldenpond.js"
echo "  (same directory as the strudel/ checkout — four levels up from website/src/repl/ for import ../../../../goldenpond.js)"
