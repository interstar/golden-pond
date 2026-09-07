"""
Shared build-time helpers for Goldenpond fenced blocks in Markdown.

**Source of truth** in this repository. Sites vend a copy of this file beside their
``generate.py`` / ``build.py`` from their shell build script (Python imports locally only).
See ``web-common/README.md``.

Fenced syntax::

    ```goldenpond root=60 mode=major bpm=120 chordDuration=8 gate=0.75 octave=0 display=global,progression,chordnames,rhythm
    1,4,5,1
    c. 4
    ```

Opening line carries optional ``key=value`` tokens; body is exactly two non-empty
lines — chord DSL, then rhythm DSL.
"""

from __future__ import annotations

import html
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
    "4": 4,
    "harmonic_major": 4,
    "hmajor": 4,
    "hmj": 4,
    "harmonicmajor": 4,
    "5": 5,
    "hungarian_minor": 5,
    "hungarian": 5,
    "hu": 5,
    "6": 6,
    "double_harmonic_major": 6,
    "doubleharmonicmajor": 6,
    "byzantine": 6,
    "h2": 6,
}

NOTE_NAMES = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")

MODE_LABELS = ("Major", "Minor", "Harmonic minor", "Melodic minor", "Harmonic major", "Hungarian minor", "Double harmonic major")

# Order of meta rows in the embed UI (subset keys)
DEFAULT_EMBED_SECTIONS_ORDER = ("global", "progression", "chordnames", "rhythm")

# ``display=a,b,c`` token → canonical section id (lowercase keys)
_EMBED_SECTION_ALIASES: dict[str, str] = {
    "global": "global",
    "globals": "global",
    "progression": "progression",
    "prog": "progression",
    "chordnames": "chordnames",
    "chord_names": "chordnames",
    "names": "chordnames",
    "rhythm": "rhythm",
}


def _canonical_embed_sections(parts: list[str]) -> list[str]:
    """Parse display= tokens; preserve first-seen order; dedupe."""
    allowed = frozenset(DEFAULT_EMBED_SECTIONS_ORDER)
    out: list[str] = []
    seen: set[str] = set()
    for raw in parts:
        if not raw.strip():
            continue
        lk = raw.strip().lower().replace("-", "").replace("_", "").replace(" ", "")
        norm = _EMBED_SECTION_ALIASES.get(lk)
        if norm is None and lk in allowed:
            norm = lk
        if norm is None or norm not in allowed or norm in seen:
            continue
        seen.add(norm)
        out.append(norm)
    return out


def _format_global_summary_line(cfg: Mapping[str, Any]) -> str:
    root = int(cfg.get("root", 60))
    mode_i = int(cfg.get("mode", 0))
    bpm = int(cfg.get("bpm", 120))
    chd = int(cfg.get("chordDuration", 8))
    gate = float(cfg.get("gate", 0.75))
    octv = int(cfg.get("octave", 0))
    inst = str(cfg.get("instrumentPreset") or "").strip()

    pitch = NOTE_NAMES[root % 12]
    oct_label = root // 12 - 1
    key_disp = f"{pitch}{oct_label}"
    ml = MODE_LABELS[mode_i] if 0 <= mode_i < len(MODE_LABELS) else f"mode {mode_i}"
    if mode_i in (0, 1):
        ml_disp = ml.lower()
    else:
        ml_disp = ml

    parts: list[str] = [
        f"Key: {key_disp} {ml_disp}",
        f"BPM: {bpm}",
        f"Chord duration: {chd}",
    ]
    if gate != GOLDENPOND_DEFAULTS["gate"]:
        gstr = str(int(gate)) if gate == int(gate) else f"{gate:.2f}".rstrip("0").rstrip(".")
        parts.append(f"Gate: {gstr}")
    if octv != 0:
        sign = "+" if octv > 0 else ""
        parts.append(f"Octave: {sign}{octv}")
    if inst:
        parts.append(f"Sound: {inst}")
    return " · ".join(parts)


def parse_goldenpond_fence_params(param_line: str) -> dict[str, Any]:
    """Parse key=value tokens from the text after ``goldenpond`` on the same line."""
    cfg: MutableMapping[str, Any] = dict(GOLDENPOND_DEFAULTS)
    line = (param_line or "").strip()
    embed_display_was_set = False

    def _finalize_display() -> None:
        if not embed_display_was_set:
            cfg["embedDisplay"] = list(DEFAULT_EMBED_SECTIONS_ORDER)

    if not line:
        _finalize_display()
        return cfg

    for raw in line.split():
        if "=" not in raw:
            continue
        key, _, val = raw.partition("=")
        key = key.strip().lower()
        val = val.strip()
        if key in ("chordduration", "duration"):
            key = "chordDuration"
        if key == "display":
            parts = [p for p in (s.strip() for s in val.split(",")) if p]
            cfg["embedDisplay"] = _canonical_embed_sections(parts)
            embed_display_was_set = True
            continue
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
    _finalize_display()
    return cfg


def _embed_json_payload(cfg: Mapping[str, Any]) -> dict[str, Any]:
    """Strip internal keys before embedding JSON for the frontend."""
    return {k: v for k, v in dict(cfg).items() if not str(k).startswith("_")}


def render_goldenpond_embed_html(cfg: Mapping[str, Any]) -> str:
    """Stable HTML scaffold for JS initialisation (.goldenpond-embed)."""
    sections: list[str] = list(cfg.get("embedDisplay") or list(DEFAULT_EMBED_SECTIONS_ORDER))
    chord_seq = str(cfg.get("chordSequence", ""))
    rhythm = str(cfg.get("rhythm", ""))
    global_line = _format_global_summary_line(cfg)

    row_html: dict[str, str] = {
        "global": (
            '<div class="goldenpond-row goldenpond-row--global">'
            '<span class="goldenpond-label">Global</span> '
            f'<span class="goldenpond-global-summary">{html.escape(global_line)}</span></div>\n'
        ),
        "progression": (
            '<div class="goldenpond-row goldenpond-row--progression">'
            '<span class="goldenpond-label">Progression</span> '
            f'<code class="goldenpond-chord-seq">{html.escape(chord_seq)}</code></div>\n'
        ),
        "chordnames": (
            '<div class="goldenpond-row goldenpond-row--chord-names">'
            '<span class="goldenpond-label">Chord names</span> '
            "<span class=\"goldenpond-chord-names\"></span></div>\n"
        ),
        "rhythm": (
            '<div class="goldenpond-row goldenpond-row--rhythm">'
            '<span class="goldenpond-label">Rhythm</span> '
            f'<code class="goldenpond-rhythm-code">{html.escape(rhythm)}</code></div>\n'
        ),
    }

    meta_rows_parts = [row_html[s] for s in sections if s in row_html]
    meta_inner = "".join(meta_rows_parts)

    json_str = json.dumps(_embed_json_payload(cfg), ensure_ascii=False)
    return (
        '<div class="goldenpond-embed">\n'
        f'<script type="application/json" class="goldenpond-data">{json_str}</script>\n'
        '<div class="goldenpond-toolbar">\n'
        '<button type="button" class="goldenpond-play">Play</button>\n'
        "</div>\n"
        '<div class="goldenpond-meta">\n'
        f"{meta_inner}"
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
