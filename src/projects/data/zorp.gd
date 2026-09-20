extends RefCounted
## Zorp's project (docs/BUILD_PLAN.md Phase 3b, builder ZORP). Schema: src/projects/project_system.gd
## header. Shaped after src/projects/data/bolt.gd (the shipped Phase 2 example).
##
## THE WORLD PROBLEM (docs/CORE_LOOP.md "World problems": Zorp): his violet hollow's glowing blue
## rivers are DIMMING. Three steps, one per game day, end with the rivers relit and part_zorp:
##   0. minigame - fly the river's old ring course, end to end ("rings", flavour "light" - his own
##      river lights, catch_game.gd's FLAVOURS table, read by ring_game.gd - "label": "river light").
##   1. find     - the three springs that feed the river, now the dimmest thing on the whole world.
##   2. place    - stake a river lamp at the first (dimmest) spring; Zorp hands it over the moment he
##      asks (he built it overnight, same shape as bolt.gd's regulator - see "ONE ITEM" below), and
##      gives part_zorp once it is standing.
## No "talk" step: exactly like bolt.gd, the project's own "intro" IS the first talk (spoken right
## before step 0's "ask", in the same conversation), so a separate talk step would only repeat it.
## NO LIGHT LINK (docs/BUILD_PLAN.md Phase 3b table: Zorp's link column is empty) - both steps that
## need a world stay on Zorp's own, tier-1 world (docs/CORE_LOOP.md "Range tiers": Zorp is reachable
## from the very start, so nothing here may point at a planet that is not).
##
## ============================================================================ WHY THIS STEP ORDER
## CORE_LOOP's own first idea already runs minigame -> find -> place (unlike bolt's find -> minigame
## -> place), and it reads better for Zorp specifically: the ring run comes FIRST and doubles as the
## reveal of the problem - he flies you down the river's whole old course so you SEE how far the dark
## has spread, before naming a cause (the dim springs) or a fix (the lamp). Bolt already found his
## three machines before he can describe what is wrong with them; Zorp can show you his river before
## he can explain it, because floating IS how Zorp experiences his own planet (npc_data.gd small_talk:
## "I floated for six hours yesterday. Bliss.").
##
## ============================================================================ THE RING COUNT: 6
## ring_game.gd's own default is `clampi(round(TAU * radius / TARGET_SPACING_M), 4, 10)`. Zorp's
## planet radius is 10.5 m (data/zorp.tres `radius = 10.5`) and TARGET_SPACING_M is 11.0
## (ring_game.gd), so: round(TAU * 10.5 / 11.0) = round(5.997) = 6. That IS what the engine would
## pick with no "count" at all - it is written here explicitly (the "minigame" step schema requires
## an explicit "count" >= 1 at the PROJECT level; project_system.gd's `_invalid_reason` rejects a
## minigame step with none) rather than left to chance, but it is the measured default for THIS
## world, not an invented number (CLAUDE.md "no fitted constants").
##
## "near": Zorp's own `home_dir` (npc_data.gd), not the player's live position - ring_game.gd's own
## "WHY NO PLAYER FALLBACK" note is explicit that a live-position anchor breaks a resumed course, and
## home_dir is exactly the kind of stable anchor the header recommends ("a neighbour's yard, say").
## The player is standing right next to Zorp when the course is asked for, so it opens in view without
## being tied to wherever he has since wandered (`wander_radius_m` 9.0 keeps him from staying put).
## "height" and "seed" are left at the engine defaults - height_mid 2.3 sits mid-band for a 1.0-3.6 m
## course and there is no world-specific reason to move it; the default seed already hashes in the
## owner, planet id and planet seed, so the same save always gets the same course with no override
## needed (ring_game.gd `setup()`).
##
## ================================================================================ THE ITEM: reused
## "a lamp decoration from the catalog", per the brief. Catalog decorations considered (every "lights"
## row in decoration_catalog.gd) and why each was passed over:
##   moon_lamp       warm gold (#ffe27a) - wrong family; Zorp's rivers are BLUE, not warm.
##   crystal_lamp    violet (#b28dff) - matches the HOLLOW's own ground, but not the water.
##   star_projector  pale blue (#cfe4ff) - about a night sky, not a river.
##   plasma_campfire cold blue flame (#8fdcff) - close in hue, but reads as a campfire, not a lamp
##                   staked in mud at a spring.
##   beacon_tower    red/orange (#ff5c5c) - wrong hue AND a tall wayfinding tower, not a spring-side
##                   marker.
##   orb_light       CHOSEN. Its core/glow constants (`#65c5d9`, `#6ac0d9`, `#79c4d9` - orb_light.gd)
##                   sit in the same cyan-blue family as the rivers themselves (zorp.tres
##                   `water_color` (0.544, 0.7596, 0.85) and STYLE_GUIDE's own "rivers `#3ec6ff`
##                   glowing"), it is already a small hovering light rather than a themed prop (fits
##                   "staked at a spring", not "a campfire" or "a tower"), and its 0.5 m footprint is
##                   the smallest of the six, so it reads as one lamp rather than a monument.
## Wrapped as a NEW project item (id "zorp_river_lamp") reusing orb_light.tscn's geometry - the exact
## pattern bolt.gd's Yard Regulator set (reusing control_console.tscn): new id/name/desc/icon_color,
## same "scene", footprint matched to the scene's own `DecoItem.footprint` (orb_light.gd:12 -
## `footprint = 0.5`). icon_color reuses orb_light's OWN shipped catalog swatch (#7fe9ff,
## decoration_catalog.gd) rather than inventing a new one, since it is still literally that object.
##
## NO "scrap_cost" - Zorp builds it himself overnight and GIVES it, exactly like bolt.gd's regulator:
## step 2's "give" hands it over the moment the step is ASKED (the talk the day after the springs are
## found), so it is already in the bag, ready to place, before the "ask" lines even finish (schema:
## "give"/`_ask` docs). The bench never offers to build it (schema: "0 or absent = the bench does not
## build this item").
##
## ONE LAMP, NOT THREE (mirrors bolt.gd's "ONE ITEM, NOT THREE" - Zorp's own voice decides it, same as
## Bolt's): CORE_LOOP says "the three dimmest springs" (plural) but a "place" step is one spot, one
## radius. Zorp is a curious optimist, not a careful counter like Bolt - "one good light and the rest
## should catch" is exactly the kind of hopeful, slightly-uncertain leap his own lines already take
## (npc_data.gd small_talk plays the same way: "I grew a plant. It grew sideways. Rude." - he reports
## what happens, right or wrong). The lamp goes at the FIRST spring found (spot "marker:s1_m0" - find
## is step 1 here, not step 0, so its markers are "s1_m0.."), the same "aim at an earlier find step's
## first marker" shape as bolt.gd's "marker:s0_m0".
##
## THE PROBLEM STAYS FIXED: the lamp is a real placed decoration (GameState.add_placed_decoration via
## DecorationManager), so it stands on Zorp's world for good after the project ends - the rivers read
## as helped, not as an errand that vanishes (docs/BUILD_PLAN.md Phase 3b rules).
##
## ================================================================================ SCRAP ARITHMETIC
## Independently measured off data/zorp.tres (CLAUDE.md "Evidence rules": measure, don't reason - not
## assumed from bolt.gd's numbers even though they land the same):
##   GameState.STARTING_SCRAP = 5                                       (game_state.gd:15,23)
##   scrap collectible pays randi_range(3,6), avg 4.5, floor 3          (collectible.gd:198-202)
##   zorp.tres: collectible_count=10, collectible_kind =
##     "crystal_chunk,moon_flower,crystal_chunk,moon_flower,scrap" - a 5-entry list with exactly ONE
##     "scrap" entry, cycled twice over the 10 spawns (kind = kinds[i % kinds.size()],
##     planet_props.gd:2387-2404) -> "scrap" lands at i=4 and i=9 -> 2 scrap pickups/day, avg 9/day,
##     floor 6/day. IDENTICAL structure to bolt's world (also a 5-entry list, one "scrap" entry, cycled
##     twice) - the two tier-1 worlds share the same scrap rate by coincidence of authoring, not by
##     this file assuming it.
## This project's OWN scrap cost is zero (the lamp is given, never built) - the only scrap spent is
## part_fit_scrap at the bench, so the same bar bolt.gd computed applies here for the same reason:
##   Absolute floor (no pickups at all): start 5, spend 0 -> still 5 at the part's arrival.
##     5 < 8: the fit is NOT affordable on zero pickups (the player must pick up scrap at least once,
##     same as bolt.gd - unchanged by this project existing).
##   Realistic floor (one guaranteed floor-roll pickup, of the 2 days x 2 scrap spawns/day = 4
##     available before the part can arrive - CORE_LOOP's one-step-a-day rule puts the earliest
##     arrival at day (start + 2), exactly as bolt.gd derives): 5 + 3 = 8 -> exactly covers the fit.
##   Two days' full floor-roll pickups (2 days x 2 spawns x 3 each = 12): 5 + 12 = 17 -> fit for 8 ->
##     9 left. Any average roll (9/day) clears it with room to spare.
## part_fit_scrap is set to 8 - the same number as bolt.gd, arrived at independently from zorp's own
## data, not copied: two tier-1 worlds with the same measured scrap rate and the same zero-cost item
## design land on the same bar. CLAUDE.md's "no fitted constants" rule argues against moving it without
## a timed play-through showing it is actually wrong (Phase 6).
##
## Voice (docs/CORE_LOOP.md "World problems": Zorp is "the exclamation-heavy, curious alien who loves
## floating"; npc_data.gd "zorp" entry - intro, greet and small_talk all read the same way: short
## exclaiming bursts, a word repeated for emphasis ("Zorp is pleased. Zorp is very pleased!"), curious
## asides, never quite certain his own guesses are right ("I grew a plant. It grew sideways. Rude.").
## No Animal Crossing words (docs/ARCHITECTURE.md §1.1). Every line <= 60 characters, 1-3 lines per
## list (project_system.gd "Writing").

