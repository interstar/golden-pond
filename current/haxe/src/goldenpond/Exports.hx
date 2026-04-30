package;

import GoldenData;
import ScoreUtilities;
import TimedSequence;

typedef SonicPiEvent = {
    var startTime:Float;
    var notes:Array<INote>;
}

typedef SonicPiLineData = {
    var lineIndex:Int;
    var events:Array<SonicPiEvent>;
}

@:expose
class Exports {
    private static inline var FLOAT_EPSILON:Float = 0.0001;
    private static var DEFAULT_SYNTHS = [":rodeo", ":pluck", ":bass_foundation", ":tri", ":growl"];

    @:expose
    public static function exportToSonicPi(data:GoldenData):String {
        var result = new StringBuf();
        result.add('use_bpm ${data.bpm}\n');

        var timeManipulator = data.makeTimeManipulator();
        var totalCycleTicks = data.makeChordProgression().toChordThings().length * timeManipulator.chordTicks;
        var lineData = new Array<SonicPiLineData>();

        for (lineIndex in 0...data.lines.length) {
            var lineGenerator = data.makeLineGenerator(lineIndex);
            var notes = lineGenerator.generateNotes(0);

            if (notes.length == 0) {
                continue;
            }

            lineData.push({
                lineIndex: lineIndex,
                events: groupByStartTime(notes)
            });
        }

        var exportedLines = new Array<String>();
        for (line in lineData) {
            exportedLines.push('live_loop :goldenpond_line_${line.lineIndex + 1} do\n'
                + '  use_synth ${getSynthForLine(line.lineIndex)}\n'
                + exportLineEvents(line.events, timeManipulator, totalCycleTicks)
                + 'end\n');
        }

        if (exportedLines.length > 0) {
            result.add('\n');
            result.add(exportedLines.join('\n'));
        }

        return result.toString();
    }

    private static function groupByStartTime(notes:Array<INote>):Array<SonicPiEvent> {
        var events = new Array<SonicPiEvent>();

        for (note in notes) {
            if (events.length == 0 || !floatEqual(events[events.length - 1].startTime, note.getStartTime())) {
                events.push({
                    startTime: note.getStartTime(),
                    notes: [note]
                });
            } else {
                events[events.length - 1].notes.push(note);
            }
        }

        return events;
    }

    private static function exportLineEvents(events:Array<SonicPiEvent>, timeManipulator:TimeManipulator, totalLengthTicks:Float):String {
        var result = new StringBuf();

        for (eventIndex in 0...events.length) {
            var event = events[eventIndex];

            for (note in event.notes) {
                result.add('  play ${note.getMidiNoteValue()}, release: ${formatNumber(note.getLength() / timeManipulator.ppq)}\n');
            }

            if (eventIndex < events.length - 1) {
                var nextEvent = events[eventIndex + 1];
                var sleepBeats = (nextEvent.startTime - event.startTime) / timeManipulator.ppq;
                if (sleepBeats > 0) {
                    result.add('  sleep ${formatNumber(sleepBeats)}\n');
                }
            }
        }

        if (events.length > 0) {
            var finalEvent = events[events.length - 1];
            var finalSleepTicks = totalLengthTicks - finalEvent.startTime;
            var finalSleepBeats = finalSleepTicks / timeManipulator.ppq;
            if (finalSleepBeats > 0) {
                result.add('  sleep ${formatNumber(finalSleepBeats)}\n');
            }
        }

        return result.toString();
    }

    private static function formatNumber(value:Float):String {
        var rounded = Math.round(value * 100000000) / 100000000;
        if (floatEqual(rounded, Math.round(rounded))) {
            return Std.string(Math.round(rounded));
        }
        var result = Std.string(rounded);
        if (result.indexOf(".") != -1) {
            while (StringTools.endsWith(result, "0")) {
                result = result.substr(0, result.length - 1);
            }
            if (StringTools.endsWith(result, ".")) {
                result = result.substr(0, result.length - 1);
            }
        }
        return result;
    }

    private static function getSynthForLine(lineIndex:Int):String {
        if (lineIndex >= 0 && lineIndex < DEFAULT_SYNTHS.length) {
            return DEFAULT_SYNTHS[lineIndex];
        }
        return ":beep";
    }

    private static function floatEqual(a:Float, b:Float):Bool {
        return Math.abs(a - b) < FLOAT_EPSILON;
    }
}
