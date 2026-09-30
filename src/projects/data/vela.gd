extends RefCounted
## Vela's project (docs/BUILD_PLAN.md Phase 3b, builder VELA). Schema: src/projects/project_system.gd
## header. Shaped after src/projects/data/bolt.gd (the shipped example) and zorp.gd (Phase 3b's own
## first sibling), and after the LINK builder's own test fixture
## (.astro_scratch/phase3a/link-critic1/defs/crit_a_zorp_to_bolt.gd) for the light-link step's exact
## keys: "npc" on the step, "with" INSIDE "lines", "hand_over" as a STEP key (not inside "lines").
##
## THE WORLD PROBLEM (docs/CORE_LOOP.md "World problems": Vela; ARCHITECTURE.md 1.1: "a still frost
## world"). His Still Frost is measured the LARGEST world shipped: radius 14.5 (data/vela.tres),
## against fen 13.0, home 12.0, bolt/zorp 10.5, grig 9.5 (hub excepted at 21.0, not a neighbour
## world). He already has EIGHT relay masts in one straight run and THREE array dishes, built as
## real scenery in planet_props.gd's `_vela()` ("THE LONG ARRAY") - only three of the eight masts
## (i == 1, 4, 7) carry a lit amber lamp, the rest are dark, and the whole world plays in silence
## (no music_track night variant, no per-letter voice - he is one of the nine "shared doot" voices,
## ARCHITECTURE.md 1.1). FROZEN and SILENT is not a metaphor here, it is what the shipped scene
## already looks and sounds like; this project's job is to give it one back-and-forth exchange (the
## mini-game), one memory of when it was warm (the link), and one more listening dish (the place).
##
## THREE STEPS, ONE PER GAME DAY, tier 3 (CampaignData.TIERS: 4 parts -> Vela, the LAST world and the
## LAST part - CORE_LOOP "Range tiers"):
##   0. minigame - CALL AND RESPONSE with his array ("call", flavour "spark" - his own amber, catch_
##      game.gd's FLAVOURS table). This is his own game (BUILD_PLAN Phase 3a table: "Simon says with
##      Use, Jump, Fly and Emote"; CORE_LOOP "he listens to his array") - the array calls, he is the
##      array, and answering it is the whole point of a neighbour whose defining trait is listening.
##   1. talk (LIGHT LINK to "fen") - Vela cannot warm the dish from his own notes, so he sends the
##      player to FEN (docs/CORE_LOOP "More mini-games...": "Vela needs the old warmth readings from
##      Fen's logbook" - named explicitly, not a free choice). Fen tears out the page in his own
##      voice ("with"), and "hand_over"s it.
##   2. place   - Vela builds a new dish from the reading and the player plants it by the one lit mast
##      he names ("mast two" - the first of the three lit masts, i == 1 zero-indexed - see "WHICH
##      MAST" below for why this one and not another lit mast). part_vela is handed over on this step's "done", as the
##      LAST part in the whole story (CORE_LOOP "The call": the rocket is ready to go home right
##      after this - the brief's own note: "his part lines should feel like the end of the journey
##      home"). No "tomorrow" is strictly required on a last step (schema: "Unused on the last
##      step") but bolt.gd's own last step still writes one for a same-day repeat talk, so this one
##      does too - the exact shipped precedent, not a deviation.
## No separate opening "talk" step: exactly like bolt.gd and zorp.gd, the project's own "intro" IS the
## first talk (spoken right before step 0's "ask", in the same conversation).
##
## ============================================================================ WHY THIS STEP ORDER
## Mini-game first, same reasoning as zorp.gd: it is the reveal AND the fix's demonstration in one -
## you hear the array work for the first time by making it answer you, before anything is explained
## about what's missing. The link sits in the MIDDLE (not first, not last) because CORE_LOOP is
## explicit that a link step is "quick and empty-handed", never the finale of a project that ends in
## a part hand-over on its own world - the place step, on Vela's own ground, has to be what closes it.
##
## ============================================================================ THE CALL GAME: count 3
## Brief config: "npc" "vela", count 3 - matched exactly. "npc" is never set inside "config": project_
## system.gd's `_start_minigame` (project_system.gd:1371-1384) writes `cfg["npc"] = npc_id` itself
## from this definition's own top-level "npc", overwriting anything given, so a "config" that also set
## "npc" would be silently thrown away - not written here, to avoid implying it does something.
## "flavour": "spark" is call_game.gd's own Vela entry in catch_game.gd's shared FLAVOURS table (the
## "one source of truth" note at that file's top) - the only flavour that is already labelled hers.
## "title" is left unset: call_game.gd's own default builds "Copy Vela's signal" from the caller's
## `display_name` the moment "npc" is present (call_game.gd:353-358), which is the exact line the
## brief's own config table would have had me hand-write - no reason to duplicate it and risk drift.
## "center_dir", "ring_radius_m" and "seed" are left at the game's own measured defaults - call_game.
## gd's own header already measured a 2.0 m ring against Vela's array and pad/spawn footprint report
## below re-confirms it (see "PLACEABILITY" - the ring's own spot search is unaffected by this file,
## it is validated live in the play-through instead).
##
## ============================================================================ THE LINK: Fen, tier 2 < tier 3
## CampaignData.TIERS lists fen under "parts: 2" (tier index 1) and vela under "parts: 4" (tier index
## 2) - fen is a STRICTLY EARLIER tier than vela, so a player standing at Vela's project has already
## had Fen's world in range since two parts ago (project_system.gd's link validation: "must live on a
## world in the same or an earlier CampaignData tier"). This is also BUILD_PLAN Phase 3b's own table
## entry for Vela ("a light link... the old warmth readings from Fen's logbook") and CORE_LOOP "More
## mini-games...": Vela is one of only two projects with a link at all (the other is Grig, from
## Zorp), by the user's own explicit naming - not invented here.
## "hand_over" (a STEP key, confirmed against the link builder's own critic fixture above - NOT inside
## "lines", which is the exact mistake project_system.gd now names a specific push_error for) gives
## ITEM_LINK the moment the talk with FEN completes, in FEN's own terse voice via "with" (REQUIRED
## non-empty, checked at load). Vela's OWN "ask"/"progress"/"tomorrow" lines on this step tell the
## player where to go (`wants_marker` shows the "!" on Fen while this is live, never on Vela) - "done"
## is never spoken for a linked step, so none is written here (an unused key would be dead weight).
##
## ============================================================================ THE ITEM: Fen's Diary Page
## kind "project_item" (schema: "'project_item', shows on the bag's Materials tab" - it is not placed,
## so "decoration" would be wrong). A memento, not a fetched resource: it exists so Vela's next line
## ("Please take this core. It kept me warm.") has something concrete behind it, the same way bolt.gd's items exist to make
## its steps physical rather than abstract. icon_color #8a8496 matches the shipped "scrap" swatch
## (catalog.gd) - old paper and old rubble read the same cool grey at icon size, and nothing about a
## torn log page should be warm (planet_props.gd's own rule for this world: "the only warm colour is
## the lamps").
##
## ============================================================================ THE ITEM: reused, like bolt's and zorp's
## "a dish-like decoration from the catalog" (the brief's own words). Catalog decorations considered
## (decoration_catalog.gd, every prop that could read as "a dish"):
##   whisper_array   REJECTED. It is already Vela's own shipped favour-tier reward (favor_system.gd:58
##                   "vela": "deco_whisper_array") and its own file header calls it "Vela's signature
##                   gift" and "the opposite reading" of the plain satellite dish specifically so the
##                   two would never be confused - reusing it here as a SECOND, project-given copy of
##                   his own signature piece would step on a design already made on purpose.
##   satellite_dish  CHOSEN. "ONE big parabolic on a tripod, cream, motionless" (whisper_array.gd's own
##                   description of it) is exactly a lone dish, footprint 0.85 (satellite_dish.gd:14),
##                   already sold in decoration_catalog.gd at 680 (tech, uncommon) - the SAME shape of
##                   reuse as bolt.gd's control_console.tscn (also separately sold, 580) and zorp.gd's
##                   orb_light.tscn: "any shipped decoration scene may be reused" (schema, ITEM).
## Wrapped as a NEW project item "vela_relay_dish": new id/name/desc, icon_color #d8a25c (Vela's own
## amber - vela_model.gd, the same swatch planet_props.gd's `_vela()` uses for every relay lamp - so
## the GIVEN dish visually claims kinship with the masts it stands beside, not with the cream shop
## original), same "scene", footprint matched to the scene's own DecoItem.footprint (0.85). NO
## "scrap_cost": Vela builds it himself overnight from the page and GIVES it the moment step 2 is
## asked (schema "give"; the day after the link completes) - exactly bolt.gd's and zorp.gd's pattern,
## and for the same reason: no round trip back to a bench for the story's own closing gift.
##
## ============================================================================ WHICH MAST, AND WHY "TWO"
## planet_props.gd's `_vela()` lights masts at loop index i == 1, 4, 7 (zero-based) - the 2nd, 5th and
## 8th mast built. Vela's own line says "mast two": the SECOND one built (i == 1), matching his own
## precise, ordinal-counting voice (small_talk: "I number the pools" is Fen's line, not hers, but
## "dish nine" and "dish four" - both ordinal, both exact - are, so a mast he'd name is by its own
## ordinal, not "the one at index one"). This is FLAVOUR TEXT, not a placement instruction: the place
## step's own "spot" is a fixed planet-local direction computed independently below and CONFIRMED
## PLACEABLE live by `debug_spot_report` (not a live lookup of any RelayMast node's transform - none
## is addressable from project_system.gd, which only knows planet-local directions), and mast i=1 was
## chosen BECAUSE it measured the most placeable of every lit mast tried (see below) - the flavour
## text was written to match the measured spot, not the other way around.
##
## ============================================================================ THE PLACE SPOT (no find step - see RULES)
## This project has no "find" step, so "spot" cannot be "marker:s<i>_m<n>" (schema: that form only
## exists once an earlier find step of the SAME project has run) - it is a literal [x,y,z], the form
## the schema documents right alongside "marker:". Every candidate below was computed in Python from
## the exact formula `_arc_side` uses (planet_props.gd:133-141: `arc_point` is a slerp, `_arc_side`
## offsets it by side_m/along_m over `planet.radius`), NOT eyeballed, and then MEASURED LIVE with
## `debug_spot_report` in a Director run (builder report has the full table; CLAUDE.md "measure, don't
## reason" - the first candidate beside the LIT mast the flavour text originally named, i=4 ("mast
## five"), measured only 32.2% placeable at radius 4.0 (blocked mostly by the array-dish cluster nearby)
## and was rejected on that number, not kept and hoped for:
##   spawn_dir = (0.454, 0.766, -0.454), pad_dir = (-0.5299, 0.4, -0.7477)  (data/vela.tres)
##   i=4 (t=0.476) side=8.0  along=0.4  -> 32.2% placeable, nearest_free 1.11 m - REJECTED
##   i=0 (t=0.060) side=11.0 along=0.0  -> 78.4% placeable, nearest_free 0.00 m - clear, but i=0 is
##                                          the one DARK mast in this stretch of the row (not lit)
##   i=1 (t=0.164) side=13.0 along=3.0  -> 81.9% placeable, nearest_free 0.00 m - CHOSEN: the highest
##                                          measured of every candidate tried, AND beside a lit mast
##   i=7 (t=0.788) side=11.0 along=0.0  -> 74.1% placeable, nearest_free 0.00 m - also lit, also good,
##                                          not chosen only because i=1 measured higher
## -> spot = (0.0676, 0.9937, 0.0899), measured 10.4 m from spawn, 18.4 m from pad and 10.6 m from
##    Vela's own home_dir - all far past DecorationManager.RESERVED_CLEARANCE (3.5 m), so "radius"
##    below needs no defensive oversize the way a spot near home/pad/spawn would.
## "radius": 4.0 - bolt.gd's own number for a single, one-item spot with room to walk around it; there
## is no world-specific reason here to move it (no fitted constants).
##
## ================================================================================ SCRAP ARITHMETIC
## Independently measured off data/vela.tres, not assumed from bolt.gd or zorp.gd even though (like
## zorp's) it lands on an identical structure (CLAUDE.md "Evidence rules"):
##   GameState.STARTING_SCRAP = 5                                       (game_state.gd:15,23)
##   scrap collectible pays randi_range(3,6), avg 4.5, floor 3          (collectible.gd:198-202)
##   vela.tres: collectible_count=10, collectible_kind =
##     "crystal_chunk,moon_flower,crystal_chunk,moon_flower,scrap" - a 5-entry list with exactly ONE
##     "scrap" entry, cycled twice over the 10 spawns (kind = kinds[i % kinds.size()],
##     planet_props.gd:2387-2404) -> "scrap" lands at i=4 and i=9 -> 2 scrap pickups/day on Vela's OWN
##     world alone, avg 9/day, floor 6/day. Identical structure to bolt's and zorp's worlds (same
##     5-entry, one-"scrap" list) - coincidence of authoring across all three, not assumed here.
## This project's OWN scrap cost is zero (the dish is given, never built; Fen's page costs nothing
## either) - the only scrap spent is part_fit_scrap at the bench, so the same bar bolt.gd and zorp.gd
## computed applies, on Vela's world alone:
##   Absolute floor (no pickups at all, on Vela's world alone): start 5, spend 0 -> still 5.
##     5 < 8: not affordable on zero pickups anywhere - unchanged from bolt.gd's and zorp.gd's bar.
##   Realistic floor (one guaranteed floor-roll pickup, of the 2 days x 2 scrap spawns/day = 4
##     available on Vela's world before the part can arrive - CORE_LOOP's one-step-a-day rule puts the
##     earliest arrival at day (start + 2)): 5 + 3 = 8 -> exactly covers the fit.
## BY THIS POINT IN THE STORY the player has also played through zorp, bolt, fen and grig - four
## worlds' worth of days and their OWN scrap floors - so the TRUE floor by the time Vela's part can
## arrive is far above 8; the arithmetic above is deliberately the same conservative Vela-only bar
## bolt.gd and zorp.gd used, not a bar inflated by assuming the player picked up anything on an
## earlier world (no fitted constants: nothing here is tuned to "feel right" for a late-game project,
## it is the same measured worst case). part_fit_scrap is set to 8 - unchanged from bolt.gd and
## zorp.gd, for the same reason both of them give: a timed play-through (Phase 6), not this file,
## is what should move it.
##
## Voice (docs/CAST_VOICES_DRAFT.md, approved 2026-09-27, with docs/STORY_HOME_SPEC.md 8.1): 
## Vela (he) is a gentle, shy lightbulb who listens to far-off sounds and says aloud when his bulb
## glows. Fen's "with" lines are in Fen's voice: he sat by the warm dish once and drew it in his diary.
## Plain English a 10-year-old reads once. Every line <= 60 characters.

