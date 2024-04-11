"""THIS DOESN'T REALLY WORK PROPERLY"""

def octave_transform(input_chord, root=60):
    """
    Squish things into a single octave for comparison between chords and sort from lowest to highest.
    """
    return sorted([root + (x % 12) for x in input_chord])

def t_matrix(chord_a, chord_b):
    """
    Get the distances between the notes of two chords.
    """
    transformed_a = octave_transform(chord_a)
    transformed_b = octave_transform(chord_b)
    return [b - a for a, b in zip(transformed_a, transformed_b)]

def get_permutations(lst):
    if len(lst) == 3:
        return [
            [lst[0], lst[1], lst[2]],
            [lst[0], lst[2], lst[1]],
            [lst[1], lst[0], lst[2]],
            [lst[1], lst[2], lst[0]],
            [lst[2], lst[0], lst[1]],
            [lst[2], lst[1], lst[0]]
        ]
    elif len(lst) == 4:
        return [
            [lst[0], lst[1], lst[2], lst[3]],
            [lst[0], lst[1], lst[3], lst[2]],
            [lst[0], lst[2], lst[1], lst[3]],
            [lst[0], lst[2], lst[3], lst[1]],
            [lst[0], lst[3], lst[1], lst[2]],
            [lst[0], lst[3], lst[2], lst[1]],
            [lst[1], lst[0], lst[2], lst[3]],
            [lst[1], lst[0], lst[3], lst[2]],
            [lst[1], lst[2], lst[0], lst[3]],
            [lst[1], lst[2], lst[3], lst[0]],
            [lst[1], lst[3], lst[0], lst[2]],
            [lst[1], lst[3], lst[2], lst[0]],
            [lst[2], lst[0], lst[1], lst[3]],
            [lst[2], lst[0], lst[3], lst[1]],
            [lst[2], lst[1], lst[0], lst[3]],
            [lst[2], lst[1], lst[3], lst[0]],
            [lst[2], lst[3], lst[0], lst[1]],
            [lst[2], lst[3], lst[1], lst[0]],
            [lst[3], lst[0], lst[1], lst[2]],
            [lst[3], lst[0], lst[2], lst[1]],
            [lst[3], lst[1], lst[0], lst[2]],
            [lst[3], lst[1], lst[2], lst[0]],
            [lst[3], lst[2], lst[0], lst[1]],
            [lst[3], lst[2], lst[1], lst[0]]
        ]
    else:
        return [lst]  # Return the list itself if it's not of length 3 or 4


def voice_lead(chord_a, chord_b):
    """
    Determine the voice leading between two chords.
    """
    transformed_a = octave_transform(chord_a)
    transformed_b = octave_transform(chord_b)

    # If chord_a has more notes than chord_b, drop the excess notes from chord_a
    while len(transformed_a) > len(transformed_b):
        transformed_a.pop()  # Drop the highest note

    # If chord_b has more notes than chord_a, drop the excess notes from chord_b
    while len(transformed_b) > len(transformed_a):
        transformed_b.pop()  # Drop the highest note

    best_voicing = None
    min_distance = float('inf')

    for permuted_b in get_permutations(transformed_b):
        t_mat = t_matrix(transformed_a, list(permuted_b))
        total_distance = sum(abs(t) for t in t_mat)
        
        # Penalize for notes that are too close to each other
        for i in range(len(permuted_b) - 1):
            if abs(permuted_b[i] - permuted_b[i + 1]) in [1, 2]:  # If notes are a semitone or a tone apart
                total_distance += 10  # Add a penalty

        if total_distance < min_distance:
            min_distance = total_distance
            best_voicing = [a + t for a, t in zip(chord_a, t_mat)]

    return best_voicing



    

