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


def finish(mix, L, lp=14000.0, peak_db=-1.0, warmth_db=1.5, air_db=0.0, loop_begin=0):
    """Master: gentle lowpass for warmth, low-shelf body, fold to loop, soft clip, normalise.
    `loop_begin` > 0: the region [0:loop_begin] is a one-shot intro (e.g. a logo) that plays once;
    only [loop_begin:L] repeats -- see S.fold_loop_at."""
    m = S.lowpass(mix, lp, 0.6)
    if warmth_db:
        m = S.lowshelf(m, 180.0, warmth_db)
    if air_db:
        m = S.highshelf(m, 9000.0, air_db)
    m = S.fold_loop_at(m, loop_begin, L) if loop_begin else S.fold_loop(m, L)
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


# =========================================================================== TITLE: "SIGNAL"
#
# WHY THE TITLE WAS REPLACED. The user: the jingle at the start of the game sounds like Animal Crossing,
# and the game must not get called a rip-off. Measured on the old track (kept as track_title_legacy,
# for A/B and rollback only -- delete it once a variant is chosen):
#   * timbre: a VIBRAPHONE lead (a struck bar with 4.6 Hz motor tremolo), a WHISTLE doubling the second
#     half of the tune, GLOCKENSPIEL octave echoes and a six-note glock "star" run. Mallets and a whistle
#     are the biggest single AC tell.
#   * rhythm: an e-piano arpeggio in continuous 8ths (2.93 onsets/s on its own), hat + shaker on the
#     off-beats and a two-beat bass (root on 1, fifth on 3): 7.8 note onsets per second in all.
#   * melody: dotted-quarter/eighth lilts ("E5:1.5 G5:0.5 C6:2") leaping round a C-major triad in the
#     5th and 6th octaves; E, C and G are 139 of the 255 pitched notes. A bright major hook, 88 bpm.
# The replacement is a sonic logo -- a short motif that reads as a transmission arriving from far off --
# over a bed with no drums, no mallets, no whistle and no hook: an analog pad, a sub, slow analog
# arpeggios and faint radio noise. Three takes, one line apart (TITLE_VARIANT, just above TRACKS at the
# end of the file); the user picks by ear, because no agent can listen.
#
# LOOP AND MOTIF TIMING. build_all writes every music loop from sample 0, so the title is ONE loop and
# the motif comes round again every loop (~27-30 s), like a beacon. Playing it only once would need a
# loop START in the smpl chunk (synth.write_wav always writes 0); Godot's WAV importer does read one.
# AudioManager fades music in from -40 dB over 1.5 s (TRANS_SINE, ease in-out). Captured in-engine that
# is -30 dB at 0.3 s, -20 dB at 0.6 s, -10 dB at 0.9 s and 0 dB from 1.3 s, so no motif note starts
# before 1.39 s: a ping at 0.3 s would be heard 30 dB down. Everything before it is bed that fades in.
# (B's dial sweep is the one exception, on purpose: it starts at 0.87 s, ~10 dB down, so the station is
# heard arriving under the end of the fade; its lock lands at 2.27 s. In-engine capture of A: the first
# ping at 1.404 s plays at 0.0 dB against steady state.)
#
# LOUDNESS. validate() pins every music peak at -1 dBFS, so loudness is set by crest factor and spectrum,
# not by gain. The target is an iPhone speaker, which plays little below ~400-500 Hz, so every take is
# measured three ways (ITU BS.1770, circular over the loop): full range; after a 2nd-order Butterworth
# high-pass at 400 Hz; after a 4th-order one at 450 Hz. The planet music the title has to sit beside:
#   meadow_day -14.06 / -15.56 / -15.46 LUFS     hub -13.54 / -15.34 / -15.26     (old title -12.77 / -14.55 / -14.53)
# ROUND 1 matched full range only and an independent critic failed it on the phone: pads voiced round
# middle C (fundamentals 185-370 Hz), the pad filter at 1.5-1.8 kHz, the sub at -18 and finish()'s +1 dB
# low shelf put 32.6 % of take A's power under 150 Hz and 55.3 % at 150-500 Hz (meadow_day 26.6 / 8.9 %),
# and A measured -13.93 / -19.39 / -20.95 -- 4-5 dB under the planet music on a phone, so starting a game
# would have stepped UP from the title. ROUND 2 moved the energy into the band a phone plays, in all three
# takes: sub 5 dB lower, finish(warmth_db=0), pads voiced round G4 (center 67, fundamentals 277-554 Hz)
# with I.analog_pad's filter opened to ~2.8 kHz, the arpeggios an octave up (their filter now tracks the
# key so they keep their colour), then the sustained pad traded against the moving part: A pad -3 / arp +4,
# B pad -3 / broadcast +5; in C the pad went UP 3 dB, because the orbit had moved an octave away from it.
# Measured on the written files -- full / hp400 / hp450-4th, and % of power under 150 / 150-500 / 500-2k /
# over 2k Hz (meadow_day 26.6 / 8.9 / 62.2 / 2.2, hub 30.5 / 11.2 / 55.8 / 2.5):
#   A -13.93 / -15.78 / -16.21    12.7 / 39.8 / 45.8 / 1.7
#   B -13.81 / -15.59 / -15.88    14.3 / 30.8 / 53.2 / 1.6
#   C -13.80 / -15.47 / -15.76    11.6 / 36.4 / 50.3 / 1.6
# i.e. within 0.4 dB of both planet tracks full range and within 1.0 dB through either high-pass, and the
# three takes within 0.45 dB of each other, so the user's pick on the phone is not decided by level.
# Each take is balanced by LOGO_DB and BED_TRIM_DB; the trim was searched (on stems, re-running finish())
# for about -13.8 LUFS, midway between meadow_day and hub. With the arpeggios up an octave and louder, in
# A the arp's onsets now set the -1 dBFS peak rather than the pings (A tops out at -13.96 LUFS at any
# trim) and in C the orbit's do; in B the dial's lock accent still does. The motif's loudest 3 s (heard
# from a cold start) stands over the loop by +1.29 LU in A, +1.87 in B, +2.02 in C, and each logo note is
# 14-54 dB over the bed inside its own critical band. A trim not re-searched after the parts change will
# be wrong.
#
# DISK. build_all fails if assets/audio passes 60 MB and the project sits right on that line. Every take
# is shorter than the old 32.7 s / 5.82 MB title (A 30.0 s / 5.32 MB, B 29.1 s / 5.18 MB, C 26.7 s /
# 4.75 MB), so switching between them can only give bytes back.

