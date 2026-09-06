"""Music loops for Astro Neighbor. Each track function returns (stereo, loop_len_samples, bpm).

All loops are rendered as loop + tail, then folded (synth.fold_loop) so that every release/reverb/delay
tail wraps around to the start of the loop -> seamless. Time-varying stereo effects (chorus) are snapped
to the loop period. Composition helpers keep everything on real chord progressions with written motifs.
"""
import math
import numpy as np
import synth as S
import instruments as I

TAIL_SEC = 4.0
NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def mname(m: int) -> str:
    return "%s%d" % (NAMES[m % 12], m // 12 - 1)

# --------------------------------------------------------------------------- composition helpers

class Prog:
    """Chord progression: list of (start_beat, length_beats, root, quality, bass_note_name_or_None)."""

    def __init__(self, chords, beats_per_chord=4.0):
        self.items = []
        b = 0.0
        for c in chords:
            if isinstance(c, tuple):
                sym, ln = c
            else:
                sym, ln = c, beats_per_chord
            root, q, bass = S.parse_chord(sym)
            self.items.append((b, ln, root, q, bass))
            b += ln
        self.total_beats = b

    def root_midi(self, i, octave=2):
        _, _, root, _, bass = self.items[i]
        return S.note_to_midi((bass or root) + str(octave))

    def tones(self, i, octave=4):
        _, _, root, q, _ = self.items[i]
        base = S.note_to_midi(root + str(octave))
        return [base + iv for iv in S.CHORD_INTERVALS[q]]


def voice_chord(prog, i, center=64, max_notes=4, drop_root=False):
    """Close voicing of chord i around `center` midi. Returns list of midi numbers."""
    tones = prog.tones(i, 4)
    if len(tones) > max_notes:
        # prefer 3rd, 7th, 9th, root over the 5th
        tones = [t for k, t in enumerate(tones) if k != 2][:max_notes]
    if drop_root and len(tones) > 3:
        tones = tones[1:]
    out = []
    for t in tones:
        m = t
        while m < center - 6:
            m += 12
        while m >= center + 6:
            m -= 12
        out.append(m)
    return sorted(set(out))


def comp(prog, hits, center=64, vel=0.7, max_notes=4, drop_root=False):
    """Chord stabs. hits = [(offset_beats_in_chord, dur), ...]; repeats per chord."""
    notes = []
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        voicing = voice_chord(prog, i, center, max_notes, drop_root)
        for off, dur in hits:
            if off >= ln:
                continue
            for m in voicing:
                notes.append((start + off, min(dur, ln - off), mname(m), vel))
    return notes


def sustain_chords(prog, center=60, vel=0.6, max_notes=4, overlap=0.0):
    notes = []
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        for m in voice_chord(prog, i, center, max_notes):
            notes.append((start, ln + overlap, mname(m), vel))
    return notes


def bass_root_fifth(prog, octave=2, vel=0.9, pattern=((0.0, 1.5), (2.0, 1.0), (3.0, 0.5))):
    """Root on 1, fifth on 3, approach on 4 (only when the chord changes)."""
    notes = []
    n = len(prog.items)
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        r = prog.root_midi(i, octave)
        nxt = prog.root_midi((i + 1) % n, octave)
        fifth = r + 7 if q not in ("dim7", "m7b5") else r + 6
        for k, (off, dur) in enumerate(pattern):
            if off >= ln:
                continue
            if k == 0:
                m = r
            elif k == 1:
                m = fifth if fifth < r + 12 else fifth - 12
            else:
                if nxt == r:
                    m = r + 12 if r + 12 < 52 else r
                else:
                    m = nxt - 1 if nxt > r else nxt + 1
                    if abs(m - r) > 7:
                        m = fifth - 12 if fifth - 12 > 24 else fifth
            notes.append((start + off, dur, mname(m), vel if k == 0 else vel * 0.85))
    return notes


def walking_bass(prog, octave=2, vel=0.85):
    """Quarter-note walking line: root, 3rd, 5th, chromatic approach to the next root."""
    notes = []
    n = len(prog.items)
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        r = prog.root_midi(i, octave)
        third = r + (3 if q.startswith("m") or q == "dim7" else 4)
        fifth = r + (6 if q in ("dim7", "m7b5") else 7)
        nxt = prog.root_midi((i + 1) % n, octave)
        if nxt == r:
            appr = r + 12 if i % 2 == 0 else fifth
        else:
            appr = nxt - 1 if (i % 2 == 0) else nxt + 1
            if appr > r + 9:
                appr -= 12
        steps = [r, third, fifth, appr]
        beat = 0.0
        k = 0
        while beat < ln:
            m = steps[k % 4]
            if m < 28:
                m += 12
            notes.append((start + beat, 0.95, mname(m), vel * (1.0 if k % 2 == 0 else 0.85)))
            beat += 1.0
            k += 1
    return notes


def bass_octave_pump(prog, octave=2, vel=0.9, grid=0.5):
    """Dance bass: root / octave alternating 8ths."""
    notes = []
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        r = prog.root_midi(i, octave)
        beat = 0.0
        k = 0
        while beat < ln - 1e-6:
            m = r if k % 2 == 0 else r + 12
            notes.append((start + beat, grid * 0.9, mname(m), vel * (1.0 if k % 2 == 0 else 0.8)))
            beat += grid
            k += 1
    return notes


def arpeggio(prog, pattern, octave=4, grid=0.5, vel=0.6, dur=None, center=None):
    """pattern = chord-tone indices (0=root,1=3rd,2=5th,3=7th,... ; +10 = up an octave, -1 = rest)."""
    notes = []
    for i, (start, ln, root, q, bass) in enumerate(prog.items):
        tones = prog.tones(i, octave)
        if center is not None:
            tones = voice_chord(prog, i, center, 4)
        beat = 0.0
        k = 0
        while beat < ln - 1e-6:
            idx = pattern[k % len(pattern)]
            if idx >= 0:
                octs = idx // 10
                j = idx % 10
                m = tones[j % len(tones)] + 12 * (j // len(tones)) + 12 * octs
                notes.append((start + beat, dur or grid * 1.1, mname(m), vel))
            beat += grid
            k += 1
    return notes


def pattern_bars(bar_text, bars, beats_per_bar=4.0, fills=None, default_vel=0.9):
    """Repeat a 1-bar drum/notation string across `bars` bars. fills: {bar_index: text} overrides."""
    notes = []
    for b in range(bars):
        txt = (fills or {}).get(b, bar_text)
        notes += S.parse_seq(txt, default_vel=default_vel, start_beat=b * beats_per_bar)
    return notes


def accent(notes, beats_per_bar=4.0, down=1.0, mid=0.94, beat=0.88, off=0.83):
    """Musical phrasing: strongest on beat 1, then beat 3, other beats, then off-beats."""
    out = []
    for b, d, p, v in notes:
        pos = b % beats_per_bar
        if abs(pos) < 1e-6:
            k = down
        elif abs(pos - beats_per_bar / 2.0) < 1e-6:
            k = mid
        elif abs(pos - round(pos)) < 1e-6:
            k = beat
        else:
            k = off
        out.append((b, d, p, v * k))
    return out


def melody(text, bars, beats_per_bar=4.0, vel=0.9, start=0.0, accents=True):
    notes = S.parse_seq(text, default_vel=vel, start_beat=start)
    if accents:
        notes = accent(notes, beats_per_bar)
    # rests count in seq length via parse
    exp = bars * beats_per_bar
    total = 0.0
    for tok in text.replace("|", " ").split():
        t = tok.split("@")[0]
        total += float(t.split(":")[1]) if ":" in t else 1.0
    assert abs(total - exp) < 1e-6, "melody length %.2f != %.2f beats" % (total, exp)
    return notes


STEM_STATS = {}   # track name -> [(stem name, rms_db, peak_db)] filled by stereo_of for the build report


def stereo_of(parts, L, tail, bpm, track=""):
    """Render part dicts into one stereo buffer of L + tail samples."""
    n_total = L + tail
    out = np.zeros((2, n_total))
    stats = STEM_STATS.setdefault(track, [])
    del stats[:]
    for p in parts:
        buf = S.render_notes(
            p["notes"], p["inst"], bpm, n_total, swing=p.get("swing", 0.0), swing_grid=p.get("swing_grid", 0.5),
            gain=S.db(p.get("db", 0.0)), pan_pos=p.get("pan", 0.0), pan_by_pitch=p.get("pan_by_pitch", 0.0),
            humanize_ms=p.get("humanize_ms", 0.0), humanize_vel=p.get("humanize_vel", 0.0), seed=p.get("seed", 1))
        if "hp" in p:
            buf = S.highpass(buf, p["hp"])
        if "lp" in p:
            buf = S.lowpass(buf, p["lp"])
        if p.get("chorus"):
            c = p["chorus"]
            buf = S.chorus(buf, c.get("rate", 0.8), c.get("depth", 2.5), c.get("base", 14.0), c.get("mix", 0.4), loop_len=L)
        if p.get("delay"):
            d = p["delay"]
            buf = S.delay(buf, d["time"], d.get("fb", 0.35), d.get("mix", 0.25), d.get("damp", 4000.0),
                          d.get("pingpong", False), d.get("spread", 0.0))
        if p.get("rev", 0.0) > 0.0:
            buf = S.reverb(buf, room=p.get("room", 0.78), damp=p.get("damp", 0.45), wet=p["rev"],
                           tone=p.get("tone", 6500.0), predelay=p.get("predelay", 0.012))
        if p.get("duck") is not None:
            buf = buf * p["duck"][None, :n_total]
        stats.append((p.get("name", getattr(p["inst"], "__name__", "inst")), S.to_db(S.rms(buf[:, :L])), S.to_db(S.peak(buf))))
        out += buf
    return out


def finish(mix, L, lp=14000.0, peak_db=-1.0, warmth_db=1.5, air_db=0.0):
    """Master: gentle lowpass for warmth, low-shelf body, fold to loop, soft clip, normalise."""
    m = S.lowpass(mix, lp, 0.6)
    if warmth_db:
        m = S.lowshelf(m, 180.0, warmth_db)
    if air_db:
        m = S.highshelf(m, 9000.0, air_db)
    m = S.fold_loop(m, L)
    m = S.remove_dc(m)
    m = S.normalize(m, -0.5)
    m = S.soft_clip(m, 0.82)
    return S.normalize(m, peak_db)


def loop_samples(bpm, bars, beats_per_bar=4.0):
    """Loop length snapped to a whole number of QOA frames (Godot decodes/loops per 5120-sample frame);
    returns (samples, effective_bpm). The tempo nudge is < 0.2 %."""
    want = bars * beats_per_bar * 60.0 / bpm * S.SR
    L = int(round(want / S.QOA_FRAME)) * S.QOA_FRAME
    return L, bars * beats_per_bar * 60.0 * S.SR / L


def sidechain(bpm, n_total, beats_per_bar=4.0, depth=0.55, attack_beats=0.02, release_beats=0.45, every=1.0):
    """Periodic pumping envelope aligned to the beat (for dance pads/bass)."""
    spb = 60.0 / bpm
    t = S.times(n_total)
    ph = (t / (spb * every)) % 1.0
    env = np.ones(n_total)
    rel = release_beats / every
    att = attack_beats / every
    dip = np.where(ph < att, 1.0 - depth * (ph / att), 1.0 - depth * np.clip(1.0 - (ph - att) / rel, 0.0, 1.0))
    env = np.minimum(env, dip)
    return env


def pan_alt(notes, spread=0.25):
    """Give a note list alternating pan values by turning it into two lists."""
    left = [n for k, n in enumerate(notes) if k % 2 == 0]
    right = [n for k, n in enumerate(notes) if k % 2 == 1]
    return left, right

# =========================================================================== TRACKS

def track_meadow_day():
    """Sunny F-major stroll. Marimba lead with a flute answer, e-piano comping, upright bass, brushed kit."""
    bpm, bars = 118.0, 16
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["F", "C/E", "Dm7", "Bb", "F", "Am7", "Bb", "C7",
                 "Gm7", "C7", "Am7", "Dm7", "Bb", "Bbm", "F/C", "C7"])
    lead = melody(
        "C5:0.5 F5:0.5 A5:1.5 G5:0.5 F5:1 | G5:0.5 E5:0.5 C5:1.5 D5:0.5 E5:1 | "
        "F5:0.5 A5:0.5 D6:1.5 C6:0.5 A5:1 | Bb5:0.5 A5:0.5 G5:1 F5:1.5 r:0.5 | "
        "C5:0.5 F5:0.5 A5:1.5 G5:0.5 F5:1 | G5:0.5 A5:0.5 C6:1.5 A5:0.5 G5:1 | "
        "F5:0.5 G5:0.5 A5:1 Bb5:0.5 C6:0.5 D6:1 | E6:0.5 D6:0.5 C6:1 G5:1 r:1 | "
        "D6:1 Bb5:0.5 A5:0.5 G5:1 A5:0.5 Bb5:0.5 | C6:1 E6:0.5 D6:0.5 C6:1 G5:1 | "
        "A5:0.5 C6:0.5 E6:1.5 D6:0.5 C6:1 | D6:1 C6:0.5 A5:0.5 F5:1 A5:1 | "
        "Bb5:0.5 C6:0.5 D6:1.5 C6:0.5 Bb5:1 | Db6:0.5 C6:0.5 Bb5:1 Ab5:0.5 Bb5:0.5 F5:1 | "
        "A5:1 G5:0.5 F5:0.5 G5:1 A5:1 | Bb5:0.5 A5:0.5 G5:1 E5:1 r:1", bars, vel=0.95)
    # flute answers in bars 9-12 (a third above / counter line)
    flute_line = S.parse_seq(
        "r:1 D6:1 C6:0.5 Bb5:0.5 A5:1 | r:1 G5:1 E5:1 r:1 | r:1 E6:1 C6:0.5 D6:0.5 E6:1 | F6:1 E6:0.5 D6:0.5 C6:2",
        default_vel=0.7, start_beat=32.0)
    # vibraphone sparkle: rising arps in bars 5-8 and 13-16
    vib = []
    for bar in (4, 5, 6, 7, 12, 13, 14, 15):
        i = bar
        tones = voice_chord(prog, i, 76, 4)
        for k, m in enumerate(tones):
            vib.append((bar * 4 + 2.0 + 0.5 * k, 1.2, mname(m), 0.55))
    ep = comp(prog, [(1.5, 1.0), (3.5, 0.75)], center=64, vel=0.6, max_notes=4)
    ep2 = comp(prog, [(0.0, 0.4)], center=64, vel=0.35, max_notes=3)
    bass = bass_root_fifth(prog, octave=2, vel=0.9)
    pad_notes = sustain_chords(prog, center=57, vel=0.5, max_notes=3, overlap=0.2)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    drums = pattern_bars("kick:1@0.9 rim:1@0.6 kick:1@0.8 rim:1@0.65", bars,
                         fills={7: "kick:1@0.9 rim:0.5@0.6 rim:0.5@0.5 kick:1@0.8 rim:0.5@0.7 kick:0.5@0.8",
                                15: "kick:1@0.9 rim:1@0.6 kick:0.5@0.8 kick:0.5@0.7 rim:0.5@0.7 rim:0.5@0.8"})
    hats = pattern_bars("hat:0.5@0.8 hat:0.5@0.45 hat:0.5@0.7 hat:0.5@0.45 hat:0.5@0.8 hat:0.5@0.45 hat:0.5@0.7 ohat:0.5@0.5", bars)
    shak = pattern_bars("shaker:0.25@0.5 shaker:0.25@0.3 shaker:0.25@0.4 shaker:0.25@0.3 " * 4, bars)
    parts = [
        dict(notes=lead, inst=I.marimba, db=-4.0, swing=0.2, pan=0.08, pan_by_pitch=0.08, rev=0.22, humanize_ms=4, humanize_vel=0.05),
        dict(notes=flute_line, inst=I.flute, db=-9.0, swing=0.2, pan=-0.25, rev=0.3, room=0.85),
        dict(notes=vib, inst=I.vibraphone, db=-13.0, swing=0.2, pan=0.35, rev=0.35, room=0.85),
        dict(notes=ep, inst=I.epiano, db=-13.0, swing=0.2, pan=-0.2, chorus=dict(rate=0.6, depth=2.0, mix=0.35), rev=0.18),
        dict(notes=ep2, inst=I.epiano, db=-16.0, pan=-0.2, rev=0.18),
        dict(notes=bass, inst=I.bass_soft, db=-9.5, swing=0.2, pan=0.0, lp=1200.0),
        dict(notes=pad_notes, inst=I.pad, db=-17.0, pan=0.0, chorus=dict(rate=0.35, depth=3.0, mix=0.5), rev=0.3),
        dict(notes=drums, inst=kit, db=-6.5, swing=0.2, pan=0.0, rev=0.08),
        dict(notes=hats, inst=kit, db=-3.0, swing=0.2, pan=0.3, rev=0.1),
        dict(notes=shak, inst=kit, db=-8.0, swing=0.1, swing_grid=0.25, pan=-0.35),
    ]
    mix = stereo_of(parts, L, tail, bpm, "meadow_day")
    return finish(mix, L, lp=15000.0, warmth_db=1.0, air_db=1.5), L, bpm


def track_meadow_night():
    """Slow D-major lullaby: music box melody, soft pad, sub bass, firefly glockenspiel, whisper shaker."""
    bpm, bars = 72.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Dmaj7", "A/C#", "Bm7", "F#m7", "Gmaj7", "D/F#", "Em7", "A7sus"])
    lead = melody(
        "F#5:1 A5:1 D6:1.5 C#6:0.5 | E6:1 C#6:1 A5:2 | B5:1 D6:1 F#6:1.5 E6:0.5 | C#6:1 A5:1 F#5:2 | "
        "G5:1 B5:1 D6:1.5 E6:0.5 | F#6:1 D6:1 A5:2 | G5:1 B5:1 E6:1 D6:1 | D6:1 B5:1 A5:1 E5:1", bars, vel=0.8)
    # music-box accompaniment: broken chords in 8ths, an octave below
    acc = arpeggio(prog, [0, 2, 3, 2, 1, 2, 3, 2], octave=4, grid=0.5, vel=0.42, dur=0.9, center=64)
    bass = []
    for i, (start, ln, root, q, b) in enumerate(prog.items):
        bass.append((start, 3.6, mname(prog.root_midi(i, 2)), 0.8))
    pad_notes = sustain_chords(prog, center=59, vel=0.5, max_notes=4, overlap=0.5)
    fire = S.parse_seq("r:7.5 A6:0.5@0.5 r:7 D7:0.5@0.4 r:0.5 r:5.5 F#6:0.5@0.5 r:1 A6:0.5@0.4 r:0.5 r:7 E7:0.5@0.35 r:0.5",
                       default_vel=0.5)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    shak = pattern_bars("r:1 shaker:1@0.5 r:1 shaker:1@0.4", bars)
    parts = [
        dict(notes=lead, inst=I.music_box, db=-5.0, pan=0.1, pan_by_pitch=0.1, rev=0.4, room=0.88, damp=0.3, tone=8000.0, humanize_ms=5),
        dict(notes=acc, inst=I.music_box, db=-14.0, pan=-0.3, pan_by_pitch=0.12, rev=0.35, room=0.88, humanize_ms=6, humanize_vel=0.08),
        dict(notes=bass, inst=I.bass_sub, db=-11.5, pan=0.0),
        dict(notes=pad_notes, inst=I.soft_pad, db=-13.0, pan=0.0, chorus=dict(rate=0.25, depth=3.5, mix=0.5), rev=0.35, room=0.9),
        dict(notes=fire, inst=I.glockenspiel, db=-16.0, pan=0.45, delay=dict(time=60.0 / bpm * 0.75, fb=0.4, mix=0.5, pingpong=True), rev=0.4),
        dict(notes=shak, inst=kit, db=-9.0, pan=-0.2),
    ]
    mix = stereo_of(parts, L, tail, bpm, "meadow_night")
    return finish(mix, L, lp=12000.0, warmth_db=2.0), L, bpm


def track_title():
    """Dreamy, hopeful C-lydian theme: vibraphone melody (whistle doubles the second half), e-piano arps, pad."""
    bpm, bars = 88.0, 12
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Cmaj7", "Fmaj7#11", "Em7", "Am7", "Dm7", "G7sus", "Cmaj7", "Fmaj7#11", "Am7", "Em7", "Fmaj7", "G7sus"])
    theme = ("E5:1.5 G5:0.5 C6:2 | B5:1 A5:1 F5:1.5 G5:0.5 | G5:2 B5:1 E6:1 | C6:1.5 B5:0.5 A5:2 | "
             "F5:1 A5:1 D6:1.5 C6:0.5 | A5:1 G5:1 D5:1 F5:0.5 G5:0.5 | "
             "E5:1.5 G5:0.5 C6:1.5 D6:0.5 | E6:1 B5:1 A5:1.5 G5:0.5 | A5:2 C6:1 E6:1 | B5:1.5 G5:0.5 E5:2 | "
             "A5:1 C6:1 E6:1.5 F6:0.5 | D6:1.5 C6:0.5 G5:1 D5:1")
    lead = melody(theme, bars, vel=0.85)
    whistle_line = [n for n in melody(theme, bars, vel=0.6) if n[0] >= 24.0]
    arp = arpeggio(prog, [0, 2, 3, 12, 3, 2, 1, 2], octave=3, grid=0.5, vel=0.5, dur=0.8)
    bass = []
    for i, (start, ln, root, q, b) in enumerate(prog.items):
        r = prog.root_midi(i, 2)
        bass.append((start, 2.4, mname(r), 0.85))
        bass.append((start + 2.5, 1.4, mname(r + 7 if r + 7 < 48 else r - 5), 0.6))
    pad_notes = sustain_chords(prog, center=62, vel=0.55, max_notes=4, overlap=0.3)
    glock_echo = [(b, d, S.transpose(p, 12), v * 0.5) for b, d, p, v in lead if d >= 1.5]
    star = S.parse_seq("r:30 G6:0.25@0.5 A6:0.25@0.5 B6:0.25@0.5 D7:0.25@0.5 E7:0.25@0.5 G7:0.25@0.5 r:16.5", default_vel=0.5)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    hats = pattern_bars("r:1 hat:0.5@0.5 r:0.5 r:1 hat:0.5@0.45 shaker:0.5@0.4", bars)
    parts = [
        dict(notes=lead, inst=I.vibraphone, db=-5.0, pan=0.05, pan_by_pitch=0.08, rev=0.35, room=0.9, humanize_ms=6),
        dict(notes=whistle_line, inst=I.whistle, db=-12.0, pan=-0.2, rev=0.35, room=0.9),
        dict(notes=arp, inst=I.epiano, db=-12.0, pan=0.0, pan_by_pitch=0.25, chorus=dict(rate=0.5, depth=2.5, mix=0.4),
             delay=dict(time=60.0 / bpm * 0.75, fb=0.25, mix=0.2, spread=0.011), rev=0.25, humanize_vel=0.06),
        dict(notes=bass, inst=I.bass_soft, db=-10.5, lp=1000.0),
        dict(notes=pad_notes, inst=I.pad, db=-15.0, chorus=dict(rate=0.3, depth=3.0, mix=0.5), rev=0.35, room=0.9),
        dict(notes=glock_echo, inst=I.glockenspiel, db=-19.0, pan=0.4, delay=dict(time=60.0 / bpm * 0.5, fb=0.35, mix=0.6, pingpong=True), rev=0.4),
        dict(notes=star, inst=I.glockenspiel, db=-15.0, pan=-0.3, delay=dict(time=60.0 / bpm * 0.375, fb=0.4, mix=0.5, pingpong=True), rev=0.45),
        dict(notes=hats, inst=kit, db=-6.0, pan=0.25, rev=0.1),
    ]
    mix = stereo_of(parts, L, tail, bpm, "title")
    return finish(mix, L, lp=14000.0, warmth_db=1.0, air_db=1.0), L, bpm


def track_violet():
    """Zorp's planet: E-minor pentatonic mystery. Theremin lead with glides, kalimba ostinato, congas, shimmer pad."""
    bpm, bars = 100.0, 12
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Em9", "Cmaj7", "Am7", "Bm7", "Em9", "Cmaj7", "Am7", "D6", "Cmaj7", "Bm7", "Am7", "B7sus"])
    lead = melody(
        "E5:2 G5:1 B5:1 | A5:2.5 G5:0.5 E5:1 | r:1 A5:1.5 G5:0.5 E5:1 | D5:2 F#5:2 | "
        "E5:1.5 G5:0.5 B5:2 | D6:1.5 B5:0.5 A5:1 G5:1 | E5:2 G5:1 A5:1 | B5:2 A5:1 F#5:1 | "
        "G5:1.5 E5:0.5 C5:1 E5:1 | D5:2 B4:1 D5:1 | E5:1.5 G5:0.5 A5:2 | B5:1.5 A5:0.5 F#5:1 r:1", bars, vel=0.8)
    # kalimba ostinato on pentatonic chord tones (8ths with a syncopated skip)
    kal = arpeggio(prog, [0, 2, 3, -1, 2, 12, 3, 2], octave=4, grid=0.5, vel=0.5, dur=0.6, center=67)
    kal2 = arpeggio(prog, [-1, 10, -1, 2, -1, 3, -1, 12], octave=4, grid=0.5, vel=0.35, dur=0.6, center=79)
    bass = []
    for i, (start, ln, root, q, b) in enumerate(prog.items):
        r = prog.root_midi(i, 2)
        bass.append((start, 2.4, mname(r), 0.85))
        bass.append((start + 2.5, 0.4, mname(r), 0.5))
        bass.append((start + 3.0, 0.9, mname(r + 7 if r + 7 < 47 else r - 5), 0.6))
    pad_notes = sustain_chords(prog, center=60, vel=0.5, max_notes=4, overlap=0.4)
    shim = [(start, ln + 0.5, mname(prog.root_midi(i, 4)), 0.5) for i, (start, ln, *_r) in enumerate(prog.items)]
    blips = S.parse_seq("r:7.5 B6:0.5@0.6 r:7.5 E7:0.5@0.5 r:7 G6:0.5@0.5 r:0.5 r:7.5 D7:0.5@0.5 r:7.5 B6:0.5@0.5 r:7.5 A6:0.5@0.5", default_vel=0.5)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    drums = pattern_bars("kick:1@0.8 r:0.5 conga_hi:0.5@0.7 conga_lo:1@0.7 r:0.5 conga_hi:0.5@0.6", bars,
                         fills={11: "kick:1@0.8 conga_hi:0.5@0.7 conga_hi:0.5@0.6 conga_lo:0.5@0.7 conga_lo:0.5@0.6 conga_hi:0.5@0.7 r:0.5"})
    shak = pattern_bars("shaker:0.5@0.55 shaker:0.5@0.35 " * 4, bars)
    parts = [
        dict(notes=lead, inst=I.theremin, db=-6.0, pan=0.1, rev=0.35, room=0.9, delay=dict(time=60.0 / bpm * 0.75, fb=0.3, mix=0.25, pingpong=True)),
        dict(notes=kal, inst=I.kalimba, db=-13.0, pan=-0.3, pan_by_pitch=0.15, rev=0.3, room=0.85, humanize_ms=5, humanize_vel=0.06),
        dict(notes=kal2, inst=I.kalimba, db=-16.0, pan=0.4, rev=0.35, room=0.9),
        dict(notes=bass, inst=I.bass_sub, db=-10.5),
        dict(notes=pad_notes, inst=I.soft_pad, db=-13.0, chorus=dict(rate=0.3, depth=4.0, mix=0.5), rev=0.35, room=0.92),
        dict(notes=shim, inst=I.shimmer, db=-15.0, pan=0.0, chorus=dict(rate=0.2, depth=5.0, mix=0.6), rev=0.4, room=0.92),
        dict(notes=blips, inst=I.blip, db=-9.0, pan=0.5, delay=dict(time=60.0 / bpm * 0.5, fb=0.45, mix=0.6, pingpong=True), rev=0.3),
        dict(notes=drums, inst=kit, db=-10.0, pan=0.0, rev=0.15, humanize_ms=4),
        dict(notes=shak, inst=kit, db=-9.0, pan=-0.4),
    ]
    mix = stereo_of(parts, L, tail, bpm, "violet")
    return finish(mix, L, lp=13000.0, warmth_db=2.0), L, bpm


def track_chrome():
    """Bolt's planet: chiptune-meets-jazz in G. Pulse lead, chip arps, square bass, swung chip kit, e-piano color."""
    bpm, bars = 124.0, 16
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Gmaj7", "E7", "Am7", "D7", "Gmaj7", "G7", "Cmaj7", "C#dim7",
                 "G/D", "E7", "Am7", "D7", "Bm7", "E7", "Am7", "D7"])
    lead = melody(
        "D5:0.5 G5:0.5 B5:0.5 D6:0.5 B5:1 G5:1 | G#5:0.5 B5:0.5 E6:1 D6:0.5 B5:0.5 G#5:1 | "
        "A5:0.5 C6:0.5 E6:1 D6:0.5 C6:0.5 A5:1 | F#5:0.5 A5:0.5 C6:1 A5:0.5 F#5:0.5 D5:1 | "
        "D5:0.5 G5:0.5 B5:0.5 D6:0.5 B5:1 G5:1 | F5:0.5 D5:0.5 B4:1 D5:0.5 F5:0.5 G5:1 | "
        "E5:0.5 G5:0.5 C6:1.5 B5:0.5 G5:1 | E5:0.5 G5:0.5 Bb5:1 C#6:0.5 Bb5:0.5 G5:1 | "
        "D6:1 B5:0.5 G5:0.5 D5:1 G5:1 | G#5:0.5 B5:0.5 D6:1 E6:0.5 D6:0.5 B5:1 | "
        "C6:1 A5:0.5 E5:0.5 G5:1 A5:1 | F#5:0.5 A5:0.5 C6:1 D6:0.5 C6:0.5 A5:1 | "
        "D6:1 F#6:0.5 D6:0.5 B5:1 A5:1 | G#5:0.5 B5:0.5 E6:1 D6:0.5 B5:0.5 G#5:1 | "
        "A5:0.5 C6:0.5 E6:1 G6:1 E6:1 | D6:0.5 C6:0.5 A5:1 F#5:1 r:1", bars, vel=0.85)
    arp = arpeggio(prog, [0, 1, 2, 3, 10, 3, 2, 1], octave=4, grid=0.25, vel=0.4, dur=0.22, center=72)
    bass = []
    n = len(prog.items)
    for i, (start, ln, root, q, b) in enumerate(prog.items):
        r = prog.root_midi(i, 2)
        nxt = prog.root_midi((i + 1) % n, 2)
        fifth = r + 7 if r + 7 < 48 else r - 5
        appr = (nxt - 1 if nxt > r else nxt + 1) if nxt != r else r + 12
        for off, m, v in ((0.0, r, 0.9), (0.75, r + 12, 0.6), (1.5, r, 0.8), (2.0, fifth, 0.85), (2.75, fifth + 12 if fifth + 12 < 55 else fifth, 0.55), (3.5, appr, 0.8)):
            bass.append((start + off, 0.45, mname(m), v))
    ep = comp(prog, [(1.5, 0.8), (3.5, 0.4)], center=64, vel=0.55, max_notes=4)
    kit = I.drumkit(I.KIT_CHIP)
    drums = pattern_bars("kick:1@0.9 snare:1@0.7 kick:0.5@0.8 kick:0.5@0.6 snare:1@0.75", bars,
                         fills={7: "kick:1@0.9 snare:0.5@0.7 snare:0.5@0.6 kick:1@0.8 snare:0.5@0.7 snare:0.5@0.8",
                                15: "kick:0.5@0.9 kick:0.5@0.7 snare:1@0.7 kick:1@0.8 snare:0.5@0.7 snare:0.5@0.9"})
    hats = pattern_bars("hat:0.5@0.8 hat:0.5@0.5 hat:0.5@0.7 hat:0.5@0.5 hat:0.5@0.8 hat:0.5@0.5 hat:0.5@0.7 ohat:0.5@0.6", bars)
    parts = [
        dict(notes=lead, inst=I.chip_pulse, db=-7.0, swing=0.25, pan=0.05, rev=0.18, room=0.7, delay=dict(time=60.0 / bpm * 0.75, fb=0.2, mix=0.18, pingpong=True)),
        dict(notes=arp, inst=I.chip_thin, db=-11.0, swing=0.12, swing_grid=0.25, pan=-0.35, pan_by_pitch=0.2, rev=0.2),
        dict(notes=bass, inst=I.chip_bass, db=-4.0, swing=0.25, swing_grid=0.25, pan=0.0),
        dict(notes=ep, inst=I.epiano, db=-15.0, swing=0.25, pan=0.3, chorus=dict(rate=0.7, depth=2.0, mix=0.35), rev=0.2),
        dict(notes=drums, inst=kit, db=-5.0, swing=0.25, pan=0.0, rev=0.08),
        dict(notes=hats, inst=kit, db=-3.0, swing=0.25, pan=0.3, rev=0.08),
    ]
    mix = stereo_of(parts, L, tail, bpm, "chrome")
    return finish(mix, L, lp=15000.0, warmth_db=0.5, air_db=1.0), L, bpm


