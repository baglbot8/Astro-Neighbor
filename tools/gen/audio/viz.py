"""Waveform + spectrogram PNG renderer (PIL only) for sanity-checking generated audio."""
import math
import numpy as np
from PIL import Image, ImageDraw
import synth as S


def _spectrogram(mono, n_fft=2048, hop=512, fmax=12000.0):
    n = len(mono)
    if n < n_fft:
        mono = np.concatenate([mono, np.zeros(n_fft - n)])
        n = n_fft
    frames = 1 + (n - n_fft) // hop
    win = np.hanning(n_fft)
    idx = np.arange(n_fft)[None, :] + hop * np.arange(frames)[:, None]
    spec = np.abs(np.fft.rfft(mono[idx] * win, axis=1))
    freqs = np.fft.rfftfreq(n_fft, 1.0 / S.SR)
    keep = freqs <= fmax
    spec = spec[:, keep]
    mag = 20.0 * np.log10(spec + 1e-6)
    return mag, freqs[keep]


def _colormap(v):
    """v in [0,1] -> RGB (dark navy -> purple -> orange -> cream)."""
    stops = [(0.0, (12, 14, 40)), (0.35, (90, 40, 130)), (0.65, (230, 110, 60)), (1.0, (255, 245, 210))]
    for (a, ca), (b, cb) in zip(stops[:-1], stops[1:]):
        if v <= b:
            k = (v - a) / (b - a)
            return tuple(int(ca[i] + (cb[i] - ca[i]) * k) for i in range(3))
    return stops[-1][1]


def render_png(path_wav, path_png, title="", bpm=None, beats_per_bar=4, width=1400):
    x, rate, has_loop = S.read_wav(path_wav)
    if has_loop:
        x = x[..., :has_loop]   # analyse the loop region only (the file carries a short tail copy)
    mono = S.to_mono(x)
    n = len(mono)
    dur = n / rate
    wave_h, spec_h, pad = 220, 360, 30
    W = width
    img = Image.new("RGB", (W, wave_h + spec_h + pad * 3 + 30), (24, 24, 32))
    d = ImageDraw.Draw(img)
    # header
    pk = S.peak(x)
    d.text((10, 8), "%s  |  %.2fs  peak %.2f dBFS  rms %.1f dBFS  %s  loop_chunk=%s" % (
        title, dur, S.to_db(pk), S.to_db(S.rms(mono)), "stereo" if S.is_stereo(x) else "mono", has_loop),
        fill=(230, 230, 230))
    # waveform (min/max per column)
    top = 30 + pad
    d.rectangle([0, top, W, top + wave_h], fill=(16, 16, 24))
    cols = np.array_split(np.arange(n), W)
    mid = top + wave_h // 2
    for cx, ids in enumerate(cols):
        if len(ids) == 0:
            continue
        seg = mono[ids]
        lo, hi = float(seg.min()), float(seg.max())
        y0 = mid - int(hi * (wave_h // 2 - 4))
        y1 = mid - int(lo * (wave_h // 2 - 4))
        col = (120, 200, 255) if max(abs(lo), abs(hi)) < 0.89 else (255, 90, 90)
        d.line([cx, y0, cx, y1], fill=col)
    # clip guide lines at -1 dBFS
    g = int(S.db(-1.0) * (wave_h // 2 - 4))
    d.line([0, mid - g, W, mid - g], fill=(80, 60, 60))
    d.line([0, mid + g, W, mid + g], fill=(80, 60, 60))
    # spectrogram
    stop = top + wave_h + pad
    mag, freqs = _spectrogram(mono)
    lo_db, hi_db = -60.0, float(np.percentile(mag, 99.5))
    norm = np.clip((mag - lo_db) / (hi_db - lo_db), 0.0, 1.0)
    # resample to W x spec_h (log-ish frequency axis)
    frames, bins = norm.shape
    fx = np.linspace(0, frames - 1, W).astype(int)
    f_edges = np.geomspace(40.0, freqs[-1], spec_h + 1)
    arr = np.zeros((spec_h, W, 3), dtype=np.uint8)
    for r in range(spec_h):
        f0, f1 = f_edges[spec_h - 1 - r], f_edges[spec_h - r]
        b0 = int(np.searchsorted(freqs, f0))
        b1 = max(b0 + 1, int(np.searchsorted(freqs, f1)))
        row = norm[fx, b0:b1].max(axis=1)
        for c in range(W):
            arr[r, c] = _colormap(float(row[c]))
    img.paste(Image.fromarray(arr), (0, stop))
    # beat grid
    if bpm:
        spb = 60.0 / bpm
        b = 0
        t = 0.0
        while t < dur:
            cx = int(t / dur * W)
            is_bar = (b % beats_per_bar) == 0
            colr = (255, 255, 255) if is_bar else (140, 140, 160)
            d.line([cx, top + wave_h, cx, top + wave_h + 8 if not is_bar else top + wave_h + 14], fill=colr)
            if is_bar:
                d.text((cx + 2, top + wave_h + 2), str(b // beats_per_bar + 1), fill=(200, 200, 220))
            t += spb
            b += 1
    # frequency labels
    for f in (100, 200, 500, 1000, 2000, 5000, 10000):
        if f < f_edges[0] or f > f_edges[-1]:
            continue
        r = spec_h - int((math.log(f) - math.log(f_edges[0])) / (math.log(f_edges[-1]) - math.log(f_edges[0])) * spec_h)
        d.text((4, stop + r - 6), "%dHz" % f, fill=(255, 255, 255))
    # loop seam preview: last 2048 + first 2048 samples zoomed
    seam_y = stop + spec_h + 4
    d.text((10, seam_y), "seam (last 2048 | first 2048 samples):", fill=(200, 200, 200))
    seg = np.concatenate([mono[-2048:], mono[:2048]])
    sx0, sw = 300, W - 320
    sh = 22
    for i in range(sw):
        j0 = int(i / sw * len(seg))
        j1 = max(j0 + 1, int((i + 1) / sw * len(seg)))
        v = seg[j0:j1]
        y0 = seam_y + sh // 2 - int(v.max() * sh / 2)
        y1 = seam_y + sh // 2 - int(v.min() * sh / 2)
        d.line([sx0 + i, y0, sx0 + i, y1], fill=(255, 210, 120))
    d.line([sx0 + sw // 2, seam_y, sx0 + sw // 2, seam_y + sh], fill=(255, 80, 80))
    img.save(path_png)
    return path_png


if __name__ == "__main__":
    import sys
    render_png(sys.argv[1], sys.argv[2], title=sys.argv[1], bpm=float(sys.argv[3]) if len(sys.argv) > 3 else None)
