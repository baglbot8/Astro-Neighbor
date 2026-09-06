# Astro Neighbor

A cozy tiny-planet life sim. You are an astronaut on a small spherical world: walk and run all the
way around it, fly with a jetpack, collect stardust, decorate your planet, do favours for your
neighbours, and take a rocket between four worlds.

Built in **Godot 4.7.1**. Every mesh, texture, shader and sound is generated procedurally by code
in this repository — there are no imported art or audio assets.

## Running it

Open the folder in Godot 4.7.1 and press play, or from a terminal:

```bash
godot --path . res://src/ui/title/title_screen.tscn
```

Handy flags (after a bare `--`):

```bash
# skip the title screen and start on a given planet — --new-game must come BEFORE --planet
godot --path . res://src/world/world.tscn -- --skip-title --new-game --planet=hub

# review the mobile front end on a desktop machine
godot --path . --resolution 2340x1080 res://src/world/world.tscn -- --skip-title --ui=mobile
```

## Controls

**Desktop** — WASD move, Shift run, Space jump (hold to fly), mouse look, wheel zoom, E interact,
Tab decorate, I bag, J favours, P pause.

**Mobile** — landscape only. Floating thumbstick on the left (push gently to walk, fully to run),
a context button on the right that names what you are near, jump and boost beside it, drag the
right of the screen to look, pinch to zoom.

## Layout

| path | what lives there |
|---|---|
| `src/autoload/` | game state, save, event bus, catalog, audio, scene routing, platform |
| `src/planet/` | planet mesh generation, biomes, props, collectibles |
| `src/player/` | the astronaut, its animation, the camera rig, the jetpack |
| `src/characters/` | neighbours, dialogue, favours |
| `src/decorations/` | 37 placeable decorations and the placement system |
| `src/rocket/` | the rocket, the pad, and the continuous launch-to-landing journey |
| `src/hub/` | Starport Plaza's buildings and shops |
| `src/world/` | world assembly, sky, lighting, day/night |
| `src/ui/` | desktop and mobile front ends |
| `docs/` | the architecture contract, art direction, quality bar, open issues |
| `tools/` | error checks, screenshot capture, palette and comparison analysis |

`docs/ARCHITECTURE.md` is the contract between systems; `docs/STYLE_GUIDE.md` carries the art
direction; `docs/OPEN_ISSUES.md` tracks known cross-cutting problems.

## Checks

```bash
tools/check.sh            # imports the project and runs every scene headless; fails on any error
tools/snap.sh <scene> <name> <seconds>   # one screenshot
tools/capture.sh <scene> <name> <frames> [director.json]   # a frame sequence
python3 tools/palette.py "label=frame.png"   # colour and contrast measurement
```

## A note on the reference images

Development used Animal Crossing screenshots and stock astronaut artwork as art direction. Those
files are **deliberately not in this repository** — they are not ours to redistribute.
`docs/STYLE_GUIDE.md` records what they showed, with measured numbers, so the guidance survives
without the images.
