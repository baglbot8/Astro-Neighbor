# Build plan: Stranded campaign (DRAFT)

Status: **DRAFT, 2026-09-10.** Written by the lead from `docs/CORE_LOOP.md` and two read-only code maps
taken the same day. The user approves each phase before it starts. Builders read this page and
CORE_LOOP.md; they do not edit either.

Revised the same day after the user's review: rocket parts are internal (no visible missing parts);
the rocket's finish goes from rusty to clean to sparkling to gold as parts are fitted, with a short
celebration each time; one project step per neighbour per in-game day, so a project spans three game
days; Orbit becomes Professor Comet, a scientist who guides you; old saves kept.

## Rules for every phase

* **Each phase ends playable.** The game boots and plays at the end of every phase, and the user can
  try it on the phone before the next phase starts.
* **One owner per file.** The owner lists below are disjoint. A builder that needs another file writes
  it in `needs_from_others`.
* **Every build gets a critic that did not write it** (QUALITY_BAR.md), up to two rounds.
* **The Director keeps working.** Campaign gates are off when `Director.is_active()`, unless a timeline
  opts in with a new `--campaign` flag, the same way `--intro` opts into the tutorial today
  (`intro_director.gd:92-98`). Existing timelines must not break.
* **Old saves are not stuck.** A save without campaign fields loads as "story finished": all planets
  open, no gates. Only a new game plays the campaign. (Lead's call: the user tests with a new game,
  and this keeps any old save working.)
* **Integration check after each phase:** `tools/check.sh`, all seven worlds boot, a Director
  play-through of the new part, and screenshots in the real game scene.

## What the code has today (2026-09-10 map)

| need | today | gap |
|---|---|---|
| campaign state | `GameState` has `flags`, friendship ints 0-100 per NPC, per-field save defaults (`game_state.gd:186-234`) | no parts, range, scrap or project fields |
| rocket range | picker lists every planet (`pad_destination_picker.gd:52`, `:91-97`) | no gate |
| rocket parts | parts are internal; `rocket_model.gd` builds the rocket in code (`:331-367`), all white today | the picker must show range; the finish must change per part (rusty → clean → sparkle → gold) |
| new-game start | tutorial beats with a Mayor Orbit radio call (`intro_director.gd`) | no crash, no story; Orbit is written as a mayor |
| scrap | a collectible kind can be added in `catalog.gd` + `collectible.gd` + `data/*.tres`; "scrap" is only a trash look (`trash_piece.gd:9`) | no scrap item or counter |
| two-currency prices | one int `price` in stardust (`shop_panel.gd:100-102,175`) | no scrap cost |
| multi-step projects | `favor_system.gd` is one item and one count per favor, by design | needs a new system |
| "place item near a spot" | decorations can be placed on any planet and save per planet (`decoration_manager.gd`) | no distance check |
| neighbour visits home | NPCs spawn only from their own planet's `.tres` (`world.gd:96-106`) | needs visitor spawning |

## Phase 1: Stranded start (the first slice)

Goal: a new game starts with the crash. The rocket's range is short. Scrap is on every world.
Stardust is rare.

**Play at the end:** new game → Professor Comet, a scientist watching the sky, sees the asteroid
coming → it hits your ship → you crash on home → the Professor radios you and tells you what to do →
you pick up scrap → your rocket is rusty and dirty → it can only reach tier 1 (Commons, Zorp, Bolt).

