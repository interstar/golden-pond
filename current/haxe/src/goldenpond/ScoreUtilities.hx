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

/** Horizontal grid lines for piano-roll SVG background. */
@:expose
enum PianoRollGridStyle {
  /** One line per vertical pitch row (legacy: pitchRowCount rows). */
  FullHorizontal;
  /** When {@link PianoRollLayout.fitPitchRange} is true: line at each MIDI C; if false, same as {@link FullHorizontal}. */
  OctavesOnly;
  /** No grid lines. */
  None;
}

/**
 * Visual options for {@link ScoreUtilities.makePianoRollSVGAdvanced}.
 * {@link PianoRollLayout.defaultLegacy} matches historic {@link ScoreUtilities.makePianoRollSVG} output.
 */
@:expose
class PianoRollLayout {
  /** If true, vertical axis fits min/max MIDI in {@code notes} (plus padding). */
  public var fitPitchRange:Bool;
  /** When not fitting pitch: {@code noteHeight = svgHeight / pitchRowCount} (legacy: 100). */
  public var pitchRowCount:Int;
  /** When not fitting pitch: MIDI mapped to bottom row (legacy: 20). */
  public var pitchReference:Int;
  /** Semitones to extend below min and above max when fitting pitch. */
  public var pitchPadSemitones:Int;
  /** Minimum inclusive semitone span when fitting (expands narrow ranges). */
  public var minPitchSpanSemitones:Int;
  public var gridStyle:PianoRollGridStyle;
  public var gridStroke:String;
  public var noteFill:String;
  public var noteStroke:Null<String>;
  public var minNoteWidthPx:Float;
  public var minNoteHeightPx:Float;

  public function new() {
    fitPitchRange = false;
    pitchRowCount = 100;
    pitchReference = 20;
    pitchPadSemitones = 3;
    minPitchSpanSemitones = 8;
    gridStyle = FullHorizontal;
    gridStroke = "#ddd";
    noteFill = "black";
    noteStroke = null;
    minNoteWidthPx = 0;
    minNoteHeightPx = 0;
  }

  public static function defaultLegacy():PianoRollLayout {
    return new PianoRollLayout();
  }
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
    
