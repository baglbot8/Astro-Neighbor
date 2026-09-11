"""Instrument voices for the sequencer. Every melodic instrument has the signature
inst(freq, dur_sec, vel) -> mono array (already enveloped, ends at ~0).
Drum voices take (vel) and are exposed through drumkit() as inst(name, dur, vel).
"""
import math
import numpy as np
import synth as S

SR = S.SR


def _partials(freq, n, partials, t=None):
    """Sum of sine partials: partials = [(ratio, amp, tau), ...] (tau = decay time constant, s)."""
    t = S.times(n) if t is None else t
    y = np.zeros(n)
    for ratio, amp, tau in partials:
        f = freq * ratio
        if f >= SR * 0.45:
            continue
        y += amp * np.sin(S.TWO_PI * f * t) * np.exp(-t / tau)
    return y


def _mallet_click(n, seed=3, fc=3000.0, amount=0.15, decay=0.004):
    m = min(n, S.n_samples(0.02))
    c = S.bandpass(S.noise(m, seed), fc, 1.2) * S.env_perc(m, decay, 0.0005)
    return S.pad_to(c * amount, n)

# --------------------------------------------------------------------------- mallets & keys

def marimba(freq, dur, vel=1.0):
    """Warm marimba: strong fundamental, tuned 4th partial, brief 10th, soft mallet click."""
    tau = float(np.clip(1.1 * (261.6 / freq) ** 0.6, 0.18, 1.6))
    n = S.n_samples(min(tau * 4.5, 2.2))
    y = _partials(freq, n, [(1.0, 1.0, tau), (4.0, 0.32 * vel, tau * 0.28), (10.0, 0.07 * vel, tau * 0.09)])
    y += _mallet_click(n, seed=int(freq) % 97, fc=2400.0, amount=0.10 * vel)
    y *= S.env_perc(n, tau * 1.6, 0.0015)
    return y * (0.5 + 0.5 * vel)


def kalimba(freq, dur, vel=1.0):
    """Kalimba tine: pure fundamental with a bright inharmonic ping and a little thumb click."""
    tau = float(np.clip(1.3 * (392.0 / freq) ** 0.5, 0.25, 1.8))
    n = S.n_samples(min(tau * 4.0, 2.0))
    y = _partials(freq, n, [(1.0, 1.0, tau), (2.0, 0.08, tau * 0.5), (5.43, 0.22 * vel, tau * 0.12),
                             (8.9, 0.06 * vel, tau * 0.07)])
    y += _mallet_click(n, seed=int(freq) % 89, fc=1800.0, amount=0.12 * vel, decay=0.003)
    y *= S.env_perc(n, tau * 1.5, 0.001)
    return y * (0.55 + 0.45 * vel)


def vibraphone(freq, dur, vel=1.0):
    """Vibes: long ring, tuned 4th partial, motor tremolo ~4.5 Hz."""
    tau = float(np.clip(2.4 * (261.6 / freq) ** 0.5, 0.5, 3.0))
    n = S.n_samples(min(max(dur + 0.8, 1.0), 3.2))
    y = _partials(freq, n, [(1.0, 1.0, tau), (4.0, 0.22 * vel, tau * 0.35), (10.0, 0.04, tau * 0.1)])
    y += _mallet_click(n, seed=int(freq) % 61, fc=3500.0, amount=0.06 * vel)
    y = S.tremolo(y, 4.6, 0.35)
    y *= S.env_perc(n, tau, 0.002) * S.adsr(n, 0.0, 0.0, 1.0, 0.25)
    return y * (0.55 + 0.45 * vel)


def glockenspiel(freq, dur, vel=1.0):
    tau = float(np.clip(1.2 * (1046.0 / freq) ** 0.4, 0.3, 1.6))
    n = S.n_samples(min(tau * 4.0, 1.8))
    y = _partials(freq, n, [(1.0, 1.0, tau), (2.76, 0.25, tau * 0.5), (5.4, 0.1, tau * 0.25)])
    y += _mallet_click(n, seed=int(freq) % 53, fc=5000.0, amount=0.05)
    y *= S.env_perc(n, tau * 1.5, 0.001)
    return y * (0.5 + 0.5 * vel)


