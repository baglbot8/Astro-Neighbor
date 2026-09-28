extends SafariWorld
## BOLT'S WORLD WAKES UP (docs/PLANET_SAFARI_SPEC.md 5.5 as amended by 6.2, 8.2 and 11; builders P4, Q4,
## R4). Loaded by PlanetSafari when a safari starts on Bolt's world, freed when it ends: nothing here
## exists outside a safari (the user's rule 5), and nothing on the planet is changed - Bolt himself is
## the one thing borrowed (he climbs a mast for each tune-up) and he is put back exactly where he stood
## when this node leaves the tree.
##
## ROUND 2 (R4, 2026-09-24/25): the user wanders and ignores hints - "if nothing shows up in 20 seconds
## of wandering, then it's not frequent enough" - and, the same night, "I dont want thing so commonly
## happening at the same time on the planet that you see something too soon ... make sure things that
## you'd take photos of arent way too common or too rare." So the planet follows the user's TIERS (spec
## 11.2) and is held inside the density BAND of 11.2b, measured by tools/ps_wanderer.gd:
##   creatures        always about, in many places  nut-crabs in 3 places, gear-beetles on 2 groves
##                                                   (the Gear Grove's sleep at night), the new
##                                                   SPRING-HOPPERS (under the deck all over the planet,
##                                                   up where it has gone quiet - see HOPPER_SCOUTS),
##                                                   spark-moths on Antenna Hill at night
##   common events    several times, ~30 s          Ring Rain at 2 spots on the ring's circle, the Scrap
##                                                   Snail crosses twice
##   uncommon events  several times, ~12 s          the Big Geyser at 3 vents, Bolt's Tune-up on 2 masts
##   rare events      once                          the Sky Whale (still overlapping the geyser at the
##                                                   start, so the rare costs a choice), the Great Magnet
##                                                   (1 day in 4)
## RARITY follows the tier: creatures and Bolt 1, spark-moths 2 (a creature, but night only), common
## events 2, uncommon events 3, rare events 4.
## NOT TOO COMMON: round 1 of R4 (46 hoppers sprinkled everywhere, crabs 6 x 3, beetles on 6 trees,
## moths on 5 posts, rain at 3 spots) met something new every 7.2 s (median) and nothing was ever more
## than 12.5 s away - too common by the band. This round thinned and spread things so that two subjects
## rarely come on screen together (the pairs that did are named where they were split up: GROVES,
## RAIN_SPOT_DEG, _pick_snail_meet, the moths' scatter, the Gear Grove's night), and let the curious
## scouts end a quiet stretch instead of a crowd filling it. The measured band is in the report.
## ROUND 3 (R4, 2026-09-25, after the critic): the planet was BURSTY - clusters then long empty stretches
## - and the scouts only worked for a wanderer whose eyes stayed on the deck. Now (1) a scout comes up
## for ANY gaze, boinging up into the view when you look over the deck (SCOUT_SKY_M), judged from where
## your lens will be when it is up (_lens_soon); (2) the director's "in view" is the scorer's own test
## made stricter than the gate's (CURIOUS_MIN_SIZE_FRAC); (3) ONE NEW THING AT A TIME: the shy
## creatures keep out of sight for SHY_SEC after you come upon something new (SHY_SEC); (4) crabs down
## their burrows near you no longer make a dead zone where no scout may come up (_creature_places).
## Measured with the critic's own wanderer and three gazes; tools/ps_wanderer.gd now defaults to the
## critic's mixed gaze.
## CONVERTED (builder BOLT, 2026-09-25; spec 12.5 and 13.2): the host, the offer lines and the roster
## (now with the spring-hopper) are this file's MANIFEST, and the pacing is the SHARED director,
## SafariWorld.Pacing - this file's own copy of it (the lonely clock, the look round, the shy timers,
## "creature ahead", the ground-spot search) is gone. The lead's two rules for it: it VARIES WHAT IT
## BRINGS - three bringers now, not the hopper alone: a spring-hopper boings up out of the deck, a
## nut-crab pushes up a loose deck plate and creeps out, a gear-beetle whirs in on its cog and lands
## (THE CURIOUS ONES below) - and it STAYS QUIET while the Sky Whale or the Great Magnet is up (their
## roster tiers "rare" / "rare_day").
##
## SCRAPBOOK AND POLISH (builder BOLTC, 2026-09-26; spec 15.5 and 16): every roster entry has its
## scrapbook "category"; two SIGHTS (the Antenna Mast, Bolt's Workshop) and three BONUS things (a lost
## sock, "Bolt No. 1", a welded smiley) - see SIGHTS AND BONUS; Bolt poses on his own rhythm, not when a
## camera points at him (BOLT_POSE_EVERY); the spark-moths are a night bringer (MOTH_SCOUT_M); the
## director retries a bring that was not seen after 2 s, not 3 (_build_pacing). Measured in the report.
##
## ------------------------------------------------------------------------------------ THE PLACES
## Measured round the planet from the start beside the pad (probe `layout`, Bolt's seed-37 props), as
## (degrees round, bearing from the start heading, + = right). 1 degree = 0.18 m; the safari walk is
## 1.5 m/s = 8.2 deg/s, so a quarter round is 11 s and the far side 22 s.
##   BASE          (0, 0)       the start. The Big Geyser's first vent is 3.3 m to its front-left (18, -65);
##                              the small mast by the pad (Antenna1) is at (20, -22).
##   VENT FIELD    (85, -80)    pipes and vent stacks a quarter round to the left: nut-crabs (1).
##   NUT FLATS     (128, 35)    the giant hex nuts and the gantry out front: nut-crabs (2).
##   FAR VENTS     (160, -40)   past the far vent stack: nut-crabs (3).
##   GEAR GROVE    (62, 147)    GearTree1 and GearTree6 a quarter round to the right: gear-beetles (1);
##                              Ring Rain's first spot, where the ring passes straight overhead (83, 145).
##   BACK GROVE    (143, -154)  GearTree4, out behind: gear-beetles (2).
##   BOLT'S PLACE  (60.6, 67.4) his home spot.
##   ANTENNA HILL  (88.4, 178)  the big mast behind the pad: Bolt's Tune-up (the paired one); the moths.
##   FAR SIDE      (162, 115)   the Sky Whale: the Big Geyser's first vent's antipode (Q4).
##   MAGNET HATCH  (96.9, -35)  the Great Magnet: Ring Rain's first spot's antipode.
##   SNAIL'S END   (81.4, -8.5) the scrap crates at the front, 167 degrees from the tune-up's mast top.
##   SNAIL'S MEET  (50.7, -52.7) where its two crossings meet (_pick_snail_meet); its first crossing
##                              starts at (87.9, -111.6).
## Ring Rain's second spot is the first carried 150 degrees round the ring's circle (113.5, -8.9); the
## geyser's other vents are (136, -83) and (104, 80). All are logged at build.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned 8 s ahead, with a SIGHT and a SOUND that duplicate each other (spec 4):
## a line on screen naming the place, a sound heard anywhere on the planet, a coloured glow that sits
## on YOUR horizon in the event's direction (it fades once you are within 50 degrees), and the event's
## own cue (the ring glints, the vents puff, metal hums...). Nothing depends on reading them.
##   0:02-0:14  BOLT'S TUNE-UP (2) on the small mast by the pad.
##   0:08-0:30  THE SKY WHALE, far side (rare, once). Warned from the first second. SPOUTS 0:22-0:24.7.
##   0:20-0:31  THE BIG GEYSER (1), by the start - the OTHER side from the whale. FULL BLAST 0:22.3-0:24.7.
##   0:30-1:00  RING RAIN (2).                      0:42-1:12  THE SCRAP SNAIL (2) to where it meets.
##   1:02-1:13  THE BIG GEYSER (2).                 1:12-1:42  RING RAIN (1) over the Gear Grove.
##   1:15-1:35  THE GREAT MAGNET (rare day) opposite Ring Rain (1); ALL AFLOAT 1:25-1:28 = rain (1) thickest.
##   1:50-2:30  THE SCRAP SNAIL (1): on to the crates, WHISTLES 2:25-2:29.5.
##   1:58-2:09  THE BIG GEYSER (3).
##   2:20-2:35  BOLT'S TUNE-UP (1) on Antenna Hill, opposite the snail's end: SPARKS 2:25-2:29.5.
##   all 3 min  NUT-CRABS, GEAR-BEETLES, BOLT; SPARK-MOTHS at night; when it has gone quiet (and no
##              rare is up) the director brings a curious SPRING-HOPPER, NUT-CRAB or GEAR-BEETLE.
##              The shy ones (crabs, beetles, moths, hoppers) keep out of sight for SHY_SEC after you
##              come upon something new, so they come one at a time.
## The three designed overlaps keep their exact times and places from Q4 (whale spout / geyser (1) blast,
## magnet afloat / rain (1) thickest, snail (1) whistling / tune-up (1) sparks): each pair shares one
## short best window and sits too far apart to catch both at their best (see WHALE_SPOUT below). The
## later repeats of the geyser, the rain and the snail are the "uncommon/common" tiers; the whale and
## the magnet never come back, so taking the geyser at 0:22 still costs the whale.
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): one MultiMesh per part - nine crabs are 2 draw calls, the
## spring-hoppers 2, the beetles 2, the moths 2, the three geyser vents 1. Every mesh is PlanetMeshKit
## vertex colour on the two materials Bolt's own props already draw with; particles are CPUParticles3D
## on the shipped puff and sparkle materials; the glows are the shipped star shader. No lights, no new
## material. Everything is built in `build` (warmed behind the fade) and only moved, shown or hidden
## afterwards: each repeated event re-uses ONE set of emitters, moved to its next place.
## CONVERTED: the curious crabs (2) and beetles (2) are extra members of the crab, burrow and beetle
## herds - no new draw call of their own - but those herds' culling boxes are now the whole planet (a
## curious one can come up anywhere), so the crab, claw, burrow and beetle MultiMeshes are drawn in every
## view, not only near their places. The crab's jet of steam is one more CPU emitter on the shipped puff
## material, built in `build` and warmed with the rest. Measured before/after in the report.
##
## ------------------------------------------------------------------------------------ FACING AND SIZE
## FACING (spec 11.1): every creature, Bolt and the tune-up carry "front", a Callable returning the
## world unit vector their face points along (every mesh here faces -Z, so it is -basis.z of the node
## the subject is scored on). The spark-moths' front is the heading of the moth nearest the lens.
## Checked in pictures (probe r4_fronts, phone renderer): each subject shot from +front shows its face,
## from -front its back. Facing there 10.0 and 0.0 (the moths 9.2 / 0.2: they turn as they circle).
## SIZE BANDS (spec 11.1): see SIZE BANDS below - each is set from the subject's usual distance so a 45
## degree shot from there scores 6 or less on size, and getting close or zooming reaches the band.

const Meshes := preload("res://src/planet_safari/worlds/bolt_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")

## THE MANIFEST (spec 12.5; safari_world.gd, THE MANIFEST). Bolt's voice (src/characters/npc_data.gd,
## src/projects/data/bolt.gd): clipped and literal, a maintenance log that counts and times things and
## confirms them; every line 60 characters or fewer, no Animal Crossing words. The roster is every
## subject this file can register, in the journal's order - the spring-hopper added (spec 13.3) - with
## its tier (spec 11.2): rarity follows it, and "rare" / "rare_day" keep the pacing director quiet - and
## its scrapbook "category" (spec 15.5, the lead's API: sight / event / neighbour / creature / bonus).
const MANIFEST := {
	"host": "bolt",
	"offer": "The yard wakes up for 180 seconds a day. I timed it.",
	"ask": "Photo safari?",
	"yes": "Proceed to the landing pad. Photograph everything.",
	"no": "Understood. The offer stands until midnight.",
	"asleep": "Yard asleep. Zero creatures awake. Come back tomorrow.",
	"roster": [
		{"id": "nut_crab", "name": "Nut-crab", "tier": "creature", "category": "creature"},
		{"id": "gear_beetle", "name": "Gear-beetle", "tier": "creature", "category": "creature"},
		{"id": "spring_hopper", "name": "Spring-hopper", "tier": "creature", "category": "creature"},
		{"id": "bolt", "name": "Bolt", "tier": "neighbour", "category": "neighbour"},
		{"id": "sky_whale", "name": "The Sky Whale", "tier": "rare", "category": "event"},
		{"id": "big_geyser", "name": "The Big Geyser", "tier": "uncommon", "category": "event"},
		{"id": "ring_rain", "name": "Ring Rain", "tier": "common", "category": "event"},
		{"id": "scrap_snail", "name": "The Scrap Snail", "tier": "common", "category": "event"},
		# "friend": "bolt" (docs/PLANET_SAFARI_SPEC.md 17.2 item 2a): a kept photo of HIS OWN tune-up is
		# a photo of Bolt for ProfessorAsk.neighbour_photo_id() - the user's exact case, where his Bolt
		# photo was this event, not the plain "bolt" roster entry, and the Professor said nothing.
		{"id": "tune_up", "name": "Bolt's Tune-up", "tier": "uncommon", "category": "event", "friend": "bolt"},
		{"id": "spark_moth", "name": "Spark-moths", "tier": "night", "category": "creature"},
		{"id": "great_magnet", "name": "The Great Magnet", "tier": "rare_day", "category": "event"},
		# THE SCRAPBOOK'S SIGHTS AND COLLECTOR'S PAGES (spec 15.5; see SIGHTS AND BONUS below)
		{"id": "antenna_mast", "name": "The Antenna Mast", "tier": "sight", "category": "sight"},
		{"id": "workshop", "name": "Bolt's Workshop", "tier": "sight", "category": "sight"},
		{"id": "lost_sock", "name": "A Lost Sock", "tier": "bonus", "category": "bonus"},
		{"id": "bolt_no_1", "name": "\"Bolt No. 1\"", "tier": "bonus", "category": "bonus"},
		{"id": "crate_smiley", "name": "A Welded Smiley", "tier": "bonus", "category": "bonus"},
	],
}
const SFX_DIR := "res://assets/audio/sfx/"

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
const WHALE_START := 8.0
const WHALE_END := 30.0
const MAGNET_START := 75.0
const MAGNET_END := 95.0
## The repeated events, one row per occurrence. The FIRST row of each is the one the designed overlap
## is measured on (Q4) and keeps its old event id, time and place; "at" is the place's index.
const GEYSER_RUNS := [
	{"id": "big_geyser", "start": 20.0, "end": 31.0, "at": 0},
	{"id": "big_geyser_2", "start": 62.0, "end": 73.0, "at": 1},
	{"id": "big_geyser_3", "start": 118.0, "end": 129.0, "at": 2},
]
const RAIN_RUNS := [
	{"id": "ring_rain", "start": 72.0, "end": 102.0, "at": 0},
	{"id": "ring_rain_2", "start": 30.0, "end": 60.0, "at": 1},
]
## "at" = the road: 0 from where the crossings meet to the crates (Q4's crossing: its end, the whistle
## and the overlap proof are unchanged), 1 from out past the Vent Field to where they meet.
const SNAIL_RUNS := [
	{"id": "scrap_snail", "start": 110.0, "end": 150.0, "at": 0},
	{"id": "scrap_snail_2", "start": 42.0, "end": 72.0, "at": 1},
]
## "at" = the mast: 0 Antenna Hill (Q4's), 1 the small mast by the pad. "best" = the sparks.
const TUNE_RUNS := [
	{"id": "tune_up", "start": 140.0, "end": 155.0, "at": 0, "best": Vector2(145.0, 149.5)},
	{"id": "tune_up_2", "start": 2.0, "end": 14.0, "at": 1, "best": Vector2(6.5, 9.8)},
]
## Each geyser run: rumble 2.3 s, FULL BLAST the next 2.4 s, then dies down to its end (run 1: 22.3-24.7).
const GEYSER_BLAST_AT := 2.3
const GEYSER_BLAST_SEC := 2.4
## Each rain run is THICKEST from 13 s to 16 s after it starts (run 1: 85-88).
const RAIN_THICK_AT := 13.0
const RAIN_THICK_SEC := 3.0
## Each snail crossing whistles over its last 5 s but half a second (run 1: 145-149.5).
const SNAIL_WHISTLE_BEFORE := 5.0
const SNAIL_WHISTLE_STOP := 0.5
## Best moments (the review's "moment" line and multiplier; SafariScoring.MOMENT_CEILING is 2.4).
##
## THE OVERLAPS FORCE A CHOICE (spec 6.2, 8.2; builder Q4). Each pair's best moments are the SAME
## short window, and the pair sits so far apart that the walk from the nearest spot where one can be
## photographed at its best to the nearest spot where the other can takes LONGER than that window:
## whoever takes one at its best cannot reach the other's. The rule, per pair: window < gap / walk
## speed, where the gap is the shortest walk between ANY spot on the planet that photographs one at its
## best and ANY spot that photographs the other (the photo scorer run over a 20,000-point grid of the
## whole surface, not only the line between them), taken at eye height standing and at the top of a
## hop, which the camera allows. The windows below keep a hop-to-hop photo pair out of reach even with
## the walk 20% faster (spec 5.1: the walk will be tuned after play). Measured (Q4 round 3, probe
## `regions`, phone renderer 2556x1179, 45 degree lens): the smallest gap anywhere, its walk time, and
## the walk speed that would catch it within the WHOLE window. Hop-to-hop is the worst case; standing
## at both ends is in brackets.
##   whale spout + tail / geyser full blast  22.3-24.7  2.4 s   24.2 deg 2.95 s, 1.23x (33.5 deg, 1.70x)
##   magnet all afloat / ring rain thickest  85-88      3.0 s   31.7 deg 3.86 s, 1.29x (42.4 deg, 1.72x)
##   snail's kettle whistling / tune-up sparks   145-149.5  4.5 s   46.4 deg 5.65 s, 1.26x (55.1 deg, 1.49x)
## (Round 2 had 3.6 s and 4.0 s: a photo pair taken at hop height 12 degrees off the direct line beat
## both. The whale's far side is the geyser's antipode: 180 degrees.) R4 kept all three pairs' times
## and places; no other event of the pairs' kinds runs inside those windows.
const WHALE_SPOUT := Vector2(22.0, 24.3)       # two short blows, at 22 and 23.2; puffs in the air 22.3-24.7
const WHALE_TAIL := Vector2(23.2, 24.9)        # the flick is past half its swing 23.51-24.59, inside the window
const SPOUT_EVERY := 1.2
const SPOUT_BLOW := 0.7
const MAGNET_AFLOAT := Vector2(85.0, 88.0)
const MAGNET_SINK := 1.5
## The bolts float up over this long before MAGNET_AFLOAT.x, and drop over this long after .y.
const SCRAP_RISE := 4.0
const SCRAP_DROP := 1.5
const MOTH_BURST_EVERY := 12.0
const MOTH_BURST_SEC := 2.0

# ------------------------------------------------------------------------------ the places
const P_GEYSER := Vector2(18.0, -65.0)
## The geyser's other two vents: out past the far vent stack, and on the right between the nuts and
## the Gear Grove (each moved to the nearest clear spot).
const P_GEYSER_MORE := [Vector2(138.0, -80.0), Vector2(104.0, 80.0)]
const P_VENT_FIELD := Vector2(85.0, -80.0)
const P_CRAB_PLACES := [Vector2(85.0, -80.0), Vector2(128.0, 35.0), Vector2(160.0, -40.0)]
const P_GEAR_GROVE := Vector2(70.0, 125.0)
## Two groves, and how many beetles live on each tree there. The Gear Grove is the close pair GearTree1
## and GearTree6 (14 degrees apart); the Back Grove is GearTree4 out on the far side. (Round 1 used
## GearTree0/3/5 too: 0 stands 32 degrees from Bolt's home and 3 25 degrees from the Vent Field's crabs,
## so a turn of the head brought two subjects on screen at once - 22 of the wanderer's 398 encounters
## came in such pairs - and 3, 4, 5 are 59-65 degrees apart, three places, not one grove.)
## Ring Rain's three spots: degrees along the ring's circle from the first (the Gear Grove's, pinned by
## Q4's pair with the Magnet). Chosen from that circle, every 10 degrees, for the farthest from every
## creature's place: +150 (113, -9) is 40 degrees from the Nut Flats' crabs and 50 from the Far Vents';
## -80 (53, -132) is 43 from the pad and 57 from the Vent Field. (Round 1's +-120 fell 10 degrees from
## the Nut Flats' crabs and 23 from the Vent Field's, so rain and crabs came on screen together.)
const RAIN_SPOT_DEG := [0.0, 150.0]
const GROVES := [["GearTree1", "GearTree6"], ["GearTree4"]]
const BEETLES_PER_TREE := [1, 2]
## The masts: Antenna Hill's (the paired tune-up) and the small one by the pad.
const MASTS := ["Antenna0", "Antenna1"]
const ANTENNA_NAME := "Antenna0"
## Spark-moth swarms at night: Antenna Hill (spec 5.5). (R4 round 1 had both masts and the three lamps:
## five swarms seen from far across the dark planet, 5.8 new encounters a night run on their own.)
const MOTH_POSTS := ["Antenna0"]
## Named places for the warning lines of the repeated events (the nearest one is named).
const PLACE_NAMES := [
	["the LANDING PAD", Vector2(0.0, 0.0)], ["the VENT FIELD", Vector2(85.0, -80.0)],
	["the NUT FLATS", Vector2(128.0, 35.0)], ["the FAR VENTS", Vector2(160.0, -40.0)],
	["the GEAR GROVE", Vector2(70.0, 125.0)], ["BOLT'S PLACE", Vector2(60.6, 67.4)],
	["ANTENNA HILL", Vector2(88.4, 178.0)], ["the FAR SIDE", Vector2(162.0, 115.0)],
	["the BACK GROVE", Vector2(143.0, -154.0)], ["the MAGNET HATCH", Vector2(96.9, -35.0)],
]

## A warning glow sits this far round from you toward its event (just inside your horizon: from eye
## height 1.6 m the horizon is acos(10.5 / 12.1) = 29.8 degrees away), 0.55 x 1.5 m, its foot on
## the horizon line - about 6 x 16 degrees of view from 5 m.
const BEACON_AHEAD_DEG := 27.0
## ...and fades out between these two (fully gone inside BEACON_NEAR_DEG), where the event itself is
## in view: 50 degrees is 9 m, and every event here is visible from about 60 degrees.
const BEACON_NEAR_DEG := 50.0
const BEACON_FULL_DEG := 70.0

# ------------------------------------------------------------------------------ SIZE BANDS (spec 11.1)
## The best SIZE band of each subject: its sphere's projected diameter as a fraction of the frame
## height (SafariPhotoScorer.score_subject's size_frac). Set per subject from its USUAL DISTANCE: at
## the 45 degree lens and that distance, size_frac / band.x <= 0.6, i.e. size scores 6 or less on the
## linear fall-off the scorer had (R3's smooth rule scores it no higher), and the band is reachable by
## walking in to d_in (45 degrees) or by zooming at the usual distance to the lens angles given. The
## numbers are exact for the scorer's sphere: size_frac = tan(asin(r / d)) / tan(fov / 2). "zoom" is the
## lens angle range that lands inside the band from the usual distance (the lens goes 45 down to 12).
##   subject       radius  usual d  size_frac there  band          score there  d_in (45)   zoom at usual d
##   nut-crab      0.30     3.0 m   0.243            0.42-0.69     5.8          1.75 m     16.6-26.9 deg
##   gear-beetle   0.26     3.0 m   0.210            0.36-0.59     5.8          1.76 m     16.8-27.2 deg
##   spring-hopper 0.22     3.0 m   0.178            0.30-0.49     5.9          1.78 m     17.1-27.5 deg
##   spark-moths   0.85     9.0 m   0.229            0.40-0.66     5.7          5.20 m     16.4-26.7 deg
##   Bolt          0.72     5.0 m   0.351            0.60-0.99     5.9          2.99 m     16.7-27.3 deg
##   scrap snail   0.85     6.0 m   0.345            0.58-0.96     6.0          3.64 m     17.0-27.7 deg
##   tune-up       1.00     6.0 m   0.408            0.70-1.00     5.8          3.59 m     19.2-27.2 deg
##   big geyser    1.50     8.0 m   0.461            0.78-1.00     5.9          4.88 m     21.6-27.5 deg
##   ring rain     2.60    11.0 m   0.587            0.98-1.00     6.0          6.91 m     27.3-27.9 deg
##   sky whale     1.70    11.0 m   0.378            0.64-1.00     5.9          6.63 m     17.8-27.5 deg
##   great magnet  1.80     9.0 m   0.493            0.83-1.00     5.9          5.54 m     23.1-27.6 deg
## USUAL DISTANCE: 3 m for the three small creatures (the spec's floor; the wanderer's medians while
## photographable are crab 5.3, beetle 6.5, hopper 2.7 m - a scout comes up 3-5 m ahead and the
## wanderer walks on toward it, so at its own median 2.7 m a hopper scores 6.6); for the rest, the
## wanderer's median distance while each was photographable, rounded down to the metre, or the
## round-1 figure where that is nearer (stricter): round 2's medians (tools/ps_wanderer.gd `dists`, 60
## runs, phone frame, 2026-09-25) were moths 10.9, Bolt 7.0, snail 7.0, tune-up 7.9, geyser 8.0, rain
## 11.9, whale 11.7, magnet 9.2 m (48 samples: it is up 20 s on 1 day in 4). Ring Rain and the Magnet
## moved to the new medians: round 1's 10 m and 7 m (the old, sky-gazing wanderer) left them at 6.6.
## Radii are not changed: Q4's overlap proof was measured with them (re-run for this round: all three
## pairs still force a choice).
const BAND_CRAB := Vector2(0.42, 0.69)
const BAND_BEETLE := Vector2(0.36, 0.59)
const BAND_HOPPER := Vector2(0.30, 0.49)
const BAND_MOTHS := Vector2(0.40, 0.66)
const BAND_BOLT := Vector2(0.60, 0.99)
const BAND_SNAIL := Vector2(0.58, 0.96)
const BAND_TUNE := Vector2(0.70, 1.00)
const BAND_GEYSER := Vector2(0.78, 1.00)
const BAND_RAIN := Vector2(0.98, 1.00)
const BAND_WHALE := Vector2(0.64, 1.00)
const BAND_MAGNET := Vector2(0.83, 1.00)

