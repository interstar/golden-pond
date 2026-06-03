/**
 * GoldenPond (Haxe JS) + Strudel bridge: `gpond` / `gpline`.
 * GoldenPond score time → Strudel cycles via a fixed beats-per-cycle (quarter notes per cycle).
 * Tempo is Strudel CPS only; GoldenPond bpm/ppq affect note timing *within* the score, not the global clock.
 *
 * `./goldenpond-runtime.js` is the Haxe bundle (copy of `goldenpond.js`). Produced by `build-strudel.sh`
 * or `cp goldenpond.js …/goldenpond-runtime.js` — see `gp4strudel/README.md`.
 */
import './goldenpond-runtime.js';
import { Fraction, Pattern, Hap, TimeSpan } from '@strudel/core';

export const packageName = '@goldenpond/strudel';

/** Quarter-note beats per Strudel cycle (fixed; matches typical 4/4 bar). */
export const GOLDENPOND_BEATS_PER_CYCLE = 4;

function strudelDoubleQuoteHint() {
  return `In the Strudel REPL, "double-quoted" strings are transpiled to mini notation (not plain JS strings). Use single-quoted strings for GoldenPond text, e.g. gpond(60, 'major', '1,5,6,4', 4) — see transpiler plugin-mini (doublequotes).`;
}

function assertPlainStringParam(paramLabel, value) {
  if (typeof value === 'string') return;
  if (typeof value === 'object' && value !== null) {
    throw new Error(`GoldenPond: ${paramLabel} must be a JavaScript string. ${strudelDoubleQuoteHint()}`);
  }
}

function modeFromString(s) {
  const m = String(s ?? 'major').toLowerCase();
  if (m === 'major') return 0;
  if (m === 'minor') return 1;
  if (m === 'hminor' || m === 'harmonic_minor' || m === 'harmonic minor') return 2;
  if (m === 'mminor' || m === 'melodic_minor' || m === 'melodic minor') return 3;
  throw new Error(`gpond: unknown mode "${s}" (use major, minor, hminor, mminor)`);
}

function getGpClasses() {
  const GoldenData = globalThis.GoldenData;
  const MidiInstrumentContext = globalThis.MidiInstrumentContext;
  if (!GoldenData || !MidiInstrumentContext) {
    throw new Error('GoldenPond JS not loaded (GoldenData / MidiInstrumentContext missing)');
  }
  return { GoldenData, MidiInstrumentContext };
}

/** Default line context: channel unused in Strudel; gate ~0.8; transpose 0. */
export function goldenpondDefaultInstrumentContext() {
  const { MidiInstrumentContext } = getGpClasses();
  return new MidiInstrumentContext(0, 100, 0.8, 0);
}

/** Whole-octave offset → semitones for `MidiInstrumentContext.transpose`. */
function octaveToTranspose(oct) {
  const n = Number(oct);
  if (!Number.isFinite(n)) return 0;
  return Math.round(n * 12);
}

/**
 * @param {object} options - `octave` / `octaveOffset` (whole octaves), optional `instrumentContext` base
 */
function instrumentContextForGpline(options = {}) {
  const { MidiInstrumentContext } = getGpClasses();
  const delta = octaveToTranspose(options.octave ?? options.octaveOffset ?? 0);
  const base = options.instrumentContext;
  if (base != null) {
    return new MidiInstrumentContext(
      base.chan,
      base.velocity,
      base.gateLength,
      (base.transpose ?? 0) + delta,
    );
  }
  return new MidiInstrumentContext(0, 100, 0.8, delta);
}

/**
 * @param {number} root - MIDI note number of the key root
 * @param {string} modeStr - major | minor | hminor | mminor
 * @param {string} chordSequence - e.g. "1,5,6,4"
 * @param {number} chordDuration - chord length in beats (GoldenPond chordDuration)
 * @param {object} [extra] - optional: bpm, ppq, stutter (GoldenPond defaults apply if omitted)
 */
export function gpond(root, modeStr, chordSequence, chordDuration, extra = {}) {
  assertPlainStringParam('mode (2nd argument)', modeStr);
  assertPlainStringParam('chordSequence (3rd argument)', chordSequence);
  const { GoldenData } = getGpClasses();
  const gd = new GoldenData();
  gd.root = root;
  gd.mode = modeFromString(modeStr);
  gd.chordSequence = chordSequence;
  if (chordDuration != null) gd.chordDuration = chordDuration;
  if (extra.bpm != null) gd.bpm = extra.bpm;
  if (extra.ppq != null) gd.ppq = extra.ppq;
  if (extra.stutter != null) gd.stutter = extra.stutter;
  return gd;
}

/** GoldenPond times in integer ticks (avoids float drift vs Strudel Fraction scheduling). */
function notesToTickEvents(notes) {
  return (notes || []).map((n) => ({
    startTicks: Math.round(n.getStartTime()),
    durTicks: Math.round(n.getLength()),
    midi: n.getMidiNoteValue(),
    gain: Math.min(1, Math.max(0, ((n.velocity != null ? n.velocity : 100) / 127))),
  }));
}

