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
  if (m === 'hmajor' || m === 'harmonic_major' || m === 'harmonic major') return 4;
  if (m === 'hungarian' || m === 'hungarian_minor' || m === 'hungarian minor') return 5;
  if (m === 'double_harmonic_major' || m === 'double harmonic major' || m === 'dhmajor' || m === 'byzantine') return 6;
  throw new Error(`gpond: unknown mode "${s}" (use major, minor, hminor, mminor, hmajor, hungarian, double_harmonic_major)`);
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

function isVisualRhythmPattern(value) {
  return value && typeof value === 'object' && value.__goldenpondVis === true;
}

function isVisualChordSequence(value) {
  return value && typeof value === 'object' && value.__goldenpondChordVis === true;
}

function normalizeRhythmPattern(value) {
  if (isVisualRhythmPattern(value)) return value;
  return { pattern: value, locations: [] };
}

function normalizeChordSequence(value) {
  if (isVisualChordSequence(value)) return value;
  return { sequence: value, locations: [] };
}

function getGoldenPondRhythmLocations(input, offset = 0) {
  if (typeof input !== 'string') return [];
  const trimmedStart = input.search(/\S/);
  if (trimmedStart < 0) return [];
  let trimmedEnd = input.length;
  while (trimmedEnd > trimmedStart && /\s/.test(input[trimmedEnd - 1])) trimmedEnd--;
  const text = input.slice(trimmedStart, trimmedEnd);
  const base = offset + trimmedStart;
  return getExplicitRhythmLocations(text, base) ?? getGeneratedRhythmLocations(text, base) ?? [];
}

function getExplicitRhythmLocations(text, base) {
  const match = /^(\S+)\s+[0-9]+(?:\/[0-9]+)?$/.exec(text);
  if (!match) return null;
  const steps = match[1];
  const locs = [];
  for (let i = 0; i < steps.length; i++) {
    if (steps[i] !== '.') {
      locs.push({ start: base + i, end: base + i + 1 });
    }
  }
  return locs;
}

function getGeneratedRhythmLocations(text, base) {
  const match = /^([0-9]+)[/%][0-9]+(?:\+[0-9]+)?\s+[><rcCbdtRpP0-9]\s+[0-9]+(?:\/[0-9]+)?$/.exec(text);
  if (!match) return null;
  return [{ start: base, end: base + match[1].length }];
}

export function vis(rhythmPattern, sourceOffset = 0) {
  assertPlainStringParam('vis rhythmPattern (1st argument)', rhythmPattern);
  return {
    __goldenpondVis: true,
    pattern: rhythmPattern,
    sourceOffset,
    locations: getGoldenPondRhythmLocations(rhythmPattern, sourceOffset),
  };
}

function getGoldenPondChordLocations(input, offset = 0) {
  if (typeof input !== 'string') return [];
  const locs = [];
  let i = 0;
  while (i < input.length) {
    const ch = input[i];
    if (isChordSeparator(ch)) {
      i++;
      continue;
    }
    if (ch === '&') {
      i++;
      continue;
    }
    if (ch === '!' || ch === '>' || ch === '<') {
      i = readChordDirective(input, i);
      continue;
    }
    const start = i;
    i = readChordAtom(input, i);
    if (i > start) {
      locs.push({ start: offset + start, end: offset + i });
    } else {
      i++;
    }
  }
  return locs;
}

function isChordSeparator(ch) {
  return ch === ',' || ch === '|' || /\s/.test(ch);
}

function readChordDirective(input, start) {
  let i = start + 1;
  while (i < input.length && !isChordSeparator(input[i]) && input[i] !== '&') i++;
  return i;
}

function readChordAtom(input, start) {
  let i = start;
  let depth = 0;
  while (i < input.length) {
    const ch = input[i];
    if (ch === '(' || ch === '[') depth++;
    if ((ch === ')' || ch === ']') && depth > 0) depth--;
    if (depth === 0 && (isChordSeparator(ch) || ch === '&')) break;
    i++;
  }
  return i;
}

