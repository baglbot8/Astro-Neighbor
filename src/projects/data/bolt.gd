extends RefCounted
## Bolt's project (BUILD_PLAN.md Phase 2 builder G). Schema: src/projects/project_system.gd header.
##
## REVISED 2026-09-12 (BUILDER G2): step 1 was a round trip - build the regulator from scrap at the
## crash-site bench, then fly it back to Bolt. The user, playing on their phone: flying back and forth
## "will get old fast and heats up the phone" (docs/CORE_LOOP.md "Mini-games instead of fetch trips").
## Step 1 is now a "minigame" step: CATCH the bolts his machines shook loose, played ON Bolt's world
## on the jetpack the game already has. No trip anywhere.
##
## THREE STEPS, CORE_LOOP's shape ("Play at the end"), one per game day:
##   0. find     - walk the yard and find the broken machines.
##   1. minigame - catch the bolts they shook loose (CATCH, flavour "bolt").
##   2. place    - install the regulator by the machines; Bolt hands over part_bolt.
## E's schema has no "talk" step here: the project's own "intro" IS that first talk (it fires in the
## same conversation as step 0's "ask" lines), so a separate talk step would just repeat it.
##
## ============================================================================ NO SCHEMA CHANGE NEEDED
## The brief asks for project_system.gd support only if the schema cannot do this. It already can:
##   * The regulator now reaches the player through "give" - "(optional, any type) items handed over
##     when the step is asked" (project_system.gd STEP docs). Step 2 (place)'s "give" hands over
##     ITEM_ID the moment it is asked (the talk the day after the catch is done), which project_system
##     .gd's `_ask` commits and toasts BEFORE the "ask" lines' status check - so the regulator is
##     already in the bag, ready to place, in the same talk Bolt says he finished it overnight.
##   * The ITEM schema already documents exactly this shape: "0 or absent [scrap_cost] = the bench
##     does not build this item (it comes from a talk step's \"give\", say)". ITEM_ID's "scrap_cost"
##     is REMOVED (was 6): nothing builds it any more, and `ProjectSystem.bench_items()` only lists
##     items with scrap_cost or stardust_cost > 0, so the bench stops offering it - no sequence break
##     back into the old round trip.
##   * "minigame" and its "give" plumbing, status lines and save shape (GameState.projects[npc]
##     ["found"], no new field) already existed for this exact case - built and measured in
##     docs/OPEN_ISSUES.md 47 before this file was touched.
##
## FLIGHT COUNT, measured against the OLD step 1: fly to Bolt (1) -> find, catch, place, all without
## leaving -> fly home to fit the part (2). Was 4 (fly to Bolt; fly home to build; fly back with it;
## fly home again to fit) - the round trip in the middle is simply gone.
##
## ============================================================================ THE CATCH COUNT: 5
## catch_game.gd: COUNT_RANGE is 1-12, "3-8 is the useful range", DEFAULT_COUNT is 5. Bolt uses 5:
##   * Play time: a full jetpack tank covers about 19 m of ground per pass (catch_game.gd "WHY THESE
##     NUMBERS"). Five spread over Bolt's 10.5 m world is a handful of passes, not a grind, and there
##     is no fail state and no timer to pad it further ("catching the last one finishes the game").
##   * Already measured ON BOLT: docs/OPEN_ISSUES.md 47 played 5 of 5 on bolt at --ui=mobile 1560x720
##     Compatibility - the exact count, world and renderer this step ships with - and measured its
##     cost there (+0.037 ms render CPU, +23 nodes, 2 draw calls; palette gates held).
##   * It replaces a WHOLE ROUND TRIP (a planet load each way plus a bench menu, several real minutes
##     per docs/OPEN_ISSUES.md 42's timed run) - five catches is not a discount on the old step, it is
##     a shorter, different kind of step, and CORE_LOOP asks for exactly that trade.
##
## ONE ITEM, NOT THREE. CORE_LOOP says "find the broken machines" (plural) but the "place" step type
## has exactly one spot + one radius (project_system.gd STEP docs), so three separately-placed fixes
## would need three place steps, not three game days spent on one. Bolt's own voice decides this: he
## counts everything twice and hates waste, so one regulator patched into the yard's main junction -
## not by his own home spot, but next to the FIRST machine you found (spot "marker:s0_m0",
## project_system.gd:118 "Marker ids are 's<step>_m<n>'") - fixes all three at once. That is also the
## more robust build: one spot from one earlier find step, no extra step types.
##
## ================================================================================ SCRAP ARITHMETIC
## Real rates measured 2026-09-11/12 (CLAUDE.md "Evidence rules": measure, don't reason):
##   GameState.STARTING_SCRAP = 5                                       (game_state.gd:15,23)
##   scrap collectible pays randi_range(3,6), avg 4.5, floor 3          (collectible.gd:198-202)
##   bolt: collectible_count=10, a 5-entry kind list with exactly ONE "scrap" entry, cycled twice over
##     the 10 spawns (kind = kinds[i % kinds.size()], planet_props.gd:2387-2404) -> 2 scrap
##     pickups/day, avg 9/day, floor 6/day                                (data/bolt.tres:56-57)
##   Collectibles respawn every game day: `Collectible.day_key()` keys "already picked" on
##     GameState.day_count, so a spot picked today is pickable again tomorrow (collectible.gd:25-26).
## THE OLD 6-scrap regulator BUILD IS GONE. Nothing in this project costs scrap any more except the
## bench's part_fit_scrap, kept at 8 (unchanged - see below for why it does not need to move).
## CORE_LOOP's "one project step per neighbour per game day" still means step 1 is asked no earlier
## than the day after step 0 completes, and step 2 no earlier than the day after step 1 completes -
## so the earliest the part can arrive is day (start + 2), matching the old timing exactly.
##   Absolute floor, the player never leaves Bolt's world and never picks up a single scrap pickup:
##     start 5, nothing spent by either the catch or the place step -> still 5 at the part's arrival.
##     5 < 8: the fit is NOT affordable on zero pickups, same as the old design ("STARTING_SCRAP itself
##     (5) is smaller than [the cost] on its own, so the player cannot rush the project without
##     picking up scrap at least once" - this was already true and is unchanged).
##   Realistic floor, the player picks up only the guaranteed MINIMUM roll of just ONE of the 4 scrap
##   spawns available across the 2 in-game days (start day + the catch day) before the part arrives:
##     5 + 3 = 8 -> exactly covers the fit, never negative.
##   Two full days' worth of floor-roll pickups (2 days x 2 scrap spawns/day x 3 each = 12):
##     5 + 12 = 17 -> fit for 8 -> 9 left.
##   Any average roll (9/day) or a single trip home (avg 36/day, Phase 2's own numbers) clears it with
##   room to spare. Because the whole project's OWN scrap cost is now zero (was 6), this is a strictly
##   EASIER bar than the old design (which needed 6 by day ~1 AND 8 more later, 14 total): a player
##   need only ever find 3 spare scrap, once, anywhere, before fitting at the bench. part_fit_scrap
##   stays at 8 - there is no reason to move it, and CLAUDE.md's "no fitted constants" rule argues
##   against tuning it without a timed play-through showing it is actually too tight (Phase 6).
##
## Voice (docs/CORE_LOOP "World problems": Bolt; src/characters/npc_data.gd "bolt" entry): a robot
## groundskeeper, orderly and warm, counts everything twice, short declarative sentences, precise
## numbers, no Animal Crossing words (docs/ARCHITECTURE.md §1.1: no "favor", "bells", "Nook").
## Every line <= 60 characters, 1-3 lines per list (project_system.gd "Writing").

