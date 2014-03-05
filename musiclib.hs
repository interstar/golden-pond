module Musiclib where
import Codec.Midi
import Data.List

-- based on miditest by http://www.increpare.com/2008/10/basic-haskell-midi-file-output/

-- named notes
data NNote = A | Bb | B | C | Db | D | Eb | E | F | Gb | G | Ab deriving (Eq, Ord, Show, Read, Enum)

noteAbove :: NNote -> NNote
noteAbove Ab = A
noteAbove x = succ x

noteBelow :: NNote -> NNote
noteBelow A = Ab
noteBelow x = pred x

nup :: NNote -> Int -> NNote
nup n i = (iterate noteAbove n) !! i

numToNote :: Int -> NNote
numToNote mn = toEnum((mn - 21) `mod` 12 ) :: NNote

noteToNum :: NNote -> Int -> Int
noteToNum n oct = fromEnum(n) + 21 + (12 * oct)

-- chords
data Modality = Major | Minor deriving (Eq, Ord, Show, Read, Enum)
data Chord = Chord Int Modality [Annotate] deriving (Eq, Show, Read)


major3 :: Int -> [Int]
major3 n = [n, n+4, n+7]

minor3 :: Int -> [Int]
minor3 n = [n, n+3, n+7]

add :: Int -> [Int] -> Int -> [Int]
add root ns x = ns ++ [root+x] 

data Annotate = Open | Seventh | Ninth | Rootless | Spread | Invert deriving (Eq, Ord, Show, Read, Enum)		
txChordNotes :: Int -> Annotate -> [Int] -> [Int]
txChordNotes root Seventh notes = add root notes 11
txChordNotes root Ninth notes = add root (txChordNotes root Seventh notes) 14
txChordNotes root Rootless notes = [x | x <- notes, x /= root]
txChordNotes root Spread [] = []
txChordNotes root Spread (n:ns)
    | (length ns) `mod` 2 == 0 = n:rest 
    | otherwise = n+12:rest
    where rest = (txChordNotes root Spread ns)
        

    


notesFrom :: Chord -> [Int]	
notesFrom (Chord root modality anns) =
    let base = (if (modality==Major) then (major3 root) else (minor3 root) )
        f = (txChordNotes root)
    in foldr f base anns
    


data Event = Note Int | AChord Chord | Rest deriving (Show)
type Melody = [Event]
type MidiEvent = (Ticks, Message)

ann :: Chord -> Annotate -> Chord
ann (Chord root mod ats) an = Chord root mod (an:ats)

midiSkeleton :: Track Ticks -> Track Ticks -> Midi
midiSkeleton t1 t2 =  Midi {
         fileType = MultiTrack, 
         timeDiv = TicksPerBeat 480, 
         tracks = [
           [
             (0,ChannelPrefix 0),
             (0,TrackName " Grand Piano  "),
             (0,InstrumentName "GM Device  1"),
             (0,TimeSignature 4 2 24 8),
             (0,KeySignature 0 0)
           ] ++ t1 ++ [
             (0,TrackEnd)
           ],
           [
             (1,ChannelPrefix 1),
             (1,TrackName " Track 2  "),
             (37,InstrumentName "GM Device  1"),
             (1,TimeSignature 4 2 24 8),
             (1,KeySignature 0 0)
           ] ++ t2 ++ [
             (1,TrackEnd)
           ]
         ]
       }  


keydown_ :: Int -> Int -> Int -> MidiEvent
keydown_ dur chan k =  (dur,NoteOn {channel = chan, key = k, velocity = 80})

keydown = keydown_ 0

keyup_ :: Int -> Int -> Int -> MidiEvent
keyup_ dur chan k =  (dur,NoteOn {channel = chan, key = k, velocity = 0})

keyup0 = keyup_ 0
keyup = keyup_ 480

