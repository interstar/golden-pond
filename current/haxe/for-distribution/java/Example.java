import haxe.root.GoldenData;
import haxe.root.Mode;
import haxe.root.TimeManipulator;
import haxe.root.MidiInstrumentContext;
import haxe.root.Note;
import haxe.root.ILineGenerator;
import haxe.root.Array;
import haxe.root.INote;

public class Example {
    public static void main(String[] args) {
        // Create a GoldenData instance
        GoldenData data = new GoldenData();
        data.root = 48;  // C3
        data.mode = 1;   // Minor mode (0=major, 1=minor, 2=harmonic minor, 3=melodic minor)
        data.chordSequence = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75";
        data.stutter = 0;  // No stuttering
        data.bpm = 120;
        data.chordDuration = 4;

        // Add lines with their instrument contexts
        data.addLine("5/8 c 1", new MidiInstrumentContext(0, 100, 0.8, 0));  // Chords on channel 0
        data.addLine("7/12 > 2", new MidiInstrumentContext(1, 100, 0.5, 0));  // Arpeggio on channel 1
        data.addLine("4/8 1 4", new MidiInstrumentContext(2, 100, 0.8, -12));   // Bass on channel 2

        // Create line generators
        ILineGenerator[] generators = new ILineGenerator[data.lines.length];
        for (int i = 0; i < data.lines.length; i++) {
            generators[i] = data.makeLineGenerator(i);
        }

        // Generate notes from each line
        Array<INote> chords = generators[0].generateNotes(0);  // First line (chords)
        Array<INote> arp = generators[1].generateNotes(0);     // Second line (arpeggio)
        Array<INote> bass = generators[2].generateNotes(0);    // Third line (bass)

        // Print chord notes with formatted floats
        System.out.println("First 20 Chord notes:");
        for (int i = 0; i < Math.min(20, chords.length); i++) {
            INote note = chords.__get(i);
            System.out.printf("Note[note: %d, startTime: %.1f, length: %.1f]\n",
                note.getMidiNoteValue(), note.getStartTime(), note.getLength());
        }

        // Print first arp note details with formatted floats
        if (arp.length > 0) {
            INote firstNote = arp.__get(0);
            System.out.println("\nFirst Note from Arpeggio");
            System.out.printf("Getting individual fields: note=%d, startTime=%.1f, length=%.1f\n",
                firstNote.getMidiNoteValue(), firstNote.getStartTime(), firstNote.getLength());
        }

        // Print a summary of the data
        System.out.println("\nGoldenData Summary:");
        System.out.println(data.toString());
    }
} 