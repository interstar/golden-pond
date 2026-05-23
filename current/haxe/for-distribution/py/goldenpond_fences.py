"""
Shared build-time helpers for Goldenpond fenced blocks in Markdown.

Used by PianoSlides `generate.py` and the Gilbert Lister Research `build.py`.

Fenced syntax::

    ```goldenpond root=60 mode=major bpm=120 chordDuration=8 gate=0.75 octave=0
    1,4,5,1
    c. 4
    ```

Opening line carries optional ``key=value`` tokens; body is exactly two non-empty
lines — chord DSL, then rhythm DSL.
"""

from __future__ import annotations

import json
import re
from typing import Any, Callable, Mapping, MutableMapping

__all__ = [
    "GOLDENPOND_DEFAULTS",
    "MODE_ALIASES",
    "parse_goldenpond_fence_params",
    "render_goldenpond_embed_html",
    "process_goldenpond_embeds",
]

GOLDENPOND_DEFAULTS: dict[str, Any] = {
    "root": 60,
    "mode": 0,
    "bpm": 120,
    "chordDuration": 8,
    "gate": 0.75,
    "octave": 0,
}

MODE_ALIASES: dict[str, int] = {
    "0": 0,
    "major": 0,
    "maj": 0,
    "ionian": 0,
    "1": 1,
    "minor": 1,
    "min": 1,
    "aeolian": 1,
    "2": 2,
    "harmonic_minor": 2,
    "hm": 2,
    "harmonic": 2,
    "3": 3,
    "melodic_minor": 3,
    "mm": 3,
    "melodic": 3,
}


def parse_goldenpond_fence_params(param_line: str) -> dict[str, Any]:
    """Parse key=value tokens from the text after ``goldenpond`` on the same line."""
    cfg: MutableMapping[str, Any] = dict(GOLDENPOND_DEFAULTS)
    if not param_line or not param_line.strip():
        return cfg
    for raw in param_line.split():
        if "=" not in raw:
            continue
        key, _, val = raw.partition("=")
        key = key.strip().lower()
        val = val.strip()
        if key in ("chordduration", "duration"):
            key = "chordDuration"
        if key == "mode":
            lk = val.lower()
            if lk.isdigit():
                cfg["mode"] = int(lk)
            elif lk in MODE_ALIASES:
                cfg["mode"] = MODE_ALIASES[lk]
            continue
        if key == "instrument":
            cfg["instrumentPreset"] = val
            continue
        if key not in ("root", "bpm", "chordDuration", "gate", "octave"):
            continue
        try:
            if key == "octave":
                cfg[key] = int(val)
            elif key == "gate":
                cfg["gate"] = float(val)
            else:
                cfg[key] = int(val)
        except ValueError:
            pass
    return cfg


def render_goldenpond_embed_html(cfg: Mapping[str, Any]) -> str:
    """Stable HTML scaffold for JS initialisation (.goldenpond-embed)."""
    json_str = json.dumps(dict(cfg), ensure_ascii=False)
    return (
        '<div class="goldenpond-embed">\n'
        f'<script type="application/json" class="goldenpond-data">{json_str}</script>\n'
        '<div class="goldenpond-toolbar">\n'
        '<button type="button" class="goldenpond-play">Play</button>\n'
        "</div>\n"
        '<div class="goldenpond-meta">\n'
        '<div class="goldenpond-row"><span class="goldenpond-label">Progression</span> '
        '<code class="goldenpond-chord-seq"></code></div>\n'
        '<div class="goldenpond-row goldenpond-row--chord-names"><span class="goldenpond-label">Chord names</span> '
        '<span class="goldenpond-chord-names"></span></div>\n'
        '<div class="goldenpond-row"><span class="goldenpond-label">Rhythm</span> '
        '<code class="goldenpond-rhythm-code"></code></div>\n'
        "</div>\n"
        '<div class="goldenpond-roll" role="img" aria-label="Piano roll"></div>\n'
        '<p class="goldenpond-error" hidden></p>\n'
        "</div>\n"
    )


def _replace_fence_default(match: re.Match[str]) -> str:
    param_line = match.group(1).strip()
    body = match.group(2)
    lines = [ln.strip() for ln in body.splitlines() if ln.strip()]
    if len(lines) < 2:
        return (
            '<div class="goldenpond-embed goldenpond-embed--error">'
            "<p><strong>Goldenpond:</strong> need two lines (chord language, then rhythm language).</p>"
            "</div>"
        )
    chord_line, rhythm_line = lines[0], lines[1]
    cfg = parse_goldenpond_fence_params(param_line)
    cfg_dict = dict(cfg)
    cfg_dict["chordSequence"] = chord_line
    cfg_dict["rhythm"] = rhythm_line
    return render_goldenpond_embed_html(cfg_dict)


def process_goldenpond_embeds(
    content: str,
    *,
    repl: Callable[[re.Match[str]], str] | None = None,
) -> str:
    """
    Replace ``goldenpond ...`` fenced blocks in *content* **before** running Markdown.

    If *repl* is omitted, uses the default HTML embed (matching PianoSlides historically).
    """
    pattern = re.compile(r"```goldenpond[ \t]*([^\n]*)\n([\s\S]*?)```", re.MULTILINE)
    fn = repl or _replace_fence_default
    return pattern.sub(fn, content)
