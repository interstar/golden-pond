from chords import *
from myparser import *

import numpy as np
import sounddevice as sd

cm = ChordMaker()

MAJOR = 0
MINOR = 1

MODAL_INTERCHANGE="MODAL_INTERCHANGE"
SEVENTH="SEVENTH"
NINTH="NINTH"
SECONDARY_N="SECONDARY_N"

ERRORS=0
def testit(id,val,target,msg) :
    if val != target :
        print("ERROR IN %s : %s" % (id,msg))
        print("Wanted:")
        print(target)
        print("Got:")
        print(val)
    else :
        print("%s OK" % id)




testit("ChordThing","%s"%ChordThing(60,MAJOR,3,2).seventh(), "ChordThing(60,MAJOR,3,0,2) + {'SEVENTH'}","ChordThings")
ct1 = ChordThing(60,MAJOR,3,2)
testit("ChordThing no extensions",ct1.has_extensions(),False,"ChordThings")
ct1 = ChordThing(60,MAJOR,3,2).ninth()
testit("ChordThing has extensions",ct1.has_extensions(),True,"ChordThings")


testit("ChordThing ninths override sevenths","%s"%ChordThing(60,MAJOR,3,2).seventh().ninth(), "ChordThing(60,MAJOR,3,0,2) + {'NINTH'}","ChordThings")
testit("ChordThing sevenths override ninths","%s"%ChordThing(60,MAJOR,3,2).ninth().seventh(), "ChordThing(60,MAJOR,3,0,2) + {'SEVENTH'}","ChordThings")
testit("ChordThing modal interchange","%s"%ChordThing(60,MAJOR,3,2).modal_interchange(), "ChordThing(60,MAJOR,3,0,2) + {'MODAL_INTERCHANGE'}","ChordThings")
testit("ChordThing has modal interchange",ChordThing(60,MAJOR,3,2).modal_interchange().has_modal_interchange(),True,"ChordThings")
testit("ChordThing swap mode",ChordThing(60,MAJOR,3,2).swap_mode().mode,MINOR,"ChordThings")
testit("ChordThing swap mode",ChordThing(60,MINOR,3,2).swap_mode().mode,MAJOR,"ChordThings")



testit("Major Triads",cm.chordProgressionFromString(60,MAJOR,"1|4|5|6"),
       [[60, 64, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
       "Basic major triads")

testit("Minor Triads",cm.chordProgressionFromString(60,MINOR,"1|4,5| 6"),
       [[60, 63, 67], [65, 68, 72], [67, 70, 74], [68, 72, 75]],
       "Basic minor triads")

testit("Major Triads with modal interchange",cm.chordProgressionFromString(60,MAJOR,"-1|4|5|6"),
       [[60, 63, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
       "Basic major triads")

testit("Minor Sevenths", cm.chordProgressionFromString(60,MINOR,"72,75,71"),
       [[62, 65, 68, 72], [67, 70, 74, 77], [60, 63, 67, 70]],"Minor 7ths")
       

testit("Chord Inversions", 
       cm.chordProgressionFromString(60,MAJOR,"1|4i"),
       [[60, 64, 67], [69, 72, 77]],
       "Chord inversions")
       
testit("Chord Inversions with extensions", 
       cm.chordProgressionFromString(60,MAJOR,"4,74,74i,74ii,74iii"),
       [[65, 69, 72], [65, 69, 72, 76], [69, 72, 76, 77], [72, 76, 77, 81], [76, 77, 81, 84]],
       "Chord inversions 2")
       
testit("Modulate to new key",cm.chordProgressionFromString(60,MAJOR,"1|4|>2|1|4|<1|1|4"),
       [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74],[61,65,68],[66,70,73]],
       "Modulating basic triads by 2")
       
testit("Modulate to new mode",cm.chordProgressionFromString(60,MAJOR,"1|4|5|7|!|1|4|5|7"),
       cm.chordProgressionFromString(60,MAJOR,"1|4|5|7|-1|-4|-5|-7"),
       "Modulating mode")       

cp = ChordParser(60, MAJOR)

testit("Simple chords",["%s" % c for c in cp.parse("1,4,6,5")],
    ['ChordThing(60,MAJOR,1,0,1) + set()', 'ChordThing(60,MAJOR,4,0,1) + set()', 'ChordThing(60,MAJOR,6,0,1) + set()', 'ChordThing(60,MAJOR,5,0,1) + set()'],"ChordParsing simple chords")

testit("Extended chords",["%s" % c for c in cp.parse("71,-94,6ii,-5")],
["ChordThing(60,MAJOR,1,0,1) + {'SEVENTH'}", "ChordThing(60,MAJOR,4,0,1) + {'NINTH', 'MODAL_INTERCHANGE'}", 'ChordThing(60,MAJOR,6,2,1) + set()', "ChordThing(60,MAJOR,5,0,1) + {'MODAL_INTERCHANGE'}"],"ChordParsing extended chords")

 
       
testit("VOICE_LEADING Parser Test",
           [str(chord) for chord in cp.parse("1&6")],
           ["ChordThing(60,MAJOR,1,0,1) + set()",
            "ChordThing(60,MAJOR,6,0,1) + {'VOICE_LEADING'}"],
           "Parsing & separator for voice leading")       
           

#TODO Unit test this
print(voice_lead([60, 63, 66],[60,63,66]))          
print(voice_lead([60, 63, 66],[65,69,72]))          
print(voice_lead([60, 63, 66],[55,58,62]))          
       
testit("Secondary chords",
        [str(chord) for chord in cp.parse("(5/4),4")],
        ["ChordThing(60,MAJOR,(5/4),0,1) + {'SECONDARY'}",
         "ChordThing(60,MAJOR,4,0,1) + set()"],
         "Testing secondary chords")

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
chord_sequence = cm.chordProgressionFromString(45,MAJOR,s)
play_chord_sequence(chord_sequence)       


    
