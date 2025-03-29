

class GoldenData :
    def __init__(self) :
        self.changed = True
        self.current_str = ""
        
    def update(self,root,mode,chordSeq,seqset,density,note_prop,chord_len,k,n) :
        self.root = root
        self.mode = mode
        self.chordSeq = chordSeq
        self.generate = seqset
        self.density = density
        self.note_prop = note_prop
        self.chord_len = chord_len
        self.k = k
        self.n = n
        self.old_str = self.current_str
        self.current_str = "%s"%self
        if self.old_str != self.current_str :
            self.changed = True
        else :
            self.changed = False
        
    def __str__(self) :
        return """\r\n
-------------------------------------------\r\n
Root : %s\r\n
Mode : %s\r\n
ChordSeq : %s\r\n
Generate Type: %s\r\n
Division : %s\r\n
Note Proportion : %s\r\n
Chord Duration : %s\r\n
Arp: k=%s, n=%s\r\n
...........................................
     
""" % (self.root, self.mode, self.chordSeq, self.generate, self.density,
self.note_prop,self.chord_len,self.k,self.n)

CURRENT_DATA = GoldenData()         


  
def makeNote(num, time, length, color=0, velocity=0.5):
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
      
def createDialog():
    form = flp.ScriptDialog("GoldenPond",
    'GoldenPond is language for defining chord progressions.\r\nThis is the FL Studio version which also lets you create rhythmic patterns for arpeggios and melodies.\r\nSee http://gilbertlisterresearch.com/ for more information and documentation.')
    
    form.AddInputKnobInt('Root',65,32,96)
    form.AddInputCombo('Mode',["major","minor","harmonic minor","melodic minor"],0)
    form.AddInputText('ChordSeq', "1,6,4,5")
    
    form.AddInputCheckbox('Chords',False)
    form.AddInputCheckbox('Bass',False)
    
    form.AddInputCheckbox('Arp ↑',False)
    form.AddInputCheckbox('Arp ↓',False)
    
    form.AddInputCheckbox('Top',False)
    form.AddInputCheckbox('Random',False)
 
    
    form.AddInputKnobInt('Rhythm k',4,1,24)
    form.AddInputKnobInt('Rhythm n',8,1,24)
    
    densityItems = MenuHelper.getRhythmicDensityNames()

    form.AddInputKnobInt('Density',4,1,8)
    form.AddInputKnob('Note Proportion',0.8,0.1,1.5)
    form.AddInputKnobInt('Chord Duration',4,1,16)
    
    form.AddInputKnobInt("Stutter",0,0,16)
    form.AddInputCheckbox("Silent",False)
    

    return form


def post_notes_to_score(notes_list):
    for note_data in notes_list:
        note_value = note_data.note
        start_time = note_data.startTime
        note_duration = note_data.length
        color = note_data.chan
        note = makeNote(note_value, start_time, note_duration,color=color)
        flp.score.addNote(note)


def transpose_all(all_notes, n):
    transposed = [{'note': note_entry['note'] + n, 
                   'start_time': note_entry['start_time'], 
                   'length': note_entry['length']} for note_entry in all_notes]
    return transposed
 

def makeALine(tm,seq,k,n,selectorType,density,note_prop,chan,all_notes) : 
    rgen = SimpleRhythmGenerator(k,n,selectorType,density)
    line = LineGenerator(tm, seq, rgen, note_prop)
    all_notes.extend(line.generateNotes(0, chan, 100))

        
def apply(form):
    root = form.GetInputValue('Root')
    mode = form.GetInputValue('Mode')
    chordSeq = form.GetInputValue('ChordSeq')
    
    seqtypes = set([])
    if form.GetInputValue("Chords")==1: seqtypes.add(SeqTypes.CHORDS)
    if form.GetInputValue("Arp ↑")==1: seqtypes.add(SeqTypes.ARPUP)
    if form.GetInputValue("Arp ↓")==1: seqtypes.add(SeqTypes.ARPDOWN)
    
    if form.GetInputValue("Bass")==1: seqtypes.add(SeqTypes.BASS)
    if form.GetInputValue("Top")==1: seqtypes.add(SeqTypes.TOP)
    if form.GetInputValue("Random")==1: seqtypes.add(SeqTypes.RANDOM)
 

    note_prop = form.GetInputValue('Note Proportion')
    chord_len = form.GetInputValue('Chord Duration')
    
    k = form.GetInputValue('Rhythm k')
    n = form.GetInputValue('Rhythm n')
    stutter = int(form.GetInputValue("Stutter"))

    # Configure TimeManipulator
    timingInfo = TimeManipulator().setPPQ(flp.score.PPQ)
    timingInfo.setChordDuration(chord_len)

    flp.score.clearNotes(False)

    if form.GetInputValue("Silent")==1: 
        return

    try:
        # Create chord progression
        if mode == 0:
            theMode = Mode.getMajorMode()
        elif mode == 1:
            theMode = Mode.getMinorMode()
        elif mode == 2:
            theMode = Mode.getHarmonicMinorMode()
        elif mode == 3:
            theMode = Mode.getMelodicMinorMode()
        else:
            theMode = Mode.getMajorMode()  # Default fallback
            
        baseSeq = ChordProgression(root, theMode, chordSeq)
        seq = StutteredChordProgression(baseSeq, stutter) if stutter > 0 else baseSeq

        all_notes = []
        
        # Get rhythmic density value
        density = form.GetInputValue('Density')

        # Generate notes for each selected line type
        if SeqTypes.CHORDS in seqtypes:
            makeALine(timingInfo,seq,1,2,SelectorType.FullChord,density,note_prop,0,all_notes)
            
        if SeqTypes.ARPUP in seqtypes:
            makeALine(timingInfo,seq,k,n,SelectorType.Ascending,density,note_prop,1,all_notes)
            
        if SeqTypes.ARPDOWN in seqtypes:
            makeALine(timingInfo,seq,k,n,SelectorType.Descending,density,note_prop,2,all_notes)            
            
        if SeqTypes.BASS in seqtypes:
            makeALine(timingInfo,seq,k,n,SelectorType.SpecificNote(1),density,3,note_prop,all_notes)
            
        if SeqTypes.TOP in seqtypes:
            makeALine(timingInfo,seq,k,n,SelectorType.TopNote,density,note_prop,4,all_notes)
                        
        if SeqTypes.RANDOM in seqtypes:
            makeALine(timingInfo,seq,k,n,SelectorType.Random,density,note_prop,5,all_notes)
                        

        post_notes_to_score(all_notes)
        
        # Update display data
        CURRENT_DATA.update(root, mode, chordSeq, 
                          ["%s"%x for x in seqtypes],
                          density, note_prop, chord_len, k, n)
        if CURRENT_DATA.changed:
            Utils.log("Changed\n%s" % CURRENT_DATA)
            
    except Exception as e:
        Utils.log("Exception\n%s" % e)
        
