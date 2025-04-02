from goldenpond import GoldenData, Mode, TimeManipulator, MidiInstrumentContext

# Create a GoldenData instance
data = GoldenData()
data.root = 48  # C3
data.mode = 1  # Minor mode (0=major, 1=minor, 2=harmonic minor, 3=melodic minor)
data.chordSequence = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
data.stutter = 0  # No stuttering
data.bpm = 120
data.chordDuration = 4

# Add lines with their instrument contexts
data.addLine("5/8 c 1", MidiInstrumentContext(0, 100, 0.8, 0))  # Chords on channel 0
data.addLine("7/12 > 2", MidiInstrumentContext(1, 100, 0.5, 0))  # Arpeggio on channel 1
data.addLine("4/8 1 4", MidiInstrumentContext(2, 100, 0.8, -12))   # Bass on channel 2

# Create line generators
generators = [data.makeLineGenerator(i) for i in range(len(data.lines))]

# Generate notes from each line
chords = generators[0].generateNotes(0)  # First line (chords)
arp = generators[1].generateNotes(0)     # Second line (arpeggio)
bass = generators[2].generateNotes(0)    # Third line (bass)

# Print chord notes with formatted floats
print("First 20 Chord notes:")
for note in [n for n in chords][:20]:
    print(f"Note[note: {note.getMidiNoteValue()}, startTime: {note.getStartTime():.1f}, length: {note.getLength():.1f}]")

# Print first arp note details with formatted floats
first_note = arp[0]
print("\nFirst Note from Arpeggio")
print(f"Getting individual fields: note={first_note.getMidiNoteValue()}, "
      f"startTime={first_note.getStartTime():.1f}, length={first_note.getLength():.1f}")

# Print a summary of the data
print("\nGoldenData Summary:")
print(data.toString())
