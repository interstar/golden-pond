
# We need to leave a couple of blank lines at the top of this file

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
    form.AddInputKnobInt('Density',4,1,8)
    form.AddInputKnob('Note Proportion',0.8,0.1,1.5)
    form.AddInputKnobInt('Chord Duration',4,1,16)
    form.AddInputKnobInt("Stutter",0,0,16)
    form.AddInputCheckbox("Silent",False)
    
    return form


def post_notes_to_score(notes_list):
    for note_data in notes_list:
        note = makeNote(
            note_data.getMidiNoteValue(),
            note_data.getStartTime(),
            note_data.getLength(),
            color=note_data.chan,
            velocity=note_data.velocity/127.0
        )
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
    # Create GoldenData instance
    data = GoldenData()
    
    # Set basic parameters
    data.root = form.GetInputValue('Root')
    data.mode = form.GetInputValue('Mode')
    data.chordSequence = form.GetInputValue('ChordSeq')
    data.stutter = form.GetInputValue("Stutter")
    data.chordDuration = form.GetInputValue('Chord Duration')
    data.bpm = 120  # FL Studio handles BPM separately
    
    # Get rhythm parameters
    k = form.GetInputValue('Rhythm k')
    n = form.GetInputValue('Rhythm n')
    density = form.GetInputValue('Density')
    note_prop = form.GetInputValue('Note Proportion')
    
    # Handle silent checkbox first
    if form.GetInputValue("Silent")==1:
        flp.score.clearNotes(False)
        return

    try:
        # Add lines based on checkboxes
        if form.GetInputValue("Chords")==1:
            pattern = f"{k}/{n} c {density}"
            data.addLine(pattern, MidiInstrumentContext(0, 100, note_prop, 0))

        if form.GetInputValue("Arp ↑")==1:
            pattern = f"{k}/{n} > {density}"
            data.addLine(pattern, MidiInstrumentContext(1, 100, note_prop, 0))

        if form.GetInputValue("Arp ↓")==1:
            pattern = f"{k}/{n} < {density}"
            data.addLine(pattern, MidiInstrumentContext(2, 100, note_prop, 0))

        if form.GetInputValue("Bass")==1:
            pattern = f"{k}/{n} 1 {density}"
            data.addLine(pattern, MidiInstrumentContext(3, 100, note_prop, -12))

        if form.GetInputValue("Top")==1:
            pattern = f"{k}/{n} t {density}"
            data.addLine(pattern, MidiInstrumentContext(4, 100, note_prop, 12))

        if form.GetInputValue("Random")==1:
            pattern = f"{k}%{n} r {density}"
            data.addLine(pattern, MidiInstrumentContext(5, 100, note_prop, 0))

        # Generate all lines using GoldenData
        all_notes = []
        for i in range(len(data.lines)):
            generator = data.makeLineGenerator(i)
            notes = generator.generateNotes(0)
            if notes:  # Only add if we got notes back
                all_notes.extend(notes)

        # Only clear and update if we successfully generated notes
        if all_notes:
            flp.score.clearNotes(False)
            post_notes_to_score(all_notes)
            
            if data.hasChanged():
                Utils.log("Project updated:\n%s" % data.toString())
            
    except Exception as e:
        Utils.log("Exception\n%s" % e)
        
