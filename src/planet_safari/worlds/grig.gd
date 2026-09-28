extends SafariWorld
## GRIG'S WORLD WAKES UP - THE CHALK HENGE (docs/PLANET_SAFARI_SPEC.md 12.3, under the rules of 11 and 13;
## builder GRIG, 2026-09-25). Loaded by PlanetSafari when a safari starts on Grig's world, freed when it
## ends: nothing here exists outside a safari (the user's rule 5), and nothing on the planet is changed.
## Grig himself is the one thing borrowed - he is fetched to the henge for each stone count - and he is
## put back exactly where he stood when this node leaves the tree.
##
## Built only from Grig's EXISTING look (src/planet/props/planet_props.gd `_grig`): the nine-stone henge
## round the landing point, the three chalk shelves across the step edges, the chalk dust in the treads,
## the two large moons and the edge-on ring - and Grig, who counts everything.
##
## ------------------------------------------------------------------------------------ THE TIERS (12.3)
##   creatures        always about, in many places  PEBBLE-BUGS at 3 spots (they curl into pebbles when
##                                                   rushed, uncurl for a player who stands still with the
##                                                   camera up), SHELF-OWLS on 2 of the shelves (they turn
##                                                   their heads - Facing matters most here - and stretch
##                                                   their wings now and then), DUST-BUNNIES (the roamer:
##                                                   they puff up out of the chalk where it has gone quiet)
##   common events    several times, ~30 s          CHALK DRIFT at 3 spots (28 s each)
##   uncommon events  several times, ~12 s          HENGE HUM at 3 stones; GRIG COUNTS THE STONES twice
##   rare event       once                          MOONRISE IN THE HENGE - a big chalk moon rises framed
##                                                   between two stones (paired with Chalk Drift (1) on the
##                                                   far side, so the rare costs a choice)
##   rare day         1 day in 4                    THE GREAT STACK - every pebble-bug gathers into one
##                                                   wobbly tower on the far steps (paired with Henge Hum (1))
##   night only       all 3 min                     CHALK-GLOW WORMS trace the henge's outline
##   the neighbour    all 3 min                     GRIG - waves when you come close, holds still for a photo
## RARITY follows the tier (SafariWorld.TIER_RARITY, from the MANIFEST roster).
##
## THE SCRAPBOOK'S NEW PAGES (spec 15.5, builder GRIGC 2026-09-26; every roster entry carries its "category"):
##   sights (always there, rarity 1, they pay; not counted by the density band or the pacing director)
##     THE NINE STONES   any monolith of the henge (the planet's own props, untouched)
##     THE SHELVES       any of the three chalk shelves (the planet's own props, untouched)
##   bonus (collector's pages: hidden, small, they pay nothing; not counted either)
##     GRIG'S TALLY MARKS     23 strokes scratched on the OUTER face of one monolith (seen from outside only)
##     THE TINY TENTH STONE   a 0.4 m copy of a monolith, tucked at the foot of the spindle tree past the henge
##     A CHALK DRAWING OF YOU on a flat tread by Grig's steps: you, waving, a star, and one tally stroke
##   WHO A PHOTO IS NAMED AFTER is the SHARED rule now (spec 17.1 rule 6, SafariPhotoScorer.class_rank):
##   a counted subject beats a sight, a sight beats a bonus page, grade/price decide only inside a class.
##   Grig's own local override of this (a sight or bonus page stepping back, "aimed at", while something
##   that counts was nearer the frame's middle) is REMOVED - the shared rule already gets it right, and a
##   sight or bonus page seen alongside the winner now also files its own scrapbook page (17.1 rule 6).
##   Grig's existing art is not changed (spec 16: its polish waits for the user's own look).
##
## ------------------------------------------------------------------------------------ THE PLACES
## Measured round the planet from the safari start beside the pad (probe `layout`, Grig's seed-89 props),
## as (degrees round, bearing from the start heading, + = right). Radius 9.5 m: 1 degree = 0.166 m; the
## safari walk is 1.5 m/s = 9.0 deg/s, so a quarter round is 10 s and the far side 20 s.
##   START          (0, 0)       the pad is behind you (18.6, 180).
##   THE HENGE      (64, 49)     the landing point, ringed by the nine monoliths 5-8 m out (the nearest,
##                               Monolith1, is 5.3 m from the start at (32, 56)). "Inside" = within 4.1 m.
##   GRIG'S STEPS   (99, -117)   his home, nearly opposite the henge; he wanders up to 7 m from it.
##   FAR SHELF      (148, -20)   ChalkShelf0: a shelf-owl.
##   HENGE SHELF    (89, 98)     ChalkShelf1, just outside the ring: a shelf-owl.
##   LAMP STEPS     (61, -62)    pebble-bugs (1).
##   BACK TERRACES  (138, 137)   pebble-bugs (2).
##   BEHIND THE PAD (80, 160)    pebble-bugs (3).
##   MIDDLE STEPS   (94, -38)    Chalk Drift (2).
##   FAR STEPS      (150, -125)  Chalk Drift (1), and the Great Stack - the henge's far side (161 deg).
##   HIGH STEPS     (135, 72)    Chalk Drift (3).
## The spots were chosen for the farthest from every other place (scratch places.py, the rule Bolt's R4
## spots used) and are nudged to the nearest clear ground at build; all are logged. The moon rises in the
## gap between the 3rd and 4th stones in ring order (logged), the gap facing most away from the start.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned WARN (8) s ahead with a SIGHT and a SOUND that duplicate each other (spec 4):
## a line on screen naming the place, a sound heard anywhere on the planet (2D), a soft glow on YOUR
## horizon in the event's direction (gone once you are near, and while the camera is up), and the event's
## own cue: Grig appears in a puff of chalk at the first stone and speaks; chalk skitters at the drift's
## spot with a gust; the stone's collar flickers under a growing hum; moonlight gathers on the horizon in
## the gap with a long low chime; the pebble-bugs curl and roll away with a rattle.
##   0:09-0:21  GRIG COUNTS (1) the three stones nearest the start: warned from 0:01 by his voice and a
##              puff of chalk where he appears, and the line on screen at 0:05 (after the control hint).
##              (It began at 0:03 in the first build, which left its line on screen only after it began.)
##   0:13-0:41  CHALK DRIFT (2), middle steps.
##   0:24-0:36  HENGE HUM (2).                     FULL GLOW 0:28-0:32
##   0:49-1:17  CHALK DRIFT (1), far steps.        TALLEST 0:57-1:01 = the moon FRAMED
##   0:52-1:04  MOONRISE IN THE HENGE (rare): up 0:53-1:01, FRAMED 0:57-1:01 (from inside, 3 m of the middle)
##   1:24-1:36  GRIG COUNTS (2) the three stones across the ring.
##   1:40-1:54  THE GREAT STACK (rare day), far steps: stands 1:41.5-1:50.5, ALL NINE 1:46-1:50
##   1:42-1:54  HENGE HUM (1), the stone farthest from the stack: FULL GLOW 1:46-1:50 (from inside the henge)
##   2:04-2:32  CHALK DRIFT (3), high steps.
##   2:36-2:48  HENGE HUM (3).
##   all 3 min  PEBBLE-BUGS, SHELF-OWLS, GRIG; GLOW WORMS at night; and, when it has gone quiet, a
##              DUST-BUNNY, a stray PEBBLE-BUG or a visiting OWL brought where you look by the shared pacing
##              director (SafariWorld.Pacing), which also keeps the shy creatures out of sight for a few
##              seconds after you come upon something new, so they come one at a time.
## THE PACING DIRECTOR here (all measured, see the report): it steps in after PACING_AFTER_SEC (9.5; Bolt's
## 12 - this is the smallest world), after only PACING_AFTER_SOON in the RARE_LEAD_SEC before a rare comes
## up (it must then stay quiet for it, spec 13.2, so nobody walks into that quiet already lonely); which
## creature it brings is its own shared per-bring cap (spec 17.1 rule 7; the local gate went, 17.3 ruling 3).
## Looking over the deck, all three can still come: a bunny leaps up, an owl
## hovers in, a pebble-bug bounces up over the step edge and uncurls in the air.
## THE OVERLAPS (spec 6.2, measured by probe `overlap`: every point of an 8,000-point grid of the planet
## from which each can be photographed at its best - eye height and the top of a 0.45 m hop - and the
## shortest walk between the two sets): moon framed / drift tallest 10.8 m = 7.2 s at 1.5 m/s (6.0 s even
## 20% faster) against a 4 s window; stack all nine / hum full glow 9.9 m = 6.6 s (5.5 s) against 4 s.
## An arrival - a brought creature popping up, bouncing in or gliding in - is an entrance, not a moment.
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): one MultiMesh per part - the bugs 2 draw calls, the owls 3 (body,
## head, wings), the bunnies 2, the stack 1, the worms 2 - whatever is in view. Every mesh is PlanetMeshKit
## vertex colour on the materials Grig's own props already draw with (rock_material, prop_material,
## pulse_material); particles are CPUParticles3D on the shipped puff and sparkle materials; the warning
## glows, the hum's halo and the moon's halo are the shipped star shader. No lights. Everything is built
## in `build` (warmed behind the fade) and only moved, shown or hidden afterwards: each repeated event
## re-uses ONE set of emitters and meshes, moved to its place. (Measured cost: see the report.)
##
## ------------------------------------------------------------------------------------ FACING AND SIZE
## FACING (spec 11.1): every creature, Grig and his count carry "front" (every mesh here faces -Z). The
## owls' front is their HEAD, which turns on its own: a shelf-owl's photo is only a good one when it
## looks at you, and it does that when you stand still with the camera up (Facing matters most here).
## SIZE BANDS: see SIZE BANDS below.

const MANIFEST := {
	"host": "grig",
	"offer": "The steps wake up. One hundred and eighty seconds. Counted.",
	"ask": "A photo safari. Yes or no?",
	"yes": "Start at the pad. Walk. Do not run. Count everything.",
	"no": "Not now? Fine. Ask again. I will still be counting.",
	"asleep": "Asleep. All nine hundred steps. Come back tomorrow.",
	"roster": [
		{"id": "pebble_bug", "name": "Pebble-bug", "tier": "creature", "category": "creature"},
		{"id": "shelf_owl", "name": "Shelf-owl", "tier": "creature", "category": "creature"},
		{"id": "dust_bunny", "name": "Dust-bunny", "tier": "creature", "category": "creature"},
		{"id": "grig", "name": "Grig", "tier": "neighbour", "category": "neighbour"},
		{"id": "chalk_drift", "name": "Chalk Drift", "tier": "common", "category": "event"},
		{"id": "henge_hum", "name": "Henge Hum", "tier": "uncommon", "category": "event"},
		{"id": "grig_count", "name": "Grig Counts the Stones", "tier": "uncommon", "category": "event"},
		{"id": "moonrise", "name": "Moonrise in the Henge", "tier": "rare", "category": "event"},
		{"id": "glow_worm", "name": "Chalk-glow Worms", "tier": "night", "category": "creature"},
		{"id": "great_stack", "name": "The Great Stack", "tier": "rare_day", "category": "event"},
		# THE SCRAPBOOK (spec 15.5): two sights, always there, and three collector's pages, hidden and small
		{"id": "nine_stones", "name": "The Nine Stones", "tier": "sight", "category": "sight"},
		{"id": "shelves", "name": "The Shelves", "tier": "sight", "category": "sight"},
		{"id": "tally_marks", "name": "Grig's Tally Marks", "tier": "bonus", "category": "bonus"},
		{"id": "tenth_stone", "name": "The Tiny Tenth Stone", "tier": "bonus", "category": "bonus"},
		{"id": "chalk_you", "name": "A Chalk Drawing of You", "tier": "bonus", "category": "bonus"},
	],
	"review": {
		"no_subject": [
			"Just steps in this one. Good steps. Still counts.",
			"Scenery. I count it anyway.",
		],
		"Smudge": [
			"%s. Smeared. Hold still next time.",
			"A soft %s. Counted. Barely.",
		],
		"Fair": [
			"%s. Clear enough. I will count it.",
			"%s. Correct. Not remarkable. Correct.",
		],
		"Fine": [
			"%s. Sharp. Squared up. Good.",
			"%s. Well cut. That one gets a number.",
		],
		"Gallery": [
			"%s. Perfect. I am numbering this one. Six-A.",
			"%s. Flawless. Measured twice. Still flawless.",
		],
		"moment": " Good timing. I noticed.",
	},
}

const Meshes := preload("res://src/planet_safari/worlds/grig_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")
const SFX_DIR := "res://assets/audio/sfx/"

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
## "at" = the arc of stones: 0 the three nearest the start, 1 the three across the ring.
const COUNT_RUNS := [
	{"id": "grig_count", "start": 9.0, "end": 21.0, "at": 0},
	{"id": "grig_count_2", "start": 84.0, "end": 96.0, "at": 1},
]
## "at" = the spot (P_DRIFT). The first row is the one paired with the moonrise.
const DRIFT_RUNS := [
	{"id": "chalk_drift", "start": 49.0, "end": 77.0, "at": 1},
	{"id": "chalk_drift_2", "start": 13.0, "end": 41.0, "at": 0},
	{"id": "chalk_drift_3", "start": 124.0, "end": 152.0, "at": 2},
]
## "at" = which hum stone (_hum_stones: 0 the one farthest from the stack, paired with it). The first row
## is the paired one.
const HUM_RUNS := [
	{"id": "henge_hum", "start": 102.0, "end": 114.0, "at": 0},
	{"id": "henge_hum_2", "start": 24.0, "end": 36.0, "at": 1},
	{"id": "henge_hum_3", "start": 156.0, "end": 168.0, "at": 2},
]
const MOON_START := 52.0
const MOON_END := 64.0
const MOON_RISE_SEC := 2.0
const MOON_SET_SEC := 2.0
## The moon is UP (photographable, and the pacing director quiet) this part of its event: from when its
## middle clears the limb to when it starts to set. It rises and sets quickly, so it is only seen when
## it is photographable (a moon half out of the ground that "is nothing" would be a broken promise).
const MOON_UP := Vector2(1.0, 9.0)
const STACK_START := 100.0
const STACK_END := 114.0
## The stack stands (photographable, the director quiet) from the first climb to the tumble.
const STACK_UP := Vector2(1.5, 10.5)
const STACK_CLIMB_AT := 1.5
const STACK_CLIMB_EVERY := 0.45
const STACK_TUMBLE_AT := 10.5

# ------------------------------------------------------------------------------ THE OVERLAPS (6.2)
## Each pair shares ONE short best window, on opposite sides of the planet (THE OVERLAPS in the header):
##   the moon FRAMED between the stones  /  Chalk Drift (1) at its TALLEST     0:57-1:01
##   ALL NINE STACKED                    /  Henge Hum (1) at FULL GLOW         1:46-1:50
## MOON_FRAMED is seconds after MOON_START; DRIFT_TALL / HUM_FULL / STACK_FULL after each run's start.
const MOON_FRAMED := Vector2(5.0, 9.0)
const DRIFT_TALL := Vector2(8.0, 12.0)
const HUM_FULL := Vector2(4.0, 8.0)
const STACK_FULL := Vector2(6.0, 10.0)
## The moon is "framed" in a photo taken within this of the henge's centre (the eye above the landing
## point), with its centre between the two gap stones on screen.
const MOON_FRAME_M := 3.0

# ------------------------------------------------------------------------------ the places
## The fourth, BY THE PAD (22, 5): 3.7 m ahead of the start, inside the horizon (4.6 m from the eye), so the
## first thing in front of you is a few pebble-bugs that curl up as you walk at them (V6GRIG, 2026-09-27:
## before it, nothing on this world stood within 5 m of the start; the nearest creature place was 9 m out).
const P_BUG_PLACES := [Vector2(55.0, -60.0), Vector2(140.0, 145.0), Vector2(80.0, 160.0), Vector2(22.0, 5.0)]
const P_DRIFT := [Vector2(100.0, -40.0), Vector2(150.0, -125.0), Vector2(138.0, 70.0)]
const OWL_SHELVES := ["ChalkShelf0", "ChalkShelf1"]
const OWLS_PER_SHELF := 1
## The great stack builds on the far steps, the henge's far side (P_DRIFT[1], whose drift runs at
## another time): the hum it is paired with is best seen from INSIDE the henge, 160 degrees away.
const STACK_AT := Vector2(150.0, -125.0)
const PLACE_NAMES := [
	["the LANDING PAD", Vector2(0.0, 0.0)], ["the HENGE", Vector2(64.0, 49.0)],
	["GRIG'S STEPS", Vector2(99.0, -117.0)], ["the FAR SHELF", Vector2(148.0, -20.0)],
	["the HENGE SHELF", Vector2(89.0, 98.0)], ["the LAMP STEPS", Vector2(55.0, -60.0)],
	["the BACK TERRACES", Vector2(140.0, 145.0)], ["BEHIND THE PAD", Vector2(80.0, 160.0)],
	["the MIDDLE STEPS", Vector2(100.0, -40.0)], ["the FAR STEPS", Vector2(150.0, -125.0)],
	["the HIGH STEPS", Vector2(138.0, 70.0)],
]

## Warning glows (Bolt's recipe): this far round from you toward the event, fading out once you are
## within BEACON_NEAR_DEG. From eye height 1.09 m the horizon is acos(9.5 / 10.59) = 26 degrees away.
const BEACON_AHEAD_DEG := 23.0
const BEACON_NEAR_DEG := 45.0
const BEACON_FULL_DEG := 65.0

# ------------------------------------------------------------------------------ SIZE BANDS (spec 11.1)
## The best SIZE band of each subject: its sphere's projected diameter as a fraction of the frame height.
## Set from the subject's USUAL DISTANCE so a 45 degree shot from there scores 6 or less (size_frac /
## band.x <= 0.6, with size_frac = tan(asin(r / d)) / tan(22.5 deg)), and getting close or zooming
## reaches the band. The small creatures use the spec's 3 m floor; the rest the wanderer's median
## distance while each was photographable (tools/ps_wanderer.gd `dists`, 20 runs, 2026-09-25: drift 7.0,
## Grig 6.3, count 4.2, hum 8.4, stack 7.4, moon 44.6 m), rounded down - for Grig the nearer 5 m, as Bolt.
##   subject      radius  usual d  size_frac there  band         zoom from there to the band's middle
##   pebble-bug   0.19    3.0 m    0.153            0.26-0.43    21 deg
##   shelf-owl    0.22    3.0 m    0.178            0.30-0.49    21 deg
##   dust-bunny   0.20    3.0 m    0.161            0.27-0.45    21 deg
##   glow worm    0.20    3.0 m    0.161            0.27-0.45    21 deg
##   Grig         0.80    5.0 m    0.325            0.66-1.00    19 deg
##   Grig counts  0.80    4.0 m    0.493            0.82-1.00    25 deg
##   chalk drift  1.40    7.0 m    0.493            0.82-1.00    25 deg
##   henge hum    1.40    8.0 m    0.429            0.72-1.00    23 deg
##   great stack  1.20    7.0 m    0.420            0.70-1.00    23 deg
##   moonrise     3.54   45 m      0.190            0.50-0.84    14 deg (both gap stones still in frame)
const BAND_BUG := Vector2(0.26, 0.43)
const BAND_OWL := Vector2(0.30, 0.49)
const BAND_BUNNY := Vector2(0.27, 0.45)
const BAND_WORM := Vector2(0.27, 0.45)
const BAND_GRIG := Vector2(0.66, 1.0)
const BAND_COUNT := Vector2(0.82, 1.0)
const BAND_DRIFT := Vector2(0.82, 1.0)
const BAND_HUM := Vector2(0.72, 1.0)
const BAND_STACK := Vector2(0.70, 1.0)
const BAND_MOON := Vector2(0.50, 0.84)

# ------------------------------------------------------------------ THE SCRAPBOOK'S NEW PAGES (spec 15.5)
## The two SIGHTS (always there, rarity 1, they pay) and three BONUS pages (hidden, small, pay nothing).
## Size bands by the same rule as the creatures (SIZE BANDS above: at 45 degrees from the usual distance the
## size scores 6 or less, so lo >= 1.76 x the size there; close or zoomed reaches 10):
##   subject             radius  usual d  size_frac there  band         best from (45 deg, band middle)
##   the nine stones     1.40    8.0 m    0.429            0.76-1.00    3.7 m (a whole stone, top to foot)
##   the shelves         1.00    6.0 m    0.410            0.72-1.00    2.8 m (the whole shelf fits across)
##   tally marks         0.25    3.0 m    0.202            0.36-0.60    1.3 m
##   tiny tenth stone    0.20    3.0 m    0.161            0.27-0.45    1.3 m
##   chalk drawing       0.42    3.1 m    0.329            0.58-0.95    1.3 m (and look down on it)
## The usual distances are the henge hum's for a stone (the same stone, the same sphere), a stated 6 m for a
## shelf (it is seen across the steps), and the spec's 3 m floor for the small bonus things.
const BAND_STONES := Vector2(0.76, 1.0)
const BAND_SHELVES := Vector2(0.72, 1.0)
const BAND_TALLY := Vector2(0.36, 0.60)
const BAND_TENTH := Vector2(0.27, 0.45)
const BAND_DRAWING := Vector2(0.58, 0.95)
const STONE_SIGHT_R := 1.4
const SHELF_SIGHT_R := 1.0
## The shelf's sight point: over the middle of its deck (the deck top is 0.70 m up, prop-local).
const SHELF_SIGHT_Y := 0.55
const TALLY_R := 0.25
const TENTH_R := 0.2
const DRAWING_R := 0.42
## Where the bonus things are tucked (degrees round, bearing from the start; THE PLACES):
##   the tiny tenth stone at the foot of the spindle tree just past the henge's far side, on the side away
##   from the ring - you find it by walking round the OUTSIDE of the henge;
##   the chalk drawing of you on a flat tread 3 m from Grig's steps, its top toward the far side, so it is
##   the right way up for someone coming from the pad;
##   the tally marks on the outer face of the monolith that neither hums nor is counted, farthest from the
##   start (logged) - seen only from outside the ring.
const P_TENTH := Vector2(103.0, 24.2)
const TENTH_TREE_SEARCH_DEG := 15.0
const TENTH_FROM_TRUNK_M := 0.5
const P_DRAWING := Vector2(108.0, -135.0)
## The drawing needs flat ground: the ground normal within this of "up" at its middle and at four points
## DRAWING_FLAT_M out, and the ground heights there within DRAWING_FLAT_DH.
const DRAWING_FLAT_DEG := 6.0
const DRAWING_FLAT_M := 0.45
const DRAWING_FLAT_DH := 0.03
## The tally panel's middle, this high up its stone's mesh (local, the base is sunk 0.10 m: ~0.9 m above
## the ground, just under eye height).
const TALLY_Y := 1.0
## The sights' focus follows the view: re-picked this often while walking (every frame with the camera up).
const SIGHT_PICK_SEC := 0.1
## ...and stays on the stone (shelf) it is on until another is this much nearer the middle of the view.
const SIGHT_SWITCH_DEG := 4.0

# ------------------------------------------------------------------------------ pebble-bugs
const BUG_PER_PLACE := 3
const BUG_SPREAD_DEG := Vector2(3.0, 12.0)
## A stray bug the pacing director brings (a pebble in view uncurls).
const BUG_STRAYS := 2
const BUG_RUSH_M := 3.0
const BUG_RUSH_SPEED := 0.6
const BUG_TOO_CLOSE_M := 1.0
const BUG_NOTICE_M := 6.5
const BUG_STILL_SEC := 1.0
const BUG_FOR_YOU_SEC := 8.0
## ...but its moment is the first seconds of it, just uncurled (it keeps facing you after).
const BUG_FOR_YOU_MOMENT := 2.5
const BUG_CURL_SEC := 0.3
const BUG_UNCURL_SEC := 0.5
## Looking over the deck, a brought stray BOUNCES: a pebble springs up over the step edge into your view,
## uncurls at the top of its bounce and lands on its feet facing you (at most BUG_BOUNCE_MAX up).
const BUG_BOUNCE_MAX := 1.6
const BUG_BOUNCE_SPARE := 0.3
enum BugState { OUT, CURL, BALL, UNCURL, GONE, BOUNCE }

# ------------------------------------------------------------------------------ shelf-owls
## A visiting owl the pacing director brings (it glides in and lands where you look).
const OWL_VISITORS := 1
const OWL_TURN_EVERY := Vector2(1.4, 3.6)
const OWL_HEAD_MAX_DEG := 115.0
const OWL_LOOK_M := 7.5
const OWL_LOOK_STILL := 0.9
const OWL_LOOK_SEC := 4.0
const OWL_LOOK_REST := 4.0
const OWL_RUSH_M := 2.4
const OWL_RUSH_SPEED := 0.6
const OWL_FLY_SEC := 1.3
const OWL_HOVER_SEC := 2.2
const OWL_SEAT_FWD_M := 0.32
## A shelf-owl you have photographed is startled by the shutter a moment later and flies off for this
## long (then glides back to its shelf); a visiting owl flies off for good.
const OWL_STARTLE_SEC := 1.2
const OWL_AWAY_SEC := 25.0
const OWL_STRETCH_EVERY := 13.0
const OWL_STRETCH_SEC := 1.6
enum OwlState { SIT, LOOK, SNUB, GONE, FLY_IN, HOVER, FLY_OFF }

# ------------------------------------------------------------------------------ dust-bunnies
const BUNNY_SCOUTS := 3
const BUNNY_HOP_M := Vector2(0.5, 0.95)
const BUNNY_HOP_H := 0.3
const BUNNY_AIR_SEC := 0.44
const BUNNY_SIT_SEC := Vector2(0.8, 2.6)
const BUNNY_CROUCH_SEC := 0.14
const BUNNY_LAND_SEC := 0.16
const BUNNY_RANGE_DEG := 7.0
const BUNNY_SHY_M := 2.2
const BUNNY_SHY_SPEED := 0.6
const BUNNY_HELLO_M := 5.5
const BUNNY_HELLO_STILL := 0.8
const BUNNY_HELLO_SEC := 3.5
const BUNNY_HELLO_REST := 6.0
const BUNNY_POP_SEC := 0.45
const BUNNY_BIG_SPARE := 0.45
const BUNNY_BIG_MAX := 2.3
const BUNNY_BIG_EVERY := 1.6
## A brought creature goes home (back into the chalk / off into the sky) once it has been out this long
## and you have left it SCOUT_DOWN_M behind, out of view.
const SCOUT_OUT_MIN_SEC := 12.0
const SCOUT_DOWN_M := 5.0
const PAD_CLEAR_DEG := 15.0
enum HopState { SIT, CROUCH, AIR, LAND, HELLO, GONE, POP }

# ------------------------------------------------------------------------------ glow worms
const WORMS := 6
const WORM_SEGS := 5
const WORM_SEG_M := 0.085
const WORM_SPEED := 0.12
const WORM_REAR_EVERY := 9.0
const WORM_REAR_SEC := 1.6

# ------------------------------------------------------------------------------ Grig's count
## Point the camera at Grig from within 7 m and he stops, turns to you and HOLDS STILL this long (he is
## a stonecutter: a sitter who fidgets is a smudge). His walk is switched off for it and given back after.
## (First build: he turned once and walked on, so a held shutter caught his back - seen in the probe's
## frames, 2026-09-25.)
const GRIG_HOLD_SEC := 3.0
const COUNT_TAP_SEC := 0.7
const COUNT_SAY_SEC := 1.2
const COUNT_STAND_M := 0.85
## SafariLayer.intro_hint holds the one banner this long at the start.
const INTRO_HINT_SEC := 5.1
const LINE_SEC := 3.6
const SHY_FRAME_GROW := 1.1
## THE VARIETY GATE for the shelf owls nothing brings (see _over_share; the bringers no longer use it). A
## notch under the spec's 30% (Pacing.MAX_SHARE), so the owls found on their own shelves - which nothing
## gates - have room: at 30% the careful test player's photos were 36% owls and 36% bunnies (10 runs).
const VARIETY_GATE := 0.25
## The pacing director's "nothing clearly in view this long" (SafariWorld.Pacing.AFTER_SEC, Bolt's 12).
const PACING_AFTER_SEC := 9.5
## ...and in the RARE_LEAD_SEC before a rare comes up (the moon, the stack), when the director will have
## to stay quiet for it (spec 13.2), it steps in sooner, so nobody goes into that quiet already lonely.
const PACING_AFTER_SOON := 4.0
## Pacing.RETRY_SEC (Bolt's 3).
const PACING_RETRY_SEC := 2.5
const RARE_LEAD_SEC := 10.0
## How high over the ground ahead a brought creature may come into view (Pacing.RISE_MAX_M, Bolt's 1.85):
## the visiting owl hovers up to this; a dust-bunny's leap reaches BUNNY_BIG_MAX.
const OWL_RISE_MAX_M := 3.2

# ------------------------------------------------------------------------------ state
var pacing: SafariWorld.Pacing
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}
var _rock: ShaderMaterial
var _prop: ShaderMaterial

