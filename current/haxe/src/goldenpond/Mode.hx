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

 
@:expose
enum Modifier {
    SEVENTH;
    NINTH;
    SIXTH;
    SECONDARY;
    VOICE_LEADING;
}

private enum BaseScale {
    MAJOR;
    MELODIC_MINOR;
    HARMONIC_MINOR;
    HARMONIC_MAJOR;
    HUNGARIAN_MINOR;
    DOUBLE_HARMONIC_MAJOR;
}

@:expose
class Mode {
    public static var major_intervals = [2, 2, 1, 2, 2, 2, 1];
    public static var minor_intervals = [2, 1, 2, 2, 1, 2, 2];
    public static var harmonic_minor_intervals = [2, 1, 2, 2, 1, 3, 1];
    public static var melodic_minor_intervals = [2, 1, 2, 2, 2, 2, 1];
    public static var harmonic_major_intervals = [2, 2, 1, 2, 1, 3, 1];
    public static var hungarian_minor_intervals = [2, 1, 3, 1, 1, 3, 1];
    public static var double_harmonic_major_intervals = [1, 3, 1, 2, 1, 3, 1];

    // Map to store all modes for each base scale
    private static var modeMap:Map<BaseScale, Array<Mode>>;

    private static function constructModeFromIntervals(sourceIntervals:Array<Int>, offset:Int, ?baseScale:BaseScale):Mode {
        var intervals = [];
        for (i in 0...7) {
            intervals.push(sourceIntervals[(i + offset - 1) % 7]);
        }
        return new Mode(intervals, baseScale);
    }
    
    private static function constructMajorMode(offset:Int):Mode {
        return constructModeFromIntervals(major_intervals, offset, BaseScale.MAJOR);
    }

    private static function constructMelodicMinorMode(offset:Int):Mode {
        return constructModeFromIntervals(melodic_minor_intervals, offset, BaseScale.MELODIC_MINOR);
    }

    private static function constructHarmonicMinorMode(offset:Int):Mode {
        return constructModeFromIntervals(harmonic_minor_intervals, offset, BaseScale.HARMONIC_MINOR);
    }

    private static function constructHarmonicMajorMode(offset:Int):Mode {
        return constructModeFromIntervals(harmonic_major_intervals, offset, BaseScale.HARMONIC_MAJOR);
    }

    private static function constructHungarianMinorMode(offset:Int):Mode {
        return constructModeFromIntervals(hungarian_minor_intervals, offset, BaseScale.HUNGARIAN_MINOR);
    }

    private static function constructDoubleHarmonicMajorMode(offset:Int):Mode {
        return constructModeFromIntervals(double_harmonic_major_intervals, offset, BaseScale.DOUBLE_HARMONIC_MAJOR);
    }

    private static function buildModeFamily(builder:Int->Mode):Array<Mode> {
        var modes = [];
        for (i in 1...8) {
            modes.push(builder(i));
        }
        return modes;
    }

    private static function initializeModeMap() {
        if (modeMap == null) {
            modeMap = new Map<BaseScale, Array<Mode>>();
            modeMap.set(BaseScale.MAJOR, buildModeFamily(constructMajorMode));
            modeMap.set(BaseScale.MELODIC_MINOR, buildModeFamily(constructMelodicMinorMode));
            modeMap.set(BaseScale.HARMONIC_MINOR, buildModeFamily(constructHarmonicMinorMode));
            modeMap.set(BaseScale.HARMONIC_MAJOR, buildModeFamily(constructHarmonicMajorMode));
            modeMap.set(BaseScale.HUNGARIAN_MINOR, buildModeFamily(constructHungarianMinorMode));
            modeMap.set(BaseScale.DOUBLE_HARMONIC_MAJOR, buildModeFamily(constructDoubleHarmonicMajorMode));
        }
    }

    private static function getMode(baseScale:BaseScale, modeNumber:Int):Mode {
        initializeModeMap();
        if (modeNumber < 1 || modeNumber > 7) {
            throw "Mode number must be between 1 and 7";
        }
        return modeMap.get(baseScale)[modeNumber - 1];
    }

