 
from core import ChordThing, Mode, ChordFactory, MAJOR, MINOR



class ChordParser:
    def __init__(self, key, mode):
        self.key = key
        self.mode = mode
        
    def _parse_separator(self, input_string):
        separators = ['|', ',', '&']
        if input_string and (input_string[0] in separators):
            return input_string[0], input_string[1:]
        else:
            return None, input_string
    
    def _parse_transpose(self, input_string):
        transpose_chars = []
        while input_string and input_string[0] not in [',', '|']:
            transpose_chars.append(input_string[0])
            input_string = input_string[1:]
        transpose_string = ''.join(transpose_chars).strip()
        if transpose_string[0] not in ['>', '<']:
            raise ValueError(f"Expected '>' or '<' at the start of '{transpose_string}'")
        transpose_value = int(transpose_string[1:])
        if transpose_string[0] == '>':
            self.key += transpose_value
        else:
            self.key -= transpose_value
        return input_string
    
    def _parse_item(self, input_string):
        item_chars = []
        inside_parentheses = False
        while input_string and (inside_parentheses or (input_string[0] not in [',', '|', '&', '>', '<'])):
            char = input_string[0]
            if char == '(':
                inside_parentheses = True
            elif char == ')':
                inside_parentheses = False
            item_chars.append(char)
            input_string = input_string[1:]
        return ''.join(item_chars).strip(), input_string

    def _interpret_item(self, item_string):
        is_modal_interchange = False
        if item_string.startswith('-'):
            is_modal_interchange = True
            item_string = item_string[1:]

        # extract inversion from item_string
        inversion = 0
        if 'i' in item_string:
            inversion = item_string.count('i')
            item_string = item_string.replace('i', '')

        # Check for secondary notation (y/x)
        if '(' in item_string and ')' in item_string:
            extension = None
            parts = item_string.split('(')
            if len(parts[0]) > 0:
                extension = int(parts[0])
            secondary_degree, degree = map(int, parts[1][:-1].split('/'))
            chord = ChordThing(self.key, self.mode, degree)
            chord.set_as_secondary(secondary_degree)
            chord.set_inversion(inversion)
            if extension in [7, 9]:  # Add logic for other extensions if needed
                chord.seventh() if extension == 7 else chord.ninth()
            return chord

        item_value = int(item_string)
        
        if 1 <= item_value <= 7:
            chord = ChordThing(self.key, self.mode, item_value)
        elif 71 <= item_value <= 77:
            chord = ChordThing(self.key, self.mode, item_value - 70).seventh()
        elif 91 <= item_value <= 97:
            chord = ChordThing(self.key, self.mode, item_value - 90).ninth()
        else:
            raise ValueError(f"Unexpected item value: {item_string}")
        
        if is_modal_interchange:
            chord.modal_interchange()
        
        chord.set_inversion(inversion)
        
        return chord
    
    def parse(self, input_string):
        chords = []
        
        while input_string:
            separator, input_string = self._parse_separator(input_string)
            if separator == '&':
                voice_lead_next = True
            else:
                voice_lead_next = False
                
            if input_string:
                if input_string[0] == '!':
                    self.mode = MINOR if self.mode == MAJOR else MAJOR
                    input_string = input_string[1:]
                elif input_string[0] in ['>', '<']:
                    input_string = self._parse_transpose(input_string)
                else:
                    item_string, input_string = self._parse_item(input_string)
                    chord = self._interpret_item(item_string)
                    if voice_lead_next:
                        print("ADDING VOICE_LEADING")
                        chord.set_voice_leading()
                    chords.append(chord)
        
        return chords
        
        
class ChordProgression :
    def __init__(self,key,mode: Mode,scoreString) :
        self.key = key
        self.mode = mode
        self.scoreString = scoreString
    
    def toChordThings(self) :
    	return ChordParser(self.key,self.mode).parse(self.scoreString)
    	
    def toNotes(self) :
        return ChordFactory.chordProgression(self.toChordThings())
        
        
 
