MAJOR = 0
MINOR = 1

MODAL_INTERCHANGE="MODAL_INTERCHANGE"
SEVENTH="SEVENTH"
NINTH="NINTH"
SECONDARY = "SECONDARY"
VOICE_LEADING = "VOICE_LEADING"


# Displaying the most up-to-date ChordThing class

class ChordThing:
    """ChordThing objects are what we parse score strings into.
       They hold all the data needed to create a chord and modify it.
    """
    def __init__(self, key, mode, degree, length=1):
        self.key = key
        self.mode = mode
        self.degree = degree
        self.length = length
        self.modifiers = set()
        self.inversion = 0
        self.secondary_base = None
        self.secondary_target = None        

    def set_as_secondary(self, secondary_base, secondary_target):
        self.modifiers.add(SECONDARY)
        self.secondary_base = secondary_base
        self.secondary_target = secondary_target
        return self

    def swap_mode(self):
        if self.mode == MAJOR:
            self.mode = MINOR
        else:
            self.mode = MAJOR
        return self
        
    def modal_interchange(self):
        self.modifiers.add(MODAL_INTERCHANGE)
        return self

    def has_modal_interchange(self):
        return MODAL_INTERCHANGE in self.modifiers        
        
    def seventh(self):
        self.modifiers.add(SEVENTH)
        self.modifiers.discard(NINTH)
        return self

    def ninth(self):
        self.modifiers.add(NINTH)
        self.modifiers.discard(SEVENTH)                    
        return self
        
    def set_inversion(self, inversion):
        self.inversion = inversion
        return self

    def __str__(self):
        mode = "MAJOR" if self.mode == MAJOR else "MINOR"
        
        # Check if it's a secondary chord and adjust the degree representation accordingly
        if SECONDARY in self.modifiers:
            degree_repr = f"({self.secondary_base}/{self.secondary_target})"
        else:
            degree_repr = str(self.degree)
        
        return "ChordThing(%s,%s,%s,%s,%s) + %s" % (self.key, mode, degree_repr, self.inversion, self.length, self.modifiers)    

    def clone(self):
        ct = ChordThing(self.key, self.mode, self.degree, self.length)
        ct.modifiers = self.modifiers.copy()
        ct.inversion = self.inversion
        ct.secondary_base = self.secondary_base
        ct.secondary_target = self.secondary_target
        return ct

    def has_extensions(self):
        return self.modifiers.intersection({SEVENTH, NINTH}) != set()
 



 
# Displaying the most up-to-date ChordParser class

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
            secondary_base, secondary_target = map(int, parts[1][:-1].split('/'))
            chord = ChordThing(self.key, self.mode, secondary_target)
            chord.set_as_secondary(secondary_base, secondary_target)
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
                        chord.modifiers.add(VOICE_LEADING)
                    chords.append(chord)
        
        return chords
 
