// goldenpond.js


// Constants
const MAJOR = 0;
const MINOR = 1;

const MODAL_INTERCHANGE = "MODAL_INTERCHANGE";
const SEVENTH = "SEVENTH";
const NINTH = "NINTH";
const SECONDARY = "SECONDARY";
const VOICE_LEADING = "VOICE_LEADING";

class ChordThing {
    constructor(key, mode, degree, length = 1) {
        this.key = key;
        this.mode = mode;
        this.degree = degree;
        this.length = length;
        this.modifiers = new Set();
        this.inversion = 0;
        this.secondaryBase = null;
        this.secondaryTarget = null;
    }

    setAsSecondary(secondaryBase, secondaryTarget) {
        this.modifiers.add('SECONDARY');
        this.secondaryBase = secondaryBase;
        this.secondaryTarget = secondaryTarget;
        return this;
    }

    swapMode() {
        this.mode = (this.mode === MAJOR) ? MINOR : MAJOR;
        return this;
    }

    modalInterchange() {
        this.modifiers.add('MODAL_INTERCHANGE');
        return this;
    }

    hasModalInterchange() {
        return this.modifiers.has('MODAL_INTERCHANGE');
    }

    seventh() {
        this.modifiers.add('SEVENTH');
        this.modifiers.delete('NINTH');
        return this;
    }

    ninth() {
        this.modifiers.add('NINTH');
        this.modifiers.delete('SEVENTH');
        return this;
    }

    setInversion(inversion) {
        this.inversion = inversion;
        return this;
    }

    toString() {
        let modeStr = this.mode === MAJOR ? "MAJOR" : "MINOR";
        let degreeStr = this.modifiers.has('SECONDARY') ? `(${this.secondaryBase}/${this.secondaryTarget})` : `${this.degree}`;
        let modifiersStr = this.modifiers.size === 0 ? "{}" : `{${Array.from(this.modifiers).join(", ")}}`;
        
        return `ChordThing(${this.key},${modeStr},${degreeStr},${this.inversion},${this.length}) + ${modifiersStr}`;
    }

    clone() {
        let cloned = new ChordThing(this.key, this.mode, this.degree, this.length);
        cloned.modifiers = new Set(this.modifiers);
        cloned.inversion = this.inversion;
        cloned.secondaryBase = this.secondaryBase;
        cloned.secondaryTarget = this.secondaryTarget;
        return cloned;
    }

    hasExtensions() {
        return this.modifiers.has('SEVENTH') || this.modifiers.has('NINTH');
    }
}
    

class ChordParser {
    constructor(key, mode) {
        this.key = key;
        this.mode = mode;
    }

    _parseSeparator(inputString) {
        const separators = ['|', ',', '&'];
        if (inputString && separators.includes(inputString[0])) {
            return [inputString[0], inputString.substring(1)];
        }
        return [null, inputString];
    }

    _parseTranspose(inputString) {
        let transposeChars = [];
        while (inputString && ![',', '|'].includes(inputString[0])) {
            transposeChars.push(inputString[0]);
            inputString = inputString.substring(1);
        }
        const transposeString = transposeChars.join('').trim();
        if (!['>', '<'].includes(transposeString[0])) {
            throw new Error(`Expected '>' or '<' at the start of '${transposeString}'`);
        }
        const transposeValue = parseInt(transposeString.substring(1));
        if (transposeString[0] === '>') {
            this.key += transposeValue;
        } else {
            this.key -= transposeValue;
        }
        return inputString;
    }

    _parseItem(inputString) {
        let itemChars = [];
        let insideParentheses = false;
        while (inputString && (insideParentheses || ![',', '|', '&', '>', '<'].includes(inputString[0]))) {
            const char = inputString[0];
            if (char === '(') insideParentheses = true;
            else if (char === ')') insideParentheses = false;
            itemChars.push(char);
            inputString = inputString.substring(1);
        }
        return [itemChars.join('').trim(), inputString];
    }

