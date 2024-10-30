package;

import Math;
import Mode;
import ChordParser;

import ScoreUtilities;

 
@:expose
enum SeqTypes {
    CHORDS;
    EUCLIDEAN;
    BASS;
    TOP;
    RANDOM;
    SCALE;
}

@:expose
enum DivisionValue {
  SIXTEENTH;
  TWELFTH;
  EIGHTH;
  SIXTH;
  QUARTER;
  THIRD;
  HALF;
  WHOLE;
}

interface IRhythmGenerator {
    public function hasNext():Bool;
    public function next():Int;
}

class SilentIterator implements IRhythmGenerator {
    public function new() {}

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        return 0;
    }
}

class RhythmGenerator implements IRhythmGenerator {
    private var rhythm:Array<Int>;
    private var index:Int;

    public function new(k:Int, n:Int) {
        this.rhythm = TimeManipulator.distributePulsesEvenly(k, n);
        this.index = 0;
    }

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        var beat = this.rhythm[this.index];
        this.index = (this.index + 1) % this.rhythm.length;
        return beat;
    }
}

class ArpIterator   {
    private var chord:Array<Int>;
    private var noteIndex:Int;
    private var step:Int;

    public function new(chord:Array<Int>, step:Int = 1) {
        this.chord = chord;
        this.noteIndex = 0;
        this.step = step;
    }

    public function hasNext():Bool {
        return true;
    }

    public function next():Int {
        var note = this.chord[this.noteIndex % this.chord.length];
        this.noteIndex = (this.noteIndex + this.step) % this.chord.length;
        return note;
    }
}


class NoteSelectorIterator  {
    private var chords:Array<Array<Int>>;
    private var chordIndex:Int;
    private var noteSelector: Array<Int> -> Int;

    public function new(chords:ChordProgression, noteSelector: Array<Int> -> Int) {
        this.chords = chords.toNotes();
        this.chordIndex = 0;
        this.noteSelector = noteSelector;
    }

    public function hasNext():Bool {
        return this.chordIndex < this.chords.length;
    }

    public function next():Int {
        var note = this.noteSelector(this.chords[this.chordIndex]);
        this.chordIndex++;
        return note;
    }
}

@:expose
class MenuHelper {
  public static function getDivisionNames():Array<String> {
    return ["1/16", "1/12", "1/8", "1/6", "1/4", "1/3", "1/2", "1"];
  }
  public static function getDivisionValues():Array<DivisionValue> {
    return [SIXTEENTH,TWELFTH,EIGHTH,SIXTH,QUARTER,THIRD,HALF,WHOLE];
  }
  public static function getDivisionFor(i:Int):DivisionValue {
    return getDivisionValues()[i];
  }
  public static function divisionValue2Numeric(dv:DivisionValue):Float {
    return [SIXTEENTH=>1/16, TWELFTH=>1/12, EIGHTH=>1/8, SIXTH=>1/6, QUARTER=>1/4, THIRD=>1/3, HALF=>1/2, WHOLE=>1][dv];
  }
  
}

@:expose
class TimeManipulator {
    public var ppq:Float;
    public var beatFraction:Float;
    public var noteProportion:Float;
    public var chordMultiplier:Float;
    public var beatLength:Float;
    public var noteLength:Float;
    public var chordLength:Float;


  //public function new(beatCode:Int, noteProportion:Float, chordMultiplier:Float, ppq:Int) {
    public function new() {
        this.ppq = 1000;
        this.beatFraction = 1/4;
        this.noteProportion = 0.8;
        this.chordMultiplier = 16;
	recalc();
    }

    private function recalc() {
        this.beatLength = this.ppq * this.beatFraction;
        this.noteLength = this.beatLength * this.noteProportion;
        this.chordLength = this.beatLength * this.chordMultiplier;
    }
  
    public function setDivision(dv:DivisionValue):TimeManipulator {
      this.beatFraction = MenuHelper.divisionValue2Numeric(dv);
      recalc();
      return this;
    }

    public function setNoteLen(np:Float):TimeManipulator {
      this.noteProportion=np;
      recalc();
      return this;
    }

    public function setChordLen(cl:Float):TimeManipulator {
      this.chordMultiplier = cl;
      recalc();
      return this;
    }

    public function setPPQ(p:Float):TimeManipulator {
      this.ppq = p;
      recalc();
      return this;
    }
  
    // Ensure SeqTypes accessible
    public function getSeqTypes() {
        return SeqTypes;	
    }
 
