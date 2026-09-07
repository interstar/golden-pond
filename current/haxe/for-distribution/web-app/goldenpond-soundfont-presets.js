/**
 * Curated presets for danigb/soundfont-player (CDN build).
 * Also maps preset name -> GM program number for Tone.js MIDI export (approximate).
 * @global
 */
(function (global) {
  "use strict";

  /** @type {Array<{value:string,label:string,program:number}>} */
  var PRESETS = [
    { value: "acoustic_grand_piano", label: "Acoustic Grand Piano", program: 0 },
    { value: "electric_piano_1", label: "Electric Piano 1", program: 4 },
    { value: "electric_piano_2", label: "Electric Piano 2", program: 5 },
    { value: "harpsichord", label: "Harpsichord", program: 6 },
    { value: "orchestral_harp", label: "Orchestral Harp", program: 46 },
    { value: "church_organ", label: "Church Organ", program: 19 },
    { value: "tuba", label: "Tuba", program: 58 },
    { value: "muted_trumpet", label: "Muted Trumpet", program: 59 },
    { value: "soprano_sax", label: "Soprano Sax", program: 64 },
    { value: "alto_sax", label: "Alto Sax", program: 65 },
    { value: "tenor_sax", label: "Tenor Sax", program: 66 },
    { value: "clarinet", label: "Clarinet", program: 71 },
    { value: "flute", label: "Flute", program: 73 },
    { value: "acoustic_guitar_steel", label: "Acoustic Guitar (steel)", program: 25 },
    { value: "acoustic_guitar_nylon", label: "Acoustic Guitar (nylon)", program: 24 },
    { value: "electric_guitar_clean", label: "Electric Guitar (clean)", program: 27 },
    { value: "electric_guitar_muted", label: "Electric Guitar (muted)", program: 28 },
    { value: "acoustic_bass", label: "Acoustic Bass", program: 32 },
    { value: "electric_bass_finger", label: "Electric Bass (finger)", program: 33 },
    { value: "violin", label: "Violin", program: 40 },
    { value: "cello", label: "Cello", program: 42 },
    { value: "timpani", label: "Timpani", program: 47 },
    { value: "string_ensemble_1", label: "String Ensemble 1", program: 48 },
    { value: "synth_strings_1", label: "Synth Strings 1", program: 50 },
    { value: "voice_oohs", label: "Voice Oohs", program: 53 },
    { value: "trumpet", label: "Trumpet", program: 56 },
    { value: "music_box", label: "Music Box", program: 10 },
    { value: "vibraphone", label: "Vibraphone", program: 11 },
    { value: "marimba", label: "Marimba", program: 12 },
    { value: "woodblock", label: "Woodblock", program: 115 },
  ];

  var byValue = {};
  PRESETS.forEach(function (p) {
    byValue[p.value] = p;
  });

  global.GoldenpondSoundfontPresets = {
    presets: PRESETS,

    /** Default instrument per pattern line when lineCount === 3 */
    defaultLinePresets: [
      "acoustic_grand_piano",
      "orchestral_harp",
      "acoustic_bass",
    ],

    midiProgramForPreset: function (presetValue) {
      var p = byValue[presetValue];
      return p ? p.program : 0;
    },

    presetOptionsHtml: function (selectedValue) {
      selectedValue = selectedValue || "acoustic_grand_piano";
      return PRESETS.map(function (p) {
        var sel = p.value === selectedValue ? " selected" : "";
        return '<option value="' + p.value + '"' + sel + ">" + p.label + "</option>";
      }).join("");
    },
  };
})(typeof window !== "undefined" ? window : this);