const ITEM_ID := "vela_relay_dish"
const LINK_ITEM_ID := "vela_warmth_pages"
const CALL_COUNT := 3


static func definition() -> Dictionary:
	return {
		"npc": "vela",
		"part": "part_vela",
		"part_fit_scrap": 150,  # ECON 2026-09-29: the fit ladder's step in the usual fit order; the bench charges GameState.part_fit_scrap() (by parts already fitted)
		"intro": [
			"My masts used to glow. Now most of them are dark.",
			"I keep calling to them. They don't answer.",
			"Before I go, I'd like to hear them all once more.",
			"Will you help me? We take turns calling.",
		],
		"part_lines": [
			"Every dish and mast is working. Listen!",
			"Please take this core. It kept me warm.",
			"Good luck finding a new home. I'll think of you.",
		],
		"part_again": [
			"Lost the core? That's okay. I had a spare.",
		],
		"items": [
			{
				"id": LINK_ITEM_ID,
				"name": "Fen's Diary Page",
				"kind": "project_item",
				"category": "material",
				"desc": "A page from Fen's diary: a drawing of Vela's warm dish.",
				"icon_color": "#8a8496",
				# No scrap_cost: Fen hands this over the moment the light link completes ("hand_over").
			},
			{
				"id": ITEM_ID,
				"name": "Relay Dish",
				"kind": "decoration",
				"category": "tech",
				"desc": "A small dish Vela built from Fen's drawing. It listens.",
				"icon_color": "#d8a25c",
				# Reused decoration scene (schema: "any shipped decoration scene may be reused").
				# footprint must match the scene's own DecoItem.footprint (satellite_dish.gd:14).
				"scene": "res://src/decorations/items/satellite_dish.tscn",
				"footprint": 0.85,
				# No "scrap_cost": Vela assembles this himself and GIVES it (step 2's "give") - the
				# bench must not offer to build it (schema: "0 or absent = the bench does not build
				# this item; it comes from a talk step's give").
			},
		],
		"steps": [
			{
				"type": "minigame",
				"title": "Answer the array",
				"game": "call",
				"count": CALL_COUNT,
				"config": {
					"flavour": "spark",
				},
				"lines": {
					"ask": [
						"Stand in the ring. I will call a pattern.",
						"Use, Jump, Fly, Emote. Copy me, in order.",
					],
					"progress": [
						"The signal's still open. Try again?",
					],
					"done": [
						"You answered every call! My bulb is glowing.",
						"You listen back. Not many people do.",
					],
					"tomorrow": [
						"That's enough for today. Come back later?",
					],
				},
			},
			{
				"type": "talk",
				"npc": "fen",
				"title": "Ask Fen for the old readings",
				"hand_over": {LINK_ITEM_ID: 1},
				"lines": {
					"ask": [
						"My big dish was warm once. I can't remember how.",
						"Fen sat by it once. Could you go ask him?",
					],
					"progress": [
						"Have you seen Fen yet? He lives by the pools.",
					],
					"with": [
						"Vela's big dish? I sat by it once. So warm!",
						"I drew it in my diary. Here, take him the page.",
					],
					"tomorrow": [
						"The page can wait a little. No hurry.",
					],
				},
			},
			{
				"type": "place",
				"title": "Place the relay dish",
				"item": ITEM_ID,
				"spot": Vector3(0.0676, 0.9937, 0.0899),
				"radius": 4.0,
				"count": 1,
				"give": {ITEM_ID: 1},
				"lines": {
					"ask": [
						"I built a dish from Fen's drawing. Oh, I'm glowing!",
						"Put it by the lit mast, please. The second one.",
					],
					"progress": [
						"Not up yet. Look for the ring by the mast.",
					],
					"done": [
						"It's listening! All my masts can hear again.",
					],
					"tomorrow": [
						"Already up today. Let it settle a while.",
					],
				},
			},
			{
				# STORY_SPINE (PLANET_SAFARI_SPEC.md 15.2, migrated from the retired sky "photo" step,
				# same appended 4th-step slot, same neighbour lines shape - see project_system.gd's
				# "planet_photo" schema entry). Subject id "mirror_moon" is the exact roster id from
				# Vela's own safari manifest (res://src/planet_safari/worlds/vela.gd MANIFEST "roster" -
				# "The Mirror Moon", his own rare tier), checked at load against that same manifest. The
				# grade is raised to "Fine" (spec 15.2's table: "the last and hardest") - unlike every
				# other neighbour's Fair, Vela's is the LAST ask before the LAST part in the whole story.
				"type": "planet_photo",
				"title": "Photo: the Mirror Moon",
				"planet": "vela",
				"kind": "subject",
				"subject": "mirror_moon",
				"grade": "Fine",
				"lines": {
					"ask": [
						"One last thing. A photo of my home, before I go.",
						"The moon shines in the ice once each safari.",
						"Could you take a sharp photo of it?",
					],
					"progress": [
						"Not yet? The moon shows in the ice once a safari.",
					],
					"already_have": [
						"You already have a sharp one? Oh! I'm glowing.",
					],
					"smudge": [
						"I see it, but it's a little blurry.",
						"Hold the shutter down. Let the picture bloom.",
					],
					"done": [
						"The moon in the ice. It's beautiful.",
						"I'll keep this photo always. It's my home.",
					],
				},
			},
		],
	}
