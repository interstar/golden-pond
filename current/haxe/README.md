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

For Python

    haxe build-py.hxml 
    
Javascript

    haxe build-js.hxml

C++

    haxe build-cpp.hxml
    
Java

    haxe build-java.hxml
    ./run-java.sh

Note that the Java build throws an error. The run-java.sh script seems to do the appropriate compiling with appropriate dependencies etc. You'll see that the unit tests fail with it though.

I know and understand very little about Haxe (and Java and C++) building at the moment, so this is still work in progress. And maybe needs a different approach.


### So this means ... ???

I'm not sure yet. I would like it to mean that this Haxe version of GoldenPond is now the definitive one. And everything else can be easily and painlessly derived from it.

That's not the case. In particular I think it very unlikely the FL Studio GoldenPond script (which is already carved out of the Python version by hand, with some manual tweaks) can ever be the one derived from Haxe. Pyscript in FL Studio is not proper and up-to-date Python, so needed some customization to work. I doubt the convoluted and complex Python that Haxe spits out will run there.

Therefore for the forseeable future, I guess I'll be maintaining a Python version of GoldenPond, distinct from the Haxe version. At least for use in FL Studio. And so, in the near future, the Python library version on PyPI will also continue to be hand made Python. 

Possibly if I get confident enough with Haxe, I may one day explore making the PyPI distribution be the Haxe derivative. 

At the same time, I'm impressed enough that I think that the Haxe version will be the basis for any Javascript, Java or C++ versions of the library. There was a Javascript version of the library in this repository, translated with the help of ChatGPT from the Python version. It is now deprecated. In future, I'll be looking to use JS transpiled from Haxe in any Javascript / browser-based applications using GoldenPond.

Eventually I hope I'll figure out getting working Java from Haxe. And then try to compile it into an Android project.

Similarly the Haxe transpiled to C++ will be the basis of any VSTs or similar plugins.

These are both long term aspirations. But Haxe gets me closer to them than I've previously been.



