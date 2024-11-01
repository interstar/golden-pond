from goldenpond import Mode, ChordProgression, TimeManipulator

seq = "71,76,72,-75,71,76,72,-75i,77,73,76,<12,77ii,>12,71,96,74ii,75"
MINOR = Mode.getMinorMode()
prog = ChordProgression(48,MINOR,seq)
tm = TimeManipulator().setPPQ(0.8);
chords = tm.chords(prog,0,0)
arp = tm.arpeggiate(prog,7,12,1,0)
bass = tm.bassline(prog,4,8,2,0)

print([x.toString() for x in chords])
print([x.toString() for x in arp])
first_note = arp[0]
print("First Note")
print("Getting individual fields : %s, %s, %s"%(first_note.note,first_note.start_time,first_note.length))
print(arp[0].toString())
