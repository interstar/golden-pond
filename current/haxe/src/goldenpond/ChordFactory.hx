package;
import haxe.ds.StringMap;
import Mode;


class ChordFactory {
    /**
     * Generates actual chords from data in ChordThing
     */
    
    public static function calculateSecondaryChord(chordThing:ChordThing):ChordThing {
        var new_tonic = chordThing.get_mode().nth_from(chordThing.key, chordThing.degree);
        var ct = new ChordThing(new_tonic, Mode.getMajorMode(), chordThing.secondary_degree, chordThing.length);

        if (chordThing.modifiers.indexOf(Modifier.SEVENTH) != -1) ct.seventh();
        if (chordThing.modifiers.indexOf(Modifier.NINTH) != -1) ct.ninth();
        ct.set_inversion(chordThing.inversion);
        return ct;
    }

    public static function generateChordNotes(chordThing:ChordThing):Array<Int> {
        if (chordThing.modifiers.indexOf(Modifier.SECONDARY) != -1) {
            chordThing = calculateSecondaryChord(chordThing);
        }
        var mode = chordThing.get_mode();

        var chord = mode.make_triad(chordThing.key, chordThing.degree);
        if (chordThing.modifiers.indexOf(Modifier.NINTH) != -1) {
            chord = mode.make_ninth(chordThing.key, chordThing.degree);
        } else if (chordThing.modifiers.indexOf(Modifier.SEVENTH) != -1) {
            chord = mode.make_seventh(chordThing.key, chordThing.degree);
        }

        // Apply inversions
        for (i in 0...chordThing.inversion) {
            chord.push(chord.shift() + 12);
        }

        return chord;
    }


    public static function chordProgression(chordThings:Array<ChordThing>):Array<Array<Int>> {
        var chords = [];
        var prev_chord:Array<Int> = null;

        for (ct in chordThings) {
            var chord = generateChordNotes(ct);
            if (prev_chord != null && ct.modifiers.indexOf(Modifier.VOICE_LEADING) != -1) {
                chord = voice_lead(prev_chord, chord);  // Use the dummy voice_lead
            }
            chords.push(chord);
            prev_chord = chord;
        }

        return chords;
    }

    public static function voice_lead(prevChord:Array<Int>, nextChord:Array<Int>):Array<Int> {
        return nextChord;  // Dummy implementation
    }
}

