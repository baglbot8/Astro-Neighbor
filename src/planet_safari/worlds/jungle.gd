extends SafariWorld
## THE TANGLE WAKES UP (docs/JUNGLE_PLANET_SPEC.md 4; built to the planet-safari rules of
## docs/PLANET_SAFARI_SPEC.md 11-17: the tiers of 11.2, the density BAND of 11.2b, Facing and Size of
## 11.1, the grade scale and the shared pacing director of 13-14, categories and "???" pages of 15.5;
## builder J2 SAFARI, 2026-09-29). Loaded by PlanetSafari when a safari starts on the jungle planet and
## freed when it ends: nothing here exists outside a safari (the user's rule 5), and nothing on the planet
## is changed or moved - every creature, glow and flower is this node's own mesh, laid among J1's trees.
## Built the way Fen's world is built (worlds/fen.gd), with the jungle's own cast.
##
## THE HOST IS MOSS, the swamp-folk shopkeeper (spec 3; npc id "moss", built by another builder). Moss is
## NOT a neighbour: no Friends page, no favour - so Moss is not a subject here, and the pacing director has
## no neighbour to bring. Moss only offers the look round ("Want a look around?") and says the review lines.
##
## Built only from the Tangle's own look (jungle.tres, planet/props/jungle_props.gd): a teal floor packed
## with knee-high broadleaf, spire palms, violet parasol trees, spiral plants, root arches over the trails,
## nine swamp pools with reeds and lily pads, two moons, amber / teal / magenta glows.
##
##   creatures        always about, in many places  LILY-HOPPERS (little peach hoppers wearing a lily leaf
##                                                   for a hat) on the rims of four pools - they plop in
##                                                   when rushed; GLOWTAILS (small violet climbers with an
##                                                   amber lamp on the tail) clinging to five palm trunks
##                                                   and a root arch - they scurry up out of sight when
##                                                   rushed; POOL-PEEPERS (round blue heads with eyes on
##                                                   stalks) peeking up out of four other pools, blowing
##                                                   bubbles; SPORE-PUFFS (drifting cream seed-balls with
##                                                   faces), the roamer; LANTERN-SNAILS on the trails at
##                                                   night. The pacing director brings a hopper out of a
##                                                   pool, a peeper up in one, a glowtail onto a trunk in
##                                                   view, or a puff.
##   common event     ~30 s, repeats                 THE GLIMMER SWARM - a firefly-like swarm circles low over
##                                                   a pool (three pools in turn)
##   uncommon events  ~12 s, repeats                 SPORE RAIN - a parasol tree lets go a shower of glowing
##                                                   spores (three trees); THE BLOOM BURST - a big bud on
##                                                   a stalk bursts open, twice
##   rare             once                           THE CANOPY GRAZER - a big, shy, long-necked grazer
##                                                   walks in, browses a parasol, lifts its head and hoots
##   rare day         1 day in 4                     THE GIANT BLOOM - a huge flower unfurls by the swamp
## RARITY follows the tier (SafariWorld.TIER_RARITY): creatures 1, the snails and the swarm 2, the rain and
## the burst 3, the grazer and the giant bloom 4.
##   sights           always there (spec 15.5)       THE ROOT ARCH (J1's arch over the trail by the landing
##                                                   pad) and THE DEEP POOL (the biggest pool): named props,
##                                                   nothing drawn. Rarity 1, pay as usual.
##   bonus            hidden, collector's only       A TINY REED HAT hung on a palm, A SHELL HOUSE at the end of
##                                                   the back trail, A HEART-SHAPED LILY PAD in a pool.
##                                                   Small, still, pay nothing.
## Sights and bonus subjects do not count toward the density band or the director (SafariWorld CATEGORY).
##
## ------------------------------------------------------------------------------------ THE PLACES
## As (degrees round from the start beside the pad, bearing from the start heading, + = right), from the
## layout logged at build (jungle.tres seed 173, radius 14: 1 degree = 0.244 m; the safari walk 1.5 m/s =
## 6.1 deg/s, a quarter round 15 s, the far side 29 s). The nine pools (Planet.crater_dirs order):
##   0 (121, 40)  hoppers                 5 (64,-114)  hoppers
##   1 (138,144)  hoppers                 6 (121,-136) -
##   2 (94, 133)  peepers; heart lily pad 7 (52, 31)   hoppers
##   3 (70, -13)  DEEP POOL; peepers;     8 (157, 51)  peepers; swarm 3
##                swarm 1
##   4 (129,-91)  peepers; swarm 2
## THE TRAILS MATTER: off J1's trails the knee-high broadleaf reaches the first-person lens (1.1 m up) and
## hides anything low (frames, 2026-09-29), so the bud, the giant bloom and the grazer stand on or beside a
## trail, and the glowtails cling to the palms nearest the trails.
## The glowtails' trunks, the spore-rain parasols, the bud and the grazer's place are picked by name
## from J1's props (RAIN_PARASOLS by name; the glowtails' palms and the grazer's parasol by rule: the
## ones nearest a trail) and logged at build with where they are.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned WARN (8 s) ahead with a SIGHT and a SOUND that duplicate each other: a line
## on screen, a sound heard anywhere on the planet, a glow on YOUR horizon toward the event (gone once you
## are within BEACON_NEAR_DEG), and the event's own cue (the swarm gathers high over its pool, the parasol's
## tiers start to glow, the bud swells and pulses, the grazer's glow spots come walking through the trees,
## the giant bud glows and swells). Nothing depends on reading them.
##   0:06-0:36  GLIMMER SWARM (1) over the deep pool. THE SWARM SPIRALS UP at +10..+13 and +22..+25 s.
##   0:22-0:34  SPORE RAIN (1). THE HEAVY SHOWER at +5..+8 s.
##   0:40-0:52  THE BLOOM BURST (1). FULL BLOOM +4..+9 s.
##   0:52-1:22  GLIMMER SWARM (2) over pool 4.
##   1:22-1:36  THE CANOPY GRAZER (rare, once): walks in along a trail through the warning, stops by a
##              parasol to browse, TURNS TO YOU, LIFTS ITS HEAD AND HOOTS 1:27-1:32, walks off.
##   1:24-1:36  SPORE RAIN (2), across the planet from the grazer: the rare's forced choice.
##   1:44-2:14  GLIMMER SWARM (3) over pool 8.
##   1:52-2:06  THE GIANT BLOOM (rare day) beside the back trail. OPEN AND GLOWING 1:58-2:03.
##   2:20-2:32  THE BLOOM BURST (2).
##   2:30-2:42  SPORE RAIN (3).
##   all 3 min  HOPPERS, GLOWTAILS, SPORE-PUFFS; LANTERN-SNAILS at night.
## The overlaps are measured centre to centre at build (logged "overlap"). The rares are short (14 s), as
## Fen's are (his header: a long rare was the one long gap in the wanderer runs).
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): one MultiMesh per part - the hoppers 2 draw calls, the glowtails
## 3, the peepers 2, the puffs 2, the snails 2, the glimmers 2, the burst petals 1. The grazer is 6 meshes, the giant
## bloom 3, the bud 2. Every solid mesh is PlanetMeshKit vertex colour on the planets' matte prop
## material; glow parts are the planet's own glow material (crystal_material, J1's glow beads); halos are
## the shipped star shader; particles are CPUParticles3D on the shipped sparkle material. No lights.
## Everything is built in `build` (warmed behind the fade) and only moved, shown or hidden afterwards.
##
## ------------------------------------------------------------------------------------ FACING AND SIZE
## FACING (spec 11.1): every creature, the grazer and the giant bloom carry "front" (every mesh faces -Z).
## The swarm's front is the heading of the glimmer nearest the lens. The hoppers, glowtails and puffs are
## CURIOUS: stand still with the camera up near one and it turns to you (a glowtail edges round its trunk
## to peek at you) - slowly, and only after CURIOUS_AFTER s (Fen's measured numbers), so Facing is a reward
## for waiting.
## SIZE BANDS (spec 11.1), Fen's formula from each subject's usual distance d: size_frac =
## tan(asin(r / d)) / tan(22.5 deg); band.x = that / 0.58; band.y = 1.65 x band.x, capped at 1.0 - so at
## the 45 degree lens there size scores 6 or less, and walking in or zooming reaches 10.
##   subject          radius  usual d  band
##   lily-hopper      0.20     3.0 m   0.28-0.46
##   glowtail         0.24     3.0 m   0.33-0.55
##   pool-peeper      0.18     3.0 m   0.25-0.41
##   spore-puff       0.20     3.0 m   0.28-0.46
##   lantern-snail    0.20     3.0 m   0.28-0.46
##   glimmer swarm    1.40     8.0 m   0.74-1.00
##   spore rain       1.30     7.0 m   0.79-1.00
##   bloom burst      0.90     6.0 m   0.63-1.00
##   canopy grazer    2.25    12.0 m   0.77-1.00   (GRAZER_SCALE 1.5 of the 1.5 m model radius)
##   giant bloom      1.40     9.0 m   0.66-1.00

## THE MANIFEST (spec 12.5 / 15.5; safari_world.gd THE MANIFEST). In Moss's voice (JUNGLE_PLANET_SPEC 3,
## CAST_VOICES_DRAFT 2): slow, warm, a little mysterious, loves the swamp; plain whole sentences a
## 10-year-old follows, no numbers, no game words, no verbal habit, every line <= 60 characters.
const MANIFEST := {
	"host": "moss",
	# JWIRE (2026-09-29): Moss's own five safari lines live once in MossLines.SAFARI_MANIFEST_LINES
	# (src/tangle/moss_lines.gd) so the stall's voice and the safari offer can never drift apart.
	"offer": MossLines.SAFARI_MANIFEST_LINES["offer"],
	"ask": MossLines.SAFARI_MANIFEST_LINES["ask"],
	"yes": MossLines.SAFARI_MANIFEST_LINES["yes"],
	"no": MossLines.SAFARI_MANIFEST_LINES["no"],
	"asleep": MossLines.SAFARI_MANIFEST_LINES["asleep"],
	"roster": [
		{"id": "lily_hopper", "name": "Lily-hopper", "tier": "creature", "category": "creature"},
		{"id": "glowtail", "name": "Glowtail", "tier": "creature", "category": "creature"},
		{"id": "pool_peeper", "name": "Pool-peeper", "tier": "creature", "category": "creature"},
		{"id": "spore_puff", "name": "Spore-puff", "tier": "creature", "category": "creature"},
		{"id": "lantern_snail", "name": "Lantern-snail", "tier": "night", "category": "creature"},
		{"id": "glimmer_swarm", "name": "The Glimmer Swarm", "tier": "common", "category": "event"},
		{"id": "spore_rain", "name": "Spore Rain", "tier": "uncommon", "category": "event"},
		{"id": "bloom_burst", "name": "The Bloom Burst", "tier": "uncommon", "category": "event"},
		{"id": "canopy_grazer", "name": "The Canopy Grazer", "tier": "rare", "category": "event"},
		{"id": "giant_bloom", "name": "The Giant Bloom", "tier": "rare_day", "category": "event"},
		# spec 15.5: two SIGHTS (always there, pay as usual) and three BONUS pages (hidden, small, pay
		# nothing). Neither counts toward the density band or the director.
		{"id": "root_arch", "name": "The Root Arch", "tier": "sight", "category": "sight"},
		{"id": "deep_pool", "name": "The Deep Pool", "tier": "sight", "category": "sight"},
		{"id": "reed_hat", "name": "A Tiny Reed Hat", "tier": "bonus", "category": "bonus"},
		{"id": "shell_house", "name": "A Shell House", "tier": "bonus", "category": "bonus"},
		{"id": "heart_lily", "name": "A Heart-shaped Lily Pad", "tier": "bonus", "category": "bonus"},
	],
	# The review's line about each photo, in Moss's voice. `%s` is the subject's name, always at the start
	# of a sentence.
	"review": {
		"no_subject": [
			"Just leaves. Leaves are nice too.",
			"Nothing in this one. The swamp was being shy.",
		],
		"Smudge": [
			"%s, I think. Soft, like swamp fog.",
			"%s. A bit blurry. Hold still next time.",
		],
		"Fair": [
			"%s. Yes, I can see it. Nice.",
			"%s. That is a good, clear one.",
		],
		"Fine": [
			"%s. Oh, that is lovely and sharp.",
			"%s. I would hang this one by my lamp.",
		],
		"Gallery": [
			"%s. Oh my. I have never seen it like that.",
			"%s. The whole swamp would want a copy.",
		],
		"moment": " And just at the right moment.",
	},
}

const Meshes := preload("res://src/planet_safari/worlds/jungle_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")
const SFX_DIR := "res://assets/audio/sfx/"

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
## "at" = the swarm place (SWARM_POOLS). THE SWARM SPIRALS UP (the moment) at SWARM_TURNS s into a run.
const SWARM_RUNS := [
	{"id": "glimmer_swarm", "start": 6.0, "end": 36.0, "at": 0},
	{"id": "glimmer_swarm_2", "start": 52.0, "end": 82.0, "at": 1},
	{"id": "glimmer_swarm_3", "start": 104.0, "end": 134.0, "at": 2},
]
const SWARM_TURNS := [10.0, 22.0]
const SWARM_TURN_SEC := 3.0
## "at" = the parasol (RAIN_PARASOLS). THE HEAVY SHOWER at RAIN_HEAVY_AT..+RAIN_HEAVY_SEC into a run.
const RAIN_RUNS := [
	{"id": "spore_rain", "start": 22.0, "end": 34.0, "at": 0},
	{"id": "spore_rain_2", "start": 84.0, "end": 96.0, "at": 1},
	{"id": "spore_rain_3", "start": 150.0, "end": 162.0, "at": 2},
]
const RAIN_HEAVY_AT := 5.0
const RAIN_HEAVY_SEC := 3.0
const BURST_RUNS := [
	{"id": "bloom_burst", "start": 40.0, "end": 52.0, "at": 0},
	{"id": "bloom_burst_2", "start": 140.0, "end": 152.0, "at": 0},
]
const BURST_OPEN_SEC := 1.6
const BURST_FULL := Vector2(4.0, 9.0)
const GRAZER_START := 82.0
const GRAZER_END := 96.0
const GRAZER_HOOT := Vector2(87.0, 92.0)
const GIANT_START := 112.0
const GIANT_END := 126.0
const GIANT_OPEN := Vector2(118.0, 123.0)

# ------------------------------------------------------------------------------ the places
## Pool indices (Planet.crater_dirs order): see the header's table.
const HOPPER_POOLS := [7, 5, 0, 1]
const SWARM_POOLS := [3, 4, 8]
const DEEP_POOL := 3
const HEART_POOL := 2
## J1's props by name (planet/props/jungle_props.gd names them in spawn order). A name that is missing
## falls back to the nearest prop of that kind to the fallback place (logged). The glowtails' palms are
## picked by rule instead (the palms nearest a trail, spread round: _build_tails).
const GLOWTAIL_ARCH := "RootArch0"
const RAIN_PARASOLS := ["Parasol15", "Parasol11", "Parasol13"]
const SIGHT_ARCH := "RootArch2"
const HAT_PALM := "SpirePalm7"

## A warning glow sits this far round from you toward its event (just inside your horizon), and fades out
## between BEACON_FULL_DEG and BEACON_NEAR_DEG (Fen's numbers: this world is 14 m, his 13).
const BEACON_AHEAD_DEG := 21.0
const BEACON_NEAR_DEG := 38.0
const BEACON_FULL_DEG := 53.0

# ------------------------------------------------------------------------------ SIZE BANDS (header)
const BAND_HOPPER := Vector2(0.28, 0.46)
const BAND_GLOWTAIL := Vector2(0.33, 0.55)
const BAND_PUFF := Vector2(0.28, 0.46)
const BAND_SNAIL := Vector2(0.28, 0.46)
const BAND_SWARM := Vector2(0.74, 1.00)
const BAND_RAIN := Vector2(0.79, 1.00)
const BAND_BURST := Vector2(0.63, 1.00)
const BAND_GRAZER := Vector2(0.77, 1.00)
const BAND_GIANT := Vector2(0.66, 1.00)

# ------------------------------------------------------------------------------ lily-hoppers
## Two a pool (three made the hoppers 0.31 of the careful player's photos over 49, cal3: the most of any)
const HOPPERS_PER_POOL := 2
const HOPPER_SCOUTS := 3
## They sit ON the crest of a pool's rim (Fen's measured rule: on the inner bank they hide behind the lip).
const HOP_RIM_IN := 0.05
const HOP_RAD := Vector2(0.25, 0.55)
const HOP_H := 0.24
const HOP_AIR_SEC := 0.4
const HOP_SIT_SEC := Vector2(1.5, 4.5)
const HOP_CROUCH_SEC := 0.14
const HOP_RUSH_M := 2.8
const HOP_RUSH_SPEED := 0.6
const HOP_UNDER_SEC := Vector2(3.0, 5.0)
## Stand still with the camera up inside CROAK_M for STILL_SEC and the nearest puffs its throat at you.
const HOP_CROAK_M := 5.5
const HOP_CROAK_SEC := 3.2
const HOP_CROAK_REST := 6.0
const HOP_BRING_POOL_M := 9.0
enum Hop { SIT, CROUCH, AIR, PLOP, UNDER, CROAK }

## The creatures' "hello" needs the still camera this long, and inside CURIOUS_M a resting creature turns
## to a still camera only after CURIOUS_AFTER s, slowly (Fen's and Zorp's measured numbers: at once and
## fast, the careless test player averaged Facing 9+ and graded Fine far too often).
const STILL_SEC := 2.5
const CURIOUS_M := 6.5
const CURIOUS_AFTER := 1.2
const CURIOUS_RATE := 0.7

# ------------------------------------------------------------------------------ glowtails
## Where a glowtail clings on a palm: this high up the trunk (node-local), this far out from the axis.
const TAIL_PALM_Y := 1.25
const TAIL_PALM_OUT := 0.34
## On the root arch: on the side of one leg, arch-local, facing along the trail.
const TAIL_ARCH_AT := Vector3(-1.2, 1.25, 0.0)
const TAIL_ARCH_OUT := 0.3
## How many palms have a glowtail, and how far apart (degrees round the planet) they are picked.
const TAIL_PALMS := 5
const TAIL_PALM_SPREAD_DEG := 35.0
const TAIL_SCOUTS := 3
const TAIL_RUSH_M := 2.6
const TAIL_RUSH_SPEED := 0.6
const TAIL_HIDE_SEC := Vector2(3.5, 6.0)
const TAIL_UP_SEC := 0.5
const TAIL_UP_M := 1.3
## The lamp flares (the moment) every GLOW_EVERY s for GLOW_SEC.
const TAIL_GLOW_EVERY := Vector2(6.0, 10.0)
const TAIL_GLOW_SEC := 1.6
## A glowtail that has noticed a still camera edges round its trunk toward it at this rate (rad/s).
const TAIL_PEEK_RATE := 0.45
const SCOUT_OUT_MIN_SEC := 12.0
const SCOUT_DOWN_M := 5.5
const SCOUT_POP_SEC := 0.45
## The director puts a glowtail on a palm whose cling point is this far from the lens.
const TAIL_BRING_M := Vector2(2.8, 9.0)
## ...or, with no palm in view, down on clear ground (this far from any understory clump, so it sits in
## the open and not half hidden in the broadleaf).
const TAIL_GROUND_CLEAR_M := 1.5
const TAIL_RISE_MAX := 0.45
enum Tail { CLING, GLOW, UP, HIDDEN, GONE, POP }

