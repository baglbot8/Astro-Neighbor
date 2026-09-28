extends SafariWorld
## FEN'S WORLD WAKES UP - THE MISTY RUINS (docs/PLANET_SAFARI_SPEC.md 12.2, built to Bolt's round-2
## rules: the tiers of 11.2, the density BAND of 11.2b, Facing and Size of 11.1, the grade scale and
## the pacing director of 13; builder FEN, 2026-09-25). Loaded by PlanetSafari when a safari starts on
## Fen's world and freed when it ends: nothing here exists outside a safari (the user's rule 5), and
## nothing on the planet is changed - Fen himself is the one thing borrowed (the pacing director may
## bring him over to see what you are photographing) and he is put back exactly where he stood when
## this node leaves the tree. The arch, the stones and the pools are never touched: the vine, the
## light in the arch and every glow are this node's own meshes, laid over them.
##
## Built only from Fen's existing look (planet_props.gd `_fen`, fen.tres): a terracotta salt pan under
## an 11-degree sun, the seven-stone colonnade, the arch at the end of the avenue, fourteen crater
## pools ringed with spires, suspended ash motes, no moon, and Fen's own glow moths (his project).
##
##   creatures        always about, in many places  POOL-FROGS on the rims of four pools (they plop
##                                                   into the water when rushed), RUIN-LIZARDS basking
##                                                   at the foot of the colonnade and of pool one's spires
##                                                   (they dart off when rushed), MIST-WISPS drifting over
##                                                   the whole pan (the roamer); GLOW-MOTHS over two pools
##                                                   at night. The pacing director (SafariWorld.Pacing)
##                                                   brings a lizard out of a crack in the crust, a frog
##                                                   up out of a nearby pool, Fen, or a wisp, when it has
##                                                   gone quiet
##   common event     ~30 s, repeats                 TOWER SWIFTS circle the colonnade, then two pools'
##                                                   spires (the swifts Fen asks for from the sky)
##   uncommon events  ~12 s, repeats                 POOL RIPPLE at three pools (the water glows, little
##                                                   fish leap); FEN'S VINE BLOOMS on the arch, twice
##   rare             once                           THE ARCH LIGHT: the low sun lines up through the arch
##                                                   and lays a golden beam across the ruins
##   rare day         1 day in 4                     THE STONE HERON lands in the biggest pool
## RARITY follows the tier (SafariWorld.TIER_RARITY): creatures and Fen 1, glow-moths and the swifts 2,
## the ripple and the bloom 3, the arch light and the heron 4.
##   sights           always there (spec 15.5)       THE OLD ARCH and THE COLONNADE: Fen's own props, named as
##                                                   subjects (no mesh of their own). Rarity 1, pay as usual.
##   bonus            hidden, collector's only       A FISH CARVED IN STONE on the back of a column, THE FROG
##                                                   IN A FLOWER CROWN on pool THIRTEEN's rim, A MESSAGE IN A
##                                                   BOTTLE bobbing in pool SEVEN. Small, still, pay nothing.
## Sights and bonus subjects do not count toward the density band or the director (SafariWorld CATEGORY).
##
## ------------------------------------------------------------------------------------ THE PLACES
## As (degrees round from the start beside the pad, bearing from the start heading, + = right).
## Fen is 13 m round: 1 degree = 0.227 m; the safari walk 1.5 m/s = 6.6 deg/s, a quarter round 14 s,
## the far side 27 s. The props (Fen's seed-61 layout, logged at build): the colonnade's seven stones
## from (29,98) to (66,140); the arch (35,131), 3.4 m tall, the avenue running through it to the pad
## (14,-180); Fen's home (74,51). The fourteen crater pools, NUMBERED AS FEN NUMBERS THEM (crater index
## + 1: "I number the pools. Fourteen."), each logged at build with its rim and its water's edge:
##   ONE      (89, 88)    glow-moths (night)          EIGHT     (157,-157)  swifts (3) round its spires
##   TWO      (65,-159)   ruin-lizards at its spires  NINE      (78, -43)   pool-frogs
##   THREE    (140,-82)   pool ripple (2)             TEN       (30, -12)   the stone heron (the biggest)
##   FOUR     (95, 27)    pool ripple (1)             ELEVEN    (124,-131)  pool-frogs
##   FIVE     (92,-110)   pool ripple (3)             TWELVE    (143,101)   pool-frogs
##   SIX      (100,172)   swifts (2) round its spires THIRTEEN  (73, 163)   -
##   SEVEN    (116,-31)   glow-moths (night)          FOURTEEN  (108, 2)    pool-frogs
## The colonnade's near end (StandingStone5, (29,98)): ruin-lizards. Its far end (StandingStone0/2/4):
## the swifts (1). The frogs sit on each pool's rim crest; the director's scout frogs come up out of any
## pool but TEN within FROG_BRING_POOL_M of where you look.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned WARN (8 s) ahead with a SIGHT and a SOUND that duplicate each other
## (spec 4): a line on screen naming the place, a sound heard anywhere on the planet, a warm glow on
## YOUR horizon toward the event (gone once you are within BEACON_NEAR_DEG), and the event's own cue
## (the swifts gather high over the place, the pool starts to glow and bubble, the buds swell and glint,
## the arch's opening starts to glow and the motes gather, the heron circles high over its pool).
## Nothing depends on reading them.
##   0:06-0:36  TOWER SWIFTS (1) round the colonnade. THE FLOCK TURNS at +10..+13 and +22..+25 s.
##   0:22-0:34  POOL RIPPLE (1) in pool FOUR. EVERY FISH LEAPS AT ONCE at +6..+8 s.
##   0:40-0:52  FEN'S VINE BLOOMS (1) on the arch. FULL BLOOM +4..+9 s.
##   0:52-1:22  TOWER SWIFTS (2) round pool SIX's spires.
##   1:22-1:34  THE ARCH LIGHT (rare, once). GOLDEN 1:27-1:32.
##   1:24-1:36  POOL RIPPLE (2) in pool THREE, 159 degrees from the arch: the rare's forced choice.
##   1:44-2:14  TOWER SWIFTS (3) round pool EIGHT's spires. Its turns at 1:54-1:57 and 2:06-2:09.
##   1:52-2:06  THE STONE HERON (rare day) in pool TEN. LANDING 1:52-1:56, WINGS SPREAD 2:01-2:04;
##              163 degrees from swifts (3).
##   2:20-2:32  FEN'S VINE BLOOMS (2).
##   2:30-2:42  POOL RIPPLE (3) in pool FIVE.
##   all 3 min  POOL-FROGS, RUIN-LIZARDS, MIST-WISPS, FEN; GLOW-MOTHS at night.
## THE OVERLAPS FORCE A CHOICE (spec 6.2), measured centre to centre at build (logged "overlap"):
##   the arch light's golden minute / ripple (2): 159 degrees, 36 m, 24 s apart at the safari walk.
##   the heron's wings / swifts (3)'s turn: 163 degrees, 37 m, 25 s apart.
## Each best window is shorter than the walk between them, so one round cannot catch both at their best.
## THE RARES ARE SHORT (12 and 14 s) on purpose: the director keeps quiet while one is up (spec 13.2), so a
## wanderer far from it has only the creatures already about; at 20 s the arch light made the one
## 24 s gap of the first 8 wanderer runs (cfen_out/r2 seed 5), and at 14 s three of 30 runs still had one
## of 20.4-21.8 s starting 67-76 s in (fb_w30). Before a rare the director is keener
## (PRE_RARE_AFTER_SEC), and one WATCHER wisp drifts out near you, drawn toward the rare's light.
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): one MultiMesh per part - the frogs 2 draw calls, the lizards 1,
## the wisps 2, the swifts 1, the fish 1, the ripple rings 1, the moths 2, the flowers 2. The heron is
## three meshes, the vine one, the arch light two plus its motes. Every solid mesh is PlanetMeshKit
## vertex colour on the matte prop material Fen's own props draw with; the see-through sheets are the
## shipped puff material; the glows are the shipped star shader; particles are CPUParticles3D on the
## shipped sparkle material. No lights. Everything is built in `build` (warmed behind the fade) and only
## moved, shown or hidden afterwards: each repeated event re-uses ONE set of emitters.
##
## ------------------------------------------------------------------------------------ FACING AND SIZE
## FACING (spec 11.1): every creature, Fen, the heron and the arch light carry "front". Every mesh here
## faces -Z, so a front is -basis.z of the node the subject is scored on; the swifts' and the moths' is
## the heading of the one nearest the lens; the arch light's is the way its beam runs (away from the
## sun): stand in the beam and look back through the arch for a 10. The frogs, lizards and wisps are
## CURIOUS: stand still with the camera up near one and it turns to you.
## SIZE BANDS (spec 11.1): set from each subject's USUAL DISTANCE so that at the 45 degree lens there,
## size scores 6 or less, and walking in or zooming reaches it (Zorp's formula): size_frac =
## tan(asin(r / d)) / tan(22.5 deg); band.x = that / 0.58; band.y = 1.65 x band.x, capped at 1.0.
##   subject          radius  usual d  band
##   pool-frog        0.20     3.0 m   0.28-0.46
##   ruin-lizard      0.24     3.0 m   0.33-0.55
##   mist-wisp        0.20     3.0 m   0.28-0.46
##   glow-moths       0.80     8.0 m   0.42-0.69
##   tower swifts     1.60     9.0 m   0.75-1.00
##   Fen              0.70     4.27 m  0.71-1.00   (MEASURED, R2: 5.0 m was picked. 13 of 15 of the
##                                                  careless player's 45 deg Fen photos were at 3.8-4.3 m,
##                                                  most at 4.27 m, where the director puts him; there
##                                                  size_frac is 0.402 and 0.402 / 0.58 = 0.69, which
##                                                  scored 6.2 there; spec 14.4/16 raise it to 0.71.)
##   pool ripple      1.20     7.0 m   0.73-1.00
##   vine bloom       1.60    10.0 m   0.67-1.00
##   the arch light   1.80    11.0 m   0.69-1.00
##   the stone heron  0.70     6.0 m   0.49-0.81

## THE MANIFEST (spec 12.5; safari_world.gd THE MANIFEST). Fen's own voice (npc_data.gd: "I watch the
## pools. That is the work.", "Nine years of notes.", "Walk slow. The crust remembers every foot.";
## src/projects/data/fen.gd: "I only watch. That is the work.", "I logged it. Twice."): a terse elder
## who keeps a logbook, counts and numbers things, short flat sentences, never an exclamation.
const MANIFEST := {
	"host": "fen",
	"offer": "The ruins wake for three minutes a day. I log it.",
	"ask": "Walk them with a camera? A photo safari.",
	"yes": "Start at the pad. Walk slow. I will note the time.",
	"no": "Another time. The ruins keep. So do I.",
	"asleep": "The ruins sleep now. So should the logbook. Tomorrow.",
	"roster": [
		{"id": "pool_frog", "name": "Pool-frog", "tier": "creature", "category": "creature"},
		{"id": "ruin_lizard", "name": "Ruin-lizard", "tier": "creature", "category": "creature"},
		{"id": "mist_wisp", "name": "Mist-wisp", "tier": "creature", "category": "creature"},
		{"id": "fen", "name": "Fen", "tier": "neighbour", "category": "neighbour"},
		{"id": "tower_swifts", "name": "Tower Swifts", "tier": "common", "category": "event"},
		{"id": "pool_ripple", "name": "Pool Ripple", "tier": "uncommon", "category": "event"},
		{"id": "vine_bloom", "name": "Fen's Vine in Bloom", "tier": "uncommon", "category": "event"},
		{"id": "glow_moth", "name": "Glow-moths", "tier": "night", "category": "creature"},
		{"id": "arch_light", "name": "The Arch Light", "tier": "rare", "category": "event"},
		{"id": "stone_heron", "name": "The Stone Heron", "tier": "rare_day", "category": "event"},
		# spec 15.5: two SIGHTS (always there, low rarity, pay as usual) and three BONUS pages (hidden,
		# small, collector's only: they pay nothing). Neither counts toward the density band or the director.
		{"id": "old_arch", "name": "The Old Arch", "tier": "sight", "category": "sight"},
		{"id": "colonnade", "name": "The Colonnade", "tier": "sight", "category": "sight"},
		{"id": "carved_fish", "name": "A Fish Carved in Stone", "tier": "bonus", "category": "bonus"},
		{"id": "frog_statue", "name": "The Frog in a Flower Crown", "tier": "bonus", "category": "bonus"},
		{"id": "bottle_note", "name": "A Message in a Bottle", "tier": "bonus", "category": "bonus"},
	],
	# The review's line about each photo, in Fen's voice. `%s` is the subject's name, always at the
	# start of a sentence, so "The Arch Light" and "Glow-moths" read right.
	"review": {
		"no_subject": [
			"The pan. Empty. I have forty pages of that.",
			"Nothing in it. Honest, at least.",
		],
		"Smudge": [
			"%s. Blurred. I will log it anyway.",
			"%s, I think. Hold still next time.",
		],
		"Fair": [
			"%s. Clear enough. Logged.",
			"%s. A fair entry. The book accepts it.",
		],
		"Fine": [
			"%s. Sharp. I logged it twice.",
			"%s. Good work. That goes on a clean page.",
		],
		"Gallery": [
			"%s. Nine years, and I never saw it like that.",
			"%s. I will copy this into the front of the book.",
		],
		"moment": " And the timing. Noted.",
	},
}

const Meshes := preload("res://src/planet_safari/worlds/fen_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")
const SFX_DIR := "res://assets/audio/sfx/"

## Fen names his pools by number (npc_data.gd: "I number the pools. Fourteen."), crater index + 1.
const POOL_WORDS := ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "ELEVEN",
	"TWELVE", "THIRTEEN", "FOURTEEN"]

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
## "at" = the swift place (0 the colonnade, 1 and 2 the pools in SWIFT_POOLS). THE FLOCK TURNS (the
## moment) at SWIFT_TURNS seconds into a run, each SWIFT_TURN_SEC long.
const SWIFT_RUNS := [
	{"id": "tower_swifts", "start": 6.0, "end": 36.0, "at": 0},
	{"id": "tower_swifts_2", "start": 52.0, "end": 82.0, "at": 1},
	{"id": "tower_swifts_3", "start": 104.0, "end": 134.0, "at": 2},
]
const SWIFT_TURNS := [10.0, 22.0]
const SWIFT_TURN_SEC := 3.0
## "at" = the pool (RIPPLE_POOLS). ALL THE FISH LEAP at RIPPLE_ALL_AT..+RIPPLE_ALL_SEC into a run.
const RIPPLE_RUNS := [
	{"id": "pool_ripple", "start": 22.0, "end": 34.0, "at": 0},
	{"id": "pool_ripple_2", "start": 84.0, "end": 96.0, "at": 1},
	{"id": "pool_ripple_3", "start": 150.0, "end": 162.0, "at": 2},
]
const RIPPLE_ALL_AT := 6.0
const RIPPLE_ALL_SEC := 2.0
const BLOOM_RUNS := [
	{"id": "vine_bloom", "start": 40.0, "end": 52.0, "at": 0},
	{"id": "vine_bloom_2", "start": 140.0, "end": 152.0, "at": 0},
]
const BLOOM_OPEN_SEC := 3.0
const BLOOM_FULL := Vector2(4.0, 9.0)
const ARCH_START := 82.0
const ARCH_END := 94.0
const ARCH_GOLD := Vector2(87.0, 92.0)
const HERON_START := 112.0
const HERON_END := 126.0
const HERON_LAND := Vector2(112.0, 116.0)
const HERON_STRETCH := Vector2(121.0, 124.0)

# ------------------------------------------------------------------------------ the places
## Crater indices (Planet.crater_dirs order, Fen's seed 61): see the header's table.
const FROG_POOLS := [8, 11, 10, 13]
const RIPPLE_POOLS := [3, 2, 4]
const MOTH_POOLS := [0, 6]
const HERON_POOL := 9
const SWIFT_POOLS := [5, 7]
const LIZARD_POOL := 1
## The colonnade's stones the lizards bask at, and the ones the swifts circle.
const LIZARD_STONES := ["StandingStone5", "StandingStone3"]
const SWIFT_STONES := ["StandingStone0", "StandingStone2", "StandingStone4"]
const ARCH_NAME := "Arch0"

## A warning glow sits this far round from you toward its event (just inside your horizon: from an eye
## 1.09 m up on a 13 m world the ground's horizon is 5.3 m, 23 degrees), and fades out between
## BEACON_FULL_DEG and BEACON_NEAR_DEG (Bolt's 9.2 m / 12.8 m, in degrees of this bigger world).
const BEACON_AHEAD_DEG := 22.0
const BEACON_NEAR_DEG := 40.0
const BEACON_FULL_DEG := 56.0