const ITEM_ID := "zorp_river_lamp"
const RING_COUNT := 6


static func definition() -> Dictionary:
	return {
		"npc": "zorp",
		"part": "part_zorp",
		"part_fit_scrap": 8,
		"intro": [
			"Oh no, oh no! My rivers are going DARK!",
			"They used to glow all night! Now: barely.",
			"You have a jetpack! Please, come look!",
		],
		"part_lines": [
			"The river HUMS again! Do you hear it? Hear it?!",
			"Take this coil - wound from real river-light!",
			"New fact: you are my best friend. Confirmed!",
		],
		"part_again": [
			"You lost the coil? I wound a spare. Obviously!",
		],
		"items": [
			{
				"id": ITEM_ID,
				"name": "River Lamp",
				"kind": "decoration",
				"category": "lights",
				"desc": "A bottled bit of river-glow, staked in the mud at the spring.",
				"icon_color": "#7fe9ff",
				# Reused decoration scene (schema: "any shipped decoration scene may be reused").
				# footprint must match the scene's own DecoItem.footprint (orb_light.gd:12).
				"scene": "res://src/decorations/items/orb_light.tscn",
				"footprint": 0.5,
				# No "scrap_cost": Zorp builds this himself overnight and GIVES it (step 2's "give") -
				# the bench must not offer to build it (schema: "0 or absent = the bench does not
				# build this item; it comes from a talk step's give").
			},
		],
		"steps": [
			{
				"type": "minigame",
				"title": "Fly the old river run",
				"game": "rings",
				"count": RING_COUNT,
				"config": {
					"flavour": "light",
					"title": "The Old River Run",
					"near": NpcData.get_data("zorp").get("home_dir", Vector3.UP),
				},
				"lines": {
					"ask": [
						"Fly the old course with me! Every ring, in order!",
						"It shows where the glow used to reach. Come on!",
					],
					"progress": [
						"Still flying? The rings are not going anywhere!",
					],
					"done": [
						"Every ring! You really flew the whole old course!",
					],
					"tomorrow": [
						"Rest that jetpack! It worked hard today.",
					],
				},
			},
			{
				"type": "find",
				"title": "Find the three dim springs",
				"count": 3,
				"marker_label": "dim spring",
				"lines": {
					"ask": [
						"Three springs feed my river. All three: dim now.",
						"Walk and find them? I will count from right here!",
					],
					"progress": [
						"Still searching? Dim springs hide in shadow.",
					],
					"done": [
						"All three! Zorp knew you could do it. Zorp knew!",
					],
					"tomorrow": [
						"Enough searching for today! Rest a few hours!",
					],
				},
			},
			{
				"type": "place",
				"title": "Light the first spring",
				"item": ITEM_ID,
				"spot": "marker:s1_m0",
				"radius": 4.0,
				"count": 1,
				"give": {ITEM_ID: 1},
				"lines": {
					"ask": [
						"I made a river lamp! Stake it at the first spring.",
						"One good light and the rest should catch. Should!",
					],
					"progress": [
						"Not glowing yet! The ring on the ground still waits.",
					],
					"done": [
						"IT'S GLOWING! Oh look, look, it is really glowing!",
					],
					"tomorrow": [
						"Already lit today! Come see it shine in a bit!",
					],
				},
			},
		],
	}
