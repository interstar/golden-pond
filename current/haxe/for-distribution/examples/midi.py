from goldenpond import Mode, ChordProgression, TimeManipulator, ScoreUtilities

import pretty_midi

SeqTypes = TimeManipulator.getSeqTypes()

class TrackParams :
	def __init__(self, chan, k, n, offset, instrument) :
		self.chan = chan
		self.k = k
		self.n = n
		self.offset = offset
		self.instrument = instrument
		
class MidiMaker :
	def __init__(self,time_manipulator,chord_progression) :
		self.time_manipulator = time_manipulator
		self.chord_progression = chord_progression
		
	def make_midi_data(self,seqtype_dict) :
		# seqtype_dict is a dictionary of SeqType => TrackParams
		# Call like this : make_midi_data({SeqTypes.CHORDS:TrackParams(0,3,8,0,80),SeqTypes.EUCLIDEAN:TrackParams(1,3,8,0,5)})
		
		midi_data = pretty_midi.PrettyMIDI()
		
		def gated(seqtype,f) :
			def wrapper():
				if seqtype in seqtype_dict :
					params = seqtype_dict[seqtype]
					notes = f(params["k"],params["n"],params["chan"])
					notes = ScoreUtilities.transposeNotes(notes,params["offset"])
					instrument = pretty_midi.Instrument(program=params["instrument"])
					for n in notes :
						end = n.start_time+n.length
						note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.start_time, end=end)
						instrument.notes.append(note)
						midi_data.instruments.append(instrument)
			return wrapper
							
		chord_progression = self.chord_progression
		time_manipulator = self.time_manipulator
		
		gated(SeqTypes.CHORDS, lambda k, n, chan : time_manipulator.chords(chord_progression, chan, 0))()
		gated(SeqTypes.EUCLIDEAN, lambda k, n, chan : time_manipulator.arpeggiate(chord_progression, k, n, chan, 0))()
		gated(SeqTypes.BASS, lambda k, n, chan : time_manipulator.bassline(chord_progression, k, n, chan, 0))()
		gated(SeqTypes.TOP, lambda k, n, chan : time_manipulator.topline(chord_progression, k, n, chan, 0))()
		gated(SeqTypes.RANDOM, lambda k, n, chan : time_manipulator.randline(chord_progression, k, n, chan, 0))()
		
		return midi_data
		


		
		
		
		
		