  public function valueEquals(other:Dynamic):Bool {
    if (!Std.isOfType(other, Note)) return false;
    var otherNote:Note = cast(other, Note);
    return this.chan == otherNote.chan &&
           this.note == otherNote.note && 
           this.velocity == otherNote.velocity && 
           this.startTime == otherNote.startTime && 
           this.length == otherNote.length;
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

  /** Same as {@link #makePianoRollSVGAdvanced} with {@link PianoRollLayout#defaultLegacy}. */
  public static function makePianoRollSVG(notes:Array<INote>, svgWidth:Int, svgHeight:Int):String {
    return makePianoRollSVGAdvanced(notes, svgWidth, svgHeight, PianoRollLayout.defaultLegacy());
  }

  static function appendNoteRect(svg:StringBuf, x:Float, y:Float, width:Float, height:Float, layout:PianoRollLayout):Void {
    if (Math.isNaN(x) || Math.isNaN(y) || Math.isNaN(width) || Math.isNaN(height)) {
      return;
    }
    var w = Math.max(layout.minNoteWidthPx, width);
    var h = Math.max(layout.minNoteHeightPx, height);
    svg.add('<rect x="' + x + '" y="' + y + '" width="' + w + '" height="' + h + '" fill="' + layout.noteFill + '"');
    if (layout.noteStroke != null) {
      svg.add(' stroke="' + layout.noteStroke + '"');
    }
    svg.add(' />\n');
  }

  public static function makePianoRollSVGAdvanced(notes:Array<INote>, svgWidth:Int, svgHeight:Int, layout:PianoRollLayout):String {
    var maxTime = 0.0;
    for (note in notes) {
      maxTime = Math.max(maxTime, note.getStartTime() + note.getLength());
    }
    var timeScale = maxTime > 0 ? svgWidth / maxTime : 0.1;

    var svg = new StringBuf();
    svg.add('<svg width="' + svgWidth + '" height="' + svgHeight + '" viewBox="0 0 ' + svgWidth + ' ' + svgHeight
      + '" xmlns="http://www.w3.org/2000/svg">\n');

    if (!layout.fitPitchRange) {
      var noteHeight = svgHeight / layout.pitchRowCount;
      if (layout.gridStyle == FullHorizontal || layout.gridStyle == OctavesOnly) {
        for (i in 0...Std.int(svgHeight / noteHeight)) {
          var yy = i * noteHeight;
          svg.add('<line x1="0" y1="' + yy + '" x2="' + svgWidth + '" y2="' + yy + '" stroke="' + layout.gridStroke + '" />\n');
        }
      }

      for (note in notes) {
        var x = note.getStartTime() * timeScale;
        var y = svgHeight - ((note.getMidiNoteValue() - layout.pitchReference) * noteHeight) - noteHeight;
        var width = note.getLength() * timeScale;
        var height = noteHeight;
        if (Math.isNaN(x) || Math.isNaN(y) || Math.isNaN(width) || Math.isNaN(height)) {
          trace('Invalid note values: note=${note}, x=${x}, y=${y}, width=${width}, height=${height}');
          continue;
        }
        appendNoteRect(svg, x, y, width, height, layout);
      }
    } else {
      var minP = 127;
      var maxP = 0;
      if (notes.length > 0) {
        for (note in notes) {
          var p = note.getMidiNoteValue();
          if (p < minP)
            minP = p;
          if (p > maxP)
            maxP = p;
        }
      } else {
        minP = 60;
        maxP = 71;
      }

      minP = Std.int(Math.max(0, minP - layout.pitchPadSemitones));
      maxP = Std.int(Math.min(127, maxP + layout.pitchPadSemitones));
      var pitchSpan = maxP - minP + 1;
      if (pitchSpan < layout.minPitchSpanSemitones) {
        var mid = Std.int(Math.floor((minP + maxP) / 2));
        minP = Std.int(Math.max(0, mid - Math.floor(layout.minPitchSpanSemitones / 2)));
        maxP = Std.int(Math.min(127, minP + layout.minPitchSpanSemitones - 1));
        pitchSpan = maxP - minP + 1;
      }

      var pxPerSemi = svgHeight / pitchSpan;

      switch (layout.gridStyle) {
        case FullHorizontal:
          for (semi in minP...(maxP + 1)) {
            var yy = svgHeight - (semi - minP) * pxPerSemi;
            svg.add('<line x1="0" y1="' + yy + '" x2="' + svgWidth + '" y2="' + yy + '" stroke="' + layout.gridStroke + '" />\n');
          }
        case OctavesOnly:
          var firstC = Math.floor(minP / 12) * 12;
          var m = firstC;
          while (m <= maxP + 12) {
            if (m >= minP && m <= maxP + 1) {
              var yy = svgHeight - (m - minP) * pxPerSemi;
              if (yy >= -1 && yy <= svgHeight + 1) {
                svg.add('<line x1="0" y1="' + yy + '" x2="' + svgWidth + '" y2="' + yy + '" stroke="' + layout.gridStroke + '" />\n');
              }
            }
            m += 12;
          }
        case None:
      }

      for (note in notes) {
        var x = note.getStartTime() * timeScale;
        var yTop = svgHeight - (note.getMidiNoteValue() - minP + 1) * pxPerSemi;
        var width = Math.max(0.0, note.getLength() * timeScale);
        var height = Math.max(0.0, pxPerSemi - 1);
        if (Math.isNaN(x) || Math.isNaN(yTop) || Math.isNaN(width) || Math.isNaN(height)) {
          trace('Invalid note values: note=${note}, x=${x}, y=${yTop}, width=${width}, height=${height}');
          continue;
        }
        appendNoteRect(svg, x, yTop, width, height, layout);
      }
    }

    svg.add('</svg>');
    return svg.toString();
  }
}
