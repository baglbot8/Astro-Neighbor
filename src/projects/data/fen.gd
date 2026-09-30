extends RefCounted
## Fen's project (docs/BUILD_PLAN.md Phase 3b, builder FEN). Schema: src/projects/project_system.gd
## header. Shaped after src/projects/data/bolt.gd (the shipped Phase 2 example) and
## src/projects/data/zorp.gd (the shipped Phase 3b sibling with the same minigame -> find -> place
## order).
##
## THE WORLD PROBLEM (docs/CORE_LOOP.md "World problems": Fen; docs/BUILD_PLAN.md Phase 3b table):
## his terracotta flat is stuck at the LONG DUSK - the sun never climbs past 11 degrees
## (fen.tres `sun_peak_elev_deg = 11.0`) - because the glow moths that lived in his mirror pools
## carried the pools' own light out and away. Three steps, one per game day, end with the light back
## at one pool and part_fen:
##   0. minigame - guide the glow moths home to a pool ("guide", flavour "moth", npc "fen" - the exact
##      MINI-GAME CONFIG this builder was handed, including the measured "home_dir" below).
##   1. find     - the three pools the returned light reached (count 3).
##   2. place    - stake a beacon at the first of them; Fen hands it over the moment he asks it (kept
##      as a spare, same shape as bolt.gd's regulator and zorp.gd's river lamp), and gives part_fen
##      once it is standing.
## No "talk" step: exactly like bolt.gd and zorp.gd, the project's own "intro" IS the first talk
## (spoken right before step 0's "ask", in the same conversation), so a separate talk step would only
## repeat it.
## NO LIGHT LINK OF HIS OWN (docs/BUILD_PLAN.md Phase 3b table: Fen's link column is empty) - both
## steps that need a world stay on Fen's own, tier-2 world. Vela's project sends the PLAYER to talk to
## Fen once (a light link written in Vela's own file, src/projects/data/vela.gd, not here) - that is a
## step on VELA's project, asked and owned by Vela; this file adds nothing for it, exactly as
## project_system.gd's schema says a light link is completed in the conversation with the NAMED
## neighbour and needs no cooperation from that neighbour's own definition file.
##
## ============================================================================ WHY THIS STEP ORDER
## Guide -> find -> place mirrors zorp.gd's order (not bolt.gd's find -> minigame -> place) for the
## same reason CORE_LOOP's own first idea already gives Fen: the moths ARE the visible mystery (why is
## it dark) and guiding them home is how the player first sees light return to a pool at all, before
## Fen can name where it settled (the three lit pools) or what still needs doing (a lantern at the
## first one). Fen watches and counts rather than acts - guiding the moths yourself, then having HIM
## point out what changed, fits an elder who tracks changes rather than causes them (npc_data.gd
## small_talk: "Pool four has moved again. Eleven centimetres." - he notices results, not causes).
##
## ========================================================================== THE GUIDE CONFIG: HANDED, NOT CHOSEN HERE
## "count": 5, "flavour": "moth", "npc": "fen" and "home_dir": [-0.2216, -0.0157, 0.9750] are the exact
## values this builder was given, already measured by the Phase 3a guide critic (crater 5's clear
## side: median 43 s to guide all five home there, against 90 s on the cluttered side the game's own
## default picked with no home_dir given). This file passes them through unchanged rather than
## re-deriving them - re-measuring a number someone already measured on the same world would be the
## "fitted constants" mistake in reverse (CLAUDE.md: measure, don't reason - but don't re-measure a
## measurement either). "seed" is left unset per the same instruction, so the same save always gets
## the same moth layout with no override needed (guide_game.gd `setup()`).
##
## ================================================================================ THE ITEM: reused
## "a lamp decoration", per the brief. Catalog decorations considered (every "lights" row in
## decoration_catalog.gd) and why each was passed over:
##   moon_lamp       warm gold (#ffe27a), close in family - but its shape IS a crescent moon
##                   (moon_lamp.gd: "a fat crescent moon on a lamp post"), and Fen's own small_talk
##                   states flatly "No moon here. Nothing to argue with the sun." Placing a
##                   moon-shaped lantern on the one world whose own voice denies having a moon is
##                   exactly the kind of thing CAST_VARIETY's "look at the picture" rule exists to
##                   catch before it ships.
##   crystal_lamp    violet/cyan/pink (#845bd9/#65c5d9/#d95d7c) - a "moon-rock clump", cool-toned;
##                   nothing here is warm the way a returning light should read.
##   star_projector  pale blue (#cfe4ff), about a night sky ("throws sparks of starlight") - Fen's
##                   pools are lit by day-light returning, not stars; also cool-toned.
##   plasma_campfire cold blue flame (#65c5d9/#a0bee6) - reads as a campfire, not a lamp staked at a
##                   pool's rim, and the wrong temperature for a "the dusk gets a little warmer" beat.
##   string_lights   pink party-light bulbs (#ffb3c1) - wrong mood entirely for a terse elder's world.
##   orb_light       cyan (#65c5d9) - already Zorp's river lamp (zorp.gd); reusing the same object for
##                   a second neighbour the player meets soon after would read as the same prop twice,
##                   and cyan is still the wrong temperature for Fen's warm copper dusk (npc_data.gd
##                   small_talk: "Some evenings the whole pan turns copper.").
##   beacon_tower    CHOSEN. Its own header calls the lit part a "glass lantern room" - literally a
##                   lantern - and its light constant `LIGHT_C` is `#d9af4f`, a warm copper-gold that
##                   matches both Fen's "pan turns copper" line and the moth's own shipped look (a pale
##                   peach-gold body, `#e6d4a8`/`#ecddb4`, docs/OPEN_ISSUES.md 51) - so the beacon reads
##                   as the same warm light the moths carried, now staked in place. Its slow-rotating
##                   beam (`beacon_tower.gd` BEAM_LENGTH 3.0, sweeping the ground) also fits a
##                   "pan-watcher" - a light that keeps watch over still water - better than a static
##                   glow would. It is the largest footprint of the six (0.75 m, `beacon_tower.gd:17`)
##                   but still comfortably inside the 4.0 m place ring (debug_spot_report below).
## Wrapped as a NEW project item (id "fen_pool_beacon") reusing beacon_tower.tscn's geometry - the
## exact pattern bolt.gd (control_console.tscn) and zorp.gd (orb_light.tscn) set: new id/name/desc/
## icon_color, same "scene", footprint matched to the scene's own DecoItem.footprint
## (beacon_tower.gd:17). icon_color reuses the scene's own LIGHT_C (#d9af4f) rather than inventing a
## new one, since it is still literally that object's own light colour.
##
## NO "scrap_cost" - Fen has kept a spare and GIVES it, exactly like bolt.gd's regulator and zorp.gd's
## river lamp: step 2's "give" hands it over the moment the step is ASKED (the talk the day after the
## three pools are found), so it is already in the bag, ready to place, before the "ask" lines even
## finish (schema: "give"/`_ask` docs). The bench never offers to build it (schema: "0 or absent = the
## bench does not build this item; it comes from a talk step's give").
##
## ONE LANTERN, NOT THREE (mirrors bolt.gd's and zorp.gd's own "ONE ITEM" reasoning, in Fen's own
## voice): the brief's first idea already says "place a lantern... by the first of them" (singular),
## and a "place" step is one spot, one radius regardless. Fen counts and logs everything ("Nine years
## of notes. Pool four moved. Twice.") - lighting the FIRST pool he logged, and trusting the rest to
## follow, is exactly the kind of careful, one-thing-at-a-time move his own lines already make. The
## beacon goes at the first pool found (spot "marker:s1_m0" - find is step 1 here, not step 0, so its
## markers are "s1_m0.."), the same "aim at an earlier find step's first marker" shape as bolt.gd's
## "marker:s0_m0" and zorp.gd's "marker:s1_m0".
##
## THE PROBLEM STAYS FIXED: the beacon is a real placed decoration (GameState.add_placed_decoration
## via DecorationManager), so it stands at the pool's rim for good after the project ends - the long
## dusk reads as helped, not as an errand that vanishes (docs/BUILD_PLAN.md Phase 3b rules). It does
## not undo the 11-degree sun (that is environment.gd's own model, out of scope here per
## docs/ARCHITECTURE.md §1.1's "honest status" note on Fen's Long Dusk) - it is one lit pool of
## fourteen, which is what the "done" and part_lines below say, not "fixed forever."
##
## ================================================================================ SCRAP ARITHMETIC
## Independently measured off data/fen.tres (CLAUDE.md "Evidence rules": measure, don't reason - not
## assumed from bolt.gd's or zorp.gd's numbers even though the structure lands the same):
##   GameState.STARTING_SCRAP = 5                                       (game_state.gd:15,23)
##   scrap collectible pays randi_range(3,6), avg 4.5, floor 3          (collectible.gd:198-202)
##   fen.tres: collectible_count=10, collectible_kind =
##     "salt_bloom,crystal_chunk,salt_bloom,crystal_chunk,scrap" - a 5-entry list with exactly ONE
##     "scrap" entry, cycled twice over the 10 spawns (kind = kinds[i % kinds.size()],
##     planet_props.gd:2387-2404) -> "scrap" lands at i=4 and i=9 -> 2 scrap pickups/day, avg 9/day,
##     floor 6/day. IDENTICAL structure to bolt's and zorp's worlds (also a 5-entry list, one "scrap"
##     entry, cycled twice) - a coincidence of authoring across three worlds, not assumed by this file.
## This project's OWN scrap cost is zero (the beacon is given, never built) - the only scrap spent is
## part_fit_scrap at the bench, so the same bar bolt.gd and zorp.gd computed applies here for the same
## reason:
##   Absolute floor (no pickups at all on Fen's own world, by this project's own 2 extra days): start
##     5, spend 0 -> still 5 at the part's arrival. 5 < 8: not affordable on zero pickups.
##   Realistic floor (one guaranteed floor-roll pickup, of the 2 days x 2 scrap spawns/day = 4
##     available before the part can arrive - CORE_LOOP's one-step-a-day rule puts the earliest
##     arrival at day (start + 2), exactly as bolt.gd and zorp.gd derive): 5 + 3 = 8 -> exactly covers.
##   Two days' full floor-roll pickups (2 days x 2 spawns x 3 each = 12): 5 + 12 = 17 -> fit for 8 ->
##     9 left. Any average roll (9/day) clears it with room to spare.
## UNLIKE Zorp and Bolt, Fen is not the player's first fit: CampaignData's tier 2 (CORE_LOOP.md "Range
## tiers") requires part_zorp AND part_bolt already fitted, which is 2 x 8 = 16 scrap already spent at
## the bench by the time Fen's project even starts. The zero-pickup floor above is therefore a
## mathematical worst case kept for the same reason bolt.gd and zorp.gd keep it (a lower bound that
## still holds), not a plausible one this deep into the story - a player who has fitted two parts has
## necessarily picked up scrap at least twice already. part_fit_scrap is set to 8, the same number as
## the two tier-1 worlds, arrived at independently from fen's own data: three worlds with the same
## measured scrap rate and the same zero-cost item design land on the same bar. CLAUDE.md's "no fitted
## constants" rule argues against moving it without a timed play-through showing it is wrong (Phase 6).
##
## Voice (docs/CAST_VOICES_DRAFT.md, approved 2026-09-27, with docs/STORY_HOME_SPEC.md 8.1): 
## Fen is a young, calm, sunny flower (he); talks about sun and water as food, his pools and
## glow moths. No logbook, no numbering, no "crust".
## Plain English a 10-year-old reads once. Every line <= 60 characters.

