/*
GoldenPond
Copyright (C) 2024 Phil Jones

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

To understand the GNU Affero General Public License see <https://www.gnu.org/licenses/>.
*/

package;

import ChordParser;
import ChordThing;
import Mode;
import TimedSequence;
import ScoreUtilities;

// Add this typedef at the top of the file, after the imports
typedef GoldenDataJson = {
    var root: Int;
    var mode: Int;
    var chordSequence: String;
    var stutter: Int;
    var bpm: Int;
    var chordDuration: Int;
    var ppq: Int;
    var correctionTarget: Null<Int>;
    var lines: Array<LineDataJson>;
}

/**
 * GoldenData - A class to store and serialize all project data
 * This allows for consistent project representation across all platforms
 */
@:expose
class GoldenData {
    // Core progression parameters
    public var root:Int;
    public var mode:Int; // 0=major, 1=minor, 2=harmonic minor, 3=melodic minor, 4=harmonic major, 5=hungarian minor, 6=double harmonic major
    public var correctionTarget:Int; // 0=scale (default), 1=pentatonic (key), 2=chord tones only, 3=pentatonic (per-chord)
    public var chordSequence:String;
    public var stutter:Int;
    
    // Timing parameters
    public var bpm:Int;
    public var chordDuration:Int;
    public var ppq:Int;
    
    // Line data - each entry contains pattern and instrument context
    public var lines:Array<LineData>;
    
    // Track if data has changed
    private var lastSerializedString:String;
    
    // Correction cache: immutable after build, rebuilt lazily when relevant state changes.
    private var corrector:GoldenCorrector;
    private var correctionBuildCount:Int;

    // Cached copies of the correction-relevant fields. ensureCorrector() compares these
    // directly (no string serialization) to detect changes without allocating.
    private var cacheRoot:Int;
    private var cacheMode:Int;
    private var cacheCorrectionTarget:Int;
    private var cacheChordSequence:String;
    private var cacheStutter:Int;
    private var cacheBpm:Int;
    private var cacheChordDuration:Int;
    private var cachePpq:Int;
    
    @:expose
    public function new() {
        this.root = 60; // Default to C4
        this.mode = 0;  // Default to major
        this.correctionTarget = 0; // Default to scale correction
        this.chordSequence = "1,4,5,1";
        this.stutter = 0;
        this.bpm = 120;
        this.chordDuration = 4;
        this.ppq = 960;
        this.lines = [];
        this.lastSerializedString = "";
        this.corrector = null;
        this.correctionBuildCount = 0;
        this.cacheRoot = 0;
        this.cacheMode = 0;
        this.cacheCorrectionTarget = 0;
        this.cacheChordSequence = "";
        this.cacheStutter = 0;
        this.cacheBpm = 0;
        this.cacheChordDuration = 0;
        this.cachePpq = 0;
    }
    
    /**
     * Add a line to the project
     * @param pattern The rhythm pattern string
     * @param instrumentContext The instrument context for this line
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function addLine(pattern:String, instrumentContext:IInstrumentContext):GoldenData {
        lines.push(new LineData(pattern, instrumentContext));
        return this;
    }
    
    /**
     * Set the mode by index
     * @param modeIndex 0=major, 1=minor, 2=harmonic minor, 3=melodic minor, 4=harmonic major, 5=hungarian minor, 6=double harmonic major
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function setMode(modeIndex:Int):GoldenData {
        this.mode = modeIndex;
        return this;
    }
    
    /**
     * Set the correction target.
     * @param target 0=scale (default), 1=pentatonic (key), 2=chord tones only, 3=pentatonic (per-chord)
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function setCorrectionTarget(target:Int):GoldenData {
        this.correctionTarget = target;
        return this;
    }
    
    /**
     * Set the PPQ (Pulses Per Quarter note)
     * @param ppq The new PPQ value
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function setPPQ(ppq:Int):GoldenData {
        this.ppq = ppq;
        return this;
    }
    
    /**
     * Make the Mode object corresponding to the current mode index
     * @return The Mode object
     */
    @:expose
    public function makeMode():Mode {
        switch (this.mode) {
            case 0: return Mode.getMajorMode();
            case 1: return Mode.getMinorMode();
            case 2: return Mode.getHarmonicMinorMode();
            case 3: return Mode.getMelodicMinorMode();
            case 4: return Mode.getHarmonicMajorMode();
            case 5: return Mode.getHungarianMinorMode();
            case 6: return Mode.getDoubleHarmonicMajorMode();
            default: return Mode.getMajorMode();
        }
    }
    
