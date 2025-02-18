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

 
@:expose
enum SeqTypes {
    CHORDS;
    EUCLIDEAN;
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

interface IRhythmGenerator {
    public function hasNext():Bool;
    public function next():Int;
}


 
interface ILineGenerator {
    function generateNotes(startTime: Float, channel: Int, velocity: Int): Array<Note>;
    function getPitches(): Array<Int>;
    function getDurations(): Array<Float>;
}


class SilentIterator implements IRhythmGenerator {
    public function new() {}

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        return 0;
    }
}

class RhythmGenerator implements IRhythmGenerator {
    private var rhythm:Array<Int>;
    private var index:Int;

    public function new(k:Int, n:Int) {
        this.rhythm = TimeManipulator.distributePulsesEvenly(k, n);
        this.index = 0;
    }

    public function restart() {
        this.index = 0;
    }

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        var beat = this.rhythm[this.index];
        this.index = (this.index + 1) % this.rhythm.length;
        return beat;
    }
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

    // Static utility method for rhythm generation
    public static function distributePulsesEvenly(k:Int, n:Int):Array<Int> {
        var rhythm = new Array<Int>();
        for (i in 0...n) rhythm.push(0);
        var stepSize = n / k;
        var currentStep = 0.0;
        for (i in 0...k) {
            rhythm[Math.round(currentStep)] = 1;
            currentStep += stepSize;
        }
        return rhythm;
    }

    public function getBPM():Float {
        return this.bpm;
    }

    public function getPPQ():Float {
        return this.ppq;
    }
}

 
class AbstractLineGenerator implements ILineGenerator {
    private var timeManipulator: TimeManipulator;
    private var seq: ChordProgression;
    private var k: Int;
    private var n: Int;
    private var gateLength: Float;
    private var rhythmicDensity: Float;
    private var transposition: Int;  // Add transposition property
    private var cachedNotes: Array<Note>;

    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        this.timeManipulator = timeManipulator;
        this.seq = seq;
        this.k = k;
        this.n = n;
        this.gateLength = gateLength;
        this.rhythmicDensity = rhythmicDensity;
        this.transposition = 0;  // Initialize to 0
        this.cachedNotes = null;
    }

    // Add transpose method
    public function transpose(offset: Int): AbstractLineGenerator {
        this.transposition = offset;
        this.cachedNotes = null;  // Clear cache to force regeneration
        return this;
    }

    @:protected function generateCachedNotes(): Array<Note> {
        var notes = new Array<Note>();
        var currentTime = 0.0;
        
        var patternDuration = timeManipulator.chordTicks * rhythmicDensity;
        var stepSize = patternDuration / n;
        var noteLength = stepSize * gateLength;  // Always use stepSize * gateLength
        var patternsPerChord = Math.floor(1 / rhythmicDensity);

        for (c in seq.toNotes()) {
            var rGen = new RhythmGenerator(this.k, this.n);
            
            // For each pattern that fits in this chord
            for (pattern in 0...patternsPerChord) {
                // Play through the n steps of this pattern
                for (step in 0...n) {
                    var beat = rGen.next();
                    if (beat == 1) {
                        var notesToAdd = pickNotesFromChord(c);
                        for (note in notesToAdd) {
                            notes.push(new Note(
                                0,
                                note,
                                100,
                                currentTime,
                                noteLength  // Use calculated note length
                            ));
                        }
                    }
                    currentTime += stepSize;  // Always advance by step size
                }
            }
        }
        return notes;
    }

    @:protected function pickNotesFromChord(chord:Array<Int>):Array<Int> {
        throw new haxe.exceptions.NotImplementedException();
    }

    public function getPitches(): Array<Int> {
        var pitches = new Array<Int>();
        for (note in cachedNotes) {
            pitches.push(note.note);
        }
        return pitches;
    }

    public function getDurations(): Array<Float> {
        var durations = new Array<Float>();
        if (cachedNotes.length == 0) return durations;

        for (i in 0...cachedNotes.length - 1) {
            var currentNote = cachedNotes[i];
            var nextNote = cachedNotes[i + 1];
            var duration = nextNote.startTime - currentNote.startTime;
            durations.push(duration);
        }

        // For the last note, use its length
        durations.push(cachedNotes[cachedNotes.length - 1].length);

        return durations;
    }

    public function generateNotes(startTime: Float, channel: Int, velocity: Int): Array<Note> {
        if (cachedNotes == null) {
            cachedNotes = generateCachedNotes();
        }
        
        var adjustedNotes = new Array<Note>();
        for (note in cachedNotes) {
            adjustedNotes.push(new Note(
                channel,
                note.note + transposition,  // Apply transposition here
                velocity,
                note.startTime + startTime,
                note.length
            ));
        }
        return adjustedNotes;
    }

    public function notesToTimeEvents(notes:Array<Note>):Array<{time:Float, event:DeltaEvent}> {
        var timeEvents = new Array<{time:Float, event:DeltaEvent}>();
        
        for (note in notes) {
            // Note-on event
            timeEvents.push({
                time: note.startTime,
                event: new DeltaEvent(
                    note.chan, 
                    note.note, 
                    note.velocity, 
                    0,
                    NOTE_ON
                )
            });
            
            // Note-off event
            timeEvents.push({
                time: note.startTime + note.length,
                event: new DeltaEvent(
                    note.chan, 
                    note.note, 
                    0,
                    0,
                    NOTE_OFF
                )
            });
        }
        return timeEvents;
    }

    public function sortTimeEvents(timeEvents:Array<{time:Float, event:DeltaEvent}>):Array<{time:Float, event:DeltaEvent}> {
        timeEvents.sort((a, b) -> {
            var timeDiff = a.time - b.time;
            if (Math.abs(timeDiff) < 0.0001) {
                // At same time:
                // 1. If same note, NOTE_OFF comes before NOTE_ON
                if (a.event.note == b.event.note && a.event.type != b.event.type) {
                    return a.event.type == NOTE_OFF ? -1 : 1;
                }
                // 2. If different notes, maintain original order based on note value
                return a.event.note - b.event.note;
            }
            return timeDiff > 0 ? 1 : -1;
        });
        return timeEvents;
    }

    public function asDeltaEvents():Array<DeltaEvent> {
        var events = new Array<DeltaEvent>();
        var notes = generateCachedNotes();
        
        // First convert to time events and sort them
        var timeEvents = notesToTimeEvents(notes);
        timeEvents = sortTimeEvents(timeEvents);
        
        // Calculate deltas by comparing with previous event's time
        for (i in 0...timeEvents.length) {
            var previousTime = (i > 0) ? timeEvents[i-1].time : 0.0;
            var currentTime = timeEvents[i].time;
            var delta = currentTime - previousTime;
            
            timeEvents[i].event.deltaFromLast = delta;
            events.push(timeEvents[i].event);
        }
        
        return events;
    }

    public function notesInSeconds(startTime:Float, channel:Int, velocity:Int):Array<Note> {
        var tickNotes = generateNotes(startTime, channel, velocity);
        var secondsPerTick = 60.0 / (timeManipulator.getBPM() * timeManipulator.getPPQ());
        
        return [for (n in tickNotes) new Note(
            n.chan,
            n.note,
            n.velocity,
            n.startTime * secondsPerTick,
            n.length * secondsPerTick
        )];
    }
}



