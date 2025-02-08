## You'll need pretty_midi, setuptools and goldenpond installed to run this

import sys
import os
#sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from goldenpond import Mode, ChordProgression, TimeManipulator, ChordLine, ArpLine

seq = ChordProgression(48, Mode.getMajorMode(), 
    '71,74,-94,73,9(5/2),72,-75,91,!,71,74,-94,73,9(5/2),72,-75,-95,!,'*3)

ti = TimeManipulator()
ti.setChordLen(16).setPPQ(0.7)

# Create lines with their own gateLength values
chord_line = ChordLine(ti, seq, 0.75)  # 75% gate length for sustained chords
arp_line = ArpLine(ti, seq, 7, 12, 0.5)  # 50% gate length for staccato arps

# Generate notes from each line
chords = chord_line.generateNotes(0, 0, 100)
arps = arp_line.generateNotes(0, 1, 100)

import pretty_midi

# Create a PrettyMIDI object
midi_data = pretty_midi.PrettyMIDI()

# Create an instrument instance
piano_program = pretty_midi.instrument_name_to_program('Acoustic Grand Piano')
piano = pretty_midi.Instrument(program=10)
piano2 = pretty_midi.Instrument(program=5)

pad = pretty_midi.Instrument(program=89)
pad2 = pretty_midi.Instrument(program=54)

for n in chords:
    end = n.start_time + n.length
    note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.start_time, end=end)
    pad.notes.append(note)
    pad2.notes.append(note)
    
for n in arps:
    end = n.start_time + n.length
    note = pretty_midi.Note(velocity=64, pitch=n.note+24, start=n.start_time, end=end)
    piano.notes.append(note)
    note = pretty_midi.Note(velocity=64, pitch=n.note+12, start=n.start_time, end=end)    
    piano2.notes.append(note)
    
# Add the instrument to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)

# Save the MIDI file
midi_data.write('./gp_example.mid')

