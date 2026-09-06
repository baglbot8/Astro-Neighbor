#!/bin/zsh
# Static + runtime error check for the whole project.
# Usage: tools/check.sh [scene.tscn ...]
# With no args: imports project, then runs every scene under showcase/ and src/world/world.tscn headless for a few frames.
# Exit code 1 if any ERROR / SCRIPT ERROR / Parse Error is printed.
set -u
setopt null_glob
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
fail=0
echo "== import =="
out=$(godot --headless --path . --import 2>&1)
if echo "$out" | grep -qiE "SCRIPT ERROR|Parse Error|ERROR:"; then
  echo "$out" | grep -iE "SCRIPT ERROR|Parse Error|ERROR:|at:|line" | head -60
  fail=1
else
  echo "import clean"
fi
if [ $# -gt 0 ]; then
  scenes=("$@")
else
  scenes=(src/world/world.tscn)
  for f in showcase/*.tscn; do [ -f "$f" ] && scenes+=("$f"); done
fi
for s in "${scenes[@]}"; do
  echo "== run $s (headless, 3s) =="
  out=$(godot --headless --path . "res://$s" -- --quit-at=3 --skip-title 2>&1)
  if echo "$out" | grep -qiE "SCRIPT ERROR|Parse Error|ERROR:|WARNING: .*(nonexistent|not found|missing)"; then
    echo "$out" | grep -iE "SCRIPT ERROR|Parse Error|ERROR:|WARNING:|at:|line" | head -60
    fail=1
  else
    echo "ok"
  fi
done
if [ $fail -ne 0 ]; then echo "CHECK FAILED"; exit 1; fi
echo "CHECK PASSED"
