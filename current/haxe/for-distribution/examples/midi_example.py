## You'll need pretty_midi, setuptools and goldenpond installed to run this

import sys
import os
from goldenpond import (
    Mode, ChordProgression, TimeManipulator, LineGenerator,
    RhythmLanguage, MenuHelper, RhythmicDensity,
    GoldenData, MidiInstrumentContext
)

# Create a GoldenData instance
data = GoldenData()
data.root = 48  # C3
data.mode = 0   # Major
data.chordSequence = "71,74,-94,73,9(5/2),72,-75,91,!m,71,74,-94,73,9(5/2),72,-75,-95,!M,"*2
data.stutter = 0
data.bpm = 120
data.chordDuration = 4

# Add lines with their instrument contexts
data.addLine("1/4 c 1", MidiInstrumentContext(0, 64, 0.75, 0))  # One note per beat, full chord
data.addLine("8/12 > 1", MidiInstrumentContext(1, 64, 0.5, 0))   # 7 notes in 12 steps, ascending
data.addLine("tt.<<.>. 1", MidiInstrumentContext(2, 64, 0.75, -12))  # 2 notes in 12 steps, single note
data.addLine("3/8 r 1", MidiInstrumentContext(3, 64, 0.75, 12))  # Random notes

# Create line generators
generators = [data.makeLineGenerator(i) for i in range(len(data.lines))]

# Generate notes from each line
chords = generators[0].generateNotes(0)
arps = generators[1].generateNotes(0)
bass = generators[2].generateNotes(0)
flute = generators[3].generateNotes(0)

import pretty_midi

# Create a PrettyMIDI object
midi_data = pretty_midi.PrettyMIDI()

# Create instrument instances
piano_program = pretty_midi.instrument_name_to_program('Acoustic Grand Piano')
piano = pretty_midi.Instrument(program=10)
piano2 = pretty_midi.Instrument(program=5)
pad = pretty_midi.Instrument(program=89)
pad2 = pretty_midi.Instrument(program=54)
bass_program = pretty_midi.Instrument(program=32)
flute_program = pretty_midi.Instrument(program=76)

# Add notes to instruments
for n in chords:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    pad.notes.append(note)
    pad2.notes.append(note)
    
for n in arps:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    piano.notes.append(note)
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue() + 12),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    piano2.notes.append(note)

for n in bass:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    bass_program.notes.append(note)

for n in flute:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    flute_program.notes.append(note)

# Add the instruments to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)
midi_data.instruments.append(bass_program)
midi_data.instruments.append(flute_program)

# Save the MIDI file
midi_data.write('./gp_example.mid')

print("MIDI file saved as gp_example.mid")