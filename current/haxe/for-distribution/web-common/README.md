# Goldenpond `web-common` (plain JS)

Static, **no npm build**: include these files with `goldenpond.js` (Haxe JS output) plus the
[soundfont-player](https://github.com/danigb/soundfont-player) CDN script. For MIDI file export,
also load `@tonejs/midi` (see `web-app/index.html`).

Files:

| File | Global | Role |
|------|--------|------|
| `goldenpond-soundfont-presets.js` | `GoldenpondSoundfontPresets` | Preset list, default line presets (3 lines), MIDI program map |
| `goldenpond-playback.js` | `GoldenpondPlayback` | Load GM presets, schedule note lists from `goldenpond.js`, Tone.js MIDI helpers |
| `goldenpond-embed.js` | `GoldenpondEmbed` | Initialise `.goldenpond-embed` blocks (HTML from `py/goldenpond_fences.py`) |
| `goldenpond-embed.css` | — | Scoped styles for embeds |
| `goldenpond-form.js` | `GoldenpondFormWidget` | Full chord + N-line UI |
| `goldenpond-form.css` | — | Form widget layout |

Suggested load order (embed only):

1. soundfont-player  
2. `goldenpond.js`  
3. `goldenpond-soundfont-presets.js`  
4. `goldenpond-playback.js`  
5. `goldenpond-embed.css`  
6. `goldenpond-embed.js`  

Add for the form (+ MIDI download): `@tonejs/midi`, `goldenpond-form.css`, `goldenpond-form.js`.

**Python:** the canonical fence helper is **`../py/goldenpond_fences.py`**. Consumers (e.g. PianoSlides and the Gilbert Lister site) vendor it beside their `generate.py` / `build.py` via their **shell build script**, then plain `from goldenpond_fences import …` — no hard-coded repo paths in Python.

Fenced blocks emit a `.goldenpond-meta` area whose rows (`Global`, progression, chord names, rhythm) are controlled by **`display=a,b,...`** on the fence line (`global`, `progression`, `chordnames`, `rhythm`; case-insensitive; comma-separated order). Omit `display=` to show all rows. The `<script type="application/json" class="goldenpond-data">` payload includes **`embedDisplay`** as the canonical row list used at build time; `GoldenpondEmbed` tolerates omitted rows.

