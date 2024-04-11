from typing import List


class Note :
    def __init__(self, note, time, length) :
        self.note = note
        self.time = time
        self.length = length
        
class TimeManipulator:
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
        rhythm = TimeManipulator.distribute_pulses_evenly(k, n)
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

    def chords(self, seq: List[List[int]], start_time):
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

    def bassline(self, seq: List[List[int]], k, n, start_time):
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

    def arpeggiate(self, seq: List[List[int]], k, n, start_time):
        all_notes = []
        current_time = start_time

        rhythm_gen = self.rhythm_generator(k, n)

        for c in seq:
            note_gen = TimeManipulator.chord_note_generator(c)
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
