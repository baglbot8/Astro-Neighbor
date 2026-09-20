extends RefCounted
## Grig's project (docs/BUILD_PLAN.md Phase 3b, builder GRIG). Schema: src/projects/project_system.gd
## header. Shaped after src/projects/data/bolt.gd and zorp.gd (the shipped Phase 2/3b examples).
##
## THE WORLD PROBLEM (docs/CORE_LOOP.md "World problems": Grig - "the sun never climbs" is Fen's;
## Grig's own row is dry chalk terraces, "too dry; bring water and grow a garden"). Three steps, one
## per game day, end with a planted garden and part_grig:
##   0. minigame - dowse for water under the chalk ("hunt", npc "grig", count 3 - exactly the brief's
##      numbers; hunt_game.gd ships one look, "spring", first built and measured ON Grig).
##   1. talk     - a LIGHT LINK to Zorp (docs/BUILD_PLAN.md Phase 3b table: "a seed pouch from Zorp").
##      Water alone does not fix dry chalk - Grig sends the player to Zorp for a flower that barely
##      drinks. Zorp hands it over ("hand_over") the moment the link completes, in his own voice.
##   2. place    - plant the seed pouch on a good tread; Grig hands over part_grig.
## No "find" step: CORE_LOOP's own first idea for Grig is exactly these three beats (dowse, link,
## plant), and docs/BUILD_PLAN.md Phase 3b's row lists exactly one mini-game step and one light link
## for Grig - a fourth step (a find) would break "three steps on three game days" (rule 1).
##
## ============================================================================ THE LINK: WHY ZORP
## docs/BUILD_PLAN.md Phase 3b: "Grig | tier 2 | ... | a seed pouch from Zorp" - not a builder choice.
## VALIDATED at load (project_system.gd `_invalid_reason`, "talk" case): Zorp lives on tier 1
## (CampaignData.TIERS index 0, "zorp" in the first list) and Grig on tier 2 (index 1, "grig" in the
## second) - target_tier (0) <= owner_tier (1), so the link never sends the player somewhere still out
## of range (docs/BUILD_PLAN.md Phase 3b: "Every link world is reachable before the project that needs
## it: Zorp (tier 1) before Grig (tier 2)"). The link sits on step 1 (the MIDDLE step), never the last
## (rule: "a link never on the last step" - step 2, the place step, is Grig's own and ends the
## project; part_lines would otherwise come out of Zorp's mouth).
##
## ================================================================================ THE HUNT COUNT: 3
## The brief's own number for Grig ("hunt", npc "grig", count 3) - not re-derived, but independently
## consistent with hunt_game.gd's own header, which measured ITS layout specifically on Grig: "on Grig
## a replay's first spot is 5.0-12.6 m from the landing (median 6.8); a story's is 15.4-17.1 m from
## Grig's home" and "nearest two spots 4.00 m" - three spots comfortably fit Grig's 9.5 m-radius world
## without crowding (hunt_game.gd CHAIN_MIN_M-CHAIN_MAX_M keeps each next spot 4-such metres from the
## last). config passes only "npc": "grig" - "look" defaults to "spring" and "title" to "Dowse for
## water" (hunt_game.gd CONFIG, both already correct for this project), so nothing here overrides an
## engine default with an invented one.
##
## ================================================================================ THE ITEM: reused
## "a flower that barely drinks" (docs/CORE_LOOP.md "More mini-games, one per neighbour"). Catalog
## decorations considered (every "plants" row in decoration_catalog.gd) and why each was passed over:
##   moon_rock_garden  rocks, not a flower - the brief is explicit ("a flower"), and Grig's world is
##                     already all rock and chalk; more rock does not read as help.
##   oxygen_planter    a retired air tank "growing air" - a joke about breathing, not about drought.
##   alien_plant_pot   "three curious tendrils... lean toward you" - a curious, active plant; the
##                     brief's flower is the opposite temperament (barely drinks, barely there).
##   cosmic_mushrooms / ufo_planter / antenna_tree  all uncommon-tier novelty plants (glowing gills,
##                     an abducted pot, a dish-growing tree) - too eventful for "barely drinks."
##   moon_flower_bed   CHOSEN. "Pale blooms that only open once the sun clocks off" (decoration_
##                     catalog.gd) is already a hardy, undemanding, pale flower - the closest shipped
##                     match to "a flower that barely drinks" of anything in the catalog, and its
##                     0.75 m footprint is a small bed, not a monument.
## Wrapped as a NEW project item (id "grig_dry_garden") reusing moon_flower_bed.tscn's geometry - the
## exact pattern bolt.gd (control_console.tscn) and zorp.gd (orb_light.tscn) set: new id/name/desc/
## icon_color, same "scene", footprint matched to the scene's own DecoItem.footprint
## (moon_flower_bed.gd:14 - `footprint = 0.75`). icon_color reuses the catalog's own shipped swatch for
## this scene (#cfe4ff, decoration_catalog.gd) rather than inventing a new one, since it is still
## literally that object - a pale, water-shy bloom now planted in chalk instead of moon dust.
##
## NO "scrap_cost" - Zorp hands the pouch over himself the moment the light link completes (step 1's
## "hand_over"), exactly like bolt.gd's regulator and zorp.gd's river lamp being "given" rather than
## built: step 2 (place) needs no "give" of its own because the item is already in the bag from step 1.
## The bench never offers to build it (schema: "0 or absent = the bench does not build this item").
##
## ================================================================================ THE PLACE SPOT
## No find step exists (see "THE WORLD PROBLEM" above), so "spot" cannot aim at a "marker:" - it is an
## explicit planet-local direction. Grig's world is the smallest shipped (radius 9.5 m, data/grig.tres)
## with a real placement budget (terraces are stepped, not flat), so the direction and radius were
## chosen by MEASURING, not guessing (CLAUDE.md "no fitted constants"): a scratch-only sweep probe
## (.astro_scratch/phase3b/grig/tests/director/spot_probe.gd, not shipped) ran project_system.gd's own
## `debug_spot_report` sampling loop over 35 candidate direction/radius combinations, in three rounds
## narrowing toward the best result, on Grig itself, headless, via `godot --path <copy>
## res://src/world/world.tscn -- --planet=grig --director=res://tests/director/grig_sweep.json
## --quit-at=3`. Grig's own home direction scored worst (15.0% at r=4 - his own doorway is the most
## cluttered ground on the planet, unsurprisingly), and a "wsw, tipped down" direction scored best of
## everything tried:
##   SPOT = Vector3(-0.899937, -0.38115, -0.21175)  RADIUS = 4.0
##   MEASURED (debug_spot_report's own sampler, footprint 0.75 - grig_dry_garden's): samples=421,
##   placeable=81.5%, nearest_free=0.00 m (the ring's own centre is itself free ground), blocked=
##   {"prop": 58, "slope": 20} - zero "reserved" (this spot is nowhere near grig's home/pad/spawn
##   clearance zones, so "radius" need not clear the 3.5 m rule that applies to "npc"/"pad"/"spawn").
##   A tighter radius 3.5 measured even higher (84.9%) but 4.0 matches bolt.gd's and zorp.gd's own
##   place radius, and 81.5% of a 4 m ring is a wide, forgiving target on a 9.5 m world.
##
## ================================================================================= SCRAP ARITHMETIC
## Independently measured off data/grig.tres (CLAUDE.md "Evidence rules": measure, don't reason - not
## assumed from bolt.gd's or zorp.gd's numbers even though they land the same):
##   GameState.STARTING_SCRAP = 5                                       (game_state.gd:15,23)
##   scrap collectible pays randi_range(3,6), avg 4.5, floor 3          (collectible.gd:198-202)
##   grig.tres: collectible_count=10, collectible_kind =
##     "chalk_core,chalk_core,chalk_core,chalk_core,scrap" - a 5-entry list with exactly ONE "scrap"
##     entry, cycled twice over the 10 spawns (kind = kinds[i % kinds.size()], planet_props.gd:2387-
##     2404) -> "scrap" lands at i=4 and i=9 -> 2 scrap pickups/day, avg 9/day, floor 6/day. IDENTICAL
##     structure to bolt's and zorp's worlds (also a 5-entry list, one "scrap" entry, cycled twice) -
##     the three tier-1/2 worlds share the same scrap rate by coincidence of authoring, not by this
##     file assuming it.
## This project's OWN scrap cost is zero (the flower is given, never built) - the only scrap spent is
## part_fit_scrap at the bench, so the same bar bolt.gd and zorp.gd compute applies here for the same
## reason (CORE_LOOP "one project step per neighbour per game day" puts the earliest part arrival at
## day (start + 2), exactly as those two derive):
##   Absolute floor (no pickups at all): start 5, spend 0 -> still 5 at the part's arrival.
##     5 < 8: the fit is NOT affordable on zero pickups (the player must pick up scrap at least once,
##     unchanged by this project existing).
##   Realistic floor (one guaranteed floor-roll pickup, of the 2 days x 2 scrap spawns/day = 4
##     available before the part can arrive): 5 + 3 = 8 -> exactly covers the fit.
##   Two days' full floor-roll pickups (2 days x 2 spawns x 3 each = 12): 5 + 12 = 17 -> fit for 8 ->
##     9 left. Any average roll (9/day) clears it with room to spare.
## part_fit_scrap is set to 8 - the same number as bolt.gd and zorp.gd, arrived at independently from
## grig's own data: three worlds with the same measured scrap rate and the same zero-cost item design
## land on the same bar. CLAUDE.md's "no fitted constants" rule argues against moving it without a
## timed play-through showing it is actually wrong (Phase 6).
##
## Voice (docs/CORE_LOOP.md "World problems": Grig is "blunt, one-eyed stonecutter who counts";
## npc_data.gd "grig" entry - intro, greet and small_talk all read the same way: short declarative
## sentences, often one word long, exact numbers, dry rather than warm, never a question he does not
## also answer himself ("Water again. A garden again. Correctly ordered."). No Animal Crossing words
## (docs/ARCHITECTURE.md §1.1). Zorp's "with" lines (spoken in HIS voice, not Grig's) match zorp.gd's
## own writing: short exclaiming bursts, a word repeated for emphasis, curious asides.
## Every line <= 60 characters, 1-3 lines per list (project_system.gd "Writing").

