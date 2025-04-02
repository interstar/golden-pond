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


@:expose
interface INote {
  function getMidiNoteValue():Int;
  function getStartTime():Float;
  function getLength():Float;
}



@:expose
interface IDeserializationHelper {
  function helpMake(code:String,json:String):ISerializable;
}

@:expose
interface ISerializable {
  function toString(): String;
  function toJSON(): String;
  function getCode(): String;
}



@:expose
interface IInstrumentContext extends ISerializable {
  // Note that duration is actually the duration available for the whole of the note. We expect 
  // the instrument context to know about gateLengths etc. to calculate the real length of the note
  function makeNote(note: Int, startTime: Float, duration: Float): INote;
}


@:expose

class Note implements INote {
  private  var chan:Int;
  private var note:Int;
  private var startTime:Float;
  private var length:Float;
  private var velocity:Int;

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
    return this.chan == other.chan &&
           this.note == other.note && 
           this.velocity == other.velocity && 
           this.startTime == other.startTime && 
           this.length == other.length;
  }

  @:expose
  public function transpose(offset:Int):Note {
    return new Note(this.chan,this.note+offset,this.velocity,this.startTime,this.length);
  }

  public function getMidiNoteValue():Int {
    return this.note;
  }

  public function getStartTime():Float {
    return this.startTime;
  }

  public function getLength():Float {
    return this.length;
  }
}

@:expose
class ScoreUtilities {
  public static function transposeNotes(notes:Array<INote>, offset:Int, instrumentContext:IInstrumentContext):Array<INote> {
    return [for (n in notes) instrumentContext.makeNote(
      n.getMidiNoteValue() + offset,
      n.getStartTime(),
      n.getLength()
    )];
  }

  public static function makePianoRollSVG(notes:Array<INote>, svgWidth:Int, svgHeight:Int):String {
    var noteHeight = svgHeight/100;
    
    // Find time range to scale properly
    var maxTime = 0.0;
    for (note in notes) {
        maxTime = Math.max(maxTime, note.getStartTime() + note.getLength());
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
        var x = note.getStartTime() * timeScale;
        var y = svgHeight - ((note.getMidiNoteValue() - pitchOffset) * noteHeight) - noteHeight;
        var width = note.getLength() * timeScale;
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
