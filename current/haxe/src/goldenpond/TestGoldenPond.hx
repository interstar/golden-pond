import Mode;
import ChordThing;
import ChordParser;
import TimedSequence;
import ScoreUtilities;

class TestGoldenPond {
    static var ERRORS = 0;
    static var TEST_COUNT = 0;  // Add counter for total tests

    static function testit(id:String, val:Dynamic, target:Dynamic, msg:String) {
        TEST_COUNT++;  // Increment test counter
        if (!deepEquals(val, target)) {
            trace('ERROR IN ${id} : ${msg}');
            trace('Wanted:*${Std.string(target)}**');
            trace('Got:*${Std.string(val)}**');
            compareDetails(val, target);
            ERRORS++;
        } else {
            trace('${id} OK');
        }
    }

    static function compareChordThings(a:ChordThing, b:ChordThing):Bool {
    	trace("In compareChordThings \n" + a + "\n" + b);
        return a.key == b.key &&
            a.mode == b.mode &&
            a.degree == b.degree &&
            a.length == b.length &&
            a.inversion == b.inversion &&
            a.secondary_degree == b.secondary_degree &&
            compareModifiers(a.modifiers, b.modifiers);
    }

    static function compareModifiers(a:Array<Modifier>, b:Array<Modifier>):Bool {
        if (a.length != b.length) return false;
        for (i in 0...a.length) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

    static function floatEqual(a:Float, b:Float, epsilon:Float = 0.0001):Bool {
        return Math.abs(a - b) < epsilon;
    }

    static function deepEquals(a:Dynamic, b:Dynamic):Bool {
        if (a == null || b == null) return a == b;

        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            if (a.length != b.length) return false;
            for (i in 0...a.length) {
                if (!deepEquals(a[i], b[i])) return false;
            }
            return true;
        }

        // Handle Note objects first
        if (Std.isOfType(a, Note) && Std.isOfType(b, Note)) {
            return a.equals(b);
        }
        
        // Handle ChordThing objects
        if (Std.isOfType(a, ChordThing) && Std.isOfType(b, ChordThing)) {
            return a.equals(b);
        }

        // Handle objects with time field specially
        if (Reflect.hasField(a, "time") && Reflect.hasField(b, "time")) {
            return floatEqual(a.time, b.time) && Reflect.field(a, "type") == Reflect.field(b, "type");
        }

        if (Std.isOfType(a, Float) && Std.isOfType(b, Float)) {
            return floatEqual(a, b);
        }

        // Fallback to standard equality check
        return a == b;
    }