TITLE_TAIL_SEC = 9.0   # not TAIL_SEC's 4 s: by arithmetic, echoes at fb 0.45 every 0.62 s are only 44 dB down
                       # after 4 s, and a room-0.94 reverb loses ~11 dB/s at most


def _loop_lfo(L, cycles, phase=0.0):
    """0..1 raised sine with a whole number of cycles per loop, so it is continuous across the seam."""
    i = np.arange(L, dtype=np.float64)
    return 0.5 + 0.5 * np.sin(S.TWO_PI * (cycles * i / float(L) + phase))


def _loop_noise(L, fc, width_oct, seed):
    """A band of noise that loops perfectly: a random-phase spectrum exactly L samples long, so its
    inverse FFT is periodic in L and the loop point is just another sample (noise rendered linearly and
    folded would be doubled over the first TAIL seconds). Gaussian band in log-frequency around fc,
    width_oct = one standard deviation in octaves. Unit RMS."""
    rng = np.random.default_rng(seed)
    f = np.fft.rfftfreq(L, 1.0 / S.SR)
    f[0] = 1.0
    mag = np.exp(-0.5 * (np.log2(f / fc) / width_oct) ** 2)
    mag[0] = 0.0
    y = np.fft.irfft(mag * np.exp(1j * rng.uniform(0.0, S.TWO_PI, len(f))), L)
    return y / (np.std(y) + 1e-12)


def _radio_air(L, bands, drift_cycles, flutter_cycles, seed):
    """'Distant radio' bed, stereo and loop-periodic. bands = [(fc, width_oct, gain), ...]; the first two
    bands crossfade with a slow LFO (the station drifting), and the whole bed flutters slightly the way a
    far signal fades in and out. Decorrelated left/right so it sits wide and behind everything."""
    out = np.zeros((2, L))
    drift = _loop_lfo(L, drift_cycles)
    flutter = 0.82 + 0.18 * _loop_lfo(L, flutter_cycles, 0.3)
    for k, (fc, w, g) in enumerate(bands):
        weight = drift if k == 0 else (1.0 - drift if k == 1 else 1.0)
        for ch in range(2):
            out[ch] += g * weight * _loop_noise(L, fc, w, seed + 17 * k + 101 * ch)
    return out * flutter[None, :]


def _title_stereo(parts, L, tail, bpm, track):
    """stereo_of for the title takes, plus two things only they need: a part may be a pre-rendered stereo
    "buf" (the radio tuning sweep), and a note may carry a 5th field, its own pan (the orbit arpeggio
    circles the listener). Same effect chain and order as stereo_of. Kept separate so the planet tracks'
    render path is not touched while other builders are working on them."""
    n_total = L + tail
    out = np.zeros((2, n_total))
    spb = 60.0 / bpm
    stats = STEM_STATS.setdefault(track, [])
    del stats[:]
    for p in parts:
        gain = S.db(p.get("db", 0.0))
        if "buf" in p:
            buf = S.pad_to(S.to_stereo(p["buf"]), n_total) * gain
        elif p["notes"] and len(p["notes"][0]) == 5:
            buf = np.zeros((2, n_total))
            for beat, dur, pitch, vel, pan_pos in p["notes"]:
                sig = S.fade_edges(p["inst"](S.nf(pitch), dur * spb, vel), 0.002, 0.002)
                S.mix_into(buf, S.pan(sig, pan_pos), int(round(beat * spb * S.SR)), gain)
        else:
            buf = S.render_notes(p["notes"], p["inst"], bpm, n_total, gain=gain, pan_pos=p.get("pan", 0.0),
                                 pan_by_pitch=p.get("pan_by_pitch", 0.0), humanize_ms=p.get("humanize_ms", 0.0),
                                 humanize_vel=p.get("humanize_vel", 0.0), seed=p.get("seed", 1))
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
        stats.append((p.get("name", getattr(p.get("inst"), "__name__", "buf")), S.to_db(S.rms(buf[:, :L])), S.to_db(S.peak(buf))))
        out += buf
    return out


def _bed_roots(prog, octave=2, overlap=0.5, vel=0.8, top=45):
    """Sub notes, one per chord, each root dropped an octave if it would sit above A2 (110 Hz, midi 45)."""
    out = []
    for i, (start, ln, *_r) in enumerate(prog.items):
        m = prog.root_midi(i, octave)
        if m > top:
            m -= 12
        out.append((start, ln + overlap, mname(m), vel))
    return out


def _with_air(mix, air, L, db_, track="title"):
    """Add a loop-periodic bed over [0, L) ONLY. finish() filters the whole L + tail buffer and then
    folds it, so the filter ring past L wraps back onto the start: circular filtering, no seam."""
    a = air * S.db(db_)
    mix[:, :L] += a
    STEM_STATS.setdefault(track, []).append(("air", S.to_db(S.rms(a)), S.to_db(S.peak(a))))
    return mix


