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



[i,ii,iii,iv,v,vi] = chordsInKey C

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
	where [i,ii,iii,iv,v,vi] = chordsInKey G

t = rep 2
q = rep 4

line1 = (q ta) ++ (t tb) ++ (q ta ++ t tb) ++ (t tb2) ++ (q ta)
newBass = chordsToMelody (\e (AChord memchord) -> chordToBassNote memchord)
line2 = newBass line1 Rest


	
