from goldenpond import Mode, ChordProgression, TimeManipulator

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48,MINOR,seq)
tm = TimeManipulator().setPPQ(0.8);
arp = tm.arpeggiate(prog,7,12,0)
chords = tm.chords(prog,0)
bass = tm.bassline(prog,4,8,0)

print(chords)
print(arp)
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note,first_note.start_time,first_note.length))
print(arp[0].toString())
