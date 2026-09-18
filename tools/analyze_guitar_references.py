"""Measure supplied guitar references without third-party audio packages.

FFmpeg performs decoding. NumPy is used only for objective signal analysis;
the report deliberately does not claim that the references were auditioned.
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
from pathlib import Path

import numpy as np

TARGET_RATE = 44_100


def decode_mono(path: Path) -> np.ndarray:
    command = [
        "ffmpeg",
        "-v",
        "error",
        "-i",
        str(path),
        "-map",
        "0:a:0",
        "-ac",
        "1",
        "-ar",
        str(TARGET_RATE),
        "-f",
        "f32le",
        "-",
    ]
    decoded = subprocess.run(command, check=True, capture_output=True).stdout
    return np.frombuffer(decoded, dtype="<f4").astype(np.float64)


def db(value: float) -> float:
    return 20.0 * math.log10(max(value, 1.0e-12))


def spectral_metrics(frame: np.ndarray) -> dict[str, object]:
    windowed = frame * np.hanning(frame.size)
    spectrum = np.abs(np.fft.rfft(windowed))
    frequencies = np.fft.rfftfreq(frame.size, 1.0 / TARGET_RATE)
    usable = (frequencies >= 55.0) & (frequencies <= 8_000.0)
    magnitudes = spectrum[usable]
    bins = frequencies[usable]
    total = float(np.sum(magnitudes))
    centroid = float(np.sum(bins * magnitudes) / max(total, 1.0e-12))
    flatness = float(
        np.exp(np.mean(np.log(np.maximum(magnitudes, 1.0e-12))))
        / max(np.mean(magnitudes), 1.0e-12)
    )
    peak_indices = np.argpartition(magnitudes, -8)[-8:]
    ordered = peak_indices[np.argsort(magnitudes[peak_indices])[::-1]]
    peaks = [
        {"hz": round(float(bins[index]), 1), "relative_db": round(db(float(magnitudes[index]) / max(float(magnitudes[ordered[0]]), 1.0e-12)), 1)}
        for index in ordered
    ]
    return {
        "centroid_hz": round(centroid, 1),
        "flatness": round(flatness, 4),
        "strongest_bins": peaks,
    }


def analyze(path: Path) -> dict[str, object]:
    samples = decode_mono(path)
    frame_size = 2048
    hop = 256
    frame_count = max(1, 1 + (samples.size - frame_size) // hop)
    rms = np.empty(frame_count)
    flux = np.empty(frame_count)
    previous = np.zeros(frame_size // 2 + 1)
    for index in range(frame_count):
        offset = index * hop
        frame = samples[offset : offset + frame_size]
        spectrum = np.abs(np.fft.rfft(frame * np.hanning(frame_size)))
        rms[index] = math.sqrt(float(np.mean(frame * frame)))
        flux[index] = float(np.sum(np.maximum(spectrum - previous, 0.0)))
        previous = spectrum

    active = rms > max(float(np.max(rms)) * 0.025, 1.0e-5)
    threshold = float(np.median(flux[active]) + 3.0 * np.std(flux[active])) if np.any(active) else float("inf")
    candidates = np.flatnonzero((flux > threshold) & active)
    onsets: list[int] = []
    minimum_gap = round(0.12 * TARGET_RATE / hop)
    for candidate in candidates:
        if not onsets or candidate - onsets[-1] >= minimum_gap:
            onsets.append(int(candidate))
        elif flux[candidate] > flux[onsets[-1]]:
            onsets[-1] = int(candidate)

    onset_reports = []
    for index in onsets[:20]:
        offset = index * hop
        analysis_offset = min(max(0, offset + round(0.035 * TARGET_RATE)), max(0, samples.size - 8192))
        frame = samples[analysis_offset : analysis_offset + 8192]
        onset_reports.append(
            {
                "seconds": round(offset / TARGET_RATE, 3),
                "rms_dbfs": round(db(float(rms[index])), 1),
                **spectral_metrics(frame),
            }
        )

    peak = float(np.max(np.abs(samples)))
    return {
        "file": str(path),
        "duration_seconds": round(samples.size / TARGET_RATE, 3),
        "decoded_sample_rate": TARGET_RATE,
        "peak_dbfs": round(db(peak), 2),
        "rms_dbfs": round(db(math.sqrt(float(np.mean(samples * samples)))), 2),
        "samples_at_or_above_full_scale": int(np.count_nonzero(np.abs(samples) >= 1.0)),
        "detected_onsets": onset_reports,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="+", type=Path)
    args = parser.parse_args()
    print(json.dumps([analyze(path) for path in args.paths], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