    _interpretItem(itemString) {
        let isModalInterchange = false;
        if (itemString.startsWith('-')) {
            isModalInterchange = true;
            itemString = itemString.substring(1);
        }

        let inversion = 0;
        while (itemString.includes('i')) {
            inversion++;
            itemString = itemString.replace('i', '');
        }

        let chord;

        if (itemString.includes('(') && itemString.includes(')')) {
            // Handle secondary notation (y/x)
            const [extensionString, secondaryPart] = itemString.split('(');
            const [secondaryBase, secondaryTarget] = secondaryPart.slice(0, -1).split('/').map(Number);
            
            chord = new ChordThing(this.key, this.mode, secondaryTarget);
            chord.setAsSecondary(secondaryBase, secondaryTarget);
            chord.setInversion(inversion);

            const extension = Number(extensionString);
            if (extension === 7) {
                chord.seventh();
            } else if (extension === 9) {
                chord.ninth();
            }
        } else {
            const itemValue = Number(itemString);

            if (1 <= itemValue && itemValue <= 7) {
                chord = new ChordThing(this.key, this.mode, itemValue);
            } else if (71 <= itemValue && itemValue <= 77) {
                chord = new ChordThing(this.key, this.mode, itemValue - 70).seventh();
            } else if (91 <= itemValue && itemValue <= 97) {
                chord = new ChordThing(this.key, this.mode, itemValue - 90).ninth();
            } else {
                throw new Error(`Unexpected item value: ${itemString}`);
            }
        }

        if (isModalInterchange) {
            chord.modalInterchange();
        }
        
        chord.setInversion(inversion);
        return chord;
    }


    parse(inputString) {
        let chords = [];
        while (inputString) {
            const [separator, remainingString] = this._parseSeparator(inputString);
            let voiceLeadNext = separator === '&';

            if (remainingString[0] === '!') {
                this.mode = this.mode === MAJOR ? MINOR : MAJOR;
                inputString = remainingString.substring(1);
            } else if (['>', '<'].includes(remainingString[0])) {
                inputString = this._parseTranspose(remainingString);
            } else {
                const [itemString, nextString] = this._parseItem(remainingString);
                const chord = this._interpretItem(itemString);
                if (voiceLeadNext) {
                    chord.modifiers.add("VOICE_LEADING");
                }
                chords.push(chord);
                inputString = nextString;
            }
        }
        return chords;
    }
}


// MAKING CHORDS

function buildChord(root, intervals) {
    let chord = [root];
    for (let interval of intervals) {
        chord.push(chord[chord.length - 1] + interval);
    }
    return chord;
}

function chordTypes() {
    return {
        'M': (root) => buildChord(root, [4, 3]),
        'm': (root) => buildChord(root, [3, 4]),
        'dim': (root) => buildChord(root, [3, 3]),
        'M7': (root) => buildChord(root, [4, 3, 4]),
        'm7': (root) => buildChord(root, [3, 4, 3]),
        'dom7': (root) => buildChord(root, [4, 3, 3]),
        'dim7': (root) => buildChord(root, [3, 3, 3]),
        'halfdim': (root) => buildChord(root, [3, 3, 4]),
        'sus2': (root) => buildChord(root, [2, 5]),
        'sus4': (root) => buildChord(root, [5, 2]),
        'aug': (root) => buildChord(root, [4, 4]),
        'dimM7': (root) => buildChord(root, [3, 3, 4])
    };
}

function octaveTransform(inputChord, root=60) {
    return inputChord.map(note => (note - root + 12) % 12);
}

function twoOctaveTransform(inputChord, root=60) {
    return inputChord.map(note => root + ((note - root + 24) % 24) - 12);
}


function tMatrix(chordA, chordB) {
    return chordA.map((note, index) => chordB[index] - note);
}