# --------------------------------------------------------------------------- A: "Sonar"
# The logo: three pings, Bb4 - F5 - D6, "ping-ping ... PING". Short-long, and up an open fifth and then a
# major sixth, so it rises and stays open rather than closing like a doorbell. Over the loop's first chord
# (Ebmaj9) all three are upper chord tones (5th, 9th, major 7th), so the landing floats instead of
# resolving: a signal, not a fanfare. Each ping answers itself: ping-pong echoes every 2/3 of a beat
# (0.62 s) that get darker as they go (4.2 kHz damping), like a return from somewhere far.
SONAR_LOGO = "r:1.5 Bb4:0.5@0.78 F5:1@0.86 D6:3@0.95"    # beats; the first ping at 1.5 beats = 1.40 s
# Each take's balance is two numbers: the logo's level, and the bed's trim under it (see LOUDNESS). Round 1
# had the pings set the -1 dBFS peak; since round 2 the louder, higher arp's onsets do, 2.5 dB over them.
SONAR_LOGO_DB = -4.0
SONAR_BED_TRIM_DB = 1.18   # CALIBRATED, see LOUDNESS above


def _sonar_logo_parts(bpm, vel_scale=1.0):
    """The sonar motif as mixer parts, on its own so a later round can render it as a notification sting."""
    echo = dict(time=60.0 / bpm * (2.0 / 3.0), fb=0.45, mix=0.5, pingpong=True, damp=2400.0)
    return [dict(name="logo_ping", notes=S.scale_vel(S.parse_seq(SONAR_LOGO), vel_scale), inst=I.sonar_ping,
                 db=SONAR_LOGO_DB, pan=-0.05, delay=echo, rev=0.4, room=0.94, damp=0.35, predelay=0.03)]


