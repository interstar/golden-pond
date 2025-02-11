// midi-file.js - A simple MIDI file writer

const midiFile = {
    debugMidiData: function(midiData) {
        let output = "MIDI Structure:\n";
        output += `Format: ${midiData.header.format}\n`;
        output += `Tracks: ${midiData.header.numTracks}\n`;
        output += `Ticks per beat: ${midiData.header.ticksPerBeat}\n\n`;
        
        midiData.tracks.forEach((track, trackIndex) => {
            output += `Track ${trackIndex}:\n`;
            track.forEach((event, eventIndex) => {
                output += `  Event ${eventIndex}:\n`;
                output += `    Delta: ${event.deltaTime}\n`;
                output += `    Type: ${event.type}\n`;
                switch(event.type) {
                    case 'setTempo':
                        output += `    Tempo: ${60000000 / event.microsecondsPerBeat} BPM\n`;
                        break;
                    case 'programChange':
                        output += `    Program: ${event.programNumber}\n`;
                        output += `    Channel: ${event.channel}\n`;
                        break;
                    case 'noteOn':
                    case 'noteOff':
                        output += `    Note: ${event.noteNumber}\n`;
                        output += `    Velocity: ${event.velocity}\n`;
                        output += `    Channel: ${event.channel}\n`;
                        break;
                }
                output += '\n';
            });
            output += '\n';
        });
        return output;
    },
    
    writeMidi: function(midiData) {
        console.log('Starting MIDI file generation');
        function writeVariableLengthQuantity(value) {
            let bytes = [];
            let v = value;
            do {
                let byte = v & 0x7F;
                v >>= 7;
                if (v > 0) byte |= 0x80;
                bytes.push(byte);
            } while (v > 0);
            return bytes;
        }

        function writeBytes(value, length) {
            let bytes = [];
            for (let i = 0; i < length; i++) {
                bytes.push((value >> ((length - 1 - i) * 8)) & 0xFF);
            }
            return bytes;
        }

        let bytes = [];
        console.log('Writing header');
        
        // Write header chunk
        bytes.push(0x4D, 0x54, 0x68, 0x64);  // MThd
        bytes.push(0, 0, 0, 6);              // Header length
        bytes.push(...writeBytes(midiData.header.format, 2));
        bytes.push(...writeBytes(midiData.header.numTracks, 2));
        bytes.push(...writeBytes(midiData.header.ticksPerBeat, 2));
        
        console.log('Header written:', bytes);

        // Write each track
        midiData.tracks.forEach((track, index) => {
            console.log(`Writing track ${index}`);
            bytes.push(0x4D, 0x54, 0x72, 0x6B);  // MTrk
            
            let trackBytes = [];
            track.forEach(event => {
                console.log('Writing event:', event);
                // Write delta time
                trackBytes.push(...writeVariableLengthQuantity(event.deltaTime));

                switch (event.type) {
                    case 'setTempo':
                        trackBytes.push(0xFF, 0x51, 0x03);
                        trackBytes.push(...writeBytes(event.microsecondsPerBeat, 3));
                        break;

                    case 'programChange':
                        trackBytes.push(0xC0 | event.channel);
                        trackBytes.push(event.programNumber);
                        break;

                    case 'noteOn':
                        trackBytes.push(0x90 | event.channel);
                        trackBytes.push(event.noteNumber);
                        trackBytes.push(event.velocity);
                        break;

                    case 'noteOff':
                        trackBytes.push(0x80 | event.channel);
                        trackBytes.push(event.noteNumber);
                        trackBytes.push(event.velocity);
                        break;
                }
            });
            
            // Add end of track marker
            trackBytes.push(0x00);  // Delta time
            trackBytes.push(0xFF, 0x2F, 0x00);  // End of track
            
            console.log(`Track ${index} bytes:`, trackBytes);
            bytes.push(...writeBytes(trackBytes.length, 4));
            bytes.push(...trackBytes);
        });

        console.log('Final byte count:', bytes.length);
        return bytes;
    }
};
