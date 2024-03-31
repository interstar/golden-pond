from parser import ChordParser, ChordThing
from parser import MAJOR, MINOR, MODAL_INTERCHANGE, SEVENTH, NINTH, SECONDARY, VOICE_LEADING



def buildChord(root,intervals) :
    chord = [root]
    for i in intervals :
        chord.append(chord[-1]+i)
    return chord


def chordTypes() :
    ct = {}
    ct['M'] = lambda root : buildChord(root,[4,3])
    ct['m'] = lambda root : buildChord(root,[3,4])
    ct['dim'] = lambda root : buildChord(root,[3,3])
    ct['M7'] = lambda root : buildChord(root,[4,3,4])
    ct['m7'] = lambda root : buildChord(root,[3,4,3])
    ct['dom7'] = lambda root : buildChord(root,[4,3,3])
    ct['dim7'] = lambda root : buildChord(root,[3,3,3])
    ct['halfdim'] = lambda root : buildChord(root,[3,3,4])
    ct['sus2'] = lambda root : buildChord(root,[2,5])
    ct['sus4'] = lambda root : buildChord(root,[5,2])
    ct['aug'] = lambda root : buildChord(root,[4,4])    
    ct['dimM7'] = lambda root : buildChord(root,[3,3,4])
    # Adding Ninth Chords
    ct['M9'] = lambda root: buildChord(root, [4, 3, 4, 3])  # Major Ninth: R-M3-P5-M7-M9
    ct['9'] = lambda root: buildChord(root, [4, 3, 3, 4])   # Dominant Ninth: R-M3-P5-m7-M9
    ct['m9'] = lambda root: buildChord(root, [3, 4, 3, 4])  # Minor Ninth: R-m3-P5-m7-M9
    ct['dim9'] = lambda root: buildChord(root, [3, 3, 3, 6])  # Diminished Ninth: R-m3-d5-d7-M9 (Rare, more common would be a half-diminished 9th)
    ct['halfdim9'] = lambda root: buildChord(root, [3, 3, 4, 3])  # Half-Diminished Ninth: R-m3-d5-m7-M9
    # Altered Ninth Chords (Examples)
    ct['7b9'] = lambda root: buildChord(root, [4, 3, 3, 3])  # Dominant 7th Flat Nine: R-M3-P5-m7-m9
    ct['7#9'] = lambda root: buildChord(root, [4, 3, 3, 5])  # Dominant 7th Sharp Nine: R-M3-P5-m7-A9
     
    return ct


#######################


def octave_transform(input_chord, root=60):
    """
    Squish things into a single octave for comparison between chords and sort from lowest to highest.
    """
    return sorted([root + (x % 12) for x in input_chord])

def t_matrix(chord_a, chord_b):
    """
    Get the distances between the notes of two chords.
    """
    transformed_a = octave_transform(chord_a)
    transformed_b = octave_transform(chord_b)
    return [b - a for a, b in zip(transformed_a, transformed_b)]

def get_permutations(lst):
    if len(lst) == 3:
        return [
            [lst[0], lst[1], lst[2]],
            [lst[0], lst[2], lst[1]],
            [lst[1], lst[0], lst[2]],
            [lst[1], lst[2], lst[0]],
            [lst[2], lst[0], lst[1]],
            [lst[2], lst[1], lst[0]]
        ]
    elif len(lst) == 4:
        return [
            [lst[0], lst[1], lst[2], lst[3]],
            [lst[0], lst[1], lst[3], lst[2]],
            [lst[0], lst[2], lst[1], lst[3]],
            [lst[0], lst[2], lst[3], lst[1]],
            [lst[0], lst[3], lst[1], lst[2]],
            [lst[0], lst[3], lst[2], lst[1]],
            [lst[1], lst[0], lst[2], lst[3]],
            [lst[1], lst[0], lst[3], lst[2]],
            [lst[1], lst[2], lst[0], lst[3]],
            [lst[1], lst[2], lst[3], lst[0]],
            [lst[1], lst[3], lst[0], lst[2]],
            [lst[1], lst[3], lst[2], lst[0]],
            [lst[2], lst[0], lst[1], lst[3]],
            [lst[2], lst[0], lst[3], lst[1]],
            [lst[2], lst[1], lst[0], lst[3]],
            [lst[2], lst[1], lst[3], lst[0]],
            [lst[2], lst[3], lst[0], lst[1]],
            [lst[2], lst[3], lst[1], lst[0]],
            [lst[3], lst[0], lst[1], lst[2]],
            [lst[3], lst[0], lst[2], lst[1]],
            [lst[3], lst[1], lst[0], lst[2]],
            [lst[3], lst[1], lst[2], lst[0]],
            [lst[3], lst[2], lst[0], lst[1]],
            [lst[3], lst[2], lst[1], lst[0]]
        ]
    else:
        return [lst]  # Return the list itself if it's not of length 3 or 4


