/*
GoldenPond Rhythm Pattern Language
Copyright (C) 2025 Phil Jones

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
*/

// Core type for note selection
@:expose
enum SelectorType {
    Ascending;         
    Descending;       
    Repeat;           
    FullChord;        
    ChordWithBass;    // Chord with root doubled one octave lower
    Drop2;            // Drop 2 voicing - second highest note dropped an octave
    Random;           
    RandomFromScale;   // New selector for random scale degree
    SpecificNote(n:Int);
    Rest;
    TopNote;
    ScaleDegree(n:Int);  // For selecting from scale (1-7)
}

// Interface that Line classes use
interface IRhythmGenerator {
    function hasNext():Bool;
    function next():SelectorType;
    function reset():Void;
    function getPatternLength():Int;  // Original pattern length
    function getTotalSteps():Int;     // Total steps across one density window
    function getStepLengthInChords():Float;
    function parseFailed():Bool;      // New method to check if parsing failed
    function getSteps():Array<SelectorType>;
}

@:expose
class DensityRatio {
    public var numerator:Int;
    public var denominator:Int;

    public function new(numerator:Int, denominator:Int = 1) {
        this.numerator = numerator;
        this.denominator = denominator;
    }

    public function getCycleLengthInChords():Float {
        return denominator / numerator;
    }

    public function getStepLengthInChords(patternLength:Int):Float {
        return getCycleLengthInChords() / patternLength;
    }
}

// Base class for explicit patterns
@:expose
class ExplicitRhythmGenerator implements IRhythmGenerator {
    private var steps:Array<SelectorType>;
    private var index:Int;
    private var densityRatio:DensityRatio;
    private var totalSteps:Int;
    private var stepLengthInChords:Float;

    public function new(steps:Array<SelectorType>, densityNumerator:Int, densityDenominator:Int = 1) {
        this.steps = steps;
        this.index = 0;
        this.densityRatio = new DensityRatio(densityNumerator, densityDenominator);
        this.totalSteps = steps.length * densityNumerator;
        this.stepLengthInChords = this.densityRatio.getStepLengthInChords(steps.length);
    }

    public function hasNext():Bool {
        return true;  // Always cycles
    }

    public function next():SelectorType {
        var selector = steps[index];
        index = (index + 1) % steps.length;
        return selector;
    }

    public function reset():Void {
        index = 0;
    }

    public function getPatternLength():Int {
        return steps.length;
    }
    
    public function getTotalSteps():Int {
        return totalSteps;
    }

    public function getStepLengthInChords():Float {
        return stepLengthInChords;
    }
    
    public function parseFailed():Bool {
        return false;  // Normal generators never fail
    }

    public function getSteps():Array<SelectorType> {
        return steps;
    }
}

// Simple distribution algorithm
@:expose
class SimpleRhythmGenerator extends ExplicitRhythmGenerator {
    public function new(k:Int, n:Int, selector:SelectorType, densityNumerator:Int, offset:Int = 0, densityDenominator:Int = 1) {
        var steps = [];
        for (i in 0...n) steps.push(Rest);
        
        // Special case for k=n
        if (k >= n) {
            for (i in 0...n) {
                steps[i] = selector;
            }
        }
        // Normal case - distribute pulses evenly
        else {
            // Calculate the step size as a floating point value
            var stepSize = n / k;
            var currentStep = 0.0;
            
            // For each pulse, calculate its position using the same algorithm as the Python function
            for (i in 0...k) {
                // Calculate position using the formula: Math.floor(currentStep + 0.5)
                // This rounds to the nearest integer
                var pos = Math.floor(currentStep + 0.5);
                
                // Apply offset and wrap around
                pos = (pos + offset) % n;
                
                steps[pos] = selector;
                
                // Increment currentStep by stepSize for next iteration
                currentStep += stepSize;
            }
        }
        
        super(steps, densityNumerator, densityDenominator);
    }
}

