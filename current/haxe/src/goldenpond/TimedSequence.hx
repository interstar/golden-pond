package;

/*
GoldenPond FL Studio Script
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


import Math;
import Mode;
import ChordParser;
import ScoreUtilities;
import RhythmGenerator;  // This will give us access to SimpleRhythmGenerator too
import RhythmGenerator.SelectorType;  // Import SelectorType from RhythmGenerator
import GoldenData;  // This will give us access to LineData

// Add these typedefs at the top of the file, after the imports
typedef MidiInstrumentContextData = {
    var chan: Int;
    var velocity: Int;
    var gateLength: Float;
    var transpose: Int;
}

typedef LineDataJson = {
    var pattern: String;
    var instrumentContextCode: String;
    var instrumentContextData: String;
}

@:expose
enum SeqTypes {
    CHORDS;
    ARPUP;
    ARPDOWN;
    BASS;
    TOP;
    RANDOM;
    SCALE;
}

@:expose
enum DivisionValue {
  SIXTEENTH;
  TWELFTH;
  EIGHTH;
  SIXTH;
  QUARTER;
  THIRD;
  HALF;
  WHOLE;
}

enum RhythmicDensity {
    SIXTEEN;
    TWELVE;
    EIGHT;
    SIX;
    FOUR;
    THREE;
    TWO;
    ONE;
}




interface ILineGenerator {
    function generateNotes(startTime: Float): Array<INote>;
    function getPitches(): Array<Int>;
    function getDurations(): Array<Float>;
}



class ArpIterator   {
    private var chord:Array<Int>;
    private var noteIndex:Int;
    private var step:Int;

    public function new(chord:Array<Int>, step:Int = 1) {
        this.chord = chord;
        this.noteIndex = 0;
        this.step = step;
    }

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        var note = this.chord[this.noteIndex % this.chord.length];
        this.noteIndex = (this.noteIndex + this.step) % this.chord.length;
        return note;
    }
}


class NoteSelectorIterator  {
    private var chords:Array<Array<Int>>;
    private var chordIndex:Int;
    private var noteSelector: Array<Int> -> Int;

    public function new(chords:ChordProgression, noteSelector: Array<Int> -> Int) {
        this.chords = chords.toNotes();
        this.chordIndex = 0;
        this.noteSelector = noteSelector;
    }

    public function hasNext():Bool {
        return this.chordIndex < this.chords.length;
    }

    public function next():Int {
        var note = this.noteSelector(this.chords[this.chordIndex]);
        this.chordIndex++;
        return note;
    }
}

@:expose
class MenuHelper {
  public static function getDivisionNames():Array<String> {
    return ["1/16", "1/12", "1/8", "1/6", "1/4", "1/3", "1/2", "1"];
  }
  public static function getDivisionValues():Array<DivisionValue> {
    return [SIXTEENTH,TWELFTH,EIGHTH,SIXTH,QUARTER,THIRD,HALF,WHOLE];
  }
  public static function getDivisionFor(i:Int):DivisionValue {
    return getDivisionValues()[i];
  }
  public static function divisionValue2Numeric(dv:DivisionValue):Float {
    return [SIXTEENTH=>1/16, TWELFTH=>1/12, EIGHTH=>1/8, SIXTH=>1/6, QUARTER=>1/4, THIRD=>1/3, HALF=>1/2, WHOLE=>1][dv];
  }
  
  public static function getRhythmicDensityNames():Array<String> {
    return ["16 patterns/chord", "12 patterns/chord", "8 patterns/chord", 
            "6 patterns/chord", "4 patterns/chord", "3 patterns/chord", 
            "2 patterns/chord", "1 pattern/chord"];
  }

  public static function getRhythmicDensityValues():Array<RhythmicDensity> {
    return [SIXTEEN, TWELVE, EIGHT, SIX, FOUR, THREE, TWO, ONE];
  }

  public static function getRhythmicDensityFor(i:Int):RhythmicDensity {
    return getRhythmicDensityValues()[i];
  }

  public static function rhythmicDensityToNumeric(rd:RhythmicDensity):Float {
    var result = [
        SIXTEEN => 1/16, TWELVE => 1/12, 
        EIGHT => 1/8, SIX => 1/6,
        FOUR => 1/4, THREE => 1/3,
        TWO => 1/2, ONE => 1
    ][rd];
    return result;
  }
}

@:expose
class TimeManipulator {
    public var ppq:Float;                    // Ticks per quarter note - fundamental resolution
    public var chordDuration:Float;          // How many quarter notes each chord lasts
    public var chordTicks:Float;             // Total ticks for one chord
    public var bpm:Float;                    // Tempo in beats per minute

    public function new() {
        this.ppq = 1000;
        this.chordDuration = 16;
        this.bpm = 120; 
        recalc();
    }

    private function recalc() {
        this.chordTicks = this.ppq * this.chordDuration;
    }

    public function setChordDuration(cl:Float):TimeManipulator {
        this.chordDuration = cl;
        recalc();
        return this;
    }

    public function setPPQ(p:Float):TimeManipulator {
        this.ppq = p;
        recalc();
        return this;
    }

    public function setBPM(b:Float):TimeManipulator {
        this.bpm = b;
        recalc();
        return this;
    }

    public function toString():String {
        return "\nTimeManipulator\n  PPQ: " + this.ppq + 
               "\n  Chord Length Multiplier: " + this.chordDuration +
               "\n  quarterToMS: " + this.quarterToMS() + 
               "\n  chordTicks:" + this.chordTicks;
    }

    public function quarterToMS():Float {
        return 60 / this.bpm;
    }

    public function getBPM():Float {
        return this.bpm;
    }

    public function getPPQ():Float {
        return this.ppq;
    }
}

@:expose
class MidiInstrumentContext implements IInstrumentContext {
    private var chan: Int;
    private var velocity: Int;
    private var gateLength: Float;
    private var transpose: Int;

    public function new(chan: Int, velocity: Int, gateLength: Float, transpose: Int) {
        this.chan = chan;
        this.velocity = velocity;
        this.gateLength = gateLength;
        this.transpose = transpose;
    }

    public function getChannel(): Int {
        return this.chan;
    }

    public function makeNote(note: Int, startTime: Float, length: Float): INote {
        return new Note(
            this.chan,
            note + this.transpose,
            this.velocity,
            startTime,
            length * this.gateLength
        );
    }

    public function toString(): String {
        return 'MidiInstrumentContext[chan: $chan, velocity: $velocity, gateLength: $gateLength, transpose: $transpose]';
    }

    public function toJSON(): String {
        return haxe.Json.stringify({
            chan: this.chan,
            velocity: this.velocity,
            gateLength: this.gateLength,
            transpose: this.transpose
        });
    }

    public function getCode(): String {
        return 'MidiInstrumentContext';
    }
}

@:expose
class DeserializationHelper implements IDeserializationHelper {
    public function new() {}
    
    public function helpMake(code: String, json: String): ISerializable {
        switch (code) {
            case 'LineData':
                var lineData: LineDataJson = haxe.Json.parse(json);
                // First create the instrument context from its data
                var instrumentContext = helpMake(lineData.instrumentContextCode, lineData.instrumentContextData);
                // Then create the line data with the instrument context
                return new LineData(lineData.pattern, cast instrumentContext);
                
            case 'MidiInstrumentContext':
                var contextData: MidiInstrumentContextData = haxe.Json.parse(json);
                return new MidiInstrumentContext(
                    contextData.chan,
                    contextData.velocity,
                    contextData.gateLength,
                    contextData.transpose
                );
                
            default:
                throw 'Unknown code: $code';
        }
    }
}

@:expose
class LineGenerator implements ILineGenerator {
    private var timeManipulator: TimeManipulator;
    private var seq: IChordProgression;
    private var rhythmGenerator: IRhythmGenerator;
    private var instrumentContext: IInstrumentContext;
    private var cachedNotes: Array<INote>;
    private var lastNoteIndex: Int;  // Track last index for Ascending/Descending
    private var lastNoteValue: Int;  // Track last actual note for Repeat

    public function new(timeManipulator: TimeManipulator, 
                      seq: IChordProgression, 
                      rhythmGenerator: IRhythmGenerator,
                      instrumentContext: IInstrumentContext) {
        this.timeManipulator = timeManipulator;
        this.seq = seq;
        this.rhythmGenerator = rhythmGenerator;
        this.instrumentContext = instrumentContext;
        this.cachedNotes = null;
        this.lastNoteIndex = -1;
        this.lastNoteValue = -1;
    }

    /**
     * Creates a LineGenerator with the specified rhythm generator.
     * This is the preferred way to create a LineGenerator with a custom rhythm pattern.
     */
    public static function create(timeManipulator: TimeManipulator, 
                                seq: IChordProgression, 
                                rhythmGenerator: IRhythmGenerator,
                                instrumentContext: IInstrumentContext): LineGenerator {
        return new LineGenerator(timeManipulator, seq, rhythmGenerator, instrumentContext);
    }

    /**
     * Creates a LineGenerator with a rhythm pattern specified as a string.
     * This is a convenience method that parses the pattern string and creates the appropriate rhythm generator.
     * 
     * @throws String Exception if the pattern cannot be parsed
     */
    public static function createFromPattern(timeManipulator: TimeManipulator, 
                                           seq: IChordProgression, 
                                           pattern: String,
                                           instrumentContext: IInstrumentContext): LineGenerator {
        var rhythmGenerator = RhythmLanguage.makeRhythmGenerator(pattern);
        if (rhythmGenerator.parseFailed()) {
            throw "Invalid rhythm pattern: \"" + pattern + "\"";
        }
        return LineGenerator.create(timeManipulator, seq, rhythmGenerator, instrumentContext);
    }

    private function selectNotesFromChord(selector:SelectorType, chordThing:ChordThing):Array<Int> {
        return switch(selector) {
            case Ascending:
                var chord = chordThing.generateChordNotes();
                lastNoteIndex = (lastNoteIndex == -1) ? 0 : (lastNoteIndex + 1) % chord.length;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Descending:
                var chord = chordThing.generateChordNotes();
                lastNoteIndex = (lastNoteIndex == -1) ? chord.length - 1 : 
                    (lastNoteIndex - 1 + chord.length) % chord.length;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Repeat:
                if (lastNoteValue == -1) {
                    var chord = chordThing.generateChordNotes();
                    lastNoteIndex = 0;
                    lastNoteValue = chord[0];
                }
                [lastNoteValue];
                
            case FullChord:
                chordThing.generateChordNotes();
                
            case Random:
                var chord = chordThing.generateChordNotes();
                lastNoteIndex = Std.int(Math.floor(Math.random() * chord.length));
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case SpecificNote(n):
                var chord = chordThing.generateChordNotes();
                lastNoteIndex = Std.int(Math.min(n - 1, chord.length - 1));
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case ScaleDegree(n):
                if (n < 1 || n > 7) {
                    [];  // Invalid scale degree
                } else {
                    var mode = chordThing.get_mode();
                    lastNoteValue = mode.nth_from(chordThing.key, n);
                    [lastNoteValue];
                }
                
            case RandomFromScale:
                var mode = chordThing.get_mode();
                var degree = Std.int(Math.floor(Math.random() * 7) + 1);
                lastNoteValue = mode.nth_from(chordThing.key, degree);
                [lastNoteValue];
                
            case TopNote:
                var chord = chordThing.generateChordNotes();
                lastNoteIndex = chord.length - 1;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Rest:
                [];
        }
    }

    private function generateCachedNotes(): Array<INote> {
        var notes = new Array<INote>();
        var currentTime = 0.0;
        var totalSteps = rhythmGenerator.getTotalSteps();
        var stepSize = timeManipulator.chordTicks / totalSteps;

        for (ct in seq.toChordThings()) {
            lastNoteIndex = -1;
            lastNoteValue = -1;
            rhythmGenerator.reset();
            
            for (step in 0...totalSteps) {
                var selector = rhythmGenerator.next();
                if (selector != Rest) {
                    var notesToAdd = selectNotesFromChord(selector, ct);
                    for (note in notesToAdd) {
                        notes.push(this.instrumentContext.makeNote(
                            note,
                            currentTime,
                            stepSize
                        ));
                    }
                }
                currentTime += stepSize;
            }
        }
        return notes;
    }

    public function getPitches(): Array<Int> {
        var pitches = new Array<Int>();
        for (note in cachedNotes) {
            pitches.push(note.getMidiNoteValue());
        }
        return pitches;
    }

    public function getDurations(): Array<Float> {
        var durations = new Array<Float>();
        if (cachedNotes.length == 0) return durations;

        for (i in 0...cachedNotes.length - 1) {
            var currentNote = cachedNotes[i];
            var nextNote = cachedNotes[i + 1];
            var duration = nextNote.getStartTime() - currentNote.getStartTime();
            durations.push(duration);
        }

        // For the last note, use its length
        durations.push(cachedNotes[cachedNotes.length - 1].getLength());

        return durations;
    }

    /**
     * Generate notes for this line
     * @param startTime The start time in ticks
     * @return Array of notes with proper instrument-specific properties
     */
    public function generateNotes(startTime: Float): Array<INote> {
        if (this.cachedNotes == null) {
            this.cachedNotes = this.generateCachedNotes();
        }
        
        return this.cachedNotes;
    }

   
    /**
     * Generate notes in seconds for this line
     * @param startTime The start time in seconds
     * @return Array of notes with proper instrument-specific properties and timing in seconds
     */
    public function notesInSeconds(startTime: Float): Array<INote> {
        var tickNotes = this.generateNotes(startTime);
        var secondsPerTick = (60.0 / (this.timeManipulator.getBPM() * this.timeManipulator.getPPQ()));
        var result = new Array<INote>();
        for (n in tickNotes) {
            result.push(this.instrumentContext.makeNote(
                n.getMidiNoteValue(),
                n.getStartTime() * secondsPerTick,
                n.getLength() * secondsPerTick
            ));
        }
        return result;
    }
}


