#!/usr/bin/env bash
# Example: deploy Strudel + GoldenPond under https://YOUR_DOMAIN/path (not domain root).
#
#   cp build-strudel-site.example.sh build-strudel-site.sh
#   chmod +x build-strudel-site.sh
#
# Edit the two assignments below (build-strudel-site.sh is gitignored), then run:
#   ./build-strudel-site.sh           # optional: add --install
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- copy this file to build-strudel-site.sh and edit these ---
SITE_URL="https://YOUR_DOMAIN.example/"
BASE_PATH="/your/path/"
# --- end edit ---

exec "$SCRIPT_DIR/build-strudel.sh" --site-url "$SITE_URL" --base-path "$BASE_PATH" "$@"
