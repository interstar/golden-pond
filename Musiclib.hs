module Musiclib (
	NNote (..)
,	nup
,	numToNote
,	noteToNum
,	Modality (..)
,	Annotate (..)
,	AChord (..)
,	major3
,	minor3
,	notesFrom
,	Event (..)
,	Melody
,	MidiEvent
,	midiSkeleton
,	ticks
,	createMidi
,	ann
,	newChord
,	chordsInKey
,	(//)
,	chordToBassNote
,	chordsToMelody

	
) where
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
data AChord = AChord Int Modality [Annotate] deriving (Eq, Show, Read)


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
        

    


notesFrom :: AChord -> [Int]	
notesFrom (AChord root modality anns) =
    let base = (if (modality==Major) then (major3 root) else (minor3 root) )
        f = (txChordNotes root)
    in foldr f base anns
    


data Event = Note Int | Chord AChord | Rest deriving (Eq, Show, Read)
type Melody = [Event]
type MidiEvent = (Ticks, Message)

ann :: AChord -> Annotate -> AChord
ann (AChord root mod ats) an = AChord root mod (an:ats)

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
renderEvent chan (Chord (AChord root modality attributes)) = map ckeydown ns ++ [keyup chan (head ns)] ++ map ckeyup0 (tail ns)
	where ns = notesFrom (AChord root modality attributes)
	      ckeydown = keydown chan
	      ckeyup0 = keyup0 chan

	
ticks :: Int -> [Event] -> Track Ticks
ticks chan events = concat $ map crenderEvent events
    where crenderEvent = renderEvent chan

createMidi :: FilePath -> Melody -> Melody -> IO()
createMidi f track1 track2 = exportFile  f $ midiSkeleton (ticks 0 track1) (ticks 1 track2)


newChord :: NNote -> Modality -> Int -> Event
newChord note mod oct = (Chord (AChord (noteToNum note oct) mod []))
    
infixl 8 //
(//) :: Event -> Annotate -> Event
(//) (Rest) a = Rest
(//) (Note i) a = Note i
(//) (Chord (AChord root modality atts)) a = Chord (ann (AChord root modality atts) a)

chordsInKey :: NNote -> [(Int->Event)]
chordsInKey key  = 
    let
        c = newChord
        i =   c (nup key 0) Major 
        ii =  c (nup key 2) Minor
        iii = c (nup key 4) Minor
        iv =  c (nup key 5) Major
        v =   c (nup key 7) Major
        vi =  c (nup key 9) Minor
    in
        [i,ii,iii,iv,v,vi]


chordsToMelody :: (Event -> Event -> Event) -> [Event] -> Event -> [Event]
chordsToMelody _ [] _ = []
chordsToMelody f ((Chord chord):es) memory = (f (Chord chord) (Chord chord)):(chordsToMelody f es (Chord chord))
chordsToMelody f (e:es) memory = (f e memory):(chordsToMelody f es memory)

chordToBassNote :: AChord -> Event
chordToBassNote (AChord root modality attributes)
    | root < 24 = (Note root)
    | otherwise = (Note (root-12))
