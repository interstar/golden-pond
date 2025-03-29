import UnitTester;

import Mode;
import ChordThing;
import ChordParser;
import ScoreUtilities;
import TimedSequence;
import RhythmGenerator;  

class TestSuite2 {

    public static function allTests(tester:UnitTester) {
        testMenuHelper(tester);
        testTimeManipulator(tester);
        testRhythmGenerator(tester);
        testDeltaEvents(tester);
        testTimeEventGeneration(tester);
        testChordTimings(tester);
        testRhythmGeneratorK1(tester);
        testTimeEventsForK1(tester);
        testNotesInSeconds(tester);
        testRhythmPatternParser(tester);
        testRhythmLanguage(tester);
        testBjorklundPatterns(tester);
        testLineGeneratorWithRhythmGenerator(tester);
    }

    static function testMenuHelper(tester:UnitTester) {
	  trace("Testing Menu Helper");
	  tester.testit("Division names",
		 MenuHelper.getDivisionNames(),
		 ["1/16", "1/12", "1/8", "1/6", "1/4", "1/3", "1/2", "1"],
		 "Division names");
	  tester.testit("Division Values",
		 MenuHelper.getDivisionValues(),
		 [SIXTEENTH,TWELFTH,EIGHTH,SIXTH,QUARTER,THIRD,HALF,WHOLE],
		 "Division Values");
	  
	  tester.testit("Division Opt 1", MenuHelper.getDivisionFor(0), SIXTEENTH,"division 1");
	  tester.testit("Division Opt 5", MenuHelper.getDivisionFor(4), QUARTER, "division 5");
	  tester.testit("DivisionValue to numeric",
		 MenuHelper.divisionValue2Numeric(EIGHTH),
		 1/8,
		 "division value EIGHTH to numeric 1/8");
	}
	