renderEvent :: Int -> Event -> Track Ticks
renderEvent chan (Rest)     = [keyup chan 0]
renderEvent chan (Note n)   = [ keydown chan n, keyup chan n]
renderEvent chan (AChord (Chord root modality attributes)) = map ckeydown ns ++ [keyup chan (head ns)] ++ map ckeyup0 (tail ns)
	where ns = notesFrom (Chord root modality attributes)
	      ckeydown = keydown chan
	      ckeyup0 = keyup0 chan

	
ticks :: Int -> [Event] -> Track Ticks
ticks chan events = concat $ map crenderEvent events
    where crenderEvent = renderEvent chan

createMidi :: FilePath -> Melody -> Melody -> IO()
createMidi f track1 track2 = exportFile  f $ midiSkeleton (ticks 0 track1) (ticks 1 track2)

c :: NNote -> Modality -> Int -> Event
c note mod oct = (AChord (Chord (noteToNum note oct) mod []))

chordToBassNote :: Chord -> Event
chordToBassNote (Chord root modality attributes) 
    | root < 24 = (Note root)
    | otherwise = (Note (root-12))

extractBassline :: [Event] -> Event -> [Event]
extractBassline [] _ = []
extractBassline ((Note n):es) event = (Rest):extractBassline es (Note n)
extractBassline ((AChord (Chord root modality attributes)):es) event =
    (chordToBassNote chord):extractBassline es (AChord chord)
    where chord = (Chord root modality attributes)
    
extractBassline ((Rest):es) (AChord (Chord root modality attributes)) = 
    (chordToBassNote chord):extractBassline es (Rest)
    where chord = (Chord root modality attributes)

extractBassline ((Rest):es) event = (Rest):extractBassline es (Rest)
    

-- first simplifications
chordSeq :: Modality -> Int -> [(NNote,Int)] -> [Event]
chordSeq _ _ [] = []
chordSeq mod numrests ((note,oct):ns) = 
	((c note mod oct) : rests) ++ (chordSeq mod numrests ns)
	where rests = replicate numrests Rest

testSeq1 = chordSeq Minor 3 [ 
	(C, 1),
	(G, 1),
	(A, 1),
	(F, 2),
	(D, 1),
	(A, 1)
	]


-- second simplifications

rep :: Int -> [a] -> [a]
rep 0 _  = []
rep i xs = xs ++ (rep (i-1) xs)


an :: Event -> Annotate -> Event
an (Rest) a = Rest
an (Note i) a = Note i
an (AChord (Chord root modality atts)) a = AChord (ann (Chord root modality atts) a)

chordSeqInkey :: NNote -> [(Int->Event)]
chordSeqInkey key  = 
    let
        i =   c (nup key 0) Major 
        ii =  c (nup key 2) Minor
        iii = c (nup key 4) Minor
        iv =  c (nup key 5) Major
        v =   c (nup key 7) Major
        vi =  c (nup key 9) Minor
    in
        [i,ii,iii,iv,v,vi]

[i,ii,iii,iv,v,vi] = chordSeqInkey C

every :: Int -> Event -> [Event]
every n e = [e] ++ replicate (n-1) (Rest)

e4 = every 4

ta = concat [
        e4 (i  2),
	    e4 (v  2),
        e4 (vi 2),
	    e4 (an (iv  3) Seventh)
	]
	
tb = concat [
	e4 (ii  2),
	e4 (iii 2),
    e4 (an (vi  3) Spread),
	e4 (v	2)
	] 

tb2 = concat [
	e4 (ii  2),
	e4 (an (iii 2) Spread),
    e4 (an (vi  3) Spread),
	e4 (an (an (v	2) Seventh) Spread)
	]
	where [i,ii,iii,iv,v,vi] = chordSeqInkey G

t = rep 2
q = rep 4

line1 = (q ta) ++ (t tb) ++ (q ta ++ t tb) ++ (t tb2) ++ (q ta)
line2 = extractBassline line1 Rest