    /**
     * Make a chord progression from the current settings
     * @return The chord progression
     */
    @:expose
    public function makeChordProgression():IChordProgression {
        var baseProgression = new ChordProgression(this.root, this.makeMode(), this.chordSequence);
        if (this.stutter > 0) {
            return new StutteredChordProgression(baseProgression, this.stutter);
        }
        return baseProgression;
    }
    
    /**
     * Make a time manipulator from the current settings
     * @return The time manipulator
     */
    @:expose
    public function makeTimeManipulator():TimeManipulator {
        return new TimeManipulator()
            .setPPQ(this.ppq)
            .setChordDuration(this.chordDuration)
            .setBPM(this.bpm);
    }
    
    /**
     * Make a line generator for the specified line
     * @param lineIndex The index of the line to generate
     * @return The line generator
     */
    @:expose
    public function makeLineGenerator(lineIndex:Int):ILineGenerator {
        if (lineIndex < 0 || lineIndex >= this.lines.length) {
            throw 'Invalid line index: $lineIndex';
        }
        
        var line = this.lines[lineIndex];
        var timeManipulator = this.makeTimeManipulator();
        var progression = this.makeChordProgression();
    
        
        return LineGenerator.createFromPattern(timeManipulator, progression, line.pattern, line.instrumentContext);
    }
    
    /**
     * Check if the data has changed since last serialization
     * @return True if the data has changed
     */
    @:expose
    public function hasChanged():Bool {
        var currentString = this.toJSON();
        var changed = currentString != this.lastSerializedString;
        this.lastSerializedString = currentString;
        return changed;
    }
    
    /**
     * Get a string representation of the project
     * @return A formatted string showing all project data
     */
    @:expose
    public function toString():String {
        var modeNames = ["major", "minor", "harmonic minor", "melodic minor", "harmonic major", "hungarian minor", "double harmonic major"];
        var modeName = modeNames[this.mode];
        var correctionTargetNames = ["scale", "pentatonic", "chord tones", "chord pentatonic"];
        var correctionTargetName = (this.correctionTarget >= 0 && this.correctionTarget < correctionTargetNames.length) ? correctionTargetNames[this.correctionTarget] : "scale";
        
        var result = 'GoldenPond Project\n';
        result += '-------------------------------------------\n';
        result += 'Root: ${this.root}\n';
        result += 'Mode: ${modeName} (${this.mode})\n';
        result += 'Chord Sequence: ${this.chordSequence}\n';
        result += 'Stutter: ${this.stutter}\n';
        result += 'BPM: ${this.bpm}\n';
        result += 'Chord Duration: ${this.chordDuration}\n';
        result += 'PPQ: ${this.ppq}\n';
        result += 'Correction Target: ${correctionTargetName} (${this.correctionTarget})\n';
        result += 'Lines:\n';
        
        for (i in 0...this.lines.length) {
            var line = this.lines[i];
            result += '  Line ${i+1}: Pattern="${line.pattern}", InstrumentContext=${line.instrumentContext.toString()}\n';
        }
        
        result += '-------------------------------------------\n';
        return result;
    }
    
    /**
     * Serialize the project data to JSON
     * @return A JSON string representation of the project
     */
    @:expose
    public function toJSON():String {
        var data = {
            root: this.root,
            mode: this.mode,
            chordSequence: this.chordSequence,
            stutter: this.stutter,
            bpm: this.bpm,
            chordDuration: this.chordDuration,
            ppq: this.ppq,
            correctionTarget: this.correctionTarget,
            lines: this.lines.map(function(line) {
                return {
                    pattern: line.pattern,
                    instrumentContextCode: line.instrumentContext.getCode(),
                    instrumentContextData: line.instrumentContext.toJSON()
                };
            })
        };
        return haxe.Json.stringify(data);
    }
    