def track_hub():
    """Starport Plaza: bustling D-major swing. Marimba melody + glock doubling, walking bass, e-piano, brush kit."""
    bpm, bars = 120.0, 16
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["D", "Bm7", "Em7", "A7", "D", "D7", "G", "Gm6",
                 "D/F#", "B7", "Em7", "A7", "Gmaj7", "F#m7", "Em7", "A7"])
    lead = melody(
        "A4:0.5 D5:0.5 F#5:1 A5:1 F#5:0.5 D5:0.5 | B4:0.5 D5:0.5 F#5:1.5 E5:0.5 D5:1 | "
        "E5:0.5 G5:0.5 B5:1 A5:0.5 G5:0.5 E5:1 | C#5:0.5 E5:0.5 G5:1 A5:0.5 G5:0.5 E5:1 | "
        "A4:0.5 D5:0.5 F#5:1 A5:1 B5:0.5 A5:0.5 | C6:0.5 A5:0.5 F#5:1 D5:0.5 F#5:0.5 A5:1 | "
        "B5:1 G5:0.5 A5:0.5 B5:1 D6:1 | Bb5:1 G5:0.5 A5:0.5 Bb5:1 E5:1 | "
        "F#5:0.5 A5:0.5 D6:1.5 C#6:0.5 A5:1 | D#5:0.5 F#5:0.5 A5:1 B5:0.5 A5:0.5 F#5:1 | "
        "E5:0.5 G5:0.5 B5:1.5 A5:0.5 G5:1 | C#6:0.5 B5:0.5 A5:1 G5:0.5 E5:0.5 C#5:1 | "
        "B5:1 A5:0.5 B5:0.5 D6:1 F#6:1 | E6:0.5 C#6:0.5 A5:1 F#5:0.5 A5:0.5 C#6:1 | "
        "B5:0.5 G5:0.5 E5:1 G5:0.5 B5:0.5 D6:1 | C#6:0.5 A5:0.5 E5:1 G5:1 r:1", bars, vel=0.9)
    glock = [(b, d, S.transpose(p, 12), v * 0.45) for b, d, p, v in lead if b >= 32.0]
    bass = walking_bass(prog, octave=2, vel=0.85)
    ep = comp(prog, [(1.5, 0.9), (2.5, 0.4), (3.5, 0.9)], center=63, vel=0.55, max_notes=4)
    vib = comp(prog, [(0.0, 3.5)], center=72, vel=0.35, max_notes=3, drop_root=True)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    drums = pattern_bars("kick:1@0.85 snare:1@0.6 kick:1@0.75 snare:1@0.65", bars,
                         fills={7: "kick:1@0.85 snare:0.5@0.6 snare:0.5@0.5 kick:1@0.75 snare:0.5@0.7 snare:0.5@0.8",
                                15: "kick:1@0.85 snare:1@0.6 kick:0.5@0.75 kick:0.5@0.6 snare:0.5@0.7 clap:0.5@0.6"})
    hats = pattern_bars("hat:0.5@0.85 hat:0.5@0.5 hat:0.5@0.75 hat:0.5@0.5 hat:0.5@0.85 hat:0.5@0.5 hat:0.5@0.75 ohat:0.5@0.55", bars)
    shak = pattern_bars("shaker:0.25@0.5 shaker:0.25@0.3 shaker:0.25@0.45 shaker:0.25@0.3 " * 4, bars)
    wood = pattern_bars("r:2.5 wood:0.5@0.5 r:1", bars)
    parts = [
        dict(notes=lead, inst=I.marimba, db=-4.0, swing=0.22, pan=0.05, pan_by_pitch=0.08, rev=0.22, humanize_ms=4, humanize_vel=0.05),
        dict(notes=glock, inst=I.glockenspiel, db=-14.0, swing=0.22, pan=-0.3, rev=0.35),
        dict(notes=bass, inst=I.bass_soft, db=-9.5, lp=1100.0, humanize_vel=0.05),
        dict(notes=ep, inst=I.epiano, db=-14.0, swing=0.22, pan=-0.25, chorus=dict(rate=0.6, depth=2.0, mix=0.35), rev=0.2),
        dict(notes=vib, inst=I.vibraphone, db=-17.0, pan=0.35, rev=0.35, room=0.85),
        dict(notes=drums, inst=kit, db=-6.0, swing=0.22, rev=0.1),
        dict(notes=hats, inst=kit, db=-3.0, swing=0.22, pan=0.3, rev=0.1),
        dict(notes=shak, inst=kit, db=-8.0, swing=0.1, swing_grid=0.25, pan=-0.4),
        dict(notes=wood, inst=kit, db=-8.0, swing=0.22, pan=0.5, rev=0.2),
    ]
    mix = stereo_of(parts, L, tail, bpm, "hub")
    return finish(mix, L, lp=15000.0, warmth_db=1.0, air_db=1.5), L, bpm