# ------------------------------------------------------------------------------ crabs
const CRAB_PER_PLACE := 3
## How far round from its place's centre a burrow may be (degrees; 1 degree = 0.18 m). (2.5-9 was
## tried in R4 round 2: no change in the density band beyond the run-to-run spread, so kept.)
const CRAB_SPREAD_DEG := Vector2(4.0, 17.0)
const CRAB_RUSH_M := 3.2          # closer than this while walking faster than CRAB_RUSH_SPEED = rushed
const CRAB_RUSH_SPEED := 0.6
const CRAB_TOO_CLOSE_M := 1.1     # this close and not still with the camera up = rushed
const CRAB_NOTICE_M := 6.5        # a hidden crab only waits for you inside this range
const CRAB_STILL_SEC := 1.0       # stand still with the camera up this long and one peeks
const CRAB_FOR_YOU_SEC := 8.0     # "came out to see you" lasts this long
const CRAB_SINK_IN := 0.44
const CRAB_SINK_PEEK := 0.20
enum CrabState { OUT, HIDE, IN, PEEK, CREEP, FLOAT }

# ------------------------------------------------------------------------------ beetles
const BEETLE_SCALE := 1.35
const BEETLE_CLIMB := 0.28        # m/s up and down the pole
const BEETLE_EMERGE_SEC := 0.5    # climbing back out of its gear after keeping out of sight (SHY_SEC)
enum BeetleState { BASE, UP, RIDE, DOWN, FLY, HOVER, SETTLE, CRAWL, GONE }

# ------------------------------------------------------------------------------ spring-hoppers
## The spring-hoppers live under the deck plates all over the planet and come up as SCOUTS (below).
## The code can also let TROUPES roam the surface: HOPPER_TROUPES little families of HOPPER_PER_TROUPE,
## each following its own slowly wandering point (HOPPER_TROUPE_SPEED) round the sphere. It is 0: every
## surface population tried made the planet too common by the band (spec 11.2b; wanderer, 20 runs each,
## median time between new encounters): 46 sprinkled over the sphere (R4 round 1) 7.2 s, 18 sprinkled
## 5.5 s, 12 sprinkled 5.7 s, two troupes of 3 6.7 s; with the scouts alone 10.2 s, and adding one troupe
## back dropped it to 8.6 s.
const HOPPER_TROUPES := 0
const HOPPER_PER_TROUPE := 3
## THE CURIOUS ONES - what the shared pacing director brings (SafariWorld.Pacing; spec 11.2, 13.2). When
## you have gone Pacing.AFTER_SEC (12 s) with nothing clearly in view, the director asks one of three
## bringers to come out where you are looking; each is a creature of this yard with its own way in:
##   SPRING-HOPPER  (HOPPER_SCOUTS) springs up out of the deck a few metres ahead (boing), hops about near
##                  there; when you look over the deck (the horizon, the sky) it does a BIG BOING up into
##                  the view instead (SCOUT_SKY_M).
##   NUT-CRAB       (CRAB_SCOUTS) pushes up a loose deck plate and creeps out of it; it behaves like any
##                  crab after (rush it and it dives back in). Ground spots only.
##   GEAR-BEETLE    (BEETLE_SCOUTS) whirs in from above on its spinning cog like a little rotor and lands;
##                  when you look over the deck it HOVERS in the view a while first.
##                  Walk right at it and it whirs off.
##   SPARK-MOTHS    (BOLTC, night only) a swarm gathers out of the dark in the air far out where you look
##                  (MOTH_SCOUT_M).
##   BOLT           (BOLT2, 2026-09-26) comes over with a puff to see what you are photographing, stands
##                  BOLT_STAY_SEC looking where you look, then wanders on (_bring_bolt; Fen's and Zorp's way).
## Each creature goes back once it has been out SCOUT_OUT_MIN_SEC and you have left it SCOUT_DOWN_M behind, out of
## view (a hopper under the deck, a crab under its plate, a beetle off into the sky). The director picks
## which (Pacing._pick_order): the one with the smallest share of your photos so far, never over 30% when
## another can come - R4's hopper-only director was 32 of the careful player's 58 photos (spec 13.1).
## THE DIRECTOR's own rules and numbers (the strict "in view" test, the lens-steady rule, "creature
## ahead", the retry, the clearances, ONE NEW THING AT A TIME with its SHY_SEC) are Pacing's, and its
## defaults ARE the numbers R4 measured here; this file only answers `places` (_creature_places) and
## reads `pacing.shy(id)` / `pacing.in_view`. ONE NEW THING AT A TIME, as it plays out here: after you
## come upon something new, the shy creatures (crabs, beetles, moths, the curious ones) that are out of
## the frame (grown by SHY_FRAME_GROW, so none is seen to go) duck away for Pacing.SHY_SEC and come out
## again where you can see them do it. Timed events and Bolt are never held back.
## WHY BOLT IS A FOURTH BRINGER (BOLT2, 2026-09-26, measured): with only the three creatures, the careful
## player's photos were 86% brought ones (60 of 70, seeds 841-848), so the pooled top share is about a
## third of 86% plus noise: gear-beetle 23/70 = 32.9% on those seeds (the director's 7 seeds: 28.6%),
## over the 30% cap of spec 14.2. No split of three can hold it; a fourth bringer can.
const HOPPER_SCOUTS := 3
const CRAB_SCOUTS := 2
const BEETLE_SCOUTS := 2
const SHY_FRAME_GROW := 1.1
const SCOUT_OUT_MIN_SEC := 12.0
const SCOUT_DOWN_M := 5.0
const SCOUT_POP_SEC := 0.45
## LOOKING OVER THE DECK (R4 round 3). On this little world the horizon is 25 degrees BELOW level from
## the eye, and the lens is 45 degrees tall: from about 10 degrees below level upward, no ground spot
## is in the middle of the frame (Pacing hands the bringers a "dir" of ZERO). Then a hopper comes up
## SCOUT_SKY_M ahead and does a BIG BOING: up into the middle of the view, SCOUT_BIG_SPARE above the
## height that first reaches it (so it is in view for the top ~60% of the hop), at most SCOUT_BIG_MAX_M
## (about +20 degrees of pitch at 3 m). The same spring and pull as its little hops (air time grows with
## the square root of the height: 1.0 s for 1.6 m). A scout out and not yet seen boings again every
## SCOUT_BIG_EVERY_SEC while you look over it ("look at me"). Kept from R4 rather than Pacing's "rise":
## these are the distances and leads the density band was measured with.
const SCOUT_SKY_M := [3.2, 2.7, 3.8]
const SCOUT_POP_YAW := [0.0, 8.0, -8.0, 16.0, -16.0]
const SCOUT_BIG_SPARE := 0.45
const SCOUT_BIG_MAX_M := 2.3
const SCOUT_BIG_EVERY_SEC := 1.6
## A big boing's top is judged SCOUT_LEAD_BIG_SEC after the pop, and a sitting scout's "look at me"
## boing's top SCOUT_LEAD_SIT_SEC after it crouches (the lens then, walking on as you are).
const SCOUT_LEAD_BIG_SEC := 1.1
const SCOUT_LEAD_SIT_SEC := 0.6
## A curious crab is braver than the ones at the vents: it only dives back under its plate when you walk
## at it inside this (the hoppers' HOPPER_SHY_M) - it comes up a few metres ahead of a walker, and at
## CRAB_RUSH_M it would be gone before it was out.
const CRAB_SCOUT_RUSH_M := 2.2
## A crab's loose deck plate lifts over this long as it pushes up.
const CRAB_PLATE_SEC := 0.3
## LOOKING OVER THE DECK a curious crab comes up on a JET OF STEAM out of its plate (nut-crabs live in the
## vents) and bobs on top of it like a ball on a fountain, in the middle of the view: up over
## CRAB_FLOAT_UP_SEC to the height a hopper's big boing would need (_scout_sky_spot) plus CRAB_FLOAT_SPARE, CRAB_FLOAT_SEC
## there, then the jet stops and it drops (the hoppers' pull: air time grows with the square root of
## the height) and scuttles about. Feel picks, stated. NOT a moment (nor is a beetle's hover): the
## director brings these when it has gone quiet, so they come often and pay nothing extra - a moment is
## earned (a crab that came out to see you, a beetle riding a gear), spec 13.1's calibration.
const CRAB_FLOAT_UP_SEC := 0.55
const CRAB_FLOAT_SEC := 2.4
const CRAB_FLOAT_SPARE := 0.2
## The steam jet's pull (m/s^2, down its own axis): light, so it climbs to the crab.
const CRAB_STEAM_PULL := 2.0
## The beetle's flight: it comes DOWN from BEETLE_FLY_FROM above its spot (x: a little to one side of
## the lens, y: up) over BEETLE_FLY_SEC, onto a spot the lens can see (a first try came in from 2.4 m to
## the side and could pass behind a crate: the director counted it seen for one 0.2 s look while the
## wanderer never did - seed 2, night, 2026-09-25). Looking over the deck it hovers BEETLE_HOVER_SEC up
## in the view first. It settles over BEETLE_LAND_SEC, then crawls about. Walk at it faster than BEETLE_SHY_SPEED inside
## BEETLE_SHY_M and it whirs off. Its cog spins BEETLE_ROTOR rad/s while it flies. Feel picks, stated.
const BEETLE_FLY_FROM := Vector2(0.35, 2.2)
const BEETLE_FLY_SEC := 1.3
const BEETLE_HOVER_SEC := 3.0
const BEETLE_HOVER_SPARE := 0.25
## How high a curious beetle may hover when the lens looks UP (round 2 of the critic, seed 35 day: the
## wanderer looked 32-38 degrees up for 8 s at t=44.9-52.2, no hop or steam jet up to SCOUT_BIG_MAX_M
## reached the view, and the director could bring nothing for 21.0 s). A beetle flies, so it is not held
## to a hop's height: up to this it hovers in the middle of a skyward view. 3.6 m reaches the middle of
## the view for a lens up to about 45 degrees (1.09 m eye, 0.5 m of the deck's curve at 3.2 m).
const BEETLE_HOVER_MAX_M := 3.6
const BEETLE_LAND_SEC := 0.7
const BEETLE_CRAWL := 0.12
const BEETLE_SHY_M := 1.6
const BEETLE_SHY_SPEED := 0.6
const BEETLE_ROTOR := 28.0
const HOPPER_N := HOPPER_TROUPES * HOPPER_PER_TROUPE + HOPPER_SCOUTS
const HOPPER_RANGE_DEG := 7.0
const HOPPER_TROUPE_SPEED := 0.35
## Where each troupe sets off from, as (degrees round from the start, bearing): out of sight of the start.
const HOPPER_TROUPE_FROM := [Vector2(75.0, -30.0), Vector2(115.0, 150.0)]
const HOPPER_HOP_M := Vector2(0.55, 1.05)
const HOPPER_HOP_H := 0.34
const HOPPER_AIR_SEC := 0.46
const HOPPER_SIT_SEC := Vector2(0.7, 2.6)
const HOPPER_CROUCH_SEC := 0.14
const HOPPER_LAND_SEC := 0.16
## Walk at one faster than HOPPER_SHY_SPEED inside HOPPER_SHY_M and it boings away from you.
const HOPPER_SHY_M := 2.2
const HOPPER_SHY_SPEED := 0.6
## Stand still with the camera up inside HOPPER_HELLO_M for HOPPER_HELLO_STILL s and the nearest one
## turns to you and bounces hello for HOPPER_HELLO_SEC s (then not again for HOPPER_HELLO_REST s).
const HOPPER_HELLO_M := 5.5
const HOPPER_HELLO_STILL := 0.8
const HOPPER_HELLO_SEC := 3.5
const HOPPER_HELLO_REST := 6.0
## Kept this far from the rocket's pad (it is not a prop, so nearest_prop_distance does not see it).
const HOPPER_PAD_CLEAR_DEG := 15.0
enum HopState { SIT, CROUCH, AIR, LAND, HELLO, GONE, POP }

const MOTH_PER_SWARM := 7
## THE DIRECTOR BRINGS SPARK-MOTHS at night (spec 16: "register the spark-moth as a night bringer"; builder
## BOLTC). One more swarm of MOTH_PER_SWARM, the SCOUT SWARM, gathers out of the dark where you are
## looking - a flier, so it comes in the AIR, MOTH_SCOUT_M along the lens (farthest first), MOTH_SCOUT_LIFT
## above the deck under it, with a clear line of sight. It comes that far out, not 3-5 m like the others,
## because a swarm is big (radius 0.85): the size rule (spec 11.1) wants 6 or less at its usual distance,
## and BAND_MOTHS gives 5.7 at 9 m, 7.2 at 8 m (at 4 m it would be a free 10). Looking down at the deck
## no air spot that far is in view, and it gives way to the others. It stays SCOUT_OUT_MIN_SEC, then goes
## off into the dark once it is out of the frame. Its moths are the same herd (no new draw call).
const MOTH_SCOUT_M := [9.0, 8.5, 9.5, 8.0]
const MOTH_SCOUT_YAW := [0.0, 7.0, -7.0]
const MOTH_SCOUT_LIFT := Vector2(1.2, 6.5)
## BOLT POSES ON HIS OWN RHYTHM (spec 16: "his pose-on-aim makes him an easy Gallery even for the careless
## player (9 of 9 careless Galleries were Bolt) - pose on his own wave or with a cooldown"; builder BOLTC).
## He no longer strikes a pose because a camera points at him. While you are within BOLT_POSE_NEAR_M he
## poses every BOLT_POSE_EVERY seconds (a fresh random wait each time), for BOLT_POSE_SEC, turning to you -
## and the first one comes BOLT_POSE_FIRST after you come within range, never the moment you arrive. A
## photo in that 1.8 s is a Gallery; to get one you wait for him, or are lucky. Feel picks, stated.
const BOLT_POSE_NEAR_M := 7.0
const BOLT_POSE_EVERY := Vector2(9.0, 14.0)
const BOLT_POSE_FIRST := Vector2(4.0, 9.0)
const BOLT_POSE_SEC := 1.8
## SafariLayer.intro_hint shows its control hint for 4.5 s on a phone (5.0 on a desktop).
const INTRO_HINT_SEC := 5.1
## Bolt's distance from the mast's axis at its foot and at the top of his climb (the tripod apex is
## 1.1 m up and its legs splay 0.55 m).
const MAST_OFF_GROUND := 0.75
const MAST_OFF_TOP := 0.45
## How high his feet climb (times the mast's scale). See _build_tune_up: the dish.
const MAST_CLIMB_M := 0.6

# ------------------------------------------------------------------------------ sights and bonus (spec 15.5)
## THE SCRAPBOOK'S NEW PAGES (spec 15.5; builder BOLTC, 2026-09-26). Two SIGHTS (always there, rarity 1,
## they pay as usual) and three BONUS things (small, tucked away, a collector's page: they pay nothing).
## Neither kind counts toward the density band or the pacing director (safari_world.gd CATEGORY), so
## none of them is in `_creature_places` either, and nothing curious is brought up inside the two things
## built here (_near_built).
##   THE ANTENNA MAST   Antenna Hill's big mast (a real prop; the tune-up and the night moths are there).
##                      Scored on a sphere round the whole mast, no front (a mast has no face).
##   BOLT'S WORKSHOP    built here: a striped lean-to with his bench, tools and a half-mended spring-hopper,
##                      WORKSHOP_RING_DEG round from his home spot, clear of props and of the snail's roads,
##                      its open front turned toward the start. Front = the open side.
##   A LOST SOCK        snagged on the arm of SOCK_PIPE (behind the start, left), swaying in the steam.
##   "BOLT No. 1"       a giant bolt on a plinth, out behind a radiator on the far side (P_BOLT_NO_1).
##                      Front = its plaque.
##   A WELDED SMILEY    on the side of SMILEY_CRATE that faces AWAY from the start: walk round it. Front =
##                      the smiley.
## NOTHING HERE EXISTS OUTSIDE A SAFARI (the user's rule 5; worlds/ files cannot change the planet): the
## workshop, the plinth, the sock and the smiley are built with the rest and freed with it. They stay up
## through the last puff (no puff of their own: `awake` is false once asleep) and go behind the black fade.
## The workshop and the plinth block the player (and sight rays) with a box/cylinder on the NPC layer
## (1 << 2): the player collides with it and Bolt does not, so he never grinds against his own bench
## while he wanders (npc.gd has no veto for a resident's wander target).
## SIZE BANDS by the rule of SIZE BANDS above (6 or less at the usual distance at 45 degrees), the usual
## distance being where a curious wanderer first frames it:
##   subject          radius   usual d  size_frac there  band         d_in (45)
##   antenna mast     1.55 s    8.0 m   0.475            0.84-1.00    4.6 m
##   workshop         1.15      6.0 m   0.472            0.83-1.00    3.4 m
##   lost sock        0.15      2.5 m   0.145            0.26-0.45    1.4 m
##   "Bolt No. 1"     0.72      5.0 m   0.351            0.62-0.95    2.9 m
##   welded smiley    0.20      3.0 m   0.162            0.29-0.50    1.7 m
const WORKSHOP_RING_DEG := [14.0, 17.0, 20.0, 23.0]
const WORKSHOP_PROP_CLEAR_M := 1.55
const WORKSHOP_ROAD_CLEAR_M := 1.9
const WORKSHOP_RADIUS := 1.15
const P_BOLT_NO_1 := Vector2(148.0, 140.0)
const SOCK_PIPE := "Pipe0"
## The sock hangs this far out along the pipe's arm from its axis (outside the pipe's 0.25 m collider).
const SOCK_OUT_M := 0.36
const SMILEY_CRATE := "Crate1"
## No curious one is brought closer than this to the workshop's or the plinth's footprint.
const BUILT_CLEAR_M := 0.8
const BAND_MAST := Vector2(0.84, 1.00)
const BAND_WORKSHOP := Vector2(0.83, 1.00)
const BAND_SOCK := Vector2(0.26, 0.45)
const BAND_BOLT_NO_1 := Vector2(0.62, 0.95)
const BAND_SMILEY := Vector2(0.29, 0.50)

# ------------------------------------------------------------------------------ state
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}

var _far := Vector3.UP
var _geyser_dir := Vector3.UP
var _geyser_dirs: Array[Vector3] = []
var _vent_field := Vector3.UP
var _crab_places: Array[Vector3] = []
var _rain_dir := Vector3.UP
var _rain_dirs: Array[Vector3] = []
var _magnet_dir := Vector3.UP
var _antenna: Node3D
var _antenna_dir := Vector3.UP
var _antenna_s := 1.0
var _home_dir := Vector3.UP
var _snail_a := Vector3.UP
var _snail_b := Vector3.UP
var _snail_c := Vector3.UP
var _pad_dir := Vector3.UP

var _crab_herd: Herd
var _burrow_herd: Herd
var _crab_steam: CPUParticles3D
var _crabs: Array = []
var _crab_focus: Node3D
var _crab_pick := -1

var _beetle_herd: Herd
var _beetles: Array = []
var _beetle_focus: Node3D
var _beetle_pick := -1

var _hop_herd: Herd
var _hoppers: Array = []
var _troupes: Array = []          # per troupe: {c: its wandering point, heading, turn: s to the next turn}
## The shared pacing director (SafariWorld.Pacing), made in `build`.
var pacing: Pacing
var _hop_focus: Node3D
var _hop_pick := -1
var _hop_still := 0.0
var _hop_hello_next := 0.0
var _boing_next := 0.0

var _moth_herd: Herd
var _moth_focus: Node3D
var _moth_centre := Vector3.ZERO
var _moth_centres: Array[Vector3] = []
var _moth_pick := -1
var _moth_heads: Array[Vector3] = []
var _moth_pos: Array[Vector3] = []
var _moth_scatter := PackedFloat32Array()

var _whale: Node3D
var _whale_tail: Node3D
var _whale_spout: CPUParticles3D
var _spout_h := PackedFloat32Array()
var _whale_song: AudioStreamPlayer
var _whale_song_next := 0.0

var _geyser: Node3D
var _geyser_at := -1
var _geyser_core: MeshInstance3D
var _geyser_jet: CPUParticles3D
var _geyser_focus: Node3D
var _geyser_whistle: AudioStreamPlayer
var _puff_clock := 0.0

var _rain_root: Node3D
var _rain_at := -1
var _rain_fall: CPUParticles3D
var _rain_heavy: CPUParticles3D
var _rain_glitter: CPUParticles3D
var _rain_focus: Node3D
var _glints: Array[MeshInstance3D] = []
var _glint_mat: ShaderMaterial
var _chime_clock := 0.0
var _ring_n := Vector3.UP
var _ring_c := Vector3.ZERO
var _ring_r := 24.0

var _magnet_root: Node3D
var _magnet: MeshInstance3D
var _scrap_herd: Herd
var _scrap: Array = []
var _magnet_focus: Node3D
var _hum: AudioStreamPlayer

var _snail: Node3D
var _snail_shell: MeshInstance3D
var _snail_body: MeshInstance3D
var _snail_whistle: AudioStreamPlayer
var _snail_order: Array = []
var _bell_clock := 0.0

var _bolt: Node3D
var _bolt_saved := Transform3D()
var _bolt_wander_saved := true
var _bolt_borrowed := false
var _bolt_mast := -1
var _bolt_wave_until := -1.0
var _bolt_pose_until := -1.0
var _bolt_next_wave := 0.0
var _bolt_next_pose := 0.0
var _bolt_came_at := -INF
var _bolt_came_n := 0
var _bolt_stay_until := -INF
var _tune_focus: Node3D
var _sparks: CPUParticles3D
var _masts: Array = []            # per mast: {node, s, base, side, up, face}
var _bolt_base := Transform3D()
var _bolt_on_mast := false
var _mast_side := Vector3.RIGHT
var _mast_up := Vector3.UP
var _bolt_face := Vector3.FORWARD
var _mast_off_top := MAST_OFF_TOP
var _mast_top := 1.0

var _bolt_pose_near := false
var _moth_scout := -1             # the scout swarm's slot in _moth_centres (-1: no moths tonight)
var _moth_scout_on := false
var _moth_scout_since := -INF
var _mast_focus: Node3D
var _workshop: Node3D
var _workshop_dir := Vector3.ZERO
var _plinth: Node3D
var _plinth_dir := Vector3.ZERO
var _sock: Node3D
var _sock_focus: Node3D
var _smiley: Node3D
var _beacons: Dictionary = {}     # event KIND -> MeshInstance3D (one glow per kind, moved per run)
var _lines: Array = []            # [due time, text] for the one banner
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []
var _metal: ShaderMaterial
var _prop_mat: ShaderMaterial


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 5_0921_37
	_metal = PlanetPropMeshes.metal_material()
	_prop_mat = PlanetPropMeshes.prop_material()
	_find_places()
	_build_crabs()
	_build_beetles()
	_build_hoppers()
	_build_bolt()
	_build_whale()
	_build_geyser()
	_build_rain()
	_build_snail()
	_build_tune_up()
	if safari.is_rare_day:
		_build_magnet()
	if safari.is_night:
		_build_moths()
	_build_sights()
	_build_bonus()
	_build_pacing()
	_register_events()
	_building = true
	tick(0.0, 0.0)
	_building = false
	_log("built: far=%s geyser=%s vent=%s rain=%s magnet=%s antenna=%s snail %s -> %s rare=%s night=%s" % [
		_pp(_far), _pp(_geyser_dir), _pp(_vent_field), _pp(_rain_dir), _pp(_magnet_dir), _pp(_antenna_dir),
		_pp(_snail_a), _pp(_snail_b), str(safari.is_rare_day), str(safari.is_night)])
	_log("R4 places: geysers %s rains %s snail road 2 %s -> %s crabs %d at %s hoppers %d beetles %d" % [
		str(_geyser_dirs.map(_pp)), str(_rain_dirs.map(_pp)), _pp(_snail_c), _pp(_snail_a),
		_crabs.size(), str(_crab_places.map(_pp)), _hoppers.size(), _beetles.size()])


## THE SHARED PACING DIRECTOR (SafariWorld.Pacing; spec 13.2) with this yard's curious ones as its
## bringers (see THE CURIOUS ONES; the spark-moths at night, MOTH_SCOUT_M). Its tunables stay at their
## defaults: they are R4's measured numbers.
func _build_pacing() -> void:
	pacing = Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	pacing.places = _creature_places
	# DENSITY MARGIN (spec 16: "give the density band some margin (it was exactly 9/10)"; builder BOLTC). A
	# bring the wanderer never sees (a crab that pushes up behind a crate, a hopper that boings where the eyes
	# have already moved on) used to cost RETRY_SEC 3 s before the next try: the worst stretch of 30 runs
	# (18.8 s, seed 2 night) was one such miss (13.7 s quiet, then 4.5 s more). 2 s here.
	pacing.RETRY_SEC = 2.0
	pacing.add_bringer({"id": "spring_hopper", "bring": _bring_hopper,
		"ready": func() -> bool: return _free_scout_hopper() != null})
	pacing.add_bringer({"id": "nut_crab", "bring": _bring_crab,
		"ready": func() -> bool: return _free_scout_crab() != null})
	pacing.add_bringer({"id": "gear_beetle", "bring": _bring_beetle,
		"ready": func() -> bool: return _free_scout_beetle() != null})
	pacing.add_bringer({"id": "bolt", "bring": _bring_bolt, "ready": _bolt_can_come})
	# at night, the spark-moths too (spec 16; see MOTH_SCOUT_M)
	if _moth_scout >= 0:
		pacing.add_bringer({"id": "spark_moth", "bring": _bring_moths,
			"ready": func() -> bool: return not _moth_scout_on and not _sleeping})