const ITEM_ID := "fen_pool_beacon"
const GUIDE_COUNT := 5
const FIND_COUNT := 3
## Crater 5's clear side (Phase 3a guide critic, docs/BUILD_PLAN.md Phase 3a table) - measured, not
## re-derived here. See "THE GUIDE CONFIG" above.
const GUIDE_HOME_DIR := Vector3(-0.2216, -0.0157, 0.9750)


static func definition() -> Dictionary:
	return {
		"npc": "fen",
		"part": "part_fen",
		"part_fit_scrap": 90,  # ECON 2026-09-29: the fit ladder's step in the usual fit order; the bench charges GameState.part_fit_scrap() (by parts already fitted)
		"intro": [
			"The glow moths flew off with my pools' light!",
			"I can't leave them lost. Not before I go.",
			"Could you guide them home? They're shy of me.",
		],
		"part_lines": [
			"The pools are glowing again. It feels so warm.",
			"Take this cell. I kept it safe by my roots.",
			"Find a good home out there. One with lots of sun.",
			"You're a real friend. I mean it. Thank you.",
		],
		"part_again": [
			"Lost the cell? It's okay. I found another one.",
		],
		"items": [
			{
				"id": ITEM_ID,
				"name": "Pool Beacon",
				"kind": "decoration",
				"category": "lights",
				"desc": "A little lamp for a pool's edge. It keeps the glow in.",
				"icon_color": "#d9af4f",
				# Reused decoration scene (schema: "any shipped decoration scene may be reused").
				# footprint must match the scene's own DecoItem.footprint (beacon_tower.gd:17).
				"scene": "res://src/decorations/items/beacon_tower.tscn",
				"footprint": 0.75,
				# No "scrap_cost": Fen keeps this himself and GIVES it (step 2's "give") - the bench
				# must not offer to build it (schema: "0 or absent = the bench does not build this
				# item; it comes from a talk step's give").
			},
		],
		"steps": [
			{
				"type": "minigame",
				"title": "Guide the glow moths home",
				"game": "guide",
				"count": GUIDE_COUNT,
				"config": {
					"flavour": "moth",
					"npc": "fen",
					"home_dir": GUIDE_HOME_DIR,
				},
				"lines": {
					"ask": [
						"Five moths have my pools' light. Now they're loose.",
						"Guide them home. Come from the far side, gently.",
					],
					"progress": [
						"Still loose? They run from you. Try sideways.",
					],
					"done": [
						"All home! My pools have their light back.",
						"Thank you. That was so kind of you.",
					],
					"tomorrow": [
						"That's enough for today. Rest in the sun a bit.",
					],
				},
			},
			{
				"type": "find",
				"title": "Find the lit pools",
				"count": FIND_COUNT,
				"marker_label": "lit pool",
				"lines": {
					"ask": [
						"Three pools got their light back. Can you find them?",
						"Walk around the flats. I'll wait here in the sun.",
					],
					"progress": [
						"Still looking? The pools aren't going anywhere.",
					],
					"done": [
						"You found all three! They look so pretty.",
					],
					"tomorrow": [
						"Enough walking for today. Come back later.",
					],
				},
			},
			{
				"type": "place",
				"title": "Light the first pool",
				"item": ITEM_ID,
				"spot": "marker:s1_m0",
				"radius": 4.0,
				"count": 1,
				"give": {ITEM_ID: 1},
				"lines": {
					"ask": [
						"Here's a little lamp for the first pool.",
						"Put it by the water's edge. Mind the salt.",
					],
					"progress": [
						"Not lit yet. Look for the ring on the ground.",
					],
					"done": [
						"It's lit! That pool won't go dark now.",
					],
					"tomorrow": [
						"Already lit today. Come back in a little while.",
					],
				},
			},
			{
				# STORY_SPINE (PLANET_SAFARI_SPEC.md 15.2, migrated from the retired sky "photo" step,
				# same appended 4th-step slot, same neighbour lines shape - see project_system.gd's
				# "planet_photo" schema entry). Subject id "pool_ripple" is the exact roster id from
				# Fen's own safari manifest (res://src/planet_safari/worlds/fen.gd MANIFEST "roster"),
				# checked at load against that same manifest.
				"type": "planet_photo",
				"title": "Photo: the Pool Ripple",
				"planet": "fen",
				"kind": "subject",
				"subject": "pool_ripple",
				"grade": "Fair",
				"lines": {
					"ask": [
						"One last thing. A photo of home, before I go.",
						"Next safari here, wait by a pool. It glows, then jumps!",
					],
					"progress": [
						"Not yet? The pools ripple by themselves. Wait.",
					],
					"already_have": [
						"You already caught it? Oh, wow!",
						"You're quicker than me. That's for sure.",
					],
					"smudge": [
						"You caught it! But it's a bit blurry.",
						"Hold the shutter down. Let the picture bloom.",
					],
					"done": [
						"A sharp ripple! Look at that. Lovely.",
						"I sprouted by that pool. I'll miss it.",
					],
				},
			},
		],
	}
