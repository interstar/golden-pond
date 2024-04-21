## Welcome to Golden Pond

### Introduction

GoldenPond is an evolving library / domain specific language for describing chord progressions and other higher-level concepts of music composition and theory, in code.

The goal is to help computer based composers and live-coders, including the author, to understand and apply more "advanced" music theory ideas by making them explicit in the language.

As a simple concrete example, GoldenPond has a notation for *secondary dominants*, allowing composers to invoke them when required, without having to manually calculate the notes that make them up. So the user simply has to write `(5/3)` to create the chord calculated by temporarily tonicizing the 3rd in our current key, and then finding the dominant, ie 5th, of it. In fact, this generalizes, so `(4/7)` would be the 4th of the key where our current 7th is the tonic.


GoldenPond was inspired by my frustration at realising that code offered so much expressivity for composing music, but that so much live-coding seemed stuck in replicating the behaviours of equipment designed for loop based music. We could describe a chord progression in a few keystrokes, but end up continually fiddling with a number repreenting the cutoff frequency of a low-pass filter. Text is a wonderfully expressive medium, but we're using it as the world's least ergonomically efficient knob!

Ultimately I'm guided by the question: "*could a music programming language be expressive enough that it would be possible to live-code music of the complexity of a Mahler Symphony, on the fly?*" What abstractions would such a language need? And would such a practice be viable, either technically or artistically?


### Code Reorganization

The first version of the GoldenPond code was written in 2013 in Haskell. While an interesting learning exercise, it lacked most of the features of later versions and is currently abandoned. You can see the code in `attic/hs` of this repository

GoldenPond was then rewritten in Python for use with the [FoxDot](https://github.com/Qirky/FoxDot) live-coding environment. You can find the current repository for this code at [https://github.com/interstar/goldenpond-py](https://github.com/interstar/goldenpond-py). However that is also deprecated. The plan is shortly to make the new Python codebase compatible with FoxDot and bring it into this repository.

I then further developed some of my ideas for generating chord progressions in a series of YouTube [video tutorials](https://www.youtube.com/watch?v=qd8SEL_rTNw&list=PLuBDEereAQUz2iiEZb7yGLH0Bzi52egGp) using [Sonic Pi](https://sonic-pi.net/). Some of the most interesting ideas came out of those videos. There was not a single code-base, just some functions to be pasted into a Sonic Pi window. But I will, for now, collect examples of these scripts in `attic/sonic-pi`. Eventually the new GoldenPond codebase will be translated to Sonic Pi as well.

The latest incarnation of GoldenPond is rewritten from scratch in Python. And was initially inspired by the fact that FL Studio now supports [Python scripting for its piano-roll](https://www.image-line.com/fl-studio-learning/fl-studio-online-manual/html/pianoroll_scripting_api.htm). This is the first time I decided to include a parser. Previously the little language of the music had to be embedded in the syntax of the hosting language, whether Haskell, Python or Ruby (Sonic Pi) and was therefore constrained by them.

Now, though, we can have the language and syntax for describing music that we actually want. Yay!

This version includes a generic Python library for parsing what we will now call the GoldenPond language, and creating data-structures representing chords and arpeggios from it. This library can then be used from a number of contexts. The main one right now is FL Studio's piano-roll. But there is also a simple FluidSynth player for testing. And my aim is to have it working with FoxDot soon.

The library is in `current/python/library`. The FL Studio script in `current/python/fl studio`. You'll notice that we currently just copy and paste the whole library into the pyscript file. This is for the convenience of FL Studio users, to give them a single file download.


Then there's a more ambitious goal. The problem with writing music software is that there are many specific targets for where it needs to run. I'm currenly looking into (with the help of ChatGPT, natch) automatic translation of this Python code to other languages. My first goal is to have a version in ClojureScript that I can run in browser based applications. And longer term thinking how to have a version in VST form. 

These experiments are under way and will end up in this git repo when there's something worth showing.

Meanwhile, GoldenPond as an idea, and actually usable code, is now a thing. And I'm very excited about it. I'm starting to consolidate it, together with some of my other music/code projects under a new "micro-research lab" : [Gilbert Lister Research](http://gilbertlisterresearch.com) That's where you'll find more documentation / tutorials too.