function get_permutations(notes) {
    function permute(arr) {
        if (arr.length === 0) return [[]];
        const [first, ...rest] = arr;
        const permsWithoutFirst = permute(rest);
        let allPerms = [];
        permsWithoutFirst.forEach(perm => {
            for (let i = 0; i <= perm.length; i++) {
                let permWithFirst = [...perm.slice(0, i), first, ...perm.slice(i)];
                allPerms.push(permWithFirst);
            }
        });
        return allPerms;
    }
    return permute(notes);
}

function voice_lead(chordA, chordB) {
    const transformedA = twoOctaveTransform(chordA);
    const transformedB = twoOctaveTransform(chordB);

    // If chordA has more notes than chordB, drop the excess notes from chordA
    while (transformedA.length > transformedB.length) {
        transformedA.pop();
    }

    // If chordB has more notes than chordA, drop the excess notes from chordB
    while (transformedB.length > transformedA.length) {
        transformedB.pop();
    }

    let bestVoicing = null;
    let minDistance = Infinity;

    const permsOfB = get_permutations(transformedB);

    for (const permutedB of permsOfB) {
        const currentTMatrix = tMatrix(transformedA, permutedB);
        let totalDistance = currentTMatrix.reduce((acc, val) => acc + Math.abs(val), 0);
        
        // Penalize for notes that are too close to each other
        for (let i = 0; i < permutedB.length - 1; i++) {
            if ([1, 2].includes(Math.abs(permutedB[i] - permutedB[i + 1]))) {
                totalDistance += 10;  // Add a penalty
            }
        }

        if (totalDistance < minDistance) {
            minDistance = totalDistance;
            bestVoicing = transformedA.map((note, index) => note + currentTMatrix[index]);
        }
    }

    return bestVoicing;
}



class ChordMaker {
    constructor() {
        this.ct = chordTypes();  // Assuming chordTypes() is a function that returns a dictionary (object) of chord types
    }

    buildChord(root, chordType) {
        return this.ct[chordType](root);
    }

    findDegreeNoteAndChordType(root, mode, degree) {
        let dnc;
        if (mode === MAJOR) {
            dnc = [[0,'M','M7'],[2,'m','m7'],[4,'m','m7'],[5,'M','M7'],[7,'M','dom7'],
                   [9,'m','m7'],[11,'dim','halfdim']][degree-1];
        } else {
            dnc = [[0,'m','m7'],[2,'dim','halfdim'],[3,'M','M7'],[5,'m','m7'],[7,'m','m7'],
                   [8,'M','M7'],[10,'M','dom7']][degree-1];
        }
        return [dnc[0] + root, dnc[1], dnc[2]];
    }

    generate_secondary_chord(chordThing) {
        // Determine the tonicized key
        let tonicized_key = this.findDegreeNoteAndChordType(chordThing.key, chordThing.mode, chordThing.secondaryTarget)[0];
        // Create a new ChordThing for the secondary chord based on the tonicized key
        let secondary_chord_thing = new ChordThing(tonicized_key, MAJOR, chordThing.secondaryBase); // We'll use MAJOR mode since we're tonicizing

        // Copy modifiers from the original chordThing to the new secondary_chord_thing (excluding the SECONDARY modifier)
        secondary_chord_thing.modifiers = new Set(chordThing.modifiers);
        secondary_chord_thing.modifiers.delete(SECONDARY);
        secondary_chord_thing.inversion = chordThing.inversion;

        // Return the chord generated for the secondary_chord_thing
        return this.oneChord(secondary_chord_thing);
    }


