# GoldenPond

## GoldenPond Overview
GoldenPond is a cross-platform library for musical chord progression generation and manipulation. Key characteristics:

- Written in Haxe for cross-platform compatibility
- Targets multiple languages/environments:
  - Python (FL Studio scripting, PyPI package)
  - JavaScript (browser-based applications)
  - Future targets: C++ (VST plugins), Java (Android)
- Two complementary domain-specific languages:
  - Chord progression language (existing)
  - Rhythm pattern language (this refactoring)
- Design philosophy:
  - Core music theory logic written once in Haxe
  - Platform-specific wrappers for different environments
  - Text-based interfaces for live coding scenarios
  - Flexibility in musical pattern generation


## Chord Language

[To Fill In]

## Pattern / Rhythm Language

### Two Pattern Types

1. **Euclidean Patterns**
   - Format: `k/n[+offset] type density`
   - Examples:
     ```
     3/8 > 4      # 3 hits in 8 steps, ascending notes, density 4
     3/8+1 > 4    # 3 hits in 8 steps with offset 1, ascending notes, density 4
     2/4 < 8      # 2 hits in 4 steps, descending notes, density 8
     2/4+2 < 8    # 2 hits in 4 steps with offset 2, descending notes, density 8
     ```
   - The Euclidean algorithm distributes k hits as evenly as possible across n steps
   - The optional offset parameter shifts the pattern by the specified number of positions
   - Note: While equivalent in length to explicit patterns, Euclidean patterns ensure even distribution of hits

2. **Explicit Patterns**
   - Format: `pattern density`
   - Examples:
     ```
     1.1. 8     # Root notes in positions 1 and 3, density 8
     >.>.=.>. 4 # Ascending pattern with note repeat, density 4
     c... 2     # Full chord then 3 gaps, density 2
     ```
   - Each character represents one step
   - Dots (.) represent gaps/rests

### Note Selection Characters

- Numbers (`1`, `2`, `3`, etc.): Select specific notes from chord (1-based indexing)
  - `1` = root note (internally index 0)
  - `2` = second note (internally index 1)
  - etc.

- Special Characters:
  - `>` = Ascending note from chord
  - `<` = Descending note from chord
  - `=` = Repeat last note
  - `c` = Full chord
  - `r` = Random note from chord
  - `.` = Gap/rest

### Pattern Parameters

- Density is always required
- Pattern length can be any number of steps
- Patterns are fitted to chord duration according to density

## Architectural Changes


## Implementation Plan

## Grammar Definition (Instaparse EDN Format)

```edn
pattern     = euclidean-pattern | explicit-pattern

(* Euclidean Pattern *)
euclidean-pattern = k separator n offset? <space> selector-type <space> density
k           = #'[0-9]+'
separator   = '/' | '%'    (* '/' for simple, '%' for Bjorklund *)
n           = #'[0-9]+'
offset      = '+' #'[0-9]+'
density     = #'[0-9]+'

(* Explicit Pattern *)
explicit-pattern = steps <space> density
steps       = step+
step        = note-selector | <'.'>

(* Note Selection *)
selector-type = '>' | '<' | 'r' | 'c' | '=' | #'[1-9]'
note-selector = selector-type

(* Common *)
space       = #'\s+'
```

### Grammar Explanation

- `pattern`: Either euclidean or explicit pattern
- `euclidean-pattern`: Two formats:
  - "3/8 > 4" (simple distribution)
  - "3%8 > 4" (Bjorklund algorithm)
  - k hits in n steps
  - selector-type for note selection
  - density parameter
- `separator`: Determines algorithm
  - '/': Simple even distribution
  - '%': Bjorklund's algorithm
- `explicit-pattern`: Format like "1.1. 8" or ">.>.=.>. 4"
  - sequence of steps (note selectors or dots)
  - density parameter

This grammar captures both pattern types and all note selection methods while enforcing the required density parameter.

## Known Patterns

The system correctly implements several well-known rhythm patterns:

- **Cuban Tresillo (3/8)**: `[1,0,0,1,0,0,1,0]` - A common Latin rhythm
- **Cuban Cinquillo (5/8)**: `[1,0,1,1,0,1,1,0]` - Another Latin rhythm
- **Cumbia/Calypso (3/4)**: `[1,0,1,1]` - Popular in Caribbean music
- **Ruchenitza (4/7)**: `[1,0,1,0,1,0,1]` - Bulgarian folk rhythm
- **Money (3/7)**: `[1,0,1,0,1,0,0]` - Used in Pink Floyd's "Money"
- **Bossa-Nova (5/16)**: `[1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,0]` - Brazilian rhythm

These patterns can be generated using the `BjorklundRhythmGenerator` with appropriate parameters. 
