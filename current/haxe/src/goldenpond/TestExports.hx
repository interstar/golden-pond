package;

import Exports;
import GoldenData;
import TimedSequence;

class TestExports {
    public static function allTests(tester:UnitTester):Void {
        testSingleLineLiteralExport(tester);
        testMultipleLinesExportAsThreads(tester);
        testLiveLoopsArePaddedToSameLength(tester);
    }

    private static function testSingleLineLiteralExport(tester:UnitTester):Void {
        var data = new GoldenData();
        data.root = 60;
        data.mode = 0;
        data.bpm = 120;
        data.chordDuration = 1;
        data.ppq = 960;
        data.chordSequence = "1";
        data.lines = [];
        data.addLine("11 1", new MidiInstrumentContext(0, 100, 1.0, 0));

        var expected = 'use_bpm 120\n'
            + '\n'
            + 'live_loop :goldenpond_line_1 do\n'
            + '  use_synth :rodeo\n'
            + '  play 60, release: 0.5\n'
            + '  sleep 0.5\n'
            + '  play 60, release: 0.5\n'
            + '  sleep 0.5\n'
            + 'end\n';

        tester.testit("Exports single line literal", Exports.exportToSonicPi(data), expected, "Single line export should use literal play/sleep output");
    }

    private static function testMultipleLinesExportAsThreads(tester:UnitTester):Void {
        var data = new GoldenData();
        data.root = 60;
        data.mode = 0;
        data.bpm = 90;
        data.chordDuration = 1;
        data.ppq = 960;
        data.chordSequence = "1";
        data.lines = [];
        data.addLine("1 1", new MidiInstrumentContext(0, 100, 1.0, 0));
        data.addLine("1 1", new MidiInstrumentContext(1, 100, 1.0, 12));

        var expected = 'use_bpm 90\n'
            + '\n'
            + 'live_loop :goldenpond_line_1 do\n'
            + '  use_synth :rodeo\n'
            + '  play 60, release: 1\n'
            + '  sleep 1\n'
            + 'end\n'
            + '\n'
            + 'live_loop :goldenpond_line_2 do\n'
            + '  use_synth :pluck\n'
            + '  play 72, release: 1\n'
            + '  sleep 1\n'
            + 'end\n';

        tester.testit("Exports multiple lines threads", Exports.exportToSonicPi(data), expected, "Each active line should export to its own in_thread block");
    }

    private static function testLiveLoopsArePaddedToSameLength(tester:UnitTester):Void {
        var data = new GoldenData();
        data.root = 60;
        data.mode = 0;
        data.bpm = 120;
        data.chordDuration = 2;
        data.ppq = 960;
        data.chordSequence = "1";
        data.lines = [];
        data.addLine("1/1 1 1", new MidiInstrumentContext(0, 100, 1.0, 0));
        data.addLine("1/2 1 1", new MidiInstrumentContext(1, 100, 1.0, 12));

        var expected = 'use_bpm 120\n'
            + '\n'
            + 'live_loop :goldenpond_line_1 do\n'
            + '  use_synth :rodeo\n'
            + '  play 60, release: 2\n'
            + '  sleep 2\n'
            + 'end\n'
            + '\n'
            + 'live_loop :goldenpond_line_2 do\n'
            + '  use_synth :pluck\n'
            + '  play 72, release: 1\n'
            + '  sleep 2\n'
            + 'end\n';

        tester.testit("Exports live loops padded", Exports.exportToSonicPi(data), expected, "Shorter live loops should be padded to the full project duration");
    }
}
