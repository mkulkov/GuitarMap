# GuitarMap audio reference and sample-bank provenance

## Supplied references

The two user-supplied files are treated as artistic references. They are not
copied into the runtime package and are not played back as note samples.

| Timbre | Supplied file | Technical profile | SHA-256 |
| --- | --- | --- | --- |
| Electric | `guitar-electro.mp3` | 3.452 s; mono; 11,025 Hz; dense chord/phrase; decoded peak +2.92 dBFS | `a473650e7a5b332cd4d5c4be94b5c4284815ae87f2cd698e48428428e652871b` |
| Acoustic | `guitar-sacustic.mp3` | 25.353 s; stereo; 44,100 Hz; repeated strums and musical phrases; decoded peak +2.66 dBFS | `0fe2776fdbb2ec35e4c2ce6f3e37463483e315dc34a44c297f7e6e57f809ef95` |

Objective analysis was performed with FFmpeg 8.1.2 and
`tools/analyze_guitar_references.py`. The electric example has one main dense
onset; its first stable analysis window has a spectral centroid near 2.14 kHz
and a rounded upper limit imposed by its 11.025 kHz sample rate. The acoustic
opening window is near 0.96 kHz, followed by strums ranging into roughly
2–3.7 kHz as multiple strings and pick noise overlap. The acoustic example contains many
overlapping attacks, a strong low/mid body, and a changing strummed texture.
Both decode above full scale; the acoustic file contains 11,264 samples at or
above full scale after mono conversion, while the electric file contains 137.

These are complete musical fragments rather than clean isolated notes. Taking
one fragment and pitch-shifting it across the fretboard would preserve several
simultaneous pitches, inherited clipping, and room/phrase content. That would
make the displayed MIDI pitch disagree with what the learner hears.

The reported reference spectral values describe polyphonic arrangements, so
they are useful for broad brightness and density targets rather than direct
single-note matching. A single C4 bank note is expected to have a lower
centroid than a chord containing several upper notes. Decay curves also cannot
be compared one-to-one because both references retrigger new material.
For a bounded sanity check, the generated C4 onset measures about 0.79 kHz for
acoustic and 1.45 kHz for electric, so the electric patch follows the
reference's brighter direction while remaining a single pitched note.

## Runtime bank

`tools/generate_guitar_wavs.py` builds deterministic single-note WAV anchors
for each timbre at MIDI 24, 36, 48, 60, 72, 84, 96, and 108. Passing
`--reference-directory` verifies that the exact supplied MP3 hashes are present
before rebuilding. The synthesis constants remain in the script so a normal
project build does not depend on the user's Downloads folder.

- Acoustic: fast pick transient, harmonic string body, gentle soundboard
  movement, and faster loss of upper partials.
- Electric: denser odd-harmonic structure, soft saturation, a rounded 4.9 kHz
  pickup/cabinet roll-off, and a slower sustain envelope.
- Both: mono PCM16 at 44.1 kHz, 2.4 seconds, peak amplitude 0.30
  (-10.46 dBFS), band-limited source harmonics, and a 140 ms cosine tail.

`GuitarAudioEngine` selects the nearest anchor and applies the exact
frequency ratio for the requested MIDI note. The maximum transposition is six
semitones. Twelve independent `AudioStreamPlayer` voices preserve multitouch
ownership, individual release, deterministic stealing, and all-notes-off on
focus loss. At maximum per-sample peak, the engine's 0.25 safe mix gain leaves
the theoretical 12-voice identical-phase sum below full scale.

`tools/render_audio_previews.py` renders `build/audio-preview/acoustic_demo.wav`
and `electric_demo.wav` from the actual anchor WAVs with the same nearest-anchor
pitch ratios. Each preview plays a short guitar-range melody followed by an
E-minor voicing. Preview files are normalized to -3 dBFS solely for convenient
audition; runtime voice gain remains conservative.

## Verification boundary

Automated tests verify exact pitch dominance, WAV format and duration, safe
peak and tail levels, distinct timbre/sustain spectra, anchor caching,
transposition limits, 12 independent voices, release, voice stealing, and
focus cleanup. These checks establish technical fitness; they do not establish
subjective similarity on speakers or headphones. Final artistic acceptance
still requires listening to both timbres in the running application, ideally
on a desktop and the target mobile device.