var _pad_dir := Vector3.UP
var _henge_dir := Vector3.UP
var _stones: Array = []           # ring order: {node, mesh, dir, pos, up, h, variant, az}
var _bug_places: Array[Vector3] = []
var _drift_dirs: Array[Vector3] = []

var _bug_herd: Herd
var _bugs: Array = []
var _bug_focus: Node3D
var _bug_pick := -1

var _owl_herd: Herd
var _owls: Array = []
var _owl_focus: Node3D
var _owl_pick := -1
var _owl_still := 0.0
var _owl_look_next := 0.0

var _bun_herd: Herd
var _bunnies: Array = []
var _bun_focus: Node3D
var _bun_pick := -1
var _bun_still := 0.0
var _bun_hello_next := 0.0
var _boing_next := 0.0

var _worm_body: Herd
var _worm_heads: Herd
var _worms: Array = []
var _worm_focus: Node3D
var _worm_pick := -1
var _worm_rho := 0.3              # radians round from the henge centre
var _worm_ref := Vector3.FORWARD

var _grig: Node3D
var _grig_saved := Transform3D()
var _grig_wander_saved := true
var _grig_borrowed := false
var _grig_run := ""
var _grig_wave_until := -1.0
var _grig_pose_until := -1.0
var _grig_next_wave := 0.0
var _grig_next_pose := 0.0
var _grig_hold_until := -1.0
var _grig_came_at := -INF
var _grig_came_n := 0
var _grig_stay_until := -INF
var _count_focus: Node3D
var _count_arcs: Array = []       # per arc: [stone index, ...]
var _count_plan: Array = []       # the running count: [{t0, t1, kind: walk/tap/say, from, to, stone}]
var _count_state := ""
var _count_stone := -1
var _tap_sparks: CPUParticles3D

var _drift_root: Node3D
var _drift_at := -1
var _drift_arms: Array[CPUParticles3D] = []
var _drift_thick: Array[CPUParticles3D] = []
var _drift_skitter: CPUParticles3D
var _drift_focus: Node3D
var _gust_clock := 0.0

var _hum_stones: Array[int] = []
var _hum_collars: Array[MeshInstance3D] = []
var _hum_mat: ShaderMaterial
var _hum_ring: MeshInstance3D
var _hum_ring_mat: ShaderMaterial
var _hum_dust: CPUParticles3D
var _hum_focus: Node3D
var _hum_glow: MeshInstance3D
var _hum_glow_mat: ShaderMaterial
var _hum_at := -1
var _hum_sound: AudioStreamPlayer

var _moon: MeshInstance3D
var _moon_halo: MeshInstance3D
var _moon_halo_mat: ShaderMaterial
var _moon_gap := Vector2i(-1, -1)
var _moon_g := Vector3.FORWARD
var _moon_eye := Vector3.ZERO
var _moon_up := Vector3.UP
var _moon_d := 45.0
var _moon_r := 5.0
var _moon_el_hide := -0.6
var _moon_el_up := -0.3
var _moon_chime_next := 0.0

var _stack_herd: Herd
var _stack: Array = []
var _stack_focus: Node3D
var _stack_dir := Vector3.UP
var _stack_h := 0.0

var _beacons: Dictionary = {}
var _lines: Array = []
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []

var _stones_focus: Node3D
var _stones_pick := -1
var _shelves: Array[Node3D] = []
var _shelves_focus: Node3D
var _shelves_pick := -1
var _sight_pick_in := 0.0
var _tally: MeshInstance3D
var _tally_stone := -1
var _tally_focus: Node3D
var _tally_front := Vector3.UP
var _tenth: MeshInstance3D
var _tenth_focus: Node3D
var _drawing: MeshInstance3D
var _drawing_focus: Node3D
var _extras_hidden := false


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 8_9092_5
	_rock = PlanetPropMeshes.rock_material()
	_prop = PlanetPropMeshes.prop_material()
	_find_places()
	_build_bugs()
	_build_owls()
	_build_bunnies()
	_build_grig()
	_build_count()
	_build_drift()
	_build_hum()
	_build_moon()
	if safari.is_rare_day:
		_build_stack()
	if safari.is_night:
		_build_worms()
	_build_scrapbook()
	_register_events()
	pacing = SafariWorld.Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	# Grig's world is the smallest (9.5 m): the director steps in a little sooner than on Bolt's (12 s),
	# which keeps the longest quiet stretch inside the band (measured, see the report).
	pacing.AFTER_SEC = PACING_AFTER_SEC
	# a brought creature that was not seen (you turned away) lets the next come a little sooner
	pacing.RETRY_SEC = PACING_RETRY_SEC
	# looking up over the deck: an owl can fly in higher than a bunny can leap (the bunny turns down a
	# rise it cannot reach, and the director asks the next bringer)
	pacing.RISE_MAX_M = OWL_RISE_MAX_M
	# `ready` says only whether one is FREE to bring: which one, and when an over-share one may still come,
	# is the director's (SafariWorld.Pacing: THE PER-BRING CAP, spec 17.1 rule 7). The local
	# `and not _over_share(id)` on each went (spec 17.3 ruling 3): with all three at 1/1/1 photos every
	# bringer was locked and the director's 20 s fallback never fired (PACE critic r2, 2026-09-27).
	pacing.add_bringer({"id": "dust_bunny", "bring": _bring_bunny,
		"ready": func() -> bool: return _free_scout() >= 0})
	pacing.add_bringer({"id": "shelf_owl", "bring": _bring_owl,
		"ready": func() -> bool: return _free_visitor() >= 0})
	pacing.add_bringer({"id": "pebble_bug", "bring": _bring_bug,
		"ready": func() -> bool: return _free_stray() >= 0 and not _stack_on(_t)})
	pacing.add_bringer({"id": "grig", "bring": _bring_grig, "ready": _grig_can_come})
	pacing.places = _creature_places
	safari.photo_taken.connect(_on_photo)
	_building = true
	tick(0.0, 0.0)
	_building = false
	_log("built: henge=%s stones=%d grig=%s bugs %s drift %s hums %s moon gap %s rare=%s night=%s" % [
		_pp(_henge_dir), _stones.size(), _pp(_grig_dir()), str(_bug_places.map(_pp)), str(_drift_dirs.map(_pp)),
		str(_hum_stones), str(_moon_gap), str(safari.is_rare_day), str(safari.is_night)])


func _find_places() -> void:
	var p := safari.planet
	_pad_dir = p.data.pad_dir.normalized() if p.data != null else safari.start_dir
	_henge_dir = p.data.spawn_dir.normalized() if p.data != null else safari.dir_from_start(64.0, 49.0)
	for b: Vector2 in P_BUG_PLACES:
		_bug_places.append(_free_near(safari.dir_from_start(b.x, b.y), 1.2))
	for d: Vector2 in P_DRIFT:
		_drift_dirs.append(_free_near(safari.dir_from_start(d.x, d.y), 1.4))
	# the henge: every monolith, in ring order round the landing point
	var c := _henge_dir
	var ref := _tangent_at(c)
	for n in p.get_node("Props").get_children():
		if not str(n.name).begins_with("Monolith"):
			continue
		var node := n as Node3D
		var mi := node.get_node_or_null("Mesh") as MeshInstance3D
		var aabb_h := mi.get_aabb().size.y * mi.scale.y if mi != null and mi.mesh != null else 2.6
		var dir := p.dir_of(node.global_position)
		var t := dir - c * dir.dot(c)
		var az := rad_to_deg(ref.signed_angle_to(t.normalized(), c)) if t.length() > 1e-5 else 0.0
		_stones.append({"node": node, "mesh": mi, "dir": dir, "pos": node.global_position,
			"up": p.up_at(node.global_position), "h": (aabb_h - 0.0475) / 0.935, "aabb_h": aabb_h,
			"variant": int(str(n.name).substr(8)), "az": az})
	_stones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["az"]) < float(b["az"]))
	# the count arcs: the three stones nearest the start in ring order, and the three opposite them
	var near_i := 0
	var best := INF
	for i in _stones.size():
		var a := safari.start_dir.angle_to(_stones[i]["dir"])
		if a < best:
			best = a
			near_i = i
	var n_st := _stones.size()
	if n_st >= 6:
		# the arc round the nearest stone, turned so it starts at the end nearer the start
		var arc0: Array = [(near_i - 1 + n_st) % n_st, near_i, (near_i + 1) % n_st]
		if safari.start_dir.angle_to(_stones[arc0[2]]["dir"]) < safari.start_dir.angle_to(_stones[arc0[0]]["dir"]):
			arc0.reverse()
		var opp := (near_i + n_st / 2) % n_st
		_count_arcs = [arc0, [(opp - 1 + n_st) % n_st, opp, (opp + 1) % n_st]]
	# the moon's gap: of the gaps between neighbouring stones, the one facing most away from the start
	# (so from the start you look across the henge at it, and from the middle it rises between them)
	var to_start := _toward(c, safari.start_dir)
	var gbest := INF
	for i in n_st:
		var j := (i + 1) % n_st
		var gdir := (_toward(c, _stones[i]["dir"]) + _toward(c, _stones[j]["dir"])).normalized()
		var dd := gdir.dot(to_start)
		if dd < gbest:
			gbest = dd
			_moon_gap = Vector2i(i, j)
			_moon_g = gdir


## A photo was taken: the shutter startles the owl in it (it flies off a moment later, OWL_STARTLE_SEC),
## and a brought bunny in it is ready to puff away as soon as you look elsewhere. A creature you have
## just photographed does not stay to be photographed again and again (spec 13.2's variety).
func _on_photo(ph: Dictionary) -> void:
	var id := str(ph.get("subject_key", "")).get_slice(":", 1)
	if id == "shelf_owl" and _owl_pick >= 0:
		_owls[_owl_pick]["startle_at"] = _t + OWL_STARTLE_SEC
		_log("owl photographed t=%.1f: %s" % [_t, "the visitor" if bool(_owls[_owl_pick]["visitor"]) else "a shelf-owl"])
	elif id == "dust_bunny" and _bun_pick >= 0:
		_bunnies[_bun_pick]["out_since"] = _t - SCOUT_OUT_MIN_SEC


## THE VARIETY RULE for the owls that LIVE on the shelves (the director never brings those): once the
## player has MIN_PHOTOS_FOR_SHARE photos and owls make up VARIETY_GATE of them, a sitting one out of the
## frame goes off hunting (_tick_owls). The BRINGERS no longer ask this (spec 17.3 ruling 3): the director's
## own per-bring cap decides what it brings and lifts an over-share one after at most 20 s of nothing.
func _over_share(id: String) -> bool:
	if pacing == null:
		return false
	var tot := 0
	for k: String in pacing.photos:
		tot += int(pacing.photos[k])
	return tot >= pacing.MIN_PHOTOS_FOR_SHARE and pacing.share_of(id) >= VARIETY_GATE


func _grig_dir() -> Vector3:
	return safari.planet.dir_of(_grig.global_position) if _grig != null and is_instance_valid(_grig) else Vector3.UP