    static function compareDetails(a:Dynamic, b:Dynamic):Void {
		trace("In compareDetails SHOULDN'T BE HERE");
        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            if (a.length != b.length) {
                trace("Length mismatch: " + a.length + " vs " + b.length);
                return;
            }
            for (i in 0...a.length) {
                if (!deepEquals(a[i], b[i])) {
                    trace("Difference at index " + i + ":");
                    trace("Wanted: " + Std.string(a[i]));
                    trace("Got: " + Std.string(b[i]));
                }
            }
        } else if (Std.isOfType(a, String) && Std.isOfType(b, String)) {
            if (a != b) {
                trace("String mismatch:");
                trace("Wanted: " + a);
                trace("Got: " + b);
            }
        } else {
            trace("Mismatch:");
            trace("Wanted: " + Std.string(a));
            trace("Got: " + Std.string(b));
        }
    }

    static function testMode() {
        var MAJOR = Mode.getMajorMode();
        var major_mode_2 = Mode.getMajorMode();

        trace("Testing Modes (ie Scale object)");
        testit("modes1", MAJOR == major_mode_2, true, "Major Mode not singleton");

        testit("modes2", MAJOR.nth_from(60, 1), 60, "Modes 2");
        testit("modes3", MAJOR.nth_from(60, 2), 62, "Modes 3");
        testit("modes4", MAJOR.nth_from(60, 3), 64, "Modes 4");

        var MINOR = Mode.getMinorMode();
        testit("modes5", MINOR.nth_from(60, 3), 63, "Modes 5");
        testit("modes6", MAJOR.nth_from(60, 8), 72, "Modes 6");
        testit("modes7", MINOR.nth_from(60, 9), 74, "Modes 7");

        testit("modes8", MAJOR.make_triad(60, 1), [60, 64, MAJOR.nth_from(60, 5)], "Modes 8");
        testit("modes9", MINOR.make_triad(60, 1), [60, 63, MINOR.nth_from(60, 5)], "Modes 9");
        testit("modes10", MAJOR.make_seventh(70, 1), [70, 74, 77, 81], "Modes 10");
        testit("modes11", MAJOR.make_ninth(70, 1), [70, 74, 77, 81, 84], "Modes 11");
        testit("modes12", MAJOR.make_ninth(70, 4), [75, 79, 82, 86, 89], "Modes 12");
        testit("modes13", MAJOR.make_chord_from_pattern(50, 2, [1, 3, 5]), MAJOR.make_triad(50, 2), "Modes 13");

        testit("modes14", Mode.constructNthMajorMode(1).intervals, [2, 2, 1, 2, 2, 2, 1], "Modes 14 : Other modes ionian");
        testit("modes15", Mode.constructNthMajorMode(2).intervals, [2, 1, 2, 2, 2, 1, 2], "Modes 15 : Dorian");
        testit("modes16", Mode.constructNthMajorMode(3).intervals, [1, 2, 2, 2, 1, 2, 2], "Modes 16 : Phrygian");
        testit("modes17", Mode.constructNthMajorMode(3).intervals, Mode.phrygian().intervals, "Modes 17 : Phrygian as name");
        testit("modes18", Mode.lydian().intervals, [2, 2, 2, 1, 2, 2, 1], "Modes 18 : Lydian");
        testit("modes19", Mode.mixolydian().intervals, [2, 2, 1, 2, 2, 1, 2], "Modes 19 : Mixolydian");
        testit("modes20", Mode.aeolian().intervals, [2, 1, 2, 2, 1, 2, 2], "Modes 20 : Aeolian");
        testit("modes21", Mode.locrian().intervals, [1, 2, 2, 1, 2, 2, 2], "Modes 21 : Locrian");
    }	

    static function testChordThing() {
        trace("Testing ChordThing. Now MODE is the actual Scale itself.");
        testit("ChordThing ninths override sevenths",
            Std.string(new ChordThing(60, Mode.getMajorMode(), 3).seventh().ninth()),
            "ChordThing(60,MAJOR,3,0,1) + [NINTH]",
            "ChordThings ninths override sevenths failed.");

        testit("ChordThing has extensions with ninth",
            new ChordThing(60, Mode.getMajorMode(), 3).ninth().has_extensions(),
            true,
            "ChordThing expected to have extensions with ninth.");

        testit("ChordThing modal interchange",
            Std.string(new ChordThing(60, Mode.getMajorMode(), 3).modal_interchange()),
            "ChordThing(60,MAJOR,3,0,1) + [MODAL_INTERCHANGE]",
            "ChordThing modal interchange failed.");

        testit("ChordThing has modal interchange",
            new ChordThing(60, Mode.getMajorMode(), 3).modal_interchange().has_modal_interchange(),
            true,
            "ChordThing expected to have modal interchange.");

        testit("ChordThing swap mode to MINOR",
            new ChordThing(60, Mode.getMajorMode(), 3).swap_mode().mode,
            Mode.getMinorMode(),
            "ChordThing swap mode to MINOR failed.");

        testit("ChordThing swap mode back to MAJOR",
            new ChordThing(60, Mode.getMinorMode(), 3).swap_mode().mode,
            Mode.getMajorMode(),
            "ChordThing swap mode back to MAJOR failed.");

        testit("ChordThing", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).seventh()), "ChordThing(60,MAJOR,3,0,2) + [SEVENTH]", "ChordThings");
        var ct1 = new ChordThing(60, Mode.getMajorMode(), 3, 2);
        testit("ChordThing no extensions", ct1.has_extensions(), false, "ChordThings");
        ct1 = new ChordThing(60, Mode.getMajorMode(), 3, 2).ninth();
        testit("ChordThing has extensions", ct1.has_extensions(), true, "ChordThings");

        testit("ChordThing ninths override sevenths", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).seventh().ninth()), "ChordThing(60,MAJOR,3,0,2) + [NINTH]", "ChordThings");
        testit("ChordThing sevenths override ninths", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).ninth().seventh()), "ChordThing(60,MAJOR,3,0,2) + [SEVENTH]", "ChordThings");
        testit("ChordThing modal interchange", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).modal_interchange()), "ChordThing(60,MAJOR,3,0,2) + [MODAL_INTERCHANGE]", "ChordThings");
        testit("ChordThing has modal interchange", new ChordThing(60, Mode.getMajorMode(), 3, 2).modal_interchange().has_modal_interchange(), true, "ChordThings");
        testit("ChordThing swap mode", new ChordThing(60, Mode.getMajorMode(), 3, 2).swap_mode().mode, Mode.getMinorMode(), "ChordThings");
        testit("ChordThing swap mode", new ChordThing(60, Mode.getMinorMode(), 3, 2).swap_mode().mode, Mode.getMajorMode(), "ChordThings");

        testit("ChordThing get mode", new ChordThing(60, Mode.getMinorMode(), 3, 2).get_mode(), Mode.getMinorMode(), "ChordThing.getMode");
        testit("ChordThing get mode2", new ChordThing(60, Mode.getMinorMode(), 3, 2).modal_interchange().get_mode(), Mode.getMajorMode(), "ChordThing.getMode");
        testit("ChordThing get mode3", new ChordThing(24, Mode.getMajorMode(), 3, 2).modal_interchange().get_mode(), Mode.getMinorMode(), "ChordThing.getMode");
    }
	
    static function testChordFactory() {
        trace("Testing ChordFactory");

        var MAJOR = Mode.getMajorMode();
        var MINOR = Mode.getMinorMode();

        // Test Major Triad
        testit("Major Triad C",
            ChordFactory.generateChordNotes(new ChordThing(60, MAJOR, 1)),
            [60, 64, 67],
            "Major triad C not correctly generated.");

        // Test Minor Triad
        testit("Minor Triad A",
            ChordFactory.generateChordNotes(new ChordThing(57, MINOR, 1)),
            [57, 60, 64],
            "Minor triad A not correctly generated.");

        // Test Major Seventh Chord
        testit("Major Seventh C",
            ChordFactory.generateChordNotes(new ChordThing(60, MAJOR, 1).seventh()),
            [60, 64, 67, 71],
            "Major seventh C not correctly generated.");

        // Test Minor Seventh Chord
        testit("Minor Seventh A",
            ChordFactory.generateChordNotes(new ChordThing(57, MINOR, 1).seventh()),
            [57, 60, 64, 67],
            "Minor seventh A not correctly generated.");

        testit("Minor Ninth A",
            ChordFactory.generateChordNotes(new ChordThing(57, MINOR, 1).ninth()),
            [57, 60, 64, 67, 71],
            "Minor ninth A not correctly generated.");

        testit("Secondary Dominant of iii chord in C",
            ChordFactory.generateChordNotes(new ChordThing(60, MAJOR, 3).set_as_secondary(5).seventh()),
            [71, 75, 78, 81],
            "Secondary dominant of iii in C not correctly generated.");
        

        trace("Testing chord progressions");

        testit("A chord progression",
            ChordFactory.chordProgression([new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 4), new ChordThing(60, MAJOR, 6), new ChordThing(60, MAJOR, 5)]),
            [[60, 64, 67], [65, 69, 72], [69, 72, 76], [67, 71, 74]],
            "Chord progression not generated by ChordFactory");        
    }

    static function testParser() {
        trace("Testing Parser");

        var cp = new ChordParser(60, MAJOR);

        testit("Simple chords", cp.parse("1,4,6,5"),
            [new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 4), new ChordThing(60, MAJOR, 6), new ChordThing(60, MAJOR, 5)],
            "ChordParsing simple chords");

        testit("Extended chords", cp.parse("71,-94,6ii,-5"),
            [new ChordThing(60, MAJOR, 1).seventh(), new ChordThing(60, MAJOR, 4).ninth().modal_interchange(), new ChordThing(60, MAJOR, 6).set_inversion(2), new ChordThing(60, MAJOR, 5).modal_interchange()],
            "ChordParsing extended chords");

        testit("Major Triads", new ChordProgression(60, MAJOR, "1|4|5|6").toNotes(),
            [[60, 64, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
            "Basic major triads");

        testit("Minor Triads", new ChordProgression(60, MINOR, "1|4,5| 6").toNotes(),
            [[60, 63, 67], [65, 68, 72], [67, 70, 74], [68, 72, 75]],
            "Basic minor triads");

        testit("Major Triads with modal interchange", new ChordProgression(60, MAJOR, "-1|4|5|6").toNotes(),
            [[60, 63, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
            "Basic major triads");

        testit("Minor Sevenths", new ChordProgression(60, MINOR, "72,75,71").toNotes(),
            [[62, 65, 68, 72], [67, 70, 74, 77], [60, 63, 67, 70]], "Minor 7ths");

        testit("Chord Inversions",
            new ChordProgression(60, MAJOR, "1|4i").toNotes(),
            [[60, 64, 67], [69, 72, 77]],
            "Chord inversions");

        testit("Chord Inversions with extensions",
            new ChordProgression(60, MAJOR, "4,74,74i,74ii,74iii").toNotes(),
            [[65, 69, 72], [65, 69, 72, 76], [69, 72, 76, 77], [72, 76, 77, 81], [76, 77, 81, 84]],
            "Chord inversions 2");

        testit("Modulate to new key", new ChordProgression(60, MAJOR, "1|4|>2|1|4|<1|1|4").toNotes(),
            [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74], [61, 65, 68], [66, 70, 73]],
            "Modulating basic triads by 2");

        testit("Modulate to new mode", new ChordProgression(60, MAJOR, "1|4|5|7|!|1|4|5|7").toNotes(),
            new ChordProgression(60, MAJOR, "1|4|5|7|-1|-4|-5|-7").toNotes(),
            "Modulating mode");

        testit("Secondary chords",
            new ChordProgression(60, MAJOR, "(5/4),4").toChordThings(),
            [new ChordThing(60, MAJOR, 4).set_as_secondary(5),
            new ChordThing(60, MAJOR, 4)],
            "Testing secondary chords");

        testit("Making secondary chords",
            new ChordProgression(60, MAJOR, "(5/2),2,5,1").toNotes(),
            [[69, 73, 76], [62, 65, 69], [67, 71, 74], [60, 64, 67]],
            "Making a secondary (5/2)");

        testit("Making secondary chords with modifiers",
            new ChordProgression(60, MAJOR, "7(5/2),72,75,71").toNotes(),
            [[69, 73, 76, 79], [62, 65, 69, 72], [67, 71, 74, 77], [60, 64, 67, 71]],
            "Making a secondary 7(5/2)");

        trace("Testing Voice Leading");
        testit("VOICE_LEADING Parser Test",
            cp.parse("1&6"),
            [new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 6).set_voice_leading()],
            "Parsing & separator for voice leading");

	trace("Testing Stutter");
	var prog1 = new ChordProgression(60,MAJOR,"1,4,6,5");
	prog1.setStutter(2);
	var prog2 = new ChordProgression(60,MAJOR,"1,4,1,4");
	testit("Stutter",
	       prog1.toNotes(),
	       prog2.toNotes(),
	       "stuttering");
	}
	
    static function testMenuHelper() {
	  trace("Testing Menu Helper");
	  testit("Division names",
		 MenuHelper.getDivisionNames(),
		 ["1/16", "1/12", "1/8", "1/6", "1/4", "1/3", "1/2", "1"],
		 "Division names");
	  testit("Division Values",
		 MenuHelper.getDivisionValues(),
		 [SIXTEENTH,TWELFTH,EIGHTH,SIXTH,QUARTER,THIRD,HALF,WHOLE],
		 "Division Values");
	  
	  testit("Division Opt 1", MenuHelper.getDivisionFor(0), SIXTEENTH,"division 1");
	  testit("Division Opt 5", MenuHelper.getDivisionFor(4), QUARTER, "division 5");
	  testit("DivisionValue to numeric",
		 MenuHelper.divisionValue2Numeric(EIGHTH),
		 1/8,
		 "division value EIGHTH to numeric 1/8");
	}

    static function testNotes() {
	  trace("Testing Notes");
	  var n = new Note(0,68,100,4,0.5);
	  testit("Note transposition",
		 n.transpose(12),
		 new Note(0,80,100,4,0.5),
		 "note transposition");

      testit("Note to string",
      	n.toString(),
      	'Note[chan: 0, note: 68, vel: 100, startTime: 4, length: 0.5]',
      	"note to string"
      );
	  trace("Transposing collections of Notes");
	  var ns = [new Note(0,68,100,4,0.5), new Note(0,64,50,8,0.5)];
	  testit("Note collection transposition",
		 ScoreUtilities.transposeNotes(ns,-4),
		 [new Note(0,64,100,4,0.5), new Note(0,60,50,8,0.5)],
		 "note collection transposition");
	
	  	 

	}
  
    static function testTimeManipulator() {
		trace("Testing Line Generators\n");

		// Configure TimeManipulator like test_goldenpond.py
		var ti = new TimeManipulator();
		ti.setPPQ(960)
		  .setChordDuration(8)
		  .setBPM(120);

		// Create chord progression
		var seq = new ChordProgression(50, MAJOR, "76,72,!,75,71");

		// Get rhythmic density values
		var density1 = MenuHelper.rhythmicDensityToNumeric(ONE);
		var density2 = MenuHelper.rhythmicDensityToNumeric(TWO);
		var density4 = MenuHelper.rhythmicDensityToNumeric(FOUR);

		// Test ChordLine
		var chord_line = new ChordLine(ti, seq, 5, 8, 0.8, density1).generateNotes(0, 0, 64);
		testit("ChordLine first five chords",
			chord_line.slice(0, 20),
			[
				// First chord
				new Note(0, 59, 64, 0, 768),
				new Note(0, 62, 64, 0, 768),
				new Note(0, 66, 64, 0, 768),
				new Note(0, 69, 64, 0, 768),
				// Second chord
				new Note(0, 59, 64, 1920, 768),
				new Note(0, 62, 64, 1920, 768),
				new Note(0, 66, 64, 1920, 768),
				new Note(0, 69, 64, 1920, 768),
				// Third chord
				new Note(0, 59, 64, 2880, 768),
				new Note(0, 62, 64, 2880, 768),
				new Note(0, 66, 64, 2880, 768),
				new Note(0, 69, 64, 2880, 768),
				// Fourth chord
				new Note(0, 59, 64, 4800, 768),
				new Note(0, 62, 64, 4800, 768),
				new Note(0, 66, 64, 4800, 768),
				new Note(0, 69, 64, 4800, 768),
				// Fifth chord
				new Note(0, 59, 64, 5760, 768),
				new Note(0, 62, 64, 5760, 768),
				new Note(0, 66, 64, 5760, 768),
				new Note(0, 69, 64, 5760, 768)
			],
			"First five chords should have correct notes and timing"
		);

		// Test BassLine
		var bass_line = new BassLine(ti, seq, 4, 8, 0.8, density2).generateNotes(0, 1, 100);
		testit("BassLine first twenty notes",
			bass_line.slice(0, 20),
			[
				new Note(1, 47, 100, 0, 384),
				new Note(1, 47, 100, 960, 384),
				new Note(1, 47, 100, 1920, 384),
				new Note(1, 47, 100, 2880, 384),
				new Note(1, 47, 100, 3840, 384),
				new Note(1, 47, 100, 4800, 384),
				new Note(1, 47, 100, 5760, 384),
				new Note(1, 47, 100, 6720, 384),
				new Note(1, 40, 100, 7680, 384),
				new Note(1, 40, 100, 8640, 384),
				new Note(1, 40, 100, 9600, 384),
				new Note(1, 40, 100, 10560, 384),
				new Note(1, 40, 100, 11520, 384),
				new Note(1, 40, 100, 12480, 384),
				new Note(1, 40, 100, 13440, 384),
				new Note(1, 40, 100, 14400, 384),
				new Note(1, 45, 100, 15360, 384),
				new Note(1, 45, 100, 16320, 384),
				new Note(1, 45, 100, 17280, 384),
				new Note(1, 45, 100, 18240, 384)
			],
			"Bass line should play root notes with correct rhythm"
		);

		// Test TopLine
		var top_line = new TopLine(ti, seq, 3, 8, 0.6, density2).generateNotes(0, 2, 100);
		testit("TopLine first twenty notes",
			top_line.slice(0, 20),
			[
				new Note(2, 81, 100, 0, 288),
				new Note(2, 81, 100, 1440, 288),
				new Note(2, 81, 100, 2400, 288),
				new Note(2, 81, 100, 3840, 288),
				new Note(2, 81, 100, 5280, 288),
				new Note(2, 81, 100, 6240, 288),
				new Note(2, 74, 100, 7680, 288),
				new Note(2, 74, 100, 9120, 288),
				new Note(2, 74, 100, 10080, 288),
				new Note(2, 74, 100, 11520, 288),
				new Note(2, 74, 100, 12960, 288),
				new Note(2, 74, 100, 13920, 288),
				new Note(2, 79, 100, 15360, 288),
				new Note(2, 79, 100, 16800, 288),
				new Note(2, 79, 100, 17760, 288),
				new Note(2, 79, 100, 19200, 288),
				new Note(2, 79, 100, 20640, 288),
				new Note(2, 79, 100, 21600, 288),
				new Note(2, 72, 100, 23040, 288),
				new Note(2, 72, 100, 24480, 288)
			],
			"Top line should play highest notes with correct rhythm"
		);

		// Test ArpLine
		var arp_line = new ArpLine(ti, seq, 6, 12, 0.5, density2).generateNotes(0, 3, 100);
		testit("ArpLine first twenty notes",
			arp_line.slice(0, 20),
			[
				new Note(3, 59, 100, 0, 160),
				new Note(3, 62, 100, 640, 160),
				new Note(3, 66, 100, 1280, 160),
				new Note(3, 69, 100, 1920, 160),
				new Note(3, 59, 100, 2560, 160),
				new Note(3, 62, 100, 3200, 160),
				new Note(3, 66, 100, 3840, 160),
				new Note(3, 69, 100, 4480, 160),
				new Note(3, 59, 100, 5120, 160),
				new Note(3, 62, 100, 5760, 160),
				new Note(3, 66, 100, 6400, 160),
				new Note(3, 69, 100, 7040, 160),
				new Note(3, 52, 100, 7680, 160),
				new Note(3, 55, 100, 8320, 160),
				new Note(3, 59, 100, 8960, 160),
				new Note(3, 62, 100, 9600, 160),
				new Note(3, 52, 100, 10240, 160),
				new Note(3, 55, 100, 10880, 160),
				new Note(3, 59, 100, 11520, 160),
				new Note(3, 62, 100, 12160, 160)
			],
			"Arp line should cycle through chord tones with correct rhythm"
		);

		// Test RandomLine
		var rand_line = new RandomLine(ti, seq, 5, 8, 0.5, density4).generateNotes(0, 4, 100);

		// Test timing pattern (5 hits every 8 steps)
		var timings = new Array<Float>();
		for (i in 0...20) {
			timings.push(rand_line[i].startTime);
		}

		testit("RandomLine timing pattern",
			timings.slice(0, 5),  // First pattern of 5 hits
			[0, 480, 720, 1200, 1440],  // Changed from floats to integers
			"Random line should follow 5/8 Euclidean rhythm"
		);

		// Test note properties
		for (note in rand_line.slice(0, 20)) {
			// All notes should be from current chord
			var chordIndex = Math.floor(note.startTime / (ti.chordTicks));
			var currentChord = seq.toNotes()[chordIndex];
			testit("RandomLine note in chord",
				currentChord.contains(note.note),
				true,
				'Note ${note.note} should be in chord at time ${note.startTime}'
			);

			// Note length should be consistent
			testit("RandomLine note length",
				note.length,
				120.0,  // 0.5 * step size for density4
				"Note length should be consistent"
			);

			// Channel and velocity should be consistent
			testit("RandomLine note properties",
				[note.chan, note.velocity],
				[4, 100],
				"Channel and velocity should be consistent"
			);
		}

		// Test ChordLine with transposition
		var transposed_line = new ChordLine(ti, seq, 5, 8, 0.8, density1);
		transposed_line.transpose(12);  // Transpose up one octave
		var transposed_notes = transposed_line.generateNotes(0, 0, 64);

		testit("ChordLine transposition",
			transposed_notes.slice(0, 4),  // Test first chord
			[
				new Note(0, 71, 64, 0, 768),  // Original 59 + 12
				new Note(0, 74, 64, 0, 768),  // Original 62 + 12
				new Note(0, 78, 64, 0, 768),  // Original 66 + 12
				new Note(0, 81, 64, 0, 768)   // Original 69 + 12
			],
			"Transposed line should be one octave higher"
		);
	}

    static function runScoreUtils() {   
        var ti = new TimeManipulator().setPPQ(960);
		var seq = new ChordProgression(60, MAJOR, "72,75,71");
		trace(seq);
		var density = MenuHelper.rhythmicDensityToNumeric(FOUR);  // 1/4 - divide each chord into 4 steps
		var svg = ScoreUtilities.makePianoRollSVG(new ChordLine(ti, seq, 1, 1, 0.8, density).generateNotes(0,0,64),800,600);		 
		trace(svg);
    }
	
    static function main() {
        trace("Starting tests...");
        
        testNotes();  // Add this back
        
        var testGroups = [
            { name: "Mode Tests", fn: testMode },
            { name: "ChordThing Tests", fn: testChordThing },
            { name: "ChordFactory Tests", fn: testChordFactory },
            { name: "Parser Tests", fn: testParser },
            { name: "MenuHelper Tests", fn: testMenuHelper },
            { name: "TimeManipulator Tests", fn: testTimeManipulator },
            { name: "RhythmGenerator Tests", fn: testRhythmGenerator },
            { name: "RhythmGenerator K1 Tests", fn: testRhythmGeneratorK1 },
            { name: "DeltaEvent Tests", fn: testDeltaEvents },
            { name: "Time Event Generation Tests", fn: testTimeEventGeneration },
            { name: "Chord Timings Tests", fn: testChordTimings },
            { name: "Time Events for k=1 Tests", fn: testTimeEventsForK1 }
        ];
        
        for (group in testGroups) {
            var startCount = TEST_COUNT;
            trace('\n=== Running ${group.name} ===');
            group.fn();
            trace('${group.name}: ${TEST_COUNT - startCount} tests run\n');
        }
        
        trace('-------------------------');
        trace('TOTAL TESTS RUN: ${TEST_COUNT}');
        trace('TOTAL ERRORS: ${ERRORS}');
        trace('-------------------------');
    }

    static function testRhythmGenerator() {
        trace("Testing RhythmGenerator");
        
        // Test 3 in 8 pattern
        var rGen = new RhythmGenerator(3, 8);
        var pattern = [];
        var hitCount = 0;
        for (i in 0...8) {
            var beat = rGen.next();
            pattern.push(beat);
            if (beat == 1) hitCount++;
        }
        
        testit("RhythmGenerator 3 in 8 hit count", 
               hitCount, 
               3, 
               "RhythmGenerator should produce exactly 3 hits in 8 steps");
               
        // Test pattern repeats correctly
        var secondPattern = [];
        hitCount = 0;
        for (i in 0...8) {
            var beat = rGen.next();
            secondPattern.push(beat);
            if (beat == 1) hitCount++;
        }
        
        testit("RhythmGenerator pattern repeat", 
               pattern,
               secondPattern, 
               "RhythmGenerator should repeat the same pattern");
               
        testit("RhythmGenerator second pattern hit count",
               hitCount,
               3,
               "RhythmGenerator should maintain 3 hits on repeat");
               
        // Test other common patterns
        function testPattern(k:Int, n:Int) {
            var rg = new RhythmGenerator(k, n);
            var hits = 0;
            for (i in 0...n) {
                if (rg.next() == 1) hits++;
            }
            return hits;
        }
        
        testit("RhythmGenerator 4 in 8", 
               testPattern(4, 8),
               4,
               "4 in 8 pattern should have 4 hits");
               
        testit("RhythmGenerator 2 in 8",
               testPattern(2, 8),
               2,
               "2 in 8 pattern should have 2 hits");
    }

    static function testDeltaEvents() {
        trace("\n=== Testing Delta Events ===");
        var startCount = TEST_COUNT;
        
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);  // 384 ticks per chord
        var seq = new ChordProgression(60, MAJOR, "1,4,5");
        
        // Test two chord lines with different k values
        var chordLine1 = new ChordLine(ti, seq, 1, 4, 0.8, 1.0);  // k=1
        var chordLine2 = new ChordLine(ti, seq, 2, 4, 0.8, 1.0);  // k=2
        var deltas1 = chordLine1.asDeltaEvents();
        var deltas2 = chordLine2.asDeltaEvents();

        trace("k=1 first chord events:");
        for (i in 0...12) trace(deltas1[i]);
        trace("\nk=2 first chord events:");
        for (i in 0...12) trace(deltas2[i]);

        // For k=1:
        // - Each chord lasts 384 ticks
        // - Notes last 0.8 * 384 = 307.2 ticks
        // - Gap to next chord is 384 - 307.2 = 76.8 ticks
        testit("k=1 first chord timing",
            deltas1.slice(0, 6).map(d -> d.deltaFromLast),
            [
                0.0, 0.0, 0.0,      // Three notes start together
                76.8, 0.0, 0.0      // Three notes end together after 0.8 * 96 ticks
            ],
            "k=1 first chord should have correct note timings"
        );

        // For k=2:
        // - Each half-chord lasts 384/2 = 192 ticks
        // - Notes last 0.8 * 192 = 153.6 ticks
        // - Gap to next half-chord is 192 - 153.6 = 38.4 ticks
        testit("k=2 first chord timing",
            deltas2.slice(0, 6).map(d -> d.deltaFromLast),
            [
                0.0, 0.0, 0.0,      // First three notes start together
                153.6, 0.0, 0.0     // First three notes end together after 0.8 * (384/2) ticks
            ],
            "k=2 first chord should have correct note timings"
        );

        // Compare gaps between chords
        testit("k=1 vs k=2 chord spacing",
            [deltas1[6].deltaFromLast, deltas2[6].deltaFromLast],
            [76.8, 38.4],  // Gap to next event should be proportional to k
            "k=1 and k=2 should have different spacing between events"
        );

        trace('Delta Events: ${TEST_COUNT - startCount} tests run\n');
    }

    static function testTimeEventGeneration() {
        trace("\n=== Testing Time Event Generation ===");
        
        // Create a simple set of notes
        var notes = [
            new Note(0, 60, 100, 0.0, 76.8),    // C, starts at 0
            new Note(0, 64, 100, 0.0, 76.8),    // E, starts at 0
            new Note(0, 67, 100, 0.0, 76.8)     // G, starts at 0
        ];
        
        var line = new ChordLine(new TimeManipulator(), new ChordProgression(60, Mode.getMajorMode(), "1"), 1, 4, 0.8, 1.0);
        var timeEvents = line.notesToTimeEvents(notes);
        
        // Test event generation
        testit("Time event count", 
            timeEvents.length, 
            6,  // 3 note-ons + 3 note-offs
            "Should generate ON and OFF events for each note"
        );
        
        // Test event times
        testit("Note-on times",
            timeEvents.filter(te -> te.event.type == NOTE_ON).map(te -> te.time),
            [0.0, 0.0, 0.0],
            "All notes should start at time 0"
        );
        
        testit("Note-off times",
            timeEvents.filter(te -> te.event.type == NOTE_OFF).map(te -> te.time),
            [76.8, 76.8, 76.8],
            "All notes should end at time 76.8"
        );
        
        // Test sorting
        var sorted = line.sortTimeEvents(timeEvents);
        testit("Sorted event order",
            sorted.map(te -> te.event.type),
            [NOTE_ON, NOTE_ON, NOTE_ON, NOTE_OFF, NOTE_OFF, NOTE_OFF],
            "Should group ONs and OFFs together"
        );
    }

    static function testChordTimings() {
        trace("\n=== Testing Chord Timings ===");
        var startCount = TEST_COUNT;
        
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);  // 384 ticks per chord
        var seq = new ChordProgression(60, MAJOR, "1,4,5");  // Simple 3-chord progression
        
        // Test k=1 case
        trace("\nTesting k=1:");
        var chordLine1 = new ChordLine(ti, seq, 1, 4, 0.8, 1.0);
        var notes1 = chordLine1.generateNotes(0, 0, 100);  // channel 0, velocity 100
        
        // Check absolute timings of first few notes
        trace("k=1 Note timings:");
        for (i in 0...Std.int(Math.min(6, notes1.length))) {
            trace('Note ${i}: startTime=${notes1[i].startTime}, length=${notes1[i].length}');
        }
        
        // Now check delta events
        var deltas1 = chordLine1.asDeltaEvents();
        trace("k=1 Delta events:");
        for (i in 0...Std.int(Math.min(12, deltas1.length))) {
            trace('Delta ${i}: deltaFromLast=${deltas1[i].deltaFromLast}, type=${deltas1[i].type}');
        }
        
        // Test k=2 case
        trace("\nTesting k=2:");
        var chordLine2 = new ChordLine(ti, seq, 2, 4, 0.8, 1.0);
        var notes2 = chordLine2.generateNotes(0, 0, 100);  // channel 0, velocity 100
        
        // Check absolute timings
        trace("k=2 Note timings:");
        for (i in 0...Std.int(Math.min(6, notes2.length))) {
            trace('Note ${i}: startTime=${notes2[i].startTime}, length=${notes2[i].length}');
        }
        
        // Get delta events for k=2
        var deltas2 = chordLine2.asDeltaEvents();
        trace("k=2 Delta events:");
        for (i in 0...Std.int(Math.min(12, deltas2.length))) {
            trace('Delta ${i}: deltaFromLast=${deltas2[i].deltaFromLast}, type=${deltas2[i].type}');
        }
        
        // Test delta expectations for k=1
        testit("k=1 first two chords deltas",
            deltas1.slice(0, 15).map(d -> Math.round(d.deltaFromLast * 10) / 10),
            [
                // First chord
                0.0, 0.0, 0.0,           // Note-ons together
                76.8, 0.0, 0.0,          // Note-offs together
                // Second chord
                307.2,                    // Delta to next chord start
                0.0, 0.0,                // Other note-ons in chord
                76.8, 0.0, 0.0,          // Note-offs together
                // Start of third chord
                307.2,                    // Delta to next chord
                0.0, 0.0                 // Other note-ons in chord
            ],
            "First two chords should have correct timing"
        );
        
        // Also test k=2 deltas
        testit("k=2 first two chords deltas",
            deltas2.slice(0, 15).map(d -> Math.round(d.deltaFromLast * 10) / 10),
            [
                // First chord
                0.0, 0.0, 0.0,           // Note-ons together
                76.8, 0.0, 0.0,          // Note-offs together
                // Second chord (should be closer due to k=2)
                115.2,                    // Delta to next chord start
                0.0, 0.0,                // Other note-ons in chord
                76.8, 0.0, 0.0,          // Note-offs together
                // Start of third chord
                115.2,                    // Delta to next chord
                0.0, 0.0                 // Other note-ons in chord
            ],
            "k=2 should have shorter gaps between chords"
        );
        
        trace('Chord Timings: ${TEST_COUNT - startCount} tests run\n');
    }

    static function testRhythmGeneratorK1() {
        trace("\nTesting RhythmGenerator k=1");
        
        // Test k=1, n=4
        var rGen = new RhythmGenerator(1, 4);
        
        // Should get pattern [1,0,0,0] repeating
        var expectedPattern = [1,0,0,0];
        var actualPattern = [];
        
        // Get 8 beats (2 complete patterns)
        for (i in 0...8) {
            actualPattern.push(rGen.next());
        }
        
        // Check first pattern
        testit("k=1 first pattern",
            actualPattern.slice(0,4),
            expectedPattern,
            'k=1 first pattern should be [1,0,0,0]'
        );
        
        // Check pattern repeats
        testit("k=1 second pattern",
            actualPattern.slice(4,8),
            expectedPattern,
            'k=1 second pattern should be [1,0,0,0]'
        );
        
        // Count total hits
        var totalHits = Lambda.count(actualPattern, x -> x == 1);
        testit("k=1 total hits",
            totalHits,
            2,
            'k=1 should have exactly one hit per pattern'
        );
    }

    static function testTimeEventsForK1() {
        trace("\n=== Testing Time Events for k=1 ===");
        
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);  // 384 ticks per chord
        var seq = new ChordProgression(60, MAJOR, "1,4");  // Simple 2-chord progression
        var chordLine = new ChordLine(ti, seq, 1, 4, 0.8, 1.0);
        
        // Get the raw notes
        var notes = chordLine.generateNotes(0, 0, 100);
        trace("Raw notes:");
        for (i in 0...Std.int(Math.min(6, notes.length))) {
            trace('Note ${i}: startTime=${notes[i].startTime}, length=${notes[i].length}');
        }
        
        // Get time events and sort them
        var timeEvents = chordLine.notesToTimeEvents(notes);
        timeEvents = chordLine.sortTimeEvents(timeEvents);
        trace("\nTime events after sorting:");
        for (i in 0...timeEvents.length) {
            trace('Event ${i}: time=${timeEvents[i].time}, 
            type=${timeEvents[i].event.type}, note=${timeEvents[i].event.note}');
        }
        
        // Test first chord's events (should be 6 events - 3 note-ons and 3 note-offs)
        testit("k=1 first chord time events",
            timeEvents.slice(0, 6).map(te -> { 
                time: floatEqual(te.time, 0.0) ? 0.0 : floatEqual(te.time, 76.8) ? 76.8 : te.time, 
                type: te.event.type 
            }),
            [
                { time: 0.0, type: NOTE_ON },
                { time: 0.0, type: NOTE_ON },
                { time: 0.0, type: NOTE_ON },
                { time: 76.8, type: NOTE_OFF },
                { time: 76.8, type: NOTE_OFF },
                { time: 76.8, type: NOTE_OFF }
            ],
            "First chord should have notes starting at 0 and ending at 76.8"
        );
        
        // Test second chord's events - update expected times to match actual chord duration
        testit("k=1 second chord time events",
            timeEvents.slice(6, 12).map(te -> { 
                time: floatEqual(te.time, 384.0) ? 384.0 : floatEqual(te.time, 460.8) ? 460.8 : te.time, 
                type: te.event.type 
            }),
            [
                { time: 384.0, type: NOTE_ON },  // Start at next chord (384 ticks)
                { time: 384.0, type: NOTE_ON },
                { time: 384.0, type: NOTE_ON },
                { time: 460.8, type: NOTE_OFF }, // End 76.8 ticks later
                { time: 460.8, type: NOTE_OFF },
                { time: 460.8, type: NOTE_OFF }
            ],
            "Second chord should start at next chord boundary (384 ticks)"
        );
    }
}

