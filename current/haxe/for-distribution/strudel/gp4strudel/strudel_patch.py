#!/usr/bin/env python3
"""Small, idempotent edits to files in an upstream Strudel checkout.

Integrations (GoldenPond, World of Cake, ...) patch Strudel with anchored
insertions instead of copying whole files over upstream's, so upstream changes
to the rest of a file are kept and several integrations can patch the same file.

  strudel_patch.py insert-before FILE ANCHOR TEXT
  strudel_patch.py insert-after  FILE ANCHOR TEXT
  strudel_patch.py json-set      FILE KEY.PATH JSON_VALUE

insert-before / insert-after
  ANCHOR is a complete line of FILE (leading/trailing whitespace ignored) that
  must occur exactly once. TEXT is one or more lines (use \\n) inserted on their
  own lines before/after it. If TEXT is already present anywhere in FILE, nothing
  changes. A missing or ambiguous anchor is an error: upstream changed, so the
  patch needs a human to look at it.

json-set
  Sets a value in a JSON file (e.g. `source.excludePattern`), rewriting it with
  2-space indentation. Idempotent.
"""

import json
import sys
from pathlib import Path


def fail(msg):
    print(f"strudel_patch: error: {msg}", file=sys.stderr)
    sys.exit(1)


def insert(path, anchor, text, after):
    p = Path(path)
    if not p.is_file():
        fail(f"no such file: {path}")
    content = p.read_text()
    text = text.replace("\\n", "\n")
    if text.strip() and text.strip() in content:
        print(f"  ok (already present) {path}")
        return
    lines = content.split("\n")
    hits = [i for i, line in enumerate(lines) if line.strip() == anchor.strip()]
    if len(hits) != 1:
        fail(f"anchor found {len(hits)} times (need exactly 1) in {path}:\n    {anchor}")
    i = hits[0]
    new = text.split("\n")
    lines[i + 1 if after else i:i + 1 if after else i] = new
    p.write_text("\n".join(lines))
    print(f"  patched {path}")


def json_set(path, keypath, value):
    p = Path(path)
    if not p.is_file():
        fail(f"no such file: {path}")
    data = json.loads(p.read_text())
    new_value = json.loads(value)
    node = data
    keys = keypath.split(".")
    for k in keys[:-1]:
        if not isinstance(node.get(k), dict):
            fail(f"{keypath}: {k} is not an object in {path}")
        node = node[k]
    if node.get(keys[-1]) == new_value:
        print(f"  ok (already set) {path} {keypath}")
        return
    node[keys[-1]] = new_value
    p.write_text(json.dumps(data, indent=2) + "\n")
    print(f"  patched {path} {keypath}")


def main(argv):
    if len(argv) != 5 or argv[1] not in ("insert-before", "insert-after", "json-set"):
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    cmd, path, a, b = argv[1:]
    if cmd == "json-set":
        json_set(path, a, b)
    else:
        insert(path, a, b, after=(cmd == "insert-after"))


if __name__ == "__main__":
    main(sys.argv)
