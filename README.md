## Welcome to Golden Pond

### Introduction

GoldenPond is an evolving library / domain specific language for describing chord progressions and other higher-level concepts of music composition and theory, in code.

The goal is to help computer based composers and live-coders, including the author, to understand and apply more "advanced" music theory ideas by making them explicit in the language.

As a simple concrete example, GoldenPond has a notation for *secondary dominants*, allowing composers to invoke them when required, without having to manually calculate the notes that make them up. So the user simply has to write `(5/3)` to create the chord calculated by temporarily tonicizing the 3rd in our current key, and then finding the dominant, ie 5th, of it. In fact, this generalizes, so `(4/7)` would be the 4th of the key where our current 7th is the tonic.


GoldenPond was inspired by my frustration at realising that code offered so much expressivity for composing music, but that so much live-coding seemed stuck in replicating the behaviours of equipment designed for loop based music. We could describe a chord progression in a few keystrokes, but end up continually fiddling with a number representing the cutoff frequency of a low-pass filter. Text is a wonderfully expressive medium, but we're using it as the world's least ergonomically efficient knob!

Ultimately I'm guided by the question: "*could a music programming language be expressive enough that it would be possible to live-code music of the complexity of a Mahler Symphony, on the fly?*" What abstractions would such a language need? And would such a practice be viable, either technically or artistically?


### Code Reorganization

GoldenPond has gone through a number of iterations in a number of different languages. You are better off ignoring almost all of these.

**The most up-to-date and current version of the library, which defines the GoldenPond language, is the version written in [Haxe](https://haxe.org).** 

It's in the haxe/src subdirectory of this repo.

All other versions of the library you may find are either a) deprecated or b) automatically derived from the Haxe version. We are now transpiling this Haxe code into Python, Javascript, C++ and Java.

The status of the Haxe->Python code is that :

- it successfully transpiles, runs and passes all the tests as Python code.
- it can be built into a working pyscript for use in FL Studio's Piano Roll ([Python scripting for Piano Roll](https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/pianoroll_scripting_api.htm)). See the haxe/for_distribution/fl subdirectory for more about this.
- it is available on PyPI at [https://pypi.org/project/goldenpond/](https://pypi.org/project/goldenpond/) so you can just download it for your own projects 
- you can see a couple of scripts in haxe/for-distribution/examples/ which use the build Python library. Including for generating MIDI files.
- I am trying to get it working with [Renardo](https://renardo.org/), a Python based live-coding environment. I've not succeeded yet.

The status of the Haxe->JS code is that :
- it successfully transpiles and runs as JS
- it runs in the browser, and there's an online version you can play with in the browser at [https://gilbertlisterresearch.com/assets/goldenpond/index.html](https://gilbertlisterresearch.com/assets/goldenpond/index.html) It's still work in progress. 
- it doesn't pass all the unit tests, but this seems to be to do with quirks of Javascript equality testing.
- you can see haxe/for-distribution/web-app/ for where we develop the web-app, but note you'll have to build the js version of the library with Haxe and place it in the same directory as index.html

The status of the Haxe->C++ code is that :
- it successfully transpiles to C++, compiles and runs the tests
- the longer term goal is to build it into a VST or other plugin so it can run in any DAW (But this is for next year)

The status of the Haxe->Java code is that :
- it now transpiles to Java and runs and passes all the unit tests
- and bundles this into a JAR file
- you can build and run an example Java program ( /haxe/for-distribution/java/Example.java ) that uses the library
- Eventually there'll be an Android app featuring the library. That's also a 2025 or 2026 goal.


### History

The "attic" directory of this repo contains 

- a) some old versions of Haskell code where I started playing with building chords in code
- b) [Sonic Pi](https://sonic-pi.net/) scripts.
- c) the original hand-written, Python script for FL Studio. 

You might as well ignore the Haskell code. It's very old and has no real interest. I may delete it soon.

The Sonic Pi is more interesting. That's where many of the ideas for Goldenpond came from. See my YouTube [video tutorials](https://www.youtube.com/watch?v=qd8SEL_rTNw&list=PLuBDEereAQUz2iiEZb7yGLH0Bzi52egGp) on using Sonic Pi which is where I developed many of the ideas. If I can get Haxe to transpile to Ruby or Sonic Pi, I may make the library available in this form too.

