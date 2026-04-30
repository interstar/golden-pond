haxe py-lib.hxml
haxe js-site.hxml
./build-java-lib.sh

cp out/python/goldenpond.py for-distribution/pypi/goldenpond/goldenpond.py
cp out/python/goldenpond.py for-distribution/fl/generated.py
cp out/js/goldenpond.js for-distribution/web-app/goldenpond.js
cp out/js/goldenpond.js for-distribution/xenwich/src/libs/goldenpond/goldenpond.js
# Strudel website imports ../../../../goldenpond.js from website/src/repl/ → this path
cp out/js/goldenpond.js for-distribution/strudel/goldenpond.js