    oneChord(chordThing, previous_chord = null) {
        let chord;

        // Check if it's a secondary chord
        if (chordThing.modifiers.has(SECONDARY)) {
            chord = this.generate_secondary_chord(chordThing);
        } else {
            if (chordThing.hasModalInterchange()) {
                let nct = chordThing.clone();
                nct.swapMode();
                nct.modifiers.delete(MODAL_INTERCHANGE);
                return this.oneChord(nct, previous_chord);
            }

            let dnc = this.findDegreeNoteAndChordType(chordThing.key, chordThing.mode, chordThing.degree);

            if (!chordThing.hasExtensions()) {
                chord = this.buildChord(dnc[0], dnc[1]);
            } 
            if (chordThing.modifiers.has(SEVENTH)) {
                chord = this.buildChord(dnc[0], dnc[2]);
            } 
            if (chordThing.modifiers.has(NINTH)) {
                chord = this.buildChord(dnc[0], dnc[2]);
            }

            // Generate chord in the correct inversion
            let inversion = chordThing.inversion;
            while (inversion > 0) {
                chord = [...chord.slice(1), chord[0] + 12];
                inversion--;
            }
        }

        // Apply voice leading if previous_chord is provided and VOICE_LEADING modifier exists
        if (previous_chord && chordThing.modifiers.has(VOICE_LEADING)) {
            chord = voice_lead(previous_chord, chord);
        }

        return chord;
       }

    chordProgression(chordThings) {
        let chords = [];
        let prev_chord = null;

        for (let ct of chordThings) {
            let chord = this.oneChord(ct, prev_chord);
            chords.push(chord);
            prev_chord = chord;
        }

        return chords;
    }

    chordProgressionFromString(root, mode, scoreString) {
        let cp = new ChordParser(root, mode);
        let chordThings = cp.parse(scoreString);
        return this.chordProgression(chordThings);
    }
}


// Placeholder for voice_lead function
function voice_lead(chordA, chordB) {
    // ... (Implementation to come later)
    return [];
}


class Note {
    constructor(note, time, length) {
        this.note = note;
        this.time = time;
        this.length = length;
    }
}

class TimingInfo {
    constructor(beatCode, noteProportion, chordMultiplier, ppq) {
        this.beatMapping = {
            0: 1/16,
            1: 1/12,
            2: 1/8,
            3: 1/6,
            4: 1/4,
            5: 1/3,
            6: 1/2,
            7: 1/1
        };

        this.ppq = ppq;
        this.beatFraction = this.beatMapping[beatCode];
        this.noteProportion = noteProportion;
        this.chordMultiplier = chordMultiplier;

        this.beatLength = this.ppq * this.beatFraction;
        this.noteLength = this.beatLength * this.noteProportion;
        this.chordLength = this.beatLength * this.chordMultiplier;
    }

    static distributePulsesEvenly(k, n) {
        let rhythm = Array(n).fill(0);
        let stepSize = n / k;
        let currentStep = 0;
        for (let i = 0; i < k; i++) {
            rhythm[Math.round(currentStep)] = 1;
            currentStep += stepSize;
        }
        return rhythm;
    }

    *rhythmGenerator(k, n) {
        let rhythm = TimingInfo.distributePulsesEvenly(k, n);
        let index = 0;
        while (true) {
            yield rhythm[index];
            index = (index + 1) % rhythm.length;
        }
    }

    static *chordNoteGenerator(chord) {
        let index = 0;
        while (true) {
            yield chord[index];
            index = (index + 1) % chord.length;
        }
    }

    chords(seq, startTime) {
        let allNotes = [];
        let currentTime = startTime;

        for (let c of seq) {
            for (let note of c) {
                allNotes.push({
                    note: note,
                    startTime: currentTime,
                    length: this.noteLength * this.chordMultiplier * 0.5
                });
            }
            currentTime += this.beatLength * this.chordMultiplier;
        }

        return allNotes;
    }

