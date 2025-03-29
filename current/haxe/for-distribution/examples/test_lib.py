from goldenpond import Mode, ChordProgression, TimeManipulator, LineGenerator


# Create a chord progression
seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48, MINOR, seq)

# TimeManipulator with PPQ, chord duration and BPM
tm = TimeManipulator().setPPQ(96).setChordDuration(4).setBPM(120)

# Create lines using rhythm patterns
chord_line = LineGenerator.createFromPattern(tm, prog, "5/8 c 1", 0.8)  # 5 notes in 8 steps, full chord
arp_line = LineGenerator.createFromPattern(tm, prog, "7/12 > 2", 0.5)  # 7 notes in 12 steps, ascending
bass_line = LineGenerator.createFromPattern(tm, prog, "4/8 1 4", 0.8)   # 4 notes in 8 steps, single note

# Generate notes from each line
chords = chord_line.generateNotes(0, 0, 100)
arp = arp_line.generateNotes(0, 1, 100)
bass = bass_line.generateNotes(0, 2, 100)

# Print chord notes
print("Chord notes:")
print([x.toString() for x in chords])

# Print first arp note details
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note, first_note.startTime, first_note.length))
#print(arp[0].toString())
