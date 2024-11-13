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
- it doesn't pass all the tests, but this is to do with quirks of Javascript equality tests.
- it runs successfully in the browser as part of a demonstration web-editor / web-app. (See haxe/for-distribution/web-app/, but note you'll have to build the js version of the library with Haxe and place it in the same directory as index.html)
- you can try this web version [here](https://gilbertlisterresearch.com/identity_assets/webapp/index.html) Not that it's still very much work in progress.

The status of the Haxe->C++ code is that :
- it successfully transpiles to C++, compiles and runs the tests
- the longer term goal is to build it into a VST or other plugin so it can run in any DAW (But this is for next year)

The status of the Haxe->Java code is that *there are issues*. Obviously it would be great to have in Java so I can write an Android app featuring the library. That's also a 2025 or 2026 goal.


### History

The "attic" directory of this repo contains 

- a) some old versions of Haskell code where I started playing with building chords in code
- b) [Sonic Pi](https://sonic-pi.net/) scripts.
- c) the original hand-written, Python script for FL Studio. 

You might as well ignore the Haskell code. It's very old and has no real interest. I may delete it soon.

The Sonic Pi is more interesting. That's where many of the ideas for Goldenpond came from. See my YouTube [video tutorials](https://www.youtube.com/watch?v=qd8SEL_rTNw&list=PLuBDEereAQUz2iiEZb7yGLH0Bzi52egGp) on using Sonic Pi which is where I developed many of the ideas. If I can get Haxe to transpile to Ruby or Sonic Pi, I may make the library available in this form too.

The Python code for FL Studio was the first time I wrote this in Python. And the first time I introduced a parser so we can now have the syntax we like, rather than relying on the host language. There's also another repository on GitHub with a more generic Python version of the library. Ignore it. THIS is the main, live development repo.


### Example

Here's a brief example of making a multi-track MIDI file from a chord progression

```
from goldenpond import Mode, ChordProgression, TimeManipulator


# Define a chord progression.
# The first two parameters are the key signature (we're in the key of C Major (midi note 48, MAJOR mode)
# The last is a string containing a number for each note.
# Numbers 1-7 mean the chord on that degree of our current scale. Ie 1 is the tonic, 5 the dominant etc.
# By default the chords are simple triads. Adding a 7 on the front makes them sevenths. A 9 makes them ninths. Eg. 93 is the 9th on the 3rd degree of the scale.


seq = ChordProgression(48,MAJOR,'71,74,-94,73,9(5/2),72,-75,91,!,71,74,-94,73,9(5/2),72,-75,-95,!,'*3)

# The TimeManipulator can take the list of chords as notes and spreads these notes in time
ti = TimeManipulator()
ti.setNoteLen(1.2).setChordLen(16).setPPQ(0.7)

# If we ask it for chords, we get all the notes of each chord at the same time. 
chords = ti.chords(seq, 0, 0)

# We can also ask it to arpeggiate the notes according to a 'Euclidean' rule for spreading n hits across k potential positions within the measure.
# In this example, we are spreading 7 hits across 12 positions

arps = ti.arpeggiate(seq, 7, 12, 1, 0)

# We now have two lines of Note objects. One representing chords, one the arpeggios, we now use pretty_midi to put these into MIDI format and write them to a file.

import pretty_midi

# Create a PrettyMIDI object
midi_data = pretty_midi.PrettyMIDI()

# Create an instrument instance
piano_program = pretty_midi.instrument_name_to_program('Acoustic Grand Piano')
piano = pretty_midi.Instrument(program=10)
piano2 = pretty_midi.Instrument(program=5)

pad = pretty_midi.Instrument(program=89)
pad2 = pretty_midi.Instrument(program=54)

for n in chords :
	end = n.start_time+n.length
	note = pretty_midi.Note(velocity=64, pitch=n.note, start=n.start_time, end=end)
	pad.notes.append(note)
	pad2.notes.append(note)
	
for n in arps :
	end = n.start_time+n.length
	note = pretty_midi.Note(velocity=64, pitch=n.note+24, start=n.start_time, end=end)
	piano.notes.append(note)
	note = pretty_midi.Note(velocity=64, pitch=n.note+12, start=n.start_time, end=end)	
	piano2.notes.append(note)
	
	
# Add the instrument to the PrettyMIDI object
midi_data.instruments.append(piano)
midi_data.instruments.append(pad)
midi_data.instruments.append(piano2)
midi_data.instruments.append(pad2)
# Save the MIDI file
midi_data.write('./gp_example.mid')


```
### Future

The experiment with Haxe has been a success. It's great having the same code available in a number of languages and environments. I am definitely interested in the GoldenPond as a VST (or other plugin) via C++ route. And, to a certain extent, the Java on Android option.

As far as the language is concerned, the next goals are to add more interesting voicings of the chords. Rather than simple triads and extensions. There's been some experimentation with automatic voice-leading but this often sounds horrible so it's not encouraged. But now the consolidation on the Haxe codebase is finished, I'm looking forward to tackling this problem.
