#!/usr/bin/env bash
# Patch Strudel with GoldenPond, vendor the Haxe runtime next to goldenpond.mjs, build the website,
# and copy the static output to ./strudel-dist/ (ready to rsync to a server).
#
# Prerequisites:
#   - goldenpond.js in this directory from current/haxe/makeall.sh (already run before this script)
#   - Strudel checkout at ./strudel/ with dependencies installed (pnpm recommended)
#
# Usage:
#   ./build-strudel.sh              # patch + copy runtime + build + ./strudel-dist/
#   ./build-strudel.sh --install    # run pnpm/npm install in ./strudel first
#   STRUDEL_DIST_DIR=/tmp/out ./build-strudel.sh
#
# Subdirectory on your domain (IMPORTANT for asset URLs — see gp4strudel/README.md):
#   ./build-strudel.sh --site-url https://example.com --base-path /strudel
# Optional: SITE_URL/BASE_PATH environment variables (--site-url/--base-path override them).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${STRUDEL_DIST_DIR:-$SCRIPT_DIR/strudel-dist}"
STRUDEL_DIR="$SCRIPT_DIR/strudel"
PATCH_SCRIPT="$SCRIPT_DIR/gp4strudel/patch.sh"
GP_SOURCE="$SCRIPT_DIR/goldenpond.js"
RUNTIME_DST="$STRUDEL_DIR/website/src/repl/goldenpond-runtime.js"

die() { echo "build-strudel.sh: error: $*" >&2; exit 1; }

DO_INSTALL=false
CLI_BASE_PATH=""
CLI_SITE_URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      DO_INSTALL=true
      shift
      ;;
    --site-url=*)
      CLI_SITE_URL="${1#*=}"
      [[ -n "$CLI_SITE_URL" ]] || die "empty value after --site-url="
      shift
      ;;
    --site-url)
      [[ -n "${2:-}" && "$2" != -* ]] || die "--site-url requires a value (e.g. https://your.site)"
      CLI_SITE_URL="$2"
      shift 2
      ;;
    --base-path=*)
      CLI_BASE_PATH="${1#*=}"
      [[ -n "$CLI_BASE_PATH" ]] || die "empty value after --base-path= (omit the flag entirely for domain root)"
      shift
      ;;
    --base-path)
      [[ -n "${2:-}" && "$2" != -* ]] || die "--base-path requires a value (e.g. /your-subdir)"
      CLI_BASE_PATH="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./build-strudel.sh [options]

  --install            Run pnpm install (or npm install) under ./strudel before building
  --site-url URL       Canonical site origin without path (e.g. https://example.com).
                       Overrides SITE_URL env. Omit to use env or Strudel default (strudel.cc).
  --base-path PATH     URL path segment where Strudel is mounted (e.g. /strudel or strudel).
                       Overrides BASE_PATH env. Omit for site served only at domain root.

Environment:
  STRUDEL_DIST_DIR     Output directory (default: ./strudel-dist next to this script)
  BASE_PATH, SITE_URL  Used when CLI flags omit them; CLI always wins.

Requires goldenpond.js beside this script (from current/haxe/makeall.sh) and ./strudel with deps installed.
EOF
      exit 0
      ;;
    *)
      die "unknown option: $1 (try --help)"
      ;;
  esac
done

EFFECTIVE_BASE_PATH="${CLI_BASE_PATH:-${BASE_PATH:-}}"
EFFECTIVE_SITE_URL="${CLI_SITE_URL:-${SITE_URL:-}}"
BUILD_BASE_PATH=""
if [[ -n "$EFFECTIVE_BASE_PATH" ]]; then
  case "$EFFECTIVE_BASE_PATH" in
    /*) BUILD_BASE_PATH="$EFFECTIVE_BASE_PATH" ;;
    *) BUILD_BASE_PATH="/$EFFECTIVE_BASE_PATH" ;;
  esac
  BUILD_BASE_PATH="${BUILD_BASE_PATH%/}"
fi

BUILD_SITE_URL="$EFFECTIVE_SITE_URL"

[[ -f "$GP_SOURCE" ]] ||
  die "missing $GP_SOURCE — run current/haxe/makeall.sh first (copies out/js/goldenpond.js here)"

[[ -f "$STRUDEL_DIR/package.json" ]] ||
  die "missing Strudel checkout at $STRUDEL_DIR (expected for-distribution/strudel/strudel)"

[[ -f "$PATCH_SCRIPT" ]] || die "missing patch script: $PATCH_SCRIPT"

echo "==> Apply GoldenPond patches (gp4strudel/patch.sh)"
bash "$PATCH_SCRIPT"

echo "==> Copy GoldenPond Haxe bundle → strudel/website/src/repl/goldenpond-runtime.js"
mkdir -p "$(dirname "$RUNTIME_DST")"
cp -f "$GP_SOURCE" "$RUNTIME_DST"

cd "$STRUDEL_DIR"

if [[ "$DO_INSTALL" == true ]]; then
  echo "==> Install dependencies (--install)"
  if command -v pnpm >/dev/null 2>&1 && [[ -f pnpm-lock.yaml ]]; then
    pnpm install
  else
    npm install
  fi
fi

[[ -d node_modules ]] ||
  die "no node_modules under Strudel — run: cd strudel && pnpm install   or   ./build-strudel.sh --install"

# Astro reads BASE_PATH / SITE_URL in website/astro.config.mjs — required for subdirectory deploys,
# otherwise / _astro assets 404 behind https://your.site/subdir/.
echo "==> Build Strudel (npm script: prebuild jsdoc + website astro build)"
if [[ -n "$BUILD_BASE_PATH" ]] || [[ -n "$BUILD_SITE_URL" ]]; then
  echo "    BASE_PATH=${BUILD_BASE_PATH:-'(domain root — empty)'}   SITE_URL=${BUILD_SITE_URL:-'(Strudel default)'}"
fi
if command -v pnpm >/dev/null 2>&1 && [[ -f pnpm-lock.yaml ]]; then
  env BASE_PATH="$BUILD_BASE_PATH" SITE_URL="$BUILD_SITE_URL" pnpm run build
else
  env BASE_PATH="$BUILD_BASE_PATH" SITE_URL="$BUILD_SITE_URL" npm run build
fi

WEBSITE_DIST="$STRUDEL_DIR/website/dist"
[[ -d "$WEBSITE_DIST" ]] || die "expected $WEBSITE_DIST after build — see errors above"

echo "==> Copy static site → $DIST_DIR"
rm -rf "$DIST_DIR"
cp -a "$WEBSITE_DIST" "$DIST_DIR"

echo ""
echo "Done. Deploy (example):"
echo "  rsync -av --delete \"$DIST_DIR/\" user@host:/var/www/strudel/"
