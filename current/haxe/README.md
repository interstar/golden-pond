## GoldenPond in Haxe

Q: Why?

A: I want to use GoldenPond in different places : in the browser, on the desktop, on my Android phone, in FL Studio, maybe as a general VST plugin.

The frustration is all these places require you to write in different languages using different frameworks.

I've thought about getting AI to do that translation. And it works reasonably well.

But AI translation still needs heavy supervision and debugging. It's different work from doing it yourself. Nicer in some ways. But not trivial.

Whereas Haxe ([https://haxe.org/](https://haxe.org/)) is a language that allegedly transpiles to a dozen target languages and platforms out of the box, and without supervision.

So I've been trying it.

And it does seem to work. (Almost)

At least, this current Haxe version of GoldenPond is successfully transpiling to, and passing the unit tests in, Python, Javascript and C++. It compiles and runs in Java too, but some tests are currently failing, which seems to be due to a subtle difference in how Java handles equality which I haven't worked out yet.

That's what I'm currently trying to solve.

### How to run this

The build information for each target language is in the respective build file

#### Haxe Native 

    haxe --interp -cp src/goldenpond --main TestGoldenPond

runs the unit tests in the Haxe interpretter 

#### For Python

    haxe py-tests.hxml 

transpile to Python and run the unit tests in Python

    haxe py-lib.hxml

transpile just the library to Python, suitable for inclusion in other projects 

#### Javascript

    haxe js-tests.hxml

transpile to JS and run the unit tests in JS using node

    haxe js-site.hxml

transpile just the library to JS. Suitable for including in web-pages. 


#### C++

    haxe build-cpp.hxml

transpile and run the unit tests in C++

#### Java

    haxe build-java.hxml
    ./run-java.sh

Note that the Java build throws an error. The run-java.sh script seems to do the appropriate compiling with appropriate dependencies etc. You'll see that the unit tests fail with it though.

I know and understand very little about Haxe (and Java and C++) building at the moment, so this is still work in progress. And maybe needs a different approach.


### So this means ... ???

I'm hoping that the Haxe version of GoldenPond is now the definitive one. And everything else can be easily and painlessly derived from it.

Despite my initial pessimism, it seems even FL Studio can work with the transpilation from Haxe, though we have some custom scripts to kludge the FL specific code together with the python library. The PyPI version of goldenpond (as of 0.3.0) is also now derived from the Haxe code-base. All other python code is therefore deprecated.

JS is fine. And when you see Goldenpond on the web, that will come from Haxe.

Eventually I hope I'll figure out getting working Java from Haxe. And then try to compile it into an Android project.

Similarly the Haxe transpiled to C++ will be the basis of any VSTs or similar plugins.

These are both long term aspirations. But Haxe gets me closer to them than I've previously been.

