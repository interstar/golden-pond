## GoldenPond Library

This is the Python version of the GoldenPond Library.

https://github.com/interstar/golden-pond


### Quick Start
<!--
    pip install goldenpond

Then make a local test file. For example
-->

```python
from goldenpond import GoldenData, Mode, TimeManipulator, MidiInstrumentContext

# Create a GoldenData instance
data = GoldenData()
data.root = 48  # C3
data.mode = 1  # Minor mode (0=major, 1=minor, 2=harmonic minor, 3=melodic minor)
data.chordSequence = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
data.stutter = 0  # No stuttering
data.bpm = 120
data.chordDuration = 4

# Add lines with different patterns and instrument contexts
data.addLine("5/8 c 1", MidiInstrumentContext(0, 64, 0.8, 0))  # Chords on channel 0
data.addLine("7/12 > 2", MidiInstrumentContext(1, 80, 0.5, 12))  # Arpeggio on channel 1
data.addLine("4/8 1 4", MidiInstrumentContext(2, 90, 0.8, -12))  # Bass on channel 2

# Create TimeManipulator and line generators
tm = TimeManipulator().setPPQ(96).setChordDuration(data.chordDuration).setBPM(data.bpm)
generators = data.createLineGenerators(tm)

# Generate notes from each line
chords = generators[0].generateNotes(0)  # First line (chords)
arp = generators[1].generateNotes(0)     # Second line (arpeggio)
bass = generators[2].generateNotes(0)    # Third line (bass)

# Print chord notes with formatted floats
print("First 20 Chord notes:")
for note in chords[:20]:
    print(f"Note[midi: {note.getMidiNoteValue()}, startTime: {note.getStartTime():.1f}, length: {note.getLength():.1f}]")

# Print first arp note details with formatted floats
first_note = arp[0]
print("\nFirst Note from Arpeggio")
print(f"Getting individual fields: midi={first_note.getMidiNoteValue()}, "
      f"startTime={first_note.getStartTime():.1f}, length={first_note.getLength():.1f}")

# Print a summary of the data
print("\nGoldenData Summary:")
print(data.toString())

```

GoldenPond is a library for creating musical patterns using a simple text-based language. It helps you define chord progressions and rhythmic patterns (like arpeggios and basslines) that follow music theory rules.

### Understanding the Example Code

Let's break down what the example code does:

1. **Setting Up the Musical Data**
   ```python
   data = GoldenData()
   data.root = 48  # C3
   data.mode = 1   # Minor mode
   data.chordSequence = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
   data.bpm = 120
   data.chordDuration = 4
   ```
   This creates a musical piece in C minor at 120 BPM, with each chord lasting 4 beats.

2. **Defining Musical Lines**
   ```python
   data.addLine("5/8 c 1", MidiInstrumentContext(0, 64, 0.8, 0))  # Chords
   data.addLine("7/12 > 2", MidiInstrumentContext(1, 80, 0.5, 12))  # Arpeggio
   data.addLine("4/8 1 4", MidiInstrumentContext(2, 90, 0.8, -12))  # Bass
   ```
   Each line defines a different musical part:
   - First line: Full chords playing 5 notes in 8 steps
   - Second line: Ascending arpeggios playing 7 notes in 12 steps
   - Third line: Bass notes playing 4 notes in 8 steps

3. **Generating Notes**
   ```python
   tm = TimeManipulator().setPPQ(96).setChordDuration(data.chordDuration).setBPM(data.bpm)
   generators = data.createLineGenerators(tm)
   chords = generators[0].generateNotes(0)
   ```
   This creates the actual musical notes with proper timing.

4. **Accessing Note Data**
   ```python
   print(f"Note[midi: {note.getMidiNoteValue()}, startTime: {note.getStartTime():.1f}, length: {note.getLength():.1f}]")
   ```
   Each note contains:
   - `midi`: The MIDI note number (pitch)
   - `startTime`: When the note starts (in beats)
   - `length`: How long the note lasts (in beats)

### What You Can Do With This

GoldenPond doesn't play music directly - it creates a data structure that you can use to:
- Generate MIDI files (see the `midi_example.py` in the repository)
- Create music in your own application
- Analyze musical patterns
- Experiment with different chord progressions and rhythms

For more details about the chord and rhythm languages, visit the [GoldenPond website](https://gilbertlisterresearch.com/goldenpond.html).

### Technical Note

The GoldenPond library is written in Haxe and transpiled to Python. The [source repository](https://github.com/interstar/golden-pond) contains the original Haxe code and build scripts. 