def music_box(freq, dur, vel=1.0):
    """Music-box comb tine: bright, delicate, quick decay."""
    tau = float(np.clip(0.9 * (1046.0 / freq) ** 0.35, 0.3, 1.2))
    n = S.n_samples(min(tau * 4.0, 1.6))
    y = _partials(freq, n, [(1.0, 1.0, tau), (2.0, 0.28, tau * 0.6), (3.0, 0.10, tau * 0.4),
                             (5.1, 0.08 * vel, tau * 0.2), (7.9, 0.03, tau * 0.1)])
    y += _mallet_click(n, seed=int(freq) % 71, fc=6000.0, amount=0.08 * vel, decay=0.0025)
    y *= S.env_perc(n, tau * 1.4, 0.0008)
    y = S.highpass(y, 250.0)
    return y * (0.5 + 0.5 * vel)


def bell(freq, dur, vel=1.0):
    """FM bell (carrier:mod 1:1.4, index decaying) — toast / chime."""
    n = S.n_samples(min(max(dur, 0.6) + 0.6, 2.5))
    t = S.times(n)
    idx = (1.8 + 1.2 * vel) * np.exp(-t / 0.45)
    mod = np.sin(S.TWO_PI * freq * 1.4 * t) * idx
    y = np.sin(S.TWO_PI * freq * t + mod) * np.exp(-t / 1.1)
    y += 0.25 * np.sin(S.TWO_PI * freq * 2.0 * t) * np.exp(-t / 0.5)
    y *= S.env_perc(n, 1.2, 0.001)
    return y * (0.5 + 0.5 * vel)


def epiano(freq, dur, vel=1.0):
    """Rhodes-ish 2-op FM with a tine partial and a slow tremolo."""
    n = S.n_samples(min(dur + 0.35, 4.0))
    t = S.times(n)
    idx = (0.35 + 1.4 * vel) * np.exp(-t / 0.4) + 0.12
    mod = np.sin(S.TWO_PI * freq * t) * idx
    y = np.sin(S.TWO_PI * freq * t + mod)
    if freq * 7.0 < SR * 0.45:
        y += 0.10 * vel * np.sin(S.TWO_PI * freq * 7.0 * t) * np.exp(-t / 0.06)
    y += 0.18 * np.sin(S.TWO_PI * freq * 0.5 * t) * np.exp(-t / 0.5) if freq > 200 else 0.0
    env = S.adsr(n, 0.003, 1.6, 0.35, 0.3, decay_curve=1.6)
    y = S.tremolo(y * env, 4.2, 0.12)
    y = S.lowpass(y, 2200.0 + 3500.0 * vel, 0.7)
    return y * (0.6 + 0.4 * vel)


def pluck(freq, dur, vel=1.0, harmonics=20, pos=0.27, tau=0.85, bright=1.0):
    """Additive nylon/harp pluck: harmonic amplitudes shaped by pluck position, higher partials decay faster."""
    tau = float(np.clip(tau * (220.0 / freq) ** 0.45, 0.2, 2.0))
    n = S.n_samples(min(tau * 4.0, 2.4))
    t = S.times(n)
    y = np.zeros(n)
    for k in range(1, harmonics + 1):
        f = freq * k * (1.0 + 0.00025 * k * k)  # slight stiffness inharmonicity
        if f >= SR * 0.45:
            break
        amp = abs(math.sin(math.pi * k * pos)) / (k ** (1.25 / bright))
        y += amp * np.sin(S.TWO_PI * f * t) * np.exp(-t * (1.0 + 0.35 * (k - 1)) / tau)
    y += _mallet_click(n, seed=int(freq) % 43, fc=3000.0, amount=0.05 * vel, decay=0.002)
    y *= S.env_perc(n, tau * 1.5, 0.0012)
    return y / 1.3 * (0.5 + 0.5 * vel)


def harp(freq, dur, vel=1.0):
    return pluck(freq, dur, vel, harmonics=14, pos=0.33, tau=1.4, bright=0.85)


