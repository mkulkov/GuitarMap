"""Bake deterministic, reference-informed guitar anchor samples.

The supplied MP3 files contain chords and musical phrases rather than isolated
chromatic notes, so they are used as timbre references instead of being
blindly pitch-shifted. The generated bank keeps one exact fundamental per WAV
and the runtime only transposes to the nearest anchor (at most six semitones).
"""

from __future__ import annotations

import argparse
import hashlib
import math
import struct
import wave
from pathlib import Path

MIX_RATE = 44_100
DURATION_SECONDS = 2.4
PEAK = 0.30
MIDI_NOTES = (24, 36, 48, 60, 72, 84, 96, 108)

REFERENCE_FILES = {
    "electric": (
        "guitar-electro.mp3",
        "a473650e7a5b332cd4d5c4be94b5c4284815ae87f2cd698e48428428e652871b",
    ),
    "acoustic": (
        "guitar-sacustic.mp3",
        "0fe2776fdbb2ec35e4c2ce6f3e37463483e315dc34a44c297f7e6e57f809ef95",
    ),
}

ACOUSTIC_HARMONICS = (1.00, 0.46, 0.31, 0.23, 0.17, 0.13, 0.10, 0.078, 0.060, 0.047, 0.036, 0.028)
ELECTRIC_HARMONICS = (0.78, 0.24, 0.48, 0.18, 0.38, 0.15, 0.30, 0.12, 0.24, 0.10, 0.19, 0.08)


def smooth_attack(time: float, seconds: float) -> float:
    progress = min(1.0, max(0.0, time / seconds))
    return progress * progress * (3.0 - 2.0 * progress)


def tail_fade(time: float) -> float:
    start = DURATION_SECONDS - 0.14
    if time <= start:
        return 1.0
    progress = (time - start) / (DURATION_SECONDS - start)
    return math.cos(min(1.0, progress) * math.pi * 0.5) ** 2


def next_noise(state: int) -> tuple[int, float]:
    state = (state * 1_103_515_245 + 12_345) & 0x7FFFFFFF
    return state, (float(state & 0xFFFF) / 32767.5) - 1.0


def synthesize(midi_note: int, timbre: str) -> list[float]:
    frequency = 440.0 * 2.0 ** ((midi_note - 69) / 12.0)
    frame_count = round(MIX_RATE * DURATION_SECONDS)
    harmonics = ACOUSTIC_HARMONICS if timbre == "acoustic" else ELECTRIC_HARMONICS
    phases = [0.055 * index * index for index in range(len(harmonics))]
    noise_state = 0x41C64E6D ^ (midi_note * 7_919) ^ (17 if timbre == "electric" else 0)
    previous_noise = 0.0
    previous_filtered = 0.0
    lowpass_alpha = 1.0 - math.exp(-math.tau * 4_900.0 / MIX_RATE)
    samples: list[float] = []

    for frame in range(frame_count):
        time = frame / MIX_RATE
        phase = math.tau * frequency * time
        body = 0.0
        for index, amplitude in enumerate(harmonics):
            harmonic = index + 1
            if frequency * harmonic >= MIX_RATE * 0.45:
                break
            decay = (1.32 + index * 0.24) if timbre == "acoustic" else (0.54 + index * 0.105)
            body += amplitude * math.sin(phase * harmonic + phases[index]) * math.exp(-decay * time)

        noise_state, noise = next_noise(noise_state)
        pick = noise - previous_noise * 0.82
        previous_noise = noise
        if timbre == "acoustic":
            transient = pick * 0.36 * math.exp(-72.0 * time)
            soundboard = 1.0 + 0.052 * math.sin(math.tau * 3.2 * time) * math.exp(-2.8 * time)
            sample = (body * soundboard + transient) * smooth_attack(time, 0.0017)
        else:
            transient = pick * 0.22 * math.exp(-88.0 * time)
            # Reduce nonlinear drive in the top register where extra partials
            # would cross Nyquist and fold back as inharmonic aliasing.
            drive = max(0.72, 1.85 / (1.0 + max(0.0, frequency - 900.0) / 2_600.0))
            driven = (body + transient) * drive
            sample = math.tanh(driven) / math.tanh(drive)
            previous_filtered += lowpass_alpha * (sample - previous_filtered)
            sample = previous_filtered * smooth_attack(time, 0.0012) * math.exp(-0.22 * time)
        samples.append(sample * tail_fade(time))

    peak = max(abs(value) for value in samples)
    gain = PEAK / max(peak, 1.0e-12)
    return [max(-PEAK, min(PEAK, value * gain)) for value in samples]


def bake(output: Path, midi_note: int, timbre: str) -> None:
    samples = synthesize(midi_note, timbre)
    frames = bytearray()
    for sample in samples:
        frames.extend(struct.pack("<h", round(sample * 32767.0)))
    output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(MIX_RATE)
        stream.writeframes(frames)


def verify_references(reference_directory: Path | None) -> None:
    if reference_directory is None:
        return
    for filename, expected_hash in REFERENCE_FILES.values():
        source = reference_directory / filename
        if not source.is_file():
            raise FileNotFoundError(source)
        actual_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        if actual_hash != expected_hash:
            raise ValueError(f"Unexpected reference content: {source} ({actual_hash})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--reference-directory",
        type=Path,
        help="Optional directory containing the two exact supplied MP3 files; hashes are verified.",
    )
    args = parser.parse_args()
    verify_references(args.reference_directory)
    root = Path(__file__).resolve().parents[1]
    for timbre in ("acoustic", "electric"):
        for midi_note in MIDI_NOTES:
            bake(root / "assets" / "audio" / timbre / f"midi_{midi_note}.wav", midi_note, timbre)


if __name__ == "__main__":
    main()
