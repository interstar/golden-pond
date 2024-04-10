 


 


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