func _find_places() -> void:
	var p := safari.planet
	_pad_dir = p.data.pad_dir.normalized() if p.data != null else safari.start_dir
	_geyser_dir = _free_near(safari.dir_from_start(P_GEYSER.x, P_GEYSER.y), 1.0)
	_geyser_dirs = [_geyser_dir]
	for g: Vector2 in P_GEYSER_MORE:
		_geyser_dirs.append(_free_near(safari.dir_from_start(g.x, g.y), 1.2))
	# The Sky Whale circles over the geyser's ANTIPODE (162 degrees round from the start, still the far
	# side): the two share their best moment, and 180 degrees is the most a walk between them can be.
	_far = -_geyser_dir
	_vent_field = safari.dir_from_start(P_VENT_FIELD.x, P_VENT_FIELD.y)
	for c: Vector2 in P_CRAB_PLACES:
		_crab_places.append(safari.dir_from_start(c.x, c.y))
	# Ring Rain falls where the ring is straight overhead (the planet's great circle in the ring's
	# plane), at the point of that circle nearest the Gear Grove; the Magnet is on the same circle, on
	# the other side (the nearest clear spot to the antipode).
	var grove := safari.dir_from_start(P_GEAR_GROVE.x, P_GEAR_GROVE.y)
	var ring := safari.world.get_node_or_null("Environment/Ring") as Node3D
	var n := ring.global_transform.basis.y.normalized() if ring != null else Vector3.UP
	_ring_n = n
	var proj := grove - n * grove.dot(n)
	var rain0 := proj.normalized() if proj.length() > 0.01 else grove
	# The pair is kept EXACTLY antipodal (180 degrees: a walk between them is 33 m, 22 s) and slid
	# together round the circle, nearest first, until the Magnet's hatch has a clear spot.
	_rain_dir = rain0
	_magnet_dir = -rain0
	for k in range(0, 17):
		var found := false
		for sgn in [1.0, -1.0]:
			var r := rain0.rotated(n, deg_to_rad(2.5 * float(k)) * sgn).normalized()
			if p.nearest_prop_distance(-r) >= 1.1:
				_rain_dir = r
				_magnet_dir = -r
				found = true
				break
		if found:
			break
	# Ring Rain's other spot(s): the same circle, RAIN_SPOT_DEG round from the first.
	_rain_dirs = []
	for deg: float in RAIN_SPOT_DEG:
		_rain_dirs.append(_rain_dir.rotated(n, deg_to_rad(deg)).normalized())
	# Antenna Hill: the named antenna, else the antenna farthest from the start.
	_antenna = p.get_node_or_null("Props/" + ANTENNA_NAME) as Node3D
	if _antenna == null:
		var best := -1.0
		for c in p.get_node("Props").get_children():
			if str(c.name).begins_with("Antenna"):
				var a := safari.start_dir.angle_to(p.dir_of((c as Node3D).global_position))
				if a > best:
					best = a
					_antenna = c
	if _antenna != null:
		_antenna_dir = p.dir_of(_antenna.global_position)
		var mi := _antenna.get_node_or_null("Mesh") as Node3D
		_antenna_s = mi.scale.x if mi != null else 1.0
	# The snail's roads: its paired crossing ends at the clearest spot near the antipode of Antenna Hill
	# (so the snail's finale and his tune-up are 180 degrees apart; Q4), and starts where its two
	# crossings meet (_pick_snail_meet).
	var bolt := safari.world.get_node_or_null("NPCs/bolt")
	_home_dir = (bolt.get("home_dir") as Vector3).normalized() if bolt != null else safari.dir_from_start(60.0, 67.0)
	_pick_snail_road()
	_pick_snail_meet()
	_pick_snail_road_home()


## The END of the snail's paired crossing (Q4's, unchanged): within 12 degrees of the antenna's
## antipode, the clearest straight road from 1.8 m off Bolt's home spot. The road's start (_snail_a) is
## then moved to where the two crossings meet (_pick_snail_meet); only this end matters to Q4's proof.
func _pick_snail_road() -> void:
	var p := safari.planet
	var anti := -_antenna_dir
	var t1 := anti.cross(_home_dir).normalized()
	var t2 := anti.cross(t1).normalized()
	var best_score := -INF
	for oa in [0.0, 6.0, -6.0, 12.0, -12.0]:
		for ob in [0.0, 6.0, -6.0, 12.0, -12.0]:
			var e := anti.rotated(t1, deg_to_rad(oa)).rotated(t2, deg_to_rad(ob)).normalized()
			var a := p.step_dir(_home_dir, e, 1.8)
			var clear := _road_clearance(a, e)
			var score := minf(clear, 1.2) - 0.02 * (absf(oa) + absf(ob))
			if score > best_score:
				best_score = score
				_snail_a = a
				_snail_b = e
	_log("snail road clearance score %.2f" % best_score)


## Every other place on the planet (Bolt's home, the crab places, the beetles' trees, both masts, the
## pad and the start, the rain spots, the geyser vents, the far side): the snail's roads keep away from
## them, so it is met on its own (spec 11.2b) and not together with something else.
func _other_places() -> Array[Vector3]:
	var p := safari.planet
	var out: Array[Vector3] = [_home_dir, _antenna_dir, _pad_dir, safari.start_dir, _far]
	out.append_array(_crab_places)
	out.append_array(_rain_dirs)
	out.append_array(_geyser_dirs)
	for grove: Array in GROVES:
		for nm: String in grove:
			var t := p.get_node_or_null("Props/" + nm) as Node3D
			if t != null:
				out.append(p.dir_of(t.global_position))
	for nm: String in MASTS:
		var m := p.get_node_or_null("Props/" + nm) as Node3D
		if m != null:
			out.append(p.dir_of(m.global_position))
	return out


## Degrees from `d` to the nearest of `places`.
func _deg_to_nearest(d: Vector3, places: Array[Vector3]) -> float:
	var best := 180.0
	for q: Vector3 in places:
		best = minf(best, rad_to_deg(d.angle_to(q)))
	return best


## Where the snail's two crossings meet (R4 round 2): the paired crossing (Q4's) now sets off from here
## to the crates, and the first crossing ends here. Of the spots 50-66 degrees out from the crates, the
## one farthest from every other place (capped at 40 degrees), with a clear road to the crates. (Round 1
## met at Bolt's home spot: Bolt and the snail came on screen together - 18 of the wanderer's 347
## encounters in 20 runs came as that pair within 8 s.) Only the road's START moves: the crates, the
## whistle there and Q4's overlap proof (measured at the road's end) are unchanged.
func _pick_snail_meet() -> void:
	var places := _other_places()
	var t0 := _tangent_at(_snail_b)
	var best_score := -INF
	for rho: float in [50.0, 58.0, 66.0]:
		for k in 24:
			var x := _polar(_snail_b, t0, rho, 15.0 * float(k))
			var clear := _road_clearance(x, _snail_b)
			if clear < 0.6:
				continue
			var score := minf(_deg_to_nearest(x, places), 40.0) + 10.0 * minf(clear, 1.2)
			if score > best_score:
				best_score = score
				_snail_a = x
	_log("snail meets at %s (%.0f deg from the nearest other place)" % [_pp(_snail_a), _deg_to_nearest(_snail_a, places)])


## The snail's FIRST crossing (R4): from a spot about 55 degrees out to where the paired crossing
## starts (_snail_a), so it arrives there and later sets off again from the same spot. Of the spots
## 45-65 degrees out from _snail_a, the road that starts at least 70 degrees from the start (away from the busy
## pad) and at least 60 degrees from the crates (its other road's end), scored like _pick_snail_meet.
func _pick_snail_road_home() -> void:
	var places := _other_places()
	var t0 := _tangent_at(_snail_a)
	var best_score := -INF
	_snail_c = _polar(_snail_a, t0, 55.0, 0.0)
	for rho: float in [45.0, 55.0, 65.0]:
		for k in 24:
			var c := _polar(_snail_a, t0, rho, 15.0 * float(k))
			if rad_to_deg(c.angle_to(safari.start_dir)) < 70.0 or rad_to_deg(c.angle_to(_snail_b)) < 60.0:
				continue
			var clear := _road_clearance(c, _snail_a)
			if clear < 0.6:
				continue
			var score := minf(_deg_to_nearest(c, places), 40.0) + 10.0 * minf(clear, 1.2)
			if score > best_score:
				best_score = score
				_snail_c = c
	_log("snail road 1 from %s (%.0f deg from the nearest other place)" % [_pp(_snail_c), _deg_to_nearest(_snail_c, places)])


## The smallest prop clearance along the straight road a -> b (25 samples).
func _road_clearance(a: Vector3, b: Vector3) -> float:
	var p := safari.planet
	var clear := INF
	for i in range(0, 25):
		var d := a.slerp(b, float(i) / 24.0).normalized()
		clear = minf(clear, p.nearest_prop_distance(d))
	return clear


## `dir`, or the nearest spot round it at least `clear_m` from every prop.
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


## The nearest named place to `d` (for the warning lines of the repeated events).
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


## The world unit vector a node's face points along: every mesh here faces -Z.
func _front_of(n: Node3D) -> Vector3:
	if n == null or not is_instance_valid(n):
		return Vector3.ZERO
	return (-n.global_basis.z).normalized()


# ---------------------------------------------------------------------------------------- crabs
func _build_crabs() -> void:
	var p := safari.planet
	var pts: Array = []
	for place: Vector3 in _crab_places:
		var n0 := _crabs.size()
		var tries := 0
		while _crabs.size() < n0 + CRAB_PER_PLACE and tries < 400:
			tries += 1
			var rho := _rng.randf_range(CRAB_SPREAD_DEG.x, CRAB_SPREAD_DEG.y)
			var psi := _rng.randf_range(0.0, 360.0)
			var d := _polar(place, _tangent_at(place), rho, psi)
			if p.nearest_prop_distance(d) < 0.6 or p.ground_normal(d).angle_to(d) > deg_to_rad(7.0):
				continue
			var ok := true
			for c: Dictionary in _crabs:
				if p.surface_distance(d, c["burrow"]) < 1.3:
					ok = false
					break
			if not ok:
				continue
			var face := _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
			_crabs.append({"burrow": d, "dir": d, "face": face, "state": CrabState.OUT, "timer": _rng.randf_range(0.5, 2.5),
				"target": d, "sink": 0.0, "for_you": 0.0, "phase": _rng.randf_range(0.0, TAU), "peeked": false})
			pts.append(p.surface_point(d))
	# the curious ones (THE CURIOUS ONES): down under a loose deck plate until the director brings one
	for k in CRAB_SCOUTS:
		_crabs.append({"burrow": safari.start_dir, "dir": safari.start_dir, "face": safari.start_fwd,
			"state": CrabState.IN, "timer": 0.0, "target": safari.start_dir, "sink": CRAB_SINK_IN, "for_you": 0.0,
			"phase": _rng.randf_range(0.0, TAU), "peeked": false, "scout": true, "gone": true, "out_since": -INF,
			"plate": 0.0})
	# The culling boxes are the whole planet: a curious one can come up anywhere.
	var rr := p.radius + 1.5
	var area := AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0)
	# the burrows: one MultiMesh (one draw call for all of them), posed once (a curious one's plate is
	# posed when it comes up, and hidden when it has gone)
	_burrow_herd = Herd.new()
	add_child(_burrow_herd)
	_burrow_herd.setup("Burrows", _crabs.size(), [[Meshes.burrow(), _metal, false]], area)
	for i in _crabs.size():
		var c: Dictionary = _crabs[i]
		if bool(c.get("scout", false)):
			_burrow_herd.hide_one(i)
		else:
			_burrow_herd.pose(i, 0, _xf_ground(c["burrow"], c["face"]).translated_local(Vector3(0.0, -0.005, 0.0)))
	_crab_herd = Herd.new()
	add_child(_crab_herd)
	_crab_herd.setup("NutCrabs", _crabs.size(), [[Meshes.crab_body(), _metal, true], [Meshes.crab_claws(), _metal, false]],
		area)
	for i in _crabs.size():
		if bool(_crabs[i].get("scout", false)):
			_crab_herd.hide_one(i)
	# the jet of steam a curious crab rides up into the view on (warmed with the rest: built here)
	_crab_steam = _steam_emitter("CrabSteam", 30, 1.1, Color("#efe6d6"), 0.09)
	_crab_steam.spread = 6.0
	# a light pull, so the jet reaches up to the crab (its speed is set per ride in _bring_crab)
	_crab_steam.gravity = Vector3(0.0, -CRAB_STEAM_PULL, 0.0)
	_crab_steam.top_level = true
	add_child(_crab_steam)
	_crab_focus = Node3D.new()
	_crab_focus.name = "CrabFocus"
	add_child(_crab_focus)
	safari.add_subject({
		"id": "nut_crab", "name": "Nut-crab", "rarity": 1, "kind": "creature",
		"band": BAND_CRAB, "node": _crab_focus, "offset": Vector3(0.0, 0.16, 0.0), "radius": 0.30,
		"awake": func() -> bool: return _crab_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _crab_moment(),
		"front": func() -> Vector3: return _front_of(_crab_focus),
	})


func _crab_moment() -> Dictionary:
	if _crab_pick < 0:
		return {"mult": 1.0, "line": ""}
	var c: Dictionary = _crabs[_crab_pick]
	if int(c["state"]) == CrabState.OUT and float(c["for_you"]) > 0.0:
		return {"mult": 1.8, "line": "came out to see you"}
	if int(c["state"]) == CrabState.PEEK:
		return {"mult": 1.4, "line": "peeking out"}
	return {"mult": 1.0, "line": ""}


func _tick_crabs(delta: float) -> void:
	if _crab_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	var crab_shy := pacing.shy("nut_crab")
	for i in _crabs.size():
		var c: Dictionary = _crabs[i]
		var scout := bool(c.get("scout", false))
		if scout and bool(c["gone"]):
			continue
		var here := p.surface_point(c["dir"])
		var dist := here.distance_to(ppos)
		var rush_m := CRAB_SCOUT_RUSH_M if scout else CRAB_RUSH_M
		var rushed := (dist < rush_m and speed > CRAB_RUSH_SPEED) or (dist < CRAB_TOO_CLOSE_M and not still_up)
		if _sleeping:
			rushed = true
		c["for_you"] = maxf(float(c["for_you"]) - delta, 0.0)
		c["timer"] = float(c["timer"]) - delta
		var st: int = c["state"]
		# one new thing at a time (SHY_SEC): out of the frame, straight down its burrow; out again after
		if crab_shy and st != CrabState.IN and st != CrabState.FLOAT and not pacing.point_in_frame(here + p.up_at(here) * 0.16, SHY_FRAME_GROW):
			c["state"] = CrabState.IN
			c["sink"] = CRAB_SINK_IN
			c["for_you"] = 0.0
			c["shy"] = true
			st = CrabState.IN
		# a curious one that has been out a while, left behind and out of view: back under its plate
		var done := scout and _t - float(c["out_since"]) > SCOUT_OUT_MIN_SEC and dist > SCOUT_DOWN_M \
			and not pacing.point_in_frame(here, 1.2)
		if scout:
			_pose_plate(i, c, delta)
		match st:
			CrabState.FLOAT:
				_float_crab(c, here, delta)
			CrabState.OUT:
				if rushed or done:
					_crab_hide(c, here)
				else:
					if float(c["timer"]) <= 0.0:
						c["timer"] = _rng.randf_range(1.5, 3.2)
						c["target"] = _polar(c["burrow"], _tangent_at(c["burrow"]), _rng.randf_range(0.0, 5.0), _rng.randf_range(0.0, 360.0))
					_crab_walk(c, c["target"], 0.45, delta)
			CrabState.HIDE:
				var at := p.surface_distance(c["dir"], c["burrow"])
				if at > 0.05:
					_crab_walk(c, c["burrow"], 1.8, delta)
				else:
					c["sink"] = minf(float(c["sink"]) + 1.6 * delta, CRAB_SINK_IN)
					if float(c["sink"]) >= CRAB_SINK_IN:
						c["state"] = CrabState.IN
						c["timer"] = _rng.randf_range(2.0, 3.0)
						c["still"] = 0.0
			CrabState.IN:
				if _sleeping:
					pass
				elif done:
					c["gone"] = true
					c["shy"] = false
					_burrow_herd.hide_one(i)
				elif bool(c.get("shy", false)):
					# it kept out of sight while you looked at something new: out it creeps once that is over
					if not crab_shy:
						c["shy"] = false
						c["state"] = CrabState.CREEP
						c["timer"] = 1.6
						c["peeked"] = false
				elif dist < CRAB_NOTICE_M:
					c["still"] = (float(c.get("still", 0.0)) + delta) if still_up else 0.0
					if float(c["timer"]) <= 0.0 and float(c["still"]) >= CRAB_STILL_SEC:
						c["state"] = CrabState.PEEK
						c["timer"] = 1.1
						c["peeked"] = true
						AudioManager.play_sfx_at("ui_tick", here, -8.0)
				elif float(c["timer"]) <= 0.0:
					c["state"] = CrabState.CREEP
					c["timer"] = 1.6
					c["peeked"] = false
			CrabState.PEEK:
				c["sink"] = move_toward(float(c["sink"]), CRAB_SINK_PEEK, 1.2 * delta)
				_face_toward(c, ppos, delta)
				if rushed:
					_crab_hide(c, here)
				elif float(c["timer"]) <= 0.0:
					c["state"] = CrabState.CREEP
					c["timer"] = 1.6
			CrabState.CREEP:
				c["sink"] = move_toward(float(c["sink"]), 0.0, CRAB_SINK_PEEK / 1.6 * delta * (1.0 if float(c["sink"]) <= CRAB_SINK_PEEK else 3.0))
				if bool(c["peeked"]):
					_face_toward(c, ppos, delta)
				if rushed:
					_crab_hide(c, here)
				elif float(c["sink"]) <= 0.0:
					c["state"] = CrabState.OUT
					c["timer"] = _rng.randf_range(1.5, 3.0)
					if bool(c["peeked"]):
						c["for_you"] = CRAB_FOR_YOU_SEC
						AudioManager.play_sfx_at("emote_wave", here, -10.0)
		if int(c["state"]) == CrabState.OUT and float(c["for_you"]) > 0.0 and dist < CRAB_NOTICE_M:
			_face_toward(c, ppos, delta)
		_pose_crab(i, c)
		if bool(c.get("gone", false)):
			_crab_herd.hide_one(i)
	_crab_pick = _pick_focus(_crabs, func(c: Dictionary) -> bool: return float(c["sink"]) < CRAB_SINK_IN - 0.05 and not bool(c.get("gone", false)),
		func(c: Dictionary) -> Vector3: return p.surface_point(c["dir"]) + p.up_at(p.surface_point(c["dir"])) * float(c.get("air", 0.0)), 0.16)
	if _crab_pick >= 0:
		_crab_focus.global_transform = _xf(_crabs[_crab_pick]["dir"], _crabs[_crab_pick]["face"]) \
			.translated_local(Vector3(0.0, float(_crabs[_crab_pick].get("air", 0.0)) - float(_crabs[_crab_pick]["sink"]), 0.0))

## A curious crab's loose deck plate (its burrow instance): lifts in over CRAB_PLATE_SEC as it comes up.
func _pose_plate(i: int, c: Dictionary, delta: float) -> void:
	var f := float(c.get("plate", 1.0))
	if f >= 1.0 and bool(c.get("plate_set", false)):
		return
	f = minf(f + delta / CRAB_PLATE_SEC, 1.0)
	c["plate"] = f
	c["plate_set"] = f >= 1.0
	var xf := _xf_ground(c["burrow"], c["face"]).translated_local(Vector3(0.0, -0.005, 0.0))
	xf.basis = xf.basis * Basis.from_scale(Vector3.ONE * maxf(f, 0.05))
	_burrow_herd.pose(i, 0, xf)


## A curious crab that is down and free, or null.
func _free_scout_crab() -> Variant:
	for c: Dictionary in _crabs:
		if bool(c.get("scout", false)) and bool(c["gone"]):
			return c
	return null


## THE DIRECTOR BRINGS A NUT-CRAB (THE CURIOUS ONES): it pushes up a loose deck plate at the director's
## ground spot and creeps out, facing you. A ground spot only (looking over the deck it cannot).
func _bring_crab(spot: Dictionary) -> bool:
	var d: Vector3 = spot["dir"]
	var c: Variant = _free_scout_crab()
	if c == null:
		return false
	var float_h := 0.0
	if d == Vector3.ZERO:
		# looking over the deck: up on a jet of steam into the view (the hoppers' sky spot, for a crab)
		var sky := _scout_sky_spot(0.16, CRAB_FLOAT_SPARE, CRAB_FLOAT_UP_SEC)
		if sky.is_empty():
			return false
		d = sky[0]
		float_h = sky[1]
	if _near_built(d, BUILT_CLEAR_M):
		return false
	var cd: Dictionary = c
	cd["gone"] = false
	cd["burrow"] = d
	cd["dir"] = d
	cd["target"] = d
	cd["face"] = _toward(d, _player_dir())
	cd["state"] = CrabState.CREEP
	cd["sink"] = CRAB_SINK_IN
	cd["timer"] = 1.6
	cd["peeked"] = false
	cd["for_you"] = 0.0
	cd["shy"] = false
	cd["out_since"] = _t
	cd["plate"] = 0.0
	cd["plate_set"] = false
	cd["air"] = 0.0
	if float_h > 0.0:
		cd["state"] = CrabState.FLOAT
		cd["float_h"] = float_h
		cd["timer"] = CRAB_FLOAT_UP_SEC + CRAB_FLOAT_SEC
		cd["sink"] = 0.0
		var g := safari.planet.surface_point(d)
		_crab_steam.global_transform = Transform3D(_xf_ground(d, cd["face"]).basis, g)
		# just fast enough for the puffs to climb to the crab's feet against the pull (v^2 = 2 g h; the
		# emitter's drag stops them a little short), so the jet holds it up without hiding its face
		var v := sqrt(2.0 * CRAB_STEAM_PULL * float_h)
		_crab_steam.initial_velocity_min = v
		_crab_steam.initial_velocity_max = v + 0.25
		_crab_steam.restart()
		_crab_steam.emitting = true
		AudioManager.play_sfx_at("splash", g, -12.0, 0.15)
	AudioManager.play_sfx_at("rotate", safari.planet.surface_point(d), -8.0, 0.35)
	_log("curious crab pushes up at %s t=%.1f%s" % [_pp(d), _t, (" on steam %.2f m" % float_h) if float_h > 0.0 else ""])
	return true


## A curious crab riding its jet of steam (CrabState.FLOAT): up, bobbing there facing you, then down
## when the jet stops, and out on the deck.
func _float_crab(c: Dictionary, here: Vector3, delta: float) -> void:
	var h := float(c["float_h"])
	var left := float(c["timer"])
	var up_t := CRAB_FLOAT_SEC + CRAB_FLOAT_UP_SEC - left
	_face_toward(c, safari.player.global_position, delta)
	if up_t < CRAB_FLOAT_UP_SEC:
		var f := up_t / CRAB_FLOAT_UP_SEC
		c["air"] = h * (1.0 - (1.0 - f) * (1.0 - f))
	elif left > 0.0:
		c["air"] = h + 0.05 * sin(_t * 5.0 + float(c["phase"]))
		c["moving"] = 0.25
	else:
		# the jet stops: it drops with the hoppers' pull
		if _crab_steam.emitting:
			_crab_steam.emitting = false
		var fall_t := HOPPER_AIR_SEC * 0.5 * sqrt(maxf(h, 0.01) / HOPPER_HOP_H)
		var f := clampf(-left / fall_t, 0.0, 1.0)
		c["air"] = h * (1.0 - f * f)
		if f >= 1.0:
			c["air"] = 0.0
			c["state"] = CrabState.OUT
			c["timer"] = _rng.randf_range(1.0, 2.0)
			AudioManager.play_sfx_at("ui_tick", here, -10.0, 0.3)


func _crab_hide(c: Dictionary, here: Vector3) -> void:
	c["state"] = CrabState.HIDE
	c["for_you"] = 0.0
	AudioManager.play_sfx_at("rotate", here, -6.0, 0.2)


func _crab_walk(c: Dictionary, target: Vector3, speed: float, delta: float) -> void:
	var p := safari.planet
	var d: Vector3 = c["dir"]
	var dist := p.surface_distance(d, target)
	if dist < 0.02:
		return
	c["dir"] = p.step_dir(d, target, minf(speed * delta, dist))
	c["moving"] = 0.25


func _face_toward(c: Dictionary, world_pos: Vector3, delta: float) -> void:
	var d: Vector3 = c["dir"]
	var want := world_pos - safari.planet.surface_point(d)
	want -= d * want.dot(d)
	if want.length() < 0.01:
		return
	var cur: Vector3 = c["face"]
	cur -= d * cur.dot(d)
	c["face"] = cur.normalized().slerp(want.normalized(), clampf(5.0 * delta, 0.0, 1.0)).normalized()


