"""Render short audition WAVs through the same nearest-anchor sample strategy."""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

MIX_RATE = 44_100
ANCHORS = (24, 36, 48, 60, 72, 84, 96, 108)
MELODY = (40, 43, 45, 47, 50, 52, 55, 57, 59, 62, 64)
CHORD = (40, 47, 52, 55, 59, 64)  # Open-position E minor voicing.


def load_mono(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as source:
        assert source.getnchannels() == 1
        assert source.getsampwidth() == 2
        assert source.getframerate() == MIX_RATE
        data = np.frombuffer(source.readframes(source.getnframes()), dtype="<i2")
    return data.astype(np.float64) / 32768.0


def nearest_anchor(midi_note: int) -> int:
    return min(ANCHORS, key=lambda anchor: abs(midi_note - anchor))


def pitched(source: np.ndarray, semitones: int) -> np.ndarray:
    ratio = 2.0 ** (semitones / 12.0)
    positions = np.arange(max(1, math.floor(source.size / ratio)), dtype=np.float64) * ratio
    return np.interp(positions, np.arange(source.size), source)


def place_note(output: np.ndarray, note: np.ndarray, start: float, length: float, gain: float) -> None:
    rendered = note[: min(note.size, round(length * MIX_RATE))].copy()
    release_frames = min(rendered.size, round(0.07 * MIX_RATE))
    if release_frames:
        rendered[-release_frames:] *= np.linspace(1.0, 0.0, release_frames, endpoint=True)
    offset = round(start * MIX_RATE)
    available = min(rendered.size, output.size - offset)
    output[offset : offset + available] += rendered[:available] * gain


def render(root: Path, timbre: str) -> np.ndarray:
    cache = {
        anchor: load_mono(root / "assets" / "audio" / timbre / f"midi_{anchor}.wav")
        for anchor in ANCHORS
    }
    duration = 7.2
    output = np.zeros(round(duration * MIX_RATE), dtype=np.float64)
    for index, midi_note in enumerate(MELODY):
        anchor = nearest_anchor(midi_note)
        note = pitched(cache[anchor], midi_note - anchor)
        place_note(output, note, 0.25 + index * 0.38, 0.72, 0.74)
    chord_start = 4.85
    for midi_note in CHORD:
        anchor = nearest_anchor(midi_note)
        note = pitched(cache[anchor], midi_note - anchor)
        place_note(output, note, chord_start, 2.1, 0.22)
    # Preview-only monitor normalization makes the bank easy to audition. The
    # application keeps its more conservative per-voice mix gain.
    peak = float(np.max(np.abs(output)))
    output *= (10.0 ** (-3.0 / 20.0)) / max(peak, 1.0e-12)
    return output


def save(path: Path, samples: np.ndarray) -> None:
    pcm = np.clip(np.rint(samples * 32767.0), -32768, 32767).astype("<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(MIX_RATE)
        output.writeframes(pcm.tobytes())


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    output_directory = root / "build" / "audio-preview"
    for timbre in ("acoustic", "electric"):
        save(output_directory / f"{timbre}_demo.wav", render(root, timbre))


if __name__ == "__main__":
    main()