def voice_lead(chord_a, chord_b):
    """
    Determine the voice leading between two chords.
    """
    transformed_a = octave_transform(chord_a)
    transformed_b = octave_transform(chord_b)

    # If chord_a has more notes than chord_b, drop the excess notes from chord_a
    while len(transformed_a) > len(transformed_b):
        transformed_a.pop()  # Drop the highest note

    # If chord_b has more notes than chord_a, drop the excess notes from chord_b
    while len(transformed_b) > len(transformed_a):
        transformed_b.pop()  # Drop the highest note

    best_voicing = None
    min_distance = float('inf')

    for permuted_b in get_permutations(transformed_b):
        t_mat = t_matrix(transformed_a, list(permuted_b))
        total_distance = sum(abs(t) for t in t_mat)
        
        # Penalize for notes that are too close to each other
        for i in range(len(permuted_b) - 1):
            if abs(permuted_b[i] - permuted_b[i + 1]) in [1, 2]:  # If notes are a semitone or a tone apart
                total_distance += 10  # Add a penalty

        if total_distance < min_distance:
            min_distance = total_distance
            best_voicing = [a + t for a, t in zip(chord_a, t_mat)]

    return best_voicing



#######################
    
class ChordMaker :
    def __init__(self) :
        self.ct = chordTypes()

    def buildChord(self,root,chordType) :
        return self.ct[chordType](root)
        
    def findDegreeNoteAndChordType(self,root,mode,degree) :
        if mode == MAJOR :
            dnc = [[0,'M','M7'],[2,'m','m7'],[4,'m','m7'],[5,'M','M7'],[7,'M','dom7'],
            [9,'m','m7'],[11,'dim','halfdim']][degree-1]
        else :
            dnc = [[0,'m','m7'],[2,'dim','halfdim'],[3,'M','M7'],[5,'m','m7'],[7,'m','m7'],
                [8,'M','M7'],[10,'M','dom7']][degree-1]
        return [dnc[0]+root, dnc[1], dnc[2]]

    def generate_secondary_chord(self, chordThing):
        # Determine the tonicized key
        tonicized_key = self.findDegreeNoteAndChordType(chordThing.key, chordThing.mode, chordThing.secondary_target)[0]

        # Create a new ChordThing for the secondary chord based on the tonicized key
        secondary_chord_thing = ChordThing(tonicized_key, MAJOR, chordThing.secondary_base)  # We'll use MAJOR mode since we're tonicizing

        # Copy modifiers from the original chordThing to the new secondary_chord_thing (excluding the SECONDARY modifier)
        secondary_chord_thing.modifiers = chordThing.modifiers - {SECONDARY}
        secondary_chord_thing.inversion = chordThing.inversion

        # Return the chord generated for the secondary_chord_thing
        return self.oneChord(secondary_chord_thing)
    
    def oneChord(self, chordThing, previous_chord=None):
        # Check if it's a secondary chord
        if SECONDARY in chordThing.modifiers:
            chord = self.generate_secondary_chord(chordThing)
        else:
            if chordThing.has_modal_interchange():
                nct = chordThing.clone()
                nct.swap_mode()
                nct.modifiers.discard(MODAL_INTERCHANGE)
                return self.oneChord(nct, previous_chord)

            dnc = ChordMaker().findDegreeNoteAndChordType(chordThing.key, chordThing.mode, chordThing.degree)

            if not chordThing.has_extensions():
                chord = self.buildChord(dnc[0], dnc[1])
            if SEVENTH in chordThing.modifiers:
                chord = self.buildChord(dnc[0], dnc[2])
            if NINTH in chordThing.modifiers:
                chord = self.buildChord(dnc[0], dnc[2])

            # generate chord in the correct inversion
            inversion = chordThing.inversion
            while inversion > 0:
                chord = chord[1:] + [chord[0] + 12]
                inversion -= 1

        # Apply voice leading if previous_chord is provided and VOICE_LEADING modifier exists
        if previous_chord and VOICE_LEADING in chordThing.modifiers:
            chord = voice_lead(previous_chord, chord)

        return chord



    
    def chordProgression(self, chordThings):
        chords = []
        prev_chord = None

        for ct in chordThings:
            chord = self.oneChord(ct, prev_chord)
            chords.append(chord)
            prev_chord = chord

        return chords

 
        
    def chordProgressionFromString(self,root,mode,scoreString):
        cp = ChordParser(root,mode)
        chordThings = cp.parse(scoreString)
        return self.chordProgression(chordThings)


