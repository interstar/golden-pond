Golden Pond
===========

An exercise in learning Haskell and music theory at the same time. Basically a Haskell program to let me quickly pump out sequences of chords in a .mid file. Personally I'm then importing these into [FL Studio](http://www.image-line.com/flstudio/) but you might have other plans.

Quick Start
-----------

Make sure you have Haskell (the ghci) installed

Use cabal to install the HCodecs (which allows you to create MIDI files)


    cabal install HCodecs


Then go into ghci with

    ghci
    
Now load the examples

    :l examples.hs
    
Have a look at the example chord sequence

    line1
	
And the derived bassline

	line2
        
And try writing it to a file

    createMidi "test.mid" line1 line2


Open the new test.mid file in totem, a sequencer or similar Midi file player.


How It Works
------------
    
Look at the examples.hs source-code, you'll see an example piece of music is currently defined like this :

	[i,ii,iii,iv,v,vi] = chordsInKey C

	ta = concat [
			(i  2 // Spread ) % 4,
			(vi 2) % 4,
			(iv 3) % 4,
			(v  2) % 4
		]
		
	tb = concat [
		(ii  2) % 4,
		(v	2) % 4,
		(iii 2) % 4,
		(vi  3 // Spread) % 4
		] 

	tb2 = concat [
		(ii  2) % 4,
		(v 2 // Spread) % 4,
		(vi  3 // Spread) % 4,
		(vi	3 // Seventh // Spread) % 4
		]
		where [i,ii,iii,iv,v,vi] = chordsInKey G


	line1 = (4 .* ta) ++ (2 .* tb) ++ (4 .* ta) ++ (4 .* tb) ++ (2 .* tb2) ++ (4 .* ta)
	newBass = chordsToMelody (\e (Chord memchord) -> chordToBassNote memchord)
	line2 = newBass line1 Rest

	
Music is a list of Events which can be one of Chord, Note or Rest. 
(Note that technically Rest creates a Midi NoteOff message at pitch 0. This probably needs changing.)

The functions that create chords are called i, ii, iii, iv etc. Here they're defined in the key of C, but you can redefine them local to a particular 
sequence by putting a chordInKey definition in the *where* clause. 

chordsInKey takes an NNote (named note) as an argument. NNotes are enums that have the values A B C Bb Db etc.

You can annotate Chords using the infix // operator. It takes an Event value and an Annotate and returns a new Event with the Annotate added.
(Currently only Chords have meaningful annotations, such as Spread (across two octaves), Seventh etc.)

You can space out events by putting Rests between them using the convenience % operator : event % n creates a list containing the Event 
followed by n-1 Rests. 

So (i 3) % 4 means "the i chord in the third octave, then 3 Rests"

I've defined another convenience operator :  n .* [Event] which just repeats the Event list n times. You see it in the above example 
being used to repeat the ta section 4 times and the tb sections twice.

The function chordsToMelody is a higher-order function that takes a function f and a list of (typically Chord) Events and returns a second list of Events derived from the first, according to the criteria in f. 

f is defined as taking two arguments : the current Event at any time step and a "memory" which contains the last Chord event. In my example above, my f is a lambda expression (\e (Chord memchord) -> chordToBassNote memchord) which uses the function chordToBassNote. chordToBassNote itself just takes a chord and returns its root one octave down (unless the chord is already fairly low in which case it just returns the root).

The effect of putting this f through chordsToMelody is to return a simplistic bass-line. But you can design as sophisticated f as you like to try to derive more complex and interesting melodies.



Credits 
-------

Golden Pond is based on Stephen Lavelle's Miditest :
[http://www.increpare.com/2008/10/basic-haskell-midi-file-output/](http://www.increpare.com/2008/10/basic-haskell-midi-file-output/)