def track_space():
    """Floaty E-lydian ambient: harp arpeggios through a dotted delay, shimmer bed, soft pad, sparse bell line."""
    bpm, bars = 66.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Emaj9", "Emaj9", "C#m9", "Amaj7#11", "Emaj9/G#", "F#m9", "Amaj7", "B6sus"])
    lead = melody(
        "B5:3 G#5:1 | F#5:2 E5:2 | E6:2.5 D#6:0.5 C#6:1 | r:1 D#6:1 E6:2 | "
        "B5:2 G#5:2 | A5:2 F#5:1 C#6:1 | E6:3 C#6:1 | F#6:1.5 E6:0.5 C#6:2", bars, vel=0.7)
    arp = arpeggio(prog, [0, 2, 3, 4, 12, 4, 3, 2], octave=4, grid=0.5, vel=0.5, dur=1.2, center=69)
    bass = [(start, ln + 0.3, mname(prog.root_midi(i, 2)), 0.8) for i, (start, ln, *_r) in enumerate(prog.items)]
    pad_notes = sustain_chords(prog, center=60, vel=0.55, max_notes=4, overlap=0.8)
    shim = [(start, ln + 1.0, mname(prog.root_midi(i, 4)), 0.5) for i, (start, ln, *_r) in enumerate(prog.items)]
    twinkle = S.parse_seq("r:6 B6:0.25@0.4 E7:0.25@0.4 r:9.5 G#6:0.25@0.4 B6:0.25@0.4 E7:0.25@0.4 r:7.25 D#7:0.25@0.35 r:7.75",
                          default_vel=0.4)
    pulse = pattern_bars("kick:1@0.35 r:1 kick:1@0.3 r:1", bars)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    parts = [
        dict(notes=lead, inst=I.bell, db=-9.0, pan=0.1, delay=dict(time=60.0 / bpm * 0.75, fb=0.35, mix=0.35, pingpong=True), rev=0.45, room=0.95, damp=0.3),
        dict(notes=arp, inst=I.harp, db=-10.0, pan=-0.2, pan_by_pitch=0.25, delay=dict(time=60.0 / bpm * 0.75, fb=0.45, mix=0.45, pingpong=True, damp=3500.0), rev=0.4, room=0.95, humanize_vel=0.08),
        dict(notes=bass, inst=I.bass_sub, db=-13.0),
        dict(notes=pad_notes, inst=I.soft_pad, db=-14.0, chorus=dict(rate=0.2, depth=5.0, mix=0.6), rev=0.45, room=0.95),
        dict(notes=shim, inst=I.shimmer, db=-11.0, chorus=dict(rate=0.15, depth=6.0, mix=0.7), rev=0.5, room=0.96),
        dict(notes=twinkle, inst=I.glockenspiel, db=-16.0, pan=0.4, delay=dict(time=60.0 / bpm * 0.5, fb=0.5, mix=0.6, pingpong=True), rev=0.5, room=0.95),
        dict(notes=pulse, inst=kit, db=-12.0, lp=300.0, rev=0.2),
    ]
    mix = stereo_of(parts, L, tail, bpm, "space")
    return finish(mix, L, lp=11000.0, warmth_db=2.0), L, bpm


