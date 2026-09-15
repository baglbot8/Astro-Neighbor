#!/usr/bin/env python3
"""Post-process a Godot web export in place (called by tools/publish_web.sh).

    web_postprocess.py <export dir> <build stamp>

Environment: ASTRO_ENGINE_CACHE=off publishes the kill switch (the page unregisters the engine worker
and deletes its caches instead of using them). Anything else, or unset, publishes the cache on.

What it does to <export dir>:
  * index.html: <meta name="astro-build"> right after <head> (as before: `curl -s <url> | grep astro-build`),
    <meta name="astro-engine" content="<sha256 of index.wasm>">, and before </head> the engine-cache page
    script (tools/web/engine_cache_head.js, which asks for index.wasm?h=<sha256> and index.pck?h=<sha256 of
    the pck>) and the read-only perf helper (tools/web/perf_head.js).
  * astro-engine-sw.js: the engine-only cache worker, copied byte for byte.
It never writes index.service.worker.js (publish_web.sh owns that constant killer) and never touches
index.wasm, index.js or index.pck. Safe to run twice: an earlier injection is replaced, not doubled.
"""
import hashlib
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BEGIN = "<!-- astro-web:begin -->"
END = "<!-- astro-web:end -->"


def read(path):
    with io.open(path, encoding="utf-8") as f:
        return f.read()


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: web_postprocess.py <export dir> <build stamp>")
    out, stamp = sys.argv[1], sys.argv[2]
    if not re.fullmatch(r"[0-9A-Za-z._-]+", stamp):
        sys.exit("build stamp has unexpected characters: %r" % stamp)
    html_path = os.path.join(out, "index.html")
    wasm_path = os.path.join(out, "index.wasm")
    for p in (html_path, wasm_path):
        if not os.path.isfile(p):
            sys.exit("missing %s" % p)

    # Off unless asked for: the user dropped the engine cache on 2026-09-15 ("Skip it for now") after it failed two
    # critics on WebKit memory (docs/OPEN_ISSUES.md 60). ASTRO_ENGINE_CACHE=on brings it back.
    enabled = os.environ.get("ASTRO_ENGINE_CACHE", "off").strip().lower() == "on"
    engine_hash = sha256_file(wasm_path)
    pck_path = os.path.join(out, "index.pck")
    if not os.path.isfile(pck_path):
        sys.exit("missing %s" % pck_path)
    pck_hash = sha256_file(pck_path)

    head_js = read(os.path.join(HERE, "engine_cache_head.js"))
    head_js = head_js.replace("__ASTRO_ENGINE_SHA256__", engine_hash)
    head_js = head_js.replace("__ASTRO_PCK_SHA256__", pck_hash)
    head_js = head_js.replace("__ASTRO_ENGINE_CACHE_ENABLED__", "true" if enabled else "false")
    if "__ASTRO_" in head_js:
        sys.exit("engine_cache_head.js still has an unfilled placeholder")
    perf_js = read(os.path.join(HERE, "perf_head.js")).strip()
    for js in (head_js, perf_js):
        if "</script" in js.lower():
            sys.exit("a head script contains </script>")

    html = read(html_path)
    # Idempotent: drop anything a previous run injected.
    html = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), "", html, flags=re.S)
    if html.count("<head>") != 1 or html.count("</head>") != 1:
        sys.exit("index.html does not have exactly one <head> and </head>")

    top = "%s<meta name=\"astro-build\" content=\"%s\"><meta name=\"astro-engine\" content=\"%s\">%s" % (
        BEGIN, stamp, engine_hash, END)
    html = html.replace("<head>", "<head>" + top, 1)
    bottom = "%s\n<script>\n%s</script>\n<script>%s</script>\n%s" % (BEGIN, head_js, perf_js, END)
    html = html.replace("</head>", bottom + "</head>", 1)
    with io.open(html_path, "w", encoding="utf-8") as f:
        f.write(html)

    sw_src = os.path.join(HERE, "astro-engine-sw.js")
    with open(sw_src, "rb") as f:
        sw_bytes = f.read()
    with open(os.path.join(out, "astro-engine-sw.js"), "wb") as f:
        f.write(sw_bytes)

    print("web_postprocess: stamp=%s engine sha256=%s pck sha256=%s cache=%s" % (
        stamp, engine_hash, pck_hash[:16], "on" if enabled else "OFF (kill switch)"))


if __name__ == "__main__":
    main()