# ------------------------------------------------------------------------------ spore-puffs
## PUFF_ROAMERS drift over the floor all safari; PUFF_WATCHERS drift out near you while a rare is warned or
## up, drawn toward it; the rest wait for the director. (Fen's mist-wisp, with its measured numbers.)
const PUFF_N := 5
const PUFF_ROAMERS := 1
const PUFF_WATCHERS := 1
const PUFF_FROM := [Vector2(95.0, -30.0)]
const PUFF_SPEED := 0.3
## Over the broadleaf (0.5-0.9 m) so it is never down among the leaves.
const PUFF_ALT := 1.25
const PUFF_OUT_MIN_SEC := 12.0
const PUFF_LEAVE_M := 6.5
const PUFF_COME_SEC := 0.8
const PUFF_LEAVE_SEC := 1.8
const PUFF_HELLO_M := 4.5
const PUFF_HELLO_SEC := 3.2
const PUFF_HELLO_REST := 6.0
const PUFF_KEEP_M := 1.6
const ROAMER_REST_SEC := 45.0
enum Puf { DRIFT, AWAY, COME, LEAVE, HELLO }

# ------------------------------------------------------------------------------ lantern-snails (night)
const SNAIL_N := 5
## Which trail arcs (JungleLayout.trail_arcs) they crawl along, and where on each (0..1).
const SNAIL_ON := [[0, 0.62], [1, 0.5], [3, 0.35], [5, 0.55], [6, 0.4]]
const SNAIL_SPEED := 0.07
## Every SNAIL_FLARE_EVERY s a snail's shell flares for SNAIL_FLARE_SEC (the moment), each on its own beat.
const SNAIL_FLARE_EVERY := 11.0
const SNAIL_FLARE_SEC := 2.4
## A snail seen and then left out of the frame SNAIL_LEAVE_SEC tucks into its shell for SNAIL_REST_SEC
## (Fen's moth rest rule: the band's "not too common" at night).
const SNAIL_LEAVE_SEC := 2.0
const SNAIL_REST_SEC := 25.0

# ------------------------------------------------------------------------------ the glimmer swarm
const GLIM_N := 9
const GLIM_RADIUS := 1.5
const GLIM_SPEED := 1.5
## circling this high over the water (the water is ~0.35 m under the floor): over the broadleaf
const GLIM_LOW := 2.1
const GLIM_HIGH := 5.5           # while they gather (the warning), this high and wider
const GLIM_LEAVE_SEC := 2.5

## SafariLayer.intro_hint holds the one banner for about 5 s.
const INTRO_HINT_SEC := 5.1
const LINE_SEC := 3.6
const SPLASH := Color("#cfe0dd")
const LEAFDUST := Color("#b9d2c0")

# ------------------------------------------------------------------------------ state
var pacing: Pacing
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}
var _prop: ShaderMaterial
var _pad_dir := Vector3.UP
var _water_r := 0.0
var _still := 0.0

var _pools: Array = []             # per crater: {dir, rim_m, shore_m}
var _props: Dictionary = {}        # J1 prop name -> Node3D
var _palms: Array = []             # every SpirePalm node
var _arcs: Array = []              # JungleLayout.trail_arcs

var _hop_herd: Herd
var _hoppers: Array = []
var _hop_focus: Node3D
var _hop_pick := -1
var _croak_next := 0.0

var _tail_herd: Herd
var _tails: Array = []
var _tail_focus: Node3D
var _tail_pick := -1
var _tail_spots: Array = []        # {node, kind "palm"/"arch", ang, out (arch)}

var _puff_herd: Herd
var _puffs: Array = []
var _puff_focus: Node3D
var _puff_pick := -1
var _spore_pop: CPUParticles3D

var _snail_herd: Herd
var _snails: Array = []            # {arc, k, dir_sign, dir, face, flare_ph, seen, rest}
var _snail_focus: Node3D
var _snail_pick := -1

var _glim_herd: Herd
var _glims: Array = []             # {ang, r_off, h_off, phase, pos, head, spd}
var _glim_focus: Node3D
var _glim_at := -1
var _glim_k := 0.0
var _glim_vis := 0.0
var _glim_places: Array = []       # [world ground centre over the water, its height]
var _chirp_clock := 0.0

var _rain_root: Node3D
var _rain_glow: MeshInstance3D
var _rain_steady: CPUParticles3D
var _rain_heavy: CPUParticles3D
var _rain_focus: Node3D
var _rain_at := -1
var _rain_level := 0.0
var _rain_places: Array = []       # {dir, top (world point under the tiers), node}

var _bud_root: Node3D
var _bud_dir := Vector3.UP
var _petal_herd: Herd
var _bud_heart: MeshInstance3D
var _bud_glow: MeshInstance3D
var _pollen: CPUParticles3D
var _bud_focus: Node3D
var _bud_open := 0.0
var _bud_swell := 0.0

var _grazer_root: Node3D
var _grazer_neck: MeshInstance3D
var _grazer_legs: Array[MeshInstance3D] = []
var _grazer_focus: Node3D
var _grazer_stand := Vector3.UP    # unit dir of where it browses
var _grazer_from := Vector3.UP     # unit dir of where it walks in from
var _grazer_face := Vector3.FORWARD
var _grazer_shown := false
var _grazer_step := 0.0

var _giant_root: Node3D
var _giant_petals: Array[MeshInstance3D] = []
var _giant_heart: MeshInstance3D
var _giant_glow: MeshInstance3D
var _giant_motes: CPUParticles3D
var _giant_focus: Node3D
var _giant_dir := Vector3.UP
var _giant_open := 0.0

var _beacons: Dictionary = {}
var _lines: Array = []
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []
var _glow_amber: ShaderMaterial
var _glow_teal: ShaderMaterial
var _glow_magenta: ShaderMaterial


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 173_0929_2
	_prop = PlanetPropMeshes.prop_material()
	# the planet's own glow material (J1's glow beads: jungle_props.gd _glow_mat), in its three glows
	_glow_amber = PlanetPropMeshes.crystal_material(Color("#ffc46b").darkened(0.25), Color("#ffc46b"), 1.7, false, 0.55)
	_glow_teal = PlanetPropMeshes.crystal_material(Color("#7ff0d2").darkened(0.25), Color("#7ff0d2"), 1.5, false, 0.55)
	_glow_magenta = PlanetPropMeshes.crystal_material(Color("#f08fcf").darkened(0.25), Color("#f08fcf"), 1.5, false, 0.55)
	_find_places()
	_build_hoppers()
	_build_peepers()
	_build_tails()
	_build_puffs()
	if safari.is_night:
		_build_snails()
	_build_swarm()
	_build_rain()
	_build_bud()
	_build_grazer()
	if safari.is_rare_day:
		_build_giant()
	_build_sights()
	_build_bonus()
	_register_events()
	_build_pacing()
	_warm_sounds()
	safari.photo_taken.connect(_on_photo)
	_building = true
	tick(0.0, 0.0)
	_building = false
	var walk := 1.5
	for pr: Array in [["grazer hoot / spore rain 2", _grazer_stand, (_rain_places[1]["dir"] as Vector3) if _rain_places.size() > 1 else Vector3.UP],
			["giant bloom open / swarm 3 spiral", _giant_dir, _pool_dir(SWARM_POOLS[2])],
			["burst 2 / spore rain 3", _bud_dir, (_rain_places[2]["dir"] as Vector3) if _rain_places.size() > 2 else Vector3.UP]]:
		var a := rad_to_deg((pr[1] as Vector3).angle_to(pr[2]))
		var m := deg_to_rad(a) * safari.planet.radius
		_log("overlap %s: %.0f deg apart, %.1f m, %.1f s at the safari walk" % [pr[0], a, m, m / walk])


func _find_places() -> void:
	var p := safari.planet
	_pad_dir = p.data.pad_dir.normalized() if p.data != null else safari.start_dir
	_water_r = p.water_radius()
	var cd := p.crater_dirs()
	for i in cd.size():
		var d := cd[i].normalized()
		var rim := p.crater_angle(i) * p.radius
		_pools.append({"dir": d, "rim_m": rim, "shore_m": _shore_m(d, rim)})
		_log("pool %d at %s rim %.2f m shore %.2f m" % [i, _pp(d), rim, float(_pools[i]["shore_m"])])
	var props := p.get_node_or_null("Props")
	if props != null:
		for c in props.get_children():
			if c is Node3D:
				_props[str(c.name)] = c
				if str(c.name).begins_with("SpirePalm"):
					_palms.append(c)
	if p.data != null:
		_arcs = JungleLayout.trail_arcs(p.data)
	_log("props: %d palms, %d named props; trails %d" % [_palms.size(), _props.size(), _arcs.size()])


## A J1 prop by name; failing that the nearest prop whose name begins with `kind` to `near` (a unit dir).
func _prop_named(nm: String, kind: String, near: Vector3) -> Node3D:
	if _props.has(nm):
		return _props[nm]
	var best: Node3D = null
	var best_a := INF
	for k: String in _props:
		if not k.begins_with(kind):
			continue
		var n: Node3D = _props[k]
		var a := safari.planet.dir_of(n.global_position).angle_to(near)
		if a < best_a:
			best_a = a
			best = n
	_log("prop %s missing: using %s" % [nm, str(best.name) if best != null else "none"])
	return best


## How far from pool centre `d` the water ends (the first dry ground going out), in metres.
func _shore_m(d: Vector3, rim_m: float) -> float:
	var p := safari.planet
	var t := _tangent_at(d)
	var shores: Array = []
	for k in 8:
		var h := t.rotated(d, TAU * float(k) / 8.0)
		var m := 0.2
		while m < rim_m + 1.0:
			var q := (d * cos(m / p.radius) + h * sin(m / p.radius)).normalized()
			if not p.is_underwater(q):
				break
			m += 0.05
		shores.append(m)
	shores.sort()
	return float(shores[shores.size() / 2])


func _pool_dir(i: int) -> Vector3:
	return (_pools[i]["dir"] as Vector3) if i < _pools.size() else safari.dir_from_start(90.0, 0.0)


## The point `m` metres out from pool `i`'s centre along the angle `ang` (radians, from the start heading).
func _pool_ring(i: int, m: float, ang: float) -> Vector3:
	var c := _pool_dir(i)
	return _polar(c, _tangent_at(c), rad_to_deg(m / safari.planet.radius), rad_to_deg(ang))


## A world point on pool `i`'s water surface, `lift` above it.
func _water_point(i: int, lift: float = 0.0) -> Vector3:
	return safari.planet.global_position + _pool_dir(i) * (_water_r + lift)