export function vc(chordSequence, sourceOffset = 0) {
  assertPlainStringParam('vc chordSequence (1st argument)', chordSequence);
  return {
    __goldenpondChordVis: true,
    sequence: chordSequence,
    sourceOffset,
    locations: getGoldenPondChordLocations(chordSequence, sourceOffset),
  };
}

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
 * @param {string} modeStr - major | minor | hminor | mminor | hmajor | hungarian | double_harmonic_major
 * @param {string} chordSequence - e.g. "1,5,6,4"
 * @param {number} chordDuration - chord length in beats (GoldenPond chordDuration)
 * @param {object} [extra] - optional: bpm, ppq, stutter (GoldenPond defaults apply if omitted)
 */
export function gpond(root, modeStr, chordSequence, chordDuration, extra = {}) {
  assertPlainStringParam('mode (2nd argument)', modeStr);
  const visualChords = normalizeChordSequence(chordSequence);
  assertPlainStringParam('chordSequence (3rd argument)', visualChords.sequence);
  const { GoldenData } = getGpClasses();
  const gd = new GoldenData();
  gd.root = root;
  gd.mode = modeFromString(modeStr);
  gd.chordSequence = visualChords.sequence;
  gd.__goldenpondVisualChords = visualChords;
  if (chordDuration != null) gd.chordDuration = chordDuration;
  if (extra.bpm != null) gd.bpm = extra.bpm;
  if (extra.ppq != null) gd.ppq = extra.ppq;
  if (extra.stutter != null) gd.stutter = extra.stutter;
  return gd;
}

/** GoldenPond times in integer ticks (avoids float drift vs Strudel Fraction scheduling). */
function notesToTickEvents(notes, visualRhythm = null, visualChords = null, chordTicks = null) {
  const rhythmLocations = visualRhythm?.locations || [];
  const chordLocations = visualChords?.locations || [];
  let rhythmLocationIndex = -1;
  let previousStartTicks = null;
  return (notes || []).map((n) => {
    const startTicks = Math.round(n.getStartTime());
    if (startTicks !== previousStartTicks) {
      rhythmLocationIndex++;
      previousStartTicks = startTicks;
    }
    const locations = [];
    if (chordLocations.length && chordTicks > 0) {
      const chordIndex = Math.max(0, Math.floor(startTicks / chordTicks));
      locations.push(chordLocations[chordIndex % chordLocations.length]);
    }
    if (rhythmLocations.length) {
      locations.push(rhythmLocations[rhythmLocationIndex % rhythmLocations.length]);
    }
    return {
      startTicks,
      durTicks: Math.round(n.getLength()),
      midi: n.getMidiNoteValue(),
      gain: Math.min(1, Math.max(0, ((n.velocity != null ? n.velocity : 100) / 127))),
      locations,
    };
  });
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
        const context = e.locations?.length ? { locations: e.locations } : {};
        out.push(new Hap(whole, part, { note: e.midi, gain: e.gain }, context));
      }
    }
    return out;
  }).splitQueries();
}

function notesToPattern(notes, timeManipulator, goldenData, options = {}) {
  const ppq = Math.round(Number(timeManipulator.ppq)) || 960;
  const beatsPerCycle = GOLDENPOND_BEATS_PER_CYCLE;
  const chordTicks = Math.round(Number(timeManipulator.chordTicks)) || Math.round((Number(goldenData?.chordDuration) || 4) * ppq);
  const events = notesToTickEvents(notes, options.visualRhythm, goldenData?.__goldenpondVisualChords, chordTicks);
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
  const visualRhythm = normalizeRhythmPattern(rhythmPattern);
  assertPlainStringParam('rhythmPattern (2nd argument)', visualRhythm.pattern);
  const baseOptions =
    typeof third === 'number'
      ? { ...(typeof fourth === 'object' && fourth !== null ? fourth : {}), octave: third }
      : third && typeof third === 'object'
        ? third
        : {};
  const options = { ...baseOptions, visualRhythm };
  const ctx = instrumentContextForGpline(options);
  goldenData.addLine(visualRhythm.pattern, ctx);
  const lineIndex = goldenData.lines.length - 1;
  return lineFromGoldenData(goldenData, lineIndex, options);
}