    /**
     * Create a GoldenData object from a JSON string
     * @param json The JSON string
     * @param deserializationHelper Helper for deserializing complex objects
     * @return A new GoldenData object
     */
    @:expose
    public static function makeFromJSON(json: String, deserializationHelper: IDeserializationHelper): GoldenData {
        var data: GoldenDataJson = haxe.Json.parse(json);
        var result = new GoldenData();
        
        // Set basic properties
        result.root = data.root;
        result.mode = data.mode;
        result.chordSequence = data.chordSequence;
        result.stutter = data.stutter;
        result.bpm = data.bpm;
        result.chordDuration = data.chordDuration;
        result.ppq = data.ppq;
        result.correctionTarget = (data.correctionTarget == null) ? 0 : data.correctionTarget;
        
        // Recreate lines using the helper
        result.lines = [];
        for (lineData in data.lines) {
            try {
                var line = cast deserializationHelper.helpMake('LineData', haxe.Json.stringify(lineData));
                result.lines.push(cast line);
            } catch (e: String) {
                trace('Error deserializing line: $e');
                continue;
            }
        }
        
        return result;
    }
    
    /**
     * Corrects an incoming MIDI note to the nearest allowed note for the chord active at a
     * specific time in the progression, according to the correction target (scale, pentatonic,
     * or chord tones only).
     * @param noteToCorrect The incoming MIDI note value.
     * @param timeInTicks The time of the note event in ticks.
     * @param previousNote Optional: The previously played note, used to determine melodic direction for melodic minor scales.
     * @return The corrected MIDI note value.
     */
    @:expose
    public function correct(noteToCorrect:Int, timeInTicks:Float, ?previousNote:Null<Int>):Int {
        ensureCorrector();
        return corrector.correct(noteToCorrect, timeInTicks, previousNote);
    }

    /**
     * Corrects an incoming MIDI note using an explicit progression chord index rather than
     * a time. Hosts that already track chord boundaries can use this to skip the time -> chord
     * conversion. The index wraps around the progression length.
     */
    @:expose
    public function correctAtChordIndex(noteToCorrect:Int, chordIndex:Int, ?previousNote:Null<Int>):Int {
        ensureCorrector();
        return corrector.correctAtChordIndex(noteToCorrect, chordIndex, previousNote);
    }

    /**
     * Returns a correction key for the chord active at the given time. The key changes when
     * either the correction-relevant project state changes or the active chord changes, so a
     * host can poll it cheaply (e.g. at control rate) to decide when to refresh a previously
     * published 128-entry correction table. When nothing relevant has changed, computing the
     * key does not reparse the progression or rebuild correction data, and it allocates nothing.
     *
     * The key is a single Int: bits 0..15 hold a chord slot (0 = invalid input,
     * 1..65535 = chord indices 0..65534), and bits 16..30 hold the revision (build count,
     * masked to 15 bits). This bounds the progression to 65535 chords and the revision to
     * 32767 distinct values before the key would wrap.
     */
    @:expose
    public function getCorrectionKey(timeInTicks:Float):Int {
        ensureCorrector();
        var slot = corrector.getChordIndexAtTime(timeInTicks) + 1;
        return ((correctionBuildCount & 0x7FFF) << 16) | slot;
    }

    /**
     * Builds a 128-entry lookup table (MIDI note 0..127 -> corrected note) for the chord
     * active at the given time. Intended to be generated on a control thread and then read,
     * without further GoldenPond calls or allocation, on a realtime path such as an audio thread.
     */
    @:expose
    public function makeCorrectionTable(timeInTicks:Float, ?previousNote:Null<Int>):Array<Int> {
        ensureCorrector();
        return corrector.makeNoteTable(timeInTicks, previousNote);
    }

    /**
     * Builds a 128-entry lookup table for an explicit progression chord index.
     */
    @:expose
    public function makeCorrectionTableAtChordIndex(chordIndex:Int, ?previousNote:Null<Int>):Array<Int> {
        ensureCorrector();
        return corrector.makeNoteTableAtChordIndex(chordIndex, previousNote);
    }

    /**
     * Builds a bidirectional (two-column) 256-entry correction table for the chord active at the
     * given time. Entries [0..127] assume an ascending phrase (incoming note higher than the
     * previous note); entries [128..255] assume a descending phrase (incoming note lower than the
     * previous note). The host selects the column by comparing the incoming note to the previous
     * note, so no rebuild is needed as a phrase changes direction. Repeated notes (equal to the
     * previous note) are already in the target set, so either column yields the identity.
     */
    @:expose
    public function makeBidirectionalCorrectionTable(timeInTicks:Float):Array<Int> {
        ensureCorrector();
        return corrector.makeBidirectionalNoteTable(timeInTicks);
    }

    /**
     * Builds a bidirectional (two-column) 256-entry correction table for an explicit progression
     * chord index.
     */
    @:expose
    public function makeBidirectionalCorrectionTableAtChordIndex(chordIndex:Int):Array<Int> {
        ensureCorrector();
        return corrector.makeBidirectionalNoteTableAtChordIndex(chordIndex);
    }

