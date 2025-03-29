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


import Mode;
import ChordThing;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import StringTools;

class Tuple2<T1, T2> {
    public var _0:T1;
    public var _1:T2;

    public function new(_0:T1, _1:T2) {
        this._0 = _0;
        this._1 = _1;
    }
}

class ChordParser {
    public var key:Int;
    public var mode:Mode;

    public function new(key:Int, mode:Mode) {
        this.key = key;
        this.mode = mode;
    }

    private function parseSeparator(inputString:String):Tuple2<Null<String>, String> {
        var separators = ['|', ',', '&'];
        if (inputString.length > 0 && separators.indexOf(inputString.charAt(0)) != -1) {
            return new Tuple2(inputString.charAt(0), inputString.substr(1));
        } else {
            return new Tuple2(null, inputString);
        }
    }

    private function parseTranspose(inputString:String):String {
        var transposeChars = new StringBuf();
        while (inputString.length > 0 && [',', '|'].indexOf(inputString.charAt(0)) == -1) {
            transposeChars.add(inputString.charAt(0));
            inputString = inputString.substr(1);
        }
        var transposeString = StringTools.trim(transposeChars.toString());
        if (transposeString.charAt(0) != '>' && transposeString.charAt(0) != '<') {
            throw "Expected '>' or '<' at the start of '" + transposeString + "'";
        }
        var transposeValue = Std.parseInt(transposeString.substr(1));
        if (transposeString.charAt(0) == '>') {
            this.key += transposeValue;
        } else {
            this.key -= transposeValue;
        }
        return inputString;
    }

    private function parseItem(inputString:String):Tuple2<String, String> {
        var itemChars = new StringBuf();
        var insideParentheses = false;
        while (inputString.length > 0 && (insideParentheses || [',', '|', '&', '>', '<'].indexOf(inputString.charAt(0)) == -1)) {
            var char = inputString.charAt(0);
            if (char == '(') {
                insideParentheses = true;
            } else if (char == ')') {
                insideParentheses = false;
            }
            itemChars.add(char);
            inputString = inputString.substr(1);
        }
        return new Tuple2(StringTools.trim(itemChars.toString()), inputString);
    }

    private function countOccurrences(str:String, char:String):Int {
        var count = 0;
        for (i in 0...str.length) {
            if (str.charAt(i) == char) {
                count++;
            }
        }
        return count;
    }

    private function parseBracket(itemString:String):ChordThing {
        var extension = null;
        var parts = itemString.split('(');
        if (parts[0].length > 0) {
            extension = Std.parseInt(parts[0]);
        }
        
        // Check if this is a mode selection (degree!mode) or secondary chord (degree/degree)
        var bracketContent = parts[1].substr(0, parts[1].length - 1);
        if (bracketContent.indexOf('!') != -1) {
            // Handle mode selection: (degree!mode)
            var modeParts = bracketContent.split('!');
            var degree = Std.parseInt(modeParts[0]);
            var modeNumber = Std.parseInt(modeParts[1]);

            
            var chord = new ChordThing(this.key, this.mode, degree);
            
            // Set the mode based on the current mode and mode number
            var newMode:Mode;
            if (this.mode == Mode.getMajorMode()) {
                newMode = Mode.constructNthMajorMode(modeNumber);
            } else if (this.mode == Mode.getHarmonicMinorMode()) {
                newMode = Mode.constructNthHarmonicMinorMode(modeNumber);
            } else if (this.mode == Mode.getMelodicMinorMode()) {
                newMode = Mode.constructNthMelodicMinorMode(modeNumber);
            } else if (this.mode == Mode.getMinorMode()) {
                newMode = Mode.constructNthMinorMode(modeNumber);
            } else {
                throw "Cannot get nth mode of unknown scale";
            }
            chord.set_mode(newMode);
            
            if (extension != null) {
                if (extension == 7) {
                    chord.seventh();
                } else if (extension == 9) {
                    chord.ninth();
                }
            }
            return chord;
        } else {
            // Handle secondary chord: (degree/degree)
            var secondaryParts = bracketContent.split('/');
            var secondaryDegree = Std.parseInt(secondaryParts[0]);
            var degree = Std.parseInt(secondaryParts[1]);
            var chord = new ChordThing(this.key, this.mode, degree);
            chord.set_as_secondary(secondaryDegree);
            if (extension != null) {
                if (extension == 7) {
                    chord.seventh();
                } else if (extension == 9) {
                    chord.ninth();
                }
            }
            return chord;
        }
    }

    private function interpretItem(itemString:String):ChordThing {
        var isModalInterchange = false;
        if (itemString.charAt(0) == '-') {
            isModalInterchange = true;
            itemString = itemString.substr(1);
        }

        var inversion = 0;
        if (itemString.indexOf('i') != -1) {
            inversion = countOccurrences(itemString, 'i');
            itemString = itemString.split('i').join('');
        }

        if (itemString.indexOf('(') != -1 && itemString.indexOf(')') != -1) {
            var chord = parseBracket(itemString);
            chord.set_inversion(inversion);
            return chord;
        }

        var itemValue = Std.parseInt(itemString);
        var modeToUse = isModalInterchange ? 
            ((this.mode == Mode.getMajorMode()) ? Mode.getMinorMode() : Mode.getMajorMode()) : 
            this.mode;

        var chord:ChordThing;
        if (1 <= itemValue && itemValue <= 7) {
            chord = new ChordThing(this.key, modeToUse, itemValue);
        } else if (61 <= itemValue && itemValue <= 67) {
            chord = new ChordThing(this.key, modeToUse, itemValue - 60).sixth();
        } else if (71 <= itemValue && itemValue <= 77) {
            chord = new ChordThing(this.key, modeToUse, itemValue - 70).seventh();
        } else if (91 <= itemValue && itemValue <= 97) {
            chord = new ChordThing(this.key, modeToUse, itemValue - 90).ninth();
        } else {
            throw "Unexpected item value: " + itemString;
        }

        chord.set_inversion(inversion);

        return chord;
    }