    bassline(seq, k, n, startTime) {
        let allNotes = [];
        let currentTime = startTime;

        let rhythmGen = this.rhythmGenerator(k, n);

        for (let c of seq) {
            let rootNote = c[0] - 12;
            let beatsForCurrentChord = 0;

            while (beatsForCurrentChord < this.chordMultiplier) {
                let beat = rhythmGen.next().value;
                if (beat === 1) {
                    allNotes.push({
                        note: rootNote,
                        startTime: currentTime,
                        length: this.noteLength
                    });
                }
                currentTime += this.beatLength;
                beatsForCurrentChord++;

                if (beatsForCurrentChord === this.chordMultiplier) {
                    rhythmGen = this.rhythmGenerator(k, n);
                }
            }
        }

        return allNotes;
    }

    arpeggiate(seq, k, n, startTime) {
        let allNotes = [];
        let currentTime = startTime;

        let rhythmGen = this.rhythmGenerator(k, n);

        for (let c of seq) {
            let noteGen = TimingInfo.chordNoteGenerator(c);
            let beatsForCurrentChord = 0;

            while (beatsForCurrentChord < this.chordMultiplier) {
                let beat = rhythmGen.next().value;
                if (beat === 1) {
                    allNotes.push({
                        note: noteGen.next().value,
                        startTime: currentTime,
                        length: this.noteLength
                    });
                }
                currentTime += this.beatLength;
                beatsForCurrentChord++;

                if (beatsForCurrentChord === this.chordMultiplier) {
                    rhythmGen = this.rhythmGenerator(k, n);
                }
            }
        }

        return allNotes;
    }
}



// TODO: Add the translated tests below



// Unit testing framework
let ERRORS = 0;

function testit(id, val, target, msg) {
    if (JSON.stringify(val) !== JSON.stringify(target)) {
        console.error(`ERROR IN ${id} : ${msg}`);
        console.error("Wanted:");
        console.error(target);
        console.error("Got:");
        console.error(val);
    } else {
        console.log(`${id} OK`);
    }
}

// ChordThing tests

testit("ChordThing", `${new ChordThing(60, MAJOR, 3, 2).seventh()}`, "ChordThing(60,MAJOR,3,0,2) + {SEVENTH}", "ChordThings");

let ct1 = new ChordThing(60, MAJOR, 3, 2);
testit("ChordThing no extensions", ct1.hasExtensions(), false, "ChordThings");
testit("ChordThing string with no extensions", `${ct1}`, "ChordThing(60,MAJOR,3,0,2) + {}", "ChordThings");
ct1 = new ChordThing(60, MAJOR, 3, 2).ninth();
testit("ChordThing has extensions", ct1.hasExtensions(), true, "ChordThings");

testit("ChordThing ninths override sevenths", `${new ChordThing(60, MAJOR, 3, 2).seventh().ninth()}`, "ChordThing(60,MAJOR,3,0,2) + {NINTH}", "ChordThings");
testit("ChordThing sevenths override ninths", `${new ChordThing(60, MAJOR, 3, 2).ninth().seventh()}`, "ChordThing(60,MAJOR,3,0,2) + {SEVENTH}", "ChordThings");
testit("ChordThing modal interchange", `${new ChordThing(60, MAJOR, 3, 2).modalInterchange()}`, "ChordThing(60,MAJOR,3,0,2) + {MODAL_INTERCHANGE}", "ChordThings");
testit("ChordThing has modal interchange", new ChordThing(60, MAJOR, 3, 2).modalInterchange().hasModalInterchange(), true, "ChordThings");
testit("ChordThing swap mode", new ChordThing(60, MAJOR, 3, 2).swapMode().mode, MINOR, "ChordThings");
testit("ChordThing swap mode", new ChordThing(60, MINOR, 3, 2).swapMode().mode, MAJOR, "ChordThings");


cp = new ChordParser(60,MAJOR);
testit("ChordParser", `${cp.parse("1")}`, "ChordThing(60,MAJOR,1,0,1) + {}", "Parse one chord");
testit("ChordParser", `${cp.parse("1,2")}`, "ChordThing(60,MAJOR,1,0,1) + {},ChordThing(60,MAJOR,2,0,1) + {}", "Parse two chords");