def synth_pluck(freq, dur, vel=1.0):
    """Dance/pop synth pluck: detuned saws through a fast-closing lowpass."""
    n = S.n_samples(min(max(dur, 0.25) + 0.25, 1.5))
    y = S.saw(freq, n) + S.saw(freq * 1.004, n, 0.3) + 0.6 * S.pulse(freq * 0.5, n, 0.5)
    y = S.sweep_lowpass(y / 2.2, 1200.0 + 5000.0 * vel, 350.0, 0.14, q=1.2)
    y *= S.adsr(n, 0.002, 0.35, 0.25, 0.12)
    return y * (0.55 + 0.45 * vel)

# --------------------------------------------------------------------------- sustained voices

def pad(freq, dur, vel=1.0, cutoff=1800.0, attack=0.35, release=0.9):
    """Warm detuned-saw pad with a sub sine."""
    n = S.n_samples(dur + release + 0.05)
    y = S.saw(freq * 0.9965, n) + S.saw(freq, n, 0.33) + S.saw(freq * 1.0035, n, 0.66)
    y = y / 3.0 + 0.35 * S.sine(freq, n)
    y = S.lowpass(y, cutoff, 0.75)
    y *= S.adsr(n, attack, 0.3, 0.85, release)
    return y * 0.8 * (0.6 + 0.4 * vel)


def soft_pad(freq, dur, vel=1.0):
    """Gentle triangle/sine pad for night & space."""
    n = S.n_samples(dur + 1.2)
    y = S.triangle(freq, n) * 0.55 + S.sine(freq, n) * 0.5 + 0.25 * S.triangle(freq * 1.003, n, 0.5)
    y += 0.12 * S.sine(freq * 2.0, n) * 0.5
    y = S.lowpass(y, 1400.0, 0.7)
    y *= S.adsr(n, 0.6, 0.4, 0.9, 1.1)
    return y * 0.7 * (0.6 + 0.4 * vel)


def shimmer(freq, dur, vel=1.0):
    """Airy high sine cluster (octaves + fifth), very slow attack — space sparkle bed."""
    n = S.n_samples(dur + 1.5)
    y = S.sine(freq * 2.0, n) + 0.6 * S.sine(freq * 3.0, n, 0.2) + 0.5 * S.sine(freq * 4.0, n, 0.4) \
        + 0.35 * S.sine(freq * 4.0 * 1.004, n, 0.7)
    y *= S.adsr(n, 0.9, 0.5, 0.8, 1.4)
    return y * 0.25 * (0.6 + 0.4 * vel)


def flute(freq, dur, vel=1.0):
    n = S.n_samples(dur + 0.12)
    f = S.vibrato_freq(freq, n, 5.2, 14.0, onset=0.18, ramp=0.25)
    y = S.sine(f, n) + 0.28 * S.sine(f * 2.0, n, 0.1) + 0.08 * S.sine(f * 3.0, n, 0.2)
    breath = S.bandpass(S.noise(n, int(freq) % 31), 2800.0, 0.8) * 0.05
    y = (y + breath) * S.adsr(n, 0.05, 0.12, 0.85, 0.1)
    return y * 0.75 * (0.6 + 0.4 * vel)


def whistle(freq, dur, vel=1.0):
    """Cheerful whistle with a tiny pitch scoop into each note."""
    n = S.n_samples(dur + 0.1)
    f = S.vibrato_freq(freq, n, 5.8, 22.0, onset=0.12, ramp=0.2)
    scoop = np.clip(S.times(n) / 0.05, 0.0, 1.0)
    f = f * (0.985 + 0.015 * scoop)
    y = S.sine(f, n) + 0.12 * S.sine(f * 2.0, n)
    y *= S.adsr(n, 0.03, 0.05, 0.9, 0.08)
    return y * 0.7 * (0.6 + 0.4 * vel)


