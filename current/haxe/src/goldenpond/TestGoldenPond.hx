import Mode;
import ChordThing;
import ChordParser;
import TimedSequence;
import ScoreUtilities;
import RhythmGenerator; // This imports all public types from RhythmGenerator.hx

class TestGoldenPond {
    static var ERRORS = 0;
    static var TEST_COUNT = 0;  // Add counter for total tests

    static function testit(id:String, val:Dynamic, target:Dynamic, msg:String) {
        TEST_COUNT++;  // Increment test counter
        if (!deepEquals(val, target)) {
            trace('ERROR IN ${id} : ${msg}');
            trace('Wanted:**${Std.string(target)}**');
            trace('Got:**${Std.string(val)}**');
            compareDetails(val, target);
            ERRORS++;
        } else {
            trace('${id} OK');
        }
    }

    static function compareChordThings(a:ChordThing, b:ChordThing):Bool {
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
        // Handle null
        if (a == null) return b == null;

        // Try direct equality first - if they're equal, no need for deep comparison
        if (a == b) return true;

        // Special cases that need deep comparison
        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            var arrayA:Array<Dynamic> = cast a;
            var arrayB:Array<Dynamic> = cast b;
            if (arrayA.length != arrayB.length) return false;
            for (i in 0...arrayA.length) {
                if (!deepEquals(arrayA[i], arrayB[i])) return false;
            }
            return true;
        }

        // Objects with custom equals methods
        if (Std.isOfType(a, Note) || Std.isOfType(a, ChordThing)) {
            return a.equals(b);
        }

        // Float comparison needs special handling
        if (Std.isOfType(a, Float)) {
            return floatEqual(cast(a, Float), cast(b, Float));
        }

