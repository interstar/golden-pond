
# We need to leave a couple of blank lines at the top of this file


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
      
def addChan(form, name, vname, tname):
    form.AddInputText(name, "")  # Pattern input
    form.AddInputKnob(vname, 0.6, 0, 1)  # Volume
    form.AddInputKnobInt(tname, 0, -3, 3)  # Transposition
    
def createDialog():
    form = flp.ScriptDialog("GoldenPond",
    """GoldenPond is language for defining chord progressions and rhythm patterns.\r\n
See http://gilbertlisterresearch.com/ for documentation.""")
    
    form.AddInputKnobInt('Root', 65, 32, 96)
    form.AddInputCombo('Mode', ["major","minor","harmonic minor","melodic minor"], 0)
    form.AddInputText('ChordSeq', "1,4,5,1")

    # Add 6 channels with volume and octave controls
    for i in range(1, 7):
        addChan(form, f"Chan{i}", f"Vol{i}", f"Oct{i}")

    form.AddInputKnob('Note Proportion', 0.8, 0.1, 1.5)
    form.AddInputKnobInt('Chord Duration', 4, 1, 16)
    form.AddInputKnobInt("Stutter", 0, 0, 16)
    form.AddInputCheckbox("Silent", False)
    
    return form


def post_notes_to_score(notes_list):
    for note in notes_list:
        flp.score.addNote(makeNote(
            note.getMidiNoteValue(),
            note.getStartTime(),
            note.getLength(),
            color=note.chan,
            velocity=note.velocity/127.0
        ))


def apply(form):
    data = GoldenData()
    
    # Set basic parameters
    data.root = form.GetInputValue('Root')
    data.mode = form.GetInputValue('Mode')
    data.chordSequence = form.GetInputValue('ChordSeq')
    data.stutter = form.GetInputValue("Stutter")
    data.chordDuration = form.GetInputValue('Chord Duration')
    data.bpm = 120  # FL Studio handles BPM separately

    # Handle silent checkbox first
    if form.GetInputValue("Silent")==1:
        flp.score.clearNotes(False)
        return

    all_notes = []
    
    # Process each channel separately so failures don't affect other channels
    for i in range(1, 7):
        try:
            pattern = form.GetInputValue(f"Chan{i}")
            if not pattern.strip():
                continue

            volume = form.GetInputValue(f"Vol{i}")
            octave = form.GetInputValue(f"Oct{i}")
            gate_length = form.GetInputValue('Note Proportion')
            
            # Create instrument context for this line
            instrument_context = MidiInstrumentContext(
                i-1,  # channel
                int(volume * 127),  # velocity
                gate_length,  # gate length
                octave * 12  # transpose (convert octaves to semitones)
            )
            
            # Add line to GoldenData
            data.addLine(pattern, instrument_context)
            
            # Try to generate notes for this line
            try:
                generator = data.makeLineGenerator(len(data.lines) - 1)
                notes = generator.generateNotes(0)
                if notes:  # Only add if we got notes back
                    all_notes.extend(notes)
            except Exception as e:
                Utils.log(f"Warning: Failed to generate notes for channel {i}: {e}")
                continue
                
        except Exception as e:
            Utils.log(f"Warning: Failed to process channel {i}: {e}")
            continue

    # Only clear and update if we successfully generated notes
    if all_notes:
        try:
            flp.score.clearNotes(False)
            post_notes_to_score(all_notes)
        except Exception as e:
            Utils.log(f"Error posting notes to score: {e}")