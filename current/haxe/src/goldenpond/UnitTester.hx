/*
GoldenPond
Copyright (C) 2024 Phil Jones

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

To understand the GNU Affero General Public License see <https://www.gnu.org/licenses/>.
*/

package;

import Mode;
import ChordThing;
import ScoreUtilities;

/**
 * UnitTester - A simple testing framework for GoldenPond
 */
class UnitTester {
    private var testCount:Int = 0;
    private var errorCount:Int = 0;
    
    public function new() {}
    
    /**
     * Run a test and track the result
     * @param name The name of the test
     * @param actual The actual value
     * @param expected The expected value
     * @param message Optional message to display on failure
     */
    public function testit<T>(name:String, actual:T, expected:T, ?message:String):Void {
        testCount++;
        
        if (!deepEquals(actual, expected)) {
            errorCount++;
            var msg = message != null ? message : "Test failed";
            trace('ERROR: $name - $msg');
            trace('  Expected: $expected');
            trace('  Got: $actual');
            compareDetails(actual,expected);
        } else {
            trace('OK: $name');
        }
    }
    
    /**
     * Get the total number of tests run
     */
    public function getTestCount():Int {
        return testCount;
    }
    
    /**
     * Get the number of failed tests
     */
    public function getErrorCount():Int {
        return errorCount;
    }
    
    /**
     * Reset the test counters
     */
    public function reset():Void {
        testCount = 0;
        errorCount = 0;
    }
    
    /**
     * Print a summary of the test results
     */
    public function printSummary():Void {
        trace('-------------------------');
        trace('Test Summary:');
        trace('  Total Tests: $testCount');
        trace('  Errors: $errorCount');
        trace('-------------------------');
    }
    
    function deepEquals(a:Dynamic, b:Dynamic):Bool {
        // Handle null
        if (a == null) return b == null;

        // Try direct equality first - if they're equal, no need for deep comparison
        if (a == b) return true;

        // Special cases that need deep comparison
        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            var arrayA:Array<Dynamic> = cast a;
            var arrayB:Array<Dynamic> = cast b;
            if (arrayA.length != arrayB.length) return false;
            for (i in 0...arrayA.length) {
                if (!deepEquals(arrayA[i], arrayB[i])) return false;
            }
            return true;
        }

        // Objects with custom equals methods
        if (Std.isOfType(a, Note) || Std.isOfType(a, ChordThing) || Std.isOfType(a, Mode)) {
            return a.equals(b);
        }

        // Float comparison needs special handling
        if (Std.isOfType(a, Float)) {
            return floatEqual(cast(a, Float), cast(b, Float));
        }

        // If we get here and the values are equal as strings, consider them equal
        return Std.string(a) == Std.string(b);
    }
    
    public function floatEqual(a:Float, b:Float, epsilon:Float = 0.0001):Bool {
        return Math.abs(a - b) < epsilon;
    }

    function compareDetails(a:Dynamic, b:Dynamic):Void {
		trace("In compareDetails SHOULDN'T BE HERE");
        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            if (a.length != b.length) {
                trace("Length mismatch: " + a.length + " vs " + b.length);
                return;
            }
            for (i in 0...a.length) {
                if (!deepEquals(a[i], b[i])) {
                    trace("Difference at index " + i + ":");
                    trace("Wanted: " + Std.string(a[i]));
                    trace("Got: " + Std.string(b[i]));
                }
            }
        } else if (Std.isOfType(a, String) && Std.isOfType(b, String)) {
            if (a != b) {
                trace("String mismatch:");
                trace("Wanted: " + a);
                trace("Got: " + b);
            }
        } else {
            trace("Mismatch:");
            trace("Wanted: " + Std.string(a));
            trace("Got: " + Std.string(b));
        }
    }  
} 
