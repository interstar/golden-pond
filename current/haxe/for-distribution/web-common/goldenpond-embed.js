/**
 * Initialise `.goldenpond-embed` fenced blocks produced at build time.
 *
 * Depends: goldenpond.js, goldenpond-playback.js, optionally goldenpond-embed.css
 *
 * @global GoldenpondEmbed
 */
(function (global) {
  "use strict";

  /** @typedef {{ setKeyLit?: function(number, boolean): void }} GH */

  /** @typedef {{
   *   root?: Document|HTMLElement,
   *   playback?: object,
   *   createPlayback?: function(): object,
   *   keyboardHighlight?: GH,
   *   reveal?: object,
   *   instrumentPreset?: string,
   *   showPianoRoll?: boolean,
   *   showChordNames?: boolean,
   *   baseLagSec?: number,
   * }} EmbedInitOpts */

  var _singletonPb = null;

  function slidesPianoRollLayout() {
    var pl = new PianoRollLayout();
    pl.fitPitchRange = true;
    pl.gridStyle = PianoRollGridStyle.OctavesOnly;
    pl.gridStroke = "#4a4a4a";
    pl.noteFill = "#8bc34a";
    pl.noteStroke = "#2e4a22";
    pl.pitchPadSemitones = 3;
    pl.minPitchSpanSemitones = 8;
    pl.minNoteWidthPx = 2;
    pl.minNoteHeightPx = 3;
    return pl;
  }

  function goldenpondFillMeta(embed, cfg, showChordNames) {
    var seqEl = embed.querySelector(".goldenpond-chord-seq");
    var rhythmEl = embed.querySelector(".goldenpond-rhythm-code");
    var namesEl = embed.querySelector(".goldenpond-chord-names");
    var namesRow = embed.querySelector(".goldenpond-row--chord-names");
    if (!showChordNames && namesRow) {
      namesRow.classList.add("goldenpond-hidden");
    } else if (namesRow) {
      namesRow.classList.remove("goldenpond-hidden");
    }
    if (seqEl) {
      seqEl.textContent = cfg.chordSequence || "";
    }
    if (rhythmEl) {
      rhythmEl.textContent = cfg.rhythm || "";
    }
    if (!showChordNames) {
      if (namesEl) {
        namesEl.textContent = "";
      }
      return;
    }
    if (namesEl) {
      try {
        if (typeof ChordProgression === "undefined") {
          namesEl.textContent = "";
          return;
        }
        var gdMini = new GoldenData();
        gdMini.root = cfg.root;
        gdMini.mode = cfg.mode;
        var progression = new ChordProgression(cfg.root, gdMini.makeMode(), cfg.chordSequence);
        var arr = progression.getChordNames();
        namesEl.textContent = Array.isArray(arr) ? arr.join(" → ") : String(arr);
      } catch (e) {
        namesEl.textContent = e && e.message ? e.message : String(e);
      }
    }
  }

  function goldenpondBuildNotes(cfg) {
    var gd = new GoldenData();
    gd.root = cfg.root;
    gd.mode = cfg.mode;
    gd.chordSequence = cfg.chordSequence;
    gd.bpm = cfg.bpm;
    gd.chordDuration = cfg.chordDuration;
    gd.lines = [];
    var gate = cfg.gate != null ? cfg.gate : 0.75;
    var octSemis = (cfg.octave != null ? cfg.octave : 0) * 12;
    var ctx = new MidiInstrumentContext(0, 100, gate, octSemis);
    gd.addLine(cfg.rhythm, ctx);
    var notes = gd.makeLineGenerator(0).generateNotes(0);
    var tm = gd.makeTimeManipulator();
    return { notes: notes, tm: tm, bpm: cfg.bpm };
  }

  function goldenpondLayoutRoll(embed, notes, showPianoRoll) {
    var rollEl = embed.querySelector(".goldenpond-roll");
    if (!rollEl) {
      return;
    }
    if (!showPianoRoll) {
      rollEl.classList.add("goldenpond-hidden");
      rollEl.innerHTML = "";
      return;
    }
    rollEl.classList.remove("goldenpond-hidden");
    var w = Math.min(1100, Math.max(480, embed.clientWidth || 800));
    var h = 300;
    rollEl.innerHTML = ScoreUtilities.makePianoRollSVGAdvanced(notes, w, h, slidesPianoRollLayout());
  }

  function ensurePlayback(opts) {
    if (opts.playback) {
      return opts.playback;
    }
    if (opts.createPlayback) {
      return opts.createPlayback();
    }
    if (!_singletonPb) {
      var ctx = new (global.AudioContext || global.webkitAudioContext)();
      _singletonPb = global.GoldenpondPlayback.create(ctx, null);
    }
    return _singletonPb;
  }

  /**
   * @param {HTMLElement} embed
   * @param {EmbedInitOpts} opts
   */
  function initOne(embed, opts) {
    if (embed.dataset.goldenpondReady === "1") {
      return;
    }
    var errEl = embed.querySelector(".goldenpond-error");
    var dataEl = embed.querySelector(".goldenpond-data");
    if (
      typeof GoldenData === "undefined" ||
      typeof MidiInstrumentContext === "undefined" ||
      typeof ScoreUtilities === "undefined" ||
      typeof PianoRollLayout === "undefined" ||
      typeof PianoRollGridStyle === "undefined"
    ) {
      if (errEl) {
        errEl.hidden = false;
        errEl.textContent = "goldenpond.js not loaded.";
      }
      return;
    }
    if (!dataEl) {
      return;
    }

    var showPianoRoll = opts.showPianoRoll !== false;
    var showChordNames = opts.showChordNames !== false;
    var gh = opts.keyboardHighlight || {};
    /** @type {any} */
    var cfg;
    try {
      cfg = JSON.parse(dataEl.textContent);
    } catch (e) {
      if (errEl) {
        errEl.hidden = false;
        errEl.textContent = "Invalid Goldenpond embed data.";
      }
      return;
    }

    var instrumentPreset = cfg.instrumentPreset || opts.instrumentPreset || "acoustic_grand_piano";

    goldenpondFillMeta(embed, cfg, showChordNames);
    try {
      var built = goldenpondBuildNotes(cfg);
      var notes = built.notes;
      var tm = built.tm;
      var bpm = cfg.bpm != null ? cfg.bpm : built.bpm;
      embed._goldenpondNotes = notes;
      embed._goldenpondTm = tm;
      embed._goldenpondBpm = bpm;
      embed._goldenpondPlayTimers = [];

      goldenpondLayoutRoll(embed, notes, showPianoRoll);
      if (showPianoRoll && global.ResizeObserver) {
        var ro = new ResizeObserver(function () {
          goldenpondLayoutRoll(embed, embed._goldenpondNotes, showPianoRoll);
        });
        ro.observe(embed);
      }

      var btn = embed.querySelector(".goldenpond-play");
      if (btn && !embed._goldenpondPlayBound) {
        embed._goldenpondPlayBound = true;
        btn.addEventListener("click", async function () {
          /** @type {any} */
          var pb;
          try {
            pb = ensurePlayback(opts);
          } catch (e) {
            if (errEl) {
              errEl.hidden = false;
              errEl.textContent = e && e.message ? String(e.message) : String(e);
            }
            return;
          }

          await pb.ensureAudio();
          (embed._goldenpondPlayTimers || []).forEach(global.clearTimeout);
          embed._goldenpondPlayTimers = [];
          var timers = [];

          pb.stopAllHeld();

          try {
            await pb.loadPresets([instrumentPreset]);
          } catch (e) {
            if (errEl) {
              errEl.hidden = false;
              errEl.textContent = e && e.message ? String(e.message) : String(e);
            }
            return;
          }

          if (errEl) {
            errEl.hidden = true;
          }

          await pb.scheduleLayers({
            layers: [{ notes: notes, instrumentPreset: instrumentPreset }],
            timeManipulator: tm,
            bpm: bpm,
            baseLagSec: opts.baseLagSec != null ? opts.baseLagSec : 0.06,
          });

          GoldenpondPlayback.iterNoteSchedule(notes, tm, bpm, function (ev) {
            if (!gh.setKeyLit) {
              return;
            }

            timers.push(
              global.setTimeout(function () {
                gh.setKeyLit(ev.midi, true);
              }, Math.max(0, ev.startSec * 1000))
            );

            timers.push(
              global.setTimeout(function () {
                gh.setKeyLit(ev.midi, false);
              }, Math.max(0, (ev.startSec + ev.durSec) * 1000))
            );
          });

          embed._goldenpondPlayTimers = timers;
        });
      }
    } catch (e2) {
      if (errEl) {
        errEl.hidden = false;
        errEl.textContent = e2 && e2.message ? String(e2.message) : String(e2);
      }
      return;
    }
    embed.dataset.goldenpondReady = "1";
  }

  function scan(rootEl, opts) {
    /** @type {ParentNode} */
    var root = rootEl || document;
    root.querySelectorAll(".goldenpond-embed").forEach(function (el) {
      initOne(el, opts || {});
    });
  }

  function stopAll(opts) {
    opts = opts || {};
    var root = opts.root || document;
    root.querySelectorAll(".goldenpond-embed").forEach(function (embed) {
      (embed._goldenpondPlayTimers || []).forEach(global.clearTimeout);
      embed._goldenpondPlayTimers = [];
    });
    var pb = opts.playback || _singletonPb;
    if (pb && pb.stopAllHeld) {
      pb.stopAllHeld();
    }
    if (opts && opts.keyboardHighlight && typeof opts.keyboardHighlight.releaseHeldNotes === "function") {
      opts.keyboardHighlight.releaseHeldNotes();
    }
    if (opts && opts.keyboardHighlight && opts.keyboardHighlight.clearAllKeys) {
      opts.keyboardHighlight.clearAllKeys();
    }
  }

  /**
   * @param {EmbedInitOpts} opts
   */
  function init(opts) {
    opts = opts || {};
    var root = opts.root || document.body;
    scan(root, opts);
    var reve = opts.reveal;
    if (reve && typeof reve.on === "function") {
      reve.on("slidechanged", function (ev) {
        stopAll({
          root: document,
          playback: opts.playback,
          keyboardHighlight: opts.keyboardHighlight,
        });
        if (ev && ev.currentSlide) {
          scan(ev.currentSlide, opts);
        }
      });
    }
  }

  global.GoldenpondEmbed = {
    init: init,
    scan: scan,
    stopAll: stopAll,
    singletonPlayback: function () {
      return _singletonPb;
    },
  };
})(typeof window !== "undefined" ? window : this);
