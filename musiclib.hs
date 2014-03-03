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
data Annotate = Open | Seventh | Ninth | Rootless | Spread | Invert deriving (Eq, Ord, Show, Read, Enum)
data Chord = Chord Int Modality [Annotate] deriving (Eq, Show, Read)

ann :: Chord -> Annotate -> Chord
ann (Chord root mod (at:ats)) an = (Chord root mod (an:at:ats))

major3 :: Int -> [Int]
major3 n = [n, n+4, n+7]

minor3 :: Int -> [Int]
minor3 n = [n, n+3, n+7]

addx :: Int -> [Int] -> Int -> [Int]
addx root ns x = ns ++ [root+x] 

add7 root ns = addx 7
add9 root ns = addx 9
		
notesFrom :: Chord -> [Int]	
notesFrom (Chord root modality anns)
	| modality == Major = major3 root
	| otherwise         = minor3 root




data Point = Note Int | AChord Chord | Rest deriving (Show)
type Melody = [Point]
type MidiEvent = (Ticks, Message)



midiSkeleton :: Track Ticks -> Midi
midiSkeleton mel =  Midi {
         fileType = MultiTrack, 
         timeDiv = TicksPerBeat 480, 
         tracks = [
          [
           (0,ChannelPrefix 0),
           (0,TrackName " Grand Piano  "),
           (0,InstrumentName "GM Device  1"),
           (0,TimeSignature 4 2 24 8),
           (0,KeySignature 0 0)
          ]
          ++
          mel
          ++
          [
           (0,TrackEnd)
          ]
         ]
       }  


keydown_ :: Int -> Int -> MidiEvent
keydown_ dur k =  (dur,NoteOn {channel = 0, key = k, velocity = 80})

keydown = keydown_ 0

keyup_ :: Int -> Int -> MidiEvent
keyup_ dur k =  (dur,NoteOn {channel = 0, key = k, velocity = 0})

keyup0 = keyup_ 0
keyup = keyup_ 480

playpoint :: Point -> Track Ticks
playpoint (Rest)     = [keyup 0]
playpoint (Note n)   = [ keydown n, keyup n]
playpoint (AChord (Chord root modality attributes)) = map keydown ns ++ [keyup (head ns)] ++ map keyup0 (tail ns)
	where ns = notesFrom (Chord root modality attributes)


	
	
createMidi :: FilePath -> Melody -> IO()
createMidi f notes = exportFile  f $ midiSkeleton $ concat $ map  playpoint notes

c :: NNote -> Modality -> Int -> Point
c note mod oct = (AChord (Chord (noteToNum note oct) mod []))

-- first simplifications
chordSeq :: Modality -> Int -> [(NNote,Int)] -> [Point]
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
i =   c C Major 
ii =  c D Minor
iii = c E Minor
iv =  c F Major
v =   c G Major
vi =  c A Minor


ta = intersperse Rest [
	i   2,
	v   2,
	vi  2,
	iv  3
	] 
tb = intersperse Rest [
	ii  2,
	iii 2,
	vi  3,
	v	2
	]
	
song = ta ++ [Rest] ++ ta ++ [Rest] ++ tb ++ [Rest] ++ ta ++ [Rest] ++ tb ++ [Rest] ++ tb ++ [Rest]
	