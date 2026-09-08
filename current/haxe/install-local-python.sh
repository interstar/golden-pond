#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYPI_DIR="$SCRIPT_DIR/for-distribution/pypi"
PYTHON_BIN="${PYTHON_BIN:-python3}"

[[ -f "$PYPI_DIR/pyproject.toml" ]] || {
  echo "install-local-python.sh: missing Python package at $PYPI_DIR" >&2
  exit 1
}

[[ -f "$PYPI_DIR/goldenpond/goldenpond.py" ]] || {
  echo "install-local-python.sh: generated goldenpond.py is missing; run makeall.sh first" >&2
  exit 1
}

echo "Installing local GoldenPond Python package with $PYTHON_BIN"
"$PYTHON_BIN" -m pip install --editable "$PYPI_DIR"