def theremin(freq, dur, vel=1.0, prev_freq=None):
    """Alien lead: sine that glides from the previous note with a wide, slowish vibrato."""
    n = S.n_samples(dur + 0.25)
    start = prev_freq if prev_freq else freq * 0.94
    f = S.glide_freq(start, freq, n, 0.13)
    f = f * S.vibrato_freq(1.0, n, 5.0, 32.0, onset=0.12, ramp=0.3)
    wob = 1.0 + 0.006 * S.lfo(0.9, n)
    y = S.sine(f * wob, n) + 0.15 * S.sine(f * 2.0 * wob, n) + 0.05 * S.triangle(f * 3.0, n)
    y *= S.adsr(n, 0.09, 0.1, 0.9, 0.22)
    return y * 0.7 * (0.6 + 0.4 * vel)


theremin.legato = True


def sine_ping(freq, dur, vel=1.0, tau=0.5):
    n = S.n_samples(min(tau * 4.0, 2.0))
    t = S.times(n)
    y = np.sin(S.TWO_PI * freq * t) * np.exp(-t / tau) + 0.15 * np.sin(S.TWO_PI * freq * 2.0 * t) * np.exp(-t / (tau * 0.4))
    y *= S.env_perc(n, tau * 1.5, 0.001)
    return y * (0.5 + 0.5 * vel)


def blip(freq, dur, vel=1.0):
    """Alien signal blip: quick downward chirp."""
    n = S.n_samples(0.16)
    f = S.glide_freq(freq * 1.5, freq, n, 0.06)
    y = S.sine(f, n) * S.env_perc(n, 0.05, 0.002)
    return y * (0.5 + 0.5 * vel)

# --------------------------------------------------------------------------- chip voices

def chip_pulse(freq, dur, vel=1.0, duty=0.25):
    n = S.n_samples(dur + 0.04)
    f = S.vibrato_freq(freq, n, 5.6, 9.0, onset=0.12, ramp=0.15)
    y = S.pulse(f, n, duty)
    y *= S.adsr(n, 0.004, 0.06, 0.72, 0.03)
    y = S.lowpass(y, 9000.0, 0.6)
    return y * 0.55 * (0.6 + 0.4 * vel)


def chip_square(freq, dur, vel=1.0):
    return chip_pulse(freq, dur, vel, 0.5)


def chip_thin(freq, dur, vel=1.0):
    return chip_pulse(freq, dur, vel, 0.125)


def chip_bass(freq, dur, vel=1.0):
    n = S.n_samples(dur + 0.03)
    y = S.pulse(freq, n, 0.5) * 0.7 + 0.5 * S.triangle(freq, n)
    y = S.lowpass(y, 1600.0, 0.7)
    y *= S.adsr(n, 0.003, 0.08, 0.7, 0.025)
    return y * 0.6 * (0.6 + 0.4 * vel)


def chip_tri_bass(freq, dur, vel=1.0):
    n = S.n_samples(dur + 0.03)
    y = S.triangle(freq, n)
    y = S.bitcrush(y, 5, 22050.0) * 0.8
    y = S.lowpass(y, 2500.0)
    y *= S.adsr(n, 0.003, 0.05, 0.8, 0.02)
    return y * 0.75 * (0.6 + 0.4 * vel)

# --------------------------------------------------------------------------- basses

def bass_soft(freq, dur, vel=1.0):
    """Upright-ish: sine body, a little triangle edge, thumb transient, natural decay."""
    n = S.n_samples(dur + 0.12)
    y = S.sine(freq, n) + 0.3 * S.triangle(freq, n) + 0.12 * S.sine(freq * 2.0, n)
    y = S.lowpass(y, 900.0, 0.7)
    thump = S.bandpass(S.noise(n, 5), 900.0, 1.0) * S.env_perc(n, 0.012, 0.001) * 0.35
    y = y * S.adsr(n, 0.004, 0.5, 0.55, 0.1, decay_curve=1.5) + thump
    return y * 0.9 * (0.6 + 0.4 * vel)


def bass_sub(freq, dur, vel=1.0):
    n = S.n_samples(dur + 0.25)
    y = S.sine(freq, n) + 0.15 * S.sine(freq * 2.0, n)
    y *= S.adsr(n, 0.02, 0.2, 0.85, 0.2)
    return y * 0.9 * (0.6 + 0.4 * vel)