const ITEM_ID := "grig_dry_garden"
const HUNT_COUNT := 3


static func definition() -> Dictionary:
	return {
		"npc": "grig",
		"part": "part_grig",
		"part_fit_scrap": 8,
		"intro": [
			"Chalk. Dry chalk. Not one drop of water in it.",
			"Nine hundred steps, and every one of them thirsty.",
			"Dowse with me. Feel for the pulse. Find water.",
		],
		"part_lines": [
			"Water again. A garden again. Correctly ordered.",
			"Take this valve. Cut it myself. Fits your rocket.",
			"Best neighbour on the steps. Recorded. Permanently.",
		],
		"part_again": [
			"Lost the valve? I keep spares. I always keep spares.",
		],
		"items": [
			{
				"id": ITEM_ID,
				"name": "Barely-There Bloom",
				"kind": "decoration",
				"category": "plants",
				"desc": "Zorp's hardy pale flower, coaxed to grow in dry chalk.",
				"icon_color": "#cfe4ff",
				# Reused decoration scene (schema: "any shipped decoration scene may be reused").
				# footprint must match the scene's own DecoItem.footprint (moon_flower_bed.gd:14).
				"scene": "res://src/decorations/items/moon_flower_bed.tscn",
				"footprint": 0.75,
				# No "scrap_cost": Zorp hands this over himself when the light link completes (step 1's
				# "hand_over") - the bench must not offer to build it (schema: "0 or absent = the bench
				# does not build this item; it comes from a talk step's give").
			},
		],
		"steps": [
			{
				"type": "minigame",
				"title": "Dowse for water",
				"game": "hunt",
				"count": HUNT_COUNT,
				"config": {
					"npc": "grig",
				},
				"lines": {
					"ask": [
						"Water hides under chalk. I feel it. Sometimes.",
						"Walk slow. Listen for the pulse. Find three.",
					],
					"progress": [
						"Still dowsing? The chalk does not lie. Mostly.",
					],
					"done": [
						"Three pulses. Three springs. Correctly counted.",
						"Water, under my own steps. I did not expect that.",
					],
					"tomorrow": [
						"Enough walking for today. Dowse again in a few hours.",
					],
				},
			},
			{
				"type": "talk",
				"title": "Fly to Zorp for a seed",
				"npc": "zorp",
				"hand_over": {ITEM_ID: 1},
				"lines": {
					"ask": [
						"Water is not enough. I need something that drinks little.",
						"Zorp grows strange flowers. Ask him for one. Now.",
					],
					"progress": [
						"Seen Zorp yet? His hollow is close. Go.",
					],
					"tomorrow": [
						"No seed yet? Fine. Try Zorp again in a few hours.",
					],
					"with": [
						"Oh! A pouch for Grig? I have just the one!",
						"Barely drinks at all! Perfect for dry chalk!",
					],
				},
			},
			{
				"type": "place",
				"title": "Plant the garden",
				"item": ITEM_ID,
				"spot": Vector3(-0.899937, -0.38115, -0.21175),
				"radius": 4.0,
				"count": 1,
				"lines": {
					"ask": [
						"Pouch in hand? Good. Plant it on a flat tread.",
						"Somewhere the water reaches. I marked a good one.",
					],
					"progress": [
						"Not planted yet. The ring is still glowing there.",
					],
					"done": [
						"It bloomed. Pale, but it bloomed. Good. Very good.",
						"My driest step has a garden now. Correctly placed.",
					],
					"tomorrow": [
						"Already planted today. Come see it grow later.",
					],
				},
			},
		],
	}