# rejected by the user 2026-09-10 after listening; not shipped
def track_title_sonar():
    """A: the sonar take. Eb major at 64 bpm, one chord a bar (3.75 s each), eight bars, no percussion.
    Three pings open it; the bed is an analog pad, a sub that swells in, and from bar 3 a slow arpeggio
    of quarter notes (1.07 onsets/s while it plays; 1.47/s for the whole take, against the old title's
    7.8) through a dotted-8th echo. One far-off ping in bar 5, low and filtered, keeps the "someone out
    there" idea alive halfway round the loop.

    THE LOGO PLAYS ONCE. The three-ping motif and its ping-pong echo (0.62 s repeats, damped, ~9 s to
    fade below audibility -- see TITLE_TAIL_SEC) are a one-shot cold-open, not something that should
    replay every loop. bars 1-4 (the motif plus its decay, and the pad/sub/arp all still arriving) are
    the intro; TITLE_LOOP_BEGIN marks bar 5, the exact midpoint of the 8-bar buffer (129 of 258 QOA
    frames -- the only interior bar boundary that lands on a whole frame, since 258 frames / 8 bars =
    32.25 frames/bar and only multiples of 8 bars divide evenly) where the motif has long since decayed
    and the pad/arp/sub bed is fully established. Godot plays [0:loop_end] once, then repeats
    [loop_begin:loop_end] forever -- a 14.98 s bed loop (bars 5-8, Ebmaj9/G-Fm9-Abmaj7#11-Bb7sus) --
    see S.fold_loop_at, used via finish(loop_begin=...) below instead of the whole-buffer S.fold_loop."""
    bpm, bars = 64.0, 8
    L, bpm = loop_samples(bpm, bars)
    loop_begin = (L // 8) * 4  # bar 5 of 8, snapped to the same QOA-frame grid as L itself
    tail = S.n_samples(TITLE_TAIL_SEC)
    prog = Prog(["Ebmaj9", "Cm9", "Abmaj9", "Bb6sus", "Ebmaj9/G", "Fm9", "Abmaj7#11", "Bb7sus"])
    pad_notes = sustain_chords(prog, center=67, vel=0.55, max_notes=4, overlap=1.0)
    # Bars 3-8: up the chord on even bars, down it on odd bars, one note a beat -- never an 8th.
    arp = []
    for i, (start, ln, *_r) in enumerate(prog.items):
        if i < 2:
            continue
        tones = voice_chord(prog, i, 79, 4)
        order = tones if i % 2 == 0 else tones[::-1]
        for k, m in enumerate(order):
            arp.append((start + k, 1.6, mname(m), 0.5 if k else 0.58))
    far = S.parse_seq("r:17.5 Bb4:1@0.4 r:13.5")
    echo = dict(time=60.0 / bpm * (2.0 / 3.0), fb=0.45, mix=0.5, pingpong=True, damp=2400.0)
    trim = SONAR_BED_TRIM_DB
    # Levels: the first render had the sub at -11 and 71 % of the loop's energy under 150 Hz (the planet
    # tracks: 27-43 %), i.e. mostly inaudible on the phone. Round 1 took it to 32.6 % (sub -18, pad -10,
    # arp -12, pad round middle C); round 2, for the phone speaker, to 12.7 %: sub -23, pad -13 voiced
    # round G4, arp -5 an octave up. See LOUDNESS.
    parts = _sonar_logo_parts(bpm) + [
        dict(name="far_ping", notes=far, inst=I.sonar_ping, db=-15.0, pan=0.35, lp=1600.0, delay=echo, rev=0.5, room=0.95),
        dict(name="pad", notes=pad_notes, inst=I.analog_pad, db=-13.0 + trim, chorus=dict(rate=0.23, depth=4.0, mix=0.5),
             rev=0.38, room=0.93),
        dict(name="arp", notes=arp, inst=I.analog_arp, db=-5.0 + trim, pan_by_pitch=0.3,
             delay=dict(time=60.0 / bpm * 0.75, fb=0.35, mix=0.32, pingpong=True, damp=2800.0), rev=0.35, room=0.9),
        dict(name="sub", notes=_bed_roots(prog), inst=I.sub_swell, db=-23.0 + trim),
    ]
    mix = _title_stereo(parts, L, tail, bpm, "title")
    air = _radio_air(L, [(700.0, 0.55, 1.0), (1400.0, 0.5, 0.7)], drift_cycles=1, flutter_cycles=13, seed=41)
    mix = _with_air(mix, air, L, -44.0 + trim)
    return finish(mix, L, lp=12000.0, warmth_db=0.0, air_db=0.0, loop_begin=loop_begin), L, bpm


# --------------------------------------------------------------------------- B: "Radio"
# The logo: a shortwave dial being tuned. A carrier whistles down from 14 semitones above F5, overshoots,
# comes back and locks, while a second, fixed carrier (the station) fades in underneath: the beat between
# the two slows from ~130 Hz to 0 as the dial closes in -- the "wow-wow-wow" of tuning to zero beat. At
# the lock the noise squelches, the fixed carrier is exactly in phase with the moving one, and the Dbmaj9
# pad and sub bloom in under the held note. Tune (1.4 s), lock, bloom: recognisable in two seconds.
RADIO_LOCK_BEAT = 2.5          # 2.27 s at 66 bpm; the sweep starts 1.4 s earlier, at 0.87 s
RADIO_SWEEP_SEC = 1.4
RADIO_TARGET = "F5"            # the 3rd of Db: a warm landing, not the root's full stop
RADIO_LOGO_DB = -6.0
RADIO_BED_TRIM_DB = -1.70  # CALIBRATED, see LOUDNESS above


def _radio_tuning(target_hz, n, seed=5):
    """The tuning sweep as a mono buffer n samples long, the lock at RADIO_SWEEP_SEC. See the note above."""
    t = S.times(n)
    # carrier offset from the target, semitones: a hand on a dial overshooting and settling
    keys_t = [0.0, 0.30, 0.62, 0.90, 1.12, 1.30, RADIO_SWEEP_SEC]
    keys_c = [14.0, 8.5, 3.0, -1.2, 0.35, -0.1, 0.0]
    c = np.interp(t, keys_t, keys_c)
    k = S.n_samples(0.06)
    c = np.convolve(np.pad(c, (k, k), mode="edge"), np.ones(k) / k, mode="same")[k:-k]
    i_lock = S.n_samples(RADIO_SWEEP_SEC)
    c[i_lock:] = 0.0
    f = target_hz * 2.0 ** (c / 12.0)
    ph = np.cumsum(f) / S.SR
    moving = np.sin(S.TWO_PI * ph)
    # the station carrier, phase-matched to the moving one at the lock so the two add, never cancel
    fixed = np.sin(S.TWO_PI * (target_hz * t + (ph[i_lock] - target_hz * t[i_lock])))
    # Carrier levels. Before the lock the dial carrier (0.4) and the station (0.25) beat against each other;
    # AT the lock they are one sine and get a 0.1 s accent on top -- the logo's downbeat. That accent is
    # what sets this take's -1 dBFS peak. The tuning's held carriers and static have a crest of only ~7 dB
    # and the Db pad ~10.5 dB, so without a short peak the loop measured -11.5 LUFS WHATEVER the bed trim
    # (the pad set the peak and normalisation undid the trim). An accent ~9 dB over the sweep, gone in
    # 0.1 s, buys that headroom for almost no loudness. (The carriers were 0.55 / 0.35 with the static
    # 4 dB hotter: with only the accent added, the tuning's 3 s loudness was still -10.2 LUFS vs -14.0.)
    a_f = np.interp(t, [0.0, 0.45, 1.0, RADIO_SWEEP_SEC, RADIO_SWEEP_SEC + 0.5], [0.0, 0.0, 0.25, 0.25, 0.0])
    # after the lock the two carriers are one sine: hand the fixed one's share to the moving one
    a_m = np.interp(t, [0.0, 0.12], [0.0, 0.4]) + np.where(t >= RADIO_SWEEP_SEC, 0.25 - a_f, 0.0)
    # ...then let the held note sink 7 dB under the blooming chord. The first render held it at full level
    # for 1.3 s and the motif's 3 s loudness came out 5.6 LU above meadow_day's loudest 3 s.
    a_m *= np.interp(t, [0.0, RADIO_SWEEP_SEC, RADIO_SWEEP_SEC + 0.6, RADIO_SWEEP_SEC + 1.3,
                         RADIO_SWEEP_SEC + 3.0, t[-1]], [1.0, 1.0, 0.45, 0.45, 0.0, 0.0])
    # accent 1.5 over the 0.65 carrier sum: ~9 dB over the sweep after the saturation below. At 1.1 the logo
    # needed 1.5 dB more level to set the peak and the sweep's 3 s loudness sat 2.8 LU over the loop.
    dt = np.maximum(t - RADIO_SWEEP_SEC, 0.0)
    accent = np.where(t >= RADIO_SWEEP_SEC, 1.5 * np.exp(-dt / 0.1) * np.clip(dt / 0.007, 0.0, 1.0), 0.0)
    tone = moving * (a_m + accent) + fixed * a_f                    # after the lock, moving == fixed exactly
    tone = np.tanh(0.35 * tone) / np.tanh(0.35)                     # AM-detector grit, gentle
    # static that follows the dial, bandpassed around 1.3x the carrier, squelched at the lock
    hiss = S.pink_noise(n, seed)
    fc = np.clip(f * 1.3, 500.0, 3000.0)
    stages = [500.0, 900.0, 1650.0, 3000.0]
    band = np.zeros(n)
    lf = np.log(fc)
    ls = np.log(np.array(stages))
    for j, fs_ in enumerate(stages):
        lo = ls[j - 1] if j > 0 else ls[0] - 1.0
        hi = ls[j + 1] if j + 1 < len(ls) else ls[-1] + 1.0
        w = np.clip(np.minimum((lf - lo) / (ls[j] - lo), (hi - lf) / (hi - ls[j])), 0.0, 1.0)
        band += S.bandpass(hiss, fs_, 1.1) * w
    a_n = np.interp(t, [0.0, 0.08, 0.9, RADIO_SWEEP_SEC, RADIO_SWEEP_SEC + 0.3, RADIO_SWEEP_SEC + 1.8],
                    [0.0, 0.9, 0.9, 0.45, 0.12, 0.0])
    y = tone * 0.55 + band * a_n * 0.5
    y = S.highpass(S.lowpass(y, 3200.0, 0.7), 280.0, 0.7)
    return S.fade_edges(y, 0.005, 0.05)


def _radio_logo_parts(bpm, n_total, vel_scale=1.0):
    """The radio motif as one pre-rendered part placed so the lock lands on RADIO_LOCK_BEAT."""
    lock_t = RADIO_LOCK_BEAT * 60.0 / bpm
    one = _radio_tuning(S.nf(RADIO_TARGET), S.n_samples(RADIO_SWEEP_SEC + 3.4))
    buf = np.zeros(n_total)
    S.mix_into(buf, one * vel_scale, S.n_samples(lock_t - RADIO_SWEEP_SEC))
    return [dict(name="logo_tuning", buf=S.pan(buf, 0.0), db=RADIO_LOGO_DB, rev=0.3, room=0.9, damp=0.4)]


# rejected by the user 2026-09-10 after listening; not shipped
def track_title_radio():
    """B: the radio take. Db major at 66 bpm, eight bars, no percussion. The first chord (Dbmaj9) is held
    back until the dial locks at beat 2.5, so the loop's first two seconds are only the tail of the last
    chord (Ab6sus) and the static -- the tuning happens over the dominant and the lock IS the resolution.
    The bed: pad, sub, and from bar 3 a far-off broadcast melody of ten long notes (0.34 onsets/s) in an
    AM-radio band, with the station noise drifting slowly between two bands behind it."""
    bpm, bars = 66.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TITLE_TAIL_SEC)
    prog = Prog([("Dbmaj9", 8.0), "Bbm9", "Gbmaj9", "Dbmaj9/F", "Ebm9", "Gbmaj7#11", "Ab6sus"])
    pad_notes = []
    for b, d, p, v in sustain_chords(prog, center=67, vel=0.55, max_notes=4, overlap=1.0):
        if b == 0.0:                      # the Db chord blooms at the lock, not at the loop point
            b, d, v = RADIO_LOCK_BEAT, d - RADIO_LOCK_BEAT, 0.62
        pad_notes.append((b, d, p, v))
    sub = [(RADIO_LOCK_BEAT, n[1] - RADIO_LOCK_BEAT, n[2], n[3]) if n[0] == 0.0 else n for n in _bed_roots(prog)]
    broadcast = S.parse_seq(
        "r:9 F5:2 Db5:1 | Ab5:3 F5:1 | Eb5:4 | r:1 Gb5:1 F5:2 | C5:2 Db5:2 | Eb5:3 r:1", default_vel=0.7, start_beat=0.0)
    trim = RADIO_BED_TRIM_DB
    parts = _radio_logo_parts(bpm, L + tail) + [
        dict(name="pad", notes=pad_notes, inst=I.analog_pad, db=-13.0 + trim, chorus=dict(rate=0.2, depth=4.5, mix=0.5),
             rev=0.4, room=0.93),
        dict(name="broadcast", notes=broadcast, inst=I.radio_lead, db=-6.0 + trim, pan=0.22,
             delay=dict(time=60.0 / bpm * 1.5, fb=0.3, mix=0.25, pingpong=True, damp=2200.0), rev=0.42, room=0.93),
        dict(name="sub", notes=sub, inst=I.sub_swell, db=-23.0 + trim),
    ]
    mix = _title_stereo(parts, L, tail, bpm, "title")
    air = _radio_air(L, [(1100.0, 0.45, 1.0), (2100.0, 0.4, 0.8)], drift_cycles=1, flutter_cycles=11, seed=43)
    mix = _with_air(mix, air, L, -43.0 + trim)
    return finish(mix, L, lp=11000.0, warmth_db=0.0, air_db=0.0), L, bpm