## Every creature's place and every awake event (the pacing director keeps what it brings clear of
## them, and waits while you walk toward one).
func _creature_places() -> Array:
	var p := safari.planet
	var out: Array = []
	if not _stack_on(_t):
		for d: Vector3 in _bug_places:
			out.append(p.surface_point(d))
	for o: Dictionary in _owls:
		if int(o["state"]) != OwlState.GONE:
			out.append((o["xf"] as Transform3D).origin)
	if _grig != null and is_instance_valid(_grig):
		out.append(_grig.global_position)
	for h: Dictionary in _bunnies:
		if int(h["state"]) != HopState.GONE:
			out.append(p.surface_point(h["dir"]))
	for b: Dictionary in _bugs:
		if bool(b["stray"]) and int(b["state"]) != BugState.GONE:
			out.append(p.surface_point(b["dir"]))
	if _worm_pick >= 0 or not _worms.is_empty():
		for w: Dictionary in _worms:
			out.append(w.get("head_pos", p.surface_point(_henge_dir)))
	for sj: Dictionary in safari.awake_subjects():
		if str(sj.get("kind", "")) == "event":
			out.append(SafariPhotoScorer.subject_point(sj))
	return out


# ---------------------------------------------------------------------------------------- pebble-bugs
func _build_bugs() -> void:
	var p := safari.planet
	var pts: Array = []
	for pi in _bug_places.size():
		var place: Vector3 = _bug_places[pi]
		var n0 := _bugs.size()
		var tries := 0
		while _bugs.size() < n0 + BUG_PER_PLACE and tries < 400:
			tries += 1
			var d := _polar(place, _tangent_at(place), _rng.randf_range(BUG_SPREAD_DEG.x, BUG_SPREAD_DEG.y), _rng.randf_range(0.0, 360.0))
			if p.nearest_prop_distance(d) < 0.5 or p.ground_normal(d).angle_to(d) > deg_to_rad(9.0):
				continue
			var ok := true
			for b: Dictionary in _bugs:
				if p.surface_distance(d, b["home"]) < 1.0:
					ok = false
					break
			if not ok:
				continue
			_bugs.append(_new_bug(d, false, pi))
			pts.append(p.surface_point(d))
	for k in BUG_STRAYS:
		var b := _new_bug(safari.start_dir, true, -1)
		b["state"] = BugState.GONE
		_bugs.append(b)
	var rr := p.radius + 1.5
	_bug_herd = Herd.new()
	add_child(_bug_herd)
	_bug_herd.setup("PebbleBugs", _bugs.size(), [[Meshes.bug_body(), _rock, true], [Meshes.bug_ball(), _rock, true]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_bug_focus = Node3D.new()
	_bug_focus.name = "BugFocus"
	add_child(_bug_focus)
	safari.add_subject({
		"id": "pebble_bug", "name": "Pebble-bug", "kind": "creature",
		# the sphere sits a little high on the bug so its lowest sight ray clears the ground it stands on
		# (at 0.07 that ray grazed the chalk 0.3 m short of it and no shot of a pebble-bug was ever whole)
		"band": BAND_BUG, "node": _bug_focus, "offset": Vector3(0.0, 0.13, 0.0), "radius": 0.19,
		"awake": func() -> bool: return _bug_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _bug_moment(),
		"front": func() -> Vector3: return _front_of(_bug_focus),
	})


func _new_bug(d: Vector3, stray: bool, place: int) -> Dictionary:
	return {"home": d, "dir": d, "face": _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU)), "state": BugState.OUT,
		"timer": _rng.randf_range(0.5, 2.5), "target": d, "k": 1.0, "for_you": 0.0, "phase": _rng.randf_range(0.0, TAU),
		"peeked": false, "stray": stray, "place": place, "out_since": -INF, "moving": 0.0}


func _bug_moment() -> Dictionary:
	if _bug_pick < 0:
		return {"mult": 1.0, "line": ""}
	var b: Dictionary = _bugs[_bug_pick]
	if int(b["state"]) == BugState.OUT and float(b["for_you"]) > BUG_FOR_YOU_SEC - BUG_FOR_YOU_MOMENT:
		return {"mult": 1.8, "line": "uncurled to see you"}
	if int(b["state"]) == BugState.BOUNCE:
		# its arrival over the step edge: an entrance, not a moment
		return {"mult": 1.0, "line": ""}
	if int(b["state"]) == BugState.UNCURL:
		return {"mult": 1.4, "line": "uncurling"}
	return {"mult": 1.0, "line": ""}


func _tick_bugs(delta: float) -> void:
	if _bug_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	var shy := pacing != null and pacing.shy("pebble_bug")
	var stacking := _stack_on(_t)
	for i in _bugs.size():
		var b: Dictionary = _bugs[i]
		var here := p.surface_point(b["dir"])
		var dist := here.distance_to(ppos)
		var rushed := (dist < BUG_RUSH_M and speed > BUG_RUSH_SPEED) or (dist < BUG_TOO_CLOSE_M and not still_up) or _sleeping
		b["for_you"] = maxf(float(b["for_you"]) - delta, 0.0)
		b["timer"] = float(b["timer"]) - delta
		var st: int = b["state"]
		# the Great Stack: every bug curls and rolls off to it (they are the stack's herd until it ends)
		if stacking and st != BugState.GONE:
			if st != BugState.BALL and st != BugState.CURL:
				b["state"] = BugState.CURL
				b["timer"] = BUG_CURL_SEC
				st = BugState.CURL
			elif st == BugState.BALL:
				b["roll"] = float(b.get("roll", 0.0)) + delta
				var away := _toward(b["dir"], _stack_dir)
				b["dir"] = p.step_dir(b["dir"], (b["dir"] as Vector3) + away * 0.2, 1.2 * delta)
				if float(b["roll"]) > 1.2 and not _point_in_frame(here, 1.05):
					b["state"] = BugState.GONE
					b["roll"] = 0.0
		elif not stacking and st == BugState.GONE and not bool(b["stray"]):
			# back from the stack: home again, curled, uncurling when nobody is looking
			b["dir"] = b["home"]
			b["state"] = BugState.BALL
			b["timer"] = _rng.randf_range(1.0, 3.0)
			st = BugState.BALL
		# one new thing at a time: out of the frame, straight into a ball; out again after
		if shy and (st == BugState.OUT or st == BugState.UNCURL) and not _point_in_frame(here + p.up_at(here) * 0.07, SHY_FRAME_GROW):
			b["state"] = BugState.BALL
			b["k"] = 0.0
			b["shy"] = true
			b["for_you"] = 0.0
			st = BugState.BALL
		# a stray the director brought goes back into the chalk once you have left it behind
		if bool(b["stray"]) and st != BugState.GONE and _t - float(b["out_since"]) > SCOUT_OUT_MIN_SEC \
				and dist > SCOUT_DOWN_M and not _point_in_frame(here, 1.2):
			b["state"] = BugState.GONE
			st = BugState.GONE
		match st:
			BugState.OUT:
				if rushed:
					_bug_curl(b, here)
				else:
					if float(b["timer"]) <= 0.0:
						b["timer"] = _rng.randf_range(1.5, 3.4)
						b["target"] = _polar(b["home"], _tangent_at(b["home"]), _rng.randf_range(0.0, 5.0), _rng.randf_range(0.0, 360.0))
					_bug_walk(b, b["target"], 0.32, delta)
					if float(b["for_you"]) > 0.0 and dist < BUG_NOTICE_M:
						_face_toward(b, ppos, delta)
			BugState.CURL:
				b["k"] = clampf(float(b["timer"]) / BUG_CURL_SEC, 0.0, 1.0)
				if float(b["timer"]) <= 0.0:
					b["state"] = BugState.BALL
					b["k"] = 0.0
					b["timer"] = _rng.randf_range(2.0, 3.5)
					b["still"] = 0.0
			BugState.BALL:
				if _sleeping or stacking:
					pass
				elif bool(b.get("shy", false)):
					if not shy:
						b["shy"] = false
						b["state"] = BugState.UNCURL
						b["timer"] = BUG_UNCURL_SEC
						b["peeked"] = false
				elif dist < BUG_NOTICE_M:
					b["still"] = (float(b.get("still", 0.0)) + delta) if still_up else 0.0
					if float(b["timer"]) <= 0.0 and float(b["still"]) >= BUG_STILL_SEC:
						b["state"] = BugState.UNCURL
						b["timer"] = BUG_UNCURL_SEC
						b["peeked"] = true
						AudioManager.play_sfx_at("ui_tick", here, -8.0)
				elif float(b["timer"]) <= 0.0:
					b["state"] = BugState.UNCURL
					b["timer"] = BUG_UNCURL_SEC
					b["peeked"] = false
			BugState.BOUNCE:
				var f := clampf(1.0 - float(b["timer"]) / float(b["air_t"]), 0.0, 1.0)
				b["h"] = 4.0 * float(b["apex"]) * f * (1.0 - f)
				b["k"] = clampf((f - 0.15) / 0.25, 0.0, 1.0)
				_face_toward(b, ppos, delta * 2.0)
				if float(b["timer"]) <= 0.0:
					b["h"] = 0.0
					b["k"] = 1.0
					b["state"] = BugState.OUT
					b["timer"] = _rng.randf_range(1.5, 3.0)
					# (the bounce was its moment; it faces you after, but "came to see you" is for waiting)
					b["for_you"] = 0.0
					b["peeked"] = false
					AudioManager.play_sfx_at("land", here, -14.0, 0.2)
			BugState.UNCURL:
				b["k"] = clampf(1.0 - float(b["timer"]) / BUG_UNCURL_SEC, 0.0, 1.0)
				if bool(b["peeked"]):
					_face_toward(b, ppos, delta * 2.0)
				if rushed:
					_bug_curl(b, here)
				elif float(b["timer"]) <= 0.0:
					b["state"] = BugState.OUT
					b["k"] = 1.0
					b["timer"] = _rng.randf_range(1.5, 3.0)
					if bool(b["peeked"]):
						b["for_you"] = BUG_FOR_YOU_SEC
						AudioManager.play_sfx_at("emote_wave", here, -10.0)
		_pose_bug(i, b)
	_bug_pick = _pick_focus(_bugs, func(b: Dictionary) -> bool:
			var bs := int(b["state"])
			return bs == BugState.OUT or ((bs == BugState.UNCURL or bs == BugState.BOUNCE) and float(b["k"]) > 0.5),
		func(b: Dictionary) -> Vector3: return p.surface_point(b["dir"]), 0.07)
	if _bug_pick >= 0:
		_bug_focus.global_transform = _xf_ground(_bugs[_bug_pick]["dir"], _bugs[_bug_pick]["face"])


func _bug_curl(b: Dictionary, here: Vector3) -> void:
	b["state"] = BugState.CURL
	b["timer"] = BUG_CURL_SEC * float(b["k"])
	b["for_you"] = 0.0
	AudioManager.play_sfx_at("rotate", here, -8.0, 0.2)


func _bug_walk(b: Dictionary, target: Vector3, speed: float, delta: float) -> void:
	var p := safari.planet
	var d: Vector3 = b["dir"]
	var dist := p.surface_distance(d, target)
	if dist < 0.02:
		return
	var nd := p.step_dir(d, target, minf(speed * delta, dist))
	if p.nearest_prop_distance(nd) < 0.35 or rad_to_deg(nd.angle_to(_pad_dir)) < PAD_CLEAR_DEG:
		b["target"] = b["home"]
		return
	var mv := nd - d
	if mv.length() > 1e-6:
		var want := mv - d * mv.dot(d)
		var cur: Vector3 = b["face"]
		b["face"] = cur.slerp(want.normalized(), clampf(6.0 * delta, 0.0, 1.0)).normalized()
	b["dir"] = nd
	b["moving"] = 0.25


func _face_toward(c: Dictionary, world_pos: Vector3, delta: float) -> void:
	var d: Vector3 = c["dir"]
	var want := world_pos - safari.planet.surface_point(d)
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = c["face"]
	cur -= d * cur.dot(d)
	c["face"] = cur.normalized().slerp(want.normalized(), clampf(5.0 * delta, 0.0, 1.0)).normalized()


func _pose_bug(i: int, b: Dictionary) -> void:
	var st: int = b["state"]
	if st == BugState.GONE:
		_bug_herd.hide_one(i)
		return
	var base := _xf_ground(b["dir"], b["face"])
	var k := float(b["k"])
	if st == BugState.BALL or ((st == BugState.CURL or st == BugState.UNCURL or st == BugState.BOUNCE) and k < 0.35):
		var roll := float(b.get("roll", 0.0)) * 6.0 + (float(b.get("h", 0.0)) * 5.0 if st == BugState.BOUNCE else 0.0)
		var wob := 0.08 * sin(_t * 9.0 + float(b["phase"])) if st == BugState.UNCURL else 0.0
		_bug_herd.pose(i, 0, Herd.ZERO)
		_bug_herd.pose(i, 1, base.translated_local(Vector3(0.0, float(b.get("h", 0.0)), 0.0)) * Transform3D(Basis(Vector3.RIGHT, roll + wob), Vector3.ZERO))
		return
	var ph := float(b["phase"]) + _t * 8.0
	var moving := float(b.get("moving", 0.0))
	b["moving"] = maxf(moving - get_process_delta_time(), 0.0)
	var bob := 0.01 * absf(sin(ph * 1.5)) * (1.0 if moving > 0.0 else 0.2) + float(b.get("h", 0.0))
	var sq := lerpf(0.55, 1.0, clampf((k - 0.35) / 0.65, 0.0, 1.0))
	var xf := base.translated_local(Vector3(0.0, bob, 0.0))
	xf.basis = xf.basis * Basis.from_scale(Vector3(1.0, sq, lerpf(0.7, 1.0, sq)))
	_bug_herd.pose(i, 0, xf)
	_bug_herd.pose(i, 1, Herd.ZERO)


func _free_stray() -> int:
	for i in _bugs.size():
		if bool(_bugs[i]["stray"]) and int(_bugs[i]["state"]) == BugState.GONE:
			return i
	return -1


## THE PACING DIRECTOR brings a stray pebble-bug: a pebble pops out of the chalk where you are about to
## look, and uncurls to see you. Ground only.
func _bring_bug(spot: Dictionary) -> bool:
	var d: Vector3 = spot["dir"]
	var i := _free_stray()
	if i < 0:
		return false
	if d == Vector3.ZERO:
		var a: Vector3 = spot["ahead"]
		var rise := float(spot["rise"])
		if a == Vector3.ZERO or rise < 0.0:
			return false
		var apex := rise + pacing.SPOT_LIFT_M - 0.07 + BUG_BOUNCE_SPARE
		if apex > BUG_BOUNCE_MAX:
			return false
		var bb: Dictionary = _bugs[i]
		bb["dir"] = a
		bb["home"] = a
		bb["target"] = a
		bb["face"] = _toward(a, _player_dir())
		bb["state"] = BugState.BOUNCE
		bb["apex"] = apex
		bb["air_t"] = BUNNY_AIR_SEC * sqrt(apex / BUNNY_HOP_H)
		bb["timer"] = float(bb["air_t"])
		bb["k"] = 0.0
		bb["h"] = 0.0
		bb["still"] = 0.0
		bb["shy"] = false
		bb["peeked"] = true
		bb["out_since"] = _t
		var g := safari.planet.surface_point(a)
		safari.puff_at(g, 8, Meshes.CHALK)
		AudioManager.play_sfx_at("jump", g, -10.0, 0.3)
		return true
	var b: Dictionary = _bugs[i]
	b["dir"] = d
	b["home"] = d
	b["target"] = d
	b["face"] = _toward(d, _player_dir())
	b["state"] = BugState.BALL
	b["k"] = 0.0
	b["timer"] = 0.35
	b["still"] = 0.0
	b["shy"] = false
	b["out_since"] = _t
	var here := safari.planet.surface_point(d)
	safari.puff_at(here, 8, Meshes.CHALK)
	AudioManager.play_sfx_at("rotate", here, -8.0, 0.2)
	# it uncurls at once, facing you (its "uncurled to see you" moment is for a player who waits by a
	# curled one, not for this arrival)
	b["state"] = BugState.UNCURL
	b["timer"] = BUG_UNCURL_SEC + 0.3
	b["peeked"] = false
	return true


