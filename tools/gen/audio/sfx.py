"""Sound effects for Astro Neighbor. Each generator returns a mono or stereo array; build_all.py
normalises (-3 dBFS), fades the edges and writes assets/audio/sfx/<name>.wav.

Design notes: short, bright, rounded (ACNH-like). A hair of plate reverb on almost everything.
World sounds (footsteps, jump, place, rocket...) are mono so AudioStreamPlayer3D can position them;
UI / jingles are stereo.
"""
import math
import numpy as np
import synth as S
import instruments as I

SR = S.SR


def _rev(x, wet=0.12, room=0.6, tone=6000.0, mono=False):
    y = S.reverb(x, room=room, damp=0.5, wet=wet, tone=tone, predelay=0.004)
    return S.to_mono(y) if mono else y


def _seq(text, inst, bpm=120.0, seconds=None, gain=1.0, swing=0.0, pan_by_pitch=0.0, pan=0.0):
    notes = S.parse_seq(text)
    beats = S.seq_length_beats(notes)
    n = S.n_samples(seconds if seconds else beats * 60.0 / bpm + 1.5)
    return S.render_notes(notes, inst, bpm, n, swing=swing, gain=gain, pan_pos=pan, pan_by_pitch=pan_by_pitch)


def _trim(x, thresh_db=-60.0, keep=0.05):
    """Trim trailing near-silence (keeps `keep` seconds after the last loud sample)."""
    m = np.abs(S.to_mono(x))
    thr = S.db(thresh_db) * (m.max() + 1e-12)
    idx = np.where(m > thr)[0]
    if len(idx) == 0:
        return x
    end = min(S.length(x), idx[-1] + S.n_samples(keep))
    return x[..., :end]

# --------------------------------------------------------------------------- footsteps

def footstep_grass(variant=0):
    seed = 100 + variant
    n = S.n_samples(0.13)
    t = S.times(n)
    thump = S.sine(95.0 - 25.0 * variant * 0.3 + 60.0 * np.exp(-t / 0.01), n) * S.env_perc(n, 0.03, 0.001) * 0.9
    body = S.bandpass(S.noise(n, seed), 420.0 + 60.0 * variant, 0.7) * S.env_perc(n, 0.035, 0.002) * 0.9
    swish = S.bandpass(S.noise(n, seed + 7), 3800.0 + 500.0 * variant, 0.9) * S.env_perc(n, 0.045, 0.012) * 0.28
    y = S.lowpass(thump + body, 2500.0) + swish
    return _rev(y, 0.08, 0.5, mono=True)


def footstep_stone(variant=0):
    seed = 110 + variant
    n = S.n_samples(0.1)
    t = S.times(n)
    thump = S.sine(130.0 + 50.0 * np.exp(-t / 0.008), n) * S.env_perc(n, 0.02, 0.0005) * 0.7
    click = S.bandpass(S.noise(n, seed), 1600.0 + 200.0 * variant, 0.9) * S.env_perc(n, 0.018, 0.0008)
    grit = S.highpass(S.noise(n, seed + 3), 4000.0) * S.env_perc(n, 0.03, 0.004) * 0.3
    y = thump + click + grit
    return _rev(y, 0.12, 0.55, mono=True)


def footstep_metal(variant=0):
    seed = 120 + variant
    n = S.n_samples(0.16)
    t = S.times(n)
    f1, f2 = (1750.0, 2610.0) if variant == 0 else (1930.0, 2880.0)
    ring = (np.sin(S.TWO_PI * f1 * t) * np.exp(-t / 0.035) + 0.6 * np.sin(S.TWO_PI * f2 * t) * np.exp(-t / 0.025)) * 0.5
    thump = S.sine(140.0 + 80.0 * np.exp(-t / 0.008), n) * S.env_perc(n, 0.025, 0.0005) * 0.8
    click = S.bandpass(S.noise(n, seed), 2500.0, 1.0) * S.env_perc(n, 0.012, 0.0005) * 0.8
    y = thump + click + ring * S.env_perc(n, 0.05, 0.001)
    return _rev(y, 0.15, 0.6, mono=True)

# --------------------------------------------------------------------------- movement

