import Mode;
import ChordThing;
import ChordParser;
import TimedSequence;
import ScoreUtilities;

class TestGoldenPond {
    static var ERRORS = 0;

    static function testit(id:String, val:Dynamic, target:Dynamic, msg:String) {
        if (!deepEquals(val, target)) {
            trace("ERROR IN " + id + " : " + msg);
            trace("Wanted:*" + Std.string(target) + "**");
            trace("Got:*" + Std.string(val) + "**");
            compareDetails(val, target);
        } else {
            trace(id + " OK");
        }
    }
    
	static function deepEquals(a:Dynamic, b:Dynamic):Bool {
		if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
		    if (a.length != b.length) return false;
		    for (i in 0...a.length) {
		        if (!deepEquals(a[i], b[i])) return false;
		    }
		    return true;
		} else if (Std.isOfType(a, Note) && Std.isOfType(b, Note)) {
		    return a.equals(b);
		} else if (Std.isOfType(a, ChordThing) && Std.isOfType(b, ChordThing)) {
		    return a.equals(b);
		} else {
		    return a == b;
		}
	}



    static function compareChordThings(a:ChordThing, b:ChordThing):Bool {
    	trace("In compareChordThings SHOULDN'T BE HERE");
        return a.key == b.key &&
            a.mode == b.mode &&
            a.degree == b.degree &&
            a.length == b.length &&
            a.inversion == b.inversion &&
            a.secondary_degree == b.secondary_degree &&
            compareModifiers(a.modifiers, b.modifiers);
    }

    static function compareModifiers(a:Array<Modifier>, b:Array<Modifier>):Bool {
		trace("In compareModifiers SHOULDN'T BE HERE");
        if (a.length != b.length) return false;
        for (i in 0...a.length) {
            if (a[i] != b[i]) return false;
        }
        return true;
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
  
	static function testTimeManipulator() {
		trace("Testing Timed Sequences");

		var ti = new TimeManipulator();
		ti.setDivision(QUARTER).setNoteLen(0.8).setChordLen(16).setPPQ(960);
		var seq = new ChordProgression(60, MAJOR, "72,75,71");
		testit("TimeManipulator Chords",
		    ti.chords(seq, 0),
		    [
		        new Note(62, 0, 1536.0), new Note(65, 0, 1536.0),
		        new Note(69, 0, 1536.0), new Note(72, 0, 1536.0),
		        new Note(67, 3840.0, 1536.0), new Note(71, 3840.0, 1536.0),
		        new Note(74, 3840.0, 1536.0), new Note(77, 3840.0, 1536.0),
		        new Note(60, 7680.0, 1536.0), new Note(64, 7680.0, 1536.0),
		        new Note(67, 7680.0, 1536.0), new Note(71, 7680.0, 1536.0)
		    ],
		    "Chord Times");

		trace("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");

		testit("TimeManipulator Bass",
		    ti.bassline(seq, 3, 8, 0),
		    [
		        new Note(50, 0, 192.0), new Note(50, 720.0, 192.0),
		        new Note(50, 1200.0, 192.0), new Note(50, 1920.0, 192.0),
		        new Note(50, 2640.0, 192.0), new Note(50, 3120.0, 192.0),
		        new Note(55, 3840.0, 192.0), new Note(55, 4560.0, 192.0),
		        new Note(55, 5040.0, 192.0), new Note(55, 5760.0, 192.0),
		        new Note(55, 6480.0, 192.0), new Note(55, 6960.0, 192.0),
		        new Note(48, 7680.0, 192.0), new Note(48, 8400.0, 192.0),
		        new Note(48, 8880.0, 192.0), new Note(48, 9600.0, 192.0),
		        new Note(48, 10320.0, 192.0), new Note(48, 10800.0, 192.0)
		    ],
		    "Bassline Times");
		trace("===================================================================================");

		testit("TimeManipulator Top",
		    ti.topline(seq, 3, 8, 0),
		    [
		        new Note(84, 0, 192.0), new Note(84, 720.0, 192.0),
		        new Note(84, 1200.0, 192.0), new Note(84, 1920.0, 192.0),
		        new Note(84, 2640.0, 192.0), new Note(84, 3120.0, 192.0),
		        new Note(89, 3840.0, 192.0), new Note(89, 4560.0, 192.0),
		        new Note(89, 5040.0, 192.0), new Note(89, 5760.0, 192.0),
		        new Note(89, 6480.0, 192.0), new Note(89, 6960.0, 192.0),
		        new Note(83, 7680.0, 192.0), new Note(83, 8400.0, 192.0),
		        new Note(83, 8880.0, 192.0), new Note(83, 9600.0, 192.0),
		        new Note(83, 10320.0, 192.0), new Note(83, 10800.0, 192.0)
		    ],
		    "Bassline Times");

		testit("TimeManipulator Silent",
		    ti.silentline(seq, 3, 8, 0),
		    [],
		    "Silence");

		testit("TimeManipulator Arpeggiate",
		    ti.arpeggiate(seq, 3, 8, 0),
		    [
		        new Note(62, 0, 192.0), new Note(65, 720.0, 192.0),
		        new Note(69, 1200.0, 192.0), new Note(72, 1920.0, 192.0),
		        new Note(62, 2640.0, 192.0), new Note(65, 3120.0, 192.0),	
		        new Note(67, 3840.0, 192.0), new Note(71, 4560.0, 192.0),
		        new Note(74, 5040.0, 192.0), new Note(77, 5760.0, 192.0),
		        new Note(67, 6480.0, 192.0), new Note(71, 6960.0, 192.0),
		        new Note(60, 7680.0, 192.0), new Note(64, 8400.0, 192.0),
		        new Note(67, 8880.0, 192.0), new Note(71, 9600.0, 192.0),
		        new Note(60, 10320.0, 192.0), new Note(64, 10800.0, 192.0)
		    ],
		    "Arp Times");

		testit("Grab combo",
		    ti.grabCombo(seq, 3, 8, 0, [SeqTypes.TOP, SeqTypes.EUCLIDEAN]),
		    [
		        new Note(84, 0, 192.0), new Note(84, 720.0, 192.0),
		        new Note(84, 1200.0, 192.0), new Note(84, 1920.0, 192.0),
		        new Note(84, 2640.0, 192.0), new Note(84, 3120.0, 192.0),
		        new Note(89, 3840.0, 192.0), new Note(89, 4560.0, 192.0),
		        new Note(89, 5040.0, 192.0), new Note(89, 5760.0, 192.0),
		        new Note(89, 6480.0, 192.0), new Note(89, 6960.0, 192.0),
		        new Note(83, 7680.0, 192.0), new Note(83, 8400.0, 192.0),
		        new Note(83, 8880.0, 192.0), new Note(83, 9600.0, 192.0),
		        new Note(83, 10320.0, 192.0), new Note(83, 10800.0, 192.0),
		        new Note(62, 0, 192.0), new Note(65, 720.0, 192.0),
		        new Note(69, 1200.0, 192.0), new Note(72, 1920.0, 192.0),
		        new Note(62, 2640.0, 192.0), new Note(65, 3120.0, 192.0),
		        new Note(67, 3840.0, 192.0), new Note(71, 4560.0, 192.0),
		        new Note(74, 5040.0, 192.0), new Note(77, 5760.0, 192.0),
		        new Note(67, 6480.0, 192.0), new Note(71, 6960.0, 192.0),
		        new Note(60, 7680.0, 192.0), new Note(64, 8400.0, 192.0),
		        new Note(67, 8880.0, 192.0), new Note(71, 9600.0, 192.0),
		        new Note(60, 10320.0, 192.0), new Note(64, 10800.0, 192.0)
		    ],
		    "Grab both TOP and EUCLIDEAN");

		testit("Grab combo of one",
		    ti.grabCombo(seq, 3, 8, 0, [SeqTypes.TOP]),
		    [
		        new Note(84, 0, 192.0), new Note(84, 720.0, 192.0),
		        new Note(84, 1200.0, 192.0), new Note(84, 1920.0, 192.0),
		        new Note(84, 2640.0, 192.0), new Note(84, 3120.0, 192.0),
		        new Note(89, 3840.0, 192.0), new Note(89, 4560.0, 192.0),
		        new Note(89, 5040.0, 192.0), new Note(89, 5760.0, 192.0),
		        new Note(89, 6480.0, 192.0), new Note(89, 6960.0, 192.0),
		        new Note(83, 7680.0, 192.0), new Note(83, 8400.0, 192.0),
		        new Note(83, 8880.0, 192.0), new Note(83, 9600.0, 192.0),
		        new Note(83, 10320.0, 192.0), new Note(83, 10800.0, 192.0)
		    ],
		    "Grab TOP only");

		testit("Grab Bass and Scale",
		    ti.grabCombo(seq, 3, 8, 0, [SeqTypes.BASS, SeqTypes.SCALE]),
		    [
		        new Note(50, 0, 192.0), new Note(50, 720.0, 192.0),
		        new Note(50, 1200.0, 192.0), new Note(50, 1920.0, 192.0),
		        new Note(50, 2640.0, 192.0), new Note(50, 3120.0, 192.0),
		        new Note(55, 3840.0, 192.0), new Note(55, 4560.0, 192.0),
		        new Note(55, 5040.0, 192.0), new Note(55, 5760.0, 192.0),
		        new Note(55, 6480.0, 192.0), new Note(55, 6960.0, 192.0),
		        new Note(48, 7680.0, 192.0), new Note(48, 8400.0, 192.0),
		        new Note(48, 8880.0, 192.0), new Note(48, 9600.0, 192.0),
		        new Note(48, 10320.0, 192.0), new Note(48, 10800.0, 192.0)
		    ],
		    "Grab both BASS and SCALE");
		    
	}

    static function runScoreUtils() {
        var ti = new TimeManipulator().setPPQ(960);
	var seq = new ChordProgression(60, MAJOR, "72,75,71");
	trace(seq);
	var svg = ScoreUtilities.makePianoRollSVG(ti.chords(seq, 0),800,600);
		 
	trace(svg);
    }
	
	
    static function main() {
        runScoreUtils();
        testMode();
        testChordThing();
        testChordFactory();
        testParser();
	testMenuHelper();
        testTimeManipulator();
        

        
/*



        //TODO Unit test this
        trace("-------------------------\nVoice Lead diagnostics");
        trace(voice_lead([60, 63, 66], [60, 63, 66]));
        trace(voice_lead([60, 63, 66], [65, 69, 72]));
        trace(voice_lead([60, 63, 66], [55, 58, 62]));
        trace("-------------------------");


            */
    }
}

