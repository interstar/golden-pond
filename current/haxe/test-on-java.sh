#!/bin/bash

# Clean output directories
rm -rf out/java/src/*
rm -rf out/java/obj/*

# Compile Haxe to Java
haxe build-java.hxml

# Compile Java files with the hxjava dependencies
cd out/java
javac -d obj -cp "obj:$(haxelib path hxjava | sed -n 2p)" src/haxe/root/*.java


# Run the test
cd obj
java -cp ".:../src:$(haxelib path hxjava | sed -n 2p)" haxe.root.TestGoldenPond

