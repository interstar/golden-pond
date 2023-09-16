## Modern Japanese chord progression
## Based on https://www.youtube.com/watch?v=yKV58VVGV9k
## See https://www.youtube.com/watch?v=ADr8hrjpKbo

define :oneChord do | tonic, mode, deg |
  majorKeyTriads = [:M,:m,:m,:M,:M,:m,:dim]
  minorKeyTriads = [:m,:dim,:M,:m,:m,:M,:M]
  majorKey7s = [:M7,:m7,:m7,:M7,:dom7,:m7,:halfdiminished]
  minorKey7s = [:m7,:halfdiminished,:M7,:m7,:m7,:M7,:dom7]
  
  # First test if deg is actually an array.
  # Because if it is, this is a more complex chord item
  if deg.class == Array then
    # Representation here is [chord-deg, inversion]
    # chord-deg is understood as degree to calculate chord,
    # inversion is 1 (first inversion), 2 (2nd inversion),
    # -1 (first inversion and drop an octave
    # -2 (second inversion and drop an octave)
    
    t,m,c = oneChord(tonic,mode,deg[0])
    
    case deg[1]
    when 0
      newChord = c
    when 1
      newChord = c[1..10]+[c[0]+12]
    when 2
      newChord = c[2..10]+[c[0]+12]+[c[1]+12]
    when 3
      newChord = c[3..10]+[c[0]+12]+[c[1]+12]+[c[2]+12]
      
    when -1
      newChord = (c[1..10]+[c[0]+12]).map {|n| n-12 }
    when -2
      newChord = (c[2..10]+[c[0]+12]+[c[1]+12]).map {|n| n - 12}
    when -3
      newChord = (c[3..10]+[c[0]+12]+[c[1]+12]+[c[2]+12]).map {|n| n - 12}
      
    else
      newChord = c
    end
    return [t,m,newChord]
  end
  
  
  # Modal interchange (negative numbers major <-> minor)
  if deg < 0 then
    return oneChord(tonic,(mode=="major") ? "minor" : "major",-deg)
  end
  
  case deg
  when 1..7 # Simple Triads
    root = degree(deg,tonic,mode)
    lookup = (mode == "major") ? majorKeyTriads : minorKeyTriads
    theChord = chord(root,lookup[deg-1])
  when 71..77 # Seventh Chords
    deg = deg - 70
    root = degree(deg,tonic,mode)
    lookup = (mode == "major") ? majorKey7s : minorKey7s
    theChord = chord(root,lookup[deg-1])
  when 21..27 # Secondary dominants
    deg = deg - 20
    original_root = degree(deg,tonic,mode)
    root = degree(5,original_root,mode)
    theChord = chord(root,:dom7)
    tonic = root
  when 41..47 # augmented (built out of intervals of 4)
    deg = deg - 40
    root = degree(deg,tonic,mode)
    theChord = [root,root+4,root+8]
  when 61..67 # Secondary diminished.(1 below 7)
    # Diminished 7ths half-step below the chord
    deg = deg - 60
    croot = degree(deg,tonic,mode)
    root = croot -1 # half step down
    theChord = chord(root,:dim7)
    tonic = root
  end
  return [tonic,mode,theChord]
end

define :chordSeq do | tonic, mode, degs |
  cs = []
  degs.each { | deg |
    xs = oneChord(tonic,mode,deg)
    cs.append(xs)
  }
  cs
end


use_bpm 120

with_fx :reverb do
  with_synth :piano do
    c = []
    tonic = :C3
    mode = "major"
    live_loop :piano do
      
      #cs9 Modern Japanese chords
      # from https://www.youtube.com/watch?v=yKV58VVGV9k
      cs9a = chordSeq(:A2,"major",[
                        4,5,73,6, [24,-2],74,75,[71,2],
                        4,5,73,6, [24,-2],74,5,-6,
                        
                        -4,-3,3,[4,-2], [1,2],75,46,-76,
                        -4,-3,5,[4,-1], 3,5,26,76
      ])
      cs9b = chordSeq(:A2,"major",[
                        [-7,-1],[-7,-1],[7,-2],[7,-2],
                        [74,2],[74,2],[71,1],[41,1]
      ])
      cs9 = [cs9a,cs9a,cs9b].flatten(1)
      
      css1 = [4]
      
      cs9.each {| xs |
        tonic,mode,c = xs
        
        #play c, amp: 0.8, decay: 2
        #play c[0]-12, amp: 0.2, decay: 2
        
        c.each {|cn| midi cn, channel: 1,
        port: "loopbe_internal_midi_1"}
        midi c[0]-12, channel: 1, port: "loopbe_internal_midi_1"
        
        sleep css1.tick(:tt)
        
      }
    end
    
    with_fx :flanger do
      with_fx :reverb do
        with_synth :prophet do
          live_loop :p2 do
            v = 0.45
            dec = 0.2
            sus = 0.1
            rel = 0.1
            
            oct = 0
            oct2 = 12
            oct3 = 24
            
            sleeps = [0.5, 0.5, 0.5, 0.5]
            sleep sleeps.tick(:WW)
            
            n = 12+c.choose + [oct,oct2].choose
            
            #play n, amp: v, decay: dec, sustain: sus, release: rel
            midi n, channel: 1, port: "loopbe_internal_midi_1"
            
            sleep sleeps.tick(:WW)
            
            #play n, amp: v, decay: dec, sustain: sus, release: rel
            midi n, channel: 1, port: "loopbe_internal_midi_1"
            
            sleep sleeps.tick(:WW)
            
            n = 12+c.choose+ [oct2,oct3].choose
            #play n, amp: v, decay: dec, sustain: sus, release: rel
            midi n, channel: 1, port: "loopbe_internal_midi_1"
            
            sleep sleeps.tick(:WW)
            
            n = 12+scale(tonic,mode).choose+[oct2,oct3].choose
            #n = c.choose+[oct2,oct3].choose
            #play n, amp: [v,0].tick(:GG), decay: dec, sustain: sus, release: rel
            midi n, channel: 1, port: "loopbe_internal_midi_1"
            
          end
        end
      end
    end
  end
  
  
end





live_loop :drums do
  3.times do
    sample :bd_808, amp: 3
    sleep 1
    sample :drum_snare_hard, amp: 0.5
    sleep 1
    sample :bd_808, amp: 3
    sleep 0.5
    sample :bd_808, amp: 3
    sleep 0.5
    sample :drum_snare_hard, amp: 0.7
    sleep 1
  end
  
  sample :bd_808, amp: 3
  sleep 1
  sample :drum_snare_hard, amp: 0.5
  sleep 0.5
  sample :drum_snare_hard, amp: [0,0,0.5].choose
  
  sleep 0.5
  sleep 0.5
  sample :bd_808, amp: 3
  sleep 0.5
  sample :drum_snare_hard, amp: 0.7
  sleep 1
  
  
end