# ------------------------------------------------------------------------------ SIZE BANDS (header)
const BAND_FROG := Vector2(0.28, 0.46)
const BAND_LIZARD := Vector2(0.33, 0.55)
const BAND_WISP := Vector2(0.28, 0.46)
const BAND_MOTHS := Vector2(0.42, 0.69)
const BAND_SWIFTS := Vector2(0.75, 1.00)
const BAND_FEN := Vector2(0.71, 1.00)
const BAND_RIPPLE := Vector2(0.73, 1.00)
const BAND_BLOOM := Vector2(0.67, 1.00)
const BAND_ARCH := Vector2(0.69, 1.00)
const BAND_HERON := Vector2(0.49, 0.81)

# ------------------------------------------------------------------------------ pool-frogs
const FROGS_PER_POOL := 3
const FROG_SCOUTS := 3
## The frogs sit this far out from the water's edge, on the dry lip.
## The frogs sit ON the crest of a pool's rim (Planet.crater_angle: the lip), not down on the inner
## bank by the water: from the pan outside, a frog on the bank is half hidden behind the lip (fb_c6: the
## careful player gave up on 11 of 13 frogs, "not fully in view", at 5-8 m).
const FROG_RIM_IN := 0.05
const FROG_HOP_RAD := Vector2(0.25, 0.55)
const FROG_HOP_H := 0.22
const FROG_AIR_SEC := 0.4
const FROG_SIT_SEC := Vector2(1.5, 4.5)
const FROG_CROUCH_SEC := 0.14
## Walk at one faster than RUSH_SPEED inside RUSH_M and it plops into the pool.
const FROG_RUSH_M := 2.8
const FROG_RUSH_SPEED := 0.6
const FROG_UNDER_SEC := Vector2(3.0, 5.0)
## Stand still with the camera up inside CROAK_M for STILL_SEC and the nearest croaks at you.
const FROG_CROAK_M := 5.5
const FROG_CROAK_SEC := 3.2
const FROG_CROAK_REST := 6.0
## The director brings a frog only out of a pool whose water is this close to the spot where you look.
const FROG_BRING_POOL_M := 9.0
enum Frog { SIT, CROUCH, AIR, PLOP, UNDER, CROAK }

## The creatures' "hello": the still camera must be held this long (Zorp's measured 2.5 s: at 0.8 the
## careless test player, who raises the camera and waits a second, caught one in about half its photos).
const STILL_SEC := 2.5
## ...and inside CURIOUS_M a resting creature turns to face a still camera: only once it has been held
## still CURIOUS_AFTER s, and slowly (CURIOUS_RATE: a time constant of 1.4 s), so FACING is a reward for
## waiting (spec 11.1). At once and fast (1.8/s from the first frame) the careless test player, which
## waits one second, averaged Facing 9.1-9.9 and graded Fine far too often (fb_c7: mean grade 1.45).
const CURIOUS_M := 6.5
const CURIOUS_AFTER := 1.2
const CURIOUS_RATE := 0.7

# ------------------------------------------------------------------------------ ruin-lizards
const LIZARDS_PER_SPOT := 2
## Scouts: lizards in cracks in the crust that the pacing director brings out where it has gone quiet.
const LIZARD_SCOUTS := 3
const LIZARD_RUSH_M := 2.6
const LIZARD_RUSH_SPEED := 0.6
const LIZARD_HIDE_SEC := Vector2(3.5, 6.0)
const LIZARD_DART_SEC := 0.45
const LIZARD_DART_M := 0.9
## Push-ups (its display, the moment): every PUSH_EVERY s for PUSH_SEC.
const LIZARD_PUSH_EVERY := Vector2(6.0, 10.0)
const LIZARD_PUSH_SEC := 1.4
const SCOUT_OUT_MIN_SEC := 12.0
const LIZARD_RISE_MAX := 0.45
const SCOUT_DOWN_M := 5.5
const SCOUT_POP_SEC := 0.35
enum Liz { BASK, PUSH, DART, HIDDEN, GONE, POP }

# ------------------------------------------------------------------------------ mist-wisps
## WISP_ROAMERS drift over the pan all safari; WISP_WATCHERS drift out (out of your view) while a rare
## event is warned or up, drawn by its light, and away after it; the rest wait for the director.
const WISP_N := 5
const WISP_ROAMERS := 1
const WISP_WATCHERS := 1
const WISP_FROM := [Vector2(120.0, 0.0)]
const WISP_SPEED := 0.3
const WISP_ALT := 1.0
const WISP_OUT_MIN_SEC := 12.0
const WISP_LEAVE_M := 6.5
const WISP_COME_SEC := 0.8
const WISP_LEAVE_SEC := 1.8
const WISP_HELLO_M := 4.5
const WISP_HELLO_SEC := 3.2
const WISP_HELLO_REST := 6.0
const WISP_KEEP_M := 1.6
## A ROAMER that has had its picture taken drifts up into the dusk once it is out of the frame, and comes
## back ROAMER_REST_SEC later somewhere near you, out of view (spec 16: the mist-wisp at 30% or less of a
## careful player's photos; the roamer was a quarter of its wisp photos, always there to be taken again).
## Only a photo sends it off, so the density wanderer, which takes none, meets the same roamer as before.
const ROAMER_REST_SEC := 45.0
enum Wis { DRIFT, AWAY, COME, LEAVE, HELLO }

# ------------------------------------------------------------------------------ glow-moths (night)
const MOTHS_PER_SWARM := 6
## Every MOTH_SETTLE_EVERY s the swarm drifts down and touches the water for MOTH_SETTLE_SEC (the moment).
const MOTH_SETTLE_EVERY := 14.0
const MOTH_SETTLE_SEC := 2.5
## The swarm circles this high over its pool's water. The water lies ~0.35 m under the pan inside a raised
## rim, so at 0.9 m the whole swarm was hidden from 5-8 m off (fb_shots night: every sight ray blocked).
const MOTH_ALT := 1.5
## ...and when it "touches down" it dips to this high over the water (still over the rim).
const MOTH_DIP := 0.5
## A swarm rests in its pool after you have seen it (the rest rule above _tick_moths): at night without
## it the wanderer met something new every 5.0 s in one run of ten (fb_w30 seed 12, under the 8 s floor).
const MOTH_LEAVE_SEC := 2.0
const MOTH_REST_SEC := 25.0

# ------------------------------------------------------------------------------ swifts
const SWIFT_N := 7
const SWIFT_RADIUS := 2.0
const SWIFT_SPEED := 1.7          # radians a second round the circle
const SWIFT_HIGH := 6.5           # while they gather (the warning), this high and wider
const SWIFT_LEAVE_SEC := 2.5

## SafariLayer.intro_hint holds the one banner for about 5 s.
const INTRO_HINT_SEC := 5.1
const LINE_SEC := 3.6
const DUST := Color("#d8cbb4")

# ------------------------------------------------------------------------------ state
var pacing: Pacing
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}
var _prop: ShaderMaterial
var _sheet_mat: Material
var _pad_dir := Vector3.UP
var _water_r := 0.0

var _pools: Array = []             # per crater: {dir, rim_m, shore_m}
var _arch: Node3D
var _arch_dir := Vector3.UP
var _arch_xf := Transform3D()      # the arch's own transform (scaled)
var _stones: Dictionary = {}       # name -> Node3D
var _swift_places: Array = []      # [world centre of the circle (ground), circle height]
var _still := 0.0

var _frog_herd: Herd
var _frogs: Array = []
var _frog_focus: Node3D
var _frog_pick := -1
var _croak_next := 0.0

var _liz_herd: Herd
var _lizards: Array = []
var _liz_focus: Node3D
var _liz_pick := -1
var _liz_spots: Array = []         # [ground dir, the column's world position]

var _wisp_herd: Herd
var _wisps: Array = []
var _wisp_focus: Node3D
var _wisp_pick := -1

var _moth_herd: Herd
var _moths: Array = []             # {swarm, ang, r, speed, bob, pos, head}
var _moth_centres: Array = []      # world points over the water
var _moth_seen: Array = []         # per swarm: when last in the frame (-INF: not since it rested)
var _moth_rest: Array = []         # per swarm: resting in its pool until
var _moth_focus: Node3D
var _moth_pick := -1

var _swift_herd: Herd
var _swifts: Array = []            # {ang, r_off, h_off, phase, pos, head}
var _swift_focus: Node3D
var _swift_at := -1
var _swift_k := 0.0                # 0 gathering high, 1 down round the place
var _swift_vis := 0.0
var _chirp_clock := 0.0

var _ripple_root: Node3D
var _ripple_glow: MeshInstance3D
var _ring_herd: Herd
var _fish_herd: Herd
var _fish: Array = []              # {start, dur, ang, span}
var _bubbles: CPUParticles3D
var _ripple_focus: Node3D
var _ripple_at := -1
var _ripple_level := 0.0

var _vine: MeshInstance3D
var _flower_herds: Array = []
var _flowers: Array = []           # {xf (arch-local), herd, i, phase}
var _bloom_open := 0.0
var _bloom_glint := 0.0
var _petals: CPUParticles3D
var _bloom_focus: Node3D

var _arch_root: Node3D
var _arch_sheet: MeshInstance3D
var _arch_glow: MeshInstance3D
var _beam: MeshInstance3D
var _motes: CPUParticles3D
var _arch_focus: Node3D
var _beam_dir := Vector3.FORWARD   # world tangent at the arch: the way the beam runs
var _arch_level := 0.0
var _arch_mat: StandardMaterial3D

var _heron_root: Node3D
var _heron_body: MeshInstance3D
var _heron_wings: Array[MeshInstance3D] = []
var _heron_focus: Node3D
var _heron_spread := 0.0
var _heron_pos := Vector3.ZERO
var _heron_face := Vector3.FORWARD
var _heron_shown := false

var _fen: Node3D
var _fen_saved := Transform3D()
var _fen_wander_saved := true
var _fen_wave_until := -1.0
var _fen_note_until := -1.0
var _fen_next_wave := 0.0
var _fen_next_note := 0.0
var _fen_came_at := -INF
var _fen_came_n := 0
var _fen_stay_until := -INF
var _fen_moved := false

var _beacons: Dictionary = {}
var _lines: Array = []
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 61_0925_12
	_prop = PlanetPropMeshes.prop_material()
	_sheet_mat = PlanetPropMeshes.puff_material(Color.WHITE)
	_find_places()
	_build_frogs()
	_build_lizards()
	_build_wisps()
	if safari.is_night:
		_build_moths()
	_build_swifts()
	_build_ripple()
	_build_vine()
	_build_arch_light()
	if safari.is_rare_day:
		_build_heron()
	_build_fen()
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
	for pr: Array in [["arch light gold / ripple 2", _arch_dir, _pool_dir(RIPPLE_POOLS[1])],
			["heron wings / swifts 3 turn", _pool_dir(HERON_POOL), _pool_dir(SWIFT_POOLS[1])],
			["vine bloom 2 / ripple 3", _arch_dir, _pool_dir(RIPPLE_POOLS[2])]]:
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
		_log("pool %s (crater %d) at %s rim %.2f m shore %.2f m" % [POOL_WORDS[i % POOL_WORDS.size()], i, _pp(d), rim,
			float(_pools[i]["shore_m"])])
	var props := p.get_node_or_null("Props")
	if props != null:
		for c in props.get_children():
			if c is Node3D and str(c.name).begins_with("StandingStone"):
				_stones[str(c.name)] = c
	_arch = p.get_node_or_null("Props/" + ARCH_NAME) as Node3D
	if _arch == null and props != null:
		for c in props.get_children():
			if c is Node3D and str(c.name).begins_with("Arch"):
				_arch = c
				break
	if _arch != null:
		_arch_xf = _arch.global_transform
		var mi := _arch.get_child(0) as Node3D if _arch.get_child_count() > 0 else null
		if mi != null:
			_arch_xf = mi.global_transform
		_arch_dir = p.dir_of(_arch.global_position)
	else:
		_arch_dir = safari.dir_from_start(35.0, 131.0)
		_arch_xf = Transform3D(Basis.looking_at(_tangent_at(_arch_dir), _arch_dir).scaled(Vector3.ONE * 1.4), p.surface_point(_arch_dir))
	_log("arch at %s scale %.2f; stones %s; fen home %s" % [_pp(_arch_dir), _arch_xf.basis.get_scale().y,
		str(_stones.keys()), _pp(_fen_home_dir())])


## How far from pool centre `d` the water ends (the first dry ground going out), in metres.
func _shore_m(d: Vector3, rim_m: float) -> float:
	var p := safari.planet
	var t := _tangent_at(d)
	var best := rim_m
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
	best = float(shores[shores.size() / 2])
	return best


func _pool_dir(i: int) -> Vector3:
	return (_pools[i]["dir"] as Vector3) if i < _pools.size() else safari.dir_from_start(90.0, 0.0)


## The point `m` metres out from pool `i`'s centre along the angle `ang` (radians, from the start heading).
func _pool_ring(i: int, m: float, ang: float) -> Vector3:
	var c := _pool_dir(i)
	return _polar(c, _tangent_at(c), rad_to_deg(m / safari.planet.radius), rad_to_deg(ang))


## A world point on pool `i`'s water surface, `lift` above it.
func _water_point(i: int, lift: float = 0.0) -> Vector3:
	var d := _pool_dir(i)
	return safari.planet.global_position + d * (_water_r + lift)


func _pool_name(i: int) -> String:
	return "POOL " + str(POOL_WORDS[i % POOL_WORDS.size()])


