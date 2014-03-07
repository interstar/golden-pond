import Musiclib

-- first simplifications
chordSeq :: Modality -> Int -> [(NNote,Int)] -> [Event]
chordSeq _ _ [] = []
chordSeq mod numrests ((note,oct):ns) = 
	((newChord note mod oct) : rests) ++ (chordSeq mod numrests ns)
	where 
		rests = replicate numrests Rest

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


infixl 8 //
(//) :: Event -> Annotate -> Event
(//) (Rest) a = Rest
(//) (Note i) a = Note i
(//) (AChord (Chord root modality atts)) a = AChord (ann (Chord root modality atts) a)

chordsInkey :: NNote -> [(Int->Event)]
chordsInkey key  = 
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

[i,ii,iii,iv,v,vi] = chordsInkey C

every :: Int -> Event -> [Event]
every n e = [e] ++ replicate (n-1) (Rest)

e4 = every 4

ta = concat [
        e4 (i  2),
	    e4 (v  2 ),
        e4 (vi 2),
	    e4 (iv 3 // Seventh )
	]
	
tb = concat [
	e4 (ii  2),
	e4 (iii 2),
    e4 (vi  3 // Spread),
	e4 (v	2)
	] 

tb2 = concat [
	e4 (ii  2),
	e4 (iii 2 // Spread),
    e4 (vi  3 // Spread),
	e4 (v	2 // Seventh // Spread)
	]
	where [i,ii,iii,iv,v,vi] = chordsInkey G

t = rep 2
q = rep 4

line1 = (q ta) ++ (t tb) ++ (q ta ++ t tb) ++ (t tb2) ++ (q ta)
line2 = extractBassline line1 Rest


-- experiments

chordsToMelody :: (Event -> Event -> Event) -> [Event] -> Event -> [Event]
chordsToMelody _ [] _ = []
chordsToMelody f ((AChord chord):es) memory = (f (AChord chord) (AChord chord)):(chordsToMelody f es (AChord chord))
chordsToMelody f (e:es) memory = (f e memory):(chordsToMelody f es memory)
	
newBass = chordsToMelody (\e (AChord memchord) -> chordToBassNote memchord)

line3 = newBass line1 Rest