func _pose_crab(i: int, c: Dictionary) -> void:
	var sink := float(c["sink"])
	if sink >= CRAB_SINK_IN - 0.001:
		_crab_herd.hide_one(i)
		return
	var ph := float(c["phase"]) + _t * 7.0
	var moving := float(c.get("moving", 0.0))
	c["moving"] = maxf(moving - get_process_delta_time(), 0.0)
	var bob := 0.015 * absf(sin(ph * 1.6)) * (1.0 if moving > 0.0 else 0.3)
	var base := _xf_ground(c["dir"], c["face"]).translated_local(Vector3(0.0, bob - sink + float(c.get("air", 0.0)), 0.0))
	_crab_herd.pose(i, 0, base)
	var wave := 0.35 + 0.35 * sin(ph * 0.6) if float(c["for_you"]) <= 0.0 else 0.9 + 0.5 * sin(_t * 9.0)
	_crab_herd.pose(i, 1, base * Transform3D(Basis(Vector3.RIGHT, wave * 0.6), Vector3(0.0, 0.12, -0.02)))




# ---------------------------------------------------------------------------------------- beetles
func _build_beetles() -> void:
	var p := safari.planet
	var trees: Array = []
	var per_tree: Array = []
	var grove_of: Array = []
	for gi in GROVES.size():
		for nm: String in GROVES[gi]:
			var t := p.get_node_or_null("Props/" + nm) as Node3D
			if t != null:
				trees.append(t)
				per_tree.append(int(BEETLES_PER_TREE[gi]))
				grove_of.append(gi)
	if trees.is_empty():
		var g0 := safari.dir_from_start(P_GEAR_GROVE.x, P_GEAR_GROVE.y)
		var all: Array = p.get_node("Props").get_children().filter(func(c: Node) -> bool: return str(c.name).begins_with("GearTree"))
		all.sort_custom(func(a: Node3D, b: Node3D) -> bool: return g0.angle_to(p.dir_of(a.global_position)) < g0.angle_to(p.dir_of(b.global_position)))
		trees = all.slice(0, 3)
		per_tree = [2, 2, 2]
		grove_of = [0, 0, 1]
	var pts: Array = []
	for ti in trees.size():
		var t: Node3D = trees[ti]
		var gears: Array = []
		for k in 3:
			var g := t.get_node_or_null("Gear%d" % k) as MeshInstance3D
			if g != null:
				gears.append(g)
		if gears.is_empty():
			continue
		var mesh := t.get_node_or_null("Mesh") as Node3D
		var s := mesh.scale.x if mesh != null else 1.0
		pts.append(t.global_position)
		pts.append(t.global_transform * Vector3(0.0, 3.4 * s, 0.0))
		for j in int(per_tree[ti]):
			_beetles.append({"grove": grove_of[ti], "tree": t, "gears": gears, "s": s, "state": BeetleState.BASE,
				"y": 0.0, "phi": _rng.randf_range(0.0, TAU), "k": 0, "a": 0.0,
				"timer": _rng.randf_range(0.5, 3.0) + 2.5 * float(j), "spin": _rng.randf_range(0.0, TAU)})
	# the curious ones (THE CURIOUS ONES): off in the sky until the director brings one
	for k in BEETLE_SCOUTS:
		_beetles.append({"scout": true, "grove": -1, "tree": null, "gears": [], "s": 1.0, "state": BeetleState.GONE,
			"y": 0.0, "phi": 0.0, "k": 0, "a": 0.0, "timer": 0.0, "spin": _rng.randf_range(0.0, TAU),
			"dir": safari.start_dir, "face": safari.start_fwd, "out_since": -INF})
	# The culling box is the whole planet: a curious one can come in anywhere.
	var rr := p.radius + 3.0
	_beetle_herd = Herd.new()
	add_child(_beetle_herd)
	_beetle_herd.setup("GearBeetles", _beetles.size(), [[Meshes.beetle_body(), _metal, true], [Meshes.beetle_cog(), _metal, false]],
		AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	for i in _beetles.size():
		if bool(_beetles[i].get("scout", false)):
			_beetle_herd.hide_one(i)
	_beetle_focus = Node3D.new()
	_beetle_focus.name = "BeetleFocus"
	add_child(_beetle_focus)
	safari.add_subject({
		"id": "gear_beetle", "name": "Gear-beetle", "rarity": 1, "kind": "creature",
		"band": BAND_BEETLE, "node": _beetle_focus, "offset": Vector3(0.0, 0.08, 0.0), "radius": 0.26,
		"awake": func() -> bool: return _beetle_pick >= 0,
		"moment": func(_tt: float) -> Dictionary:
			if _beetle_pick >= 0 and int(_beetles[_beetle_pick]["state"]) == BeetleState.RIDE:
				return {"mult": 1.5, "line": "riding a gear"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_beetle_focus),
	})


func _gear_height(b: Dictionary, k: int) -> float:
	var g: MeshInstance3D = b["gears"][k]
	return g.position.y + g.mesh.get_aabb().end.y * float(b["s"])


func _tick_beetles(delta: float) -> void:
	if _beetle_herd == null:
		return
	var beetle_shy := pacing.shy("gear_beetle")
	for i in _beetles.size():
		var b: Dictionary = _beetles[i]
		if bool(b.get("scout", false)):
			_tick_beetle_scout(i, b, beetle_shy, delta)
			continue
		var tree: Node3D = b["tree"]
		# one new thing at a time (SHY_SEC): out of the frame, into its gear; it climbs out again after
		if beetle_shy and not bool(b.get("shy", false)) and is_instance_valid(tree):
			var at: Vector3 = (b["xf"] as Transform3D).origin if b.has("xf") else tree.global_position
			if not pacing.point_in_frame(at, SHY_FRAME_GROW):
				b["shy"] = true
		if bool(b.get("shy", false)):
			if beetle_shy:
				_beetle_herd.hide_one(i)
				b.erase("xf")
				continue
			b["shy"] = false
			b["emerge"] = 0.0
		# At night the Gear Grove's beetles sleep inside their gears: the spark-moths have Antenna Hill
		# beside it (33 degrees off), and the two came on screen together - 19 of the wanderer's 307
		# encounters in 20 runs. The Back Grove's stay about, down at the foot of their tree.
		if not is_instance_valid(tree) or (safari.is_night and int(b["grove"]) == 0):
			_beetle_herd.hide_one(i)
			b.erase("xf")
			continue
		b["timer"] = float(b["timer"]) - delta
		var s := float(b["s"])
		var st: int = b["state"]
		var xf := Transform3D()
		match st:
			BeetleState.BASE:
				b["phi"] = float(b["phi"]) + 0.55 * delta
				xf = _beetle_on_ground(b)
				# At night the beetles stay down at the foot of their trees (the moths have the heights):
				# seen up close, not from across the planet.
				if float(b["timer"]) <= 0.0 and not safari.is_night:
					b["state"] = BeetleState.UP
					b["k"] = _rng.randi_range(0, (b["gears"] as Array).size() - 1)
					b["y"] = 0.12 * s
			BeetleState.UP:
				b["y"] = float(b["y"]) + BEETLE_CLIMB * delta
				b["phi"] = float(b["phi"]) + 1.1 * delta
				xf = _beetle_on_pole(b, true)
				if float(b["y"]) >= _gear_height(b, int(b["k"])) - 0.02:
					b["state"] = BeetleState.RIDE
					b["timer"] = _rng.randf_range(5.0, 9.0)
					b["a"] = _rng.randf_range(0.0, TAU)
			BeetleState.RIDE:
				xf = _beetle_on_gear(b)
				if float(b["timer"]) <= 0.0:
					b["state"] = BeetleState.DOWN
			BeetleState.DOWN:
				b["y"] = float(b["y"]) - BEETLE_CLIMB * 1.3 * delta
				b["phi"] = float(b["phi"]) - 1.1 * delta
				xf = _beetle_on_pole(b, false)
				if float(b["y"]) <= 0.1 * s:
					b["state"] = BeetleState.BASE
					b["timer"] = _rng.randf_range(2.0, 4.5)
		if _sleeping and float(b.get("gone", -1.0)) < 0.0:
			b["gone"] = _t
		if _sleeping and _t - float(b["gone"]) > PlanetSafari.SLEEP_PUFF_HIDE_SEC:
			_beetle_herd.hide_one(i)
			continue
		b["emerge"] = minf(float(b.get("emerge", 1.0)) + delta / BEETLE_EMERGE_SEC, 1.0)
		var sc := Basis.from_scale(Vector3.ONE * BEETLE_SCALE * lerpf(0.2, 1.0, float(b["emerge"])))
		xf.basis = xf.basis * sc
		b["xf"] = xf
		_beetle_herd.pose(i, 0, xf)
		b["spin"] = float(b["spin"]) + (5.0 if st == BeetleState.RIDE else 2.2) * delta
		_beetle_herd.pose(i, 1, xf * Transform3D(Basis(Vector3.UP, float(b["spin"])), Vector3(0.0, 0.155, 0.03)))
	_beetle_pick = _pick_focus(_beetles, func(b: Dictionary) -> bool: return b.has("xf") and not _sleeping,
		func(b: Dictionary) -> Vector3: return (b["xf"] as Transform3D).origin, 0.0)
	if _beetle_pick >= 0:
		_beetle_focus.global_transform = _beetles[_beetle_pick]["xf"]

## A curious beetle that is off and free, or null.
func _free_scout_beetle() -> Variant:
	for b: Dictionary in _beetles:
		if bool(b.get("scout", false)) and int(b["state"]) == BeetleState.GONE:
			return b
	return null


## THE DIRECTOR BRINGS A GEAR-BEETLE (THE CURIOUS ONES): it whirs down on its spinning cog from above
## and lands at the director's ground spot. Looking over the deck (no ground
## spot) it comes in at the height that puts it in the middle of the view (_scout_sky_spot, plus
## BEETLE_HOVER_SPARE) and HOVERS there BEETLE_HOVER_SEC before it settles.
func _bring_beetle(spot: Dictionary) -> bool:
	var bv: Variant = _free_scout_beetle()
	if bv == null:
		return false
	var b: Dictionary = bv
	var d: Vector3 = spot["dir"]
	var hover := 0.0
	if d == Vector3.ZERO:
		# looking over the deck: it hovers up in the view (the hoppers' sky spot, for a beetle)
		var sky := _scout_sky_spot(0.1, BEETLE_HOVER_SPARE, BEETLE_FLY_SEC, BEETLE_HOVER_MAX_M)
		if sky.is_empty():
			return false
		d = sky[0]
		hover = sky[1]
	if _near_built(d, BUILT_CLEAR_M):
		return false
	var p := safari.planet
	var ground := p.surface_point(d)
	var n := p.ground_normal(d)
	var lens: Transform3D = spot["lens"]
	var side := lens.basis.x - n * lens.basis.x.dot(n)
	side = side.normalized() if side.length() > 0.01 else _tangent_at(d)
	if _rng.randf() < 0.5:
		side = -side
	b["dir"] = d
	b["hover"] = hover
	b["to"] = ground + n * maxf(hover, 0.02)
	b["from"] = ground + n * (maxf(hover, 0.02) + BEETLE_FLY_FROM.y) + side * BEETLE_FLY_FROM.x
	b["pos"] = b["from"]
	b["face"] = _toward(d, _player_dir())
	b["state"] = BeetleState.FLY
	b["timer"] = BEETLE_FLY_SEC
	b["out_since"] = _t
	AudioManager.play_sfx_at("rotate", ground, -10.0, 0.2)
	_log("curious beetle whirs in to %s t=%.1f%s" % [_pp(d), _t, (" hovering %.2f m" % hover) if hover > 0.0 else ""])
	return true


## One curious beetle: FLY in -> (HOVER) -> SETTLE -> CRAWL about -> GONE (see THE CURIOUS ONES).
func _tick_beetle_scout(i: int, b: Dictionary, shy: bool, delta: float) -> void:
	var st: int = b["state"]
	if st == BeetleState.GONE:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	b["timer"] = float(b["timer"]) - delta
	var d: Vector3 = b["dir"]
	var n := p.ground_normal(d)
	var pos: Vector3 = b["pos"]
	var dist := pos.distance_to(ppos)
	var flying := st == BeetleState.FLY or st == BeetleState.HOVER or st == BeetleState.SETTLE
	# gone: the planet goes to sleep; out of view while something new is up (ONE NEW THING AT A TIME);
	# out long enough and left behind; or rushed (it whirs off - up and out of the frame first)
	var away := (_sleeping and _t - float(b.get("sleep_t", _t)) > PlanetSafari.SLEEP_PUFF_HIDE_SEC) \
		or (st == BeetleState.CRAWL and shy and not pacing.point_in_frame(pos, SHY_FRAME_GROW)) \
		or (_t - float(b["out_since"]) > SCOUT_OUT_MIN_SEC and dist > SCOUT_DOWN_M and not pacing.point_in_frame(pos, 1.2)) \
		or (b.has("off") and (not pacing.point_in_frame(pos, 1.05) or float(b["off"]) > 3.0))
	if _sleeping and not b.has("sleep_t"):
		b["sleep_t"] = _t
	if away:
		b["state"] = BeetleState.GONE
		b.erase("xf")
		b.erase("off")
		b.erase("sleep_t")
		_beetle_herd.hide_one(i)
		return
	var tilt := 0.0
	match st:
		BeetleState.FLY:
			var f := clampf(1.0 - float(b["timer"]) / BEETLE_FLY_SEC, 0.0, 1.0)
			var e := 1.0 - (1.0 - f) * (1.0 - f)
			pos = (b["from"] as Vector3).lerp(b["to"], e) + n * 0.25 * sin(f * PI)
			tilt = 0.25 * (1.0 - f)
			_turn_beetle(b, ppos - pos, n, 6.0, delta)
			if float(b["timer"]) <= 0.0:
				pos = b["to"]
				if float(b["hover"]) > 0.0:
					b["state"] = BeetleState.HOVER
					b["timer"] = BEETLE_HOVER_SEC
				else:
					b["state"] = BeetleState.SETTLE
					b["timer"] = BEETLE_LAND_SEC * 0.5
		BeetleState.HOVER:
			pos = (b["to"] as Vector3) + n * 0.06 * sin(_t * 4.0)
			_turn_beetle(b, ppos - pos, n, 4.0, delta)
			if float(b["timer"]) <= 0.0:
				b["state"] = BeetleState.SETTLE
				b["from"] = pos
				b["to"] = p.surface_point(d) + n * 0.02
				# a higher hover (BEETLE_HOVER_MAX_M) comes down no faster than the highest hop-height one did
				b["land"] = BEETLE_LAND_SEC * maxf(1.0, float(b["hover"]) / SCOUT_BIG_MAX_M)
				b["timer"] = b["land"]
		BeetleState.SETTLE:
			var f := clampf(1.0 - float(b["timer"]) / float(b.get("land", BEETLE_LAND_SEC)), 0.0, 1.0)
			if float(b["hover"]) > 0.0:
				pos = (b["from"] as Vector3).lerp(b["to"], f * f * (3.0 - 2.0 * f))
			if float(b["timer"]) <= 0.0:
				pos = p.surface_point(d) + n * 0.02
				b["state"] = BeetleState.CRAWL
				b["timer"] = _rng.randf_range(0.8, 2.0)
		BeetleState.CRAWL:
			if b.has("off"):
				# whirring off: up and away
				b["off"] = float(b["off"]) + delta
				pos += (n * 1.4 + (b["face"] as Vector3) * 0.6) * delta * (1.0 + 2.0 * float(b["off"]))
				tilt = -0.2
			elif pos.distance_to(ppos) < BEETLE_SHY_M and speed > BEETLE_SHY_SPEED:
				b["off"] = 0.0
				AudioManager.play_sfx_at("rotate", pos, -10.0, 0.2)
			else:
				if float(b["timer"]) <= 0.0:
					b["timer"] = _rng.randf_range(1.2, 3.0)
					b["face"] = (b["face"] as Vector3).rotated(d, _rng.randf_range(-1.2, 1.2)).normalized()
				var fwd := (b["face"] as Vector3) - d * (b["face"] as Vector3).dot(d)
				var d2 := p.step_dir(d, (d * cos(0.3) + fwd.normalized() * sin(0.3)).normalized(), BEETLE_CRAWL * delta)
				if p.nearest_prop_distance(d2) >= 0.4 and rad_to_deg(d2.angle_to(_pad_dir)) >= HOPPER_PAD_CLEAR_DEG:
					d = d2
					b["dir"] = d
				else:
					b["face"] = (b["face"] as Vector3).rotated(d, PI * 0.6).normalized()
				n = p.ground_normal(d)
				pos = p.surface_point(d) + n * 0.02
	b["pos"] = pos
	var fw: Vector3 = b["face"]
	fw -= n * fw.dot(n)
	if fw.length() < 0.001:
		fw = _tangent_at(d)
	var xf := Transform3D(Basis.looking_at(fw.normalized(), n) * Basis(Vector3.RIGHT, -tilt)
		* Basis.from_scale(Vector3.ONE * BEETLE_SCALE), pos)
	b["xf"] = xf
	_beetle_herd.pose(i, 0, xf)
	var fly := flying or b.has("off")
	b["spin"] = float(b["spin"]) + (BEETLE_ROTOR if fly else 2.2) * delta
	var lift := 0.03 if fly else 0.0
	_beetle_herd.pose(i, 1, xf * Transform3D(Basis(Vector3.UP, float(b["spin"])), Vector3(0.0, 0.155 + lift, 0.03)))


func _turn_beetle(b: Dictionary, want: Vector3, n: Vector3, rate: float, delta: float) -> void:
	var w := want - n * want.dot(n)
	if w.length() < 0.001:
		return
	var cur: Vector3 = b["face"]
	cur -= n * cur.dot(n)
	if cur.length() < 0.001:
		cur = w
	b["face"] = cur.normalized().slerp(w.normalized(), clampf(rate * delta, 0.0, 1.0)).normalized()


func _beetle_on_ground(b: Dictionary) -> Transform3D:
	var tree: Node3D = b["tree"]
	var s := float(b["s"])
	var phi := float(b["phi"])
	var r := 0.62 * s
	var up := tree.global_basis.y.normalized()
	var pos := tree.global_transform * Vector3(cos(phi) * r, 0.02, sin(phi) * r)
	var tangent := (tree.global_basis * Vector3(-sin(phi), 0.0, cos(phi))).normalized()
	return Transform3D(Basis.looking_at(tangent, up), pos)


func _beetle_on_pole(b: Dictionary, going_up: bool) -> Transform3D:
	var tree: Node3D = b["tree"]
	var s := float(b["s"])
	var phi := float(b["phi"])
	var rc := 0.125 * s + 0.05
	var up := tree.global_basis.y.normalized()
	var out := (tree.global_basis * Vector3(cos(phi), 0.0, sin(phi))).normalized()
	var pos := tree.global_transform * Vector3(cos(phi) * rc, float(b["y"]), sin(phi) * rc)
	var head := up if going_up else -up
	# The beetle's back (+Y) points out from the pole, its head (-Z) along the pole.
	var z := -head
	var x := out.cross(z).normalized()
	return Transform3D(Basis(x, out, z).orthonormalized(), pos)


func _beetle_on_gear(b: Dictionary) -> Transform3D:
	var g: MeshInstance3D = b["gears"][int(b["k"])]
	var ab := g.mesh.get_aabb()
	var a := float(b["a"])
	var rr := ab.size.x * 0.5 * 0.62
	var gx := g.global_transform
	var pos := gx * Vector3(cos(a) * rr, ab.end.y, sin(a) * rr)
	var up := gx.basis.y.normalized()
	var tangent := (gx.basis * Vector3(-sin(a), 0.0, cos(a))).normalized()
	return Transform3D(Basis.looking_at(tangent, up), pos)




# ---------------------------------------------------------------------------------------- spring-hoppers
## THE NEW CRITTER (R4, spec 11.2): small copper spring-hoppers that live under the deck plates all
## over the planet and are curious: where it has gone quiet, one springs up in front of you (the
## scouts, HOPPER_SCOUTS). Each sits, looks about, and boings off on its one spring, keeping near where
## it came up. Walk fast at one and it boings away; stand still with the camera up and the nearest
## turns to you and bounces hello (its moment, and its best Facing). Two parts in one herd (body +
## spring): 2 draw calls for all of them.
func _build_hoppers() -> void:
	var p := safari.planet
	# The troupes' wandering points, and each member set down round its troupe's.
	var homes: Array[Vector3] = []
	for k in HOPPER_TROUPES:
		var f: Vector2 = HOPPER_TROUPE_FROM[k % HOPPER_TROUPE_FROM.size()]
		var c := _free_near(safari.dir_from_start(f.x, f.y), 1.0)
		_troupes.append({"c": c, "heading": _tangent_at(c).rotated(c, _rng.randf_range(0.0, TAU)), "turn": 0.0})
		for j in HOPPER_PER_TROUPE:
			homes.append(_polar(c, _tangent_at(c), _rng.randf_range(1.0, 4.0), 120.0 * float(j) + _rng.randf_range(-30.0, 30.0)))
	var pts: Array = []
	for d0: Vector3 in homes:
		var d := d0
		if rad_to_deg(d.angle_to(_pad_dir)) < HOPPER_PAD_CLEAR_DEG:
			d = _polar(_pad_dir, _tangent_at(_pad_dir), HOPPER_PAD_CLEAR_DEG + 2.0, rad_to_deg(_tangent_at(_pad_dir).signed_angle_to(d - _pad_dir * d.dot(_pad_dir), _pad_dir)))
		d = _free_near(d, 0.7)
		var face := _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
		_hoppers.append({"troupe": _hoppers.size() / HOPPER_PER_TROUPE, "scout": false, "home": d, "dir": d, "face": face, "heading": face, "state": HopState.SIT,
			"timer": _rng.randf_range(0.2, 2.0), "from": d, "to": d, "sq": 1.0, "h": 0.0, "sink": 0.0,
			"look": 0.0, "phase": _rng.randf_range(0.0, TAU)})
		pts.append(p.surface_point(d))
	# the scouts: under the deck until they are curious
	for k in HOPPER_SCOUTS:
		_hoppers.append({"troupe": -1, "scout": true, "home": safari.start_dir, "dir": safari.start_dir,
			"face": safari.start_fwd, "heading": safari.start_fwd, "state": HopState.GONE, "timer": 0.0,
			"from": safari.start_dir, "to": safari.start_dir, "sq": 0.5, "h": 0.0, "sink": 0.5, "look": 0.0,
			"phase": _rng.randf_range(0.0, TAU), "out_since": -INF})
	# The herd's culling box is the whole planet: they roam everywhere.
	var rr := p.radius + 1.5
	var area := AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0)
	_hop_herd = Herd.new()
	add_child(_hop_herd)
	_hop_herd.setup("SpringHoppers", _hoppers.size(), [[Meshes.hopper_body(), _metal, true],
		[Meshes.hopper_spring(), _metal, false]], area)
	_hop_focus = Node3D.new()
	_hop_focus.name = "HopperFocus"
	add_child(_hop_focus)
	safari.add_subject({
		"id": "spring_hopper", "name": "Spring-hopper", "rarity": 1, "kind": "creature",
		"band": BAND_HOPPER, "node": _hop_focus, "offset": Vector3(0.0, 0.08, 0.0), "radius": 0.22,
		"awake": func() -> bool: return _hop_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _hopper_moment(),
		"front": func() -> Vector3: return _front_of(_hop_focus),
	})


func _hopper_moment() -> Dictionary:
	if _hop_pick < 0:
		return {"mult": 1.0, "line": ""}
	var h: Dictionary = _hoppers[_hop_pick]
	var st: int = h["state"]
	if st == HopState.HELLO:
		return {"mult": 1.6, "line": "bouncing hello"}
	if st == HopState.AIR:
		var f := 1.0 - float(h["timer"]) / float(h.get("air_t", HOPPER_AIR_SEC))
		if f > 0.2 and f < 0.8:
			return {"mult": 1.5, "line": "big boing!" if float(h.get("air_h", HOPPER_HOP_H)) > 0.6 else "mid-hop!"}
	return {"mult": 1.0, "line": ""}


