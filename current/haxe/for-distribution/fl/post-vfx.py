# Goldenpond VFX Harmonizer Script
# Copyright (C) 2025 Phil Jones
# Based on the structure of the default "Snap to Scale" VFX Script.

import flvfx as vfx
import math

# Get the definitive interval patterns directly from the Mode class
# This assumes the main library (generated.py) is already loaded
MELODIC_MINOR_INTERVALS = Mode.getMelodicMinorMode().intervals
NATURAL_MINOR_INTERVALS = Mode.getMinorMode().intervals

def generate_scale_from_intervals(tonic, intervals):
    """Generates a 7-note scale from a tonic note and a list of step intervals."""
    scale_notes = [tonic]
    current_note = tonic
    for i in range(6): # Loop 6 times to get the next 6 notes
        current_note += intervals[i % len(intervals)]
        scale_notes.append(current_note)
    return scale_notes

# A custom voice class to track the original parent voice and corrected pitch.
class HarmonizerVoice(vfx.Voice):
    parent_voice = None
    corrected_note = 0

# This class holds the core logic and is instantiated at the end.
class GoldenPondHarmonizer:
    def __init__(self):
        self.progression = None
        self.last_known_sequence = ""
        self.last_known_root = -1
        self.last_known_mode = -1
        self.last_played_note = None # Add state for melodic direction

    def get_progression(self, root, mode_idx, sequence_str):
        if root is None or mode_idx is None or sequence_str is None:
            self.progression = None
            return None

        if (self.progression is None or 
            sequence_str != self.last_known_sequence or 
            root != self.last_known_root or 
            mode_idx != self.last_known_mode):
            try:
                mode_map = [Mode.getMajorMode, Mode.getMinorMode, Mode.getHarmonicMinorMode, Mode.getMelodicMinorMode]
                mode_obj = mode_map[int(mode_idx)]()
                self.progression = ChordProgression(int(root), mode_obj, sequence_str)
                self.last_known_sequence = sequence_str
                self.last_known_root = root
                self.last_known_mode = mode_idx
                print("GoldenPond Harmonizer: Progression updated.")
            except Exception as e:
                self.progression = None
                print(f"GoldenPond Harmonizer: Error creating progression: {e}")
        return self.progression

    def map_to_nearest_in_octave(self, note_in, notes_to_map_to):
        if not notes_to_map_to: return note_in
        note_in_class = note_in % 12
        min_dist = 12
        closest_tone_class = -1
        for tone in notes_to_map_to:
            tone_class = tone % 12
            dist = abs(note_in_class - tone_class)
            if dist > 6: dist = 12 - dist
            if dist < min_dist:
                min_dist = dist
                closest_tone_class = tone_class
        original_octave_base = note_in - note_in_class
        corrected_note = original_octave_base + closest_tone_class
        if abs(corrected_note - note_in) > 6:
            if note_in < corrected_note: corrected_note -= 12
            else: corrected_note += 12
        return corrected_note

harmonizer = GoldenPondHarmonizer()

def createDialog():
    form = vfx.ScriptDialog("GoldenPond Harmonizer", "Constrains MIDI to a chord progression.")
    form.addGroup("Progression Settings")
    form.addInputKnobInt("GPH: Root", 60, 0, 127)
    form.addInputCombo("GPH: Mode", "major,minor,harmonic minor,melodic minor", 0)
    form.addInputText("GPH: Chord Sequence", "1,4,5,1")
    form.addInputKnobInt("GPH: Chord Duration", 4, 1, 64)
    form.endGroup()
    return form

def onTriggerVoice(incoming_voice):
    # Get UI values
    root = vfx.context.form.getInputValue("Progression Settings:GPH: Root")
    mode_idx = vfx.context.form.getInputValue("Progression Settings:GPH: Mode")
    sequence_str = vfx.context.form.getInputValue("Progression Settings:GPH: Chord Sequence")
    chord_duration_beats = vfx.context.form.getInputValue("Progression Settings:GPH: Chord Duration")

    prog = harmonizer.get_progression(root, mode_idx, sequence_str)
    
    new_voice = HarmonizerVoice(incoming_voice)
    new_voice.parent_voice = incoming_voice
    original_note = new_voice.note
    
    # Determine melodic direction
    direction = 0 # 0 for none, 1 for ascending, -1 for descending
    if harmonizer.last_played_note is not None:
        if original_note > harmonizer.last_played_note:
            direction = 1
        elif original_note < harmonizer.last_played_note:
            direction = -1
    
    # Update the last played note for the next trigger
    harmonizer.last_played_note = original_note

    notes_for_log = [original_note]
    scale_notes = [original_note] # Default to the original note if something fails

    if prog is not None:
        ticks = vfx.context.ticks
        ppq = vfx.context.PPQ
        if not vfx.context.isPlaying: ticks = 0
        chord_duration_in_ticks = chord_duration_beats * ppq
        current_chord_index = 0
        if chord_duration_in_ticks > 0:
            current_chord_index = math.floor(ticks / chord_duration_in_ticks)
        
        chord_things = prog.toChordThings()
        if chord_things:
            active_chord = chord_things[current_chord_index % len(chord_things)]
            
            current_tonic = active_chord.key
            current_intervals = active_chord.mode.intervals
            
            # Check if the current mode is Melodic Minor
            is_melodic_minor = (current_intervals == MELODIC_MINOR_INTERVALS)
            
            intervals_to_use = current_intervals
            # If it is, and we are descending, use the Natural Minor scale instead
            if is_melodic_minor and direction == -1:
                intervals_to_use = NATURAL_MINOR_INTERVALS
            
            scale_notes = generate_scale_from_intervals(current_tonic, intervals_to_use)
            notes_for_log = scale_notes
    
    new_voice.corrected_note = harmonizer.map_to_nearest_in_octave(original_note, scale_notes)
    
    print(f"Harmonizer -> In: {original_note}, Scale: {notes_for_log}, Out: {new_voice.corrected_note}")

    new_voice.trigger()

def onTick():
    for v in vfx.context.voices:
        if hasattr(v, 'parent_voice') and v.parent_voice is not None:
            v.copyFrom(v.parent_voice)
            if hasattr(v, 'corrected_note'):
                v.note = v.corrected_note

def onReleaseVoice(incoming_voice):
    for v in vfx.context.voices:
        if hasattr(v, 'parent_voice') and v.parent_voice == incoming_voice:
            v.release()
            return