The Python code for FL Studio was the first time I wrote this in Python. And the first time I introduced a parser so we can now have the syntax we like, rather than relying on the host language. There's also another repository on GitHub with a more generic Python version of the library. Ignore it. THIS is the main, live development repo.


### Example

Here's a brief example of making a multi-track MIDI file from a chord progression. Note you'll need the Python [pretty_midi](https://craffel.github.io/pretty-midi/) library. See [the tutorial](https://gilbertlisterresearch.com/goldenpond.html) for details of both the chord language for defining the progression (or sequence), and the rhythm language that use used for each of the lines here.

```
## You'll need pretty_midi, setuptools and goldenpond installed to run this

import sys
import os
from goldenpond import (
    Mode, ChordProgression, TimeManipulator, LineGenerator,
    RhythmLanguage, MenuHelper, RhythmicDensity,
    GoldenData, MidiInstrumentContext
)

# Create a GoldenData instance
data = GoldenData()
data.root = 48  # C3
data.mode = 0   # Major
data.chordSequence = "71,74,-94,73,9(5/2),72,-75,91,!m,71,74,-94,73,9(5/2),72,-75,-95,!M,"*2
data.stutter = 0
data.bpm = 120
data.chordDuration = 4

# Add lines with their instrument contexts
data.addLine("1/4 c 1", MidiInstrumentContext(0, 64, 0.75, 0))  # Play full chord on note in a 4 step pattern, 
data.addLine("8/12 > 1", MidiInstrumentContext(1, 64, 0.5, 0))   # 8 notes in 12 steps, ascending arpeggio
data.addLine("tt.<<.>. 1", MidiInstrumentContext(2, 64, 0.75, -12))  # two top notes, two descending notes and one ascendin
data.addLine("3/8 r 1", MidiInstrumentContext(3, 64, 0.75, 12))  # Random notes in a tresillo (3 in 8 Euclidean)

# Create line generators
generators = [data.makeLineGenerator(i) for i in range(len(data.lines))]

# Generate notes from each line
chords = generators[0].generateNotes(0)
arps = generators[1].generateNotes(0)
bass = generators[2].generateNotes(0)
flute = generators[3].generateNotes(0)

import pretty_midi

# Create a PrettyMIDI object
midi_data = pretty_midi.PrettyMIDI()

# Create instrument instances
piano_program = pretty_midi.instrument_name_to_program('Acoustic Grand Piano')
piano = pretty_midi.Instrument(program=10)
piano2 = pretty_midi.Instrument(program=5)
pad = pretty_midi.Instrument(program=89)
pad2 = pretty_midi.Instrument(program=54)
bass_program = pretty_midi.Instrument(program=32)
flute_program = pretty_midi.Instrument(program=76)

# Add notes to instruments
for n in chords:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    pad.notes.append(note)
    pad2.notes.append(note)
    
for n in arps:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    piano.notes.append(note)
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue() + 12),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    piano2.notes.append(note)

for n in bass:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    bass_program.notes.append(note)

for n in flute:
    note = pretty_midi.Note(
        velocity=int(n.velocity),
        pitch=int(n.getMidiNoteValue()),
        start=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm),
        end=n.getStartTime() / data.makeTimeManipulator().ppq * (60.0 / data.bpm) + 
            n.getLength() / data.makeTimeManipulator().ppq * (60.0 / data.bpm)
    )
    flute_program.notes.append(note)

# Add the instruments to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)
midi_data.instruments.append(bass_program)
midi_data.instruments.append(flute_program)

# Save the MIDI file
midi_data.write('./gp_example.mid')

print("MIDI file saved as gp_example.mid")


```
### Future

The experiment with Haxe has been a success. It's great having the same code available in a number of languages and environments. I am definitely interested in the GoldenPond as a VST (or other plugin) via C++ route. And, to a certain extent, the Java on Android option.

As far as the language is concerned, the next goals are to add more interesting voicings of the chords. Rather than simple triads and extensions. There's been some experimentation with automatic voice-leading but this often sounds horrible so it's not encouraged. But now the consolidation on the Haxe codebase is finished, I'm looking forward to tackling this problem.
