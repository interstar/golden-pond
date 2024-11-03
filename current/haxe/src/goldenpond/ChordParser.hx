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
            var extension = null;
            var parts = itemString.split('(');
            if (parts[0].length > 0) {
                extension = Std.parseInt(parts[0]);
            }
            var secondaryParts = parts[1].substr(0, parts[1].length - 1).split('/');
            var secondaryDegree = Std.parseInt(secondaryParts[0]);
            var degree = Std.parseInt(secondaryParts[1]);
            var chord = new ChordThing(this.key, this.mode, degree);
            chord.set_as_secondary(secondaryDegree);
            chord.set_inversion(inversion);
            if (extension != null) {
                if (extension == 7) {
                    chord.seventh();
                } else if (extension == 9) {
                    chord.ninth();
                }
            }
            return chord;
        }

        var itemValue = Std.parseInt(itemString);

        var chord:ChordThing;
        if (1 <= itemValue && itemValue <= 7) {
            chord = new ChordThing(this.key, this.mode, itemValue);
        } else if (71 <= itemValue && itemValue <= 77) {
            chord = new ChordThing(this.key, this.mode, itemValue - 70).seventh();
        } else if (91 <= itemValue && itemValue <= 97) {
            chord = new ChordThing(this.key, this.mode, itemValue - 90).ninth();
        } else {
            throw "Unexpected item value: " + itemString;
        }

        if (isModalInterchange) {
            chord.modal_interchange();
        }

        chord.set_inversion(inversion);

        return chord;
    }

    public function parse(inputString:String):Array<ChordThing> {
        var chords:Array<ChordThing> = [];
        var voiceLeadNext = false;

        while (inputString.length > 0) {
            var sepResult = parseSeparator(inputString);
            var separator = sepResult._0;
            inputString = sepResult._1;

            if (separator == '&') {
                voiceLeadNext = true;
            }

            if (inputString.length > 0) {
                if (inputString.charAt(0) == '!') {
                    this.mode = (this.mode == Mode.getMajorMode()) ? Mode.getMinorMode() : Mode.getMajorMode();
                    inputString = inputString.substr(1);
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
class ChordProgression {
  public var key:Int;
  public var mode:Mode;
  public var scoreString:String;
  private var stutter:Int;
  private var chordThings:Array<ChordThing>;

  @:expose
  public function new(key:Int, mode:Mode, scoreString:String) {
    this.key = key;
    this.mode = mode;
    this.scoreString = scoreString;
    this.stutter = 0;
    this.recalc();
  }

  private function recalc() {
    this.chordThings = this.toChordThings();
  } 
  
  @:expose
  public function setStutter(x:Int) {
    this.stutter=x;
    this.recalc();

    if (stutter > 0) {
      var lenseq = chordThings.length;
      var frag = chordThings.slice(0, stutter);
      var repeatedFrag:Array<ChordThing> = [];
      
      // Repeat frag to reach at least the length of lenseq
      while (repeatedFrag.length < lenseq) {
	repeatedFrag = repeatedFrag.concat(frag);
      }
      
      this.chordThings = repeatedFrag.slice(0, lenseq);
    }  
  }
  
  
  @:expose
  public function toChordThings():Array<ChordThing> {
    return new ChordParser(this.key, this.mode).parse(this.scoreString);
  }
  
  @:expose
  public function toNotes():Array<Array<Int>> {
    return ChordFactory.chordProgression(this.chordThings);
  }
}