# --------------------------------------------------------------------------- C: "Orbit"
# The logo: the game's initials in Morse, A = .-  N = -. , keyed on one soft F5 tone. Dit-dah, dah-dit:
# a palindrome, so it is easy to remember even for someone who has never heard Morse. Unit = 1/6 beat
# (0.139 s at 72 bpm, ~9 words/min), dah = 3 units, gap = 1, gap between letters = 3; the call is 13
# units = 1.81 s. Then the "orbit": one arpeggio note a beat that climbs a chord and comes back down over
# two bars, while its pan goes round the listener with it (sin of the orbit phase) -- so the only moving
# part moves in space, not in tempo. Halfway round the loop a fainter call answers from the right, a
# fourth higher (Bb5): another beacon, another neighbour.
ORBIT_MORSE = ".- -."          # A N
ORBIT_UNIT_BEATS = 1.0 / 6.0
ORBIT_CALL_BEAT = 5.0 / 3.0    # 1.39 s: the fade-in is done
# This take works the other way round from A and B: the BED sets the -1 dBFS peak (the orbit's plucked
# onsets) and the call sits just under it. A keyed sine is nearly all energy, so whenever the call set
# the peak its 3 s loudness came out at -10.8 / -11.3 LUFS (logo at -6 / -8.5 to -11 dB), up to 3.2 LU
# over the loop. Round 1 put it at -12 (+1.42 LU over the loop). Round 2 moved the orbit up an octave,
# onto the call's own register (F5), and at -12 the call's lead over the loop fell to +0.24 LU, so it is
# at -10 now: +2.02 LU, 13.8-54 dB over the bed in its own critical band.
ORBIT_LOGO_DB = -10.0
ORBIT_BED_TRIM_DB = 2.5    # CALIBRATED, see LOUDNESS above


def morse_notes(code, pitch, start_beat, unit, vel):
    """Morse -> note list. '.' = 1 unit, '-' = 3 units, 1 unit between elements, 3 between letters."""
    notes, b = [], start_beat
    for letter in code.split():
        for sym in letter:
            ln = unit if sym == "." else 3.0 * unit
            notes.append((b, ln, pitch, vel))
            b += ln + unit
        b += 2.0 * unit
    return notes