def jump():
    n = S.n_samples(0.3)
    t = S.times(n)
    f = 300.0 * (900.0 / 300.0) ** np.clip(t / 0.14, 0.0, 1.0)
    boing = S.triangle(f * (1.0 + 0.02 * np.sin(S.TWO_PI * 28.0 * t)), n) * S.adsr(n, 0.005, 0.08, 0.5, 0.12) * 0.8
    whoosh = S.sweep_lowpass(S.highpass(S.noise(n, 201), 600.0), 900.0, 6000.0, 0.12) * S.adsr(n, 0.01, 0.1, 0.3, 0.1) * 0.35
    y = S.lowpass(boing, 5000.0) + whoosh
    return _rev(y, 0.1, 0.55, mono=True)


def land():
    n = S.n_samples(0.28)
    t = S.times(n)
    thud = S.sine(120.0 * np.exp(-t / 0.05) + 55.0, n) * S.env_perc(n, 0.07, 0.001)
    dust = S.lowpass(S.noise(n, 202), 1200.0) * S.env_perc(n, 0.1, 0.01) * 0.35
    y = thud + dust
    return _rev(y, 0.1, 0.55, mono=True)

# --------------------------------------------------------------------------- items

def pickup():
    y = _seq("C6:0.25 G6:0.5", I.pluck, bpm=150.0, seconds=0.5)
    n = S.length(y)
    t = S.times(n)
    sparkle = np.sin(S.TWO_PI * 4200.0 * t) * np.exp(-t / 0.08) * 0.15
    y = y + sparkle
    return _rev(y, 0.18, 0.6)


def collect_stardust():
    notes = "E6:0.125@0.8 G6:0.125@0.85 B6:0.125@0.9 E7:0.375@1.0"
    y = _seq(notes, I.glockenspiel, bpm=120.0, seconds=0.9, pan_by_pitch=0.12)
    n = S.length(y)
    t = S.times(n)
    shimmer = S.highpass(S.noise(n, 203), 7000.0) * np.exp(-t / 0.12) * 0.12
    y = y + shimmer
    return _rev(y, 0.25, 0.7, tone=9000.0)


def place():
    n = S.n_samples(0.3)
    t = S.times(n)
    plonk = S.sine(520.0 * np.exp(-t / 0.035) + 190.0, n) * S.env_perc(n, 0.09, 0.001)
    click = S.bandpass(S.noise(n, 204), 2200.0, 1.2) * S.env_perc(n, 0.008, 0.0004) * 0.6
    y = S.lowpass(plonk, 3000.0) + click
    return _rev(y, 0.12, 0.6, mono=True)


def pickup_item():
    n = S.n_samples(0.28)
    t = S.times(n)
    f = 190.0 + 330.0 * (1.0 - np.exp(-t / 0.05))
    swoop = S.sine(f, n) * S.adsr(n, 0.01, 0.05, 0.7, 0.08)
    click = S.bandpass(S.noise(n, 205), 2600.0, 1.2) * S.env_perc(n, 0.006, 0.0004)
    y = S.lowpass(swoop, 3000.0)
    S.mix_into(y, click * 0.5, S.n_samples(0.13))
    return _rev(y, 0.12, 0.6, mono=True)


def rotate():
    n = S.n_samples(0.06)
    t = S.times(n)
    y = S.bandpass(S.noise(n, 206), 2800.0, 1.5) * S.env_perc(n, 0.006, 0.0003) + np.sin(S.TWO_PI * 1900.0 * t) * np.exp(-t / 0.012) * 0.5
    return _rev(y, 0.08, 0.5)


def blocked():
    n = S.n_samples(0.22)
    t = S.times(n)
    f = 118.0 * (1.0 - 0.12 * np.clip(t / 0.2, 0, 1))
    y = S.pulse(f, n, 0.45) * 0.6 + S.saw(f * 2.0, n) * 0.25
    y = S.lowpass(y, 900.0) * S.adsr(n, 0.005, 0.02, 0.9, 0.06)
    y = S.tremolo(y, 26.0, 0.5)
    return _rev(y, 0.06, 0.5)

# --------------------------------------------------------------------------- UI

def ui_tick():
    n = S.n_samples(0.04)
    t = S.times(n)
    y = S.bandpass(S.noise(n, 207), 1800.0, 1.2) * S.env_perc(n, 0.006, 0.0005) * 0.7 + np.sin(S.TWO_PI * 1500.0 * t) * np.exp(-t / 0.01)
    return S.lowpass(y, 6000.0)


