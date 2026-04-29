/**
 * GoldenPond → Strudel adapter
 *
 * Builds a Strudel Pattern whose query returns Haps with absolute cycle positions
 * (whole = true note span; part = intersection with the query window).
 * Depends on global `strudel` from strudel.js (Pattern, Hap, TimeSpan, Fraction).
 */
(function (global) {
  'use strict';

  function notesToTickEvents(notes) {
    return (notes || []).map(function (n) {
      return {
        startTicks: Math.round(n.getStartTime()),
        durTicks: Math.round(n.getLength()),
        midi: n.getMidiNoteValue(),
        gain: Math.min(1, Math.max(0, ((n.velocity != null ? n.velocity : 100) / 127))),
      };
    });
  }

  function phraseBeatsFromGoldenData(goldenData) {
    try {
      var prog = goldenData.makeChordProgression();
      var things = prog.toChordThings();
      var n = things && things.length ? things.length : 1;
      var dur = Number(goldenData.chordDuration) || 4;
      var bpc = 4;
      return Math.max(bpc, n * dur);
    } catch (e) {
      return 4;
    }
  }

  function resolveLoopTicks(events, goldenData, options, ppq) {
    if (options && options.loopBeats != null && isFinite(options.loopBeats) && options.loopBeats > 0) {
      return Math.round(options.loopBeats * ppq);
    }
    var maxEndTicks = 0;
    for (var i = 0; i < events.length; i++) {
      var e = events[i];
      maxEndTicks = Math.max(maxEndTicks, e.startTicks + e.durTicks);
    }
    var phraseBeats = goldenData != null ? phraseBeatsFromGoldenData(goldenData) : 4;
    var phraseTicks = Math.round(phraseBeats * ppq);
    return Math.max(phraseTicks, maxEndTicks > 0 ? maxEndTicks : phraseTicks);
  }

  function buildPatternFromTickEvents(events, loopTicks, ppq, beatsPerCycle, Pattern, Hap, TimeSpan, Fraction) {
    var ticksPerCycle = Math.round(ppq * beatsPerCycle);
    var ticksPerCycleFr = Fraction(ticksPerCycle);
    // Strudel's `Fraction` export is one-arg only; Fraction(p,q) ignores q — use .div().
    var loopSpanCycles = Fraction(loopTicks).div(ticksPerCycleFr);
    return new Pattern(function (state) {
      var span = state.span;
      var qB = span.begin;
      var qE = span.end;
      var out = [];
      var kMin = Math.floor(Number(qB.div(loopSpanCycles))) - 1;
      var kMax = Math.ceil(Number(qE.div(loopSpanCycles))) + 1;
      for (var k = kMin; k <= kMax; k++) {
        var offset = Fraction(k).mul(loopSpanCycles);
        for (var j = 0; j < events.length; j++) {
          var e = events[j];
          var wB = Fraction(e.startTicks).div(ticksPerCycleFr).add(offset);
          var wE = Fraction(e.startTicks + e.durTicks).div(ticksPerCycleFr).add(offset);
          if (wE.lte(qB) || wB.gte(qE)) continue;
          var whole = new TimeSpan(wB, wE);
          var part = whole.intersection(span);
          if (!part) continue;
          out.push(new Hap(whole, part, { note: e.midi, gain: e.gain }));
        }
      }
      return out;
    }).splitQueries();
  }

  /**
   * @param {Array} notes - GoldenPond note objects (getStartTime/getLength/getMidiNoteValue/velocity)
   * @param {object} timeManipulator - must expose .ppq (ticks per quarter)
   * @param {object} [options]
   * @param {number} [options.beatsPerCycle=4] - Strudel cycles; one cycle spans this many quarter-note beats
   * @param {number} [options.loopBeats] - phrase length in quarter-note beats (overrides auto length)
   * @param {object} [options.goldenData] - when set, loop length is at least full chord progression span
   */
  function notesToPattern(notes, timeManipulator, options) {
    var S = global.strudel;
    if (!S || !S.Pattern || !S.Hap || !S.TimeSpan || !S.Fraction) {
      throw new Error('strudel bundle (Pattern/Hap/TimeSpan/Fraction) must load before goldenpond-strudel.js');
    }
    var ppq = Math.round(Number(timeManipulator.ppq)) || 960;
    var beatsPerCycle = options && options.beatsPerCycle != null ? options.beatsPerCycle : 4;
    var events = notesToTickEvents(notes);
    var gd = options && options.goldenData;
    var loopTicks = resolveLoopTicks(events, gd, options || {}, ppq);
    return buildPatternFromTickEvents(events, loopTicks, ppq, beatsPerCycle, S.Pattern, S.Hap, S.TimeSpan, S.Fraction);
  }

  /**
   * One GoldenData line → Strudel Pattern (uses makeTimeManipulator + makeLineGenerator).
   * @param {GoldenData} goldenData
   * @param {number} lineIndex - index into goldenData.lines
   * @param {object} [options] - passed to notesToPattern (goldenData merged in for loop length)
   */
  function lineFromGoldenData(goldenData, lineIndex, options) {
    var tm = goldenData.makeTimeManipulator();
    var gen = goldenData.makeLineGenerator(lineIndex);
    var notes = gen.generateNotes(0);
    var opt = Object.assign({}, options || {}, { goldenData: goldenData });
    return notesToPattern(notes, tm, opt);
  }

  global.goldenpondStrudel = {
    notesToPattern: notesToPattern,
    lineFromGoldenData: lineFromGoldenData,
  };
})(typeof window !== 'undefined' ? window : globalThis);