func _tick_hoppers(delta: float) -> void:
	if _hop_herd == null:
		return
	var p := safari.planet
	var pl := safari.player
	var ppos := pl.global_position
	var speed := pl.get_tangent_velocity().length()
	var still_up := safari.camera_up and speed < 0.15
	_hop_still = (_hop_still + delta) if still_up else 0.0
	_tick_troupes(delta)
	var hop_shy := pacing.shy("spring_hopper")
	# the one that says hello: the nearest in range, once you have stood still long enough
	var hello_i := -1
	if _hop_still >= HOPPER_HELLO_STILL and _t >= _hop_hello_next and not _sleeping:
		var best := HOPPER_HELLO_M
		for i in _hoppers.size():
			var hd: Dictionary = _hoppers[i]
			if int(hd["state"]) != HopState.SIT:
				continue
			var dd := p.surface_point(hd["dir"]).distance_to(ppos)
			if dd < best:
				best = dd
				hello_i = i
	for i in _hoppers.size():
		var h: Dictionary = _hoppers[i]
		var here: Vector3 = _hop_ground(h)[0]
		var dist := here.distance_to(ppos)
		h["timer"] = float(h["timer"]) - delta
		var st: int = h["state"]
		if _sleeping and st != HopState.GONE and st != HopState.AIR:
			h["state"] = HopState.GONE
			h["timer"] = 0.4
			st = HopState.GONE
		match st:
			HopState.SIT:
				# looks about: small turns of its face
				h["look"] = float(h["look"]) + delta
				if float(h["look"]) > 1.1:
					h["look"] = 0.0
					h["face"] = (h["face"] as Vector3).rotated(h["dir"], _rng.randf_range(-0.7, 0.7)).normalized()
				h["sq"] = 1.0 + 0.03 * sin(_t * 3.0 + float(h["phase"]))
				if bool(h["scout"]) and _t - float(h["out_since"]) > SCOUT_OUT_MIN_SEC and dist > SCOUT_DOWN_M \
						and not pacing.point_in_frame(here, 1.2):
					# far behind you and out of view: back under the deck
					h["state"] = HopState.GONE
				elif bool(h["scout"]) and hop_shy and not pacing.point_in_frame(here, SHY_FRAME_GROW):
					# one new thing at a time (SHY_SEC): out of view, back under the deck
					h["state"] = HopState.GONE
				elif bool(h["scout"]) and _t - float(h["out_since"]) < SCOUT_OUT_MIN_SEC and not pacing.in_view \
						and _t >= float(h.get("next_big", 0.0)) and dist < SCOUT_DOWN_M + 1.0:
					# "look at me": you are looking over it (at the horizon or the sky), so it boings up
					# into your view instead of hopping about unseen below the frame
					h["next_big"] = _t + SCOUT_BIG_EVERY_SEC
					var apex := _big_apex(here, _hop_ground(h)[1], pacing.lens_soon(SCOUT_LEAD_SIT_SEC))
					if apex > 0.0:
						_big_boing(h, apex)
				elif i == hello_i:
					h["state"] = HopState.HELLO
					h["timer"] = HOPPER_HELLO_SEC
					_hop_hello_next = _t + HOPPER_HELLO_SEC + HOPPER_HELLO_REST
					AudioManager.play_sfx_at("ui_tick", here, -10.0, 0.2)
				elif dist < HOPPER_SHY_M and speed > HOPPER_SHY_SPEED:
					var away := here - ppos
					_hop_plan(h, away, true)
				elif float(h["timer"]) <= 0.0:
					_hop_plan(h, Vector3.ZERO, false)
			HopState.CROUCH:
				h["sq"] = lerpf(1.0, 0.55, clampf(1.0 - float(h["timer"]) / HOPPER_CROUCH_SEC, 0.0, 1.0))
				_turn_face(h, h["heading"], 14.0, delta)
				if float(h["timer"]) <= 0.0:
					h["state"] = HopState.AIR
					h["timer"] = float(h.get("air_t", HOPPER_AIR_SEC))
					if _t >= _boing_next and dist < 5.0:
						_boing_next = _t + 0.4
						AudioManager.play_sfx_at("jump", here, -16.0, 0.25)
			HopState.AIR:
				var f := clampf(1.0 - float(h["timer"]) / float(h.get("air_t", HOPPER_AIR_SEC)), 0.0, 1.0)
				h["dir"] = (h["from"] as Vector3).slerp(h["to"], f).normalized()
				h["h"] = 4.0 * float(h.get("air_h", HOPPER_HOP_H)) * f * (1.0 - f)
				h["sq"] = lerpf(1.3, 1.0, f)
				if float(h["timer"]) <= 0.0:
					h["dir"] = h["to"]
					h["h"] = 0.0
					h["state"] = HopState.LAND
					h["timer"] = HOPPER_LAND_SEC
					h["air_h"] = HOPPER_HOP_H
					h["air_t"] = HOPPER_AIR_SEC
			HopState.LAND:
				h["sq"] = lerpf(0.6, 1.0, clampf(1.0 - float(h["timer"]) / HOPPER_LAND_SEC, 0.0, 1.0))
				if float(h["timer"]) <= 0.0:
					h["state"] = HopState.SIT
					h["timer"] = _rng.randf_range(HOPPER_SIT_SEC.x, HOPPER_SIT_SEC.y)
			HopState.HELLO:
				_turn_face(h, ppos - here, 8.0, delta)
				var b := absf(sin((HOPPER_HELLO_SEC - float(h["timer"])) * 7.5))
				h["h"] = 0.09 * b
				h["sq"] = lerpf(0.75, 1.15, b)
				if float(h["timer"]) <= 0.0 or (dist < HOPPER_SHY_M and speed > HOPPER_SHY_SPEED):
					h["h"] = 0.0
					h["state"] = HopState.SIT
					h["timer"] = _rng.randf_range(HOPPER_SIT_SEC.x, HOPPER_SIT_SEC.y)
			HopState.GONE:
				# springs down into the deck
				h["sink"] = minf(float(h["sink"]) + delta / 0.4 * 0.5, 0.5)
				h["sq"] = 0.5
			HopState.POP:
				# springs up out of the deck, stretched tall, turning to see you
				var f := clampf(1.0 - float(h["timer"]) / SCOUT_POP_SEC, 0.0, 1.0)
				h["sink"] = 0.5 * (1.0 - f)
				h["h"] = 0.22 * sin(f * PI)
				h["sq"] = lerpf(1.35, 1.0, f)
				_turn_face(h, ppos - here, 10.0, delta)
				if float(h["timer"]) <= 0.0:
					h["sink"] = 0.0
					h["h"] = 0.0
					h["state"] = HopState.LAND
					h["timer"] = HOPPER_LAND_SEC
					if float(h.get("big", 0.0)) > 0.0:
						_big_boing(h, float(h["big"]))
					h["big"] = 0.0
		_pose_hopper(i, h)
	_hop_pick = _pick_focus(_hoppers, func(h: Dictionary) -> bool: return float(h["sink"]) < 0.2,
		func(h: Dictionary) -> Vector3: return (h["body"] as Transform3D).origin if h.has("body") else p.surface_point(h["dir"]), 0.08)
	if _hop_pick >= 0 and _hoppers[_hop_pick].has("body"):
		_hop_focus.global_transform = _hoppers[_hop_pick]["body"]


## Each troupe's point wanders on round the planet at HOPPER_TROUPE_SPEED: a gentle new bearing every
## 4-9 s, turned away from the pad; its members' homes follow it.
func _tick_troupes(delta: float) -> void:
	if _sleeping:
		return
	var p := safari.planet
	for k in _troupes.size():
		var tr: Dictionary = _troupes[k]
		var c: Vector3 = tr["c"]
		var hd: Vector3 = tr["heading"]
		tr["turn"] = float(tr["turn"]) - delta
		if float(tr["turn"]) <= 0.0:
			tr["turn"] = _rng.randf_range(4.0, 9.0)
			hd = hd.rotated(c, _rng.randf_range(-0.9, 0.9))
		if rad_to_deg(c.angle_to(_pad_dir)) < HOPPER_PAD_CLEAR_DEG + 8.0:
			hd = _toward(c, c - _pad_dir)
		var ahead := (c * cos(0.3) + (hd - c * hd.dot(c)).normalized() * sin(0.3)).normalized()
		var c2 := p.step_dir(c, ahead, HOPPER_TROUPE_SPEED * delta)
		# carry the bearing along with the point (parallel transport on the sphere)
		hd = Quaternion(c, c2) * hd
		hd = (hd - c2 * hd.dot(c2)).normalized()
		tr["c"] = c2
		tr["heading"] = hd
	for h: Dictionary in _hoppers:
		if int(h["troupe"]) >= 0:
			h["home"] = (_troupes[int(h["troupe"])] as Dictionary)["c"]


## THE DIRECTOR'S `places` (Pacing.places): where the other creatures are (and every awake subject but
## the hoppers): crab burrows (a curious crab's plate while it is up), the beetles' trees and any curious
## beetle that is out, the moth swarms, Bolt. The director brings nothing within Pacing.CLEAR_M of these,
## and waits while you walk toward one (Pacing.creature_ahead). Only creatures that can still come into view count (R4 round 3): a crab
## down its burrow within CRAB_NOTICE_M of you waits there until you stand still with the camera up, and
## a sleeping beetle is inside its gear - walking through a crab place whose crabs had all hidden was a
## dead zone where nothing was in view and no scout could come up (a trace of seed 102: 7 s of it).
func _creature_places() -> Array[Vector3]:
	var p := safari.planet
	var others: Array[Vector3] = []
	var ppos := safari.player.global_position if is_instance_valid(safari.player) else Vector3.ZERO
	for c: Dictionary in _crabs:
		if bool(c.get("gone", false)):
			continue
		var at := p.surface_point(c["burrow"])
		var down := int(c["state"]) == CrabState.IN or int(c["state"]) == CrabState.HIDE
		if down and at.distance_to(ppos) < CRAB_NOTICE_M:
			continue
		others.append(at)
	for b: Dictionary in _beetles:
		if bool(b.get("scout", false)):
			if b.has("xf"):
				others.append((b["xf"] as Transform3D).origin)
		elif is_instance_valid(b["tree"]) and b.has("xf"):
			others.append((b["tree"] as Node3D).global_position)
	for k in _moth_centres.size():
		if k != _moth_scout or _moth_scout_on:
			others.append(_moth_centres[k])
	if is_instance_valid(_bolt):
		others.append(_bolt.global_position)
	for sj: Dictionary in safari.awake_subjects():
		# not a sight or a bonus thing (spec 15.5): they are always there, and "walking toward" one is not
		# walking toward a creature (Pacing.creature_ahead would hold every bring back for them)
		if str(sj.get("id", "")) != "spring_hopper" and SafariWorld.counts_for_pacing(sj):
			others.append(SafariPhotoScorer.subject_point(sj))
	return others


## When the lens looks over the deck (the horizon or the sky, where no ground spot is in the middle of
## the frame): a spot on the ground ahead from which a BIG BOING carries a scout up into the middle of
## the view, and that boing's height. [] when there is none (looking too high: it waits).
## Shared by all three curious ones (a hopper's big boing, a crab's jet of steam, a beetle's hover):
## `lift` is how high its middle sits above the ground, `spare` how far past the lowest height that
## reaches the view it goes, `lead` how soon it is up there (the lens is judged then).
func _scout_sky_spot(lift: float = Meshes.HOPPER_SPRING_H + 0.1, spare: float = SCOUT_BIG_SPARE,
		lead: float = SCOUT_LEAD_BIG_SEC, max_m: float = SCOUT_BIG_MAX_M) -> Array:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if cam == null:
		return []
	var p := safari.planet
	var lens := pacing.lens_soon(lead)
	var pd := p.dir_of(lens.origin)
	var fwd := -lens.basis.z
	fwd -= pd * fwd.dot(pd)
	if fwd.length() < 0.01:
		return []
	fwd = fwd.normalized()
	var others := pacing.other_places()
	for m: float in SCOUT_SKY_M:
		for yaw: float in SCOUT_POP_YAW:
			var dirn := fwd.rotated(pd, deg_to_rad(yaw))
			var d := p.step_dir(pd, (pd * cos(0.5) + dirn * sin(0.5)).normalized(), m)
			if p.nearest_prop_distance(d) < 0.55 or rad_to_deg(d.angle_to(_pad_dir)) < HOPPER_PAD_CLEAR_DEG \
					or p.ground_normal(d).angle_to(d) > deg_to_rad(12.0):
				continue
			var ground := p.surface_point(d)
			var crowded := false
			for q: Vector3 in others:
				if ground.distance_to(q) < pacing.CLEAR_M:
					crowded = true
					break
			if crowded:
				continue
			var apex := _big_apex(ground, p.ground_normal(d), lens, lift, spare, max_m)
			if apex > 0.0:
				return [d, apex]
	return []


## How high a hopper standing at `ground` must boing for its body to come up into the middle
## Pacing.SPOT_FRAME_FRAC of the view, in the lens's line of sight, with some to spare at the top of the hop so
## it is up there a while (SCOUT_BIG_SPARE). 0 when its body is already in view on the ground or no
## boing up to SCOUT_BIG_MAX_M would do.
func _big_apex(ground: Vector3, n: Vector3, lens: Transform3D, lift: float = Meshes.HOPPER_SPRING_H + 0.1,
		spare: float = SCOUT_BIG_SPARE, max_m: float = SCOUT_BIG_MAX_M) -> float:
	var space := get_world_3d().direct_space_state
	if pacing.in_view_from(lens, ground + n * lift, pacing.SPOT_FRAME_FRAC):
		return 0.0
	var hh := 0.3
	while hh <= max_m - spare + 0.001:
		var body := ground + n * (lift + hh)
		if pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC):
			if not _sight_clear(space, lens.origin, body):
				return 0.0
			return hh + spare
		hh += 0.15
	return 0.0


## A curious hopper that is under the deck and free, or null.
func _free_scout_hopper() -> Variant:
	for h: Dictionary in _hoppers:
		if bool(h["scout"]) and int(h["state"]) == HopState.GONE and float(h["sink"]) >= 0.49:
			return h
	return null


## THE DIRECTOR BRINGS A SPRING-HOPPER (THE CURIOUS ONES): it springs up at the director's ground spot,
## or - looking over the deck, where there is none - at its own SCOUT_SKY_M spot with a BIG BOING up into
## the view. R4's scout, unchanged but for who decides when.
func _bring_hopper(spot: Dictionary) -> bool:
	var hv: Variant = _free_scout_hopper()
	if hv == null:
		return false
	var h: Dictionary = hv
	var d: Vector3 = spot["dir"]
	var big := 0.0
	if d == Vector3.ZERO:
		var sky := _scout_sky_spot()
		if sky.is_empty():
			return false
		d = sky[0]
		big = sky[1]
	if _near_built(d, BUILT_CLEAR_M):
		return false
	h["big"] = big
	h["next_big"] = _t + SCOUT_POP_SEC + SCOUT_BIG_EVERY_SEC
	h["dir"] = d
	h["home"] = d
	h["from"] = d
	h["to"] = d
	h["state"] = HopState.POP
	h["timer"] = SCOUT_POP_SEC
	h["out_since"] = _t
	h["face"] = _toward(d, _player_dir())
	h["heading"] = h["face"]
	AudioManager.play_sfx_at("jump", safari.planet.surface_point(d), -8.0, 0.2)
	_log("curious scout pops up at %s t=%.1f%s" % [_pp(d), _t, (" big boing %.2f m" % big) if big > 0.0 else ""])
	return true


## One big boing straight up and back down where it stands (the same spring, the same pull as a hop).
func _big_boing(h: Dictionary, apex: float) -> void:
	h["air_h"] = apex
	h["air_t"] = HOPPER_AIR_SEC * sqrt(apex / HOPPER_HOP_H)
	h["from"] = h["dir"]
	h["to"] = h["dir"]
	h["state"] = HopState.CROUCH
	h["timer"] = HOPPER_CROUCH_SEC
	AudioManager.play_sfx_at("jump", safari.planet.surface_point(h["dir"]), -8.0, 0.35)


## Plans the next hop: along its heading with a wobble, pulled home when it has strayed, away from
## `away` when it is fleeing. Hops that would land on a prop, a slope or the pad turn it round.
func _hop_plan(h: Dictionary, away: Vector3, flee: bool) -> void:
	var p := safari.planet
	var d: Vector3 = h["dir"]
	var heading: Vector3 = h["heading"]
	heading -= d * heading.dot(d)
	if flee and away.length() > 0.01:
		heading = away - d * away.dot(d)
	elif rad_to_deg(d.angle_to(h["home"])) > HOPPER_RANGE_DEG:
		heading = _toward(d, h["home"]).rotated(d, _rng.randfn(0.0, 0.4))
	else:
		heading = heading.normalized().rotated(d, _rng.randfn(0.0, 0.8))
	heading = heading.normalized()
	var hop_len := _rng.randf_range(HOPPER_HOP_M.x, HOPPER_HOP_M.y) * (1.3 if flee else 1.0)
	for k in 5:
		var far := (d * cos(0.5) + heading * sin(0.5)).normalized()
		var to := p.step_dir(d, far, hop_len)
		if p.nearest_prop_distance(to) >= 0.45 and rad_to_deg(to.angle_to(_pad_dir)) >= HOPPER_PAD_CLEAR_DEG \
				and p.ground_normal(to).angle_to(to) < deg_to_rad(12.0) and not _near_built(to, 0.3):
			h["heading"] = heading
			h["from"] = d
			h["to"] = to
			h["state"] = HopState.CROUCH
			h["timer"] = HOPPER_CROUCH_SEC
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


## The ground under a hopper (its surface point and slope normal), re-measured only when it has moved:
## most of them sit most of the time, and the slope costs four height samples.
func _hop_ground(h: Dictionary) -> Array:
	var d: Vector3 = h["dir"]
	if not h.has("g_dir") or (h["g_dir"] as Vector3) != d:
		h["g_dir"] = d
		h["g_pt"] = safari.planet.surface_point(d)
		h["g_n"] = safari.planet.ground_normal(d.normalized())
	return [h["g_pt"], h["g_n"]]


func _pose_hopper(i: int, h: Dictionary) -> void:
	var sink := float(h["sink"])
	if sink >= 0.49:
		_hop_herd.hide_one(i)
		h.erase("body")
		return
	# the same frame as _xf_ground(dir, face), from the cached ground
	var g := _hop_ground(h)
	var d: Vector3 = (h["dir"] as Vector3).normalized()
	var n: Vector3 = g[1]
	var fw: Vector3 = h["face"]
	fw -= d * fw.dot(d)
	fw -= n * fw.dot(n)
	if fw.length() < 0.001:
		fw = _tangent_at(d)
	var base := Transform3D(Basis.looking_at(fw.normalized(), n), g[0])
	var sq := float(h["sq"])
	var hh := float(h["h"])
	# a lean into the hop while in the air
	var lean := 0.0
	if int(h["state"]) == HopState.AIR:
		var f := clampf(1.0 - float(h["timer"]) / float(h.get("air_t", HOPPER_AIR_SEC)), 0.0, 1.0)
		lean = lerpf(-0.25, 0.2, f)
	var foot := base.translated_local(Vector3(0.0, hh - sink, 0.0))
	var spring := Transform3D(foot.basis * Basis.from_scale(Vector3(1.0, sq, 1.0)), foot.origin)
	var body := foot.translated_local(Vector3(0.0, Meshes.HOPPER_SPRING_H * sq, 0.0))
	body.basis = body.basis * Basis(Vector3.RIGHT, lean)
	_hop_herd.pose(i, 1, spring)
	_hop_herd.pose(i, 0, body)
	h["body"] = body


# ---------------------------------------------------------------------------------------- moths
## Night only: a swarm round the blinking top of each post in MOTH_POSTS, one herd. The
## subject is the swarm nearest the middle of the view; its front is the heading of that swarm's moth
## nearest the lens (a swarm has no one face; the moth in front is the one the picture is of).
func _build_moths() -> void:
	var p := safari.planet
	for nm: String in MOTH_POSTS:
		var post := p.get_node_or_null("Props/" + nm) as Node3D
		if post == null:
			continue
		if nm == ANTENNA_NAME and _antenna != null:
			_moth_centres.append(_antenna.global_transform * Vector3(0.0, (3.0 + 0.08) * _antenna_s, 0.0))
			continue
		var mi := post.get_node_or_null("Mesh") as MeshInstance3D
		var top := post.global_position + p.up_at(post.global_position) * 3.0
		if mi != null and mi.mesh != null:
			top = mi.global_transform * Vector3(0.0, mi.mesh.get_aabb().end.y, 0.0)
		_moth_centres.append(top - p.up_at(top) * 0.15)
	if _moth_centres.is_empty():
		return
	_moth_centre = _moth_centres[0]
	# THE SCOUT SWARM (MOTH_SCOUT_M): one more slot, away in the dark (scattered) until the director brings it
	_moth_scout = _moth_centres.size()
	_moth_centres.append(_moth_centre)
	_moth_scatter.resize(_moth_centres.size())
	for k in _moth_centres.size():
		_moth_scatter[k] = 1.0 if k == _moth_scout else 0.0
	var n := _moth_centres.size() * MOTH_PER_SWARM
	_moth_heads.resize(n)
	_moth_pos.resize(n)
	_moth_herd = Herd.new()
	add_child(_moth_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(0.5, 0.5)
	# the culling box is the whole planet and the air over it: the scout swarm can come anywhere
	var rr := p.radius + MOTH_SCOUT_LIFT.y + 3.0
	_moth_herd.setup("SparkMoths", n, [[Meshes.moth(), _prop_mat, false],
		[glow, MaterialLib.glow_sprite(Color("#ff9a3c"), 2.0, {"softness": 0.0, "core": 0.22, "blink": 0.35, "blink_speed": 7.0})
			, false]], AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0))
	_moth_focus = Node3D.new()
	_moth_focus.name = "MothFocus"
	add_child(_moth_focus)
	_moth_focus.global_position = _moth_centre
	safari.add_subject({
		"id": "spark_moth", "name": "Spark-moths", "rarity": 2, "kind": "creature",
		"band": BAND_MOTHS, "node": _moth_focus, "radius": 0.85,
		"awake": func() -> bool: return safari.is_night and not _sleeping and _moth_pick >= 0,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 1.8, "line": "mid-burst!"} if fmod(tt, MOTH_BURST_EVERY) < MOTH_BURST_SEC else {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _moth_front(),
	})


## Poses swarm `s`'s moths circling `centre` (spread by the burst and by how scattered it is).
func _pose_swarm(s: int, centre: Vector3, spread: float) -> void:
	var up := safari.planet.up_at(centre)
	var e1 := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
	var e2 := up.cross(e1).normalized()
	for k in MOTH_PER_SWARM:
		var i := s * MOTH_PER_SWARM + k
		var fi := float(k) + 1.37 * float(s)
		var th := _t * (1.3 + 0.17 * float(k)) + fi * 0.9
		var r := (0.42 + 0.3 * sin(_t * 0.7 + fi * 1.7)) * spread * (1.0 + 5.0 * _moth_scatter[s])
		var pos := centre + (e1 * cos(th) + e2 * sin(th)) * r + up * (0.15 * sin(_t * 2.1 + fi) - 0.25 + 0.1 * float(k) / MOTH_PER_SWARM)
		var vel := (-e1 * sin(th) + e2 * cos(th)).normalized()
		var flap := 0.3 + 0.7 * absf(sin(_t * 22.0 + fi))
		var b := Basis.looking_at(vel, up) * Basis.from_scale(Vector3(flap, 1.0, 1.0))
		_moth_herd.pose(i, 0, Transform3D(b, pos))
		_moth_herd.pose(i, 1, Transform3D(Basis.from_scale(Vector3.ONE * (0.8 + 0.3 * sin(_t * 6.0 + fi))), pos))
		_moth_heads[i] = vel
		_moth_pos[i] = pos


## THE DIRECTOR BRINGS SPARK-MOTHS (MOTH_SCOUT_M): the scout swarm gathers out of the dark in the air
## where the lens looks, far out. False (the next bringer is asked) when no such spot is in view.
func _bring_moths(spot: Dictionary) -> bool:
	if _moth_scout < 0 or _moth_scout_on or _sleeping:
		return false
	var q := _moth_air_spot(spot["lens"])
	if q == Vector3.ZERO:
		return false
	_moth_centres[_moth_scout] = q
	_moth_scatter[_moth_scout] = 1.0
	_moth_scout_on = true
	_moth_scout_since = _t
	AudioManager.play_sfx_at("shooting_star", q, -14.0, 0.2)
	_log("spark-moths gather at %s (%.1f m up) t=%.1f" % [_pp(safari.planet.dir_of(q)),
		(q - safari.planet.surface_point(safari.planet.dir_of(q))).length(), _t])
	return true


## A point in the air MOTH_SCOUT_M along the lens (turned MOTH_SCOUT_YAW), MOTH_SCOUT_LIFT above the deck
## under it, in the middle of the view, seen along a clear line and clear of the other creatures' places
## by Pacing.CLEAR_M; Vector3.ZERO when there is none.
func _moth_air_spot(lens: Transform3D) -> Vector3:
	var p := safari.planet
	var o := lens.origin
	var up := p.up_at(o)
	var f := -lens.basis.z
	var others := pacing.other_places()
	for m: float in MOTH_SCOUT_M:
		for yaw: float in MOTH_SCOUT_YAW:
			var q := o + f.rotated(up, deg_to_rad(yaw)) * m
			var d := p.dir_of(q)
			var lift := (q - p.surface_point(d)).dot(p.up_at(q))
			if lift < MOTH_SCOUT_LIFT.x or lift > MOTH_SCOUT_LIFT.y:
				continue
			if not pacing.in_view_from(lens, q, pacing.SPOT_FRAME_FRAC) or not pacing.sight_clear(o, q):
				continue
			var crowded := false
			for c: Vector3 in others:
				if q.distance_to(c) < pacing.CLEAR_M:
					crowded = true
					break
			if not crowded:
				return q
	return Vector3.ZERO


## The scout swarm goes back into the dark once it has been out SCOUT_OUT_MIN_SEC and is out of the
## frame (so it is never seen to go), or when the planet sleeps.
func _tick_moth_scout() -> void:
	if _moth_scout < 0 or not _moth_scout_on:
		return
	if _sleeping or (_t - _moth_scout_since >= SCOUT_OUT_MIN_SEC \
			and not pacing.point_in_frame(_moth_centres[_moth_scout], SHY_FRAME_GROW)):
		_moth_scout_on = false


func _moth_front() -> Vector3:
	if _moth_pick < 0 or _moth_heads.is_empty():
		return Vector3.ZERO
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var lens := cam.global_position if cam != null else safari.player.global_position
	var best := -1
	var best_d := INF
	for k in MOTH_PER_SWARM:
		var i := _moth_pick * MOTH_PER_SWARM + k
		var dd := _moth_pos[i].distance_to(lens)
		if dd < best_d:
			best_d = dd
			best = i
	return _moth_heads[best] if best >= 0 else Vector3.ZERO