@:expose
class ChordLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, k, n, gateLength, rhythmicDensity);
    }

    override function pickNotesFromChord(chord: Array<Int>): Array<Int> {
        return chord;  // Return all notes from the chord
    }
}


@:expose
class BassLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, k, n, gateLength, rhythmicDensity);
    }

    override function pickNotesFromChord(chord: Array<Int>): Array<Int> {
        return [chord[0] - 12];  // First note, octave down
    }
}



@:expose
class TopLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, k, n, gateLength, rhythmicDensity);
    }

    override function pickNotesFromChord(chord: Array<Int>): Array<Int> {
        return [chord[chord.length - 1] + 12];  // Last note, octave up
    }
}


@:expose
class ArpLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, k, n, gateLength, rhythmicDensity);
    }


    override function generateCachedNotes(): Array<Note> {
        var notes = new Array<Note>();
        var currentTime = 0.0;
        
        var patternDuration = timeManipulator.chordTicks * rhythmicDensity;
        var euclideanStepSize = patternDuration / n;
        var patternsPerChord = Math.floor(1 / rhythmicDensity);

        for (c in seq.toNotes()) {
            var arpIter = new ArpIterator(c);  // New iterator for each chord
            
            // For each pattern that fits in this chord
            for (pattern in 0...patternsPerChord) {
                var rGen = new RhythmGenerator(this.k, this.n);
                // Play through the n steps of this pattern
                for (step in 0...n) {
                    var beat = rGen.next();
                    if (beat == 1) {
                        notes.push(new Note(
                            0,
                            arpIter.next(),  // Use arpIter for note selection
                            100,
                            currentTime,
                            euclideanStepSize * gateLength
                        ));
                    }
                    currentTime += euclideanStepSize;
                }
            }
        }
        return notes;
    }
}

@:expose
class SilentLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, 1, 1, gateLength, rhythmicDensity);
    }

    override function generateCachedNotes(): Array<Note> {
        return []; // Generates no notes
    }
}

@:expose
class RandomLine extends AbstractLineGenerator {
    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, k: Int, n: Int, gateLength: Float, rhythmicDensity: Float) {
        super(timeManipulator, seq, k, n, gateLength, rhythmicDensity);
    }

    override function pickNotesFromChord(chord: Array<Int>): Array<Int> {
        var randomIndex = Math.floor(Math.random() * chord.length);
        return [chord[randomIndex]];
    }
}


