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
    
Now load the library

    :l musiclib.hs
    
Have a look at the example chord sequence

    line1
	
And the derived bassline

	line2
        
And try writing it to a file

    createMidi "test.mid" line1 line2


Open the new test.mid file in totem, a sequencer or similar Midi file player.


How It Works
------------
    
Look at the source-code, you'll see *song* is currently defined like this

    ta = intersperse Rest [
	    i   2,
	    v   2,
	    vi  2,
	    iv  3
	    ] 
    tb = intersperse Rest [
	    ii  2,
	    iii 2,
	    vi  3,
	    v	2
	    ]
	
    song = ta ++ [Rest] ++ ta ++ [Rest] ++ tb ++ [Rest] ++ ta ++ [Rest] ++ tb ++ [Rest] ++ tb ++ [Rest]
	
Basically two sections are being defined ... ta and tb. Each is a list of AChord objects (do we call them "objects" in Haskell?) that represent chords and are being created through the functions i, ii, iii, iv etc. which take an octave as an argument and return the appropriate chord for that ). We also intersperse the chords with Rests (ie. a measure of playing nothing.)



Credits 
-------

Golden Pond is based on Stephen Lavelle's Miditest :
[http://www.increpare.com/2008/10/basic-haskell-midi-file-output/](http://www.increpare.com/2008/10/basic-haskell-midi-file-output/)
