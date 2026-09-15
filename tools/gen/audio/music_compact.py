#!/usr/bin/env python3
"""Mono, 33.075 kHz music masters: the same loops as music.py, at 3/8 of the samples.

WHY (2026-09-14). The user plays over mobile data. The 11 loops were 44.1 kHz stereo and made up
~11.3 MB of QOA inside index.pck (measured in a scratch --export-release Web). Every deploy changes
every ETag, so a phone re-downloads that on each update. Mono halves the samples; 33.075 kHz takes
another quarter off: 1/2 * 3/4 = 3/8 of the bytes.

WHY 33075 Hz AND NOT 32000. Every loop in music.py is a whole number of 5120-sample QOA frames at
44.1 kHz (loop_samples()), so every loop length (and the title take A's loop_begin, a multiple of
2560) is divisible by 4. 33075 = 44100 * 3/4, so each new loop length is EXACTLY 3/4 of the old one --
an integer, with no tempo nudge and no rounding at the seam. 32000 would need k * 5120 * 320/441 to be
an integer, which none of the eleven loops are (441 = 3^2 * 7^2 shares no factor with 5120). The new
Nyquist is 16537.5 Hz; every track's master already sits under finish(lp <= 14000) and measured -40 to
-88 dB of its energy above 16.5 kHz before this step.

HOW, AND WHY EACH STEP HAS NO FREE PARAMETER.
  1. Downmix M = (L + R) / 2. Anything centred passes at exactly unity (a constant-power centre pan puts
     s/sqrt2 in each channel, and Godot plays a mono stream at full level in both channels, so the ear
     gets the same power). Only decorrelated reverb/chorus/ping-pong width is lost.
  2. Resample the repeating region as a PERIODIC signal: one FFT over exactly one loop, keep every bin
     below the new Nyquist, inverse FFT at 3/4 the length. The bins are the same frequencies
     (k * 44100 / P == k * 33075 / (3P/4)), so the result is the band-limited loop itself, and the
     sample after the last one is the first one -- the seam is just another sample. A one-shot resampler
     would ring at both ends and click at the wrap.
  3. A one-shot intro before loop_begin (title take A only; the shipped "legacy" title has none) goes
     through a polyphase 3:4 resampler with the loop following it, so the hand-off is continuous.
  4. Peak-normalise to -1 dBFS: the same last step music.py's finish() already applies to every master
     and build_all.py's validate() checks (+/- 0.6 dB). No new or tuned gain.
  5. synth.write_wav(rate=33075): same smpl loop chunk, same 2-QOA-frame copy of the loop start after
     the loop end (the Godot QOA wrap fix), same TPDF dither.

    python3 tools/gen/audio/music_compact.py                 # render every track from music.py -> assets
    python3 tools/gen/audio/music_compact.py --only title,frost
    python3 tools/gen/audio/music_compact.py --out DIR       # write somewhere else (never assets/)

build_all.py --music still writes the old stereo 44.1 kHz files until it calls write_music() below
instead of S.write_wav() -- see the note at the bottom.
"""
import argparse
import os
import sys
from fractions import Fraction

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth as S  # noqa: E402

RATE = 33075                      # = S.SR * 3 / 4; see the module note
PEAK_DB = -1.0                    # music.py finish() / build_all.py validate() master peak
MUSIC_DIR = os.path.join(HERE, "..", "..", "..", "assets", "audio", "music")


def _ratio():
    r = Fraction(RATE, S.SR)
    return r.numerator, r.denominator


def _scaled(n: int) -> int:
    up, down = _ratio()
    if (n * up) % down:
        raise ValueError("%d samples at %d Hz is not a whole number of samples at %d Hz" % (n, S.SR, RATE))
    return n * up // down


def resample_periodic(x: np.ndarray, n_out: int) -> np.ndarray:
    """Band-limited resample of ONE period of a periodic signal to n_out samples (exact for the loop:
    the output is periodic in n_out). Bins at or above the output Nyquist are dropped."""
    n_in = len(x)
    X = np.fft.rfft(x)
    k = n_out // 2 + 1
    Y = np.zeros(k, dtype=complex)
    m = min(k, len(X))
    Y[:m] = X[:m]
    if n_out % 2 == 0:
        Y[n_out // 2] = 0.0       # the Nyquist bin is ambiguous at the new rate: drop it
    return np.fft.irfft(Y, n=n_out) * (n_out / float(n_in))


def compact(x: np.ndarray, loop_begin: int = 0):
    """x: a music.py master (stereo or mono float, length = loop end, no tail) at S.SR.
    Returns (mono float at RATE, loop_begin at RATE)."""
    m = S.to_mono(np.asarray(x, dtype=np.float64))
    n_new = _scaled(len(m))
    lb_new = _scaled(loop_begin)
    loop = resample_periodic(m[loop_begin:], n_new - lb_new)
    if loop_begin:
        from scipy.signal import resample_poly
        up, down = _ratio()
        seg = np.concatenate([m[:loop_begin], m[loop_begin:], m[loop_begin:]])
        intro = resample_poly(seg, up, down)[:lb_new]
        out = np.concatenate([intro, loop])
    else:
        out = loop
    return S.normalize(out, PEAK_DB), lb_new


def write_music(path: str, x: np.ndarray, loop_begin: int = 0) -> int:
    """Drop-in for S.write_wav(path, x, loop=True, loop_begin=loop_begin) on a music master."""
    y, lb = compact(x, loop_begin)
    return S.write_wav(path, y, loop=True, rate=RATE, loop_begin=lb)


def main():
    import music as M
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--out", default=MUSIC_DIR)
    args = ap.parse_args()
    only = set(filter(None, args.only.split(",")))
    for name, fn in M.TRACKS.items():
        if only and name not in only:
            continue
        x, L, bpm = fn()
        assert S.length(x) == L
        lb = M.TITLE_LOOP_BEGIN if name == "title" else 0
        y, lb_new = compact(x, lb)
        path = os.path.join(args.out, name + ".wav")
        size = S.write_wav(path, y, loop=True, rate=RATE, loop_begin=lb_new)
        seam = S.loop_seam_error(y, loop_begin=lb_new)
        print("%-13s %6.2f s  %d Hz mono  loop %d..%d  peak %6.2f dBFS  %7.1f KB  seam %.4f (p99.9 step %.4f)" % (
            name, len(y) / float(RATE), RATE, lb_new, len(y), S.to_db(S.peak(y)), size / 1024.0,
            seam["seam_jump"], seam["p999_step"]))


# build_all.py (not this file's owner) needs, in its == MUSIC == loop:
#     import music_compact as MC
#     size = MC.write_music(path, x, loop_begin=loop_begin)      # instead of S.write_wav(...)
# Its validate()/seam checks run on the 44.1 kHz master x and stay valid as they are.

if __name__ == "__main__":
    main()
