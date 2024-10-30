package;

@:expose
enum Modifier {
    MODAL_INTERCHANGE;
    SEVENTH;
    NINTH;
    SECONDARY;
    VOICE_LEADING;
}

@:expose
class Mode {
    public static var major_intervals = [2, 2, 1, 2, 2, 2, 1];
    public static var minor_intervals = [2, 1, 2, 2, 1, 2, 2];

    // Singleton instances
    private static var _major_mode:Mode;
    private static var _minor_mode:Mode;


    public var intervals:Array<Int>;

    public function new(intervals:Array<Int>) {
        this.intervals = intervals;
    }

    public static function getMajorMode():Mode {
        if (_major_mode == null) {
            _major_mode = new Mode(major_intervals);
        }
        return _major_mode;
    }

    public static function getMinorMode():Mode {
        if (_minor_mode == null) {
            _minor_mode = new Mode(minor_intervals);
        }
        return _minor_mode;
    }

    public static function constructNthMajorMode(offset:Int):Mode {
        var new_intervals = major_intervals.slice(offset - 1).concat(major_intervals.slice(0, offset - 1));
        return new Mode(new_intervals);
    }

    public static function ionian():Mode {
        return constructNthMajorMode(1);
    }

    public static function dorian():Mode {
        return constructNthMajorMode(2);
    }

    public static function phrygian():Mode {
        return constructNthMajorMode(3);
    }

    public static function lydian():Mode {
        return constructNthMajorMode(4);
    }

    public static function mixolydian():Mode {
        return constructNthMajorMode(5);
    }

    public static function aeolian():Mode {
        return constructNthMajorMode(6);
    }

    public static function locrian():Mode {
        return constructNthMajorMode(7);
    }

    public function nth_from(root:Int, n:Int):Int {
        if (n == 1) return root;
        var note = root;
        for (i in 0...n - 1) {
            note += intervals[i % intervals.length];
        }
        return note;
    }

    public function make_chord_from_pattern(root:Int, n:Int, pat:Array<Int>):Array<Int> {
        return pat.map(function(x:Int):Int {
            return nth_from(root, n + x - 1);
        });
    }

    public function make_triad(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5]);
    }

    public function make_seventh(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5, 7]);
    }

    public function make_ninth(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5, 7, 9]);
    }
}

// Singleton instances
@:expose
var MAJOR = Mode.getMajorMode();
@:expose
var MINOR = Mode.getMinorMode();

