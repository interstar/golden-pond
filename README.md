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
    
Look at the examples.hs source-code, you'll see music is currently defined like this

    ta = concat [
            e4 (i  2),
	        e4 (v  2 ),
            e4 (vi 2),
	        e4 (iv 3 // Seventh )
	    ]
	
    tb = concat [
	    e4 (ii  2),
	    e4 (iii 2),
        e4 (vi  3 // Spread),
	    e4 (v	2)
	    ] 
	    where [i,ii,iii,iv,v,vi] = chordsInKey G
	
    song = ta ++ ta ++ tb ++ ta ++ tb ++ tab
	

Music is a list of Events. In this example, Chord events.

The functions that create chords are called i, ii, iii, iv etc. By default they're in the key of C but you can redefine them using the 
chordInKey function which takes an NNote (named note) as an argument. NNotes are enums that have the values A B C Bb Db etc.

You can annotate Chords using the infix // operator. It takes an Event value and an Annotation and adds the Annotation to the Event (though this is only currently meaningful for Chords)

The e4 function is a convenience that takes an Event and puts 3 Rests after it.



Credits 
-------

Golden Pond is based on Stephen Lavelle's Miditest :
[http://www.increpare.com/2008/10/basic-haskell-midi-file-output/](http://www.increpare.com/2008/10/basic-haskell-midi-file-output/)
