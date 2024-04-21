import sys
sys.path.insert(0, '../goldenpond')  # Adjust path if necessary

from goldenpond import core, voiceleading  # Import the module or specific functions/classes


from goldenpond.core import Mode, MAJOR, MINOR, ChordThing, ChordFactory, SeqTypes
from goldenpond.voiceleading import voice_lead
from goldenpond.parser import ChordParser, ChordProgression
from goldenpond.timed_sequences import TimeManipulator


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

MAJOR = Mode.getMajorMode()
major_mode_2 = Mode.getMajorMode()

print("Testing Modes (ie Scale object)")
testit("modes1",MAJOR is major_mode_2,True,"Major Mode not singleton")

testit("modes2",MAJOR.nth_from(60,1),60,"Modes 2")
testit("modes3",MAJOR.nth_from(60,2),62,"Modes 3")
testit("modes4",MAJOR.nth_from(60,3),64,"Modes 4")
MINOR = Mode.getMinorMode()
testit("modes5",MINOR.nth_from(60,3),63,"Modes 5")
testit("modes6",MAJOR.nth_from(60,8),72,"Modes 6")
testit("modes7",MINOR.nth_from(60,9),74,"Modes 7")


testit("modes8",MAJOR.make_triad(60,1),[60,64,MAJOR.nth_from(60,5)],"Modes 8")
testit("modes9",MINOR.make_triad(60,1),[60,63,MINOR.nth_from(60,5)],"Modes 9")
testit("modes10",MAJOR.make_seventh(70,1),[70,74,77,81],"Modes 10")
testit("modes11",MAJOR.make_ninth(70,1),[70,74,77,81,84],"Modes 11")
testit("modes12",MAJOR.make_ninth(70,4),[75,79,82,86,89],"Modes 12")
testit("modes13",MAJOR.make_chord_from_pattern(50,2,[1,3,5]),MAJOR.make_triad(50,2),"Modes 13")


print("Testing ChordThing. Now MODE is the actual Scale itself.")
# Additional tests to verify ChordThing behavior and extensions handling
testit("ChordThing ninths override sevenths",
       "%s" % ChordThing(60, MAJOR, 3).seventh().ninth(),
       "ChordThing(60,MAJOR,3,0,1) + {2}",
       "ChordThings ninths override sevenths failed.")

testit("ChordThing has extensions with ninth",
       ChordThing(60, MAJOR, 3).ninth().has_extensions(),
       True,
       "ChordThing expected to have extensions with ninth.")

testit("ChordThing modal interchange",
       "%s" % ChordThing(60, MAJOR, 3).modal_interchange(),
       "ChordThing(60,MAJOR,3,0,1) + {0}",
       "ChordThing modal interchange failed.")

testit("ChordThing has modal interchange",
       ChordThing(60, MAJOR, 3).modal_interchange().has_modal_interchange(),
       True,
       "ChordThing expected to have modal interchange.")

testit("ChordThing swap mode to MINOR",
       ChordThing(60, MAJOR, 3).swap_mode().mode,
       MINOR,
       "ChordThing swap mode to MINOR failed.")

testit("ChordThing swap mode back to MAJOR",
       ChordThing(60, MINOR, 3).swap_mode().mode,
       MAJOR,
       "ChordThing swap mode back to MAJOR failed.")


testit("ChordThing","%s"%ChordThing(60,MAJOR,3,2).seventh(), "ChordThing(60,MAJOR,3,0,2) + {1}","ChordThings")
ct1 = ChordThing(60,MAJOR,3,2)
testit("ChordThing no extensions",ct1.has_extensions(),False,"ChordThings")
ct1 = ChordThing(60,MAJOR,3,2).ninth()
testit("ChordThing has extensions",ct1.has_extensions(),True,"ChordThings")


testit("ChordThing ninths override sevenths","%s"%ChordThing(60,MAJOR,3,2).seventh().ninth(), "ChordThing(60,MAJOR,3,0,2) + {2}","ChordThings")
testit("ChordThing sevenths override ninths","%s"%ChordThing(60,MAJOR,3,2).ninth().seventh(), "ChordThing(60,MAJOR,3,0,2) + {1}","ChordThings")
testit("ChordThing modal interchange","%s"%ChordThing(60,MAJOR,3,2).modal_interchange(), "ChordThing(60,MAJOR,3,0,2) + {0}","ChordThings")
testit("ChordThing has modal interchange",ChordThing(60,MAJOR,3,2).modal_interchange().has_modal_interchange(),True,"ChordThings")
testit("ChordThing swap mode",ChordThing(60,MAJOR,3,2).swap_mode().mode,MINOR,"ChordThings")
testit("ChordThing swap mode",ChordThing(60,MINOR,3,2).swap_mode().mode,MAJOR,"ChordThings")