def ui_confirm():
    y = _seq("G5:0.25 C6:0.75", I.marimba, bpm=140.0, seconds=0.6)
    return _rev(y, 0.18, 0.6)


def ui_cancel():
    y = _seq("E5:0.25 A4:0.75", I.marimba, bpm=140.0, seconds=0.55, gain=0.9)
    return _rev(S.lowpass(y, 4000.0), 0.15, 0.6)


def ui_open():
    n = S.n_samples(0.32)
    t = S.times(n)
    whoosh = S.sweep_lowpass(S.highpass(S.noise(n, 208), 500.0), 800.0, 7000.0, 0.09) * S.adsr(n, 0.01, 0.06, 0.4, 0.12) * 0.3
    pop = S.sine(380.0 * (2.0 ** np.clip(t / 0.06, 0, 1)), n) * S.env_perc(n, 0.05, 0.002)
    y = np.zeros(n)
    S.mix_into(y, whoosh, 0)
    S.mix_into(y, pop, S.n_samples(0.06))
    return _rev(y, 0.15, 0.6)


def ui_close():
    n = S.n_samples(0.3)
    t = S.times(n)
    pop = S.sine(760.0 * (0.5 ** np.clip(t / 0.06, 0, 1)), n) * S.env_perc(n, 0.05, 0.002)
    whoosh = S.sweep_lowpass(S.highpass(S.noise(n, 209), 400.0), 5000.0, 600.0, 0.1) * S.adsr(n, 0.005, 0.05, 0.4, 0.12) * 0.25
    y = pop * 0.9
    S.mix_into(y, whoosh, S.n_samples(0.04))
    return _rev(y, 0.12, 0.6)


def ui_buy():
    n = S.n_samples(1.0)
    t = S.times(n)
    y = np.zeros((2, n))
    # register "ka-" click + coin bells
    click = S.bandpass(S.noise(n, 210), 3000.0, 1.0) * S.env_perc(n, 0.01, 0.0005)
    S.mix_into(y, S.pan(click * 0.8, 0.0), 0)
    coins = _seq("E6:0.125@0.9 A6:0.125@0.95 C#7:0.25@1.0 E7:0.5@0.9", I.bell, bpm=150.0, seconds=1.0, pan_by_pitch=0.1)
    S.mix_into(y, coins * 0.9, S.n_samples(0.05))
    ring = np.sin(S.TWO_PI * 5200.0 * t) * np.exp(-t / 0.05) * 0.15
    S.mix_into(y, S.pan(ring, 0.2), S.n_samples(0.05))
    return _rev(y, 0.2, 0.65, tone=9000.0)


def toast():
    y = _seq("A5:1", I.bell, bpm=120.0, seconds=0.9)
    return _rev(y, 0.25, 0.7)


def text_advance():
    n = S.n_samples(0.06)
    t = S.times(n)
    y = np.sin(S.TWO_PI * 1250.0 * t) * np.exp(-t / 0.015) + S.bandpass(S.noise(n, 211), 2500.0, 1.5) * S.env_perc(n, 0.005, 0.0003) * 0.4
    return S.lowpass(y, 7000.0)

# --------------------------------------------------------------------------- jingles

def quest_accept():
    y = _seq("C5:0.33 E5:0.33 G5:0.9", I.marimba, bpm=120.0, seconds=1.1, pan_by_pitch=0.1)
    y2 = _seq("r:0.66 G6:0.9@0.5", I.bell, bpm=120.0, seconds=1.1, gain=0.5)
    return _rev(y + y2, 0.22, 0.7)


def quest_complete():
    mar = _seq("C5:0.25 E5:0.25 G5:0.25 C6:0.25 E6:1.5", I.marimba, bpm=110.0, seconds=1.8, pan_by_pitch=0.08)
    bell = _seq("r:1.0 E6:1.5@0.7 r:0 ", I.bell, bpm=110.0, seconds=1.8, gain=0.6)
    chord = _seq("r:1.0 [C4,E4,G4,C5]:1.5@0.5", I.vibraphone, bpm=110.0, seconds=1.8, gain=0.55)
    glk = _seq("r:1.0 C7:0.25@0.5 G6:0.25@0.5 E7:0.75@0.6", I.glockenspiel, bpm=110.0, seconds=1.8, gain=0.5, pan=0.3)
    return _rev(mar + bell + chord + glk, 0.28, 0.75, tone=8000.0)


