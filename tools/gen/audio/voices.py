"""Animalese-style voice blips: voice_<profile>_<0..4>.wav, 60-120 ms each.
Five distinct pitches per profile so the typewriter babble has contour.
"""
import numpy as np
import synth as S

PROFILES = ["astro", "alien", "robot", "elder", "kid"]


def _formant(x, f1, f2, q=2.5, mix2=0.6):
    return S.bandpass(x, f1, q) * 1.0 + S.bandpass(x, f2, q) * mix2


def astro(i):
    """Soft rounded 'mm / ba' tones, mid pitch."""
    f0 = [215.0, 240.0, 262.0, 288.0, 318.0][i]
    n = S.n_samples([0.095, 0.085, 0.1, 0.09, 0.11][i])
    f = S.vibrato_freq(f0, n, 6.0, 12.0, onset=0.03, ramp=0.04) * S.glide_freq(0.97, 1.0, n, 0.03)
    src = S.saw(f, n) * 0.5 + S.sine(f, n) * 0.8 + 0.25 * S.sine(f * 2.0, n)
    vowel = [(650.0, 1100.0), (500.0, 900.0), (700.0, 1250.0), (450.0, 1000.0), (600.0, 1150.0)][i]
    y = _formant(src, vowel[0], vowel[1], q=2.0, mix2=0.5) * 2.2 + S.lowpass(src, 700.0) * 0.6
    y = S.lowpass(y, 3200.0)
    return y * S.adsr(n, 0.012, 0.02, 0.85, 0.03)


def alien(i):
    """Warbly high tones with pitch slides."""
    f0 = [620.0, 700.0, 780.0, 880.0, 960.0][i]
    n = S.n_samples([0.09, 0.075, 0.1, 0.085, 0.11][i])
    up = i % 2 == 0
    f = S.glide_freq(f0 * (0.82 if up else 1.22), f0, n, 0.06)
    f = f * S.vibrato_freq(1.0, n, 11.0, 45.0, onset=0.005, ramp=0.02)
    y = S.sine(f, n) + 0.35 * S.triangle(f * 2.0, n) + 0.15 * S.sine(f * 3.0, n)
    y = S.lowpass(y, 6000.0)
    return y * S.adsr(n, 0.006, 0.02, 0.8, 0.025)


def robot(i):
    """Square-wave two-tone bleeps with a light bitcrush."""
    pairs = [(330.0, 440.0), (392.0, 294.0), (494.0, 659.0), (262.0, 349.0), (587.0, 440.0)][i]
    n = S.n_samples([0.08, 0.07, 0.09, 0.075, 0.085][i])
    half = n // 2
    f = np.concatenate([np.full(half, pairs[0]), np.full(n - half, pairs[1])])
    y = S.pulse(f, n, 0.5) * 0.7 + 0.2 * S.pulse(f * 2.0, n, 0.25)
    y = S.bitcrush(y, 6, 9000.0)
    y = S.lowpass(y, 5500.0)
    return y * S.adsr(n, 0.004, 0.01, 0.9, 0.012)


def elder(i):
    """Low, slow, sine-ish 'hmm'."""
    f0 = [112.0, 124.0, 136.0, 150.0, 165.0][i]
    n = S.n_samples([0.115, 0.1, 0.12, 0.105, 0.11][i])
    f = S.vibrato_freq(f0, n, 4.5, 10.0, onset=0.03, ramp=0.05) * S.glide_freq(1.04, 1.0, n, 0.05)
    y = S.sine(f, n) + 0.45 * S.sine(f * 2.0, n) + 0.2 * S.triangle(f * 3.0, n)
    y = _formant(y, 380.0, 750.0, q=1.8, mix2=0.4) * 1.5 + S.lowpass(y, 500.0) * 0.8
    y = S.lowpass(y, 1800.0)
    return y * S.adsr(n, 0.025, 0.02, 0.9, 0.04)


def kid(i):
    """High fast chirps."""
    f0 = [880.0, 990.0, 1100.0, 1250.0, 1400.0][i]
    n = S.n_samples([0.065, 0.06, 0.07, 0.06, 0.068][i])
    f = S.glide_freq(f0 * 0.85, f0 * 1.06, n, 0.04)
    y = S.sine(f, n) + 0.3 * S.pulse(f, n, 0.3) + 0.15 * S.sine(f * 2.0, n)
    y = S.lowpass(y, 7000.0)
    return y * S.adsr(n, 0.004, 0.012, 0.85, 0.018)


GEN = {"astro": astro, "alien": alien, "robot": robot, "elder": elder, "kid": kid}


def render(profile, i):
    y = GEN[profile](i)
    y = S.fade_edges(y, 0.003, 0.004)
    y = S.remove_dc(y)
    return S.normalize(y, -3.0)


def all_names():
    return ["voice_%s_%d" % (p, i) for p in PROFILES for i in range(5)]
