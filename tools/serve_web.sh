#!/bin/zsh
# Build (if needed) and serve the web export on the local network, so a phone on the same
# Wi-Fi can play it in a browser. Prints the URL to open on the phone.
#
#   tools/serve_web.sh            serve the existing build
#   tools/serve_web.sh --build    re-export first, then serve
#
# The web export is forced onto the Compatibility (WebGL2) renderer. See docs/OPEN_ISSUES.md 31
# and 32 for what that changes. Stop the server with Ctrl-C.
set -u
PORT="${PORT:-8791}"
REPO="$(cd "$(dirname "$0")/.." && pwd)/Astro Neighbor Repo/Astro Neighbor"
OUT="$(cd "$(dirname "$0")/.." && pwd)/build/web"

if [ "${1:-}" = "--build" ]; then
	echo "exporting..."
	rm -rf "$OUT"; mkdir -p "$OUT"
	godot --headless --path "$REPO" --export-release "Web" || { echo "export failed"; exit 1; }
fi
[ -f "$OUT/index.html" ] || { echo "no build yet - run: tools/serve_web.sh --build"; exit 1; }

IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo localhost)"
echo ""
echo "  On this Mac:  http://localhost:$PORT/"
echo "  On a phone :  http://$IP:$PORT/     (same Wi-Fi, landscape)"
echo ""
echo "  Ctrl-C to stop."
echo ""
cd "$OUT" && python3 -m http.server "$PORT"
