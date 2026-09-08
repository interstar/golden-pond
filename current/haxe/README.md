## GoldenPond in Haxe

Q: Why?

A: I want to use GoldenPond in different places : in the browser, on the desktop, on my Android phone, in FL Studio, maybe as a general VST plugin.

The frustration is all these places require you to write in different languages using different frameworks.

I've thought about getting AI to do that translation. And it works reasonably well.

But AI translation still needs heavy supervision and debugging. It's different work from doing it yourself. Nicer in some ways. But not trivial.

Whereas Haxe ([https://haxe.org/](https://haxe.org/)) is a language that allegedly transpiles to a dozen target languages and platforms out of the box, and without supervision.

So I've been trying it.

And it does seem to work. (Almost)

At least, this current Haxe version of GoldenPond is successfully transpiling to, and passing the unit tests in, Python, JavaScript, C++ and Java.

### How to run this

The individual target configurations are in the respective `.hxml` files. The
convenience scripts below run the common workflows from any directory.

#### Test all targets

    ./test_all_languages.sh

This runs the Haxe interpreter tests and the Python, JavaScript, C++, and Java
target tests.

#### Rebuild the library and distribution copies

    ./makeall.sh

This builds the Python, JavaScript, and Java outputs and refreshes the copies
used by the PyPI package, FL Studio, the web app, Signal, Strudel, and Xenwich.
It also installs the generated Python package into the active environment in
editable mode. To opt out:

    ./makeall.sh --skip-local-python

#### Build and deploy the web products

    ./build-and-deploy.sh

This runs the tests, rebuilds the library, builds Signal and Strudel, verifies
the web output directories, and uploads the web app, Signal, and Strudel
bundles. Use `--skip-upload` to build without deploying.

#### Haxe Native 

    haxe --interp -cp src/goldenpond --main TestGoldenPond

runs the unit tests in the Haxe interpreter 

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
    ./test-on-java.sh

The Java build works via the helper scripts in this directory, and the unit tests pass.

I know and understand very little about Haxe (and Java and C++) building at the moment, so this is still work in progress. And maybe needs a different approach.


### So this means ... ???

I'm hoping that the Haxe version of GoldenPond is now the definitive one. And everything else can be easily and painlessly derived from it.

Despite my initial pessimism, it seems even FL Studio can work with the transpilation from Haxe, though we have some custom scripts to assemble the FL-specific code with the Python library. The PyPI-style package is also derived from the Haxe code-base. All other Python code is therefore deprecated.

JS is fine. And when you see Goldenpond on the web, that will come from Haxe.

Eventually I hope I'll figure out getting working Java from Haxe. And then try to compile it into an Android project.

Similarly the Haxe transpiled to C++ will be the basis of any VSTs or similar plugins.

These are both long term aspirations. But Haxe gets me closer to them than I've previously been.