def bass_synth(freq, dur, vel=1.0):
    """Round synth bass with a short filter sweep (event / chrome)."""
    n = S.n_samples(dur + 0.06)
    y = S.saw(freq, n) * 0.7 + S.pulse(freq, n, 0.5) * 0.4 + 0.5 * S.sine(freq, n)
    y = S.sweep_lowpass(y / 1.6, 900.0 + 1400.0 * vel, 220.0, 0.12, q=1.0)
    y *= S.adsr(n, 0.003, 0.12, 0.75, 0.05)
    return y * 0.9 * (0.6 + 0.4 * vel)

# --------------------------------------------------------------------------- drums

def kick(vel=1.0, soft=True):
    n = S.n_samples(0.35)
    t = S.times(n)
    f = 48.0 + 110.0 * np.exp(-t / 0.045)
    y = S.sine(f, n) * S.env_perc(n, 0.11, 0.0005)
    click = S.lowpass(S.noise(n, 11), 2500.0) * S.env_perc(n, 0.006, 0.0002) * (0.25 if soft else 0.5)
    y = y + click
    if soft:
        y = S.lowpass(y, 1800.0)
    return y * (0.6 + 0.4 * vel)


def kick_dance(vel=1.0):
    n = S.n_samples(0.4)
    t = S.times(n)
    f = 45.0 + 160.0 * np.exp(-t / 0.035)
    y = S.sine(f, n) * S.env_perc(n, 0.16, 0.0005)
    click = S.bandpass(S.noise(n, 12), 3000.0, 0.8) * S.env_perc(n, 0.008, 0.0002) * 0.5
    y = S.soft_clip((y + click) * 1.4, 0.6)
    return y * (0.6 + 0.4 * vel)


def snare(vel=1.0, brushed=True):
    n = S.n_samples(0.28)
    tone = S.sine(185.0, n) * S.env_perc(n, 0.05, 0.0005) * 0.6
    body = S.bandpass(S.noise(n, 21), 1800.0, 0.6) * S.env_perc(n, 0.09 if brushed else 0.12, 0.004 if brushed else 0.0005)
    y = tone + body * (0.8 if brushed else 1.2)
    if brushed:
        y = S.lowpass(y, 6500.0)
    return y * 0.8 * (0.6 + 0.4 * vel)


def rim(vel=1.0):
    n = S.n_samples(0.09)
    y = S.sine(820.0, n) * S.env_perc(n, 0.015, 0.0003) * 0.6 + S.sine(410.0, n) * S.env_perc(n, 0.03, 0.0003) * 0.5
    y += S.highpass(S.noise(n, 22), 2500.0) * S.env_perc(n, 0.006, 0.0002) * 0.5
    return y * 0.8 * (0.6 + 0.4 * vel)


def hat(vel=1.0, open_=False, brushed=True):
    n = S.n_samples(0.45 if open_ else 0.12)
    y = S.highpass(S.noise(n, 31 if open_ else 32), 6500.0 if not brushed else 5000.0, 0.7)
    y = S.lowpass(y, 14000.0)
    y *= S.env_perc(n, 0.16 if open_ else 0.035, 0.004 if brushed else 0.0005)
    return y * (0.35 if brushed else 0.5) * (0.6 + 0.4 * vel)


def shaker(vel=1.0):
    n = S.n_samples(0.14)
    y = S.bandpass(S.noise(n, 41), 6000.0, 0.9) * S.env_perc(n, 0.05, 0.012)
    return y * 0.4 * (0.6 + 0.4 * vel)


def clap(vel=1.0):
    n = S.n_samples(0.3)
    y = np.zeros(n)
    for i, off in enumerate((0.0, 0.011, 0.023)):
        m = S.bandpass(S.noise(n, 51 + i), 1500.0, 0.8) * S.env_perc(n, 0.015, 0.001)
        S.mix_into(y, m, S.n_samples(off), 0.6)
    y += S.bandpass(S.noise(n, 55), 1800.0, 0.6) * S.env_perc(n, 0.09, 0.03) * 0.8
    return y * 0.7 * (0.6 + 0.4 * vel)


