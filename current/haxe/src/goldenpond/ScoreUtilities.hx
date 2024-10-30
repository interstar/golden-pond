@:expose
class Note {
    public var note:Int;
    public var start_time:Float;
    public var length:Float;

    public function new(note:Int, start_time:Float, length:Float) {
        this.note = note;
        this.start_time = start_time;
        this.length = length;
    }

    public function toString():String {
        return 'Note[note: ' + note + ', start_time: ' + start_time + ', length: ' + length + ']';
    }

	@:expose
    public function toStruct() {
        return {note: this.note, start_time: this.start_time, length: this.length};
    }
    
    public function equals(other:Note):Bool {
        return this.note == other.note && this.start_time == other.start_time && this.length == other.length;
    }
}

@:expose
class ScoreUtilities {
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
