#!/usr/bin/env python3
"""Generates assets/audio/sfx/jetpack_loop.wav — the astronaut's jetpack thruster loop (R2.8).

    python3 tools/gen/audio/jetpack_loop.py

Kept as its own entry point rather than added to sfx.py's SFX table so the player builder could add
the one asset the jetpack needs without editing the audio builder's file. It follows the exact
conventions `sfx.py::rocket_loop` and `build_all.py::render` use, so folding it into the table later
is a copy-paste:

    "jetpack_loop": (jetpack_loop, False, True),

i.e. mono, loop=True, no trimming and no edge fades (a loop must stay exactly periodic), whole
QOA frames so Godot's loop wrap is click-free, and normalised to -3 dBFS.

The sound: a soft, tight, high hiss, deliberately NOT the rocket. Where rocket_loop is a low rumble
built on a 240 Hz lowpass with a 52 Hz sub, this is a 1.5 kHz bandpassed jet with a thin 2.8 kHz
airbrush on top, a gentle two-rate flutter and no sub at all — a backpack thruster, not an engine.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

import numpy as np  # noqa: E402
import synth as S  # noqa: E402


def jetpack_loop():
    """~1.5 s seamless thruster hiss. Rates are whole cycles per loop so the flutter is periodic."""
    L = 13 * S.QOA_FRAME
    n = L + S.n_samples(0.5)
    t = S.times(n)
    per = L / float(S.SR)
    body = S.bandpass(S.noise(n, 601), 1500.0, 0.8) * 1.0
    air = S.highpass(S.noise(n, 602), 2800.0) * 0.34
    warm = S.lowpass(S.noise(n, 603), 520.0, 0.7) * 0.42
    flutter = (1.0
               + 0.10 * np.sin(S.TWO_PI * (11.0 / per) * t)
               + 0.06 * np.sin(S.TWO_PI * (5.0 / per) * t))
    y = (body + air + warm) * flutter
    y = S.fold_loop(y, L)
    return S.soft_clip(y * 0.8, 0.7)


def main():
    out_dir = os.path.join(ROOT, "assets", "audio", "sfx")
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, "jetpack_loop.wav")
    y = S.to_mono(jetpack_loop())
    y = S.remove_dc(S.normalize(y, -3.0))
    S.write_wav(path, y, loop=True)
    print("wrote %s  %.3f s  peak %.2f dBFS  %d bytes"
          % (path, S.length(y) / float(S.SR), S.to_db(S.peak(y)), os.path.getsize(path)))


if __name__ == "__main__":
    main()