def conga(vel=1.0, hi=True):
    n = S.n_samples(0.3)
    t = S.times(n)
    base = 205.0 if hi else 150.0
    f = base * (1.0 + 0.22 * np.exp(-t / 0.02))
    y = S.sine(f, n) * S.env_perc(n, 0.12 if hi else 0.16, 0.001)
    slap = S.bandpass(S.noise(n, 61), 2200.0, 1.0) * S.env_perc(n, 0.01, 0.0005) * 0.35
    return (y + slap) * 0.8 * (0.6 + 0.4 * vel)


def woodblock(vel=1.0):
    n = S.n_samples(0.08)
    y = S.sine(1250.0, n) * S.env_perc(n, 0.018, 0.0003) + 0.5 * S.sine(830.0, n) * S.env_perc(n, 0.025, 0.0003)
    return y * 0.6 * (0.6 + 0.4 * vel)


def chip_kick(vel=1.0):
    n = S.n_samples(0.2)
    t = S.times(n)
    f = 55.0 + 200.0 * np.exp(-t / 0.03)
    y = S.triangle(f, n) * S.env_perc(n, 0.07, 0.0005)
    return S.lowpass(y, 3000.0) * (0.6 + 0.4 * vel)


def chip_snare(vel=1.0):
    n = S.n_samples(0.16)
    y = S.bitcrush(S.noise(n, 71), 6, 16000.0) * S.env_perc(n, 0.05, 0.0005)
    y += S.triangle(210.0, n) * S.env_perc(n, 0.03, 0.0005) * 0.5
    return S.lowpass(y, 9000.0) * 0.5 * (0.6 + 0.4 * vel)


def chip_hat(vel=1.0, open_=False):
    n = S.n_samples(0.25 if open_ else 0.06)
    y = S.bitcrush(S.noise(n, 72 if open_ else 73), 6, 22050.0)
    y = S.highpass(y, 8000.0) * S.env_perc(n, 0.09 if open_ else 0.02, 0.0005)
    return y * 0.3 * (0.6 + 0.4 * vel)


KIT_ACOUSTIC = {
    "kick": lambda v: kick(v, True), "snare": lambda v: snare(v, True), "rim": rim,
    "hat": lambda v: hat(v, False, True), "ohat": lambda v: hat(v, True, True), "shaker": shaker,
    "clap": clap, "conga_hi": lambda v: conga(v, True), "conga_lo": lambda v: conga(v, False),
    "wood": woodblock,
}
KIT_DANCE = dict(KIT_ACOUSTIC)
KIT_DANCE.update({"kick": kick_dance, "hat": lambda v: hat(v, False, False), "ohat": lambda v: hat(v, True, False),
                  "snare": lambda v: snare(v, False)})
KIT_CHIP = dict(KIT_ACOUSTIC)
KIT_CHIP.update({"kick": chip_kick, "snare": chip_snare, "hat": lambda v: chip_hat(v, False),
                 "ohat": lambda v: chip_hat(v, True)})


def drumkit(kit):
    """Wrap a name->voice dict as a sequencer instrument (pitch = drum name)."""
    def inst(name, dur, vel):
        fn = kit.get(name)
        if fn is None:
            raise KeyError("unknown drum %r" % name)
        return fn(vel)
    return inst

# --------------------------------------------------------------------------- title "signal" voices
# Added for the title's "Signal" sonic logo (music.track_title_*). The user said the old title read as
# Animal Crossing. Its timbral tells were mallets -- a vibraphone lead, glockenspiel echoes -- a whistle
# doubling the tune, and an e-piano bouncing in 8ths. These voices are deliberately the other family:
# sustained or slow-attack analog-synth tones, filtered warm, with NO mallet click (_mallet_click) and
# NO inharmonic "struck bar" partials (glockenspiel 2.76/5.4, vibraphone 4.0/10.0, marimba 4.0/10.0).
# Nothing below is used by any other track; changing them only changes the title.

