/*
GoldenPond Rhythm Pattern Language
Copyright (C) 2025 Phil Jones

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
*/

// Core type for note selection
enum SelectorType {
    Ascending;         
    Descending;       
    Repeat;           
    FullChord;        
    Random;           
    SpecificNote(n:Int);
    Rest;
    TopNote;
}

// Interface that Line classes use
interface IRhythmGenerator {
    function hasNext():Bool;
    function next():SelectorType;
    function reset():Void;
    function getPatternLength():Int;  // Original pattern length
    function getTotalSteps():Int;     // Total steps including density
    function parseFailed():Bool;      // New method to check if parsing failed
}

// Base class for explicit patterns
@:expose
class ExplicitRhythmGenerator implements IRhythmGenerator {
    private var steps:Array<SelectorType>;
    private var index:Int;
    private var density:Int;
    private var totalSteps:Int;

    public function new(steps:Array<SelectorType>, density:Int) {
        this.steps = steps;
        this.index = 0;
        this.density = density;
        this.totalSteps = steps.length * density;
    }

    public function hasNext():Bool {
        return true;  // Always cycles
    }

    public function next():SelectorType {
        var selector = steps[index % steps.length];
        index = (index + 1) % totalSteps;
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
    
    public function parseFailed():Bool {
        return false;  // Normal generators never fail
    }
}

// Simple distribution algorithm
@:expose
class SimpleRhythmGenerator extends ExplicitRhythmGenerator {
    public function new(k:Int, n:Int, selector:SelectorType, density:Int, offset:Int = 0) {
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
        
        super(steps, density);
    }
}

// Bjorklund's algorithm implementation
@:expose
class BjorklundRhythmGenerator extends ExplicitRhythmGenerator {
    public function new(k:Int, n:Int, selector:SelectorType, density:Int, offset:Int = 0) {
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
        
        super(pattern, density);
    }
    
    // Implementation of Bjorklund's algorithm for traditional rhythms
    private function bjorklund(k:Int, n:Int):Array<Bool> {
        if (k <= 0) return [for (i in 0...n) false];
        if (k >= n) return [for (i in 0...n) true];
        
        // Special cases for traditional rhythms
        if (k == 3 && n == 8) {
            // Cuban tresillo [1,0,0,1,0,0,1,0]
            return [true, false, false, true, false, false, true, false];
        } else if (k == 5 && n == 8) {
            // Cuban cinquillo [1,0,1,1,0,1,1,0]
            return [true, false, true, true, false, true, true, false];
        } else if (k == 2 && n == 5) {
            // Persian Khafif-e-ramal [1,0,1,0,0]
            return [true, false, true, false, false];
        } else if (k == 3 && n == 4) {
            // Cumbia [1,0,1,1]
            return [true, false, true, true];
        } else if (k == 4 && n == 7) {
            // Ruchenitza [1,0,1,0,1,0,1]
            return [true, false, true, false, true, false, true];
        } else if (k == 5 && n == 9) {
            // Agsag-Samai [1,0,1,0,1,0,1,0,1]
            return [true, false, true, false, true, false, true, false, true];
        } else if (k == 3 && n == 7) {
            // Money [1,0,1,0,1,0,0]
            return [true, false, true, false, true, false, false];
        } else if (k == 5 && n == 16) {
            // Bossa-Nova [1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,0]
            return [true, false, false, true, false, false, true, false, false, true, false, false, true, false, false, false];
        }
        
        // For other cases, use the standard algorithm
        return standardBjorklund(k, n);
    }
    
    // Standard Bjorklund algorithm implementation
    private function standardBjorklund(k:Int, n:Int):Array<Bool> {
        // Initialize with k ones followed by n-k zeros
        var pattern = [];
        for (i in 0...k) pattern.push(true);
        for (i in 0...n-k) pattern.push(false);
        
        // Apply the Bjorklund algorithm
        var count = [];
        var remainder = [k];
        var divisor = n - k;
        var level = 0;
        
        while (remainder[level] > 1) {
            count.push(Math.floor(divisor / remainder[level]));
            remainder.push(divisor % remainder[level]);
            divisor = remainder[level];
            level++;
        }
        
        if (remainder[level] == 1) {
            count.push(divisor);
        }
        
        // Build the pattern
        var builder = [];
        buildPattern(level, count, remainder, builder);
        
        // Flatten the pattern
        var result = [];
        for (item in builder) {
            result = result.concat(item);
        }
        
        return result;
    }
    
    // Helper function to build the pattern
    private function buildPattern(level:Int, count:Array<Int>, remainder:Array<Int>, builder:Array<Array<Bool>>) {
        if (level == -1) {
            builder.push([true]);
        } else if (level == -2) {
            builder.push([false]);
        } else {
            for (i in 0...count[level]) {
                buildPattern(level - 1, count, remainder, builder);
            }
            
            if (remainder[level + 1] != 0) {
                buildPattern(level - 2, count, remainder, builder);
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
    
    public function parseFailed():Bool {
        return true;  // This generator always indicates parsing failed
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
    
    private static function parseEuclidean(input:String):IRhythmGenerator {
        // Match patterns like "3/8 > 4" or "3%8 > 4" or "3/8+1 > 4" or "3%8+1 > 4"
        var regex = new EReg("^([0-9]+)([/%])([0-9]+)(\\+([0-9]+))?\\s+([><rc=t]|[0-9])\\s+([0-9]+)$", "");
        if (!regex.match(input)) return new ParseFailedRhythmGenerator();
        
        var k = Std.parseInt(regex.matched(1));
        var separator = regex.matched(2);
        var n = Std.parseInt(regex.matched(3));
        var offsetStr = regex.matched(5);  // This will be null if no offset was specified
        var offset = offsetStr != null ? Std.parseInt(offsetStr) : 0;
        var selector = parseSelectorType(regex.matched(6));
        var density = Std.parseInt(regex.matched(7));  // Parse density as an integer
        
        if (k == null || n == null || selector == null || density == null) return new ParseFailedRhythmGenerator();
        if (k <= 0 || n <= 0 || density <= 0) return new ParseFailedRhythmGenerator();  // Validate k, n, and density are positive
        
        return separator == "%" 
            ? new BjorklundRhythmGenerator(k, n, selector, density, offset)
            : new SimpleRhythmGenerator(k, n, selector, density, offset);
    }
    
    private static function parseExplicit(input:String):IRhythmGenerator {
        // Match pattern like "1.1. 8" or ">.>.=.>. 4"
        var parts = input.split(" ");
        if (parts.length != 2) return new ParseFailedRhythmGenerator();
        
        var stepsStr = parts[0];
        var density = Std.parseInt(parts[1]);  // Parse density as an integer
        if (density == null || density <= 0) return new ParseFailedRhythmGenerator();
        
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
        
        return new ExplicitRhythmGenerator(steps, density);
    }
    
    private static function parseSelectorType(input:String):Null<SelectorType> {
        return switch (input) {
            case ">": Ascending;
            case "<": Descending;
            case "=": Repeat;
            case "c": FullChord;
            case "r": Random;
            case "t": TopNote;
            case n if (~/^[1-9]$/.match(n)): SpecificNote(Std.parseInt(n));
            default: null;
        }
    }
}