def friendship_up():
    y = _seq("C6:0.125 E6:0.125 G6:0.125 B6:0.125 D7:0.125 G7:0.5", I.sine_ping, bpm=130.0, seconds=1.0, pan_by_pitch=0.15)
    n = S.length(y)
    t = S.times(n)
    shimmer = S.highpass(S.noise(n, 212), 8000.0) * np.exp(-t / 0.2) * 0.1
    return _rev(y + shimmer, 0.3, 0.75, tone=10000.0)

# --------------------------------------------------------------------------- world / machines

def rocket_ignite():
    n = S.n_samples(1.5)
    t = S.times(n)
    build = np.clip(t / 1.3, 0.0, 1.0) ** 1.6
    base = S.lowpass(S.noise(n, 213), 260.0, 0.8) * 1.6
    mid = S.bandpass(S.noise(n, 214), 700.0, 0.8) * 0.5 * build
    sub = S.sine(38.0 + 22.0 * build, n) * 0.6 * build
    crackle = S.highpass(S.noise(n, 215), 3000.0) * (np.random.default_rng(216).uniform(0, 1, n) > 0.985) * 0.4 * build
    y = (base * (0.2 + 0.8 * build) + mid + sub + S.lowpass(crackle, 6000.0)) * S.adsr(n, 0.05, 0.0, 1.0, 0.03)
    return S.soft_clip(y * 0.9, 0.7)


def rocket_loop():
    """2 s seamless rumble: filtered noise (loop-folded) with a periodic amplitude wobble."""
    L = 17 * S.QOA_FRAME  # 1.974 s, a whole number of QOA frames so Godot's loop wrap is clean
    n = L + S.n_samples(0.5)
    t = S.times(n)
    base = S.lowpass(S.noise(n, 217), 240.0, 0.8) * 1.6
    mid = S.bandpass(S.noise(n, 218), 800.0, 0.7) * 0.35
    hiss = S.highpass(S.noise(n, 219), 2500.0) * 0.06
    per = L / float(S.SR)  # wobble rates are whole cycles per loop so the modulation is periodic
    wob = 1.0 + 0.12 * np.sin(S.TWO_PI * (8.0 / per) * t) + 0.08 * np.sin(S.TWO_PI * (3.0 / per) * t)
    sub = S.sine(round(52.0 * per) / per, n) * 0.5 * (1.0 + 0.1 * np.sin(S.TWO_PI * (4.0 / per) * t))
    y = (base + mid + hiss) * wob + sub
    y = S.fold_loop(y, L)
    return S.soft_clip(y * 0.8, 0.7)


def rocket_land():
    n = S.n_samples(1.6)
    t = S.times(n)
    thud = S.sine(85.0 * np.exp(-t / 0.08) + 38.0, n) * S.env_perc(n, 0.16, 0.001) * 1.2
    burst = S.lowpass(S.noise(n, 220), 700.0) * S.env_perc(n, 0.08, 0.002) * 0.8
    hiss = S.highpass(S.noise(n, 221), 1800.0) * S.env_perc(n, 0.5, 0.03) * 0.28
    y = thud + burst + hiss
    return _rev(S.soft_clip(y, 0.7), 0.15, 0.7, mono=True)


def door_open():
    n = S.n_samples(0.45)
    t = S.times(n)
    tap = S.bandpass(S.noise(n, 222), 900.0, 0.8) * S.env_perc(n, 0.02, 0.001) * 0.8 + S.sine(220.0 * np.exp(-t / 0.02) + 120.0, n) * S.env_perc(n, 0.04, 0.001) * 0.6
    sweep = S.sweep_lowpass(S.highpass(S.noise(n, 223), 300.0), 500.0, 3500.0, 0.25) * S.adsr(n, 0.02, 0.1, 0.5, 0.15) * 0.22
    y = tap
    S.mix_into(y, sweep, S.n_samples(0.05))
    return _rev(y, 0.15, 0.65, mono=True)


def door_close():
    n = S.n_samples(0.45)
    t = S.times(n)
    sweep = S.sweep_lowpass(S.highpass(S.noise(n, 224), 300.0), 3500.0, 500.0, 0.2) * S.adsr(n, 0.01, 0.1, 0.4, 0.1) * 0.2
    thunk = S.sine(160.0 * np.exp(-t / 0.03) + 90.0, n) * S.env_perc(n, 0.07, 0.001) + S.bandpass(S.noise(n, 225), 700.0, 0.8) * S.env_perc(n, 0.03, 0.001) * 0.7
    y = sweep
    S.mix_into(y, thunk, S.n_samples(0.16))
    return _rev(y, 0.15, 0.65, mono=True)


