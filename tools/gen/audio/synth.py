"""Tiny numpy synth library for Astro Neighbor audio generation.

Conventions
-----------
* mono   = 1-D float64 array in roughly [-1, 1]
* stereo = 2-D float64 array shaped (2, n)  (row 0 = left, row 1 = right)
* All times are seconds unless a name ends in _samples / _beats.
* Frequencies may be scalars or per-sample arrays (for slides / vibrato).

No scipy: IIR filters are realised as truncated impulse responses convolved via FFT,
delay lines / combs / allpasses are processed block-wise (block = delay length) so the
Python loop count stays small even for 40 s stereo renders.
"""
import math
import struct
import numpy as np

SR = 44100
TWO_PI = 2.0 * math.pi

# --------------------------------------------------------------------------- basics

def n_samples(seconds: float) -> int:
    return int(round(seconds * SR))


def times(n: int) -> np.ndarray:
    return np.arange(n, dtype=np.float64) / SR


def db(gain_db: float) -> float:
    """dB -> linear gain."""
    return 10.0 ** (gain_db / 20.0)


def to_db(lin: float) -> float:
    return 20.0 * math.log10(max(abs(lin), 1e-12))


def is_stereo(x: np.ndarray) -> bool:
    return x.ndim == 2


def to_stereo(x: np.ndarray) -> np.ndarray:
    if is_stereo(x):
        return x
    return np.vstack([x, x])


def to_mono(x: np.ndarray) -> np.ndarray:
    if is_stereo(x):
        return 0.5 * (x[0] + x[1])
    return x


def length(x: np.ndarray) -> int:
    return x.shape[-1]


def pad_to(x: np.ndarray, n: int) -> np.ndarray:
    """Zero-pad (or truncate) mono/stereo to n samples."""
    cur = length(x)
    if cur == n:
        return x
    if cur > n:
        return x[..., :n]
    if is_stereo(x):
        return np.concatenate([x, np.zeros((2, n - cur))], axis=1)
    return np.concatenate([x, np.zeros(n - cur)])


def mix_into(dst: np.ndarray, src: np.ndarray, start: int, gain: float = 1.0) -> None:
    """Add src into dst (both mono or both stereo) at sample offset start, clipping to dst length."""
    n = length(dst)
    if start >= n:
        return
    if start < 0:
        src = src[..., -start:]
        start = 0
    m = min(length(src), n - start)
    if m <= 0:
        return
    if is_stereo(dst):
        dst[:, start:start + m] += gain * src[..., :m]
    else:
        dst[start:start + m] += gain * src[..., :m]


def fade_edges(x: np.ndarray, fade_in: float = 0.003, fade_out: float = 0.003) -> np.ndarray:
    """Apply short linear fades so nothing starts or ends with a click."""
    y = np.array(x, dtype=np.float64, copy=True)
    n = length(y)
    fi = min(n_samples(fade_in), n // 2)
    fo = min(n_samples(fade_out), n // 2)
    if fi > 0:
        y[..., :fi] *= np.linspace(0.0, 1.0, fi, endpoint=False)
    if fo > 0:
        y[..., n - fo:] *= np.linspace(1.0, 0.0, fo, endpoint=False)
    return y


def normalize(x: np.ndarray, peak_db: float = -3.0) -> np.ndarray:
    p = float(np.max(np.abs(x))) if length(x) else 0.0
    if p < 1e-9:
        return x
    return x * (db(peak_db) / p)


def remove_dc(x: np.ndarray) -> np.ndarray:
    if is_stereo(x):
        return x - x.mean(axis=1, keepdims=True)
    return x - x.mean()


def peak(x: np.ndarray) -> float:
    return float(np.max(np.abs(x))) if length(x) else 0.0


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(x * x))) if length(x) else 0.0

# --------------------------------------------------------------------------- notes

_NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def note_to_midi(name: str) -> int:
    """'C4' -> 60, 'F#3' -> 54, 'Bb5' -> 82."""
    s = name.strip()
    letter = s[0].upper()
    i = 1
    acc = 0
    while i < len(s) and s[i] in "#b":
        acc += 1 if s[i] == "#" else -1
        i += 1
    octave = int(s[i:])
    return 12 * (octave + 1) + _NOTE_INDEX[letter] + acc


def midi_to_freq(m: float) -> float:
    return 440.0 * 2.0 ** ((m - 69.0) / 12.0)


def nf(p) -> float:
    """Note -> frequency. Accepts 'A4', a midi number, or a frequency (float > 127)."""
    if isinstance(p, str):
        return midi_to_freq(note_to_midi(p))
    p = float(p)
    if p <= 127.0:
        return midi_to_freq(p)
    return p