# ---------------------------------------------------------------------------------------- shelf-owls
func _build_owls() -> void:
	var p := safari.planet
	for nm: String in OWL_SHELVES:
		var shelf := p.get_node_or_null("Props/" + nm) as Node3D
		if shelf == null:
			continue
		var sb := shelf.global_basis.orthonormalized()
		var up := sb.y
		# face out over the drop: the side of the shelf where the ground is lower
		var fz := sb.z
		var lo_pos := p.surface_point(p.dir_of(shelf.global_position + fz * 1.2)).length()
		var lo_neg := p.surface_point(p.dir_of(shelf.global_position - fz * 1.2)).length()
		var face := (-fz if lo_neg < lo_pos else fz)
		for k in OWLS_PER_SHELF:
			var x := -0.55 + 1.1 * float(k) if OWLS_PER_SHELF > 1 else 0.0
			# at the front of the deck, over the drop, so the deck's own edge does not hide its feet
			var seat := shelf.global_transform * Vector3(x, 0.70, 0.0) + face * OWL_SEAT_FWD_M
			var xf := Transform3D(Basis.looking_at(face, up), seat)
			_owls.append(_new_owl(xf, false))
	for k in OWL_VISITORS:
		var o := _new_owl(Transform3D(Basis.IDENTITY, p.surface_point(safari.start_dir)), true)
		o["state"] = OwlState.GONE
		_owls.append(o)
	var rr := p.radius + 4.0
	_owl_herd = Herd.new()
	add_child(_owl_herd)
	_owl_herd.setup("ShelfOwls", _owls.size(), [[Meshes.owl_body(), _prop, true], [Meshes.owl_head(), _prop, true],
		[Meshes.owl_wings(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_owl_focus = Node3D.new()
	_owl_focus.name = "OwlFocus"
	add_child(_owl_focus)
	safari.add_subject({
		"id": "shelf_owl", "name": "Shelf-owl", "kind": "creature",
		"band": BAND_OWL, "node": _owl_focus, "offset": Vector3(0.0, 0.28, 0.0), "radius": 0.22,
		"awake": func() -> bool: return _owl_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _owl_moment(),
		"front": func() -> Vector3: return _front_of(_owl_focus),
	})


func _new_owl(seat: Transform3D, visitor: bool) -> Dictionary:
	return {"seat": seat, "xf": seat, "yaw": 0.0, "yaw_to": _rng.randf_range(-60.0, 60.0), "timer": _rng.randf_range(0.5, 2.5),
		"state": OwlState.SIT, "visitor": visitor, "fly_t": 0.0, "from": seat.origin, "hover": Vector3.ZERO,
		"out_since": -INF, "phase": _rng.randf_range(0.0, TAU), "look_left": 0.0}


func _owl_moment() -> Dictionary:
	if _owl_pick < 0:
		return {"mult": 1.0, "line": ""}
	var o: Dictionary = _owls[_owl_pick]
	var st: int = o["state"]
	if st == OwlState.FLY_IN and not bool(o["visitor"]):
		# a shelf-owl gliding home (a visitor's glide in is its entrance, not a moment)
		return {"mult": 1.8, "line": "on the wing"}
	if (st == OwlState.SIT or st == OwlState.LOOK) and _owl_stretch(o) > 0.25:
		return {"mult": 1.7, "line": "stretching its wings"}
	return {"mult": 1.0, "line": ""}


## 0..1 while owl `o` stretches its wings (for OWL_STRETCH_SEC, every OWL_STRETCH_EVERY or so, its own
## phase). Looking at you is its FACING (the score), not a moment; the stretch is the moment.
func _owl_stretch(o: Dictionary) -> float:
	var every := OWL_STRETCH_EVERY + 4.0 * sin(float(o["phase"]) * 3.0)
	var ph := fmod(_t + float(o["phase"]) * 4.0, every)
	return sin(ph / OWL_STRETCH_SEC * PI) if ph < OWL_STRETCH_SEC else 0.0


## The head's yaw (degrees, in the body's frame) that looks at `world_pos`.
func _owl_yaw_to(o: Dictionary, world_pos: Vector3) -> float:
	var xf: Transform3D = o["xf"]
	var loc := xf.affine_inverse() * world_pos
	return clampf(rad_to_deg(atan2(-loc.x, -loc.z)), -OWL_HEAD_MAX_DEG - 60.0, OWL_HEAD_MAX_DEG + 60.0)


func _tick_owls(delta: float) -> void:
	if _owl_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var lens := cam.global_position if cam != null else pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	_owl_still = (_owl_still + delta) if still_up else 0.0
	var shy := pacing != null and pacing.shy("shelf_owl")
	# THE VARIETY RULE for the owls that live on the shelves (the director never brings those, so its gate
	# cannot hold them): measured on the earlier build, the careful test player's photos were 35% owls (14
	# of 40, 5 runs). Only photos count, so a player who takes none - the density gate's wanderer - meets
	# exactly the same owls.
	var held := _over_share("shelf_owl")
	# the one that looks at you: the nearest sitting one, once you have stood still with the camera up
	var look_i := -1
	if _owl_still >= OWL_LOOK_STILL and _t >= _owl_look_next and not _sleeping:
		var best := OWL_LOOK_M
		for i in _owls.size():
			var od: Dictionary = _owls[i]
			if int(od["state"]) != OwlState.SIT:
				continue
			var dd := (od["xf"] as Transform3D).origin.distance_to(lens)
			if dd < best:
				best = dd
				look_i = i
	for i in _owls.size():
		var o: Dictionary = _owls[i]
		var here: Vector3 = (o["xf"] as Transform3D).origin
		var dist := here.distance_to(pl.global_position)
		o["timer"] = float(o["timer"]) - delta
		var st: int = o["state"]
		if _sleeping and st != OwlState.GONE and st != OwlState.FLY_OFF:
			_owl_fly_off(o)
			st = OwlState.FLY_OFF
		var sitting := st == OwlState.SIT or st == OwlState.LOOK or st == OwlState.SNUB
		if sitting and _t >= float(o.get("startle_at", INF)):
			o.erase("startle_at")
			if not bool(o["visitor"]):
				o["away_until"] = _t + OWL_AWAY_SEC
			_owl_fly_off(o)
			AudioManager.play_sfx_at("tree_shake", here, -14.0, 0.3)
			st = OwlState.FLY_OFF
			sitting = false
		# (held: the owls already make up VARIETY_GATE of your photos - see _over_share - so a sitting one
		# out of the frame goes off hunting until the others catch up)
		if (shy or held) and sitting and not _point_in_frame(here + p.up_at(here) * 0.24, SHY_FRAME_GROW):
			o["state"] = OwlState.GONE
			o["shy"] = true
			st = OwlState.GONE
		elif bool(o["visitor"]) and sitting and _t - float(o["out_since"]) > SCOUT_OUT_MIN_SEC and dist > SCOUT_DOWN_M \
				and not _point_in_frame(here, 1.2):
			o["state"] = OwlState.GONE
			st = OwlState.GONE
		match st:
			OwlState.SIT:
				if float(o["timer"]) <= 0.0:
					o["timer"] = _rng.randf_range(OWL_TURN_EVERY.x, OWL_TURN_EVERY.y)
					o["yaw_to"] = _rng.randf_range(-OWL_HEAD_MAX_DEG, OWL_HEAD_MAX_DEG)
					if absf(float(o["yaw_to"]) - float(o["yaw"])) > 60.0 and dist < 8.0:
						AudioManager.play_sfx_at("ui_tick", here, -16.0, 0.3)
				if i == look_i:
					o["state"] = OwlState.LOOK
					o["timer"] = OWL_LOOK_SEC
					_owl_look_next = _t + OWL_LOOK_SEC + OWL_LOOK_REST
					AudioManager.play_sfx_at("emote_happy", here, -14.0, 0.2)
				elif dist < OWL_RUSH_M and speed > OWL_RUSH_SPEED:
					o["state"] = OwlState.SNUB
					o["timer"] = 3.0
			OwlState.LOOK:
				o["yaw_to"] = _owl_yaw_to(o, lens)
				if float(o["timer"]) <= 0.0 or (dist < OWL_RUSH_M and speed > OWL_RUSH_SPEED):
					o["state"] = OwlState.SIT
					o["timer"] = _rng.randf_range(OWL_TURN_EVERY.x, OWL_TURN_EVERY.y)
			OwlState.SNUB:
				# rushed: it turns its head right round, away from you
				var away := _owl_yaw_to(o, lens) + 180.0
				o["yaw_to"] = clampf(wrapf(away, -180.0, 180.0), -OWL_HEAD_MAX_DEG - 50.0, OWL_HEAD_MAX_DEG + 50.0)
				if float(o["timer"]) <= 0.0:
					o["state"] = OwlState.SIT
			OwlState.GONE:
				var back := bool(o.get("shy", false)) or o.has("away_until")
				if back and not shy and not held and not _sleeping and not bool(o["visitor"]) and _t >= float(o.get("away_until", -INF)):
					o["shy"] = false
					o.erase("away_until")
					_owl_fly_in(o, o["seat"])
			OwlState.FLY_IN:
				var f := clampf(1.0 - float(o["timer"]) / OWL_FLY_SEC, 0.0, 1.0)
				var seat: Transform3D = o["seat"]
				var up := p.up_at(seat.origin)
				var from: Vector3 = o["from"]
				var e := 1.0 - (1.0 - f) * (1.0 - f)
				var pos := from.lerp(seat.origin, e) + up * sin(f * PI) * 0.4
				var fwd := (seat.origin - from)
				fwd -= up * fwd.dot(up)
				o["xf"] = Transform3D(Basis.looking_at(fwd.normalized() if fwd.length() > 0.01 else -seat.basis.z, up), pos)
				o["yaw_to"] = 0.0
				if float(o["timer"]) <= 0.0:
					if o.get("hover", Vector3.ZERO) != Vector3.ZERO:
						o["state"] = OwlState.HOVER
						o["timer"] = OWL_HOVER_SEC
					else:
						o["state"] = OwlState.SIT
						o["xf"] = seat
						o["timer"] = _rng.randf_range(0.6, 1.5)
						AudioManager.play_sfx_at("land", seat.origin, -14.0, 0.2)
			OwlState.HOVER:
				# over the deck: it holds in the air where you look, wings beating, then drops to the ground
				var hov: Vector3 = o["hover"]
				var seat: Transform3D = o["seat"]
				var up := p.up_at(hov)
				var fwd := lens - hov
				fwd -= up * fwd.dot(up)
				var bob := 0.06 * sin(_t * 9.0)
				o["xf"] = Transform3D(Basis.looking_at(fwd.normalized() if fwd.length() > 0.01 else -seat.basis.z, up), hov + up * bob)
				o["yaw_to"] = 0.0
				if float(o["timer"]) <= 0.0:
					o["hover"] = Vector3.ZERO
					o["seat"] = o.get("land", seat)
					o["from"] = hov
					o["state"] = OwlState.FLY_IN
					o["timer"] = OWL_FLY_SEC * 0.7
			OwlState.FLY_OFF:
				var f := clampf(1.0 - float(o["timer"]) / OWL_FLY_SEC, 0.0, 1.0)
				var from: Vector3 = o["from"]
				var up := p.up_at(from)
				var xf0: Transform3D = o["xf"]
				o["xf"] = Transform3D(xf0.basis, from + up * (f * 3.0) - xf0.basis.z * (f * 2.5))
				if float(o["timer"]) <= 0.0:
					o["state"] = OwlState.GONE
		# the head turns quickly, the way an owl's does
		o["yaw"] = move_toward(float(o["yaw"]), float(o["yaw_to"]), 420.0 * delta)
		_pose_owl(i, o)
	_owl_pick = _pick_focus(_owls, func(o: Dictionary) -> bool: return int(o["state"]) != OwlState.GONE and int(o["state"]) != OwlState.FLY_OFF,
		func(o: Dictionary) -> Vector3: return (o["xf"] as Transform3D).origin, 0.24)
	if _owl_pick >= 0:
		var o: Dictionary = _owls[_owl_pick]
		var xf: Transform3D = o["xf"]
		_owl_focus.global_transform = Transform3D(xf.basis * Basis(Vector3.UP, deg_to_rad(float(o["yaw"]))), xf.origin)


func _pose_owl(i: int, o: Dictionary) -> void:
	var st: int = o["state"]
	if st == OwlState.GONE:
		_owl_herd.hide_one(i)
		return
	var xf: Transform3D = o["xf"]
	var ph := float(o["phase"])
	var breathe := 1.0 + 0.02 * sin(_t * 2.2 + ph)
	var flying := st == OwlState.FLY_IN or st == OwlState.HOVER or st == OwlState.FLY_OFF
	var body := xf
	if flying:
		# wings out and beating (the wing part below), the body rocking with them
		body.basis = body.basis * Basis(Vector3.FORWARD, 0.06 * sin(_t * 18.0))
	elif st == OwlState.SNUB:
		body.basis = body.basis * Basis.from_scale(Vector3(1.05, 0.9, 1.0))
	var wings := 0.0
	if flying:
		wings = 0.75 + 0.25 * sin(_t * 18.0)
	elif st != OwlState.SNUB:
		var sx := _owl_stretch(o)
		wings = sx
		body.basis = body.basis * Basis.from_scale(Vector3(1.0, breathe * (1.0 + 0.06 * sx), 1.0))
	_owl_herd.pose(i, 0, body)
	if wings > 0.02:
		_owl_herd.pose(i, 2, Transform3D(xf.basis * Basis.from_scale(Vector3.ONE * wings), xf.origin + xf.basis.y * Meshes.OWL_SHOULDER_Y))
	else:
		_owl_herd.pose(i, 2, Herd.ZERO)
	var head := Transform3D(xf.basis * Basis(Vector3.UP, deg_to_rad(float(o["yaw"]))), xf.origin + xf.basis.y * Meshes.OWL_NECK_Y)
	_owl_herd.pose(i, 1, head)


func _owl_fly_in(o: Dictionary, seat: Transform3D) -> void:
	var up := safari.planet.up_at(seat.origin)
	var side := seat.basis.x.normalized()
	o["seat"] = seat
	o["from"] = seat.origin + up * 2.6 + side * (2.2 if _rng.randf() < 0.5 else -2.2) + seat.basis.z * 1.5
	o["state"] = OwlState.FLY_IN
	o["timer"] = OWL_FLY_SEC
	o["xf"] = Transform3D(seat.basis, o["from"])
	AudioManager.play_sfx_at("tree_shake", seat.origin, -18.0, 0.3)


func _owl_fly_off(o: Dictionary) -> void:
	o["from"] = (o["xf"] as Transform3D).origin
	o["state"] = OwlState.FLY_OFF
	o["timer"] = OWL_FLY_SEC


func _free_visitor() -> int:
	for i in _owls.size():
		if bool(_owls[i]["visitor"]) and int(_owls[i]["state"]) == OwlState.GONE:
			return i
	return -1


## THE PACING DIRECTOR brings a visiting owl: it glides in and lands on the ground where you are about to
## look; looking over the deck, it holds in the air in the middle of your view for a moment first.
func _bring_owl(spot: Dictionary) -> bool:
	var i := _free_visitor()
	if i < 0:
		return false
	var o: Dictionary = _owls[i]
	var p := safari.planet
	var d: Vector3 = spot["dir"]
	o["hover"] = Vector3.ZERO
	if d == Vector3.ZERO:
		var a: Vector3 = spot["ahead"]
		var rise := float(spot["rise"])
		if a == Vector3.ZERO or rise < 0.0:
			return false
		d = a
		var g := p.surface_point(a)
		o["hover"] = g + p.ground_normal(a) * (pacing.SPOT_LIFT_M + rise + 0.05 - 0.24)
	var seat := _xf_ground(d, _toward(d, _player_dir()))
	_owl_fly_in(o, seat)
	if o["hover"] != Vector3.ZERO:
		# into the hover first, then down to the seat
		var hov: Vector3 = o["hover"]
		var up := p.up_at(hov)
		o["from"] = hov + up * 1.8 + seat.basis.x * 2.0
		o["seat"] = Transform3D(seat.basis, hov)
		o["state"] = OwlState.FLY_IN
		o["timer"] = OWL_FLY_SEC * 0.8
		o["land"] = seat
	o["out_since"] = _t
	o["yaw"] = 0.0
	o["yaw_to"] = 0.0
	return true


# ---------------------------------------------------------------------------------------- dust-bunnies
func _build_bunnies() -> void:
	var p := safari.planet
	for k in BUNNY_SCOUTS:
		_bunnies.append({"home": safari.start_dir, "dir": safari.start_dir, "face": safari.start_fwd, "heading": safari.start_fwd,
			"state": HopState.GONE, "timer": 0.0, "from": safari.start_dir, "to": safari.start_dir, "sq": 0.0, "h": 0.0,
			"look": 0.0, "phase": _rng.randf_range(0.0, TAU), "out_since": -INF, "grow": 0.0})
	var rr := p.radius + 3.0
	_bun_herd = Herd.new()
	add_child(_bun_herd)
	_bun_herd.setup("DustBunnies", _bunnies.size(), [[Meshes.bunny_body(), _prop, true], [Meshes.bunny_ears(), _prop, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_bun_focus = Node3D.new()
	_bun_focus.name = "BunnyFocus"
	add_child(_bun_focus)
	safari.add_subject({
		"id": "dust_bunny", "name": "Dust-bunny", "kind": "creature",
		"band": BAND_BUNNY, "node": _bun_focus, "offset": Vector3(0.0, 0.13, 0.0), "radius": 0.20,
		"awake": func() -> bool: return _bun_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _bunny_moment(),
		"front": func() -> Vector3: return _front_of(_bun_focus),
	})


func _bunny_moment() -> Dictionary:
	if _bun_pick < 0:
		return {"mult": 1.0, "line": ""}
	var h: Dictionary = _bunnies[_bun_pick]
	var st: int = h["state"]
	if st == HopState.AIR and not bool(h.get("arriving", false)):
		var f := 1.0 - float(h["timer"]) / float(h.get("air_t", BUNNY_AIR_SEC))
		if f > 0.3 and f < 0.7:
			return {"mult": 1.5, "line": "a big leap!" if float(h.get("air_h", BUNNY_HOP_H)) > 0.6 else "mid-hop!"}
	return {"mult": 1.0, "line": ""}


func _free_scout() -> int:
	for i in _bunnies.size():
		if int(_bunnies[i]["state"]) == HopState.GONE and float(_bunnies[i]["grow"]) <= 0.01:
			return i
	return -1


## THE PACING DIRECTOR brings a dust-bunny: a puff of chalk gathers where you are about to look and it
## is a bunny. Looking over the deck, it gathers ahead and takes a big leap up into your view.
func _bring_bunny(spot: Dictionary) -> bool:
	var i := _free_scout()
	if i < 0:
		return false
	var h: Dictionary = _bunnies[i]
	var d: Vector3 = spot["dir"]
	var big := 0.0
	if d == Vector3.ZERO:
		var a: Vector3 = spot["ahead"]
		var rise := float(spot["rise"])
		if a == Vector3.ZERO or rise < 0.0:
			return false
		big = rise + pacing.SPOT_LIFT_M - 0.13 + BUNNY_BIG_SPARE
		if big > BUNNY_BIG_MAX:
			return false
		d = a
	h["big"] = big
	h["next_big"] = _t + BUNNY_POP_SEC + BUNNY_BIG_EVERY
	h["dir"] = d
	h["home"] = d
	h["from"] = d
	h["to"] = d
	h["state"] = HopState.POP
	h["timer"] = BUNNY_POP_SEC
	h["out_since"] = _t
	# its arrival (the pop and the first leap) is an entrance, not a moment; its later hops and leaps are
	h["arriving"] = true
	h["face"] = _toward(d, _player_dir())
	h["heading"] = h["face"]
	h["h"] = 0.0
	var here := safari.planet.surface_point(d)
	safari.puff_at(here + safari.planet.up_at(here) * 0.12, 12, Meshes.CHALK)
	AudioManager.play_sfx_at("jump", here, -10.0, 0.2)
	return true


func _tick_bunnies(delta: float) -> void:
	if _bun_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	_bun_still = (_bun_still + delta) if still_up else 0.0
	var shy := pacing != null and pacing.shy("dust_bunny")
	var hello_i := -1
	if _bun_still >= BUNNY_HELLO_STILL and _t >= _bun_hello_next and not _sleeping:
		var best := BUNNY_HELLO_M
		for i in _bunnies.size():
			var hd: Dictionary = _bunnies[i]
			if int(hd["state"]) != HopState.SIT:
				continue
			var dd := p.surface_point(hd["dir"]).distance_to(ppos)
			if dd < best:
				best = dd
				hello_i = i
	for i in _bunnies.size():
		var h: Dictionary = _bunnies[i]
		var here := p.surface_point(h["dir"])
		var dist := here.distance_to(ppos)
		h["timer"] = float(h["timer"]) - delta
		var st: int = h["state"]
		if _sleeping and st != HopState.GONE and st != HopState.AIR:
			h["state"] = HopState.GONE
			st = HopState.GONE
		match st:
			HopState.SIT:
				h["look"] = float(h["look"]) + delta
				if float(h["look"]) > 1.1:
					h["look"] = 0.0
					h["face"] = (h["face"] as Vector3).rotated(h["dir"], _rng.randf_range(-0.7, 0.7)).normalized()
				h["sq"] = 1.0 + 0.03 * sin(_t * 3.0 + float(h["phase"]))
				var in_frame := _point_in_frame(here, 1.2)
				if _t - float(h["out_since"]) > SCOUT_OUT_MIN_SEC and dist > SCOUT_DOWN_M and not in_frame:
					_bunny_go(h, here)
				elif shy and not _point_in_frame(here, SHY_FRAME_GROW):
					_bunny_go(h, here)
				elif _t - float(h["out_since"]) < SCOUT_OUT_MIN_SEC and pacing != null and not pacing.in_view \
						and _t >= float(h.get("next_big", 0.0)) and dist < SCOUT_DOWN_M + 1.0:
					# "look at me": you are looking over it, so it leaps up into your view
					h["next_big"] = _t + BUNNY_BIG_EVERY
					var apex := _big_apex(here, p.ground_normal(h["dir"]))
					if apex > 0.0:
						_big_leap(h, apex)
				elif i == hello_i:
					h["state"] = HopState.HELLO
					h["timer"] = BUNNY_HELLO_SEC
					_bun_hello_next = _t + BUNNY_HELLO_SEC + BUNNY_HELLO_REST
					AudioManager.play_sfx_at("ui_tick", here, -10.0, 0.2)
				elif dist < BUNNY_SHY_M and speed > BUNNY_SHY_SPEED:
					_hop_plan(h, here - ppos, true)
				elif float(h["timer"]) <= 0.0:
					_hop_plan(h, Vector3.ZERO, false)
			HopState.CROUCH:
				h["sq"] = lerpf(1.0, 0.6, clampf(1.0 - float(h["timer"]) / BUNNY_CROUCH_SEC, 0.0, 1.0))
				_turn_face(h, h["heading"], 14.0, delta)
				if float(h["timer"]) <= 0.0:
					h["state"] = HopState.AIR
					h["timer"] = float(h.get("air_t", BUNNY_AIR_SEC))
					if _t >= _boing_next and dist < 5.0:
						_boing_next = _t + 0.4
						AudioManager.play_sfx_at("jump", here, -18.0, 0.25)
			HopState.AIR:
				var f := clampf(1.0 - float(h["timer"]) / float(h.get("air_t", BUNNY_AIR_SEC)), 0.0, 1.0)
				h["dir"] = (h["from"] as Vector3).slerp(h["to"], f).normalized()
				h["h"] = 4.0 * float(h.get("air_h", BUNNY_HOP_H)) * f * (1.0 - f)
				h["sq"] = lerpf(1.25, 1.0, f)
				if float(h["timer"]) <= 0.0:
					h["dir"] = h["to"]
					h["h"] = 0.0
					h["state"] = HopState.LAND
					h["timer"] = BUNNY_LAND_SEC
					h["air_h"] = BUNNY_HOP_H
					h["air_t"] = BUNNY_AIR_SEC
			HopState.LAND:
				h["sq"] = lerpf(0.65, 1.0, clampf(1.0 - float(h["timer"]) / BUNNY_LAND_SEC, 0.0, 1.0))
				if float(h["timer"]) <= 0.0 and float(h.get("big", 0.0)) <= 0.0:
					h["arriving"] = false
				if float(h["timer"]) <= 0.0:
					h["state"] = HopState.SIT
					h["timer"] = _rng.randf_range(BUNNY_SIT_SEC.x, BUNNY_SIT_SEC.y)
			HopState.HELLO:
				_turn_face(h, ppos - here, 8.0, delta)
				var bb := absf(sin((BUNNY_HELLO_SEC - float(h["timer"])) * 7.0))
				h["h"] = 0.08 * bb
				h["sq"] = lerpf(0.8, 1.12, bb)
				if float(h["timer"]) <= 0.0 or (dist < BUNNY_SHY_M and speed > BUNNY_SHY_SPEED):
					h["h"] = 0.0
					h["state"] = HopState.SIT
					h["timer"] = _rng.randf_range(BUNNY_SIT_SEC.x, BUNNY_SIT_SEC.y)
			HopState.GONE:
				# back into a puff of chalk
				h["grow"] = maxf(float(h["grow"]) - delta / 0.3, 0.0)
			HopState.POP:
				# gathers out of a puff of chalk, turning to see you
				var f := clampf(1.0 - float(h["timer"]) / BUNNY_POP_SEC, 0.0, 1.0)
				h["grow"] = f
				h["sq"] = lerpf(1.3, 1.0, f)
				_turn_face(h, ppos - here, 10.0, delta)
				if float(h["timer"]) <= 0.0:
					h["grow"] = 1.0
					h["state"] = HopState.LAND
					h["timer"] = BUNNY_LAND_SEC
					if float(h.get("big", 0.0)) > 0.0:
						_big_leap(h, float(h["big"]))
					h["big"] = 0.0
		_pose_bunny(i, h)
	_bun_pick = _pick_focus(_bunnies, func(h: Dictionary) -> bool: return int(h["state"]) != HopState.GONE and float(h["grow"]) > 0.6,
		func(h: Dictionary) -> Vector3: return (h["body"] as Transform3D).origin if h.has("body") else p.surface_point(h["dir"]), 0.13)
	if _bun_pick >= 0 and _bunnies[_bun_pick].has("body"):
		_bun_focus.global_transform = _bunnies[_bun_pick]["body"]


func _bunny_go(h: Dictionary, here: Vector3) -> void:
	h["state"] = HopState.GONE
	if _point_in_frame(here, 1.0):
		safari.puff_at(here + safari.planet.up_at(here) * 0.12, 8, Meshes.CHALK)


## The leap height that brings a bunny standing at `ground` into the middle of the view (0 = none).
func _big_apex(ground: Vector3, n: Vector3) -> float:
	if pacing == null:
		return 0.0
	var lens := pacing.lens_soon(0.6)
	var h := 0.3
	while h <= BUNNY_BIG_MAX - BUNNY_BIG_SPARE + 0.001:
		var body := ground + n * (0.13 + h)
		if pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC):
			return h + BUNNY_BIG_SPARE if pacing.sight_clear(lens.origin, body) else 0.0
		h += 0.15
	return 0.0


func _big_leap(h: Dictionary, apex: float) -> void:
	h["air_h"] = apex
	h["air_t"] = BUNNY_AIR_SEC * sqrt(apex / BUNNY_HOP_H)
	h["from"] = h["dir"]
	h["to"] = h["dir"]
	h["state"] = HopState.CROUCH
	h["timer"] = BUNNY_CROUCH_SEC
	AudioManager.play_sfx_at("jump", safari.planet.surface_point(h["dir"]), -10.0, 0.35)


func _hop_plan(h: Dictionary, away: Vector3, flee: bool) -> void:
	var p := safari.planet
	var d: Vector3 = h["dir"]
	var heading: Vector3 = h["heading"]
	heading -= d * heading.dot(d)
	if flee and away.length() > 0.01:
		heading = away - d * away.dot(d)
	elif rad_to_deg(d.angle_to(h["home"])) > BUNNY_RANGE_DEG:
		heading = _toward(d, h["home"]).rotated(d, _rng.randfn(0.0, 0.4))
	else:
		heading = heading.normalized().rotated(d, _rng.randfn(0.0, 0.8))
	heading = heading.normalized()
	var hop_len := _rng.randf_range(BUNNY_HOP_M.x, BUNNY_HOP_M.y) * (1.3 if flee else 1.0)
	for k in 5:
		var far := (d * cos(0.5) + heading * sin(0.5)).normalized()
		var to := p.step_dir(d, far, hop_len)
		if p.nearest_prop_distance(to) >= 0.45 and rad_to_deg(to.angle_to(_pad_dir)) >= PAD_CLEAR_DEG \
				and p.ground_normal(to).angle_to(to) < deg_to_rad(12.0):
			h["heading"] = heading
			h["from"] = d
			h["to"] = to
			h["state"] = HopState.CROUCH
			h["timer"] = BUNNY_CROUCH_SEC
			return
		heading = heading.rotated(d, PI + _rng.randf_range(-1.0, 1.0)).normalized()
	h["heading"] = heading
	h["timer"] = _rng.randf_range(0.5, 1.2)


func _turn_face(h: Dictionary, want: Vector3, rate: float, delta: float) -> void:
	var d: Vector3 = h["dir"]
	var w := want - d * want.dot(d)
	if w.length() < 0.001:
		return
	var cur: Vector3 = h["face"]
	cur -= d * cur.dot(d)
	if cur.length() < 0.001:
		cur = _tangent_at(d)
	h["face"] = cur.normalized().slerp(w.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _pose_bunny(i: int, h: Dictionary) -> void:
	var grow := float(h["grow"])
	if grow <= 0.01:
		_bun_herd.hide_one(i)
		h.erase("body")
		return
	var base := _xf_ground(h["dir"], h["face"])
	var sq := float(h["sq"])
	var foot := base.translated_local(Vector3(0.0, float(h["h"]), 0.0))
	var body := Transform3D(foot.basis * Basis.from_scale(Vector3(grow / maxf(sqrt(sq), 0.5), grow * sq, grow / maxf(sqrt(sq), 0.5))), foot.origin)
	var lean := 0.0
	if int(h["state"]) == HopState.AIR:
		var f := clampf(1.0 - float(h["timer"]) / float(h.get("air_t", BUNNY_AIR_SEC)), 0.0, 1.0)
		lean = lerpf(0.5, -0.2, f)
	var ears := Transform3D(foot.basis * Basis(Vector3.RIGHT, lean) * Basis.from_scale(Vector3.ONE * grow),
		foot.origin + foot.basis.y * (Meshes.BUNNY_EAR_Y * grow * sq))
	_bun_herd.pose(i, 0, body)
	_bun_herd.pose(i, 1, ears)
	h["body"] = foot


# ---------------------------------------------------------------------------------------- glow worms
## Night only: WORMS chalk-glow worms crawl round the henge, just inside its ring of stones.
func _build_worms() -> void:
	var p := safari.planet
	if _stones.is_empty():
		return
	var rho := INF
	for st: Dictionary in _stones:
		rho = minf(rho, _henge_dir.angle_to(st["dir"]))
	_worm_rho = rho - 0.9 / p.radius
	_worm_ref = _tangent_at(_henge_dir)
	for k in WORMS:
		_worms.append({"psi": 360.0 * float(k) / float(WORMS) + _rng.randf_range(-12.0, 12.0), "phase": _rng.randf_range(0.0, TAU),
			"rear_at": _rng.randf_range(0.0, WORM_REAR_EVERY), "sink": 0.0, "shy": false})
	var rr := p.radius + 1.0
	var area := AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0)
	_worm_body = Herd.new()
	add_child(_worm_body)
	_worm_body.setup("GlowWorms", WORMS * WORM_SEGS, [[Meshes.worm_segment(),
		PlanetPropMeshes.pulse_material(Color("#cfe6c4"), 1.6, 1.4, 0, 0.6, Color("#d8e4d0")), false]], area)
	_worm_heads = Herd.new()
	add_child(_worm_heads)
	_worm_heads.setup("GlowWormHeads", WORMS, [[Meshes.worm_head(), _prop, false]], area)
	_worm_focus = Node3D.new()
	_worm_focus.name = "WormFocus"
	add_child(_worm_focus)
	safari.add_subject({
		"id": "glow_worm", "name": "Chalk-glow Worms", "kind": "creature",
		"band": BAND_WORM, "node": _worm_focus, "offset": Vector3(0.0, 0.12, 0.12), "radius": 0.2,
		"awake": func() -> bool: return _worm_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _worm_pick >= 0 and _worm_rearing(_worms[_worm_pick]) > 0.3:
				return {"mult": 1.6, "line": "rearing up to glow"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_worm_focus),
	})


func _worm_rearing(w: Dictionary) -> float:
	var ph := fmod(_t + float(w["rear_at"]), WORM_REAR_EVERY)
	return sin(ph / WORM_REAR_SEC * PI) if ph < WORM_REAR_SEC else 0.0


func _worm_point(psi: float, wob: float) -> Vector3:
	var d := _polar(_henge_dir, _worm_ref, rad_to_deg(_worm_rho) + wob, psi)
	return d


func _tick_worms(delta: float) -> void:
	if _worm_body == null:
		return
	var p := safari.planet
	var shy := pacing != null and pacing.shy("glow_worm")
	var deg_per_m := rad_to_deg(1.0 / (p.radius * sin(_worm_rho)))
	for k in _worms.size():
		var w: Dictionary = _worms[k]
		if not _sleeping:
			w["psi"] = float(w["psi"]) + WORM_SPEED * deg_per_m * delta
		var head_d := _worm_point(float(w["psi"]), 0.25 * sin(_t * 1.3 + float(w["phase"])))
		var head_pos := p.surface_point(head_d)
		w["head_pos"] = head_pos
		if shy and float(w["sink"]) < 0.01 and not _point_in_frame(head_pos, SHY_FRAME_GROW):
			w["shy"] = true
		if bool(w["shy"]) and not shy:
			w["shy"] = false
		var want := 1.0 if (bool(w["shy"]) or _sleeping) else 0.0
		w["sink"] = move_toward(float(w["sink"]), want, delta / 0.6)
		var sink := float(w["sink"]) * 0.12
		var rear := _worm_rearing(w)
		var prev := head_d
		for s in WORM_SEGS:
			var psi_s := float(w["psi"]) - float(s + 1) * WORM_SEG_M * deg_per_m
			var d := _worm_point(psi_s, 0.25 * sin(_t * 1.3 + float(w["phase"]) - float(s + 1) * 0.6))
			var fwd := p.surface_point(prev) - p.surface_point(d)
			var xf := _xf_ground(d, fwd)
			var sc := 1.0 - 0.1 * float(s)
			if float(w["sink"]) >= 0.99:
				_worm_body.pose(k * WORM_SEGS + s, 0, Herd.ZERO)
			else:
				_worm_body.pose(k * WORM_SEGS + s, 0, Transform3D(xf.basis * Basis.from_scale(Vector3.ONE * sc), xf.origin - xf.basis.y * sink))
			prev = d
		var hfwd := p.surface_point(head_d) - p.surface_point(_worm_point(float(w["psi"]) - WORM_SEG_M * deg_per_m, 0.0))
		var hxf := _xf_ground(head_d, hfwd)
		hxf = hxf.translated_local(Vector3(0.0, 0.1 * rear - sink, 0.0))
		hxf.basis = hxf.basis * Basis(Vector3.RIGHT, 0.5 * rear)
		w["head_xf"] = hxf
		if float(w["sink"]) >= 0.99:
			_worm_heads.hide_one(k)
		else:
			_worm_heads.pose(k, 0, hxf)
	_worm_pick = _pick_focus(_worms, func(w: Dictionary) -> bool: return float(w["sink"]) < 0.3,
		func(w: Dictionary) -> Vector3: return w.get("head_pos", Vector3.ZERO), 0.08)
	if _worm_pick >= 0:
		_worm_focus.global_transform = _worms[_worm_pick]["head_xf"]


# ---------------------------------------------------------------------------------------- Grig
func _build_grig() -> void:
	_grig = safari.world.get_node_or_null("NPCs/grig") as Node3D
	if _grig == null:
		return
	_grig_saved = _grig.global_transform
	_grig_wander_saved = bool(_grig.get("_wander_on")) if _grig.get("_wander_on") != null else true
	safari.add_subject({
		"id": "grig", "name": "Grig", "kind": "neighbour",
		"band": BAND_GRIG, "node": _grig, "offset": Vector3(0.0, 0.8, 0.0), "radius": 0.80,
		# Counting stones he IS the count (that subject scores him, with his front): one subject, not two.
		"awake": func() -> bool: return is_instance_valid(_grig) and _grig.is_visible_in_tree() and not _grig_borrowed,
		"moment": func(_tt: float) -> Dictionary:
			if _t < _grig_pose_until:
				return {"mult": 1.8, "line": "holding very still for you"}
			if _t < _grig_wave_until:
				return {"mult": 1.6, "line": "waving at you"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_grig),
	})


func _build_count() -> void:
	if _grig == null or _count_arcs.is_empty():
		return
	_count_focus = Node3D.new()
	_count_focus.name = "CountFocus"
	add_child(_count_focus)
	_tap_sparks = CPUParticles3D.new()
	_tap_sparks.name = "TapChalk"
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	_tap_sparks.mesh = q
	_tap_sparks.material_override = PlanetPropMeshes.sparkle_material(Color("#e6dcc4"))
	_tap_sparks.amount = 24
	_tap_sparks.lifetime = 0.7
	_tap_sparks.explosiveness = 0.9
	_tap_sparks.one_shot = true
	_tap_sparks.local_coords = true
	_tap_sparks.direction = Vector3(0.0, 0.4, 1.0)
	_tap_sparks.spread = 60.0
	_tap_sparks.initial_velocity_min = 0.6
	_tap_sparks.initial_velocity_max = 1.4
	_tap_sparks.gravity = Vector3(0.0, -1.5, 0.0)
	_tap_sparks.emitting = false
	add_child(_tap_sparks)
	safari.add_subject({
		"id": "grig_count", "name": "Grig Counts the Stones", "kind": "event",
		"band": BAND_COUNT, "node": _count_focus, "radius": 0.8,
		"awake": func() -> bool: return _any_running(COUNT_RUNS) and _grig_borrowed,
		"moment": func(_tt: float) -> Dictionary:
			if _count_state == "say":
				return {"mult": 2.0, "line": "counting out loud"}
			if _count_state == "tap":
				return {"mult": 1.7, "line": "tapping a stone"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_grig),
	})


## Where Grig stands to tap stone `si`: on its inner side, a little to one side, so from the middle of
## the henge he is seen in profile beside it and not hidden behind it.
func _stand_at(si: int, from_side: float) -> Vector3:
	var p := safari.planet
	var st: Dictionary = _stones[si]
	var sd: Vector3 = st["dir"]
	var inward := _toward(sd, _henge_dir)
	var side := inward.cross(sd).normalized() * from_side
	var off := (inward * COUNT_STAND_M + side * 0.45)
	return p.dir_of(p.surface_point(sd) + off)


## The running count's plan, from the run's start: per stone a tap, then Grig turns to you and says its
## number, then walks on to the next. His pace is whatever fits the three stones into the run (the ring's
## spacing differs from arc to arc), between 0.8 and 1.8 m/s.
func _plan_count(run: Dictionary) -> void:
	_count_plan = []
	var arc: Array = _count_arcs[int(run["at"])]
	var p := safari.planet
	var walk_m := 0.0
	for k in range(1, arc.size()):
		walk_m += p.surface_distance(_stand_at(arc[k - 1], -1.0), _stand_at(arc[k], -1.0))
	var t := float(run["start"]) + 0.4
	var walk_sec := float(run["end"]) - t - 0.5 - float(arc.size()) * (COUNT_TAP_SEC + COUNT_SAY_SEC)
	var speed := clampf(walk_m / maxf(walk_sec, 0.1), 0.8, 1.8)
	for k in arc.size():
		var si: int = arc[k]
		var here := _stand_at(si, -1.0)
		if k > 0:
			var prev := _stand_at(arc[k - 1], -1.0)
			var walk := p.surface_distance(prev, here) / speed
			_count_plan.append({"t0": t, "t1": t + walk, "kind": "walk", "from": prev, "to": here, "stone": si})
			t += walk
		_count_plan.append({"t0": t, "t1": t + COUNT_TAP_SEC, "kind": "tap", "from": here, "to": here, "stone": si})
		t += COUNT_TAP_SEC
		_count_plan.append({"t0": t, "t1": t + COUNT_SAY_SEC, "kind": "say", "from": here, "to": here, "stone": si})
		t += COUNT_SAY_SEC
	_log("count plan %s: %d steps, walk %.1f m at %.2f m/s, ends %.1f (run ends %.1f)" % [run["id"], _count_plan.size(),
		walk_m, speed, t, float(run["end"])])


func _tick_grig(delta: float) -> void:
	if _grig == null or not is_instance_valid(_grig) or _sleeping or _building:
		return
	var p := safari.planet
	var run := _run_at(COUNT_RUNS, _t, true)
	if not run.is_empty() and not _count_arcs.is_empty():
		if not _grig_borrowed or _grig_run != str(run["id"]):
			_borrow_grig(run)
		var arc: Array = _count_arcs[int(run["at"])]
		var first := _stand_at(arc[0], -1.0)
		var pos := p.surface_point(first)
		var face := _toward(first, (_stones[arc[0]] as Dictionary)["dir"])
		var state := "wait"
		var stone := int(arc[0])
		var moving := false
		for step: Dictionary in _count_plan:
			if _t >= float(step["t0"]) and _t < float(step["t1"]):
				var f := (_t - float(step["t0"])) / maxf(float(step["t1"]) - float(step["t0"]), 0.01)
				var d := (step["from"] as Vector3).slerp(step["to"], f).normalized()
				pos = p.surface_point(d)
				state = str(step["kind"])
				stone = int(step["stone"])
				if state == "walk":
					face = _toward(d, step["to"])
					moving = true
				elif state == "tap":
					face = _toward(d, (_stones[stone] as Dictionary)["dir"])
				else:
					var lens := safari.player.global_position
					face = _toward(d, p.dir_of(lens))
				break
			elif _t >= float(step["t1"]):
				pos = p.surface_point(step["to"])
				state = "done"
		if state != _count_state or stone != _count_stone:
			_count_changed(state, stone)
		_count_state = state
		_count_stone = stone
		var up := p.up_at(pos)
		var cur := -_grig.global_basis.z
		cur -= up * cur.dot(up)
		var fw := cur.normalized().slerp(face, clampf(8.0 * delta, 0.0, 1.0)) if cur.length() > 0.01 else face
		_grig.global_transform = Transform3D(Basis.looking_at(fw.normalized(), up), pos + up * 0.06)
		_grig.set("_speed_factor", 1.0 if moving else 0.0)
		var sp := (_stones[stone] as Dictionary)
		var stone_mid: Vector3 = (sp["pos"] as Vector3) + (sp["up"] as Vector3) * 1.0
		_count_focus.global_position = pos.lerp(stone_mid, 0.3) + up * 0.75
		_count_focus.global_basis = _grig.global_basis
		return
	if _grig_borrowed:
		_release_grig(false)
		_grig.call("play_emote", "happy")
		_grig_pose_until = _t + 1.6
	_count_state = ""
	if _grig_hold_until > 0.0 and _t >= _grig_hold_until:
		_end_grig_hold()
	# ---- brought by the director: he stands GRIG_STAY_SEC, then wanders on
	if _grig_stay_until > -INF and _t >= _grig_stay_until and _grig_hold_until <= 0.0:
		_grig_stay_until = -INF
		if _grig.has_method("wander_enabled"):
			_grig.call("wander_enabled", _grig_wander_saved)
	# waves when you come close; holds still for the photo when you point the camera at him nearby
	var pl := safari.player
	var dist := _grig.global_position.distance_to(pl.global_position)
	if dist < 3.6 and _t >= _grig_next_wave:
		_grig.call("face_player", true)
		_grig.call("play_emote", "wave")
		_grig_wave_until = _t + 1.6
		_grig_next_wave = _t + 7.0
	if safari.camera_up and dist < 7.0 and _t >= _grig_next_pose:
		var cam := safari.rig.get_view_camera()
		if cam != null:
			var to := (_grig.global_position + p.up_at(_grig.global_position) * 0.8 - cam.global_position).normalized()
			if to.dot(-cam.global_transform.basis.z) > cos(deg_to_rad(10.0)):
				_grig.call("face_player", true)
				_grig.call("play_emote", "happy")
				if _grig.has_method("wander_enabled"):
					_grig.call("wander_enabled", false)
				if _grig.has_method("hold_facing"):
					_grig.call("hold_facing", pl.global_position)
				_grig_pose_until = _t + GRIG_HOLD_SEC
				_grig_hold_until = _t + GRIG_HOLD_SEC
				_grig_next_pose = _t + GRIG_HOLD_SEC + 4.0
				_grig_next_wave = maxf(_grig_next_wave, _t + 3.0)


## A count step began: the tap's knock and chalk, Grig's number.
func _count_changed(state: String, stone: int) -> void:
	var sp: Dictionary = _stones[stone]
	var at: Vector3 = (sp["pos"] as Vector3) + (sp["up"] as Vector3) * 1.1
	if state == "tap":
		_grig.call("play_emote", "wave")
		AudioManager.play_sfx_at("footstep_stone_%d" % (stone % 2), at, 2.0, 0.05)
		AudioManager.play_sfx_at("place", at, -6.0, 0.1)
		_tap_sparks.global_transform = Transform3D(Basis.looking_at(_toward(safari.planet.dir_of(at), _henge_dir), sp["up"]), at)
		_tap_sparks.restart()
		_tap_sparks.emitting = true
	elif state == "say":
		# his number: the stone's own, in ring order from the one nearest the start
		AudioManager.play_sfx_at("doot_c_%d" % (stone % 4), _grig.global_position, 0.0, 0.05)
		_sound_once("doot_c_%d" % ((stone + 1) % 4), 0.85, -12.0).play()
	elif state == "done":
		_grig.call("play_emote", "happy")


func _borrow_grig(run: Dictionary) -> void:
	var first := not _grig_borrowed
	_grig_borrowed = true
	_grig_run = str(run["id"])
	_plan_count(run)
	var from := _grig.global_position
	var arc: Array = _count_arcs[int(run["at"])]
	var start := safari.planet.surface_point(_stand_at(arc[0], -1.0))
	_queue_line("Grig: \"Stone count. Again. Stand still.\"  (%s)" % ("the HENGE, near the pad" if int(run["at"]) == 0 else "the HENGE, far side"))
	for k in 3:
		AudioManager.play_sfx_at("doot_c_%d" % k, from, 0.0, 0.1)
	_sound_once("doot_c_3", 0.8, -6.0).play()
	safari.puff_at(from, 22, Meshes.CHALK)
	if first:
		if _grig.has_method("wander_enabled"):
			_grig.call("wander_enabled", false)
		_grig.set_physics_process(false)
	_grig.global_position = start
	safari.puff_at(start, 22, Meshes.CHALK)
	AudioManager.play_sfx_at("footstep_stone_0", start, 0.0, 0.1)


## His photo hold is over: his walk and his own facing are given back.
func _end_grig_hold() -> void:
	_grig_hold_until = -1.0
	if _grig == null or not is_instance_valid(_grig):
		return
	if _grig.has_method("release_facing"):
		_grig.call("release_facing")
	if not _grig_borrowed and _grig_stay_until <= -INF and _grig.has_method("wander_enabled"):
		_grig.call("wander_enabled", _grig_wander_saved)


## Gives Grig back to his own script. `home` also puts him back where he stood before the safari.
func _release_grig(home: bool) -> void:
	if _grig == null or not is_instance_valid(_grig):
		return
	_grig_stay_until = -INF
	if _grig_hold_until > 0.0:
		_end_grig_hold()
	elif not _grig_borrowed and _grig.has_method("wander_enabled"):
		_grig.call("wander_enabled", _grig_wander_saved)
	if _grig_borrowed:
		_grig.set("_speed_factor", 0.0)
		_grig.set_physics_process(true)
		if _grig.has_method("wander_enabled"):
			_grig.call("wander_enabled", _grig_wander_saved)
	_grig_borrowed = false
	_grig_run = ""
	if home:
		_grig.global_transform = _grig_saved
		if _grig is CharacterBody3D:
			(_grig as CharacterBody3D).velocity = Vector3.ZERO


## THE PACING DIRECTOR brings GRIG (V6GRIG, 2026-09-27; Bolt's, Fen's and Zorp's way - bolt.gd _bring_bolt,
## whose numbers are Fen's, not tuned here). WHY (measured, 3 wanderer runs a planet, seeds 1-3, phone frame):
## Grig was on screen 0.8 s a run against Bolt 6.8 s and Fen 8.6 s - his steps are 16 m from the pad, over the
## horizon of this 9.5 m world, so the one big bright figure here was almost never seen; the screen went to
## a shelf-owl sitting still (12.9 s a run, 43% of all the seconds anything was on screen). Now, when it has
## gone quiet, Grig comes over with a puff of chalk to count what you are photographing, stands GRIG_STAY_SEC
## (he holds still for a camera pointed at him, _tick_grig), then wanders on. Not while a stone count has
## him or will within his stay, not when he is near you or in view already, not twice within GRIG_COME_REST s.
const GRIG_COME_REST := 25.0
const GRIG_RISE_MAX := 1.7
const GRIG_STAY_SEC := 10.0
## A spot this clear of any prop (a monolith, a shelf, a lamp), so he never stands in a stone.
const GRIG_CLEAR_M := 0.9
const GRIG_COME_LINES := ["Grig: \"You are counting too? Good.\"", "Grig: \"Checking your count. Carry on.\"",
	"Grig: \"One photographer. Counted.\""]


func _grig_can_come() -> bool:
	if _grig == null or not is_instance_valid(_grig) or _sleeping or _grig_borrowed:
		return false
	if _t - _grig_came_at < GRIG_COME_REST:
		return false
	# a count borrows him from its warning: his whole stay must end before that
	for run: Dictionary in COUNT_RUNS:
		var s0 := float(run["start"]) - WARN
		if bool(_eligible.get(str(run["id"]), false)) and _t < float(run["end"]) and _t + GRIG_STAY_SEC + 1.0 > s0:
			return false
	var head := _grig.global_position + safari.planet.up_at(_grig.global_position) * 0.8
	return _grig.global_position.distance_to(safari.player.global_position) > 8.0 and not pacing.point_in_frame(head, 1.1)


func _bring_grig(spot: Dictionary) -> bool:
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO and spot["ahead"] != Vector3.ZERO and float(spot["rise"]) >= 0.0 and float(spot["rise"]) <= GRIG_RISE_MAX:
		d = spot["ahead"]
	if d == Vector3.ZERO or not _grig_can_come():
		return false
	var p := safari.planet
	if p.nearest_prop_distance(d) < GRIG_CLEAR_M or rad_to_deg(d.angle_to(_pad_dir)) < PAD_CLEAR_DEG:
		return false
	safari.puff_at(_grig.global_position, 14, Meshes.CHALK)
	var g := p.surface_point(d)
	var up := p.up_at(g)
	var lens: Transform3D = spot["lens"]
	var face := -lens.basis.z
	face -= up * face.dot(up)
	if face.length() < 0.01:
		face = _tangent_at(d)
	face = face.normalized().rotated(up, _rng.randf_range(-0.5, 0.5))
	_grig.global_transform = Transform3D(Basis.looking_at(face, up), g)
	if _grig is CharacterBody3D:
		(_grig as CharacterBody3D).velocity = Vector3.ZERO
	if _grig.has_method("wander_enabled"):
		_grig.call("wander_enabled", false)
	safari.puff_at(g, 18, Meshes.CHALK)
	# an arrival is an entrance, not a moment (THE OVERLAPS): the wave is not the scored "waving at you"
	_grig.call("play_emote", "wave")
	_grig_next_wave = _t + 8.0
	AudioManager.play_sfx_at("doot_c_%d" % (_grig_came_n % 4), g, 0.0, 0.1)
	_queue_line(GRIG_COME_LINES[_grig_came_n % GRIG_COME_LINES.size()])
	_grig_came_n += 1
	_grig_came_at = _t
	_grig_stay_until = _t + GRIG_STAY_SEC
	_log("Grig comes over to %s t=%.1f" % [_pp(d), _t])
	return true


# ---------------------------------------------------------------------------------------- chalk drift
## A gust lifts the chalk out of the treads into a swirling column: every emitter works in its own frame
## (local coords, the root's +Y the planet's up there), and a tangential pull round that axis with a
## gentle inward one winds the chalk into spiral ribbons as it rises. A second, taller swirl joins while
## it is at its TALLEST (DRIFT_TALL, the moment). (CPUParticles3D has no amount_ratio in 4.7 - Bolt's
## rain note - so "thicker" is a second emitter.)
func _build_drift() -> void:
	_drift_root = Node3D.new()
	_drift_root.name = "ChalkDrift"
	add_child(_drift_root)
	_drift_arms.append(_chalk_swirl("Swirl", 200, 2.8, 0.06, 0.8, Vector2(3.0, 4.0), 0.9))
	_drift_thick.append(_chalk_swirl("SwirlTall", 200, 3.4, 0.07, 1.3, Vector2(4.2, 5.2), 0.7))
	for e in [_drift_arms[0], _drift_thick[0]]:
		_drift_root.add_child(e)
	_drift_skitter = _chalk_swirl("Skitter", 26, 0.9, 0.05, 0.1, Vector2(1.0, 2.0), 1.4)
	_drift_skitter.direction = Vector3(1.0, 0.3, 0.0)
	_drift_skitter.spread = 180.0
	_drift_root.add_child(_drift_skitter)
	_drift_focus = Node3D.new()
	_drift_focus.name = "DriftFocus"
	_drift_root.add_child(_drift_focus)
	_drift_focus.position = Vector3(0.0, 1.2, 0.0)
	_move_drift(0)
	safari.add_subject({
		"id": "chalk_drift", "name": "Chalk Drift", "kind": "event",
		"band": BAND_DRIFT, "node": _drift_focus, "radius": 1.4,
		"awake": func() -> bool: return _any_running(DRIFT_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(DRIFT_RUNS, tt, false)
			if not run.is_empty():
				var k0 := tt - float(run["start"])
				if k0 >= DRIFT_TALL.x and k0 < DRIFT_TALL.y:
					return {"mult": 2.0, "line": "the ribbons at their tallest"}
			return {"mult": 1.0, "line": ""},
	})


func _chalk_swirl(label: String, amount: int, life: float, size: float, lift: float, swirl: Vector2, ring_r: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = label
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 10
	m.rings = 5
	m.material = PlanetPropMeshes.puff_material(Color.WHITE)
	p.mesh = m
	p.amount = amount
	p.lifetime = life
	p.local_coords = true
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = ring_r
	p.emission_ring_inner_radius = ring_r * 0.35
	p.emission_ring_height = 0.15
	p.direction = Vector3.UP
	p.spread = 20.0
	p.initial_velocity_min = 0.15
	p.initial_velocity_max = 0.45
	# the gravity is UP (its own frame): the chalk rises, and the tangential pull turns round it
	p.gravity = Vector3(0.0, lift, 0.0)
	p.tangential_accel_min = swirl.x
	p.tangential_accel_max = swirl.y
	# pulled in about as hard as the swirl flings out (v^2 / r at about 1 m/s on a 0.8 m ring)
	p.radial_accel_min = -1.6
	p.radial_accel_max = -1.1
	p.damping_min = 0.2
	p.damping_max = 0.5
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.5
	var c := Color("#dcd5c4")
	var ramp := Gradient.new()
	ramp.set_color(0, Color(c, 0.0))
	ramp.add_point(0.15, Color(c, 0.7))
	ramp.set_color(ramp.get_point_count() - 1, Color(c, 0.0))
	p.color_ramp = ramp
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.6))
	grow.add_point(Vector2(1.0, 1.2))
	p.scale_amount_curve = grow
	p.emitting = false
	return p


func _move_drift(at: int) -> void:
	if at == _drift_at:
		return
	_drift_at = at
	var d: Vector3 = _drift_dirs[at]
	_drift_root.global_transform = _xf(d, _tangent_at(d))


func _tick_drift(delta: float) -> void:
	if _drift_root == null:
		return
	var run := _run_at(DRIFT_RUNS, _t, true)
	var on := not run.is_empty() and not _sleeping
	if on:
		# a new run moves the whole column to its spot (runs are 30 s and more apart: nothing is alive)
		_move_drift(int(run["at"]))
	var k0 := _t - float(run["start"]) if on else -99.0
	var warn := on and k0 < 0.0
	var going := on and k0 >= 0.0
	var dur := float(run["end"]) - float(run["start"]) if on else 0.0
	_drift_skitter.emitting = warn or (going and k0 < 3.0)
	_drift_arms[0].emitting = going and k0 < dur - 2.0
	_drift_thick[0].emitting = going and k0 >= DRIFT_TALL.x - 1.5 and k0 < DRIFT_TALL.y - 0.5
	if on and not _sleeping:
		_gust_clock -= delta
		if _gust_clock <= 0.0:
			_gust_clock = 2.6 if warn else 3.4
			var near := rad_to_deg(_player_dir().angle_to(_drift_dirs[int(run["at"])]))
			_sound_once("tree_shake", 0.55, lerpf(-6.0, -18.0, clampf(near / 150.0, 0.0, 1.0))).play()


# ---------------------------------------------------------------------------------------- henge hum
func _build_hum() -> void:
	var n_st := _stones.size()
	if n_st == 0:
		return
	# (0) the stone farthest from the stack's place (paired with it), then two more spread round the ring
	var stack_d := safari.dir_from_start(STACK_AT.x, STACK_AT.y)
	var far_i := 0
	var best := -1.0
	for i in n_st:
		var a := stack_d.angle_to(_stones[i]["dir"])
		if a > best:
			best = a
			far_i = i
	_hum_stones = [far_i, (far_i + 3) % n_st, (far_i + 6) % n_st]
	# (2) near the start is seen early: make run 2 (at index 1) the one of the other two nearer the start
	if safari.start_dir.angle_to(_stones[_hum_stones[2]]["dir"]) < safari.start_dir.angle_to(_stones[_hum_stones[1]]["dir"]):
		_hum_stones = [far_i, _hum_stones[2], _hum_stones[1]]
	_hum_mat = PlanetPropMeshes.pulse_material(Color("#e9d8ab"), 0.0, 0.0, 0, 1.0, Color("#d8cfb9")).duplicate() as ShaderMaterial
	for si in _hum_stones:
		var st: Dictionary = _stones[si]
		var v := int(st["variant"])
		var h := float(st["h"])
		var r0 := 0.40 + 0.03 * float(v % 3)
		var r_top := r0 * 0.74
		var r_at := func(y: float) -> float: return lerpf(r0 * 0.94, r_top, clampf((y - h * 0.26) / (h * 0.64), 0.0, 1.0))
		var y_lo := h * 0.40
		var y_hi := h * 0.78
		var col := MeshInstance3D.new()
		col.name = "HumCollar%d" % si
		col.mesh = Meshes.hum_collar(r_at.call(y_lo), y_lo, r_at.call(y_hi), y_hi)
		col.material_override = _hum_mat
		col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(col)
		var mi: MeshInstance3D = st["mesh"]
		col.global_transform = mi.global_transform if mi != null else (st["node"] as Node3D).global_transform
		col.visible = false
		_hum_collars.append(col)
	_hum_ring_mat = PlanetPropMeshes.pulse_material(Color("#e9d8ab"), 0.0, 0.0, 0, 1.0, Color("#d8cfb9")).duplicate() as ShaderMaterial
	_hum_ring = MeshInstance3D.new()
	_hum_ring.name = "HumRipple"
	_hum_ring.mesh = Meshes.ground_ring()
	_hum_ring.material_override = _hum_ring_mat
	_hum_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hum_ring)
	_hum_ring.visible = false
	_hum_dust = CPUParticles3D.new()
	_hum_dust.name = "HumDust"
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	_hum_dust.mesh = q
	_hum_dust.material_override = PlanetPropMeshes.sparkle_material(Color("#eadfc4"))
	_hum_dust.amount = 40
	_hum_dust.lifetime = 2.2
	_hum_dust.local_coords = true
	_hum_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_hum_dust.emission_ring_axis = Vector3.UP
	_hum_dust.emission_ring_radius = 0.9
	_hum_dust.emission_ring_inner_radius = 0.6
	_hum_dust.emission_ring_height = 0.1
	_hum_dust.direction = Vector3.UP
	_hum_dust.spread = 10.0
	_hum_dust.initial_velocity_min = 0.4
	_hum_dust.initial_velocity_max = 0.9
	_hum_dust.gravity = Vector3(0.0, 0.2, 0.0)
	_hum_dust.emitting = false
	add_child(_hum_dust)
	_hum_focus = Node3D.new()
	_hum_focus.name = "HumFocus"
	add_child(_hum_focus)
	# the stone's own glow: a soft warm halo round its middle (the shipped star shader, additive)
	_hum_glow = MeshInstance3D.new()
	_hum_glow.name = "HumGlow"
	var gq := QuadMesh.new()
	gq.size = Vector2(2.2, 3.4)
	_hum_glow.mesh = gq
	_hum_glow_mat = MaterialLib.glow_sprite(Color("#e8cf98"), 1.1, {"softness": 0.0, "core": 0.0}).duplicate() as ShaderMaterial
	_hum_glow.material_override = _hum_glow_mat
	_hum_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_hum_glow)
	_hum_glow.visible = false
	_hum_sound = _sound("comms_bed", 0.32, -40.0, true)
	_move_hum(0)
	safari.add_subject({
		"id": "henge_hum", "name": "Henge Hum", "kind": "event",
		"band": BAND_HUM, "node": _hum_focus, "radius": 1.4,
		"awake": func() -> bool: return _any_running(HUM_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(HUM_RUNS, tt, false)
			if not run.is_empty():
				var k0 := tt - float(run["start"])
				if k0 >= HUM_FULL.x and k0 < HUM_FULL.y and _inside_henge():
					return {"mult": 2.0, "line": "humming at full glow"}
			return {"mult": 1.0, "line": ""},
	})


func _move_hum(at: int) -> void:
	if at == _hum_at or at >= _hum_stones.size():
		return
	_hum_at = at
	var st: Dictionary = _stones[_hum_stones[at]]
	var up: Vector3 = st["up"]
	var base: Vector3 = st["pos"]
	var xf := Transform3D(Basis.looking_at(_tangent_at(safari.planet.dir_of(base)), up), base)
	_hum_ring.global_transform = xf
	_hum_dust.global_transform = xf
	_hum_focus.global_position = base + up * (float(st["h"]) * 0.5)
	_hum_glow.global_position = base + up * (float(st["h"]) * 0.55)
	for k in _hum_collars.size():
		_hum_collars[k].visible = false


func _tick_hum(delta: float) -> void:
	if _hum_collars.is_empty():
		return
	var run := _run_at(HUM_RUNS, _t, true)
	var on := not run.is_empty() and not _sleeping
	var glow := 0.0
	var k0 := -99.0
	if on:
		_move_hum(int(run["at"]))
		k0 = _t - float(run["start"])
		var dur := float(run["end"]) - float(run["start"])
		if k0 < 0.0:
			# the warning: a faint flicker that grows
			glow = (0.08 + 0.12 * (1.0 + k0 / WARN)) * (0.6 + 0.4 * sin(_t * 11.0))
		elif k0 < HUM_FULL.x:
			glow = lerpf(0.25, 1.0, k0 / HUM_FULL.x)
		elif k0 < HUM_FULL.y:
			glow = 1.0 + 0.12 * sin(_t * 8.0)
		else:
			glow = clampf((dur - k0) / (dur - HUM_FULL.y), 0.0, 1.0)
	var col := _hum_collars[_hum_at] if _hum_at >= 0 else null
	if col != null:
		col.visible = glow > 0.01
	_hum_mat.set_shader_parameter("emission_strength", 2.6 * glow)
	_hum_glow.visible = glow > 0.02
	_hum_glow_mat.set_shader_parameter("fade", clampf(glow, 0.0, 1.0) * 0.55)
	var full := on and k0 >= HUM_FULL.x and k0 < HUM_FULL.y
	_hum_ring.visible = on and k0 >= 0.0 and glow > 0.2
	if _hum_ring.visible:
		var rp := fmod(maxf(k0, 0.0), 1.1) / 1.1
		var st: Dictionary = _stones[_hum_stones[_hum_at]]
		# (kept within 1.7 m: on a 9.5 m world a flat ring any wider floats off the curving ground)
		_hum_ring.global_transform = Transform3D(_hum_ring.global_basis.orthonormalized() * Basis.from_scale(Vector3.ONE * (0.6 + 1.1 * rp)),
			(st["pos"] as Vector3) + (st["up"] as Vector3) * 0.02)
		_hum_ring_mat.set_shader_parameter("emission_strength", 2.0 * glow * (1.0 - rp))
	_hum_dust.emitting = on and k0 >= 0.0 and glow > 0.3
	if on:
		var near := rad_to_deg(_player_dir().angle_to(_stones[_hum_stones[_hum_at]]["dir"]))
		var vol := lerpf(-8.0, -22.0, clampf(near / 150.0, 0.0, 1.0)) + (6.0 * (glow - 1.0))
		_hum_sound.volume_db = vol
		_hum_sound.pitch_scale = 0.3 + 0.04 * glow
		if not _hum_sound.playing:
			_hum_sound.play()
	elif _hum_sound.playing:
		_hum_sound.stop()
	if full and fmod(k0, 1.1) < delta and _hum_ring.visible:
		AudioManager.play_sfx_at("ui_tick", _hum_focus.global_position, -10.0, 0.05)


# ---------------------------------------------------------------------------------------- the moon
## MOONRISE IN THE HENGE: a big chalk moon rises out of the horizon in the gap between two neighbouring
## monoliths (the gap facing most away from the start), as seen from the landing point in the middle of
## the henge. It is a world object MOON_D metres from that eye, sized to fill about half the gap.
func _build_moon() -> void:
	if _moon_gap.x < 0:
		return
	var p := safari.planet
	var c := p.surface_point(_henge_dir)
	_moon_up = p.up_at(c)
	_moon_eye = c + _moon_up * AstronautModel.HELMET_CY
	# the gap's width as seen from the eye
	var a: Dictionary = _stones[_moon_gap.x]
	var b: Dictionary = _stones[_moon_gap.y]
	var mid_a := (a["pos"] as Vector3) + (a["up"] as Vector3) * float(a["h"]) * 0.5
	var mid_b := (b["pos"] as Vector3) + (b["up"] as Vector3) * float(b["h"]) * 0.5
	var gap_deg := rad_to_deg((mid_a - _moon_eye).angle_to(mid_b - _moon_eye))
	var diam_deg := clampf(gap_deg * 0.5, 10.0, 14.0)
	_moon_d = 45.0
	_moon_r = _moon_d * tan(deg_to_rad(diam_deg * 0.5))
	# The planet's limb from the eye, and the stones' tops: it rises to sit just clear of the limb, in
	# the gap, its bottom a degree above the ground line beyond.
	var limb := -acos(p.radius / (p.radius + AstronautModel.HELMET_CY))
	var a_m := asin(_moon_r / _moon_d)
	# up to the middle of the gap between the limb and the lower of the two stones' tops, so it is in
	# the gap and as high as it can be there (seen over more of the planet)
	var top_lo := minf(_elev_of((a["pos"] as Vector3) + (a["up"] as Vector3) * float(a["h"])),
		_elev_of((b["pos"] as Vector3) + (b["up"] as Vector3) * float(b["h"])))
	var el_lo := limb + a_m + deg_to_rad(1.0)
	var el_hi := top_lo - a_m - deg_to_rad(1.0)
	_moon_el_up = (el_lo + el_hi) * 0.5 if el_hi > el_lo else el_lo
	_moon_el_hide = limb - a_m - deg_to_rad(1.0)
	_moon = MeshInstance3D.new()
	_moon.name = "BigMoon"
	_moon.mesh = Meshes.moon()
	_moon.material_override = _rock
	_moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_moon.extra_cull_margin = 2.0
	add_child(_moon)
	_moon.visible = false
	_moon_halo = MeshInstance3D.new()
	_moon_halo.name = "MoonHalo"
	var q := QuadMesh.new()
	q.size = Vector2.ONE * (_moon_r * 3.4)
	_moon_halo.mesh = q
	_moon_halo_mat = MaterialLib.glow_sprite(Color("#d9d0b8"), 0.9, {"softness": 0.0, "core": 0.0}).duplicate() as ShaderMaterial
	_moon_halo.material_override = _moon_halo_mat
	_moon_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_moon_halo)
	_moon_halo.visible = false
	_place_moon(_moon_el_hide)
	var top_a := rad_to_deg(_elev_of((a["pos"] as Vector3) + (a["up"] as Vector3) * float(a["h"])))
	var top_b := rad_to_deg(_elev_of((b["pos"] as Vector3) + (b["up"] as Vector3) * float(b["h"])))
	_log("moon: gap %d-%d %.1f deg wide, moon %.1f deg (r %.2f m at %.0f m), limb %.1f, rises to %.1f; stone tops %.1f / %.1f deg" % [
		_moon_gap.x, _moon_gap.y, gap_deg, diam_deg, _moon_r, _moon_d, rad_to_deg(limb), rad_to_deg(_moon_el_up), top_a, top_b])
	safari.add_subject({
		"id": "moonrise", "name": "Moonrise in the Henge", "kind": "event",
		"band": BAND_MOON, "node": _moon, "radius": _moon_r,
		"awake": func() -> bool:
			var k0 := _t - MOON_START
			return safari.event_running("moonrise") and _moon.visible and k0 >= MOON_UP.x and k0 < MOON_UP.y,
		"moment": func(tt: float) -> Dictionary:
			var k0 := tt - MOON_START
			if k0 >= MOON_FRAMED.x and k0 < MOON_FRAMED.y and _moon_framed():
				return {"mult": 2.2, "line": "framed between two stones"}
			if k0 >= 0.0 and k0 < MOON_RISE_SEC:
				return {"mult": 1.4, "line": "rising"}
			return {"mult": 1.0, "line": ""},
	})


## True when the lens is inside the ring of stones (nearer the landing point than the nearest stone,
## less a metre): the hum's best is seen from inside the henge, with the ring round it.
func _inside_henge() -> bool:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if cam == null or _stones.is_empty():
		return false
	var p := safari.planet
	var near := INF
	for st: Dictionary in _stones:
		near = minf(near, p.surface_distance(_henge_dir, st["dir"]))
	return p.surface_distance(_henge_dir, p.dir_of(cam.global_position)) <= near - 1.0


## Elevation of `q` above the eye's level, seen from the henge's eye (radians).
func _elev_of(q: Vector3) -> float:
	var v := (q - _moon_eye).normalized()
	return asin(clampf(v.dot(_moon_up), -1.0, 1.0))


func _place_moon(el: float) -> void:
	var dir := (_moon_g * cos(el) + _moon_up * sin(el)).normalized()
	var pos := _moon_eye + dir * _moon_d
	_moon.global_transform = Transform3D(Basis.looking_at(-dir, _moon_up) * Basis.from_scale(Vector3.ONE * _moon_r), pos)
	_moon_halo.global_position = _moon_eye + dir * (_moon_d + _moon_r * 1.2)


## True when a photo now would show the moon FRAMED: the lens within MOON_FRAME_M of the henge's eye, and
## the moon's centre between the two gap stones on screen.
func _moon_framed() -> bool:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if cam == null or _moon == null:
		return false
	if cam.global_position.distance_to(_moon_eye) > MOON_FRAME_M:
		return false
	var a: Dictionary = _stones[_moon_gap.x]
	var b: Dictionary = _stones[_moon_gap.y]
	var qa := (a["pos"] as Vector3) + (a["up"] as Vector3) * float(a["h"]) * 0.5
	var qb := (b["pos"] as Vector3) + (b["up"] as Vector3) * float(b["h"]) * 0.5
	var mp := _moon.global_position
	if cam.is_position_behind(qa) or cam.is_position_behind(qb) or cam.is_position_behind(mp):
		return false
	var xa := cam.unproject_position(qa).x
	var xb := cam.unproject_position(qb).x
	var xm := cam.unproject_position(mp).x
	return xm > minf(xa, xb) and xm < maxf(xa, xb)


func _tick_moon(_delta: float) -> void:
	if _moon == null:
		return
	var k0 := _t - MOON_START
	var dur := MOON_END - MOON_START
	var on := bool(_eligible.get("moonrise", false)) and k0 >= -WARN and k0 < dur and not _sleeping
	if not on:
		_moon.visible = false
		_moon_halo.visible = false
		return
	var el := _moon_el_hide
	var gone := k0 >= MOON_UP.y + MOON_SET_SEC
	if k0 >= 0.0:
		var up_f := clampf(k0 / MOON_RISE_SEC, 0.0, 1.0)
		var down_f := clampf((k0 - MOON_UP.y) / MOON_SET_SEC, 0.0, 1.0)
		var f := (1.0 - (1.0 - up_f) * (1.0 - up_f)) * (1.0 - down_f * down_f)
		el = lerpf(_moon_el_hide, _moon_el_up, f)
	_place_moon(el)
	_moon.visible = k0 >= 0.0 and not gone
	# the warning: moonlight gathers on the horizon in the gap before the moon shows; it fades after
	_moon_halo.visible = true
	var halo := clampf((k0 + WARN) / WARN, 0.0, 1.0) * clampf(1.0 - (k0 - MOON_UP.y) / (dur - MOON_UP.y), 0.0, 1.0)
	if k0 < 0.0:
		# before it rises the halo sits on the limb in the gap
		_moon_halo.global_position = _moon_eye + (_moon_g * cos(_moon_el_hide + asin(_moon_r / _moon_d)) + _moon_up * sin(_moon_el_hide + asin(_moon_r / _moon_d))).normalized() * (_moon_d + _moon_r * 1.2)
	_moon_halo_mat.set_shader_parameter("fade", halo * (0.8 + 0.2 * sin(_t * 1.7)))
	if k0 < MOON_FRAMED.y and _t >= _moon_chime_next:
		_moon_chime_next = _t + 4.0
		_sound_once("skiff_reveal", 0.45, -8.0).play()


# ---------------------------------------------------------------------------------------- the great stack
func _build_stack() -> void:
	var p := safari.planet
	_stack_dir = _free_near(safari.dir_from_start(STACK_AT.x, STACK_AT.y), 1.4)
	for k in 9:
		var ang := TAU * float(k) / 9.0 + _rng.randf_range(-0.2, 0.2)
		var from := _polar(_stack_dir, _tangent_at(_stack_dir), rad_to_deg(_rng.randf_range(5.0, 7.0) / p.radius), rad_to_deg(ang))
		var base := _polar(_stack_dir, _tangent_at(_stack_dir), rad_to_deg(0.55 / p.radius), rad_to_deg(ang))
		_stack.append({"from": from, "base": base, "dir": from, "h": 0.0, "roll": 0.0, "order": k})
	var rr := p.radius + 3.5
	_stack_herd = Herd.new()
	add_child(_stack_herd)
	_stack_herd.setup("GreatStack", 9, [[Meshes.bug_ball(), _rock, true]], AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_stack_focus = Node3D.new()
	_stack_focus.name = "StackFocus"
	add_child(_stack_focus)
	safari.add_subject({
		"id": "great_stack", "name": "The Great Stack", "kind": "event",
		"band": BAND_STACK, "node": _stack_focus, "radius": 1.2,
		"awake": func() -> bool:
			var k0 := _t - STACK_START
			return safari.event_running("great_stack") and k0 >= STACK_UP.x and k0 < STACK_UP.y,
		"moment": func(tt: float) -> Dictionary:
			var k0 := tt - STACK_START
			if k0 >= STACK_FULL.x and k0 < STACK_FULL.y:
				return {"mult": 2.2, "line": "all nine stacked"}
			if k0 >= STACK_CLIMB_AT and k0 < STACK_FULL.x:
				return {"mult": 1.3, "line": "stacking up"}
			return {"mult": 1.0, "line": ""},
	})


func _stack_on(tt: float) -> bool:
	return _stack_herd != null and bool(_eligible.get("great_stack", false)) and tt >= STACK_START - WARN and tt < STACK_END


## The stack's timeline, from STACK_START: the pebbles roll in from 6 m round over the warning's last 4 s
## and the first 2 s, climb on one by one (every 0.9 s from 2 s), stand ALL NINE from 10 s (STACK_FULL),
## wobble more and more, and tumble off at 15 s, rolling away to hide by the end.
func _tick_stack(delta: float) -> void:
	if _stack_herd == null:
		return
	var p := safari.planet
	var k0 := _t - STACK_START
	var on := _stack_on(_t) and not _sleeping and k0 >= -4.0
	if not on:
		for i in 9:
			_stack_herd.hide_one(i)
		return
	var up := p.up_at(p.surface_point(_stack_dir))
	var ground := p.surface_point(_stack_dir)
	var ball_h := Meshes.BUG_BALL_R * 1.75
	var n_up := 0
	var wob := 0.0
	if k0 >= STACK_CLIMB_AT:
		n_up = clampi(int(floor((k0 - STACK_CLIMB_AT) / STACK_CLIMB_EVERY)) + 1, 0, 9)
		wob = 0.02 + 0.05 * clampf((k0 - STACK_FULL.x) / (STACK_TUMBLE_AT - STACK_FULL.x), 0.0, 1.0)
	var tumble := k0 >= STACK_TUMBLE_AT
	for i in 9:
		var s: Dictionary = _stack[i]
		var pos := Vector3.ZERO
		var basis := Basis.IDENTITY
		if tumble:
			var f := clampf((k0 - STACK_TUMBLE_AT) / 3.0, 0.0, 1.0)
			var out := _polar(_stack_dir, _tangent_at(_stack_dir), rad_to_deg((0.4 + 3.0 * f) / p.radius), 40.0 * float(i))
			var gpt := p.surface_point(out)
			var hh := float(i) * ball_h * maxf(1.0 - f * 2.5, 0.0)
			pos = gpt + p.up_at(gpt) * hh
			basis = _xf_ground(out, _toward(out, _stack_dir)).basis * Basis(Vector3.RIGHT, -f * 14.0)
			if f >= 1.0 or (f > 0.6 and not _point_in_frame(gpt, 1.05)):
				_stack_herd.hide_one(i)
				continue
		elif i < n_up:
			# on the tower: level i, leaning with the wobble
			var sway := sin(_t * 3.1) * wob * float(i)
			var side := _tangent_at(_stack_dir)
			pos = ground + up * (float(i) * ball_h) + side * sway
			var t_on := STACK_CLIMB_AT + STACK_CLIMB_EVERY * float(i)
			var hop := clampf((k0 - t_on) / 0.35, 0.0, 1.0)
			if hop < 1.0:
				pos += up * (0.25 * sin(hop * PI)) + (p.surface_point(s["base"]) - ground) * (1.0 - hop)
			basis = Transform3D(Basis.looking_at(side.cross(up).normalized(), up), pos).basis * Basis(Vector3.FORWARD, sway * 0.8)
		else:
			# rolling in to its place round the base
			var f := clampf((k0 + 4.0) / (4.0 + STACK_CLIMB_AT), 0.0, 1.0)
			var d := (s["from"] as Vector3).slerp(s["base"], 1.0 - (1.0 - f) * (1.0 - f)).normalized()
			pos = p.surface_point(d)
			basis = _xf_ground(d, _toward(d, _stack_dir)).basis * Basis(Vector3.RIGHT, -f * 18.0)
		_stack_herd.pose(i, 0, Transform3D(basis, pos))
	_stack_h = maxf(float(n_up), 1.0) * ball_h
	_stack_focus.global_position = ground + up * (_stack_h * 0.5 + 0.1)
	if k0 >= STACK_CLIMB_AT and not tumble and fmod(k0 - STACK_CLIMB_AT, STACK_CLIMB_EVERY) < delta and n_up <= 9:
		AudioManager.play_sfx_at("place", ground, -4.0, 0.15)
	if tumble and k0 - STACK_TUMBLE_AT < delta:
		AudioManager.play_sfx_at("tree_shake", ground, 0.0, 0.1)


# ======================================================================================== SCHEDULE
# ---------------------------------------------------------------------------------------- the scrapbook (15.5)
## THE TWO SIGHTS AND THE THREE COLLECTOR'S PAGES. The sights are the planet's own props, untouched: a focus
## node follows whichever stone (whichever shelf) is nearest the middle of the view, so a photo of any of
## them is a photo of the Nine Stones (the Shelves). The bonus things are new, small and built here, on the
## materials Grig's props already draw with (rock_material, vertex colour): three meshes, one draw call each,
## warmed behind the fade with everything else, gone with the last puff.
## WHO A PHOTO IS NAMED AFTER is the shared rule now (spec 17.1 rule 6, SafariPhotoScorer.class_rank): no
## local "backdrop" logic here decides it - Grig's own override of that is removed (see the header).
func _build_scrapbook() -> void:
	var p := safari.planet
	# THE NINE STONES (a sight)
	_stones_focus = Node3D.new()
	_stones_focus.name = "StonesFocus"
	add_child(_stones_focus)
	safari.add_subject({
		"id": "nine_stones", "name": "The Nine Stones", "kind": "sight", "category": "sight",
		"band": BAND_STONES, "node": _stones_focus, "radius": STONE_SIGHT_R,
		"awake": func() -> bool: return _stones_pick >= 0 and not _sleeping,
	})
	# THE SHELVES (a sight)
	for n in p.get_node("Props").get_children():
		if str(n.name).begins_with("ChalkShelf") and n is Node3D:
			_shelves.append(n as Node3D)
	_shelves_focus = Node3D.new()
	_shelves_focus.name = "ShelvesFocus"
	add_child(_shelves_focus)
	safari.add_subject({
		"id": "shelves", "name": "The Shelves", "kind": "sight", "category": "sight",
		"band": BAND_SHELVES, "node": _shelves_focus, "radius": SHELF_SIGHT_R,
		"awake": func() -> bool: return _shelves_pick >= 0 and not _sleeping,
	})
	_build_tally()
	_build_tenth()
	_build_drawing()
	_log("scrapbook: tally on stone %d %s, tenth stone %s, drawing %s, shelves %s" % [_tally_stone,
		_pp(p.dir_of(_tally.global_position)) if _tally != null else "-",
		_pp(p.dir_of(_tenth.global_position)) if _tenth != null else "-",
		_pp(p.dir_of(_drawing.global_position)) if _drawing != null else "-",
		str(_shelves.map(func(n: Node3D) -> String: return _pp(p.dir_of(n.global_position))))])


## GRIG'S TALLY MARKS on the outer face of one monolith: of the stones that neither hum nor are counted,
## the one farthest from the start; of its four flat faces, the one that looks most AWAY from the ring's
## middle - so they are seen only by someone walking round the outside of the henge.
func _build_tally() -> void:
	if _stones.is_empty():
		return
	var busy := {}
	for si: int in _hum_stones:
		busy[si] = true
	for arc: Array in _count_arcs:
		for si: int in arc:
			busy[si] = true
	var far := -1.0
	for pass_i in 2:
		for i in _stones.size():
			if pass_i == 0 and busy.has(i):
				continue
			var a := safari.start_dir.angle_to(_stones[i]["dir"])
			if a > far:
				far = a
				_tally_stone = i
		if _tally_stone >= 0:
			break
	var st: Dictionary = _stones[_tally_stone]
	var mi: MeshInstance3D = st["mesh"]
	var sxf: Transform3D = mi.global_transform if mi != null else (st["node"] as Node3D).global_transform
	# the monolith's own shape (planet_props.gd _step_monolith, as _build_hum reads it): a four-sided taper
	# with its corners on the local axes, so its flat faces look along the diagonals
	var v := int(st["variant"])
	var h := float(st["h"])
	var r0 := 0.40 + 0.03 * float(v % 3)
	var r_top := r0 * 0.74
	var y := minf(TALLY_Y, h * 0.5)
	var r_y := lerpf(r0 * 0.94, r_top, clampf((y - h * 0.26) / (h * 0.64), 0.0, 1.0))
	var da_dy := (r_top - r0 * 0.94) / (h * 0.64) / sqrt(2.0)
	var away := -_toward(st["dir"], _henge_dir)
	var best_k := 0
	var best_dot := -INF
	for k in 4:
		var ang := PI * 0.25 + PI * 0.5 * float(k)
		var dot := (sxf.basis * Vector3(cos(ang), 0.0, sin(ang))).normalized().dot(away)
		if dot > best_dot:
			best_dot = dot
			best_k = k
	var ang := PI * 0.25 + PI * 0.5 * float(best_k)
	var nh := Vector3(cos(ang), 0.0, sin(ang))
	var n_loc := (nh - Vector3.UP * da_dy).normalized()
	var up_loc := (Vector3.UP + nh * da_dy).normalized()
	var x_loc := up_loc.cross(n_loc).normalized()
	var origin := nh * (r_y / sqrt(2.0)) + Vector3.UP * y
	_tally = MeshInstance3D.new()
	_tally.name = "TallyMarks"
	_tally.mesh = Meshes.tally_marks()
	_tally.material_override = _rock
	_tally.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_tally)
	_tally.global_transform = sxf * Transform3D(Basis(x_loc, up_loc, n_loc), origin)
	_tally_front = (_tally.global_basis.z).normalized()
	_tally_focus = Node3D.new()
	_tally_focus.name = "TallyFocus"
	add_child(_tally_focus)
	_tally_focus.global_position = _tally.global_position + _tally_front * 0.04
	safari.add_subject({
		"id": "tally_marks", "name": "Grig's Tally Marks", "kind": "bonus", "category": "bonus",
		"band": BAND_TALLY, "node": _tally_focus, "radius": TALLY_R,
		"awake": func() -> bool: return not _extras_hidden,
		# a flat thing has a face: it reads best square on
		"front": func() -> Vector3: return _tally_front,
	})


## THE TINY TENTH STONE at the foot of the spindle tree nearest P_TENTH, on the side away from the henge.
func _build_tenth() -> void:
	var p := safari.planet
	var td := safari.dir_from_start(P_TENTH.x, P_TENTH.y)
	var tree: Node3D = null
	var tbest := deg_to_rad(TENTH_TREE_SEARCH_DEG)
	for n in p.get_node("Props").get_children():
		if str(n.name).begins_with("SpindleTree") and n is Node3D:
			var a := td.angle_to(p.dir_of((n as Node3D).global_position))
			if a < tbest:
				tbest = a
				tree = n as Node3D
	var sd := _free_near(td, 0.8)
	if tree != null:
		var trunk := p.dir_of(tree.global_position)
		var away := -_toward(trunk, _henge_dir)
		sd = p.step_dir(trunk, p.dir_of(p.surface_point(trunk) + away * 2.0), TENTH_FROM_TRUNK_M)
	var data: PlanetData = p.data
	_tenth = MeshInstance3D.new()
	_tenth.name = "TenthStone"
	_tenth.mesh = Meshes.tenth_stone(data.rock_color if data != null else Meshes.STONE,
		data.ground_color_low if data != null else Meshes.CHALK_DARK, data.ground_shadow_color if data != null else Meshes.SHADOW)
	_tenth.material_override = _rock
	add_child(_tenth)
	var xf := _xf_ground(sd, _toward(sd, _henge_dir))
	xf.origin -= xf.basis.y * 0.02
	_tenth.global_transform = xf
	_tenth_focus = Node3D.new()
	_tenth_focus.name = "TenthFocus"
	add_child(_tenth_focus)
	_tenth_focus.global_position = xf.origin + xf.basis.y * 0.22
	safari.add_subject({
		"id": "tenth_stone", "name": "The Tiny Tenth Stone", "kind": "bonus", "category": "bonus",
		"band": BAND_TENTH, "node": _tenth_focus, "radius": TENTH_R,
		"awake": func() -> bool: return not _extras_hidden,
	})


## A CHALK DRAWING OF YOU on the flattest clear tread near P_DRAWING (by Grig's steps), bent to the planet's
## curve, its top toward the far side so it is the right way up for someone coming from the pad.
func _build_drawing() -> void:
	var p := safari.planet
	var d0 := safari.dir_from_start(P_DRAWING.x, P_DRAWING.y)
	var dd := d0
	var found := false
	for ring_deg: float in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 15.0]:
		var n_k := 1 if ring_deg == 0.0 else 12
		for k in n_k:
			var d := _polar(d0, _tangent_at(d0), ring_deg, 30.0 * float(k))
			if _flat_enough(d):
				dd = d
				found = true
				break
		if found:
			break
	var n := p.ground_normal(dd)
	var top := -_toward(dd, safari.start_dir)
	top = (top - n * top.dot(n)).normalized()
	_drawing = MeshInstance3D.new()
	_drawing.name = "ChalkDrawing"
	_drawing.mesh = Meshes.chalk_you(p.radius)
	_drawing.material_override = _rock
	_drawing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drawing)
	_drawing.global_transform = Transform3D(Basis.looking_at(top, n), p.surface_point(dd) + n * 0.006)
	_drawing_focus = Node3D.new()
	_drawing_focus.name = "DrawingFocus"
	add_child(_drawing_focus)
	_drawing_focus.global_position = p.surface_point(dd) + n * 0.2
	var front := n
	safari.add_subject({
		"id": "chalk_you", "name": "A Chalk Drawing of You", "kind": "bonus", "category": "bonus",
		"band": BAND_DRAWING, "node": _drawing_focus, "radius": DRAWING_R,
		"awake": func() -> bool: return not _extras_hidden,
		# it lies on the ground: it reads best looked down on
		"front": func() -> Vector3: return front,
	})
	if not found:
		_log("scrapbook: no flat tread near the drawing's place - it lies at %s anyway" % _pp(dd))


## Flat, clear ground for the drawing: no prop within 1.0 m, and the ground level and flat at its middle
## and DRAWING_FLAT_M out four ways.
func _flat_enough(d: Vector3) -> bool:
	var p := safari.planet
	if p.nearest_prop_distance(d) < 1.0:
		return false
	var h0 := p.surface_point(d).length()
	var pts: Array[Vector3] = [d]
	var t := _tangent_at(d)
	for k in 4:
		pts.append(_polar(d, t, rad_to_deg(DRAWING_FLAT_M / p.radius), 90.0 * float(k)))
	for q: Vector3 in pts:
		if rad_to_deg(p.ground_normal(q).angle_to(q)) > DRAWING_FLAT_DEG:
			return false
		if absf(p.surface_point(q).length() - h0) > DRAWING_FLAT_DH:
			return false
	return true


## The sights' focus follows the view (see _build_scrapbook).
func _tick_scrapbook(delta: float) -> void:
	_sight_pick_in -= delta
	if _sight_pick_in > 0.0 and not safari.camera_up and not _building:
		return
	_sight_pick_in = SIGHT_PICK_SEC
	if not _stones.is_empty():
		_stones_pick = _pick_sight(_stones, func(st: Dictionary) -> Vector3: return st["pos"], 1.3, _stones_pick)
		if _stones_pick >= 0:
			var st: Dictionary = _stones[_stones_pick]
			_stones_focus.global_position = (st["pos"] as Vector3) + (st["up"] as Vector3) * (float(st["h"]) * 0.5)
	if not _shelves.is_empty():
		_shelves_pick = _pick_sight(_shelves, func(n: Node3D) -> Vector3: return n.global_position, SHELF_SIGHT_Y, _shelves_pick)
		if _shelves_pick >= 0:
			_shelves_focus.global_position = _shelves[_shelves_pick].global_transform * Vector3(0.0, SHELF_SIGHT_Y, 0.0)


## Which stone (shelf) the sight is on: the one _pick_focus likes best (nearest the middle of the view, with
## a clear line to it), but the one it is on now stays until another is SIGHT_SWITCH_DEG nearer the middle
## or it can no longer be seen - two stones near the middle must not trade places frame to frame while you
## aim and focus (a probe's photo of the stones focused on one and scored the other: focus 0).
func _pick_sight(items: Array, pos_of: Callable, lift: float, current: int) -> int:
	var best := _pick_focus(items, func(_x: Variant) -> bool: return true, pos_of, lift)
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if best < 0 or current < 0 or current >= items.size() or best == current or cam == null:
		return best
	var fwd := -cam.global_transform.basis.z
	var ang := func(i: int) -> float:
		var q: Vector3 = pos_of.call(items[i])
		q += safari.planet.up_at(q) * lift
		return rad_to_deg(fwd.angle_to(q - cam.global_position))
	if float(ang.call(best)) < float(ang.call(current)) - SIGHT_SWITCH_DEG:
		return best
	var qc: Vector3 = pos_of.call(items[current])
	qc += safari.planet.up_at(qc) * lift
	if pacing != null and not pacing.sight_clear(cam.global_position, qc):
		return best
	return current


## Grig's local naming override that used to live here (a "backdrop" stepping back for whatever the
## camera was aimed at) is REMOVED (spec 17.1 rule 6): naming now comes from the shared class rule in
## SafariPhotoScorer.score_frame (class_rank), the same as every other planet.


func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line]
	var ev: Array = []
	for run: Dictionary in COUNT_RUNS:
		var arc: Array = _count_arcs[int(run["at"])] if int(run["at"]) < _count_arcs.size() else []
		var d: Vector3 = (_stones[arc[1]] as Dictionary)["dir"] if not arc.is_empty() else _henge_dir
		ev.append(["grig_count", run["id"], "Grig Counts the Stones", run["start"], run["end"], d, "any", Color("#e0b88a"), ""])
	for run: Dictionary in DRIFT_RUNS:
		var d: Vector3 = _drift_dirs[int(run["at"])]
		ev.append(["chalk_drift", run["id"], "Chalk Drift", run["start"], run["end"], d, "any", Color("#e3dccb"),
			"A gust stirs the chalk on %s..." % _place_name(d)])
	for run: Dictionary in HUM_RUNS:
		var st: Dictionary = _stones[_hum_stones[int(run["at"])]] if int(run["at"]) < _hum_stones.size() else {}
		var d: Vector3 = st["dir"] if not st.is_empty() else _henge_dir
		ev.append(["henge_hum", run["id"], "Henge Hum", run["start"], run["end"], d, "any", Color("#eadba8"),
			"A stone in the HENGE starts to hum..."])
	if _moon != null:
		var md := safari.planet.dir_of(_moon_eye + _moon_g * 6.0)
		ev.append(["moonrise", "moonrise", "Moonrise in the Henge", MOON_START, MOON_END, md, "any", Color("#dcd6c6"),
			"A pale glow gathers past the HENGE... something is rising."])
	if _stack_herd != null:
		ev.append(["great_stack", "great_stack", "The Great Stack", STACK_START, STACK_END, _stack_dir, "only", Color("#cfc6b0"),
			"Every pebble starts rolling... toward %s!" % _place_name(_stack_dir)])
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
				_on_warn(kind, id)
				if line != "":
					_queue_line(line),
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


## The warning's SOUND, heard anywhere on the planet (2D), for the kinds whose own tick does not already
## start one (the hum's rising drone, the drift's gusts and the moon's chime start in their ticks; Grig's
## voice in _borrow_grig).
func _on_warn(kind: String, id: String) -> void:
	_log("warn %s t=%.1f" % [id, _t])
	match kind:
		"great_stack":
			for k in 3:
				get_tree().create_timer(0.35 * float(k)).timeout.connect(func() -> void:
					if is_inside_tree() and not _sleeping:
						_sound_once("rotate", 0.6 + 0.1 * float(k), -6.0).play())


func _on_start(kind: String) -> void:
	match kind:
		"chalk_drift":
			AudioManager.play_sfx_at("tree_shake", _drift_root.global_position, 0.0, 0.05)
			safari.puff_at(_drift_root.global_position + safari.planet.up_at(_drift_root.global_position) * 0.3, 20, Meshes.CHALK)
		"henge_hum":
			AudioManager.play_sfx_at("comms_over", _hum_focus.global_position, -2.0, 0.05)
		"moonrise":
			_sound_once("finale_shower", 0.6, -10.0).play()
		"great_stack":
			AudioManager.play_sfx_at("place", safari.planet.surface_point(_stack_dir), 0.0, 0.1)


func _on_end(kind: String) -> void:
	match kind:
		"chalk_drift":
			safari.puff_at(_drift_root.global_position + safari.planet.up_at(_drift_root.global_position) * 0.4, 16, Meshes.CHALK)
		"moonrise":
			if _moon != null:
				_moon.visible = false


## The run of `runs` whose window holds `tt` (from its warning when `with_warn`) and that is eligible.
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
func _make_beacon(id: String, colour: Color) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	b.name = "Beacon_" + id
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 1.35)
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
		if safari.camera_up:
			want = 0.0
		var lv := move_toward(float(b.get_meta("level", 0.0)), want, delta * (4.0 if safari.camera_up else 1.5))
		b.set_meta("level", lv)
		b.visible = lv > 0.01
		if not b.visible:
			continue
		var tdir := target - pd * target.dot(pd)
		if ang > 165.0 or tdir.length() < 0.05:
			var cf := -safari.rig.get_view_camera().global_transform.basis.z if safari.rig != null and safari.rig.get_view_camera() != null else safari.start_fwd
			tdir = cf - pd * cf.dot(pd)
		if tdir.length() < 0.001:
			tdir = _tangent_at(pd)
		var a := deg_to_rad(minf(BEACON_AHEAD_DEG, ang))
		var along := (pd * cos(a) + tdir.normalized() * sin(a)).normalized()
		b.global_position = safari.ground_point(along, 0.7)
		(b.material_override as ShaderMaterial).set_shader_parameter("fade", lv * (0.72 + 0.28 * sin(_t * 3.4)))