def tree_shake():
    n = S.n_samples(0.6)
    t = S.times(n)
    rng = np.random.default_rng(226)
    flutter = 0.55 + 0.45 * np.sin(S.TWO_PI * 24.0 * t + 2.0 * np.sin(S.TWO_PI * 5.0 * t))
    leaves = S.bandpass(S.noise(n, 227), 3200.0, 0.5) * flutter
    leaves += S.bandpass(S.noise(n, 228), 5500.0, 0.6) * (0.5 + 0.5 * np.sin(S.TWO_PI * 31.0 * t + 1.0)) * 0.6
    y = leaves * S.adsr(n, 0.02, 0.2, 0.6, 0.25)
    y += S.lowpass(S.noise(n, 229), 300.0) * S.env_perc(n, 0.06, 0.005) * 0.5  # trunk thump
    return _rev(y, 0.12, 0.6, mono=True)


def splash():
    n = S.n_samples(0.7)
    t = S.times(n)
    bloop = S.sine(620.0 * np.exp(-t / 0.05) + 140.0, n) * S.env_perc(n, 0.08, 0.002) * 0.8
    burst = S.lowpass(S.noise(n, 230), 1500.0) * S.env_perc(n, 0.06, 0.003) * 0.8
    fizz = S.highpass(S.noise(n, 231), 2500.0) * S.env_perc(n, 0.25, 0.04) * 0.3
    drops = np.zeros(n)
    for k, off in enumerate((0.18, 0.26, 0.33, 0.41)):
        m = S.n_samples(0.08)
        d = S.sine(900.0 + 300.0 * k, m) * S.env_perc(m, 0.02, 0.001) * 0.2
        S.mix_into(drops, d, S.n_samples(off))
    y = bloop + burst + fizz + drops
    return _rev(y, 0.15, 0.6, mono=True)

# --------------------------------------------------------------------------- emotes / misc

def emote_happy():
    """Giggle: three quick rising formant chirps."""
    n = S.n_samples(0.6)
    y = np.zeros(n)
    for k, (off, f0) in enumerate(((0.0, 520.0), (0.13, 600.0), (0.26, 700.0))):
        m = S.n_samples(0.11)
        f = S.glide_freq(f0, f0 * 1.35, m, 0.09)
        f = f * (1.0 + 0.03 * np.sin(S.TWO_PI * 22.0 * S.times(m)))
        v = S.pulse(f, m, 0.3) * 0.5 + S.sine(f, m) * 0.6
        v = S.bandpass(v, 1100.0, 0.8) * 2.0 + S.lowpass(v, 1500.0) * 0.5
        v *= S.adsr(m, 0.01, 0.02, 0.8, 0.03)
        S.mix_into(y, v, S.n_samples(off))
    y = S.lowpass(y, 5000.0)
    return _rev(y, 0.15, 0.6)


def emote_wave():
    n = S.n_samples(0.45)
    y = np.zeros(n)
    for off, f0, f1 in ((0.0, 420.0, 520.0), (0.16, 560.0, 720.0)):
        m = S.n_samples(0.2)
        f = S.glide_freq(f0, f1, m, 0.12)
        v = (S.sine(f, m) + 0.3 * S.triangle(f, m)) * S.adsr(m, 0.01, 0.04, 0.8, 0.05)
        S.mix_into(y, v, S.n_samples(off))
    return _rev(S.lowpass(y, 4000.0), 0.15, 0.6)


