#!/bin/zsh
# Quick single screenshot of a scene after N seconds (no movie mode, real-time). Faster than capture.sh.
# Usage: tools/snap.sh <scene under res://> <name> [seconds=2] [extra user args...]
# Output: $ASTRO_CAPTURE_DIR/snaps/<name>.png
set -u
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
scene="$1"; name="$2"; secs="${3:-2}"
shift 2; [ $# -gt 0 ] && shift
root="${ASTRO_CAPTURE_DIR:-$HOME/.astro_captures}/snaps"
mkdir -p "$root"
tmpjson="$(mktemp -t astro_snap).json"
echo "[{\"t\": $secs, \"capture\": \"$name\"}, {\"t\": $(echo "$secs + 0.3" | bc), \"quit\": true}]" > "$tmpjson"
pos="$((RANDOM % 500)),$((RANDOM % 350))"
godot --path . "res://$scene" --always-on-top --position "$pos" -- --skip-title "--director=$tmpjson" "--capture-dir=$root" "$@" 2>&1 | grep -E "DIRECTOR|ERROR|SCRIPT|Parse" | tail -20
rm -f "$tmpjson"
echo "snap -> $root/$name.png"