def transpose(name: str, semitones: int) -> str:
    """Transpose a note name by semitones (sharps spelling)."""
    m = note_to_midi(name) + semitones
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return "%s%d" % (names[m % 12], m // 12 - 1)


CHORD_INTERVALS = {
    "": [0, 4, 7], "maj": [0, 4, 7], "m": [0, 3, 7], "min": [0, 3, 7],
    "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10],
    "6": [0, 4, 7, 9], "m6": [0, 3, 7, 9], "9": [0, 4, 7, 10, 14], "maj9": [0, 4, 7, 11, 14],
    "m9": [0, 3, 7, 10, 14], "sus4": [0, 5, 7], "7sus": [0, 5, 7, 10], "7sus4": [0, 5, 7, 10],
    "dim7": [0, 3, 6, 9], "m7b5": [0, 3, 6, 10], "add9": [0, 4, 7, 14], "6sus": [0, 5, 7, 9, 14],
    "maj7#11": [0, 4, 7, 11, 18], "5": [0, 7], "madd9": [0, 3, 7, 14], "69": [0, 4, 9, 14],
}


def chord_notes(root: str, quality: str, octave: int = 4) -> list:
    """chord_notes('F', 'maj7', 4) -> ['F4', 'A4', 'C5', 'E5'] (midi-based spelling)."""
    base = note_to_midi(root + str(octave))
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    out = []
    for iv in CHORD_INTERVALS[quality]:
        m = base + iv
        out.append("%s%d" % (names[m % 12], m // 12 - 1))
    return out


def parse_chord(sym: str):
    """'Bbm7' -> ('Bb', 'm7'); 'C/E' -> ('C', '', bass 'E'). Returns (root, quality, bass_or_None)."""
    bass = None
    if "/" in sym:
        sym, bass = sym.split("/")
    root = sym[0]
    i = 1
    while i < len(sym) and sym[i] in "#b":
        root += sym[i]
        i += 1
    quality = sym[i:]
    if quality not in CHORD_INTERVALS:
        raise ValueError("unknown chord quality %r in %r" % (quality, sym))
    return root, quality, bass

# --------------------------------------------------------------------------- oscillators

def _phase(freq, n: int, phase0: float = 0.0) -> np.ndarray:
    """Cycle phase in [0,1) for scalar or per-sample freq."""
    if np.isscalar(freq):
        inc = np.full(n, float(freq) / SR)
    else:
        inc = np.asarray(freq, dtype=np.float64)[:n] / SR
        if len(inc) < n:
            inc = np.concatenate([inc, np.full(n - len(inc), inc[-1] if len(inc) else 0.0)])
    ph = (phase0 + np.cumsum(inc) - inc) % 1.0
    return ph, inc


def sine(freq, n: int, phase0: float = 0.0) -> np.ndarray:
    ph, _ = _phase(freq, n, phase0)
    return np.sin(TWO_PI * ph)


def triangle(freq, n: int, phase0: float = 0.0) -> np.ndarray:
    ph, _ = _phase(freq, n, phase0)
    return 2.0 / math.pi * np.arcsin(np.sin(TWO_PI * ph))


def _poly_blep(t: np.ndarray, dt: np.ndarray) -> np.ndarray:
    out = np.zeros_like(t)
    m1 = t < dt
    if np.any(m1):
        tt = t[m1] / dt[m1]
        out[m1] = tt + tt - tt * tt - 1.0
    m2 = t > 1.0 - dt
    if np.any(m2):
        tt = (t[m2] - 1.0) / dt[m2]
        out[m2] = tt * tt + tt + tt + 1.0
    return out


def saw(freq, n: int, phase0: float = 0.0) -> np.ndarray:
    """Band-limited (polyBLEP) sawtooth."""
    ph, inc = _phase(freq, n, phase0)
    inc = np.maximum(inc, 1e-9)
    return 2.0 * ph - 1.0 - _poly_blep(ph, inc)


def pulse(freq, n: int, duty: float = 0.5, phase0: float = 0.0) -> np.ndarray:
    """Band-limited pulse wave with the given duty cycle (0.5 = square)."""
    ph, inc = _phase(freq, n, phase0)
    inc = np.maximum(inc, 1e-9)
    s1 = 2.0 * ph - 1.0 - _poly_blep(ph, inc)
    ph2 = (ph + duty) % 1.0
    s2 = 2.0 * ph2 - 1.0 - _poly_blep(ph2, inc)
    # s1 - s2 is already DC-free (values -2d / 2-2d); scale so the peak is 1.
    return (s1 - s2) / (2.0 * max(duty, 1.0 - duty))


def square(freq, n: int, phase0: float = 0.0) -> np.ndarray:
    return pulse(freq, n, 0.5, phase0)


def noise(n: int, seed: int = 0) -> np.ndarray:
    rng = np.random.default_rng(seed)
    return rng.uniform(-1.0, 1.0, n)


def pink_noise(n: int, seed: int = 0) -> np.ndarray:
    """1/f noise via spectral shaping."""
    w = noise(n, seed)
    spec = np.fft.rfft(w)
    f = np.fft.rfftfreq(n, 1.0 / SR)
    f[0] = f[1] if n > 1 else 1.0
    spec = spec / np.sqrt(f / 20.0)
    spec[0] = 0.0
    y = np.fft.irfft(spec, n)
    return y / (np.max(np.abs(y)) + 1e-12)


def lfo(rate_hz: float, n: int, phase0: float = 0.0, shape: str = "sine") -> np.ndarray:
    if shape == "tri":
        return triangle(rate_hz, n, phase0)
    return sine(rate_hz, n, phase0)


def vibrato_freq(freq: float, n: int, rate: float = 5.5, cents: float = 20.0,
                 onset: float = 0.15, ramp: float = 0.2, phase0: float = 0.0) -> np.ndarray:
    """Per-sample frequency array with vibrato fading in after `onset` seconds."""
    t = times(n)
    depth = np.clip((t - onset) / max(ramp, 1e-4), 0.0, 1.0)
    mod = lfo(rate, n, phase0) * depth * cents
    return freq * 2.0 ** (mod / 1200.0)


def glide_freq(f_from: float, f_to: float, n: int, glide_time: float = 0.1) -> np.ndarray:
    """Exponential pitch glide from f_from to f_to over glide_time seconds."""
    t = times(n)
    k = np.clip(t / max(glide_time, 1e-4), 0.0, 1.0)
    k = 1.0 - (1.0 - k) ** 2  # ease-out
    return f_from * (f_to / f_from) ** k

# --------------------------------------------------------------------------- envelopes

def adsr(n: int, a: float = 0.01, d: float = 0.1, s: float = 0.7, r: float = 0.2,
         attack_curve: float = 1.0, decay_curve: float = 2.0) -> np.ndarray:
    """ADSR over n samples; release occupies the LAST r seconds. Always ends at 0."""
    na, nd, nr = n_samples(a), n_samples(d), n_samples(r)
    if na + nd + nr > n:
        k = n / float(na + nd + nr + 1)
        na, nd, nr = int(na * k), int(nd * k), int(nr * k)
    ns = max(0, n - na - nd - nr)
    parts = []
    if na > 0:
        parts.append(np.linspace(0.0, 1.0, na, endpoint=False) ** attack_curve)
    if nd > 0:
        x = np.linspace(0.0, 1.0, nd, endpoint=False)
        parts.append(s + (1.0 - s) * (1.0 - x) ** decay_curve)
    if ns > 0:
        parts.append(np.full(ns, s))
    if nr > 0:
        x = np.linspace(0.0, 1.0, nr, endpoint=True)
        parts.append(s * (1.0 - x) ** 2)
    env = np.concatenate(parts) if parts else np.zeros(n)
    return pad_to(env, n)


def env_perc(n: int, decay: float = 0.3, attack: float = 0.002, curve: float = 1.0,
             end_fade: float = 0.01) -> np.ndarray:
    """Percussive envelope: fast attack, exponential decay (time constant `decay`), forced to 0 at the end."""
    t = times(n)
    env = np.exp(-t / max(decay, 1e-4)) ** curve
    na = n_samples(attack)
    if na > 0 and na < n:
        env[:na] *= np.linspace(0.0, 1.0, na, endpoint=False)
    nf_ = min(n_samples(end_fade), n)
    if nf_ > 0:
        env[n - nf_:] *= np.linspace(1.0, 0.0, nf_, endpoint=True)
    return env


def env_line(n: int, points) -> np.ndarray:
    """Piecewise-linear envelope from [(time_sec, value), ...]."""
    t = times(n)
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return np.interp(t, xs, ys)

# --------------------------------------------------------------------------- filters (FIR-approximated IIR)

_IR_CACHE = {}


def _rbj(kind: str, fc: float, q: float, gain_db: float = 0.0):
    fc = min(max(fc, 5.0), SR * 0.49)
    w0 = TWO_PI * fc / SR
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2.0 * q)
    A = 10.0 ** (gain_db / 40.0)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
        a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
        a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    elif kind == "bp":
        b0, b1, b2 = alpha, 0.0, -alpha
        a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    elif kind == "notch":
        b0, b1, b2 = 1.0, -2 * cw, 1.0
        a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    elif kind == "peak":
        b0, b1, b2 = 1 + alpha * A, -2 * cw, 1 - alpha * A
        a0, a1, a2 = 1 + alpha / A, -2 * cw, 1 - alpha / A
    elif kind == "lowshelf":
        sa = 2 * math.sqrt(A) * alpha
        b0 = A * ((A + 1) - (A - 1) * cw + sa)
        b1 = 2 * A * ((A - 1) - (A + 1) * cw)
        b2 = A * ((A + 1) - (A - 1) * cw - sa)
        a0 = (A + 1) + (A - 1) * cw + sa
        a1 = -2 * ((A - 1) + (A + 1) * cw)
        a2 = (A + 1) + (A - 1) * cw - sa
    elif kind == "highshelf":
        sa = 2 * math.sqrt(A) * alpha
        b0 = A * ((A + 1) + (A - 1) * cw + sa)
        b1 = -2 * A * ((A - 1) + (A + 1) * cw)
        b2 = A * ((A + 1) + (A - 1) * cw - sa)
        a0 = (A + 1) - (A - 1) * cw + sa
        a1 = 2 * ((A - 1) - (A + 1) * cw)
        a2 = (A + 1) - (A - 1) * cw - sa
    else:
        raise ValueError(kind)
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def _biquad_ir(coeffs, n: int) -> np.ndarray:
    b0, b1, b2, a1, a2 = coeffs
    h = np.zeros(n)
    x1 = x2 = 0.0
    y1 = y2 = 0.0
    for i in range(n):
        x0 = 1.0 if i == 0 else 0.0
        y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        h[i] = y0
        x2, x1 = x1, x0
        y2, y1 = y1, y0
        if i > 64 and abs(y0) < 1e-7 and abs(y1) < 1e-7:
            return h[:i + 1]
    return h


def _biquad_ir_cached(kind: str, fc: float, q: float, gain_db: float) -> np.ndarray:
    key = (kind, round(fc, 2), round(q, 3), round(gain_db, 2))
    h = _IR_CACHE.get(key)
    if h is None:
        coeffs = _rbj(kind, fc, q, gain_db)
        # long enough for low cutoffs / high Q: ring time ~ Q / fc
        n = int(min(1 << 17, max(512, 12.0 * SR * max(q, 0.5) / max(fc, 5.0))))
        h = _biquad_ir(coeffs, n)
        _IR_CACHE[key] = h
    return h


def fftconvolve(x: np.ndarray, h: np.ndarray, keep: str = "same") -> np.ndarray:
    """Linear convolution via FFT. keep='same' -> len(x) samples (causal, no delay compensation);
    keep='full' -> len(x)+len(h)-1."""
    n = len(x) + len(h) - 1
    size = 1 << (n - 1).bit_length()
    X = np.fft.rfft(x, size)
    H = np.fft.rfft(h, size)
    y = np.fft.irfft(X * H, size)[:n]
    if keep == "same":
        return y[:len(x)]
    return y


def _per_channel(fn, x: np.ndarray, *args, **kw) -> np.ndarray:
    if is_stereo(x):
        return np.vstack([fn(x[0], *args, **kw), fn(x[1], *args, **kw)])
    return fn(x, *args, **kw)


def biquad(x: np.ndarray, kind: str, fc: float, q: float = 0.7071, gain_db: float = 0.0) -> np.ndarray:
    h = _biquad_ir_cached(kind, fc, q, gain_db)
    return _per_channel(lambda m: fftconvolve(m, h), x)


def lowpass(x, fc, q=0.7071):
    return biquad(x, "lp", fc, q)


def highpass(x, fc, q=0.7071):
    return biquad(x, "hp", fc, q)


def bandpass(x, fc, q=1.0):
    return biquad(x, "bp", fc, q)


def peak_eq(x, fc, gain_db, q=1.0):
    return biquad(x, "peak", fc, q, gain_db)


def lowshelf(x, fc, gain_db, q=0.7071):
    return biquad(x, "lowshelf", fc, q, gain_db)


def highshelf(x, fc, gain_db, q=0.7071):
    return biquad(x, "highshelf", fc, q, gain_db)


def lowpass4(x, fc, q=0.7071):
    """Two cascaded biquads (24 dB/oct)."""
    return lowpass(lowpass(x, fc, q), fc, q)


def onepole_lp(x: np.ndarray, fc: float) -> np.ndarray:
    a = math.exp(-TWO_PI * fc / SR)
    n = int(min(65536, max(16, math.log(1e-5) / math.log(max(a, 1e-9)))))
    h = (1.0 - a) * a ** np.arange(n)
    return _per_channel(lambda m: fftconvolve(m, h), x)


def sweep_lowpass(x: np.ndarray, fc_start: float, fc_end: float, tau: float, q: float = 0.8,
                  stages: int = 5) -> np.ndarray:
    """Filter-envelope emulation: crossfade between a few static lowpasses as cutoff decays
    exponentially from fc_start to fc_end with time constant tau."""
    n = length(x)
    t = times(n)
    k = np.exp(-t / max(tau, 1e-4))
    fcs = [fc_end * (fc_start / fc_end) ** (i / (stages - 1.0)) for i in range(stages)]  # ascending
    logf = np.log(fc_end * (fc_start / fc_end) ** k)
    logs = np.log(np.array(fcs))
    out = np.zeros_like(x)
    # weights: linear interpolation in log-frequency between adjacent stages
    for i, fc in enumerate(fcs):
        if i == 0:
            w = np.clip(1.0 - (logf - logs[0]) / (logs[1] - logs[0]), 0.0, 1.0)
        elif i == stages - 1:
            w = np.clip((logf - logs[i - 1]) / (logs[i] - logs[i - 1]), 0.0, 1.0)
        else:
            w = np.clip(np.minimum((logf - logs[i - 1]) / (logs[i] - logs[i - 1]),
                                   (logs[i + 1] - logf) / (logs[i + 1] - logs[i])), 0.0, 1.0)
        if np.max(w) <= 0.0:
            continue
        out += lowpass(x, fc, q) * w
    return out

# --------------------------------------------------------------------------- delay / reverb / chorus

def _onepole_block_conv(damp_coeff: float):
    """Impulse response of y[n] = (1-a) x[n] + a y[n-1]."""
    a = damp_coeff
    J = int(min(512, max(8, math.log(1e-5) / math.log(max(a, 1e-9))))) if a > 0.0 else 1
    return (1.0 - a) * a ** np.arange(J)


def _comb(x: np.ndarray, D: int, fb: float, damp: float) -> np.ndarray:
    """Feedback comb with damping lowpass inside the loop (Freeverb style), block processed."""
    n = len(x)
    y = np.zeros(n)
    h = _onepole_block_conv(damp)
    J = len(h)
    carry = np.zeros(J - 1)
    for start in range(0, n, D):
        end = min(start + D, n)
        blen = end - start
        if start >= D:
            delayed = y[start - D:end - D]
        else:
            delayed = np.zeros(blen)
        if J > 1:
            f = np.convolve(delayed, h)
            f[:J - 1] += carry
            carry = f[blen:blen + J - 1]
            if len(carry) < J - 1:
                carry = np.concatenate([carry, np.zeros(J - 1 - len(carry))])
            f = f[:blen]
        else:
            f = delayed
        y[start:end] = x[start:end] + fb * f
    return y


def _allpass(x: np.ndarray, D: int, g: float = 0.5) -> np.ndarray:
    n = len(x)
    y = np.zeros(n)
    for start in range(0, n, D):
        end = min(start + D, n)
        if start >= D:
            xd = x[start - D:end - D]
            yd = y[start - D:end - D]
        else:
            xd = np.zeros(end - start)
            yd = xd
        y[start:end] = -g * x[start:end] + xd + g * yd
    return y


_COMBS = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
_ALLPASSES = [556, 441, 341, 225]


def reverb(x: np.ndarray, room: float = 0.75, damp: float = 0.4, wet: float = 0.2, dry: float = 1.0,
           width: float = 0.9, predelay: float = 0.008, tone: float = 7000.0, lowcut: float = 150.0,
           size_scale: float = 1.0) -> np.ndarray:
    """Warm plate-ish Schroeder/Freeverb reverb: 8 damped feedback combs + 4 series allpasses per channel.
    Returns stereo."""
    xs = to_stereo(x)
    n = xs.shape[1]
    inp = 0.5 * (xs[0] + xs[1])
    pd = n_samples(predelay)
    if pd > 0:
        inp = np.concatenate([np.zeros(pd), inp[:n - pd]])
    inp = highpass(inp, lowcut)
    fb = room * 0.28 + 0.7
    dmp = damp * 0.4
    outs = []
    for ch, spread in ((0, 0), (1, 23)):
        acc = np.zeros(n)
        for D in _COMBS:
            acc += _comb(inp, int(D * size_scale) + spread, fb, dmp)
        acc *= 0.015
        for D in _ALLPASSES:
            acc = _allpass(acc, int(D * size_scale) + spread, 0.5)
        outs.append(acc)
    wetL, wetR = outs
    w1 = 0.5 * width + 0.5
    w2 = 0.5 * (1.0 - width)
    L = wetL * w1 + wetR * w2
    R = wetR * w1 + wetL * w2
    w = np.vstack([L, R])
    w = onepole_lp(w, tone)
    return dry * xs + wet * w


def delay(x: np.ndarray, time: float, feedback: float = 0.35, mix: float = 0.25, damp_fc: float = 4000.0,
          pingpong: bool = False, spread: float = 0.0) -> np.ndarray:
    """Feedback delay with damping in the loop. Returns stereo. spread offsets the right channel time (sec)."""
    xs = to_stereo(x)
    n = xs.shape[1]
    a = math.exp(-TWO_PI * damp_fc / SR)
    h = _onepole_block_conv(a)
    J = len(h)
    DL = max(1, n_samples(time))
    DR = max(1, n_samples(time + spread))
    D = min(DL, DR)
    yl = np.zeros(n)
    yr = np.zeros(n)
    carry_l = np.zeros(J - 1)
    carry_r = np.zeros(J - 1)

    def filt(sig, carry):
        f = np.convolve(sig, h)
        f[:J - 1] += carry
        blen = len(sig)
        c = f[blen:blen + J - 1]
        if len(c) < J - 1:
            c = np.concatenate([c, np.zeros(J - 1 - len(c))])
        return f[:blen], c

    for start in range(0, n, D):
        end = min(start + D, n)
        blen = end - start
        dl = yl[start - DL:end - DL] if start >= DL else np.zeros(blen)
        dr = yr[start - DR:end - DR] if start >= DR else np.zeros(blen)
        if len(dl) < blen:
            dl = np.concatenate([np.zeros(blen - len(dl)), dl])
        if len(dr) < blen:
            dr = np.concatenate([np.zeros(blen - len(dr)), dr])
        fl, carry_l = filt(dl, carry_l)
        fr, carry_r = filt(dr, carry_r)
        if pingpong:
            yl[start:end] = xs[0, start:end] + feedback * fr
            yr[start:end] = xs[1, start:end] + feedback * fl
        else:
            yl[start:end] = xs[0, start:end] + feedback * fl
            yr[start:end] = xs[1, start:end] + feedback * fr
    wet = np.vstack([yl, yr]) - xs
    return xs + mix * wet


def chorus(x: np.ndarray, rate: float = 0.8, depth_ms: float = 2.5, base_ms: float = 14.0, mix: float = 0.4,
           loop_len: int = 0) -> np.ndarray:
    """Stereo chorus (modulated delay, quadrature LFO per channel). If loop_len is given the LFO rate is
    snapped so the modulation is periodic over the loop."""
    xs = to_stereo(x)
    n = xs.shape[1]
    if loop_len > 0:
        cycles = max(1, round(rate * loop_len / SR))
        rate = cycles * SR / float(loop_len)
    t = times(n)
    idx = np.arange(n, dtype=np.float64)
    out = np.zeros_like(xs)
    for ch in range(2):
        ph = 0.0 if ch == 0 else 0.25
        d = (base_ms + depth_ms * np.sin(TWO_PI * (rate * t + ph))) * SR / 1000.0
        src = np.clip(idx - d, 0.0, n - 1.0)
        wet = np.interp(src, idx, xs[ch])
        out[ch] = xs[ch] * (1.0 - mix) + wet * mix
    return out


def tremolo(x: np.ndarray, rate: float = 5.0, depth: float = 0.3, phase0: float = 0.0) -> np.ndarray:
    n = length(x)
    m = 1.0 - depth * 0.5 * (1.0 + np.sin(TWO_PI * rate * times(n) + phase0))
    return x * m


def soft_clip(x: np.ndarray, knee: float = 0.7) -> np.ndarray:
    """Transparent below `knee`, tanh-rounded above; never exceeds 1.0."""
    ax = np.abs(x)
    over = ax > knee
    y = np.array(x, copy=True)
    y[over] = np.sign(x[over]) * (knee + (1.0 - knee) * np.tanh((ax[over] - knee) / (1.0 - knee)))
    return y


def bitcrush(x: np.ndarray, bits: int = 8, rate: float = 11025.0) -> np.ndarray:
    """Sample-and-hold + quantise, for robot voices / chip drums."""
    n = length(x)
    step = SR / rate
    idx = (np.floor(np.arange(n) / step) * step).astype(int)
    idx = np.clip(idx, 0, n - 1)
    y = x[..., idx]
    q = 2.0 ** (bits - 1)
    return np.round(y * q) / q


def pan(x: np.ndarray, p: float = 0.0) -> np.ndarray:
    """Constant-power pan of a mono signal: p in [-1 (left), +1 (right)]. Returns stereo."""
    if is_stereo(x):
        return x
    a = (p + 1.0) * math.pi / 4.0
    return np.vstack([x * math.cos(a), x * math.sin(a)])


def widen(x: np.ndarray, amount: float = 0.3, delay_ms: float = 12.0) -> np.ndarray:
    """Haas-style stereo widening for a mono source."""
    xs = to_stereo(x)
    d = n_samples(delay_ms / 1000.0)
    r = np.concatenate([np.zeros(d), xs[1][:-d]]) if d > 0 else xs[1]
    return np.vstack([xs[0], xs[1] * (1.0 - amount) + r * amount])

# --------------------------------------------------------------------------- sequencer

def parse_seq(text: str, default_dur: float = 1.0, default_vel: float = 0.9, start_beat: float = 0.0):
    """Mini notation -> list of (beat, dur_beats, pitch, vel).

    Tokens separated by whitespace; '|' is ignored (bar lines for readability).
      C5:0.5      note, half a beat
      r:1         rest
      [C4,E4]:2   chord
      G5:1@0.6    velocity 0.6
      x           any non-note pitch string is passed through unchanged (drum names like kick, hat)
    """
    out = []
    beat = start_beat
    for tok in text.replace("|", " ").split():
        vel = default_vel
        if "@" in tok:
            tok, v = tok.split("@")
            vel = float(v)
        if ":" in tok:
            p, d = tok.split(":")
            dur = float(d)
        else:
            p, dur = tok, default_dur
        if p in ("r", "-"):
            beat += dur
            continue
        pitches = p[1:-1].split(",") if p.startswith("[") else [p]
        for pp in pitches:
            out.append((beat, dur, pp, vel))
        beat += dur
    return out


def seq_length_beats(notes) -> float:
    return max((b + d for b, d, _, _ in notes), default=0.0)


def shift(notes, beats: float):
    return [(b + beats, d, p, v) for b, d, p, v in notes]


def scale_vel(notes, k: float):
    return [(b, d, p, v * k) for b, d, p, v in notes]


def transpose_notes(notes, semitones: int):
    out = []
    for b, d, p, v in notes:
        if isinstance(p, str):
            try:
                p = transpose(p, semitones)
            except (ValueError, KeyError, IndexError):
                pass
        out.append((b, d, p, v))
    return out


def render_notes(notes, inst, bpm: float, n_total: int, swing: float = 0.0, swing_grid: float = 0.5,
                 gain: float = 1.0, pan_pos: float = 0.0, pan_by_pitch: float = 0.0,
                 humanize_ms: float = 0.0, humanize_vel: float = 0.0, seed: int = 1,
                 note_fade: float = 0.002, cache: bool = True) -> np.ndarray:
    """Render a note list with an instrument into a stereo buffer of n_total samples.

    inst(pitch, dur_sec, vel) -> mono or stereo array. pitch is a frequency for note names / numbers,
    or the raw string for drum-like instruments. Instruments with attribute `legato = True` also
    receive prev_freq= (frequency of the previous note, or None).
    swing delays every off-beat `swing_grid` subdivision by swing * swing_grid beats.
    """
    out = np.zeros((2, n_total))
    spb = 60.0 / bpm  # seconds per beat
    rng = np.random.default_rng(seed)
    legato = getattr(inst, "legato", False)
    prev_freq = None
    memo = {}
    for beat, dur, pitch, vel in sorted(notes, key=lambda x: x[0]):
        b = beat
        if swing > 0.0:
            pos = (b / swing_grid) % 2.0
            if abs(pos - 1.0) < 1e-6:
                b += swing * swing_grid
        t0 = b * spb
        if humanize_ms > 0.0:
            t0 += rng.normal(0.0, humanize_ms / 1000.0)
        v = vel * (1.0 + rng.normal(0.0, humanize_vel)) if humanize_vel > 0.0 else vel
        v = float(np.clip(v, 0.05, 1.2))
        if isinstance(pitch, str):
            try:
                f = nf(pitch)
            except (ValueError, KeyError, IndexError):
                f = pitch
        else:
            f = nf(pitch)
        dur_sec = dur * spb
        key = (f if not isinstance(f, str) else f, round(dur_sec, 4), round(v, 3), prev_freq if legato else None)
        sig = memo.get(key) if cache else None
        if sig is None:
            if legato:
                sig = inst(f, dur_sec, v, prev_freq=prev_freq)
            else:
                sig = inst(f, dur_sec, v)
            sig = fade_edges(sig, note_fade, note_fade)
            if cache:
                memo[key] = sig
        if not isinstance(f, str):
            prev_freq = f
        p = pan_pos
        if pan_by_pitch != 0.0 and not isinstance(f, str):
            p += pan_by_pitch * (math.log2(f / 440.0))
        p = max(-1.0, min(1.0, p))
        st = pan(sig, p) if not is_stereo(sig) else sig
        mix_into(out, st, int(round(t0 * SR)), gain)
    return out


def fold_loop(buf: np.ndarray, loop_len: int) -> np.ndarray:
    """Seamless-loop fold: every period of the (loop + tail) buffer is summed onto the first one,
    so reverb/delay/release tails that spill past the loop point wrap around to its start."""
    out = np.array(buf[..., :loop_len], copy=True)
    pos = loop_len
    while pos < length(buf):
        chunk = buf[..., pos:pos + loop_len]
        out[..., :length(chunk)] += chunk
        pos += loop_len
    return out


def fold_loop_at(buf: np.ndarray, loop_begin: int, loop_end: int) -> np.ndarray:
    """Like fold_loop, but for a track with a one-shot intro before the repeating region: samples
    [0:loop_begin] (the intro, e.g. a logo) are kept exactly as rendered, and everything from
    loop_end onward (reverb/delay tails spilling past the loop, at period loop_end - loop_begin) is
    summed back into [loop_begin:loop_end] so THAT region loops seamlessly on its own. Returns a
    buffer of length loop_end (same convention as fold_loop returning length loop_len)."""
    period = loop_end - loop_begin
    out = np.array(buf[..., :loop_end], copy=True)
    pos = loop_end
    while pos < length(buf):
        chunk = buf[..., pos:pos + period]
        n = length(chunk)
        out[..., loop_begin:loop_begin + n] += chunk
        pos += period
    return out


def loop_seam_error(x: np.ndarray, window: int = 2048, loop_begin: int = 0) -> dict:
    """Numeric loop check: compares the jump across the seam (last sample -> first sample of the
    REPEATING region, i.e. x[loop_begin]) with the typical sample-to-sample step of the signal, and
    the RMS of the head/tail windows either side of the seam. `loop_begin` > 0 for a track with a
    one-shot intro before the loop (see fold_loop_at) -- 0 checks the seam fold_loop is meant to fix."""
    m = to_mono(x)
    seam = abs(float(m[loop_begin] - m[-1]))
    steps = np.abs(np.diff(m))
    typical = float(np.percentile(steps, 99.9)) if len(steps) else 0.0
    head = rms(m[loop_begin:loop_begin + window])
    tail = rms(m[-window:])
    return {"seam_jump": seam, "p999_step": typical, "ratio": seam / (typical + 1e-12),
            "head_rms": head, "tail_rms": tail}

# --------------------------------------------------------------------------- analysis helpers

def spectral_centroid(x: np.ndarray) -> float:
    m = to_mono(x)
    if len(m) < 16:
        return 0.0
    w = np.hanning(len(m))
    spec = np.abs(np.fft.rfft(m * w))
    f = np.fft.rfftfreq(len(m), 1.0 / SR)
    s = spec.sum()
    return float((spec * f).sum() / s) if s > 0 else 0.0

# --------------------------------------------------------------------------- WAV I/O

QOA_FRAME = 5120          # samples per QOA frame (Godot 4.7 imports WAV as QOA by default)
LOOP_TAIL = 2 * QOA_FRAME  # extra samples written after a loop's end (a copy of its start)


def write_wav(path: str, x: np.ndarray, loop: bool = False, dither: bool = True, seed: int = 7,
              loop_tail: int = LOOP_TAIL, rate: int = SR, loop_begin: int = 0) -> int:
    """Write 16-bit PCM WAV (mono or stereo). loop=True adds an 'smpl' chunk (loop `loop_begin`..len(x))
    which Godot's WAV importer detects automatically, and appends `loop_tail` samples copied from
    `loop_begin` after the loop end: Godot's QOA playback substitutes the sample AT loop_end for the
    first sample after a wrap, so that sample must equal x[loop_begin] for the loop to be click-free.
    `loop_begin` defaults to 0 (loop the whole buffer, the old behaviour); pass > 0 for an intro that
    plays once before the loop starts (e.g. a logo before a bed) -- Godot plays 0..loop_end once, then
    repeats loop_begin..loop_end. `rate` only changes the header (default SR = the old behaviour, byte
    for byte); the comms voices pass COMMS_RATE because they are band-limited to 3.4 kHz and 44.1 kHz
    would double their size. Returns bytes written."""
    x = np.asarray(x, dtype=np.float64)
    loop_len = length(x)
    if loop and loop_tail > 0:
        x = np.concatenate([x, x[..., loop_begin:loop_begin + loop_tail]], axis=-1)
    if is_stereo(x):
        channels = 2
        inter = np.empty(x.shape[1] * 2)
        inter[0::2] = x[0]
        inter[1::2] = x[1]
        frames = x.shape[1]
    else:
        channels = 1
        inter = x
        frames = len(x)
    if dither and frames > 0:
        rng = np.random.default_rng(seed)
        inter = inter + (rng.uniform(-0.5, 0.5, len(inter)) + rng.uniform(-0.5, 0.5, len(inter))) / 32768.0
    pcm = np.clip(np.round(inter * 32767.0), -32768, 32767).astype("<i2")
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, channels, rate, rate * channels * 2, channels * 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(data)) + data
    if loop:
        # smpl chunk: manufacturer, product, sample period (ns), midi unity note, pitch fraction,
        # smpte format, smpte offset, num loops, sampler data, then one loop record.
        smpl = struct.pack("<IIIIIIIII", 0, 0, int(1e9 / rate), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<IIIIII", 0, 0, loop_begin, loop_len, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    riff = b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks
    with open(path, "wb") as f:
        f.write(riff)
    return len(riff)


def read_wav(path: str):
    """Minimal 16-bit PCM WAV reader -> (array mono/stereo float, sample_rate, loop_end or None)."""
    with open(path, "rb") as f:
        raw = f.read()
    assert raw[:4] == b"RIFF" and raw[8:12] == b"WAVE"
    pos = 12
    channels, rate, bits = 1, SR, 16
    data = b""
    has_loop = None
    while pos + 8 <= len(raw):
        cid = raw[pos:pos + 4]
        size = struct.unpack("<I", raw[pos + 4:pos + 8])[0]
        body = raw[pos + 8:pos + 8 + size]
        if cid == b"fmt ":
            _, channels, rate, _, _, bits = struct.unpack("<HHIIHH", body[:16])
        elif cid == b"data":
            data = body
        elif cid == b"smpl":
            has_loop = struct.unpack("<I", body[48:52])[0]
        pos += 8 + size + (size & 1)
    assert bits == 16
    pcm = np.frombuffer(data, dtype="<i2").astype(np.float64) / 32768.0
    if channels == 2:
        return np.vstack([pcm[0::2], pcm[1::2]]), rate, has_loop
    return pcm, rate, has_loop

# --------------------------------------------------------------------------- comms (the shared voice channel)
# Added for the COMMS voices (tools/gen/audio/voices.py). Every neighbour is a radio transmission, and
# ONE channel defined here is what makes ten very different timbres sound like one universe. Nothing
# above this line calls into this section, so no other generator's output changes.

COMMS_RATE = 22050        # half of SR: the channel stops at 3.4 kHz, so 22.05 kHz loses nothing and halves the bytes
COMMS_LO = 300.0          # the classic voice channel is 300-3400 Hz (telephone / two-way radio)
COMMS_HI = 3400.0


def svf_tv(x: np.ndarray, fc, q: float = 4.0, mode: str = "bp") -> np.ndarray:
    """Time-varying TPT (Zavalishin) state-variable filter, mono. `fc` is a scalar or per-sample array.
    mode 'bp' is unity-gain at fc, 'lp' / 'hp' are the usual 12 dB/oct outputs. The TPT form stays stable
    while fc moves every sample, which the FIR-approximated biquads above cannot do - it is what lets a
    formant GLIDE (Mayor Orbit, Stella) instead of stepping between static filters."""
    n = len(x)
    fcs = np.full(n, float(fc)) if np.isscalar(fc) else np.asarray(fc, dtype=np.float64)[:n]
    g = np.tan(math.pi * np.clip(fcs, 5.0, SR * 0.45) / SR)
    k = 1.0 / max(q, 0.05)
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    out = np.zeros(n)
    ic1 = ic2 = 0.0
    xs = np.asarray(x, dtype=np.float64)
    for i in range(n):
        v3 = xs[i] - ic2
        v1 = a1[i] * ic1 + a2[i] * v3
        v2 = ic2 + a2[i] * ic1 + a3[i] * v3
        ic1 = 2.0 * v1 - ic1
        ic2 = 2.0 * v2 - ic2
        if mode == "bp":
            out[i] = k * v1
        elif mode == "lp":
            out[i] = v2
        else:
            out[i] = xs[i] - k * v1 - v2
    return out


def comms_chain(x: np.ndarray, drive: float = 1.7, presence_db: float = 1.5, presence_fc: float = 1300.0,
                lo: float = COMMS_LO, hi: float = COMMS_HI) -> np.ndarray:
    """THE shared radio channel every comms sound goes through (voices, key-up, squelch, static bed).
      1. 24 dB/oct high-pass at 300 Hz and 24 dB/oct low-pass at 3.4 kHz - the voice channel.
      2. +1.5 dB presence bump at 1.3 kHz (Q 0.8): the mid-range 'radio' colour. Kept small because a
         big 1-3 kHz peak is exactly what makes a long conversation tiring.
      3. Light tanh saturation on a peak-normalised signal, so every voice gets the SAME amount of grit
         whatever its level (drive 1.7 = about 6 % THD on a full-scale sine).
      4. Band-limit again (low-pass 3.9 kHz, high-pass 240 Hz) to remove the harmonics step 3 made, so the
         saturation adds warmth inside the channel and never adds hiss above it.
    Mono in, mono out, at SR. Output peak is 1.0 before any later normalisation."""
    y = highpass(highpass(x, lo), lo)
    y = lowpass4(y, hi)
    if presence_db != 0.0:
        y = peak_eq(y, presence_fc, presence_db, 0.8)
    p = peak(y)
    if p > 1e-9:
        y = y / p
    if drive > 0.0:
        y = np.tanh(drive * y) / math.tanh(drive)
    y = lowpass(y, hi * 1.15)
    y = highpass(y, lo * 0.8)
    return y


def _fft_taper(n_bins: int, rate: float, f_pass: float, f_stop: float, n_fft: int) -> np.ndarray:
    f = np.fft.rfftfreq(n_fft, 1.0 / rate)[:n_bins]
    w = np.ones(n_bins)
    band = (f > f_pass) & (f < f_stop)
    w[band] = 0.5 * (1.0 + np.cos(math.pi * (f[band] - f_pass) / (f_stop - f_pass)))
    w[f >= f_stop] = 0.0
    return w


def resample_half(x: np.ndarray) -> np.ndarray:
    """SR (44.1 kHz) -> COMMS_RATE (22.05 kHz), mono. FFT low-pass (raised-cosine 9.5-10.5 kHz) then drop
    every other sample. Zero-padded so the circular FFT cannot wrap a tail onto the head."""
    n = len(x)
    size = 1 << (n + 4096 - 1).bit_length()
    X = np.fft.rfft(x, size)
    X *= _fft_taper(len(X), SR, 9500.0, 10500.0, size)
    y = np.fft.irfft(X, size)[:n]
    return y[::2].copy()


def upsample_double(x: np.ndarray) -> np.ndarray:
    """COMMS_RATE -> SR, mono, by FFT zero-stuffing (exact for band-limited content). Analysis only:
    it lets the SR-only biquads above (K-weighting, band splits) measure a 22.05 kHz file."""
    n = len(x)
    X = np.fft.rfft(x)
    Y = np.zeros(n + 1, dtype=complex)   # rfft length of a 2n-sample signal
    Y[:len(X)] = X
    return np.fft.irfft(Y, 2 * n) * 2.0


def loudness_k(x: np.ndarray) -> float:
    """Ungated ITU-R BS.1770 style loudness (K-weighted mean square, 'LUFS'), mono or stereo at SR.
    The K pre-filter is rebuilt from its analogue prototype with the RBJ shelf/high-pass above
    (+4 dB shelf at 1682 Hz, Q 0.707; high-pass 38 Hz, Q 0.5). No gating: this is for comparing short
    sounds with each other, not for broadcast compliance."""
    m = to_mono(x)
    if len(m) < 16:
        return -120.0
    y = highshelf(m, 1681.97, 4.0, 0.7072)
    y = highpass(y, 38.13, 0.5003)
    ms = float(np.mean(y * y))
    return -0.691 + 10.0 * math.log10(max(ms, 1e-12))


def loudness_short_max(x: np.ndarray, window: float = 0.4, hop: float = 0.1) -> float:
    """Max 400 ms 'momentary' K-loudness - the number that tracks how loud a burst FEELS, where the
    whole-file mean is diluted by silence."""
    m = to_mono(x)
    w = n_samples(window)
    h = n_samples(hop)
    if len(m) <= w:
        return loudness_k(m)
    y = highpass(highshelf(m, 1681.97, 4.0, 0.7072), 38.13, 0.5003)
    best = -120.0
    for s in range(0, len(y) - w + 1, h):
        seg = y[s:s + w]
        best = max(best, -0.691 + 10.0 * math.log10(max(float(np.mean(seg * seg)), 1e-12)))
    return best
