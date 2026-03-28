#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

failures=0
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_test() {
    local label="$1"
    shift
    local log_file="$tmp_dir/${label// /_}.log"

    echo
    echo "=== $label ==="

    "$@" >"$log_file" 2>&1
    local status=$?

    cat "$log_file"

    if [ "$status" -eq 0 ] && grep -Eq 'Errors:[[:space:]]*0([[:space:]]|$)' "$log_file"; then
        echo "PASS: $label"
    else
        echo "FAIL: $label"
        failures=$((failures + 1))
    fi
}

run_test "Haxe interpreter" haxe --interp -cp src/goldenpond --main TestGoldenPond
run_test "Python target" haxe py-tests.hxml
run_test "JavaScript target" haxe js-tests.hxml
run_test "C++ target" haxe build-cpp.hxml
run_test "Java target" ./test-on-java.sh

echo
echo "=== Summary ==="
if [ "$failures" -eq 0 ]; then
    echo "All language targets passed."
    exit 0
fi

echo "$failures target(s) failed."
exit 1
