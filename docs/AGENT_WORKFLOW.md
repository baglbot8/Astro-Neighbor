# Agent Workflow

Before you start, read `docs/OPEN_ISSUES.md` — it lists known cross-domain problems so you do not spend time debugging someone else's bug.

## Builders
1. Read `docs/ARCHITECTURE.md` and `docs/STYLE_GUIDE.md` fully. Look at `reference/*.jpg` with the Read tool.
2. Build only in your owned folders (+ `showcase/<component>*.tscn`, `tests/director/*.json`).
3. Create a **showcase scene** that shows your work at its best AND under stress (e.g. `showcase/planets.tscn` cycles all 4 planets; `showcase/astronaut_turntable.tscn` rotates the character and plays each animation).
4. Iterate with your own eyes: `tools/check.sh`, then `tools/capture.sh showcase/x.tscn x 60` and Read the PNGs. Fix what you see. Repeat until it looks like the reference images.
5. Final report (this is what the critic reads): what you built, file list, how to view it, known limitations (be honest — hidden problems found by the critic count double).

### Your showcase scene MUST match gameplay lighting (hard-won rule)
A showcase whose lighting differs from the game is worse than no showcase — you will tune your art against a lie. Two builders have now been failed for this:
* The NPC showcase rendered in a blown-out white void (luma p05 **0.787**, range **0.168**, value mean **0.966**, blown **23.5%** — all four palette gates failed). Eight Zorp iterations and nine Bolt iterations were judged in it, which is why every character shipped 0.11-0.20 saturation *below* its own spec swatch and Zorp's hue drifted lavender to pink.
* The rocket showcase staged the player 9 m from the pad already facing it, which hid the fact that the pad is off-screen from the real spawn on all four planets — the user's actual complaint.

So: **instantiate `res://src/world/environment.tscn` in your showcase**, use the gameplay camera framing (28 deg pitch, FOV 45, 6.5 m), and start from the real spawn position and facing. Before you trust any showcase, run `python3 tools/palette.py` on it and confirm it lands in the same band as a real gameplay frame. Always confirm your final result in `src/world/world.tscn` too.

### Builders must NOT edit `docs/`
`docs/ARCHITECTURE.md`, `STYLE_GUIDE.md`, `QUALITY_BAR.md` and this file are the contract you are graded against. Editing them yourself to match your implementation invalidates the review. If you believe a spec number is wrong, **say so in your report with the measurement that proves it** and let the orchestrator amend the doc. (This already happened once: a builder measured that AC eye spacing is 28-35%, not the 40% the guide claimed. The measurement was correct and the doc was amended — but by the orchestrator, after review.)

## Critics
Follow `docs/QUALITY_BAR.md` exactly. You are not the builder's friend. Look at frames. Try to break it. Output the verdict block.

## Loop
Orchestrator sends FAIL verdicts back to the builder (same agent, via SendMessage, so context is kept) with the blocking list. Builder fixes, reports, critic re-reviews. Repeat until PASS. Then integration critic plays the whole game end-to-end.

## Tools cheat-sheet
```
tools/check.sh                                   # errors anywhere?
tools/check.sh showcase/planets.tscn             # one scene
tools/capture.sh showcase/planets.tscn planets 90            # 90 frames @30fps -> ~/.astro_captures/planets/
tools/capture.sh src/world/world.tscn walk 330 tests/director/walk_and_jump.json --planet=home --new-game
tools/snap.sh src/world/world.tscn home 2 --planet=home --new-game --time=21   # one PNG after 2 s, at night
godot --path . res://showcase/x.tscn -- --skip-title --quit-at=5           # run & auto-quit
```
Director timeline format: see header of `src/autoload/director.gd`.
macOS stops drawing a window that is fully covered by another window. capture.sh/snap.sh open the window at a random position and always-on-top to avoid this; if you run godot by hand for captures add `--always-on-top --position 100,100` BEFORE the `--`. If a capture has many identical frames, that is why — rerun.
Godot prints `CPU render time ... average: X ms/frame` at the end of capture.sh — that's your perf number.