    private function parseMode(inputString:String):String {
        var modeChars = new StringBuf();
        while (inputString.length > 0 && [',', '|'].indexOf(inputString.charAt(0)) == -1) {
            modeChars.add(inputString.charAt(0));
            inputString = inputString.substr(1);
        }
        var modeString = StringTools.trim(modeChars.toString());
        
        // Check if there's a mode specifier after the !
        if (modeString.length < 2) {
            throw "Expected mode specifier after '!'. Use !M, !m, !hm, or !mm";
        }
        
        var modeSpec = modeString.charAt(1);
        switch (modeSpec) {
            case 'M':
                this.mode = Mode.getMajorMode();
            case 'm':
                if (modeString.length >= 3 && modeString.charAt(2) == 'm') {
                    this.mode = Mode.getMelodicMinorMode();
                } else {
                    this.mode = Mode.getMinorMode();
                }
            case 'h':
                if (modeString.length < 3 || modeString.charAt(2) != 'm') {
                    throw "Expected 'hm' for harmonic minor mode";
                }
                this.mode = Mode.getHarmonicMinorMode();
            default:
                throw "Invalid mode specifier: " + modeSpec + ". Use !M, !m, !hm, or !mm";
        }
        
        return inputString;
    }

    public function parse(inputString:String):Array<ChordThing> {
        var chords:Array<ChordThing> = [];
        var voiceLeadNext = false;

        while (inputString.length > 0) {
            trace("Current input string: " + inputString);
            var sepResult = parseSeparator(inputString);
            var separator = sepResult._0;
            inputString = sepResult._1;
            trace("After separator parse: " + inputString);

            if (separator == '&') {
                voiceLeadNext = true;
            }

            if (inputString.length > 0) {
                if (inputString.charAt(0) == '!') {
                    inputString = parseMode(inputString);
                } else if (inputString.charAt(0) == '>' || inputString.charAt(0) == '<') {
                    inputString = parseTranspose(inputString);
                } else {
                    var itemResult = parseItem(inputString);
                    var itemString = itemResult._0;
                    inputString = itemResult._1;
                   
                    var chord = interpretItem(itemString);
                    if (voiceLeadNext) {
                        chord.set_voice_leading();
                    }
                    chords.push(chord);
                }
            }
        }

        return chords;
    }
}

@:expose
interface IChordProgression {
  public function toChordThings():Array<ChordThing>;
  public function toNotes():Array<Array<Int>>;
  public function getChordNames():Array<String>;
}

@:expose
class ChordProgression implements IChordProgression {
  public var key:Int;
  public var mode:Mode;
  public var scoreString:String;
  private var chordThings:Array<ChordThing>;

  @:expose
  public function new(key:Int, mode:Mode, scoreString:String) {
    this.key = key;
    this.mode = mode;
    this.scoreString = scoreString;
    this.recalc();
  }

  private function recalc() {
    this.chordThings = this.toChordThings();
  }
  
  @:expose
  public function toChordThings():Array<ChordThing> {
    return new ChordParser(this.key, this.mode).parse(this.scoreString);
  }
  
  @:expose
  public function toNotes():Array<Array<Int>> {
    var chords = [];
    var prev_chord:Array<Int> = null;

    for (ct in this.chordThings) {
      var chord = ct.generateChordNotes();
      if (prev_chord != null && ct.modifiers.indexOf(Modifier.VOICE_LEADING) != -1) {
        chord = voice_lead(prev_chord, chord);
      }
      chords.push(chord);
      prev_chord = chord;
    }

    return chords;
  }
  
  private function voice_lead(prevChord:Array<Int>, nextChord:Array<Int>):Array<Int> {
    return nextChord;  // Dummy implementation for now
  }
  
  @:expose
  public function getChordNames():Array<String> {
    var names = [];
    for (ct in this.chordThings) {
      names.push(ct.getChordName());
    }
    return names;
  }
}

@:expose
class StutteredChordProgression implements IChordProgression {
  private var progression:ChordProgression;
  private var stutterCount:Int;
  
  @:expose
  public function new(progression:ChordProgression, stutterCount:Int) {
    this.progression = progression;
    this.stutterCount = stutterCount;
  }
  
  @:expose
  public function setStutterCount(count:Int):StutteredChordProgression {
    this.stutterCount = count;
    return this;
  }
  
  @:expose
  public function getStutterCount():Int {
    return this.stutterCount;
  }
  
  private function stutterArray<T>(items:Array<T>):Array<T> {
    if (stutterCount <= 0 || items.length <= 0) {
      return items;
    }
    
    // Take the first stutterCount items (or all if there are fewer)
    var count:Int = Std.int(Math.min(stutterCount, items.length));
    var fragment = items.slice(0, count);
    var result:Array<T> = [];
    
    // Repeat the fragment to match the original length
    while (result.length < items.length) {
      result = result.concat(fragment);
    }
    
    // Trim to the original length
    return result.slice(0, items.length);
  }
  
  @:expose
  public function toChordThings():Array<ChordThing> {
    return stutterArray(progression.toChordThings());
  }
  
  @:expose
  public function toNotes():Array<Array<Int>> {
    return stutterArray(progression.toNotes());
  }
  
  @:expose
  public function getChordNames():Array<String> {
    return stutterArray(progression.getChordNames());
  }
}

