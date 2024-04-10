from core import Mode, MAJOR, MINOR, ChordThing, ChordFactory

#from chords import *
#from parser import *

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
       "ChordThing(60,MAJOR,3,0,1) + {<Modifier.NINTH: 3>}",
       "ChordThings ninths override sevenths failed.")

testit("ChordThing has extensions with ninth",
       ChordThing(60, MAJOR, 3).ninth().has_extensions(),
       True,
       "ChordThing expected to have extensions with ninth.")

testit("ChordThing modal interchange",
       "%s" % ChordThing(60, MAJOR, 3).modal_interchange(),
       "ChordThing(60,MAJOR,3,0,1) + {<Modifier.MODAL_INTERCHANGE: 1>}",
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


testit("ChordThing","%s"%ChordThing(60,MAJOR,3,2).seventh(), "ChordThing(60,MAJOR,3,0,2) + {<Modifier.SEVENTH: 2>}","ChordThings")
ct1 = ChordThing(60,MAJOR,3,2)
testit("ChordThing no extensions",ct1.has_extensions(),False,"ChordThings")
ct1 = ChordThing(60,MAJOR,3,2).ninth()
testit("ChordThing has extensions",ct1.has_extensions(),True,"ChordThings")


testit("ChordThing ninths override sevenths","%s"%ChordThing(60,MAJOR,3,2).seventh().ninth(), "ChordThing(60,MAJOR,3,0,2) + {<Modifier.NINTH: 3>}","ChordThings")
testit("ChordThing sevenths override ninths","%s"%ChordThing(60,MAJOR,3,2).ninth().seventh(), "ChordThing(60,MAJOR,3,0,2) + {<Modifier.SEVENTH: 2>}","ChordThings")
testit("ChordThing modal interchange","%s"%ChordThing(60,MAJOR,3,2).modal_interchange(), "ChordThing(60,MAJOR,3,0,2) + {<Modifier.MODAL_INTERCHANGE: 1>}","ChordThings")
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
        





