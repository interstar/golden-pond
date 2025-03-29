import sys
sys.path.append('./out/python')  # Changed to match our build directory

# Import the specific classes we need
from goldenpond import (
    TimeManipulator, ChordProgression, LineGenerator,
    MenuHelper, RhythmicDensity, Mode, RhythmLanguage,
    SimpleRhythmGenerator, BjorklundRhythmGenerator, SelectorType,
    GoldenData
)
import pretty_midi
import json

# Line definitions
LINES = [
    ("5/8 c 1", 0.8, 0, 0, 0.8),    # Chord line
    ("1/1 1 16", 0.8, -1, 1, 0.8),  # Bass line (transposed down an octave)
    ("4/8 R 4", 0.6, 2, 2, 0.6),    # Top line (transposed up two octaves)
    ("6/12 > 2", 0.5, 0, 3, 0.5),   # Arp line
    ("5%8 r 4", 0.5, 0, 4, 0.5)     # Random line
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
    
    # Add lines
    for pattern, gate, octave, channel, gate_length in LINES:
        data.addLine(pattern, gate_length, octave, channel, gate)
    
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
    
    # Setup TimeManipulator
    ti = TimeManipulator()
    ti.setPPQ(960).setChordDuration(data.chordDuration).setBPM(data.bpm)
    
    # Create chord progression
    seq = data.createProgression()
    
    # Print density values
    densities = {
        'ONE': MenuHelper.rhythmicDensityToNumeric(RhythmicDensity.ONE),
        'TWO': MenuHelper.rhythmicDensityToNumeric(RhythmicDensity.TWO),
        'FOUR': MenuHelper.rhythmicDensityToNumeric(RhythmicDensity.FOUR),
        'EIGHT': MenuHelper.rhythmicDensityToNumeric(RhythmicDensity.EIGHT),
        'SIXTEEN': MenuHelper.rhythmicDensityToNumeric(RhythmicDensity.SIXTEEN)
    }
    print(f"Density values: {', '.join(f'{k}={v}' for k, v in densities.items())}")

    # Generate lines
    print("\nDemonstrating different ways to create LineGenerator:")
    print("1. Using createFromPattern with rhythm language:")
    
    # Helper to convert ticks to seconds
    def ticks_to_seconds(ticks):
        return float(ticks) / ti.ppq * (60.0 / data.bpm)

    # Generate and add notes to programs
    for i, (pattern, gate, octave, channel, _) in enumerate(LINES):
        line = LineGenerator.createFromPattern(ti, seq, pattern, gate)
        if octave != 0:
            line = line.transpose(octave * 12)
        notes = line.generateNotes(0, channel, 100 if channel > 0 else 64)
        
        print(f"  - {pattern}: {len(notes)} notes")
        
        # Add notes to program
        program = programs[list(PROGRAMS.keys())[i]]
        for note in notes:
            note_start = ticks_to_seconds(note.startTime)
            note_end = note_start + ticks_to_seconds(note.length)
            program.notes.append(pretty_midi.Note(
                velocity=int(note.velocity),
                pitch=int(note.note),
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