    static function testTimeManipulator(tester:UnitTester) {
		trace("Testing Line Generators\n");

		// Configure TimeManipulator like test_goldenpond.py
		var ti = new TimeManipulator();
		ti.setPPQ(960)
		  .setChordDuration(8)
		  .setBPM(120);

		// Create chord progression
		var seq = new ChordProgression(50, MAJOR, "76,72,!m,75,71");

		// Get rhythmic density values
		var density1 = MenuHelper.rhythmicDensityToNumeric(ONE);
		var density2 = MenuHelper.rhythmicDensityToNumeric(TWO);
		var density4 = MenuHelper.rhythmicDensityToNumeric(FOUR);

		// Test ChordLine - now using explicit RhythmGenerator
		var chordRhythm = new SimpleRhythmGenerator(5, 8, FullChord, 1, 0);
		var chord_line = LineGenerator.create(ti, seq, chordRhythm, 0.8).generateNotes(0, 0, 64);
		tester.testit("ChordLine first five chords",
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
		tester.testit("BassLine first twenty notes",
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
		tester.testit("TopLine first twenty notes",
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
		tester.testit("ArpLine first twenty notes",
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

		tester.testit("RandomLine timing pattern",
			timings.slice(0, 5),  // First pattern of 5 hits
			[0, 480, 720, 1200, 1440],  // Changed from floats to integers
			"Random line should follow 5/8 Euclidean rhythm"
		);

		// Test note properties
		for (note in rand_line.slice(0, 20)) {
			// All notes should be from current chord
			var chordIndex = Math.floor(note.startTime / (ti.chordTicks));
			var currentChord = seq.toNotes()[chordIndex];
			tester.testit("RandomLine note in chord",
				currentChord.contains(note.note),
				true,
				'Note ${note.note} should be in chord at time ${note.startTime}'
			);

			// Note length should be consistent
			tester.testit("RandomLine note length",
				note.length,
				120.0,  // 0.5 * step size for density4
				"Note length should be consistent"
			);

			// Channel and velocity should be consistent
			tester.testit("RandomLine note properties",
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
		tester.testit("ChordLine transposition",
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
        tester.testit("Mixed Pattern 1.>.>.=<",
        mixed.getSteps(),
        [SpecificNote(1), Rest, Ascending, Rest, Ascending, Rest, Repeat, Descending],
        "Should parse mixed pattern"
        );
        var line = LineGenerator.create(ti, seq, mixed, 0.8);
        var notes = line.generateNotes(0, 0, 64);
        tester.testit("Mixed Line first 5 notes",
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

    static function testRhythmGenerator(tester:UnitTester) {
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
        
        tester.testit("RhythmGenerator 3 in 8 hit count", 
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
        
        tester.testit("RhythmGenerator pattern repeat", 
               pattern,
               secondPattern, 
               "RhythmGenerator should repeat the same pattern");
               
        tester.testit("RhythmGenerator second pattern hit count",
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
        
        tester.testit("RhythmGenerator 4 in 8", 
               testPattern(4, 8),
               4,
               "4 in 8 pattern should have 4 hits");
               
        tester.testit("RhythmGenerator 2 in 8",
               testPattern(2, 8),
               2,
               "2 in 8 pattern should have 2 hits");
    }

    static function testDeltaEvents(tester:UnitTester) {
        var startCount = tester.getTestCount();
        
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);
        var seq = new ChordProgression(60, MAJOR, "1,4,5");
        
        var chordRhythm1 = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var chordRhythm2 = new SimpleRhythmGenerator(2, 4, FullChord, 1, 0);
        var chordLine1 = LineGenerator.create(ti, seq, chordRhythm1, 0.8);
        var chordLine2 = LineGenerator.create(ti, seq, chordRhythm2, 0.8);
        var deltas1 = chordLine1.asDeltaEvents();
        var deltas2 = chordLine2.asDeltaEvents();

        tester.testit("k=1 first chord timing",
            deltas1.slice(0, 6).map(d -> d.deltaFromLast),
            [0.0, 0.0, 0.0, 76.8, 0.0, 0.0],
            "k=1 first chord should have correct note timings"
        );

        tester.testit("k=2 first chord timing",
            deltas2.slice(0, 6).map(d -> d.deltaFromLast),
            [0.0, 0.0, 0.0, 76.8, 0.0, 0.0],
            "k=2 first chord should have correct note timings"
        );

        tester.testit("k=1 vs k=2 chord spacing",
            [deltas1[6].deltaFromLast, deltas2[6].deltaFromLast],
            [307.2, 115.2],
            "k=1 and k=2 should have different spacing between events"
        );
    }

    static function testTimeEventGeneration(tester:UnitTester) {
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
        tester.testit("Time event count", 
            timeEvents.length, 
            6,  // 3 note-ons + 3 note-offs
            "Should generate ON and OFF events for each note"
        );
        
        // Test event times
        tester.testit("Note-on times",
            timeEvents.filter(te -> te.event.type == NOTE_ON).map(te -> te.time),
            [0.0, 0.0, 0.0],
            "All notes should start at time 0"
        );
        
        tester.testit("Note-off times",
            timeEvents.filter(te -> te.event.type == NOTE_OFF).map(te -> te.time),
            [76.8, 76.8, 76.8],
            "All notes should end at time 76.8"
        );
        
        // Test sorting
        var sorted = line.sortTimeEvents(timeEvents);
        tester.testit("Sorted event order",
            sorted.map(te -> te.event.type),
            [NOTE_ON, NOTE_ON, NOTE_ON, NOTE_OFF, NOTE_OFF, NOTE_OFF],
            "Should group ONs and OFFs together"
        );
    }

    static function testChordTimings(tester:UnitTester) {
        trace("\n=== Testing Chord Timings ===");
        var startCount = tester.getTestCount();
        
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
        tester.testit("k=1 first two chords deltas",
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
        tester.testit("k=2 first two chords deltas",
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
        
        trace('Chord Timings: ${tester.getTestCount() - startCount} tests run\n');
    }

    static function testRhythmGeneratorK1(tester:UnitTester) {
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
        tester.testit("k=1 first pattern",
            actualPattern.slice(0,4),
            expectedPattern,
            'k=1 first pattern should be [Ascending, Rest, Rest, Rest]'
        );
        
        // Check pattern repeats
        tester.testit("k=1 second pattern",
            actualPattern.slice(4,8),
            expectedPattern,
            'k=1 second pattern should be [Ascending, Rest, Rest, Rest]'
        );
        
        // Count total hits
        var totalHits = Lambda.count(actualPattern, x -> x == Ascending);
        tester.testit("k=1 total hits",
            totalHits,
            2,
            'k=1 should have exactly one hit per pattern'
        );
    }

    static function testTimeEventsForK1(tester:UnitTester) {
        var ti = new TimeManipulator().setPPQ(96).setChordDuration(4);
        var seq = new ChordProgression(60, MAJOR, "1,4");
        var chordRhythm = new SimpleRhythmGenerator(1, 4, FullChord, 1, 0);
        var chordLine = LineGenerator.create(ti, seq, chordRhythm, 0.8);
        
        var notes = chordLine.generateNotes(0, 0, 100);
        
        var timeEvents = chordLine.notesToTimeEvents(notes);
        timeEvents = chordLine.sortTimeEvents(timeEvents);
        
        // Test first chord's events (should be 6 events - 3 note-ons and 3 note-offs)
        tester.testit("k=1 first chord time events",
            timeEvents.slice(0, 6).map(te -> { 
                time: tester.floatEqual(te.time, 0.0) ? 0.0 : tester.floatEqual(te.time, 76.8) ? 76.8 : te.time, 
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
        tester.testit("k=1 second chord time events",
            timeEvents.slice(6, 12).map(te -> { 
                time: tester.floatEqual(te.time, 384.0) ? 384.0 : tester.floatEqual(te.time, 460.8) ? 460.8 : te.time, 
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

    static function testNotesInSeconds(tester:UnitTester) {
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
        tester.testit("Notes count", tickNotes.length, secondNotes.length, "Should have same number of notes");
        
        // At 120 BPM, one tick = 60/(120*96) seconds
        var secondsPerTick = 60.0 / (120.0 * 96.0);
        
        for (i in 0...tickNotes.length) {
            var tickNote = tickNotes[i];
            var secondNote = secondNotes[i];
            
            // Test each property individually
            tester.testit('Note ${i} pitch', tickNote.note, secondNote.note, "Note pitch should match");
            tester.testit('Note ${i} channel', tickNote.chan, secondNote.chan, "Channel should match");
            tester.testit('Note ${i} velocity', tickNote.velocity, secondNote.velocity, "Velocity should match");
            
            // Test time values with explicit float comparison
            var expectedStartTime = tickNote.startTime * secondsPerTick;
            var expectedLength = tickNote.length * secondsPerTick;
            
            tester.testit('Note ${i} start time', 
                tester.floatEqual(expectedStartTime, secondNote.startTime), 
                true,
                'Start time should be ${expectedStartTime}'
            );
            
            tester.testit('Note ${i} length', 
                tester.floatEqual(expectedLength, secondNote.length), 
                true,
                'Length should be ${expectedLength}'
            );
        }
        
        trace("testNotesInSeconds completed.");
    }

    static function testRhythmPatternParser(tester:UnitTester) {
        trace("\n=== Testing Rhythm Pattern Parser ===");
        var startCount = tester.getTestCount();
        
        // Test Euclidean pattern parsing
        var euclidean1 = RhythmLanguage.parse("3/8 > 4");
        tester.testit("Euclidean pattern 3/8 > 4",
            !euclidean1.parseFailed(),
            true,
            "Should parse valid Euclidean pattern"
        );
        
        var euclidean2 = RhythmLanguage.parse("3/8+2 > 4");
        tester.testit("Euclidean pattern with offset",
            !euclidean2.parseFailed(),
            true,
            "Should parse Euclidean pattern with offset"
        );
        
        var bjorklund = RhythmLanguage.parse("3%8 > 4");
        tester.testit("Bjorklund pattern",
            !bjorklund.parseFailed(),
            true,
            "Should parse Bjorklund pattern"
        );
        
        // Test explicit pattern parsing
        var explicit1 = RhythmLanguage.parse("1.1. 8");
        tester.testit("Explicit pattern 1.1. 8",
            !explicit1.parseFailed(),
            true,
            "Should parse valid explicit pattern"
        );
        
        var explicit2 = RhythmLanguage.parse(">.>.=.>. 4");
        tester.testit("Explicit pattern with special selectors",
            !explicit2.parseFailed(),
            true,
            "Should parse valid explicit pattern"
        );
        
        // Test invalid patterns
        var invalid1 = RhythmLanguage.parse("abc");
        tester.testit("Invalid pattern 'abc'",
            invalid1.parseFailed(),
            true,
            "Should return ParseFailedRhythmGenerator for invalid pattern"
        );
        
        var invalid2 = RhythmLanguage.parse("3/0 > 4");
        tester.testit("Invalid pattern '3/0 > 4'",
            invalid2.parseFailed(),
            true,
            "Should return ParseFailedRhythmGenerator for invalid pattern with zero denominator"
        );
        
        trace('Rhythm Pattern Parser: ${tester.getTestCount() - startCount} tests run\n');


    }

    static function testRhythmLanguage(tester:UnitTester) {
        trace("\n=== Testing Rhythm Language ===");
        var startCount = tester.getTestCount();
        
        // Test SimpleRhythmGenerator creation
        var simple = RhythmLanguage.makeRhythmGenerator("3/8 > 4");
        tester.testit("SimpleRhythmGenerator from string",
            !simple.parseFailed() && Std.isOfType(simple, SimpleRhythmGenerator),
            true,
            "Should create SimpleRhythmGenerator from string pattern"
        );
        
        // Test BjorklundRhythmGenerator creation
        var bjorklund = RhythmLanguage.makeRhythmGenerator("3%8 > 4");
        tester.testit("BjorklundRhythmGenerator from string",
            !bjorklund.parseFailed() && Std.isOfType(bjorklund, BjorklundRhythmGenerator),
            true,
            "Should create BjorklundRhythmGenerator from string pattern"
        );
        
        // Test ExplicitRhythmGenerator creation
        var explicit = RhythmLanguage.makeRhythmGenerator(">.>.=.>. 4");
        tester.testit("ExplicitRhythmGenerator from string",
            !explicit.parseFailed() && Std.isOfType(explicit, ExplicitRhythmGenerator),
            true,
            "Should create ExplicitRhythmGenerator from string pattern"
        );
        
        // Test pattern with offset
        var withOffset = RhythmLanguage.makeRhythmGenerator("3/8+2 > 4");
        tester.testit("Pattern with offset",
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
            tester.testit('Explicit pattern "${pattern}"',
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
            tester.testit('Invalid pattern "${pattern}" returns ParseFailedRhythmGenerator',
                generator.parseFailed() && Std.isOfType(generator, ParseFailedRhythmGenerator),
                true,
                'Should return ParseFailedRhythmGenerator for invalid pattern "${pattern}"'
            );
            
            tester.testit('Invalid pattern "${pattern}" has parseFailed=true',
                generator.parseFailed(),
                true,
                'ParseFailedRhythmGenerator should have parseFailed=true'
            );
        }
        
        // Test that normal generators have parseFailed=false
        tester.testit('Normal generator has parseFailed=false',
            !simple.parseFailed(),
            true,
            'Normal rhythm generators should have parseFailed=false'
        );
        
        trace('Rhythm Language: ${tester.getTestCount() - startCount} tests run\n');
    }

    static function testBjorklundPattern(tester:UnitTester, k:Int, n:Int, expected:Array<SelectorType>, name:String, offset:Int = 0) {
        var generator = new BjorklundRhythmGenerator(k, n, Ascending, 1, offset);
        var pattern = [];
        
        // Get the pattern
        for (i in 0...n) {
            pattern.push(generator.next());
        }
        
        tester.testit('Bjorklund E(${k},${n})${offset > 0 ? "+"+offset : ""} - ${name}',
            pattern,
            expected,
            'Should generate correct ${name} pattern'
        );
    }

    static function testBjorklundPatterns(tester:UnitTester) {
        // Common patterns from the literature, now using SelectorType
        var hit = Ascending;  // Using Ascending as our "hit" marker
        var rest = Rest;      // Using Rest as our "rest" marker
        
        // Test the Cuban tresillo pattern (3/8)
        testBjorklundPattern(tester,3, 8, [hit,rest,rest,hit,rest,rest,hit,rest], "Cuban tresillo");
        
        // E(3,8) with offset 1 = [0,1,0,0,1,0,0,1]
        testBjorklundPattern(tester,3, 8, [rest,hit,rest,rest,hit,rest,rest,hit], "Cuban tresillo", 1);
        
        // Test with different offset
        testBjorklundPattern(tester,3, 8, [hit,rest,hit,rest,rest,hit,rest,rest], "Cuban tresillo", 2);
        
        // Test the Cuban cinquillo pattern (5/8)
        testBjorklundPattern(tester,5, 8, [hit,rest,hit,hit,rest,hit,hit,rest], "Cuban cinquillo");
        
        // Test the Persian Khafif-e-ramal pattern (2/5)
        testBjorklundPattern(tester,2, 5, [hit,rest,hit,rest,rest], "Persian Khafif-e-ramal");
        
        // Test the Cumbia pattern (3/4) with offset 2 to get the expected pattern
        testBjorklundPattern(tester,3, 4, [hit,rest,hit,hit], "Cumbia", 2);
        
        // Test the Ruchenitza pattern (4/7)
        testBjorklundPattern(tester,4, 7, [hit,rest,hit,rest,hit,rest,hit], "Ruchenitza");
        
        // Test the Agsag-Samai pattern (5/9)
        testBjorklundPattern(tester,5, 9, [hit,rest,hit,rest,hit,rest,hit,rest,hit], "Agsag-Samai");
        
        // Test the Money pattern (3/7)
        testBjorklundPattern(tester,3, 7, [hit,rest,hit,rest,hit,rest,rest], "Money");
        
        // Bjorklund 6%8 pattern with offset 3 to get the expected pattern
        testBjorklundPattern(tester,6, 8, [hit,hit,hit,rest,hit,hit,hit,rest], "Bjorklund 6%8");
        
        // Test the Bossa-Nova pattern (5/16)
        testBjorklundPattern(tester,5, 16, [hit,rest,rest,hit,rest,rest,hit,rest,rest,hit,rest,rest,hit,rest,rest,rest], "Bossa-Nova");
    }

    static function testLineGeneratorWithRhythmGenerator(tester:UnitTester) {
        trace("\n=== Testing LineGenerator with RhythmGenerator ===");
        var startCount = tester.getTestCount();
        
        var ti = new TimeManipulator();
        ti.setPPQ(960).setChordDuration(8).setBPM(120);
        
        var seq = new ChordProgression(50, MAJOR, "76,72,!m,75,71");
        
        // Test creating LineGenerator with SimpleRhythmGenerator
        var simpleRhythm = new SimpleRhythmGenerator(3, 8, FullChord, 1, 0);
        var line1 = LineGenerator.create(ti, seq, simpleRhythm, 0.8);
        var notes1 = line1.generateNotes(0, 0, 100);
        
        tester.testit("LineGenerator with SimpleRhythmGenerator",
            notes1.length > 0,
            true,
            "Should generate notes with SimpleRhythmGenerator"
        );
        
        // Test creating LineGenerator with BjorklundRhythmGenerator
        var bjorklundRhythm = new BjorklundRhythmGenerator(3, 8, FullChord, 1, 0);
        var line2 = LineGenerator.create(ti, seq, bjorklundRhythm, 0.8);
        var notes2 = line2.generateNotes(0, 0, 100);
        
        tester.testit("LineGenerator with BjorklundRhythmGenerator",
            notes2.length > 0,
            true,
            "Should generate notes with BjorklundRhythmGenerator"
        );
        
        // Test creating LineGenerator with ExplicitRhythmGenerator
        var explicitRhythm = new ExplicitRhythmGenerator([FullChord, Rest, FullChord, Rest, FullChord], 1);
        var line3 = LineGenerator.create(ti, seq, explicitRhythm, 0.8);
        var notes3 = line3.generateNotes(0, 0, 100);
        
        tester.testit("LineGenerator with ExplicitRhythmGenerator",
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
            tester.testit('LineGenerator from pattern "${pattern}"',
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
        tester.testit("LineGenerator from invalid pattern throws exception",
            exceptionThrown,
            true,
            "Should throw exception for invalid pattern"
        );
        
        trace('LineGenerator with RhythmGenerator: ${tester.getTestCount() - startCount} tests run\n');
    }



    static function testScaleBasedNoteSelection(tester:UnitTester) {
        trace("\n=== Testing Scale-Based Note Selection ===");
        var startCount = tester.getTestCount();
        
        var ti = new TimeManipulator();
        ti.setPPQ(960).setChordDuration(8).setBPM(120);
        
        // Create a simple chord progression in C major
        var seq = new ChordProgression(60, MAJOR, "1,4,5,1");
        
        // Test RandomFromScale selector
        var randomScaleRhythm = new SimpleRhythmGenerator(1, 4, RandomFromScale, 1, 0);
        var randomScaleLine = LineGenerator.create(ti, seq, randomScaleRhythm, 0.8);
        var randomScaleNotes = randomScaleLine.generateNotes(0, 0, 100);
        
        tester.testit("RandomFromScale selector note in scale",
            randomScaleNotes[0].note >= 60 && randomScaleNotes[0].note <= 71,
            true,
            "Random scale note should be within C major scale"
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
    
    
	
	
}
