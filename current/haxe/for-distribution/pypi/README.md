## GoldenPond Library

This is the Python version of the GoldenPond Library.

https://github.com/interstar/golden-pond


### Quick Start
<!--
    pip install goldenpond

Then make a local test file. For example
-->

```python
from goldenpond import Mode, ChordProgression, TimeManipulator, ChordLine, ArpLine, BassLine

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48, MINOR, seq)

# TimeManipulator with PPQ, chord duration and BPM
tm = TimeManipulator().setPPQ(96).setChordDuration(4).setBPM(120)

# Create lines with k, n, gateLength and rhythmicDensity parameters
chord_line = ChordLine(tm, prog, 1, 4, 0.8, 1.0)  # k=1, n=4, 80% gate length, density=1.0
arp_line = ArpLine(tm, prog, 7, 12, 0.5, 0.5)    # k=7, n=12, 50% gate length, density=0.5
bass_line = BassLine(tm, prog, 1, 4, 0.8, 0.25)   # k=1, n=4, 80% gate length, density=0.25

# Generate notes from each line
chords = chord_line.generateNotes(0, 0, 100)  # channel 0, velocity 100
arp = arp_line.generateNotes(0, 1, 100)      # channel 1, velocity 100
bass = bass_line.generateNotes(0, 2, 100)    # channel 2, velocity 100

print([x.toString() for x in chords])
print([x.toString() for x in arp])
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note, first_note.start_time, first_note.length))
print(arp[0].toString())
```

GoldenPond is a little language for defining chord-progressions, following the rules of functional harmony, in a convenient, programmer-friendly way.

See https://gilbertlisterresearch.com/GoldenPond.html for more details.

In this example, we define a chord-progression using the GoldenPond language, and assign it to variable `seq`.

The ChordProgression class knows how to parse the string which expresses the chord progression in the GoldenPond language. It must also be given a root note (in this example, MIDI note 48) and a mode (Major or Minor. We get these from the Mode class).

However, while a ChordProgression has successfully turned our sequence into a collection of pitch values, we don't (yet) have these notes organized into a score of events across time. This is where the Line classes come in.

Each Line class (ChordLine, ArpLine, BassLine, etc.) takes a TimeManipulator and ChordProgression and generates notes in different ways:

- ChordLine: plays all notes in each chord simultaneously
- ArpLine: plays chord notes as arpeggios using Euclidean rhythms
- BassLine: plays just the root notes using Euclidean rhythms
- TopLine: plays just the highest notes using Euclidean rhythms
- RandomLine: randomly selects notes from each chord

The Euclidean rhythm functions use a "[Euclidean Rhythm](https://en.wikipedia.org/wiki/Euclidean_rhythm)" algorithm to spread the notes in time. The values k and n passed as arguments control the rhythm pattern. For example, ArpLine(tm, prog, 7, 12, 0.5) will create an arpeggio with 7 pulses spread evenly across 12 steps, with notes 50% of their maximum length.

In this example, you can see we don't do anything with this data except print it out. GoldenPond doesn't play or render the audio. It's purely about parsing this programmer-oriented representation of chord-progressions into a simple data structure. See https://github.com/interstar/golden-pond/blob/main/current/haxe/for-distribution/examples/midi_example.py for an example of using it to make a MIDI file.

### The Obscure Genesis of this Code

The GoldenPond library is NOT written in Python. It's written in Haxe (https://haxe.org/), a programming language designed to be transpiled to a number of other languages including Python.

The [git-repository](https://github.com/interstar/golden-pond) contains this Haxe code and various scripts used in transpiling and building it into a number of forms. This Python library is just one of them. 