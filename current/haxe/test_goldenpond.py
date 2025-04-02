import sys
sys.path.append('./out/python')  # Changed to match our build directory

# Import the specific classes we need
from goldenpond import (
    TimeManipulator, ChordProgression, LineGenerator,
    MenuHelper, RhythmicDensity, Mode, RhythmLanguage,
    SimpleRhythmGenerator, BjorklundRhythmGenerator, SelectorType,
    GoldenData, MidiInstrumentContext
)
import pretty_midi
import json

# Line definitions with their instrument contexts
LINES = [
    ("5/8 c 1", MidiInstrumentContext(0, 64, 0.8, 0)),    # Chord line
    ("1/1 1 16", MidiInstrumentContext(1, 80, 0.8, -12)),  # Bass line (transposed down an octave)
    ("4/8 R 4", MidiInstrumentContext(2, 72, 0.6, 24)),    # Top line (transposed up two octaves)
    ("6/12 > 2", MidiInstrumentContext(3, 68, 0.5, 0)),   # Arp line
    ("5%8 r 4", MidiInstrumentContext(4, 60, 0.5, 0))     # Random line
]

# MIDI program numbers
PROGRAMS = {
    'chord': 0,    # Piano
    'bass': 32,    # Acoustic Bass
    'top': 73,     # Flute
    'arp': 46,     # Harp
    'rand': 58     # Random
}

def create_golden_data():
    # Create a GoldenData instance
    data = GoldenData()
    data.root = 44  # C4
    data.mode = 0   # Major
    data.chordSequence = "7(1!1),7(1!2),7(1!3),7(1!4),7(1!5),7(1!6),7(1!7),!mm,7(1!1),7(1!2),7(1!3),7(1!4),7(1!5),7(1!6),7(1!7)"
    data.stutter = 0
    data.bpm = 120
    data.chordDuration = 8
    
    # Add lines with their instrument contexts
    for pattern, instrument_context in LINES:
        data.addLine(pattern, instrument_context)
    
    # Generate and print the summary
    print("\nGoldenData Summary:")
    print(data.toString())
    
    # Save as JSON
    with open("golden_data.json", "w") as f:
        f.write(data.toJSON())
    print("\nGoldenData saved to golden_data.json")
    
    return data

def create_midi(data: GoldenData):
    # Initialize MIDI file
    midi = pretty_midi.PrettyMIDI(initial_tempo=data.bpm)
    
    # Create instrument programs
    programs = {name: pretty_midi.Instrument(program=num) for name, num in PROGRAMS.items()}
    
    # Create line generators from GoldenData
    generators = [data.makeLineGenerator(i) for i in range(len(data.lines))]
    
    # Generate notes from each line
    for i, generator in enumerate(generators):
        notes = generator.generateNotes(0)
        
        # Get the instrument context for this line
        instrument_context = data.lines[i].instrumentContext
        
        # Add notes to appropriate program
        program = programs[list(PROGRAMS.keys())[i]]
        for note in notes:
            note_start = note.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
            note_end = note_start + note.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
            program.notes.append(pretty_midi.Note(
                velocity=int(note.velocity),
                pitch=int(note.getMidiNoteValue()),
                start=note_start,
                end=note_end
            ))

    # Add programs to MIDI and write file
    midi.instruments.extend(programs.values())
    midi.write("midi_output.mid")
    print(f"\nMIDI file written to midi_output.mid")

if __name__ == "__main__":
    data = create_golden_data()
    create_midi(data) 