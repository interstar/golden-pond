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


[i,ii,iii,iv,v,vi] = chordsInKey C


ta = concat [
        (i  2 // Spread ) % 4,
        (vi 2) % 4,
	    (iv 3) % 4,
		(v  2) % 4
	]
	
tb = concat [
	(ii  2) % 4,
	(v	2) % 4,
	(iii 2) % 4,
    (vi  3 // Spread) % 4
	] 

tb2 = concat [
	(ii  2) % 4,
	(v 2 // Spread) % 4,
    (vi  3 // Spread) % 4,
	(vi	3 // Seventh // Spread) % 4
	]
	where [i,ii,iii,iv,v,vi] = chordsInKey G


line1 = (4 .* ta) ++ (2 .* tb) ++ (4 .* ta) ++ (4 .* tb) ++ (2 .* tb2) ++ (4 .* ta)
newBass = chordsToMelody (\e (Chord memchord) -> chordToBassNote memchord)
line2 = newBass line1 Rest


