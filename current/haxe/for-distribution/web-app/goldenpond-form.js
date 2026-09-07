/**
 * Full Goldenpond form (chord DSL + N rhythm lines, audio, MIDI/export).
 *
 * Depends: goldenpond.js, GoldenpondPlayback, GoldenpondSoundfontPresets,
 * Soundfont CDN, Midi from @tonejs/midi (for download).
 *
 * @global GoldenpondFormWidget
 */
(function (global) {
  "use strict";

  var DEFAULT_LINES = [
    { pattern: "1/4 c 4", defaultK: 1, defaultN: 4, active: true, octave: 0, gate: 0.8 },
    { pattern: "3/4 > 4", defaultK: 3, defaultN: 4, active: true, octave: 0, gate: 0.5 },
    { pattern: "1/2 1 4", defaultK: 1, defaultN: 2, active: true, octave: -1, gate: 0.8 },
  ];

  function el(tag, attrs, html) {
    var n = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        if (k === "class") {
          n.className = attrs[k];
        } else {
          n.setAttribute(k, attrs[k]);
        }
      });
    }
    if (html != null) {
      n.innerHTML = html;
    }
    return n;
  }

  function getSelectedMode(modeVal) {
    var v = parseInt(String(modeVal), 10);
    switch (v) {
      case 0:
        return Mode.getMajorMode();
      case 1:
        return Mode.getMinorMode();
      case 2:
        return Mode.getHarmonicMinorMode();
      case 3:
        return Mode.getMelodicMinorMode();
      case 4:
        return Mode.getHarmonicMajorMode();
      case 5:
        return Mode.getHungarianMinorMode();
      case 6:
        return Mode.getDoubleHarmonicMajorMode();
      default:
        return Mode.getMajorMode();
    }
  }

  var NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

  function clamp(v, lo, hi) {
    return Math.max(lo, Math.min(hi, v));
  }

  function decomposeRootMidi(midi) {
    var safe = clamp(parseInt(String(midi), 10), 32, 96);
    return {
      noteIndex: ((safe % 12) + 12) % 12,
      octave: Math.floor(safe / 12) - 1,
    };
  }

  function composeRootMidi(noteIndex, octave) {
    return clamp((octave + 1) * 12 + noteIndex, 32, 96);
  }

  /**
   * @param {HTMLElement} container
   * @param {{
   *   lineCount?: number,
   *   showChordNames?: boolean,
   *   showPianoRollPreview?: boolean,
   *   rootInitial?: number,
   * }} opts
   */
  function mount(container, opts) {
    if (!container) {
      throw new Error("GoldenpondFormWidget.mount: missing container");
    }
    opts = opts || {};
    var lineCount = opts.lineCount != null ? opts.lineCount : 3;
    lineCount = Math.max(1, Math.min(lineCount, 12));
    var showChordNames = opts.showChordNames !== false;
    var showRoll = opts.showPianoRollPreview === true;

    var widget = el("div", { class: "goldenpond-form-widget gpf-widget" });
    var transport = el("div", { class: "gpf-transport" });
    var btnRow = el("div", { class: "gpf-btn-row" });
    var bPlay = el("button", { type: "button" }, "Play");
    var bStop = el("button", { type: "button" }, "Stop");
    var bMidi = el("button", { type: "button" }, "Download MIDI");
    var bSum = el("button", { type: "button" }, "Download summary");
    var bJson = el("button", { type: "button" }, "Download project JSON");
    btnRow.appendChild(bPlay);
    btnRow.appendChild(bStop);
    btnRow.appendChild(bMidi);
    btnRow.appendChild(bSum);
    btnRow.appendChild(bJson);
    transport.appendChild(btnRow);
    widget.appendChild(transport);

    var rootNoteSel = null;
    var rootOctave = null;
    var rootMidiOut = null;
    var modeSel = null;
    var chordLen = null;
    var chordLenOut = null;
    var bpmIn = null;
    var bpmOut = null;
    var chordsTa = null;
    var namesBox = null;
    var linePanels = [];

    function addGlobalRow(widgetRoot, lbl, ctl, extraClass) {
      var r = el("div", { class: "gpf-row" + (extraClass ? " " + extraClass : "") });
      r.appendChild(el("label", {}, lbl));
      r.appendChild(ctl);
      widgetRoot.appendChild(r);
      return ctl;
    }

    function makeRangeWithValue(id, min, max, value, valueClass) {
      var wrap = el("div", { class: "gpf-inline-control" });
      var input = /** @type {HTMLInputElement} */ (el("input", { type: "range", min: String(min), max: String(max), value: String(value), id: id }));
      var out = el("span", { class: valueClass || "gpf-inline-value" }, String(value));
      wrap.appendChild(input);
      wrap.appendChild(out);
      return { wrap: wrap, input: input, out: out };
    }

    function getRootMidi() {
      return composeRootMidi(parseInt(rootNoteSel.value, 10), parseInt(rootOctave.value, 10));
    }

    function syncRootDisplay() {
      rootMidiOut.textContent = String(getRootMidi());
    }

    var rootInitial = decomposeRootMidi(opts.rootInitial != null ? opts.rootInitial : 60);
    var rootWrap = el("div", { class: "gpf-root-control" });
    rootNoteSel = /** @type {HTMLSelectElement} */ (document.createElement("select"));
    rootNoteSel.id = "gpf-root-note";
    NOTE_NAMES.forEach(function (name, idx) {
      var o = document.createElement("option");
      o.value = String(idx);
      o.textContent = name;
      if (idx === rootInitial.noteIndex) {
        o.selected = true;
      }
      rootNoteSel.appendChild(o);
    });
    rootWrap.appendChild(rootNoteSel);
    var octaveCtl = makeRangeWithValue("gpf-root-oct", 1, 7, rootInitial.octave, "gpf-inline-value gpf-octave-value");
    rootOctave = octaveCtl.input;
    rootWrap.appendChild(octaveCtl.wrap);
    rootMidiOut = el("span", { class: "gpf-root-midi" }, "");
    rootWrap.appendChild(rootMidiOut);
    addGlobalRow(widget, "Root", rootWrap, "gpf-row-root");
    syncRootDisplay();

    modeSel = /** @type {HTMLSelectElement} */ (document.createElement("select"));
    modeSel.id = "gpf-mode";
    modeSel.className = "gpf-mode-select";
    [["0", "Major"], ["1", "Minor"], ["2", "Harmonic minor"], ["3", "Melodic minor"], ["4", "Harmonic major"], ["5", "Hungarian minor"], ["6", "Double harmonic major"]].forEach(function (p) {
      var o = document.createElement("option");
      o.value = p[0];
      o.textContent = p[1];
      modeSel.appendChild(o);
    });
    addGlobalRow(widget, "Mode", modeSel, "gpf-row-compact");

    var chordLenCtl = makeRangeWithValue("gpf-chord-len", 1, 16, 8);
    chordLen = chordLenCtl.input;
    chordLenOut = chordLenCtl.out;
    addGlobalRow(widget, "Chord duration", chordLenCtl.wrap);

    var bpmCtl = makeRangeWithValue("gpf-bpm", 40, 200, 120);
    bpmIn = bpmCtl.input;
    bpmOut = bpmCtl.out;
    addGlobalRow(widget, "BPM", bpmCtl.wrap);

    chordsTa = /** @type {HTMLTextAreaElement} */ (
      addGlobalRow(widget, "Chord sequence", el("textarea", { class: "gpf-chords", id: "gpf-chords" }))
    );
    chordsTa.value = "1,4,5,1";

    namesBox = el("div", { class: showChordNames ? "gpf-chord-names" : "gpf-chord-names gpf-hidden", id: "gpf-names" });
    namesBox.innerHTML = "<h3>Chord names</h3><p></p>";

    widget.appendChild(namesBox);

    /** @type {ReturnType<GoldenpondPlayback['create']>|null} */
    var playback = null;

    function ensurePlayback() {
      if (!playback) {
        var ctx = new (global.AudioContext || global.webkitAudioContext)();
        playback = global.GoldenpondPlayback.create(ctx, null);
      }
      return playback;
    }

    function lineDefaults(idx) {
      var d = DEFAULT_LINES[idx];
      if (d) {
        return Object.assign({}, d);
      }
      return { pattern: "1/4 c 4", defaultK: 1, defaultN: 4, active: idx === 0, octave: 0, gate: 0.75 };
    }

    var presetsSrc = global.GoldenpondSoundfontPresets;
    var defPresets =
      presetsSrc && presetsSrc.defaultLinePresets
        ? presetsSrc.defaultLinePresets
        : ["acoustic_grand_piano", "orchestral_harp", "acoustic_bass"];

    /** @typedef {{ panel:HTMLElement, chk:HTMLInputElement, preset:HTMLSelectElement, patt:HTMLInputElement, oct:HTMLInputElement, gate:HTMLInputElement, preview:HTMLElement }} LineUI */

    for (var i = 0; i < lineCount; i++) {
      var LD = lineDefaults(i);
      var panel = el("div", { class: "gpf-line-panel", "data-line": String(i) });
      panel.appendChild(el("h4", {}, "Pattern line " + (i + 1)));

      var lineHead = el("div", { class: "gpf-line-head" });
      var headLeft = el("div", { class: "gpf-line-head-left" });
      var chk = /** @type {HTMLInputElement} */ (document.createElement("input"));
      chk.type = "checkbox";
      chk.id = "gpf-line-" + i + "-on";
      chk.checked = LD.active;
      headLeft.appendChild(chk);
      var preset = /** @type {HTMLSelectElement} */ (document.createElement("select"));
      preset.id = "gpf-line-" + i + "-preset";
      preset.innerHTML = presetsSrc
        ? presetsSrc.presetOptionsHtml(defPresets[i] || "acoustic_grand_piano")
        : '<option value="acoustic_grand_piano">Piano</option>';
      headLeft.appendChild(preset);
      lineHead.appendChild(headLeft);
      panel.appendChild(lineHead);

      var patt = /** @type {HTMLInputElement} */ (document.createElement("input"));
      patt.type = "text";
      patt.className = "pattern-input";
      patt.id = "gpf-line-" + i + "-patt";
      patt.value = LD.pattern;
      panel.appendChild(patt);

      var grid = el("div", { class: "gpf-line-grid" });
      var colControls = el("div", { class: "gpf-line-controls" });
      var octRow = el("div", { class: "gpf-slider-row" });
      var lblOct = document.createElement("label");
      lblOct.htmlFor = "gpf-line-" + i + "-oct";
      lblOct.textContent = "Octave Transpose";
      octRow.appendChild(lblOct);
      var oct = /** @type {HTMLInputElement} */ (document.createElement("input"));
      oct.type = "range";
      oct.min = "-2";
      oct.max = "2";
      oct.step = "1";
      oct.value = String(LD.octave);
      oct.id = "gpf-line-" + i + "-oct";
      octRow.appendChild(oct);
      colControls.appendChild(octRow);

      var gateRow = el("div", { class: "gpf-slider-row" });
      var lblGate = document.createElement("label");
      lblGate.htmlFor = "gpf-line-" + i + "-gate";
      lblGate.textContent = "Gate";
      gateRow.appendChild(lblGate);
      var gate = /** @type {HTMLInputElement} */ (document.createElement("input"));
      gate.type = "range";
      gate.min = "0.1";
      gate.max = "1.0";
      gate.step = "0.05";
      gate.value = String(LD.gate);
      gate.id = "gpf-line-" + i + "-gate";
      gateRow.appendChild(gate);
      colControls.appendChild(gateRow);

      var colPv = el("div", {});
      colPv.appendChild(el("strong", {}, "Preview"));
      var preview = el("div", { class: "gpf-preview" + (showRoll ? "" : " gpf-hidden"), id: "gpf-prev-" + i });
      colPv.appendChild(preview);
      grid.appendChild(colControls);
      grid.appendChild(colPv);
      panel.appendChild(grid);

      linePanels.push({
        panel: panel,
        chk: chk,
        preset: preset,
        patt: patt,
        oct: oct,
        gate: gate,
        preview: preview,
      });
      widget.appendChild(panel);
    }

    function updateChordNames() {
      if (!showChordNames) {
        return;
      }
      var pGraph = namesBox.querySelector("p");
      if (!pGraph) {
        return;
      }
      try {
        var progression = new ChordProgression(
          getRootMidi(),
          getSelectedMode(modeSel.value),
          chordsTa.value
        );
        var arr = progression.getChordNames();
        pGraph.textContent = arr.join(" → ");
      } catch (e) {
        pGraph.textContent = String(e.message || e);
      }
    }

    /** @typedef {{ gd:GoldenData, lines: Array<{preset:string, notes:*, generator:*, panelIndex:number}>, tm: *, bpm:number }} BuildOut */

    /** @returns {BuildOut|null} */
    function buildCore() {
      try {
        var gd = new GoldenData();
        gd.root = getRootMidi();
        gd.mode = parseInt(modeSel.value, 10);
        gd.chordSequence = chordsTa.value;
        gd.bpm = parseInt(bpmIn.value, 10);
        gd.chordDuration = parseInt(chordLen.value, 10);
        gd.lines = [];

        var outLines = [];
        for (var li = 0; li < linePanels.length; li++) {
          var L = linePanels[li];
          if (!L.chk.checked) {
            continue;
          }
          var gLen = parseFloat(L.gate.value);
          var octSemi = parseInt(L.oct.value, 10) * 12;
          var ctx = new MidiInstrumentContext(outLines.length, 100, gLen, octSemi);
          gd.addLine(L.patt.value, ctx);
          var gen = gd.makeLineGenerator(gd.lines.length - 1);
          outLines.push({
            preset: L.preset.value,
            generator: gen,
            notes: gen.generateNotes(0),
            panelIndex: li,
          });
        }

        var tm = gd.makeTimeManipulator();

        return {
          gd: gd,
          lines: outLines,
          tm: tm,
          bpm: parseInt(bpmIn.value, 10),
        };
      } catch (e) {
        return null;
      }
    }

    function redrawPreviews(built) {
      if (!showRoll || !built) {
        return;
      }
      for (var i = 0; i < linePanels.length; i++) {
        linePanels[i].preview.innerHTML = "";
      }
      for (var j = 0; j < built.lines.length; j++) {
        var bl = built.lines[j];
        var pan = linePanels[bl.panelIndex];
        if (!pan || !pan.preview) {
          continue;
        }
        var rr = pan.preview.getBoundingClientRect();
        pan.preview.innerHTML = ScoreUtilities.makePianoRollSVG(bl.notes, rr.width || 280, rr.height || 120);
      }
    }

    function refresh() {
      syncNumericDisplays();
      var st = buildCore();
      redrawPreviews(st);
      updateChordNames();
    }

    function syncNumericDisplays() {
      syncRootDisplay();
      chordLenOut.textContent = chordLen.value;
      bpmOut.textContent = bpmIn.value;
    }

    syncNumericDisplays();

    var watch = [rootNoteSel, rootOctave, chordLen, bpmIn, modeSel, chordsTa];
    for (var wi = 0; wi < linePanels.length; wi++) {
      var lp = linePanels[wi];
      watch.push(lp.chk, lp.preset, lp.patt, lp.oct, lp.gate);
    }
    for (var wj = 0; wj < watch.length; wj++) {
      var nd = watch[wj];
      if (nd && nd.addEventListener) {
        nd.addEventListener("input", refresh);
        nd.addEventListener("change", refresh);
      }
    }

    container.appendChild(widget);
    refresh();

    bStop.addEventListener("click", function () {
      if (playback) {
        playback.stopAllHeld();
      }
    });

    bPlay.addEventListener("click", async function () {
      var built = buildCore();
      if (!built || built.lines.length === 0) {
        global.alert("Nothing to play — enable at least one line with a valid pattern.");
        return;
      }
      try {
        var pb = ensurePlayback();
        await pb.ensureAudio();
        pb.stopAllHeld();
        await pb.scheduleLayers({
          layers: built.lines.map(function (L) {
            return { notes: L.notes, instrumentPreset: L.preset };
          }),
          timeManipulator: built.tm,
          bpm: built.bpm,
        });
      } catch (e) {
        global.alert(String(e.message || e));
      }
    });

    bMidi.addEventListener("click", function () {
      var built = buildCore();
      if (!built || built.lines.length === 0) {
        global.alert("No active lines.");
        return;
      }
      try {
        var midi = global.GoldenpondPlayback.buildToneMidi({
          tracks: built.lines.map(function (L, idx) {
            return {
              lineIndex: idx,
              instrumentPreset: L.preset,
              notes: L.generator.generateNotes(0),
            };
          }),
          timeManipulator: built.tm,
          bpm: built.bpm,
        });
        GoldenpondPlayback.downloadMidiBlob(midi, "goldenpond.mid");
      } catch (e) {
        global.alert(String(e.message || e));
      }
    });

    bSum.addEventListener("click", function () {
      var built = buildCore();
      if (!built) {
        return;
      }
      var blob = new Blob([built.gd.toString()], { type: "text/plain" });
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = "goldenpond-project.txt";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });

    bJson.addEventListener("click", function () {
      var built = buildCore();
      if (!built) {
        return;
      }
      var blob = new Blob([built.gd.toJSON()], { type: "application/json" });
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = "goldenpond-project.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });

    return {
      destroy: function () {
        widget.remove();
      },
      refresh: refresh,
      getPlayback: function () {
        return playback;
      },
    };
  }

  global.GoldenpondFormWidget = { mount: mount };
})(typeof window !== "undefined" ? window : this);
