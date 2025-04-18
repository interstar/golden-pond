#!/bin/bash

# Clean output directories
rm -rf out/java/src/*
rm -rf out/java/obj/*

# Compile Haxe to Java
haxe build-java.hxml

# Compile Java files with the hxjava dependencies
cd out/java
javac -d obj -cp "obj:$(haxelib path hxjava | sed -n 2p)" src/haxe/root/*.java

# Create JAR file
jar cf goldenpond.jar -C obj .

# Create distribution directory if it doesn't exist
mkdir -p ../../for-distribution/java

# Copy JAR to distribution directory
cp goldenpond.jar ../../for-distribution/java/ 