func _tick_moths() -> void:
	if _moth_herd == null:
		return
	if _sleeping:
		for i in _moth_centres.size() * MOTH_PER_SWARM:
			_moth_herd.hide_one(i)
		_moth_pick = -1
		return
	var moth_shy := pacing.shy("spark_moth")
	var burst := fmod(_t, MOTH_BURST_EVERY)
	var spread := 1.0 + (1.3 * sin(burst / MOTH_BURST_SEC * PI) if burst < MOTH_BURST_SEC else 0.0)
	_moth_scatter.resize(_moth_centres.size())
	_tick_moth_scout()
	for s in _moth_centres.size():
		var centre: Vector3 = _moth_centres[s]
		if s == _moth_scout:
			# the scout swarm gathers in while it is out and scatters off into the dark after (never shy:
			# the director brought it to be seen)
			_moth_scatter[s] = move_toward(_moth_scatter[s], 0.0 if _moth_scout_on else 1.0, get_process_delta_time() / 0.8)
			if _moth_scatter[s] >= 0.999:
				for k in MOTH_PER_SWARM:
					_moth_herd.hide_one(s * MOTH_PER_SWARM + k)
				continue
			_pose_swarm(s, centre, spread)
			continue
		# The swarm scatters while Bolt is up its mast (a tune-up), and settles back after: one sight
		# at a time on Antenna Hill, not the moths and the tune-up on screen together.
		var busy := _bolt_on_mast and _bolt_mast >= 0 and _bolt_mast < _masts.size() \
			and not (_masts[_bolt_mast] as Dictionary).is_empty() \
			and ((_masts[_bolt_mast] as Dictionary)["node"] as Node3D).global_position.distance_to(centre) < 4.0
		# one new thing at a time (SHY_SEC): out of the frame they go off into the dark, and gather again after
		if moth_shy and _moth_scatter[s] < 0.999 and not pacing.point_in_frame(centre, SHY_FRAME_GROW):
			_moth_scatter[s] = 1.0
		_moth_scatter[s] = move_toward(_moth_scatter[s], 1.0 if (busy or moth_shy) else 0.0, get_process_delta_time() / 0.8)
		if _moth_scatter[s] >= 0.999:
			for k in MOTH_PER_SWARM:
				_moth_herd.hide_one(s * MOTH_PER_SWARM + k)
			continue
		_pose_swarm(s, centre, spread)
	_moth_pick = _pick_focus(range(_moth_centres.size()), func(si: int) -> bool: return _moth_scatter[si] < 0.3,
		func(si: int) -> Vector3: return _moth_centres[si], 0.0)
	if _moth_pick >= 0:
		_moth_focus.global_position = _moth_centres[_moth_pick]

# ---------------------------------------------------------------------------------------- whale
func _build_whale() -> void:
	_whale = Node3D.new()
	_whale.name = "SkyWhale"
	add_child(_whale)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = Meshes.whale_body()
	body.material_override = _metal
	_whale.add_child(body)
	_whale_tail = Node3D.new()
	_whale_tail.name = "TailPivot"
	_whale_tail.position = Vector3(0.0, 0.05, 2.25)
	_whale.add_child(_whale_tail)
	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	tail.mesh = Meshes.whale_tail()
	tail.material_override = _metal
	_whale_tail.add_child(tail)
	# 34 puffs per 1.3 s lifetime was the emission rate for the old 1.1 s blow; the blow is now SPOUT_BLOW
	# long, so the rate is scaled by 1.1 / SPOUT_BLOW to keep the same puffs in each blow (a denser, not
	# thinner, spout).
	_whale_spout = _steam_emitter("Spout", roundi(34.0 * 1.1 / SPOUT_BLOW), 1.3, Color("#dfe7ee"), 0.10)
	_whale_spout.position = Vector3(0.0, 1.0, -1.25)
	_whale_spout.initial_velocity_min = 2.4
	_whale_spout.initial_velocity_max = 3.6
	_whale_spout.spread = 16.0
	_whale_spout.gravity = Vector3(0.0, -2.2, 0.0)
	_whale.add_child(_whale_spout)
	_whale.visible = false
	_whale_song = _sound("skiff_reveal", 0.5, -10.0)
	safari.add_subject({
		"id": "sky_whale", "name": "The Sky Whale", "rarity": 4, "kind": "event", "event": "sky_whale",
		"band": BAND_WHALE, "front": func() -> Vector3: return _front_of(_whale), "node": _whale, "offset": Vector3(0.0, 0.0, -0.3), "radius": 1.7,
		# The moments are what the picture SHOWS: the spout is up (its puffs are in the air from 0.3 s
		# after each blow until they thin out) AND this lens can see it (_spout_in_view), or the tail
		# is flicked past half its swing.
		"moment": func(tt: float) -> Dictionary:
			if _spout_visible(tt) and _spout_in_view(tt):
				return {"mult": 2.2, "line": "mid-spout!"}
			if _tail_flick(tt) > 0.3:
				return {"mult": 1.6, "line": "tail up!"}
			return {"mult": 1.0, "line": ""},
	})


## The spout blows for SPOUT_BLOW s every SPOUT_EVERY s, each blow STARTING inside WHALE_SPOUT (at
## 22 and 23.2 s; .y is 24.3, not 24.4, so ceilf below cannot round 2.4 / 1.2 up to a third blow that
## never happens); its puffs live 1.3 s. Seconds since the latest blow started, or -1 before the
## first. (The old rule took fmod over the whole window and so also counted 26.3-26.8 s, when no blow
## had started since 24 s and the air was empty.)
func _spout_phase(tt: float) -> float:
	if tt < WHALE_SPOUT.x:
		return -1.0
	var last := ceilf((WHALE_SPOUT.y - WHALE_SPOUT.x) / SPOUT_EVERY) - 1.0
	var n := minf(floorf((tt - WHALE_SPOUT.x) / SPOUT_EVERY), last)
	return tt - (WHALE_SPOUT.x + n * SPOUT_EVERY)


func _spout_visible(tt: float) -> bool:
	var ph := _spout_phase(tt)
	return ph >= 0.3 and ph < SPOUT_BLOW + 0.8


## How high a puff has risen above the blowhole at each age: the average puff integrated from the
## emitter's own numbers (mid velocity, mid damping, its gravity), SPOUT_STEPS steps over its life.
const SPOUT_STEPS := 200
## A puff counts as part of the picture while it is at least half as opaque as at its peak: the
## emitter's colour ramp peaks (0.62) at 12% of its life and falls straight to 0 at the end, so half
## is at 12% + 88% / 2 = 56% of its life.
const SPOUT_OPAQUE_UNTIL := 0.56


func _spout_heights() -> PackedFloat32Array:
	if not _spout_h.is_empty():
		return _spout_h
	var e := _whale_spout
	var v := (e.initial_velocity_min + e.initial_velocity_max) * 0.5
	var damp := (e.damping_min + e.damping_max) * 0.5
	var g := -e.gravity.y
	var dt := e.lifetime / float(SPOUT_STEPS)
	var h := 0.0
	_spout_h.append(0.0)
	for i in SPOUT_STEPS:
		v -= g * dt
		v = move_toward(v, 0.0, damp * dt)
		h += v * dt
		_spout_h.append(h)
	return _spout_h


## The puffs that are in the air at time `tt`, in the whale's own frame: three points spread over the
## ages of the puffs alive and still at least half opaque (the latest blow started `ph` s ago and
## lasted SPOUT_BLOW s). Empty when there are none.
func _spout_points(tt: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var ph := _spout_phase(tt)
	if ph < 0.0:
		return pts
	var life := _whale_spout.lifetime
	var a0 := maxf(0.0, ph - SPOUT_BLOW)
	var a1 := minf(ph, life * SPOUT_OPAQUE_UNTIL)
	if a1 <= a0:
		return pts
	var hs := _spout_heights()
	for f in [1.0 / 6.0, 0.5, 5.0 / 6.0]:
		var age := lerpf(a0, a1, f)
		var h := hs[clampi(roundi(age / life * SPOUT_STEPS), 0, SPOUT_STEPS)]
		pts.append(_whale_spout.position + Vector3.UP * h)
	return pts


## True when the spout can be seen from the lens the photo is taken with: more than half of the puffs
## in the air (_spout_points) are inside the frame and the line from the lens to them does not pass
## through the whale's body (a shot from underneath or head-on from below sees only belly).
func _spout_in_view(tt: float) -> bool:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	if cam == null or _whale == null or not _whale.visible:
		return false
	var pts := _spout_points(tt)
	if pts.is_empty():
		return false
	var frame := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var lens := _whale.global_transform.affine_inverse() * cam.global_position
	var seen := 0
	for q in pts:
		var w := _whale.global_transform * q
		if cam.is_position_behind(w) or not frame.has_point(cam.unproject_position(w)):
			continue
		if not Meshes.whale_body_hides(lens, q):
			seen += 1
	return seen * 2 > pts.size()


func _tail_flick(tt: float) -> float:
	if tt < WHALE_TAIL.x or tt >= WHALE_TAIL.y:
		return 0.0
	return 0.55 * sin((tt - WHALE_TAIL.x) / (WHALE_TAIL.y - WHALE_TAIL.x) * PI)


## The radius of the whale's circle over the far side, in degrees round the planet from F (0.8 m).
## F is the geyser's antipode, so every degree out from it is a degree nearer the geyser: the circle
## is kept tight (it was 8 degrees) so the pair keeps its full distance (probe `race`, Q4).
const WHALE_CIRCLE_DEG := 4.5


## The whale's path, in polar coordinates round the far side F (rho = degrees from F).
func _tick_whale(delta: float) -> void:
	# The song: from the first second (the warning), every 8.5 s until it has swum away; louder the
	# nearer you are to the far side, and heard everywhere.
	if _t >= _whale_song_next and _t < WHALE_END and not _sleeping and not _building:
		_whale_song_next += 8.5
		_whale_song.play()
	if _whale_song.playing:
		var ang := rad_to_deg(_player_dir().angle_to(_far))
		_whale_song.volume_db = lerpf(-3.0, -9.0, clampf(ang / 150.0, 0.0, 1.0))
	if not bool(_eligible.get("sky_whale", false)) or _t < WHALE_START or _t >= WHALE_END or _sleeping:
		return
	var ref := safari.start_fwd
	var rho: float
	var psi: float
	var alt: float
	var pitch := 0.0
	if _t < 16.0:
		var k := smoothstep(WHALE_START, 16.0, _t)
		rho = lerpf(25.0, WHALE_CIRCLE_DEG, k)
		psi = lerpf(-40.0, 0.0, k)
		alt = lerpf(1.9, 3.0, k)
		pitch = 0.18 * (1.0 - k)
	elif _t < 26.0:
		var k := (_t - 16.0) / 10.0
		rho = WHALE_CIRCLE_DEG
		psi = lerpf(0.0, 200.0, k)
		alt = 3.0 + 0.25 * sin(_t * 0.9)
	else:
		var k := smoothstep(26.0, WHALE_END, _t)
		rho = lerpf(WHALE_CIRCLE_DEG, 22.0, k)
		psi = 200.0 + 40.0 * k
		alt = lerpf(3.0, 17.0, k * k)
		pitch = 0.7 * smoothstep(26.0, 27.2, _t)
	var d := _polar(_far, ref, rho, psi)
	var d2 := _polar(_far, ref, rho + (0.0 if _t < 26.0 else 0.5), psi + (6.0 if _t >= 16.0 else -0.2))
	if _t < 16.0:
		d2 = _polar(_far, ref, rho - 0.5, psi + 1.0)
	var pos := safari.ground_point(d, alt)
	var up := safari.planet.up_at(pos)
	var fwd := safari.ground_point(d2, alt) - pos
	fwd -= up * fwd.dot(up)
	if fwd.length() < 0.001:
		fwd = _tangent_at(d)
	var b := Basis.looking_at(fwd.normalized(), up)
	b = b * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.FORWARD, 0.08 * sin(_t * 0.7))
	_whale.global_transform = Transform3D(b, pos)
	_whale_tail.rotation = Vector3(0.22 * sin(_t * 1.6) + _tail_flick(_t), 0.0, 0.0)
	var spout_on := _t >= WHALE_SPOUT.x and _t < WHALE_SPOUT.y and fmod(_t - WHALE_SPOUT.x, SPOUT_EVERY) < SPOUT_BLOW
	if spout_on and not _whale_spout.emitting:
		AudioManager.play_sfx_at("splash", _whale_spout.global_position, -2.0, 0.1)
	_whale_spout.emitting = spout_on




# ---------------------------------------------------------------------------------------- geyser
## Three vents in the deck (one herd, one draw call), always there; ONE jet, core and focus that move
## to whichever vent is due (GEYSER_RUNS: the uncommon tier, ~11 s each).
func _build_geyser() -> void:
	var mouths := Herd.new()
	add_child(mouths)
	var pts: Array = []
	for d: Vector3 in _geyser_dirs:
		pts.append(safari.planet.surface_point(d))
	mouths.setup("GeyserVents", _geyser_dirs.size(), [[Meshes.geyser_mouth(), _metal, false]], Herd.area_around(pts, 1.5))
	for i in _geyser_dirs.size():
		mouths.pose(i, 0, _xf_ground(_geyser_dirs[i], _tangent_at(_geyser_dirs[i])).translated_local(Vector3(0.0, -0.04, 0.0)))
	_geyser = Node3D.new()
	_geyser.name = "BigGeyser"
	add_child(_geyser)
	_geyser_core = MeshInstance3D.new()
	_geyser_core.name = "Core"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.34
	cm.bottom_radius = 0.20
	cm.height = 1.0
	cm.radial_segments = 14
	cm.rings = 2
	cm.cap_top = false
	cm.cap_bottom = false
	_geyser_core.mesh = cm
	_geyser_core.material_override = PlanetPropMeshes.puff_material(Color(0.84, 0.87, 0.91, 0.2))
	_geyser_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_geyser_core.visible = false
	_geyser.add_child(_geyser_core)
	_geyser_jet = _steam_emitter("Jet", 110, 1.6, Color("#d9e0e8"), 0.24)
	_geyser_jet.position = Vector3(0.0, 0.25, 0.0)
	_geyser_jet.spread = 7.0
	_geyser_jet.gravity = Vector3(0.0, -1.5, 0.0)
	_geyser.add_child(_geyser_jet)
	_geyser_focus = Node3D.new()
	_geyser_focus.name = "GeyserFocus"
	_geyser.add_child(_geyser_focus)
	_geyser_focus.position = Vector3(0.0, 2.6, 0.0)
	_geyser_whistle = _sound("jetpack_loop", 0.55, -30.0, true)
	_move_geyser(0)
	safari.add_subject({
		"id": "big_geyser", "name": "The Big Geyser", "rarity": 3, "kind": "event",
		"band": BAND_GEYSER, "node": _geyser_focus, "radius": 1.5,
		"awake": func() -> bool: return _any_running(GEYSER_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(GEYSER_RUNS, tt, false)
			if not run.is_empty():
				var b0 := float(run["start"]) + GEYSER_BLAST_AT
				if tt >= b0 and tt < b0 + GEYSER_BLAST_SEC:
					return {"mult": 2.0, "line": "full blast!"}
			return {"mult": 1.0, "line": ""},
	})


func _move_geyser(at: int) -> void:
	if at == _geyser_at:
		return
	_geyser_at = at
	var d: Vector3 = _geyser_dirs[at]
	_geyser.global_transform = _xf_ground(d, _tangent_at(d)).translated_local(Vector3(0.0, -0.04, 0.0))


func _tick_geyser(delta: float) -> void:
	if _sleeping:
		_geyser_whistle.stop()
		return
	var run := _run_at(GEYSER_RUNS, _t, true)
	if run.is_empty():
		if _geyser_whistle.playing:
			_geyser_whistle.stop()
		if _geyser_core.visible:
			_geyser_core.visible = false
		_geyser_jet.emitting = false
		return
	_move_geyser(int(run["at"]))
	var g0 := float(run["start"])
	var g1 := float(run["end"])
	var blast := Vector2(g0 + GEYSER_BLAST_AT, g0 + GEYSER_BLAST_AT + GEYSER_BLAST_SEC)
	var warn0 := g0 - WARN
	# The rising whistle over the 8 s warning: pitch and loudness climb together.
	if _t >= warn0 and _t < g0:
		var k := (_t - warn0) / WARN
		if not _geyser_whistle.playing:
			_geyser_whistle.play()
		_geyser_whistle.pitch_scale = lerpf(0.55, 1.7, k)
		_geyser_whistle.volume_db = lerpf(-13.0, -5.0, k)
		_puff_clock -= delta
		if _puff_clock <= 0.0:
			_puff_clock = lerpf(1.0, 0.35, k)
			safari.puff_at(_geyser.global_transform * Vector3(0.0, 0.3, 0.0), 6 + int(10.0 * k))
			# ...and the vents of the yard puff with it (every pipe and vent stack within 70 degrees).
			_puff_vents(k)
	elif _geyser_whistle.playing:
		_geyser_whistle.stop()
	if _t < g0 or _t >= g1:
		if _geyser_core.visible:
			_geyser_core.visible = false
		_geyser_jet.emitting = false
		return
	var h: float
	if _t < blast.x:
		h = 1.2 + 0.8 * absf(sin((_t - g0) * 3.2))
	elif _t < blast.y:
		h = lerpf(2.0, 6.0, smoothstep(blast.x, blast.x + 0.8, _t)) + 0.35 * sin(_t * 11.0)
	else:
		h = lerpf(5.5, 0.4, (_t - blast.y) / (g1 - blast.y))
	_geyser_core.visible = true
	_geyser_core.scale = Vector3(1.0 + 0.06 * sin(_t * 17.0), h, 1.0 + 0.06 * cos(_t * 15.0))
	_geyser_core.position = Vector3(0.0, 0.2 + h * 0.5, 0.0)
	_geyser_jet.emitting = true
	_geyser_jet.initial_velocity_min = 2.0 + h * 0.9
	_geyser_jet.initial_velocity_max = 3.0 + h * 1.2
	_geyser_focus.position = Vector3(0.0, maxf(1.2, h * 0.5), 0.0)


func _puff_vents(k: float) -> void:
	var props := safari.planet.get_node_or_null("Props")
	if props == null:
		return
	var here := safari.planet.dir_of(_geyser.global_position)
	for c in props.get_children():
		var nm := str(c.name)
		if not (nm.begins_with("Vent") or nm.begins_with("Pipe")):
			continue
		var n3 := c as Node3D
		if here.angle_to(safari.planet.dir_of(n3.global_position)) > deg_to_rad(70.0):
			continue
		if _rng.randf() < 0.5:
			safari.puff_at(n3.global_transform * Vector3(0.0, 1.5, 0.0), 4 + int(5.0 * k))


# ---------------------------------------------------------------------------------------- ring rain
## Three spots on the ring's circle (RAIN_RUNS: the common tier, 30 s each); ONE set of curtains and
## glints, moved to the spot that is due when its warning starts.
func _build_rain() -> void:
	_rain_root = Node3D.new()
	_rain_root.name = "RingRain"
	add_child(_rain_root)
	var root := _rain_root
	# Two curtains of the same ice on the same material: a light fall for the whole shower and a heavy
	# one only while it is at its thickest (the moment), so the picture shows the moment.
	# (CPUParticles3D has no amount_ratio in 4.7, and changing `amount` restarts an emitter.) Together
	# they are the 320 the single emitter had; the light one alone is 110.
	_rain_fall = _rain_curtain("Fall", 110)
	root.add_child(_rain_fall)
	_rain_heavy = _rain_curtain("FallThick", 210)
	root.add_child(_rain_heavy)
	_rain_glitter = CPUParticles3D.new()
	_rain_glitter.name = "Glitter"
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.1, 0.1)
	_rain_glitter.mesh = q2
	_rain_glitter.material_override = PlanetPropMeshes.sparkle_material(Color("#e2eefa"))
	_rain_glitter.amount = 70
	_rain_glitter.lifetime = 0.7
	_rain_glitter.local_coords = true
	_rain_glitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain_glitter.emission_box_extents = Vector3(2.6, 0.05, 2.6)
	_rain_glitter.direction = Vector3.UP
	_rain_glitter.spread = 40.0
	_rain_glitter.initial_velocity_min = 0.4
	_rain_glitter.initial_velocity_max = 1.1
	_rain_glitter.gravity = Vector3(0.0, -1.5, 0.0)
	_rain_glitter.position = Vector3(0.0, 0.25, 0.0)
	_rain_glitter.emitting = false
	root.add_child(_rain_glitter)
	_rain_focus = Node3D.new()
	_rain_focus.name = "RainFocus"
	root.add_child(_rain_focus)
	_rain_focus.position = Vector3(0.0, 3.2, 0.0)
	# The ring's glint: five soft stars on the ring itself, straight above the rain (the ring is the
	# one sky object fixed to the planet, and it is in view from nearly everywhere).
	var ring := safari.world.get_node_or_null("Environment/Ring") as PlanetRing
	if ring != null:
		_ring_r = (ring.inner_radius + ring.outer_radius) * 0.5
		_ring_c = ring.global_position
	_glint_mat = MaterialLib.glow_sprite(Color("#dcebff"), 2.6, {"softness": 0.1, "core": 0.3, "points": 1.0, "blink": 0.4, "blink_speed": 5.0}).duplicate() as ShaderMaterial
	for k in 5:
		var g := MeshInstance3D.new()
		g.name = "Glint%d" % k
		var gq := QuadMesh.new()
		gq.size = Vector2.ONE * (2.4 if k == 2 else 1.6)
		g.mesh = gq
		g.material_override = _glint_mat
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.extra_cull_margin = 4.0
		add_child(g)
		g.visible = false
		_glints.append(g)
	_move_rain(0)
	safari.add_subject({
		"id": "ring_rain", "name": "Ring Rain", "rarity": 2, "kind": "event",
		"band": BAND_RAIN, "node": _rain_focus, "radius": 2.6,
		"awake": func() -> bool: return _any_running(RAIN_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(RAIN_RUNS, tt, false)
			if not run.is_empty():
				var k0 := float(run["start"]) + RAIN_THICK_AT
				if tt >= k0 and tt < k0 + RAIN_THICK_SEC:
					return {"mult": 1.8, "line": "in the thick of it"}
			return {"mult": 1.0, "line": ""},
	})


## The curtains, their subject and the ring's glints to spot `at`.
func _move_rain(at: int) -> void:
	if at == _rain_at:
		return
	_rain_at = at
	var d: Vector3 = _rain_dirs[at]
	_rain_root.global_transform = _xf(d, _tangent_at(d))
	for k in _glints.size():
		var dirk := d.rotated(_ring_n, deg_to_rad(-10.0 + 5.0 * float(k))).normalized()
		_glints[k].global_position = _ring_c + dirk * (_ring_r + (float(k % 2) - 0.5) * 3.0)


## Seconds a drop takes from the emitter down to the height of the rain's subject centre (the part a
## photo is scored on): d = v t + g t^2 / 2 solved for t, with the emitter's mid speed and its gravity.
func _rain_fall_time() -> float:
	var e := _rain_heavy
	var d := e.position.y - _rain_focus.position.y
	var v := (e.initial_velocity_min + e.initial_velocity_max) * 0.5
	var g := -e.gravity.y
	return (-v + sqrt(v * v + 2.0 * g * d)) / g if g > 0.0 else d / v


func _rain_curtain(label: String, amount: int) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.name = label
	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	e.mesh = q
	e.material_override = PlanetPropMeshes.sparkle_material(Color("#cfe2f5"))
	e.amount = amount
	e.lifetime = 2.0
	e.local_coords = true
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	e.emission_box_extents = Vector3(3.0, 1.2, 3.0)
	e.direction = Vector3.DOWN
	e.spread = 6.0
	e.initial_velocity_min = 5.0
	e.initial_velocity_max = 6.5
	e.gravity = Vector3(0.0, -5.0, 0.0)
	e.scale_amount_min = 0.6
	e.scale_amount_max = 1.3
	e.position = Vector3(0.0, 12.5, 0.0)
	e.emitting = false
	return e


func _tick_rain(delta: float) -> void:
	var run := _run_at(RAIN_RUNS, _t, true) if not _sleeping else {}
	var glint := 0.0
	var r0 := 0.0
	var r1 := 0.0
	if not run.is_empty():
		_move_rain(int(run["at"]))
		r0 = float(run["start"])
		r1 = float(run["end"])
		var warn0 := r0 - WARN
		glint = clampf((_t - warn0) / 3.0, 0.0, 1.0) if _t < r0 else lerpf(1.0, 0.5, clampf((_t - r0) / 6.0, 0.0, 1.0))
		if _t < r0:
			_chime_clock -= delta
			if _chime_clock <= 0.0:
				_chime_clock = 1.7
				var s := _sound_once("collect_stardust", 0.72, -9.0)
				s.play()
	for g in _glints:
		g.visible = glint > 0.01
	_glint_mat.set_shader_parameter("fade", glint)
	var raining := not run.is_empty() and _t >= r0 and _t < r1
	_rain_fall.emitting = raining
	# The heavy curtain starts falling 12.5 m up, so it is started early enough to reach the subject's
	# centre as the moment begins (fall time from its speed and gravity) and stopped to leave it with it.
	var lead := _rain_fall_time()
	var thick := r0 + RAIN_THICK_AT
	_rain_heavy.emitting = raining and _t >= thick - lead and _t < thick + RAIN_THICK_SEC - lead
	_rain_glitter.emitting = raining and _t >= r0 + 1.2
	if raining:
		_chime_clock -= delta
		if _chime_clock <= 0.0:
			_chime_clock = 3.0
			var near := rad_to_deg(_player_dir().angle_to(_rain_dirs[_rain_at]))
			var s := _sound_once("finale_shower", 1.1, lerpf(-5.0, -20.0, clampf(near / 120.0, 0.0, 1.0)))
			s.play()

# ---------------------------------------------------------------------------------------- magnet
func _build_magnet() -> void:
	var p := safari.planet
	_magnet_root = Node3D.new()
	_magnet_root.name = "GreatMagnet"
	add_child(_magnet_root)
	var fwd := _toward(_magnet_dir, safari.start_dir)
	_magnet_root.global_transform = _xf_ground(_magnet_dir, fwd).translated_local(Vector3(0.0, -0.03, 0.0))
	var hatch := MeshInstance3D.new()
	hatch.name = "Hatch"
	hatch.mesh = Meshes.hatch()
	hatch.material_override = _metal
	hatch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_magnet_root.add_child(hatch)
	_magnet = MeshInstance3D.new()
	_magnet.name = "Magnet"
	_magnet.mesh = Meshes.magnet()
	_magnet.material_override = _metal
	_magnet_root.add_child(_magnet)
	_magnet.position = Vector3(0.0, -2.4, 0.0)
	_magnet.visible = false
	var pts: Array = []
	for i in 16:
		var rho_m := _rng.randf_range(0.95, 2.7)
		var d := p.step_dir(_magnet_dir, _polar(_magnet_dir, fwd, 30.0, _rng.randf_range(0.0, 360.0)), rho_m)
		var face := _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU))
		var rest := _xf(d, face) * Transform3D(Basis(Vector3.RIGHT, PI * 0.5 * float(i % 2)) , Vector3(0.0, 0.035 + 0.04 * float(i % 2), 0.0))
		_scrap.append({"rest": rest, "phase": _rng.randf_range(0.0, TAU), "h": _rng.randf_range(0.7, 2.6),
			"r": _rng.randf_range(0.7, 1.9), "a": _rng.randf_range(0.0, TAU), "spin": _rng.randf_range(1.0, 3.0)})
		pts.append(rest.origin)
	pts.append(_magnet_root.global_transform * Vector3(0.0, 3.2, 0.0))
	_scrap_herd = Herd.new()
	add_child(_scrap_herd)
	_scrap_herd.setup("LooseBolts", 8, [[Meshes.loose_bolt(), _metal, true], [Meshes.loose_nut(), _metal, true]],
		Herd.area_around(pts, 2.0))
	_magnet_focus = Node3D.new()
	_magnet_focus.name = "MagnetFocus"
	_magnet_root.add_child(_magnet_focus)
	_magnet_focus.position = Vector3(0.0, 1.6, 0.0)
	_hum = _sound("comms_bed", 0.35, -30.0, true)
	safari.add_subject({
		"id": "great_magnet", "name": "The Great Magnet", "rarity": 4, "kind": "rare", "event": "great_magnet",
		"band": BAND_MAGNET, "node": _magnet_focus, "radius": 1.8,
		"moment": func(tt: float) -> Dictionary:
			return {"mult": 2.0, "line": "everything afloat"} if tt >= MAGNET_AFLOAT.x and tt < MAGNET_AFLOAT.y else {"mult": 1.0, "line": ""},
	})


