#!/usr/bin/env python3
"""Regenerate every Astro Neighbor audio asset.

    python3 tools/gen/audio/build_all.py             # everything
    python3 tools/gen/audio/build_all.py --only meadow_day,ui_buy
    python3 tools/gen/audio/build_all.py --music      # music only   (--sfx / --voices likewise)
    python3 tools/gen/audio/build_all.py --viz DIR    # also write waveform/spectrogram PNGs into DIR
    python3 tools/gen/audio/build_all.py --stems      # print per-stem levels for each music track

Outputs: assets/audio/sfx/*.wav (mono/stereo 16-bit 44.1 kHz), assets/audio/music/*.wav (stereo, with a
'smpl' loop chunk; loops are a whole number of 5120-sample QOA frames and carry a 2-frame copy of their
start after the loop end so Godot's QOA loop wrap is click-free -- see synth.write_wav). Prints a table (name, seconds, peak dBFS, size) and validates every file:
no clipping, no DC offset, faded edges (no clicks), loop seam continuity for loops, size limits.
"""
import argparse
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")

import numpy as np  # noqa: E402
import synth as S  # noqa: E402
import sfx as SFX  # noqa: E402
import voices as V  # noqa: E402
import music as M  # noqa: E402

MUSIC_MAX_BYTES = 6 * 1024 * 1024


def validate(name, x, loop, is_music):
    problems = []
    pk = S.peak(x)
    if pk > S.db(-0.5):
        problems.append("peak %.2f dBFS too hot" % S.to_db(pk))
    if is_music and abs(S.to_db(pk) - (-1.0)) > 0.6:
        problems.append("music peak %.2f dBFS (want -1)" % S.to_db(pk))
    if (not is_music) and abs(S.to_db(pk) - (-3.0)) > 0.6:
        problems.append("sfx peak %.2f dBFS (want -3)" % S.to_db(pk))
    m = S.to_mono(x)
    dc = float(np.mean(m))
    if abs(dc) > 2e-3:
        problems.append("DC offset %.4f" % dc)
    # clipping: runs of full-scale samples
    full = np.abs(x) >= 0.999
    if full.any():
        problems.append("%d full-scale samples" % int(full.sum()))
    if loop:
        e = S.loop_seam_error(x)
        if e["ratio"] > 1.0:
            problems.append("loop seam jump %.4f > p99.9 step %.4f" % (e["seam_jump"], e["p999_step"]))
    else:
        # a 3 ms linear fade keeps the first/last sample ~0 and the first 0.5 ms under ~0.17 x peak
        edge = S.n_samples(0.0005)
        if abs(float(x[..., 0].max())) > 0.02 or abs(float(x[..., -1].max())) > 0.02 \
                or np.max(np.abs(x[..., :edge])) > 0.25 or np.max(np.abs(x[..., -edge:])) > 0.25:
            problems.append("edges not faded (click risk)")
    return problems


def row(name, x, size, extra=""):
    return "%-22s %7.3fs  %6.2f dBFS  %8.1f KB  %s" % (name, S.length(x) / S.SR, S.to_db(S.peak(x)), size / 1024.0, extra)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--music", action="store_true")
    ap.add_argument("--sfx", action="store_true")
    ap.add_argument("--voices", action="store_true")
    ap.add_argument("--viz", default="")
    ap.add_argument("--stems", action="store_true")
    args = ap.parse_args()
    only = set(filter(None, args.only.split(",")))
    do_all = not (args.music or args.sfx or args.voices)
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    if args.viz:
        os.makedirs(args.viz, exist_ok=True)
        import viz
    failures = []
    total_bytes = 0
    t_start = time.time()

    print("== SFX ==")
    if do_all or args.sfx:
        for name in SFX.SFX:
            if only and name not in only:
                continue
            x, loop = SFX.render(name)
            path = os.path.join(SFX_DIR, name + ".wav")
            size = S.write_wav(path, x, loop=loop)
            total_bytes += size
            probs = validate(name, x, loop, False)
            print(row(name, x, size, ("LOOP(+%d tail) " % S.LOOP_TAIL if loop else "") + ("stereo " if S.is_stereo(x) else "mono ") +
                      "centroid %5d Hz" % S.spectral_centroid(x) + ("  !! " + "; ".join(probs) if probs else "")))
            if probs:
                failures.append((name, probs))
            if args.viz and name in ("footstep_grass_0", "jump", "ui_buy", "quest_complete", "rocket_loop", "collect_stardust"):
                viz.render_png(path, os.path.join(args.viz, name + ".png"), title=name)

    print("== VOICES ==")
    if do_all or args.voices:
        for profile in V.PROFILES:
            for i in range(5):
                name = "voice_%s_%d" % (profile, i)
                if only and name not in only:
                    continue
                x = V.render(profile, i)
                path = os.path.join(SFX_DIR, name + ".wav")
                size = S.write_wav(path, x)
                total_bytes += size
                probs = validate(name, x, False, False)
                dur = S.length(x) / S.SR
                if not (0.055 <= dur <= 0.125):
                    probs.append("duration %.3f outside 60-120 ms" % dur)
                print(row(name, x, size, "centroid %5d Hz" % S.spectral_centroid(x) + ("  !! " + "; ".join(probs) if probs else "")))
                if probs:
                    failures.append((name, probs))

    print("== MUSIC ==")
    if do_all or args.music:
        for name, fn in M.TRACKS.items():
            if only and name not in only:
                continue
            t0 = time.time()
            x, L, bpm = fn()
            assert S.length(x) == L
            path = os.path.join(MUSIC_DIR, name + ".wav")
            size = S.write_wav(path, x, loop=True)
            total_bytes += size
            probs = validate(name, x, True, True)
            if size > MUSIC_MAX_BYTES:
                probs.append("size %.2f MB > 6 MB" % (size / 1e6))
            seam = S.loop_seam_error(x)
            print(row(name, x, size, "LOOP %6.2f bpm  rms %5.1f dB  seam %.4f/%.4f  (%.1fs render)%s" % (
                bpm, S.to_db(S.rms(x)), seam["seam_jump"], seam["p999_step"], time.time() - t0,
                ("  !! " + "; ".join(probs)) if probs else "")))
            if args.stems:
                for stem, r, p in M.STEM_STATS.get(name, []):
                    print("      %-14s rms %6.1f  peak %6.1f" % (stem, r, p))
            if probs:
                failures.append((name, probs))
            if args.viz:
                viz.render_png(path, os.path.join(args.viz, name + ".png"), title=name, bpm=bpm)

    # totals
    def dir_size(d):
        return sum(os.path.getsize(os.path.join(d, f)) for f in os.listdir(d) if f.endswith(".wav"))
    tot = dir_size(SFX_DIR) + dir_size(MUSIC_DIR)
    print("== total assets/audio: %.1f MB in %d files (%.1fs) ==" % (
        tot / 1e6, len([f for f in os.listdir(SFX_DIR) if f.endswith(".wav")]) + len([f for f in os.listdir(MUSIC_DIR) if f.endswith(".wav")]),
        time.time() - t_start))
    if tot > 60e6:
        failures.append(("assets/audio", ["total %.1f MB > 60 MB" % (tot / 1e6)]))
    if failures:
        print("VALIDATION FAILED:")
        for n, p in failures:
            print("  %s: %s" % (n, "; ".join(p)))
        sys.exit(1)
    print("all files valid")


if __name__ == "__main__":
    main()
