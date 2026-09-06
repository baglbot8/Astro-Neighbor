#!/bin/zsh
# Render a scene to PNG frames so a human or critic can LOOK at it.
# Usage: tools/capture.sh <scene path under res://> <name> [frames=60] [director.json] [extra godot user args...]
# Output: $ASTRO_CAPTURE_DIR/<name>/f00000000.png ... (default $HOME/.astro_captures)
# Examples:
#   tools/capture.sh showcase/astronaut_turntable.tscn astronaut 90
#   tools/capture.sh src/world/world.tscn walk 300 tests/director/walk_and_jump.json --planet=home --new-game
# Tip: view the LAST frame first (ls | tail -1), then a few earlier ones for motion.
set -u
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
scene="$1"; name="$2"; frames="${3:-60}"; director="${4:-}"
shift 2; [ $# -gt 0 ] && shift; [ $# -gt 0 ] && shift
root="${ASTRO_CAPTURE_DIR:-$HOME/.astro_captures}"
out="$root/$name"
rm -rf "$out"; mkdir -p "$out"
args=(--skip-title)
if [ -n "$director" ]; then args+=("--director=res://$director"); fi
args+=("$@")
pos="$((RANDOM % 500)),$((RANDOM % 350))"
godot --path . "res://$scene" --always-on-top --position "$pos" --write-movie "$out/f.png" --quit-after "$frames" --fixed-fps 30 -- "${args[@]}" 2>&1 | grep -vE "^$" | tail -40
rm -f "$out/f.wav"
count=$(ls "$out"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "captured $count frames -> $out"
ls "$out" | tail -3