    /**
     * Rebuilds the correction cache lazily, only when a value relevant to correction has
     * changed. The change check compares the current fields against cached copies directly
     * (Int == Int, String == String), so unchanged-state polls allocate nothing.
     */
    private function ensureCorrector():Void {
        if (corrector == null
            || this.root != cacheRoot
            || this.mode != cacheMode
            || this.correctionTarget != cacheCorrectionTarget
            || this.chordSequence != cacheChordSequence
            || this.stutter != cacheStutter
            || this.bpm != cacheBpm
            || this.chordDuration != cacheChordDuration
            || this.ppq != cachePpq) {
            corrector = new GoldenCorrector(this.makeTimeManipulator(), this.makeChordProgression(), this.correctionTarget);
            cacheRoot = this.root;
            cacheMode = this.mode;
            cacheCorrectionTarget = this.correctionTarget;
            cacheChordSequence = this.chordSequence;
            cacheStutter = this.stutter;
            cacheBpm = this.bpm;
            cacheChordDuration = this.chordDuration;
            cachePpq = this.ppq;
            correctionBuildCount++;
        }
    }
}

/**
 * LineData - A class to store data for a single line
 */
class LineData implements ISerializable {
    public var pattern:String;
    public var instrumentContext:IInstrumentContext;
    
    public function new(pattern:String, instrumentContext:IInstrumentContext) {
        this.pattern = pattern;
        this.instrumentContext = instrumentContext;
    }

    public function toString():String {
        return 'LineData[pattern: $pattern, instrumentContext: ${instrumentContext.toString()}]';
    }

    public function toJSON():String {
        return haxe.Json.stringify({
            pattern: this.pattern,
            instrumentContextCode: this.instrumentContext.getCode(),
            instrumentContextData: this.instrumentContext.toJSON()
        });
    }

    public function getCode():String {
        return 'LineData';
    }
}

/**
 * Immutable correction cache. Built from a snapshot of the GoldenData harmonic/timing state,
 * so repeated correction queries never reparse the chord progression.
 */
class GoldenCorrector {
    private var chordTicks:Float;
    private var chords:Array<CorrectionChord>;

    public function new(timeManipulator:TimeManipulator, progression:IChordProgression, correctionTarget:Int) {
        this.chordTicks = timeManipulator.chordTicks;

        var chordThings = progression.toChordThings();
        this.chords = [for (ct in chordThings) CorrectionChord.fromChordThing(ct, correctionTarget)];
    }

    /**
     * Corrects a note at a tick position. Returns the original note for invalid input.
     */
    public function correct(noteToCorrect:Int, timeInTicks:Float, previousNote:Null<Int>):Int {
        var chordIndex = getChordIndexAtTime(timeInTicks);
        if (chordIndex < 0) return noteToCorrect;
        return correctAtChordIndex(noteToCorrect, chordIndex, previousNote);
    }

    /**
     * Returns the progression chord index active at the given tick position, or -1 for
     * invalid input (non-finite/negative time, empty progression, or chordTicks <= 0).
     * The index wraps around the progression length.
     */
    public function getChordIndexAtTime(timeInTicks:Float):Int {
        if (!Math.isFinite(timeInTicks) || timeInTicks < 0) return -1;
        if (chordTicks <= 0 || chords.length == 0) return -1;

        var chordCount:Float = chords.length;
        var chordIndex = Std.int(Math.floor(timeInTicks / chordTicks) % chordCount);
        if (chordIndex < 0) chordIndex += chords.length;
        return chordIndex;
    }

    /**
     * Returns the correction chord for a wrapped progression chord index, or null if the
     * progression is empty.
     */
    private function chordAt(chordIndex:Int):Null<CorrectionChord> {
        if (chords.length == 0) return null;
        var index = chordIndex % chords.length;
        if (index < 0) index += chords.length;
        return chords[index];
    }

    /**
     * Corrects a note at an explicit progression chord index.
     */
    public function correctAtChordIndex(noteToCorrect:Int, chordIndex:Int, previousNote:Null<Int>):Int {
        var chord = chordAt(chordIndex);
        if (chord == null) return noteToCorrect;
        return chord.correct(noteToCorrect, previousNote);
    }

    /**
     * Builds a 128-entry correction table for the chord active at the given time.
     */
    public function makeNoteTable(timeInTicks:Float, previousNote:Null<Int>):Array<Int> {
        var table = [for (i in 0...128) 0];
        for (note in 0...128) {
            table[note] = correct(note, timeInTicks, previousNote);
        }
        return table;
    }