## `dir`, or the nearest spot round it at least `clear_m` from every prop (J1 registers every understory
## clump too, so this is clear of the broadleaf) and out of the water.
func _free_near(dir: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(dir) >= clear_m and not p.is_underwater(dir):
		return dir
	var t := _tangent_at(dir)
	for ring_deg in [1.5, 3.0, 4.5, 6.0, 8.0, 10.0, 13.0, 16.0]:
		for k in 12:
			var d := _polar(dir, t, ring_deg, 30.0 * float(k))
			if p.nearest_prop_distance(d) >= clear_m and not p.is_underwater(d) and rad_to_deg(d.angle_to(_pad_dir)) > 10.0:
				return d
	return dir


# ---------------------------------------------------------------------------------------- lily-hoppers
func _build_hoppers() -> void:
	var p := safari.planet
	for pi: int in HOPPER_POOLS:
		if pi >= _pools.size():
			continue
		for k in HOPPERS_PER_POOL:
			var ang := TAU * float(k) / float(HOPPERS_PER_POOL) + _rng.randf_range(-0.5, 0.5)
			var d := _hop_spot(pi, ang)
			_hoppers.append({"pool": pi, "ang": ang, "dir": d, "face": _toward(d, d * 2.0 - _pool_dir(pi)),
				"state": Hop.SIT, "timer": _rng.randf_range(0.5, 3.0), "from": d, "to": d, "air": 0.0,
				"apex": HOP_H, "h": 0.0, "croak": 0.0, "scout": false, "out_t": 0.0})
	for k in HOPPER_SCOUTS:
		_hoppers.append({"pool": 0, "ang": 0.0, "dir": safari.start_dir, "face": safari.start_fwd, "state": Hop.UNDER,
			"timer": 0.0, "from": safari.start_dir, "to": safari.start_dir, "air": 0.0, "apex": HOP_H, "h": 0.0,
			"croak": 0.0, "scout": true, "out_t": 0.0})
	_hop_herd = Herd.new()
	add_child(_hop_herd)
	var rr := p.radius + 3.0
	_hop_herd.setup("LilyHoppers", _hoppers.size(), [[Meshes.hopper(), _prop, true], [Meshes.hopper_throat(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_hop_focus = Node3D.new()
	_hop_focus.name = "HopperFocus"
	add_child(_hop_focus)
	safari.add_subject({
		"id": "lily_hopper", "name": "Lily-hopper", "kind": "creature",
		"band": BAND_HOPPER, "node": _hop_focus, "offset": Vector3(0.0, 0.16, 0.0), "radius": 0.2,
		"awake": func() -> bool: return _hop_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _hop_moment(),
		"front": func() -> Vector3: return _front_of(_hop_focus),
	})


func _hop_seat_m(pi: int) -> float:
	return float(_pools[pi]["rim_m"]) - HOP_RIM_IN


## A hopper's seat on pool `pi`'s rim at angle `ang`, moved round the rim off any prop.
func _hop_spot(pi: int, ang: float) -> Vector3:
	var p := safari.planet
	var seat := _hop_seat_m(pi)
	for tries in 8:
		var a := ang + 0.22 * float(tries) * (1.0 if tries % 2 == 0 else -1.0)
		var d := _pool_ring(pi, seat, a)
		if p.nearest_prop_distance(d) >= 0.3 and not p.is_underwater(d):
			return d
	return _pool_ring(pi, seat + 0.2, ang)


func _hop_moment() -> Dictionary:
	if _hop_pick < 0:
		return {"mult": 1.0, "line": ""}
	var f: Dictionary = _hoppers[_hop_pick]
	if int(f["state"]) == Hop.CROAK:
		return {"mult": 1.8, "line": "puffing up its throat at you"}
	if int(f["state"]) in [Hop.AIR, Hop.PLOP] and float(f["h"]) > 0.6 * float(f["apex"]):
		return {"mult": 1.5, "line": "mid-hop, hat and all"}
	return {"mult": 1.0, "line": ""}


func _hop_out(f: Dictionary) -> bool:
	return int(f["state"]) != Hop.UNDER


func _tick_hoppers(delta: float) -> void:
	if _hop_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	var shy := pacing != null and pacing.shy("lily_hopper")
	var croak_i := -1
	if _still >= STILL_SEC and _t >= _croak_next and not _sleeping:
		var best := HOP_CROAK_M
		for i in _hoppers.size():
			var f: Dictionary = _hoppers[i]
			if int(f["state"]) in [Hop.SIT, Hop.CROUCH]:
				var dd := p.surface_point(f["dir"]).distance_to(ppos)
				if dd < best:
					best = dd
					croak_i = i
	for i in _hoppers.size():
		var f: Dictionary = _hoppers[i]
		var here := p.surface_point(f["dir"])
		var dist := here.distance_to(ppos)
		var st: int = f["state"]
		f["timer"] = float(f["timer"]) - delta
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.12, 1.1)
		# THE END, and ONE NEW THING AT A TIME: out of the frame a hopper slips under the water.
		if (_sleeping or (shy and not in_frame)) and st in [Hop.SIT, Hop.CROUCH, Hop.CROAK]:
			f["state"] = Hop.UNDER
			f["timer"] = 0.6 if _sleeping else _rng.randf_range(HOP_UNDER_SEC.x, HOP_UNDER_SEC.y)
			f["shy"] = true
			st = Hop.UNDER
		var rushed := dist < HOP_RUSH_M and speed > HOP_RUSH_SPEED
		match st:
			Hop.SIT:
				if i == croak_i:
					f["state"] = Hop.CROAK
					f["croak"] = HOP_CROAK_SEC
					_croak_next = _t + HOP_CROAK_SEC + HOP_CROAK_REST
					AudioManager.play_sfx_at("doot_a_1", here, -8.0, 0.1)
				elif rushed:
					_hop_plop(f)
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_turn_face(f, ppos - here, CURIOUS_RATE, delta)
				elif float(f["timer"]) <= 0.0:
					f["state"] = Hop.CROUCH
					f["timer"] = HOP_CROUCH_SEC
			Hop.CROUCH:
				if float(f["timer"]) <= 0.0:
					var pi: int = f["pool"]
					var na := float(f["ang"]) + _rng.randf_range(HOP_RAD.x, HOP_RAD.y) * (1.0 if _rng.randf() < 0.5 else -1.0)
					f["ang"] = na
					_hop_to(f, _hop_spot(pi, na), HOP_H)
			Hop.AIR, Hop.PLOP:
				f["air"] = float(f["air"]) + delta
				var k := clampf(float(f["air"]) / HOP_AIR_SEC, 0.0, 1.0)
				f["dir"] = (f["from"] as Vector3).slerp(f["to"], k).normalized()
				f["h"] = 4.0 * float(f["apex"]) * k * (1.0 - k)
				if k >= 1.0:
					f["h"] = 0.0
					if st == Hop.PLOP:
						f["state"] = Hop.UNDER
						f["timer"] = _rng.randf_range(HOP_UNDER_SEC.x, HOP_UNDER_SEC.y)
						var at := p.global_position + (f["dir"] as Vector3) * _water_r
						if in_frame or dist < 8.0:
							safari.puff_at(at, 6, SPLASH)
							AudioManager.play_sfx_at("splash", at, -10.0, 0.25)
					else:
						f["state"] = Hop.SIT
						f["timer"] = _rng.randf_range(HOP_SIT_SEC.x, HOP_SIT_SEC.y)
			Hop.UNDER:
				var held := (bool(f.get("shy", false)) and shy) or bool(f["scout"])
				if not _sleeping and not held and float(f["timer"]) <= 0.0 and dist > HOP_RUSH_M and not rushed:
					f["shy"] = false
					var na := _rng.randf_range(0.0, TAU)
					f["ang"] = na
					f["dir"] = _hop_spot(int(f["pool"]), na)
					f["face"] = _toward(f["dir"], (f["dir"] as Vector3) * 2.0 - _pool_dir(int(f["pool"])))
					f["state"] = Hop.SIT
					f["timer"] = _rng.randf_range(HOP_SIT_SEC.x, HOP_SIT_SEC.y)
			Hop.CROAK:
				f["croak"] = float(f["croak"]) - delta
				_turn_face(f, ppos - here, 5.0, delta)
				if float(f["croak"]) <= 0.0 or rushed or not still_up:
					f["state"] = Hop.SIT
					f["timer"] = _rng.randf_range(HOP_SIT_SEC.x, HOP_SIT_SEC.y)
		if int(f["state"]) != Hop.UNDER:
			f["out_t"] = float(f["out_t"]) + delta
		# a scout left behind, out of view, slips back under
		if bool(f["scout"]) and int(f["state"]) in [Hop.SIT, Hop.CROUCH] and float(f["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			f["state"] = Hop.UNDER
		_pose_hopper(i, f)
	_hop_pick = _pick_focus(_hoppers, func(f: Dictionary) -> bool: return _hop_out(f),
		func(f: Dictionary) -> Vector3: return p.surface_point(f["dir"]), 0.14)
	if _hop_pick >= 0:
		var f: Dictionary = _hoppers[_hop_pick]
		_hop_focus.global_transform = _xf_ground(f["dir"], f["face"]).translated_local(Vector3(0.0, float(f["h"]), 0.0))


func _hop_to(f: Dictionary, to: Vector3, apex: float) -> void:
	f["from"] = f["dir"]
	f["to"] = to
	f["air"] = 0.0
	f["apex"] = apex
	f["state"] = Hop.AIR
	if safari.planet.surface_distance(f["dir"], to) > 0.05:
		f["face"] = _toward(f["dir"], to)


## Rushed: it hops out over the water and plops in.
func _hop_plop(f: Dictionary) -> void:
	var pi: int = f["pool"]
	var into := _pool_ring(pi, maxf(float(_pools[pi]["shore_m"]) - 0.7, 0.2), float(f["ang"]))
	_hop_to(f, into, HOP_H * 1.3)
	f["state"] = Hop.PLOP


func _turn_face(c: Dictionary, want: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = c["dir"]
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = c["face"]
	cur -= d * cur.dot(d)
	c["face"] = cur.normalized().slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_hopper(i: int, f: Dictionary) -> void:
	var st: int = f["state"]
	if st == Hop.UNDER:
		_hop_herd.hide_one(i)
		return
	var crouch := 0.84 if st == Hop.CROUCH else 1.0
	var stretch := 1.12 if st in [Hop.AIR, Hop.PLOP] else 1.0
	var base := _xf_ground(f["dir"], f["face"])
	base = base.translated_local(Vector3(0.0, float(f["h"]), 0.0))
	base.basis = base.basis * Basis.from_scale(Vector3(1.0 / sqrt(crouch * stretch), crouch * stretch, 1.0 / sqrt(crouch * stretch)))
	_hop_herd.pose(i, 0, base)
	var th := 0.5
	if st == Hop.CROAK:
		th = 0.55 + 0.75 * absf(sin(_t * 5.0))
	_hop_herd.pose(i, 1, base * Transform3D(Basis.from_scale(Vector3.ONE * th), Meshes.HOPPER_THROAT_AT))


## THE PACING DIRECTOR brings a hopper: it hops up out of the pool nearest the spot where you look, onto
## that pool's rim, when a rim spot is in the middle of the view (pools only: never out of dry ground).
func _bring_hopper(spot: Dictionary) -> bool:
	var i := -1
	for k in _hoppers.size():
		if bool(_hoppers[k]["scout"]) and int(_hoppers[k]["state"]) == Hop.UNDER:
			i = k
			break
	if i < 0:
		return false
	var p := safari.planet
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO:
		d = spot["ahead"]
	if d == Vector3.ZERO:
		return false
	var lens: Transform3D = spot["lens"]
	var g := p.surface_point(d)
	for pi in _pools.size():
		if _water_point(pi).distance_to(g) > HOP_BRING_POOL_M or pi == HEART_POOL:
			continue
		for k in 12:
			var ang := TAU * float(k) / 12.0
			var fd := _hop_spot(pi, ang)
			if p.surface_point(fd).distance_to(lens.origin) < 2.5:
				continue
			var body := p.surface_point(fd) + p.up_at(p.surface_point(fd)) * 0.16
			if not pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC) or not pacing.sight_clear(lens.origin, body):
				continue
			var f: Dictionary = _hoppers[i]
			f["pool"] = pi
			f["ang"] = ang
			f["dir"] = fd
			# looking out over the jungle, not at you: it turns to a still camera (CURIOUS_*)
			f["face"] = _toward(fd, fd * 2.0 - _pool_dir(pi)).rotated(fd, _rng.randf_range(-1.2, 1.2))
			f["state"] = Hop.SIT
			f["timer"] = _rng.randf_range(HOP_SIT_SEC.x, HOP_SIT_SEC.y)
			f["out_t"] = 0.0
			var at := p.global_position + fd * _water_r
			safari.puff_at(at, 6, SPLASH)
			AudioManager.play_sfx_at("splash", at, -8.0, 0.25)
			return true
	return false


# ---------------------------------------------------------------------------------------- pool-peepers
## POOL-PEEPERS (spec 4's "pool dwellers"): round blue heads with eyes on stalks that peek up out of the
## water of the pools the hoppers do not use, look about, blow a bubble now and then (the moment), and
## sink again. The director brings one up in a pool whose water is in view.
const PEEPER_POOLS := [3, 2, 4, 8]
const PEEPERS_PER_POOL := 2
const PEEPER_SCOUTS := 2
const PEEP_UP_SEC := Vector2(6.0, 10.0)
const PEEP_DOWN_SEC := Vector2(4.0, 8.0)
const PEEP_RISE_SEC := 0.5
const PEEP_RUSH_M := 2.2
const PEEP_RUSH_SPEED := 0.6
## While up it blows a bubble every BUBBLE_EVERY s, BUBBLE_SEC long (the moment).
const PEEP_BUBBLE_EVERY := Vector2(3.5, 6.0)
const PEEP_BUBBLE_SEC := 1.3
const PEEP_BRING_POOL_M := 9.0
## How far in from the water's edge a peeper comes up (m): near enough the edge to be seen over the bank.
const PEEP_IN_M := Vector2(0.35, 0.8)
const BAND_PEEPER := Vector2(0.25, 0.41)
enum Peep { UNDER, RISE, UP, SINK }

var _peep_herd: Herd
var _peepers: Array = []
var _peep_focus: Node3D
var _peep_pick := -1


func _build_peepers() -> void:
	var p := safari.planet
	for pi: int in PEEPER_POOLS:
		if pi >= _pools.size():
			continue
		for k in PEEPERS_PER_POOL:
			var d := _peep_spot(pi, _rng.randf_range(0.0, TAU))
			_peepers.append({"pool": pi, "dir": d, "face": _toward(d, safari.start_dir).rotated(d, _rng.randf_range(-2.0, 2.0)),
				"state": Peep.UP if k == 0 else Peep.UNDER, "timer": _rng.randf_range(1.0, 6.0), "k": 1.0 if k == 0 else 0.0,
				"bubble": 0.0, "bubble_next": _rng.randf_range(1.0, 4.0), "scout": false, "out_t": 0.0})
	for k in PEEPER_SCOUTS:
		_peepers.append({"pool": 0, "dir": safari.start_dir, "face": safari.start_fwd, "state": Peep.UNDER, "timer": 0.0,
			"k": 0.0, "bubble": 0.0, "bubble_next": 3.0, "scout": true, "out_t": 0.0})
	_peep_herd = Herd.new()
	add_child(_peep_herd)
	var rr := p.radius + 3.0
	_peep_herd.setup("PoolPeepers", _peepers.size(), [[Meshes.peeper(), _prop, false], [Meshes.peeper_bubble(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_peep_focus = Node3D.new()
	_peep_focus.name = "PeeperFocus"
	add_child(_peep_focus)
	safari.add_subject({
		"id": "pool_peeper", "name": "Pool-peeper", "kind": "creature",
		"band": BAND_PEEPER, "node": _peep_focus, "offset": Vector3(0.0, 0.14, 0.0), "radius": 0.18,
		"awake": func() -> bool: return _peep_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _peep_pick >= 0 and float(_peepers[_peep_pick]["bubble"]) > 0.25:
				return {"mult": 1.8, "line": "blowing a bubble"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_peep_focus),
	})


## A spot on pool `pi`'s water, PEEP_IN_M in from its edge at angle `ang`.
func _peep_spot(pi: int, ang: float) -> Vector3:
	var shore := float(_pools[pi]["shore_m"])
	var m := maxf(shore - _rng.randf_range(PEEP_IN_M.x, PEEP_IN_M.y), 0.2)
	for tries in 6:
		var d := _pool_ring(pi, m, ang + 0.5 * float(tries))
		if safari.planet.is_underwater(d):
			return d
	return _pool_dir(pi)


func _peep_out(f: Dictionary) -> bool:
	return int(f["state"]) == Peep.UP or (int(f["state"]) in [Peep.RISE, Peep.SINK] and float(f["k"]) > 0.6)


func _peep_pos(f: Dictionary) -> Vector3:
	var d: Vector3 = f["dir"]
	# up: the head's waterline at the water; under: sunk its own height below it
	return safari.planet.global_position + d * (_water_r - 0.34 * (1.0 - float(f["k"])) + 0.01 * sin(_t * 2.0 + float(f["timer"])))


func _tick_peepers(delta: float) -> void:
	if _peep_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var shy := pacing != null and pacing.shy("pool_peeper")
	for i in _peepers.size():
		var f: Dictionary = _peepers[i]
		var here := _peep_pos(f)
		var dist := here.distance_to(ppos)
		var st: int = f["state"]
		f["timer"] = float(f["timer"]) - delta
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.15, 1.1)
		if (_sleeping or (shy and not in_frame)) and st in [Peep.UP, Peep.RISE]:
			f["state"] = Peep.SINK
			f["shy"] = true
			st = Peep.SINK
		var rushed := dist < PEEP_RUSH_M and speed > PEEP_RUSH_SPEED
		match st:
			Peep.UNDER:
				var held := (bool(f.get("shy", false)) and shy) or bool(f["scout"])
				if not _sleeping and not held and float(f["timer"]) <= 0.0 and dist > PEEP_RUSH_M:
					f["shy"] = false
					f["dir"] = _peep_spot(int(f["pool"]), _rng.randf_range(0.0, TAU))
					f["face"] = _toward(f["dir"], p.dir_of(ppos)).rotated(f["dir"], _rng.randf_range(-2.2, 2.2))
					f["state"] = Peep.RISE
			Peep.RISE:
				f["k"] = move_toward(float(f["k"]), 1.0, delta / PEEP_RISE_SEC)
				if float(f["k"]) >= 1.0:
					f["state"] = Peep.UP
					f["timer"] = _rng.randf_range(PEEP_UP_SEC.x, PEEP_UP_SEC.y)
					f["bubble_next"] = _rng.randf_range(1.0, PEEP_BUBBLE_EVERY.x)
			Peep.UP:
				if rushed:
					f["state"] = Peep.SINK
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_turn_face(f, ppos - here, CURIOUS_RATE, delta)
					# a curious one stays up while you are still
					f["timer"] = maxf(float(f["timer"]), 1.0)
				f["bubble_next"] = float(f["bubble_next"]) - delta
				if float(f["bubble_next"]) <= 0.0 and float(f["bubble"]) <= 0.0:
					f["bubble"] = PEEP_BUBBLE_SEC
					f["bubble_next"] = _rng.randf_range(PEEP_BUBBLE_EVERY.x, PEEP_BUBBLE_EVERY.y)
				if float(f["timer"]) <= 0.0 and not bool(f["scout"]):
					f["state"] = Peep.SINK
			Peep.SINK:
				f["k"] = move_toward(float(f["k"]), 0.0, delta / PEEP_RISE_SEC)
				if float(f["k"]) <= 0.0:
					f["state"] = Peep.UNDER
					f["timer"] = _rng.randf_range(PEEP_DOWN_SEC.x, PEEP_DOWN_SEC.y)
					if in_frame and dist < 10.0:
						AudioManager.play_sfx_at("splash", here, -14.0, 0.3)
		if float(f["bubble"]) > 0.0:
			var was := float(f["bubble"])
			f["bubble"] = was - delta
			if was > 0.0 and float(f["bubble"]) <= 0.0 and in_frame and dist < 8.0:
				AudioManager.play_sfx_at("pickup", here, -18.0, 0.3)
		if int(f["state"]) != Peep.UNDER:
			f["out_t"] = float(f["out_t"]) + delta
		# a scout left behind, out of view, sinks back down
		if bool(f["scout"]) and int(f["state"]) == Peep.UP and float(f["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			f["state"] = Peep.SINK
		_pose_peeper(i, f)
	_peep_pick = _pick_focus(_peepers, func(f: Dictionary) -> bool: return _peep_out(f),
		func(f: Dictionary) -> Vector3: return _peep_pos(f), 0.14)
	if _peep_pick >= 0:
		var f: Dictionary = _peepers[_peep_pick]
		_peep_focus.global_transform = Transform3D(Basis.looking_at(f["face"], f["dir"]), _peep_pos(f))


func _pose_peeper(i: int, f: Dictionary) -> void:
	if int(f["state"]) == Peep.UNDER:
		_peep_herd.hide_one(i)
		return
	var d: Vector3 = f["dir"]
	var face: Vector3 = f["face"]
	var look := 0.25 * sin(_t * 0.7 + float(i) * 1.3)
	var b := Basis.looking_at(face, d) * Basis(Vector3.UP, look)
	var xf := Transform3D(b, _peep_pos(f))
	_peep_herd.pose(i, 0, xf)
	var bub := float(f["bubble"])
	if bub > 0.0:
		var g := clampf(1.0 - bub / PEEP_BUBBLE_SEC, 0.0, 1.0)
		var sc := lerpf(0.3, 1.6, g)
		_peep_herd.pose(i, 1, xf * Transform3D(Basis.from_scale(Vector3.ONE * sc), Meshes.PEEPER_BUBBLE_AT + Vector3(0.0, 0.05 * sc, -0.04 * sc)))
	else:
		_peep_herd.pose(i, 1, Herd.ZERO)


## THE PACING DIRECTOR brings a peeper: it comes up in the pool nearest where you look, at a spot of its
## water that is in the middle of the view with a clear line of sight (so the bank does not hide it).
func _bring_peeper(spot: Dictionary) -> bool:
	var i := -1
	for k in _peepers.size():
		if bool(_peepers[k]["scout"]) and int(_peepers[k]["state"]) == Peep.UNDER:
			i = k
			break
	if i < 0:
		return false
	var p := safari.planet
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO:
		d = spot["ahead"]
	if d == Vector3.ZERO:
		return false
	var lens: Transform3D = spot["lens"]
	var g := p.surface_point(d)
	for pi in _pools.size():
		if _water_point(pi).distance_to(g) > PEEP_BRING_POOL_M:
			continue
		for k in 10:
			var fd := _peep_spot(pi, TAU * float(k) / 10.0)
			var head := p.global_position + fd * (_water_r + 0.14)
			if head.distance_to(lens.origin) < 2.4:
				continue
			if not pacing.in_view_from(lens, head, pacing.SPOT_FRAME_FRAC) or not pacing.sight_clear(lens.origin, head):
				continue
			var f: Dictionary = _peepers[i]
			f["pool"] = pi
			f["dir"] = fd
			f["face"] = _toward(fd, p.dir_of(lens.origin)).rotated(fd, _rng.randf_range(0.8, 1.8) * (1.0 if _rng.randf() < 0.5 else -1.0))
			f["state"] = Peep.RISE
			f["k"] = 0.0
			f["out_t"] = 0.0
			f["bubble_next"] = _rng.randf_range(1.5, 3.0)
			safari.puff_at(p.global_position + fd * _water_r, 5, SPLASH)
			AudioManager.play_sfx_at("splash", head, -10.0, 0.3)
			return true
	return false


# ---------------------------------------------------------------------------------------- glowtails
func _build_tails() -> void:
	var p := safari.planet
	# THE PALMS NEAREST A TRAIL (the lens sees a trunk over the broadleaf best from the path), spread round
	# the planet: greedily the nearest-to-a-trail first, each TAIL_PALM_SPREAD_DEG from the others and from
	# the start. J1's layout is seeded, so the same palms every time (logged).
	var rows: Array = []
	for n: Node3D in _palms:
		var pd := p.dir_of(n.global_position)
		var tq: Array = _nearest_trail_point(pd)
		rows.append([(tq[0] as Vector3).angle_to(pd) * p.radius, n, pd, tq[0]])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var picked: Array = []
	for r: Array in rows:
		if picked.size() >= TAIL_PALMS:
			break
		var pd: Vector3 = r[2]
		if rad_to_deg(pd.angle_to(safari.start_dir)) < TAIL_PALM_SPREAD_DEG * 0.5:
			continue
		var ok := true
		for q: Array in picked:
			if rad_to_deg(pd.angle_to(q[2])) < TAIL_PALM_SPREAD_DEG:
				ok = false
				break
		if ok:
			picked.append(r)
	for r: Array in picked:
		var n: Node3D = r[1]
		# it clings on the side of the trunk toward the trail, where you walk
		_tail_spots.append({"node": n, "kind": "palm", "ang": _palm_ang_toward(n, r[3])})
	var arch := _prop_named(GLOWTAIL_ARCH, "RootArch", safari.dir_from_start(43.0, 119.0))
	if arch != null:
		var az := arch.global_basis.z.normalized()
		var to_start := safari.planet.surface_point(safari.start_dir) - arch.global_position
		_tail_spots.append({"node": arch, "kind": "arch", "side": 1.0 if az.dot(to_start) >= 0.0 else -1.0})
	for si in _tail_spots.size():
		var sp: Dictionary = _tail_spots[si]
		var c := _tail_cling(sp["node"], str(sp["kind"]), float(sp.get("ang", 0.0)), float(sp.get("side", 1.0)))
		_tails.append({"spot": si, "pos": c[0], "up": c[1], "face": c[2], "ang": float(sp.get("ang", 0.0)),
			"palm": sp["node"], "kind": sp["kind"], "side": float(sp.get("side", 1.0)), "ground": false,
			"state": Tail.CLING, "timer": _rng.randf_range(1.0, 4.0), "glow_next": _rng.randf_range(2.0, 8.0),
			"glow": 0.0, "k": 0.0, "out_t": 0.0})
		_log("glowtail %d on %s at %s, %.1f m from a trail" % [si, str((sp["node"] as Node3D).name), _pp(p.dir_of(c[0])),
			(_nearest_trail_point(p.dir_of(c[0]))[0] as Vector3).angle_to(p.dir_of(c[0])) * p.radius])
	for k in TAIL_SCOUTS:
		_tails.append({"spot": -1, "pos": p.surface_point(safari.start_dir), "up": p.up_at(p.surface_point(safari.start_dir)),
			"face": safari.start_fwd, "ang": 0.0, "palm": null, "kind": "ground", "side": 1.0, "ground": true,
			"state": Tail.GONE, "timer": 0.0, "glow_next": _rng.randf_range(3.0, 8.0), "glow": 0.0, "k": 0.0, "out_t": 0.0})
	_tail_herd = Herd.new()
	add_child(_tail_herd)
	var r := p.radius + 4.0
	var halo := QuadMesh.new()
	halo.size = Vector2(0.5, 0.5)
	_tail_herd.setup("Glowtails", _tails.size(), [[Meshes.glowtail(), _prop, true], [Meshes.glowtail_bulb(), _glow_amber, false],
		[halo, MaterialLib.glow_sprite(Color("#ffc97a"), 1.8, {"softness": 0.0, "core": 0.22}), false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_tail_focus = Node3D.new()
	_tail_focus.name = "GlowtailFocus"
	add_child(_tail_focus)
	safari.add_subject({
		"id": "glowtail", "name": "Glowtail", "kind": "creature",
		"band": BAND_GLOWTAIL, "node": _tail_focus, "offset": Vector3(0.0, 0.22, 0.0), "radius": 0.24,
		"awake": func() -> bool: return _tail_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _tail_pick >= 0 and int(_tails[_tail_pick]["state"]) == Tail.GLOW:
				return {"mult": 1.8, "line": "its tail lamp blazing"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_tail_focus),
	})


## The angle round palm `n`'s trunk (its own frame) that points toward unit direction `toward`.
func _palm_ang_toward(n: Node3D, toward: Vector3) -> float:
	var xf := n.global_transform
	var up := xf.basis.y.normalized()
	var bx := xf.basis.x.normalized()
	var bz := (up.cross(bx)).normalized()
	bx = bz.cross(up).normalized()
	var want := safari.planet.surface_point(toward) - xf.origin
	want -= up * want.dot(up)
	if want.length() < 0.01:
		return 0.0
	return atan2(want.normalized().dot(bz), want.normalized().dot(bx))


## [unit dir, arc index, fraction] of the point on any trail nearest unit direction `d` ([d, -1, 0] with no
## trails).
func _nearest_trail_point(d: Vector3) -> Array:
	var best: Array = [d, -1, 0.0]
	var best_a := INF
	for ai in _arcs.size():
		var arc: PackedVector3Array = _arcs[ai]
		for k in 61:
			var f := float(k) / 60.0
			var q := arc[0].slerp(arc[1], f).normalized()
			var a := q.angle_to(d)
			if a < best_a:
				best_a = a
				best = [q, ai, f]
	return best


## The unit dir `side_m` metres to the right of trail arc `ai` at fraction `k` (the arc's own middle if
## there is no such arc).
func _trail_side(ai: int, k: float, side_m: float) -> Vector3:
	if ai < 0 or ai >= _arcs.size():
		return safari.dir_from_start(40.0, 60.0)
	var arc: PackedVector3Array = _arcs[ai]
	var d := arc[0].slerp(arc[1], k).normalized()
	var along := _toward(d, arc[1] if k < 0.99 else arc[1] * 2.0 - arc[0])
	var right := along.cross(d).normalized()
	return safari.planet.step_dir(d, (d + right).normalized(), side_m)


## The nearest point on any trail to unit direction `d` (a unit direction), or `d` itself.
func _nearest_trail_dir(d: Vector3) -> Vector3:
	var best := d
	var best_a := INF
	for arc: PackedVector3Array in _arcs:
		for k in 21:
			var q := arc[0].slerp(arc[1], float(k) / 20.0).normalized()
			var a := q.angle_to(d)
			if a < best_a:
				best_a = a
				best = q
	return best


## Where a glowtail clings: [seat origin, up, face]. A palm: TAIL_PALM_Y up the trunk, TAIL_PALM_OUT out
## from its axis on the bearing `ang` (the trunk's own frame), facing out. The arch: on the side of one
## leg (TAIL_ARCH_AT), facing along the trail on side `side`.
func _tail_cling(n: Node3D, kind: String, ang: float, side: float) -> Array:
	var xf := n.global_transform
	var up := xf.basis.y.normalized()
	var sc := xf.basis.get_scale().y
	if kind == "arch":
		var out := (xf.basis.z.normalized() * side)
		out = (out - up * out.dot(up)).normalized()
		return [xf * TAIL_ARCH_AT + out * TAIL_ARCH_OUT, up, out]
	var bx := xf.basis.x.normalized()
	var bz := (up.cross(bx)).normalized()
	bx = bz.cross(up).normalized()
	var out2 := (bx * cos(ang) + bz * sin(ang)).normalized()
	var axis := xf.origin + up * TAIL_PALM_Y * sc
	return [axis + out2 * TAIL_PALM_OUT * sc, up, out2]


func _tail_out(z: Dictionary) -> bool:
	var st: int = z["state"]
	return st in [Tail.CLING, Tail.GLOW] or (st == Tail.POP and float(z["timer"]) < SCOUT_POP_SEC * 0.5)


func _tick_tails(delta: float) -> void:
	if _tail_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var shy := pacing != null and pacing.shy("glowtail")
	for i in _tails.size():
		var z: Dictionary = _tails[i]
		var st: int = z["state"]
		var here: Vector3 = z["pos"]
		var dist := here.distance_to(ppos)
		var scout := int(z["spot"]) < 0
		z["timer"] = float(z["timer"]) - delta
		if st != Tail.GONE:
			z["out_t"] = float(z["out_t"]) + delta
		var in_frame := _point_in_frame(here + (z["up"] as Vector3) * 0.2, 1.1)
		if (_sleeping or (shy and not in_frame)) and st in [Tail.CLING, Tail.GLOW]:
			if bool(z["ground"]):
				_tail_dive(z, in_frame)
			else:
				_tail_climb(z)
				z["shy"] = true
			st = z["state"]
		var rushed := dist < TAIL_RUSH_M and speed > TAIL_RUSH_SPEED
		match st:
			Tail.GONE:
				pass
			Tail.POP:
				z["k"] = clampf(float(z["timer"]) / SCOUT_POP_SEC, 0.0, 1.0)
				if float(z["timer"]) <= 0.0:
					z["state"] = Tail.CLING
					z["k"] = 0.0
					z["timer"] = _rng.randf_range(1.0, 3.0)
			Tail.CLING:
				if rushed:
					if bool(z["ground"]):
						_tail_dive(z, in_frame)
					else:
						_tail_climb(z)
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_tail_peek(z, ppos, delta)
				z["glow_next"] = float(z["glow_next"]) - delta
				if int(z["state"]) == Tail.CLING and float(z["glow_next"]) <= 0.0:
					z["state"] = Tail.GLOW
					z["glow"] = TAIL_GLOW_SEC
					z["glow_next"] = _rng.randf_range(TAIL_GLOW_EVERY.x, TAIL_GLOW_EVERY.y)
			Tail.GLOW:
				z["glow"] = float(z["glow"]) - delta
				if rushed:
					if bool(z["ground"]):
						_tail_dive(z, in_frame)
					else:
						_tail_climb(z)
				elif float(z["glow"]) <= 0.0:
					z["state"] = Tail.CLING
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_tail_peek(z, ppos, delta)
			Tail.UP:
				z["k"] = clampf(1.0 - float(z["timer"]) / TAIL_UP_SEC, 0.0, 1.0)
				if float(z["timer"]) <= 0.0:
					z["state"] = Tail.HIDDEN
					z["timer"] = _rng.randf_range(TAIL_HIDE_SEC.x, TAIL_HIDE_SEC.y)
			Tail.HIDDEN:
				var held := bool(z.get("shy", false)) and shy
				if scout and not bool(z["ground"]) and float(z["out_t"]) > SCOUT_OUT_MIN_SEC:
					z["state"] = Tail.GONE
				elif not _sleeping and not held and float(z["timer"]) <= 0.0 and dist > TAIL_RUSH_M:
					# back down to where it clung, facing out again
					z["shy"] = false
					if not scout:
						var sp: Dictionary = _tail_spots[int(z["spot"])]
						var c := _tail_cling(sp["node"], str(sp["kind"]), float(sp.get("ang", 0.0)), float(sp.get("side", 1.0)))
						z["pos"] = c[0]
						z["face"] = c[2]
						z["ang"] = float(sp.get("ang", 0.0))
					z["state"] = Tail.POP
					z["timer"] = SCOUT_POP_SEC
					z["k"] = 1.0
		# a scout left behind, out of view, slips away
		if scout and int(z["state"]) in [Tail.CLING, Tail.GLOW] and float(z["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			z["state"] = Tail.GONE
		_pose_tail(i, z)
	_tail_pick = _pick_focus(_tails, func(z: Dictionary) -> bool: return _tail_out(z),
		func(z: Dictionary) -> Vector3: return z["pos"], 0.22)
	if _tail_pick >= 0:
		var z: Dictionary = _tails[_tail_pick]
		_tail_focus.global_transform = Transform3D(Basis.looking_at(z["face"], z["up"]), z["pos"])


## A glowtail noticing a still camera: its face turns toward you, and one on a palm edges round the trunk
## toward you (TAIL_PEEK_RATE) - slowly.
func _tail_peek(z: Dictionary, ppos: Vector3, delta: float) -> void:
	var up: Vector3 = z["up"]
	var here: Vector3 = z["pos"]
	if str(z["kind"]) == "palm" and not bool(z["ground"]) and z["palm"] != null and is_instance_valid(z["palm"]):
		var n: Node3D = z["palm"]
		var want := _palm_ang_toward(n, safari.planet.dir_of(ppos))
		var cur := float(z["ang"])
		var da := wrapf(want - cur, -PI, PI)
		cur += clampf(da, -TAIL_PEEK_RATE * delta, TAIL_PEEK_RATE * delta)
		z["ang"] = cur
		var c := _tail_cling(n, "palm", cur, 1.0)
		z["pos"] = c[0]
		# it keeps its face mostly out from the trunk, turned a little more toward you
		var to := ppos - here
		to -= up * to.dot(up)
		var out: Vector3 = c[2]
		if to.length() > 0.01:
			out = out.slerp(to.normalized(), 0.35).normalized()
		(z as Dictionary)["face"] = (z["face"] as Vector3).slerp(out, clampf(CURIOUS_RATE * 2.0 * delta, 0.0, 1.0)).normalized()
		return
	var want2 := ppos - here
	want2 -= up * want2.dot(up)
	if want2.length() < 0.01:
		return
	var cur2: Vector3 = z["face"]
	cur2 -= up * cur2.dot(up)
	z["face"] = cur2.normalized().slerp(want2.normalized(), clampf(CURIOUS_RATE * delta, 0.0, 1.0)).normalized()


## Rushed on a trunk: it scurries up out of sight into the canopy.
func _tail_climb(z: Dictionary) -> void:
	z["state"] = Tail.UP
	z["timer"] = TAIL_UP_SEC
	z["k"] = 0.0
	var here: Vector3 = z["pos"]
	if _point_in_frame(here, 1.2):
		AudioManager.play_sfx_at("footstep_grass_1", here, -10.0, 0.3)


## A glowtail on the ground slips back into the undergrowth (a puff of leaf dust if you can see it).
func _tail_dive(z: Dictionary, seen: bool) -> void:
	if int(z["state"]) == Tail.GONE:
		return
	var here: Vector3 = z["pos"]
	if seen and not _sleeping:
		safari.puff_at(here + (z["up"] as Vector3) * 0.1, 6, LEAFDUST)
	z["state"] = Tail.GONE


func _pose_tail(i: int, z: Dictionary) -> void:
	var st: int = z["state"]
	if st in [Tail.GONE, Tail.HIDDEN]:
		_tail_herd.hide_one(i)
		return
	var up: Vector3 = z["up"]
	var pos: Vector3 = z["pos"]
	var k := float(z["k"])
	if bool(z["ground"]):
		# out of the undergrowth: it rises up out of the ground
		pos -= up * 0.3 * k
	else:
		# on a trunk: it scurries up (UP) or down from above (POP)
		pos += up * TAIL_UP_M * k
	var b := Basis.looking_at(z["face"], up)
	var breath := 1.0 + 0.03 * sin(_t * 3.1 + float(i))
	var xf := Transform3D(b * Basis.from_scale(Vector3(1.0, breath, 1.0)), pos)
	_tail_herd.pose(i, 0, xf)
	var flare := 0.0
	if st == Tail.GLOW:
		flare = clampf(minf(TAIL_GLOW_SEC - float(z["glow"]), float(z["glow"])) / 0.3, 0.0, 1.0)
	var sway := 0.03 * sin(_t * 2.3 + float(i) * 1.7)
	var bulb := xf * (Meshes.GLOWTAIL_BULB_AT + Vector3(sway, 0.0, 0.0))
	_tail_herd.pose(i, 1, Transform3D(b * Basis.from_scale(Vector3.ONE * (1.0 + 0.8 * flare)), bulb))
	_tail_herd.pose(i, 2, Transform3D(b * Basis.from_scale(Vector3.ONE * (0.45 + 1.1 * flare)), bulb))


## THE PACING DIRECTOR brings a glowtail: it scampers down a palm trunk that is in the middle of the view
## (TAIL_BRING_M from the lens), or - with no palm there - pops up out of the undergrowth onto clear ground.
func _bring_tail(spot: Dictionary) -> bool:
	var i := -1
	for k in _tails.size():
		if int(_tails[k]["spot"]) < 0 and int(_tails[k]["state"]) == Tail.GONE:
			i = k
			break
	if i < 0:
		return false
	var p := safari.planet
	var lens: Transform3D = spot["lens"]
	var z: Dictionary = _tails[i]
	# 1. a palm in view
	var used: Array = []
	for t: Dictionary in _tails:
		if int(t["state"]) != Tail.GONE and t["palm"] != null:
			used.append(t["palm"])
	var cands: Array = []
	for n: Node3D in _palms:
		var dd := n.global_position.distance_to(lens.origin)
		if dd >= TAIL_BRING_M.x - 0.5 and dd <= TAIL_BRING_M.y + 0.5 and not used.has(n):
			cands.append([dd, n])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c: Array in cands:
		var n: Node3D = c[1]
		var base := _palm_ang_toward(n, p.dir_of(lens.origin))
		for off: float in [0.0, 0.7, -0.7]:
			var cl := _tail_cling(n, "palm", base + off, 1.0)
			var body: Vector3 = (cl[0] as Vector3) + (cl[1] as Vector3) * 0.22
			var dd := body.distance_to(lens.origin)
			if dd < TAIL_BRING_M.x or dd > TAIL_BRING_M.y:
				continue
			if not pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC) or not pacing.sight_clear(lens.origin, body):
				continue
			z["palm"] = n
			z["kind"] = "palm"
			z["ground"] = false
			z["ang"] = base + off
			z["pos"] = cl[0]
			z["up"] = cl[1]
			# out from the trunk, a little away from you: it turns to a still camera (CURIOUS_*)
			z["face"] = (cl[2] as Vector3).rotated(cl[1], _rng.randf_range(0.5, 1.0) * (1.0 if _rng.randf() < 0.5 else -1.0))
			z["state"] = Tail.POP
			z["timer"] = SCOUT_POP_SEC
			z["k"] = 1.0
			z["out_t"] = 0.0
			AudioManager.play_sfx_at("footstep_grass_0", cl[0], -6.0, 0.25)
			return true
	# 2. clear ground in view
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0 or float(spot["rise"]) > TAIL_RISE_MAX:
			return false
		d = spot["ahead"]
	if p.nearest_prop_distance(d) < TAIL_GROUND_CLEAR_M or p.is_underwater(d):
		return false
	var g := p.surface_point(d)
	z["palm"] = null
	z["kind"] = "ground"
	z["ground"] = true
	z["pos"] = g
	z["up"] = p.ground_normal(d)
	var to_lens := lens.origin - g
	to_lens -= (z["up"] as Vector3) * to_lens.dot(z["up"])
	var face := to_lens.normalized() if to_lens.length() > 0.01 else _tangent_at(d)
	z["face"] = face.rotated(z["up"], _rng.randf_range(0.9, 1.6) * (1.0 if _rng.randf() < 0.5 else -1.0))
	z["state"] = Tail.POP
	z["timer"] = SCOUT_POP_SEC
	z["k"] = 1.0
	z["out_t"] = 0.0
	safari.puff_at(g + (z["up"] as Vector3) * 0.08, 8, LEAFDUST)
	AudioManager.play_sfx_at("footstep_grass_1", g, -6.0, 0.25)
	return true


# ---------------------------------------------------------------------------------------- spore-puffs
func _build_puffs() -> void:
	var p := safari.planet
	for k in PUFF_N:
		var roam := k < PUFF_ROAMERS
		var watch := k >= PUFF_ROAMERS and k < PUFF_ROAMERS + PUFF_WATCHERS
		var d := safari.start_dir
		if roam:
			var f: Vector2 = PUFF_FROM[k]
			d = _free_near(safari.dir_from_start(f.x, f.y), 0.8)
		_puffs.append({"dir": d, "head": _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU)),
			"state": Puf.DRIFT if roam else Puf.AWAY, "roamer": roam, "watch": watch, "out_t": 0.0,
			"alt": PUFF_ALT, "grow": 1.0 if roam else 0.0, "turn": 0.0, "turn_t": 0.0,
			"phase": _rng.randf_range(0.0, TAU), "hello": 0.0})
	_puff_herd = Herd.new()
	add_child(_puff_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(0.8, 0.8)
	var r := p.radius + 6.0
	_puff_herd.setup("SporePuffs", PUFF_N, [[Meshes.puff(), _prop, false],
		[glow, MaterialLib.glow_sprite(Color("#e8e2b8"), 1.5, {"softness": 0.0, "core": 0.18, "blink": 0.15, "blink_speed": 1.4}), false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_spore_pop = CPUParticles3D.new()
	_spore_pop.name = "PuffSpores"
	_spore_pop.amount = 18
	_spore_pop.lifetime = 1.6
	_spore_pop.one_shot = false
	# local: a world-coordinate CPUParticles3D reads its global transform when the warm-up copies it out of the tree
	_spore_pop.local_coords = true
	_spore_pop.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_spore_pop.emission_sphere_radius = 0.12
	_spore_pop.direction = Vector3.UP
	_spore_pop.spread = 180.0
	_spore_pop.gravity = Vector3.ZERO
	_spore_pop.initial_velocity_min = 0.25
	_spore_pop.initial_velocity_max = 0.55
	_spore_pop.damping_min = 0.4
	_spore_pop.damping_max = 0.8
	_spore_pop.scale_amount_min = 0.6
	_spore_pop.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	q.material = PlanetPropMeshes.sparkle_material(Color("#efe6b8"))
	_spore_pop.mesh = q
	_spore_pop.emitting = false
	add_child(_spore_pop)
	_puff_focus = Node3D.new()
	_puff_focus.name = "PuffFocus"
	add_child(_puff_focus)
	safari.add_subject({
		"id": "spore_puff", "name": "Spore-puff", "kind": "creature",
		"band": BAND_PUFF, "node": _puff_focus, "offset": Vector3.ZERO, "radius": 0.2,
		"awake": func() -> bool: return _puff_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _puff_pick >= 0 and int(_puffs[_puff_pick]["state"]) == Puf.HELLO:
				return {"mult": 1.8, "line": "puffing out a cloud of spores"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_puff_focus),
	})


func _puff_out(w: Dictionary) -> bool:
	return int(w["state"]) in [Puf.DRIFT, Puf.HELLO] or (int(w["state"]) == Puf.COME and float(w["grow"]) > 0.7)


func _puff_pos(w: Dictionary) -> Vector3:
	var d: Vector3 = w["dir"]
	var lift := float(w["alt"]) + 0.09 * sin(_t * 1.1 + float(w["phase"]))
	if int(w["state"]) in [Puf.COME, Puf.LEAVE]:
		lift += 0.9 * (1.0 - float(w["grow"]))
	var g := safari.planet.surface_point(d)
	return g + safari.planet.up_at(g) * lift


func _tick_puffs(delta: float) -> void:
	if _puff_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var still_up := safari.camera_up and safari.player.get_tangent_velocity().length() < 0.15
	var shy := pacing != null and pacing.shy("spore_puff")
	var hello_done := false
	var rare_on := _rare_warned_or_up()
	var any_hello := false
	for i in _puffs.size():
		var w: Dictionary = _puffs[i]
		if bool(w["watch"]):
			_tick_watcher(w, rare_on)
		if bool(w["roamer"]):
			_tick_roamer_rest(w)
		var st: int = w["state"]
		var pos := _puff_pos(w)
		var dist := pos.distance_to(ppos)
		var in_frame := _point_in_frame(pos, 1.1)
		if st != Puf.AWAY:
			w["out_t"] = float(w["out_t"]) + delta
		var brought := not bool(w["roamer"]) and not bool(w["watch"])
		if (_sleeping or (shy and not in_frame and brought)) and st in [Puf.DRIFT, Puf.HELLO, Puf.COME]:
			w["state"] = Puf.LEAVE
			st = Puf.LEAVE
		match st:
			Puf.AWAY:
				pass
			Puf.COME:
				w["grow"] = move_toward(float(w["grow"]), 1.0, delta / PUFF_COME_SEC)
				if float(w["grow"]) >= 1.0:
					w["state"] = Puf.DRIFT
			Puf.LEAVE:
				w["grow"] = move_toward(float(w["grow"]), 0.0, delta / PUFF_LEAVE_SEC)
				if float(w["grow"]) <= 0.0:
					w["state"] = Puf.AWAY
			Puf.DRIFT:
				var curious := still_up and dist < CURIOUS_M
				if not curious:
					_puff_drift(w, delta)
				elif dist < PUFF_KEEP_M:
					var here: Vector3 = w["dir"]
					w["dir"] = p.step_dir(here, (here * 2.0 - p.dir_of(ppos)).normalized(), 0.3 * delta)
				if _still >= STILL_SEC and dist < PUFF_HELLO_M and not hello_done and float(w["hello"]) <= -PUFF_HELLO_REST:
					w["state"] = Puf.HELLO
					w["hello"] = PUFF_HELLO_SEC
					hello_done = true
					AudioManager.play_sfx_at("collect_stardust", pos, -14.0, 0.2)
				elif curious and _still >= CURIOUS_AFTER:
					_puff_face(w, ppos, CURIOUS_RATE, delta)
				w["hello"] = float(w["hello"]) - delta
				if brought and float(w["out_t"]) > PUFF_OUT_MIN_SEC and dist > PUFF_LEAVE_M and not in_frame:
					w["state"] = Puf.LEAVE
			Puf.HELLO:
				w["hello"] = float(w["hello"]) - delta
				_puff_face(w, ppos, 6.0, delta)
				any_hello = true
				_spore_pop.global_position = pos
				if float(w["hello"]) <= 0.0 or not still_up:
					w["state"] = Puf.DRIFT
					w["hello"] = 0.0
		_pose_puff(i, w)
	_spore_pop.emitting = any_hello and not _sleeping
	_puff_pick = _pick_focus(_puffs, func(w: Dictionary) -> bool: return _puff_out(w),
		func(w: Dictionary) -> Vector3: return _puff_pos(w), 0.0)
	if _puff_pick >= 0:
		var w: Dictionary = _puffs[_puff_pick]
		var pos := _puff_pos(w)
		_puff_focus.global_transform = Transform3D(Basis.looking_at(w["head"], p.up_at(pos)), pos)


## ROAMER_REST_SEC: off once photographed and out of the frame; back later near you, out of view.
func _tick_roamer_rest(w: Dictionary) -> void:
	var st: int = w["state"]
	var until := float(w.get("rest_until", -INF))
	if _t < until and st in [Puf.DRIFT, Puf.HELLO] and not _point_in_frame(_puff_pos(w), 1.1):
		w["state"] = Puf.LEAVE
	elif st == Puf.AWAY and _t >= until and not _sleeping and until > -INF:
		if _puff_place_near(w):
			w["rest_until"] = -INF


## Puts puff `w` somewhere near you (15-45 degrees round) that you are not looking at, drifting in.
func _puff_place_near(w: Dictionary) -> bool:
	var p := safari.planet
	for tries in 12:
		var d := _polar(_player_dir(), _tangent_at(_player_dir()), _rng.randf_range(15.0, 45.0), _rng.randf_range(0.0, 360.0))
		var pos := p.surface_point(d) + p.up_at(p.surface_point(d)) * PUFF_ALT
		if p.nearest_prop_distance(d) >= 0.6 and not p.is_underwater(d) and not _point_in_frame(pos, 1.2):
			w["dir"] = d
			w["alt"] = PUFF_ALT
			w["head"] = _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
			w["state"] = Puf.COME
			w["grow"] = 0.0
			w["out_t"] = 0.0
			return true
	return false


## True from a rare event's warning to its end (the grazer; the giant bloom on a rare day).
func _rare_warned_or_up() -> bool:
	if bool(_eligible.get("canopy_grazer", false)) and _t >= GRAZER_START - WARN and _t < GRAZER_END:
		return true
	return bool(_eligible.get("giant_bloom", false)) and _t >= GIANT_START - WARN and _t < GIANT_END


## A WATCHER drifts out near you (out of the frame) when a rare is warned, and on toward the rare, drawn
## to it; after it, it drifts off out of your view.
func _tick_watcher(w: Dictionary, rare_on: bool) -> void:
	var st: int = w["state"]
	if rare_on and st == Puf.AWAY and not _sleeping:
		_puff_place_near(w)
	elif not rare_on and st in [Puf.DRIFT, Puf.HELLO] and not _point_in_frame(_puff_pos(w), 1.1):
		w["state"] = Puf.LEAVE


func _puff_drift(w: Dictionary, delta: float) -> void:
	var p := safari.planet
	var d: Vector3 = w["dir"]
	var head: Vector3 = w["head"]
	head = (head - d * head.dot(d)).normalized()
	w["turn_t"] = float(w["turn_t"]) - delta
	if float(w["turn_t"]) <= 0.0:
		w["turn_t"] = _rng.randf_range(2.0, 5.0)
		w["turn"] = _rng.randf_range(-0.35, 0.35)
	var turn := float(w["turn"])
	if bool(w["watch"]) and _rare_warned_or_up():
		var goal := _grazer_stand if _t < GRAZER_END + 1.0 else _giant_dir
		var want := _toward(d, goal)
		turn += clampf(head.cross(want).dot(d), -1.0, 1.0) * 0.6
	var ahead := p.step_dir(d, (d + head * 0.2).normalized(), 1.0)
	# round the trunks (the floor's understory is below it and does not matter)
	var tree := _nearest_trunk_m(ahead)
	if tree < 1.0 or rad_to_deg(ahead.angle_to(_pad_dir)) < 12.0:
		turn = 1.2 if turn >= 0.0 else -1.2
	head = head.rotated(d, turn * delta).normalized()
	var nd := p.step_dir(d, (d + head * 0.2).normalized(), PUFF_SPEED * delta)
	if d.dot(nd) < 0.9999999:
		head = Quaternion(d, nd) * head
	w["dir"] = nd
	w["head"] = (head - nd * head.dot(nd)).normalized()


## Metres from unit dir `d` to the nearest palm or parasol trunk (the things a puff at PUFF_ALT would
## drift into); the broadleaf below it does not count.
func _nearest_trunk_m(d: Vector3) -> float:
	var p := safari.planet
	var best := INF
	for k: String in _props:
		if not (k.begins_with("SpirePalm") or k.begins_with("Parasol") or k.begins_with("Spiral") or k.begins_with("RootArch")):
			continue
		var n: Node3D = _props[k]
		var a := p.dir_of(n.global_position).angle_to(d) * p.radius
		best = minf(best, a)
	return best


func _puff_face(w: Dictionary, world_pos: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = w["dir"]
	var want := world_pos - safari.planet.surface_point(d)
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = w["head"]
	w["head"] = cur.slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_puff(i: int, w: Dictionary) -> void:
	var st: int = w["state"]
	if st == Puf.AWAY:
		_puff_herd.hide_one(i)
		return
	var pos := _puff_pos(w)
	var up := safari.planet.up_at(pos)
	var g := lerpf(0.35, 1.0, float(w["grow"])) if st != Puf.LEAVE else maxf(float(w["grow"]), 0.001)
	var head: Vector3 = w["head"]
	var puffed := 1.0
	if st == Puf.HELLO:
		puffed = 1.0 + 0.18 * absf(sin(_t * 6.0))
	var b := Basis.looking_at(head, up) * Basis(Vector3.FORWARD, 0.12 * sin(_t * 1.3 + float(w["phase"])))
	var breath := (1.0 + 0.05 * sin(_t * 2.4 + float(w["phase"]))) * puffed
	_puff_herd.pose(i, 0, Transform3D(b * Basis.from_scale(Vector3.ONE * g * breath), pos))
	_puff_herd.pose(i, 1, Transform3D(Basis.from_scale(Vector3.ONE * g), pos))


## THE PACING DIRECTOR brings a puff: it drifts down out of the canopy into the middle of the view.
func _bring_puff(spot: Dictionary) -> bool:
	var i := -1
	for k in _puffs.size():
		var w: Dictionary = _puffs[k]
		if int(w["state"]) == Puf.AWAY and not bool(w["roamer"]) and not bool(w["watch"]):
			i = k
			break
	if i < 0:
		return false
	var d: Vector3 = spot["dir"]
	var alt := PUFF_ALT
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		d = spot["ahead"]
		alt = maxf(float(spot["rise"]) + pacing.SPOT_LIFT_M, PUFF_ALT)
	if safari.planet.is_underwater(d):
		alt += 0.3
	var w: Dictionary = _puffs[i]
	var lens: Transform3D = spot["lens"]
	w["dir"] = d
	w["alt"] = alt
	w["head"] = _toward(d, safari.planet.dir_of(lens.origin)).rotated(d, (1.0 if _rng.randf() < 0.5 else -1.0) * _rng.randf_range(1.0, 2.0))
	w["state"] = Puf.COME
	w["grow"] = 0.0
	w["out_t"] = 0.0
	w["hello"] = 0.0
	AudioManager.play_sfx_at("collect_stardust", _puff_pos(w), -14.0, 0.2)
	return true


# ---------------------------------------------------------------------------------------- lantern-snails (night)
func _build_snails() -> void:
	var p := safari.planet
	if _arcs.is_empty():
		return
	for k in mini(SNAIL_N, SNAIL_ON.size()):
		var on: Array = SNAIL_ON[k]
		var ai: int = mini(int(on[0]), _arcs.size() - 1)
		var s := {"arc": ai, "k": float(on[1]), "sgn": 1.0 if k % 2 == 0 else -1.0, "dir": Vector3.UP, "face": Vector3.FORWARD,
			"flare_ph": _rng.randf_range(0.0, SNAIL_FLARE_EVERY), "seen": -INF, "rest": -INF, "shift": _rng.randf_range(-0.35, 0.35)}
		_snail_place(s)
		_snails.append(s)
	_snail_herd = Herd.new()
	add_child(_snail_herd)
	var r := p.radius + 3.0
	_snail_herd.setup("LanternSnails", _snails.size(), [[Meshes.snail(), _prop, true], [Meshes.snail_glow(), _glow_magenta, false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_snail_focus = Node3D.new()
	_snail_focus.name = "SnailFocus"
	add_child(_snail_focus)
	safari.add_subject({
		"id": "lantern_snail", "name": "Lantern-snail", "kind": "creature",
		"band": BAND_SNAIL, "node": _snail_focus, "offset": Vector3(0.0, 0.14, 0.0), "radius": 0.2,
		"awake": func() -> bool: return safari.is_night and not _sleeping and _snail_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _snail_pick >= 0 and _snail_flare(_snails[_snail_pick]) > 0.6:
				return {"mult": 1.8, "line": "its shell lit up bright"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_snail_focus),
	})


## Snail `s` on its trail at its fraction "k", a little to one side of the centreline ("shift" m).
func _snail_place(s: Dictionary) -> void:
	var arc: PackedVector3Array = _arcs[int(s["arc"])]
	var k := clampf(float(s["k"]), 0.02, 0.98)
	var d := arc[0].slerp(arc[1], k).normalized()
	var along := _toward(d, arc[1])
	var side := d.cross(along).normalized()
	d = (d + side * (float(s["shift"]) / safari.planet.radius)).normalized()
	s["dir"] = d
	s["face"] = along * float(s["sgn"])


## 0..1: how bright snail `s`'s shell flares now (every SNAIL_FLARE_EVERY s, each on its own beat).
func _snail_flare(s: Dictionary) -> float:
	var ph := fmod(_t + float(s["flare_ph"]), SNAIL_FLARE_EVERY)
	if ph > SNAIL_FLARE_SEC:
		return 0.0
	return clampf(minf(ph / 0.4, (SNAIL_FLARE_SEC - ph) / 0.4), 0.0, 1.0)


func _tick_snails(delta: float) -> void:
	if _snail_herd == null:
		return
	var p := safari.planet
	var r := p.radius
	for i in _snails.size():
		var s: Dictionary = _snails[i]
		var here := p.surface_point(s["dir"])
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.15, 1.1)
		# THE REST (Fen's moth rule): seen, then left out of the frame, it tucks in for SNAIL_REST_SEC
		if in_frame and _t >= float(s["rest"]):
			s["seen"] = _t
		elif float(s["seen"]) > -INF and _t - float(s["seen"]) >= SNAIL_LEAVE_SEC and _t >= float(s["rest"]) and not in_frame:
			s["rest"] = _t + SNAIL_REST_SEC
			s["seen"] = -INF
		if _t < float(s["rest"]) or _sleeping:
			_snail_herd.hide_one(i)
			continue
		# crawl along the trail, turning round at its ends
		var arc: PackedVector3Array = _arcs[int(s["arc"])]
		var len_m := maxf(acos(clampf(arc[0].dot(arc[1]), -1.0, 1.0)) * r, 0.5)
		s["k"] = float(s["k"]) + float(s["sgn"]) * SNAIL_SPEED * delta / len_m
		if float(s["k"]) > 0.95 or float(s["k"]) < 0.05:
			s["sgn"] = -float(s["sgn"])
			s["k"] = clampf(float(s["k"]), 0.05, 0.95)
		_snail_place(s)
		var xf := _xf_ground(s["dir"], s["face"])
		var creep := 1.0 + 0.05 * sin(_t * 2.0 + float(i))
		xf.basis = xf.basis * Basis.from_scale(Vector3(1.0 / sqrt(creep), 1.0, creep))
		_snail_herd.pose(i, 0, xf)
		var fl := _snail_flare(s)
		_snail_herd.pose(i, 1, xf * Transform3D(Basis.from_scale(Vector3.ONE * (0.8 + 0.5 * fl)), Vector3(0.0, 0.17 * (1.0 - (0.8 + 0.5 * fl)), 0.05 * (1.0 - (0.8 + 0.5 * fl)))))
	var ids: Array = []
	for i in _snails.size():
		if _t >= float(_snails[i]["rest"]):
			ids.append(i)
	var k2 := _pick_focus(ids, func(_i: int) -> bool: return true,
		func(i: int) -> Vector3: return p.surface_point(_snails[i]["dir"]), 0.14)
	_snail_pick = int(ids[k2]) if k2 >= 0 else -1
	if _snail_pick >= 0:
		var s: Dictionary = _snails[_snail_pick]
		_snail_focus.global_transform = _xf_ground(s["dir"], s["face"])


# ---------------------------------------------------------------------------------------- the glimmer swarm
func _build_swarm() -> void:
	var p := safari.planet
	for pi: int in SWARM_POOLS:
		_glim_places.append([_pool_dir(pi), GLIM_LOW])
	for k in GLIM_N:
		_glims.append({"ang": TAU * float(k) / float(GLIM_N) + _rng.randf_range(-0.25, 0.25),
			"r_off": _rng.randf_range(-0.45, 0.45), "h_off": _rng.randf_range(-0.35, 0.35),
			"phase": _rng.randf_range(0.0, TAU), "pos": Vector3.ZERO, "head": Vector3.FORWARD, "spd": _rng.randf_range(0.85, 1.2)})
	_glim_herd = Herd.new()
	add_child(_glim_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(0.34, 0.34)
	var r := p.radius + 8.0
	_glim_herd.setup("Glimmers", GLIM_N, [[Meshes.glimmer(), _prop, false],
		[glow, MaterialLib.glow_sprite(Color("#ffd68a"), 2.0, {"softness": 0.0, "core": 0.25, "blink": 0.35, "blink_speed": 3.0}), false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	for i in GLIM_N:
		_glim_herd.hide_one(i)
	_glim_focus = Node3D.new()
	_glim_focus.name = "SwarmFocus"
	add_child(_glim_focus)
	safari.add_subject({
		"id": "glimmer_swarm", "name": "The Glimmer Swarm", "kind": "event",
		"band": BAND_SWARM, "node": _glim_focus, "radius": 1.4,
		"awake": func() -> bool: return _glim_at >= 0 and _glim_k > 0.6 and _glim_vis > 0.9 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			return {"mult": 2.0, "line": "the whole swarm spiralling up together"} if _swarm_turning() else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _nearest_heading(_glims, 0 if _glim_at >= 0 else -1, ""),
	})


func _swarm_turning() -> bool:
	var run := _run_at(SWARM_RUNS, _t, false)
	if run.is_empty():
		return false
	var tin := _t - float(run["start"])
	for s0: float in SWARM_TURNS:
		if tin >= s0 and tin < s0 + SWARM_TURN_SEC:
			return true
	return false


func _tick_swarm(delta: float) -> void:
	if _glim_herd == null:
		return
	var p := safari.planet
	var run := _run_at(SWARM_RUNS, _t, true)
	var want_vis := 0.0
	if not run.is_empty() and not _sleeping:
		_glim_at = int(run["at"])
		want_vis = 1.0
		var tin := _t - float(run["start"])
		_glim_k = move_toward(_glim_k, 1.0 if tin >= 0.0 else 0.0, delta / 3.0)
	elif _glim_at >= 0:
		_glim_k = move_toward(_glim_k, 0.0, delta / GLIM_LEAVE_SEC)
	_glim_vis = move_toward(_glim_vis, want_vis, delta / (1.2 if want_vis > 0.0 else GLIM_LEAVE_SEC))
	if _glim_at < 0 or _glim_vis <= 0.0:
		for i in GLIM_N:
			_glim_herd.hide_one(i)
		if _glim_vis <= 0.0 and run.is_empty():
			_glim_at = -1
		return
	var place: Array = _glim_places[_glim_at]
	var cd: Vector3 = place[0]
	var g := p.global_position + cd * _water_r
	var up := p.up_at(g)
	var t := _tangent_at(cd)
	var b := up.cross(t)
	var turning := _swarm_turning()
	var hgt := lerpf(GLIM_HIGH, float(place[1]), _glim_k)
	var rad := lerpf(GLIM_RADIUS * 1.8, GLIM_RADIUS, _glim_k)
	# spiralling up: they draw in to a tight column and climb, then settle back
	var tw := 0.0
	if turning:
		var run2 := _run_at(SWARM_RUNS, _t, false)
		var tin := _t - float(run2["start"])
		for s0: float in SWARM_TURNS:
			if tin >= s0 and tin < s0 + SWARM_TURN_SEC:
				tw = sin(PI * (tin - s0) / SWARM_TURN_SEC)
	for i in GLIM_N:
		var s: Dictionary = _glims[i]
		var spd := GLIM_SPEED * float(s["spd"]) * (1.0 + 0.8 * tw)
		s["ang"] = float(s["ang"]) + spd * delta
		var a := float(s["ang"])
		var frac := float(i) / float(GLIM_N)
		var rr := rad * (1.0 - 0.45 * tw) + float(s["r_off"]) * (1.0 - 0.7 * tw) + 0.25 * sin(a * 2.0 + float(s["phase"]))
		var hh := hgt + float(s["h_off"]) * (1.0 - 0.5 * tw) + 0.3 * sin(a * 1.5 + float(s["phase"])) + tw * (0.3 + 1.4 * frac)
		var pos := g + (t * cos(a) + b * sin(a)) * rr + up * hh
		var head := (-t * sin(a) + b * cos(a)).normalized()
		s["pos"] = pos
		s["head"] = head
		var bas := Basis.looking_at(head, up.rotated(head, -0.4))
		var beat := 1.0 - 0.4 * absf(sin(_t * 16.0 + float(s["phase"])))
		var sc := _glim_vis * 1.6
		_glim_herd.pose(i, 0, Transform3D(bas * Basis.from_scale(Vector3(beat * sc, sc, sc)), pos))
		_glim_herd.pose(i, 1, Transform3D(Basis.from_scale(Vector3.ONE * _glim_vis * (1.0 + 0.5 * tw)), pos))
	_glim_focus.global_transform = Transform3D(Basis.looking_at(t, up), g + up * (hgt + 0.5 * tw))
	_chirp_clock -= delta
	if _chirp_clock <= 0.0 and _glim_vis > 0.5:
		_chirp_clock = _rng.randf_range(0.8, 1.6)
		AudioManager.play_sfx_at("doot_c_2", g + up * hgt, -16.0, 0.3)


# ---------------------------------------------------------------------------------------- spore rain
func _build_rain() -> void:
	var p := safari.planet
	var fallback := [Vector2(62.5, 3.8), Vector2(70.5, -130.0), Vector2(118.7, 83.0)]
	for k in RAIN_PARASOLS.size():
		var fb: Vector2 = fallback[k]
		var n := _prop_named(RAIN_PARASOLS[k], "Parasol", safari.dir_from_start(fb.x, fb.y))
		if n == null:
			continue
		var up := n.global_basis.y.normalized()
		# the shower falls from under the tiers (2.2-3.2 m) round the trunk; it is SCORED at its middle,
		# RAIN_SCORE_H up, under the tiers' flat colliders (which stop sight rays)
		_rain_places.append({"dir": p.dir_of(n.global_position), "node": n, "base": n.global_position, "up": up})
		_log("spore rain %d under %s at %s" % [k, str(n.name), _pp(p.dir_of(n.global_position))])
	_rain_root = Node3D.new()
	_rain_root.name = "SporeRain"
	add_child(_rain_root)
	_rain_glow = _glow_quad("RainGlow", Color("#bff0dc"), Vector2(3.2, 2.6))
	_rain_root.add_child(_rain_glow)
	_rain_steady = _rain_emitter("RainSteady", 46, 3.4, Color("#c9f2df"))
	_rain_heavy = _rain_emitter("RainHeavy", 60, 2.6, Color("#f4e7b0"))
	_rain_focus = Node3D.new()
	_rain_focus.name = "RainFocus"
	add_child(_rain_focus)
	safari.add_subject({
		"id": "spore_rain", "name": "Spore Rain", "kind": "event",
		"band": BAND_RAIN, "node": _rain_focus, "radius": 1.3,
		"awake": func() -> bool: return _any_running(RAIN_RUNS) and _rain_at >= 0 and _rain_level > 0.6 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(RAIN_RUNS, _t, false)
			if not run.is_empty():
				var tin := _t - float(run["start"])
				if tin >= RAIN_HEAVY_AT and tin < RAIN_HEAVY_AT + RAIN_HEAVY_SEC:
					return {"mult": 2.0, "line": "the heaviest shower of spores"}
			return {"mult": 1.0, "line": ""},
	})
const RAIN_SCORE_H := 1.8
const RAIN_TOP_H := 2.3


func _rain_emitter(label: String, amount: int, life: float, colour: Color) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = label
	e.amount = amount
	e.lifetime = life
	e.local_coords = true
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	e.emission_box_extents = Vector3(1.4, 0.1, 1.4)
	e.direction = Vector3.DOWN
	e.spread = 20.0
	e.gravity = Vector3(0.0, -0.18, 0.0)
	e.initial_velocity_min = 0.25
	e.initial_velocity_max = 0.5
	e.damping_min = 0.05
	e.damping_max = 0.15
	e.scale_amount_min = 0.7
	e.scale_amount_max = 1.5
	var q := QuadMesh.new()
	q.size = Vector2(0.075, 0.075)
	q.material = PlanetPropMeshes.sparkle_material(colour)
	e.mesh = q
	e.emitting = false
	_rain_root.add_child(e)
	return e


func _tick_rain(delta: float) -> void:
	if _rain_root == null or _rain_places.is_empty():
		return
	var run := _run_at(RAIN_RUNS, _t, true)
	var want := 0.0
	if not run.is_empty() and not _sleeping:
		var at := mini(int(run["at"]), _rain_places.size() - 1)
		if at != _rain_at:
			_rain_at = at
			var pl: Dictionary = _rain_places[at]
			var up: Vector3 = pl["up"]
			var base: Vector3 = pl["base"]
			_rain_root.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, up)), base)
			_rain_focus.global_transform = Transform3D(Basis.looking_at(_tangent_at(safari.planet.dir_of(base)), up), base + up * RAIN_SCORE_H)
			_rain_glow.position = Vector3(0.0, 1.6, 0.0)
			_rain_steady.position = Vector3(0.0, RAIN_TOP_H, 0.0)
			_rain_heavy.position = Vector3(0.0, RAIN_TOP_H, 0.0)
		var tin := _t - float(run["start"])
		# the warning: the tiers glow; the run: the shower, heavy at RAIN_HEAVY_AT
		want = 0.4 if tin < 0.0 else 1.0
		_rain_steady.emitting = tin >= -1.5 and tin < float(run["end"]) - float(run["start"]) - 1.0
		_rain_heavy.emitting = tin >= RAIN_HEAVY_AT - 0.6 and tin < RAIN_HEAVY_AT + RAIN_HEAVY_SEC
	else:
		_rain_steady.emitting = false
		_rain_heavy.emitting = false
	_rain_level = move_toward(_rain_level, want, delta / 1.2)
	_rain_glow.visible = _rain_level > 0.01
	(_rain_glow.material_override as ShaderMaterial).set_shader_parameter("fade", _rain_level * (0.5 + 0.15 * sin(_t * 2.6)))


# ---------------------------------------------------------------------------------------- the bloom burst
const PETALS_N := 7


func _build_bud() -> void:
	var p := safari.planet
	# BESIDE A TRAIL (BUD_TRAIL): off the trails the knee-high broadleaf hides a 1.3 m flower from a lens
	# 1.1 m up (frames, 2026-09-29); on the trail's edge it stands in the open, seen along the path
	_bud_dir = _trail_side(int(BUD_TRAIL[0]), float(BUD_TRAIL[1]), float(BUD_TRAIL[2]))
	_bud_root = Node3D.new()
	_bud_root.name = "BurstBud"
	add_child(_bud_root)
	var face := _toward(_bud_dir, safari.start_dir)
	_bud_root.global_transform = _xf_ground(_bud_dir, face)
	var stalk := MeshInstance3D.new()
	stalk.name = "Stalk"
	stalk.mesh = Meshes.bud_stalk()
	stalk.material_override = _prop
	_bud_root.add_child(stalk)
	_bud_heart = MeshInstance3D.new()
	_bud_heart.name = "Heart"
	_bud_heart.mesh = Meshes.bloom_heart()
	_bud_heart.material_override = _glow_amber
	_bud_heart.position = Meshes.BUD_AT
	_bud_root.add_child(_bud_heart)
	_bud_glow = _glow_quad("BudGlow", Color("#f2c3dc"), Vector2(1.6, 1.6))
	_bud_glow.position = Meshes.BUD_AT + Vector3(0.0, 0.25, 0.0)
	_bud_root.add_child(_bud_glow)
	_petal_herd = Herd.new()
	add_child(_petal_herd)
	_petal_herd.setup("BudPetals", PETALS_N, [[Meshes.petal(false), _prop, false]], Herd.area_around([_bud_root.global_position], 3.0))
	_pollen = CPUParticles3D.new()
	_pollen.name = "BudPollen"
	_pollen.amount = 40
	_pollen.lifetime = 2.2
	_pollen.local_coords = true
	_pollen.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_pollen.emission_sphere_radius = 0.15
	_pollen.direction = Vector3.UP
	_pollen.spread = 65.0
	_pollen.gravity = Vector3(0.0, -0.3, 0.0)
	_pollen.initial_velocity_min = 0.8
	_pollen.initial_velocity_max = 1.6
	_pollen.damping_min = 0.6
	_pollen.damping_max = 1.0
	_pollen.scale_amount_min = 0.7
	_pollen.scale_amount_max = 1.5
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = PlanetPropMeshes.sparkle_material(Color("#ffd99a"))
	_pollen.mesh = q
	_pollen.emitting = false
	_pollen.position = Meshes.BUD_AT + Vector3(0.0, 0.1, 0.0)
	_bud_root.add_child(_pollen)
	_bud_focus = Node3D.new()
	_bud_focus.name = "BurstFocus"
	add_child(_bud_focus)
	var up := p.up_at(_bud_root.global_position)
	_bud_focus.global_transform = Transform3D(Basis.looking_at(face, up), _bud_root.global_transform * Meshes.BUD_AT)
	safari.add_subject({
		"id": "bloom_burst", "name": "The Bloom Burst", "kind": "event",
		"band": BAND_BURST, "node": _bud_focus, "radius": 0.9,
		"awake": func() -> bool: return _any_running(BURST_RUNS) and _bud_open > 0.5 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(BURST_RUNS, _t, false)
			if not run.is_empty():
				var tin := _t - float(run["start"])
				if tin >= BURST_FULL.x and tin < BURST_FULL.y:
					return {"mult": 2.0, "line": "bursting open in a cloud of pollen"}
			return {"mult": 1.0, "line": ""},
	})
	_log("bloom bud at %s (nearest prop %.2f m)" % [_pp(_bud_dir), p.nearest_prop_distance(_bud_dir)])
	_pose_petals()
## [trail arc (JungleLayout.trail_arcs), fraction along it, metres to its right side].
const BUD_TRAIL := [2, 0.5, 1.0]


func _tick_bud(delta: float) -> void:
	if _bud_root == null:
		return
	var run := _run_at(BURST_RUNS, _t, true)
	var want_open := 0.0
	var want_swell := 0.0
	if not run.is_empty() and not _sleeping:
		var tin := _t - float(run["start"])
		want_swell = 1.0 if tin < 0.0 else 0.0
		if tin >= 0.0:
			want_open = 1.0 if tin < float(run["end"]) - float(run["start"]) - 1.5 else 0.0
		_pollen.emitting = tin >= BURST_FULL.x - 0.5 and tin < BURST_FULL.y
	else:
		_pollen.emitting = false
	_bud_open = move_toward(_bud_open, want_open, delta / BURST_OPEN_SEC)
	_bud_swell = move_toward(_bud_swell, want_swell, delta / 1.0)
	var lv := maxf(_bud_swell * (0.5 + 0.3 * sin(_t * 5.0)), _bud_open * 0.8)
	_bud_glow.visible = lv > 0.01
	(_bud_glow.material_override as ShaderMaterial).set_shader_parameter("fade", lv)
	_bud_heart.scale = Vector3.ONE * lerpf(0.4, 1.3, _bud_open)
	_pose_petals()


## Closed, the petals stand up round the heart, wrapped tight (swelling and pulsing in the warning); open,
## they lie out flat and a little down, with a spring overshoot as they burst.
func _pose_petals() -> void:
	var o := _bud_open
	var burst := o + 0.25 * sin(PI * clampf(o, 0.0, 1.0)) * (1.0 - o)
	var swell := 1.0 + 0.2 * _bud_swell * (0.5 + 0.5 * sin(_t * 5.0))
	var xf0 := _bud_root.global_transform
	for k in PETALS_N:
		var a := TAU * float(k) / float(PETALS_N)
		# tilt out from standing (0.12 rad) to laid open (1.45 rad)
		var tilt := lerpf(0.12, 1.45, clampf(burst, 0.0, 1.2))
		var sway := 0.06 * sin(_t * 1.4 + float(k)) * o
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -tilt - sway)
		var sc := lerpf(0.7, 1.35, o) * swell
		var loc := Transform3D(b * Basis.from_scale(Vector3.ONE * sc), Meshes.BUD_AT + Vector3(0.0, 0.02, 0.0))
		_petal_herd.pose(k, 0, xf0 * loc)


# ---------------------------------------------------------------------------------------- the canopy grazer
## It walks in along a trail over the WARN seconds from GRAZER_WALK_M away and stops on the trail at the
## point nearest its parasol (see _build_grazer).
const GRAZER_WALK_M := 9.0
const GRAZER_MIN_DEG := 60.0
## Big: its back stands over the knee-high broadleaf and its head reaches the parasol tiers (J1's tiers
## are 2.2-3.2 m up), so it reads above the understory from the trail.
const GRAZER_SCALE := 1.5
const GRAZER_TURN_DEG := 110.0


func _build_grazer() -> void:
	var p := safari.planet
	# its parasol: the one nearest a trail that is not a spore-rain tree and is GRAZER_MIN_DEG or more
	# round from the start (J1 keeps parasols 2.6 m or more off the trails, so it reaches to browse)
	var par: Node3D = null
	var best_m := INF
	var rain_nodes: Array = _rain_places.map(func(r: Dictionary) -> Node3D: return r["node"])
	for k: String in _props:
		if not k.begins_with("Parasol") or rain_nodes.has(_props[k]):
			continue
		var n: Node3D = _props[k]
		var nd := p.dir_of(n.global_position)
		if rad_to_deg(nd.angle_to(safari.start_dir)) < GRAZER_MIN_DEG:
			continue
		var m := (_nearest_trail_point(nd)[0] as Vector3).angle_to(nd) * p.radius
		if m < best_m:
			best_m = m
			par = n
	var pd := p.dir_of(par.global_position) if par != null else safari.dir_from_start(83.5, 68.3)
	# ON THE TRAIL nearest its parasol (the broadleaf off the trails hides even a 3 m grazer from a lens
	# 1.1 m up), facing the tree to browse; it walks in along that trail from GRAZER_WALK_M away, from the
	# end farther from the start
	var near := _nearest_trail_point(pd)
	var ai := int(near[1])
	var k0 := float(near[2])
	_grazer_stand = near[0]
	var arc: PackedVector3Array = _arcs[ai] if ai >= 0 else PackedVector3Array([pd, pd])
	var len_m := maxf(acos(clampf(arc[0].dot(arc[1]), -1.0, 1.0)) * p.radius, 0.1)
	var dk := GRAZER_WALK_M / len_m
	var ka := clampf(k0 - dk, 0.0, 1.0)
	var kb := clampf(k0 + dk, 0.0, 1.0)
	var da := arc[0].slerp(arc[1], ka).normalized()
	var db := arc[0].slerp(arc[1], kb).normalized()
	_grazer_from = da if da.angle_to(safari.start_dir) > db.angle_to(safari.start_dir) else db
	if _grazer_from.angle_to(_grazer_stand) * p.radius < 3.0:
		_grazer_from = _polar(_grazer_stand, _toward(_grazer_stand, pd), rad_to_deg(GRAZER_WALK_M / p.radius), 180.0)
	_grazer_face = _toward(_grazer_stand, pd)
	var best_line := _grazer_from.angle_to(_grazer_stand) * p.radius
	_grazer_root = Node3D.new()
	_grazer_root.name = "CanopyGrazer"
	add_child(_grazer_root)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = Meshes.grazer_body()
	body.material_override = _prop
	_grazer_root.add_child(body)
	var spots := MeshInstance3D.new()
	spots.name = "Spots"
	spots.mesh = Meshes.grazer_spots()
	spots.material_override = _glow_teal
	spots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grazer_root.add_child(spots)
	_grazer_neck = MeshInstance3D.new()
	_grazer_neck.name = "Neck"
	_grazer_neck.mesh = Meshes.grazer_neck()
	_grazer_neck.material_override = _prop
	_grazer_neck.position = Meshes.GRAZER_SHOULDER
	_grazer_root.add_child(_grazer_neck)
	for k in 4:
		var leg := MeshInstance3D.new()
		leg.name = "Leg%d" % k
		leg.mesh = Meshes.grazer_leg()
		leg.material_override = _prop
		leg.position = Meshes.GRAZER_HIPS[k]
		_grazer_root.add_child(leg)
		_grazer_legs.append(leg)
	_grazer_root.visible = false
	_grazer_focus = Node3D.new()
	_grazer_focus.name = "GrazerFocus"
	add_child(_grazer_focus)
	safari.add_subject({
		"id": "canopy_grazer", "name": "The Canopy Grazer", "kind": "rare",
		"band": BAND_GRAZER, "node": _grazer_focus, "offset": Vector3(0.0, 1.45, -0.2) * GRAZER_SCALE, "radius": 1.5 * GRAZER_SCALE,
		"awake": func() -> bool: return safari.event_running("canopy_grazer") and _grazer_shown and not _sleeping,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 2.2, "line": "lifting its head to hoot"} if tt >= GRAZER_HOOT.x and tt < GRAZER_HOOT.y else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_grazer_focus),
	})
	_log("canopy grazer: on trail %d by %s (%.1f m from its trunk) at %s, walks in %.1f m along the trail from %s" % [
		ai, str(par.name) if par != null else "?", _grazer_stand.angle_to(pd) * p.radius, _pp(_grazer_stand), best_line, _pp(_grazer_from)])


func _tick_grazer(delta: float) -> void:
	if _grazer_root == null:
		return
	var on := bool(_eligible.get("canopy_grazer", false)) and _t >= GRAZER_START - WARN and _t < GRAZER_END + 4.0 and not _sleeping
	_grazer_root.visible = on
	_grazer_shown = on
	if not on:
		return
	var t_in := _t - GRAZER_START
	var dir := _grazer_stand
	var face := _grazer_face
	var walking := 0.0
	var neck_up := 0.0      # 0 browsing low into the tier's edge, 1 head up high (the hoot)
	var neck_fwd := 0.0     # 1 = neck reaching forward (walking)
	if t_in < 0.0:
		# THE WARNING: it walks in from the jungle
		var k := smoothstep(0.0, 1.0, clampf((t_in + WARN) / WARN, 0.0, 1.0))
		dir = _grazer_from.slerp(_grazer_stand, k).normalized()
		face = _toward(dir, _grazer_stand) if k < 0.97 else _grazer_face
		face = face.slerp(_grazer_face, smoothstep(0.8, 1.0, k)).normalized()
		walking = 1.0 - smoothstep(0.9, 1.0, k)
		neck_fwd = 1.0
	elif _t < GRAZER_END:
		# browsing, then the hoot: the head comes up high and back, and it calls
		neck_up = 0.15 + 0.12 * sin(t_in * 1.3)
		neck_fwd = 0.45 * (1.0 - smoothstep(GRAZER_HOOT.x - 1.5, GRAZER_HOOT.x, _t) * (1.0 - smoothstep(GRAZER_HOOT.y, GRAZER_HOOT.y + 1.5, _t)))
		if _t >= GRAZER_HOOT.x - 0.8 and _t < GRAZER_HOOT.y + 0.8:
			neck_up = lerpf(neck_up, 1.0, clampf(minf(_t - (GRAZER_HOOT.x - 0.8), GRAZER_HOOT.y + 0.8 - _t) / 0.8, 0.0, 1.0))
		face = _grazer_face.rotated(_grazer_stand, 0.12 * sin(t_in * 0.4))
		# for the hoot it turns from the tree toward you (at most GRAZER_TURN_DEG), then back to browse
		var turn_w := smoothstep(GRAZER_HOOT.x - 3.0, GRAZER_HOOT.x - 0.5, _t) * (1.0 - smoothstep(GRAZER_HOOT.y + 0.5, GRAZER_HOOT.y + 3.0, _t))
		if turn_w > 0.0 and is_instance_valid(safari.player):
			var to := _toward(_grazer_stand, safari.planet.dir_of(safari.player.global_position))
			var ang := clampf(face.signed_angle_to(to, _grazer_stand), -deg_to_rad(GRAZER_TURN_DEG), deg_to_rad(GRAZER_TURN_DEG))
			face = face.rotated(_grazer_stand, ang * turn_w).normalized()
	else:
		# away: it turns and walks off the way it came
		var k := clampf((_t - GRAZER_END) / 4.0, 0.0, 1.0)
		dir = _grazer_stand.slerp(_grazer_from, smoothstep(0.0, 1.0, k)).normalized()
		face = _toward(dir, _grazer_from)
		walking = 1.0
		neck_fwd = 1.0
		if k >= 0.99:
			_grazer_root.visible = false
	var xf := _xf_ground(dir, face)
	if walking > 0.0:
		_grazer_step += delta * 1.7 * walking
	var bob := 0.04 * absf(sin(_grazer_step * PI)) * walking
	xf = xf.translated_local(Vector3(0.0, bob - 0.04, 0.0))
	xf.basis = xf.basis * Basis.from_scale(Vector3.ONE * GRAZER_SCALE)
	_grazer_root.global_transform = xf
	_grazer_focus.global_transform = Transform3D(xf.basis.orthonormalized(), xf.origin)
	# neck: pitched forward to walk, back and up to hoot
	var pitch := lerpf(0.0, -0.45, neck_fwd) + lerpf(0.0, 0.3, neck_up)
	_grazer_neck.transform = Transform3D(Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, 0.15 * sin(_t * 0.6) * (1.0 - walking)), Meshes.GRAZER_SHOULDER)
	for k in 4:
		var ph := _grazer_step * PI + (0.0 if k == 0 or k == 3 else PI)
		var swing := 0.35 * sin(ph) * walking
		_grazer_legs[k].transform = Transform3D(Basis(Vector3.RIGHT, swing), Meshes.GRAZER_HIPS[k])
	# footsteps and the hoot
	if walking > 0.3 and fmod(_grazer_step, 1.0) < delta * 1.7 * walking + 0.001:
		AudioManager.play_sfx_at("footstep_grass_0", xf.origin, -2.0, 0.1)
	if _t >= GRAZER_HOOT.x and _t - delta < GRAZER_HOOT.x:
		var head := _grazer_neck.global_transform * Meshes.GRAZER_HEAD
		AudioManager.play_sfx_at("voice_elder_2", head, 0.0, 0.0)
		_sound_once("doot_a_0", 0.45, -6.0).play()


# ---------------------------------------------------------------------------------------- the giant bloom (rare day)
const GIANT_PETALS := 8
## [trail arc, fraction along it, metres to its right side]: arc 5 runs from the spawn out to the back
## trail's bend at (94, 112), a few metres from pool 2.
const GIANT_TRAIL := [5, 0.88, 1.5]
const GIANT_PETAL_SCALE := 2.7


func _build_giant() -> void:
	var p := safari.planet
	# beside the back trail near its bend (GIANT_TRAIL), in the open: its petals open out over the path
	_giant_dir = _trail_side(int(GIANT_TRAIL[0]), float(GIANT_TRAIL[1]), float(GIANT_TRAIL[2]))
	_giant_root = Node3D.new()
	_giant_root.name = "GiantBloom"
	add_child(_giant_root)
	var face := _toward(_giant_dir, safari.start_dir)
	_giant_root.global_transform = _xf_ground(_giant_dir, face)
	var base := MeshInstance3D.new()
	base.name = "Base"
	base.mesh = Meshes.giant_base()
	base.material_override = _prop
	_giant_root.add_child(base)
	for k in GIANT_PETALS:
		var mi := MeshInstance3D.new()
		mi.name = "Petal%d" % k
		mi.mesh = Meshes.petal(true)
		mi.material_override = _prop
		_giant_root.add_child(mi)
		_giant_petals.append(mi)
	_giant_heart = MeshInstance3D.new()
	_giant_heart.name = "Heart"
	_giant_heart.mesh = Meshes.bloom_heart()
	_giant_heart.material_override = _glow_teal
	_giant_heart.position = Meshes.GIANT_HEART_AT
	_giant_root.add_child(_giant_heart)
	_giant_glow = _glow_quad("GiantGlow", Color("#aef0dc"), Vector2(3.4, 3.4))
	_giant_glow.position = Meshes.GIANT_HEART_AT + Vector3(0.0, 0.5, 0.0)
	_giant_root.add_child(_giant_glow)
	_giant_motes = CPUParticles3D.new()
	_giant_motes.name = "GiantMotes"
	_giant_motes.amount = 36
	_giant_motes.lifetime = 3.5
	_giant_motes.local_coords = true
	_giant_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_giant_motes.emission_sphere_radius = 0.4
	_giant_motes.direction = Vector3.UP
	_giant_motes.spread = 30.0
	_giant_motes.gravity = Vector3.ZERO
	_giant_motes.initial_velocity_min = 0.3
	_giant_motes.initial_velocity_max = 0.7
	_giant_motes.scale_amount_min = 0.8
	_giant_motes.scale_amount_max = 1.6
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	q.material = PlanetPropMeshes.sparkle_material(Color("#c9f5e4"))
	_giant_motes.mesh = q
	_giant_motes.emitting = false
	_giant_motes.position = Meshes.GIANT_HEART_AT + Vector3(0.0, 0.2, 0.0)
	_giant_root.add_child(_giant_motes)
	_giant_root.visible = false
	_giant_focus = Node3D.new()
	_giant_focus.name = "GiantFocus"
	add_child(_giant_focus)
	var up := p.up_at(_giant_root.global_position)
	_giant_focus.global_transform = Transform3D(Basis.looking_at(face, up), _giant_root.global_position + up * 1.0)
	safari.add_subject({
		"id": "giant_bloom", "name": "The Giant Bloom", "kind": "rare",
		"band": BAND_GIANT, "node": _giant_focus, "radius": 1.4,
		"awake": func() -> bool: return safari.event_running("giant_bloom") and _giant_open > 0.4 and not _sleeping,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 2.2, "line": "wide open and glowing"} if tt >= GIANT_OPEN.x and tt < GIANT_OPEN.y else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_giant_focus),
	})
	_log("giant bloom beside trail %d at %s (nearest prop %.2f m)" % [int(GIANT_TRAIL[0]), _pp(_giant_dir), p.nearest_prop_distance(_giant_dir)])


func _tick_giant(delta: float) -> void:
	if _giant_root == null:
		return
	var warned := bool(_eligible.get("giant_bloom", false)) and _t >= GIANT_START - WARN and _t < GIANT_END + 3.0 and not _sleeping
	_giant_root.visible = warned
	if not warned:
		return
	var want := 0.0
	var swell := 0.0
	if _t < GIANT_START:
		swell = clampf((_t - (GIANT_START - WARN)) / WARN, 0.0, 1.0)
	elif _t < GIANT_END:
		want = 0.7 if _t < GIANT_OPEN.x else (1.0 if _t < GIANT_OPEN.y else 0.8)
	_giant_open = move_toward(_giant_open, want, delta / 3.0)
	_giant_motes.emitting = _t >= GIANT_OPEN.x - 1.0 and _t < GIANT_OPEN.y + 1.0
	var lv := maxf(swell * (0.45 + 0.25 * sin(_t * 3.0)), _giant_open * (0.75 + 0.2 * sin(_t * 1.8)))
	_giant_glow.visible = lv > 0.01
	(_giant_glow.material_override as ShaderMaterial).set_shader_parameter("fade", lv)
	_giant_heart.scale = Vector3.ONE * lerpf(1.2, 3.4, _giant_open)
	var grow := lerpf(0.6, 1.0, maxf(swell, minf(_giant_open * 2.0, 1.0)))
	for k in GIANT_PETALS:
		var a := TAU * float(k) / float(GIANT_PETALS) + (0.2 if k % 2 else 0.0)
		var tilt := lerpf(0.1, 1.35 - 0.12 * float(k % 2), _giant_open)
		var sway := 0.04 * sin(_t * 1.1 + float(k)) * _giant_open
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -tilt - sway)
		_giant_petals[k].transform = Transform3D(b * Basis.from_scale(Vector3.ONE * GIANT_PETAL_SCALE * grow), Meshes.GIANT_HEART_AT + Vector3(0.0, -0.05 * float(k % 2), 0.0))


# ======================================================================================== SIGHTS AND BONUS (15.5)
## THE SIGHTS are J1's own props, named: a focus node on each and nothing drawn. Their bands are for
## framing the whole thing with the wide lens from where a person stands to look at it (Fen's arch and
## colonnade numbers); neither has a face, so neither has a Facing score. Rarity 1; they pay as usual.
const BAND_ROOT_ARCH := Vector2(0.50, 0.90)
const BAND_DEEP_POOL := Vector2(0.55, 1.00)
## THE BONUS PAGES: small, still, tucked away. Bands from the header's formula at the distance a finder
## stands (2.5-3 m).
##   subject          radius  usual d  band
##   the reed hat     0.15     2.5 m   0.25-0.41
##   the shell house  0.22     3.0 m   0.31-0.50
##   the heart lily   0.20     3.0 m   0.28-0.46
const BAND_HAT := Vector2(0.25, 0.41)
const BAND_HOUSE := Vector2(0.31, 0.50)
const BAND_LILY := Vector2(0.28, 0.46)
## The hat hangs on its palm this high up the trunk (node-local), on the side away from the nearest trail.
const HAT_Y := 1.35
const HAT_OUT := 0.33
## The shell house sits this far past the end of the back trail (JungleLayout arc 6: a dead end).
const HOUSE_TRAIL := 6
const HOUSE_PAST_M := 1.0
## The heart lily floats this far in from its pool's edge, on the side toward the start.
const LILY_IN_M := 0.7
const LILY_DRIFT_M := 0.1
const LILY_DRIFT_SEC := 28.0

var _sight_nodes: Array = []
var _hat: MeshInstance3D
var _house: MeshInstance3D
var _lily: MeshInstance3D
var _lily_anchor := Vector3.UP
var _lily_t0 := Vector3.FORWARD


func _build_sights() -> void:
	var p := safari.planet
	# THE ROOT ARCH: the arch over the trail by the landing pad, its middle and half its height
	var arch := _prop_named(SIGHT_ARCH, "RootArch", safari.dir_from_start(9.0, 102.0))
	var ac := safari.ground_point(safari.dir_from_start(9.0, 102.0), 1.4)
	var ar := 1.7
	if arch != null:
		ac = arch.global_position + arch.global_basis.y.normalized() * 1.35
		for c in arch.get_children():
			if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
				var mi: MeshInstance3D = c
				var bb := mi.get_aabb()
				ac = mi.global_transform * bb.get_center()
				var sc := mi.global_basis.get_scale()
				ar = 0.5 * maxf(bb.size.y * sc.y, bb.size.x * sc.x)
				break
	var arch_focus := Node3D.new()
	arch_focus.name = "RootArchFocus"
	add_child(arch_focus)
	arch_focus.global_position = ac
	_sight_nodes.append(arch_focus)
	safari.add_subject({
		"id": "root_arch", "name": "The Root Arch", "kind": "sight", "category": "sight",
		"band": BAND_ROOT_ARCH, "node": arch_focus, "radius": ar,
		"awake": func() -> bool: return not _sleeping,
	})
	# THE DEEP POOL: the water's middle, a little up, as wide as its water
	var pool_focus := Node3D.new()
	pool_focus.name = "DeepPoolFocus"
	add_child(pool_focus)
	pool_focus.global_position = _water_point(DEEP_POOL, 0.35)
	_sight_nodes.append(pool_focus)
	var pr := float(_pools[DEEP_POOL]["shore_m"]) if DEEP_POOL < _pools.size() else 2.0
	safari.add_subject({
		"id": "deep_pool", "name": "The Deep Pool", "kind": "sight", "category": "sight",
		"band": BAND_DEEP_POOL, "node": pool_focus, "radius": pr,
		"awake": func() -> bool: return not _sleeping,
	})
	_log("sights: root arch %s at %s r %.2f m; deep pool (%d) at %s r %.2f m" % [
		str(arch.name) if arch != null else "-", _pp(p.dir_of(ac)), ar, DEEP_POOL, _pp(_pool_dir(DEEP_POOL)), pr])


func _build_bonus() -> void:
	var p := safari.planet
	# 1. A TINY REED HAT, hung on a palm trunk on the side away from the trail
	_hat = MeshInstance3D.new()
	_hat.name = "ReedHat"
	_hat.mesh = Meshes.reed_hat()
	_hat.material_override = _prop
	add_child(_hat)
	var palm := _prop_named(HAT_PALM, "SpirePalm", safari.dir_from_start(36.0, -140.0))
	if palm != null:
		var pd := p.dir_of(palm.global_position)
		var trail := _nearest_trail_dir(pd)
		var away := (pd * 2.0 - trail).normalized()
		var ang := _palm_ang_toward(palm, away)
		var xf := palm.global_transform
		var up := xf.basis.y.normalized()
		var sc := xf.basis.get_scale().y
		var bx := xf.basis.x.normalized()
		var bz := (up.cross(bx)).normalized()
		bx = bz.cross(up).normalized()
		var out := (bx * cos(ang) + bz * sin(ang)).normalized()
		_hat.global_transform = Transform3D(Basis.looking_at(out, up) * Basis(Vector3.FORWARD, 0.35), xf.origin + up * HAT_Y * sc + out * (HAT_OUT - 0.04) * sc)
		_log("reed hat on %s at %s, facing away from the trail" % [palm.name, _pp(p.dir_of(_hat.global_position))])
	else:
		_hat.global_transform = _xf(_free_near(safari.dir_from_start(36.0, -140.0), 0.5), safari.start_fwd).translated_local(Vector3(0.0, 0.2, 0.0))
	safari.add_subject({
		"id": "reed_hat", "name": "A Tiny Reed Hat", "kind": "bonus", "category": "bonus",
		"band": BAND_HAT, "node": _hat, "offset": Vector3(0.0, -0.02, -0.05), "radius": 0.15,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_hat),
	})
	# 2. A SHELL HOUSE, just past the end of the back trail, its door to the trail
	_house = MeshInstance3D.new()
	_house.name = "ShellHouse"
	_house.mesh = Meshes.shell_house()
	_house.material_override = _prop
	add_child(_house)
	var hd := safari.dir_from_start(125.0, 101.0)
	var end_d := hd
	if HOUSE_TRAIL < _arcs.size():
		var arc: PackedVector3Array = _arcs[HOUSE_TRAIL]
		end_d = arc[1]
		var along := _toward(end_d, arc[1] * 2.0 - arc[0])
		hd = _polar(end_d, along, rad_to_deg(HOUSE_PAST_M / p.radius), 0.0)
	hd = _free_near(hd, 0.45)
	_house.global_transform = _xf_ground(hd, _toward(hd, end_d))
	safari.add_subject({
		"id": "shell_house", "name": "A Shell House", "kind": "bonus", "category": "bonus",
		"band": BAND_HOUSE, "node": _house, "offset": Vector3(0.0, 0.22, 0.0), "radius": 0.22,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_house),
	})
	_log("shell house at %s (trail end %s, nearest prop %.2f m)" % [_pp(hd), _pp(end_d), p.nearest_prop_distance(hd)])
	# 3. A HEART-SHAPED LILY PAD, floating near its pool's edge on the side toward the start
	_lily = MeshInstance3D.new()
	_lily.name = "HeartLily"
	_lily.mesh = Meshes.heart_lily()
	_lily.material_override = _prop
	_lily.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lily)
	var lc := _pool_dir(HEART_POOL)
	var shore := float(_pools[HEART_POOL]["shore_m"]) if HEART_POOL < _pools.size() else 1.5
	var lt := _toward(lc, safari.start_dir)
	var la := maxf(shore - LILY_IN_M, 0.2) / p.radius
	_lily_anchor = (lc * cos(la) + lt * sin(la)).normalized()
	if not p.is_underwater(_lily_anchor):
		_lily_anchor = lc
	_lily_t0 = _tangent_at(_lily_anchor)
	safari.add_subject({
		"id": "heart_lily", "name": "A Heart-shaped Lily Pad", "kind": "bonus", "category": "bonus",
		"band": BAND_LILY, "node": _lily, "offset": Vector3(0.0, 0.03, 0.0), "radius": 0.2,
		"awake": func() -> bool: return not _sleeping,
	})
	_log("heart lily in pool %d at %s (%.2f m in from its edge)" % [HEART_POOL, _pp(_lily_anchor), LILY_IN_M])


## The heart lily turns slowly on the water, drifting round a small circle about its spot.
func _tick_bonus(_delta: float) -> void:
	if _lily == null:
		return
	var p := safari.planet
	var a := TAU * _t / LILY_DRIFT_SEC
	var t1 := _lily_anchor.cross(_lily_t0).normalized()
	var off := (_lily_t0 * cos(a) + t1 * sin(a)) * (LILY_DRIFT_M / p.radius)
	var d := (_lily_anchor + off).normalized()
	var fwd := _lily_t0.rotated(_lily_anchor, a * 0.3 + 0.3 * sin(_t * 0.31))
	fwd = (fwd - d * fwd.dot(d)).normalized()
	_lily.global_transform = Transform3D(Basis.looking_at(fwd, d), p.global_position + d * (_water_r + 0.01 + 0.008 * sin(_t * 1.7)))


# ======================================================================================== THE DIRECTOR
## BEFORE A RARE EVENT the director is keener (Zorp's and Fen's measured fix): through the WARN seconds
## before the grazer (and the giant bloom on a rare day) something is brought after PRE_RARE_AFTER_SEC of
## nothing instead of AFTER_SEC, so a creature is about when the director goes quiet near the rare.
const PRE_RARE_AFTER_SEC := 5.0
const PRE_LAST_AFTER_SEC := 3.0
## Once it has a photo this safari, a puff is brought only as the FALLBACK, when the others had this much
## longer and could not come (Fen's WISP_FALLBACK_SEC: the one bringer that can always come otherwise
## takes most of the brings). Keyed on photos, so the density wanderer (none) is untouched.
const PUFF_FALLBACK_SEC := 3.0
var _after_sec := 12.0


func _tick_pacing() -> void:
	if pacing == null:
		return
	var until := -1.0
	if bool(_eligible.get("canopy_grazer", false)) and _t >= GRAZER_START - WARN and _t < GRAZER_START:
		until = GRAZER_START - _t
	if bool(_eligible.get("giant_bloom", false)) and _t >= GIANT_START - WARN and _t < GIANT_START:
		until = GIANT_START - _t
	pacing.AFTER_SEC = _after_sec if until < 0.0 else (PRE_RARE_AFTER_SEC if until > 4.0 else PRE_LAST_AFTER_SEC)


func _build_pacing() -> void:
	pacing = Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	_after_sec = pacing.AFTER_SEC
	# `ready` says only whether one is FREE to bring (spec 17.1 rule 7, 17.3 ruling 3: no share test here)
	pacing.add_bringer({"id": "glowtail", "bring": _bring_tail,
		"ready": func() -> bool:
			for z: Dictionary in _tails:
				if int(z["spot"]) < 0 and int(z["state"]) == Tail.GONE:
					return true
			return false})
	pacing.add_bringer({"id": "lily_hopper", "bring": _bring_hopper,
		"ready": func() -> bool:
			for f: Dictionary in _hoppers:
				if bool(f["scout"]) and int(f["state"]) == Hop.UNDER:
					return true
			return false})
	pacing.add_bringer({"id": "pool_peeper", "bring": _bring_peeper,
		"ready": func() -> bool:
			for f: Dictionary in _peepers:
				if bool(f["scout"]) and int(f["state"]) == Peep.UNDER:
					return true
			return false})
	pacing.add_bringer({"id": "spore_puff", "bring": _bring_puff,
		"ready": func() -> bool:
			if int(pacing.photos.get("spore_puff", 0)) > 0 and pacing.lonely < pacing.AFTER_SEC + PUFF_FALLBACK_SEC:
				return false
			for w: Dictionary in _puffs:
				if int(w["state"]) == Puf.AWAY and not bool(w["roamer"]) and not bool(w["watch"]):
					return true
			return false})
	pacing.places = _creature_places


## Where the other creatures are, or will come into view: the hopper pools, the glowtails' trunks, the
## creatures that are out, the snails at night, and every awake event.
func _creature_places() -> Array:
	var p := safari.planet
	var out: Array = []
	for pi: int in HOPPER_POOLS:
		if pi < _pools.size():
			out.append(_water_point(pi))
	for f: Dictionary in _hoppers:
		if bool(f["scout"]) and int(f["state"]) != Hop.UNDER:
			out.append(p.surface_point(f["dir"]))
	for pi: int in PEEPER_POOLS:
		if pi < _pools.size():
			out.append(_water_point(pi))
	for f: Dictionary in _peepers:
		if bool(f["scout"]) and int(f["state"]) != Peep.UNDER:
			out.append(_peep_pos(f))
	for z: Dictionary in _tails:
		if int(z["spot"]) >= 0 or int(z["state"]) != Tail.GONE:
			out.append(z["pos"])
	for w: Dictionary in _puffs:
		if int(w["state"]) != Puf.AWAY:
			out.append(p.surface_point(w["dir"]))
	if safari.is_night:
		for s: Dictionary in _snails:
			out.append(p.surface_point(s["dir"]))
	if _glim_at >= 0:
		out.append(p.surface_point(_glim_places[_glim_at][0]))
	if _any_running(RAIN_RUNS) and _rain_at >= 0:
		out.append(_rain_places[_rain_at]["base"])
	if _any_running(BURST_RUNS):
		out.append(p.surface_point(_bud_dir))
	if _grazer_shown:
		out.append(p.surface_point(_grazer_stand))
	if safari.event_running("giant_bloom"):
		out.append(p.surface_point(_giant_dir))
	return out


# ======================================================================================== SCHEDULE
## Every event run is its own PlanetSafari event (its own id, so event_running and the "woke" count work
## per run); the runs of one kind share one warning glow and one subject.
func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line, tier]
	var ev: Array = []
	for run: Dictionary in SWARM_RUNS:
		var d: Vector3 = _glim_places[int(run["at"])][0]
		ev.append(["glimmer_swarm", run["id"], "The Glimmer Swarm", run["start"], run["end"], d, "any", Color("#ffd68a"),
			"Tiny lights are gathering over a pool...", "common"])
	for run: Dictionary in RAIN_RUNS:
		var at := mini(int(run["at"]), _rain_places.size() - 1)
		var d: Vector3 = _rain_places[at]["dir"] if at >= 0 else safari.dir_from_start(90.0, 0.0)
		ev.append(["spore_rain", run["id"], "Spore Rain", run["start"], run["end"], d, "any", Color("#bff0dc"),
			"A parasol tree is starting to glow...", "uncommon"])
	for run: Dictionary in BURST_RUNS:
		ev.append(["bloom_burst", run["id"], "The Bloom Burst", run["start"], run["end"], _bud_dir, "any", Color("#f2c3dc"),
			"A big bud is swelling. It is about to burst.", "uncommon"])
	ev.append(["canopy_grazer", "canopy_grazer", "The Canopy Grazer", GRAZER_START, GRAZER_END, _grazer_stand, "any", Color("#aee8e0"),
		"Something big is walking through the trees...", "rare"])
	ev.append(["giant_bloom", "giant_bloom", "The Giant Bloom", GIANT_START, GIANT_END, _giant_dir, "only", Color("#c9f5e4"),
		"A giant flower is waking up by the back trail...", "rare_day"])
	for e: Array in ev:
		var kind: String = e[0]
		var id: String = e[1]
		var beacon: MeshInstance3D = _beacons[kind] if _beacons.has(kind) else _make_beacon(kind, e[7])
		var line: String = e[8]
		var dir: Vector3 = e[5]
		var ok := safari.add_event({
			"id": id, "name": e[2], "start": e[3], "end": e[4], "warn": WARN, "dir": dir,
			"when": "any", "rare": e[6], "overlap_ok": true, "tier": e[9],
			"on_warn": func(_e: Dictionary) -> void:
				beacon.set_meta("on", true)
				beacon.set_meta("dir", dir)
				_queue_line(line)
				_warn_sound(kind)
				_log("warn %s t=%.2f: line \"%s\", sound %s, beacon on toward %s, cue %s" % [id, _t, line,
					WARN_SOUNDS.get(kind, "?"), _pp(dir), WARN_CUES.get(kind, "?")]),
			"on_start": func(_e: Dictionary) -> void:
				_on_start(kind),
			"on_end": func(_e: Dictionary) -> void:
				beacon.set_meta("on", false),
		})
		_eligible[id] = ok
		if not beacon.has_meta("dir_set"):
			beacon.set_meta("dir", dir)
			beacon.set_meta("dir_set", true)


## What each warning plays and shows besides the line and the glow (logged at every warning).
const WARN_SOUNDS := {"glimmer_swarm": "doot_c_2 x2, high (then soft chimes near the swarm)", "spore_rain": "tree_shake, soft + doot_c_1",
	"bloom_burst": "doot_c_0 rising", "canopy_grazer": "footsteps, low and slow + voice_elder low", "giant_bloom": "shooting_star, low + friendship_up"}
const WARN_CUES := {"glimmer_swarm": "the swarm gathers and circles high over its pool, then comes down",
	"spore_rain": "the parasol's underside starts to glow and the first spores drift down",
	"bloom_burst": "the bud swells and pulses pink",
	"canopy_grazer": "the grazer walks in through the trees, its teal spots glowing",
	"giant_bloom": "the giant closed bud glows and swells"}


## The SOUND half of every warning: heard anywhere on the planet (a 2D sound), the moment it is warned.
func _warn_sound(kind: String) -> void:
	match kind:
		"glimmer_swarm":
			var a := _sound_once("doot_c_2", 2.0, -7.0)
			a.play()
			get_tree().create_timer(0.3).timeout.connect(func() -> void:
				if is_instance_valid(a):
					a.pitch_scale = 2.4
					a.play())
		"spore_rain":
			_sound_once("tree_shake", 1.5, -8.0).play()
			_sound_once("doot_c_1", 1.6, -9.0).play()
		"bloom_burst":
			_sound_once("doot_c_0", 1.3, -7.0).play()
		"canopy_grazer":
			_sound_once("footstep_grass_0", 0.45, -2.0).play()
			_sound_once("voice_elder_1", 0.6, -8.0).play()
		"giant_bloom":
			_sound_once("shooting_star", 0.55, -6.0).play()
			_sound_once("friendship_up", 0.7, -9.0).play()


func _on_start(kind: String) -> void:
	match kind:
		"bloom_burst":
			_sound_once("pickup", 0.8, -6.0).play()
		"spore_rain":
			_sound_once("doot_c_1", 1.2, -10.0).play()
		"giant_bloom":
			_sound_once("tree_shake", 0.7, -8.0).play()


## The run of `runs` whose window holds `tt` (from its warning when `with_warn`) and that is eligible
## today, or {}. The runs of one kind never overlap, warnings included.
func _run_at(runs: Array, tt: float, with_warn: bool) -> Dictionary:
	for run: Dictionary in runs:
		var s0 := float(run["start"]) - (WARN if with_warn else 0.0)
		if tt >= s0 and tt < float(run["end"]) and bool(_eligible.get(str(run["id"]), false)):
			return run
	return {}


func _any_running(runs: Array) -> bool:
	for run: Dictionary in runs:
		if safari.event_running(str(run["id"])):
			return true
	return false


# ---------------------------------------------------------------------------------------- beacons
## A warning glow on YOUR horizon toward its event (Bolt's and Fen's `_make_beacon`).
func _make_beacon(id: String, colour: Color) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	b.name = "Beacon_" + id
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 1.5)
	b.mesh = q
	var m := MaterialLib.glow_sprite(colour, 1.6, {"softness": 0.0, "core": 0.12}).duplicate() as ShaderMaterial
	b.material_override = m
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.set_meta("on", false)
	b.set_meta("level", 0.0)
	b.visible = false
	add_child(b)
	_beacons[id] = b
	return b


func _tick_beacons(delta: float) -> void:
	var pd := _player_dir()
	for id: String in _beacons:
		var b: MeshInstance3D = _beacons[id]
		var target: Vector3 = b.get_meta("dir", Vector3.UP)
		var ang := rad_to_deg(pd.angle_to(target))
		var want := smoothstep(BEACON_NEAR_DEG, BEACON_FULL_DEG, ang) if bool(b.get_meta("on", false)) and not _sleeping else 0.0
		# hidden while the camera is up: it is for choosing where to WALK, not for the photographs
		if safari.camera_up:
			want = 0.0
		var lv := move_toward(float(b.get_meta("level", 0.0)), want, delta * (4.0 if safari.camera_up else 1.5))
		b.set_meta("level", lv)
		b.visible = lv > 0.01
		if not b.visible:
			continue
		var tdir := target - pd * target.dot(pd)
		if ang > 165.0 or tdir.length() < 0.05:
			var cam := safari.rig.get_view_camera() if safari.rig != null else null
			var cf := -cam.global_transform.basis.z if cam != null else safari.start_fwd
			tdir = cf - pd * cf.dot(pd)
		if tdir.length() < 0.001:
			tdir = _tangent_at(pd)
		var a := deg_to_rad(minf(BEACON_AHEAD_DEG, ang))
		var along := (pd * cos(a) + tdir.normalized() * sin(a)).normalized()
		b.global_position = safari.ground_point(along, 1.0)
		(b.material_override as ShaderMaterial).set_shader_parameter("fade", lv * (0.72 + 0.28 * sin(_t * 3.4)))


# ======================================================================================== TICK
## One banner at a time: a line waits for the intro hint and for the line before it (Bolt's rule).
func _queue_line(text: String) -> void:
	var due := maxf(_t, INTRO_HINT_SEC)
	if not _lines.is_empty():
		due = maxf(due, float(_lines[-1][0]) + LINE_SEC)
	elif _t < _line_free_at:
		due = maxf(due, _line_free_at)
	_lines.append([due, text])


func tick(t: float, delta: float) -> void:
	_t = t
	var still_up := safari.camera_up and is_instance_valid(safari.player) and safari.player.get_tangent_velocity().length() < 0.15
	_still = (_still + delta) if still_up else 0.0
	_tick_pacing()
	if not _lines.is_empty() and not _building and _t >= float(_lines[0][0]) and not _sleeping:
		safari.announce(str(_lines[0][1]), 3.5)
		_line_free_at = _t + LINE_SEC
		_lines.pop_front()
	_tick_hoppers(delta)
	_tick_peepers(delta)
	_tick_tails(delta)
	_tick_puffs(delta)
	_tick_snails(delta)
	_tick_swarm(delta)
	_tick_rain(delta)
	_tick_bud(delta)
	_tick_grazer(delta)
	_tick_giant(delta)
	_tick_bonus(delta)
	_tick_beacons(delta)


## The three minutes are up: hoppers slip under, glowtails scurry up their trunks, puffs drift up and
## away, snails tuck in, the swarm climbs off, the bud closes; everything else goes in PlanetSafari's
## puff; the sounds stop.
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_grazer_root, _giant_root]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for pr: CPUParticles3D in [_rain_steady, _rain_heavy, _pollen, _giant_motes, _spore_pop]:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false)
	return true


# ======================================================================================== HELPERS
## A soft glow quad on the shipped star shader, its own material copy so its `fade` is its own.
func _glow_quad(label: String, colour: Color, size: Vector2) -> MeshInstance3D:
	var g := MeshInstance3D.new()
	g.name = label
	var q := QuadMesh.new()
	q.size = size
	g.mesh = q
	g.material_override = MaterialLib.glow_sprite(colour, 1.4, {"softness": 0.0, "core": 0.18}).duplicate() as ShaderMaterial
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(g.material_override as ShaderMaterial).set_shader_parameter("fade", 0.0)
	g.visible = false
	return g


## The world unit vector a node's face points along: every mesh here faces -Z.
func _front_of(n: Node3D) -> Vector3:
	if n == null or not is_instance_valid(n):
		return Vector3.ZERO
	return (-n.global_basis.z).normalized()


## Of `items` that `ok` accepts, the one nearest the middle of the view whose middle the lens can see
## (Bolt's `_pick_focus`); -1 when none is awake.
func _pick_focus(items: Array, ok: Callable, pos_of: Callable, lift: float) -> int:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var cands: Array = []
	for i in items.size():
		if not bool(ok.call(items[i])):
			continue
		var q: Vector3 = pos_of.call(items[i])
		var score := 1000.0
		if cam != null:
			var to := q - cam.global_position
			var dist := to.length()
			var ang := rad_to_deg((-cam.global_transform.basis.z).angle_to(to / maxf(dist, 0.001)))
			score = ang + dist * 0.05 if ang < 35.0 else 100.0 + dist
		cands.append([score, i, q])
	if cands.is_empty():
		return -1
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if cam == null:
		return int(cands[0][1])
	for k in mini(cands.size(), 4):
		if float(cands[k][0]) >= 100.0:
			break
		var q: Vector3 = cands[k][2]
		var target := q + safari.planet.up_at(q) * lift
		if pacing == null or pacing.sight_clear(cam.global_position, target):
			return int(cands[k][1])
	return int(cands[0][1])


## The heading of the member of group `pick` nearest the lens (the swarm's front).
func _nearest_heading(items: Array, pick: int, key: String) -> Vector3:
	if pick < 0 or items.is_empty():
		return Vector3.ZERO
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var lens := cam.global_position if cam != null else safari.player.global_position
	var best_d := INF
	var head := Vector3.ZERO
	for m: Dictionary in items:
		if key != "" and int(m[key]) != pick:
			continue
		var dd := (m["pos"] as Vector3).distance_to(lens)
		if dd < best_d:
			best_d = dd
			head = m["head"]
	return head.normalized()


## True when world point `q` projects inside the frame grown by `grow`.
func _point_in_frame(q: Vector3, grow: float) -> bool:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if cam == null or cam.is_position_behind(q):
		return false
	var frame := get_viewport().get_visible_rect().size
	var sp := cam.unproject_position(q)
	var half := frame * 0.5 * grow
	return absf(sp.x - frame.x * 0.5) <= half.x and absf(sp.y - frame.y * 0.5) <= half.y


func _player_dir() -> Vector3:
	return safari.planet.dir_of(safari.player.global_position) if is_instance_valid(safari.player) else safari.start_dir


## A unit tangent at `d` (the start heading carried over, or any).
func _tangent_at(d: Vector3) -> Vector3:
	var t := safari.start_fwd - d * safari.start_fwd.dot(d)
	if t.length() < 0.01:
		t = Vector3.RIGHT - d * d.x
	return t.normalized()


## The point `rho_deg` round from `centre` along a bearing `psi_deg` from the tangent `ref`.
func _polar(centre: Vector3, ref: Vector3, rho_deg: float, psi_deg: float) -> Vector3:
	var r := (ref - centre * ref.dot(centre)).normalized()
	var h := r.rotated(centre, -deg_to_rad(psi_deg)).normalized()
	var a := deg_to_rad(rho_deg)
	return (centre * cos(a) + h * sin(a)).normalized()


## Upright on the ground at `d` but tilted to the local ground slope.
func _xf_ground(d: Vector3, fwd: Vector3) -> Transform3D:
	var xf := _xf(d, fwd)
	var n := safari.planet.ground_normal(d.normalized())
	var f := -xf.basis.z
	f = (f - n * f.dot(n)).normalized()
	xf.basis = Basis.looking_at(f, n)
	return xf


## The tangent at `d` pointing toward `target` (a direction), or any tangent.
func _toward(d: Vector3, target: Vector3) -> Vector3:
	var t := target - d * target.dot(d)
	return t.normalized() if t.length() > 0.001 else _tangent_at(d)


## Upright on the ground at `d`, facing `fwd` (projected on the ground).
func _xf(d: Vector3, fwd: Vector3) -> Transform3D:
	return safari.planet.surface_transform(d.normalized(), fwd)


## A 2D sound (heard anywhere on the planet) owned by this node.
func _sound(sfx: String, pitch: float, db: float) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.name = "Snd_" + sfx
	var st: Variant = load(SFX_DIR + sfx + ".wav") if ResourceLoader.exists(SFX_DIR + sfx + ".wav") else null
	a.stream = st as AudioStream
	a.pitch_scale = pitch
	a.volume_db = db
	a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(a)
	_sounds.append(a)
	return a


## EVERY ONE-SHOT PLAYER IS MADE IN `build` (behind the fade), not on its first use (Zorp's round-1
## critic measured +21-28 ms at the first warning when two WAVs were load()ed then). The names every
## _sound_once call uses:
const ONCE_SFX := ["doot_c_2", "doot_c_1", "doot_c_0", "tree_shake", "footstep_grass_0", "voice_elder_1", "shooting_star",
	"friendship_up", "pickup", "doot_a_0"]


func _warm_sounds() -> void:
	for sfx: String in ONCE_SFX:
		_sound_once(sfx, 1.0, -80.0)
	# the positional ones AudioManager plays: load them now so the first is not a disk read mid-safari
	for sfx: String in ["doot_a_1", "collect_stardust", "footstep_grass_0", "footstep_grass_1", "splash", "voice_elder_2"]:
		if ResourceLoader.exists(SFX_DIR + sfx + ".wav"):
			load(SFX_DIR + sfx + ".wav")


## A one-shot 2D sound: one player per effect name, re-used.
func _sound_once(sfx: String, pitch: float, db: float) -> AudioStreamPlayer:
	var nm := "Once_" + sfx
	var a := get_node_or_null(nm) as AudioStreamPlayer
	if a == null:
		a = _sound(sfx, pitch, db)
		a.name = nm
	a.pitch_scale = pitch
	a.volume_db = db
	return a


func _pp(d: Vector3) -> String:
	var around := rad_to_deg(safari.start_dir.angle_to(d))
	var t := d - safari.start_dir * d.dot(safari.start_dir)
	var bearing := 0.0
	if t.length() > 1e-5:
		bearing = -rad_to_deg(safari.start_fwd.signed_angle_to(t.normalized(), safari.start_dir))
	return "(%.1f, %.1f)" % [around, bearing]


## For the test logs: where each photographed creature came from. And a photographed ROAMER puff goes to
## rest (ROAMER_REST_SEC).
func _on_photo(ph: Dictionary) -> void:
	var id := str(ph.get("subject_key", "")).get_slice(":", 1)
	var src := ""
	match id:
		"spore_puff":
			if _puff_pick >= 0:
				var w: Dictionary = _puffs[_puff_pick]
				src = "roamer" if bool(w["roamer"]) else ("watcher" if bool(w["watch"]) else "brought")
				if bool(w["roamer"]):
					w["rest_until"] = _t + ROAMER_REST_SEC
		"glowtail":
			if _tail_pick >= 0:
				var z: Dictionary = _tails[_tail_pick]
				src = ("trunk" if int(z["spot"]) >= 0 else ("scout-ground" if bool(z["ground"]) else "scout-palm"))
		"lily_hopper":
			if _hop_pick >= 0:
				src = "scout" if bool(_hoppers[_hop_pick]["scout"]) else "rim"
		"pool_peeper":
			if _peep_pick >= 0:
				src = "scout" if bool(_peepers[_peep_pick]["scout"]) else "pool"
	_log("photo t=%.1f %s from %s grade %s" % [_t, id, src, str(ph.get("grade", ""))])


func _log(msg: String) -> void:
	print("[JungleSafari] " + msg)


## Everything a test needs to find the subjects and places (the probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"pools": _pools.map(func(pl: Dictionary) -> Vector3: return pl["dir"]),
		"grazer_stand": _grazer_stand, "grazer_from": _grazer_from, "giant": _giant_dir, "bud": _bud_dir,
		"rain": _rain_places.map(func(r: Dictionary) -> Vector3: return r["dir"]),
		"swarm": _glim_places.map(func(s: Array) -> Vector3: return s[0]),
		"hopper_dirs": _hoppers.map(func(f: Dictionary) -> Vector3: return f["dir"]),
		"tail_pos": _tails.map(func(z: Dictionary) -> Vector3: return z["pos"]),
		"puff_dirs": _puffs.map(func(w: Dictionary) -> Vector3: return w["dir"]),
		"hat": _hat.global_position if _hat != null else Vector3.ZERO,
		"house": _house.global_position if _house != null else Vector3.ZERO,
		"lily": _lily.global_position if _lily != null else Vector3.ZERO,
		"eligible": _eligible.duplicate(),
	}
