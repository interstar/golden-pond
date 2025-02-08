from goldenpond import Mode, ChordProgression, TimeManipulator, ChordLine, ArpLine, BassLine

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48, MINOR, seq)
tm = TimeManipulator().setPPQ(0.8)

# Create lines with their own gateLength values
chord_line = ChordLine(tm, prog, 0.8)  # 80% gate length
arp_line = ArpLine(tm, prog, 7, 12, 0.5)  # 50% gate length for staccato
bass_line = BassLine(tm, prog, 4, 8, 0.8)  # 80% gate length

# Generate notes from each line
chords = chord_line.generateNotes(0, 0, 100)
arp = arp_line.generateNotes(0, 1, 100)
bass = bass_line.generateNotes(0, 2, 100)

print([x.toString() for x in chords])
#print([x.toString() for x in arp])
first_note = arp[0]
#print("First Note")
#print("Getting individual fields : %s, %s, %s"%(first_note.note,first_note.start_time,first_note.length))
#print(arp[0].toString())