# ======================================================================================== TICK
## True in the RARE_LEAD_SEC before a rare subject of today comes up.
func _rare_soon(tt: float) -> bool:
	var ups: Array = []
	if bool(_eligible.get("moonrise", false)):
		ups.append(MOON_START + MOON_UP.x)
	if bool(_eligible.get("great_stack", false)):
		ups.append(STACK_START + STACK_UP.x)
	for u: float in ups:
		if tt >= u - RARE_LEAD_SEC and tt < u:
			return true
	return false


func _queue_line(text: String) -> void:
	var due := maxf(_t, INTRO_HINT_SEC)
	if not _lines.is_empty():
		due = maxf(due, float(_lines[-1][0]) + LINE_SEC)
	elif _t < _line_free_at:
		due = maxf(due, _line_free_at)
	_lines.append([due, text])


func tick(t: float, delta: float) -> void:
	_t = t
	if pacing != null:
		pacing.AFTER_SEC = PACING_AFTER_SOON if _rare_soon(t) else PACING_AFTER_SEC
	if not _lines.is_empty() and not _building and _t >= float(_lines[0][0]) and not _sleeping:
		safari.announce(str(_lines[0][1]), 3.5)
		_log("line t=%.1f: %s" % [_t, str(_lines[0][1])])
		_line_free_at = _t + LINE_SEC
		_lines.pop_front()
	_tick_bugs(delta)
	_tick_owls(delta)
	_tick_bunnies(delta)
	_tick_worms(delta)
	_tick_grig(delta)
	_tick_drift(delta)
	_tick_hum(delta)
	_tick_moon(delta)
	_tick_stack(delta)
	_tick_beacons(delta)
	_tick_scrapbook(delta)


