#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/for-distribution"
SIGNAL_DIR="$DIST_DIR/signal"
STRUDEL_DIR="$DIST_DIR/strudel"

SKIP_TESTS=false
SKIP_UPLOAD=false
INSTALL=false

usage() {
  cat <<'EOF'
Usage: ./build-and-deploy.sh [options]

Build and optionally deploy the GoldenPond downstream products.

Options:
  --skip-tests       Skip the cross-target GoldenPond test suite.
  --skip-upload      Build and verify outputs without uploading them.
  --install          Install Signal and Strudel npm dependencies before building.
  -h, --help         Show this help.

Strudel deployment settings:
  If for-distribution/strudel/build-strudel-site.sh exists, it is used for
  the local site URL and base path. Otherwise set STRUDEL_SITE_URL and
  STRUDEL_BASE_PATH and the generic build-strudel.sh is used.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --skip-upload)
      SKIP_UPLOAD=true
      shift
      ;;
    --install)
      INSTALL=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

die() {
  echo "build-and-deploy.sh: error: $*" >&2
  exit 1
}

echo "==> GoldenPond downstream build"

if [[ "$SKIP_TESTS" == false ]]; then
  echo "==> Test all Haxe targets"
  "$SCRIPT_DIR/test_all_languages.sh"
fi

echo "==> Build GoldenPond and refresh downstream library copies"
"$SCRIPT_DIR/makeall.sh"

if [[ "$INSTALL" == true ]]; then
  echo "==> Install Signal dependencies"
  (cd "$SIGNAL_DIR" && npm install)
fi

echo "==> Build Signal"
(cd "$SIGNAL_DIR" && npm run build)

if [[ "$INSTALL" == true ]]; then
  echo "==> Install Strudel dependencies"
  STRUDEL_INSTALL=(--install)
else
  STRUDEL_INSTALL=()
fi

if [[ -x "$STRUDEL_DIR/build-strudel-site.sh" ]]; then
  echo "==> Build Strudel with local deployment settings"
  "$STRUDEL_DIR/build-strudel-site.sh" "${STRUDEL_INSTALL[@]}"
else
  [[ -n "${STRUDEL_SITE_URL:-}" ]] || die "missing STRUDEL_SITE_URL and no local build-strudel-site.sh"
  [[ -n "${STRUDEL_BASE_PATH:-}" ]] || die "missing STRUDEL_BASE_PATH and no local build-strudel-site.sh"
  echo "==> Build Strudel with STRUDEL_SITE_URL/STRUDEL_BASE_PATH"
  "$STRUDEL_DIR/build-strudel.sh" \
    --site-url "$STRUDEL_SITE_URL" \
    --base-path "$STRUDEL_BASE_PATH" \
    "${STRUDEL_INSTALL[@]}"
fi

[[ -f "$DIST_DIR/web-app/index.html" ]] || die "web-app build output is missing"
[[ -f "$SIGNAL_DIR/dist/index.html" ]] || die "Signal build output is missing"
[[ -f "$STRUDEL_DIR/strudel-dist/index.html" ]] || die "Strudel build output is missing"

echo "==> Verified build outputs"
echo "    $DIST_DIR/web-app"
echo "    $SIGNAL_DIR/dist"
echo "    $STRUDEL_DIR/strudel-dist"

if [[ "$SKIP_UPLOAD" == true ]]; then
  echo "==> Upload skipped"
else
  echo "==> Upload web products"
  "$DIST_DIR/upload-web.sh"
fi

echo "==> Done"