func _tick_magnet() -> void:
	if _scrap_herd == null:
		return
	var on := bool(_eligible.get("great_magnet", false))
	var warn0 := MAGNET_START - WARN
	# the hum: over the warning it swells, heard everywhere; while it runs it follows your distance
	if on and not _sleeping and _t >= warn0 and _t < MAGNET_END + 1.0:
		if not _hum.playing:
			_hum.play()
		var near := rad_to_deg(_player_dir().angle_to(_magnet_dir))
		var swell := clampf((_t - warn0) / 3.0, 0.0, 1.0)
		# heard anywhere through the warning (-8 dB), then by your distance while it runs
		var level := -8.0 if _t < MAGNET_START else lerpf(-5.0, -15.0, clampf(near / 150.0, 0.0, 1.0))
		_hum.volume_db = lerpf(-24.0, level, swell)
		_hum.pitch_scale = 0.35 + 0.02 * sin(_t * 3.0)
	elif _hum.playing:
		_hum.stop()
	# the magnet rises out of its hatch at the start and sinks at the end
	var rise := 0.0
	# It rises over 1.6 s and sinks over the last MAGNET_SINK s of the event, so nothing of it is
	# still standing (and photographable-looking) once the event - and its subject - has ended.
	if on and _t >= MAGNET_START and _t < MAGNET_END:
		rise = smoothstep(MAGNET_START, MAGNET_START + 1.6, _t) * (1.0 - smoothstep(MAGNET_END - MAGNET_SINK, MAGNET_END, _t))
	if _sleeping:
		rise = 0.0
	_magnet.visible = rise > 0.001
	_magnet_focus.position = Vector3(0.0, 0.35 + 1.25 * rise, 0.0)
	_magnet.position = Vector3(0.0, lerpf(-2.4, 0.0, rise), 0.0)
	_magnet.rotation = Vector3(0.0, 0.5 * sin(_t * 0.35), 0.0)
	var up := _magnet_root.global_basis.y.normalized()
	var axis := _magnet_root.global_position
	for i in _scrap.size():
		var sc: Dictionary = _scrap[i]
		var rest: Transform3D = sc["rest"]
		var xf := rest
		var jitter := 0.0
		if on and _t >= warn0 and _t < MAGNET_START:
			jitter = 0.02 * sin(_t * 47.0 + float(sc["phase"]))
			xf = rest.translated(up * absf(jitter))
		# The bolts float up one by one over SCRAP_RISE s, are ALL afloat exactly while the moment
		# ("everything afloat", MAGNET_AFLOAT) runs, and drop back to the deck straight after it - the
		# picture shows the moment, and nothing else looks like it.
		var lift := 0.0
		if on and not _sleeping and _t >= MAGNET_START and _t < MAGNET_END:
			var up0 := MAGNET_AFLOAT.x - SCRAP_RISE + 0.5 * float(i % 5)
			lift = smoothstep(up0, maxf(up0 + 0.8, MAGNET_AFLOAT.x - 0.05), _t) \
				* (1.0 - smoothstep(MAGNET_AFLOAT.y, MAGNET_AFLOAT.y + SCRAP_DROP, _t))
		if lift > 0.0:
			var a := float(sc["a"]) + _t * 0.45
			var r := float(sc["r"])
			var side := _magnet_root.global_basis.x.normalized()
			var fwd := _magnet_root.global_basis.z.normalized()
			var fly_pos := axis + up * (float(sc["h"]) + 0.12 * sin(_t * 1.7 + float(sc["phase"]))) + (side * cos(a) + fwd * sin(a)) * r
			var tumble := Basis(Vector3(0.3, 1.0, 0.5).normalized(), _t * float(sc["spin"]) + float(sc["phase"]))
			var fly := Transform3D(_magnet_root.global_basis.orthonormalized() * tumble, fly_pos)
			xf = rest.interpolate_with(fly, lift)
		_scrap_herd.pose(i % 8, 0 if i < 8 else 1, xf)




# ---------------------------------------------------------------------------------------- snail
## Two crossings (SNAIL_RUNS, the common tier): first it comes HOME along the far road to Bolt's place
## (_snail_c -> _snail_a), rests there as a kettle, then sets off to the crates (_snail_a -> _snail_b,
## Q4's crossing). Between crossings it is just a kettle sitting where it stopped.
func _build_snail() -> void:
	_snail = Node3D.new()
	_snail.name = "ScrapSnail"
	add_child(_snail)
	_snail_body = MeshInstance3D.new()
	_snail_body.name = "Body"
	_snail_body.mesh = Meshes.snail_body()
	_snail_body.material_override = _metal
	_snail.add_child(_snail_body)
	_snail_shell = MeshInstance3D.new()
	_snail_shell.name = "Kettle"
	_snail_shell.mesh = Meshes.snail_shell()
	_snail_shell.material_override = _metal
	_snail.add_child(_snail_shell)
	_snail_shell.position = Vector3(0.0, 0.0, 0.15)
	_snail_body.scale = Vector3.ONE * 0.001
	_snail_body.visible = false
	_snail_whistle = _sound("jetpack_loop", 2.1, -30.0, true)
	_snail_order = SNAIL_RUNS.duplicate()
	_snail_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["start"]) < float(b["start"]))
	_place_snail_on(int(_snail_order[0]["at"]), 0.0)
	safari.add_subject({
		"id": "scrap_snail", "name": "The Scrap Snail", "rarity": 2, "kind": "event",
		"band": BAND_SNAIL, "node": _snail, "offset": Vector3(0.0, 0.55, 0.0), "radius": 0.85,
		"awake": func() -> bool: return _any_running(SNAIL_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(SNAIL_RUNS, tt, false)
			if not run.is_empty():
				var w := _snail_whistle_window(run)
				if tt >= w.x and tt < w.y:
					return {"mult": 2.0, "line": "kettle whistling!"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_snail),
	})


func _snail_whistle_window(run: Dictionary) -> Vector2:
	var e := float(run["end"])
	return Vector2(e - SNAIL_WHISTLE_BEFORE, e - SNAIL_WHISTLE_STOP)


func _snail_road(at: int) -> Array:
	return [_snail_a, _snail_b] if at == 0 else [_snail_c, _snail_a]


func _place_snail_on(at: int, k: float) -> void:
	var road := _snail_road(at)
	var a: Vector3 = road[0]
	var b: Vector3 = road[1]
	var d := a.slerp(b, k).normalized()
	var ahead := a.slerp(b, minf(k + 0.02, 1.0)).normalized()
	var fwd := safari.planet.surface_point(ahead) - safari.planet.surface_point(d)
	if k >= 0.999 or fwd.length() < 0.001:
		fwd = safari.planet.surface_point(b) - safari.planet.surface_point(a)
	_snail.global_transform = _xf(d, fwd)


## The crossing the snail is on, or the last one it made, or (before any) the first: never empty.
func _snail_run_now() -> Dictionary:
	var cur: Dictionary = _snail_order[0]
	for run: Dictionary in _snail_order:
		if _t >= float(run["start"]) - WARN:
			cur = run
	return cur


func _tick_snail(delta: float) -> void:
	var run := _snail_run_now()
	var s0 := float(run["start"])
	var s1 := float(run["end"])
	var w := _snail_whistle_window(run)
	var ok := bool(_eligible.get(str(run["id"]), false))
	var warn0 := s0 - WARN
	# the kettle rocks and its bell clanks over the warning (heard everywhere)
	var rock := 0.0
	if ok and _t >= warn0 and _t < s0 + 2.0 and not _sleeping:
		rock = 0.10 * sin(_t * 9.0) * (1.0 if _t < s0 else 0.4)
		_bell_clock -= delta
		if _bell_clock <= 0.0 and _t < s0:
			_bell_clock = 2.0
			_sound_once("quest_accept", 0.5, -6.0).play()
			AudioManager.play_sfx_at("footstep_metal_0", _snail.global_position, 0.0, 0.1)
	_snail_shell.rotation = Vector3(0.0, 0.0, rock)
	var out := 0.0
	if ok and _t >= s0 and not _sleeping:
		out = smoothstep(s0, s0 + 2.0, _t) * (1.0 - smoothstep(s1, s1 + 1.5, _t))
	_snail_body.visible = out > 0.01
	var stretch := 1.0 + 0.07 * sin(_t * 3.0) * (1.0 if _t < w.x else 0.2)
	_snail_body.scale = Vector3(out, out, out * stretch)
	_snail_shell.position = Vector3(0.0, 0.2 * out + 0.03 * sin(_t * 3.0) * out, 0.15 + 0.02 * sin(_t * 3.0))
	var road := clampf((_t - (s0 + 2.0)) / (w.x - s0 - 2.0), 0.0, 1.0)
	if _t >= s0 and ok:
		_place_snail_on(int(run["at"]), road)
	# Its warning glow follows it: the event's direction is the snail itself.
	if _beacons.has("scrap_snail"):
		(_beacons["scrap_snail"] as Node).set_meta("dir", safari.planet.dir_of(_snail.global_position))
	var whistling := ok and _t >= w.x and _t < w.y and not _sleeping
	if whistling:
		if not _snail_whistle.playing:
			_snail_whistle.play()
		var near := rad_to_deg(_player_dir().angle_to(safari.planet.dir_of(_snail.global_position)))
		_snail_whistle.volume_db = lerpf(-8.0, -26.0, clampf(near / 90.0, 0.0, 1.0))
		_snail_whistle.pitch_scale = 2.1 + 0.08 * sin(_t * 5.0)
		_puff_clock -= delta
		if _puff_clock <= 0.0:
			_puff_clock = 0.35
			safari.puff_at(_snail_shell.global_transform * Vector3(0.0, 0.62, -0.62), 6)
	elif _snail_whistle.playing:
		_snail_whistle.stop()


# ---------------------------------------------------------------------------------------- Bolt
func _build_bolt() -> void:
	_bolt = safari.world.get_node_or_null("NPCs/bolt") as Node3D
	if _bolt == null:
		return
	_bolt_saved = _bolt.global_transform
	_bolt_wander_saved = bool(_bolt.get("_wander_on")) if _bolt.get("_wander_on") != null else true
	safari.add_subject({
		"id": "bolt", "name": "Bolt", "rarity": 1, "kind": "neighbour",
		"band": BAND_BOLT, "node": _bolt, "offset": Vector3(0.0, 0.75, 0.0), "radius": 0.72,
		# Up a mast he IS the tune-up (that subject scores him, with his front): one subject, not two.
		"awake": func() -> bool: return is_instance_valid(_bolt) and _bolt.is_visible_in_tree() and not _bolt_borrowed,
		"moment": func(_tt: float) -> Dictionary:
			if _t < _bolt_pose_until:
				return {"mult": 1.8, "line": "striking a pose"}
			if _t < _bolt_wave_until:
				return {"mult": 1.6, "line": "waving at you"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_bolt),
	})


## Both masts (MASTS): where Bolt stands at the foot and which way he faces. He climbs the side of the
## mast that is square-on to a walker coming from the start, so he is seen in profile beside it (not
## hidden behind it), turned three-quarters toward the start.
func _build_tune_up() -> void:
	var p := safari.planet
	for nm: String in MASTS:
		var ant := p.get_node_or_null("Props/" + nm) as Node3D
		if nm == ANTENNA_NAME and _antenna != null:
			ant = _antenna
		if ant == null:
			_masts.append({})
			continue
		var mi := ant.get_node_or_null("Mesh") as Node3D
		var s := mi.scale.x if mi != null else 1.0
		var up := ant.global_basis.y.normalized()
		var toward := safari.planet.surface_point(safari.start_dir) - ant.global_position
		toward -= up * toward.dot(up)
		if toward.length() < 0.5:
			# the small mast is near the start: face the way the start looks, from its left
			toward = -safari.start_fwd
			toward -= up * toward.dot(up)
		var side := toward.normalized() if toward.length() > 0.01 else ant.global_basis.x.normalized()
		var mast_side := up.cross(side).normalized()
		# THE DISH (R4, seen in frames 2026-09-24): PlanetPropMeshes.antenna_tower hangs its dish at 0.62
		# of the mast's height (1.86 m on Antenna Hill, 2.1 m by the pad), tilted down toward the mesh's
		# -Z. The old climb (1.05 m up, 0.30 m from the axis) put Bolt's 1.4 m head through it on BOTH
		# masts. He now climbs the tripod leg on the dish's HIGH side (the leg at 120 degrees in the
		# mesh, toward +Z), MAST_OFF_TOP from the axis, and stops at MAST_CLIMB_M: his head top is then
		# 2.05 m x scale, under the dish's underside there (about 2.18 m x scale).
		if mi != null:
			var leg := mi.global_basis * Vector3(cos(TAU / 3.0), 0.0, sin(TAU / 3.0))
			leg -= up * leg.dot(up)
			if leg.length() > 0.01:
				mast_side = leg.normalized()
		var off_top := MAST_OFF_TOP
		var top := MAST_CLIMB_M * s
		var face := (-mast_side * 0.5 + side).normalized()
		var base := Transform3D(Basis.looking_at(face, up), ant.global_position + mast_side * MAST_OFF_GROUND)
		_masts.append({"node": ant, "s": s, "up": up, "side": mast_side, "face": face, "base": base,
			"off_top": off_top, "top": top})
	if _masts.is_empty() or (_masts[0] as Dictionary).is_empty():
		return
	_use_mast(0)
	_tune_focus = Node3D.new()
	_tune_focus.name = "TuneFocus"
	add_child(_tune_focus)
	_tune_focus.global_transform = _bolt_base.translated_local(Vector3(0.0, 1.9 * _antenna_s, 0.0))
	_sparks = CPUParticles3D.new()
	_sparks.name = "Sparks"
	var q := QuadMesh.new()
	q.size = Vector2(0.13, 0.13)
	_sparks.mesh = q
	_sparks.material_override = PlanetPropMeshes.sparkle_material(Color("#ffb35c"))
	_sparks.amount = 70
	_sparks.lifetime = 0.9
	_sparks.explosiveness = 0.5
	_sparks.local_coords = true
	# a fountain: up and out, falling round the mast (not sprayed at the lens)
	_sparks.direction = Vector3(0.0, 1.0, 0.0)
	_sparks.spread = 75.0
	_sparks.initial_velocity_min = 1.6
	_sparks.initial_velocity_max = 3.6
	_sparks.gravity = Vector3(0.0, -7.0, 0.0)
	_sparks.scale_amount_min = 0.6
	_sparks.scale_amount_max = 1.4
	_sparks.emitting = false
	add_child(_sparks)
	_place_sparks()
	safari.add_subject({
		"id": "tune_up", "name": "Bolt's Tune-up", "rarity": 3, "kind": "event",
		"band": BAND_TUNE, "node": _tune_focus, "radius": 1.0,
		"awake": func() -> bool: return _any_running(TUNE_RUNS),
		"moment": func(tt: float) -> Dictionary:
			var run := _run_at(TUNE_RUNS, tt, false)
			if not run.is_empty():
				var b: Vector2 = run["best"]
				if tt >= b.x and tt < b.y:
					return {"mult": 2.0, "line": "sparks flying!"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_bolt),
	})


## Points the climb (foot, side, face, the antenna's scale) at mast `i`.
func _use_mast(i: int) -> void:
	var m: Dictionary = _masts[i]
	if m.is_empty():
		return
	_bolt_mast = i
	_mast_side = m["side"]
	_mast_up = m["up"]
	_bolt_face = m["face"]
	_bolt_base = m["base"]
	_antenna_s = float(m["s"])
	_mast_off_top = float(m["off_top"])
	_mast_top = float(m["top"])


func _place_sparks() -> void:
	var m: Dictionary = _masts[maxi(_bolt_mast, 0)]
	var ant: Node3D = m["node"]
	_sparks.global_transform = Transform3D(Basis.looking_at(_bolt_face, _mast_up),
		ant.global_position + _mast_up * (1.9 * _antenna_s) + _mast_side * 0.16)


func _tick_bolt(_delta: float) -> void:
	if _bolt == null or not is_instance_valid(_bolt) or _sleeping or _building:
		return
	# ---- a tune-up (he is borrowed from its warning to its end)
	var run := _run_at(TUNE_RUNS, _t, true) if _sparks != null else {}
	if not run.is_empty() and not (_masts[int(run["at"])] as Dictionary).is_empty():
		var t0 := float(run["start"])
		var t1 := float(run["end"])
		var best: Vector2 = run["best"]
		if not _bolt_borrowed or _bolt_mast != int(run["at"]):
			_borrow_bolt(int(run["at"]))
		var ant: Node3D = (_masts[_bolt_mast] as Dictionary)["node"]
		var y := 0.0
		var climbing := false
		if _t < t0:
			y = 0.0
		elif _t < t0 + 4.0:
			y = lerpf(0.0, _mast_top, (_t - t0) / 4.0)
			climbing = true
		elif _t < t1 - 4.0:
			y = _mast_top + 0.04 * sin(_t * 6.0)
		else:
			y = lerpf(_mast_top, 0.0, (_t - (t1 - 4.0)) / 4.0)
			climbing = true
		_bolt_on_mast = y > 0.05
		var k := clampf(y / _mast_top, 0.0, 1.0)
		var at := ant.global_position + _mast_up * y + _mast_side * lerpf(MAST_OFF_GROUND, _mast_off_top, k)
		_bolt.global_transform = Transform3D(Basis.looking_at(_bolt_face, _mast_up), at)
		_bolt.set("_speed_factor", 1.0 if climbing else 0.0)
		_tune_focus.global_transform = _bolt.global_transform.translated_local(Vector3(0.0, 0.9, -0.2))
		var sparking := _t >= best.x and _t < best.y and fmod(_t, 1.0) < 0.65
		if sparking and not _sparks.emitting:
			AudioManager.play_sfx_at("place", _sparks.global_position, -2.0, 0.3)
		_sparks.emitting = sparking
		if climbing and fmod(_t, 0.5) < _delta_safe():
			AudioManager.play_sfx_at("footstep_metal_1", _bolt.global_position, -6.0, 0.15)
		return
	if _bolt_borrowed:
		_release_bolt(false)
		_sparks.emitting = false
		_bolt.call("play_emote", "happy")
		_bolt_pose_until = _t + 1.6
	# ---- brought by the director: he stands BOLT_STAY_SEC, then wanders on
	if _bolt_stay_until > -INF and _t >= _bolt_stay_until:
		_bolt_stay_until = -INF
		if _bolt.has_method("wander_enabled"):
			_bolt.call("wander_enabled", _bolt_wander_saved)
	# ---- waves when you come close; poses ON HIS OWN RHYTHM while you are near (BOLT_POSE_EVERY), never
	# because a camera points at him (spec 16)
	var pl := safari.player
	var dist := _bolt.global_position.distance_to(pl.global_position)
	if dist < 3.6 and _t >= _bolt_next_wave:
		_bolt.call("face_player", true)
		_bolt.call("play_emote", "wave")
		_bolt_wave_until = _t + 1.6
		_bolt_next_wave = _t + 7.0
	var near := dist < BOLT_POSE_NEAR_M
	if near and not _bolt_pose_near:
		# you have just come within range: his first pose is a little while off, not now
		_bolt_next_pose = maxf(_bolt_next_pose, _t + _rng.randf_range(BOLT_POSE_FIRST.x, BOLT_POSE_FIRST.y))
	_bolt_pose_near = near
	if near and _t >= _bolt_next_pose and _t >= _bolt_wave_until:
		_bolt.call("face_player", true)
		_bolt.call("play_emote", "happy")
		_bolt_pose_until = _t + BOLT_POSE_SEC
		_bolt_next_pose = _t + _rng.randf_range(BOLT_POSE_EVERY.x, BOLT_POSE_EVERY.y)
		_bolt_next_wave = maxf(_bolt_next_wave, _t + 3.0)


func _delta_safe() -> float:
	return maxf(get_process_delta_time(), 0.001)


func _borrow_bolt(mast: int) -> void:
	var first := not _bolt_borrowed
	_bolt_stay_until = -INF
	_bolt_borrowed = true
	_use_mast(mast)
	_place_sparks()
	var from := _bolt.global_position
	_bolt.call("play_emote", "wave")
	var where := "over on Antenna Hill" if mast == 0 else "by " + _place_name(safari.planet.dir_of(_bolt_base.origin))
	_queue_line("Bolt: \"Up I go!\"  (%s)" % where)
	for k in 3:
		AudioManager.play_sfx_at("voice_robot_%d" % k, from, 0.0, 0.1)
	AudioManager.play_sfx("voice_robot_3", -4.0)
	safari.puff_at(from, 22)
	AudioManager.play_sfx_at("jump", from, -2.0)
	if first:
		if _bolt.has_method("wander_enabled"):
			_bolt.call("wander_enabled", false)
		_bolt.set_physics_process(false)
	_bolt.global_transform = _bolt_base
	safari.puff_at(_bolt_base.origin, 22)


## THE PACING DIRECTOR brings BOLT (THE CURIOUS ONES): when it has gone quiet he comes over, with a
## puff, to see what you are photographing, stands BOLT_STAY_SEC looking where you look (he turns to you
## and poses for a camera held on him, _tick_bolt), then wanders on. Not while a tune-up has him or will
## within his stay, not when he is near you or in view already, and not twice within BOLT_COME_REST s.
## The numbers are Fen's (fen.gd FEN_COME_REST / FEN_RISE_MAX / FEN_STAY_SEC), not tuned here.
const BOLT_COME_REST := 25.0
const BOLT_RISE_MAX := 1.7
const BOLT_STAY_SEC := 10.0
const BOLT_COME_LINES := ["Bolt: \"Inspection. What is in your frame?\"", "Bolt: \"Reporting in. Carry on.\"",
	"Bolt: \"Walk-round check. Log me if needed.\""]


func _bolt_can_come() -> bool:
	if _bolt == null or not is_instance_valid(_bolt) or _sleeping or _bolt_borrowed:
		return false
	if _t - _bolt_came_at < BOLT_COME_REST:
		return false
	# a tune-up borrows him from its warning: his whole stay must end before that
	for run: Dictionary in TUNE_RUNS:
		var s0 := float(run["start"]) - WARN
		if bool(_eligible.get(str(run["id"]), false)) and _t < float(run["end"]) and _t + BOLT_STAY_SEC + 1.0 > s0:
			return false
	var head := _bolt.global_position + safari.planet.up_at(_bolt.global_position) * 0.75
	return _bolt.global_position.distance_to(safari.player.global_position) > 8.0 and not pacing.point_in_frame(head, 1.1)


func _bring_bolt(spot: Dictionary) -> bool:
	var d: Vector3 = spot["dir"]
	if d == Vector3.ZERO and spot["ahead"] != Vector3.ZERO and float(spot["rise"]) >= 0.0 and float(spot["rise"]) <= BOLT_RISE_MAX:
		d = spot["ahead"]
	if d == Vector3.ZERO or not _bolt_can_come() or _near_built(d, BUILT_CLEAR_M + 0.3):
		return false
	var p := safari.planet
	safari.puff_at(_bolt.global_position, 14)
	var g := p.surface_point(d)
	var up := p.up_at(g)
	var lens: Transform3D = spot["lens"]
	var face := -lens.basis.z
	face -= up * face.dot(up)
	if face.length() < 0.01:
		face = _tangent_at(d)
	face = face.normalized().rotated(up, _rng.randf_range(-0.5, 0.5))
	_bolt.global_transform = Transform3D(Basis.looking_at(face, up), g)
	if _bolt is CharacterBody3D:
		(_bolt as CharacterBody3D).velocity = Vector3.ZERO
	if _bolt.has_method("wander_enabled"):
		_bolt.call("wander_enabled", false)
	safari.puff_at(g, 18)
	_bolt.call("play_emote", "wave")
	_bolt_next_wave = _t + 8.0
	AudioManager.play_sfx_at("voice_robot_%d" % (_bolt_came_n % 3), g, -2.0, 0.1)
	_queue_line(BOLT_COME_LINES[_bolt_came_n % BOLT_COME_LINES.size()])
	_bolt_came_n += 1
	_bolt_came_at = _t
	_bolt_stay_until = _t + BOLT_STAY_SEC
	_log("Bolt comes over to %s t=%.1f" % [_pp(d), _t])
	return true


## Gives Bolt back to his own script. `home` also puts him back where he stood before the safari.
func _release_bolt(home: bool) -> void:
	if _bolt == null or not is_instance_valid(_bolt):
		return
	if _bolt_stay_until > -INF and not _bolt_borrowed and _bolt.has_method("wander_enabled"):
		_bolt.call("wander_enabled", _bolt_wander_saved)
	_bolt_stay_until = -INF
	if _bolt_borrowed:
		_bolt.set("_speed_factor", 0.0)
		_bolt.set_physics_process(true)
		if _bolt.has_method("wander_enabled"):
			_bolt.call("wander_enabled", _bolt_wander_saved)
	_bolt_borrowed = false
	_bolt_on_mast = false
	if home:
		_bolt.global_transform = _bolt_saved
		if _bolt is CharacterBody3D:
			(_bolt as CharacterBody3D).velocity = Vector3.ZERO


# ---------------------------------------------------------------------------------------- sights (spec 15.5)
## THE ANTENNA MAST and BOLT'S WORKSHOP (see SIGHTS AND BONUS).
func _build_sights() -> void:
	var p := safari.planet
	if _antenna != null:
		_mast_focus = Node3D.new()
		_mast_focus.name = "MastFocus"
		add_child(_mast_focus)
		_mast_focus.global_position = _antenna.global_transform * Vector3(0.0, 1.55 * _antenna_s, 0.0)
		safari.add_subject({
			"id": "antenna_mast", "name": "The Antenna Mast", "kind": "sight", "category": "sight",
			"band": BAND_MAST, "node": _mast_focus, "radius": 1.55 * _antenna_s,
			"awake": func() -> bool: return not _sleeping,
		})
	# the workshop: the clearest flat spot WORKSHOP_RING_DEG round from Bolt's home, off the snail's roads
	var roads: Array[Vector3] = []
	for k in 25:
		roads.append(_snail_c.slerp(_snail_a, float(k) / 24.0).normalized())
		roads.append(_snail_a.slerp(_snail_b, float(k) / 24.0).normalized())
	var avoid: Array[Vector3] = [_pad_dir, safari.start_dir]
	avoid.append_array(_crab_places)
	avoid.append_array(_geyser_dirs)
	var best := -INF
	var t0 := _tangent_at(_home_dir)
	for rho: float in WORKSHOP_RING_DEG:
		for k in 24:
			var d := _polar(_home_dir, t0, rho, 15.0 * float(k))
			var clear := p.nearest_prop_distance(d)
			if clear < WORKSHOP_PROP_CLEAR_M or p.ground_normal(d).angle_to(d) > deg_to_rad(7.0):
				continue
			var road := INF
			for q: Vector3 in roads:
				road = minf(road, p.surface_distance(d, q))
			if road < WORKSHOP_ROAD_CLEAR_M:
				continue
			var away := INF
			for q: Vector3 in avoid:
				away = minf(away, p.surface_distance(d, q))
			if away < 4.0:
				continue
			var score := minf(clear, 2.5) + 0.5 * minf(road, 3.0) - 0.05 * rho
			if score > best:
				best = score
				_workshop_dir = d
	if _workshop_dir != Vector3.ZERO:
		_workshop = _built_thing("BoltsWorkshop", Meshes.workshop(), _workshop_dir,
			BoxShape3D.new(), Vector3(Meshes.WORKSHOP_W - 0.1, Meshes.WORKSHOP_H - 0.2, Meshes.WORKSHOP_D))
		safari.add_subject({
			"id": "workshop", "name": "Bolt's Workshop", "kind": "sight", "category": "sight",
			"band": BAND_WORKSHOP, "node": _workshop, "offset": Vector3(0.0, 1.0, 0.0), "radius": WORKSHOP_RADIUS,
			"awake": func() -> bool: return not _sleeping,
			"front": func() -> Vector3: return _front_of(_workshop),
		})
	else:
		push_warning("BoltSafari: no clear spot for Bolt's workshop")
	_log("sights: mast %s workshop %s (%.1f m from Bolt's home)" % [
		_pp(_antenna_dir), _pp(_workshop_dir) if _workshop_dir != Vector3.ZERO else "-",
		p.surface_distance(_workshop_dir, _home_dir) if _workshop_dir != Vector3.ZERO else -1.0])


## A thing built for the safari at ground direction `d`, its front (-Z) turned toward the start, with a
## collider (`shape`, `size`: a box's size or a cylinder's (radius, height, -)) on the NPC layer: it
## blocks the player and every sight ray, but not Bolt (see SIGHTS AND BONUS).
func _built_thing(label: String, mesh: ArrayMesh, d: Vector3, shape: Shape3D, size: Vector3) -> Node3D:
	var p := safari.planet
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1 << 2
	body.collision_mask = 0
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.material_override = _metal
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	if shape is BoxShape3D:
		(shape as BoxShape3D).size = size
		cs.position = Vector3(0.0, size.y * 0.5, 0.0)
	elif shape is CylinderShape3D:
		(shape as CylinderShape3D).radius = size.x
		(shape as CylinderShape3D).height = size.y
		cs.position = Vector3(0.0, size.y * 0.5, 0.0)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	var to_start := _toward(d, safari.start_dir)
	body.global_transform = _xf_ground(d, to_start).translated_local(Vector3(0.0, -0.02, 0.0))
	return body


## True when the ground spot `d` is within `margin` m of the workshop's or the plinth's footprint.
func _near_built(d: Vector3, margin: float) -> bool:
	var p := safari.planet
	if _workshop_dir != Vector3.ZERO and p.surface_distance(d, _workshop_dir) < 1.2 + margin:
		return true
	if _plinth_dir != Vector3.ZERO and p.surface_distance(d, _plinth_dir) < 0.45 + margin:
		return true
	return false


# ---------------------------------------------------------------------------------------- bonus (spec 15.5)
## THE THREE COLLECTOR'S THINGS (see SIGHTS AND BONUS): small and tucked away, but each in plain sight of
## a curious wanderer who walks round the prop it is on or behind.
func _build_bonus() -> void:
	var p := safari.planet
	# A LOST SOCK on the arm of SOCK_PIPE: the arm is on the side of the pipe's nozzle (its steam, placed
	# by PlanetProps at -0.62 m x scale on the mesh's x), 0.17 m thick, (0.9 + 0.3 (i % 3)) m up (planet
	# props, steam_pipe)
	var pipe := p.get_node_or_null("Props/" + SOCK_PIPE) as Node3D
	var pmi := pipe.get_node_or_null("Mesh") as Node3D if pipe != null else null
	if pmi != null:
		var i := int(SOCK_PIPE.trim_prefix("Pipe"))
		var h := 0.9 + 0.3 * float(i % 3)
		var ps := pmi.scale.x
		var hang := pmi.global_transform * Vector3(-SOCK_OUT_M / ps, h - 0.17, 0.0)
		var up := p.up_at(hang)
		var arm := (pmi.global_transform.basis * Vector3(-1.0, 0.0, 0.0)).normalized()
		arm = (arm - up * arm.dot(up)).normalized()
		_sock = MeshInstance3D.new()
		_sock.name = "LostSock"
		(_sock as MeshInstance3D).mesh = Meshes.sock()
		(_sock as MeshInstance3D).material_override = _prop_mat
		add_child(_sock)
		# hung from the arm's underside, the foot pointing along the arm (out toward the nozzle)
		_sock.global_transform = Transform3D(Basis.looking_at(arm, up), hang)
		_sock.set_meta("rest", _sock.global_transform)
		_sock_focus = Node3D.new()
		_sock_focus.name = "SockFocus"
		_sock.add_child(_sock_focus)
		_sock_focus.position = Vector3(0.0, -0.13, -0.03)
		safari.add_subject({
			"id": "lost_sock", "name": "A Lost Sock", "kind": "bonus", "category": "bonus",
			"band": BAND_SOCK, "node": _sock_focus, "radius": 0.15,
			"awake": func() -> bool: return not _sleeping,
		})
	# "BOLT No. 1" out behind a radiator on the far side, its plaque toward the start
	_plinth_dir = _free_near(safari.dir_from_start(P_BOLT_NO_1.x, P_BOLT_NO_1.y), 1.1)
	_plinth = _built_thing("BoltNo1", Meshes.bolt_no_1(), _plinth_dir, CylinderShape3D.new(), Vector3(0.42, 1.45, 0.0))
	safari.add_subject({
		"id": "bolt_no_1", "name": "\"Bolt No. 1\"", "kind": "bonus", "category": "bonus",
		"band": BAND_BOLT_NO_1, "node": _plinth, "offset": Vector3(0.0, 0.72, 0.0), "radius": 0.72,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_plinth),
	})
	# A WELDED SMILEY on the side of SMILEY_CRATE that faces away from the start (not the stencilled +Z
	# face): the crate is (0.95 + 0.22 (i % 3)) m wide, (0.72 + 0.16 ((i + 1) % 3)) m tall, 0.85 m deep
	# (planet props, supply_crate), times its scale
	var crate := p.get_node_or_null("Props/" + SMILEY_CRATE) as Node3D
	var cmi := crate.get_node_or_null("Mesh") as Node3D if crate != null else null
	if cmi != null:
		var i := int(SMILEY_CRATE.trim_prefix("Crate"))
		var w := 0.95 + 0.22 * float(i % 3)
		var hgt := 0.72 + 0.16 * float((i + 1) % 3)
		var away := _toward(p.dir_of(crate.global_position), -safari.start_dir)
		var best_face := Vector3.ZERO
		var best_dot := -INF
		for f: Vector3 in [Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0)]:
			var dd := (cmi.global_basis * f).normalized().dot(away)
			if dd > best_dot:
				best_dot = dd
				best_face = f
		var local := Vector3(best_face.x * w * 0.5, hgt * 0.45, best_face.z * 0.425) + best_face * 0.004
		var at := cmi.global_transform * local
		var out := (cmi.global_basis * best_face).normalized()
		var up := p.up_at(at)
		out = (out - up * out.dot(up)).normalized()
		_smiley = MeshInstance3D.new()
		_smiley.name = "CrateSmiley"
		(_smiley as MeshInstance3D).mesh = Meshes.crate_smiley()
		(_smiley as MeshInstance3D).material_override = _metal
		add_child(_smiley)
		# the mesh's beads point along its -Z: out of the crate's face
		_smiley.global_transform = Transform3D(Basis.looking_at(out, up), at)
		safari.add_subject({
			"id": "crate_smiley", "name": "A Welded Smiley", "kind": "bonus", "category": "bonus",
			"band": BAND_SMILEY, "node": _smiley, "offset": Vector3(0.0, 0.0, -0.03), "radius": 0.2,
			"awake": func() -> bool: return not _sleeping,
			"front": func() -> Vector3: return _front_of(_smiley),
		})
	_log("bonus: sock on %s at %s, Bolt No. 1 at %s, smiley on %s at %s" % [SOCK_PIPE,
		_pp(p.dir_of(_sock.global_position)) if _sock != null else "-", _pp(_plinth_dir), SMILEY_CRATE,
		_pp(p.dir_of(_smiley.global_position)) if _smiley != null else "-"])


