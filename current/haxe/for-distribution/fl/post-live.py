


class GoldenData :
    def __init__(self) :
        self.changed = True
        self.current_str = ""
        
    def update(self,root,mode,chordDuration,chords,lines) :
        self.root = root
        self.mode = mode
        self.chordDuration = chordDuration
        self.chords = chords
        self.lines = lines
        
        self.old_str = self.current_str
        self.current_str = "%s"%self
        if self.old_str != self.current_str :
            self.changed = True
        else :
            self.changed = False
        
    def __str__(self) :
        lines = "\r\n".join(self.lines)
        return """\r\n
-------------------------------------------\r\n
Root : %s\r\n
Mode : %s\r\n
Chord Duration: %s\r\n
Chords : %s\r\n
Lines : %s 
...........................................
     
""" % (self.root, self.mode, self.chordDuration, self.chords, self.lines)

CURRENT_DATA = GoldenData()         


  
def makeNote(num, time, length, color=0, velocity=0.7):
    """
    make a new Note object

    num: pitch
    time: time in ticks
    length: duration in ticks
    color: int in [0: 16)
    """
    note = flp.Note()
    note.number = int(num)
    note.time = int(time)
    note.length = int(length)
    note.color = int(color)
    note.velocity = velocity
    return note
      
def addChan(form,name,vname,tname) :
    form.AddInputText(name,"")  # Pattern input
    form.AddInputKnob(vname,0.6,0,1)  # Volume
    form.AddInputKnobInt(tname,0,-3,3)  # Transposition
    
def createDialog():
    form = flp.ScriptDialog("GoldenPond",
    """GoldenPond is language for defining chord progressions and rhythm patterns.\r\n
See http://gilbertlisterresearch.com/ for documentation.""")
    
    form.AddInputKnobInt('Root',65,32,96)
    form.AddInputCombo('Mode',["major","minor"],0)
    form.AddInputText('ChordSeq', "1,4,5,1")

    # Add 6 channels with volume and octave controls
    for i in range(1, 7):
        addChan(form, f"Chan{i}", f"Vol{i}", f"Oct{i}")


    form.AddInputKnob('Note Proportion',0.8,0.1,1.5)
    form.AddInputKnobInt('Chord Duration',4,1,16)
    
    form.AddInputKnobInt("Stutter",0,0,16)
    form.AddInputCheckbox("Silent",False)
    
    return form


def post_notes_to_score(notes_list):
    for note in notes_list:
        flp.score.addNote(makeNote(
            note.note,
            note.startTime,
            note.length,
            color=note.chan,
            velocity=note.velocity/127.0
        ))


 
 
def addVel(v,t,xs) :
    def change(x) :
        x.note=x.note+(12*t)
        return [x,v]
    return [change(x) for x in xs]
    
def channel(chan, pattern, velocity, transpose, seq, timingInfo, note_prop):
    """
    Create a line from a rhythm pattern string
    Examples:
        "c..." - chord followed by rests
        "3/8 > 4" - euclidean pattern, ascending
        "1.>.>.=. 4" - explicit pattern with ascending and repeat
    """
    try:
        if not pattern or pattern.isspace():
            return []

        # Create rhythm generator from pattern
        rhythmGenerator = RhythmLanguage.makeRhythmGenerator(pattern)
        if rhythmGenerator.parseFailed():
            Utils.log(f"Invalid pattern in channel {chan}: {pattern}")
            return []
            
        # Create line generator
        line = LineGenerator.create(timingInfo, seq, rhythmGenerator, note_prop)
        
        # Generate notes with velocity and transposition
        notes = line.generateNotes(0, chan, int(velocity * 127))
        
        # Apply transposition if needed
        if transpose != 0:
            notes = [note.transpose(transpose * 12) for note in notes]
            
        return notes
        
    except Exception as e:        
        return []



        
def apply(form):
    root = form.GetInputValue('Root')
    mode = form.GetInputValue('Mode')
    chordSeq = form.GetInputValue('ChordSeq')

    note_prop = form.GetInputValue('Note Proportion')
    chord_len = form.GetInputValue('Chord Duration')
    stutter = form.GetInputValue("Stutter")
    

    # Configure TimeManipulator
    timingInfo = TimeManipulator().setPPQ(flp.score.PPQ)
    timingInfo.setChordDuration(chord_len)

    flp.score.clearNotes(False)

    if form.GetInputValue("Silent")==1 : return
    
    lines = []
    try : 
        # Create chord progression
        theMode = Mode.getMajorMode() if mode == 0 else Mode.getMinorMode()
        seq = ChordProgression(root, theMode, chordSeq)
        seq.setStutter(stutter)
 
        all_notes = []

        for i in range(1,7):
            pattern = form.GetInputValue(f"Chan{i}")
            velocity = form.GetInputValue(f"Vol{i}")
            transpose = form.GetInputValue(f"Oct{i}")
            
            notes = channel(i-1, pattern, velocity, transpose, seq, 
                          timingInfo, note_prop)
            all_notes.extend(notes)
            lines.append("%s %s %s %s" % (pattern, velocity, transpose, note_prop))

        post_notes_to_score(all_notes)
        
        CURRENT_DATA.update(root,mode,chord_len,chordSeq,lines)
        if CURRENT_DATA.changed:
            Utils.log("Changed\n%s" % CURRENT_DATA)
            
    except Exception as e:
        Utils.log("Exception\n%s" % e)