// Bjorklund's algorithm implementation
@:expose
class BjorklundRhythmGenerator extends ExplicitRhythmGenerator {
    public function new(k:Int, n:Int, selector:SelectorType, densityNumerator:Int, offset:Int = 0, densityDenominator:Int = 1) {
        // Ensure k and n are valid
        k = Std.int(Math.max(0, Math.min(k, n)));
        n = Std.int(Math.max(1, n));
        
        // Generate the pattern
        var pattern = [];
        
        // Special case for k=0 or k=n
        if (k <= 0) {
            pattern = [for (i in 0...n) Rest];
        } else if (k >= n) {
            pattern = [for (i in 0...n) selector];
        } else {
            // Generate Bjorklund pattern
            var bits = bjorklund(k, n);
            
            // Apply offset by rotating the pattern
            if (offset > 0) {
                // Create a new array for the rotated pattern
                var rotated = [for (i in 0...n) false];
                
                // Shift each bit by the offset
                for (i in 0...n) {
                    // Calculate the new position after offset
                    // Note: we need to rotate left, so we subtract the offset
                    var newPos = (i - offset + n) % n;
                    rotated[i] = bits[newPos];
                }
                
                bits = rotated;
            }
            
            // Convert bits to pattern
            pattern = bits.map(function(bit) {
                return bit ? selector : Rest;
            });
        }
        
        super(pattern, densityNumerator, densityDenominator);
    }
    
    // Implementation of Bjorklund's algorithm for traditional rhythms
    private function bjorklund(k:Int, n:Int):Array<Bool> {
        if (k <= 0) return [for (i in 0...n) false];
        if (k >= n) return [for (i in 0...n) true];
        
        // Use the standard algorithm for all cases
        return standardBjorklund(k, n);
    }
    
    // Standard Bjorklund algorithm implementation based on the Python version
    private function standardBjorklund(k:Int, n:Int):Array<Bool> {
        var pattern:Array<Int> = [];
        var counts:Array<Int> = [];
        var remainders:Array<Int> = [];
        var divisor = n - k;
        remainders.push(k);
        var level = 0;
        
        // Calculate counts and remainders
        while (true) {
            counts.push(Math.floor(divisor / remainders[level]));
            remainders.push(divisor % remainders[level]);
            divisor = remainders[level];
            level = level + 1;
            if (remainders[level] <= 1) {
                break;
            }
        }
        counts.push(divisor);
        
        // Build the pattern recursively
        buildPatternRecursive(level, counts, remainders, pattern);
        
        // Rotate the pattern to start with a hit (1)
        var firstOneIndex = pattern.indexOf(1);
        if (firstOneIndex > 0) {
            pattern = pattern.slice(firstOneIndex).concat(pattern.slice(0, firstOneIndex));
        }
        
        // Convert to boolean array
        return pattern.map(function(val) {
            return val == 1;
        });
    }
    
    // Helper function to build the pattern recursively
    private function buildPatternRecursive(level:Int, counts:Array<Int>, remainders:Array<Int>, pattern:Array<Int>) {
        if (level == -1) {
            pattern.push(0);
        } else if (level == -2) {
            pattern.push(1);
        } else {
            for (i in 0...counts[level]) {
                buildPatternRecursive(level - 1, counts, remainders, pattern);
            }
            if (remainders[level] != 0) {
                buildPatternRecursive(level - 2, counts, remainders, pattern);
            }
        }
    }
}

// Special generator for when parsing fails
@:expose
class ParseFailedRhythmGenerator implements IRhythmGenerator {
    private var patternLength:Int;
    
    public function new(patternLength:Int = 1) {
        this.patternLength = patternLength;
    }
    
    public function hasNext():Bool {
        return true;
    }
    
    public function next():SelectorType {
        return Rest;  // Always returns Rest
    }
    
    public function reset():Void {
        // Nothing to reset
    }
    
    public function getPatternLength():Int {
        return patternLength;
    }
    
    public function getTotalSteps():Int {
        return patternLength;  // For failed patterns, total steps equals pattern length
    }

    public function getStepLengthInChords():Float {
        return 1.0;
    }
    
    public function parseFailed():Bool {
        return true;  // This generator always indicates parsing failed
    }

    public function getSteps():Array<SelectorType> {
        return [];
    }
}

// Parser that creates appropriate generator
@:expose
class RhythmLanguage {
    /**
     * Creates a rhythm generator from a pattern string.
     * 
     * @param pattern The pattern string in rhythm language format
     * @return IRhythmGenerator The created rhythm generator, or a ParseFailedRhythmGenerator if the pattern is invalid
     */
    public static function makeRhythmGenerator(pattern:String):IRhythmGenerator {
        return parse(pattern);
    }
    