/**
 * One full pass through the chord list, in GoldenPond quarter-note beats
 * (each chord lasts goldenData.chordDuration beats).
 */
function phraseBeatsFromGoldenData(goldenData) {
  try {
    const prog = goldenData.makeChordProgression();
    const things = prog.toChordThings();
    const n = things && things.length ? things.length : 1;
    const dur = Number(goldenData.chordDuration) || 4;
    return Math.max(GOLDENPOND_BEATS_PER_CYCLE, n * dur);
  } catch {
    return GOLDENPOND_BEATS_PER_CYCLE;
  }
}

/** Loop length in ticks (integer); at least phrase span and note span. */
function resolveLoopTicks(events, goldenData, options, ppq) {
  if (options?.loopBeats != null && isFinite(options.loopBeats) && options.loopBeats > 0) {
    return Math.round(options.loopBeats * ppq);
  }
  let maxEndTicks = 0;
  for (let i = 0; i < events.length; i++) {
    const e = events[i];
    maxEndTicks = Math.max(maxEndTicks, e.startTicks + e.durTicks);
  }
  const phraseBeats = goldenData != null ? phraseBeatsFromGoldenData(goldenData) : GOLDENPOND_BEATS_PER_CYCLE;
  const phraseTicks = Math.round(phraseBeats * ppq);
  return Math.max(phraseTicks, maxEndTicks > 0 ? maxEndTicks : phraseTicks);
}

/**
 * @param {Array<{startTicks:number,durTicks:number,midi:number,gain:number}>} events
 * @param {number} loopTicks - phrase repeat period in PPQ ticks (integer)
 * @param {number} ppq - pulses per quarter
 * @param {number} beatsPerCycle - quarter notes per Strudel cycle
 */
function buildPatternFromTickEvents(events, loopTicks, ppq, beatsPerCycle) {
  const ticksPerCycle = Math.round(ppq * beatsPerCycle);
  const ticksPerCycleFr = Fraction(ticksPerCycle);
  // Strudel's exported `Fraction` is a one-arg helper; never use Fraction(p,q) — the second arg is ignored.
  const loopSpanCycles = Fraction(loopTicks).div(ticksPerCycleFr);
  return new Pattern((state) => {
    const span = state.span;
    const qB = span.begin;
    const qE = span.end;
    const out = [];
    const kMin = Math.floor(Number(qB.div(loopSpanCycles))) - 1;
    const kMax = Math.ceil(Number(qE.div(loopSpanCycles))) + 1;
    for (let k = kMin; k <= kMax; k++) {
      const offset = Fraction(k).mul(loopSpanCycles);
      for (let j = 0; j < events.length; j++) {
        const e = events[j];
        const wB = Fraction(e.startTicks).div(ticksPerCycleFr).add(offset);
        const wE = Fraction(e.startTicks + e.durTicks).div(ticksPerCycleFr).add(offset);
        if (wE.lte(qB) || wB.gte(qE)) continue;
        const whole = new TimeSpan(wB, wE);
        const part = whole.intersection(span);
        if (!part) continue;
        out.push(new Hap(whole, part, { note: e.midi, gain: e.gain }));
      }
    }
    return out;
  }).splitQueries();
}

function notesToPattern(notes, timeManipulator, goldenData, options = {}) {
  const ppq = Math.round(Number(timeManipulator.ppq)) || 960;
  const beatsPerCycle = GOLDENPOND_BEATS_PER_CYCLE;
  const events = notesToTickEvents(notes);
  const loopTicks = resolveLoopTicks(events, goldenData, options, ppq);
  return buildPatternFromTickEvents(events, loopTicks, ppq, beatsPerCycle);
}

function lineFromGoldenData(goldenData, lineIndex, options = {}) {
  const tm = goldenData.makeTimeManipulator();
  const gen = goldenData.makeLineGenerator(lineIndex);
  const notes = gen.generateNotes(0);
  return notesToPattern(notes, tm, goldenData, options);
}

/**
 * Appends a line to `goldenData` and returns a Strudel Pattern for that line.
 * @param {object} goldenData - GoldenData instance
 * @param {string} rhythmPattern - GoldenPond rhythm DSL
 * @param {number|object} [third] - if a number: whole-octave offset (e.g. 1 = +12 semitones). If an object: options (see below).
 * @param {object} [fourth] - when `third` is a number, optional extra options merged in (e.g. `{ loopBeats: 32 }`).
 *   When `third` is an options object: `octave` / `octaveOffset` (whole octaves, added to `instrumentContext.transpose`),
 *   `instrumentContext`, `loopBeats`, etc.
 */
export function gpline(goldenData, rhythmPattern, third, fourth) {
  assertPlainStringParam('rhythmPattern (2nd argument)', rhythmPattern);
  const options =
    typeof third === 'number'
      ? { ...(typeof fourth === 'object' && fourth !== null ? fourth : {}), octave: third }
      : third && typeof third === 'object'
        ? third
        : {};
  const ctx = instrumentContextForGpline(options);
  goldenData.addLine(rhythmPattern, ctx);
  const lineIndex = goldenData.lines.length - 1;
  return lineFromGoldenData(goldenData, lineIndex, options);
}
