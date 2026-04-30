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

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import Mode;


class ChordThing {
    public var key:Int;
    public var mode:Mode;
    public var degree:Int;
    public var length:Int;
    public var modifiers:Array<Modifier>;
    public var inversion:Int;
    public var secondary_degree:Null<Int>;

    public function new(key:Int, mode:Mode, degree:Int, length:Int = 1) {
        this.key = key;
        this.mode = mode;
        this.degree = degree;
        this.length = length;
        this.modifiers = [];
        this.inversion = 0;
        this.secondary_degree = null;
    }

    public function valueEquals(other:Dynamic):Bool {
        if (!Std.isOfType(other, ChordThing)) return false;
        var otherChord:ChordThing = cast(other, ChordThing);
        
        if (this.key != otherChord.key || !this.mode.valueEquals(otherChord.mode) || 
            this.degree != otherChord.degree || this.length != otherChord.length || 
            this.inversion != otherChord.inversion ||
            this.secondary_degree != otherChord.secondary_degree) {
            return false;
        }

        if (this.modifiers.length != otherChord.modifiers.length) {
            return false;
        }

        for (i in 0...this.modifiers.length) {
            if (this.modifiers[i] != otherChord.modifiers[i]) {
                return false;
            }
        }

        return true;
    }

    public function set_as_secondary(secondary_degree:Int):ChordThing {
        this.modifiers.push(Modifier.SECONDARY);
        this.secondary_degree = secondary_degree;
        return this;
    }

    public function swap_mode():ChordThing {
        if (this.mode.valueEquals(Mode.getMajorMode())) {
            this.mode = Mode.getMinorMode();
        } else {
            this.mode = Mode.getMajorMode();
        }
        return this;
    }

