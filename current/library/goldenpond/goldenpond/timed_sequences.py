from typing import List
from random import choice

from goldenpond.core import SeqTypes

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
    def chord_note_generator(chord, step=1):
        index = 0
        while True:
            yield chord[index]
            index = (index + step) % len(chord)

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


    def noteline(self, n_gen, r_gen, seq: List[List[int]], start_time):
        """Generic note creator, customize with specific note choosing algorithm passed as argument f"""
        all_notes = []
        current_time = start_time

        rhythm_gen = r_gen()

        for c in seq:
            beats_for_current_chord = 0
            note_gen = n_gen(c)
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
                    rhythm_gen = r_gen()

        return all_notes


    def bassline(self, seq: List[List[int]], k, n, start_time):
        def lowest(c) : 
            while True :
                yield c[0] - 12  # root note one octave down
        def rhythm() :
            return self.rhythm_generator(k, n)
            
        return self.noteline(lowest, rhythm, seq, start_time)

    def topline(self, seq: List[List[int]], k, n, start_time):
        def top(c) : 
            while True :
                yield c[-1] + 12  # top note one octave up
        def rhythm() :
            return self.rhythm_generator(k, n)                
        return self.noteline(top, rhythm, seq, start_time)

    def randline(self, seq: List[List[int]], k, n, start_time):
        def r(c) : 
            while True :
                yield choice(c) + 12  # random note one octave up
        def rhythm() :
            return self.rhythm_generator(k, n)
        return self.noteline(r, rhythm, seq,  start_time)
        
    def arpeggiate(self, seq: List[List[int]], k, n, start_time):
        def gen(c) :
            return TimeManipulator.chord_note_generator(c)
        def rhythm() :
            return self.rhythm_generator(k, n)            
        return self.noteline(gen, rhythm, seq,  start_time)
                
    def scaleline(self,seq:List[List[int]], k, n, start_time):
        """NOT IMPLEMENTED
        Problem is how to get the scale at this point.
        seq is just a list of chords which are list of notes. We've thrown away the information 
        necessary to say which key / mode we're in.
        We could pass these in as an argument, but modifiers like secondary 
        may have already taken us out of the key""" 
        
        
        return []
                
    def silentline(self, seq, k, n, start_time):
        def r(c) :
            while True :
                yield None
        def rhythm() :
            while True :
                yield 0
        return self.noteline(r,rhythm, seq, start_time)
        

    def grabCombo(self,seq,k,n,start_time,seqset) :
        notes = []
        for val in seqset :
            if val == SeqTypes.CHORDS :
                notes = notes + self.chords(seq,start_time)
                continue
            if val == SeqTypes.EUCLIDEAN :
                notes = notes + self.arpeggiate(seq,k,n,start_time)
                continue
            if val == SeqTypes.BASS :
                notes = notes + self.bassline(seq,k,n,start_time)
                continue
            if val == SeqTypes.TOP :
                notes = notes + self.topline(seq,k,n,start_time)
                continue
            if val == SeqTypes.RANDOM :
                notes = notes + self.randline(seq,k,n,start_time)
                continue
            if val == SeqTypes.SCALE :
                notes = notes + self.scaleline(seq,k,n,start_time)
                continue
        return notes
            
