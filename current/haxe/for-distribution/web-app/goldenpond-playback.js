/**
 * Schedule Goldenpond-generated notes via soundfont-player.
 * Depends: Soundfont global (soundfont-player), goldenpond.js (GoldenData runtime).
 *
 * @global GoldenpondPlayback
 */
(function (global) {
  "use strict";

  var GM_VEL_GAIN_BOOST = 1.12;

  /**
   * @param {AudioContext} audioCtx
   * @param {GainNode|AudioNode|null} destination - optional; defaults to master -> destination
   */
  function create(audioCtx, destination) {
    if (!audioCtx) {
      throw new Error("GoldenpondPlayback.create: AudioContext required");
    }
    var master = destination;
    if (!master) {
      master = audioCtx.createGain();
      master.gain.value = 0.82;
      master.connect(audioCtx.destination);
    }

    /** @type {Record<string, any>} */
    var cache = {};

    function ensureSoundfont() {
      if (typeof Soundfont === "undefined" || typeof Soundfont.instrument !== "function") {
        throw new Error("soundfont-player not loaded (expected global Soundfont)");
      }
    }

    function stopAllHeld() {
      Object.keys(cache).forEach(function (k) {
        var inst = cache[k];
        if (inst && typeof inst.stop === "function") {
          try {
            inst.stop(audioCtx.currentTime);
          } catch (_) {}
        }
      });
    }

    function ensureAudio() {
      if (audioCtx.state === "suspended") {
        return audioCtx.resume();
      }
      return Promise.resolve();
    }

    /**
     * @param {string} presetName danigb instrument name eg acoustic_grand_piano
     */
    function loadPreset(presetName) {
      ensureSoundfont();
      if (cache[presetName]) {
        return Promise.resolve(cache[presetName]);
      }
      return Soundfont.instrument(audioCtx, presetName, { destination: master }).then(function (inst) {
        cache[presetName] = inst;
        return inst;
      });
    }

    /**
     * Pre-load several presets (single fan-in avoids duplicate requests).
     * @param {string[]} presetNames
     */
    function loadPresets(presetNames) {
      ensureSoundfont();
      var unique = presetNames.filter(function (n, i, a) {
        return n && a.indexOf(n) === i;
      });
      return Promise.all(unique.map(loadPreset)).then(function () {
        return cache;
      });
    }

    /**
     * @param {{
     *   notes: Array,
     *   timeManipulator: { ppq: number },
     *   bpm: number,
     *   instrumentPreset: string,
     *   baseLagSec?: number,
     * }} opts
     */
    function scheduleLine(opts) {
      var notes = opts.notes;
      var tm = opts.timeManipulator;
      var bpm = opts.bpm;
      var preset = opts.instrumentPreset || "acoustic_grand_piano";
      var baseLagSec = opts.baseLagSec != null ? opts.baseLagSec : 0.06;

      var spb = 60 / bpm;
      var ppq = tm.ppq;
      var base = audioCtx.currentTime + baseLagSec;

      var inst = cache[preset];
      if (!inst) {
        throw new Error("GoldenpondPlayback: preset not loaded: " + preset);
      }

      notes.forEach(function (n) {
        var startSec = (n.getStartTime() / ppq) * spb;
        var durSec = (n.getLength() / ppq) * spb;
        var midi = n.getMidiNoteValue();
        var vel = n.velocity != null ? n.velocity : 110;
        var gain = Math.min(1, Math.max(0.03, (vel / 127) * GM_VEL_GAIN_BOOST));
        inst.play(midi, base + Math.max(0, startSec), {
          duration: Math.max(0.035, durSec),
          gain: gain,
        });
      });

      return {};
    }

    /**
     * @param {{
     *   layers: Array<{ notes: *, instrumentPreset: string }>,
     *   timeManipulator: { ppq: number },
     *   bpm: number,
     *   baseLagSec?: number,
     * }} opts
     */
    async function scheduleLayers(opts) {
      await ensureAudio();
      stopAllHeld();
      var layers = opts.layers.filter(function (L) {
        return L && L.notes && L.notes.length;
      });
      var presets = layers.map(function (L) {
        return L.instrumentPreset || "acoustic_grand_piano";
      });
      await loadPresets(presets);

      layers.forEach(function (L) {
        scheduleLine({
          notes: L.notes,
          timeManipulator: opts.timeManipulator,
          bpm: opts.bpm,
          instrumentPreset: L.instrumentPreset,
          baseLagSec: opts.baseLagSec,
        });
      });

      return {};
    }

    return {
      audioContext: audioCtx,
      destination: master,
      GM_VEL_GAIN_BOOST: GM_VEL_GAIN_BOOST,
      ensureAudio: ensureAudio,
      loadPreset: loadPreset,
      loadPresets: loadPresets,
      scheduleLine: scheduleLine,
      scheduleLayers: scheduleLayers,
      stopAllHeld: stopAllHeld,
      clearTimers: function (timers) {
        (timers || []).forEach(function (id) {
          clearTimeout(id);
        });
      },
    };
  }

  /**
   * Iterate note timing in seconds (for UI sync e.g. piano key highlights).
   * @param {Array} notes
   * @param {{ ppq: number }} timeManipulator
   * @param {number} bpm
   * @param {function({midi:number,startSec:number,durSec:number,velocity:number}):void} fn
   */
  function iterNoteSchedule(notes, timeManipulator, bpm, fn) {
    if (!notes || !notes.length) {
      return;
    }
    var spb = 60 / bpm;
    var ppq = timeManipulator.ppq;
    notes.forEach(function (n) {
      var startSec = (n.getStartTime() / ppq) * spb;
      var durSec = (n.getLength() / ppq) * spb;
      fn({
        midi: n.getMidiNoteValue(),
        startSec: Math.max(0, startSec),
        durSec: Math.max(0, durSec),
        velocity: n.velocity != null ? n.velocity : 110,
      });
    });
  }

  global.GoldenpondPlayback = {
    create: create,
    iterNoteSchedule: iterNoteSchedule,

    /**
     * Build a Midi instance (Tone js) — caller must ensure `Midi` constructor exists (@tonejs/midi).
     * @param {{
     *   tracks: Array<{ notes: *, lineIndex: number, instrumentPreset?: string }>,
     *   timeManipulator: { ppq: number },
     *   bpm: number,
     *   midiProgramLookup?: function(preset:string):number
     * }} opts
     */
    buildToneMidi: function (opts) {
      if (typeof Midi === "undefined") {
        throw new Error("@tonejs/midi not loaded (expected global Midi)");
      }
      var midi = new Midi();
      var bpm = opts.bpm;
      var secondsPerBeat = 60.0 / bpm;
      var tm = opts.timeManipulator;

      midi.header.setTempo(bpm);
      midi.header.timeSignature = [4, 4];

      var midiProgramLookup =
        opts.midiProgramLookup ||
        function (preset) {
          if (global.GoldenpondSoundfontPresets && global.GoldenpondSoundfontPresets.midiProgramForPreset) {
            return global.GoldenpondSoundfontPresets.midiProgramForPreset(preset || "acoustic_grand_piano");
          }
          return 0;
        };

      opts.tracks.forEach(function (entry, index) {
        var track = midi.addTrack();
        track.channel = index;
        track.instrument.number =
          midiProgramLookup(entry.instrumentPreset || "acoustic_grand_piano");

        entry.notes.forEach(function (note) {
          track.addNote({
            midi: note.getMidiNoteValue(),
            time: (note.getStartTime() / tm.ppq) * secondsPerBeat,
            duration: (note.getLength() / tm.ppq) * secondsPerBeat,
            velocity: note.velocity != null ? note.velocity : 100,
          });
        });
      });

      return midi;
    },

    downloadMidiBlob: function (midi, filename) {
      var bytes = midi.toArray();
      var blob = new Blob([new Uint8Array(bytes)], { type: "audio/midi" });
      var url = global.URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = filename || "goldenpond.mid";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      global.URL.revokeObjectURL(url);
    },
  };
})(typeof window !== "undefined" ? window : this);