    /**
     * Parses a pattern string and creates the appropriate rhythm generator.
     * 
     * @param input The pattern string to parse
     * @return IRhythmGenerator The created rhythm generator, or a ParseFailedRhythmGenerator if the pattern is invalid
     */
    public static function parse(input:String):IRhythmGenerator {
        input = StringTools.trim(input);
        
        // Try parsing as Euclidean pattern first
        var euclidean = parseEuclidean(input);
        if (!euclidean.parseFailed()) return euclidean;
        
        // Try parsing as explicit pattern
        var explicit = parseExplicit(input);
        if (!explicit.parseFailed()) return explicit;
        
        // If all parsing attempts fail, return a ParseFailedRhythmGenerator
        return new ParseFailedRhythmGenerator();
    }
    
    private static function parseDensityRatio(input:String):Null<DensityRatio> {
        var ratioRegex = ~/^([0-9]+)(?:\/([0-9]+))?$/;
        if (!ratioRegex.match(input)) return null;

        var numerator = Std.parseInt(ratioRegex.matched(1));
        var denominatorMatch = ratioRegex.matched(2);
        var denominator = denominatorMatch != null ? Std.parseInt(denominatorMatch) : 1;

        if (numerator == null || denominator == null || numerator <= 0 || denominator <= 0) {
            return null;
        }

        return new DensityRatio(numerator, denominator);
    }

    private static function parseEuclidean(input:String):IRhythmGenerator {
        // Match patterns like "3/8 > 4" or "3%8 > 4" or "3/8+1 > 1/2" or "3%8+1 > 2/3"
        var regex = new EReg("^([0-9]+)([/%])([0-9]+)(\\+([0-9]+))?\\s+([><rcbdtR]|[0-9])\\s+([0-9]+(?:/[0-9]+)?)$", "");
        if (!regex.match(input)) return new ParseFailedRhythmGenerator();

        var k = Std.parseInt(regex.matched(1));
        var separator = regex.matched(2);
        var n = Std.parseInt(regex.matched(3));
        var offsetStr = regex.matched(5);
        var offset = offsetStr != null ? Std.parseInt(offsetStr) : 0;
        var selector = parseSelectorType(regex.matched(6));
        var densityRatio = parseDensityRatio(regex.matched(7));

        if (k == null || n == null || selector == null || densityRatio == null) return new ParseFailedRhythmGenerator();
        if (k <= 0 || n <= 0) return new ParseFailedRhythmGenerator();

        return separator == "%"
            ? new BjorklundRhythmGenerator(k, n, selector, densityRatio.numerator, offset, densityRatio.denominator)
            : new SimpleRhythmGenerator(k, n, selector, densityRatio.numerator, offset, densityRatio.denominator);
    }

    private static function parseExplicit(input:String):IRhythmGenerator {
        // Match pattern like "1.1. 8" or ">.>.=.>. 1/2"
        var regex = new EReg("^(\\S+)\\s+([0-9]+(?:/[0-9]+)?)$", "");
        if (!regex.match(input)) return new ParseFailedRhythmGenerator();

        var stepsStr = regex.matched(1);
        var densityRatio = parseDensityRatio(regex.matched(2));
        if (densityRatio == null) return new ParseFailedRhythmGenerator();

        var steps = new Array<SelectorType>();
        for (i in 0...stepsStr.length) {
            var char = stepsStr.charAt(i);
            if (char == ".") {
                steps.push(Rest);
            } else {
                var selector = parseSelectorType(char);
                if (selector == null) return new ParseFailedRhythmGenerator();
                steps.push(selector);
            }
        }

        return new ExplicitRhythmGenerator(steps, densityRatio.numerator, densityRatio.denominator);
    }

    private static function parseSelectorType(input:String):Null<SelectorType> {
        return switch (input) {
            case ">": Ascending;
            case "<": Descending;
            case "=": Repeat;
            case "c": FullChord;
            case "b": ChordWithBass;    // Chord with root doubled one octave lower
            case "d": Drop2;            // Drop 2 voicing
            case "r": Random;
            case "R": RandomFromScale;  // New selector for random scale degree
            case "t": TopNote;
            case n if (~/^[1-9]$/.match(n)): SpecificNote(Std.parseInt(n));
            default: null;
        }
    }
}