def sonar_ping(freq, dur, vel=1.0):
    """Beacon / sonar ping for the title motif. A near-pure sine with a 7 ms onset (a mallet is ~1 ms and
    clicks), landing from 14 cents sharp over the first ~60 ms the way a transducer settles, plus a second
    sine 0.8 Hz above so the ring swells slowly -- a constant 0.8 Hz at every pitch rather than a ratio,
    because a ratio beats at ~2 Hz up at D6 and that starts to read as vibraphone tremolo (4.6 Hz).
    TWO-STAGE ENVELOPE: a 0.11 s "strike" that falls ~8 dB into a long ring (time constant ~1.2 s).
    The motif has to set the track's -1 dBFS peak (validate() pins it) without being the loudest thing
    for three whole seconds; with one plain exponential the first render put the motif's 3 s loudness
    3.6 LU over the loop's. The strike carries the peak, the ring carries the sound. Lowpassed at
    4.2 kHz so the onset never gets glassy."""
    tau = float(np.clip(1.25 * (466.0 / freq) ** 0.35, 0.55, 1.6))
    n = S.n_samples(min(tau * 4.6, 5.5))
    t = S.times(n)
    f = freq * 2.0 ** (14.0 * np.exp(-t / 0.028) / 1200.0)
    y = S.sine(f, n) + 0.32 * S.sine(f + 0.8, n, 0.25)
    y += 0.10 * S.sine(f * 2.0, n) * np.exp(-t / 0.18)
    y *= S.env_perc(n, tau, 0.007) * (0.38 + 0.62 * np.exp(-t / 0.11))
    return S.lowpass(y, 4200.0, 0.6) / 1.35 * (0.5 + 0.5 * vel)


def analog_pad(freq, dur, vel=1.0):
    """Warm poly-synth pad, the title's bed: two saws 7.4 cents either side of the pitch plus a 32 %
    pulse, through a lowpass that OPENS from 480 Hz to 2400 + 800 x vel Hz (2.84 kHz at vel 0.55; time
    constant 0.9 s) while the 1.3 s attack swells, then a 1.9 s release. It arrives as a swell rather
    than a strike (`pad`: 0.35 s attack). WHY SO OPEN: the target is an iPhone speaker, which plays
    little below ~400-500 Hz, so the saw harmonics between 500 Hz and 3 kHz are most of what a phone
    hears of this pad. Round 1 opened it only to 1.5 + 0.6 x vel kHz (1.83 kHz) and voiced it round
    middle C: take A then had 0.2 % of its power above 2 kHz and 55 % at 150-500 Hz, and measured
    4-5 dB under the planet music through a 400-450 Hz high-pass. (A very first cut, at 1.4 kHz, had
    0.0 % above 2 kHz.) Chorus is added per part."""
    n = S.n_samples(dur + 2.0)
    y = S.saw(freq * 0.99573, n) + S.saw(freq * 1.00428, n, 0.37) + 0.5 * S.pulse(freq, n, 0.32, 0.61)
    y = y / 2.5 + 0.3 * S.sine(freq, n)
    y = S.sweep_lowpass(y, 480.0, 2400.0 + 800.0 * vel, 0.9, q=0.75)
    y *= S.adsr(n, 1.3, 0.5, 0.85, 1.9)
    return y * 0.75 * (0.6 + 0.4 * vel)


def analog_arp(freq, dur, vel=1.0):
    """Slow analog arpeggio voice: saw + a triangle 6 cents up + a sine an octave below, a 14 ms attack
    and a lowpass that TRACKS THE KEY: it closes from (1.8 + 4.1 x vel) x the pitch (3.85 x at vel 0.5,
    capped at 9 kHz) to 1.25 x the pitch, tau 0.42 s. At G4, where round 1 played it, that is the same
    ~1.5 kHz -> 490 Hz it had as fixed numbers. Round 2 moved both arpeggios up an octave into the band
    a phone speaker plays (554-1047 Hz in the sonar take), and a fixed 480 Hz end point would have sat
    an octave BELOW the new fundamentals, choking every note to its onset. It then RINGS (amplitude time
    constant 0.85 s), so notes a beat apart overlap: the opposite of the old title's e-piano 8ths and
    of `synth_pluck` (2 ms attack, filter closed in 0.14 s). The first 80 ms stand ~5 dB over the ring
    (same two-stage idea as sonar_ping): in the orbit take these onsets have to carry the bed's peaks,
    because a pad-led bed (crest ~10-11 dB) cannot sit at -14 LUFS under the -1 dBFS peak."""
    n = S.n_samples(max(dur, 0.25) + 1.6)
    y = 0.65 * S.saw(freq, n) + 0.45 * S.triangle(freq * 1.0035, n, 0.3) + 0.25 * S.sine(freq * 0.5, n)
    y = S.sweep_lowpass(y, min(freq * (1.8 + 4.1 * vel), 9000.0), freq * 1.25, 0.42, q=0.9)
    y *= S.env_perc(n, 0.85, 0.014) * (0.55 + 0.45 * np.exp(-S.times(n) / 0.08))
    return y * 0.8 * (0.55 + 0.45 * vel)