def _orbit_logo_parts(bpm, start_beat=ORBIT_CALL_BEAT, vel_scale=1.0):
    call = morse_notes(ORBIT_MORSE, "F5", start_beat, ORBIT_UNIT_BEATS, 0.9 * vel_scale)
    return [dict(name="logo_morse", notes=call, inst=I.morse_tone, db=ORBIT_LOGO_DB, pan=-0.08,
                 delay=dict(time=60.0 / bpm * 0.75, fb=0.38, mix=0.4, pingpong=True, damp=2600.0), rev=0.38, room=0.93)]


# rejected by the user 2026-09-10 after listening; not shipped
def track_title_orbit():
    """C: the orbit take. Bb major at 72 bpm, two bars per chord (Bbmaj9, Gm9, Ebmaj9, F6sus), no
    percussion. After the call, the orbit arpeggio carries the loop at one note a beat (1.2 onsets/s);
    pad and sub stay underneath."""
    bpm, bars = 72.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TITLE_TAIL_SEC)
    prog = Prog([("Bbmaj9", 8.0), ("Gm9", 8.0), ("Ebmaj9", 8.0), ("F6sus", 8.0)])
    pad_notes = sustain_chords(prog, center=67, vel=0.5, max_notes=4, overlap=1.5)
    orbit = []
    steps = [0, 1, 2, 3, 4, 3, 2, 1]                     # up the chord and back: one orbit per chord
    for i, (start, ln, *_r) in enumerate(prog.items):
        tones = voice_chord(prog, i, 76, 4)
        tones = tones + [tones[0] + 12]
        for k in range(int(ln)):
            if start + k < 4.0:                          # the call has the first bar to itself
                continue
            th = S.TWO_PI * (k % 8) / 8.0
            orbit.append((start + k, 1.5, mname(tones[steps[k % 8]]), 0.5 + 0.1 * math.cos(th), 0.55 * math.sin(th)))
    reply = morse_notes(ORBIT_MORSE, "Bb5", 16.0 + ORBIT_CALL_BEAT, ORBIT_UNIT_BEATS, 0.4)
    trim = ORBIT_BED_TRIM_DB
    parts = _orbit_logo_parts(bpm) + [
        dict(name="reply", notes=reply, inst=I.morse_tone, db=-16.0, pan=0.55, lp=1900.0,
             delay=dict(time=60.0 / bpm * 0.75, fb=0.4, mix=0.45, pingpong=True, damp=2200.0), rev=0.5, room=0.95),
        # The orbit's plucked onsets, not the pad, should set the bed's peaks (a pad's crest is ~10 dB,
        # too little to sit at -14 LUFS under a -1 dBFS peak), hence orbit over pad by 7 dB.
        dict(name="orbit", notes=orbit, inst=I.analog_arp, db=-8.5 + trim,
             delay=dict(time=60.0 / bpm * 0.75, fb=0.38, mix=0.35, pingpong=True, damp=2600.0), rev=0.38, room=0.92),
        # Round 1 had pad -18.5 / sub -21 with the pad round A#3 and the orbit round E4. Round 2 (phone
        # speaker, see LOUDNESS): orbit up an octave, pad round G4 and 3 dB up to fill the gap the orbit
        # left, sub down 5.
        dict(name="pad", notes=pad_notes, inst=I.analog_pad, db=-15.5 + trim, chorus=dict(rate=0.18, depth=4.5, mix=0.5),
             rev=0.4, room=0.93),
        dict(name="sub", notes=_bed_roots(prog), inst=I.sub_swell, db=-26.0 + trim),
    ]
    mix = _title_stereo(parts, L, tail, bpm, "title")
    air = _radio_air(L, [(2600.0, 0.7, 1.0), (1200.0, 0.6, 0.6)], drift_cycles=1, flutter_cycles=9, seed=47)
    mix = _with_air(mix, air, L, -46.0 + trim)
    return finish(mix, L, lp=12000.0, warmth_db=0.0, air_db=0.0), L, bpm


def track_title_legacy():
    """The OLD title, kept only so the three takes can be A/B'd against it and rolled back in one line.
    It is the one the user said reads as Animal Crossing (see the note at the top of this section).
    Dreamy, hopeful C-lydian theme: vibraphone melody (whistle doubles the second half), e-piano arps, pad."""
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


def track_dust():
    """Fen's long dusk: the slowest, sparsest loop in the game. F-mixolydian, 58 bpm, and the only
    track with NO percussion at all -- on a world where the sun has not moved for nine years there
    is nothing to keep time with. Flute lead over a marimba that plays one note per beat, a sub that
    holds a whole chord, and a wide pad. Deliberately far from `violet` (100 bpm, E-minor pentatonic,
    theremin and congas), which is what Fen shipped on as an interim."""
    bpm, bars = 58.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Fmaj9", "Eb6", "Bbmaj7", "Cm9", "Fmaj9", "Dm9", "Bbmaj7", "C7sus"])
    lead = melody(
        "C5:2 F5:2 | A5:3 G5:1 | F5:2.5 D5:1.5 | C5:2 r:2 | "
        "D5:1.5 F5:0.5 A5:2 | G5:2 F5:2 | D5:3 C5:1 | F5:2 r:2", bars, vel=0.72)
    # One marimba note per beat: the pan does not hurry and neither does this.
    acc = arpeggio(prog, [0, 2, 1, 2], octave=4, grid=1.0, vel=0.38, dur=1.6, center=62)
    bass = [(start, ln + 0.4, mname(prog.root_midi(i, 2)), 0.8) for i, (start, ln, *_r) in enumerate(prog.items)]
    pad_notes = sustain_chords(prog, center=58, vel=0.5, max_notes=4, overlap=0.9)
    shim = [(start, ln + 1.2, mname(prog.root_midi(i, 4)), 0.42) for i, (start, ln, *_r) in enumerate(prog.items)]
    # Far-off chimes on the rim of a pool. Eight bars, one every other bar, never on a downbeat.
    chime = S.parse_seq("r:6.5 F6:0.5@0.4 r:9 C6:0.5@0.35 r:7.5 A5:0.5@0.4 r:0.5 r:6.5 D6:0.5@0.3 r:0.5",
                        default_vel=0.4)
    parts = [
        dict(notes=lead, inst=I.flute, db=-7.0, pan=0.08, rev=0.42, room=0.93, damp=0.35,
             delay=dict(time=60.0 / bpm * 0.75, fb=0.28, mix=0.22, pingpong=True, damp=3200.0)),
        dict(notes=acc, inst=I.marimba, db=-14.0, pan=-0.28, pan_by_pitch=0.12, rev=0.34, room=0.9,
             humanize_ms=7, humanize_vel=0.07),
        dict(notes=bass, inst=I.bass_sub, db=-11.0),
        dict(notes=pad_notes, inst=I.soft_pad, db=-13.0, chorus=dict(rate=0.18, depth=5.5, mix=0.6), rev=0.42, room=0.94),
        dict(notes=shim, inst=I.shimmer, db=-16.0, chorus=dict(rate=0.13, depth=6.0, mix=0.65), rev=0.45, room=0.95),
        dict(notes=chime, inst=I.sine_ping, db=-15.0, pan=0.42,
             delay=dict(time=60.0 / bpm * 0.5, fb=0.42, mix=0.5, pingpong=True), rev=0.45, room=0.94),
    ]
    mix = stereo_of(parts, L, tail, bpm, "dust")
    return finish(mix, L, lp=10500.0, warmth_db=2.4), L, bpm


