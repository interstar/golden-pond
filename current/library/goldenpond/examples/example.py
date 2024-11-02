import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

 
from goldenpond.parser import *

import numpy as np
import sounddevice as sd




__SYNTH__ = '__fluid__'
               
if __SYNTH__ == '__native__' :     
    def play_chord_sequence(chord_sequence, duration=0.5, amplitude=0.1, sample_rate=44100):
        # Generate a time array
        t = np.linspace(0, duration, int(sample_rate * duration), False)

        # Generate the audio signal for each chord and concatenate them
        audio_signal = np.concatenate([amplitude * generate_chord_signal(chord, t) for chord in chord_sequence])

        # Play the audio signal
        sd.play(audio_signal, sample_rate)
        sd.wait()

    def generate_chord_signal(chord, t):
        # Generate a square wave for each note in the chord and sum them
        return np.sum([generate_note_signal(note, t) for note in chord], axis=0)

    def generate_note_signal(note, t):
        # Generate a square wave for the note
        frequency = 440 * 2**((note - 69) / 12)
        return 0.5 * (1 + np.sign(np.sin(2 * np.pi * frequency * t)))

import sys
print(sys.path)

import fluidsynth
import time 
    
if __SYNTH__ == '__fluid__' : 
    sf2_path = "/usr/share/sounds/sf2/FluidR3_GM.sf2"  # Adjust if your SoundFont path is different

def play_chord_sequence(chord_sequence, duration=1):
    fs = fluidsynth.Synth()
    fs.start()

    # Load the SoundFont
    sfid = fs.sfload(sf2_path)
    fs.program_select(0, sfid, 0, 0)

    for chord in chord_sequence:
        # Play each note in the chord
        print(chord)
        for note in chord:
            fs.noteon(0, note, 127)
        
        # Wait for the duration using the standard time.sleep function
        time.sleep(duration)
        
        # Stop each note in the chord
        for note in chord:
            fs.noteoff(0, note)
    
    # Cleanup
    fs.delete()
           
s = "1,(5/4),4,(5/6),6,(5/5),5i,(5/1),>1,"
s2 = "71,7(5/4),74,7(5/6),76,7(5/5),75i,7(5/1),>1,"
s3 = "91,9(5/4),94,9(5/6),96,9(5/5),95i,9(5/1),>1,"
s = s + s2 + s3 + s
s = s.strip(",")             
chord_sequence = ChordProgression(45,MAJOR,s).toNotes()
chord_sequence2 = ChordProgression(45,MINOR,s).toNotes()

#play_chord_sequence(chord_sequence+chord_sequence2,0.5)       

# cush chords /  chromatic mediants (up)
s = "74,73,72,75,71,>3,74,73,72,75,<3,71"
cs = ChordProgression(45,MINOR,s).toNotes()
#play_chord_sequence(cs)

# cush chords /  chromatic mediants (down)
s = "74,73,72,75,71,<3,74,73,72,75,>3,71"
cs = ChordProgression(45,MINOR,s).toNotes()
#play_chord_sequence(cs)

# double chromatic mediants
s = "74,73,72,75,71,!,>3,74,73,72,75,!,<3,71"
cs = ChordProgression(45,MAJOR,s).toNotes()
#play_chord_sequence(cs)
 


# secondary diminished?
s = "71,<5,75,>5,73,72,75,71"
cs = ChordProgression(52,MAJOR,s).toNotes()
#play_chord_sequence(cs)


# flat 6
s = "71,73,-76,75"
cs = ChordProgression(52,MAJOR,s).toNotes()
play_chord_sequence(cs)
    