class Note :
    def __init__(self, note, time, length) :
        self.note = note
        self.time = time
        self.length = length
        
class TimingInfo:
    def __init__(self, beat_code, note_proportion, chord_multiplier, ppq):
        # Mapping from beat_code to fractions of a beat
        self.beat_mapping = {
            0: 1/16,
            1: 1/12,
            2: 1/8,
            3: 1/6,
            4: 1/4,
            5: 1/3,
            6: 1/2,
            7: 1/1
        }
        
        self.ppq = ppq
        self.beat_fraction = self.beat_mapping[beat_code]
        self.note_proportion = note_proportion
        self.chord_multiplier = chord_multiplier
        
        self.beat_length = self.ppq * self.beat_fraction
        self.note_length = self.beat_length * self.note_proportion
        self.chord_length = self.beat_length * self.chord_multiplier

    @staticmethod
    def distribute_pulses_evenly(k, n):
        rhythm = [0] * n
        step_size = n / k
        current_step = 0
        for _ in range(k):
            rhythm[int(round(current_step))] = 1
            current_step += step_size
        return rhythm

    def rhythm_generator(self, k, n):
        rhythm = TimingInfo.distribute_pulses_evenly(k, n)
        index = 0
        while True:
            yield rhythm[index]
            index = (index + 1) % len(rhythm)
    
    @staticmethod
    def chord_note_generator(chord):
        index = 0
        while True:
            yield chord[index]
            index = (index + 1) % len(chord)

    def chords(self, seq, start_time):
        all_notes = []
        current_time = start_time
        
        for c in seq:
            # Play all the notes of the chord simultaneously
            for note in c:
                all_notes.append({
                    'note': note,
                    'start_time': current_time,
                    'length': self.note_length * self.chord_multiplier * 0.5  # half the duration of chord's period
                })
            current_time += self.beat_length * self.chord_multiplier
        
        return all_notes

    def bassline(self, seq, k, n, start_time):
        all_notes = []
        current_time = start_time

        rhythm_gen = self.rhythm_generator(k, n)

        for c in seq:
            root_note = c[0] - 12  # root note one octave down
            beats_for_current_chord = 0
            
            while beats_for_current_chord < self.chord_multiplier:
                beat = next(rhythm_gen)
                if beat == 1:  # If the beat is a "hit"
                    all_notes.append({
                        'note': root_note,
                        'start_time': current_time,
                        'length': self.note_length
                    })
                current_time += self.beat_length
                beats_for_current_chord += 1
                # Reset the rhythm generator after finishing the beats for one chord
                if beats_for_current_chord == self.chord_multiplier:
                    rhythm_gen = self.rhythm_generator(k, n)

        return all_notes

    def arpeggiate(self, seq, k, n, start_time):
        all_notes = []
        current_time = start_time

        rhythm_gen = self.rhythm_generator(k, n)

        for c in seq:
            note_gen = TimingInfo.chord_note_generator(c)
            beats_for_current_chord = 0  # Counter to track beats for the current chord
            
            while beats_for_current_chord < self.chord_multiplier:
                beat = next(rhythm_gen)
                if beat == 1:  # If the beat is a "hit"
                    all_notes.append({
                        'note': next(note_gen),
                        'start_time': current_time,
                        'length': self.note_length
                    })
                current_time += self.beat_length
                beats_for_current_chord += 1
                # Reset the rhythm generator after finishing the beats for one chord
                if beats_for_current_chord == self.chord_multiplier:
                    rhythm_gen = self.rhythm_generator(k, n)

        return all_notes
