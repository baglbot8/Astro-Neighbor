extends SafariWorld
## ZORP'S WORLD WAKES UP - THE GLOWING GARDEN (docs/PLANET_SAFARI_SPEC.md 12.1, built to Bolt's round-2
## rules: the tiers of 11.2, the density BAND of 11.2b, Facing and Size of 11.1, the pacing director of
## 13.2; builder ZORP, 2026-09-25; the scrapbook's sights and bonus items of 15.5 and the director's
## share of 14.3, builder ZORPC, 2026-09-26). Loaded by PlanetSafari when a safari starts on Zorp's world and freed
## when it ends: nothing here exists outside a safari (the user's rule 5), and nothing on the planet is
## changed - Zorp himself is the one thing borrowed (he waters the bulb beds) and he is put back exactly
## where he stood when this node leaves the tree. The crystal clusters "light up" with glows laid OVER
## the planet's own Crystal props; the props themselves are never touched.
##
## Built only from Zorp's existing look (planet_props.gd `_violet`): mushroom trees and toadstools,
## pulsing crystal clusters, tentacle plants with glowing bulbs, drifting spores, two moons, no lamps.
##
##   creatures        always about, in many places  MUSH-HOPPERS round two mushroom rings (they squat
##                                                   into a mushroom when rushed), GLOW-JELLIES drifting
##                                                   low over the whole planet (the roamer), LANTERN-
##                                                   BEETLES over the bulb bed at night; the pacing
##                                                   director (SafariWorld.Pacing) brings a scout hopper,
##                                                   a jelly or Zorp when it goes quiet, and at night a
##                                                   stray beetle swarm too. WHICH one is the director's
##                                                   job (spec 14.3): nothing here rests a creature on a
##                                                   timer of its own; the roaming jelly and the watchers
##                                                   keep out of view while the director holds the jelly
##                                                   back, and this planet sets the director's cap at 0.27
##                                                   (MAX_SHARE, see _build_pacing).
##   common event     ~30 s, repeats                 SPORE BLOOM at three rings
##   uncommon events  ~12 s, repeats                 CRYSTAL CHIME at three clusters; ZORP WATERS THE
##                                                   TENTACLE BULBS at two beds, and they open
##   rare             once                           THE GREAT BLOOM unfurls on the far side, mid-safari
##   rare day         1 day in 4                     TWIN-MOON GLOW: two moons line up over the crystal
##                                                   field and every crystal lights at once
##   sights           always there (spec 15.5)       THE TENTACLE BULB BED; THE GREAT MUSHROOM RING
##   bonus            hidden, collector's only       THE SPORE GNOME; ZORP'S WATERING CAN, upside down;
##                                                   THE HEART CRYSTAL (see "the scrapbook" below)
## RARITY follows the tier (SafariWorld.TIER_RARITY): creatures and Zorp 1, lantern-beetles and the
## spore bloom 2, the chime and the watering 3, the Great Bloom and the Twin-Moon Glow 4, sights and bonus
## items 1. Every roster entry names its scrapbook "category" (safari_world.gd CATEGORY).
##
## ------------------------------------------------------------------------------------ THE PLACES
## As (degrees round from the start beside the pad, bearing from the start heading, + = right).
## 1 degree = 0.183 m; the safari walk 1.5 m/s = 8.2 deg/s, a quarter round 11 s, the far side 22 s.
## The props (Zorp's seed-23 layout, probe --ps-layout): mushroom trees at (36,60) (75,73) (81,120)
## (82,176) (127,126) (117,107) (82,-142); crystals Crystal0 (122,5) Crystal1 (52,-136) Crystal2 (79,16)
## Crystal3 (106,-5) Crystal4 (76,-38) Crystal5 (31,9); tentacle plants (138,-103) (39,-95) (135,176)
## (61,-38) (41,-131); the pad behind the start at (17,-180).
##   RING A "the TOADSTOOL RING"  (75, 95)    mush-hoppers; spore bloom 3
##   RING B "the MOSSY RING"      (100, -70)  mush-hoppers; spore bloom 2
##   RING C "the FAR RING"        (125, 45)   spore bloom 1 (no hoppers: the far one)
##   BED A  "the BULB BED"        (40, -113)  between two tentacle plants: watering 1; beetles at night
##   BED B  "the BACK BEDS"       (138, -103) watering 2
##   CHIMES                       Crystal1, Crystal5 (the start's crystals), Crystal0
##   THE GREAT BLOOM              the antipode of Crystal5 (so it and chime 2 are 180 degrees apart)
##   THE MOON MEADOW              the middle of the crystal field (every cluster more than 60 degrees
##                                from the start): the twin moons line up over it
## Every place is logged at build, moved to the nearest clear spot where needed.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned WARN (8 s) ahead with a SIGHT and a SOUND that duplicate each other
## (spec 4): a line on screen naming the place, a sound heard anywhere on the planet, a coloured glow
## on YOUR horizon toward the event (gone once you are within 50 degrees), and the event's own cue (the
## ring's caps glow and trickle spores, the crystals glint and tinkle, Zorp calls out, the bud grows
## and hums, the moons rise and the crystals flicker). Nothing depends on reading them.
##   0:07-0:37  SPORE BLOOM (1) at ring C. BIG BREATH 0:20-0:23.5.
##   0:12-0:24  WATERING (1) at bed A (Zorp borrowed from 0:04). BULBS OPEN 0:18-0:22.
##   0:40-0:52  CRYSTAL CHIME (1) at Crystal1. RINGING 0:44.5-0:48.
##   1:02-1:32  SPORE BLOOM (2) at ring B. BIG BREATH 1:15-1:18.5.
##   1:24-1:36  THE GREAT BLOOM (rare, once). FULL BLOOM 1:28-1:33.5.
##   1:24-1:36  CRYSTAL CHIME (2) at Crystal5, by the start. RINGING 1:28.5-1:32.
##   1:55-2:07  WATERING (2) at bed B (Zorp borrowed from 1:47). BULBS OPEN 2:01-2:05.
##   2:20-2:50  SPORE BLOOM (3) at ring A. BIG BREATH 2:33-2:36.5.
##   2:26-2:38  TWIN-MOON GLOW (rare day, 1 in 4). LINED UP 2:33-2:37.
##   2:30-2:42  CRYSTAL CHIME (3) at Crystal0, in the crystal field. RINGING 2:34.5-2:38.
##   all 3 min  MUSH-HOPPERS, GLOW-JELLIES, ZORP; LANTERN-BEETLES at night.
## THE OVERLAPS FORCE A CHOICE (spec 6.2): two pairs share one short best window and sit on opposite
## sides of the planet - the watering's open bulbs (bed A, 0:18-0:22) / spore bloom 1's big breath
## (ring C, 0:20-0:23.5), 158 degrees and 19 s of walking apart; the Great Bloom in full bloom
## (1:28-1:33.5) / chime 2 ringing (Crystal5, its antipode, 1:28.5-1:32), 177 degrees and 22 s apart.
## On a rare day a third, softer one: the Twin-Moon line-up (the meadow, 2:33-2:37) / spore bloom 3's
## big breath (ring A, 2:33-2:36.5), 98 degrees and 12 s apart centre to centre - further than its
## 4 s window, but a standpoint between them has not been ruled out. Chime 3 rings in the crystal field
## under the lined-up moons on purpose: one picture can hold both. Every pair is logged at build.
## Unlike Bolt's (Q4's grid of where each can be photographed at its best), these are measured centre
## to centre only.
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): one MultiMesh per part - the hoppers 1 draw call, the jellies
## 2, the beetles 2, the rings 1, the bulbs 3, the Great Bloom's petals 1. The scrapbook adds 6 plain
## meshes: the great ring 2 (toadstools, glowing spots), the gnome 2, the can 1, the heart 1 - on the
## same materials (the heart on the planet's own pink crystal key, which its crystal props draw with). Every mesh is PlanetMeshKit
## vertex colour on materials Zorp's own props already draw with (the matte prop toon; the crystal
## shader with the planet's own mushroom-spot and tentacle-bulb keys) plus ONE new crystal-shader key,
## the lantern-beetles' warm glow; the glows are the shipped star shader; particles are CPUParticles3D
## on the shipped sparkle material. No lights. Everything is built in `build` (warmed behind the fade)
## and only moved, shown or hidden afterwards: each repeated event re-uses ONE set of emitters.
##
## ------------------------------------------------------------------------------------ FACING AND SIZE
## FACING (spec 11.1): every creature, Zorp and the watering (Zorp's own face) carry "front". Every
## mesh here faces -Z, so a front is -basis.z of the node the subject is scored on; the beetles' front
## is the heading of the beetle nearest the lens. The hoppers and jellies are CURIOUS: stand still with
## the camera up near one and it turns to you (and says hello: the moment).
## SIZE BANDS (spec 11.1): each band is set from the subject's USUAL DISTANCE so that at the 45 degree
## lens there, size scores 6 or less, and walking in or zooming reaches it. size_frac = tan(asin(r / d))
## / tan(22.5 deg); band.x = that / 0.58 (the scorer's curve then gives 5.9-6.0), band.y = 1.65 x band.x
## (Bolt's ratio), capped at 1.0.
##   subject          radius  usual d  size_frac there  band
##   mush-hopper      0.25     3.0 m   0.202            0.35-0.58
##   glow-jelly       0.28     3.0 m   0.226            0.39-0.64
##   lantern-beetles  0.80     8.0 m   0.243            0.42-0.69
##   Zorp             0.70     5.0 m   0.341            0.59-0.97
##   spore bloom      1.80     9.0 m   0.493            0.85-1.00
##   crystal chime    1.00     7.0 m   0.348            0.60-0.99
##   watering         1.00     6.0 m   0.408            0.70-1.00
##   the Great Bloom  1.40    11.0 m   0.309            0.53-0.88
##   twin-moon glow   (sky)   (sky)    0.242            0.42-0.69   (the sky's own moon pair, lined up: its
##                                                                  half-width 0.101 rad at any distance)
## The usual distances are the creatures' spec floor (3 m) and, for the rest, first guesses to be
## checked against the wanderer's `dists` (see the report).

## THE MANIFEST (spec 12.5; safari_world.gd THE MANIFEST). Zorp's own voice (npc_data.gd, the project
## lines in src/projects/data/zorp.gd, STYLE_GUIDE "Zorp = enthusiastic and curious about Earth
## things"): excited, repeats himself, calls himself Zorp, counts things as "facts", <= 60 characters.
const MANIFEST := {
	"host": "zorp",
	"offer": "Oh! Oh! My garden wakes up for three minutes a day!",
	"ask": "Photo safari? It is VERY science!",
	"yes": "Yes! Start at the landing pad. Walk softly, softly!",
	"no": "No? That is fine. The garden will wait. Mostly.",
	"asleep": "Shhh. The garden is asleep. Come back tomorrow!",
	"roster": [
		{"id": "mush_hopper", "name": "Mush-hopper", "tier": "creature", "category": "creature"},
		{"id": "glow_jelly", "name": "Glow-jelly", "tier": "creature", "category": "creature"},
		{"id": "lantern_beetle", "name": "Lantern-beetles", "tier": "night", "category": "creature"},
		{"id": "zorp", "name": "Zorp", "tier": "neighbour", "category": "neighbour"},
		{"id": "spore_bloom", "name": "Spore Bloom", "tier": "common", "category": "event"},
		{"id": "crystal_chime", "name": "Crystal Chime", "tier": "uncommon", "category": "event"},
		{"id": "watering", "name": "Watering Time", "tier": "uncommon", "category": "event"},
		{"id": "great_bloom", "name": "The Great Bloom", "tier": "rare", "category": "event"},
		{"id": "twin_moon_glow", "name": "Twin-Moon Glow", "tier": "rare_day", "category": "event"},
		# spec 15.5: two sights (always there) and three bonus items (collector's pages, pay nothing)
		{"id": "bulb_bed", "name": "The Tentacle Bulb Bed", "tier": "sight", "category": "sight"},
		{"id": "great_ring", "name": "The Great Mushroom Ring", "tier": "sight", "category": "sight"},
		{"id": "spore_gnome", "name": "The Spore Gnome", "tier": "bonus", "category": "bonus"},
		{"id": "zorp_can", "name": "Zorp's Watering Can", "tier": "bonus", "category": "bonus"},
		{"id": "heart_crystal", "name": "The Heart Crystal", "tier": "bonus", "category": "bonus"},
	],
	# The review's line about each photo, in Zorp's voice. `%s` is the subject's name, always at the
	# start of a sentence or after "Fact:", so "The Great Bloom" and "Lantern-beetles" read right.
	"review": {
		"no_subject": [
			"Fact: that is the garden. Zorp approves of the garden.",
			"A picture of nice violet air. Very calming!",
		],
		"Smudge": [
			"Fact: %s. A fuzzy fact, but it counts!",
			"%s, blurry! Zorp likes blurry. Still counts!",
		],
		"Fair": [
			"Fact: %s. A good, clear fact!",
			"%s! Zorp can see it. Into the fact book!",
		],
		"Fine": [
			"Fact: %s. Crisp! Zorp is pleased. Very pleased!",
			"%s, sharp as a crystal! Zorp is so proud!",
		],
		"Gallery": [
			"Fact: %s. PERFECT. Zorp will frame it. Twice!",
			"%s! Oh! Oh! Best photo in the whole Hollow!",
		],
		"moment": " And the timing! Zorp gasped!",
	},
}

const Meshes := preload("res://src/planet_safari/worlds/zorp_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")
const SFX_DIR := "res://assets/audio/sfx/"

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
## "at" = the ring (0 A, 1 B, 2 C). The BIG BREATH is SPORE_BIG_AT..+SPORE_BIG_SEC after a run starts.
const SPORE_RUNS := [
	{"id": "spore_bloom", "start": 7.0, "end": 37.0, "at": 2},
	{"id": "spore_bloom_2", "start": 62.0, "end": 92.0, "at": 1},
	{"id": "spore_bloom_3", "start": 140.0, "end": 170.0, "at": 0},
]
const SPORE_BIG_AT := 13.0
const SPORE_BIG_SEC := 3.5
## Between big breaths the ring breathes out a small puff every SPORE_PUFF_EVERY s for SPORE_PUFF_SEC.
const SPORE_PUFF_EVERY := 5.0
const SPORE_PUFF_SEC := 2.0
## "at" = the cluster (CHIME_CRYSTALS). RINGING (the flash) is CHIME_PEAK_AT..+CHIME_PEAK_SEC in.
const CHIME_RUNS := [
	{"id": "crystal_chime", "start": 40.0, "end": 52.0, "at": 0},
	{"id": "crystal_chime_2", "start": 84.0, "end": 96.0, "at": 1},
	{"id": "crystal_chime_3", "start": 150.0, "end": 162.0, "at": 2},
]
const CHIME_PEAK_AT := 4.5
const CHIME_PEAK_SEC := 3.5
## "at" = the bed. The bulbs are OPEN WATER_OPEN_AT..+WATER_OPEN_SEC in (Zorp waters from the start).
const WATER_RUNS := [
	{"id": "watering", "start": 12.0, "end": 24.0, "at": 0},
	{"id": "watering_2", "start": 115.0, "end": 127.0, "at": 1},
]
const WATER_OPEN_AT := 6.0
const WATER_OPEN_SEC := 4.0
const BLOOM_START := 84.0
const BLOOM_END := 96.0
const BLOOM_FULL := Vector2(88.0, 93.5)
const MOON_START := 146.0
const MOON_END := 158.0
const MOON_LINED := Vector2(153.0, 157.0)
## THE TWIN MOONS ARE THE PLANET'S OWN TWO MOONS: the crescents sky.gdshader draws in Zorp's sky
## (moon_count 2; the uniforms moon_dir_a / moon_dir_b, which environment.gd writes every frame). From
## the warning on, the event slides them out of their own places to line up side by side over the
## crystal field, MOON_ELEV_DEG above the meadow's horizon on the far side from the start (so from the
## field's near edge they hang over the lit crystals), and after the line-up they slide home over
## MOON_BACK_SEC. Nothing else of the sky is touched: the event only re-writes those two directions
## just before each frame is drawn (RenderingServer.frame_pre_draw, after environment.gd's own write)
## while it moves them; the frame after it stops, environment.gd's own values are back. (Round 1 hung
## two new cratered spheres 7 m over the meadow: with the sky's own pair that made four moons, and the
## round-1 critic read them as flat pale spheres with no glow.)
## 12 degrees: a moon pair lined up at 35 filled a centred frame with sky and no ground, from every
## standpoint the probe tried (czorp_out/shots_r6 first capture); at 12 the frame centred on the pair
## holds it and two lit crystal clusters below it, day and night.
const MOON_ELEV_DEG := 12.0
const MOON_BACK_SEC := 8.0
## Lined up, this much sky (radians) between the two discs' edges.
const MOON_LINE_GAP := 0.012
## The photo subject sits this far from the lens along the pair's direction (the moons are at infinity;
## its radius gives the pair's real angular size, so the scorer's size is the moons' size).
const MOON_FOCUS_M := 20.0
## Each crystal's glow sits this high over the cluster, over the tips.
const MOON_GLOW_H := 1.15

# ------------------------------------------------------------------------------ the places
const P_RINGS := [Vector2(75.0, 95.0), Vector2(100.0, -70.0), Vector2(125.0, 45.0)]
const RING_NAMES := ["the TOADSTOOL RING", "the MOSSY RING", "the FAR RING"]
const P_BEDS := [Vector2(40.0, -113.0), Vector2(138.0, -103.0)]
const BED_NAMES := ["the BULB BED", "the BACK BEDS"]
const CHIME_CRYSTALS := ["Crystal1", "Crystal5", "Crystal0"]
## Named places for the warning lines (the nearest one is named).
const PLACE_NAMES := [
	["the LANDING PAD", Vector2(0.0, 0.0)], ["the TOADSTOOL RING", Vector2(75.0, 95.0)],
	["the MOSSY RING", Vector2(100.0, -70.0)], ["the FAR RING", Vector2(125.0, 45.0)],
	["the BULB BED", Vector2(40.0, -113.0)], ["the BACK BEDS", Vector2(138.0, -103.0)],
	["the CRYSTAL FIELD", Vector2(95.0, -15.0)], ["the FAR SIDE", Vector2(170.0, 0.0)],
]

