/*
GoldenPond
Copyright (C) 2024 Phil Jones

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
*/

import UnitTester;
import ScoreUtilities;
import ScoreUtilities.PianoRollLayout;
import ScoreUtilities.PianoRollGridStyle;
import ScoreUtilities.Note;
import ScoreUtilities.INote;

class TestPianoRollSVG {
  public static function allTests(tester:UnitTester):Void {
    trace("\n=== Testing makePianoRollSVG / makePianoRollSVGAdvanced ===");
    var n0 = new Note(0, 60, 100, 0, 1000);
    var svgLegacy = ScoreUtilities.makePianoRollSVG([n0], 200, 100);
    var svgAdv = ScoreUtilities.makePianoRollSVGAdvanced([n0], 200, 100, PianoRollLayout.defaultLegacy());
    tester.testit("makePianoRollSVG equals makePianoRollSVGAdvanced with defaultLegacy", svgLegacy, svgAdv,
      "Wrapper must match advanced with default layout");

    tester.testit("legacy single note rect y for MIDI 60 at h=100", StringTools.contains(svgLegacy, '<rect x="0" y="59"'),
      true, "noteHeight=1 pitchRef 20 -> y=59");

    var empty = ScoreUtilities.makePianoRollSVG([], 80, 50);
    tester.testit("empty notes still produces svg root", StringTools.startsWith(empty, '<svg '), true);
    tester.testit("empty notes has no rects", empty.indexOf("<rect") < 0, true);

    var fourChord:Array<INote> = cast [
      new Note(0, 60, 100, 0, 400),
      new Note(0, 64, 100, 0, 400),
      new Note(0, 67, 100, 0, 400),
      new Note(0, 70, 100, 0, 400),
    ];
    var fit = new PianoRollLayout();
    fit.fitPitchRange = true;
    fit.gridStyle = OctavesOnly;
    fit.gridStroke = "#4a4a4a";
    fit.noteFill = "#8bc34a";
    fit.noteStroke = "#2e4a22";
    var svgFit = ScoreUtilities.makePianoRollSVGAdvanced(fourChord, 400, 200, fit);
    var lineTags = svgFit.split("<line").length - 1;
    tester.testit("fit pitch + octave grid uses few line elements", lineTags < 16, true);
    tester.testit("fit layout uses custom note fill", svgFit.indexOf('fill="#8bc34a"') >= 0, true);
    tester.testit("fit layout uses note stroke", svgFit.indexOf('stroke="#2e4a22"') >= 0, true);

    var noGrid = new PianoRollLayout();
    noGrid.gridStyle = None;
    var svgNo = ScoreUtilities.makePianoRollSVGAdvanced([n0], 120, 80, noGrid);
    tester.testit("legacy mode no grid omits line elements", svgNo.indexOf("<line") < 0, true);
  }
}