def track_chalk():
    """Grig's chalk steps: measured and counted. D-dorian at 92 bpm with a woodblock on every beat --
    he counts risers, so the track counts too -- plus a rim on the half bar. Vibraphone states the
    motif in plain quarters, a plucked bass walks the roots and there is no pad wash to hide behind.
    Spare on purpose: `chrome` (124 bpm chiptune jazz) is the track Grig shipped on as an interim and
    is the busiest in the game."""
    bpm, bars = 92.0, 8
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Dm9", "Dm9", "Gm7", "Am7", "Bbmaj7", "F6", "Gm7", "A7sus"])
    lead = melody(
        "D5:1 F5:1 A5:1 G5:1 | F5:2 D5:2 | G5:1 A#5:1 A5:1 G5:1 | A5:2 r:2 | "
        "A#5:1 A5:1 F5:1 D5:1 | C5:2 F5:2 | G5:1 A5:1 A#5:1 A5:1 | D5:3 r:1", bars, vel=0.78)
    # Two chord tones per bar, always on 1 and 3: a step is either there or it is not.
    acc = arpeggio(prog, [0, -1, 2, -1], octave=4, grid=1.0, vel=0.42, dur=1.5, center=67)
    bass = []
    for i, (start, ln, root, q, b) in enumerate(prog.items):
        r = prog.root_midi(i, 2)
        bass.append((start, 1.7, mname(r), 0.85))
        bass.append((start + 2.0, 0.8, mname(r + 7), 0.55))
        bass.append((start + 3.0, 0.8, mname(r + 12), 0.45))
    pad_notes = sustain_chords(prog, center=57, vel=0.42, max_notes=3, overlap=0.15)
    kit = I.drumkit(I.KIT_ACOUSTIC)
    # The count. Four to a bar, the downbeat hardest, and a rim on 3 so the bar has a middle.
    count = pattern_bars("wood:1@0.5 wood:1@0.3 rim:1@0.42 wood:1@0.3", bars,
                         fills={7: "wood:1@0.5 wood:1@0.3 rim:1@0.42 wood:0.5@0.3 wood:0.5@0.38"})
    parts = [
        dict(notes=lead, inst=I.vibraphone, db=-7.5, pan=0.1, pan_by_pitch=0.1, rev=0.32, room=0.86, damp=0.4),
        dict(notes=acc, inst=I.kalimba, db=-15.0, pan=-0.34, rev=0.28, room=0.84, humanize_ms=3, humanize_vel=0.04),
        dict(notes=bass, inst=I.pluck, db=-11.5, pan=0.0, rev=0.14, room=0.8),
        dict(notes=pad_notes, inst=I.pad, db=-17.0, chorus=dict(rate=0.22, depth=3.0, mix=0.4), rev=0.3, room=0.88),
        dict(notes=count, inst=kit, db=-13.0, pan=-0.12, rev=0.18, room=0.82, humanize_ms=2),
    ]
    mix = stereo_of(parts, L, tail, bpm, "chalk")
    return finish(mix, L, lp=13000.0, warmth_db=1.2, air_db=0.8), L, bpm


