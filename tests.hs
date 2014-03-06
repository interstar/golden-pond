import Musiclib

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

c = newChord

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


