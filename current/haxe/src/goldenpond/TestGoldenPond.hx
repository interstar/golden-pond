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

import Mode;
import ChordThing;
import ChordParser;
import TimedSequence;
import ScoreUtilities;
import RhythmGenerator;  
import TestSuite1;
import TestSuite2;

class TestGoldenPond {
  	
    public static function main() {
        var tester:UnitTester = new UnitTester();
        TestSuite1.allTests(tester);
        TestSuite2.allTests(tester);
        tester.printSummary();
    }

}

