#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

INSTALL_LOCAL_PYTHON=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-local-python)
      INSTALL_LOCAL_PYTHON=false
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./makeall.sh [--skip-local-python]

Build the GoldenPond targets and refresh their distribution copies.

By default, install the generated Python package into the active Python
environment in editable mode. Use --skip-local-python to opt out.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: ./makeall.sh [--skip-local-python]" >&2
      exit 2
      ;;
  esac
done

haxe py-lib.hxml
haxe js-site.hxml
./build-java-lib.sh

cp out/python/goldenpond.py for-distribution/pypi/goldenpond/goldenpond.py
cp out/python/goldenpond.py for-distribution/fl/generated.py

if [[ "$INSTALL_LOCAL_PYTHON" == true ]]; then
  ./install-local-python.sh
fi

cp out/js/goldenpond.js for-distribution/web-app/goldenpond.js
cp for-distribution/web-common/goldenpond-form.css for-distribution/web-app/goldenpond-form.css
cp for-distribution/web-common/goldenpond-soundfont-presets.js for-distribution/web-app/goldenpond-soundfont-presets.js
cp for-distribution/web-common/goldenpond-playback.js for-distribution/web-app/goldenpond-playback.js
cp for-distribution/web-common/goldenpond-form.js for-distribution/web-app/goldenpond-form.js
cp out/js/goldenpond.js for-distribution/xenwich/src/libs/goldenpond/goldenpond.js
# Strudel website imports ../../../../goldenpond.js from website/src/repl/ → this path
cp out/js/goldenpond.js for-distribution/strudel/goldenpond.js
cp out/js/goldenpond.js for-distribution/signal/app/public/goldenpond.js
