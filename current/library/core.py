from enum import Enum, auto
from typing import Set

class Mode:
    major_intervals = [2, 2, 1, 2, 2, 2, 1]
    minor_intervals = [2, 1, 2, 2, 1, 2, 2]

    # Singleton instances
    _major_mode = None
    _minor_mode = None

    def __init__(self, intervals):
        self.intervals = intervals

    @classmethod
    def getMajorMode(cls):
        """Return the singleton instance of the Major mode."""
        if cls._major_mode is None:
            cls._major_mode = Mode(cls.major_intervals)
        return cls._major_mode

    @classmethod
    def getMinorMode(cls):
        """Return the singleton instance of the Minor mode."""
        if cls._minor_mode is None:
            cls._minor_mode = Mode(cls.minor_intervals)
        return cls._minor_mode


    def nth_from(self, root, n):
        """Return the MIDI note number for the nth degree of the scale from the root.
        For the first degree, return the root note itself."""
        if n == 1:
            return root  # Return the root note for the first degree

        note = root
        # Start interval addition from the first interval for the second degree
        for i in range(n - 2 + 1):  # Adjust for 0-indexed intervals list
            note += self.intervals[i % len(self.intervals)]
        return note

    def make_chord_from_pattern(self,root,n,pat) :
        "Given a generic pattern of form [1,3,6] for example, give us the chord of the 1st, 3rd and 6th degree counting up from n, of the scale starting on root"
        return [self.nth_from(root,n+x-1) for x in pat] 
        
    def make_triad(self,root,n):
        "Return triad on degree n of this scale starting at root"
        return self.make_chord_from_pattern(root,n,[1,3,5])
        
    def make_seventh(self,root,n):
        "Return seventh on degree n of this scale starting at root"
        return self.make_chord_from_pattern(root,n,[1,3,5,7])

    def make_ninth(self,root,n):
        "Return seventh on degree n of this scale starting at root"
        return self.make_chord_from_pattern(root,n,[1,3,5,7,9])
        
        
MAJOR = Mode.getMajorMode()
MINOR = Mode.getMinorMode()

class Modifier(Enum):
    MODAL_INTERCHANGE=auto()
    SEVENTH=auto()
    NINTH=auto()
    SECONDARY = auto()
    VOICE_LEADING = auto()


# Displaying the most up-to-date ChordThing class

class ChordThing:
    """ChordThing objects are what we parse score strings into.
       They hold all the data needed to create a chord and modify it.
       Note that mode should now be an instance of Mode
    """
    def __init__(self, key, mode: Mode, degree, length=1):
        self.key = key
        self.mode = mode
        self.degree = degree
        self.length = length
        self.modifiers: Set[Modifier] = set()
        self.inversion = 0
        self.secondary_degree = None        

    def set_as_secondary(self, secondary_degree):
        self.modifiers.add(Modifier.SECONDARY)
        self.secondary_degree = secondary_degree
        return self

    def swap_mode(self):
        if self.mode == MAJOR:
            self.mode = MINOR
        else:
            self.mode = MAJOR
        return self
        
    def modal_interchange(self):
        self.modifiers.add(Modifier.MODAL_INTERCHANGE)
        return self

    def has_modal_interchange(self):
        return Modifier.MODAL_INTERCHANGE in self.modifiers        
        
    def seventh(self):
        self.modifiers.add(Modifier.SEVENTH)
        self.modifiers.discard(Modifier.NINTH)
        return self

    def ninth(self):
        self.modifiers.add(Modifier.NINTH)
        self.modifiers.discard(Modifier.SEVENTH)                    
        return self
        
    def set_inversion(self, inversion):
        self.inversion = inversion
        return self
        
    def set_voice_leading(self) :
        self.modifiers.add(Modifier.VOICE_LEADING)
        return self     

    def __str__(self):
        mode = "MAJOR" if self.mode == MAJOR else "MINOR"
        
        # Check if it's a secondary chord and adjust the degree representation accordingly
        if Modifier.SECONDARY in self.modifiers:
            degree_repr = f"({self.secondary_degree}/{self.degree})"
        else:
            degree_repr = str(self.degree)
        
        return "ChordThing(%s,%s,%s,%s,%s) + %s" % (self.key, mode, degree_repr, self.inversion, self.length, self.modifiers)    
    
    def __repr__(self):
        return self.__str__()        

    def clone(self):
        ct = ChordThing(self.key, self.mode, self.degree, self.length)
        ct.modifiers = self.modifiers.copy()
        ct.inversion = self.inversion
        ct.secondary_degree = self.secondary_degree
        return ct

    def has_extensions(self):
        return self.modifiers.intersection({Modifier.SEVENTH, Modifier.NINTH}) != set()
        
    def get_mode(self) :
        if self.has_modal_interchange() :
            return MAJOR if self.mode is MINOR else MINOR
        else :
            return self.mode
            
    def __eq__(self,other) :
        return self.__str__() == other.__str__()            


def voice_lead(chord) :
    return chord
    
class ChordFactory :
    """
    Generates actual chords from data in ChordThing
    """
    
    @classmethod 
    def calculateSecondaryChord(cls,chordThing) :
        new_tonic = chordThing.get_mode().nth_from(chordThing.key,chordThing.degree)
        print("Calculating secondary : %s / %s" % (chordThing.secondary_degree,chordThing.degree))
        print("new tonic %s" % new_tonic)
        
        ct = ChordThing(new_tonic,MAJOR,chordThing.secondary_degree,chordThing.length)

        if Modifier.SEVENTH in chordThing.modifiers : ct.seventh()
        if Modifier.NINTH in chordThing.modifiers : ct.ninth()
        ct.set_inversion(chordThing.inversion)
        print("new chordThing %s" % ct)
        return ct
   
    @classmethod
    def generateChordNotes(cls,chordThing) :
        if Modifier.SECONDARY in chordThing.modifiers:
            chordThing = cls.calculateSecondaryChord(chordThing)
        mode = chordThing.get_mode()

        chord = mode.make_triad(chordThing.key,chordThing.degree)
        if Modifier.NINTH in chordThing.modifiers :
            chord = mode.make_ninth(chordThing.key,chordThing.degree)
        elif Modifier.SEVENTH in chordThing.modifiers :
            chord = mode.make_seventh(chordThing.key,chordThing.degree)

        # Apply inversions
        for _ in range(chordThing.inversion):
            chord = chord[1:] + [chord[0] + 12]
            
        return chord     

    @classmethod        
    def chordProgression(cls, chordThings):
        chords = []
        prev_chord = None

        for ct in chordThings:
            chord = cls.generateChordNotes(ct)
            if prev_chord is not None and Modifier.VOICE_LEADING in ct.modifiers :
                chord = voice_lead(prev_chord, chord)
            chords.append(chord)
            prev_chord = chord

        return chords
               
                        