## A warning glow sits this far round from you toward its event (just inside your horizon), and fades
## out between BEACON_FULL_DEG and BEACON_NEAR_DEG (Bolt's numbers: the same 10.5 m planet).
const BEACON_AHEAD_DEG := 27.0
const BEACON_NEAR_DEG := 50.0
const BEACON_FULL_DEG := 70.0

# ------------------------------------------------------------------------------ SIZE BANDS (header)
const BAND_HOPPER := Vector2(0.35, 0.58)
const BAND_JELLY := Vector2(0.39, 0.64)
const BAND_BEETLES := Vector2(0.42, 0.69)
const BAND_ZORP := Vector2(0.59, 0.97)
const BAND_SPORE := Vector2(0.85, 1.00)
const BAND_CHIME := Vector2(0.60, 0.99)
const BAND_WATER := Vector2(0.70, 1.00)
const BAND_BLOOM := Vector2(0.53, 0.88)
const BAND_MOON := Vector2(0.42, 0.69)

# ------------------------------------------------------------------------------ mush-hoppers
const HOPPERS_PER_RING := 3
## Scouts: hoppers under the soil that the pacing director brings up where it has gone quiet.
const HOPPER_SCOUTS := 3
const HOPPER_RANGE_M := Vector2(0.5, 1.7)
const HOPPER_HOP_M := Vector2(0.45, 0.9)
const HOPPER_HOP_H := 0.3
const HOPPER_AIR_SEC := 0.45
const HOPPER_SIT_SEC := Vector2(0.8, 2.8)
const HOPPER_CROUCH_SEC := 0.14
## Walk at one faster than RUSH_SPEED inside RUSH_M and it squats into a mushroom.
const HOPPER_RUSH_M := 2.2
const HOPPER_RUSH_SPEED := 0.6
const HOPPER_HIDE_SEC := Vector2(2.5, 4.0)
## Stand still with the camera up inside HELLO_M for HELLO_STILL s and the nearest says hello.
const HOPPER_HELLO_M := 5.5
## (2.5 s, not Bolt's 0.8: at 0.8 the careless test player, who raises the camera and waits a second,
## caught a hello in about half its photos - cal_r1 in the report.)
const HOPPER_HELLO_STILL := 2.5
const HOPPER_HELLO_SEC := 3.5
const HOPPER_HELLO_REST := 6.0
## ...and inside CURIOUS_M a sitting one turns to face a still camera.
const CURIOUS_M := 6.5
const SCOUT_OUT_MIN_SEC := 12.0
const SCOUT_DOWN_M := 5.0
const SCOUT_POP_SEC := 0.45
## A scout that comes up where you look OVER the ground boings up to the director's "rise" plus this.
const SCOUT_BIG_SPARE := 0.45
enum Hop { SIT, CROUCH, AIR, HIDE, HELLO, GONE, POP }

# ------------------------------------------------------------------------------ glow-jellies
## JELLY_ROAMERS roam the planet all safari; JELLY_WATCHERS - the WATCHERS - drift out (somewhere out of
## your view) while a rare event is warned or up, drawn out by its glow, and float off again after it;
## the rest wait up in the sky for the pacing director. (Five roamers all safari held the density band
## but made jellies 43% of the careful test player's photos, over the 30% rule.)
const JELLY_N := 7
const JELLY_ROAMERS := 1
const JELLY_WATCHERS := 3
const JELLY_FROM := [Vector2(95.0, 35.0), Vector2(120.0, -150.0), Vector2(140.0, 100.0), Vector2(60.0, -60.0),
	Vector2(165.0, -20.0)]
const JELLY_SPEED := 0.32
const JELLY_ALT := 1.15
## A jelly the director brought drifts off up into the sky once it has been out this long and you have
## left it this far behind, out of view.
const JELLY_OUT_MIN_SEC := 12.0
const JELLY_LEAVE_M := 6.0
const JELLY_COME_SEC := 0.8
const JELLY_LEAVE_SEC := 2.0
const JELLY_HELLO_M := 4.5
const JELLY_KEEP_M := 1.6
enum Jel { DRIFT, AWAY, COME, LEAVE, HELLO }

# ------------------------------------------------------------------------------ lantern-beetles (night)
const BEETLES_PER_SWARM := 6
## Every BEETLE_RING_EVERY s the swarm gathers into a glowing ring for BEETLE_RING_SEC (the moment).
const BEETLE_RING_EVERY := 15.0
const BEETLE_RING_SEC := 2.0
const BEETLE_ALT := 0.95
## ONE BED SWARM, at the BULB BED (bed A, by the start: the first night creature most walks meet). Round 1
## had a swarm over each bed and 4 of 8 night wanderer runs had a median new-encounter gap under 8 s
## (czorp_out/band_n2..n8); one bed swarm fixed that.
const BEETLE_BEDS := [0]
## THE STRAY SWARM (ZORP2, spec 14.3): the night's fourth BRINGER. Round 1 rested the bed swarm on a timer
## of its own (25 s after each look) and dropped the stray swarm to thin the night; the beetles then fell
## to 2 of 26 night photos (sys2 zcar) while the jellies rose to 34%: the timer fought the director's
## share. Both are gone: at night the director may bring a stray swarm like a jelly (its lanterns light
## up where you look, BEETLE_ALT over the ground), and it decides WHEN, by the shares; the bed swarm keeps
## out of sight only while the director says `shy` (something new was just seen, or the beetles are over
## their share). A stray swarm that has been out BEETLE_STRAY_OUT_SEC and is left BEETLE_STRAY_LEAVE_M
## behind, out of view, puts its lanterns out (the jellies' JELLY_OUT_MIN_SEC / JELLY_LEAVE_M).
const BEETLE_STRAY_OUT_SEC := 12.0
const BEETLE_STRAY_LEAVE_M := 6.0

## SafariLayer.intro_hint holds the one banner for about 5 s.
const INTRO_HINT_SEC := 5.1
const LINE_SEC := 3.6

# ------------------------------------------------------------------------------ state
var pacing: Pacing
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}
var _prop: ShaderMaterial
var _glow_cyan: ShaderMaterial
var _glow_pink: ShaderMaterial
var _glow_warm: ShaderMaterial

var _pad_dir := Vector3.UP
var _ring_dirs: Array[Vector3] = []
var _bed_dirs: Array[Vector3] = []
var _chime_nodes: Array = []
var _chime_dirs: Array[Vector3] = []
var _crystals: Array = []          # every Crystal prop (Node3D)
var _bloom_dir := Vector3.UP
var _meadow_dir := Vector3.UP

var _hop_herd: Herd
var _hoppers: Array = []
var _hop_focus: Node3D
var _hop_pick := -1
var _hop_still := 0.0
var _hop_hello_next := 0.0

var _jelly_herd: Herd
var _jellies: Array = []
var _jelly_focus: Node3D
var _jelly_pick := -1

var _beetle_herd: Herd
var _swarms: Array = []            # {c: centre (world), dir, fade, stray, out, out_t}
var _beetles: Array = []           # {swarm, ang, r, speed, bob, pos, head}
var _beetle_focus: Node3D
var _beetle_pick := -1

var _spore_root: Node3D
var _spore_glow: MeshInstance3D
var _spore_small: CPUParticles3D
var _spore_big: CPUParticles3D
var _spore_focus: Node3D
var _spore_at := -1
var _rustle_clock := 0.0

var _chime_glows: Array[MeshInstance3D] = []
var _chime_sparkle: CPUParticles3D
var _chime_focus: Node3D
var _chime_at := -1
var _tinkle_clock := 0.0
var _chime_flash_clock := 0.0

var _stalk_herd: Herd
var _petal_herd: Herd
var _core_herd: Herd
var _bulbs: Array = []             # {bed, dir, face, xf}
var _bed_open := PackedFloat32Array([0.0, 0.0])
var _water_focus: Node3D
var _can: MeshInstance3D
var _drops: CPUParticles3D
var _water_at := -1
var _zorp: Node3D
var _zorp_saved := Transform3D()
var _zorp_wander_saved := true
var _zorp_borrowed := false
var _zorp_wave_until := -1.0
var _zorp_pose_until := -1.0
var _zorp_next_wave := 0.0
var _zorp_next_pose := 0.0
var _zorp_bed_xf := Transform3D()

var _bloom_root: Node3D
var _bloom_stem: MeshInstance3D
var _bloom_petals: Herd
var _bloom_core: MeshInstance3D
var _pollen: CPUParticles3D
var _bloom_focus: Node3D
var _bloom_hum: AudioStreamPlayer

var _moon_glows: Array[MeshInstance3D] = []
var _moon_focus: Node3D
var _sky_mat: ShaderMaterial        # the planet sky's material (environment.gd's), for the moon directions
var _moon_dir := Vector3.UP         # the pair's middle when lined up (a world direction)
var _moon_to: Array[Vector3] = [Vector3.UP, Vector3.UP]     # moon A and moon B lined up
var _moon_env: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]  # environment.gd's own directions
var _moon_now: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]  # what the event writes this frame
var _moon_k := 0.0                  # 0 = the moons where environment.gd has them, 1 = lined up
var _moon_half := 0.1               # the lined-up pair's half-width, radians

var _beacons: Dictionary = {}
var _lines: Array = []
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 23_0925_12
	_prop = PlanetPropMeshes.prop_material()
	# The planet's own glowing materials (planet_props.gd _violet: the mushroom-tree spots and the
	# tentacle bulbs): PlanetPropMeshes caches by key, so these are the very materials the planet draws.
	_glow_cyan = PlanetPropMeshes.crystal_material(Color("#7fd8c8"), Color("#5fd8b4"), 0.7, false, 0.35)
	_glow_pink = PlanetPropMeshes.crystal_material(Color("#d692c4"), Color("#d066ae"), 0.8, false, 0.35)
	# ...and one new key: the lantern-beetles' warm lantern (a small accent).
	_glow_warm = PlanetPropMeshes.crystal_material(Color("#e2c98e"), Color("#e8bf72"), 0.9, false, 0.4)
	_find_places()
	_build_rings()
	_build_hoppers()
	_build_jellies()
	_build_zorp()
	_build_beds()
	_build_scrapbook()
	_build_spores()
	_build_chime()
	_build_bloom()
	if safari.is_rare_day:
		_build_moons()
	if safari.is_night:
		_build_beetles()
	_register_events()
	_build_pacing()
	_warm_sounds()
	safari.photo_taken.connect(_on_photo)
	_building = true
	tick(0.0, 0.0)
	_building = false
	_log("built: rings %s beds %s chimes %s bloom %s meadow %s home %s rare=%s night=%s" % [
		str(_ring_dirs.map(_pp)), str(_bed_dirs.map(_pp)), str(_chime_dirs.map(_pp)), _pp(_bloom_dir),
		_pp(_meadow_dir), _pp(_zorp_home_dir()), str(safari.is_rare_day), str(safari.is_night)])
	# The three designed overlaps, centre to centre (the header's THE OVERLAPS FORCE A CHOICE).
	var walk := 1.5
	for pr: Array in [["bulbs open / big breath 1", _bed_dirs[0], _ring_dirs[2]],
			["full bloom / chime 2 ringing", _bloom_dir, _chime_dirs[1]],
			["moons lined up / big breath 3", _meadow_dir, _ring_dirs[0]]]:
		var a := rad_to_deg((pr[1] as Vector3).angle_to(pr[2]))
		_log("overlap %s: %.0f deg apart, %.1f m, %.1f s at the safari walk" % [pr[0], a,
			deg_to_rad(a) * safari.planet.radius, deg_to_rad(a) * safari.planet.radius / walk])


func _find_places() -> void:
	var p := safari.planet
	_pad_dir = p.data.pad_dir.normalized() if p.data != null else safari.start_dir
	for r: Vector2 in P_RINGS:
		_ring_dirs.append(_free_near(safari.dir_from_start(r.x, r.y), 1.9))
	for b: Vector2 in P_BEDS:
		_bed_dirs.append(_free_near(safari.dir_from_start(b.x, b.y), 1.0))
	var props := p.get_node_or_null("Props")
	if props != null:
		for c in props.get_children():
			if str(c.name).begins_with("Crystal") and c is Node3D:
				_crystals.append(c)
	for nm: String in CHIME_CRYSTALS:
		var n := p.get_node_or_null("Props/" + nm) as Node3D
		if n == null and not _crystals.is_empty():
			n = _crystals[_chime_nodes.size() % _crystals.size()]
		_chime_nodes.append(n)
		_chime_dirs.append(p.dir_of(n.global_position) if n != null else safari.dir_from_start(60.0, 0.0))
	# The Great Bloom stands on the antipode of chime 2's crystals; the moons line up over the middle of
	# the crystal field (the clusters more than 60 degrees out from the start).
	_bloom_dir = _free_near(-_chime_dirs[1], 1.6)
	var sum := Vector3.ZERO
	for c: Node3D in _crystals:
		var cd := p.dir_of(c.global_position)
		if rad_to_deg(cd.angle_to(safari.start_dir)) > 60.0:
			sum += cd
	_meadow_dir = sum.normalized() if sum.length() > 0.1 else safari.dir_from_start(95.0, -15.0)


