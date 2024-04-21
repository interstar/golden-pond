
from core import MAJOR,MINOR
from parser import ChordProgression
from timed_sequences import TimeManipulator

seq = ChordProgression(48,MAJOR,'71,74,-94,73,9(5/2),72,-75,91,!,71,74,-94,73,9(5/2),72,-75,-95,!,'*3).toNotes()

ti = TimeManipulator(4,1.2,16,0.7)
chords = ti.chords(seq, 0)
arps = ti.arpeggiate(seq, 7, 12, 0)


import pretty_midi

# Create a PrettyMIDI object
midi_data = pretty_midi.PrettyMIDI()

# Create an instrument instance
piano_program = pretty_midi.instrument_name_to_program('Acoustic Grand Piano')
piano = pretty_midi.Instrument(program=10)
piano2 = pretty_midi.Instrument(program=5)

pad = pretty_midi.Instrument(program=89)
pad2 = pretty_midi.Instrument(program=54)

for n in chords :
	end = n["start_time"]+n["length"]
	note = pretty_midi.Note(velocity=64, pitch=n["note"], start=n["start_time"], end=end)
	pad.notes.append(note)
	pad2.notes.append(note)
	
for n in arps :
	end = n["start_time"]+n["length"]
	note = pretty_midi.Note(velocity=64, pitch=n["note"]+24, start=n["start_time"], end=end)
	piano.notes.append(note)
	note = pretty_midi.Note(velocity=64, pitch=n["note"]+12, start=n["start_time"], end=end)	
	piano2.notes.append(note)
	
	
# Add the instrument to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)
# Save the MIDI file
midi_data.write('./gp_example.mid')