## The three minutes are up: the bugs curl up, the bunnies puff back into chalk, the owls fly off, the
## worms dig in; everything else goes in the puff PlanetSafari makes at each awake subject, the warnings
## and sounds stop. Grig is handed back at once and put back where he stood when this node leaves.
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_moon, _moon_halo, _hum_ring, _hum_glow]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for c in _hum_collars:
			c.visible = false
		var emitters: Array = []
		emitters.append_array(_drift_arms)
		emitters.append_array(_drift_thick)
		emitters.append_array([_drift_skitter, _hum_dust, _tap_sparks])
		for pr: CPUParticles3D in emitters:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false
		if _stack_herd != null:
			for i in 9:
				_stack_herd.hide_one(i)
		# the collector's pages go back into hiding with everything else (the sights are the planet's own)
		_extras_hidden = true
		for n: Node3D in [_tally, _tenth, _drawing]:
			if n != null and is_instance_valid(n):
				n.visible = false)
	if _grig_borrowed:
		_release_grig(false)
	return true


func _exit_tree() -> void:
	_release_grig(true)


# ======================================================================================== HELPERS
## Of `items` that `ok` accepts, the one nearest the middle of the view whose middle the lens can see
## (Bolt's _pick_focus); -1 when none is awake.
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
	if cam == null or pacing == null:
		return int(cands[0][1])
	for k in mini(cands.size(), 4):
		if float(cands[k][0]) >= 100.0:
			break
		var q: Vector3 = cands[k][2]
		if pacing.sight_clear(cam.global_position, q + safari.planet.up_at(q) * lift):
			return int(cands[k][1])
	return int(cands[0][1])