## The sock sways a little on its pipe, more while the pipe's steam puffs past it.
func _tick_bonus() -> void:
	if _sock != null and _sock.has_meta("rest"):
		var rest: Transform3D = _sock.get_meta("rest")
		var sway := 0.10 * sin(_t * 1.7) + 0.05 * sin(_t * 4.3 + 1.0)
		_sock.global_transform = Transform3D(rest.basis * Basis(Vector3(0.0, 0.0, 1.0), sway), rest.origin)


# ======================================================================================== SCHEDULE
## Every event run is its own PlanetSafari event (its own id, so event_running and the "woke" count
## work per run); the runs of one kind share one warning glow and one subject.
func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line]
	var ev: Array = []
	ev.append(["sky_whale", "sky_whale", "The Sky Whale", WHALE_START, WHALE_END, _far, "any", Color("#9fc3e8"),
		"A long, low song drifts over from the FAR SIDE..."])
	for run: Dictionary in GEYSER_RUNS:
		var d: Vector3 = _geyser_dirs[int(run["at"])]
		var line := "The deck whistles by the landing pad... something's building up!" if int(run["at"]) == 0 \
			else "The deck whistles by %s... something's building up!" % _place_name(d)
		ev.append(["big_geyser", run["id"], "The Big Geyser", run["start"], run["end"], d, "any", Color("#eef0f2"), line])
	ev.append(["great_magnet", "great_magnet", "The Great Magnet", MAGNET_START, MAGNET_END, _magnet_dir, "only", Color("#e0876e"),
		"Everything metal starts to hum... out past the vents!"])
	for run: Dictionary in RAIN_RUNS:
		var d: Vector3 = _rain_dirs[int(run["at"])]
		var line := "Bolt's ring glints over the GEAR GROVE..." if int(run["at"]) == 0 \
			else "Bolt's ring glints over %s..." % _place_name(d)
		ev.append(["ring_rain", run["id"], "Ring Rain", run["start"], run["end"], d, "any", Color("#cfe2f5"), line])
	for run: Dictionary in SNAIL_RUNS:
		var road := _snail_road(int(run["at"]))
		var line := "A bell clanks over at Bolt's place..." if int(run["at"]) == 0 \
			else "A bell clanks over by %s..." % _place_name(road[0])
		ev.append(["scrap_snail", run["id"], "The Scrap Snail", run["start"], run["end"], road[0], "any", Color("#9fd3c8"), line])
	for run: Dictionary in TUNE_RUNS:
		var m: Dictionary = _masts[int(run["at"])] if int(run["at"]) < _masts.size() else {}
		var d := safari.planet.dir_of((m["node"] as Node3D).global_position) if not m.is_empty() else _antenna_dir
		ev.append(["tune_up", run["id"], "Bolt's Tune-up", run["start"], run["end"], d, "any", Color("#ffb35c"), ""])
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
				if line != "":
					# PlanetSafari's own control hint holds the one banner for the first 4.5 s, so a
					# line due then waits for it (the whale's: its song and glow still start at once).
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


func _on_start(kind: String) -> void:
	match kind:
		"sky_whale":
			_whale.visible = true
		"big_geyser":
			AudioManager.play_sfx_at("rocket_ignite", _geyser.global_position, 2.0, 0.05)
			safari.puff_at(_geyser.global_transform * Vector3(0.0, 0.3, 0.0), 24)
		"great_magnet":
			safari.puff_at(_magnet_root.global_position, 24)
			AudioManager.play_sfx_at("door_open", _magnet_root.global_position, 0.0)
		"scrap_snail":
			safari.puff_at(_snail.global_position + safari.planet.up_at(_snail.global_position) * 0.3, 14)
		"tune_up":
			AudioManager.play_sfx_at("emote_wave", _bolt_base.origin, 0.0)


func _on_end(kind: String) -> void:
	match kind:
		"sky_whale":
			_whale.visible = false
			_whale_spout.emitting = false
		"big_geyser":
			safari.puff_at(_geyser.global_transform * Vector3(0.0, 0.6, 0.0), 18)
		"great_magnet":
			AudioManager.play_sfx_at("tree_shake", _magnet_root.global_position, 0.0)
		"scrap_snail":
			pass
		"tune_up":
			if _sparks != null:
				_sparks.emitting = false


## The run of `runs` whose window holds `tt` (from its warning when `with_warn`) and that is eligible
## today, or {}. The runs of one kind never overlap, warnings included.
func _run_at(runs: Array, tt: float, with_warn: bool) -> Dictionary:
	for run: Dictionary in runs:
		var s0 := float(run["start"]) - (WARN if with_warn else 0.0)
		if tt >= s0 and tt < float(run["end"]) and bool(_eligible.get(str(run["id"]), false)):
			return run
	return {}


## True while any run of `runs` is running (PlanetSafari's own event clock).
func _any_running(runs: Array) -> bool:
	for run: Dictionary in runs:
		if safari.event_running(str(run["id"])):
			return true
	return false

# ---------------------------------------------------------------------------------------- beacons
## (star.gdshader's `softness` is where the edge STARTS to fall off: 0 = a soft gradient from the
## centre, 0.9 = a hard-edged disc. Measured on the first pass, which drew hard ovals.)
## A warning glow: a soft star that sits on YOUR horizon in the direction of its event (24 degrees
## round from you, lifted 1.3 m), so "that way" reads from anywhere on the planet; it fades out once
## you are within 38 degrees, where the event itself is in view.
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
		# Hidden while the camera is up: the glow is for choosing where to WALK, and it must not end up
		# in the photographs.
		if safari.camera_up:
			want = 0.0
		var lv := move_toward(float(b.get_meta("level", 0.0)), want, delta * (4.0 if safari.camera_up else 1.5))
		b.set_meta("level", lv)
		b.visible = lv > 0.01
		if not b.visible:
			continue
		# Toward the event along the great circle; when the event is (nearly) straight through the
		# planet every way is the way, so the glow sits on the horizon straight ahead of the lens.
		var tdir := target - pd * target.dot(pd)
		if ang > 165.0 or tdir.length() < 0.05:
			var cf := -safari.rig.get_view_camera().global_transform.basis.z if safari.rig != null and safari.rig.get_view_camera() != null else safari.start_fwd
			tdir = cf - pd * cf.dot(pd)
		if tdir.length() < 0.001:
			tdir = _tangent_at(pd)
		var a := deg_to_rad(minf(BEACON_AHEAD_DEG, ang))
		var along := (pd * cos(a) + tdir.normalized() * sin(a)).normalized()
		b.global_position = safari.ground_point(along, 0.75)
		(b.material_override as ShaderMaterial).set_shader_parameter("fade", lv * (0.72 + 0.28 * sin(_t * 3.4)))




# ======================================================================================== TICK
## One banner at a time: a line waits for the intro hint (INTRO_HINT_SEC) and for the line before it
## to have had LINE_SEC on screen (with repeated events two warnings can fall due in the same second -
## the whale's and Bolt's at the start - and the second replaced the first a frame later).
const LINE_SEC := 3.6


func _queue_line(text: String) -> void:
	var due := maxf(_t, INTRO_HINT_SEC)
	if not _lines.is_empty():
		due = maxf(due, float(_lines[-1][0]) + LINE_SEC)
	elif _t < _line_free_at:
		due = maxf(due, _line_free_at)
	_lines.append([due, text])


func tick(t: float, delta: float) -> void:
	_t = t
	if not _lines.is_empty() and not _building and _t >= float(_lines[0][0]) and not _sleeping:
		safari.announce(str(_lines[0][1]), 3.5)
		_line_free_at = _t + LINE_SEC
		_lines.pop_front()
	_tick_crabs(delta)
	_tick_beetles(delta)
	_tick_hoppers(delta)
	_tick_moths()
	_tick_whale(delta)
	_tick_geyser(delta)
	_tick_rain(delta)
	_tick_magnet()
	_tick_snail(delta)
	_tick_bolt(delta)
	_tick_bonus()
	_tick_beacons(delta)


## The three minutes are up: the crabs dive into their burrows, the hoppers spring down into the deck,
## everything else goes in the puff that PlanetSafari makes at each awake subject, the warnings and
## sounds stop. Bolt is handed back to his own script at once and put back where he stood when this
## node leaves (behind the black fade).
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_whale, _geyser_core, _magnet, _snail]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for pr: CPUParticles3D in [_geyser_jet, _rain_fall, _rain_heavy, _rain_glitter, _sparks, _whale_spout]:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false
		for g in _glints:
			g.visible = false
		if _scrap_herd != null:
			for i in 8:
				_scrap_herd.hide_one(i))
	if _bolt_borrowed:
		_release_bolt(false)
	return true


func _exit_tree() -> void:
	_release_bolt(true)


# ======================================================================================== HELPERS
## Of `items` that `ok` accepts, the one nearest the middle of the view (the one being aimed at);
## -1 when none is awake. Ties and off-view ones go by distance. R4: of the (up to four) best in view,
## the first whose middle the lens can SEE (one ray, `lift` metres above `pos_of`) - so a crab behind a
## crate does not win over the one beside it that is in the picture.
func _pick_focus(items: Array, ok: Callable, pos_of: Callable, lift: float) -> int:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var cands: Array = []
	for i in items.size():
		if not bool(ok.call(items[i])):
			continue
		var p: Vector3 = pos_of.call(items[i])
		var score := 1000.0
		if cam != null:
			var to := p - cam.global_position
			var dist := to.length()
			var ang := rad_to_deg((-cam.global_transform.basis.z).angle_to(to / maxf(dist, 0.001)))
			score = ang + dist * 0.05 if ang < 35.0 else 100.0 + dist
		cands.append([score, i, p])
	if cands.is_empty():
		return -1
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if cam == null:
		return int(cands[0][1])
	var space := get_world_3d().direct_space_state
	for k in mini(cands.size(), 4):
		if float(cands[k][0]) >= 100.0:
			break
		var p: Vector3 = cands[k][2]
		if _sight_clear(space, cam.global_position, p + safari.planet.up_at(p) * lift):
			return int(cands[k][1])
	return int(cands[0][1])


## True when a ray from the lens to `q` meets nothing before it gets within 0.3 m of it.
func _sight_clear(space: PhysicsDirectSpaceState3D, from: Vector3, q: Vector3) -> bool:
	if space == null:
		return true
	var ex: Array[RID] = []
	if is_instance_valid(safari.player):
		ex.append(safari.player.get_rid())
	var rq := PhysicsRayQueryParameters3D.create(from, q, 0xFFFFFFFF, ex)
	rq.collide_with_areas = false
	var hit := space.intersect_ray(rq)
	return hit.is_empty() or (hit["position"] as Vector3).distance_to(q) <= 0.3

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


## Upright on the ground at `d` but tilted to the local ground slope (small things sitting ON the
## deck: a flat disc on the radial up floats on one side of a slope).
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


## A soft steam emitter on the shipped puff material (the same look as PlanetSafari's own puffs).
func _steam_emitter(label: String, amount: int, life: float, colour: Color, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = label
	var m := SphereMesh.new()
	m.radius = size
	m.height = size * 2.0
	m.radial_segments = 14
	m.rings = 7
	m.material = PlanetPropMeshes.puff_material(Color.WHITE)
	p.mesh = m
	p.amount = amount
	p.lifetime = life
	# Local: gravity and direction are then in the emitter's own frame, whose +Y is the planet's up
	# there (a global gravity would point the wrong way on a sphere).
	p.local_coords = true
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 5.0
	p.damping_min = 0.6
	p.damping_max = 1.2
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(colour, 0.0))
	ramp.add_point(0.12, Color(colour, 0.62))
	ramp.set_color(ramp.get_point_count() - 1, Color(colour, 0.0))
	p.color_ramp = ramp
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = grow
	p.emitting = false
	return p


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


## A one-shot 2D sound: a pool of one player per effect name, re-used.
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
	print("[BoltSafari] " + msg)




## Everything a test needs to find the subjects and places (the probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"far": _far, "geyser": _geyser_dir, "vent_field": _vent_field, "rain": _rain_dir, "magnet": _magnet_dir,
		"antenna": _antenna_dir, "snail_a": _snail_a, "snail_b": _snail_b, "home": _home_dir,
		"snail_c": _snail_c, "geysers": _geyser_dirs.duplicate(), "rains": _rain_dirs.duplicate(),
		"crab_places": _crab_places.duplicate(),
		"crabs": _crabs.map(func(c: Dictionary) -> Vector3: return c["burrow"]),
		"crab_states": _crabs.map(func(c: Dictionary) -> int: return int(c["state"])),
		"crab_dirs": _crabs.map(func(c: Dictionary) -> Vector3: return c["dir"]),
		"beetle_xf": _beetles.map(func(b: Dictionary) -> Transform3D: return b.get("xf", Transform3D())),
		"beetle_states": _beetles.map(func(b: Dictionary) -> int: return int(b["state"])),
		"hopper_dirs": _hoppers.map(func(h: Dictionary) -> Vector3: return h["dir"]),
		"hopper_states": _hoppers.map(func(h: Dictionary) -> int: return int(h["state"])),
		"moth_centres": _moth_centres.duplicate(),
		"moth_scout": _moth_scout, "moth_scout_on": _moth_scout_on,
		"workshop": _workshop_dir, "plinth": _plinth_dir,
		"sock": _sock.global_position if _sock != null else Vector3.ZERO,
		"smiley": _smiley.global_position if _smiley != null else Vector3.ZERO,
		"eligible": _eligible.duplicate(),
	}