## `dir`, or the nearest spot round it at least `clear_m` from every prop.
func _free_near(dir: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(dir) >= clear_m:
		return dir
	var t := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
	for ring_deg in [3.0, 6.0, 9.0, 12.0, 15.0, 18.0]:
		for k in 8:
			var d := dir.rotated(t.rotated(dir, TAU * float(k) / 8.0), deg_to_rad(ring_deg)).normalized()
			if p.nearest_prop_distance(d) >= clear_m and rad_to_deg(d.angle_to(_pad_dir)) > 12.0:
				return d
	return dir


func _zorp_home_dir() -> Vector3:
	if _zorp != null and is_instance_valid(_zorp):
		return (_zorp.get("home_dir") as Vector3).normalized()
	return safari.dir_from_start(45.0, -30.0)


## The nearest named place to `d` (for the warning lines).
func _place_name(d: Vector3) -> String:
	var best := ""
	var best_a := INF
	for row: Array in PLACE_NAMES:
		var pd: Vector2 = row[1]
		var a := d.angle_to(safari.dir_from_start(pd.x, pd.y))
		if a < best_a:
			best_a = a
			best = str(row[0])
	return best


# ---------------------------------------------------------------------------------------- rings
func _build_rings() -> void:
	var pts: Array = []
	for d: Vector3 in _ring_dirs:
		pts.append(safari.planet.surface_point(d))
	var h := Herd.new()
	add_child(h)
	h.setup("MushroomRings", _ring_dirs.size(), [[Meshes.mushroom_ring(), _prop, true]], Herd.area_around(pts, 2.5))
	for i in _ring_dirs.size():
		h.pose(i, 0, _xf_ground(_ring_dirs[i], _tangent_at(_ring_dirs[i])).translated_local(Vector3(0.0, -0.02, 0.0)))


# ---------------------------------------------------------------------------------------- mush-hoppers
func _build_hoppers() -> void:
	var p := safari.planet
	var pts: Array = []
	for ri in 2:
		var c: Vector3 = _ring_dirs[ri]
		for k in HOPPERS_PER_RING:
			var d := _ring_spot(c, TAU * float(k) / float(HOPPERS_PER_RING) + _rng.randf_range(-0.4, 0.4))
			_hoppers.append({"ring": ri, "dir": d, "face": _toward(d, c).rotated(d, _rng.randf_range(-1.5, 1.5)),
				"state": Hop.SIT, "timer": _rng.randf_range(0.3, 2.5), "from": d, "to": d, "air": 0.0,
				"air_sec": HOPPER_AIR_SEC, "apex": HOPPER_HOP_H, "h": 0.0, "squat": 0.0, "hello": 0.0,
				"out_t": 0.0, "phase": _rng.randf_range(0.0, TAU)})
			pts.append(p.surface_point(d))
	for k in HOPPER_SCOUTS:
		_hoppers.append({"ring": -1, "dir": safari.start_dir, "face": safari.start_fwd, "state": Hop.GONE,
			"timer": 0.0, "from": safari.start_dir, "to": safari.start_dir, "air": 0.0, "air_sec": HOPPER_AIR_SEC,
			"apex": HOPPER_HOP_H, "h": 0.0, "squat": 0.0, "hello": 0.0, "out_t": 0.0, "phase": _rng.randf_range(0.0, TAU)})
	_hop_herd = Herd.new()
	add_child(_hop_herd)
	# scouts come up anywhere: the culling box is the whole planet
	var r := p.radius + 4.0
	_hop_herd.setup("MushHoppers", _hoppers.size(), [[Meshes.hopper(), _prop, true]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_hop_focus = Node3D.new()
	_hop_focus.name = "HopperFocus"
	add_child(_hop_focus)
	safari.add_subject({
		"id": "mush_hopper", "name": "Mush-hopper", "kind": "creature",
		"band": BAND_HOPPER, "node": _hop_focus, "offset": Vector3(0.0, 0.2, 0.0), "radius": 0.25,
		"awake": func() -> bool: return _hop_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _hopper_moment(),
		"front": func() -> Vector3: return _front_of(_hop_focus),
	})


## A spot round ring centre `c`, `ang` radians round, HOPPER_RANGE_M out.
func _ring_spot(c: Vector3, ang: float) -> Vector3:
	var m := _rng.randf_range(HOPPER_RANGE_M.x, HOPPER_RANGE_M.y)
	return _polar(c, _tangent_at(c), rad_to_deg(m / safari.planet.radius), rad_to_deg(ang))


func _hopper_moment() -> Dictionary:
	if _hop_pick < 0:
		return {"mult": 1.0, "line": ""}
	var h: Dictionary = _hoppers[_hop_pick]
	if int(h["state"]) == Hop.HELLO:
		return {"mult": 1.8, "line": "saying hello"}
	if int(h["state"]) == Hop.AIR and float(h["h"]) > 0.6 * float(h["apex"]):
		return {"mult": 1.5, "line": "mid-hop"}
	return {"mult": 1.0, "line": ""}


func _hopper_out(h: Dictionary) -> bool:
	var st: int = h["state"]
	return st != Hop.GONE and not (st == Hop.POP and float(h["timer"]) > SCOUT_POP_SEC * 0.5) \
		and float(h["squat"]) < 0.5


func _tick_hoppers(delta: float) -> void:
	if _hop_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	_hop_still = (_hop_still + delta) if still_up else 0.0
	var shy := pacing != null and pacing.shy("mush_hopper")
	# hello: the nearest one out, to a still camera
	var hello_i := -1
	if _hop_still >= HOPPER_HELLO_STILL and _t >= _hop_hello_next and not _sleeping:
		var best := HOPPER_HELLO_M
		for i in _hoppers.size():
			var h: Dictionary = _hoppers[i]
			if int(h["state"]) in [Hop.SIT, Hop.CROUCH] and _hopper_out(h):
				var dd := p.surface_point(h["dir"]).distance_to(ppos)
				if dd < best:
					best = dd
					hello_i = i
	for i in _hoppers.size():
		var h: Dictionary = _hoppers[i]
		var here := p.surface_point(h["dir"])
		var dist := here.distance_to(ppos)
		var st: int = h["state"]
		h["timer"] = float(h["timer"]) - delta
		var scout := int(h["ring"]) < 0
		if st != Hop.GONE:
			h["out_t"] = float(h["out_t"]) + delta
		var in_frame := _point_in_frame(here + p.up_at(here) * 0.2, 1.1)
		# THE END and ONE NEW THING AT A TIME: out of the frame, a ring hopper squats into a mushroom and
		# a scout dives back under the soil.
		if _sleeping or (shy and not in_frame and st != Hop.GONE and st != Hop.AIR):
			if scout:
				_scout_dive(h)
			elif st != Hop.HIDE:
				h["state"] = Hop.HIDE
				h["timer"] = 0.6 if _sleeping else _rng.randf_range(HOPPER_HIDE_SEC.x, HOPPER_HIDE_SEC.y)
				h["shy"] = true
			st = h["state"]
		var rushed := dist < HOPPER_RUSH_M and speed > HOPPER_RUSH_SPEED
		match st:
			Hop.GONE:
				h["squat"] = 1.0
			Hop.POP:
				if float(h["timer"]) <= 0.0:
					_hop_plan(h, _free_hop_target(h), float(h.get("pop_apex", HOPPER_HOP_H)))
			Hop.SIT:
				h["squat"] = move_toward(float(h["squat"]), 0.0, 3.0 * delta)
				if i == hello_i:
					h["state"] = Hop.HELLO
					h["hello"] = HOPPER_HELLO_SEC
					_hop_hello_next = _t + HOPPER_HELLO_SEC + HOPPER_HELLO_REST
					AudioManager.play_sfx_at("emote_happy", here, -10.0, 0.2)
				elif rushed and not scout:
					h["state"] = Hop.HIDE
					h["timer"] = _rng.randf_range(HOPPER_HIDE_SEC.x, HOPPER_HIDE_SEC.y)
					AudioManager.play_sfx_at("rotate", here, -10.0, 0.25)
				elif rushed and scout:
					_hop_plan(h, _away_target(h, ppos), HOPPER_HOP_H)
				elif still_up and dist < CURIOUS_M:
					_turn_face(h, ppos - here, 2.5, delta)
				elif float(h["timer"]) <= 0.0:
					h["state"] = Hop.CROUCH
					h["timer"] = HOPPER_CROUCH_SEC
			Hop.CROUCH:
				if float(h["timer"]) <= 0.0:
					_hop_plan(h, _free_hop_target(h), HOPPER_HOP_H)
			Hop.AIR:
				h["air"] = float(h["air"]) + delta
				var k := clampf(float(h["air"]) / float(h["air_sec"]), 0.0, 1.0)
				h["dir"] = (h["from"] as Vector3).slerp(h["to"], k).normalized()
				h["h"] = 4.0 * float(h["apex"]) * k * (1.0 - k)
				if k >= 1.0:
					h["h"] = 0.0
					h["state"] = Hop.SIT
					h["timer"] = _rng.randf_range(HOPPER_SIT_SEC.x, HOPPER_SIT_SEC.y)
					if dist < 8.0:
						AudioManager.play_sfx_at("land", here, -18.0, 0.3)
			Hop.HIDE:
				h["squat"] = move_toward(float(h["squat"]), 1.0, 5.0 * delta)
				var held := bool(h.get("shy", false)) and shy
				if not _sleeping and not held and float(h["timer"]) <= 0.0 and not rushed:
					h["shy"] = false
					h["state"] = Hop.SIT
					h["timer"] = _rng.randf_range(0.5, 1.5)
			Hop.HELLO:
				h["hello"] = float(h["hello"]) - delta
				_turn_face(h, ppos - here, 6.0, delta)
				h["h"] = absf(sin(_t * 7.0)) * 0.12
				if float(h["hello"]) <= 0.0 or rushed or not still_up:
					h["state"] = Hop.SIT
					h["h"] = 0.0
					h["timer"] = _rng.randf_range(HOPPER_SIT_SEC.x, HOPPER_SIT_SEC.y)
		# a scout that has been out a while and is left behind, out of view, dives back under
		if scout and int(h["state"]) in [Hop.SIT, Hop.CROUCH] and float(h["out_t"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not in_frame:
			_scout_dive(h)
		_pose_hopper(i, h)
	_hop_pick = _pick_focus(_hoppers, func(h: Dictionary) -> bool: return _hopper_out(h),
		func(h: Dictionary) -> Vector3: return p.surface_point(h["dir"]), 0.2)
	if _hop_pick >= 0:
		var h: Dictionary = _hoppers[_hop_pick]
		_hop_focus.global_transform = _xf_ground(h["dir"], h["face"]).translated_local(Vector3(0.0, float(h["h"]), 0.0))


func _scout_dive(h: Dictionary) -> void:
	if int(h["state"]) == Hop.GONE:
		return
	var here := safari.planet.surface_point(h["dir"])
	if _point_in_frame(here, 1.2) and not _sleeping:
		safari.puff_at(here + safari.planet.up_at(here) * 0.1, 8, Color("#d9cfe6"))
	h["state"] = Hop.GONE
	h["squat"] = 1.0
	h["h"] = 0.0


## Where a hopper hops next: round its ring, or (a scout) near where it is, clear of props.
func _free_hop_target(h: Dictionary) -> Vector3:
	var p := safari.planet
	var d: Vector3 = h["dir"]
	for tries in 8:
		var cand: Vector3
		if int(h["ring"]) >= 0:
			var c: Vector3 = _ring_dirs[int(h["ring"])]
			var cur := _toward(c, d)
			var ang := atan2(cur.dot(_tangent_at(c).cross(c)), cur.dot(_tangent_at(c)))
			cand = _ring_spot(c, -ang + _rng.randf_range(-0.9, 0.9))
			if p.surface_distance(cand, d) > HOPPER_HOP_M.y * 1.3:
				cand = p.step_dir(d, cand, _rng.randf_range(HOPPER_HOP_M.x, HOPPER_HOP_M.y))
		else:
			var hc: Vector3 = h.get("home", d)
			cand = _polar(hc, _tangent_at(hc), rad_to_deg(_rng.randf_range(0.0, 1.2) / p.radius), _rng.randf_range(0.0, 360.0))
			if p.surface_distance(cand, d) > HOPPER_HOP_M.y * 1.3:
				cand = p.step_dir(d, cand, _rng.randf_range(HOPPER_HOP_M.x, HOPPER_HOP_M.y))
		if p.nearest_prop_distance(cand) >= 0.45 and rad_to_deg(cand.angle_to(_pad_dir)) > 12.0 and not _in_keep_clear(cand, 0.2):
			return cand
	return d


func _away_target(h: Dictionary, from: Vector3) -> Vector3:
	var p := safari.planet
	var d: Vector3 = h["dir"]
	var away := _toward(d, d * 2.0 - p.dir_of(from))
	var cand := p.step_dir(d, (d + away * 0.2).normalized(), HOPPER_HOP_M.y)
	return cand if p.nearest_prop_distance(cand) >= 0.45 and not _in_keep_clear(cand, 0.2) else _free_hop_target(h)


func _hop_plan(h: Dictionary, to: Vector3, apex: float) -> void:
	h["from"] = h["dir"]
	h["to"] = to
	h["air"] = 0.0
	h["apex"] = apex
	h["air_sec"] = HOPPER_AIR_SEC * sqrt(maxf(apex, 0.05) / HOPPER_HOP_H)
	h["state"] = Hop.AIR
	h["squat"] = 0.0
	var way := _toward(h["dir"], to)
	if safari.planet.surface_distance(h["dir"], to) > 0.05:
		h["face"] = way


func _turn_face(h: Dictionary, want: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = h["dir"]
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = h["face"]
	cur -= d * cur.dot(d)
	h["face"] = cur.normalized().slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_hopper(i: int, h: Dictionary) -> void:
	var st: int = h["state"]
	if st == Hop.GONE:
		_hop_herd.hide_one(i)
		return
	var sink := 0.0
	if st == Hop.POP:
		sink = 0.42 * clampf(float(h["timer"]) / SCOUT_POP_SEC, 0.0, 1.0)
	var sq := float(h["squat"])
	var crouch := 0.82 if st == Hop.CROUCH else 1.0
	var stretch := 1.12 if st == Hop.AIR and float(h["air"]) < 0.5 * float(h["air_sec"]) else 1.0
	var sy := lerpf(1.0, 0.5, sq) * crouch * stretch
	var sx := lerpf(1.0, 1.08, sq) / sqrt(crouch * stretch)
	var base := _xf_ground(h["dir"], h["face"]).translated_local(Vector3(0.0, float(h["h"]) - sink - 0.03 * sq, 0.0))
	base.basis = base.basis * Basis.from_scale(Vector3(sx, sy, sx))
	_hop_herd.pose(i, 0, base)


## THE PACING DIRECTOR brings a scout: up out of the soil where you look (or, looking over the
## ground, boinging up into the view).
func _bring_hopper(spot: Dictionary) -> bool:
	var i := -1
	for k in _hoppers.size():
		if int(_hoppers[k]["ring"]) < 0 and int(_hoppers[k]["state"]) == Hop.GONE:
			i = k
			break
	if i < 0:
		return false
	var d: Vector3 = spot["dir"]
	var apex := HOPPER_HOP_H
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		d = spot["ahead"]
		apex = maxf(float(spot["rise"]) + SCOUT_BIG_SPARE, 0.6)
	if _in_keep_clear(d, 0.3):
		return false
	var h: Dictionary = _hoppers[i]
	h["dir"] = d
	h["home"] = d
	var lens: Transform3D = spot["lens"]
	h["face"] = _toward(d, safari.planet.dir_of(lens.origin))
	h["state"] = Hop.POP
	h["timer"] = SCOUT_POP_SEC
	h["pop_apex"] = apex
	h["out_t"] = 0.0
	h["squat"] = 0.0
	h["h"] = 0.0
	var here := safari.planet.surface_point(d)
	safari.puff_at(here + safari.planet.up_at(here) * 0.05, 8, Color("#d9cfe6"))
	AudioManager.play_sfx_at("jump", here, -8.0, 0.25)
	return true


# ---------------------------------------------------------------------------------------- glow-jellies
func _build_jellies() -> void:
	var p := safari.planet
	for k in JELLY_N:
		var roam := k < JELLY_ROAMERS
		var watch := k >= JELLY_ROAMERS and k < JELLY_ROAMERS + JELLY_WATCHERS
		var d := safari.start_dir
		if roam:
			var f: Vector2 = JELLY_FROM[k]
			d = _free_near(safari.dir_from_start(f.x, f.y), 0.8)
		_jellies.append({"dir": d, "head": _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU)),
			"state": Jel.DRIFT if roam else Jel.AWAY, "roamer": roam, "timer": 0.0, "out_t": 0.0,
			"alt": JELLY_ALT, "grow": 1.0 if roam else 0.0, "turn": 0.0, "turn_t": 0.0,
			"phase": _rng.randf_range(0.0, TAU), "hello": 0.0, "back": false, "watch": watch})
	_jelly_herd = Herd.new()
	add_child(_jelly_herd)
	var r := p.radius + 6.0
	_jelly_herd.setup("GlowJellies", JELLY_N, [[Meshes.jelly_bell(), _glow_cyan, false], [Meshes.jelly_frills(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_jelly_focus = Node3D.new()
	_jelly_focus.name = "JellyFocus"
	add_child(_jelly_focus)
	safari.add_subject({
		"id": "glow_jelly", "name": "Glow-jelly", "kind": "creature",
		"band": BAND_JELLY, "node": _jelly_focus, "offset": Vector3(0.0, 0.0, 0.0), "radius": 0.28,
		"awake": func() -> bool: return _jelly_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _jelly_pick >= 0 and int(_jellies[_jelly_pick]["state"]) == Jel.HELLO:
				return {"mult": 1.8, "line": "twirling hello"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_jelly_focus),
	})


func _jelly_out(j: Dictionary) -> bool:
	return int(j["state"]) in [Jel.DRIFT, Jel.HELLO] or (int(j["state"]) == Jel.COME and float(j["grow"]) > 0.7)


func _jelly_pos(j: Dictionary) -> Vector3:
	var d: Vector3 = j["dir"]
	var lift := float(j["alt"]) + 0.08 * sin(_t * 1.3 + float(j["phase"]))
	if int(j["state"]) in [Jel.COME, Jel.LEAVE]:
		lift += 1.2 * (1.0 - float(j["grow"]))
	return safari.planet.surface_point(d) + safari.planet.up_at(safari.planet.surface_point(d)) * lift


func _tick_jellies(delta: float) -> void:
	if _jelly_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var still_up := safari.camera_up and safari.player.get_tangent_velocity().length() < 0.15
	# The ROAMERS are not shy (R-ZORP band_r4: making them float away out of view after every new
	# encounter left 12 s rare windows with nothing about); only the ones the director brought are.
	var shy := pacing != null and pacing.shy("glow_jelly")
	var held := _jelly_held()
	var hello_done := false
	var rare_on := _rare_warned_or_up()
	for i in _jellies.size():
		var j: Dictionary = _jellies[i]
		if bool(j["watch"]):
			_tick_watcher(j, rare_on and not held)
		var st: int = j["state"]
		var pos := _jelly_pos(j)
		var dist := pos.distance_to(ppos)
		var in_frame := _point_in_frame(pos, 1.1)
		if st != Jel.AWAY:
			j["out_t"] = float(j["out_t"]) + delta
		# a brought jelly slips away when the director says shy; the ROAMER only while it holds the jelly
		# back (_jelly_held), and it comes back once it does not
		var slip := shy and not bool(j["roamer"]) and not bool(j["watch"])
		if bool(j["roamer"]) and held:
			slip = true
		if (_sleeping or (slip and not in_frame)) and st in [Jel.DRIFT, Jel.HELLO, Jel.COME]:
			j["state"] = Jel.LEAVE
			j["back"] = bool(j["roamer"]) and not _sleeping
			st = Jel.LEAVE
		match st:
			Jel.AWAY:
				if bool(j["back"]) and not shy and not (held and bool(j["roamer"])) and not _sleeping:
					j["back"] = false
					j["state"] = Jel.COME
					j["out_t"] = 0.0
			Jel.COME:
				j["grow"] = move_toward(float(j["grow"]), 1.0, delta / JELLY_COME_SEC)
				if float(j["grow"]) >= 1.0:
					j["state"] = Jel.DRIFT
			Jel.LEAVE:
				j["grow"] = move_toward(float(j["grow"]), 0.0, delta / JELLY_LEAVE_SEC)
				if float(j["grow"]) <= 0.0:
					j["state"] = Jel.AWAY
			Jel.DRIFT:
				# curious: to a still camera near it, it stops drifting and turns to look (and backs off a
				# little if it is closer than JELLY_KEEP_M - drifting on while facing you, it had come to
				# 0.4 m from the lens: shots_r4)
				var curious := still_up and dist < CURIOUS_M
				if not curious:
					_jelly_drift(j, delta)
				elif dist < JELLY_KEEP_M:
					var here: Vector3 = j["dir"]
					j["dir"] = p.step_dir(here, (here * 2.0 - p.dir_of(ppos)).normalized(), 0.3 * delta)
				if _hop_still >= HOPPER_HELLO_STILL and dist < JELLY_HELLO_M and not hello_done and float(j["hello"]) <= -HOPPER_HELLO_REST:
					j["state"] = Jel.HELLO
					j["hello"] = HOPPER_HELLO_SEC
					hello_done = true
					AudioManager.play_sfx_at("emote_happy", pos, -12.0, 0.2)
				elif still_up and dist < CURIOUS_M:
					_jelly_face(j, ppos, 1.8, delta)
				j["hello"] = float(j["hello"]) - delta
				if not bool(j["roamer"]) and not bool(j["watch"]) and float(j["out_t"]) > JELLY_OUT_MIN_SEC and dist > JELLY_LEAVE_M and not in_frame:
					j["state"] = Jel.LEAVE
			Jel.HELLO:
				j["hello"] = float(j["hello"]) - delta
				_jelly_face(j, ppos, 6.0, delta)
				if float(j["hello"]) <= 0.0 or not still_up:
					j["state"] = Jel.DRIFT
					j["hello"] = 0.0
		_pose_jelly(i, j)
	_jelly_pick = _pick_focus(_jellies, func(j: Dictionary) -> bool: return _jelly_out(j),
		func(j: Dictionary) -> Vector3: return _jelly_pos(j), 0.0)
	if _jelly_pick >= 0:
		var j: Dictionary = _jellies[_jelly_pick]
		var pos := _jelly_pos(j)
		_jelly_focus.global_transform = Transform3D(Basis.looking_at(j["head"], p.up_at(pos)), pos)


## True from a rare event's warning to its end (the Great Bloom; the Twin-Moon Glow on a rare day).
func _rare_warned_or_up() -> bool:
	if bool(_eligible.get("great_bloom", false)) and _t >= BLOOM_START - WARN and _t < BLOOM_END:
		return true
	return bool(_eligible.get("twin_moon_glow", false)) and _t >= MOON_START - WARN and _t < MOON_END


## A WATCHER comes out somewhere you are not looking when a rare event is warned, and floats off
## (out of your view) after it - but not while the director would not bring a jelly for its share
## (_jelly_held: the watchers were 4 of the careful player's 33 jelly photos, c2zorp_out/g4). The density
## gate's wanderer takes no photos, so nothing is ever held for it and the watchers still come for it.
func _tick_watcher(j: Dictionary, rare_on: bool) -> void:
	var st: int = j["state"]
	if rare_on and st == Jel.AWAY and not _sleeping:
		var p := safari.planet
		for tries in 12:
			var d := _polar(_player_dir(), _tangent_at(_player_dir()), _rng.randf_range(35.0, 150.0), _rng.randf_range(0.0, 360.0))
			var pos := p.surface_point(d) + p.up_at(p.surface_point(d)) * JELLY_ALT
			if p.nearest_prop_distance(d) >= 1.0 and not _point_in_frame(pos, 1.2):
				j["dir"] = d
				j["head"] = _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
				j["state"] = Jel.COME
				j["grow"] = 0.0
				j["out_t"] = 0.0
				return
	elif not rare_on and st in [Jel.DRIFT, Jel.HELLO] and not _point_in_frame(_jelly_pos(j), 1.1):
		j["state"] = Jel.LEAVE


func _jelly_drift(j: Dictionary, delta: float) -> void:
	var p := safari.planet
	var d: Vector3 = j["dir"]
	var head: Vector3 = j["head"]
	head = (head - d * head.dot(d)).normalized()
	j["turn_t"] = float(j["turn_t"]) - delta
	if float(j["turn_t"]) <= 0.0:
		j["turn_t"] = _rng.randf_range(2.0, 5.0)
		j["turn"] = _rng.randf_range(-0.35, 0.35)
	var turn := float(j["turn"])
	# steer round props and away from the pad: look a metre ahead
	var ahead := p.step_dir(d, (d + head * 0.2).normalized(), 1.0)
	if p.nearest_prop_distance(ahead) < 1.0 or rad_to_deg(ahead.angle_to(_pad_dir)) < 14.0 or _in_keep_clear(ahead, 0.4):
		turn = 1.2 if turn >= 0.0 else -1.2
	head = head.rotated(d, turn * delta).normalized()
	var nd := p.step_dir(d, (d + head * 0.2).normalized(), JELLY_SPEED * delta)
	# parallel transport the heading onto the new spot
	if d.dot(nd) < 0.9999999:
		head = Quaternion(d, nd) * head
	j["dir"] = nd
	j["head"] = (head - nd * head.dot(nd)).normalized()


func _jelly_face(j: Dictionary, world_pos: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = j["dir"]
	var want := world_pos - safari.planet.surface_point(d)
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = j["head"]
	j["head"] = cur.slerp(want.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_jelly(i: int, j: Dictionary) -> void:
	var st: int = j["state"]
	if st == Jel.AWAY:
		_jelly_herd.hide_one(i)
		return
	var pos := _jelly_pos(j)
	var up := safari.planet.up_at(pos)
	var g := lerpf(0.4, 1.0, float(j["grow"])) if st != Jel.LEAVE else maxf(float(j["grow"]), 0.001)
	# a swim stroke: the bell squeezes and relaxes; a hello adds a little spin
	var ph := _t * 3.8 + float(j["phase"])
	var sq := 1.0 + 0.09 * sin(ph)
	var head: Vector3 = j["head"]
	if st == Jel.HELLO:
		head = head.rotated(up, 0.35 * sin(_t * 9.0))
	var b := Basis.looking_at(head, up)
	var bell := Transform3D(b * Basis.from_scale(Vector3(g / sqrt(sq), g * sq, g / sqrt(sq))), pos)
	_jelly_herd.pose(i, 0, bell)
	var fr := Transform3D(b * Basis.from_scale(Vector3(g, g * (1.0 + 0.12 * sin(ph - 0.8)), g)), pos)
	_jelly_herd.pose(i, 1, fr)


## THE PACING DIRECTOR brings a jelly: it drifts down out of the sky into the middle of the view.
func _bring_jelly(spot: Dictionary) -> bool:
	var i := -1
	for k in _jellies.size():
		var j: Dictionary = _jellies[k]
		if int(j["state"]) == Jel.AWAY and not bool(j["back"]) and not bool(j["watch"]):
			i = k
			break
	if i < 0:
		return false
	var d: Vector3 = spot["dir"]
	var alt := JELLY_ALT
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		d = spot["ahead"]
		alt = maxf(float(spot["rise"]) + pacing.SPOT_LIFT_M, JELLY_ALT)
	if _in_keep_clear(d, 0.4):
		return false
	var j: Dictionary = _jellies[i]
	var lens: Transform3D = spot["lens"]
	j["dir"] = d
	j["alt"] = alt
	j["head"] = _toward(d, safari.planet.dir_of(lens.origin))
	j["state"] = Jel.COME
	j["grow"] = 0.0
	j["out_t"] = 0.0
	j["hello"] = 0.0
	AudioManager.play_sfx_at("collect_stardust", _jelly_pos(j), -14.0, 0.2)
	return true


# ---------------------------------------------------------------------------------------- lantern-beetles
func _build_beetles() -> void:
	var p := safari.planet
	var pts: Array = []
	for bi: int in BEETLE_BEDS:
		var d: Vector3 = _bed_dirs[bi]
		var c := p.surface_point(d) + p.up_at(p.surface_point(d)) * BEETLE_ALT
		_swarms.append({"c": c, "dir": d, "fade": 1.0, "stray": false, "out": true, "out_t": 0.0})
		pts.append(c)
	# THE STRAY SWARM: dark until the director brings it (_bring_beetles)
	_swarms.append({"c": p.surface_point(safari.start_dir), "dir": safari.start_dir, "fade": 0.0, "stray": true,
		"out": false, "out_t": 0.0})
	for si in _swarms.size():
		for k in BEETLES_PER_SWARM:
			_beetles.append({"swarm": si, "ang": TAU * float(k) / float(BEETLES_PER_SWARM) + _rng.randf_range(-0.3, 0.3),
				"r": _rng.randf_range(0.45, 0.85), "speed": _rng.randf_range(0.7, 1.2) * (1.0 if k % 2 == 0 else -1.0),
				"bob": _rng.randf_range(0.0, TAU), "pos": Vector3.ZERO, "head": Vector3.FORWARD})
	_beetle_herd = Herd.new()
	add_child(_beetle_herd)
	var r := p.radius + 4.0
	_beetle_herd.setup("LanternBeetles", _beetles.size(), [[Meshes.beetle(), _prop, false], [Meshes.beetle_lantern(), _glow_warm, false]],
		AABB(p.global_position - Vector3.ONE * r, Vector3.ONE * r * 2.0))
	_beetle_focus = Node3D.new()
	_beetle_focus.name = "BeetleFocus"
	add_child(_beetle_focus)
	safari.add_subject({
		"id": "lantern_beetle", "name": "Lantern-beetles", "kind": "creature",
		"band": BAND_BEETLES, "node": _beetle_focus, "radius": 0.8,
		"awake": func() -> bool: return _beetle_pick >= 0,
		"moment": func(tt: float) -> Dictionary:
			if fmod(tt, BEETLE_RING_EVERY) < BEETLE_RING_SEC:
				return {"mult": 1.8, "line": "lanterns in a ring"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _beetle_front(),
	})


## THE PACING DIRECTOR brings the STRAY SWARM (night only): its lanterns light up where you look, BEETLE_ALT
## over the ground spot (or, looking over the ground, at the height the director's "rise" asks for).
func _bring_beetles(spot: Dictionary) -> bool:
	if not _stray_free():
		return false
	var p := safari.planet
	var d: Vector3 = spot["dir"]
	var alt := BEETLE_ALT
	if d == Vector3.ZERO:
		if spot["ahead"] == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		d = spot["ahead"]
		alt = maxf(float(spot["rise"]) + pacing.SPOT_LIFT_M, BEETLE_ALT)
	if _in_keep_clear(d, 0.5):
		return false
	var sw: Dictionary = _swarms[-1]
	var g := p.surface_point(d)
	sw["dir"] = d
	sw["c"] = g + p.up_at(g) * alt
	sw["out"] = true
	sw["out_t"] = 0.0
	sw["fade"] = 0.0
	AudioManager.play_sfx_at("collect_stardust", sw["c"], -16.0, 0.35)
	return true


## The stray swarm is dark and free to be brought.
func _stray_free() -> bool:
	if _swarms.is_empty() or not bool(_swarms[-1]["stray"]):
		return false
	var sw: Dictionary = _swarms[-1]
	return not bool(sw["out"]) and float(sw["fade"]) <= 0.01


## The heading of the beetle of the picked swarm nearest the lens.
func _beetle_front() -> Vector3:
	if _beetle_pick < 0:
		return Vector3.ZERO
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var best := INF
	var out := Vector3.ZERO
	for b: Dictionary in _beetles:
		if int(b["swarm"]) != _beetle_pick:
			continue
		var dd := (b["pos"] as Vector3).distance_to(cam.global_position) if cam != null else 0.0
		if dd < best:
			best = dd
			out = b["head"]
	return out


func _tick_beetles(delta: float) -> void:
	if _beetle_herd == null:
		return
	var p := safari.planet
	var shy := pacing != null and pacing.shy("lantern_beetle")
	var ringed := fmod(_t, BEETLE_RING_EVERY) < BEETLE_RING_SEC
	var ppos := safari.player.global_position
	for si in _swarms.size():
		var sw: Dictionary = _swarms[si]
		var c: Vector3 = sw["c"]
		var in_frame := _point_in_frame(c, 1.1)
		# out of the frame when the director says shy (something new was just seen, or the beetles are over
		# their share): the lanterns go out and they slip away
		var hide := _sleeping or (shy and not in_frame)
		if bool(sw["stray"]):
			if not bool(sw["out"]):
				hide = true
			else:
				sw["out_t"] = float(sw["out_t"]) + delta
				var left := float(sw["out_t"]) > BEETLE_STRAY_OUT_SEC and c.distance_to(ppos) > BEETLE_STRAY_LEAVE_M \
					and not in_frame
				if hide or left:
					sw["out"] = false
					hide = true
		sw["fade"] = move_toward(float(sw["fade"]), 0.0 if hide else 1.0, delta * (3.0 if hide else 0.8))
	for i in _beetles.size():
		var b: Dictionary = _beetles[i]
		var sw: Dictionary = _swarms[int(b["swarm"])]
		var f := float(sw["fade"])
		if f <= 0.01:
			_beetle_herd.hide_one(i)
			continue
		b["ang"] = float(b["ang"]) + float(b["speed"]) * delta
		var c: Vector3 = sw["c"]
		var up := p.up_at(c)
		var t0 := _tangent_at(p.dir_of(c))
		var t1 := up.cross(t0).normalized()
		var r := float(b["r"]) if not ringed else 0.5
		var a := float(b["ang"])
		var bob := 0.18 * sin(_t * 2.1 + float(b["bob"])) if not ringed else 0.0
		var pos := c + (t0 * cos(a) + t1 * sin(a)) * r * (0.6 + 0.4 * f) + up * bob
		var head := (-t0 * sin(a) + t1 * cos(a)) * signf(float(b["speed"]))
		b["pos"] = pos
		b["head"] = head
		var s := 2.2 * f
		_beetle_herd.pose(i, 0, Transform3D(Basis.looking_at(head, up).scaled(Vector3.ONE * s), pos))
		_beetle_herd.pose(i, 1, Transform3D(Basis.looking_at(head, up).scaled(Vector3.ONE * s), pos))
	_beetle_pick = -1
	var cands: Array = []
	for si in _swarms.size():
		cands.append(_swarms[si])
	_beetle_pick = _pick_focus(cands, func(sw: Dictionary) -> bool: return float(sw["fade"]) > 0.6,
		func(sw: Dictionary) -> Vector3: return sw["c"], 0.0)
	if _beetle_pick >= 0:
		var c: Vector3 = _swarms[_beetle_pick]["c"]
		_beetle_focus.global_transform = Transform3D(Basis.looking_at(_tangent_at(p.dir_of(c)), p.up_at(c)), c)


# ---------------------------------------------------------------------------------------- Zorp
func _build_zorp() -> void:
	_zorp = safari.world.get_node_or_null("NPCs/zorp") as Node3D
	if _zorp == null:
		return
	_zorp_saved = _zorp.global_transform
	_zorp_wander_saved = bool(_zorp.get("_wander_on")) if _zorp.get("_wander_on") != null else true
	safari.add_subject({
		"id": "zorp", "name": "Zorp", "kind": "neighbour",
		"band": BAND_ZORP, "node": _zorp, "offset": Vector3(0.0, 0.75, 0.0), "radius": 0.7,
		# At a bed he IS the watering (that subject scores him, with his front): one subject, not two.
		"awake": func() -> bool: return is_instance_valid(_zorp) and _zorp.is_visible_in_tree() and not _zorp_borrowed,
		"moment": func(_tt: float) -> Dictionary:
			if _t < _zorp_pose_until:
				return {"mult": 1.8, "line": "striking a pose"}
			if _t < _zorp_wave_until:
				return {"mult": 1.6, "line": "waving at you"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_zorp),
	})


func _tick_zorp(_delta: float) -> void:
	if _zorp == null or not is_instance_valid(_zorp) or _sleeping or _building:
		return
	if _zorp_hop_t >= 0.0:
		var k := clampf((_t - _zorp_hop_t - ZORP_HOP_HANG_SEC) / _zorp_hop_sec, 0.0, 1.0)
		var xf := _zorp_hop_ground
		_zorp.global_transform = xf.translated(safari.planet.up_at(xf.origin) * _zorp_hop_apex * (1.0 - k * k))
		if k >= 1.0:
			_end_zorp_hop()
			AudioManager.play_sfx_at("land", xf.origin, -10.0, 0.2)
	var run := _run_at(WATER_RUNS, _t, true)
	if not run.is_empty():
		if not _zorp_borrowed or _water_at != int(run["at"]):
			_borrow_zorp(int(run["at"]))
		_zorp_still_on = 0.0
		return
	if _zorp_borrowed:
		_release_zorp(false)
		_zorp.call("play_emote", "happy")
		_zorp_pose_until = _t + 1.6
	if _zorp_stay_until > -INF and _t >= _zorp_stay_until:
		_zorp_stay_until = -INF
		if _zorp.has_method("wander_enabled"):
			_zorp.call("wander_enabled", _zorp_wander_saved)
	var pl := safari.player
	var dist := _zorp.global_position.distance_to(pl.global_position)
	# brought: he looks about at what you are photographing, then notices you (see ZORP_LOOK_SEC)
	if _zorp_look_until > -INF and _t >= _zorp_look_until:
		_end_zorp_look()
	# THE PROXIMITY WAVE: walk up to him and he waves - once per ZORP_WAVE_REST, not while he is looking
	# about, not in the hop (spec 17.1 rule 8: a moment is waited for, not a gift of every coming)
	if dist < ZORP_WAVE_M and _t >= _zorp_next_wave and _zorp_look_until == -INF and _zorp_hop_t < 0.0:
		_zorp.call("face_player", true)
		_zorp.call("play_emote", "wave")
		_zorp_wave_until = _t + 1.6
		_zorp_next_wave = _t + ZORP_WAVE_REST
	# he poses for a camera held still ON HIM (within 10 degrees, not in the hop) for HOPPER_HELLO_STILL, the
	# creatures' hello: THE PATIENT PLAYER'S MOMENT. While he is looking about it is also what makes him
	# notice you. Counted on him, not on the camera alone: a camera already held still on an empty spot
	# would otherwise pose him the instant he landed in it (n3zorp arrival probe, pitch -10: "striking a
	# pose" 0.36 s after the bring) - the gift of a coming this round removes.
	var cam := safari.rig.get_view_camera()
	var on_him := false
	if cam != null and _hop_still > 0.0 and dist < 7.0 and _zorp_hop_t < 0.0:
		var to := (_zorp.global_position + safari.planet.up_at(_zorp.global_position) * 0.75 - cam.global_position).normalized()
		on_him = to.dot(-cam.global_transform.basis.z) > cos(deg_to_rad(10.0))
	_zorp_still_on = (_zorp_still_on + _delta) if on_him else 0.0
	if _zorp_still_on >= HOPPER_HELLO_STILL and _t >= _zorp_next_pose:
		_end_zorp_look()
		_zorp.call("face_player", true)
		_zorp.call("play_emote", "happy")
		_zorp_pose_until = _t + 1.8
		_zorp_next_pose = _t + 6.0
		_zorp_next_wave = maxf(_zorp_next_wave, _t + ZORP_WAVE_REST)


## He stops looking about and turns to you (his idle look-at does the turn; no emote, no moment).
func _end_zorp_look() -> void:
	if _zorp_look_until == -INF:
		return
	_zorp_look_until = -INF
	if _zorp != null and is_instance_valid(_zorp) and _zorp.has_method("release_facing"):
		_zorp.call("release_facing")


func _borrow_zorp(bed: int) -> void:
	_end_zorp_hop()
	_end_zorp_look()
	var first := not _zorp_borrowed
	_zorp_borrowed = true
	_water_at = bed
	var from := _zorp.global_position
	_zorp.call("play_emote", "wave")
	safari.puff_at(from, 20, Color("#d9cfe6"))
	if first:
		if _zorp.has_method("wander_enabled"):
			_zorp.call("wander_enabled", false)
		_zorp.set_physics_process(false)
	_zorp_bed_xf = _bed_stand(bed)
	_zorp.global_transform = _zorp_bed_xf
	safari.puff_at(_zorp_bed_xf.origin, 20, Color("#d9cfe6"))
	_zorp.set("_speed_factor", 0.0)


## Where Zorp stands to water bed `bed`: beside it on the side toward the start (so a walker coming
## from the pad sees him three-quarters on), facing the bed's middle.
func _bed_stand(bed: int) -> Transform3D:
	var p := safari.planet
	var c: Vector3 = _bed_dirs[bed]
	var toward_start := _toward(c, safari.start_dir)
	var side := toward_start.cross(c).normalized()
	var stand := _polar(c, (toward_start + side * 0.6).normalized(), rad_to_deg(0.95 / p.radius), 0.0)
	stand = _free_near_small(stand, 0.45)
	var g := p.surface_point(stand)
	var face := p.surface_point(c) - g
	var up := p.up_at(g)
	face -= up * face.dot(up)
	return Transform3D(Basis.looking_at(face.normalized(), up), g)


func _free_near_small(d: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(d) >= clear_m:
		return d
	var t := _tangent_at(d)
	for deg in [1.0, 2.0, 3.0, 4.0]:
		for k in 8:
			var c := _polar(d, t, deg, 45.0 * float(k))
			if p.nearest_prop_distance(c) >= clear_m:
				return c
	return d


## A hop is over (landed, or cut short): he stands on the ground and his own physics runs again.
func _end_zorp_hop() -> void:
	if _zorp_hop_t < 0.0:
		return
	_zorp_hop_t = -1.0
	if _zorp != null and is_instance_valid(_zorp):
		_zorp.global_transform = _zorp_hop_ground
		if not _zorp_borrowed:
			_zorp.set_physics_process(true)
		if _zorp is CharacterBody3D:
			(_zorp as CharacterBody3D).velocity = Vector3.ZERO


## Gives Zorp back to his own script. `home` also puts him back where he stood before the safari.
func _release_zorp(home: bool) -> void:
	if _zorp == null or not is_instance_valid(_zorp):
		return
	_end_zorp_hop()
	_end_zorp_look()
	if _zorp_borrowed:
		_zorp.set("_speed_factor", 0.0)
		_zorp.set_physics_process(true)
		if _zorp.has_method("wander_enabled"):
			_zorp.call("wander_enabled", _zorp_wander_saved)
	_zorp_borrowed = false
	if _zorp_stay_until > -INF or home:
		_zorp_stay_until = -INF
		if _zorp.has_method("wander_enabled"):
			_zorp.call("wander_enabled", _zorp_wander_saved)
	if home:
		_zorp.global_transform = _zorp_saved
		if _zorp is CharacterBody3D:
			(_zorp as CharacterBody3D).velocity = Vector3.ZERO


## THE PACING DIRECTOR brings ZORP (his own curiosity): when it has gone quiet he pops over with a puff
## to see what you are photographing, then wanders home on his own. Not while he is at a bed (or about
## to be), not when he is already near you or in view, and not twice within ZORP_COME_REST s. A third
## bringer by day, so the director can vary what it brings (spec 13.2: with only the hopper and the
## jelly, the careful test player's photos were 42% jellies and 33% hoppers - cal_r1 in the report).
const ZORP_COME_REST := 6.0
## ...and only when he is more than this far from you (and out of the frame). Round 1 had 8 m: after a
## coming he stays ZORP_STAY_SEC beside you, so the next could not come until you had walked 8 m off, and
## by day - three bringers, Zorp the third - he was brought 19 times in 12 careful safaris against the
## hoppers' 37 and the jellies' 31 (c2zorp_out/g1); the director made up his share with jellies (34% by day).
## Round 2 had 4.0 m. Now (spec 17.1 rule 8) he comes to ZORP_MIN_M or more, so this is set past the
## farthest of ZORP_NEAR_M: he is brought again only once he has wandered off or you have walked off.
const ZORP_AWAY_M := 5.0
## HIS WAVE (spec 17.1 rule 8, critic r2 of 2026-09-27: 16 of 21 careless Zorp photos and 24 of 24 careful
## ones were Gallery, every one a caught moment at 2.5-2.9 m). He used to come to 2.2-3 m, inside his
## 3.6 m wave, and wave as he landed: every coming was a Gallery handed over. Now:
##   * he waves when you come within ZORP_WAVE_M (3.6 m, unchanged), at most once per ZORP_WAVE_REST;
##   * he COMES TO ZORP_MIN_M or more from you (the wave range and 0.4 m to spare), and does not wave;
##   * he LOOKS ABOUT for ZORP_LOOK_SEC after landing - side-on, at whatever you were photographing - then
##     notices you and turns to you (no emote, no moment);
##   * THE MOMENT is waited for: hold the camera still on him HOPPER_HELLO_STILL (2.5 s, the creatures'
##     hello) and he poses ("striking a pose"), and that also ends his looking about.
## So a raise-and-tap gets him side-on with no moment; a player who waits gets him facing, and one who
## holds still on him gets the pose.
const ZORP_WAVE_M := 3.6
const ZORP_WAVE_REST := 20.0
const ZORP_MIN_M := 4.0
## "A second or two" of looking about after he lands, random so the turn is not a clockwork beat. SET BY
## MEASUREMENT, said plainly: with the pose counted on him (below), it decides how often a player who shoots
## the moment he turns has already held the camera on him 2.5 s. Careful test player, Zorp Galleries: 1.5-4.5 s
## 23/23 and 0.5-2.0 s 15/24 (pose then counted on the camera alone, n3zorp r1, r2); 0.5-1.5 s 11/28 (r3),
## then 2/24 in 2 of 10 safaris once the pose was counted on him (r4). This is the fifth setting.
const ZORP_LOOK_SEC := Vector2(1.0, 2.5)
## How far off the line to you he looks while looking about (degrees): side-on (Facing 5).
const ZORP_LOOK_YAW := 90.0
var _zorp_look_until := -INF
var _zorp_still_on := 0.0     # seconds the camera has been held still on him (the pose, _tick_zorp)
## WHERE HE COMES TO: a spot ZORP_MIN_M or more from you, straight along the view (ZORP_NEAR_M metres round
## the surface, turned ZORP_NEAR_YAW), where ALL OF HIM - his feet (ZORP_FOOT_M up) to the top of his head
## (ZORP_TOP_M up) - is inside the middle ZORP_VIEW_FRAC of where the lens will be looking, with a clear
## line to his feet, middle and top: on the ground if there is such a spot, else the lowest HOP that shows
## him whole. Round 2 asked only for his MIDDLE (ZORP_MID_M, the point his photo is scored on) in view, so
## with the lens tilted up he popped in as a head at the bottom of the frame (the lead, 2026-09-27).
## LOOKING OVER THE DECK (the lens level or up: on this planet of radius 10.5 no ground is in view above a
## pitch of about -2 degrees, and the horizon is ~4.4 m off) he comes in with a HOP: he pops up
## ZORP_HOP_STEP_M steps (up to ZORP_HOP_MAX_M) over the spot, just high enough to be seen whole, and drops
## onto it at ZORP_HOP_G - the fall of round 2's hop (1.2 m in 0.7 s), kept, so a higher hop takes longer.
## A spot farther than the horizon hides his feet behind the planet, so the sight test sends him up a hop.
## SINCE 2026-09-27 (spec 17.3 ruling 2) ONLY THE GROUND SPOT, WHOLE: `_zorp_spot` asks for his feet too and
## lift 0, so no hop and no waist-up landing is offered any more (the hop branch in _bring_zorp stays but is
## not reached); with no ground in view he does not come and the director brings a hopper or a jelly.
## Before that: his middle and head top inside the middle ZORP_VIEW_FRAC once he stands on the spot - whole
## if the ground is in view, else waist-up (n3zorp r7 probe: +3 deg came waist-up, +6 deg did not). Round 3 hopped him in whole at any pitch; with the lens at +14 deg he
## then dropped out of the frame's bottom (critic r1: in 7 of 20 real brings even his head top ended outside).
const ZORP_MID_M := 0.75
const ZORP_FOOT_M := 0.05
## His model's world AABB reaches 1.56-1.58 m (an over-estimate: box corners); 1.3 m kept inside the middle 0.9
## of the frame leaves ~0.2 m spare at 4-5 m, and the arrival frames (n3zorp_out/arrival_final) show his whole head.
const ZORP_TOP_M := 1.3
const ZORP_VIEW_FRAC := 0.9
const ZORP_NEAR_M: Array = [4.2, 4.5, 4.0, 4.8]
const ZORP_NEAR_YAW: Array = [0.0, 12.0, -12.0]
const ZORP_HOP_STEP_M := 0.15
const ZORP_HOP_MAX_M := 2.7
const ZORP_HOP_G := 2.0 * 1.2 / (0.7 * 0.7)
## ...after hanging at the top this long, where all of him is in view: with the lens tilted up he lands
## below the frame (no ground is in view there), so the pop-in is the moment he is seen whole. A stated pick.
const ZORP_HOP_HANG_SEC := 0.3
var _zorp_hop_t := -1.0
var _zorp_hop_apex := 0.0
var _zorp_hop_sec := 0.7
var _zorp_hop_ground := Transform3D()
## Once he has come he stays put this long (his wandering held), turned to you, then wanders on. (Walking
## straight off home, he was photographed after 28 of 61 comings, against the jellies' 46 of 53: cal_r8.)
const ZORP_STAY_SEC := 10.0
var _zorp_stay_until := -INF
const ZORP_COME_LINES := ["Zorp: \"Ooh! What are we photographing?\"", "Zorp: \"Is it me? It can be me!\"",
	"Zorp: \"Hello! Zorp is here for science!\""]
var _zorp_came_at := -INF
var _zorp_came_n := 0


## See WHERE HE COMES TO above: {"d": ground direction, "lift": metres up he pops in at (0 = on the
## ground)}, or {} when there is no such spot.
func _zorp_spot(spot: Dictionary) -> Dictionary:
	var p := safari.planet
	var lens: Transform3D = spot["lens"]
	var pd := p.dir_of(lens.origin)
	var fwd := -lens.basis.z
	fwd -= pd * fwd.dot(pd)
	if fwd.length() < 0.01:
		fwd = -lens.basis.y - pd * (-lens.basis.y).dot(pd)
	if fwd.length() < 0.01:
		return {}
	fwd = fwd.normalized()
	# from where you stand now AND where the lens will be (the director leads it SPOT_LEAD_SEC)
	var here := safari.player.global_position
	var there := p.surface_point(pd)
	var cands: Array = []
	for m: float in ZORP_NEAR_M:
		for yaw: float in ZORP_NEAR_YAW:
			var dirn := fwd.rotated(pd, deg_to_rad(yaw))
			cands.append(p.step_dir(pd, (pd * cos(0.5) + dirn * sin(0.5)).normalized(), m))
	var clear: Array = cands.filter(func(d: Vector3) -> bool:
		var g := p.surface_point(d)
		return g.distance_to(here) >= ZORP_MIN_M and g.distance_to(there) >= ZORP_MIN_M \
			and p.nearest_prop_distance(d) >= 0.6 and rad_to_deg(d.angle_to(_pad_dir)) >= 15.0 and not _in_keep_clear(d, 0.4))
	# ONLY WHOLE, STANDING ON THE GROUND (spec 17.3 ruling 2): feet, middle and head top all inside the
	# middle ZORP_VIEW_FRAC with a clear line to each, lift 0. With the lens level or tilted up no ground
	# spot passes, so he does not come and the director brings someone else (the lead: "a lens tilted too
	# high simply does not get him"). Round 3's waist-up landing and its hop are no longer offered.
	for d: Vector3 in clear:
		if _zorp_whole_from(lens, p.surface_point(d), 0.0):
			return {"d": d, "lift": 0.0}
	return {}


## True when all of him standing `lift` m over ground point `g` - feet, middle and the top of his head - is
## inside the middle ZORP_VIEW_FRAC of the view from `lens`, with a clear line to each.
func _zorp_whole_from(lens: Transform3D, g: Vector3, lift: float) -> bool:
	var up := safari.planet.up_at(g)
	for h: float in [ZORP_FOOT_M, ZORP_MID_M, ZORP_TOP_M]:
		var q := g + up * (h + lift)
		if not pacing.in_view_from(lens, q, ZORP_VIEW_FRAC) or not pacing.sight_clear(lens.origin, q):
			return false
	return true


func _zorp_can_come() -> bool:
	if _zorp == null or not is_instance_valid(_zorp) or _zorp_borrowed or _sleeping:
		return false
	if _t - _zorp_came_at < ZORP_COME_REST:
		return false
	# not while a watering is warned or running, nor in the WARN before the next one
	for run: Dictionary in WATER_RUNS:
		if _t >= float(run["start"]) - WARN * 2.0 and _t < float(run["end"]):
			return false
	var head := _zorp.global_position + safari.planet.up_at(_zorp.global_position) * 0.75
	return _zorp.global_position.distance_to(safari.player.global_position) > ZORP_AWAY_M and not _point_in_frame(head, 1.1)


func _bring_zorp(spot: Dictionary) -> bool:
	if not _zorp_can_come():
		return false
	var at := _zorp_spot(spot)
	if at.is_empty():
		return false
	var d: Vector3 = at["d"]
	var lift := float(at["lift"])
	var p := safari.planet
	safari.puff_at(_zorp.global_position, 16, Color("#d9cfe6"))
	var g := p.surface_point(d)
	var up := p.up_at(g)
	var lens: Transform3D = spot["lens"]
	var to_you := lens.origin - g
	to_you -= up * to_you.dot(up)
	if to_you.length() < 0.01:
		to_you = _tangent_at(d)
	# LOOKING ABOUT: side-on (ZORP_LOOK_YAW), to one side or the other (no wave: spec 17.1 rule 8)
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var face := to_you.normalized().rotated(up, deg_to_rad(ZORP_LOOK_YAW * side))
	var ground := Transform3D(Basis.looking_at(face, up), g)
	_zorp.global_transform = ground.translated(up * lift)
	if _zorp is CharacterBody3D:
		(_zorp as CharacterBody3D).velocity = Vector3.ZERO
	_zorp_hop_sec = 0.0
	if lift > 0.0:
		# the HOP: he holds still in the air while it plays (his own physics would drop him at once)
		_zorp.set_physics_process(false)
		_zorp_hop_t = _t
		_zorp_hop_apex = lift
		_zorp_hop_sec = sqrt(2.0 * lift / ZORP_HOP_G)
		_zorp_hop_ground = ground
		AudioManager.play_sfx_at("jump", g, -6.0, 0.15)
	safari.puff_at(g + up * lift, 20, Color("#d9cfe6"))
	if _zorp.has_method("hold_facing"):
		_zorp.call("hold_facing", g + face * 5.0)
	var hop_total := (ZORP_HOP_HANG_SEC + _zorp_hop_sec) if lift > 0.0 else 0.0
	_zorp_look_until = _t + hop_total + _rng.randf_range(ZORP_LOOK_SEC.x, ZORP_LOOK_SEC.y)
	_queue_line(ZORP_COME_LINES[_zorp_came_n % ZORP_COME_LINES.size()])
	_zorp_came_n += 1
	_zorp_came_at = _t
	_zorp_stay_until = _t + ZORP_STAY_SEC
	if _zorp.has_method("wander_enabled"):
		_zorp.call("wander_enabled", false)
	return true


# ---------------------------------------------------------------------------------------- bulb beds + watering
const BULBS_PER_BED := 5
const PETALS := 5


func _build_beds() -> void:
	var p := safari.planet
	var pts: Array = []
	for bi in _bed_dirs.size():
		var c: Vector3 = _bed_dirs[bi]
		var t0 := _tangent_at(c)
		for k in BULBS_PER_BED:
			var d := c if k == 0 else _polar(c, t0, rad_to_deg(_rng.randf_range(0.32, 0.5) / p.radius), 90.0 * float(k) + _rng.randf_range(-20.0, 20.0))
			var xf := _xf_ground(d, t0.rotated(c, _rng.randf_range(0.0, TAU)))
			var s := _rng.randf_range(0.85, 1.15) * (1.2 if k == 0 else 1.0)
			xf.basis = xf.basis.scaled(Vector3.ONE * s)
			_bulbs.append({"bed": bi, "xf": xf, "s": s})
			pts.append(xf.origin)
	var area := Herd.area_around(pts, 1.5)
	_stalk_herd = Herd.new()
	add_child(_stalk_herd)
	_stalk_herd.setup("BulbStalks", _bulbs.size(), [[Meshes.bulb_stalk(), _prop, true]], area)
	_petal_herd = Herd.new()
	add_child(_petal_herd)
	_petal_herd.setup("BulbPetals", _bulbs.size() * PETALS, [[Meshes.bulb_petal(), _prop, false]], area)
	_core_herd = Herd.new()
	add_child(_core_herd)
	_core_herd.setup("BulbCores", _bulbs.size(), [[Meshes.bulb_core(), _glow_pink, false]], area)
	for i in _bulbs.size():
		var b: Dictionary = _bulbs[i]
		_stalk_herd.pose(i, 0, b["xf"])
		_core_herd.pose(i, 0, (b["xf"] as Transform3D).translated_local(Meshes.BULB_TOP))
	_pose_bulbs()
	# the can and the water
	_can = MeshInstance3D.new()
	_can.name = "WateringCan"
	_can.mesh = Meshes.watering_can()
	_can.scale = Vector3.ONE * 1.5
	_can.material_override = _prop
	_can.visible = false
	add_child(_can)
	_drops = CPUParticles3D.new()
	_drops.name = "WaterDrops"
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	_drops.mesh = q
	_drops.material_override = PlanetPropMeshes.sparkle_material(Color("#9fd2e0"))
	_drops.amount = 40
	_drops.lifetime = 0.8
	# local: gravity is then in the can's own frame, whose +Y is about the planet's up (the can only
	# tips 0.55 rad), and a duplicate drawn by the warm-up outside the tree does not ask for a transform
	_drops.local_coords = true
	_drops.gravity = Vector3(0.0, -4.0, 0.0)
	_drops.direction = Vector3(0.0, 0.0, -1.0)
	_drops.spread = 14.0
	_drops.initial_velocity_min = 0.6
	_drops.initial_velocity_max = 1.1
	_drops.scale_amount_min = 0.6
	_drops.scale_amount_max = 1.2
	_drops.emitting = false
	_can.add_child(_drops)
	_drops.position = Vector3(0.0, 0.07, -0.26)
	_water_focus = Node3D.new()
	_water_focus.name = "WaterFocus"
	add_child(_water_focus)
	safari.add_subject({
		"id": "watering", "name": "Watering Time", "kind": "event",
		"band": BAND_WATER, "node": _water_focus, "radius": 1.0,
		"awake": func() -> bool: return _any_running(WATER_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(WATER_RUNS, tt, false)
			if not run.is_empty():
				var t_in := tt - float(run["start"])
				if t_in >= WATER_OPEN_AT and t_in < WATER_OPEN_AT + WATER_OPEN_SEC:
					return {"mult": 2.0, "line": "the bulbs opening wide"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_zorp) if _zorp_borrowed else Vector3.ZERO,
	})


func _pose_bulbs() -> void:
	for i in _bulbs.size():
		var b: Dictionary = _bulbs[i]
		var open := float(_bed_open[int(b["bed"])])
		var top := (b["xf"] as Transform3D).translated_local(Meshes.BULB_TOP)
		var tilt := lerpf(-0.12, 1.15, open)
		for k in PETALS:
			var basis := Basis(Vector3.UP, TAU * float(k) / float(PETALS)) * Basis(Vector3.RIGHT, tilt)
			_petal_herd.pose(i * PETALS + k, 0, top * Transform3D(basis, Vector3(0.0, -0.03, 0.0)))


func _tick_water(delta: float) -> void:
	if _petal_herd == null:
		return
	var run := _run_at(WATER_RUNS, _t, true)
	var want := [0.0, 0.0]
	var pouring := false
	if not run.is_empty() and not _sleeping:
		var bed := int(run["at"])
		var t_in := _t - float(run["start"])
		var t_end := float(run["end"]) - float(run["start"])
		var o := 0.0
		if t_in >= 2.0 and t_in < WATER_OPEN_AT:
			o = (t_in - 2.0) / (WATER_OPEN_AT - 2.0)
		elif t_in >= WATER_OPEN_AT and t_in < t_end - 1.5:
			o = 1.0
		elif t_in >= t_end - 1.5:
			o = lerpf(1.0, 0.25, clampf((t_in - (t_end - 1.5)) / 1.5, 0.0, 1.0))
		want[bed] = o
		pouring = t_in >= 0.0 and t_in < WATER_OPEN_AT + 1.0
		_water_focus.global_transform = _xf(_bed_dirs[bed], _tangent_at(_bed_dirs[bed])).translated_local(Vector3(0.0, 0.8, 0.0))
		if _zorp_borrowed and _zorp != null:
			var zx := _zorp.global_transform
			var tip := sin(_t * 2.0) * 0.1
			_can.global_transform = zx * Transform3D(Basis(Vector3.RIGHT, -0.55 + tip if pouring else 0.0).scaled(Vector3.ONE * 1.5), Vector3(0.34, 0.6, -0.35))
			_can.visible = true
	else:
		_can.visible = false
	for k in 2:
		_bed_open[k] = move_toward(_bed_open[k], float(want[k]), delta * 0.9)
	_drops.emitting = pouring and _can.visible
	_pose_bulbs()


# ---------------------------------------------------------------------------------------- the scrapbook (15.5)
## TWO SIGHTS (always there, low rarity; "sight" category: they pay as usual but never count toward the
## density band or the pacing director) and THREE BONUS ITEMS (small and tucked away; "bonus" category:
## collector's pages that pay nothing). Where each is, as (degrees round from the start, bearing):
##   THE TENTACLE BULB BED   the two bulb beds the watering uses (BED A (43,-111), BED B (147,-106)): one
##                           subject, scored on the bed nearest the middle of the view
##   THE GREAT MUSHROOM RING GREAT_RING_AT (40,95), 7.3 m from the start off to the right: seven big
##                           toadstools with glowing spots round a circle of radius 1.35 m. Its caps peek
##                           over the horizon from the start; nothing lives in it. (At (30,110) it stood
##                           5 m from the pad and the rocket's legs were in its photo.)
##   THE SPORE GNOME         under MushroomTree6 (82,-142), on the far side of its stem from the start:
##                           hidden by the stem until you walk round it
##   ZORP'S WATERING CAN     upside down in the grass CAN_FROM_HOME_M past Zorp's home spot, away from
##                           the start, three tiny toadstools grown up round it
##   THE HEART CRYSTAL       at the foot of Crystal3 (106,-5) in the crystal field, on its far side from
##                           the start
## SIZE BANDS. A bonus item follows the creature rule of spec 11.1 from the distance a finder stands at,
## BONUS_USUAL_M (1.5 m): at the 45 degree lens there it scores 6 or less, and walking up to about 0.9 m
## or zooming fills the band (band.x = size_frac there / 0.58, band.y = 1.65 x band.x, the header's rule):
##   subject              radius  size_frac at 1.5 m  band
##   the spore gnome      0.13    0.210               0.36-0.60
##   Zorp's watering can  0.16    0.259               0.45-0.74
##   the heart crystal    0.12    0.194               0.33-0.55
## A SIGHT cannot follow it: on this 10.5 m planet the ground horizon is 4.9 m from the eye, so the ring
## can never be as small as 11.1 asks from anywhere it can be seen from. A sight is the low-rarity easy
## page, so its band is simply the size it has when all of it is in a 45 degree frame from where you stand
## to see it: the bed (r 0.85) 3-6 m away is 0.35-0.72 of the frame, band 0.45-0.9; the ring (r 1.2) 3.3-5.4
## m away, band 0.55-0.95. A stated pick, not fitted. The ring's sphere is r 1.2 at 0.85 m up, not the 1.7 m
## its toadstools spread: with its lowest sight-ray point at or below the ground (r 1.5 at 0.4 m, r 1.25 at
## 0.6 m), the ground in front of the ring stopped that ray from every distance the ring fits the frame at,
## so a careful player never had all of it in view (c2zorp_out/zp/ring_b*, ring2_b*, ring3: "Planet d=1.41").
const GREAT_RING_AT := Vector2(40.0, 95.0)
const CAN_FROM_HOME_M := 1.7
const BONUS_USUAL_M := 1.5
const BAND_BED := Vector2(0.45, 0.9)
const BAND_GREAT_RING := Vector2(0.55, 0.95)
const BAND_GNOME := Vector2(0.36, 0.60)
const BAND_CAN := Vector2(0.45, 0.74)
const BAND_HEART := Vector2(0.33, 0.55)
const GNOME_TREE := "MushroomTree6"
const HEART_CRYSTAL := "Crystal3"
## Nothing is brought, and no hopper hops, inside these (metres round each item): [dir, radius].
var _keep_clear: Array = []
var _great_ring_dir := Vector3.UP
var _bed_sight_focus: Node3D
var _scrap_nodes: Dictionary = {}   # id -> Node3D (for the probes: debug_places)


func _build_scrapbook() -> void:
	var p := safari.planet
	# --- THE TENTACLE BULB BED (sight): the bed nearest the middle of the view
	_bed_sight_focus = Node3D.new()
	_bed_sight_focus.name = "BulbBedFocus"
	add_child(_bed_sight_focus)
	_bed_sight_focus.global_transform = _xf(_bed_dirs[0], _tangent_at(_bed_dirs[0]))
	safari.add_subject({
		"id": "bulb_bed", "name": "The Tentacle Bulb Bed", "kind": "sight", "category": "sight",
		"band": BAND_BED, "node": _bed_sight_focus, "offset": Vector3(0.0, 0.35, 0.0), "radius": 0.85,
		"awake": func() -> bool: return not _sleeping,
	})
	_scrap_nodes["bulb_bed"] = _bed_sight_focus
	# --- THE GREAT MUSHROOM RING (sight)
	_great_ring_dir = _free_near(safari.dir_from_start(GREAT_RING_AT.x, GREAT_RING_AT.y), 2.1)
	var ring := Node3D.new()
	ring.name = "GreatMushroomRing"
	add_child(ring)
	ring.global_transform = _xf_ground(_great_ring_dir, _toward(_great_ring_dir, safari.start_dir))
	ring.add_child(_mesh_node("Toadstools", Meshes.great_ring(), _prop, true))
	ring.add_child(_mesh_node("Spots", Meshes.great_ring_spots(), _glow_cyan, false))
	safari.add_subject({
		"id": "great_ring", "name": "The Great Mushroom Ring", "kind": "sight", "category": "sight",
		"band": BAND_GREAT_RING, "node": ring, "offset": Vector3(0.0, 0.85, 0.0), "radius": 1.2,
		"awake": func() -> bool: return not _sleeping,
	})
	_keep_clear.append([_great_ring_dir, Meshes.GREAT_RING_R + 0.5])
	_scrap_nodes["great_ring"] = ring
	# --- THE SPORE GNOME (bonus): on the far side of the mushroom tree's stem from the start
	var gnome_dir := _behind_prop(GNOME_TREE, 0.75, safari.dir_from_start(82.0, -142.0))
	var gnome := Node3D.new()
	gnome.name = "SporeGnome"
	add_child(gnome)
	# it faces round the stem, side-on to the way you came: you meet its face as you walk round
	gnome.global_transform = _xf_ground(gnome_dir, _toward(gnome_dir, safari.start_dir).rotated(gnome_dir, deg_to_rad(100.0)))
	gnome.add_child(_mesh_node("Body", Meshes.spore_gnome(), _prop, true))
	gnome.add_child(_mesh_node("Spores", Meshes.spore_gnome_glow(), _glow_cyan, false))
	safari.add_subject({
		"id": "spore_gnome", "name": "The Spore Gnome", "kind": "bonus", "category": "bonus",
		"band": BAND_GNOME, "node": gnome, "offset": Vector3(0.0, 0.13, 0.0), "radius": 0.13,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(gnome),
	})
	_keep_clear.append([gnome_dir, 0.35])
	_scrap_nodes["spore_gnome"] = gnome
	# --- ZORP'S WATERING CAN, UPSIDE DOWN (bonus): just past his home spot, away from the start
	var home := _zorp_home_dir()
	var away := -_toward(home, safari.start_dir)
	var can_dir := _free_near_small(_polar(home, away.rotated(home, deg_to_rad(35.0)), rad_to_deg(CAN_FROM_HOME_M / p.radius), 0.0), 0.4)
	var can := Node3D.new()
	can.name = "UpsideDownCan"
	add_child(can)
	# side-on to the start (its spout across the way you come from it): a can standing on its head
	can.global_transform = _xf_ground(can_dir, _toward(can_dir, safari.start_dir).rotated(can_dir, deg_to_rad(90.0)))
	can.add_child(_mesh_node("Can", Meshes.can_upside_down(), _prop, true))
	safari.add_subject({
		"id": "zorp_can", "name": "Zorp's Watering Can", "kind": "bonus", "category": "bonus",
		"band": BAND_CAN, "node": can, "offset": Vector3(0.0, 0.1, 0.0), "radius": 0.16,
		"awake": func() -> bool: return not _sleeping,
	})
	_keep_clear.append([can_dir, 0.4])
	_scrap_nodes["zorp_can"] = can
	# --- THE HEART CRYSTAL (bonus): at the crystal cluster's foot, on its far side from the start
	var heart_dir := _behind_prop(HEART_CRYSTAL, 0.5, safari.dir_from_start(106.0, -5.0))
	var heart := Node3D.new()
	heart.name = "HeartCrystal"
	add_child(heart)
	# it faces out, away from its cluster (its back to the crystals), leaning back on them a little
	var out := -_toward(heart_dir, _prop_dir(HEART_CRYSTAL, heart_dir))
	var hx := _xf_ground(heart_dir, out)
	hx.basis = hx.basis * Basis(Vector3.RIGHT, 0.18)
	heart.global_transform = hx
	heart.add_child(_mesh_node("Heart", Meshes.heart_crystal(),
		PlanetPropMeshes.crystal_material(Color("#ad3e8f"), Color("#d05cab"), 0.45, true, 0.12), false))
	safari.add_subject({
		"id": "heart_crystal", "name": "The Heart Crystal", "kind": "bonus", "category": "bonus",
		"band": BAND_HEART, "node": heart, "offset": Vector3(0.0, 0.12, 0.0), "radius": 0.12,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(heart),
	})
	_keep_clear.append([heart_dir, 0.3])
	_scrap_nodes["heart_crystal"] = heart


## Every frame: the bed sight is scored on the bed nearest the middle of the view.
func _tick_scrapbook() -> void:
	if _bed_sight_focus == null:
		return
	var i := _pick_focus(_bed_dirs, func(_d: Vector3) -> bool: return true,
		func(d: Vector3) -> Vector3: return safari.planet.surface_point(d), 0.35)
	if i >= 0:
		_bed_sight_focus.global_transform = _xf(_bed_dirs[i], _tangent_at(_bed_dirs[i]))


## True when ground direction `d` is inside any scrapbook item's keep-clear circle grown by `margin_m`.
func _in_keep_clear(d: Vector3, margin_m: float) -> bool:
	var p := safari.planet
	for kc: Array in _keep_clear:
		if p.surface_distance(d, kc[0]) < float(kc[1]) + margin_m:
			return true
	return false


## The ground direction of prop `prop_name` (Props/<name>), or `fallback`.
func _prop_dir(prop_name: String, fallback: Vector3) -> Vector3:
	var n := safari.planet.get_node_or_null("Props/" + prop_name) as Node3D
	return safari.planet.dir_of(n.global_position) if n != null else fallback


## A ground spot `m` metres beyond prop `prop_name` as seen from the start (the far side of it).
func _behind_prop(prop_name: String, m: float, fallback: Vector3) -> Vector3:
	var c := _prop_dir(prop_name, fallback)
	var away := -_toward(c, safari.start_dir)
	return _polar(c, away, rad_to_deg(m / safari.planet.radius), 0.0)


## A plain MeshInstance3D child (built in `build`, so it is warmed with everything else).
func _mesh_node(label: String, mesh: Mesh, mat: Material, shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ---------------------------------------------------------------------------------------- spore bloom
func _build_spores() -> void:
	_spore_root = Node3D.new()
	_spore_root.name = "SporeBloom"
	add_child(_spore_root)
	_spore_glow = _glow_quad("SporeGlow", Color("#c9a6e0"), Vector2(2.6, 1.3))
	_spore_root.add_child(_spore_glow)
	_spore_glow.position = Vector3(0.0, 0.35, 0.0)
	_spore_small = _spore_emitter("SporeSmall", 48, 4.0, Color("#aee8dc"), 0.12, 0.45, 1.0)
	_spore_root.add_child(_spore_small)
	_spore_big = _spore_emitter("SporeBig", 120, 4.5, Color("#e3b6dc"), 0.18, 0.8, 1.7)
	_spore_big.explosiveness = 0.25
	_spore_root.add_child(_spore_big)
	_spore_focus = Node3D.new()
	_spore_focus.name = "SporeFocus"
	_spore_root.add_child(_spore_focus)
	# a tall glowing column over the ring: seen from farther round the curve (cal_r9: the careful player
	# photographed an event in 11 of 224 photos, and a day with three creature subjects cannot keep
	# each under 30% unless the events are met)
	# (1.9 m: at 1.5 the sphere's lower rim ray met the ground round the curve from 9-11 m away and the
	# careful test player gave up on it "not fully in view" in 8 of 17 tries - cal_r10; at 2.4 the best
	# photo was of the cloud alone, the ring below the frame - shots_r3)
	_spore_focus.position = Vector3(0.0, 1.9, 0.0)
	_move_spores(SPORE_RUNS[0]["at"])
	safari.add_subject({
		"id": "spore_bloom", "name": "Spore Bloom", "kind": "event",
		"band": BAND_SPORE, "node": _spore_focus, "radius": 1.8,
		"awake": func() -> bool: return _any_running(SPORE_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(SPORE_RUNS, tt, false)
			if not run.is_empty():
				var t_in := tt - float(run["start"])
				if t_in >= SPORE_BIG_AT and t_in < SPORE_BIG_AT + SPORE_BIG_SEC:
					return {"mult": 2.0, "line": "breathing out a big glowing cloud"}
			return {"mult": 1.0, "line": ""},
	})


func _spore_emitter(label: String, amount: int, life: float, colour: Color, size: float, v_min: float, v_max: float) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = label
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	e.mesh = q
	e.material_override = PlanetPropMeshes.sparkle_material(colour)
	e.amount = amount
	e.lifetime = life
	e.local_coords = true
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	e.emission_ring_axis = Vector3.UP
	e.emission_ring_radius = 1.1
	e.emission_ring_inner_radius = 0.7
	e.emission_ring_height = 0.1
	e.direction = Vector3.UP
	e.spread = 35.0
	e.initial_velocity_min = v_min
	e.initial_velocity_max = v_max
	e.damping_min = 0.3
	e.damping_max = 0.6
	e.gravity = Vector3(0.0, 0.05, 0.0)
	e.scale_amount_min = 0.7
	e.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.add_point(0.15, Color(1, 1, 1, 1.0))
	ramp.add_point(0.7, Color(1, 1, 1, 0.8))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0.0))
	e.color_ramp = ramp
	e.emitting = false
	return e


func _move_spores(at: int) -> void:
	if _spore_at == at:
		return
	_spore_at = at
	_spore_root.global_transform = _xf(_ring_dirs[at], _tangent_at(_ring_dirs[at]))
	_spore_small.restart()
	_spore_small.emitting = false


func _tick_spores(delta: float) -> void:
	var run := _run_at(SPORE_RUNS, _t, true)
	var glow := 0.0
	var small := false
	var big := false
	if not run.is_empty() and not _sleeping:
		_move_spores(int(run["at"]))
		var t_in := _t - float(run["start"])
		if t_in < 0.0:
			# the warning: the caps glow brighter as it builds, a thin trickle of spores, a rustle
			var k := clampf((t_in + WARN) / WARN, 0.0, 1.0)
			glow = 0.25 + 0.35 * k * (0.75 + 0.25 * sin(_t * 5.0))
			small = fmod(t_in + WARN, 2.5) < 0.8
			_rustle_clock -= delta
			if _rustle_clock <= 0.0:
				_rustle_clock = 2.5
				_sound_once("tree_shake", 0.55, -9.0).play()
		else:
			big = t_in >= SPORE_BIG_AT and t_in < SPORE_BIG_AT + SPORE_BIG_SEC
			small = not big and fmod(t_in, SPORE_PUFF_EVERY) < SPORE_PUFF_SEC
			glow = 0.55 + (0.45 if big else 0.2 * sin(_t * 2.0 + 1.0))
			if big and not _spore_big.emitting:
				_sound_once("splash", 0.5, -6.0).play()
	_spore_small.emitting = small
	_spore_big.emitting = big
	var cur := float(_spore_glow.get_meta("level", 0.0))
	cur = move_toward(cur, glow, delta * 2.0)
	_spore_glow.set_meta("level", cur)
	_spore_glow.visible = cur > 0.01
	(_spore_glow.material_override as ShaderMaterial).set_shader_parameter("fade", cur)


# ---------------------------------------------------------------------------------------- crystal chime
func _build_chime() -> void:
	var colours := [Color("#8fd6de"), Color("#d99ac9"), Color("#a9c8f0")]
	for k in 3:
		var g := _glow_quad("ChimeGlow%d" % k, colours[k], Vector2(1.6, 1.6) * (1.0 + 0.25 * float(k % 2)))
		add_child(g)
		_chime_glows.append(g)
	_chime_sparkle = CPUParticles3D.new()
	_chime_sparkle.name = "ChimeSparkle"
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	_chime_sparkle.mesh = q
	_chime_sparkle.material_override = PlanetPropMeshes.sparkle_material(Color("#bfe6ee"))
	_chime_sparkle.amount = 40
	_chime_sparkle.lifetime = 1.4
	_chime_sparkle.local_coords = true
	_chime_sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_chime_sparkle.emission_sphere_radius = 0.5
	_chime_sparkle.direction = Vector3.UP
	_chime_sparkle.spread = 60.0
	_chime_sparkle.initial_velocity_min = 0.3
	_chime_sparkle.initial_velocity_max = 0.9
	_chime_sparkle.gravity = Vector3.ZERO
	_chime_sparkle.emitting = false
	add_child(_chime_sparkle)
	_chime_focus = Node3D.new()
	_chime_focus.name = "ChimeFocus"
	add_child(_chime_focus)
	_move_chime(0)
	safari.add_subject({
		"id": "crystal_chime", "name": "Crystal Chime", "kind": "event",
		"band": BAND_CHIME, "node": _chime_focus, "radius": 1.0,
		"awake": func() -> bool: return _any_running(CHIME_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(CHIME_RUNS, tt, false)
			if not run.is_empty():
				var t_in := tt - float(run["start"])
				if t_in >= CHIME_PEAK_AT and t_in < CHIME_PEAK_AT + CHIME_PEAK_SEC:
					return {"mult": 2.0, "line": "ringing bright"}
			return {"mult": 1.0, "line": ""},
	})


func _move_chime(at: int) -> void:
	if _chime_at == at:
		return
	_chime_at = at
	var d: Vector3 = _chime_dirs[at]
	var n: Node3D = _chime_nodes[at]
	var base := n.global_position if n != null else safari.planet.surface_point(d)
	var up := safari.planet.up_at(base)
	var t0 := _tangent_at(d)
	var t1 := up.cross(t0).normalized()
	for k in _chime_glows.size():
		var a := TAU * float(k) / 3.0
		# over the tips (Crystal props stand 0.9-1.3 m): a glow inside the opaque crystal would be hidden
		_chime_glows[k].global_position = base + up * (1.15 + 0.25 * float(k)) + (t0 * cos(a) + t1 * sin(a)) * 0.3
	_chime_sparkle.global_transform = Transform3D(Basis.looking_at(t0, up), base + up * 0.85)
	# the subject's middle is up among the glows, over the tips: seen from farther over the curve
	_chime_focus.global_transform = Transform3D(Basis.looking_at(t0, up), base + up * 1.2)


func _tick_chime(delta: float) -> void:
	var run := _run_at(CHIME_RUNS, _t, true)
	var levels := [0.0, 0.0, 0.0]
	var sparkle := false
	if not run.is_empty() and not _sleeping:
		_move_chime(int(run["at"]))
		var t_in := _t - float(run["start"])
		if t_in < 0.0:
			# the warning: faint glints, and a tinkle heard anywhere every ~0.8 s
			for k in 3:
				levels[k] = 0.18 + 0.18 * maxf(sin(_t * 6.0 + float(k) * 2.1), 0.0)
			_tinkle_clock -= delta
			if _tinkle_clock <= 0.0:
				_tinkle_clock = _rng.randf_range(0.6, 1.0)
				_sound_once("doot_a_%d" % _rng.randi_range(0, 3), _rng.randf_range(1.7, 2.2), -14.0).play()
		else:
			var peak := t_in >= CHIME_PEAK_AT and t_in < CHIME_PEAK_AT + CHIME_PEAK_SEC
			sparkle = true
			if peak:
				# RINGING: the three glows flash in turn, a chord on each flash
				_chime_flash_clock -= delta
				var which := int(floor(t_in * 3.0)) % 3
				for k in 3:
					levels[k] = 1.0 if k == which else 0.45
				if _chime_flash_clock <= 0.0:
					_chime_flash_clock = 1.0 / 3.0
					_sound_once("doot_c_%d" % which, [1.5, 1.78, 2.0][which], -6.0).play()
			else:
				for k in 3:
					levels[k] = 0.45 + 0.2 * sin(_t * 3.0 + float(k) * 2.1)
				_tinkle_clock -= delta
				if _tinkle_clock <= 0.0:
					_tinkle_clock = _rng.randf_range(0.5, 0.9)
					_sound_once("doot_a_%d" % _rng.randi_range(0, 3), _rng.randf_range(1.6, 2.1), -10.0).play()
	for k in 3:
		var g: MeshInstance3D = _chime_glows[k]
		var cur := move_toward(float(g.get_meta("level", 0.0)), float(levels[k]), delta * 6.0)
		g.set_meta("level", cur)
		g.visible = cur > 0.01
		(g.material_override as ShaderMaterial).set_shader_parameter("fade", cur)
	_chime_sparkle.emitting = sparkle


# ---------------------------------------------------------------------------------------- the Great Bloom
const BLOOM_PETALS := 8
## How far the open head nods over (radians from straight up).
const BLOOM_NOD := 0.85
var _bloom_head_basis := Basis()


func _build_bloom() -> void:
	_bloom_root = Node3D.new()
	_bloom_root.name = "GreatBloom"
	add_child(_bloom_root)
	_bloom_root.global_transform = _xf_ground(_bloom_dir, _toward(_bloom_dir, safari.start_dir))
	_bloom_stem = MeshInstance3D.new()
	_bloom_stem.name = "Stem"
	_bloom_stem.mesh = Meshes.bloom_stem()
	_bloom_stem.material_override = _prop
	_bloom_root.add_child(_bloom_stem)
	_bloom_core = MeshInstance3D.new()
	_bloom_core.name = "Core"
	_bloom_core.mesh = Meshes.bloom_core()
	_bloom_core.material_override = _glow_cyan
	_bloom_root.add_child(_bloom_core)
	_bloom_petals = Herd.new()
	_bloom_root.add_child(_bloom_petals)
	var c := _bloom_root.global_position
	_bloom_petals.setup("BloomPetals", BLOOM_PETALS, [[Meshes.bloom_petal(), _prop, true]], AABB(c - Vector3.ONE * 5.0, Vector3.ONE * 10.0))
	_pollen = CPUParticles3D.new()
	_pollen.name = "Pollen"
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	_pollen.mesh = q
	_pollen.material_override = PlanetPropMeshes.sparkle_material(Color("#e6d7a8"))
	_pollen.amount = 70
	_pollen.lifetime = 3.0
	_pollen.local_coords = true
	_pollen.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_pollen.emission_sphere_radius = 0.3
	_pollen.direction = Vector3.UP
	_pollen.spread = 70.0
	_pollen.initial_velocity_min = 0.5
	_pollen.initial_velocity_max = 1.4
	_pollen.damping_min = 0.3
	_pollen.damping_max = 0.6
	_pollen.gravity = Vector3(0.0, -0.1, 0.0)
	_pollen.emitting = false
	_bloom_root.add_child(_pollen)
	_pollen.position = Meshes.BLOOM_HEAD + Vector3(0.0, 0.2, 0.0)
	_bloom_focus = Node3D.new()
	_bloom_focus.name = "BloomFocus"
	_bloom_root.add_child(_bloom_focus)
	_bloom_focus.position = Meshes.BLOOM_HEAD + Vector3(0.0, 0.2, 0.0)
	_bloom_hum = _sound("comms_bed", 0.45, -80.0, true)
	_bloom_root.visible = false
	_pose_bloom(0.0, 0.0)
	safari.add_subject({
		"id": "great_bloom", "name": "The Great Bloom", "kind": "rare",
		"band": BAND_BLOOM, "node": _bloom_focus, "radius": 1.4, "event": "great_bloom",
		# its face: the open head's +Y (the flower looks out that way)
		"front": func() -> Vector3: return (_bloom_root.global_basis * _bloom_head_basis * Vector3.UP).normalized(),
		"moment": func(tt: float) -> Dictionary:
			if tt >= BLOOM_FULL.x and tt < BLOOM_FULL.y:
				return {"mult": 2.4, "line": "in full bloom"}
			return {"mult": 1.0, "line": ""},
	})


## `grow` 0..1: the stem rises out of the ground; `open` 0..1: the petals unfurl.
func _pose_bloom(grow: float, open: float) -> void:
	var g := maxf(grow, 0.001)
	_bloom_stem.scale = Vector3(lerpf(0.4, 1.0, g), g, lerpf(0.4, 1.0, g))
	var head := Meshes.BLOOM_HEAD * g
	# the head nods over toward the root's -Z (the start's side) as it opens: its face looks out
	# sideways and up, so it is seen face-on from eye level (its "front")
	var hb := Basis(Vector3.RIGHT, -BLOOM_NOD * clampf(open * 1.3, 0.0, 1.0) * g)
	_bloom_core.transform = Transform3D(hb.scaled(Vector3.ONE * lerpf(0.3, 1.0, open) * g), head)
	var tilt := lerpf(-0.1, 1.2, open)
	var sway := 0.04 * sin(_t * 0.9)
	for k in BLOOM_PETALS:
		var b := Basis(Vector3.UP, TAU * float(k) / float(BLOOM_PETALS) + sway) * Basis(Vector3.RIGHT, tilt + 0.05 * float(k % 2))
		_bloom_petals.pose(k, 0, _bloom_root.global_transform * Transform3D(hb, head) * Transform3D(b.scaled(Vector3.ONE * g), Vector3.ZERO))
	_bloom_head_basis = hb
	_bloom_focus.position = head + hb * Vector3(0.0, 0.15, 0.0)
	_pollen.position = head + hb * Vector3(0.0, 0.2, 0.0)


func _tick_bloom(delta: float) -> void:
	if not bool(_eligible.get("great_bloom", false)) or _bloom_root == null:
		return
	var t0 := BLOOM_START - WARN
	if _t < t0 or _t >= BLOOM_END or _sleeping:
		if _bloom_hum.playing and not _sleeping:
			_bloom_hum.volume_db = move_toward(_bloom_hum.volume_db, -60.0, delta * 20.0)
			if _bloom_hum.volume_db <= -59.0:
				_bloom_hum.stop()
		return
	_bloom_root.visible = true
	var grow := clampf((_t - t0) / (WARN - 1.0), 0.0, 1.0)
	grow = grow * grow * (3.0 - 2.0 * grow)
	var open := 0.0
	if _t >= BLOOM_START and _t < BLOOM_FULL.x:
		open = (_t - BLOOM_START) / (BLOOM_FULL.x - BLOOM_START)
		open = open * open * (3.0 - 2.0 * open)
	elif _t >= BLOOM_FULL.x and _t < BLOOM_FULL.y:
		open = 1.0
	elif _t >= BLOOM_FULL.y:
		open = lerpf(1.0, 0.55, clampf((_t - BLOOM_FULL.y) / 3.0, 0.0, 1.0))
	_pose_bloom(grow, open)
	_pollen.emitting = _t >= BLOOM_FULL.x and _t < BLOOM_FULL.y
	if not _bloom_hum.playing:
		_bloom_hum.volume_db = -30.0
		_bloom_hum.play()
	var want_db := -14.0 if _t < BLOOM_FULL.y else -24.0
	_bloom_hum.volume_db = move_toward(_bloom_hum.volume_db, want_db, delta * 6.0)


# ---------------------------------------------------------------------------------------- Twin-Moon Glow
func _build_moons() -> void:
	var p := safari.planet
	var g := p.surface_point(_meadow_dir)
	var up := p.up_at(g)
	# across the field, away from the start: stood at the near edge looking on, the pair is over it
	var h := -_toward(_meadow_dir, safari.start_dir)
	var e := deg_to_rad(MOON_ELEV_DEG)
	_moon_dir = (up * sin(e) + h * cos(e)).normalized()
	var side := up.cross(h).normalized()
	var axis := _moon_dir.cross(side).normalized()   # turning _moon_dir about it moves it toward `side`
	var env_node := get_tree().root.get_node_or_null("World/Environment/WorldEnvironment") as WorldEnvironment
	var env: Environment = env_node.environment if env_node != null else get_viewport().find_world_3d().environment
	if env != null and env.sky != null:
		_sky_mat = env.sky.sky_material as ShaderMaterial
	# the discs' own sizes (sky.gdshader: moon A moon_size, moon B 0.55 of it), side by side
	var ra := 0.055
	if _sky_mat != null and _sky_mat.get_shader_parameter("moon_size") != null:
		ra = float(_sky_mat.get_shader_parameter("moon_size"))
	var rb := ra * 0.55
	var span := ra + rb + MOON_LINE_GAP
	var ta := (span + rb - ra) * 0.5
	_moon_to = [_moon_dir.rotated(axis, ta), _moon_dir.rotated(axis, ta - span)]
	_moon_half = ta + ra
	if _sky_mat != null:
		RenderingServer.frame_pre_draw.connect(_moon_pre_draw)
	else:
		push_warning("ZorpSafari: no sky material found - the Twin-Moon Glow cannot move the moons")
	# a glow over every crystal cluster on the planet
	for c: Node3D in _crystals:
		var q := _glow_quad("CrystalGlow_" + str(c.name), Color("#9fdcd6") if _moon_glows.size() % 2 == 0 else Color("#d9a3cf"), Vector2(1.7, 1.7))
		add_child(q)
		q.global_position = c.global_position + p.up_at(c.global_position) * MOON_GLOW_H
		_moon_glows.append(q)
	_moon_focus = Node3D.new()
	_moon_focus.name = "MoonFocus"
	add_child(_moon_focus)
	# THE SUBJECT IS THE MOON PAIR over the lit crystal field, placed along the pair's direction from the lens.
	safari.add_subject({
		"id": "twin_moon_glow", "name": "Twin-Moon Glow", "kind": "rare",
		"band": BAND_MOON, "node": _moon_focus, "radius": MOON_FOCUS_M * sin(_moon_half), "event": "twin_moon_glow",
		"moment": func(tt: float) -> Dictionary:
			if tt >= MOON_LINED.x and tt < MOON_LINED.y:
				return {"mult": 2.4, "line": "the two moons lined up"}
			return {"mult": 1.0, "line": ""},
	})


## The sky's moon directions as environment.gd last wrote them (not the event's own last write).
func _moon_env_dirs() -> void:
	if _sky_mat == null:
		return
	var names := ["moon_dir_a", "moon_dir_b"]
	for k in 2:
		var v: Variant = _sky_mat.get_shader_parameter(names[k])
		if v is Vector3 and (v as Vector3).length() > 0.5 and not (v as Vector3).is_equal_approx(_moon_now[k]):
			_moon_env[k] = (v as Vector3).normalized()


func _moon_pre_draw() -> void:
	if _sky_mat == null or _moon_k <= 0.0 or not is_inside_tree():
		return
	_sky_mat.set_shader_parameter("moon_dir_a", _moon_now[0])
	_sky_mat.set_shader_parameter("moon_dir_b", _moon_now[1])


func _tick_moons(delta: float) -> void:
	if _moon_focus == null or not bool(_eligible.get("twin_moon_glow", false)):
		return
	var t0 := MOON_START - WARN
	var on := _t >= t0 and _t < MOON_END and not _sleeping
	# the moons: out of their places through the warning and the rise, lined up, then home again
	var k := 0.0
	if not _sleeping:
		if _t >= t0 and _t < MOON_LINED.x:
			k = smoothstep(t0, MOON_LINED.x, _t)
		elif _t >= MOON_LINED.x and _t < MOON_LINED.y:
			k = 1.0
		elif _t >= MOON_LINED.y and _t < MOON_LINED.y + MOON_BACK_SEC:
			k = 1.0 - smoothstep(MOON_LINED.y, MOON_LINED.y + MOON_BACK_SEC, _t)
	_moon_env_dirs()
	if k > 0.0 and _moon_env[0] != Vector3.ZERO and _moon_env[1] != Vector3.ZERO:
		for m in 2:
			_moon_now[m] = _moon_env[m].slerp(_moon_to[m], k).normalized()
		_moon_k = k
	else:
		_moon_k = 0.0
		_moon_now = [Vector3.ZERO, Vector3.ZERO]
	var level := 0.0
	if on:
		if _t < MOON_START:
			level = 0.15 + 0.15 * maxf(sin(_t * 7.0), 0.0)
		elif _t >= MOON_LINED.x and _t < MOON_LINED.y:
			level = 1.0
		else:
			level = 0.6 + 0.15 * sin(_t * 2.4)
	for i in _moon_glows.size():
		var g := _moon_glows[i]
		var cur := move_toward(float(g.get_meta("level", 0.0)), level * (0.85 + 0.15 * sin(_t * 3.0 + float(i))), delta * 3.0)
		g.set_meta("level", cur)
		g.visible = cur > 0.01
		(g.material_override as ShaderMaterial).set_shader_parameter("fade", cur)
	# the photo's middle: along the pair's direction from the lens
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if on and cam != null:
		var mid := _moon_dir
		if _moon_k > 0.0:
			mid = (_moon_now[0] + _moon_now[1]).normalized()
		_moon_focus.global_position = cam.global_position + mid * MOON_FOCUS_M


# ======================================================================================== THE DIRECTOR
## BEFORE A RARE EVENT the director is keener: through the WARN seconds before the Great Bloom (and the
## Twin-Moon Glow on a rare day) something is brought after PRE_RARE_AFTER_SEC of nothing instead of
## AFTER_SEC, so a creature is about when the director goes quiet for the rare (spec 13.2 keeps it quiet
## WHILE the rare is up; this changes nothing then). Measured: without it the 20-second rule held in
## 21 of 24 wanderer runs, every long gap starting 8-14 s before the bloom (band_r3 in the report).
const PRE_RARE_AFTER_SEC := 5.0
var _after_sec := 12.0


func _tick_pacing() -> void:
	if pacing == null:
		return
	var keen := false
	for w: Vector2 in [Vector2(BLOOM_START - WARN, BLOOM_START), Vector2(MOON_START - WARN, MOON_START)]:
		if _t >= w.x and _t < w.y:
			keen = true
	if keen and not bool(_eligible.get("twin_moon_glow", false)) and _t >= MOON_START - WARN:
		keen = false
	pacing.AFTER_SEC = PRE_RARE_AFTER_SEC if keen else _after_sec


func _build_pacing() -> void:
	pacing = Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	_after_sec = pacing.AFTER_SEC
	# WHICH ONE is the director's job (spec 14.3): the "ready" tests below say only whether one is FREE to
	# bring. (Round 1 also refused any subject at 27% of the photos here, a cap of this world's own - gone:
	# the director's own held_back / over_cap do that for every planet, and lift it when the 20-second
	# rule needs them to.)
	pacing.add_bringer({"id": "mush_hopper", "bring": _bring_hopper,
		"ready": func() -> bool:
			for h: Dictionary in _hoppers:
				if int(h["ring"]) < 0 and int(h["state"]) == Hop.GONE:
					return true
			return false})
	pacing.add_bringer({"id": "glow_jelly", "bring": _bring_jelly,
		"ready": func() -> bool:
			for j: Dictionary in _jellies:
				if int(j["state"]) == Jel.AWAY and not bool(j["back"]) and not bool(j["watch"]):
					return true
			return false})
	pacing.add_bringer({"id": "zorp", "bring": _bring_zorp, "ready": _zorp_can_come})
	# THE STRAY SWARM, night only: the night's fourth bringer (the header's lantern-beetles).
	if safari.is_night and not _swarms.is_empty():
		pacing.add_bringer({"id": "lantern_beetle", "bring": _bring_beetles, "ready": _stray_free})
	pacing.places = _creature_places
	pacing.MAX_SHARE = MAX_SHARE


## THE DIRECTOR'S CAP ON THIS PLANET (SafariWorld.Pacing.MAX_SHARE, which a world may set after setup):
## 0.27 here, the spec's 30% less one photo in a ten-plate safari. By day Zorp's garden has THREE regulars
## (hoppers, jellies, Zorp) and few event photos, so an even split is itself a third each - the director's
## own header says so of Bolt by day - and at the director's 0.30 the careful player's day photos stood at
## 33-36% jellies however the brings were shared (c2zorp_out/g1..g3). At 0.27 a subject that has had its
## ~3 of 10 is not brought again until nothing else can come for AFTER_SEC + HOLD_WAIT_SEC (16 s), so the
## fourth and later brings go to the others. It binds only for a player who takes photos: the density
## gate's wanderer takes none, and the 20-second rule still lifts it.
const MAX_SHARE := 0.27


## THE ROAMING JELLY GIVES WAY TO THE DIRECTOR'S SHARE (spec 14.3). The roamer is out all safari and is
## not made shy by ONE NEW THING AT A TIME (see _tick_jellies); round 1 measured it gave 8 of the careful
## player's 23 jelly photos (c2zorp_out/base), on top of the director's own brings, so the jellies stood at
## 32% pooled however the director shared its brings. So while the director would not BRING a jelly for
## its share - HELD BACK (over its fair share: SafariWorld.Pacing.held_back) or OVER THE CAP (over_cap) -
## the roamer drifts up out of the frame too, and comes back when that is over - and, as for every
## held-back subject, when nothing has been clearly in view for AFTER_SEC + HOLD_WAIT_SEC (the 20-second
## rule wins).
func _jelly_held() -> bool:
	return pacing != null and (pacing.held_back("glow_jelly") or pacing.over_cap("glow_jelly")) \
		and pacing.lonely < pacing.AFTER_SEC + pacing.HOLD_WAIT_SEC


## Where the other creatures are, or will come into view: the rings, the beds (beetles at night, or
## being watered), Zorp, the jellies drifting now, the scouts that are out, and every awake event.
func _creature_places() -> Array:
	var p := safari.planet
	var out: Array = []
	for i in 2:
		out.append(p.surface_point(_ring_dirs[i]))
	for bi in _bed_dirs.size():
		if (safari.is_night and bi in BEETLE_BEDS) or _any_running(WATER_RUNS):
			out.append(p.surface_point(_bed_dirs[bi]))
	for sw: Dictionary in _swarms:
		if bool(sw["stray"]) and bool(sw["out"]):
			out.append(p.surface_point(sw["dir"]))
	if _zorp != null and is_instance_valid(_zorp):
		out.append(_zorp.global_position)
	for j: Dictionary in _jellies:
		if int(j["state"]) != Jel.AWAY:
			out.append(p.surface_point(j["dir"]))
	for h: Dictionary in _hoppers:
		if int(h["ring"]) < 0 and int(h["state"]) != Hop.GONE:
			out.append(p.surface_point(h["dir"]))
	if _any_running(SPORE_RUNS) and _spore_at >= 0:
		out.append(p.surface_point(_ring_dirs[_spore_at]))
	if _any_running(CHIME_RUNS) and _chime_at >= 0:
		out.append(p.surface_point(_chime_dirs[_chime_at]))
	if safari.event_running("great_bloom"):
		out.append(p.surface_point(_bloom_dir))
	return out


# ======================================================================================== SCHEDULE
## Every event run is its own PlanetSafari event (its own id, so event_running and the "woke" count
## work per run); the runs of one kind share one warning glow and one subject.
func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line]
	var ev: Array = []
	for run: Dictionary in SPORE_RUNS:
		var d: Vector3 = _ring_dirs[int(run["at"])]
		ev.append(["spore_bloom", run["id"], "Spore Bloom", run["start"], run["end"], d, "any", Color("#d7b3e3"),
			"The mushrooms at %s start to glow..." % RING_NAMES[int(run["at"])]])
	for run: Dictionary in CHIME_RUNS:
		var d: Vector3 = _chime_dirs[int(run["at"])]
		var where := "by the landing pad" if int(run["at"]) == 1 else "at " + _place_name(d)
		ev.append(["crystal_chime", run["id"], "Crystal Chime", run["start"], run["end"], d, "any", Color("#a9dce6"),
			"Tink... tink... the crystals %s are tuning up!" % where])
	for run: Dictionary in WATER_RUNS:
		var d: Vector3 = _bed_dirs[int(run["at"])]
		ev.append(["watering", run["id"], "Watering Time", run["start"], run["end"], d, "any", Color("#e0a8d0"),
			"Zorp: \"Watering time! Bulbs, wake up!\"  (at %s)" % BED_NAMES[int(run["at"])]])
	ev.append(["great_bloom", "great_bloom", "The Great Bloom", BLOOM_START, BLOOM_END, _bloom_dir, "any", Color("#9fe0d4"),
		"Something HUGE is budding on the FAR SIDE..."])
	ev.append(["twin_moon_glow", "twin_moon_glow", "Twin-Moon Glow", MOON_START, MOON_END, _meadow_dir, "only", Color("#d6cfe6"),
		"The two moons drift together over %s... every crystal hums!" % _place_name(_meadow_dir)])
	for e: Array in ev:
		var kind: String = e[0]
		var id: String = e[1]
		var beacon: MeshInstance3D = _beacons[kind] if _beacons.has(kind) else _make_beacon(kind, e[7])
		var line: String = e[8]
		var dir: Vector3 = e[5]
		var ok := safari.add_event({
			"id": id, "name": e[2], "start": e[3], "end": e[4], "warn": WARN, "dir": dir,
			"when": "any", "rare": e[6], "overlap_ok": true,
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
const WARN_SOUNDS := {"spore_bloom": "tree_shake (then every 2.5 s)", "crystal_chime": "doot_c_1 (then tinkles every ~0.8 s)",
	"watering": "emote_wave + doot_c_2", "great_bloom": "skiff_reveal (then a hum)", "twin_moon_glow": "shooting_star"}
const WARN_CUES := {"spore_bloom": "the ring's caps glow and trickle spores", "crystal_chime": "the crystals glint",
	"watering": "Zorp pops over to the bed with the can", "great_bloom": "a bud grows up out of the ground",
	"twin_moon_glow": "the sky's two moons start to drift together, the crystals flicker"}


## The SOUND half of every warning: heard anywhere on the planet (a 2D sound), the moment it is warned.
func _warn_sound(kind: String) -> void:
	match kind:
		"spore_bloom":
			_sound_once("tree_shake", 0.55, -6.0).play()
		"crystal_chime":
			_sound_once("doot_c_1", 2.0, -6.0).play()
		"watering":
			_sound_once("emote_wave", 1.15, -4.0).play()
			_sound_once("doot_c_2", 1.3, -6.0).play()
		"great_bloom":
			_sound_once("skiff_reveal", 0.6, -8.0).play()
		"twin_moon_glow":
			_sound_once("shooting_star", 0.6, -6.0).play()


func _on_start(kind: String) -> void:
	match kind:
		"spore_bloom":
			pass
		"crystal_chime":
			_sound_once("doot_c_0", 1.5, -6.0).play()
		"watering":
			if _zorp != null and is_instance_valid(_zorp):
				_zorp.call("play_emote", "happy")
			AudioManager.play_sfx_at("splash", _zorp_bed_xf.origin, -6.0, 0.1)
		"great_bloom":
			safari.puff_at(_bloom_root.global_position + safari.planet.up_at(_bloom_root.global_position) * 0.3, 24, Color("#d9cfe6"))
		"twin_moon_glow":
			_sound_once("friendship_up", 0.8, -8.0).play()


func _on_end(kind: String) -> void:
	match kind:
		"great_bloom":
			safari.puff_at(_bloom_focus.global_position, 26, Color("#e6d7ec"))
			get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
				if is_instance_valid(_bloom_root):
					_bloom_root.visible = false
					_pollen.emitting = false)
		"twin_moon_glow":
			_moon_k = 0.0


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
	_tick_pacing()
	if not _lines.is_empty() and not _building and _t >= float(_lines[0][0]) and not _sleeping:
		safari.announce(str(_lines[0][1]), 3.5)
		_line_free_at = _t + LINE_SEC
		_lines.pop_front()
	_tick_hoppers(delta)
	_tick_jellies(delta)
	_tick_beetles(delta)
	_tick_zorp(delta)
	_tick_water(delta)
	_tick_scrapbook()
	_tick_spores(delta)
	_tick_chime(delta)
	_tick_bloom(delta)
	_tick_moons(delta)
	_tick_beacons(delta)


## The three minutes are up: hoppers squat into mushrooms (the scouts dive), jellies float off up,
## the lanterns go out, everything else goes in PlanetSafari's puff, the sounds stop. Zorp is handed
## back to his own script at once and put back where he stood when this node leaves.
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_bloom_root, _can]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for pr: CPUParticles3D in [_spore_small, _spore_big, _chime_sparkle, _pollen, _drops]:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false)
	if _zorp_borrowed or _zorp_stay_until > -INF or _zorp_hop_t >= 0.0:
		_release_zorp(false)
	return true


func _exit_tree() -> void:
	_release_zorp(true)
	# the moons: environment.gd writes its own directions again on its next frame
	_moon_k = 0.0
	if RenderingServer.frame_pre_draw.is_connected(_moon_pre_draw):
		RenderingServer.frame_pre_draw.disconnect(_moon_pre_draw)


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
	g.set_meta("level", 0.0)
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


## A 2D sound (heard anywhere on the planet) owned by this node. `loop` loops a private copy.
func _sound(sfx: String, pitch: float, db: float, loop: bool = false) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.name = "Snd_" + sfx
	var st: Variant = load(SFX_DIR + sfx + ".wav") if ResourceLoader.exists(SFX_DIR + sfx + ".wav") else null
	if st is AudioStreamWAV and loop:
		var w := (st as AudioStreamWAV).duplicate() as AudioStreamWAV
		var bytes := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / (bytes * (2 if w.stereo else 1))
		st = w
	a.stream = st as AudioStream
	a.pitch_scale = pitch
	a.volume_db = db
	a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(a)
	_sounds.append(a)
	return a


## EVERY ONE-SHOT PLAYER IS MADE IN `build` (behind the fade), not on its first use: the round-1 critic
## measured a +21-28 ms first long frame at the first warning (safari t 4.0, the watering: two WAVs
## load()ed and a player made for each, beside the puffs and the beacon), and anything made after the
## build is not warmed. The effect names every _sound_once call uses:
const ONCE_SFX := ["tree_shake", "splash", "doot_a_0", "doot_a_1", "doot_a_2", "doot_a_3", "doot_c_0", "doot_c_1",
	"doot_c_2", "emote_wave", "skiff_reveal", "shooting_star", "friendship_up"]


func _warm_sounds() -> void:
	for sfx: String in ONCE_SFX:
		_sound_once(sfx, 1.0, -80.0)


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


## For the test logs: where each photographed creature came from (a roamer, a watcher or one the
## director brought; a ring hopper or a scout; Zorp at home or brought).
func _on_photo(ph: Dictionary) -> void:
	var id := str(ph.get("subject_key", "")).get_slice(":", 1)
	var src := ""
	match id:
		"glow_jelly":
			if _jelly_pick >= 0:
				var j: Dictionary = _jellies[_jelly_pick]
				src = "roamer" if bool(j["roamer"]) else ("watcher" if bool(j["watch"]) else "brought")
		"mush_hopper":
			if _hop_pick >= 0:
				src = "ring" if int(_hoppers[_hop_pick]["ring"]) >= 0 else "scout"
		"zorp":
			src = "brought" if _t - _zorp_came_at < 20.0 else "about"
		"lantern_beetle":
			if _beetle_pick >= 0:
				src = "stray" if bool(_swarms[_beetle_pick]["stray"]) else "bed"
	_log("photo t=%.1f %s from %s grade %s" % [_t, id, src, str(ph.get("grade", ""))])


func _log(msg: String) -> void:
	print("[ZorpSafari] " + msg)


## Everything a test needs to find the subjects and places (the probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"rings": _ring_dirs.duplicate(), "beds": _bed_dirs.duplicate(), "chimes": _chime_dirs.duplicate(),
		"bloom": _bloom_dir, "meadow": _meadow_dir, "home": _zorp_home_dir(),
		"hopper_dirs": _hoppers.map(func(h: Dictionary) -> Vector3: return h["dir"]),
		"hopper_states": _hoppers.map(func(h: Dictionary) -> int: return int(h["state"])),
		"jelly_dirs": _jellies.map(func(j: Dictionary) -> Vector3: return j["dir"]),
		"jelly_states": _jellies.map(func(j: Dictionary) -> int: return int(j["state"])),
		"eligible": _eligible.duplicate(),
		"moon_dir": _moon_dir, "moon_to": _moon_to.duplicate(), "moon_now": _moon_now.duplicate(),
		"scrapbook": _scrap_nodes.duplicate(), "great_ring": _great_ring_dir,
	}