| builder | model | owns | does |
|---|---|---|---|
| A: campaign state | Sonnet | `src/autoload/game_state.gd`, new `src/campaign/campaign_data.gd` | new fields: `scrap`, `rocket_parts`, `campaign_active`, `story_done`, `project_step_day` (per neighbour, for the one-step-a-day rule); save + load with defaults, and a save without them loads as story finished; the tier table and part list as data; `add_scrap` / `spend_scrap`; new EventBus signals listed in `needs_from_others` for the lead to add |
| B: rocket range | Sonnet | `src/rocket/pad_destination_picker.gd` | the picker shows planets beyond the current tier as out of range and says how many parts you need; it shows the parts fitted |
| R: rocket finish | Opus (art direction against measured gates) | `src/rocket/rocket_model.gd`, the rocket's entries in `src/materials/material_lib.gd` | six finish stages driven by parts fitted: 0 rusty and dirty, 1-3 each cleaner, 4 clean with sparkle, 5 gold instead of white; procedural only; every stage passes the STYLE_GUIDE palette gates, measured per region in the real game scene |
| C: crash intro | Opus (story beat, camera and art) | `src/onboarding/*`, `src/characters/npc_data.gd` (Professor Comet's name and lines only) | the asteroid hit and crash landing as one continuous shot (no cut, R2.5); Mayor Orbit is shown as Professor Comet (the code id `mayor_orbit` stays); the Professor's radio call is rewritten as a scientist who saw the hit; the tutorial beats become: move, pick up scrap, look at the rocket, fly to tier 1 |
| D: scrap and economy | Sonnet | `src/planet/collectible.gd`, `src/autoload/catalog.gd`, `src/planet/data/*.tres`, `src/planet/trash_piece.gd`, `src/ui/hud/hud.gd` | scrap pickup (its own look, not the shard fallback); a few per world per day; stardust shards removed from home, hub and Grig; trash pays scrap; HUD scrap counter |

Lead: adds EventBus signals and the `--campaign` flag in `director.gd`. Critics: one Sonnet critic
for A, B and D against a checklist; one Opus critic for C and R (a story beat, a camera shot, and six
rocket finishes judged on rendered frames).

## Phase 2: The first project, end to end (Bolt)

Goal: prove the whole loop on one world before writing the other four.

**Play at the end:** fly to Bolt → Bolt's three-step project over three game days → build a fix
from scrap at the crash site → place it on Bolt's yard → Bolt gives the part → fit it with scrap →
the camera zooms in on the astronaut celebrating → the rocket is a little cleaner → the picker shows
a longer range.

| builder | model | owns | does |
|---|---|---|---|
| E: project system | Opus (a new system across quests, decorating and dialogue) | new `src/projects/project_system.gd`, `src/projects/project_markers.gd` | ordered steps with these step types: talk, find (visit markers the system spawns), collect, build, place (item X within N m of a spot, using `decoration_manager.get_instances()`); one step per neighbour per in-game day (the neighbour says "come back tomorrow"); friendship per step; save state |
| F: build bench | Sonnet | new `src/projects/build_bench.gd` + scene, `src/ui/shop/shop_panel.gd` | a bench at the crash site builds fixes for scrap (+ stardust for some); fitting a part costs gift + scrap; shop prices can include scrap |
| G: Bolt content | Sonnet | new `src/projects/data/bolt.gd`, `src/dialogue/` Bolt lines | Bolt's three steps, lines and the part |
| N: part celebration | Opus (camera and body language) | new `src/campaign/part_celebration.gd` | a short cutscene when a part is fitted: the camera zooms in on the astronaut celebrating (body language, the visor stays opaque), then shows the rocket's new finish; skippable; a new sound that follows STYLE_GUIDE "Sound identity", generated by the lead alone after the builders finish (never `build_all.py` while builders work) |

Lead: wires the project system into `conversation.gd` if E asks for it. Critic: Opus for E and N, Sonnet for
F and G. A real play-through is timed: Bolt should take about an hour (CORE_LOOP pacing).

## Phase 3: The other four worlds

**Play at the end:** the whole story up to the last part, and a game board on the Commons that replays
every mini-game you have unlocked.

**Changed 2026-09-12, then 2026-09-13.** The first plan had one fetch-style step per project that needed
another world. The user, after playing on their phone, found fetch trips "will get old fast and heats up
the phone" (CORE_LOOP "Mini-games instead of fetch trips"). Then two mini-games looked too few for five
neighbours, so they picked three more, occasional light links on two worlds only, and replays from the
Commons (CORE_LOOP "More mini-games, one per neighbour" and "Replays from the Commons"). So this phase runs
in two steps.

### Phase 3a: before the world builders (in parallel)

| builder | model | owns | does |
|---|---|---|---|
| GUIDE | Sonnet | new `src/minigames/guide_game.gd` | "guide them home"; first look Fen's glow moths |
| HUNT | Sonnet | new `src/minigames/hunt_game.gd` | "signal hunt"; first look Grig's springs |
| CALL | Sonnet | new `src/minigames/call_game.gd` | "call and response": Simon says with Use, Jump, Fly and Emote; first use Vela |
| LINK | Sonnet | `src/projects/project_system.gd`, `src/dialogue/conversation.gd`, `src/characters/npc.gd` | a "talk" step that another neighbour completes (a light link) |
| BOARD | Opus (travel, arrival timing, UI and rewards across systems) | new board files in `src/minigames/`, the `src/world/world.gd` hook, `src/ui/pause/dev_menu.gd` | the Commons game board and the replay trip |

Lead, before they start (2026-09-13): registered "guide", "hunt" and "call" in `MinigameSystem.GAMES`
(`has_game()` checks the file, so this is safe before the scripts exist), and added
`ProjectSystem.played_minigames()` for the board. Critics: Opus for all five - game feel judged on real
touch routing and rendered frames, save state, and the trip.

### Phase 3b: the four worlds (in parallel, after 3a passes)

Four Sonnet builders, one per world: `src/projects/data/{zorp,fen,grig,vela}.gd` and each world's lines.
Sonnet critics with a checklist; the lead times one full play-through.

| neighbour | tier | world problem | the mini-game step | light link |
|---|---|---|---|---|
| Zorp | 1 | the rivers are dimming | ring run along the old river ("rings", flavour "light") | none |
| Fen | 2 | stuck at dusk | guide the glow moths home to a pool ("guide", flavour "moth") | none |
| Grig | 2 | too dry | dowse for water under the chalk ("hunt", look "spring") | a seed pouch from Zorp |
| Vela | 3 | frozen and silent | Simon says with her array ("call") | the old warmth readings from Fen's logbook |

Each project keeps three steps on three game days, exactly one mini-game step, and ends with the part. A
`place` step needs a `find` step first to aim at a `marker:` spot, or a radius well over 3.5 m from the
home, pad or spawn. Every link world is reachable before the project that needs it: Zorp (tier 1) before
Grig (tier 2), and Fen (tier 2) before Vela (tier 3).

Still planned, not replaced by the board: an unlocked mini-game can come back as one of that neighbour's
favours (the user, 2026-09-12; CORE_LOOP "They come back as favours"). That is `favor_system.gd` work, so it
belongs to Phase 4 builder J.

## Phase 4: Neighbours visit your crash site

**Play at the end:** between trips, a friend lands at your crash site and asks for something there.
Mayor Orbit becomes Professor Comet in full, with no mayor role.

| builder | model | owns | does |
|---|---|---|---|
| H: visitors | Sonnet | new `src/campaign/visitor_system.gd`, `src/world/world.gd` spawn hook | spawn a friend on home by a visit schedule; their home-planet spot stays empty while away |
| I: Commons | Sonnet | `src/hub/buildings/town_hall.gd` | no mayor role (renaming moves elsewhere or goes); Professor Comet's lines and room become a scientist's, watching the sky |
| J: favors | Sonnet | `src/favors/favor_system.gd` | favors rarely during the story; visit requests use its item-count plumbing; an unlocked mini-game can come back as a favour |

## Phase 5: The finale

**Play at the end:** the last part → Professor Comet spots the giant asteroid and calls everyone to the
Commons → the meeting → you fly the rocket into
the giant asteroid → it breaks into a shooting-star shower → friends give you a small new ship →
all planets open, Planet Score comes back on.

| builder | model | owns | does |
|---|---|---|---|
| K: meeting and choice | Sonnet | new `src/campaign/finale.gd`, finale lines | the meeting on the Commons, all friends there |
| L: asteroid flight | Opus (the big art moment) | `src/rocket/space_travel.*`, new asteroid and shower generators | one continuous shot; the shower is the fireworks |
| M: the new ship | Sonnet | `src/rocket/rocket_model.gd` (a second, small ship look) | the gift ship; post-story travel uses it |

Critic: Opus, on rendered frames in the real game scene.

## Phase 6: Pacing pass

A timed play-through of the whole story. Tune scrap, stardust and step sizes toward about one hour
per world. Every number changed is written down with the time it came from.

## Not in this plan

* What else to do after the story (CORE_LOOP open question).
* The comms voice and the new title music. That sound work is separate and already under way.
