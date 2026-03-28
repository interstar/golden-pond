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
    public var mode:Int; // 0=major, 1=minor, 2=harmonic minor, 3=melodic minor
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
    
    @:expose
    public function new() {
        this.root = 60; // Default to C4
        this.mode = 0;  // Default to major
        this.chordSequence = "1,4,5,1";
        this.stutter = 0;
        this.bpm = 120;
        this.chordDuration = 4;
        this.ppq = 960;
        this.lines = [];
        this.lastSerializedString = "";
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
     * @param modeIndex 0=major, 1=minor, 2=harmonic minor, 3=melodic minor
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function setMode(modeIndex:Int):GoldenData {
        this.mode = modeIndex;
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
        var modeNames = ["major", "minor", "harmonic minor", "melodic minor"];
        var modeName = modeNames[this.mode];
        
        var result = 'GoldenPond Project\n';
        result += '-------------------------------------------\n';
        result += 'Root: ${this.root}\n';
        result += 'Mode: ${modeName} (${this.mode})\n';
        result += 'Chord Sequence: ${this.chordSequence}\n';
        result += 'Stutter: ${this.stutter}\n';
        result += 'BPM: ${this.bpm}\n';
        result += 'Chord Duration: ${this.chordDuration}\n';
        result += 'PPQ: ${this.ppq}\n';
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
     * Corrects an incoming MIDI note to the nearest note of the scale 
     * that is active at a specific time in the progression.
     * @param noteToCorrect The incoming MIDI note value.
     * @param timeInTicks The time of the note event in ticks.
     * @param previousNote Optional: The previously played note, used to determine melodic direction for melodic minor scales.
     * @return The corrected MIDI note value.
     */
    @:expose
    public function correct(noteToCorrect:Int, timeInTicks:Float, ?previousNote:Null<Int>):Int {
        // Determine melodic direction (0=none, 1=ascending, -1=descending).
        var direction = 0; 
        if (previousNote != null) {
            if (noteToCorrect > previousNote) direction = 1;
            else if (noteToCorrect < previousNote) direction = -1;
        }

        // 1. Get the correct scale for the given time and melodic direction.
        var scaleNotes = getScaleForChordAtTime(timeInTicks, noteToCorrect, previousNote);

        // 2. If we couldn't determine a scale (e.g., empty progression), return the original note.
        if (scaleNotes == null || scaleNotes.length == 0) {
            return noteToCorrect;
        }

        // 3. Map the note to the nearest note in the determined scale.
        return mapToNearestInScale(noteToCorrect, scaleNotes, direction);
    }
    
    /**
     * Determines which scale is active at a specific time in ticks.
     * Includes special handling for melodic minor scales based on direction.
     */
    private function getScaleForChordAtTime(timeInTicks:Float, noteToCorrect:Int, ?previousNote:Null<Int>):Array<Int> {
        var timeManipulator = this.makeTimeManipulator();
        var progression = this.makeChordProgression();

        var chordDurationInTicks = timeManipulator.chordTicks;
        if (chordDurationInTicks <= 0) return null;

        // Find the index of the chord playing at the given time.
        var chordIndex = Math.floor(timeInTicks / chordDurationInTicks);
        
        var chordThings = progression.toChordThings();
        if (chordThings == null || chordThings.length == 0) return null;

        // Get the active chord, looping the progression if it has finished.
        var activeChord = chordThings[chordIndex % chordThings.length];

        // Determine melodic direction (0=none, 1=ascending, -1=descending).
        var direction = 0; 
        if (previousNote != null) {
            if (noteToCorrect > previousNote) direction = 1;
            else if (noteToCorrect < previousNote) direction = -1;
        }

        var tonic = activeChord.key;
        var intervals = activeChord.mode.intervals;

        // Special handling for Melodic Minor: use natural minor on descent.
        if (activeChord.mode.valueEquals(Mode.getMelodicMinorMode()) && direction == -1) {
            intervals = Mode.getMinorMode().intervals;
        }

        // Generate the 7 notes of the active scale.
        var scale = [tonic];
        var currentNote = tonic;
        for (i in 0...6) {
            currentNote += intervals[i % intervals.length];
            scale.push(currentNote);
        }
        return scale;
    }
    
    /**
     * Maps an incoming note to the nearest pitch in a given scale.
     */
    private function mapToNearestInScale(noteIn:Int, scaleNotes:Array<Int>, direction:Int):Int {
        if (scaleNotes == null || scaleNotes.length == 0) return noteIn;

        var noteInClass = noteIn % 12;
        var minDistance = 12;
        var candidates:Array<Int> = [];

        // First, find the minimum distance
        for (scaleNote in scaleNotes) {
            var scaleNoteClass = scaleNote % 12;
            var distance = Std.int(Math.abs(noteInClass - scaleNoteClass));
            if (distance > 6) distance = 12 - distance;
            if (distance < minDistance) {
                minDistance = distance;
            }
        }

        // Now, collect all candidates with that minimum distance
        for (scaleNote in scaleNotes) {
            var scaleNoteClass = scaleNote % 12;
            var distance = Std.int(Math.abs(noteInClass - scaleNoteClass));
            if (distance > 6) distance = 12 - distance;
            
            if (distance == minDistance) {
                if (candidates.indexOf(scaleNoteClass) == -1) {
                    candidates.push(scaleNoteClass);
                }
            }
        }

        if (candidates.length == 0) return noteIn;

        var closestNoteClass = -1;

        if (candidates.length == 1) {
            closestNoteClass = candidates[0];
        } else {
            // Tie-breaking logic
            if (direction == 1) { // Ascending, prefer the higher note
                var higherNote = -1;
                for (c in candidates) {
                    var diff = c - noteInClass;
                    if (diff < -6) diff += 12; // e.g. C(0) is higher than B(11)
                    if (diff > 0) { // It's a note above
                        if (higherNote == -1) higherNote = c;
                    }
                }
                if (higherNote != -1) closestNoteClass = higherNote;
                else closestNoteClass = candidates[0]; // Fallback
            } else { // Descending or no direction, prefer the lower note (which is the old behavior)
                closestNoteClass = candidates[0];
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