func _point_in_frame(q: Vector3, grow: float) -> bool:
	return pacing.point_in_frame(q, grow) if pacing != null else false


func _front_of(n: Node3D) -> Vector3:
	if n == null or not is_instance_valid(n):
		return Vector3.ZERO
	return (-n.global_basis.z).normalized()


func _player_dir() -> Vector3:
	return safari.planet.dir_of(safari.player.global_position) if is_instance_valid(safari.player) else safari.start_dir


func _tangent_at(d: Vector3) -> Vector3:
	var t := safari.start_fwd - d * safari.start_fwd.dot(d)
	if t.length() < 0.01:
		t = Vector3.RIGHT - d * d.x
	return t.normalized()


func _polar(centre: Vector3, ref: Vector3, rho_deg: float, psi_deg: float) -> Vector3:
	var r := (ref - centre * ref.dot(centre)).normalized()
	var h := r.rotated(centre, -deg_to_rad(psi_deg)).normalized()
	var a := deg_to_rad(rho_deg)
	return (centre * cos(a) + h * sin(a)).normalized()


func _xf_ground(d: Vector3, fwd: Vector3) -> Transform3D:
	var xf := _xf(d, fwd)
	var n := safari.planet.ground_normal(d.normalized())
	var f := -xf.basis.z
	f = (f - n * f.dot(n)).normalized()
	xf.basis = Basis.looking_at(f, n)
	return xf