    public static function distributePulsesEvenly(k:Int, n:Int):Array<Int> {
        var rhythm = new Array<Int>();
        for (i in 0...n) rhythm.push(0);
        var stepSize = n / k;
        var currentStep = 0.0;
        for (i in 0...k) {
            rhythm[Math.round(currentStep)] = 1;
            currentStep += stepSize;
        }
        return rhythm;
    }

    public function chords(seq:ChordProgression, startTime:Float):Array<Note> {
        var allNotes = new Array<Note>();
        var currentTime = startTime;
        for (c in seq.toNotes()) {
            for (note in c) {
                allNotes.push(new Note(note, currentTime, this.noteLength * this.chordMultiplier * 0.5));
            }
            currentTime += this.beatLength * this.chordMultiplier;
        }
        return allNotes;
    }

    public function noteline(seq:ChordProgression, noteSelector: Array<Int> -> Int, rhythmGen: IRhythmGenerator, startTime:Float):Array<Note> {
        var allNotes = new Array<Note>();
        var currentTime = startTime;
        for (c in seq.toNotes()) {
            var beatsForCurrentChord = 0;
            while (beatsForCurrentChord < this.chordMultiplier) {
                var beat = rhythmGen.next();
                if (beat == 1) {
                    allNotes.push(new Note(noteSelector(c), currentTime, this.noteLength));
                }
                currentTime += this.beatLength;
                beatsForCurrentChord++;
            }
        }
        return allNotes;
    }

    public function bassline(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
        var nGen = new NoteSelectorIterator(seq, function(chord:Array<Int>):Int { return chord[0] - 12; });
        var rGen = new RhythmGenerator(k, n);
        return this.noteline(seq, function(chord:Array<Int>):Int { return chord[0] - 12; }, rGen, startTime);
    }

    public function topline(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
        var nGen = new NoteSelectorIterator(seq, function(chord:Array<Int>):Int { return chord[chord.length - 1] + 12; });
        var rGen = new RhythmGenerator(k, n);
        return this.noteline(seq, function(chord:Array<Int>):Int { return chord[chord.length - 1] + 12; }, rGen, startTime);
    }

    public function randline(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
        var nGen = new NoteSelectorIterator(seq, function(chord:Array<Int>):Int { return chord[Math.floor(Math.random() * chord.length)] + 12; });
        var rGen = new RhythmGenerator(k, n);
        return this.noteline(seq, function(chord:Array<Int>):Int { return chord[Math.floor(Math.random() * chord.length)] + 12; }, rGen, startTime);
    }

    public function arpeggiate(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
		var rGen = new RhythmGenerator(k, n);
		var allNotes = new Array<Note>();
		var currentTime = startTime;

		for (c in seq.toNotes()) {
		    var beatsForCurrentChord = 0;
		    var arpIter = new ArpIterator(c);
		    while (beatsForCurrentChord < this.chordMultiplier) {
		        var beat = rGen.next();
		        if (beat == 1) {
		            allNotes.push(new Note(arpIter.next(), currentTime, this.noteLength));
		        }
		        currentTime += this.beatLength;
		        beatsForCurrentChord++;
		    }
		    rGen = new RhythmGenerator(k, n); // Reset the rhythm generator after finishing the beats for one chord
		}
		return allNotes;
	}

    public function scaleline(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
        return [];
    }

    public function silentline(seq:ChordProgression, k:Int, n:Int, startTime:Float):Array<Note> {
        var rGen = new SilentIterator();
        return this.noteline(seq, function(chord:Array<Int>):Int { return 0; }, rGen, startTime);
    }

    public function grabCombo(seq:ChordProgression, k:Int, n:Int, startTime:Float, seqset:Array<SeqTypes>):Array<Note> {
        var notes = new Array<Note>();
        for (val in seqset) {
            switch (val) {
                case SeqTypes.CHORDS:
                    notes = notes.concat(this.chords(seq, startTime));
                case SeqTypes.EUCLIDEAN:
                    notes = notes.concat(this.arpeggiate(seq, k, n, startTime));
                case SeqTypes.BASS:
                    notes = notes.concat(this.bassline(seq, k, n, startTime));
                case SeqTypes.TOP:
                    notes = notes.concat(this.topline(seq, k, n, startTime));
                case SeqTypes.RANDOM:
                    notes = notes.concat(this.randline(seq, k, n, startTime));
                case SeqTypes.SCALE:
                    notes = notes.concat(this.scaleline(seq, k, n, startTime));
            }
        }
        return notes;
    }
}

