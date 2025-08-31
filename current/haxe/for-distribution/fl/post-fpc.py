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

def addFpcLine(form, i):
    """Adds controls for a single FPC line to the form."""
    form.AddInputText(f"Pat{i}", "")  # Pattern input
    form.AddInputKnob(f"Vel{i}", 0.8, 0, 1)  # Velocity
    form.AddInputKnobInt(f"Note{i}", 35 + i, 0, 127)  # MIDI Note

def createDialog():
    form = flp.ScriptDialog("GoldenPond FPC",
    """Create drum patterns for FPC. Each line triggers a different MIDI note.\r\nSee http://gilbertlisterresearch.com/ for documentation on the rhythm language."""
)

    form.AddInputKnobInt('Pattern Duration (beats)', 4, 1, 64)
    form.AddInputKnobInt('Repetitions', 4, 1, 64)
    form.AddInputKnob('Note Proportion', 0.5, 0.01, 1.0)
    form.AddInputCheckbox("Silent", False)

    # Add 8 FPC lines
    for i in range(1, 9):
        addFpcLine(form, i)

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
    Utils.log("--- GoldenPond FPC Script Started ---")
    if form.GetInputValue("Silent") == 1:
        flp.score.clearNotes(False)
        return

    pattern_duration_beats = form.GetInputValue('Pattern Duration (beats)')
    repetitions = form.GetInputValue('Repetitions')
    note_prop = form.GetInputValue('Note Proportion')

    time_manipulator = TimeManipulator().setPPQ(96).setBPM(120).setChordDuration(pattern_duration_beats)
    all_notes = []

    # Create a dummy progression that repeats, to control the total length.
    # The LineGenerator will play the rhythm pattern once for each "chord" in the progression.
    progression_string = ",".join(["1"] * repetitions)
    dummy_progression = ChordProgression(60, Mode.getMajorMode(), progression_string)

    for i in range(1, 9):
        try:
            pattern = form.GetInputValue(f"Pat{i}")
            if not pattern.strip():
                continue
            
            Utils.log(f"--- Processing Line {i}: Raw Pattern='{pattern}' ---")

            parts = pattern.strip().split(' ')
            if "/" not in pattern and "%" not in pattern and len(parts) == 1:
                pattern = f"{pattern} 1"
                Utils.log(f"Line {i}: Added default density. Using Pattern='{pattern}'")

            velocity = form.GetInputValue(f"Vel{i}")
            target_midi_note = form.GetInputValue(f"Note{i}")

            rhythm_gen = RhythmLanguage.parse(pattern)
            if rhythm_gen.parseFailed():
                Utils.log(f"Line {i}: ERROR - Failed to parse rhythm pattern.")
                continue
            
            Utils.log(f"Line {i}: Successfully parsed pattern.")

            instrument_context = MidiInstrumentContext(i, int(velocity * 127), note_prop, 0)

            # Generate notes using the dummy progression to get the rhythm.
            line_generator = LineGenerator(time_manipulator, dummy_progression, rhythm_gen, instrument_context)
            notes_with_wrong_pitch = line_generator.generateNotes(0)

            if notes_with_wrong_pitch:
                # Post-processing: Create a new list of notes with the correct pitch.
                corrected_notes = []
                for wrong_note in notes_with_wrong_pitch:
                    # Create a new Note object, copying timing but overriding the pitch.
                    corrected_note = Note(
                        wrong_note.chan,
                        target_midi_note, # Override the pitch here
                        wrong_note.velocity,
                        wrong_note.startTime,
                        wrong_note.length
                    )
                    corrected_notes.append(corrected_note)
                
                Utils.log(f"Line {i}: SUCCESS - Generated and corrected {len(corrected_notes)} notes.")
                all_notes.extend(corrected_notes)
            else:
                Utils.log(f"Line {i}: WARNING - Note generation returned no notes.")

        except Exception as e:
            Utils.log(f"Line {i}: CRITICAL ERROR - An unexpected exception occurred: {e}")
            continue

    Utils.log(f"--- Finalizing --- Total notes to be added: {len(all_notes)}")
    if all_notes:
        try:
            flp.score.clearNotes(False)
            post_notes_to_score(all_notes)
            Utils.log("Successfully posted notes to score.")
        except Exception as e:
            Utils.log(f"CRITICAL ERROR - Failed to post notes to score: {e}")
    else:
        Utils.log("No notes were generated for any line. Piano roll was not changed.")