    public function seventh():ChordThing {
        if (this.modifiers.indexOf(Modifier.NINTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.NINTH), 1);
        }
        if (this.modifiers.indexOf(Modifier.SIXTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.SIXTH), 1);
        }
        this.modifiers.push(Modifier.SEVENTH);
        return this;
    }

    public function ninth():ChordThing {
        if (this.modifiers.indexOf(Modifier.SEVENTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.SEVENTH), 1);
        }
        if (this.modifiers.indexOf(Modifier.SIXTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.SIXTH), 1);
        }
        this.modifiers.push(Modifier.NINTH);
        return this;
    }

    public function sixth():ChordThing {
        if (this.modifiers.indexOf(Modifier.SEVENTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.SEVENTH), 1);
        }
        if (this.modifiers.indexOf(Modifier.NINTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.NINTH), 1);
        }
        this.modifiers.push(Modifier.SIXTH);
        return this;
    }

    public function set_inversion(inversion:Int):ChordThing {
        this.inversion = inversion;
        return this;
    }

    public function set_voice_leading():ChordThing {
        this.modifiers.push(Modifier.VOICE_LEADING);
        return this;
    }

    public function toString():String {
        var modeStr = (this.mode.valueEquals(Mode.getMajorMode())) ? "MAJOR" : "MINOR";
        var degree_repr = if (this.modifiers.indexOf(Modifier.SECONDARY) != -1)
            "(" + this.secondary_degree + "/" + this.degree + ")"
        else
            "" + this.degree;
        var modifierStrings = this.modifiers.map(function(modifier:Modifier):String {
            return Std.string(modifier);
        });
        var modifiersStr = "[" + modifierStrings.join(", ") + "]";

        return "ChordThing(" + this.key + "," + modeStr + "," + degree_repr + "," + this.inversion + "," + this.length + ") + " + modifiersStr;
    }

    public function clone():ChordThing {
        var ct = new ChordThing(this.key, this.mode, this.degree, this.length);
        ct.modifiers = this.modifiers.copy();
        ct.inversion = this.inversion;
        ct.secondary_degree = this.secondary_degree;
        return ct;
    }

    public function has_extensions():Bool {
        return this.modifiers.indexOf(Modifier.SEVENTH) != -1 || this.modifiers.indexOf(Modifier.NINTH) != -1;
    }

    public function get_mode():Mode {
        return this.mode;
    }
    
    /**
     * Calculates a secondary chord based on this chord
     * @return A new ChordThing representing the secondary chord
     */
    public function calculateAsSecondaryChord():ChordThing {
        var new_tonic = this.mode.nth_from(this.key, this.degree);
        var ct = new ChordThing(new_tonic, Mode.getMajorMode(), this.secondary_degree, this.length);

        if (this.modifiers.indexOf(Modifier.SEVENTH) != -1) ct.seventh();
        if (this.modifiers.indexOf(Modifier.NINTH) != -1) ct.ninth();
        ct.set_inversion(this.inversion);
        return ct;
    }
    
    /**
     * Generates the actual notes for this chord
     * @return Array of MIDI note numbers
     */
    public function generateChordNotes():Array<Int> {
        if (this.modifiers.indexOf(Modifier.SECONDARY) != -1 && this.secondary_degree != null) {
            return this.calculateAsSecondaryChord().generateChordNotes();
        }
        
        var chord:Array<Int>;
        
        if (this.modifiers.indexOf(Modifier.NINTH) != -1) {
            chord = this.mode.make_ninth(this.key, this.degree);
        } else if (this.modifiers.indexOf(Modifier.SEVENTH) != -1) {
            chord = this.mode.make_seventh(this.key, this.degree);
        } else if (this.modifiers.indexOf(Modifier.SIXTH) != -1) {
            chord = this.mode.make_sixth(this.key, this.degree);
        } else {
            chord = this.mode.make_triad(this.key, this.degree);
        }

        // Apply inversions
        for (i in 0...this.inversion) {
            chord.push(chord.shift() + 12);
        }

        return chord;
    }
    
    /**
     * Converts a MIDI note number to a note name (e.g., 60 -> "C4")
     * @param midiNote The MIDI note number
     * @param includeOctave Whether to include the octave in the name
     * @return The note name
     */
    private function midiToNoteName(midiNote:Int, includeOctave:Bool = false):String {
        var noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        var noteName = noteNames[midiNote % 12];
        
        if (includeOctave) {
            var octave = Math.floor(midiNote / 12) - 1;
            return noteName + octave;
        }
        
        return noteName;
    }
    
    /**
     * Calculates the actual root note of the chord based on the key, degree, and mode
     * @return The MIDI note number of the root
     */
    private function calculateRootNote():Int {
        return this.mode.nth_from(this.key, this.degree);
    }
    
    /**
     * Gets the bass note for inversions
     * @return The MIDI note number of the bass note
     */
    private function getBassNote():Int {
        if (this.inversion == 0) {
            return calculateRootNote();
        }
        
        // Create a clone without inversion to get the original chord notes
        var originalChord = this.clone();
        originalChord.inversion = 0;
        var chordNotes = originalChord.generateChordNotes();
        
        // Return the appropriate note based on inversion
        // Ensure the inversion index is valid
        var inversionIndex = Std.int(Math.min(this.inversion, chordNotes.length - 1));
        return chordNotes[inversionIndex];
    }
    
    /**
     * Determines the chord quality by analyzing the intervals between notes
     * @return The chord quality as a string (e.g., "", "m", "dim", "aug")
     */
    private function determineChordQuality():String {
        var chordNotes = getUninvertedChordNotes();
        
        if (chordNotes.length < 3) {
            // Not enough notes to determine quality
            return "";
        }
        
        // Calculate intervals from the root
        var root = chordNotes[0];
        var third = chordNotes[1];
        var fifth = chordNotes[2];
        
        // Calculate interval sizes
        var thirdInterval = intervalFromRoot(third, root);
        var fifthInterval = intervalFromRoot(fifth, root);
        
        // Determine chord quality based on intervals
        if (thirdInterval == 4 && fifthInterval == 7) {
            // Major chord (major third + perfect fifth)
            return "";
        } else if (thirdInterval == 3 && fifthInterval == 7) {
            // Minor chord (minor third + perfect fifth)
            return "m";
        } else if (thirdInterval == 3 && fifthInterval == 6) {
            // Diminished chord (minor third + diminished fifth)
            return "dim";
        } else if (thirdInterval == 4 && fifthInterval == 8) {
            // Augmented chord (major third + augmented fifth)
            return "aug";
        } else {
            // Default to major/minor based on third
            return (thirdInterval == 4) ? "" : "m";
        }
    }
    
    private function getUninvertedChordNotes():Array<Int> {
        var originalChord = this.clone();
        originalChord.inversion = 0;
        return originalChord.generateChordNotes();
    }

    private function intervalFromRoot(note:Int, root:Int):Int {
        var interval = (note - root) % 12;
        return interval < 0 ? interval + 12 : interval;
    }

    private function determineChordSuffix():String {
        var chordNotes = getUninvertedChordNotes();
        if (chordNotes.length < 3) return "";

        var root = chordNotes[0];
        var thirdInterval = intervalFromRoot(chordNotes[1], root);
        var fifthInterval = intervalFromRoot(chordNotes[2], root);
        var quality = determineChordQuality();
        var hasSeventh = this.modifiers.indexOf(Modifier.SEVENTH) != -1;
        var hasNinth = this.modifiers.indexOf(Modifier.NINTH) != -1;
        var hasSixth = this.modifiers.indexOf(Modifier.SIXTH) != -1;

        if (hasSixth) {
            return quality == "" ? "6" : quality + "6";
        }

        if (!hasSeventh && !hasNinth) {
            return quality;
        }

        if (chordNotes.length < 4) {
            return quality;
        }

        var seventhInterval = intervalFromRoot(chordNotes[3], root);
        var isNinth = hasNinth && chordNotes.length >= 5;

        if (thirdInterval == 3 && fifthInterval == 6) {
            if (seventhInterval == 9) {
                return isNinth ? "dim9" : "dim7";
            }
            if (seventhInterval == 10) {
                return isNinth ? "m7b5(add9)" : "m7b5";
            }
        }

        if (thirdInterval == 4 && fifthInterval == 7) {
            if (seventhInterval == 11) {
                return isNinth ? "maj9" : "maj7";
            }
            if (seventhInterval == 10) {
                return isNinth ? "9" : "7";
            }
        }

        if (thirdInterval == 3 && fifthInterval == 7) {
            if (seventhInterval == 11) {
                return isNinth ? "m(maj9)" : "m(maj7)";
            }
            if (seventhInterval == 10) {
                return isNinth ? "m9" : "m7";
            }
        }

        if (thirdInterval == 4 && fifthInterval == 8) {
            if (seventhInterval == 11) {
                return isNinth ? "augmaj9" : "augmaj7";
            }
            if (seventhInterval == 10) {
                return isNinth ? "aug9" : "aug7";
            }
        }

        return quality + (isNinth ? "9" : "7");
    }
    
    /**
     * Converts this ChordThing to a conventional chord name
     * @return The chord name in standard notation
     */
    public function getChordName():String {
        // If this is a secondary chord, we need to calculate it the same way ChordFactory does
        if (this.modifiers.indexOf(Modifier.SECONDARY) != -1 && this.secondary_degree != null) {
            // Create a new chord in the temporarily tonicized key
            var secondaryChord = this.calculateAsSecondaryChord();
            return secondaryChord.getChordName();
        }
        
        var chordNotes = getUninvertedChordNotes();
        if (chordNotes.length == 0) return "";

        var rootNote = chordNotes[0];
        var rootName = midiToNoteName(rootNote);
        
        // Build the chord name
        var chordName = rootName + determineChordSuffix();
        
        // Add inversion if present (using slash notation)
        if (this.inversion > 0) {
            var bassNote = getBassNote();
            var bassName = midiToNoteName(bassNote);
            
            chordName += "/" + bassName;
        }
        
        return chordName;
    }

    public function set_mode(newMode:Mode) {
        this.mode = newMode;
    }
}