testit("ChordThing get mode",ChordThing(60,MINOR,3,2).get_mode(),MINOR,"ChordThing.getMode")
testit("ChordThing get mode2",ChordThing(60,MINOR,3,2).modal_interchange().get_mode(),MAJOR,"ChordThing.getMode")
testit("ChordThing get mode3",ChordThing(24,MAJOR,3,2).modal_interchange().get_mode(),MINOR,"ChordThing.getMode")



print("Testing ChordFactory")

# Test Major Triad
testit("Major Triad C",
       ChordFactory.generateChordNotes(ChordThing(60, MAJOR, 1)),
       [60, 64, 67],
       "Major triad C not correctly generated.")

# Test Minor Triad
testit("Minor Triad A",
       ChordFactory.generateChordNotes(ChordThing(57, MINOR, 1)),
       [57, 60, 64],
       "Minor triad A not correctly generated.")

# Test Major Seventh Chord
testit("Major Seventh C",
       ChordFactory.generateChordNotes(ChordThing(60, MAJOR, 1).seventh()),
       [60, 64, 67, 71],
       "Major seventh C not correctly generated.")

# Test Minor Seventh Chord
testit("Minor Seventh A",
       ChordFactory.generateChordNotes(ChordThing(57, MINOR, 1).seventh()),
       [57, 60, 64, 67],
       "Minor seventh A not correctly generated.")

testit("Minor Ninth A",
       ChordFactory.generateChordNotes(ChordThing(57, MINOR, 1).ninth()),
       [57,60,64,67,71],
       "Minor ninth A not correctly generated.")
        

testit("Secondary Dominant of iii chord in C",
	   ChordFactory.generateChordNotes(ChordThing(60, MAJOR, 3).set_as_secondary(5).seventh()),
	   [71,75,78,81],
	   "Secondary dominantof iii in C not correctly generated")

print("Testing chord progressions")

testit("A chord progression",
	ChordFactory.chordProgression( [ChordThing(60,MAJOR,1), ChordThing(60,MAJOR,4,), ChordThing(60,MAJOR,6,), ChordThing(60,MAJOR,5,)]),
	[[60, 64, 67], [65, 69, 72], [69, 72, 76], [67, 71, 74]],
	"Chord progression not generated by ChordFactory")
	
	
	
print("Testing Parser")

cp = ChordParser(60, MAJOR)

testit("Simple chords",cp.parse("1,4,6,5"),
    [ChordThing(60,MAJOR,1), ChordThing(60,MAJOR,4,), ChordThing(60,MAJOR,6,), ChordThing(60,MAJOR,5,)],
    "ChordParsing simple chords")

testit("Extended chords",cp.parse("71,-94,6ii,-5"),
    [ChordThing(60,MAJOR,1).seventh(), ChordThing(60,MAJOR,4).ninth().modal_interchange(), ChordThing(60,MAJOR,6).set_inversion(2), ChordThing(60,MAJOR,5).modal_interchange()],
    "ChordParsing extended chords")
 

