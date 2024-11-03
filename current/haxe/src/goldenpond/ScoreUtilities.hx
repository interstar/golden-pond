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


@:expose

class Note {
  public var chan:Int;
  public var note:Int;
  public var start_time:Float;
  public var length:Float;

  public function new(chan:Int, note:Int, start_time:Float, length:Float) {
    this.chan = chan;
    this.note = note;
    this.start_time = start_time;
    this.length = length;
  }

  public function toString():String {
    return 'Note[chan: ' + chan + ', note: ' + note + ', start_time: ' + start_time + ', length: ' + length + ']';
  }

  @:expose
  public function toStruct() {
      return {chan: this.chan, note: this.note, start_time: this.start_time, length: this.length};
  }
    
  public function equals(other:Note):Bool {
    return this.note == other.note && this.start_time == other.start_time && this.length == other.length;
  }

  @:expose
  public function transpose(offset:Int):Note {
    return new Note(this.chan,this.note+offset,this.start_time,this.length);
  }
}



@:expose
class ScoreUtilities {

  public static function transposeNotes(notes:Array<Note>,offset:Int):Array<Note> {
    return [for (n in notes) n.transpose(offset)];
  }

  public static function makePianoRollSVG(notes:Array<Note>, svgWidth:Int, svgHeight:Int):String {
    var noteHeight = svgHeight/100;
    var timeScale = 0.1; // Scale factor for time
    var pitchOffset = 20; // Offset to start the pitch axis higher
    
    var svg = new StringBuf();
    svg.add('<svg width="' + svgWidth + '" height="' + svgHeight + '" xmlns="http://www.w3.org/2000/svg">\n');
    
    // Draw faint horizontal lines for each note row
    for (i in 0...Std.int(svgHeight / noteHeight)) {
      var y = i * noteHeight;
      svg.add('<line x1="0" y1="' + y + '" x2="' + svgWidth + '" y2="' + y + '" stroke="#ddd" />\n');
    }
    
    // Draw each note as a rectangle
    for (note in notes) {
      var x = note.start_time * timeScale;
      var y = svgHeight - ((note.note - pitchOffset) * noteHeight) - noteHeight;         
      var width = note.length * timeScale;
      var height = noteHeight;
      
      svg.add('<rect x="' + x + '" y="' + y + '" width="' + width + '" height="' + height + '" fill="black" />\n');
    }
    
    svg.add('</svg>');

    return svg.toString();
  }
}
  