## `dir`, or the nearest spot round it at least `clear_m` from every prop and out of the water.
func _free_near(dir: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(dir) >= clear_m and not p.is_underwater(dir):
		return dir
	var t := _tangent_at(dir)
	for ring_deg in [1.5, 3.0, 4.5, 6.0, 8.0, 10.0, 13.0]:
		for k in 8:
			var d := _polar(dir, t, ring_deg, 45.0 * float(k))
			if p.nearest_prop_distance(d) >= clear_m and not p.is_underwater(d) and rad_to_deg(d.angle_to(_pad_dir)) > 10.0:
				return d
	return dir


func _fen_home_dir() -> Vector3:
	if _fen != null and is_instance_valid(_fen) and _fen.get("home_dir") != null:
		return (_fen.get("home_dir") as Vector3).normalized()
	return safari.dir_from_start(74.0, 51.0)


# ---------------------------------------------------------------------------------------- pool-frogs
func _build_frogs() -> void:
	var p := safari.planet
	var pts: Array = []
	for pi: int in FROG_POOLS:
		if pi >= _pools.size():
			continue
		var shore := _frog_seat_m(pi)
		for k in FROGS_PER_POOL:
			var ang := TAU * float(k) / float(FROGS_PER_POOL) + _rng.randf_range(-0.5, 0.5)
			var d := _frog_spot(pi, ang)
			_frogs.append({"pool": pi, "ang": ang, "dir": d, "face": _toward(d, d * 2.0 - _pool_dir(pi)),
				"state": Frog.SIT, "timer": _rng.randf_range(0.5, 3.0), "from": d, "to": d, "air": 0.0,
				"apex": FROG_HOP_H, "h": 0.0, "croak": 0.0, "shore": shore, "scout": false, "out_t": 0.0})
			pts.append(p.surface_point(d))
	# the SCOUTS: frogs under the water of any pool, that the pacing director brings up onto a rim near
	# where you look when it has gone quiet
	for k in FROG_SCOUTS:
		_frogs.append({"pool": 0, "ang": 0.0, "dir": safari.start_dir, "face": safari.start_fwd, "state": Frog.UNDER,
			"timer": 0.0, "from": safari.start_dir, "to": safari.start_dir, "air": 0.0, "apex": FROG_HOP_H, "h": 0.0,
			"croak": 0.0, "shore": 1.0, "scout": true, "out_t": 0.0})
	_frog_herd = Herd.new()
	add_child(_frog_herd)
	var rr := p.radius + 3.0
	_frog_herd.setup("PoolFrogs", _frogs.size(), [[Meshes.frog(), _prop, true], [Meshes.frog_throat(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_frog_focus = Node3D.new()
	_frog_focus.name = "FrogFocus"
	add_child(_frog_focus)
	safari.add_subject({
		"id": "pool_frog", "name": "Pool-frog", "kind": "creature",
		"band": BAND_FROG, "node": _frog_focus, "offset": Vector3(0.0, 0.15, 0.0), "radius": 0.2,
		"awake": func() -> bool: return _frog_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _frog_moment(),
		"front": func() -> Vector3: return _front_of(_frog_focus),
	})


## A frog's seat on pool `pi`'s dry lip at angle `ang`, moved round the rim off any prop.
func _frog_seat_m(pi: int) -> float:
	return float(_pools[pi]["rim_m"]) - FROG_RIM_IN


func _frog_spot(pi: int, ang: float) -> Vector3:
	var p := safari.planet
	var shore := _frog_seat_m(pi)
	for tries in 8:
		var a := ang + 0.22 * float(tries) * (1.0 if tries % 2 == 0 else -1.0)
		var d := _pool_ring(pi, shore, a)
		if p.nearest_prop_distance(d) >= 0.3 and not p.is_underwater(d):
			return d
	return _pool_ring(pi, shore + 0.2, ang)


func _frog_moment() -> Dictionary:
	if _frog_pick < 0:
		return {"mult": 1.0, "line": ""}
	var f: Dictionary = _frogs[_frog_pick]
	if int(f["state"]) == Frog.CROAK:
		return {"mult": 1.8, "line": "croaking at you"}
	if int(f["state"]) in [Frog.AIR, Frog.PLOP] and float(f["h"]) > 0.6 * float(f["apex"]):
		return {"mult": 1.5, "line": "mid-hop"}
	return {"mult": 1.0, "line": ""}


func _frog_out(f: Dictionary) -> bool:
	return int(f["state"]) != Frog.UNDER


func _tick_frogs(delta: float) -> void:
	if _frog_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	var shy := pacing != null and pacing.shy("pool_frog")
	var croak_i := -1
	if _still >= STILL_SEC and _t >= _croak_next and not _sleeping:
		var best := FROG_CROAK_M
		for i in _frogs.size():
			var f: Dictionary = _frogs[i]
			if int(f["state"]) in [Frog.SIT, Frog.CROUCH]:
				var dd := p.surface_point(f["dir"]).distance_to(ppos)
				if dd < best:
					best = dd
					croak_i = i
	for i in _frogs.size():
		var f: Dictionary = _frogs[i]
		var here := p.surface_point(f["dir"])
		var dist := here.distance_to(ppos)
		var st: int = f["state"]
		f["timer"] = float(f["timer"]) - delta
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.12, 1.1)
		# THE END, and ONE NEW THING AT A TIME: out of the frame a frog slips under the water.
		if (_sleeping or (shy and not in_frame)) and st in [Frog.SIT, Frog.CROUCH, Frog.CROAK]:
			f["state"] = Frog.UNDER
			f["timer"] = 0.6 if _sleeping else _rng.randf_range(FROG_UNDER_SEC.x, FROG_UNDER_SEC.y)
			f["shy"] = true
			st = Frog.UNDER
		var rushed := dist < FROG_RUSH_M and speed > FROG_RUSH_SPEED
		match st:
			Frog.SIT:
				if i == croak_i:
					f["state"] = Frog.CROAK
					f["croak"] = FROG_CROAK_SEC
					_croak_next = _t + FROG_CROAK_SEC + FROG_CROAK_REST
					AudioManager.play_sfx_at("doot_a_0", here, -8.0, 0.1)
				elif rushed:
					_frog_plop(f)
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_turn_face(f, ppos - here, CURIOUS_RATE, delta)
				elif float(f["timer"]) <= 0.0:
					f["state"] = Frog.CROUCH
					f["timer"] = FROG_CROUCH_SEC
			Frog.CROUCH:
				if float(f["timer"]) <= 0.0:
					var pi: int = f["pool"]
					var na := float(f["ang"]) + _rng.randf_range(FROG_HOP_RAD.x, FROG_HOP_RAD.y) * (1.0 if _rng.randf() < 0.5 else -1.0)
					var to := _frog_spot(pi, na)
					f["ang"] = na
					_frog_hop(f, to, FROG_HOP_H)
			Frog.AIR, Frog.PLOP:
				f["air"] = float(f["air"]) + delta
				var k := clampf(float(f["air"]) / FROG_AIR_SEC, 0.0, 1.0)
				f["dir"] = (f["from"] as Vector3).slerp(f["to"], k).normalized()
				f["h"] = 4.0 * float(f["apex"]) * k * (1.0 - k)
				if k >= 1.0:
					f["h"] = 0.0
					if st == Frog.PLOP:
						f["state"] = Frog.UNDER
						f["timer"] = _rng.randf_range(FROG_UNDER_SEC.x, FROG_UNDER_SEC.y)
						var at := p.global_position + (f["dir"] as Vector3) * _water_r
						if in_frame or dist < 8.0:
							safari.puff_at(at, 6, Color("#cfe0dd"))
							AudioManager.play_sfx_at("splash", at, -10.0, 0.25)
					else:
						f["state"] = Frog.SIT
						f["timer"] = _rng.randf_range(FROG_SIT_SEC.x, FROG_SIT_SEC.y)
			Frog.UNDER:
				var held := (bool(f.get("shy", false)) and shy) or bool(f["scout"])
				if not _sleeping and not held and float(f["timer"]) <= 0.0 and dist > FROG_RUSH_M and not rushed:
					f["shy"] = false
					var na := _rng.randf_range(0.0, TAU)
					f["ang"] = na
					f["dir"] = _frog_spot(int(f["pool"]), na)
					f["face"] = _toward(f["dir"], (f["dir"] as Vector3) * 2.0 - _pool_dir(int(f["pool"])))
					f["state"] = Frog.SIT
					f["timer"] = _rng.randf_range(FROG_SIT_SEC.x, FROG_SIT_SEC.y)
			Frog.CROAK:
				f["croak"] = float(f["croak"]) - delta
				_turn_face(f, ppos - here, 5.0, delta)
				if float(f["croak"]) <= 0.0 or rushed or not still_up:
					f["state"] = Frog.SIT
					f["timer"] = _rng.randf_range(FROG_SIT_SEC.x, FROG_SIT_SEC.y)
		if int(f["state"]) != Frog.UNDER:
			f["out_t"] = float(f["out_t"]) + delta
		# a scout left behind, out of view, slips back under
		if bool(f["scout"]) and int(f["state"]) in [Frog.SIT, Frog.CROUCH] and float(f["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			f["state"] = Frog.UNDER
		_pose_frog(i, f)
	_frog_pick = _pick_focus(_frogs, func(f: Dictionary) -> bool: return _frog_out(f),
		func(f: Dictionary) -> Vector3: return p.surface_point(f["dir"]), 0.13)
	if _frog_pick >= 0:
		var f: Dictionary = _frogs[_frog_pick]
		_frog_focus.global_transform = _xf_ground(f["dir"], f["face"]).translated_local(Vector3(0.0, float(f["h"]), 0.0))


func _frog_hop(f: Dictionary, to: Vector3, apex: float) -> void:
	f["from"] = f["dir"]
	f["to"] = to
	f["air"] = 0.0
	f["apex"] = apex
	f["state"] = Frog.AIR
	if safari.planet.surface_distance(f["dir"], to) > 0.05:
		f["face"] = _toward(f["dir"], to)


## Rushed: it hops out over the water and plops in.
func _frog_plop(f: Dictionary) -> void:
	var pi: int = f["pool"]
	var into := _pool_ring(pi, maxf(float(_pools[pi]["shore_m"]) - 0.7, 0.2), float(f["ang"]))
	_frog_hop(f, into, FROG_HOP_H * 1.3)
	f["state"] = Frog.PLOP


func _turn_face(c: Dictionary, want: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = c["dir"]
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = c["face"]
	cur -= d * cur.dot(d)
	c["face"] = cur.normalized().slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_frog(i: int, f: Dictionary) -> void:
	var st: int = f["state"]
	if st == Frog.UNDER:
		_frog_herd.hide_one(i)
		return
	var crouch := 0.84 if st == Frog.CROUCH else 1.0
	var stretch := 1.12 if st in [Frog.AIR, Frog.PLOP] else 1.0
	var base := _xf_ground(f["dir"], f["face"])
	# a frog in the air over the water flies at the water's level, not the pool floor's
	base = base.translated_local(Vector3(0.0, float(f["h"]), 0.0))
	base.basis = base.basis * Basis.from_scale(Vector3(1.0 / sqrt(crouch * stretch), crouch * stretch, 1.0 / sqrt(crouch * stretch)))
	_frog_herd.pose(i, 0, base)
	var th := 0.5
	if st == Frog.CROAK:
		th = 0.55 + 0.75 * absf(sin(_t * 5.0))
	_frog_herd.pose(i, 1, base * Transform3D(Basis.from_scale(Vector3.ONE * th), Meshes.FROG_THROAT_AT))


## THE PACING DIRECTOR brings a frog: it hops up out of the pool nearest the spot where you look, onto
## that pool's rim, when a rim spot is in the middle of the view (pools only: never out of dry ground).
func _bring_frog(spot: Dictionary) -> bool:
	var i := -1
	for k in _frogs.size():
		if bool(_frogs[k]["scout"]) and int(_frogs[k]["state"]) == Frog.UNDER:
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
		var wp := _water_point(pi)
		if wp.distance_to(g) > FROG_BRING_POOL_M or pi == HERON_POOL or pi == STATUE_POOL or pi == BOTTLE_POOL:
			continue
		for k in 12:
			var ang := TAU * float(k) / 12.0
			var fd := _frog_spot(pi, ang)
			if p.surface_point(fd).distance_to(lens.origin) < 2.5:
				continue
			var body := p.surface_point(fd) + p.up_at(p.surface_point(fd)) * 0.15
			if not pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC) or not pacing.sight_clear(lens.origin, body):
				continue
			var f: Dictionary = _frogs[i]
			f["pool"] = pi
			f["ang"] = ang
			f["dir"] = fd
			f["shore"] = _frog_seat_m(pi)
			# looking out over the pan, not at you: it turns to a still camera (CURIOUS_*)
			f["face"] = _toward(fd, fd * 2.0 - _pool_dir(pi)).rotated(fd, _rng.randf_range(-1.2, 1.2))
			f["state"] = Frog.SIT
			f["timer"] = _rng.randf_range(FROG_SIT_SEC.x, FROG_SIT_SEC.y)
			f["out_t"] = 0.0
			var at := p.global_position + fd * _water_r
			safari.puff_at(at, 6, Color("#cfe0dd"))
			AudioManager.play_sfx_at("splash", at, -8.0, 0.25)
			return true
	return false


# ---------------------------------------------------------------------------------------- ruin-lizards
func _build_lizards() -> void:
	var p := safari.planet
	var pts: Array = []
	# spot 0: the colonnade's near end; spot 1: pool TWO's spires (LIZARD_POOL)
	for nm: String in LIZARD_STONES:
		var st := _stones.get(nm) as Node3D
		if st == null:
			continue
		_liz_spots.append([p.dir_of(st.global_position), st.global_position])
		break
	if LIZARD_POOL < _pools.size():
		var rim := float(_pools[LIZARD_POOL]["rim_m"]) + 0.75
		var d := _pool_ring(LIZARD_POOL, rim, 0.6)
		_liz_spots.append([p.dir_of(p.surface_point(d)), p.surface_point(d)])
	if _liz_spots.size() < 2:
		_liz_spots.append([safari.dir_from_start(40.0, 99.0), p.surface_point(safari.dir_from_start(40.0, 99.0))])
	for si in _liz_spots.size():
		var cdir: Vector3 = _liz_spots[si][0]
		for k in LIZARDS_PER_SPOT:
			var d := _liz_seat(cdir, TAU * float(k) / float(LIZARDS_PER_SPOT) + 0.8 * float(si))
			_lizards.append({"spot": si, "dir": d, "home": d, "face": _sun_face(d), "state": Liz.BASK,
				"timer": _rng.randf_range(1.0, 4.0), "push_next": _rng.randf_range(2.0, 8.0), "push": 0.0,
				"from": d, "to": d, "out_t": 0.0})
			pts.append(p.surface_point(d))
	for k in LIZARD_SCOUTS:
		_lizards.append({"spot": -1, "dir": safari.start_dir, "home": safari.start_dir, "face": safari.start_fwd,
			"state": Liz.GONE, "timer": 0.0, "push_next": _rng.randf_range(3.0, 8.0), "push": 0.0,
			"from": safari.start_dir, "to": safari.start_dir, "out_t": 0.0})
	_liz_herd = Herd.new()
	add_child(_liz_herd)
	var r := p.radius + 3.0
	_liz_herd.setup("RuinLizards", _lizards.size(), [[Meshes.lizard(), _prop, true]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_liz_focus = Node3D.new()
	_liz_focus.name = "LizardFocus"
	add_child(_liz_focus)
	safari.add_subject({
		"id": "ruin_lizard", "name": "Ruin-lizard", "kind": "creature",
		"band": BAND_LIZARD, "node": _liz_focus, "offset": Vector3(0.0, 0.15, -0.04), "radius": 0.24,
		"awake": func() -> bool: return _liz_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _liz_pick >= 0 and int(_lizards[_liz_pick]["state"]) == Liz.PUSH:
				return {"mult": 1.8, "line": "doing push-ups"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_liz_focus),
	})


## A basking seat round column centre `c` (a direction), 0.75-1.0 m out, off props.
func _liz_seat(c: Vector3, ang: float) -> Vector3:
	var p := safari.planet
	for tries in 10:
		var a := ang + 0.5 * float(tries)
		var m := 1.05 + 0.12 * float(tries % 3)
		var d := _polar(c, _tangent_at(c), rad_to_deg(m / p.radius), rad_to_deg(a))
		if p.nearest_prop_distance(d) >= 0.35 and not p.is_underwater(d):
			return d
	return _free_near(c, 0.6)


## Basking lizards face the low sun (so the photographer with the sun at their back sees their faces).
func _sun_face(d: Vector3) -> Vector3:
	var env := safari.world.get_node_or_null("Environment") if safari.world != null else null
	var sun := Vector3.ZERO
	if env != null and env.has_method("get_sun_direction"):
		sun = env.call("get_sun_direction")
	var t := sun - d * sun.dot(d)
	if t.length() < 0.05:
		return _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
	return t.normalized().rotated(d, _rng.randf_range(-0.6, 0.6))


func _liz_out(z: Dictionary) -> bool:
	var st: int = z["state"]
	return st in [Liz.BASK, Liz.PUSH] or (st == Liz.POP and float(z["timer"]) < SCOUT_POP_SEC * 0.5)


func _tick_lizards(delta: float) -> void:
	if _liz_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	var shy := pacing != null and pacing.shy("ruin_lizard")
	for i in _lizards.size():
		var z: Dictionary = _lizards[i]
		var here := p.surface_point(z["dir"])
		var dist := here.distance_to(ppos)
		var st: int = z["state"]
		var scout := int(z["spot"]) < 0
		z["timer"] = float(z["timer"]) - delta
		if st != Liz.GONE:
			z["out_t"] = float(z["out_t"]) + delta
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.07, 1.1)
		if (_sleeping or (shy and not in_frame)) and st in [Liz.BASK, Liz.PUSH]:
			if scout:
				_liz_dive(z, in_frame)
			else:
				_liz_dart(z, ppos)
				z["shy"] = true
			st = z["state"]
		var rushed := dist < LIZARD_RUSH_M and speed > LIZARD_RUSH_SPEED
		match st:
			Liz.GONE:
				pass
			Liz.POP:
				if float(z["timer"]) <= 0.0:
					z["state"] = Liz.BASK
					z["timer"] = _rng.randf_range(1.0, 3.0)
			Liz.BASK:
				if rushed:
					if scout:
						_liz_dive(z, in_frame)
					else:
						_liz_dart(z, ppos)
				elif _still >= CURIOUS_AFTER and dist < CURIOUS_M:
					_turn_face(z, ppos - here, CURIOUS_RATE, delta)
				z["push_next"] = float(z["push_next"]) - delta
				if int(z["state"]) == Liz.BASK and float(z["push_next"]) <= 0.0:
					z["state"] = Liz.PUSH
					z["push"] = LIZARD_PUSH_SEC
					z["push_next"] = _rng.randf_range(LIZARD_PUSH_EVERY.x, LIZARD_PUSH_EVERY.y)
			Liz.PUSH:
				z["push"] = float(z["push"]) - delta
				if rushed:
					if scout:
						_liz_dive(z, in_frame)
					else:
						_liz_dart(z, ppos)
				elif float(z["push"]) <= 0.0:
					z["state"] = Liz.BASK
			Liz.DART:
				var k := clampf(1.0 - float(z["timer"]) / LIZARD_DART_SEC, 0.0, 1.0)
				z["dir"] = (z["from"] as Vector3).slerp(z["to"], k).normalized()
				if float(z["timer"]) <= 0.0:
					z["state"] = Liz.HIDDEN
					z["timer"] = _rng.randf_range(LIZARD_HIDE_SEC.x, LIZARD_HIDE_SEC.y)
			Liz.HIDDEN:
				var held := bool(z.get("shy", false)) and shy
				if not _sleeping and not held and float(z["timer"]) <= 0.0 and dist > LIZARD_RUSH_M:
					z["shy"] = false
					z["dir"] = z["home"]
					z["face"] = _sun_face(z["dir"])
					z["state"] = Liz.BASK
					z["timer"] = _rng.randf_range(1.0, 3.0)
		# a scout left behind, out of view, slips back into its crack
		if scout and int(z["state"]) in [Liz.BASK, Liz.PUSH] and float(z["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			_liz_dive(z, false)
		_pose_lizard(i, z)
	_liz_pick = _pick_focus(_lizards, func(z: Dictionary) -> bool: return _liz_out(z),
		func(z: Dictionary) -> Vector3: return p.surface_point(z["dir"]), 0.07)
	if _liz_pick >= 0:
		var z: Dictionary = _lizards[_liz_pick]
		_liz_focus.global_transform = _xf_ground(z["dir"], z["face"])


## Rushed: it scurries off round its column and out of sight.
func _liz_dart(z: Dictionary, from: Vector3) -> void:
	var p := safari.planet
	var d: Vector3 = z["dir"]
	var away := _toward(d, d * 2.0 - p.dir_of(from))
	var to := p.step_dir(d, (d + away * 0.2).normalized(), LIZARD_DART_M)
	z["from"] = d
	z["to"] = to
	z["face"] = away
	z["state"] = Liz.DART
	z["timer"] = LIZARD_DART_SEC
	if _point_in_frame(p.surface_point(d), 1.2):
		AudioManager.play_sfx_at("footstep_stone_0", p.surface_point(d), -12.0, 0.3)


## A scout slips back into its crack (a little puff of salt if you can see it).
func _liz_dive(z: Dictionary, seen: bool) -> void:
	if int(z["state"]) == Liz.GONE:
		return
	var here := safari.planet.surface_point(z["dir"])
	if seen and not _sleeping:
		safari.puff_at(here + safari.planet.up_at(here) * 0.05, 6, DUST)
	z["state"] = Liz.GONE


func _pose_lizard(i: int, z: Dictionary) -> void:
	var st: int = z["state"]
	if st in [Liz.GONE, Liz.HIDDEN]:
		_liz_herd.hide_one(i)
		return
	var base := _xf_ground(z["dir"], z["face"])
	var sink := 0.0
	if st == Liz.POP:
		sink = 0.12 * clampf(float(z["timer"]) / SCOUT_POP_SEC, 0.0, 1.0)
	var lift := 0.0
	var pitch := 0.0
	if st == Liz.PUSH:
		var ph := absf(sin((LIZARD_PUSH_SEC - float(z["push"])) * TAU * 1.4))
		lift = 0.035 * ph
		pitch = 0.28 * ph
	elif st == Liz.DART:
		lift = 0.01 * absf(sin(_t * 30.0))
	base = base.translated_local(Vector3(0.0, lift - sink, 0.0))
	# a push-up tips the head end up (the mesh faces -Z: a turn about +X lifts the front)
	base.basis = base.basis * Basis(Vector3.RIGHT, pitch)
	_liz_herd.pose(i, 0, base)


## THE PACING DIRECTOR brings a lizard: it scurries out of a crack in the crust where you look.
func _bring_lizard(spot: Dictionary) -> bool:
	var i := -1
	for k in _lizards.size():
		if int(_lizards[k]["spot"]) < 0 and int(_lizards[k]["state"]) == Liz.GONE:
			i = k
			break
	if i < 0:
		return false
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO:
		# looking over the ground: a lizard can only come out ON the ground, so only when the ground spot
		# ahead is already in the lower part of the view (a small "rise" means it sits just under the
		# middle of the frame; LIZARD_RISE_MAX of it keeps it inside the frame)
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0 or float(spot["rise"]) > LIZARD_RISE_MAX:
			return false
		d = spot["ahead"]
	var z: Dictionary = _lizards[i]
	var lens: Transform3D = spot["lens"]
	z["dir"] = d
	z["home"] = d
	# out of its crack it faces the low sun, as they all do, not you
	z["face"] = _sun_face(d)
	z["state"] = Liz.POP
	z["timer"] = SCOUT_POP_SEC
	z["out_t"] = 0.0
	var here := safari.planet.surface_point(d)
	safari.puff_at(here + safari.planet.up_at(here) * 0.05, 8, DUST)
	AudioManager.play_sfx_at("footstep_stone_1", here, -6.0, 0.25)
	return true


# ---------------------------------------------------------------------------------------- mist-wisps
func _build_wisps() -> void:
	var p := safari.planet
	for k in WISP_N:
		var roam := k < WISP_ROAMERS
		var watch := k >= WISP_ROAMERS and k < WISP_ROAMERS + WISP_WATCHERS
		var d := safari.start_dir
		if roam:
			var f: Vector2 = WISP_FROM[k]
			d = _free_near(safari.dir_from_start(f.x, f.y), 0.8)
		_wisps.append({"dir": d, "head": _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU)),
			"state": Wis.DRIFT if roam else Wis.AWAY, "roamer": roam, "watch": watch, "out_t": 0.0,
			"alt": WISP_ALT, "grow": 1.0 if roam else 0.0, "turn": 0.0, "turn_t": 0.0,
			"phase": _rng.randf_range(0.0, TAU), "hello": 0.0})
	_wisp_herd = Herd.new()
	add_child(_wisp_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(0.85, 0.85)
	var r := p.radius + 6.0
	_wisp_herd.setup("MistWisps", WISP_N, [[Meshes.wisp(), _prop, false],
		[glow, MaterialLib.glow_sprite(Color("#efe2c4"), 1.8, {"softness": 0.0, "core": 0.2, "blink": 0.15, "blink_speed": 1.6}), false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_wisp_focus = Node3D.new()
	_wisp_focus.name = "WispFocus"
	add_child(_wisp_focus)
	safari.add_subject({
		"id": "mist_wisp", "name": "Mist-wisp", "kind": "creature",
		"band": BAND_WISP, "node": _wisp_focus, "offset": Vector3.ZERO, "radius": 0.2,
		"awake": func() -> bool: return _wisp_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _wisp_pick >= 0 and int(_wisps[_wisp_pick]["state"]) == Wis.HELLO:
				return {"mult": 1.8, "line": "twirling hello"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_wisp_focus),
	})


func _wisp_out(w: Dictionary) -> bool:
	return int(w["state"]) in [Wis.DRIFT, Wis.HELLO] or (int(w["state"]) == Wis.COME and float(w["grow"]) > 0.7)


func _wisp_pos(w: Dictionary) -> Vector3:
	var d: Vector3 = w["dir"]
	var lift := float(w["alt"]) + 0.07 * sin(_t * 1.1 + float(w["phase"]))
	if int(w["state"]) in [Wis.COME, Wis.LEAVE]:
		lift += 0.9 * (1.0 - float(w["grow"]))
	var g := safari.planet.surface_point(d)
	return g + safari.planet.up_at(g) * lift


func _tick_wisps(delta: float) -> void:
	if _wisp_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var still_up := safari.camera_up and safari.player.get_tangent_velocity().length() < 0.15
	var shy := pacing != null and pacing.shy("mist_wisp")
	var hello_done := false
	var rare_on := _rare_warned_or_up()
	for i in _wisps.size():
		var w: Dictionary = _wisps[i]
		if bool(w["watch"]):
			_tick_watcher(w, rare_on)
		if bool(w["roamer"]):
			_tick_roamer_rest(w)
		var st: int = w["state"]
		var pos := _wisp_pos(w)
		var dist := pos.distance_to(ppos)
		var in_frame := _point_in_frame(pos, 1.1)
		if st != Wis.AWAY:
			w["out_t"] = float(w["out_t"]) + delta
		var brought := not bool(w["roamer"]) and not bool(w["watch"])
		if (_sleeping or (shy and not in_frame and brought)) and st in [Wis.DRIFT, Wis.HELLO, Wis.COME]:
			w["state"] = Wis.LEAVE
			st = Wis.LEAVE
		match st:
			Wis.AWAY:
				pass
			Wis.COME:
				w["grow"] = move_toward(float(w["grow"]), 1.0, delta / WISP_COME_SEC)
				if float(w["grow"]) >= 1.0:
					w["state"] = Wis.DRIFT
			Wis.LEAVE:
				w["grow"] = move_toward(float(w["grow"]), 0.0, delta / WISP_LEAVE_SEC)
				if float(w["grow"]) <= 0.0:
					w["state"] = Wis.AWAY
			Wis.DRIFT:
				var curious := still_up and dist < CURIOUS_M
				if not curious:
					_wisp_drift(w, delta)
				elif dist < WISP_KEEP_M:
					var here: Vector3 = w["dir"]
					w["dir"] = p.step_dir(here, (here * 2.0 - p.dir_of(ppos)).normalized(), 0.3 * delta)
				if _still >= STILL_SEC and dist < WISP_HELLO_M and not hello_done and float(w["hello"]) <= -WISP_HELLO_REST:
					w["state"] = Wis.HELLO
					w["hello"] = WISP_HELLO_SEC
					hello_done = true
					AudioManager.play_sfx_at("collect_stardust", pos, -14.0, 0.2)
				elif curious and _still >= CURIOUS_AFTER:
					_wisp_face(w, ppos, CURIOUS_RATE, delta)
				w["hello"] = float(w["hello"]) - delta
				if brought and float(w["out_t"]) > WISP_OUT_MIN_SEC and dist > WISP_LEAVE_M and not in_frame:
					w["state"] = Wis.LEAVE
			Wis.HELLO:
				w["hello"] = float(w["hello"]) - delta
				_wisp_face(w, ppos, 6.0, delta)
				if float(w["hello"]) <= 0.0 or not still_up:
					w["state"] = Wis.DRIFT
					w["hello"] = 0.0
		_pose_wisp(i, w)
	_wisp_pick = _pick_focus(_wisps, func(w: Dictionary) -> bool: return _wisp_out(w),
		func(w: Dictionary) -> Vector3: return _wisp_pos(w), 0.0)
	if _wisp_pick >= 0:
		var w: Dictionary = _wisps[_wisp_pick]
		var pos := _wisp_pos(w)
		_wisp_focus.global_transform = Transform3D(Basis.looking_at(w["head"], p.up_at(pos)), pos)


## ROAMER_REST_SEC: off once photographed and out of the frame; back later near you, out of view.
func _tick_roamer_rest(w: Dictionary) -> void:
	var st: int = w["state"]
	var until := float(w.get("rest_until", -INF))
	if _t < until and st in [Wis.DRIFT, Wis.HELLO] and not _point_in_frame(_wisp_pos(w), 1.1):
		w["state"] = Wis.LEAVE
	elif st == Wis.AWAY and _t >= until and not _sleeping and until > -INF:
		var p := safari.planet
		for tries in 12:
			var d := _polar(_player_dir(), _tangent_at(_player_dir()), _rng.randf_range(15.0, 45.0), _rng.randf_range(0.0, 360.0))
			var pos := p.surface_point(d) + p.up_at(p.surface_point(d)) * WISP_ALT
			if p.nearest_prop_distance(d) >= 1.0 and not p.is_underwater(d) and not _point_in_frame(pos, 1.2):
				w["dir"] = d
				w["alt"] = WISP_ALT
				w["head"] = _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
				w["state"] = Wis.COME
				w["grow"] = 0.0
				w["out_t"] = 0.0
				w["rest_until"] = -INF
				return


## True from a rare event's warning to its end (the arch light; the heron on a rare day).
func _rare_warned_or_up() -> bool:
	if bool(_eligible.get("arch_light", false)) and _t >= ARCH_START - WARN and _t < ARCH_END:
		return true
	return bool(_eligible.get("stone_heron", false)) and _t >= HERON_START - WARN and _t < HERON_END


## A WATCHER drifts out somewhere near you that you are not looking at (15-45 degrees round, out of the
## frame) when a rare event is warned, and drifts on toward the rare's place, drawn by its light; after
## it, it drifts off out of your view.
func _tick_watcher(w: Dictionary, rare_on: bool) -> void:
	var st: int = w["state"]
	if rare_on and st == Wis.AWAY and not _sleeping:
		var p := safari.planet
		for tries in 12:
			var d := _polar(_player_dir(), _tangent_at(_player_dir()), _rng.randf_range(15.0, 45.0), _rng.randf_range(0.0, 360.0))
			var pos := p.surface_point(d) + p.up_at(p.surface_point(d)) * WISP_ALT
			if p.nearest_prop_distance(d) >= 1.0 and not p.is_underwater(d) and not _point_in_frame(pos, 1.2):
				w["dir"] = d
				w["head"] = _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
				w["state"] = Wis.COME
				w["grow"] = 0.0
				w["out_t"] = 0.0
				return
	elif not rare_on and st in [Wis.DRIFT, Wis.HELLO] and not _point_in_frame(_wisp_pos(w), 1.1):
		w["state"] = Wis.LEAVE


func _wisp_drift(w: Dictionary, delta: float) -> void:
	var p := safari.planet
	var d: Vector3 = w["dir"]
	var head: Vector3 = w["head"]
	head = (head - d * head.dot(d)).normalized()
	w["turn_t"] = float(w["turn_t"]) - delta
	if float(w["turn_t"]) <= 0.0:
		w["turn_t"] = _rng.randf_range(2.0, 5.0)
		w["turn"] = _rng.randf_range(-0.35, 0.35)
	var turn := float(w["turn"])
	# a watcher leans toward the rare it is drawn to
	if bool(w["watch"]) and _rare_warned_or_up():
		var goal := _arch_dir if _t < ARCH_END + 1.0 else _pool_dir(HERON_POOL)
		var want := _toward(d, goal)
		turn += clampf(head.cross(want).dot(d), -1.0, 1.0) * 0.6
	var ahead := p.step_dir(d, (d + head * 0.2).normalized(), 1.0)
	if p.nearest_prop_distance(ahead) < 1.0 or rad_to_deg(ahead.angle_to(_pad_dir)) < 12.0:
		turn = 1.2 if turn >= 0.0 else -1.2
	head = head.rotated(d, turn * delta).normalized()
	var nd := p.step_dir(d, (d + head * 0.2).normalized(), WISP_SPEED * delta)
	if d.dot(nd) < 0.9999999:
		head = Quaternion(d, nd) * head
	w["dir"] = nd
	w["head"] = (head - nd * head.dot(nd)).normalized()


func _wisp_face(w: Dictionary, world_pos: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = w["dir"]
	var want := world_pos - safari.planet.surface_point(d)
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = w["head"]
	w["head"] = cur.slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_wisp(i: int, w: Dictionary) -> void:
	var st: int = w["state"]
	if st == Wis.AWAY:
		_wisp_herd.hide_one(i)
		return
	var pos := _wisp_pos(w)
	var up := safari.planet.up_at(pos)
	var g := lerpf(0.35, 1.0, float(w["grow"])) if st != Wis.LEAVE else maxf(float(w["grow"]), 0.001)
	var head: Vector3 = w["head"]
	if st == Wis.HELLO:
		head = head.rotated(up, 0.6 * sin(_t * 8.0))
	var b := Basis.looking_at(head, up)
	var breath := 1.0 + 0.06 * sin(_t * 2.6 + float(w["phase"]))
	_wisp_herd.pose(i, 0, Transform3D(b * Basis.from_scale(Vector3.ONE * g * breath), pos))
	_wisp_herd.pose(i, 1, Transform3D(Basis.from_scale(Vector3.ONE * g), pos))


## THE PACING DIRECTOR brings a wisp: it drifts down out of the dusk into the middle of the view.
func _bring_wisp(spot: Dictionary) -> bool:
	var i := -1
	for k in _wisps.size():
		var w: Dictionary = _wisps[k]
		if int(w["state"]) == Wis.AWAY and not bool(w["roamer"]) and not bool(w["watch"]):
			i = k
			break
	if i < 0:
		return false
	var d: Vector3 = spot["dir"]
	var alt := WISP_ALT
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		d = spot["ahead"]
		alt = maxf(float(spot["rise"]) + pacing.SPOT_LIFT_M, WISP_ALT)
	if safari.planet.is_underwater(d):
		alt += 0.3
	var w: Dictionary = _wisps[i]
	var lens: Transform3D = spot["lens"]
	w["dir"] = d
	w["alt"] = alt
	# drifting across the view, not straight at you
	w["head"] = _toward(d, safari.planet.dir_of(lens.origin)).rotated(d, (1.0 if _rng.randf() < 0.5 else -1.0) * _rng.randf_range(1.0, 2.0))
	w["state"] = Wis.COME
	w["grow"] = 0.0
	w["out_t"] = 0.0
	w["hello"] = 0.0
	AudioManager.play_sfx_at("collect_stardust", _wisp_pos(w), -14.0, 0.2)
	return true


# ---------------------------------------------------------------------------------------- glow-moths (night)
func _build_moths() -> void:
	for pi: int in MOTH_POOLS:
		if pi < _pools.size():
			_moth_centres.append(_water_point(pi, MOTH_ALT))
	if _moth_centres.is_empty():
		return
	for si in _moth_centres.size():
		_moth_seen.append(-INF)
		_moth_rest.append(-INF)
	var n := _moth_centres.size() * MOTHS_PER_SWARM
	for k in n:
		_moths.append({"swarm": k / MOTHS_PER_SWARM, "ang": _rng.randf_range(0.0, TAU), "r": _rng.randf_range(0.5, 1.3),
			"speed": _rng.randf_range(0.7, 1.2) * (1.0 if k % 2 == 0 else -1.0), "bob": _rng.randf_range(0.0, TAU),
			"pos": Vector3.ZERO, "head": Vector3.FORWARD})
	_moth_herd = Herd.new()
	add_child(_moth_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(0.42, 0.42)
	_moth_herd.setup("GlowMoths", n, [[Meshes.moth(), _prop, false],
		[glow, MaterialLib.glow_sprite(Color("#f2e6bf"), 1.8, {"softness": 0.0, "core": 0.22, "blink": 0.3, "blink_speed": 4.0}), false]],
		Herd.area_around(_moth_centres, 3.0))
	_moth_focus = Node3D.new()
	_moth_focus.name = "MothFocus"
	add_child(_moth_focus)
	safari.add_subject({
		"id": "glow_moth", "name": "Glow-moths", "kind": "creature",
		"band": BAND_MOTHS, "node": _moth_focus, "radius": 0.8,
		"awake": func() -> bool: return safari.is_night and not _sleeping and _moth_pick >= 0,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 1.8, "line": "dipping to the water"} if _moth_settle(tt) > 0.6 else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _nearest_heading(_moths, _moth_pick, "swarm"),
	})


## 0..1: how far down on the water the swarms are (they settle every MOTH_SETTLE_EVERY s).
func _moth_settle(tt: float) -> float:
	var ph := fmod(tt + 5.0, MOTH_SETTLE_EVERY)
	if ph > MOTH_SETTLE_SEC + 1.2:
		return 0.0
	return clampf(minf(ph / 0.6, (MOTH_SETTLE_SEC + 1.2 - ph) / 0.6), 0.0, 1.0)


func _tick_moths(delta: float) -> void:
	if _moth_herd == null:
		return
	var p := safari.planet
	var settle := _moth_settle(_t)
	# THE SWARMS REST (Zorp's measured rule): once seen and left out of the frame MOTH_LEAVE_SEC, a swarm
	# settles into its pool (only while out of the frame - you never see it go) for MOTH_REST_SEC
	for si in _moth_centres.size():
		var c0: Vector3 = _moth_centres[si]
		if _point_in_frame(c0, 1.1):
			if _t >= float(_moth_rest[si]):
				_moth_seen[si] = _t
		elif float(_moth_seen[si]) > -INF and _t - float(_moth_seen[si]) >= MOTH_LEAVE_SEC and _t >= float(_moth_rest[si]):
			_moth_rest[si] = _t + MOTH_REST_SEC
			_moth_seen[si] = -INF
	for i in _moths.size():
		var m: Dictionary = _moths[i]
		var sw := int(m["swarm"])
		if _t < float(_moth_rest[sw]):
			_moth_herd.hide_one(i)
			continue
		var c: Vector3 = _moth_centres[sw]
		var up := p.up_at(c)
		if _sleeping:
			m["r"] = float(m["r"]) + delta * 1.5
		m["ang"] = float(m["ang"]) + float(m["speed"]) * delta
		var t := _tangent_at(p.dir_of(c))
		var b := up.cross(t)
		var a := float(m["ang"])
		var rr := float(m["r"]) * lerpf(1.0, 0.7, settle)
		var hgt := lerpf(0.25 * sin(_t * 1.7 + float(m["bob"])), -MOTH_ALT + MOTH_DIP, settle)
		var pos := c + (t * cos(a) + b * sin(a)) * rr + up * hgt
		var head := (-t * sin(a) + b * cos(a)) * signf(float(m["speed"]))
		m["pos"] = pos
		m["head"] = head
		if _sleeping and float(m["r"]) > 4.0:
			_moth_herd.hide_one(i)
			continue
		var bas := Basis.looking_at(head, up)
		var flap := 1.0 - 0.35 * absf(sin(_t * 14.0 + float(m["bob"])))
		_moth_herd.pose(i, 0, Transform3D(bas * Basis.from_scale(Vector3(flap, 1.0, 1.0)), pos))
		_moth_herd.pose(i, 1, Transform3D(Basis.IDENTITY, pos))
	# the swarm the scorer would take: nearest the middle of the view that the lens can see (the shared
	# _pick_focus; a plain "nearest the middle" picked a swarm on the far side of the planet)
	var ids: Array = []
	for si in _moth_centres.size():
		if _t >= float(_moth_rest[si]):
			ids.append(si)
	var k := _pick_focus(ids, func(_si: int) -> bool: return true,
		func(si: int) -> Vector3: return _moth_centres[si], 0.0)
	_moth_pick = int(ids[k]) if k >= 0 else -1
	if _moth_pick >= 0:
		var c: Vector3 = _moth_centres[_moth_pick]
		var up := p.up_at(c)
		_moth_focus.global_transform = Transform3D(Basis.looking_at(_tangent_at(p.dir_of(c)), up), c - up * (MOTH_ALT - MOTH_DIP - 0.2) * settle)


## The heading of the member of group `pick` nearest the lens (a swarm's or a flock's front).
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


# ---------------------------------------------------------------------------------------- tower swifts
func _build_swifts() -> void:
	var p := safari.planet
	# place 0: the colonnade's far end (the middle of its stones); places 1-2: pools' spires
	var sum := Vector3.ZERO
	var n := 0
	for nm: String in SWIFT_STONES:
		var st := _stones.get(nm) as Node3D
		if st != null:
			sum += p.dir_of(st.global_position)
			n += 1
	var col_dir := sum.normalized() if n > 0 else safari.dir_from_start(55.0, 150.0)
	# low enough to weave among the columns and spires, with the pan and its horizon behind them rather
	# than the dark sky (the first frames, shots1: dark birds on a dark sky did not read)
	_swift_places.append([col_dir, 2.3])
	for pi: int in SWIFT_POOLS:
		_swift_places.append([_pool_dir(pi), 1.8])
	for k in SWIFT_N:
		_swifts.append({"ang": TAU * float(k) / float(SWIFT_N) + _rng.randf_range(-0.2, 0.2),
			"r_off": _rng.randf_range(-0.5, 0.5), "h_off": _rng.randf_range(-0.4, 0.4),
			"phase": _rng.randf_range(0.0, TAU), "pos": Vector3.ZERO, "head": Vector3.FORWARD, "spd": _rng.randf_range(0.9, 1.15)})
	_swift_herd = Herd.new()
	add_child(_swift_herd)
	var r := p.radius + 10.0
	_swift_herd.setup("TowerSwifts", SWIFT_N, [[Meshes.swift(), _prop, true]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	for i in SWIFT_N:
		_swift_herd.hide_one(i)
	_swift_focus = Node3D.new()
	_swift_focus.name = "SwiftFocus"
	add_child(_swift_focus)
	safari.add_subject({
		"id": "tower_swifts", "name": "Tower Swifts", "kind": "event",
		"band": BAND_SWIFTS, "node": _swift_focus, "radius": 1.6,
		"awake": func() -> bool: return _swift_at >= 0 and _swift_k > 0.6 and _swift_vis > 0.9 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			return {"mult": 2.0, "line": "the whole flock turning together"} if _swift_turning() else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _nearest_heading(_swifts, 0 if _swift_at >= 0 else -1, ""),
	})


func _swift_turning() -> bool:
	var run := _run_at(SWIFT_RUNS, _t, false)
	if run.is_empty():
		return false
	var tin := _t - float(run["start"])
	for s0: float in SWIFT_TURNS:
		if tin >= s0 and tin < s0 + SWIFT_TURN_SEC:
			return true
	return false


func _tick_swifts(delta: float) -> void:
	if _swift_herd == null:
		return
	var p := safari.planet
	var run := _run_at(SWIFT_RUNS, _t, true)
	var want_vis := 0.0
	if not run.is_empty() and not _sleeping:
		_swift_at = int(run["at"])
		want_vis = 1.0
		var tin := _t - float(run["start"])
		_swift_k = move_toward(_swift_k, 1.0 if tin >= 0.0 else 0.0, delta / 3.0)
	elif _swift_at >= 0:
		# leaving: they climb away and thin out
		_swift_k = move_toward(_swift_k, 0.0, delta / SWIFT_LEAVE_SEC)
	_swift_vis = move_toward(_swift_vis, want_vis, delta / (1.2 if want_vis > 0.0 else SWIFT_LEAVE_SEC))
	if _swift_at < 0 or _swift_vis <= 0.0:
		for i in SWIFT_N:
			_swift_herd.hide_one(i)
		if _swift_vis <= 0.0 and run.is_empty():
			_swift_at = -1
		return
	var place: Array = _swift_places[_swift_at]
	var cd: Vector3 = place[0]
	var g := p.surface_point(cd)
	var up := p.up_at(g)
	var t := _tangent_at(cd)
	var b := up.cross(t)
	var turning := _swift_turning()
	var hgt := lerpf(SWIFT_HIGH, float(place[1]), _swift_k)
	var rad := lerpf(SWIFT_RADIUS * 1.8, SWIFT_RADIUS, _swift_k)
	for i in SWIFT_N:
		var s: Dictionary = _swifts[i]
		var spd := SWIFT_SPEED * float(s["spd"]) * (1.35 if turning else 1.0)
		s["ang"] = float(s["ang"]) + spd * delta
		var a := float(s["ang"])
		# turning, the flock bunches up and banks low together
		var rr := rad + float(s["r_off"]) * (0.3 if turning else 1.0) + 0.3 * sin(a * 2.0 + float(s["phase"]))
		var hh := hgt + float(s["h_off"]) * (0.3 if turning else 1.0) + 0.25 * sin(a * 3.0 + float(s["phase"])) - (0.6 if turning else 0.0)
		var pos := g + (t * cos(a) + b * sin(a)) * rr + up * hh
		var head := (-t * sin(a) + b * cos(a)).normalized()
		s["pos"] = pos
		s["head"] = head
		var bank := (0.7 if turning else 0.35)
		var bas := Basis.looking_at(head, up.rotated(head, -bank))
		var beat := 1.0 - 0.3 * absf(sin(_t * 11.0 + float(s["phase"])))
		var sc := _swift_vis * 1.15
		_swift_herd.pose(i, 0, Transform3D(bas * Basis.from_scale(Vector3(beat * sc, sc, sc)), pos))
	_swift_focus.global_transform = Transform3D(Basis.looking_at(t, up), g + up * hgt)
	# chirps near the flock
	_chirp_clock -= delta
	if _chirp_clock <= 0.0 and _swift_vis > 0.5:
		_chirp_clock = _rng.randf_range(0.6, 1.4)
		AudioManager.play_sfx_at("doot_c_3", g + up * hgt, -14.0, 0.25)


# ---------------------------------------------------------------------------------------- pool ripple
const FISH_N := 4
const FISH_LEAP_SEC := 0.9
## The pool's water lies ~0.35 m under the pan (fen.tres water_level) inside a raised rim, so from a few
## metres off only what rises over the rim is seen: the fish leap this high.
const FISH_LEAP_H := 1.0
const FISH_EVERY := 1.3


func _build_ripple() -> void:
	var p := safari.planet
	_ripple_root = Node3D.new()
	_ripple_root.name = "Ripple"
	add_child(_ripple_root)
	_ripple_glow = _glow_quad("RippleGlow", Color("#bfe3d8"), Vector2(3.6, 3.0))
	_ripple_root.add_child(_ripple_glow)
	var pts: Array = []
	for pi: int in RIPPLE_POOLS:
		pts.append(_water_point(pi))
	var area := Herd.area_around(pts, 3.5)
	_ring_herd = Herd.new()
	add_child(_ring_herd)
	_ring_herd.setup("RippleRings", 3, [[Meshes.ripple_ring(), _sheet_mat, false]], area)
	_fish_herd = Herd.new()
	add_child(_fish_herd)
	_fish_herd.setup("PoolFish", FISH_N, [[Meshes.fish(), _prop, false]], area)
	for k in FISH_N:
		_fish.append({"start": -99.0, "ang": 0.0, "span": 0.9})
		_fish_herd.hide_one(k)
	for k in 3:
		_ring_herd.hide_one(k)
	_bubbles = CPUParticles3D.new()
	_bubbles.name = "RippleBubbles"
	_bubbles.amount = 22
	_bubbles.lifetime = 1.6
	_bubbles.local_coords = true
	_bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_bubbles.emission_sphere_radius = 1.2
	_bubbles.direction = Vector3.UP
	_bubbles.spread = 15.0
	_bubbles.gravity = Vector3.ZERO
	_bubbles.initial_velocity_min = 0.35
	_bubbles.initial_velocity_max = 0.8
	_bubbles.scale_amount_min = 0.5
	_bubbles.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	q.material = PlanetPropMeshes.sparkle_material(Color("#dff2ea"))
	_bubbles.mesh = q
	_bubbles.emitting = false
	_ripple_root.add_child(_bubbles)
	_ripple_focus = Node3D.new()
	_ripple_focus.name = "RippleFocus"
	add_child(_ripple_focus)
	safari.add_subject({
		"id": "pool_ripple", "name": "Pool Ripple", "kind": "event",
		"band": BAND_RIPPLE, "node": _ripple_focus, "radius": 1.2,
		"awake": func() -> bool: return _any_running(RIPPLE_RUNS) and _ripple_at >= 0 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(RIPPLE_RUNS, _t, false)
			if not run.is_empty():
				var tin := _t - float(run["start"])
				if tin >= RIPPLE_ALL_AT and tin < RIPPLE_ALL_AT + RIPPLE_ALL_SEC:
					return {"mult": 2.2, "line": "every fish leaping at once"}
			if _fish_up():
				return {"mult": 1.6, "line": "a fish mid-leap"}
			return {"mult": 1.0, "line": ""},
	})


func _fish_up() -> bool:
	for f: Dictionary in _fish:
		var k := (_t - float(f["start"])) / FISH_LEAP_SEC
		if k > 0.2 and k < 0.8:
			return true
	return false


func _tick_ripple(delta: float) -> void:
	if _ripple_root == null:
		return
	var p := safari.planet
	var run := _run_at(RIPPLE_RUNS, _t, true)
	var want := 0.0
	if not run.is_empty() and not _sleeping:
		var at := int(run["at"])
		if at != _ripple_at:
			_ripple_at = at
			var pi: int = RIPPLE_POOLS[at]
			var wp := _water_point(pi, 0.02)
			var up := p.up_at(wp)
			_ripple_root.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, up)), wp)
			_ripple_focus.global_transform = Transform3D(Basis.looking_at(_tangent_at(p.dir_of(wp)), up), wp + up * 0.75)
			_ripple_glow.position = Vector3(0.0, 0.7, 0.0)
		var tin := _t - float(run["start"])
		want = 0.45 if tin < 0.0 else 1.0
		_bubbles.emitting = true
		if tin >= 0.0:
			_tick_fish(run, tin)
	else:
		_bubbles.emitting = false
	_ripple_level = move_toward(_ripple_level, want, delta / 1.2)
	_ripple_glow.visible = _ripple_level > 0.01
	(_ripple_glow.material_override as ShaderMaterial).set_shader_parameter("fade", _ripple_level * (0.55 + 0.15 * sin(_t * 2.2)))
	# the rings: three expanding from the middle, one after another
	var run_on := not run.is_empty() and _t >= float(run["start"]) and not _sleeping
	for k in 3:
		if not run_on or _ripple_at < 0:
			_ring_herd.hide_one(k)
			continue
		var ph := fmod(_t * 0.5 + float(k) / 3.0, 1.0)
		var wp := _ripple_root.global_position
		var up := p.up_at(wp)
		var r := lerpf(0.2, 1.6, ph)
		var bas := Basis(Quaternion(Vector3.UP, up)) * Basis.from_scale(Vector3(r, 1.0, r))
		_ring_herd.pose(k, 0, Transform3D(bas, wp + up * 0.02))
	if not run_on:
		for k in FISH_N:
			_fish_herd.hide_one(k)


func _tick_fish(run: Dictionary, tin: float) -> void:
	var p := safari.planet
	var all_leap := tin >= RIPPLE_ALL_AT and tin < RIPPLE_ALL_AT + RIPPLE_ALL_SEC
	var pi: int = RIPPLE_POOLS[int(run["at"])]
	var shore := float(_pools[pi]["shore_m"])
	for k in FISH_N:
		var f: Dictionary = _fish[k]
		var age := _t - float(f["start"])
		if age > FISH_LEAP_SEC:
			var due := fmod(tin + float(k) * FISH_EVERY / float(FISH_N), FISH_EVERY) < 0.05
			if due or (all_leap and age > FISH_LEAP_SEC + 0.1):
				f["start"] = _t
				f["ang"] = _rng.randf_range(0.0, TAU)
				f["span"] = _rng.randf_range(0.5, minf(1.1, shore * 0.8))
				age = 0.0
		if age > FISH_LEAP_SEC:
			_fish_herd.hide_one(k)
			continue
		var kk := clampf(age / FISH_LEAP_SEC, 0.0, 1.0)
		var c := _pool_dir(pi)
		var t := _tangent_at(c).rotated(c, float(f["ang"]))
		var wp := _water_point(pi)
		var up := p.up_at(wp)
		var span := float(f["span"])
		var along := lerpf(-span * 0.5, span * 0.5, kk)
		var pos := wp + t * along + up * (FISH_LEAP_H * 4.0 * kk * (1.0 - kk) - 0.05)
		var vel := t * span - up * (FISH_LEAP_H * 4.0 * (2.0 * kk - 1.0))
		var bas := Basis.looking_at(vel.normalized(), up if absf(vel.normalized().dot(up)) < 0.98 else t)
		_fish_herd.pose(k, 0, Transform3D(bas * Basis.from_scale(Vector3.ONE * 1.6), pos))
		if age < 0.02 or absf(kk - 1.0) < 0.03:
			if _point_in_frame(pos, 1.2) and pos.distance_to(safari.player.global_position) < 12.0:
				AudioManager.play_sfx_at("splash", pos, -16.0, 0.3)


# ---------------------------------------------------------------------------------------- Fen's vine
const FLOWER_AT := [1, 3, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 23]
## Flowers are drawn this much bigger than the mesh (0.3 m across open): at 7 m a 12 cm flower was a
## dot (shots1).
const FLOWER_SCALE := 1.7


func _build_vine() -> void:
	var p := safari.planet
	if _arch == null:
		return
	_vine = MeshInstance3D.new()
	_vine.name = "FenVine"
	_vine.mesh = Meshes.vine()
	_vine.material_override = _prop
	add_child(_vine)
	_vine.global_transform = _arch_xf
	var path := Meshes.vine_path()
	var area := Herd.area_around([_arch_xf.origin], 5.0)
	for v in 2:
		var h := Herd.new()
		add_child(h)
		var n := 0
		for k in FLOWER_AT.size():
			if k % 2 == v:
				n += 1
		h.setup("VineFlowers%d" % v, n, [[Meshes.flower(v), _prop, false]], area)
		_flower_herds.append(h)
	var counts := [0, 0]
	for k in FLOWER_AT.size():
		var idx: int = mini(FLOWER_AT[k], path.size() - 1)
		var pt: Vector3 = path[idx]
		# each flower faces out of the arch's face it grows on (+Z or -Z), tipped a little up
		var side := 1.0 if pt.z >= 0.0 else -1.0
		var face_axis := Vector3(0.0, 0.25, side).normalized()
		var bas := Basis(Quaternion(Vector3.UP, face_axis))
		var v := k % 2
		_flowers.append({"xf": Transform3D(bas, pt + Vector3(0.0, 0.0, side * 0.04)), "herd": v, "i": counts[v],
			"phase": _rng.randf_range(0.0, TAU)})
		counts[v] += 1
	_petals = CPUParticles3D.new()
	_petals.name = "VinePetals"
	_petals.amount = 16
	_petals.lifetime = 3.0
	# local: its frame is the arch's, whose +Y is the planet's up there (a CPUParticles3D with world
	# coordinates reads its global transform when the warm-up copies it outside the tree)
	_petals.local_coords = true
	_petals.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_petals.emission_box_extents = Vector3(1.0, 0.3, 0.3) * _arch_xf.basis.get_scale().x
	_petals.direction = Vector3.ZERO
	_petals.spread = 180.0
	_petals.gravity = Vector3(0.0, -0.25, 0.0)
	_petals.initial_velocity_min = 0.05
	_petals.initial_velocity_max = 0.2
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = PlanetPropMeshes.sparkle_material(Color("#e8cdb8"))
	_petals.mesh = q
	_petals.emitting = false
	add_child(_petals)
	_petals.global_transform = Transform3D(_arch_xf.basis.orthonormalized(), _arch_xf * Vector3(0.0, 3.0, 0.0))
	_bloom_focus = Node3D.new()
	_bloom_focus.name = "BloomFocus"
	add_child(_bloom_focus)
	var up := p.up_at(_arch_xf.origin)
	_bloom_focus.global_transform = Transform3D(Basis.looking_at(_arch_xf.basis.z.normalized(), up), _arch_xf * Vector3(0.0, 2.3, 0.0))
	safari.add_subject({
		"id": "vine_bloom", "name": "Fen's Vine in Bloom", "kind": "event",
		"band": BAND_BLOOM, "node": _bloom_focus, "radius": 1.6,
		"awake": func() -> bool: return _any_running(BLOOM_RUNS) and _bloom_open > 0.5 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(BLOOM_RUNS, _t, false)
			if not run.is_empty():
				var tin := _t - float(run["start"])
				if tin >= BLOOM_FULL.x and tin < BLOOM_FULL.y:
					return {"mult": 2.0, "line": "in full bloom"}
			return {"mult": 1.0, "line": ""},
	})
	_pose_flowers()


func _tick_vine(delta: float) -> void:
	if _vine == null:
		return
	var run := _run_at(BLOOM_RUNS, _t, true)
	var want_open := 0.0
	var want_glint := 0.0
	if not run.is_empty() and not _sleeping:
		var tin := _t - float(run["start"])
		want_glint = 1.0 if tin < 0.0 else 0.0
		if tin >= 0.0:
			want_open = 1.0 if tin < float(run["end"]) - float(run["start"]) - 1.5 else 0.0
		_petals.emitting = tin >= BLOOM_FULL.x - 1.0 and tin < BLOOM_FULL.y
	else:
		_petals.emitting = false
	_bloom_open = move_toward(_bloom_open, want_open, delta / BLOOM_OPEN_SEC)
	_bloom_glint = move_toward(_bloom_glint, want_glint, delta / 1.0)
	_pose_flowers()


func _pose_flowers() -> void:
	for f: Dictionary in _flowers:
		var h: Herd = _flower_herds[int(f["herd"])]
		var o := smoothstep(0.0, 1.0, clampf(_bloom_open * 1.25 - 0.25 * sin(float(f["phase"])) * 0.4, 0.0, 1.0))
		# a closed bud: small and tall; swelling (the warning): a little bigger, pulsing
		var swell := 1.0 + 0.25 * _bloom_glint * (0.5 + 0.5 * sin(_t * 4.0 + float(f["phase"])))
		var sx := lerpf(0.32, 1.0, o) * swell
		var sy := lerpf(1.6, 1.0, o) * lerpf(0.4, 1.0, o) * swell
		var sway := 0.12 * sin(_t * 1.3 + float(f["phase"])) * o
		var loc: Transform3D = f["xf"]
		loc.basis = loc.basis * Basis(Vector3.FORWARD, sway) * Basis.from_scale(Vector3(sx, maxf(sy, 0.3), sx) * FLOWER_SCALE)
		h.pose(int(f["i"]), 0, _arch_xf * loc)


# ---------------------------------------------------------------------------------------- the arch light
func _build_arch_light() -> void:
	var p := safari.planet
	if _arch == null:
		return
	_arch_root = Node3D.new()
	_arch_root.name = "ArchLight"
	add_child(_arch_root)
	var up := p.up_at(_arch_xf.origin)
	# which way the beam runs: along the arch's own axis (so it always passes through the opening), from
	# the pad's side DOWN THE AVENUE between the colonnade's stones - "a golden beam across the ruins".
	# SAID PLAINLY: the sky's real sun is not moved; this light is laid along the arch, not along the
	# sun's azimuth at that hour (the probe logs the angle between them).
	var axis := _arch_xf.basis.z.normalized()
	axis = (axis - up * axis.dot(up)).normalized()
	var to_pad := p.surface_point(_pad_dir) - _arch_xf.origin
	_beam_dir = -axis if to_pad.dot(axis) > 0.0 else axis
	var env := safari.world.get_node_or_null("Environment") if safari.world != null else null
	if env != null and env.has_method("get_sun_direction"):
		var sun: Vector3 = env.call("get_sun_direction")
		var sh := sun - up * sun.dot(up)
		if sh.length() > 0.01:
			_log("arch light: beam runs %.0f deg off the way the sun's light runs now" % rad_to_deg((-sh.normalized()).angle_to(_beam_dir)))
	_arch_sheet = MeshInstance3D.new()
	_arch_sheet.name = "ArchSheet"
	_arch_sheet.mesh = Meshes.arch_sheet(Color("#f3c98a"))
	# the arch light's own copy of the shipped puff material (the same shader), so it can fade
	_arch_mat = (_sheet_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	_arch_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	_arch_sheet.material_override = _arch_mat
	_arch_sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arch_root.add_child(_arch_sheet)
	_arch_sheet.global_transform = _arch_xf
	_arch_sheet.visible = false
	_arch_glow = _glow_quad("ArchGlow", Color("#f6d39a"), Vector2(3.4, 3.4))
	_arch_root.add_child(_arch_glow)
	_arch_glow.global_position = _arch_xf * Vector3(0.0, 2.0, 0.0) - _beam_dir * 0.5
	_beam = MeshInstance3D.new()
	_beam.name = "ArchBeam"
	_beam.mesh = _beam_strip()
	_beam.material_override = _arch_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arch_root.add_child(_beam)
	_beam.visible = false
	_motes = CPUParticles3D.new()
	_motes.name = "ArchMotes"
	_motes.amount = 40
	_motes.lifetime = 4.0
	_motes.local_coords = true
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(0.9, 1.4, 4.0)
	_motes.direction = Vector3.UP
	_motes.spread = 60.0
	_motes.gravity = Vector3.ZERO
	_motes.initial_velocity_min = 0.03
	_motes.initial_velocity_max = 0.12
	_motes.scale_amount_min = 0.6
	_motes.scale_amount_max = 1.4
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	q.material = PlanetPropMeshes.sparkle_material(Color("#f6dcaa"))
	_motes.mesh = q
	_motes.emitting = false
	_arch_root.add_child(_motes)
	var mid := _arch_xf.origin + _beam_dir * 3.2 + up * 1.4
	_motes.global_transform = Transform3D(Basis.looking_at(-_beam_dir, up), mid)
	_arch_focus = Node3D.new()
	_arch_focus.name = "ArchFocus"
	add_child(_arch_focus)
	_arch_focus.global_transform = Transform3D(Basis.looking_at(-_beam_dir, up), _arch_xf * Vector3(0.0, 1.7, 0.0))
	safari.add_subject({
		"id": "arch_light", "name": "The Arch Light", "kind": "rare",
		"band": BAND_ARCH, "node": _arch_focus, "radius": 1.8,
		"awake": func() -> bool: return safari.event_running("arch_light") and _arch_level > 0.5 and not _sleeping,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 2.2, "line": "the beam at its brightest"} if tt >= ARCH_GOLD.x and tt < ARCH_GOLD.y else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _beam_dir,
	})


## The lit strip on the ground: from the arch's foot out along the beam, 9 m, as wide as the opening,
## laid on the ground a few centimetres up (world space), soft at the edges and fading out at the end.
func _beam_strip() -> ArrayMesh:
	var p := safari.planet
	var up0 := p.up_at(_arch_xf.origin)
	var side := up0.cross(_beam_dir).normalized()
	var half := 0.95 * _arch_xf.basis.get_scale().x * 0.72
	var grid: Array = []
	var steps := 18
	var length := 9.0
	for k in steps + 1:
		var m := -1.0 + (length + 1.0) * float(k) / float(steps)
		var row: Array = []
		for s in 5:
			var off := lerpf(-half * 1.3, half * 1.3, float(s) / 4.0)
			var guess := _arch_xf.origin + _beam_dir * m + side * off
			var d := p.dir_of(guess)
			var g := p.surface_point(d) + p.up_at(p.surface_point(d)) * 0.05
			if p.is_underwater(d):
				g = p.global_position + d * (_water_r + 0.03)
			var edge := 1.0 - absf(float(s) - 2.0) / 2.0
			var along := clampf((m + 1.0) / 1.2, 0.0, 1.0) * clampf((length - m) / 4.0, 0.0, 1.0)
			row.append([g, Color(0.98, 0.82, 0.55, 0.42 * edge * along)])
		grid.append(row)
	return Meshes.sheet_from_grid(grid)


func _tick_arch(delta: float) -> void:
	if _arch_root == null:
		return
	var want := 0.0
	var warned := bool(_eligible.get("arch_light", false)) and _t >= ARCH_START - WARN and _t < ARCH_END and not _sleeping
	if warned:
		if _t < ARCH_START:
			want = 0.3 * clampf((_t - (ARCH_START - WARN)) / WARN, 0.0, 1.0)
		elif _t >= ARCH_GOLD.x and _t < ARCH_GOLD.y:
			want = 1.0
		else:
			want = 0.75
	_arch_level = move_toward(_arch_level, want, delta / 1.5)
	_motes.emitting = warned
	var on := _arch_level > 0.01
	_arch_sheet.visible = on
	_beam.visible = on and _t >= ARCH_START - 1.0
	_arch_glow.visible = on
	(_arch_glow.material_override as ShaderMaterial).set_shader_parameter("fade", _arch_level * (0.8 + 0.2 * sin(_t * 1.7)))
	_arch_mat.albedo_color = Color(1.0, 1.0, 1.0, clampf(_arch_level, 0.0, 1.0))


# ---------------------------------------------------------------------------------------- the stone heron
func _build_heron() -> void:
	var p := safari.planet
	if HERON_POOL >= _pools.size():
		return
	_heron_root = Node3D.new()
	_heron_root.name = "StoneHeron"
	add_child(_heron_root)
	_heron_body = MeshInstance3D.new()
	_heron_body.name = "Body"
	_heron_body.mesh = Meshes.heron_body()
	_heron_body.material_override = _prop
	_heron_root.add_child(_heron_body)
	for sgn in [1.0, -1.0]:
		var w := MeshInstance3D.new()
		w.name = "Wing%s" % ("R" if sgn > 0.0 else "L")
		w.mesh = Meshes.heron_wing(sgn)
		w.material_override = _prop
		_heron_root.add_child(w)
		_heron_wings.append(w)
	_heron_root.visible = false
	# where it stands: in the shallows of the biggest pool, on the side toward the start
	var c := _pool_dir(HERON_POOL)
	var shore := float(_pools[HERON_POOL]["shore_m"])
	var toward := _toward(c, safari.start_dir)
	var stand := _polar(c, toward, rad_to_deg(maxf(shore - 0.55, 0.2) / p.radius), 25.0)
	_heron_pos = p.global_position + stand * _water_r
	_heron_face = _toward(stand, safari.start_dir).rotated(stand, 0.9)
	_heron_focus = Node3D.new()
	_heron_focus.name = "HeronFocus"
	add_child(_heron_focus)
	safari.add_subject({
		"id": "stone_heron", "name": "The Stone Heron", "kind": "rare",
		"band": BAND_HERON, "node": _heron_focus, "offset": Vector3(0.0, 0.95, 0.0), "radius": 0.7,
		"awake": func() -> bool: return safari.event_running("stone_heron") and _heron_shown and not _sleeping,
		"moment": func(tt: float) -> Dictionary:
			if tt >= HERON_LAND.x and tt < HERON_LAND.y:
				return {"mult": 2.0, "line": "landing, wings wide"}
			if tt >= HERON_STRETCH.x and tt < HERON_STRETCH.y:
				return {"mult": 2.2, "line": "spreading its wings"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_heron_focus),
	})


func _tick_heron(delta: float) -> void:
	if _heron_root == null:
		return
	var p := safari.planet
	var up := p.up_at(_heron_pos)
	var on := bool(_eligible.get("stone_heron", false)) and _t >= HERON_START - WARN and _t < HERON_END + 3.0 and not _sleeping
	_heron_root.visible = on
	_heron_shown = on
	if not on:
		return
	var pos := _heron_pos
	var face := _heron_face
	var spread := 0.0
	# flying, it lies forward (neck out, legs trailing) instead of standing upright in the air
	var fly := 0.0
	var t_in := _t - HERON_START
	var c := _water_point(HERON_POOL)
	var t0 := _tangent_at(p.dir_of(c))
	var b0 := up.cross(t0)
	if t_in < 0.0:
		# THE WARNING: it circles high over its pool, wings wide, and comes lower as it nears
		var a := _t * 0.55
		var h := lerpf(9.0, 5.0, clampf((t_in + WARN) / WARN, 0.0, 1.0))
		pos = c + (t0 * cos(a) + b0 * sin(a)) * 4.0 + up * h
		face = (-t0 * sin(a) + b0 * cos(a)).normalized()
		spread = 1.0
		fly = 1.0
	elif t_in < 3.0:
		# gliding down onto its spot
		var k := t_in / 3.0
		var a := (HERON_START) * 0.55
		var from := c + (t0 * cos(a) + b0 * sin(a)) * 4.0 + up * 5.0
		pos = from.lerp(_heron_pos, smoothstep(0.0, 1.0, k))
		var fl := _heron_pos - from
		fl -= up * fl.dot(up)
		face = fl.normalized() if fl.length() > 0.01 else _heron_face
		face = face.slerp(_heron_face, smoothstep(0.6, 1.0, k))
		spread = 1.0 - smoothstep(0.75, 1.0, k) * 0.2
		fly = 1.0 - smoothstep(0.5, 0.95, k)
	elif _t < HERON_END:
		# standing in the shallows: a slow stalk, a look round, and one great stretch of the wings
		var k := t_in - 3.0
		face = _heron_face.rotated(up, 0.5 * sin(k * 0.35))
		pos = _heron_pos + face * 0.12 * sin(k * 0.25)
		if t_in < 4.0:
			spread = 1.0 - (t_in - 3.0)
		if _t >= HERON_STRETCH.x - 0.6 and _t < HERON_STRETCH.y + 0.6:
			spread = clampf(minf(_t - (HERON_STRETCH.x - 0.6), HERON_STRETCH.y + 0.6 - _t) / 0.6, 0.0, 1.0)
	else:
		# away: wings wide, up and off over the pan
		var k := (_t - HERON_END) / 3.0
		spread = 1.0
		fly = smoothstep(0.0, 0.4, k)
		pos = _heron_pos + (_heron_face * 5.0 + up * 6.0) * k * k
		face = _heron_face
		if k >= 0.99:
			_heron_root.visible = false
	var bas := Basis.looking_at(face, up) * Basis(Vector3.RIGHT, -1.15 * fly)
	_heron_root.global_transform = Transform3D(bas, pos)
	_heron_focus.global_transform = Transform3D(bas, pos)
	_heron_spread = spread
	var flap := 0.0
	if t_in < 3.0 or _t >= HERON_END:
		flap = 0.35 * sin(_t * 5.0)
	for wi in 2:
		var sgn := 1.0 if wi == 0 else -1.0
		var fold := Basis(Vector3.UP, -sgn * PI * 0.5 * (1.0 - spread))
		var lift := Basis(Vector3.FORWARD, sgn * (0.25 * spread + flap * spread))
		var sc := Basis.from_scale(Vector3(lerpf(0.55, 1.0, spread), 1.0, 1.0))
		_heron_wings[wi].transform = Transform3D(fold * lift * sc, Vector3(Meshes.HERON_SHOULDER.x * sgn,
			Meshes.HERON_SHOULDER.y, Meshes.HERON_SHOULDER.z))
	# stepping into the water: a ring of splash where it lands
	if t_in >= 2.9 and t_in < 2.9 + delta * 1.5:
		safari.puff_at(_heron_pos, 14, Color("#cfe0dd"))
		AudioManager.play_sfx_at("splash", _heron_pos, -6.0, 0.1)


# ---------------------------------------------------------------------------------------- Fen
func _build_fen() -> void:
	_fen = safari.world.get_node_or_null("NPCs/fen") as Node3D if safari.world != null else null
	if _fen == null and safari.world != null:
		for n in safari.world.find_children("*", "", true, false):
			if str(n.get("npc_id")) == "fen":
				_fen = n as Node3D
				break
	if _fen == null:
		return
	_fen_saved = _fen.global_transform
	_fen_wander_saved = bool(_fen.get("_wander_on")) if _fen.get("_wander_on") != null else true
	safari.add_subject({
		"id": "fen", "name": "Fen", "kind": "neighbour",
		"band": BAND_FEN, "node": _fen, "offset": Vector3(0.0, 0.75, 0.0), "radius": 0.7,
		"awake": func() -> bool: return is_instance_valid(_fen) and _fen.is_visible_in_tree(),
		"moment": func(_tt: float) -> Dictionary:
			if _t < _fen_note_until:
				return {"mult": 1.8, "line": "writing you into the logbook"}
			if _t < _fen_wave_until:
				return {"mult": 1.6, "line": "waving at you"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_fen),
	})


func _tick_fen(_delta: float) -> void:
	if _fen == null or not is_instance_valid(_fen) or _sleeping or _building:
		return
	if _fen_stay_until > -INF and _t >= _fen_stay_until:
		_fen_stay_until = -INF
		if _fen.has_method("wander_enabled"):
			_fen.call("wander_enabled", _fen_wander_saved)
	var pl := safari.player
	var dist := _fen.global_position.distance_to(pl.global_position)
	if dist < 3.6 and _t >= _fen_next_wave:
		_fen.call("face_player", true)
		_fen.call("play_emote", "wave")
		_fen_wave_until = _t + 1.6
		_fen_next_wave = _t + 12.0
	# he writes you into his logbook for a camera held still on him
	if _still >= STILL_SEC and dist < 7.0 and _t >= _fen_next_note:
		var cam := safari.rig.get_view_camera()
		if cam != null:
			var to := (_fen.global_position + safari.planet.up_at(_fen.global_position) * 0.75 - cam.global_position).normalized()
			if to.dot(-cam.global_transform.basis.z) > cos(deg_to_rad(10.0)):
				_fen.call("face_player", true)
				_fen.call("play_emote", "think")
				_fen_note_until = _t + 2.0
				_fen_next_note = _t + 7.0
				_fen_next_wave = maxf(_fen_next_wave, _t + 3.0)


## THE PACING DIRECTOR brings FEN: when it has gone quiet he comes over, with a puff of salt dust, to see
## what you are photographing, stays FEN_STAY_SEC turned to you, then wanders on. Not when he is near
## you or in view already, and not twice within FEN_COME_REST s.
const FEN_COME_REST := 25.0
const FEN_RISE_MAX := 1.7
const FEN_STAY_SEC := 10.0
const FEN_COME_LINES := ["Fen: \"What are we looking at. I will note it.\"", "Fen: \"Walk slow. I am coming.\"",
	"Fen: \"You look busy. Good. Busy is good.\""]


func _fen_can_come() -> bool:
	if _fen == null or not is_instance_valid(_fen) or _sleeping:
		return false
	if _t - _fen_came_at < FEN_COME_REST:
		return false
	var head := _fen.global_position + safari.planet.up_at(_fen.global_position) * 0.75
	return _fen.global_position.distance_to(safari.player.global_position) > 8.0 and not _point_in_frame(head, 1.1)


func _bring_fen(spot: Dictionary) -> bool:
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO and spot["ahead"] != Vector3.ZERO and float(spot["rise"]) >= 0.0 and float(spot["rise"]) <= FEN_RISE_MAX:
		d = spot["ahead"]
	if d == Vector3.ZERO or not _fen_can_come() or safari.planet.is_underwater(d):
		return false
	var p := safari.planet
	safari.puff_at(_fen.global_position, 14, DUST)
	var g := p.surface_point(d)
	var up := p.up_at(g)
	var lens: Transform3D = spot["lens"]
	# he looks where you are looking (he came to see what it is), not at you; he turns to you for a
	# camera held still on him (_tick_fen)
	var face := -lens.basis.z
	face -= up * face.dot(up)
	if face.length() < 0.01:
		face = _tangent_at(d)
	face = face.normalized().rotated(up, _rng.randf_range(-0.5, 0.5))
	_fen.global_transform = Transform3D(Basis.looking_at(face, up), g)
	if _fen is CharacterBody3D:
		(_fen as CharacterBody3D).velocity = Vector3.ZERO
	_fen_moved = true
	safari.puff_at(g, 18, DUST)
	_fen.call("play_emote", "think")
	_fen_next_wave = _t + 8.0
	AudioManager.play_sfx_at("emote_wave", g, -4.0, 0.1)
	_queue_line(FEN_COME_LINES[_fen_came_n % FEN_COME_LINES.size()])
	_fen_came_n += 1
	_fen_came_at = _t
	_fen_stay_until = _t + FEN_STAY_SEC
	if _fen.has_method("wander_enabled"):
		_fen.call("wander_enabled", false)
	return true


## Gives Fen back to his own script. `home` also puts him back where he stood before the safari.
func _release_fen(home: bool) -> void:
	if _fen == null or not is_instance_valid(_fen):
		return
	if _fen.has_method("wander_enabled"):
		_fen.call("wander_enabled", _fen_wander_saved)
	_fen_stay_until = -INF
	if home:
		_fen.global_transform = _fen_saved
		if _fen is CharacterBody3D:
			(_fen as CharacterBody3D).velocity = Vector3.ZERO


# ======================================================================================== SIGHTS AND BONUS (15.5)
## THE SIGHTS are Fen's own props, named: a focus node on each and nothing drawn, so they cost nothing on
## the phone. Their SIZE BANDS are for framing the whole thing with the wide lens from where a person
## stands to look at it - the arch from 5-8 m, the heart of the colonnade from about 6-10 m - and a stone
## has no face, so neither has a Facing score. Rarity 1 (TIER_RARITY "sight"); they pay as usual.
const BAND_OLD_ARCH := Vector2(0.50, 0.90)
const BAND_COLONNADE := Vector2(0.55, 1.00)
## The colonnade's subject is its FAR ROW (the seven stones stand in two rows, 1-3-5 and 0-2-4-6, 8 m
## apart, with the arch and the rocket pad's FLY sign in the gap between them, so no spot sees them all):
## a sphere this big round the middle of these stones, this high - on stone 2, with 0 and 4 2.5 m either
## side, so a photo centred on it centres a column. Why these three: aimed at a column from 4 m and 7 m on
## 8 bearings (critic probe, 2026-09-26), 0, 2 and 4 named The Colonnade from 36 of 36 stands. The old
## point, the middle of the four stones over 5 m from the arch (0, 1, 2, 6), fell in the gap between the
## rows, and the best Colonnade photo from 8 m centred the FLY sign's post with the arch beside it.
const COLONNADE_STONES := ["StandingStone0", "StandingStone2", "StandingStone4"]
const COLONNADE_R := 2.6
const COLONNADE_LIFT := 1.4
## THE BONUS PAGES: small, still and tucked away (a curious wanderer finds them by walking up to a column
## or a pool). Bands from the header's formula at the distance a finder stands (2.5-3 m): at 45 degrees
## from there each scores about 6 on size; walking up or zooming fills it.
##   subject          radius  usual d  band
##   the carved fish  0.17     2.5 m   0.28-0.47
##   the frog statue  0.22     3.0 m   0.31-0.50
##   the bottle       0.15     2.5 m   0.25-0.41
const BAND_CARVING := Vector2(0.28, 0.47)
const BAND_STATUE := Vector2(0.31, 0.50)
const BAND_BOTTLE := Vector2(0.25, 0.41)
## The fish is carved into the BACK (the side away from the avenue) of the first of these stones that
## stands - none of them the lizards' (StandingStone5, 3) or the swifts' (0, 2, 4) - this high up its face.
const CARVING_STONES := ["StandingStone6", "StandingStone1", "StandingStone4", "StandingStone0"]
const CARVING_Y := 0.78
## Where the carving is SCORED, in its own frame (-Z = out of the stone): the standing stone's collider is a
## 0.42 m cylinder round its middle (planet_props.gd `_spawn_blocking`, col_radius 0.42) and the stone is
## only 0.24 m thick, so the face the fish is cut into lies INSIDE the collider and every sight ray to it
## would stop on the cylinder first (measured: seen from 0 of 67 stands). The scored sphere is pushed out
## along the face's normal until its front is clear of the cylinder: centre 0.12 + 0.33 = 0.45 m from the
## stone's axis, radius 0.17, so its near side is 0.62 m out. Head-on (where Facing is 10) this moves the
## point along the line of sight only.
const CARVING_SUBJECT_AT := Vector3(0.02, 0.0, -0.33)
## The frog statue sits on pool THIRTEEN's rim (a pool nothing else uses), tucked beside one of its spires.
const STATUE_POOL := 12
## The bottle bobs in pool SEVEN (the moths' at night; nothing by day), this far in from the water's edge.
const BOTTLE_POOL := 6
const BOTTLE_IN_M := 0.5
const BOTTLE_DRIFT_M := 0.12
const BOTTLE_DRIFT_SEC := 24.0

var _sight_nodes: Array = []
var _carving: MeshInstance3D
var _statue: MeshInstance3D
var _bottle_root: Node3D
var _bottle_anchor := Vector3.UP   # the bottle's spot on the water (a unit direction)
var _bottle_t0 := Vector3.FORWARD  # a tangent there, for its slow drift


func _build_sights() -> void:
	var p := safari.planet
	# THE OLD ARCH: the arch's own mesh, its middle and half its height
	var ac := _arch_xf.origin + p.up_at(_arch_xf.origin) * 1.7
	var ar := 1.7
	var ami: MeshInstance3D = null
	if _arch != null:
		for c in _arch.get_children():
			if c is MeshInstance3D:
				ami = c
				break
	if ami != null and ami.mesh != null:
		var bb := ami.get_aabb()
		ac = ami.global_transform * bb.get_center()
		var sc := ami.global_basis.get_scale()
		ar = 0.5 * maxf(bb.size.y * sc.y, bb.size.x * sc.x)
	var arch_focus := Node3D.new()
	arch_focus.name = "OldArchFocus"
	add_child(arch_focus)
	arch_focus.global_position = ac
	_sight_nodes.append(arch_focus)
	safari.add_subject({
		"id": "old_arch", "name": "The Old Arch", "kind": "sight", "category": "sight",
		"band": BAND_OLD_ARCH, "node": arch_focus, "radius": ar,
		"awake": func() -> bool: return not _sleeping,
	})
	# THE COLONNADE: the middle of its far row, stones 0, 2 and 4 (see COLONNADE_STONES); every stone if
	# fewer than two of them stand
	var sum := Vector3.ZERO
	var used := 0
	var dists: Array = []
	for st: Node3D in _stones.values():
		dists.append("%s %.1f" % [st.name, st.global_position.distance_to(_arch_xf.origin)])
		if COLONNADE_STONES.has(str(st.name)):
			sum += p.dir_of(st.global_position)
			used += 1
	if used < 2:
		sum = Vector3.ZERO
		for st: Node3D in _stones.values():
			sum += p.dir_of(st.global_position)
	var cd := sum.normalized() if sum.length() > 0.001 else safari.dir_from_start(47.0, 119.0)
	var col_focus := Node3D.new()
	col_focus.name = "ColonnadeFocus"
	add_child(col_focus)
	col_focus.global_position = safari.ground_point(cd, COLONNADE_LIFT)
	_sight_nodes.append(col_focus)
	safari.add_subject({
		"id": "colonnade", "name": "The Colonnade", "kind": "sight", "category": "sight",
		"band": BAND_COLONNADE, "node": col_focus, "radius": COLONNADE_R,
		"awake": func() -> bool: return not _sleeping,
	})
	var fly := get_tree().root.find_child("FlySign", true, false) as Node3D
	_log("sights: old arch at %s r %.2f m; colonnade (%d of %d stones) at %s r %.2f m, %.1f m from the arch, %s from the FLY sign; stones to arch: %s" % [
		_pp(p.dir_of(ac)), ar, used, _stones.size(), _pp(cd), COLONNADE_R, col_focus.global_position.distance_to(ac),
		("%.1f m" % col_focus.global_position.distance_to(fly.global_position)) if fly != null else "-", ", ".join(dists)])


func _build_bonus() -> void:
	var p := safari.planet
	# 1. A FISH CARVED IN STONE, on the back of a column
	var stone: Node3D = null
	for nm: String in CARVING_STONES:
		if _stones.has(nm):
			stone = _stones[nm]
			break
	if stone == null and not _stones.is_empty():
		stone = _stones.values()[0]
	_carving = MeshInstance3D.new()
	_carving.name = "CarvedFish"
	_carving.mesh = Meshes.fish_carving()
	# the stone's own rock material (planet_props.gd `_fen`: the standing stones), so it reads as cut stone
	_carving.material_override = PlanetPropMeshes.rock_material()
	add_child(_carving)
	if stone != null:
		var smi: Node3D = stone
		for c in stone.get_children():
			if c is MeshInstance3D:
				smi = c
				break
		var sb := smi.global_basis
		var up := sb.y.normalized()
		var nz := sb.z.normalized()
		# the back: the broad face turned away from the avenue (the line from the pad through the arch)
		var sp := smi.global_position
		var along := (_arch_xf.origin - p.surface_point(_pad_dir)).normalized()
		var side := (sp - _arch_xf.origin)
		side -= along * side.dot(along)
		side -= up * side.dot(up)
		var n := nz if nz.dot(side) >= 0.0 else -nz
		var half_t := 0.12 * sb.z.length()
		var at := sp + up * CARVING_Y + n * (half_t + 0.004)
		# (the stone leans along its broad face, not across it, so the face is where the fish sits)
		_carving.global_transform = Transform3D(Basis.looking_at(n, up), at)
		_log("carved fish on %s's back at %s, facing %s" % [stone.name, _pp(p.dir_of(at)), str(n.snapped(Vector3.ONE * 0.01))])
	else:
		_carving.global_transform = _xf(_free_near(safari.dir_from_start(47.0, 119.0), 0.5), safari.start_fwd).translated_local(Vector3(0.0, CARVING_Y, 0.0))
	safari.add_subject({
		"id": "carved_fish", "name": "A Fish Carved in Stone", "kind": "bonus", "category": "bonus",
		"band": BAND_CARVING, "node": _carving, "offset": CARVING_SUBJECT_AT, "radius": 0.17,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_carving),
	})
	# 2. THE FROG IN A FLOWER CROWN, on pool THIRTEEN's rim beside a spire, looking out over the pan
	_statue = MeshInstance3D.new()
	_statue.name = "FrogStatue"
	_statue.mesh = Meshes.frog_statue()
	_statue.material_override = PlanetPropMeshes.rock_material()
	add_child(_statue)
	var crown := MeshInstance3D.new()
	crown.name = "Crown"
	crown.mesh = Meshes.frog_statue_crown()
	crown.material_override = _prop
	_statue.add_child(crown)
	var sd := safari.dir_from_start(73.0, 163.0)
	if STATUE_POOL < _pools.size():
		var rim := float(_pools[STATUE_POOL]["rim_m"]) - FROG_RIM_IN
		var best := -1.0
		for k in 36:
			var d := _pool_ring(STATUE_POOL, rim, TAU * float(k) / 36.0)
			if p.is_underwater(d):
				continue
			var pd := p.nearest_prop_distance(d)
			# beside a spire (0.45-0.9 m from one), and failing that the spot nearest one that is clear
			var score := 10.0 - absf(pd - 0.6) if pd >= 0.45 else -1.0
			if score > best:
				best = score
				sd = d
	var sface := _toward(sd, sd * 2.0 - _pool_dir(STATUE_POOL))
	_statue.global_transform = _xf_ground(sd, sface)
	safari.add_subject({
		"id": "frog_statue", "name": "The Frog in a Flower Crown", "kind": "bonus", "category": "bonus",
		"band": BAND_STATUE, "node": _statue, "offset": Vector3(0.0, 0.24, 0.0), "radius": 0.22,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_statue),
	})
	_log("frog statue on %s's rim at %s (nearest prop %.2f m)" % [_pool_name(STATUE_POOL), _pp(sd), p.nearest_prop_distance(sd)])
	# 3. A MESSAGE IN A BOTTLE, bobbing near pool SEVEN's edge on the side toward the start
	_bottle_root = Node3D.new()
	_bottle_root.name = "BottleNote"
	add_child(_bottle_root)
	for part: Array in [[Meshes.bottle_note(), _prop], [Meshes.bottle_glass(), _sheet_mat]]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = part[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_bottle_root.add_child(mi)
	var bc := _pool_dir(BOTTLE_POOL)
	var shore := float(_pools[BOTTLE_POOL]["shore_m"]) if BOTTLE_POOL < _pools.size() else 1.5
	var bt := _toward(bc, safari.start_dir)
	var ba := maxf(shore - BOTTLE_IN_M, 0.2) / p.radius
	_bottle_anchor = (bc * cos(ba) + bt * sin(ba)).normalized()
	if not p.is_underwater(_bottle_anchor):
		_bottle_anchor = bc
	_bottle_t0 = _tangent_at(_bottle_anchor)
	safari.add_subject({
		"id": "bottle_note", "name": "A Message in a Bottle", "kind": "bonus", "category": "bonus",
		"band": BAND_BOTTLE, "node": _bottle_root, "offset": Vector3(0.0, 0.02, 0.0), "radius": 0.15,
		"awake": func() -> bool: return not _sleeping,
	})
	_log("bottle in %s at %s (%.2f m in from its edge)" % [_pool_name(BOTTLE_POOL), _pp(_bottle_anchor), BOTTLE_IN_M])


## The bottle bobs and turns slowly on the water, drifting round a small circle about its spot.
func _tick_bonus(_delta: float) -> void:
	if _bottle_root == null:
		return
	var p := safari.planet
	var a := TAU * _t / BOTTLE_DRIFT_SEC
	var t1 := _bottle_anchor.cross(_bottle_t0).normalized()
	var off := (_bottle_t0 * cos(a) + t1 * sin(a)) * (BOTTLE_DRIFT_M / p.radius)
	var d := (_bottle_anchor + off).normalized()
	var up := d
	var fwd := _bottle_t0.rotated(_bottle_anchor, a * 0.5 + 0.4 * sin(_t * 0.37))
	fwd = (fwd - up * fwd.dot(up)).normalized()
	var b := Basis.looking_at(fwd, up)
	b = b * Basis(Vector3(1, 0, 0), 0.06 * sin(_t * 1.3)) * Basis(Vector3(0, 0, 1), 0.08 * sin(_t * 1.7 + 0.6))
	_bottle_root.global_transform = Transform3D(b, p.global_position + d * (_water_r + 0.035 + 0.012 * sin(_t * 1.9)))


# ======================================================================================== THE DIRECTOR
## BEFORE A RARE EVENT the director is keener (Zorp's measured fix): through the WARN seconds before the
## arch light (and the heron on a rare day) something is brought after PRE_RARE_AFTER_SEC of nothing
## instead of AFTER_SEC, so a creature is about when the director goes quiet for the rare (spec 13.2
## keeps it quiet WHILE the rare is up; this changes nothing then).
const PRE_RARE_AFTER_SEC := 5.0
const PRE_LAST_AFTER_SEC := 3.0
var _after_sec := 12.0


func _tick_pacing() -> void:
	if pacing == null:
		return
	var until := -1.0
	if _t >= ARCH_START - WARN and _t < ARCH_START:
		until = ARCH_START - _t
	if bool(_eligible.get("stone_heron", false)) and _t >= HERON_START - WARN and _t < HERON_START:
		until = HERON_START - _t
	# keener still in the last seconds, so the director's last bring before it goes quiet lands just
	# before the rare starts
	pacing.AFTER_SEC = _after_sec if until < 0.0 else (PRE_RARE_AFTER_SEC if until > 4.0 else PRE_LAST_AFTER_SEC)


func _build_pacing() -> void:
	pacing = Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	_after_sec = pacing.AFTER_SEC
	# `ready` says only whether one is FREE to bring: which one, and when an over-share one may still come,
	# is the director's (SafariWorld.Pacing: THE PER-BRING CAP, spec 17.1 rule 7). The local share caps
	# (_under_share, SHARE_CAP 0.25, the wisp's 0.15) went, spec 17.3 ruling 3: with every bringer over its
	# cap they locked the director and its 20 s fallback never fired (PACE critic r2, 2026-09-27).
	pacing.add_bringer({"id": "ruin_lizard", "bring": _bring_lizard,
		"ready": func() -> bool:
			for z: Dictionary in _lizards:
				if int(z["spot"]) < 0 and int(z["state"]) == Liz.GONE:
					return true
			return false})
	pacing.add_bringer({"id": "pool_frog", "bring": _bring_frog,
		"ready": func() -> bool:
			for f: Dictionary in _frogs:
				if bool(f["scout"]) and int(f["state"]) == Frog.UNDER:
					return true
			return false})
	pacing.add_bringer({"id": "fen", "bring": _bring_fen,
		"ready": func() -> bool: return _fen_can_come()})
	pacing.add_bringer({"id": "mist_wisp", "bring": _bring_wisp,
		"ready": func() -> bool:
			# once it has a photo this safari, a wisp is only the FALLBACK: brought when the others had
			# WISP_FALLBACK_SEC more to come and did not (see WISP_FALLBACK_SEC)
			if int(pacing.photos.get("mist_wisp", 0)) > 0 and pacing.lonely < pacing.AFTER_SEC + WISP_FALLBACK_SEC:
				return false
			for w: Dictionary in _wisps:
				if int(w["state"]) == Wis.AWAY and not bool(w["roamer"]) and not bool(w["watch"]):
					return true
			return false})
	pacing.places = _creature_places


## Once the wisp has a photo in this safari it is brought only as a FALLBACK: when nothing has been
## clearly in view for this long past the director's AFTER_SEC (the others had their turn and could not
## come - a lizard needs ground in view, a frog a pool, Fen his rest). The wisp is the one bringer that
## can always come (it drifts in at any height), so without this the director brought it for 8 of its 13
## careful photos (c2fen_out/g3). Keyed on PHOTOS, so the density wanderer (none) is untouched; it never
## locks the director (with nothing in view `lonely` grows past it).
const WISP_FALLBACK_SEC := 3.0


## Where the other creatures are, or will come into view: the frog pools, the lizard spots, Fen, the
## wisps drifting now, the scouts that are out, the moth pools at night, and every awake event.
func _creature_places() -> Array:
	var p := safari.planet
	var out: Array = []
	for pi: int in FROG_POOLS:
		if pi < _pools.size():
			out.append(_water_point(pi))
	for f: Dictionary in _frogs:
		if bool(f["scout"]) and int(f["state"]) != Frog.UNDER:
			out.append(p.surface_point(f["dir"]))
	for sp: Array in _liz_spots:
		out.append(p.surface_point(sp[0]))
	if _fen != null and is_instance_valid(_fen):
		out.append(_fen.global_position)
	for w: Dictionary in _wisps:
		if int(w["state"]) != Wis.AWAY:
			out.append(p.surface_point(w["dir"]))
	for z: Dictionary in _lizards:
		if int(z["spot"]) < 0 and int(z["state"]) != Liz.GONE:
			out.append(p.surface_point(z["dir"]))
	if safari.is_night:
		for c: Vector3 in _moth_centres:
			out.append(c)
	if _swift_at >= 0:
		out.append(p.surface_point(_swift_places[_swift_at][0]))
	if _any_running(RIPPLE_RUNS) and _ripple_at >= 0:
		out.append(_water_point(RIPPLE_POOLS[_ripple_at]))
	if _any_running(BLOOM_RUNS) or safari.event_running("arch_light"):
		out.append(_arch_xf.origin)
	if safari.event_running("stone_heron"):
		out.append(_heron_pos)
	return out


# ======================================================================================== SCHEDULE
## Every event run is its own PlanetSafari event (its own id, so event_running and the "woke" count work
## per run); the runs of one kind share one warning glow and one subject.
func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line, tier]
	var ev: Array = []
	for run: Dictionary in SWIFT_RUNS:
		var at := int(run["at"])
		var d: Vector3 = _swift_places[at][0]
		var where := "the COLONNADE" if at == 0 else _pool_name(SWIFT_POOLS[at - 1]) + "'s spires"
		ev.append(["tower_swifts", run["id"], "Tower Swifts", run["start"], run["end"], d, "any", Color("#b9a8d6"),
			"Swifts are gathering high over %s..." % where, "common"])
	for run: Dictionary in RIPPLE_RUNS:
		var pi: int = RIPPLE_POOLS[int(run["at"])]
		ev.append(["pool_ripple", run["id"], "Pool Ripple", run["start"], run["end"], _pool_dir(pi), "any", Color("#bfe3d8"),
			"%s is starting to glow. Something stirs in it." % _pool_name(pi).capitalize(), "uncommon"])
	for run: Dictionary in BLOOM_RUNS:
		ev.append(["vine_bloom", run["id"], "Fen's Vine in Bloom", run["start"], run["end"], _arch_dir, "any", Color("#e8c9b4"),
			"Fen: \"The vine on the ARCH. The buds are swelling. Note the minute.\"", "uncommon"])
	ev.append(["arch_light", "arch_light", "The Arch Light", ARCH_START, ARCH_END, _arch_dir, "any", Color("#f6d39a"),
		"The low sun is creeping toward the ARCH...", "rare"])
	ev.append(["stone_heron", "stone_heron", "The Stone Heron", HERON_START, HERON_END, _pool_dir(HERON_POOL), "only", Color("#c9ccd4"),
		"A great grey bird is circling over %s..." % _pool_name(HERON_POOL), "rare_day"])
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
				beacon.set_meta("on", false)
				_on_end(kind),
		})
		_eligible[id] = ok
		if not beacon.has_meta("dir_set"):
			beacon.set_meta("dir", dir)
			beacon.set_meta("dir_set", true)


## What each warning plays and shows besides the line and the glow (logged at every warning).
const WARN_SOUNDS := {"tower_swifts": "doot_c_3 x3, high (then chirps near the flock)", "pool_ripple": "splash, low (then bubbles)",
	"vine_bloom": "tree_shake + doot_c_0", "arch_light": "skiff_reveal, low", "stone_heron": "shooting_star, low + emote_wave"}
const WARN_CUES := {"tower_swifts": "the flock gathers and circles high over the place, then comes down",
	"pool_ripple": "the pool starts to glow and bubble", "vine_bloom": "the buds on the arch swell and pulse",
	"arch_light": "the arch's opening starts to glow and gold motes gather in it",
	"stone_heron": "the heron circles high over its pool, coming lower"}


## The SOUND half of every warning: heard anywhere on the planet (a 2D sound), the moment it is warned.
func _warn_sound(kind: String) -> void:
	match kind:
		"tower_swifts":
			var a := _sound_once("doot_c_3", 2.2, -6.0)
			a.play()
			get_tree().create_timer(0.25).timeout.connect(func() -> void:
				if is_instance_valid(a):
					a.pitch_scale = 2.5
					a.play())
		"pool_ripple":
			_sound_once("splash", 0.6, -6.0).play()
		"vine_bloom":
			_sound_once("tree_shake", 1.3, -6.0).play()
			_sound_once("doot_c_0", 1.2, -8.0).play()
		"arch_light":
			_sound_once("skiff_reveal", 0.7, -6.0).play()
		"stone_heron":
			_sound_once("shooting_star", 0.55, -6.0).play()
			_sound_once("emote_wave", 0.6, -8.0).play()


func _on_start(kind: String) -> void:
	match kind:
		"pool_ripple":
			if _ripple_at >= 0:
				AudioManager.play_sfx_at("splash", _ripple_root.global_position, -4.0, 0.1)
		"vine_bloom":
			_sound_once("friendship_up", 0.9, -10.0).play()
		"arch_light":
			_sound_once("doot_c_1", 0.8, -8.0).play()
		"stone_heron":
			_sound_once("tree_shake", 0.7, -8.0).play()


func _on_end(kind: String) -> void:
	match kind:
		"arch_light":
			_motes.emitting = false


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
## A warning glow on YOUR horizon toward its event (Bolt's: worlds/bolt.gd `_make_beacon`).
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
		b.global_position = safari.ground_point(along, 0.75)
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
	_tick_frogs(delta)
	_tick_lizards(delta)
	_tick_wisps(delta)
	_tick_moths(delta)
	_tick_swifts(delta)
	_tick_ripple(delta)
	_tick_vine(delta)
	_tick_arch(delta)
	_tick_heron(delta)
	_tick_fen(delta)
	_tick_bonus(delta)
	_tick_beacons(delta)


## The three minutes are up: frogs slip under, lizards dart off (the scouts into their cracks), wisps
## fade up into the dusk, moths spiral away, the swifts climb off, the flowers close; everything else
## goes in PlanetSafari's puff; the sounds stop. Fen is handed back at once and put back where he stood
## when this node leaves.
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_arch_root, _heron_root]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for pr: CPUParticles3D in [_bubbles, _petals, _motes]:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false)
	_release_fen(false)
	return true


func _exit_tree() -> void:
	_release_fen(true)


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
## (Bolt's `_pick_focus`, R4); -1 when none is awake.
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
const ONCE_SFX := ["doot_c_3", "splash", "tree_shake", "doot_c_0", "doot_c_1", "skiff_reveal", "shooting_star",
	"emote_wave", "friendship_up"]


func _warm_sounds() -> void:
	for sfx: String in ONCE_SFX:
		_sound_once(sfx, 1.0, -80.0)
	# the positional ones AudioManager plays: load them now so the first is not a disk read mid-safari
	for sfx: String in ["doot_a_0", "collect_stardust", "footstep_stone_0", "footstep_stone_1", "emote_happy"]:
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


## For the test logs: where each photographed creature came from. And a photographed ROAMER wisp goes to
## rest (ROAMER_REST_SEC).
func _on_photo(ph: Dictionary) -> void:
	var id := str(ph.get("subject_key", "")).get_slice(":", 1)
	var src := ""
	match id:
		"mist_wisp":
			if _wisp_pick >= 0:
				var w: Dictionary = _wisps[_wisp_pick]
				src = "roamer" if bool(w["roamer"]) else ("watcher" if bool(w["watch"]) else "brought")
				if bool(w["roamer"]):
					w["rest_until"] = _t + ROAMER_REST_SEC
		"ruin_lizard":
			if _liz_pick >= 0:
				src = "column" if int(_lizards[_liz_pick]["spot"]) >= 0 else "scout"
		"fen":
			src = "brought" if _t - _fen_came_at < 20.0 else "about"
	_log("photo t=%.1f %s from %s grade %s" % [_t, id, src, str(ph.get("grade", ""))])


func _log(msg: String) -> void:
	print("[FenSafari] " + msg)


## Everything a test needs to find the subjects and places (the probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"pools": _pools.map(func(p: Dictionary) -> Vector3: return p["dir"]), "arch": _arch_dir,
		"beam_dir": _beam_dir, "arch_xf": _arch_xf, "heron_pos": _heron_pos, "home": _fen_home_dir(),
		"swift_places": _swift_places.map(func(s: Array) -> Vector3: return s[0]),
		"frog_dirs": _frogs.map(func(f: Dictionary) -> Vector3: return f["dir"]),
		"lizard_dirs": _lizards.map(func(z: Dictionary) -> Vector3: return z["dir"]),
		"wisp_dirs": _wisps.map(func(w: Dictionary) -> Vector3: return w["dir"]),
		"eligible": _eligible.duplicate(),
	}