testit("Major Triads",ChordProgression(60,MAJOR,"1|4|5|6").toNotes(),
       [[60, 64, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
       "Basic major triads")

testit("Minor Triads",ChordProgression(60,MINOR,"1|4,5| 6").toNotes(),
       [[60, 63, 67], [65, 68, 72], [67, 70, 74], [68, 72, 75]],
       "Basic minor triads")

testit("Major Triads with modal interchange",ChordProgression(60,MAJOR,"-1|4|5|6").toNotes(),
       [[60, 63, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
       "Basic major triads")

testit("Minor Sevenths", ChordProgression(60,MINOR,"72,75,71").toNotes(),
       [[62, 65, 68, 72], [67, 70, 74, 77], [60, 63, 67, 70]],"Minor 7ths")
       

testit("Chord Inversions", 
       ChordProgression(60,MAJOR,"1|4i").toNotes(),
       [[60, 64, 67], [69, 72, 77]],
       "Chord inversions")
       
testit("Chord Inversions with extensions", 
       ChordProgression(60,MAJOR,"4,74,74i,74ii,74iii").toNotes(),
       [[65, 69, 72], [65, 69, 72, 76], [69, 72, 76, 77], [72, 76, 77, 81], [76, 77, 81, 84]],
       "Chord inversions 2")
       
testit("Modulate to new key",ChordProgression(60,MAJOR,"1|4|>2|1|4|<1|1|4").toNotes(),
       [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74],[61,65,68],[66,70,73]],
       "Modulating basic triads by 2")
       
testit("Modulate to new mode",ChordProgression(60,MAJOR,"1|4|5|7|!|1|4|5|7").toNotes(),
       ChordProgression(60,MAJOR,"1|4|5|7|-1|-4|-5|-7").toNotes(),
       "Modulating mode")       
       
testit("Secondary chords",
        ChordProgression(60,MAJOR,"(5/4),4").toChordThings(),
        [ChordThing(60,MAJOR,4).set_as_secondary(5),
         ChordThing(60,MAJOR,4)],
         "Testing secondary chords")
         
testit("Making secondary chords",
    ChordProgression(60,MAJOR,'(5/2),2,5,1').toNotes(),
    [[69, 73, 76], [62, 65, 69], [67, 71, 74], [60, 64, 67]],    
    "Making a secondary (5/2)")
    
testit("Making secondary chords with modifiers",
    ChordProgression(60,MAJOR,'7(5/2),72,75,71').toNotes(),
    [[69, 73, 76, 79], [62, 65, 69, 72], [67, 71, 74, 77], [60, 64, 67, 71]]	,    
    "Making a secondary 7(5/2)")       


print("Testing Voice Leading")       
testit("VOICE_LEADING Parser Test",
           cp.parse("1&6"),
           [ChordThing(60,MAJOR,1),ChordThing(60,MAJOR,6).set_voice_leading()],
           "Parsing & separator for voice leading")       


#TODO Unit test this
print("-------------------------\nVoice Lead diagnostics")
print(voice_lead([60, 63, 66],[60,63,66]))          
print(voice_lead([60, 63, 66],[65,69,72]))          
print(voice_lead([60, 63, 66],[55,58,62]))          
print("-------------------------")  
       
print("Testing Timed Sequences")


ti = TimeManipulator(4,0.8,16,960)
seq = ChordProgression(60,MAJOR,'72,75,71').toNotes()
testit("TimeManipulator Chords",
    ti.chords(seq, 0),
    [{'note': 62, 'start_time': 0, 'length': 1536.0}, {'note': 65, 'start_time': 0, 'length': 1536.0}, {'note': 69, 'start_time': 0, 'length': 1536.0}, {'note': 72, 'start_time': 0, 'length': 1536.0}, {'note': 67, 'start_time': 3840.0, 'length': 1536.0}, {'note': 71, 'start_time': 3840.0, 'length': 1536.0}, {'note': 74, 'start_time': 3840.0, 'length': 1536.0}, {'note': 77, 'start_time': 3840.0, 'length': 1536.0}, {'note': 60, 'start_time': 7680.0, 'length': 1536.0}, {'note': 64, 'start_time': 7680.0, 'length': 1536.0}, {'note': 67, 'start_time': 7680.0, 'length': 1536.0}, {'note': 71, 'start_time': 7680.0, 'length': 1536.0}],
    "Chord Times")
testit("TimeManipulator Bass",
    ti.bassline(seq, 3, 8, 0),
    [{'note': 50, 'start_time': 0, 'length': 192.0}, {'note': 50, 'start_time': 720.0, 'length': 192.0}, {'note': 50, 'start_time': 1200.0, 'length': 192.0}, {'note': 50, 'start_time': 1920.0, 'length': 192.0}, {'note': 50, 'start_time': 2640.0, 'length': 192.0}, {'note': 50, 'start_time': 3120.0, 'length': 192.0}, {'note': 55, 'start_time': 3840.0, 'length': 192.0}, {'note': 55, 'start_time': 4560.0, 'length': 192.0}, {'note': 55, 'start_time': 5040.0, 'length': 192.0}, {'note': 55, 'start_time': 5760.0, 'length': 192.0}, {'note': 55, 'start_time': 6480.0, 'length': 192.0}, {'note': 55, 'start_time': 6960.0, 'length': 192.0}, {'note': 48, 'start_time': 7680.0, 'length': 192.0}, {'note': 48, 'start_time': 8400.0, 'length': 192.0}, {'note': 48, 'start_time': 8880.0, 'length': 192.0}, {'note': 48, 'start_time': 9600.0, 'length': 192.0}, {'note': 48, 'start_time': 10320.0, 'length': 192.0}, {'note': 48, 'start_time': 10800.0, 'length': 192.0}],
    "Bassline Times")
    
testit("TimeManipulator Top",
    ti.topline(seq, 3, 8, 0),
    [{'note': 84, 'start_time': 0, 'length': 192.0}, {'note': 84, 'start_time': 720.0, 'length': 192.0}, {'note': 84, 'start_time': 1200.0, 'length': 192.0}, {'note': 84, 'start_time': 1920.0, 'length': 192.0}, {'note': 84, 'start_time': 2640.0, 'length': 192.0}, {'note': 84, 'start_time': 3120.0, 'length': 192.0}, {'note': 89, 'start_time': 3840.0, 'length': 192.0}, {'note': 89, 'start_time': 4560.0, 'length': 192.0}, {'note': 89, 'start_time': 5040.0, 'length': 192.0}, {'note': 89, 'start_time': 5760.0, 'length': 192.0}, {'note': 89, 'start_time': 6480.0, 'length': 192.0}, {'note': 89, 'start_time': 6960.0, 'length': 192.0}, {'note': 83, 'start_time': 7680.0, 'length': 192.0}, {'note': 83, 'start_time': 8400.0, 'length': 192.0}, {'note': 83, 'start_time': 8880.0, 'length': 192.0}, {'note': 83, 'start_time': 9600.0, 'length': 192.0}, {'note': 83, 'start_time': 10320.0, 'length': 192.0}, {'note': 83, 'start_time': 10800.0, 'length': 192.0}],
    "Bassline Times")

testit("TimeManipulator Silent",
    ti.silentline(seq, 3, 8, 0),
    [],
    "Silence")
    
    
testit("TimeManipulator Arpeggiate",
    ti.arpeggiate(seq, 3, 8, 0),
    [{'note': 62, 'start_time': 0, 'length': 192.0}, {'note': 65, 'start_time': 720.0, 'length': 192.0}, {'note': 69, 'start_time': 1200.0, 'length': 192.0}, {'note': 72, 'start_time': 1920.0, 'length': 192.0}, {'note': 62, 'start_time': 2640.0, 'length': 192.0}, {'note': 65, 'start_time': 3120.0, 'length': 192.0}, {'note': 67, 'start_time': 3840.0, 'length': 192.0}, {'note': 71, 'start_time': 4560.0, 'length': 192.0}, {'note': 74, 'start_time': 5040.0, 'length': 192.0}, {'note': 77, 'start_time': 5760.0, 'length': 192.0}, {'note': 67, 'start_time': 6480.0, 'length': 192.0}, {'note': 71, 'start_time': 6960.0, 'length': 192.0}, {'note': 60, 'start_time': 7680.0, 'length': 192.0}, {'note': 64, 'start_time': 8400.0, 'length': 192.0}, {'note': 67, 'start_time': 8880.0, 'length': 192.0}, {'note': 71, 'start_time': 9600.0, 'length': 192.0}, {'note': 60, 'start_time': 10320.0, 'length': 192.0}, {'note': 64, 'start_time': 10800.0, 'length': 192.0}],
    "Arp Times")
    
testit("Grab combo",
    ti.grabCombo(seq,3,8,0,set([SeqTypes.TOP,SeqTypes.EUCLIDEAN])),
    [{'note': 84, 'start_time': 0, 'length': 192.0}, {'note': 84, 'start_time': 720.0, 'length': 192.0}, {'note': 84, 'start_time': 1200.0, 'length': 192.0}, {'note': 84, 'start_time': 1920.0, 'length': 192.0}, {'note': 84, 'start_time': 2640.0, 'length': 192.0}, {'note': 84, 'start_time': 3120.0, 'length': 192.0}, {'note': 89, 'start_time': 3840.0, 'length': 192.0}, {'note': 89, 'start_time': 4560.0, 'length': 192.0}, {'note': 89, 'start_time': 5040.0, 'length': 192.0}, {'note': 89, 'start_time': 5760.0, 'length': 192.0}, {'note': 89, 'start_time': 6480.0, 'length': 192.0}, {'note': 89, 'start_time': 6960.0, 'length': 192.0}, {'note': 83, 'start_time': 7680.0, 'length': 192.0}, {'note': 83, 'start_time': 8400.0, 'length': 192.0}, {'note': 83, 'start_time': 8880.0, 'length': 192.0}, {'note': 83, 'start_time': 9600.0, 'length': 192.0}, {'note': 83, 'start_time': 10320.0, 'length': 192.0}, {'note': 83, 'start_time': 10800.0, 'length': 192.0},
    {'note': 62, 'start_time': 0, 'length': 192.0}, {'note': 65, 'start_time': 720.0, 'length': 192.0}, {'note': 69, 'start_time': 1200.0, 'length': 192.0}, {'note': 72, 'start_time': 1920.0, 'length': 192.0}, {'note': 62, 'start_time': 2640.0, 'length': 192.0}, {'note': 65, 'start_time': 3120.0, 'length': 192.0}, {'note': 67, 'start_time': 3840.0, 'length': 192.0}, {'note': 71, 'start_time': 4560.0, 'length': 192.0}, {'note': 74, 'start_time': 5040.0, 'length': 192.0}, {'note': 77, 'start_time': 5760.0, 'length': 192.0}, {'note': 67, 'start_time': 6480.0, 'length': 192.0}, {'note': 71, 'start_time': 6960.0, 'length': 192.0}, {'note': 60, 'start_time': 7680.0, 'length': 192.0}, {'note': 64, 'start_time': 8400.0, 'length': 192.0}, {'note': 67, 'start_time': 8880.0, 'length': 192.0}, {'note': 71, 'start_time': 9600.0, 'length': 192.0}, {'note': 60, 'start_time': 10320.0, 'length': 192.0}, {'note': 64, 'start_time': 10800.0, 'length': 192.0}],
    "Grab both TOP and EUCLIDEAN")

testit("Grab combo of one",
    ti.grabCombo(seq,3,8,0,set([SeqTypes.TOP])),
    [{'note': 84, 'start_time': 0, 'length': 192.0}, {'note': 84, 'start_time': 720.0, 'length': 192.0}, {'note': 84, 'start_time': 1200.0, 'length': 192.0}, {'note': 84, 'start_time': 1920.0, 'length': 192.0}, {'note': 84, 'start_time': 2640.0, 'length': 192.0}, {'note': 84, 'start_time': 3120.0, 'length': 192.0}, {'note': 89, 'start_time': 3840.0, 'length': 192.0}, {'note': 89, 'start_time': 4560.0, 'length': 192.0}, {'note': 89, 'start_time': 5040.0, 'length': 192.0}, {'note': 89, 'start_time': 5760.0, 'length': 192.0}, {'note': 89, 'start_time': 6480.0, 'length': 192.0}, {'note': 89, 'start_time': 6960.0, 'length': 192.0}, {'note': 83, 'start_time': 7680.0, 'length': 192.0}, {'note': 83, 'start_time': 8400.0, 'length': 192.0}, {'note': 83, 'start_time': 8880.0, 'length': 192.0}, {'note': 83, 'start_time': 9600.0, 'length': 192.0}, {'note': 83, 'start_time': 10320.0, 'length': 192.0}, {'note': 83, 'start_time': 10800.0, 'length': 192.0}],
    "Grab TOP only")
    
testit("Grab Bass and Scale",
    ti.grabCombo(seq,3,8,0,set([SeqTypes.BASS,SeqTypes.SCALE])),
    [{'note': 50, 'start_time': 0, 'length': 192.0}, {'note': 50, 'start_time': 720.0, 'length': 192.0}, {'note': 50, 'start_time': 1200.0, 'length': 192.0}, {'note': 50, 'start_time': 1920.0, 'length': 192.0}, {'note': 50, 'start_time': 2640.0, 'length': 192.0}, {'note': 50, 'start_time': 3120.0, 'length': 192.0}, {'note': 55, 'start_time': 3840.0, 'length': 192.0}, {'note': 55, 'start_time': 4560.0, 'length': 192.0}, {'note': 55, 'start_time': 5040.0, 'length': 192.0}, {'note': 55, 'start_time': 5760.0, 'length': 192.0}, {'note': 55, 'start_time': 6480.0, 'length': 192.0}, {'note': 55, 'start_time': 6960.0, 'length': 192.0}, {'note': 48, 'start_time': 7680.0, 'length': 192.0}, {'note': 48, 'start_time': 8400.0, 'length': 192.0}, {'note': 48, 'start_time': 8880.0, 'length': 192.0}, {'note': 48, 'start_time': 9600.0, 'length': 192.0}, {'note': 48, 'start_time': 10320.0, 'length': 192.0}, {'note': 48, 'start_time': 10800.0, 'length': 192.0}
    
    ],
    "Grab both BASS and SCALE")