func _toward(d: Vector3, target: Vector3) -> Vector3:
	var t := target - d * target.dot(d)
	return t.normalized() if t.length() > 0.001 else _tangent_at(d)


func _xf(d: Vector3, fwd: Vector3) -> Transform3D:
	return safari.planet.surface_transform(d.normalized(), fwd)


func _free_near(dir: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(dir) >= clear_m:
		return dir
	var t := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
	for ring_deg in [3.0, 6.0, 9.0, 12.0, 15.0]:
		for k in 8:
			var d := dir.rotated(t.rotated(dir, TAU * float(k) / 8.0), deg_to_rad(ring_deg)).normalized()
			if p.nearest_prop_distance(d) >= clear_m:
				return d
	return dir


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


func _log(msg: String) -> void:
	print("[GrigSafari] " + msg)


## Everything a test needs to find the subjects and places (the probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"henge": _henge_dir, "bug_places": _bug_places.duplicate(), "drift": _drift_dirs.duplicate(),
		"stones": _stones.map(func(s: Dictionary) -> Vector3: return s["dir"]),
		"stone_pos": _stones.map(func(s: Dictionary) -> Vector3: return s["pos"]),
		"hum_stones": _hum_stones.duplicate(), "count_arcs": _count_arcs.duplicate(true),
		"moon_gap": _moon_gap, "moon_eye": _moon_eye, "moon_g": _moon_g, "stack": _stack_dir,
		"owl_seats": _owls.map(func(o: Dictionary) -> Transform3D: return o["seat"]),
		"eligible": _eligible.duplicate(),
		"tally_stone": _tally_stone, "tally": _tally.global_position if _tally != null else Vector3.ZERO,
		"tenth": _tenth.global_position if _tenth != null else Vector3.ZERO,
		"drawing": _drawing.global_position if _drawing != null else Vector3.ZERO,
		"shelves": _shelves.map(func(n: Node3D) -> Vector3: return n.global_position),
	}
