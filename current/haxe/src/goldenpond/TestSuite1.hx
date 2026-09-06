import UnitTester;

import Mode;
import ChordThing;
import ChordParser;
import ScoreUtilities;
import GoldenData;
import TimedSequence;

class TestSuite1 {

    public static function allTests(tester:UnitTester) {
        testMode(tester);
        testNotes(tester);
        testChordThing(tester);
        testParser(tester);
        testChordNaming(tester);
        testChordProgressionNaming(tester);        
        testGoldenData(tester);
        testCorrections(tester);
    }

    static function testMode(tester:UnitTester) {
        var MAJOR = Mode.getMajorMode();
        var major_mode_2 = Mode.getMajorMode();

        trace("Testing Modes (ie Scale object)");
        tester.testit("modes1", MAJOR == major_mode_2, true, "Major Mode not singleton");

        tester.testit("modes2", MAJOR.nth_from(60, 1), 60, "Modes 2");
        tester.testit("modes3", MAJOR.nth_from(60, 2), 62, "Modes 3");
        tester.testit("modes4", MAJOR.nth_from(60, 3), 64, "Modes 4");

        var MINOR = Mode.getMinorMode();
        tester.testit("modes5", MINOR.nth_from(60, 3), 63, "Modes 5");
        tester.testit("modes6", MAJOR.nth_from(60, 8), 72, "Modes 6");
        tester.testit("modes7", MINOR.nth_from(60, 9), 74, "Modes 7");

        tester.testit("modes8", MAJOR.make_triad(60, 1), [60, 64, MAJOR.nth_from(60, 5)], "Modes 8");
        tester.testit("modes9", MINOR.make_triad(60, 1), [60, 63, MINOR.nth_from(60, 5)], "Modes 9");
        tester.testit("modes10", MAJOR.make_seventh(70, 1), [70, 74, 77, 81], "Modes 10");
        tester.testit("modes11", MAJOR.make_ninth(70, 1), [70, 74, 77, 81, 84], "Modes 11");
        tester.testit("modes12", MAJOR.make_ninth(70, 4), [75, 79, 82, 86, 89], "Modes 12");
        tester.testit("modes13", MAJOR.make_chord_from_pattern(50, 2, [1, 3, 5]), MAJOR.make_triad(50, 2), "Modes 13");

        tester.testit("modes14", Mode.constructNthMajorMode(1).intervals, [2, 2, 1, 2, 2, 2, 1], "Modes 14 : Other modes ionian");
        tester.testit("modes15", Mode.constructNthMajorMode(2).intervals, [2, 1, 2, 2, 2, 1, 2], "Modes 15 : Dorian");
        tester.testit("modes16", Mode.constructNthMajorMode(3).intervals, [1, 2, 2, 2, 1, 2, 2], "Modes 16 : Phrygian");
        tester.testit("modes17", Mode.constructNthMajorMode(3).intervals, Mode.getPhrygianMode().intervals, "Modes 17 : Phrygian as name");
        tester.testit("modes18", Mode.getLydianMode().intervals, [2, 2, 2, 1, 2, 2, 1], "Modes 18 : Lydian");
        tester.testit("modes19", Mode.getMixolydianMode().intervals, [2, 2, 1, 2, 2, 1, 2], "Modes 19 : Mixolydian");
        tester.testit("modes20", Mode.getAeolianMode().intervals, [2, 1, 2, 2, 1, 2, 2], "Modes 20 : Aeolian");
        tester.testit("modes21", Mode.getLocrianMode().intervals, [1, 2, 2, 1, 2, 2, 2], "Modes 21 : Locrian");

        // Test Harmonic Minor Mode
        var HARMONIC_MINOR = Mode.getHarmonicMinorMode();
        var harmonic_minor_2 = Mode.getHarmonicMinorMode();
        tester.testit("modes22", HARMONIC_MINOR == harmonic_minor_2, true, "Harmonic Minor Mode not singleton");
        tester.testit("modes23", HARMONIC_MINOR.intervals, [2, 1, 2, 2, 1, 3, 1], "Harmonic Minor intervals");
        tester.testit("modes24", HARMONIC_MINOR.nth_from(60, 7), 71, "Harmonic Minor 7th degree (raised 7th)");
        tester.testit("modes25", HARMONIC_MINOR.make_triad(60, 1), [60, 63, 67], "Harmonic Minor triad");
        tester.testit("modes26", HARMONIC_MINOR.make_seventh(60, 1), [60, 63, 67, 71], "Harmonic Minor seventh");

        // Test Melodic Minor Mode
        tester.testit("modes27", Mode.getMelodicMinorMode() == Mode.getMelodicMinorMode(), true, "Melodic Minor Mode not singleton");
        tester.testit("modes28", Mode.getMelodicMinorMode().intervals, [2, 1, 2, 2, 2, 2, 1], "Melodic Minor intervals");
        tester.testit("modes29", Mode.getMelodicMinorMode().nth_from(60, 6), 69, "Melodic Minor 6th degree (raised 6th)");
        tester.testit("modes30", Mode.getMelodicMinorMode().nth_from(60, 7), 71, "Melodic Minor 7th degree (raised 7th)");
        tester.testit("modes31", Mode.getMelodicMinorMode().make_triad(60, 1), [60, 63, 67], "Melodic Minor triad");
        tester.testit("modes32", Mode.getMelodicMinorMode().make_seventh(60, 1), [60, 63, 67, 71], "Melodic Minor seventh");

        // Test mode construction for new modes
        tester.testit("modes33", Mode.constructNthHarmonicMinorMode(1).intervals, [2, 1, 2, 2, 1, 3, 1], "Harmonic Minor mode construction");
        tester.testit("modes34", Mode.constructNthMelodicMinorMode(1).intervals, [2, 1, 2, 2, 2, 2, 1], "Melodic Minor mode construction");

        // Test Harmonic Major Mode
        tester.testit("modes35", Mode.getHarmonicMajorMode() == Mode.getHarmonicMajorMode(), true, "Harmonic Major Mode not singleton");
        tester.testit("modes36", Mode.getHarmonicMajorMode().intervals, [2, 2, 1, 2, 1, 3, 1], "Harmonic Major intervals");
        tester.testit("modes37", Mode.getHarmonicMajorMode().nth_from(60, 6), 68, "Harmonic Major lowered 6th degree");
        tester.testit("modes38", Mode.constructNthHarmonicMajorMode(1).intervals, [2, 2, 1, 2, 1, 3, 1], "Harmonic Major mode construction");

        // Test Hungarian Minor Mode
        tester.testit("modes39", Mode.getHungarianMinorMode() == Mode.getHungarianMinorMode(), true, "Hungarian Minor Mode not singleton");
        tester.testit("modes40", Mode.getHungarianMinorMode().intervals, [2, 1, 3, 1, 1, 3, 1], "Hungarian Minor intervals");
        tester.testit("modes41", Mode.getHungarianMinorMode().nth_from(60, 4), 66, "Hungarian Minor raised 4th degree");
        tester.testit("modes42", Mode.constructNthHungarianMinorMode(1).intervals, [2, 1, 3, 1, 1, 3, 1], "Hungarian Minor mode construction");

        // Test Double Harmonic Major Mode
        tester.testit("modes43", Mode.getDoubleHarmonicMajorMode() == Mode.getDoubleHarmonicMajorMode(), true, "Double Harmonic Major Mode not singleton");
        tester.testit("modes44", Mode.getDoubleHarmonicMajorMode().intervals, [1, 3, 1, 2, 1, 3, 1], "Double Harmonic Major intervals");
        tester.testit("modes45", Mode.getDoubleHarmonicMajorMode().nth_from(60, 2), 61, "Double Harmonic Major lowered 2nd degree");
        tester.testit("modes46", Mode.constructNthDoubleHarmonicMajorMode(1).intervals, [1, 3, 1, 2, 1, 3, 1], "Double Harmonic Major mode construction");

        tester.testit("modes47", Mode.nthModeOf(Mode.getMajorMode(), 3).intervals, Mode.constructNthMajorMode(3).intervals, "nthModeOf major family");
        tester.testit("modes48", Mode.nthModeOf(Mode.getHarmonicMajorMode(), 4).intervals, Mode.constructNthHarmonicMajorMode(4).intervals, "nthModeOf harmonic major family");
        tester.testit("modes49", Mode.nthModeOf(Mode.getHungarianMinorMode(), 5).intervals, Mode.constructNthHungarianMinorMode(5).intervals, "nthModeOf hungarian minor family");
        tester.testit("modes50", Mode.nthModeOf(Mode.getDoubleHarmonicMajorMode(), 6).intervals, Mode.constructNthDoubleHarmonicMajorMode(6).intervals, "nthModeOf double harmonic major family");
        tester.testit("modes51", Mode.getMajorMode().isMinorScale(), false, "Major mode should not have a flat third");
        tester.testit("modes52", Mode.getMinorMode().isMinorScale(), true, "Minor mode should have a flat third");
        tester.testit("modes53", Mode.getHarmonicMajorMode().isMinorScale(), false, "Harmonic major should not have a flat third");
        tester.testit("modes54", Mode.getHungarianMinorMode().isMinorScale(), true, "Hungarian minor should have a flat third");
    }	
    
    
    static function testNotes(tester:UnitTester) {
	  trace("Testing Notes");
	  var n = new Note(0,68,100,4,0.5);
	  tester.testit("Note transposition",
		 n.transpose(12),
		 new Note(0,80,100,4,0.5),
		 "note transposition");

      tester.testit("Note to string",
      	n.toString(),
      	'Note[chan: 0, note: 68, vel: 100, startTime: 4, length: 0.5]',
      	"note to string"
      );
	  trace("Transposing collections of Notes");
	  var ns:Array<INote> = [new Note(0,68,100,4,0.5), new Note(0,64,50,8,0.5)];
	  var instrumentContext = new MidiInstrumentContext(0, 100, 0.8, 0);
	  tester.testit("Note collection transposition",
		 ScoreUtilities.transposeNotes(ns, -4, instrumentContext),
		 [instrumentContext.makeNote(64,4,0.5), instrumentContext.makeNote(60,8,0.5)],
		 "note collection transposition");
	
	}
     
    
    static function testChordThing(tester:UnitTester) {
        trace("Testing ChordThing. Now MODE is the actual Scale itself.");
        
        tester.testit("ChordThing ninths override sevenths",
            Std.string(new ChordThing(60, Mode.getMajorMode(), 3).seventh().ninth()),
            "ChordThing(60,MAJOR,3,0,1) + [NINTH]",
            "ChordThings ninths override sevenths failed.");

        tester.testit("ChordThing has extensions with ninth",
            new ChordThing(60, Mode.getMajorMode(), 3).ninth().has_extensions(),
            true,
            "ChordThing expected to have extensions with ninth.");


        tester.testit("ChordThing with length",
            Std.string(new ChordThing(60, Mode.getMinorMode(), 3, 2)),
            "ChordThing(60,MINOR,3,0,2) + []",
            "ChordThing with length failed.");

        tester.testit("ChordThing swap mode to MINOR",
            new ChordThing(60, Mode.getMajorMode(), 3).swap_mode().mode,
            Mode.getMinorMode(),
            "ChordThing swap mode to MINOR failed.");

        tester.testit("ChordThing swap mode back to MAJOR",
            new ChordThing(60, Mode.getMinorMode(), 3).swap_mode().mode,
            Mode.getMajorMode(),
            "ChordThing swap mode back to MAJOR failed.");

        tester.testit("ChordThing", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).seventh()), "ChordThing(60,MAJOR,3,0,2) + [SEVENTH]", "ChordThings");
        var ct1 = new ChordThing(60, Mode.getMajorMode(), 3, 2);
        tester.testit("ChordThing no extensions", ct1.has_extensions(), false, "ChordThings");
        ct1 = new ChordThing(60, Mode.getMajorMode(), 3, 2).ninth();
        tester.testit("ChordThing has extensions", ct1.has_extensions(), true, "ChordThings");

        tester.testit("ChordThing ninths override sevenths", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).seventh().ninth()), "ChordThing(60,MAJOR,3,0,2) + [NINTH]", "ChordThings");
        tester.testit("ChordThing sevenths override ninths", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).ninth().seventh()), "ChordThing(60,MAJOR,3,0,2) + [SEVENTH]", "ChordThings");
        tester.testit("ChordThing mode switching", Std.string(new ChordThing(60, Mode.getMinorMode(), 3, 2)), "ChordThing(60,MINOR,3,0,2) + []", "ChordThings");
        tester.testit("ChordThing get mode", new ChordThing(60, Mode.getMinorMode(), 3, 2).get_mode(), Mode.getMinorMode(), "ChordThing.getMode");
        tester.testit("ChordThing get mode after swap", new ChordThing(60, Mode.getMinorMode(), 3, 2).swap_mode().get_mode(), Mode.getMajorMode(), "ChordThing.getMode after swap");

        // Test ChordThing basic functionality
        tester.testit("ChordThing basic", Std.string(new ChordThing(60, Mode.getMajorMode(), 3)), "ChordThing(60,MAJOR,3,0,1) + []", "ChordThings");
        tester.testit("ChordThing with length", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2)), "ChordThing(60,MAJOR,3,0,2) + []", "ChordThings");
        tester.testit("ChordThing with inversion", Std.string(new ChordThing(60, Mode.getMajorMode(), 3, 2).set_inversion(1)), "ChordThing(60,MAJOR,3,1,2) + []", "ChordThings");
        tester.testit("ChordThing with seventh", Std.string(new ChordThing(60, Mode.getMajorMode(), 3).seventh()), "ChordThing(60,MAJOR,3,0,1) + [SEVENTH]", "ChordThings");
        tester.testit("ChordThing with ninth", Std.string(new ChordThing(60, Mode.getMajorMode(), 3).ninth()), "ChordThing(60,MAJOR,3,0,1) + [NINTH]", "ChordThings");
        tester.testit("ChordThing mode switching", Std.string(new ChordThing(60, Mode.getMajorMode(), 3).swap_mode()), "ChordThing(60,MINOR,3,0,1) + []", "ChordThings");

        // Test ChordThing mode handling
        tester.testit("ChordThing major mode", new ChordThing(60, Mode.getMajorMode(), 3).get_mode(), Mode.getMajorMode(), "ChordThing.getMode");
        tester.testit("ChordThing minor mode", new ChordThing(60, Mode.getMinorMode(), 3).get_mode(), Mode.getMinorMode(), "ChordThing.getMode");
        tester.testit("ChordThing harmonic minor mode", new ChordThing(60, Mode.getHarmonicMinorMode(), 3).get_mode(), Mode.getHarmonicMinorMode(), "ChordThing.getMode");
        tester.testit("ChordThing melodic minor mode", new ChordThing(60, Mode.getMelodicMinorMode(), 3).get_mode(), Mode.getMelodicMinorMode(), "ChordThing.getMode");
    }    
    
    static function testParser(tester:UnitTester) {
        trace("Testing Parser");

        var cp = new ChordParser(60, Mode.getMajorMode());
        tester.testit("ChordThing Construction basic", cp.parse("1")[0], new ChordThing(60, Mode.getMajorMode(), 1), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("2")[0], new ChordThing(60, Mode.getMajorMode(), 2), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("3")[0], new ChordThing(60, Mode.getMajorMode(), 3), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("4")[0], new ChordThing(60, Mode.getMajorMode(), 4), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("5")[0], new ChordThing(60, Mode.getMajorMode(), 5), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("6")[0], new ChordThing(60, Mode.getMajorMode(), 6), "ChordThing Construction basic");
        tester.testit("ChordThing Construction basic", cp.parse("7")[0], new ChordThing(60, Mode.getMajorMode(), 7), "ChordThing Construction basic");

        tester.testit("ChordThing Construction sevenths", cp.parse("71")[0], new ChordThing(60, Mode.getMajorMode(), 1).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("72")[0], new ChordThing(60, Mode.getMajorMode(), 2).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("73")[0], new ChordThing(60, Mode.getMajorMode(), 3).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("74")[0], new ChordThing(60, Mode.getMajorMode(), 4).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("75")[0], new ChordThing(60, Mode.getMajorMode(), 5).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("76")[0], new ChordThing(60, Mode.getMajorMode(), 6).seventh(), "ChordThing Construction sevenths");
        tester.testit("ChordThing Construction sevenths", cp.parse("77")[0], new ChordThing(60, Mode.getMajorMode(), 7).seventh(), "ChordThing Construction sevenths");

        tester.testit("ChordThing Construction ninths", cp.parse("91")[0], new ChordThing(60, Mode.getMajorMode(), 1).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("92")[0], new ChordThing(60, Mode.getMajorMode(), 2).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("93")[0], new ChordThing(60, Mode.getMajorMode(), 3).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("94")[0], new ChordThing(60, Mode.getMajorMode(), 4).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("95")[0], new ChordThing(60, Mode.getMajorMode(), 5).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("96")[0], new ChordThing(60, Mode.getMajorMode(), 6).ninth(), "ChordThing Construction ninths");
        tester.testit("ChordThing Construction ninths", cp.parse("97")[0], new ChordThing(60, Mode.getMajorMode(), 7).ninth(), "ChordThing Construction ninths");

        // Test sixth chords
        tester.testit("ChordThing Construction sixths", cp.parse("61")[0], new ChordThing(60, Mode.getMajorMode(), 1).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("62")[0], new ChordThing(60, Mode.getMajorMode(), 2).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("63")[0], new ChordThing(60, Mode.getMajorMode(), 3).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("64")[0], new ChordThing(60, Mode.getMajorMode(), 4).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("65")[0], new ChordThing(60, Mode.getMajorMode(), 5).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("66")[0], new ChordThing(60, Mode.getMajorMode(), 6).sixth(), "ChordThing Construction sixths");
        tester.testit("ChordThing Construction sixths", cp.parse("67")[0], new ChordThing(60, Mode.getMajorMode(), 7).sixth(), "ChordThing Construction sixths");

        // Test mutual exclusivity in ChordThing Modifiers
        tester.testit("ChordThing Construction sixth overrides seventh", cp.parse("71")[0].sixth(), cp.parse("61")[0], "ChordThing Construction sixth should override seventh");
        tester.testit("ChordThing Construction sixth overrides ninth", cp.parse("91")[0].sixth(), cp.parse("61")[0], "ChordThing Construction sixth should override ninth");
        tester.testit("ChordThing Construction seventh overrides sixth", cp.parse("61")[0].seventh(), cp.parse("71")[0], "ChordThing Construction seventh should override sixth");
        tester.testit("ChordThing Construction ninth overrides sixth", cp.parse("61")[0].ninth(), cp.parse("91")[0], "ChordThing Construction ninth should override sixth");


        tester.testit("Canonical seventh chord", cp.parse("7:1")[0], new ChordThing(60, Mode.getMajorMode(), 1).seventh(), "Canonical seventh chord syntax");
        tester.testit("Canonical ninth chord", cp.parse("9:4")[0], new ChordThing(60, Mode.getMajorMode(), 4).ninth(), "Canonical ninth chord syntax");
        tester.testit("Canonical eleventh chord", cp.parse("11:1")[0], new ChordThing(60, Mode.getMajorMode(), 1).eleventh(), "Canonical eleventh chord syntax");
        tester.testit("Canonical thirteenth chord", cp.parse("13:5")[0], new ChordThing(60, Mode.getMajorMode(), 5).thirteenth(), "Canonical thirteenth chord syntax");
        tester.testit("Canonical sus2 chord", cp.parse("s2:4")[0], new ChordThing(60, Mode.getMajorMode(), 4).sus2(), "Canonical sus2 chord syntax");
        tester.testit("Canonical sus4 chord", cp.parse("s4:5")[0], new ChordThing(60, Mode.getMajorMode(), 5).sus4(), "Canonical sus4 chord syntax");
        tester.testit("Canonical sus2 long spelling", cp.parse("sus2:4")[0], new ChordThing(60, Mode.getMajorMode(), 4).sus2(), "Canonical sus2 long syntax");
        tester.testit("Canonical sus4 long spelling", cp.parse("sus4:5")[0], new ChordThing(60, Mode.getMajorMode(), 5).sus4(), "Canonical sus4 long syntax");
        tester.testit("Canonical seventh matches legacy shorthand", cp.parse("7:1")[0], cp.parse("71")[0], "Canonical seventh should match compact legacy syntax");
        tester.testit("Canonical ninth matches legacy shorthand", cp.parse("9:4")[0], cp.parse("94")[0], "Canonical ninth should match compact legacy syntax");
        tester.testit("Canonical sixth matches legacy shorthand", cp.parse("6:2")[0], cp.parse("62")[0], "Canonical sixth should match compact legacy syntax");

        tester.testit("Simple chords", cp.parse("1,4,6,5"),
            [new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 4), new ChordThing(60, MAJOR, 6), new ChordThing(60, MAJOR, 5)],
            "ChordParsing simple chords");

        tester.testit("Space-separated simple chords", cp.parse("1 4 6 5"),
            [new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 4), new ChordThing(60, MAJOR, 6), new ChordThing(60, MAJOR, 5)],
            "ChordParsing should accept spaces as separators");

        tester.testit("Repeated separators", cp.parse("  71   94,, 6ii | 5  "),
            [new ChordThing(60, MAJOR, 1).seventh(),
             new ChordThing(60, MAJOR, 4).ninth(),
             new ChordThing(60, MAJOR, 6).set_inversion(2),
             new ChordThing(60, MAJOR, 5)],
            "ChordParsing should ignore repeated comma, pipe, and whitespace separators");

        tester.testit("Extended chords", cp.parse("71,94,6ii,5"),
            [new ChordThing(60, MAJOR, 1).seventh(),
             new ChordThing(60, MAJOR, 4).ninth(),
             new ChordThing(60, MAJOR, 6).set_inversion(2),
             new ChordThing(60, MAJOR, 5)],
            "ChordParsing extended chords");

        tester.testit("Mode specifiers", cp.parse("1,!m,4,!mm,6,!hm,5,!HM,1,!hu,4,!H2,5,!M,1"),
            [new ChordThing(60, Mode.getMajorMode(), 1),
             new ChordThing(60, Mode.getMinorMode(), 4),
             new ChordThing(60, Mode.getMelodicMinorMode(), 6),
             new ChordThing(60, Mode.getHarmonicMinorMode(), 5),
             new ChordThing(60, Mode.getHarmonicMajorMode(), 1),
             new ChordThing(60, Mode.getHungarianMinorMode(), 4),
             new ChordThing(60, Mode.getDoubleHarmonicMajorMode(), 5),
             new ChordThing(60, Mode.getMajorMode(), 1)],
            "ChordParsing mode specifiers");

        // Test bracket mode selection
        tester.testit("Bracket mode selection in major", cp.parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getMajorMode(), 1),
             new ChordThing(60, Mode.constructNthMajorMode(2), 3),
             new ChordThing(60, Mode.constructNthMajorMode(3), 5),
             new ChordThing(60, Mode.constructNthMajorMode(4), 7)],
            "Bracket mode selection in major");

        tester.testit("Bracket mode selection with extensions", cp.parse("1,7(3!2),9(5!3),(7!4)"),
            [new ChordThing(60, Mode.getMajorMode(), 1),
             new ChordThing(60, Mode.constructNthMajorMode(2), 3).seventh(),
             new ChordThing(60, Mode.constructNthMajorMode(3), 5).ninth(),
             new ChordThing(60, Mode.constructNthMajorMode(4), 7)],
            "Bracket mode selection with extensions");

        tester.testit("Bracket mode selection in harmonic minor", new ChordParser(60, Mode.getHarmonicMinorMode()).parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getHarmonicMinorMode(), 1),
             new ChordThing(60, Mode.constructNthHarmonicMinorMode(2), 3),
             new ChordThing(60, Mode.constructNthHarmonicMinorMode(3), 5),
             new ChordThing(60, Mode.constructNthHarmonicMinorMode(4), 7)],
            "Bracket mode selection in harmonic minor");

        tester.testit("Bracket mode selection in melodic minor", new ChordParser(60, Mode.getMelodicMinorMode()).parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getMelodicMinorMode(), 1),
             new ChordThing(60, Mode.constructNthMelodicMinorMode(2), 3),
             new ChordThing(60, Mode.constructNthMelodicMinorMode(3), 5),
             new ChordThing(60, Mode.constructNthMelodicMinorMode(4), 7)],
            "Bracket mode selection in melodic minor");


        tester.testit("Bracket mode selection in harmonic major", new ChordParser(60, Mode.getHarmonicMajorMode()).parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getHarmonicMajorMode(), 1),
             new ChordThing(60, Mode.constructNthHarmonicMajorMode(2), 3),
             new ChordThing(60, Mode.constructNthHarmonicMajorMode(3), 5),
             new ChordThing(60, Mode.constructNthHarmonicMajorMode(4), 7)],
            "Bracket mode selection in harmonic major");

        tester.testit("Bracket mode selection in hungarian minor", new ChordParser(60, Mode.getHungarianMinorMode()).parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getHungarianMinorMode(), 1),
             new ChordThing(60, Mode.constructNthHungarianMinorMode(2), 3),
             new ChordThing(60, Mode.constructNthHungarianMinorMode(3), 5),
             new ChordThing(60, Mode.constructNthHungarianMinorMode(4), 7)],
            "Bracket mode selection in hungarian minor");

        tester.testit("Bracket mode selection in double harmonic major", new ChordParser(60, Mode.getDoubleHarmonicMajorMode()).parse("1,(3!2),(5!3),(7!4)"),
            [new ChordThing(60, Mode.getDoubleHarmonicMajorMode(), 1),
             new ChordThing(60, Mode.constructNthDoubleHarmonicMajorMode(2), 3),
             new ChordThing(60, Mode.constructNthDoubleHarmonicMajorMode(3), 5),
             new ChordThing(60, Mode.constructNthDoubleHarmonicMajorMode(4), 7)],
            "Bracket mode selection in double harmonic major");

        tester.testit("Major Triads", new ChordProgression(60, MAJOR, "1|4|5|6").toNotes(),
            [[60, 64, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
            "Basic major triads");

        tester.testit("Minor Triads", new ChordProgression(60, MINOR, "1|4,5| 6").toNotes(),
            [[60, 63, 67], [65, 68, 72], [67, 70, 74], [68, 72, 75]],
            "Basic minor triads");

        tester.testit("Major Triads with modal interchange", new ChordProgression(60, MAJOR, "-1|4|5|6").toNotes(),
            [[60, 63, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
            "Basic major triads");

        tester.testit("Minor Sevenths", new ChordProgression(60, MINOR, "72,75,71").toNotes(),
            [[62, 65, 68, 72], [67, 70, 74, 77], [60, 63, 67, 70]], "Minor 7ths");

        tester.testit("Chord Inversions",
            new ChordProgression(60, MAJOR, "1|4i").toNotes(),
            [[60, 64, 67], [69, 72, 77]],
            "Chord inversions");

        tester.testit("Chord Inversions with extensions",
            new ChordProgression(60, MAJOR, "4,74,74i,74ii,74iii").toNotes(),
            [[65, 69, 72], [65, 69, 72, 76], [69, 72, 76, 77], [72, 76, 77, 81], [76, 77, 81, 84]],
            "Chord inversions 2");

        tester.testit("Modulate to new key", new ChordProgression(60, MAJOR, "1|4|>2|1|4|<1|1|4").toNotes(),
            [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74], [61, 65, 68], [66, 70, 73]],
            "Modulating basic triads by 2");

        tester.testit("Modulate to new key with spaces", new ChordProgression(60, MAJOR, "1 4 >2 1 4 <1 1 4").toNotes(),
            [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74], [61, 65, 68], [66, 70, 73]],
            "Modulating basic triads by 2 should accept spaces as separators");

        tester.testit("Modulate to new mode", new ChordProgression(60, MAJOR, "1|4|5|7|!m|1|4|5|7").toNotes(),
            new ChordProgression(60, MAJOR, "1|4|5|7|-1|-4|-5|-7").toNotes(),
            "Modulating mode");

        tester.testit("Modulate to new mode with spaces", new ChordProgression(60, MAJOR, "1 4 5 7 !m 1 4 5 7").toNotes(),
            new ChordProgression(60, MAJOR, "1 4 5 7 -1 -4 -5 -7").toNotes(),
            "Modulating mode should accept spaces as separators");

        tester.testit("Secondary chords",
            new ChordProgression(60, MAJOR, "(5/4),4").toChordThings(),
            [new ChordThing(60, MAJOR, 4).set_as_secondary(5),
            new ChordThing(60, MAJOR, 4)],
            "Testing secondary chords");

        tester.testit("Making secondary chords",
            new ChordProgression(60, MAJOR, "(5/2),2,5,1").toNotes(),
            [[69, 73, 76], [62, 65, 69], [67, 71, 74], [60, 64, 67]],
            "Making a secondary (5/2)");

        tester.testit("Making secondary chords with modifiers",
            new ChordProgression(60, MAJOR, "7(5/2),72,75,71").toNotes(),
            [[69, 73, 76, 79], [62, 65, 69, 72], [67, 71, 74, 77], [60, 64, 67, 71]],
            "Making a secondary 7(5/2)");

        tester.testit("Secondary chords compare secondary degree",
            new ChordThing(60, MAJOR, 2).set_as_secondary(5).valueEquals(
                new ChordThing(60, MAJOR, 2).set_as_secondary(6)
            ),
            false,
            "ChordThing equality should distinguish different secondary degrees");
            

        // Test Minor Triad
        tester.testit("Minor Triad A",
            new ChordThing(57, Mode.getMinorMode(), 1).generateChordNotes(),
            [57, 60, 64],
            "Minor triad A not correctly generated.");

        // Test Major Seventh Chord
        tester.testit("Major Seventh C",
            new ChordThing(60, Mode.getMajorMode(), 1).seventh().generateChordNotes(),
            [60, 64, 67, 71],
            "Major seventh C not correctly generated.");

        // Test Minor Seventh Chord
        tester.testit("Minor Seventh A",
            new ChordThing(57, Mode.getMinorMode(), 1).seventh().generateChordNotes(),
            [57, 60, 64, 67],
            "Minor seventh A not correctly generated.");

        tester.testit("Minor Ninth A",
            new ChordThing(57, Mode.getMinorMode(), 1).ninth().generateChordNotes(),
            [57, 60, 64, 67, 71],
            "Minor ninth A not correctly generated.");

        tester.testit("Major Eleventh C",
            new ChordThing(60, Mode.getMajorMode(), 1).eleventh().generateChordNotes(),
            [60, 64, 67, 71, 74, 77],
            "Major eleventh C not correctly generated.");

        tester.testit("Major Thirteenth C",
            new ChordThing(60, Mode.getMajorMode(), 1).thirteenth().generateChordNotes(),
            [60, 64, 67, 71, 74, 77, 81],
            "Major thirteenth C not correctly generated.");

        tester.testit("Sus2 C",
            new ChordThing(60, Mode.getMajorMode(), 1).sus2().generateChordNotes(),
            [60, 62, 67],
            "Sus2 C not correctly generated.");

        tester.testit("Sus4 C",
            new ChordThing(60, Mode.getMajorMode(), 1).sus4().generateChordNotes(),
            [60, 65, 67],
            "Sus4 C not correctly generated.");

        tester.testit("Sus4 seventh C",
            new ChordThing(60, Mode.getMajorMode(), 1).sus4().seventh().generateChordNotes(),
            [60, 65, 67, 71],
            "Sus4 seventh C should replace the third while preserving the seventh.");

        tester.testit("Secondary Dominant of iii chord in C",
            new ChordThing(60, Mode.getMajorMode(), 3).set_as_secondary(5).seventh().generateChordNotes(),
            [71, 75, 78, 81],
            "Secondary dominant of iii in C not correctly generated.");
       

        var progression = new ChordProgression(60, Mode.getMajorMode(), "1,4,6,5");
        tester.testit("A chord progression",
            progression.toNotes(),
            [[60, 64, 67], [65, 69, 72], [69, 72, 76], [67, 71, 74]],
            "Chord progression not generated correctly");     
            
        trace("Testing Voice Leading");
        tester.testit("VOICE_LEADING Parser Test",
            cp.parse("1&6"),
            [new ChordThing(60, MAJOR, 1), new ChordThing(60, MAJOR, 6).set_voice_leading()],
            "Parsing & separator for voice leading");

	    trace("Testing Stutter");
	    // Create a base progression
	    var baseProg1 = new ChordProgression(60, MAJOR, "1,4,6,5");
	    // Create a stuttered version with stutter count 2
	    var stutteredProg = new StutteredChordProgression(baseProg1, 2);
	    // Create a progression with the expected result pattern
	    var prog2 = new ChordProgression(60, MAJOR, "1,4,1,4");
	    var prog3 = new ChordProgression(60, MAJOR, "1,1,1,1");

	    tester.testit("Stutter",
	           stutteredProg.toNotes(),
	           prog2.toNotes(),
	           "stuttering");

	    // Test with stutter count of 1
	    var stutteredProg1 = new StutteredChordProgression(baseProg1, 1);
	    
	    tester.testit("Stutter 2",
	        stutteredProg1.toChordThings(),
	        prog3.toChordThings(),
	        "stuttering 2");
   }

    static function testChordNaming(tester:UnitTester) {
        // Test basic major and minor chords
        var cMajor = new ChordThing(60, Mode.getMajorMode(), 1);
        tester.testit("C Major chord name", cMajor.getChordName(), "C", "Basic C Major chord should be named 'C'");
        
        var aMinor = new ChordThing(60, Mode.getMajorMode(), 6);
        tester.testit("A Minor chord name", aMinor.getChordName(), "Am", "A Minor chord should be named 'Am'");
        
        // Test with modal interchange
        var cMinor = new ChordThing(60, Mode.getMinorMode(), 1);
        tester.testit("C Minor chord name", cMinor.getChordName(), "Cm", "C Minor chord should be named 'Cm'");
        
        // Test with extensions
        var cMaj7 = new ChordThing(60, Mode.getMajorMode(), 1).seventh();
        tester.testit("Cmaj7 chord name", cMaj7.getChordName(), "Cmaj7", "I seventh in C major should be named 'Cmaj7'");

        var g7 = new ChordThing(60, Mode.getMajorMode(), 5).seventh();
        tester.testit("G7 chord name", g7.getChordName(), "G7", "G7 chord should be named 'G7'");
        
        // In C major, the ii chord (D) is minor, so D9 should be Dm9
        var d9 = new ChordThing(60, Mode.getMajorMode(), 2).ninth();
        tester.testit("D9 chord name", d9.getChordName(), "Dm9", "D9 chord in C major should be named 'Dm9'");
        
        var cMaj11 = new ChordThing(60, Mode.getMajorMode(), 1).eleventh();
        tester.testit("Cmaj11 chord name", cMaj11.getChordName(), "Cmaj11", "C major eleventh chord should be named 'Cmaj11'");

        var cMaj13 = new ChordThing(60, Mode.getMajorMode(), 1).thirteenth();
        tester.testit("Cmaj13 chord name", cMaj13.getChordName(), "Cmaj13", "C major thirteenth chord should be named 'Cmaj13'");

        var cSus2 = new ChordThing(60, Mode.getMajorMode(), 1).sus2();
        tester.testit("Csus2 chord name", cSus2.getChordName(), "Csus2", "C sus2 chord should be named 'Csus2'");

        var cSus4 = new ChordThing(60, Mode.getMajorMode(), 1).sus4();
        tester.testit("Csus4 chord name", cSus4.getChordName(), "Csus4", "C sus4 chord should be named 'Csus4'");

        var cSus4Maj7 = new ChordThing(60, Mode.getMajorMode(), 1).sus4().seventh();
        tester.testit("Csus4maj7 chord name", cSus4Maj7.getChordName(), "Csus4maj7", "C sus4 major seventh chord should be named 'Csus4maj7'");

        // Test with inversions
        var fInv1 = new ChordThing(60, Mode.getMajorMode(), 4).set_inversion(1);
        tester.testit("F/A chord name", fInv1.getChordName(), "F/A", "F with first inversion should be named 'F/A'");
        
        var gInv2 = new ChordThing(60, Mode.getMajorMode(), 5).set_inversion(2);
        tester.testit("G/D chord name", gInv2.getChordName(), "G/D", "G with second inversion should be named 'G/D'");
        
        // Test with secondary chords
        // In C major, when we set the 3rd degree (E) as a secondary chord targeting the 6th degree (A),
        // ChordThing Construction.calculateSecondaryChord creates a new chord in A major with degree 3, which is C#m
        var secondaryChord = new ChordThing(60, Mode.getMajorMode(), 3).seventh().set_as_secondary(6);
        tester.testit("Secondary chord name", secondaryChord.getChordName(), "C#m7", 
               "Secondary chord should be named based on the chord created by ChordThing Construction.calculateSecondaryChord");
        
        // Test with different keys
        var fSharpMinor = new ChordThing(66, Mode.getMinorMode(), 1);
        tester.testit("F# Minor chord name", fSharpMinor.getChordName(), "F#m", "F# Minor chord should be named 'F#m'");
        
        // Test with complex combinations - in C major, the ii chord (D) with 7th and first inversion
        var complex = new ChordThing(60, Mode.getMajorMode(), 2).seventh().set_inversion(1);
        tester.testit("D7/F chord name", complex.getChordName(), "Dm7/F", "Dm7 with first inversion should be named 'Dm7/F'");

        var lydianSharpFour = new ChordThing(60, Mode.getLydianMode(), 4);
        tester.testit("Lydian #iv chord name", lydianSharpFour.getChordName(), "F#dim", "C Lydian degree 4 should be named from the Lydian root");

        var harmonicMinorLeadingTone = new ChordThing(60, Mode.getHarmonicMinorMode(), 7);
        tester.testit("Harmonic minor leading-tone chord name", harmonicMinorLeadingTone.getChordName(), "Bdim", "C harmonic minor degree 7 should use the raised leading tone");

        var melodicMinorSixth = new ChordThing(60, Mode.getMelodicMinorMode(), 6);
        tester.testit("Melodic minor sixth chord name", melodicMinorSixth.getChordName(), "Adim", "C melodic minor degree 6 should use the raised sixth and seventh scale");
    }
    
    static function testChordProgressionNaming(tester:UnitTester) {
        // Test a simple progression
        var progression = new ChordProgression(60, Mode.getMajorMode(), "1,4,5,1");
        var expectedNames = ["C", "F", "G", "C"];
        tester.testit("Simple progression names", progression.getChordNames(), expectedNames, "Simple progression should have correct names");
        
        // Test a more complex progression
        var complexProg = new ChordProgression(60, Mode.getMajorMode(), "1,4,5,1i,6,2,5,1");
        var expectedComplexNames = ["C", "F", "G", "C/E", "Am", "Dm", "G", "C"];
        tester.testit("Complex progression names", complexProg.getChordNames(), expectedComplexNames, "Complex progression should have correct names");
        
        // Test with modal interchange and secondary chords
        // In C major:
        // 1 = C
        // -4 = Fm (modal interchange)
        // (5/2) = A7 (V7 of ii, which is Dm)
        // This is the correct interpretation: (5/2) means the 5 chord in the key of the 2nd degree
        var jazzProg = new ChordProgression(60, Mode.getMajorMode(), "1,-4,(5/2),1");
        var expectedJazzNames = ["C", "Fm", "A", "C"];
        tester.testit("Jazz progression names", jazzProg.getChordNames(), expectedJazzNames, "Jazz progression should have correct names");

        var modalProg = new ChordProgression(60, Mode.getMajorMode(), "7(6!4),7(2!4),7(5!4),7(1!4)");
        var expectedModalNames = ["Am7", "D7", "Gmaj7", "Cmaj7"];
        tester.testit("Modal progression names", modalProg.getChordNames(), expectedModalNames, "Modal chord names should use the selected bracket mode");
    }
    
    static function testGoldenData(tester:UnitTester) {
        trace("Testing GoldenData");
        
        // Create a GoldenData object
        var goldenData = new GoldenData();
        
        // Add some lines
        goldenData.addLine("1,2,3", new MidiInstrumentContext(0, 100, 0.8, 0))
                 .addLine("4,5,6", new MidiInstrumentContext(1, 100, 0.8, 0));
        
        // Test serialization
        var json = goldenData.toJSON();
        tester.testit("GoldenData JSON serialization",
            json != null && json.length > 0,
            true,
            "JSON should not be null or empty");
            
        // Test deserialization
        var deserialized = GoldenData.makeFromJSON(json, new DeserializationHelper());
        tester.testit("GoldenData JSON deserialization",
            deserialized != null && deserialized.lines.length == 2,
            true,
            "Deserialized object should not be null and should have 2 lines");
            
        // Test that the data matches
        tester.testit("GoldenData root", deserialized.root == goldenData.root, true, "Root should match");
        tester.testit("GoldenData mode", deserialized.mode == goldenData.mode, true, "Mode should match");
        tester.testit("GoldenData chord sequence", deserialized.chordSequence == goldenData.chordSequence, true, "Chord sequence should match");
        tester.testit("GoldenData stutter", deserialized.stutter == goldenData.stutter, true, "Stutter should match");
        tester.testit("GoldenData bpm", deserialized.bpm == goldenData.bpm, true, "BPM should match");
        tester.testit("GoldenData chord duration", deserialized.chordDuration == goldenData.chordDuration, true, "Chord duration should match");
        
        // Test that the lines match
        for (i in 0...2) {
            tester.testit("GoldenData line pattern", deserialized.lines[i].pattern == goldenData.lines[i].pattern, true, "Line pattern should match");
            tester.testit("GoldenData instrument context code", deserialized.lines[i].instrumentContext.getCode() == goldenData.lines[i].instrumentContext.getCode(), true, "Instrument context code should match");
        }
        
        // Test that the reconstructed data generates the same progression
        var reconstructedProgression = deserialized.makeChordProgression();
        tester.testit("GoldenData reconstructed progression",
            reconstructedProgression.toNotes(),
            goldenData.makeChordProgression().toNotes(),
            "Reconstructed progression should match original");
            
        // Test toString output
        var summary = goldenData.toString();
        var modeNames = ["major", "minor", "harmonic minor", "melodic minor", "harmonic major", "hungarian minor", "double harmonic major"];
        var modeName = modeNames[goldenData.mode];
        
        tester.testit("GoldenData toString",
            summary.indexOf("GoldenPond Project") >= 0 &&
            summary.indexOf("Root: " + goldenData.root) >= 0 &&
            summary.indexOf("Mode: " + modeName + " (" + goldenData.mode + ")") >= 0 &&
            summary.indexOf("BPM: " + goldenData.bpm) >= 0,
            true,
            "toString should contain expected information");
            
        var harmonicMajorData = new GoldenData();
        harmonicMajorData.mode = 4;
        tester.testit("GoldenData harmonic major mode mapping", harmonicMajorData.makeMode().intervals, Mode.getHarmonicMajorMode().intervals, "GoldenData should map mode 4 to harmonic major");

        var hungarianMinorData = new GoldenData();
        hungarianMinorData.mode = 5;
        tester.testit("GoldenData hungarian minor mode mapping", hungarianMinorData.makeMode().intervals, Mode.getHungarianMinorMode().intervals, "GoldenData should map mode 5 to hungarian minor");

        var doubleHarmonicMajorData = new GoldenData();
        doubleHarmonicMajorData.mode = 6;
        tester.testit("GoldenData double harmonic major mode mapping", doubleHarmonicMajorData.makeMode().intervals, Mode.getDoubleHarmonicMajorMode().intervals, "GoldenData should map mode 6 to double harmonic major");

        // Test PPQ functionality
        trace("Testing GoldenData PPQ");
        var goldenDataWithPPQ = new GoldenData();
        
        // Test the new setPPQ method
        goldenDataWithPPQ.setPPQ(480);
        tester.testit("GoldenData setPPQ", goldenDataWithPPQ.ppq, 480, "setPPQ should update the ppq value");

        // Test that makeTimeManipulator uses the new ppq
        var timeManipulator = goldenDataWithPPQ.makeTimeManipulator();
        tester.testit("GoldenData makeTimeManipulator uses custom PPQ", timeManipulator.ppq, 480, "makeTimeManipulator should use the ppq from GoldenData");

        // Test serialization and deserialization of ppq
        var jsonWithPPQ = goldenDataWithPPQ.toJSON();
        var deserializedWithPPQ = GoldenData.makeFromJSON(jsonWithPPQ, new DeserializationHelper());
        tester.testit("GoldenData JSON deserialization with PPQ", deserializedWithPPQ.ppq, 480, "Deserialized object should have the correct ppq value");
    }
    
    static function testCorrections(tester:UnitTester) {
        trace("--- Testing GoldenData Note Correction ---");

        // Setup: C Major progression, 4 beats/chord, 960 PPQ
        var data = new GoldenData();
        data.setPPQ(960); // Assumes the ppq change is implemented
        data.chordSequence = "1,6"; // Cmaj (I), Amin (vi)
        data.chordDuration = 4; // 4 beats = 3840 ticks per chord

        // Test 1: Simple correction in the first chord (C Major scale)
        var noteIn1 = 61; // C#
        var time1 = 100;  // During the first chord (Cmaj)
        var corrected1 = data.correct(noteIn1, time1);
        tester.testit("Correction: C# to C in Cmaj", corrected1, 60, "Should correct C# down to C");

        // Test 2: Correction in the second chord (A Minor scale)
        var noteIn2 = 75; // D#5
        var time2 = 4000; // During the second chord (Amin)
        var corrected2 = data.correct(noteIn2, time2);
        tester.testit("Correction: D#5 to D5 in Amin", corrected2, 74, "Should correct D#5 to D5 (closest note in A minor)");

        // Test 3: Melodic Minor (Ascending)
        // A Melodic Minor scale: A(69), B(71), C(72), D(74), E(76), F#(78), G#(80)
        data.root = 69; // A
        data.mode = 3;  // Melodic Minor
        data.chordSequence = "1";
        var noteIn3 = 77; // F5, which is the flat 6th
        var corrected3 = data.correct(noteIn3, 100, 76); // Ascending from E5(76)
        tester.testit("Correction: Melodic Minor Ascending", corrected3, 78, "Should correct F5 up to F#5 (the raised 6th)");

        // Test 4: Melodic Minor (Descending)
        // Should use A Natural Minor scale: A(69), B(71), C(72), D(74), E(76), F(77), G(79)
        var noteIn4 = 78; // F# (the raised 6th)
        var corrected4 = data.correct(noteIn4, 100, 80); // Descending from G#(80)
        tester.testit("Correction: Melodic Minor Descending", corrected4, 77, "Should correct F# down to F (the natural 6th)");
    }
   
}