const ITEM_ID := "bolt_yard_regulator"
const CATCH_COUNT := 5


static func definition() -> Dictionary:
	return {
		"npc": "bolt",
		"part": "part_bolt",
		"part_fit_scrap": 8,
		"intro": [
			"Problem detected. Three machines: broken.",
			"Please find them. I will count while you walk.",
		],
		"part_lines": [
			"Yard fully repaired. Confirmed. Twice.",
			"Take this gear. I have three thousand more.",
			"Logged as: excellent friend. Final answer.",
		],
		"part_again": [
			"You lost the gear? I logged a spare. Predictable.",
		],
		"items": [
			{
				"id": ITEM_ID,
				"name": "Yard Regulator",
				"kind": "decoration",
				"category": "tech",
				"desc": "A regulator plate, patched into the yard's main junction.",
				"icon_color": "#6f819c",
				# Reused decoration scene (schema: "any shipped decoration scene may be reused").
				# footprint must match the scene's own DecoItem.footprint (control_console.gd:11).
				"scene": "res://src/decorations/items/control_console.tscn",
				"footprint": 0.9,
				# No "scrap_cost": Bolt assembles this himself and GIVES it (step 2's "give") - the
				# bench must not offer to build it (schema: "0 or absent = the bench does not build
				# this item; it comes from a talk step's give").
			},
		],
		"steps": [
			{
				"type": "find",
				"title": "Find the broken machines",
				"count": 3,
				"marker_label": "broken machine",
				"lines": {
					"ask": [
						"Three machines stopped today. Precisely three.",
						"Walk the yard. I trust your legs more than mine.",
					],
					"progress": [
						"Still searching? I believe in you. Statistically.",
					],
					"done": [
						"All three found. My count agrees with yours.",
						"Good work. Accuracy logged at 100 percent.",
					],
					"tomorrow": [
						"That is enough counting for today. Rest those legs.",
					],
				},
			},
			{
				"type": "minigame",
				"title": "Catch the loose bolts",
				"game": "catch",
				"count": CATCH_COUNT,
				"config": {
					"flavour": "bolt",
					"label": "bolt",
					"label_plural": "bolts",
					"title": "Bolt's bolts",
				},
				"lines": {
					"ask": [
						"Five bolts. Rattled loose. Airborne now.",
						"Fly. Catch them. I cannot reach that high.",
					],
					"progress": [
						"Bolts still drifting. I am not chasing them.",
					],
					"done": [
						"All five caught. I counted your catches. Twice.",
						"I will assemble the regulator tonight. Efficient.",
					],
					"tomorrow": [
						"Assembly takes a few hours. Return then. Confirmed.",
					],
				},
			},
			{
				"type": "place",
				"title": "Install the regulator",
				"item": ITEM_ID,
				"spot": "marker:s0_m0",
				"radius": 4.0,
				"count": 1,
				"give": {ITEM_ID: 1},
				"lines": {
					"ask": [
						"Regulator assembled. Five bolts, one part. Exact.",
						"Place it by the first machine. I marked the spot.",
					],
					"progress": [
						"Not placed yet. The ring on the ground still glows.",
					],
					"done": [
						"Installed. All three machines: green. Confirmed.",
					],
					"tomorrow": [
						"Already installed today. Admire it again shortly.",
					],
				},
			},
		],
	}
