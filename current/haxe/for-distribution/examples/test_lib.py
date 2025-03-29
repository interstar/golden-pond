from goldenpond import GoldenData, Mode, TimeManipulator

# Create a GoldenData instance
data = GoldenData()
data.root = 48  # C3
data.mode = 1  # Minor mode (0=major, 1=minor, 2=harmonic minor, 3=melodic minor)
data.chordSequence = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
data.stutter = 0  # No stuttering
data.bpm = 120
data.chordDuration = 4

# Add some lines with different patterns and channels
data.addLine("5/8 c 1", 0.8, 3, 0)  # Chords on channel 0
data.addLine("7/12 > 2", 0.5, 4, 1)  # Arpeggio on channel 1
data.addLine("4/8 1 4", 0.8, 2, 2)   # Bass on channel 2

# Create TimeManipulator and line generators
tm = TimeManipulator().setPPQ(96).setChordDuration(data.chordDuration).setBPM(data.bpm)
generators = data.createLineGenerators(tm)

# Generate notes from each line
chords = generators[0].generateNotes(0, 0, 100)  # First line (chords)
arp = generators[1].generateNotes(0, 1, 100)     # Second line (arpeggio)
bass = generators[2].generateNotes(0, 2, 100)    # Third line (bass)

# Print chord notes with formatted floats
print("First 20 Chord notes:")
for note in [n for n in chords][:20]:
    print(f"Note[note: {note.note}, startTime: {note.startTime:.1f}, length: {note.length:.1f}]")

# Print first arp note details with formatted floats
first_note = arp[0]
print("\nFirst Note from Arpeggio")
print(f"Getting individual fields: note={first_note.note}, "
      f"startTime={first_note.startTime:.1f}, length={first_note.length:.1f}")

# Print a summary of the data
print("\nGoldenData Summary:")
print(data.toString())
