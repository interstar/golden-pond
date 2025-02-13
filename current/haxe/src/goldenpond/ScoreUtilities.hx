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
  public var startTime:Float;
  public var length:Float;
  public var velocity:Int;

  public function new(chan:Int, note:Int, velocity:Int, startTime:Float, length:Float) {
    this.chan = chan;
    this.note = note;
    this.startTime = startTime;
    this.length = length;
    this.velocity = velocity;
  }

  public function toString():String {
    return 'Note[chan: ' + chan + ', note: ' + note + ', vel: ' + velocity + ', startTime: ' + startTime + ', length: ' + length + ']';
  }

  @:expose
  public function toStruct() {
      return {chan: this.chan, note: this.note, velocity: this.velocity, startTime: this.startTime, length: this.length};
  }
    
  public function equals(other:Note):Bool {
    return this.note == other.note && this.velocity == other.velocity && this.startTime == other.startTime && this.length == other.length;
  }

  @:expose
  public function transpose(offset:Int):Note {
    return new Note(this.chan,this.note+offset,this.velocity,this.startTime,this.length);
  }
}



@:expose
class ScoreUtilities {

  public static function getNoteOn():NoteEventType {
    return NOTE_ON;
  }

  public static function getNoteOff():NoteEventType {
    return NOTE_OFF;
  }

  public static function transposeNotes(notes:Array<Note>,offset:Int):Array<Note> {
    return [for (n in notes) n.transpose(offset)];
  }

  public static function makePianoRollSVG(notes:Array<Note>, svgWidth:Int, svgHeight:Int):String {
    var noteHeight = svgHeight/100;
    
    // Find time range to scale properly
    var maxTime = 0.0;
    for (note in notes) {
        maxTime = Math.max(maxTime, note.startTime + note.length);
    }
    
    // Calculate timeScale based on the actual note durations
    var timeScale = maxTime > 0 ? svgWidth/maxTime : 0.1;
    var pitchOffset = 20; // Offset to start the pitch axis higher
    
    var svg = new StringBuf();
    svg.add('<svg width="' + svgWidth + '" height="' + svgHeight + 
            '" viewBox="0 0 ' + svgWidth + ' ' + svgHeight + 
            '" xmlns="http://www.w3.org/2000/svg">\n');
    
    // Draw faint horizontal lines for each note row
    for (i in 0...Std.int(svgHeight / noteHeight)) {
        var y = i * noteHeight;
        svg.add('<line x1="0" y1="' + y + '" x2="' + svgWidth + 
               '" y2="' + y + '" stroke="#ddd" />\n');
    }
    
    // Draw each note as a rectangle
    for (note in notes) {
        // Ensure all values are valid numbers
        var x = note.startTime * timeScale;
        var y = svgHeight - ((note.note - pitchOffset) * noteHeight) - noteHeight;
        var width = note.length * timeScale;
        var height = noteHeight;
        
        // Skip invalid notes
        if (Math.isNaN(x) || Math.isNaN(y) || Math.isNaN(width) || Math.isNaN(height)) {
            trace('Invalid note values: note=${note}, x=${x}, y=${y}, width=${width}, height=${height}');
            continue;
        }
        
        svg.add('<rect x="' + x + '" y="' + y + 
               '" width="' + width + '" height="' + height + 
               '" fill="black" />\n');
    }
    
    svg.add('</svg>');
    return svg.toString();
  }

  
}

@:expose
enum NoteEventType {
    NOTE_ON;
    NOTE_OFF;
}

@:expose
class DeltaEvent {
    public var chan:Int;
    public var note:Int;
    public var velocity:Int;
    public var deltaFromLast:Float;
    public var type:NoteEventType;

    public function new(chan:Int, note:Int, velocity:Int, deltaFromLast:Float, type:NoteEventType) {
        this.chan = chan;
        this.note = note;
        this.velocity = velocity;
        this.deltaFromLast = deltaFromLast;
        this.type = type;
    }

    public function toString():String {
        return 'DeltaEvent[chan: ${chan}, note: ${note}, vel: ${velocity}, delta: ${deltaFromLast}, type: ${type}]';
    }
}
  
