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
    
    // Line data - each entry is a map with pattern, volume, octave, etc.
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
        this.lines = [];
        this.lastSerializedString = "";
    }
    
    /**
     * Add a line to the project
     * @param pattern The rhythm pattern string
     * @param volume The volume (0.0-1.0)
     * @param octave The octave transposition (-3 to 3)
     * @param channel The channel number (0-15)
     * @param gateLength The gate length (0.0-1.0)
     * @return This GoldenData instance for chaining
     */
    @:expose
    public function addLine(pattern:String, volume:Float, octave:Int, channel:Int = 0, gateLength:Float = 0.8):GoldenData {
        lines.push(new LineData(pattern, volume, octave, channel, gateLength));
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
     * Get the Mode object corresponding to the current mode index
     * @return The Mode object
     */
    @:expose
    public function getModeObject():Mode {
        switch (this.mode) {
            case 0: return Mode.getMajorMode();
            case 1: return Mode.getMinorMode();
            case 2: return Mode.getHarmonicMinorMode();
            case 3: return Mode.getMelodicMinorMode();
            default: return Mode.getMajorMode();
        }
    }
    
    /**
     * Create a ChordProgression from the current settings
     * @return A ChordProgression object
     */
    @:expose
    public function createProgression():IChordProgression {
        var baseProgression = new ChordProgression(this.root, this.getModeObject(), this.chordSequence);
        if (this.stutter > 0) {
            return new StutteredChordProgression(baseProgression, this.stutter);
        }
        return baseProgression;
    }
    
    /**
     * Create line generators for all lines in the project
     * @param timingInfo The TimeManipulator to use for timing
     * @return Array of LineGenerator objects
     */
    @:expose
    public function createLineGenerators(timingInfo:TimeManipulator):Array<LineGenerator> {
        var progression = this.createProgression();
        var generators:Array<LineGenerator> = [];
        
        for (line in this.lines) {
            var generator = LineGenerator.createFromPattern(
                timingInfo,
                progression,
                line.pattern,
                line.gateLength
            );
            if (generator != null) {
                generator.transpose(line.octave * 12);
                generators.push(generator);
            }
        }
        
        return generators;
    }
    
    /**
     * Check if the data has changed since the last serialization
     * @return True if the data has changed
     */
    @:expose
    public function hasChanged():Bool {
        var currentString = this.toString();
        var changed = currentString != this.lastSerializedString;
        this.lastSerializedString = currentString;
        return changed;
    }
    
    /**
     * Convert the project data to a string representation
     * @return A string representation of the project
     */
    @:expose
    public function toString():String {
        var modeNames = ["major", "minor", "harmonic minor", "melodic minor"];
        var modeName = modeNames[this.mode];
        
        var result = 'GoldenPond Project\n';
        result += '-------------------------------------------\n';
        result += 'Root: ${this.root}\n';
        result += 'Mode: ${modeName}\n';
        result += 'Chord Sequence: ${this.chordSequence}\n';
        result += 'Stutter: ${this.stutter}\n';
        result += 'BPM: ${this.bpm}\n';
        result += 'Chord Duration: ${this.chordDuration}\n';
        result += 'Lines:\n';
        
        for (i in 0...this.lines.length) {
            var line = this.lines[i];
            result += '  Line ${i+1}: Pattern="${line.pattern}", Volume=${line.volume}, Octave=${line.octave}, Channel=${line.channel}\n';
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
            lines: this.lines.map(function(line) {
                return {
                    pattern: line.pattern,
                    volume: line.volume,
                    octave: line.octave,
                    channel: line.channel,
                    gateLength: line.gateLength
                };
            })
        };
        return haxe.Json.stringify(data);
    }
    
    /**
     * Create a GoldenData object from a JSON string
     * @param json The JSON string
     * @return A new GoldenData object
     */
    @:expose
    public static function fromJSON(json:String):GoldenData {
        var data = haxe.Json.parse(json);
        var result = new GoldenData();
        
        // Set basic properties
        result.root = data.root;
        result.mode = data.mode;
        result.chordSequence = data.chordSequence;
        result.stutter = data.stutter;
        result.bpm = data.bpm;
        result.chordDuration = data.chordDuration;
        
        // Recreate lines
        result.lines = [];
        var linesArray:Array<Dynamic> = cast data.lines;
        for (lineData in linesArray) {
            result.addLine(
                lineData.pattern,
                lineData.volume,
                lineData.octave,
                lineData.channel,
                lineData.gateLength
            );
        }
        
        return result;
    }
}

/**
 * LineData - A class to store data for a single line
 */
class LineData {
    public var pattern:String;
    public var volume:Float;
    public var octave:Int;
    public var channel:Int;
    public var gateLength:Float;
    
    public function new(pattern:String, volume:Float, octave:Int, channel:Int, gateLength:Float = 0.8) {
        this.pattern = pattern;
        this.volume = volume;
        this.octave = octave;
        this.channel = channel;
        this.gateLength = gateLength;
    }
} 