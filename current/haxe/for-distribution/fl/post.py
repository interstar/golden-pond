
class GoldenData :
    def __init__(self) :
        self.changed = True
        self.current_str = ""
        
    def update(self,root,mode,chordSeq,seqset,division,note_prop,chord_len,k,n) :
        self.root = root
        self.mode = mode
        self.chordSeq = chordSeq
        self.generate = seqset
        self.division = division
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
Chord Length : %s\r\n
Euclidean: k=%s, n=%s\r\n
...........................................
     
""" % (self.root, self.mode, self.chordSeq, self.generate, self.division,
self.note_prop,self.chord_len,self.k,self.n)

CURRENT_DATA = GoldenData()         


  
def makeNote(num, time, length, color=0, velocity=65):
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
    form.AddInputCombo('Mode',["major","minor"],0)
    form.AddInputText('ChordSeq', "1,4,5,1")
    
    form.AddInputCheckbox('Chords',False)
    form.AddInputCheckbox('Euclidean',False)
    form.AddInputCheckbox('Bass',False)
    form.AddInputCheckbox('Top',False)
    form.AddInputCheckbox('Random',False)
    form.AddInputCheckbox('Scale',False)    
    
    form.AddInputKnobInt('Rhythm k',4,1,24)
    form.AddInputKnobInt('Rhythm n',8,1,24)
    
    divisionItems = MenuHelper.getDivisionNames()

    form.AddInputCombo('Division',divisionItems,4)
    form.AddInputKnob('Note Proportion',0.8,0.1,1.5)
    form.AddInputKnobInt('Chord Length',4,1,16)
    
    form.AddInputKnobInt("Stutter",0,0,16)
    form.AddInputCheckbox("Silent",False)
    

    #form.AddInputCombo('Generate',['Chords','Euclidean','Bass','C+E','E+B','C+B','All','All E+12','Top'],0)

    return form


def post_notes_to_score(notes_list):
    for note_data in notes_list:
        note_value = note_data.note
        start_time = note_data.start_time
        note_duration = note_data.length
        color = note_data.chan
        note = makeNote(note_value, start_time, note_duration,color=color)
        flp.score.addNote(note)


def transpose_all(all_notes, n):
    transposed = [{'note': note_entry['note'] + n, 
                   'start_time': note_entry['start_time'], 
                   'length': note_entry['length']} for note_entry in all_notes]
    return transposed
 


        
def apply(form):
    root = form.GetInputValue('Root')
    mode = form.GetInputValue('Mode')
    chordSeq = form.GetInputValue('ChordSeq')
    #gtype = form.GetInputValue('Generate')
        
    seqtypes = set([])
    if form.GetInputValue("Chords")==1: seqtypes.add(SeqTypes.CHORDS)
    if form.GetInputValue("Euclidean")==1: seqtypes.add(SeqTypes.EUCLIDEAN)
    if form.GetInputValue("Bass")==1: seqtypes.add(SeqTypes.BASS)
    if form.GetInputValue("Top")==1: seqtypes.add(SeqTypes.TOP)
    if form.GetInputValue("Random")==1: seqtypes.add(SeqTypes.RANDOM)
    if form.GetInputValue("Scale")==1: seqtypes.add(SeqTypes.SCALE)

    division = MenuHelper.getDivisionFor(form.GetInputValue('Division'))
    note_prop = form.GetInputValue('Note Proportion')
    chord_len = form.GetInputValue('Chord Length')
 
    
    k = form.GetInputValue('Rhythm k')
    n = form.GetInputValue('Rhythm n')

    stutter = form.GetInputValue("Stutter")

    timingInfo = TimeManipulator().setPPQ(flp.score.PPQ)
    timingInfo.setChordLen(chord_len).setNoteLen(note_prop).setDivision(division)

    division, note_prop, chord_len
    

    flp.score.clearNotes(False)

    if form.GetInputValue("Silent")==1 : return
    try : 
        if mode == 0 : 
            theMode = Mode.getMajorMode()
        else :
            theMode = Mode.getMinorMode()
     
        seq = ChordProgression(root,theMode,chordSeq)
        seq.setStutter(stutter)
 
        time = 0
 
        all_notes = timingInfo.grabCombo(seq,k,n,0,list(seqtypes))
 
        post_notes_to_score(all_notes)
        
        CURRENT_DATA.update(root,mode,chordSeq,["%s"%x for x in seqtypes],division,note_prop,chord_len,k,n)
        if CURRENT_DATA.changed :
            Utils.log("Changed\n%s" % CURRENT_DATA)
            
    except Exception as e :
        Utils.log("Exception\n%s" % e)
        
