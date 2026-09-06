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

enum ChordToken {
    ChordAtom(value:String);
    ModeDirective(value:String);
    TransposeDirective(value:String);
    VoiceLeadNext;
}

class ChordTokenizer {
    private static function isWhitespace(char:String):Bool {
        return char == " " || char == "\t" || char == "\n" || char == "\r";
    }

    private static function isSoftSeparator(char:String):Bool {
        return char == "," || char == "|" || isWhitespace(char);
    }

    private static function readDirective(inputString:String, start:Int):Int {
        var pos = start + 1;
        while (pos < inputString.length) {
            var char = inputString.charAt(pos);
            if (isSoftSeparator(char) || char == "&") {
                break;
            }
            pos++;
        }
        return pos;
    }

    private static function readChordAtom(inputString:String, start:Int):Int {
        var pos = start;
        var insideParentheses = false;
        while (pos < inputString.length) {
            var char = inputString.charAt(pos);
            if (char == "(") {
                insideParentheses = true;
            } else if (char == ")") {
                insideParentheses = false;
            }

            if (!insideParentheses && (isSoftSeparator(char) || char == "&" || char == ">" || char == "<")) {
                break;
            }
            pos++;
        }
        return pos;
    }

    public static function tokenize(inputString:String):Array<ChordToken> {
        var tokens:Array<ChordToken> = [];
        var pos = 0;

        while (pos < inputString.length) {
            var char = inputString.charAt(pos);
            if (isSoftSeparator(char)) {
                pos++;
            } else if (char == "&") {
                tokens.push(VoiceLeadNext);
                pos++;
            } else if (char == "!") {
                var end = readDirective(inputString, pos);
                tokens.push(ModeDirective(inputString.substr(pos, end - pos)));
                pos = end;
            } else if (char == ">" || char == "<") {
                var end = readDirective(inputString, pos);
                tokens.push(TransposeDirective(inputString.substr(pos, end - pos)));
                pos = end;
            } else {
                var end = readChordAtom(inputString, pos);
                var atom = StringTools.trim(inputString.substr(pos, end - pos));
                if (atom.length > 0) {
                    tokens.push(ChordAtom(atom));
                }
                pos = end;
            }
        }

        return tokens;
    }
}

class ChordParser {
    public var key:Int;
    public var mode:Mode;

    public function new(key:Int, mode:Mode) {
        this.key = key;
        this.mode = mode;
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

    private function applyChordType(chord:ChordThing, chordType:String):ChordThing {
        if (chordType == null || chordType.length == 0) return chord;

        switch (chordType) {
            case "6":
                chord.sixth();
            case "7":
                chord.seventh();
            case "9":
                chord.ninth();
            case "11":
                chord.eleventh();
            case "13":
                chord.thirteenth();
            case "s2", "sus2":
                chord.sus2();
            case "s4", "sus4":
                chord.sus4();
            default:
                throw "Unexpected chord type: " + chordType;
        }

        return chord;
    }

    private function parseBracket(itemString:String):ChordThing {
        var parts = itemString.split('(');
        var chordType = parts[0];
        
        // Check if this is a mode selection (degree!mode) or secondary chord (degree/degree)
        var bracketContent = parts[1].substr(0, parts[1].length - 1);
        if (bracketContent.indexOf('!') != -1) {
            // Handle mode selection: (degree!mode)
            var modeParts = bracketContent.split('!');
            var degree = Std.parseInt(modeParts[0]);
            var modeNumber = Std.parseInt(modeParts[1]);

            
            var chord = new ChordThing(this.key, this.mode, degree);
            chord.set_mode(Mode.nthModeOf(this.mode, modeNumber));
            return applyChordType(chord, chordType);
        } else {
            // Handle secondary chord: (degree/degree)
            var secondaryParts = bracketContent.split('/');
            var secondaryDegree = Std.parseInt(secondaryParts[0]);
            var degree = Std.parseInt(secondaryParts[1]);
            var chord = new ChordThing(this.key, this.mode, degree);
            chord.set_as_secondary(secondaryDegree);
            return applyChordType(chord, chordType);
        }
    }

    private function parseTypedItem(itemString:String, modeToUse:Mode):ChordThing {
        var parts = itemString.split(':');
        if (parts.length != 2) {
            throw "Expected chord type and target separated by ':' in: " + itemString;
        }

        var chordType = parts[0];
        var target = parts[1];
        if (target.indexOf('(') != -1 && target.indexOf(')') != -1) {
            return parseBracket(chordType + target);
        }

        var degree = Std.parseInt(target);
        if (degree == null || degree < 1 || degree > 7) {
            throw "Unexpected chord target: " + target;
        }

        return applyChordType(new ChordThing(this.key, modeToUse, degree), chordType);
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

        var modeToUse = isModalInterchange ? 
            ((this.mode == Mode.getMajorMode()) ? Mode.getMinorMode() : Mode.getMajorMode()) : 
            this.mode;

        if (itemString.indexOf(':') != -1) {
            var chord = parseTypedItem(itemString, modeToUse);
            chord.set_inversion(inversion);
            return chord;
        }

        if (itemString.indexOf('(') != -1 && itemString.indexOf(')') != -1) {
            var chord = parseBracket(itemString);
            chord.set_inversion(inversion);
            return chord;
        }

        var itemValue = Std.parseInt(itemString);

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

    private function interpretTranspose(transposeString:String) {
        if (transposeString.charAt(0) != '>' && transposeString.charAt(0) != '<') {
            throw "Expected '>' or '<' at the start of '" + transposeString + "'";
        }
        var transposeValue = Std.parseInt(transposeString.substr(1));
        if (transposeString.charAt(0) == '>') {
            this.key += transposeValue;
        } else {
            this.key -= transposeValue;
        }
    }

    private function interpretMode(modeString:String) {
        if (modeString.length < 2) {
            throw "Expected mode specifier after '!'. Use !M, !m, !hm, !mm, !HM, !hu, or !H2";
        }

        var modeSpec = modeString.substr(1);
        switch (modeSpec) {
            case 'M':
                this.mode = Mode.getMajorMode();
            case 'm':
                this.mode = Mode.getMinorMode();
            case 'hm':
                this.mode = Mode.getHarmonicMinorMode();
            case 'mm':
                this.mode = Mode.getMelodicMinorMode();
            case 'HM':
                this.mode = Mode.getHarmonicMajorMode();
            case 'hu':
                this.mode = Mode.getHungarianMinorMode();
            case 'H2':
                this.mode = Mode.getDoubleHarmonicMajorMode();
            default:
                throw "Invalid mode specifier: " + modeSpec + ". Use !M, !m, !hm, !mm, !HM, !hu, or !H2";
        }
    }

    public function parse(inputString:String):Array<ChordThing> {
        var chords:Array<ChordThing> = [];
        var voiceLeadNext = false;

        for (token in ChordTokenizer.tokenize(inputString)) {
            switch (token) {
                case VoiceLeadNext:
                    voiceLeadNext = true;
                case ModeDirective(modeString):
                    interpretMode(modeString);
                case TransposeDirective(transposeString):
                    interpretTranspose(transposeString);
                case ChordAtom(itemString):
                    var chord = interpretItem(itemString);
                    if (voiceLeadNext) {
                        chord.set_voice_leading();
                    }
                    chords.push(chord);
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