        // If we get here and the values are equal as strings, consider them equal
        return Std.string(a) == Std.string(b);
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
            new ChordThing(60, MAJOR, 1).generateChordNotes(),
            [60, 64, 67],
            "Major triad C not correctly generated.");

        // Test Minor Triad
        testit("Minor Triad A",
            new ChordThing(57, MINOR, 1).generateChordNotes(),
            [57, 60, 64],
            "Minor triad A not correctly generated.");

        // Test Major Seventh Chord
        testit("Major Seventh C",
            new ChordThing(60, MAJOR, 1).seventh().generateChordNotes(),
            [60, 64, 67, 71],
            "Major seventh C not correctly generated.");

        // Test Minor Seventh Chord
        testit("Minor Seventh A",
            new ChordThing(57, MINOR, 1).seventh().generateChordNotes(),
            [57, 60, 64, 67],
            "Minor seventh A not correctly generated.");

        testit("Minor Ninth A",
            new ChordThing(57, MINOR, 1).ninth().generateChordNotes(),
            [57, 60, 64, 67, 71],
            "Minor ninth A not correctly generated.");

        testit("Secondary Dominant of iii chord in C",
            new ChordThing(60, MAJOR, 3).set_as_secondary(5).seventh().generateChordNotes(),
            [71, 75, 78, 81],
            "Secondary dominant of iii in C not correctly generated.");
        

        trace("Testing chord progressions");

        var progression = new ChordProgression(60, MAJOR, "1,4,6,5");
        testit("A chord progression",
            progression.toNotes(),
            [[60, 64, 67], [65, 69, 72], [69, 72, 76], [67, 71, 74]],
            "Chord progression not generated correctly");        
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

		// Test ChordLine - now using explicit RhythmGenerator
		var chordRhythm = new SimpleRhythmGenerator(5, 8, FullChord, 1, 0);
		var chord_line = LineGenerator.create(ti, seq, chordRhythm, 0.8).generateNotes(0, 0, 64);
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

		// Test BassLine - now using explicit RhythmGenerator
		var bassRhythm = new SimpleRhythmGenerator(1, 1, SpecificNote(1), 16, 0);
		var bass_line = LineGenerator.create(ti, seq, bassRhythm, 0.8)
			.transpose(-12)  // Explicitly transpose down one octave
			.generateNotes(0, 1, 100);
		testit("BassLine first twenty notes",
			bass_line.slice(0, 20),
			[
				new Note(1, 47, 100, 0, 384),
				new Note(1, 47, 100, 480, 384),
				new Note(1, 47, 100, 960, 384),
				new Note(1, 47, 100, 1440, 384),
				new Note(1, 47, 100, 1920, 384),
				new Note(1, 47, 100, 2400, 384),
				new Note(1, 47, 100, 2880, 384),
				new Note(1, 47, 100, 3360, 384),
				new Note(1, 47, 100, 3840, 384),
				new Note(1, 47, 100, 4320, 384),
				new Note(1, 47, 100, 4800, 384),
				new Note(1, 47, 100, 5280, 384),
				new Note(1, 47, 100, 5760, 384),
				new Note(1, 47, 100, 6240, 384),
				new Note(1, 47, 100, 6720, 384),
				new Note(1, 47, 100, 7200, 384),
				new Note(1, 40, 100, 7680, 384),
				new Note(1, 40, 100, 8160, 384),
				new Note(1, 40, 100, 8640, 384),
				new Note(1, 40, 100, 9120, 384)
			],
			"Bass line should play root notes with correct rhythm"
		);

		// Test TopLine - now using explicit RhythmGenerator
		var topRhythm = new SimpleRhythmGenerator(3, 8, TopNote, 2, 0);
		var top_line = LineGenerator.create(ti, seq, topRhythm, 0.6)
			.transpose(12)   // Explicitly transpose up one octave
			.generateNotes(0, 2, 100);
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

		// Test ArpLine - now using explicit RhythmGenerator
		var arpRhythm = new SimpleRhythmGenerator(6, 12, Ascending, 2, 0);
		var arp_line = LineGenerator.create(ti, seq, arpRhythm, 0.5).generateNotes(0, 3, 100);
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

		// Test RandomLine - now using explicit RhythmGenerator
		var randomRhythm = new BjorklundRhythmGenerator(5, 8, Random, 4, 0);
		var rand_line = LineGenerator.create(ti, seq, randomRhythm, 0.5).generateNotes(0, 4, 100);

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

		// Test ChordLine with transposition - now using explicit RhythmGenerator
		var transposedRhythm = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
		var transposed_line = LineGenerator.create(ti, seq, transposedRhythm, 0.8);
		transposed_line.transpose(12);  // Transpose up one octave
		var transposed_notes = transposed_line.generateNotes(0, 0, 64);
		testit("ChordLine transposition",
			transposed_notes.slice(0, 4),
			[
				new Note(0, 71, 64, 0, 1536),
				new Note(0, 74, 64, 0, 1536),
				new Note(0, 78, 64, 0, 1536),
				new Note(0, 81, 64, 0, 1536)
			],
			"Transposed line should be one octave higher"
		);

        var mixed = RhythmLanguage.parse("1.>.>.=< 1");
        testit("Mixed Pattern 1.>.>.=<",
        mixed.getSteps(),
        [SpecificNote(1), Rest, Ascending, Rest, Ascending, Rest, Repeat, Descending],
        "Should parse mixed pattern"
        );
        var line = LineGenerator.create(ti, seq, mixed, 0.8);
        var notes = line.generateNotes(0, 0, 64);
        testit("Mixed Line first 5 notes",
        notes.slice(0, 5),
        [
            new Note(0, 59, 64, 0, 768),
            new Note(0, 62, 64, 1920, 768),
            new Note(0, 66, 64, 3840, 768),
            new Note(0, 66, 64, 5760, 768),
            new Note(0, 62, 64, 6720, 768)        ],
        "Mixed line should play correct notes"
        );


	}

    static function runScoreUtils() {   
        var ti = new TimeManipulator().setPPQ(960);
		var seq = new ChordProgression(60, MAJOR, "72,75,71");
		trace(seq);
		var density = MenuHelper.rhythmicDensityToNumeric(FOUR);  // 1/4 - divide each chord into 4 steps
		var chordRhythm = new SimpleRhythmGenerator(1, 1, FullChord, 1, 0);
		var svg = ScoreUtilities.makePianoRollSVG(LineGenerator.create(ti, seq, chordRhythm, 0.8).generateNotes(0,0,64),800,600);		 
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
            { name: "Time Events for k=1 Tests", fn: testTimeEventsForK1 },
            { name: "Notes In Seconds Tests", fn: testNotesInSeconds },
            { name: "Rhythm Pattern Parser Tests", fn: testRhythmPatternParser },
            { name: "Rhythm Language Tests", fn: testRhythmLanguage },
            { name: "LineGenerator with RhythmGenerator Tests", fn: testLineGeneratorWithRhythmGenerator },
            { name: "Bjorklund Patterns Tests", fn: testBjorklundPatterns },
            { name: "Chord Naming Tests", fn: testChordNaming },
            { name: "Chord Progression Naming Tests", fn: testChordProgressionNaming }
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
        trace("Testing Rhythm Generator");
        
        // Test 3 in 8 pattern
        var rGen = new SimpleRhythmGenerator(3, 8, Ascending, 1, 0);  // Add selector parameter
        var pattern = [];
        var hitCount = 0;
        for (i in 0...8) {
            var beat = rGen.next();
            pattern.push(beat);
            if (beat == Ascending) hitCount++;  // Check for Ascending instead of 1
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
            if (beat == Ascending) hitCount++;  // Check for Ascending instead of 1
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
            var rg = new SimpleRhythmGenerator(k, n, Ascending, 1, 0);  // Add selector parameter
            var hits = 0;
            for (i in 0...n) {
                if (rg.next() == Ascending) hits++;  // Check for Ascending instead of 1
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
        var startCount = TEST_COUNT;
        
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);
        var seq = new ChordProgression(60, MAJOR, "1,4,5");
        
        var chordRhythm1 = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var chordRhythm2 = new SimpleRhythmGenerator(2, 4, FullChord, 1, 0);
        var chordLine1 = LineGenerator.create(ti, seq, chordRhythm1, 0.8);
        var chordLine2 = LineGenerator.create(ti, seq, chordRhythm2, 0.8);
        var deltas1 = chordLine1.asDeltaEvents();
        var deltas2 = chordLine2.asDeltaEvents();

        testit("k=1 first chord timing",
            deltas1.slice(0, 6).map(d -> d.deltaFromLast),
            [0.0, 0.0, 0.0, 76.8, 0.0, 0.0],
            "k=1 first chord should have correct note timings"
        );

        testit("k=2 first chord timing",
            deltas2.slice(0, 6).map(d -> d.deltaFromLast),
            [0.0, 0.0, 0.0, 76.8, 0.0, 0.0],
            "k=2 first chord should have correct note timings"
        );

        testit("k=1 vs k=2 chord spacing",
            [deltas1[6].deltaFromLast, deltas2[6].deltaFromLast],
            [307.2, 115.2],
            "k=1 and k=2 should have different spacing between events"
        );
    }

    static function testTimeEventGeneration() {
        trace("\n=== Testing Time Event Generation ===");
        
        // Create a simple set of notes
        var notes = [
            new Note(0, 60, 100, 0.0, 76.8),    // C, starts at 0
            new Note(0, 64, 100, 0.0, 76.8),    // E, starts at 0
            new Note(0, 67, 100, 0.0, 76.8)     // G, starts at 0
        ];
        
        var chordRhythm = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var line = LineGenerator.create(new TimeManipulator(), new ChordProgression(60, Mode.getMajorMode(), "1"), chordRhythm, 0.8);
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
        var chordRhythm1 = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var chordLine1 = LineGenerator.create(ti, seq, chordRhythm1, 0.8);
        var notes1 = chordLine1.generateNotes(0, 0, 100);  // channel 0, velocity 100
        var deltas1 = chordLine1.asDeltaEvents();

        
        // Test k=2 case
        trace("\nTesting k=2:");
        var chordRhythm2 = new SimpleRhythmGenerator(2, 4, FullChord, 1, 0);
        var chordLine2 = LineGenerator.create(ti, seq, chordRhythm2, 0.8);
        var notes2 = chordLine2.generateNotes(0, 0, 100);  // channel 0, velocity 100
        
        
        // Get delta events for k=2
        var deltas2 = chordLine2.asDeltaEvents();
        
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
        var rGen = new SimpleRhythmGenerator(1, 4, Ascending, 1, 0);  // Changed from RhythmGenerator
        
        // Should get pattern [1,0,0,0] repeating
        var expectedPattern = [Ascending, Rest, Rest, Rest];
        var actualPattern = [];
        
        // Get 8 beats (2 complete patterns)
        for (i in 0...8) {
            actualPattern.push(rGen.next());
        }
        
        // Check first pattern
        testit("k=1 first pattern",
            actualPattern.slice(0,4),
            expectedPattern,
            'k=1 first pattern should be [Ascending, Rest, Rest, Rest]'
        );
        
        // Check pattern repeats
        testit("k=1 second pattern",
            actualPattern.slice(4,8),
            expectedPattern,
            'k=1 second pattern should be [Ascending, Rest, Rest, Rest]'
        );
        
        // Count total hits
        var totalHits = Lambda.count(actualPattern, x -> x == Ascending);
        testit("k=1 total hits",
            totalHits,
            2,
            'k=1 should have exactly one hit per pattern'
        );
    }

    static function testTimeEventsForK1() {
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);
        var seq = new ChordProgression(60, MAJOR, "1,4");
        var chordRhythm = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var chordLine = LineGenerator.create(ti, seq, chordRhythm, 0.8);
        
        var notes = chordLine.generateNotes(0, 0, 100);
        
        var timeEvents = chordLine.notesToTimeEvents(notes);
        timeEvents = chordLine.sortTimeEvents(timeEvents);
        
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

    static function testNotesInSeconds() {
        trace("Starting testNotesInSeconds...");
        
        var tm = new TimeManipulator();
        tm.setPPQ(96).setChordDuration(4).setBPM(120);
        
        var prog = new ChordProgression(60, Mode.getMajorMode(), "1,4,5");
        var chordRhythm = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var line = LineGenerator.create(tm, prog, chordRhythm, 0.8);
        
        var tickNotes = line.generateNotes(0, 0, 100);
        var secondNotes = line.notesInSeconds(0, 0, 100);
        
        trace('Generated ${tickNotes.length} notes');
        
        // Test length match
        testit("Notes count", tickNotes.length, secondNotes.length, "Should have same number of notes");
        
        // At 120 BPM, one tick = 60/(120*96) seconds
        var secondsPerTick = 60.0 / (120.0 * 96.0);
        
        for (i in 0...tickNotes.length) {
            var tickNote = tickNotes[i];
            var secondNote = secondNotes[i];
            
            // Test each property individually
            testit('Note ${i} pitch', tickNote.note, secondNote.note, "Note pitch should match");
            testit('Note ${i} channel', tickNote.chan, secondNote.chan, "Channel should match");
            testit('Note ${i} velocity', tickNote.velocity, secondNote.velocity, "Velocity should match");
            
            // Test time values with explicit float comparison
            var expectedStartTime = tickNote.startTime * secondsPerTick;
            var expectedLength = tickNote.length * secondsPerTick;
            
            testit('Note ${i} start time', 
                floatEqual(expectedStartTime, secondNote.startTime), 
                true,
                'Start time should be ${expectedStartTime}'
            );
            
            testit('Note ${i} length', 
                floatEqual(expectedLength, secondNote.length), 
                true,
                'Length should be ${expectedLength}'
            );
        }
        
        trace("testNotesInSeconds completed.");
    }

    static function testRhythmPatternParser() {
        trace("\n=== Testing Rhythm Pattern Parser ===");
        var startCount = TEST_COUNT;
        
        // Test Euclidean pattern parsing
        var euclidean1 = RhythmLanguage.parse("3/8 > 4");
        testit("Euclidean pattern 3/8 > 4",
            !euclidean1.parseFailed(),
            true,
            "Should parse valid Euclidean pattern"
        );
        
        var euclidean2 = RhythmLanguage.parse("3/8+2 > 4");
        testit("Euclidean pattern with offset",
            !euclidean2.parseFailed(),
            true,
            "Should parse Euclidean pattern with offset"
        );
        
        var bjorklund = RhythmLanguage.parse("3%8 > 4");
        testit("Bjorklund pattern",
            !bjorklund.parseFailed(),
            true,
            "Should parse Bjorklund pattern"
        );
        
        // Test explicit pattern parsing
        var explicit1 = RhythmLanguage.parse("1.1. 8");
        testit("Explicit pattern 1.1. 8",
            !explicit1.parseFailed(),
            true,
            "Should parse valid explicit pattern"
        );
        
        var explicit2 = RhythmLanguage.parse(">.>.=.>. 4");
        testit("Explicit pattern with special selectors",
            !explicit2.parseFailed(),
            true,
            "Should parse valid explicit pattern"
        );
        
        // Test invalid patterns
        var invalid1 = RhythmLanguage.parse("abc");
        testit("Invalid pattern 'abc'",
            invalid1.parseFailed(),
            true,
            "Should return ParseFailedRhythmGenerator for invalid pattern"
        );
        
        var invalid2 = RhythmLanguage.parse("3/0 > 4");
        testit("Invalid pattern '3/0 > 4'",
            invalid2.parseFailed(),
            true,
            "Should return ParseFailedRhythmGenerator for invalid pattern with zero denominator"
        );
        
        trace('Rhythm Pattern Parser: ${TEST_COUNT - startCount} tests run\n');


    }

    static function testRhythmLanguage() {
        trace("\n=== Testing Rhythm Language ===");
        var startCount = TEST_COUNT;
        
        // Test SimpleRhythmGenerator creation
        var simple = RhythmLanguage.makeRhythmGenerator("3/8 > 4");
        testit("SimpleRhythmGenerator from string",
            !simple.parseFailed() && Std.isOfType(simple, SimpleRhythmGenerator),
            true,
            "Should create SimpleRhythmGenerator from string pattern"
        );
        
        // Test BjorklundRhythmGenerator creation
        var bjorklund = RhythmLanguage.makeRhythmGenerator("3%8 > 4");
        testit("BjorklundRhythmGenerator from string",
            !bjorklund.parseFailed() && Std.isOfType(bjorklund, BjorklundRhythmGenerator),
            true,
            "Should create BjorklundRhythmGenerator from string pattern"
        );
        
        // Test ExplicitRhythmGenerator creation
        var explicit = RhythmLanguage.makeRhythmGenerator(">.>.=.>. 4");
        testit("ExplicitRhythmGenerator from string",
            !explicit.parseFailed() && Std.isOfType(explicit, ExplicitRhythmGenerator),
            true,
            "Should create ExplicitRhythmGenerator from string pattern"
        );
        
        // Test pattern with offset
        var withOffset = RhythmLanguage.makeRhythmGenerator("3/8+2 > 4");
        testit("Pattern with offset",
            !withOffset.parseFailed(),
            true,
            "Should create rhythm generator with offset"
        );
        
        // Test various explicit patterns
        var patterns = [
            "1.1. 8",           // Root notes in positions 1 and 3
            "c... 2",           // Full chord then 3 gaps
            "r.r.r.r. 4",       // Random notes
            ">.>.=.<.<. 4"      // Mix of ascending, descending, and repeat
        ];
        
        for (pattern in patterns) {
            var generator = RhythmLanguage.makeRhythmGenerator(pattern);
            testit('Explicit pattern "${pattern}"',
                !generator.parseFailed() && Std.isOfType(generator, ExplicitRhythmGenerator),
                true,
                'Should create ExplicitRhythmGenerator from "${pattern}"'
            );
        }
        
        // Test invalid patterns
        var invalidPatterns = [
            "3/8",              // Missing density
            "3/8 X 4",          // Invalid selector
            "abc 4",            // Invalid pattern
            "3/0 > 4",          // Invalid n=0
            "0/8 > 4"           // Invalid k=0
        ];
        
        for (pattern in invalidPatterns) {
            var generator = RhythmLanguage.makeRhythmGenerator(pattern);
            testit('Invalid pattern "${pattern}" returns ParseFailedRhythmGenerator',
                generator.parseFailed() && Std.isOfType(generator, ParseFailedRhythmGenerator),
                true,
                'Should return ParseFailedRhythmGenerator for invalid pattern "${pattern}"'
            );
            
            testit('Invalid pattern "${pattern}" has parseFailed=true',
                generator.parseFailed(),
                true,
                'ParseFailedRhythmGenerator should have parseFailed=true'
            );
        }
        
        // Test that normal generators have parseFailed=false
        testit('Normal generator has parseFailed=false',
            !simple.parseFailed(),
            true,
            'Normal rhythm generators should have parseFailed=false'
        );
        
        trace('Rhythm Language: ${TEST_COUNT - startCount} tests run\n');
    }

    static function testBjorklundPattern(k:Int, n:Int, expected:Array<SelectorType>, name:String, offset:Int = 0) {
        var generator = new BjorklundRhythmGenerator(k, n, Ascending, 1, offset);
        var pattern = [];
        
        // Get the pattern
        for (i in 0...n) {
            pattern.push(generator.next());
        }
        
        testit('Bjorklund E(${k},${n})${offset > 0 ? "+"+offset : ""} - ${name}',
            pattern,
            expected,
            'Should generate correct ${name} pattern'
        );
    }

    static function testBjorklundPatterns() {
        // Common patterns from the literature, now using SelectorType
        var hit = Ascending;  // Using Ascending as our "hit" marker
        var rest = Rest;      // Using Rest as our "rest" marker
        
        // Test the Cuban tresillo pattern (3/8)
        testBjorklundPattern(3, 8, [hit,rest,rest,hit,rest,rest,hit,rest], "Cuban tresillo");
        
        // E(3,8) with offset 1 = [0,1,0,0,1,0,0,1]
        testBjorklundPattern(3, 8, [rest,hit,rest,rest,hit,rest,rest,hit], "Cuban tresillo", 1);
        
        // Test with different offset
        testBjorklundPattern(3, 8, [hit,rest,hit,rest,rest,hit,rest,rest], "Cuban tresillo", 2);
        
        // Test the Cuban cinquillo pattern (5/8)
        testBjorklundPattern(5, 8, [hit,rest,hit,hit,rest,hit,hit,rest], "Cuban cinquillo");
        
        // Test the Persian Khafif-e-ramal pattern (2/5)
        testBjorklundPattern(2, 5, [hit,rest,hit,rest,rest], "Persian Khafif-e-ramal");
        
        // Test the Cumbia pattern (3/4) with offset 2 to get the expected pattern
        testBjorklundPattern(3, 4, [hit,rest,hit,hit], "Cumbia", 2);
        
        // Test the Ruchenitza pattern (4/7)
        testBjorklundPattern(4, 7, [hit,rest,hit,rest,hit,rest,hit], "Ruchenitza");
        
        // Test the Agsag-Samai pattern (5/9)
        testBjorklundPattern(5, 9, [hit,rest,hit,rest,hit,rest,hit,rest,hit], "Agsag-Samai");
        
        // Test the Money pattern (3/7)
        testBjorklundPattern(3, 7, [hit,rest,hit,rest,hit,rest,rest], "Money");
        
        // Bjorklund 6%8 pattern with offset 3 to get the expected pattern
        testBjorklundPattern(6, 8, [hit,hit,hit,rest,hit,hit,hit,rest], "Bjorklund 6%8");
        
        // Test the Bossa-Nova pattern (5/16)
        testBjorklundPattern(5, 16, [hit,rest,rest,hit,rest,rest,hit,rest,rest,hit,rest,rest,hit,rest,rest,rest], "Bossa-Nova");
    }

    static function testLineGeneratorWithRhythmGenerator() {
        trace("\n=== Testing LineGenerator with RhythmGenerator ===");
        var startCount = TEST_COUNT;
        
        var ti = new TimeManipulator();
        ti.setPPQ(960).setChordDuration(8).setBPM(120);
        
        var seq = new ChordProgression(50, MAJOR, "76,72,!,75,71");
        
        // Test creating LineGenerator with SimpleRhythmGenerator
        var simpleRhythm = new SimpleRhythmGenerator(3, 8, FullChord, 1, 0);
        var line1 = LineGenerator.create(ti, seq, simpleRhythm, 0.8);
        var notes1 = line1.generateNotes(0, 0, 100);
        
        testit("LineGenerator with SimpleRhythmGenerator",
            notes1.length > 0,
            true,
            "Should generate notes with SimpleRhythmGenerator"
        );
        
        // Test creating LineGenerator with BjorklundRhythmGenerator
        var bjorklundRhythm = new BjorklundRhythmGenerator(3, 8, FullChord, 1, 0);
        var line2 = LineGenerator.create(ti, seq, bjorklundRhythm, 0.8);
        var notes2 = line2.generateNotes(0, 0, 100);
        
        testit("LineGenerator with BjorklundRhythmGenerator",
            notes2.length > 0,
            true,
            "Should generate notes with BjorklundRhythmGenerator"
        );
        
        // Test creating LineGenerator with ExplicitRhythmGenerator
        var explicitRhythm = new ExplicitRhythmGenerator([FullChord, Rest, FullChord, Rest, FullChord], 1);
        var line3 = LineGenerator.create(ti, seq, explicitRhythm, 0.8);
        var notes3 = line3.generateNotes(0, 0, 100);
        
        testit("LineGenerator with ExplicitRhythmGenerator",
            notes3.length > 0,
            true,
            "Should generate notes with ExplicitRhythmGenerator"
        );
        
        // Test creating LineGenerator from pattern string
        var patterns = [
            "3/8 > 4",          // Simple Euclidean
            "3%8 > 4",          // Bjorklund
            ">.>.=.<. 4"        // Explicit
        ];
        
        for (i in 0...patterns.length) {
            var pattern = patterns[i];
            var line = LineGenerator.createFromPattern(ti, seq, pattern, 0.8);
            testit('LineGenerator from pattern "${pattern}"',
                line != null,
                true,
                'Should create LineGenerator from pattern "${pattern}"'
            );
        }
        
        // Test with invalid pattern
        var exceptionThrown = false;
        try {
            var invalidLine = LineGenerator.createFromPattern(ti, seq, "invalid pattern", 0.8);
            // If we get here, no exception was thrown
        } catch (e:String) {
            exceptionThrown = true;
        }
        testit("LineGenerator from invalid pattern throws exception",
            exceptionThrown,
            true,
            "Should throw exception for invalid pattern"
        );
        
        trace('LineGenerator with RhythmGenerator: ${TEST_COUNT - startCount} tests run\n');
    }

    static function testChordNaming() {
        // Test basic major and minor chords
        var cMajor = new ChordThing(60, Mode.getMajorMode(), 1);
        testit("C Major chord name", cMajor.getChordName(), "C", "Basic C Major chord should be named 'C'");
        
        var aMinor = new ChordThing(60, Mode.getMajorMode(), 6);
        testit("A Minor chord name", aMinor.getChordName(), "Am", "A Minor chord should be named 'Am'");
        
        // Test with modal interchange
        var cMinor = new ChordThing(60, Mode.getMajorMode(), 1).modal_interchange();
        testit("C Minor (modal interchange) chord name", cMinor.getChordName(), "Cm", "C Minor chord should be named 'Cm'");
        
        // Test with extensions
        var g7 = new ChordThing(60, Mode.getMajorMode(), 5).seventh();
        testit("G7 chord name", g7.getChordName(), "G7", "G7 chord should be named 'G7'");
        
        // In C major, the ii chord (D) is minor, so D9 should be Dm9
        var d9 = new ChordThing(60, Mode.getMajorMode(), 2).ninth();
        testit("D9 chord name", d9.getChordName(), "Dm9", "D9 chord in C major should be named 'Dm9'");
        
        // Test with inversions
        var fInv1 = new ChordThing(60, Mode.getMajorMode(), 4).set_inversion(1);
        testit("F/A chord name", fInv1.getChordName(), "F/A", "F with first inversion should be named 'F/A'");
        
        var gInv2 = new ChordThing(60, Mode.getMajorMode(), 5).set_inversion(2);
        testit("G/D chord name", gInv2.getChordName(), "G/D", "G with second inversion should be named 'G/D'");
        
        // Test with secondary chords
        // In C major, when we set the 3rd degree (E) as a secondary chord targeting the 6th degree (A),
        // ChordFactory.calculateSecondaryChord creates a new chord in A major with degree 3, which is C#m
        var secondaryChord = new ChordThing(60, Mode.getMajorMode(), 3).seventh().set_as_secondary(6);
        testit("Secondary chord name", secondaryChord.getChordName(), "C#m7", 
               "Secondary chord should be named based on the chord created by ChordFactory.calculateSecondaryChord");
        
        // Test with different keys
        var fSharpMinor = new ChordThing(66, Mode.getMinorMode(), 1);
        testit("F# Minor chord name", fSharpMinor.getChordName(), "F#m", "F# Minor chord should be named 'F#m'");
        
        // Test with complex combinations - in C major, the ii chord (D) with 7th and first inversion
        var complex = new ChordThing(60, Mode.getMajorMode(), 2).seventh().set_inversion(1);
        testit("D7/F chord name", complex.getChordName(), "Dm7/F", "Dm7 with first inversion should be named 'Dm7/F'");
    }
    
    static function testChordProgressionNaming() {
        // Test a simple progression
        var progression = new ChordProgression(60, Mode.getMajorMode(), "1,4,5,1");
        var expectedNames = ["C", "F", "G", "C"];
        testit("Simple progression names", progression.getChordNames(), expectedNames, "Simple progression should have correct names");
        
        // Test a more complex progression
        var complexProg = new ChordProgression(60, Mode.getMajorMode(), "1,4,5,1i,6,2,5,1");
        var expectedComplexNames = ["C", "F", "G", "C/E", "Am", "Dm", "G", "C"];
        testit("Complex progression names", complexProg.getChordNames(), expectedComplexNames, "Complex progression should have correct names");
        
        // Test with modal interchange and secondary chords
        // In C major:
        // 1 = C
        // -4 = Fm (modal interchange)
        // (5/2) = A7 (V7 of ii, which is Dm)
        // This is the correct interpretation: (5/2) means the 5 chord in the key of the 2nd degree
        var jazzProg = new ChordProgression(60, Mode.getMajorMode(), "1,-4,(5/2),1");
        var expectedJazzNames = ["C", "Fm", "A", "C"];
        testit("Jazz progression names", jazzProg.getChordNames(), expectedJazzNames, "Jazz progression should have correct names");
    }
}

