from goldenpond import Mode, ChordProgression, TimeManipulator, ChordLine, ArpLine, BassLine

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48, MINOR, seq)

# TimeManipulator with PPQ, chord duration and BPM
tm = TimeManipulator().setPPQ(96).setChordDuration(4).setBPM(120)

# Create lines with k, n, gateLength and rhythmicDensity parameters
chord_line = ChordLine(tm, prog, 5, 8, 0.8, 1.0)  # k=5, n=8, 80% gate length, density=1.0
arp_line = ArpLine(tm, prog, 7, 12, 0.5, 0.5)    # k=7, n=12, 50% gate length, density=0.5
bass_line = BassLine(tm, prog, 4, 8, 0.8, 0.25)   # k=4, n=8, 80% gate length, density=0.25

# Generate notes from each line
chords = chord_line.generateNotes(0, 0, 100)
arp = arp_line.generateNotes(0, 1, 100)
bass = bass_line.generateNotes(0, 2, 100)

print([x.toString() for x in chords])
#print([x.toString() for x in arp])
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note, first_note.startTime, first_note.length))
#print(arp[0].toString())
