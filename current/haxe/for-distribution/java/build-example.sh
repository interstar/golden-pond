#!/bin/bash

# Create output directory if it doesn't exist
mkdir -p out/java/example

# Compile the example
javac -cp goldenpond.jar Example.java -d out/java/example

# Run the example
java -cp out/java/example:goldenpond.jar Example 