testit("Simple chords",
    cp.parse("1,4,6,5").map(c => c.toString()),
    ['ChordThing(60,MAJOR,1,0,1) + {}', 'ChordThing(60,MAJOR,4,0,1) + {}', 'ChordThing(60,MAJOR,6,0,1) + {}', 'ChordThing(60,MAJOR,5,0,1) + {}'],
    "ChordParsing simple chords");

testit("Extended chords",
    cp.parse("71,-94,6ii,-5").map(c => c.toString()),
    ["ChordThing(60,MAJOR,1,0,1) + {SEVENTH}", "ChordThing(60,MAJOR,4,0,1) + {NINTH, MODAL_INTERCHANGE}", 'ChordThing(60,MAJOR,6,2,1) + {}', "ChordThing(60,MAJOR,5,0,1) + {MODAL_INTERCHANGE}"],
    "ChordParsing extended chords");


// Create an instance of ChordMaker
let cm = new ChordMaker();

// Unit tests
testit("Major Triads", cm.chordProgressionFromString(60, MAJOR, "1|4|5|6"),
    [[60, 64, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
    "Basic major triads");

testit("Minor Triads", cm.chordProgressionFromString(60, MINOR, "1|4,5|6"),
    [[60, 63, 67], [65, 68, 72], [67, 70, 74], [68, 72, 75]],
    "Basic minor triads");

testit("Major Triads with modal interchange", cm.chordProgressionFromString(60, MAJOR, "-1|4|5|6"),
    [[60, 63, 67], [65, 69, 72], [67, 71, 74], [69, 72, 76]],
    "Basic major triads with modal interchange");

testit("Minor Sevenths", cm.chordProgressionFromString(60, MINOR, "72,75,71"),
    [[62, 65, 68, 72], [67, 70, 74, 77], [60, 63, 67, 70]], "Minor 7ths");


testit("Chord Inversions", 
       cm.chordProgressionFromString(60, MAJOR, "1|4i"),
       [[60, 64, 67], [69, 72, 77]],
       "Chord inversions");

testit("Chord Inversions with extensions", 
       cm.chordProgressionFromString(60, MAJOR, "4,74,74i,74ii,74iii"),
       [[65, 69, 72], [65, 69, 72, 76], [69, 72, 76, 77], [72, 76, 77, 81], [76, 77, 81, 84]],
       "Chord inversions 2");

testit("Modulate to new key",
       cm.chordProgressionFromString(60, MAJOR, "1|4|>2|1|4|<1|1|4"),
       [[60, 64, 67], [65, 69, 72], [62, 66, 69], [67, 71, 74], [61, 65, 68], [66, 70, 73]],
       "Modulating basic triads by 2");

testit("Modulate to new mode",
       cm.chordProgressionFromString(60, MAJOR, "1|4|5|7|!|1|4|5|7"),
       cm.chordProgressionFromString(60, MAJOR, "1|4|5|7|-1|-4|-5|-7"),
       "Modulating mode");


testit("VOICE_LEADING Parser Test",
    cp.parse("1&6").map(c => c.toString()),
    ["ChordThing(60,MAJOR,1,0,1) + {}", 
     "ChordThing(60,MAJOR,6,0,1) + {VOICE_LEADING}"],
    "Parsing & separator for voice leading");


// More voice leading
testit("octaveTransform Test 1", 
    octaveTransform([60, 64, 67], 60), 
    [0, 4, 7], 
    "Transforming chord [60, 64, 67] with root 60");

testit("octaveTransform Test 2", 
    octaveTransform([60, 76, 79], 65), 
    [7, 11, 2], 
    "Transforming chord [60, 76, 79] with root 65");

testit("octaveTransform Test 3", 
    octaveTransform([72, 76, 67], 60), 
    [0, 4, 7], 
    "Transforming chord [72, 76, 67] with root 60");

testit("tMatrix Test 1", 
    tMatrix([60, 64, 67], [60, 64, 67], 60), 
    [0, 0, 0], 
    "Matrix between chords [60, 64, 67] and [60, 64, 67] with root 60");
    
testit("tMatrix Test 2", 
    tMatrix([60, 64, 67], [60, 76, 79], 65), 
    [0, 12, 0], 
    "Matrix between chords [60, 64, 67] and [60, 76, 79] with root 65");

          
testit("Secondary chords",
    cp.parse("(5/4),4").map(c => c.toString()),
    ["ChordThing(60,MAJOR,(5/4),0,1) + {SECONDARY}",
     "ChordThing(60,MAJOR,4,0,1) + {}"],
    "Testing secondary chords");

testit("Making secondary chords",
    JSON.stringify(cm.chordProgressionFromString(60,MAJOR,'(5/2),2,5,1')),
    "[[69,73,76],[62,65,69],[67,71,74],[60,64,67]]",    
    "Making a secondary (5/2)");

testit("Making secondary chords with modifiers",
    JSON.stringify(cm.chordProgressionFromString(60,MAJOR,'7(5/2),72,75,71')),
    "[[69,73,76,79],[62,65,69,72],[67,71,74,77],[60,64,67,71]]",    
    "Making a secondary 7(5/2)");
 
ti = new TimingInfo(4,0.8,16,960)
seq = cm.chordProgressionFromString(60,MAJOR,'72,75,71')

testit("TimingInfo chords",
    JSON.stringify(ti.chords(seq,0)),
    '[{"note":62,"startTime":0,"length":1536},{"note":65,"startTime":0,"length":1536},{"note":69,"startTime":0,"length":1536},{"note":72,"startTime":0,"length":1536},{"note":67,"startTime":3840,"length":1536},{"note":71,"startTime":3840,"length":1536},{"note":74,"startTime":3840,"length":1536},{"note":77,"startTime":3840,"length":1536},{"note":60,"startTime":7680,"length":1536},{"note":64,"startTime":7680,"length":1536},{"note":67,"startTime":7680,"length":1536},{"note":71,"startTime":7680,"length":1536}]',
    "Making Chords from a 2,5,1")
    
testit("TimingInfo bassline",
    JSON.stringify(ti.bassline(seq,3,8,0)),
    '[{"note":50,"startTime":0,"length":192},{"note":50,"startTime":720,"length":192},{"note":50,"startTime":1200,"length":192},{"note":50,"startTime":1920,"length":192},{"note":50,"startTime":2640,"length":192},{"note":50,"startTime":3120,"length":192},{"note":55,"startTime":3840,"length":192},{"note":55,"startTime":4560,"length":192},{"note":55,"startTime":5040,"length":192},{"note":55,"startTime":5760,"length":192},{"note":55,"startTime":6480,"length":192},{"note":55,"startTime":6960,"length":192},{"note":48,"startTime":7680,"length":192},{"note":48,"startTime":8400,"length":192},{"note":48,"startTime":8880,"length":192},{"note":48,"startTime":9600,"length":192},{"note":48,"startTime":10320,"length":192},{"note":48,"startTime":10800,"length":192}]',
    "Making Bassline from a 2,5,1")
    
testit("TimingInfo arp",
    JSON.stringify(ti.arpeggiate(seq,3,8,0)),
    '[{"note":62,"startTime":0,"length":192},{"note":65,"startTime":720,"length":192},{"note":69,"startTime":1200,"length":192},{"note":72,"startTime":1920,"length":192},{"note":62,"startTime":2640,"length":192},{"note":65,"startTime":3120,"length":192},{"note":67,"startTime":3840,"length":192},{"note":71,"startTime":4560,"length":192},{"note":74,"startTime":5040,"length":192},{"note":77,"startTime":5760,"length":192},{"note":67,"startTime":6480,"length":192},{"note":71,"startTime":6960,"length":192},{"note":60,"startTime":7680,"length":192},{"note":64,"startTime":8400,"length":192},{"note":67,"startTime":8880,"length":192},{"note":71,"startTime":9600,"length":192},{"note":60,"startTime":10320,"length":192},{"note":64,"startTime":10800,"length":192}]',
    "Making Arpeggio from a 2,5,1")
  
function testTiming() {
    let ti = new TimingInfo(4, 0.8, 16, 960);
    let seq = cm.chordProgressionFromString(60, MAJOR, '72,75,71');

    testit("TimingInfo Chords 2",
        ti.chords(seq, 0),
        [
            {note: 62, startTime: 0, length: 1536.0},
            {note: 65, startTime: 0, length: 1536.0},
            {note: 69, startTime: 0, length: 1536.0},
            {note: 72, startTime: 0, length: 1536.0},
            {note: 67, startTime: 3840.0, length: 1536.0},
            {note: 71, startTime: 3840.0, length: 1536.0},
            {note: 74, startTime: 3840.0, length: 1536.0},
            {note: 77, startTime: 3840.0, length: 1536.0},
            {note: 60, startTime: 7680.0, length: 1536.0},
            {note: 64, startTime: 7680.0, length: 1536.0},
            {note: 67, startTime: 7680.0, length: 1536.0},
            {note: 71, startTime: 7680.0, length: 1536.0}
        ],
        "Chord Times");

    testit("TimingInfo Bass 2",
        ti.bassline(seq, 3, 8, 0),
        [
            {note: 50, startTime: 0, length: 192.0},
            {note: 50, startTime: 720, length: 192.0},
            {note: 50, startTime: 1200, length: 192.0},
            {note: 50, startTime: 1920, length: 192.0},
            {note: 50, startTime: 2640, length: 192.0},
            {note: 50, startTime: 3120, length: 192.0},
            {note: 55, startTime: 3840, length: 192.0},
            {note: 55, startTime: 4560, length: 192.0},
            {note: 55, startTime: 5040, length: 192.0},
            {note: 55, startTime: 5760, length: 192.0},
            {note: 55, startTime: 6480, length: 192.0},
            {note: 55, startTime: 6960, length: 192.0},
            {note: 48, startTime: 7680, length: 192.0},
            {note: 48, startTime: 8400, length: 192.0},
            {note: 48, startTime: 8880, length: 192.0},
            {note: 48, startTime: 9600, length: 192.0},
            {note: 48, startTime: 10320, length: 192.0},
            {note: 48, startTime: 10800, length: 192.0}
        ],
        "Bassline Times");

    testit("TimingInfo Arpeggiate 2",
        ti.arpeggiate(seq, 3, 8, 0),
        [
            {note: 62, startTime: 0, length: 192.0},
            {note: 65, startTime: 720, length: 192.0},
            {note: 69, startTime: 1200, length: 192.0},
            {note: 72, startTime: 1920, length: 192.0},
            {note: 62, startTime: 2640, length: 192.0},
            {note: 65, startTime: 3120, length: 192.0},
            {note: 67, startTime: 3840, length: 192.0},
            {note: 71, startTime: 4560, length: 192.0},
            {note: 74, startTime: 5040, length: 192.0},
            {note: 77, startTime: 5760, length: 192.0},
            {note: 67, startTime: 6480, length: 192.0},
            {note: 71, startTime: 6960, length: 192.0},
            {note: 60, startTime: 7680, length: 192.0},
            {note: 64, startTime: 8400, length: 192.0},
            {note: 67, startTime: 8880, length: 192.0},
            {note: 71, startTime: 9600, length: 192.0},
            {note: 60, startTime: 10320, length: 192.0},
            {note: 64, startTime: 10800, length: 192.0}
        ],
        "Arp Times");
}

testTiming();



