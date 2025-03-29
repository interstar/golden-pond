## You'll need pretty_midi, setuptools and goldenpond installed to run this

import sys
import os
from goldenpond import (
    Mode, ChordProgression, TimeManipulator, LineGenerator,
    RhythmLanguage, MenuHelper, RhythmicDensity
)

# Create a chord progression
seq = ChordProgression(48, Mode.getMajorMode(), 
    '71,74,-94,73,9(5/2),72,-75,91,!m,71,74,-94,73,9(5/2),72,-75,-95,!M,'*2)

# TimeManipulator with PPQ, chord duration and BPM
ti = TimeManipulator()
ti.setPPQ(96).setChordDuration(4).setBPM(120)

# Create lines using rhythm patterns
chord_line = LineGenerator.createFromPattern(ti, seq, "1/4 c 1", 0.75)  # One note per beat, full chord
arp_line = LineGenerator.createFromPattern(ti, seq, "8/12 > 1", 0.5)   # 7 notes in 12 steps, ascending
bass_line = LineGenerator.createFromPattern(ti, seq,  "tt.<<.>. 1", 0.75).transpose(-12)  # 2 notes in 12 steps, single note
flute_line = LineGenerator.createFromPattern(ti, seq, "3/8 r 1", 0.75).transpose(12)

# Generate notes from each line (now in seconds)
chords = chord_line.notesInSeconds(0, 0, 100)
arps = arp_line.notesInSeconds(0, 1, 100)
bass = bass_line.notesInSeconds(0, 2, 100)
flute = flute_line.notesInSeconds(0, 3, 100)

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
    note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.startTime, end=n.startTime + n.length)
    pad.notes.append(note)
    pad2.notes.append(note)
    
for n in arps:
    note = pretty_midi.Note(velocity=64, pitch=n.note+24, start=n.startTime, end=n.startTime + n.length)
    piano.notes.append(note)
    note = pretty_midi.Note(velocity=64, pitch=n.note+12, start=n.startTime, end=n.startTime + n.length)    
    piano2.notes.append(note)

for n in bass:
    note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.startTime, end=n.startTime + n.length)    
    bass_program.notes.append(note)

for n in flute:
    note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.startTime, end=n.startTime + n.length)    
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