## GoldenPond Library

This is the Python version of the GoldenPond Library.

https://github.com/interstar/golden-pond


### Quick Start
<!--
    pip install goldenpond

Then make a local test file. For example
-->

```
from goldenpond import Mode, ChordProgression, TimeManipulator

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48,MINOR,seq)
tm = TimeManipulator().setPPQ(0.8);
chords = tm.chords(prog,0,0)
arp = tm.arpeggiate(prog,7,12,1,0)
bass = tm.bassline(prog,4,8,2,0)

print([x.toString() for x in chords])
print([x.toString() for x in arp])
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note,first_note.start_time,first_note.length))
print(arp[0].toString())



```

GoldenPond is a little language for defining chord-progressions, following the rules of functional harmony, in a convenient, programmer-friendly way.

See https://gilbertlisterresearch.com/GoldenPond.html for more more details.

In this example, we define a chord-progression using the GoldenPond language, and assign it to variable `seq`.

The ChordProgression class knows how to parse the string which expresses the chord progression in the GoldenPond language. It must also be given a root note (in this example, MIDI note 48) and a mode (Major or Minor. We get these from the Mode class).

However, while a ChordProgression has successfully turned our sequence into a collection of pitch values, we don't (yet) have these notes organized into a score of events across time. This is the job of the TimeManipulator.

The TimeManipulator takes the ChordProgression and extracts different musical *lines* from it.

For example, the chords() function, returns the notes of each chord played simultaneously. While the arpeggiate() function returns those notes in the form of arpeggios (ie. each note in the chord slightly later than the previous one).

The arpeggiate function uses a "[Euclidean Rhythm](https://en.wikipedia.org/wiki/Euclidean_rhythm)" algorithm to spread the notes in time. The values 7 and 12 passed as arguments in this example, are the `k` and `n` values respectively. The final 0 argument is the initial start time of the whole sequence.

The bassline function returns just the root note of the chord. Again organized rhythmically according to the Euclidean algorithm. A topline function similarly returns the top notes of each chord. And a randline function return randomly chosen notes from the chord.





 
### The Obscure Genesis of this Code

The GoldenPond library is NOT written in Python. It's written in Haxe (https://haxe.org/), a programming language designed to be transpiled to a number of other languages including Python.

The [git-repository](https://github.com/interstar/golden-pond) contains this Haxe code and various scripts used in transpiling and building it into a number of forms. This Python library is just one of them. 
