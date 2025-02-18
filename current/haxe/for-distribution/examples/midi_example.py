## You'll need pretty_midi, setuptools and goldenpond installed to run this

import sys
import os
#sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from goldenpond import Mode, ChordProgression, TimeManipulator, ChordLine, ArpLine, BassLine

# RhythmicDensity values:
# SIXTEEN = 0  -> 16 patterns/chord (1/16) -> density = 1/16 = 0.0625
# TWELVE  = 1  -> 12 patterns/chord (1/12) -> density = 1/12 = 0.0833
# EIGHT   = 2  -> 8 patterns/chord  (1/8)  -> density = 1/8  = 0.125
# SIX     = 3  -> 6 patterns/chord  (1/6)  -> density = 1/6  = 0.1667
# FOUR    = 4  -> 4 patterns/chord  (1/4)  -> density = 1/4  = 0.25
# THREE   = 5  -> 3 patterns/chord  (1/3)  -> density = 1/3  = 0.3333
# TWO     = 6  -> 2 patterns/chord  (1/2)  -> density = 1/2  = 0.5
# ONE     = 7  -> 1 pattern/chord   (1/1)  -> density = 1/1  = 1.0

seq = ChordProgression(48, Mode.getMajorMode(), 
    '71,74,-94,73,9(5/2),72,-75,91,!,71,74,-94,73,9(5/2),72,-75,-95,!,'*3)

# TimeManipulator with PPQ, chord duration and BPM
ti = TimeManipulator()
ti.setPPQ(96).setChordDuration(4).setBPM(120)

# Create lines with k, n, gateLength and rhythmicDensity parameters
# Using EIGHT (index 2) -> 8 patterns/chord -> density = 1/8 = 0.125
chord_line = ChordLine(ti, seq, 1, 4, 0.75, 1.0)  # k=1, n=4, 75% gate length, density=ONE
arp_line = ArpLine(ti, seq, 7, 12, 0.5, 1)      # k=7, n=12, 50% gate length, density=ONE
bass_line = BassLine(ti, seq, 2, 12, 0.75, 1)      # k=2, n=4, 50% gate length, density=TWO

# Generate notes from each line (now in seconds)
chords = chord_line.notesInSeconds(0, 0, 100)
arps = arp_line.notesInSeconds(0, 1, 100)
bass = bass_line.notesInSeconds(0, 2, 100)

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


# Then modify the MIDI note creation
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
    
# Add the instruments to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)
midi_data.instruments.append(bass_program)

# Save the MIDI file
midi_data.write('./gp_example.mid')

