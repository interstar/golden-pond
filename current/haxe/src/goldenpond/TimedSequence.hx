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
    function generateNotes(startTime: Float, channel: Int, velocity: Int): Array<Note>;
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
class LineGenerator implements ILineGenerator {
    private var timeManipulator: TimeManipulator;
    private var seq: ChordProgression;
    private var rhythmGenerator: IRhythmGenerator;
    private var gateLength: Float;
    private var transposition: Int;
    private var cachedNotes: Array<Note>;
    private var lastNoteIndex: Int;  // Track last index for Ascending/Descending
    private var lastNoteValue: Int;  // Track last actual note for Repeat

    public function new(timeManipulator: TimeManipulator, seq: ChordProgression, rhythmGenerator: IRhythmGenerator, gateLength: Float) {
        this.timeManipulator = timeManipulator;
        this.seq = seq;
        this.rhythmGenerator = rhythmGenerator;
        this.gateLength = gateLength;
        this.transposition = 0;
        this.cachedNotes = null;
        this.lastNoteIndex = -1;
        this.lastNoteValue = -1;
    }

    /**
     * Creates a LineGenerator with the specified rhythm generator.
     * This is the preferred way to create a LineGenerator with a custom rhythm pattern.
     */
    public static function create(timeManipulator: TimeManipulator, seq: ChordProgression, rhythmGenerator: IRhythmGenerator, gateLength: Float): LineGenerator {
        return new LineGenerator(timeManipulator, seq, rhythmGenerator, gateLength);
    }

    /**
     * Creates a LineGenerator with a rhythm pattern specified as a string.
     * This is a convenience method that parses the pattern string and creates the appropriate rhythm generator.
     * 
     * @throws String Exception if the pattern cannot be parsed
     */
    public static function createFromPattern(timeManipulator: TimeManipulator, seq: ChordProgression, pattern: String, gateLength: Float): LineGenerator {
        var rhythmGenerator = RhythmLanguage.makeRhythmGenerator(pattern);
        if (rhythmGenerator.parseFailed()) {
            throw 'Invalid rhythm pattern: "${pattern}"';
        }
        return create(timeManipulator, seq, rhythmGenerator, gateLength);
    }

    private function selectNotesFromChord(selector:SelectorType, chord:Array<Int>):Array<Int> {
        return switch(selector) {
            case Ascending:
                lastNoteIndex = (lastNoteIndex == -1) ? 0 : (lastNoteIndex + 1) % chord.length;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Descending:
                lastNoteIndex = (lastNoteIndex == -1) ? chord.length - 1 : 
                    (lastNoteIndex - 1 + chord.length) % chord.length;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Repeat:
                if (lastNoteValue == -1) {
                    lastNoteIndex = 0;
                    lastNoteValue = chord[0];
                }
                [lastNoteValue];
                
            case FullChord:
                chord;
                
            case Random:
                lastNoteIndex = Std.int(Math.floor(Math.random() * chord.length)    );
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case SpecificNote(n):
                lastNoteIndex = Std.int(Math.min(n - 1, chord.length - 1));
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case TopNote:
                lastNoteIndex = chord.length - 1;
                lastNoteValue = chord[lastNoteIndex];
                [lastNoteValue];
                
            case Rest:
                [];
        }
    }

    private function generateCachedNotes(): Array<Note> {
        var notes = new Array<Note>();
        var currentTime = 0.0;
        
        var totalSteps = rhythmGenerator.getTotalSteps();
        var patternLength = rhythmGenerator.getPatternLength();
        
        // Calculate step size based on the pattern length and total steps
        var stepSize = timeManipulator.chordTicks / totalSteps;
        var noteLength = stepSize * gateLength;
        
        // Add diagnostic traces
        trace('Generating notes with:');
        trace('  totalSteps: ${totalSteps}');
        trace('  patternLength: ${patternLength}');
        trace('  stepSize: ${stepSize}');
        trace('  chordTicks: ${timeManipulator.chordTicks}');

        for (c in seq.toNotes()) {
            // Reset both indices for each chord
            lastNoteIndex = -1;
            lastNoteValue = -1;
            
            // Reset the rhythm generator for each chord
            rhythmGenerator.reset();
            
            // Single loop through all steps for this chord
            for (step in 0...totalSteps) {
                var selector = rhythmGenerator.next();
                
                // Only add notes for non-Rest selectors
                if (selector != Rest) {
                    var notesToAdd = selectNotesFromChord(selector, c);
                    for (note in notesToAdd) {
                        notes.push(new Note(
                            0,
                            note,
                            100,
                            currentTime,
                            noteLength
                        ));
                    }
                }
                
                currentTime += stepSize;
            }
        }
        
        trace('Generated ${notes.length} notes');
        return notes;
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

    public function transpose(offset: Int): LineGenerator {
        this.transposition = offset;
        this.cachedNotes = null;  // Clear cache to force regeneration
        return this;
    }
}


