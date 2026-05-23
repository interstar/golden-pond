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

Python fences live in **`../py/goldenpond_fences.py`** (`process_goldenpond_embeds`), shared by PianoSlides and the Gilbert Lister site builder.