def dance_beat():
    """One 2-bar loopable mini beat (~121.6 BPM, 3.95 s), for the DJ / dance emote."""
    L = 34 * S.QOA_FRAME               # whole QOA frames -> clean loop wrap in Godot
    bpm = 8 * 60.0 * S.SR / L          # ~121.6 BPM
    n = L + S.n_samples(0.5)
    kit = I.drumkit(I.KIT_DANCE)
    drums = S.parse_seq("kick:1@0.9 kick:1@0.85 kick:1@0.9 kick:1@0.85 " * 2)
    claps = S.parse_seq("r:1 clap:1@0.8 r:1 clap:1@0.8 r:1 clap:1@0.8 r:1 clap:0.5@0.8 clap:0.5@0.7")
    hats = S.parse_seq("hat:0.5@0.5 ohat:0.5@0.7 " * 8)
    bass = S.parse_seq("A2:0.45 A3:0.45@0.7 A2:0.45 A3:0.45@0.7 C3:0.45 C4:0.45@0.7 C3:0.45 C4:0.45@0.7 "
                       "G2:0.45 G3:0.45@0.7 G2:0.45 G3:0.45@0.7 D3:0.45 D4:0.45@0.7 D3:0.45 D4:0.45@0.7", default_vel=0.9)
    y = S.render_notes(drums, kit, bpm, n, gain=S.db(-4.0))
    y += S.render_notes(claps, kit, bpm, n, gain=S.db(-8.0), pan_pos=0.1)
    y += S.render_notes(hats, kit, bpm, n, gain=S.db(-12.0), pan_pos=0.3)
    y += S.render_notes(bass, I.bass_synth, bpm, n, gain=S.db(-7.0))
    y = S.fold_loop(y, L)
    return S.soft_clip(y, 0.8)


def shooting_star():
    n = S.n_samples(1.3)
    t = S.times(n)
    whoosh = S.sweep_lowpass(S.highpass(S.noise(n, 232), 800.0), 9000.0, 900.0, 0.5) * S.adsr(n, 0.05, 0.3, 0.3, 0.4) * 0.25
    twinkle = _seq("E7:0.125@0.8 B6:0.125@0.7 G6:0.125@0.7 D6:0.125@0.6 B5:0.125@0.6 G5:0.5@0.5", I.glockenspiel, bpm=110.0, seconds=1.3, pan_by_pitch=0.15)
    y = S.pan(whoosh, -0.2) + twinkle
    return _rev(y, 0.35, 0.85, tone=9000.0)


# name -> (generator, stereo?, loop?)
SFX = {
    "footstep_grass_0": (lambda: footstep_grass(0), False, False),
    "footstep_grass_1": (lambda: footstep_grass(1), False, False),
    "footstep_stone_0": (lambda: footstep_stone(0), False, False),
    "footstep_stone_1": (lambda: footstep_stone(1), False, False),
    "footstep_metal_0": (lambda: footstep_metal(0), False, False),
    "footstep_metal_1": (lambda: footstep_metal(1), False, False),
    "jump": (jump, False, False),
    "land": (land, False, False),
    "pickup": (pickup, True, False),
    "collect_stardust": (collect_stardust, True, False),
    "place": (place, False, False),
    "pickup_item": (pickup_item, False, False),
    "rotate": (rotate, True, False),
    "blocked": (blocked, True, False),
    "ui_tick": (ui_tick, True, False),
    "ui_confirm": (ui_confirm, True, False),
    "ui_cancel": (ui_cancel, True, False),
    "ui_open": (ui_open, True, False),
    "ui_close": (ui_close, True, False),
    "ui_buy": (ui_buy, True, False),
    "toast": (toast, True, False),
    "quest_accept": (quest_accept, True, False),
    "quest_complete": (quest_complete, True, False),
    "friendship_up": (friendship_up, True, False),
    "rocket_ignite": (rocket_ignite, False, False),
    "rocket_loop": (rocket_loop, False, True),
    "rocket_land": (rocket_land, False, False),
    "door_open": (door_open, False, False),
    "door_close": (door_close, False, False),
    "tree_shake": (tree_shake, False, False),
    "splash": (splash, False, False),
    "emote_happy": (emote_happy, True, False),
    "emote_wave": (emote_wave, True, False),
    "dance_beat": (dance_beat, True, True),
    "text_advance": (text_advance, True, False),
    "shooting_star": (shooting_star, True, False),
}


def render(name):
    gen, stereo, loop = SFX[name]
    y = gen()
    if loop:
        # loops must stay exactly periodic: no trimming, no edge fades
        y = S.to_stereo(y) if stereo else S.to_mono(y)
        return S.remove_dc(S.normalize(y, -3.0)), True
    y = _trim(y)
    y = S.to_stereo(y) if stereo else S.to_mono(y)
    y = S.fade_edges(y, 0.003, 0.004)
    y = S.remove_dc(y)
    return S.normalize(y, -3.0), False
