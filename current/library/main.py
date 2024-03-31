from chords import *
from parser import *

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
        
    
testTiming()    

#TODO Unit test this
print(voice_lead([60, 63, 66],[60,63,66]))          
print(voice_lead([60, 63, 66],[65,69,72]))          
print(voice_lead([60, 63, 66],[55,58,62]))          
       
testit("Secondary chords",
        [str(chord) for chord in cp.parse("(5/4),4")],
        ["ChordThing(60,MAJOR,(5/4),0,1) + {'SECONDARY'}",
         "ChordThing(60,MAJOR,4,0,1) + set()"],
         "Testing secondary chords")
         
testit("Making secondary chords",
    "%s" % cm.chordProgressionFromString(60,MAJOR,'(5/2),2,5,1'),
    "[[69, 73, 76], [62, 65, 69], [67, 71, 74], [60, 64, 67]]",    
    "Making a secondary (5/2)")
    
testit("Making secondary chords with modifiers",
    "%s" % cm.chordProgressionFromString(60,MAJOR,'7(5/2),72,75,71'),
    "[[69, 73, 76, 79], [62, 65, 69, 72], [67, 71, 74, 77], [60, 64, 67, 71]]",    
    "Making a secondary 7(5/2)")

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
chord_sequence = cm.chordProgressionFromString(45,MAJOR,s)
play_chord_sequence(chord_sequence)       


    
