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
      default:
        return Mode.getMajorMode();
    }
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

    var rootSlider = null;
    var modeSel = null;
    var chordLen = null;
    var bpmIn = null;
    var chordsTa = null;
    var namesBox = null;
    var linePanels = [];

    function addGlobalRow(widgetRoot, lbl, ctl) {
      var r = el("div", { class: "gpf-row" });
      r.appendChild(el("label", {}, lbl));
      r.appendChild(ctl);
      widgetRoot.appendChild(r);
      return ctl;
    }

    rootSlider = /** @type {HTMLInputElement} */ (
      addGlobalRow(widget, "Root (MIDI)", el("input", { type: "range", min: "32", max: "96", value: String(opts.rootInitial != null ? opts.rootInitial : 60), id: "gpf-root" }))
    );

    rootSlider.id = "gpf-root";

    modeSel = /** @type {HTMLSelectElement} */ (document.createElement("select"));
    modeSel.id = "gpf-mode";
    [["0", "Major"], ["1", "Minor"], ["2", "Harmonic minor"], ["3", "Melodic minor"]].forEach(function (p) {
      var o = document.createElement("option");
      o.value = p[0];
      o.textContent = p[1];
      modeSel.appendChild(o);
    });
    addGlobalRow(widget, "Mode", modeSel);

    chordLen = /** @type {HTMLInputElement} */ (
      addGlobalRow(widget, "Chord duration", el("input", { type: "range", min: "1", max: "16", value: "8", id: "gpf-chord-len" }))
    );
    bpmIn = /** @type {HTMLInputElement} */ (
      addGlobalRow(widget, "BPM", el("input", { type: "range", min: "40", max: "200", value: "120", id: "gpf-bpm" }))
    );

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

      var lblAct = document.createElement("label");
      var chk = /** @type {HTMLInputElement} */ (document.createElement("input"));
      chk.type = "checkbox";
      chk.id = "gpf-line-" + i + "-on";
      chk.checked = LD.active;
      lblAct.appendChild(chk);
      lblAct.appendChild(document.createTextNode(" Active"));
      panel.appendChild(lblAct);

      var lblInst = document.createElement("label");
      lblInst.htmlFor = "gpf-line-" + i + "-preset";
      lblInst.textContent = "Instrument";
      panel.appendChild(lblInst);
      var preset = /** @type {HTMLSelectElement} */ (document.createElement("select"));
      preset.id = "gpf-line-" + i + "-preset";
      preset.innerHTML = presetsSrc
        ? presetsSrc.presetOptionsHtml(defPresets[i] || "acoustic_grand_piano")
        : '<option value="acoustic_grand_piano">Piano</option>';
      panel.appendChild(preset);

      var lblPatt = document.createElement("label");
      lblPatt.htmlFor = "gpf-line-" + i + "-patt";
      lblPatt.textContent = "Pattern";
      panel.appendChild(lblPatt);
      var patt = /** @type {HTMLInputElement} */ (document.createElement("input"));
      patt.type = "text";
      patt.className = "pattern-input";
      patt.id = "gpf-line-" + i + "-patt";
      patt.value = LD.pattern;
      panel.appendChild(patt);

      var grid = el("div", { class: "gpf-line-grid" });
      var colControls = el("div", {});
      var lblOct = document.createElement("label");
      lblOct.htmlFor = "gpf-line-" + i + "-oct";
      lblOct.textContent = "Octave transpose";
      colControls.appendChild(lblOct);
      var oct = /** @type {HTMLInputElement} */ (document.createElement("input"));
      oct.type = "range";
      oct.min = "-2";
      oct.max = "2";
      oct.step = "1";
      oct.value = String(LD.octave);
      oct.id = "gpf-line-" + i + "-oct";
      colControls.appendChild(oct);

      var lblGate = document.createElement("label");
      lblGate.htmlFor = "gpf-line-" + i + "-gate";
      lblGate.textContent = "Gate";
      colControls.appendChild(lblGate);
      var gate = /** @type {HTMLInputElement} */ (document.createElement("input"));
      gate.type = "range";
      gate.min = "0.1";
      gate.max = "1.0";
      gate.step = "0.05";
      gate.value = String(LD.gate);
      gate.id = "gpf-line-" + i + "-gate";
      colControls.appendChild(gate);

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
          parseInt(rootSlider.value, 10),
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
        gd.root = parseInt(rootSlider.value, 10);
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
      var st = buildCore();
      redrawPreviews(st);
      updateChordNames();
    }

    var watch = [rootSlider, chordLen, bpmIn, modeSel, chordsTa];
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