def sub_swell(freq, dur, vel=1.0):
    """Soft sub that swells in (0.35 s) and lets go slowly (1.1 s) so a bass change is a tide, not a pluck.
    A 2nd harmonic at -18 dB, because the target is an iPhone speaker, which reproduces little below
    ~200 Hz: that harmonic is most of what the phone plays of it."""
    n = S.n_samples(dur + 1.2)
    y = S.sine(freq, n) + 0.12 * S.sine(freq * 2.0, n, 0.1)
    y *= S.adsr(n, 0.35, 0.4, 0.88, 1.1)
    return y * 0.9 * (0.6 + 0.4 * vel)


def morse_tone(freq, dur, vel=1.0):
    """A keyed CW tone: the written length IS the key-down time (a dit or a dah). 7 ms raised-cosine
    edges like a real keyer's shaping (a hard key clicks), a sine with a little 2nd and 3rd harmonic so
    it has body rather than reading as a test tone, and a 40 ms afterglow at 15 % so the gaps between
    elements do not fall to dead silence. Each key-down starts ~4 dB hot and settles in ~50 ms: a keyed
    sine is otherwise nearly all energy (crest ~3 dB), and as the title's logo it has to set the loop's
    -1 dBFS peak without its 3 s loudness towering over the bed (it measured 3.2 LU over at first)."""
    key = max(S.n_samples(dur), S.n_samples(0.03))
    glow = S.n_samples(0.04)
    n = key + glow
    y = S.sine(freq, n) + 0.14 * S.sine(freq * 2.0, n, 0.1) + 0.05 * S.sine(freq * 3.0, n, 0.3)
    edge = S.n_samples(0.007)
    ramp = 0.5 - 0.5 * np.cos(np.pi * np.arange(edge) / edge)
    env = 1.0 + 0.6 * np.exp(-S.times(n) / 0.02)
    env[:edge] *= ramp
    env[key - edge:key] = 0.15 + 0.85 * ramp[::-1]
    env[key:] = 0.15 * np.exp(-np.arange(glow) / (0.25 * glow)) * np.linspace(1.0, 0.0, glow)
    return S.lowpass(y * env, 3600.0, 0.7) * 0.8 * (0.55 + 0.45 * vel)


def radio_lead(freq, dur, vel=1.0):
    """A far-off broadcast: a 34 % pulse + triangle squeezed into an AM-radio band (360 Hz - 2.3 kHz,
    24 dB/oct on top: at 12 dB/oct the pulse's harmonics still showed on the spectrogram up to 10 kHz,
    which is not a radio any more), 0.16 s swell, and 0.6 Hz / +-5 cent wow instead of vibrato. Vibrato
    at 5-6 Hz on a sine-ish tone is exactly what makes `whistle` a whistle, which the brief bans."""
    n = S.n_samples(dur + 0.5)
    t = S.times(n)
    f = freq * (1.0 + 0.0028 * np.sin(S.TWO_PI * 0.6 * t))
    y = 0.55 * S.pulse(f, n, 0.34) + 0.5 * S.triangle(f, n)
    y = S.highpass(S.lowpass4(y, 2300.0, 0.7071), 360.0, 0.8)
    y *= S.adsr(n, 0.16, 0.4, 0.78, 0.45)
    return y * 0.8 * (0.6 + 0.4 * vel)