    /**
     * Builds a 128-entry correction table for an explicit chord index.
     */
    public function makeNoteTableAtChordIndex(chordIndex:Int, previousNote:Null<Int>):Array<Int> {
        var table = [for (i in 0...128) 0];
        for (note in 0...128) {
            table[note] = correctAtChordIndex(note, chordIndex, previousNote);
        }
        return table;
    }

    /**
     * Builds a 256-entry bidirectional correction table for the chord active at the given time.
     * Entries [0..127] assume an ascending phrase (incoming note higher than the previous note);
     * entries [128..255] assume a descending phrase (incoming note lower than the previous note).
     * The host selects the column by comparing the incoming note to the previous note, so the
     * table does not need rebuilding as a melody changes direction.
     */
    public function makeBidirectionalNoteTable(timeInTicks:Float):Array<Int> {
        var table = [for (i in 0...256) 0];
        var chordIndex = getChordIndexAtTime(timeInTicks);
        if (chordIndex < 0) {
            for (note in 0...128) {
                table[note] = note;
                table[128 + note] = note;
            }
            return table;
        }
        var chord = chords[chordIndex];
        for (note in 0...128) {
            table[note] = chord.correctWithDirection(note, 1);
            table[128 + note] = chord.correctWithDirection(note, -1);
        }
        return table;
    }

    /**
     * Builds a 256-entry bidirectional correction table for an explicit progression chord index.
     */
    public function makeBidirectionalNoteTableAtChordIndex(chordIndex:Int):Array<Int> {
        var table = [for (i in 0...256) 0];
        var chord = chordAt(chordIndex);
        if (chord == null) {
            for (note in 0...128) {
                table[note] = note;
                table[128 + note] = note;
            }
            return table;
        }
        for (note in 0...128) {
            table[note] = chord.correctWithDirection(note, 1);
            table[128 + note] = chord.correctWithDirection(note, -1);
        }
        return table;
    }
}

/**
 * Scale data for a single chord in the progression, precomputed so queries are cheap.
 */
class CorrectionChord {
    private var ascendingScale:Array<Int>;
    private var descendingScale:Array<Int>;
    private var isMelodicMinor:Bool;

    public function new(ascendingScale:Array<Int>, descendingScale:Array<Int>, isMelodicMinor:Bool) {
        this.ascendingScale = ascendingScale;
        this.descendingScale = descendingScale;
        this.isMelodicMinor = isMelodicMinor;
    }

    public static function fromChordThing(ct:ChordThing, correctionTarget:Int):CorrectionChord {
        switch (correctionTarget) {
            case 1: // Pentatonic (key): 5-note scale rooted at the key centre, major/minor flavour from the mode.
                var penta = buildPentatonic(ct.key, ct.mode.isMinorScale());
                return new CorrectionChord(penta, penta, false);
            case 2: // Chord tones only: the actual notes of the chord (root/3rd/5th + extensions).
                var tones = ct.generateChordNotes();
                return new CorrectionChord(tones, tones, false);
            case 3: // Pentatonic (per-chord): pentatonic rooted at the chord's own root, flavour from the chord's third.
                var chordPenta = buildChordPentatonic(ct);
                return new CorrectionChord(chordPenta, chordPenta, false);
            default: // 0 (or anything else): full 7-note scale (original behaviour).
                var ascending = buildScale(ct.key, ct.mode.intervals);
                var melodic = ct.mode.valueEquals(Mode.getMelodicMinorMode());
                var descending = melodic ? buildScale(ct.key, Mode.getMinorMode().intervals) : ascending;
                return new CorrectionChord(ascending, descending, melodic);
        }
    }

    private static function buildScale(tonic:Int, intervals:Array<Int>):Array<Int> {
        var scale = [tonic];
        var currentNote = tonic;
        for (i in 0...intervals.length - 1) {
            currentNote += intervals[i % intervals.length];
            scale.push(currentNote);
        }
        return scale;
    }

    /**
     * Builds a 5-note pentatonic scale rooted at tonic. Minor pentatonic (1,b3,4,5,b7)
     * uses steps [3,2,2,3,2]; major pentatonic (1,2,3,5,6) uses [2,2,3,2,3].
     */
    private static function buildPentatonic(tonic:Int, isMinor:Bool):Array<Int> {
        var steps = isMinor ? [3, 2, 2, 3, 2] : [2, 2, 3, 2, 3];
        return buildScale(tonic, steps);
    }