def track_event():
    """Event space: light four-on-the-floor in A minor / C. Synth-pluck riff, pumping pad, octave bass, claps."""
    bpm, bars = 124.0, 16
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    n_total = L + tail
    prog = Prog(["Am7", "Fmaj7", "C", "G", "Am7", "Fmaj7", "C", "G",
                 "Dm7", "Em7", "Fmaj7", "G", "Am7", "Fmaj7", "C/E", "G"])
    riff_a = ("A5:0.25 r:0.25 A5:0.25 C6:0.25 E6:0.5 r:0.5 D6:0.25 C6:0.25 A5:0.5 r:0.5 G5:0.5 | "
              "A5:0.25 r:0.25 A5:0.25 C6:0.25 F6:0.5 r:0.5 E6:0.25 C6:0.25 A5:1 r:0.5 | "
              "G5:0.25 r:0.25 G5:0.25 C6:0.25 E6:0.5 r:0.5 G6:0.5 E6:0.5 C6:0.5 r:0.5 | "
              "D6:0.5 B5:0.5 G5:0.5 A5:0.5 B5:1 D6:0.5 r:0.5 | ")
    riff_b = ("A5:0.25 r:0.25 A5:0.25 C6:0.25 E6:0.5 r:0.5 D6:0.25 C6:0.25 A5:0.5 r:0.5 G5:0.5 | "
              "A5:0.25 r:0.25 A5:0.25 C6:0.25 F6:0.5 r:0.5 E6:0.25 C6:0.25 A5:1 r:0.5 | "
              "G5:0.25 r:0.25 G5:0.25 C6:0.25 E6:0.5 r:0.5 G6:0.5 E6:0.5 C6:0.5 r:0.5 | "
              "B5:0.5 D6:0.5 G6:0.5 F6:0.5 D6:1 B5:0.5 r:0.5 | ")
    riff_c = ("F5:0.25 r:0.25 F5:0.25 A5:0.25 D6:0.5 r:0.5 C6:0.25 A5:0.25 F5:0.5 r:0.5 E5:0.5 | "
              "G5:0.25 r:0.25 G5:0.25 B5:0.25 E6:0.5 r:0.5 D6:0.25 B5:0.25 G5:1 r:0.5 | "
              "A5:0.25 r:0.25 A5:0.25 C6:0.25 F6:0.5 r:0.5 E6:0.5 C6:0.5 A5:0.5 r:0.5 | "
              "B5:0.5 D6:0.5 G6:0.5 A6:0.5 B6:1 G6:0.5 r:0.5 | ")
    riff_d = ("A5:0.25 r:0.25 A5:0.25 C6:0.25 E6:0.5 r:0.5 D6:0.25 C6:0.25 A5:0.5 r:0.5 G5:0.5 | "
              "A5:0.25 r:0.25 A5:0.25 C6:0.25 F6:0.5 r:0.5 E6:0.25 C6:0.25 A5:1 r:0.5 | "
              "G5:0.25 r:0.25 G5:0.25 C6:0.25 E6:0.5 r:0.5 G6:0.5 E6:0.5 C6:0.5 r:0.5 | "
              "D6:0.5 B5:0.5 G5:0.5 F5:0.5 E5:0.5 D5:0.5 B4:0.5 r:0.5")
    riff = melody(riff_a + riff_b + riff_c + riff_d, bars, vel=0.85)
    lead = S.parse_seq("A5:1 C6:1 D6:1.5 E6:0.5 | G6:1 E6:1 D6:2 | C6:1 A5:1 F5:1.5 G5:0.5 | A5:1 B5:1 D6:1 B5:1",
                       default_vel=0.7, start_beat=32.0)
    ep = comp(prog, [(1.5, 0.4), (3.0, 0.4), (3.75, 0.25)], center=65, vel=0.6, max_notes=4)
    bass = bass_octave_pump(prog, octave=2, vel=0.9)
    pad_notes = sustain_chords(prog, center=62, vel=0.55, max_notes=4, overlap=0.1)
    kit = I.drumkit(I.KIT_DANCE)
    drums = pattern_bars("kick:1@0.95 kick:1@0.9 kick:1@0.95 kick:1@0.9", bars,
                         fills={15: "kick:1@0.95 kick:1@0.9 kick:0.5@0.95 kick:0.5@0.8 kick:0.5@0.9 kick:0.5@0.8"})
    claps = pattern_bars("r:1 clap:1@0.9 r:1 clap:1@0.9", bars, fills={15: "r:1 clap:1@0.9 r:1 clap:0.5@0.9 clap:0.5@0.8"})
    hats = pattern_bars("hat:0.5@0.5 ohat:0.5@0.7 hat:0.5@0.5 ohat:0.5@0.7 hat:0.5@0.5 ohat:0.5@0.7 hat:0.5@0.5 ohat:0.5@0.8", bars)
    shak = pattern_bars("shaker:0.25@0.5 shaker:0.25@0.3 shaker:0.25@0.4 shaker:0.25@0.3 " * 4, bars)
    duck = sidechain(bpm, n_total, depth=0.5, release_beats=0.5)
    parts = [
        dict(notes=riff, inst=I.synth_pluck, db=-8.0, pan=0.1, pan_by_pitch=0.1, delay=dict(time=60.0 / bpm * 0.75, fb=0.3, mix=0.28, pingpong=True), rev=0.2),
        dict(notes=lead, inst=I.chip_square, db=-9.0, pan=-0.15, rev=0.3, delay=dict(time=60.0 / bpm * 0.75, fb=0.3, mix=0.3, pingpong=True)),
        dict(notes=ep, inst=I.epiano, db=-14.0, pan=-0.3, chorus=dict(rate=0.8, depth=2.0, mix=0.35), rev=0.2),
        dict(notes=bass, inst=I.bass_synth, db=-3.0, duck=duck),
        dict(notes=pad_notes, inst=I.pad, db=-12.0, chorus=dict(rate=0.4, depth=3.0, mix=0.5), rev=0.3, duck=duck),
        dict(notes=drums, inst=kit, db=-9.0, rev=0.03),
        dict(notes=claps, inst=kit, db=0.0, pan=0.1, rev=0.25, room=0.7),
        dict(notes=hats, inst=kit, db=-5.0, pan=0.3, rev=0.08),
        dict(notes=shak, inst=kit, db=-9.0, pan=-0.4),
    ]
    mix = stereo_of(parts, L, tail, bpm, "event")
    return finish(mix, L, lp=15000.0, warmth_db=0.5, air_db=1.5), L, bpm


TRACKS = {
    "title": track_title,
    "meadow_day": track_meadow_day,
    "meadow_night": track_meadow_night,
    "violet": track_violet,
    "chrome": track_chrome,
    "hub": track_hub,
    "space": track_space,
    "event": track_event,
}