    private static function getBaseScaleOf(original:Mode):BaseScale {
        initializeModeMap();
        if (original.baseScale != null) {
            return original.baseScale;
        }
        var families = [
            BaseScale.MAJOR,
            BaseScale.MELODIC_MINOR,
            BaseScale.HARMONIC_MINOR,
            BaseScale.HARMONIC_MAJOR,
            BaseScale.HUNGARIAN_MINOR,
            BaseScale.DOUBLE_HARMONIC_MAJOR
        ];

        for (baseScale in families) {
            var family = modeMap.get(baseScale);
            for (mode in family) {
                if (mode.valueEquals(original)) {
                    return baseScale;
                }
            }
        }

        throw "Cannot get nth mode of unknown scale";
    }

    public var intervals:Array<Int>;
    private var baseScale:Null<BaseScale>;

    public function new(intervals:Array<Int>, ?baseScale:BaseScale) {
        this.intervals = intervals;
        this.baseScale = baseScale;
    }

    public static function nthModeOf(original:Mode, n:Int):Mode {
        return getMode(getBaseScaleOf(original), n);
    }

    public static function getMajorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 1);
    }

    public static function getMinorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 6); // Aeolian mode
    }

    public static function getHarmonicMinorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.HARMONIC_MINOR, 1);
    }

    public static function getMelodicMinorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MELODIC_MINOR, 1);
    }

    public static function getHarmonicMajorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.HARMONIC_MAJOR, 1);
    }

    public static function getHungarianMinorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.HUNGARIAN_MINOR, 1);
    }

    public static function getDoubleHarmonicMajorMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.DOUBLE_HARMONIC_MAJOR, 1);
    }

    public static function getDorianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 2);
    }

    public static function getPhrygianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 3);
    }

    public static function getLydianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 4);
    }

    public static function getMixolydianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 5);
    }

    public static function getAeolianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 6);
    }

    public static function getLocrianMode():Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, 7);
    }

    public static function constructNthMajorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.MAJOR, offset);
    }

    public static function constructNthHarmonicMinorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.HARMONIC_MINOR, offset);
    }

    public static function constructNthMelodicMinorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.MELODIC_MINOR, offset);
    }

    public static function constructNthHarmonicMajorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.HARMONIC_MAJOR, offset);
    }

    public static function constructNthHungarianMinorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.HUNGARIAN_MINOR, offset);
    }

    public static function constructNthDoubleHarmonicMajorMode(offset:Int):Mode {
        initializeModeMap();
        return getMode(BaseScale.DOUBLE_HARMONIC_MAJOR, offset);
    }

    public static function constructNthMinorMode(n:Int):Mode {
        // Natural minor modes are the same as major modes, just starting from a different point
        return constructNthMajorMode(n);
    }

    public function nth_from(root:Int, n:Int):Int {
        if (n == 1) return root;
        var note = root;
        for (i in 0...n - 1) {
            note += intervals[i % intervals.length];
        }
        return note;
    }

    public function make_chord_from_pattern(root:Int, n:Int, pat:Array<Int>):Array<Int> {
        return pat.map(function(x:Int):Int {
            return nth_from(root, n + x - 1);
        });
    }

    public function make_triad(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5]);
    }

    public function make_sixth(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5, 6]);
    }

    public function make_seventh(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5, 7]);
    }

    public function make_ninth(root:Int, n:Int):Array<Int> {
        return make_chord_from_pattern(root, n, [1, 3, 5, 7, 9]);
    }

    public function valueEquals(other:Dynamic):Bool {
        if (!Std.isOfType(other, Mode)) return false;
        var otherMode:Mode = cast(other, Mode);
        
        if (otherMode == null) return false;
        if (intervals.length != otherMode.intervals.length) return false;
        for (i in 0...intervals.length) {
            if (intervals[i] != otherMode.intervals[i]) return false;
        }
        return true;
    }

    public function hashCode():Int {
        var hash = 17;
        for (interval in intervals) {
            hash = hash * 31 + interval;
        }
        return hash;
    }
}

// Singleton instances
@:expose
var MAJOR = Mode.getMajorMode();
@:expose
var MINOR = Mode.getMinorMode();
@:expose
var HARMONIC_MINOR = Mode.getHarmonicMinorMode();
@:expose
var MELODIC_MINOR = Mode.getMelodicMinorMode();
@:expose
var HARMONIC_MAJOR = Mode.getHarmonicMajorMode();
@:expose
var HUNGARIAN_MINOR = Mode.getHungarianMinorMode();
@:expose
var DOUBLE_HARMONIC_MAJOR = Mode.getDoubleHarmonicMajorMode();