    /**
     * Builds a per-chord pentatonic: rooted at the chord's own root (not the key centre),
     * with major/minor flavour taken from the chord's third. Secondary chords are resolved
     * to their actual sounding chord first.
     */
    private static function buildChordPentatonic(ct:ChordThing):Array<Int> {
        var actual = (ct.modifiers.indexOf(Modifier.SECONDARY) != -1 && ct.secondary_degree != null)
            ? ct.calculateAsSecondaryChord()
            : ct;
        var root = actual.mode.nth_from(actual.key, actual.degree);
        var third = actual.mode.nth_from(actual.key, actual.degree + 2);
        var thirdInterval = (third - root) % 12;
        if (thirdInterval < 0) thirdInterval += 12;
        return buildPentatonic(root, thirdInterval == 3);
    }

    public function correct(noteIn:Int, previousNote:Null<Int>):Int {
        var direction = 0;
        if (previousNote != null) {
            if (noteIn > previousNote) direction = 1;
            else if (noteIn < previousNote) direction = -1;
        }
        return correctWithDirection(noteIn, direction);
    }

    /**
     * Corrects a note given an explicit melodic direction: 1 = ascending (note above the
     * previous note), -1 = descending (note below), 0 = neutral (no previous note). Direction
     * selects the melodic-minor ascending/descending scale and the ascending/descending
     * tie-break preference.
     */
    public function correctWithDirection(noteIn:Int, direction:Int):Int {
        var scale = (isMelodicMinor && direction == -1) ? descendingScale : ascendingScale;
        return mapToNearestInScale(noteIn, scale, direction);
    }

    private static function mapToNearestInScale(noteIn:Int, scaleNotes:Array<Int>, direction:Int):Int {
        if (scaleNotes == null || scaleNotes.length == 0) return noteIn;

        var noteInClass = noteIn % 12;

        // First pass: find the minimum pitch-class distance.
        var minDistance = 12;
        for (scaleNote in scaleNotes) {
            var scaleNoteClass = scaleNote % 12;
            var distance = Std.int(Math.abs(noteInClass - scaleNoteClass));
            if (distance > 6) distance = 12 - distance;
            if (distance < minDistance) {
                minDistance = distance;
            }
        }

        // Second pass: collect the (at most two) nearest pitch classes into fixed locals,
        // so this hot path allocates nothing. On the 12-note circle a note can be
        // equidistant from at most two distinct pitch classes.
        var candidate0 = -1;
        var candidate1 = -1;
        for (scaleNote in scaleNotes) {
            var scaleNoteClass = scaleNote % 12;
            var distance = Std.int(Math.abs(noteInClass - scaleNoteClass));
            if (distance > 6) distance = 12 - distance;

            if (distance == minDistance) {
                if (candidate0 == -1) {
                    candidate0 = scaleNoteClass;
                } else if (candidate1 == -1 && scaleNoteClass != candidate0) {
                    candidate1 = scaleNoteClass;
                }
            }
        }

        if (candidate0 == -1) return noteIn;

        var closestNoteClass = -1;

        if (candidate1 == -1) {
            closestNoteClass = candidate0;
        } else {
            if (direction == 1) { // Ascending, prefer the higher note
                var higherNote = -1;
                var diff = candidate0 - noteInClass;
                if (diff < -6) diff += 12; // e.g. C(0) is higher than B(11)
                if (diff > 0) {
                    higherNote = candidate0;
                }

                diff = candidate1 - noteInClass;
                if (diff < -6) diff += 12;
                if (diff > 0 && higherNote == -1) {
                    higherNote = candidate1;
                }

                if (higherNote != -1) closestNoteClass = higherNote;
                else closestNoteClass = candidate0; // Fallback
            } else { // Descending or no direction, prefer the lower note (which is the old behavior)
                closestNoteClass = candidate0;
            }
        }

        if (closestNoteClass == -1) return noteIn;

        var originalOctaveBase = noteIn - noteInClass;
        var correctedNote = originalOctaveBase + closestNoteClass;

        // Adjust octave if the correction crossed the halfway point (6 semitones).
        if (Math.abs(correctedNote - noteIn) > 6.0) {
            if (noteIn < correctedNote) {
                correctedNote -= 12;
            } else {
                correctedNote += 12;
            }
        }

        return correctedNote;
    }
} 