def track_frost():
    """Vela's still frost: the quietest track in the game, and the only one with no drum kit at all.

    54 bpm in A-aeolian, two bars to a chord so the harmony moves half as often as anywhere else --
    on a world whose whole claim is "no edges", the music should not supply any either. There is no
    melody instrument in the usual sense: a shimmer bed and a soft pad carry the whole loop, and the
    only foreground events are a music-box figure of four notes per eight bars.

    THE SLOW PING IS THE LONG ARRAY. One glass ping every four bars (~17.8 s), panned wide with a
    long ping-pong delay, is the dish sweeping. It is the one deliberate "someone lives here" cue
    and it is what stops the loop being a plain ambient wash. Keep it sparse -- two per loop is the
    whole point; at four it stops being an event and starts being a rhythm.

    Cold is bought with LOW-PASS and register, not with chorus: `finish(lp=9000)` is the darkest in
    the file, and the bass sits an octave above `space`'s sub so nothing rumbles. Sparse on purpose:
    `space` (66 bpm, seven parts) is the closest sibling and is twice as busy.

    IT IS FOUR BARS, NOT EIGHT, AND THAT IS A DISK BUDGET AND NOT A MUSICAL CHOICE. build_all.py
    gates each track at 6 MiB and all of assets/audio at 60 MB, and the other ten tracks already
    spend 57.0 MB of that. The first build here was eight bars at 54 bpm -- 35.5 s, 6.31 MB -- and
    failed BOTH gates at once. A seventh world simply does not fit at the size the other six are,
    so the shortest, sparsest loop in the game is the one that gives the size back: at 4 bars /
    58 bpm this is 16.6 s and ~2.9 MB, and an ambient bed with no drum grid and four foreground
    notes is where a short loop is least audible. If an eighth world is ever added, that budget
    needs raising deliberately rather than another track being squeezed.

    The harmonic rhythm is still the slowest in the game: one chord per bar at 58 bpm is a change
    every 4.14 s, against `space`'s 3.6 s and `chalk`'s 2.6 s."""
    bpm, bars = 58.0, 4
    L, bpm = loop_samples(bpm, bars)
    tail = S.n_samples(TAIL_SEC)
    prog = Prog(["Am9", "Fmaj7#11", "Dm9", "Emin"], beats_per_chord=4.0)
    pad_notes = sustain_chords(prog, center=58, vel=0.38, max_notes=4, overlap=1.2)
    shim = [(start, ln + 1.5, mname(prog.root_midi(i, 4)), 0.42)
            for i, (start, ln, *_r) in enumerate(prog.items)]
    bass = [(start, ln + 0.5, mname(prog.root_midi(i, 3)), 0.55)
            for i, (start, ln, *_r) in enumerate(prog.items)]
    # Three notes in sixteen beats. Everything else is rest.
    figure = S.parse_seq("r:2 A5:2@0.34 r:5 E5:2@0.30 r:2 C6:2@0.30 r:1", default_vel=0.32)
    # The dish: one ping per loop, on the downbeat.
    ping = S.parse_seq("r:1 E6:1@0.30 r:14", default_vel=0.28)
    parts = [
        dict(notes=pad_notes, inst=I.soft_pad, db=-13.0,
             chorus=dict(rate=0.11, depth=4.0, mix=0.45), rev=0.52, room=0.97, damp=0.55),
        dict(notes=shim, inst=I.shimmer, db=-14.5,
             chorus=dict(rate=0.09, depth=5.0, mix=0.6), rev=0.55, room=0.97),
        dict(notes=bass, inst=I.bass_soft, db=-16.0, lp=420.0, rev=0.16, room=0.9),
        dict(notes=figure, inst=I.music_box, db=-15.0, pan=-0.22, pan_by_pitch=0.18,
             delay=dict(time=60.0 / bpm * 1.5, fb=0.34, mix=0.34, pingpong=True, damp=2600.0),
             rev=0.5, room=0.96, humanize_ms=6, humanize_vel=0.05),
        dict(notes=ping, inst=I.sine_ping, db=-17.5, pan=0.46,
             delay=dict(time=60.0 / bpm * 1.0, fb=0.52, mix=0.55, pingpong=True, damp=2200.0),
             rev=0.58, room=0.97),
    ]
    mix = stereo_of(parts, L, tail, bpm, "frost")
    return finish(mix, L, lp=9000.0, warmth_db=0.6, air_db=0.4), L, bpm


# THE ONE-LINE SWITCH: which "Signal" take ships as assets/audio/music/title.wav. The others stay generator
# functions only -- rendering them into assets/ would ship them in the web export for nothing.
TITLE_VARIANTS = {"A": track_title_sonar, "B": track_title_radio, "C": track_title_orbit,
                  "legacy": track_title_legacy}
TITLE_VARIANT = "legacy"   # user, 2026-09-10, after listening on the phone: "I still like the Old music
                            # so let's go with that." A/B/C are kept below for the record, not shipped.

# Non-zero only for take A ("sonar"): the sample where its logo motif hands off to the looping bed --
# see the "THE LOGO PLAYS ONCE" note on track_title_sonar. Callers that write title.wav's smpl loop
# chunk (write_wav's loop_begin=) should use this so the intro plays once instead of every 30 s; a
# switch to another TITLE_VARIANT gets 0 (loop the whole buffer) until that take gets the same design.
TITLE_LOOP_BEGIN = (loop_samples(64.0, 8)[0] // 8) * 4 if TITLE_VARIANT == "A" else 0

TRACKS = {
    "title": TITLE_VARIANTS[TITLE_VARIANT],
    "meadow_day": track_meadow_day,
    "meadow_night": track_meadow_night,
    "violet": track_violet,
    "chrome": track_chrome,
    "hub": track_hub,
    "space": track_space,
    "event": track_event,
    "dust": track_dust,
    "chalk": track_chalk,
    "frost": track_frost,
}


if __name__ == "__main__":
    # Render ONLY the title, without regenerating anything else (build_all.py rewrites every asset in the
    # game, which clobbers anyone else's work in progress):
    #   python3 tools/gen/audio/music.py                  -> assets/audio/music/title.wav, from TITLE_VARIANT
    #   python3 tools/gen/audio/music.py --variants DIR   -> DIR/title_<A|B|C|legacy>.wav, never into assets/
    import os
    import sys
    here = os.path.dirname(os.path.abspath(__file__))
    if len(sys.argv) > 2 and sys.argv[1] == "--variants":
        # only take A has a one-shot logo (see TITLE_LOOP_BEGIN); the others still loop the whole buffer.
        jobs = [(os.path.join(sys.argv[2], "title_%s.wav" % k), fn, TITLE_LOOP_BEGIN if k == "A" else 0)
                for k, fn in TITLE_VARIANTS.items()]
    else:
        jobs = [(os.path.join(here, "..", "..", "..", "assets", "audio", "music", "title.wav"),
                 TRACKS["title"], TITLE_LOOP_BEGIN)]
    for path, fn, loop_begin in jobs:
        x, L, bpm = fn()
        size = S.write_wav(path, x, loop=True, loop_begin=loop_begin)
        seam = S.loop_seam_error(x, loop_begin=loop_begin)
        print("%-18s %6.2f s  %6.2f bpm  peak %6.2f dBFS  %7.1f KB  seam %.4f (p99.9 step %.4f)  loop_begin %d" % (
            os.path.basename(path), L / float(S.SR), bpm, S.to_db(S.peak(x)), size / 1024.0,
            seam["seam_jump"], seam["p999_step"], loop_begin))
