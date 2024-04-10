from chords import *
from parser import *

import numpy as np
import sounddevice as sd


def testTiming() :
    ti = TimingInfo(4,0.8,16,960)
    seq = cm.chordProgressionFromString(60,MAJOR,'72,75,71')
    testit("TimingInfo Chords",
        ("%s"%ti.chords(seq, 0)),
        "[{'note': 62, 'start_time': 0, 'length': 1536.0}, {'note': 65, 'start_time': 0, 'length': 1536.0}, {'note': 69, 'start_time': 0, 'length': 1536.0}, {'note': 72, 'start_time': 0, 'length': 1536.0}, {'note': 67, 'start_time': 3840.0, 'length': 1536.0}, {'note': 71, 'start_time': 3840.0, 'length': 1536.0}, {'note': 74, 'start_time': 3840.0, 'length': 1536.0}, {'note': 77, 'start_time': 3840.0, 'length': 1536.0}, {'note': 60, 'start_time': 7680.0, 'length': 1536.0}, {'note': 64, 'start_time': 7680.0, 'length': 1536.0}, {'note': 67, 'start_time': 7680.0, 'length': 1536.0}, {'note': 71, 'start_time': 7680.0, 'length': 1536.0}]",
        "Chord Times")
    testit("TimingInfo Bass",
        ("%s"%ti.bassline(seq, 3, 8, 0)),
        "[{'note': 50, 'start_time': 0, 'length': 192.0}, {'note': 50, 'start_time': 720.0, 'length': 192.0}, {'note': 50, 'start_time': 1200.0, 'length': 192.0}, {'note': 50, 'start_time': 1920.0, 'length': 192.0}, {'note': 50, 'start_time': 2640.0, 'length': 192.0}, {'note': 50, 'start_time': 3120.0, 'length': 192.0}, {'note': 55, 'start_time': 3840.0, 'length': 192.0}, {'note': 55, 'start_time': 4560.0, 'length': 192.0}, {'note': 55, 'start_time': 5040.0, 'length': 192.0}, {'note': 55, 'start_time': 5760.0, 'length': 192.0}, {'note': 55, 'start_time': 6480.0, 'length': 192.0}, {'note': 55, 'start_time': 6960.0, 'length': 192.0}, {'note': 48, 'start_time': 7680.0, 'length': 192.0}, {'note': 48, 'start_time': 8400.0, 'length': 192.0}, {'note': 48, 'start_time': 8880.0, 'length': 192.0}, {'note': 48, 'start_time': 9600.0, 'length': 192.0}, {'note': 48, 'start_time': 10320.0, 'length': 192.0}, {'note': 48, 'start_time': 10800.0, 'length': 192.0}]",
        "Bassline Times")
    testit("TimingInfo Arpeggiate",
        ("%s"%ti.arpeggiate(seq, 3, 8, 0)),
        "[{'note': 62, 'start_time': 0, 'length': 192.0}, {'note': 65, 'start_time': 720.0, 'length': 192.0}, {'note': 69, 'start_time': 1200.0, 'length': 192.0}, {'note': 72, 'start_time': 1920.0, 'length': 192.0}, {'note': 62, 'start_time': 2640.0, 'length': 192.0}, {'note': 65, 'start_time': 3120.0, 'length': 192.0}, {'note': 67, 'start_time': 3840.0, 'length': 192.0}, {'note': 71, 'start_time': 4560.0, 'length': 192.0}, {'note': 74, 'start_time': 5040.0, 'length': 192.0}, {'note': 77, 'start_time': 5760.0, 'length': 192.0}, {'note': 67, 'start_time': 6480.0, 'length': 192.0}, {'note': 71, 'start_time': 6960.0, 'length': 192.0}, {'note': 60, 'start_time': 7680.0, 'length': 192.0}, {'note': 64, 'start_time': 8400.0, 'length': 192.0}, {'note': 67, 'start_time': 8880.0, 'length': 192.0}, {'note': 71, 'start_time': 9600.0, 'length': 192.0}, {'note': 60, 'start_time': 10320.0, 'length': 192.0}, {'note': 64, 'start_time': 10800.0, 'length': 192.0}]",
        "Arp Times")
        
    
#testTiming()    

#TODO Unit test this
print(voice_lead([60, 63, 66],[60,63,66]))          
print(voice_lead([60, 63, 66],[65,69,72]))          
print(voice_lead([60, 63, 66],[55,58,62]))          
       


__SYNTH__ = '__fluid__'
               
if __SYNTH__ == '__native__' :     
    def play_chord_sequence(chord_sequence, duration=1, amplitude=0.1, sample_rate=44100):
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
s = s + s + s + s
s = s.strip(",")             
chord_sequence = ChordProgression(45,MAJOR,s).toNotes()
play_chord_sequence(chord_sequence)       


    
