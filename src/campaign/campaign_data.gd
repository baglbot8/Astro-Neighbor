class_name CampaignData
extends RefCounted
## Static data + gate logic for the "Stranded" campaign (docs/CORE_LOOP.md, docs/BUILD_PLAN.md).
## Static data and static functions only - never instance this, there is no per-instance state.
##
## Read `gates_on()` / `planet_in_range()` / `parts_needed_for()` / `finish_stage()` rather than
## `GameState.campaign_active` etc. directly: they are the one place THE DIRECTOR RULE lives, and
## every planet-range or rocket-finish consumer needs the same answer.

## One part per neighbour world, in the fitting order CORE_LOOP.md's "Range tiers" table earns them
## (Zorp, Bolt first - tier 1 - then Fen, Grig, then Vela last). `name` is a short placeholder for
## UI copy; content builders (BUILD_PLAN Phase 2-3) can rename without touching `id`, which is what
## GameState.rocket_parts and save files key on.
const PARTS := [
	{"id": "part_zorp", "npc": "zorp", "name": "Zorp Coil"},
	{"id": "part_bolt", "npc": "bolt", "name": "Bolt Gear"},
	{"id": "part_fen", "npc": "fen", "name": "Fen Cell"},
	{"id": "part_grig", "npc": "grig", "name": "Grig Valve"},
	{"id": "part_vela", "npc": "vela", "name": "Vela Core"},
]

## Range tiers (CORE_LOOP.md "Range tiers", "a first idea, to test" - Phase 6 tunes this from a
## timed play-through). "home" is not listed: it is always in range, see `planet_in_range`. Tiers
## are cumulative and disjoint - each planet belongs to exactly one tier's list, and reaching a
## later tier's threshold does not remove an earlier one.
const TIERS := [
	{"parts": 0, "planets": ["hub", "zorp", "bolt"]},
	{"parts": 2, "planets": ["fen", "grig"]},
	{"parts": 4, "planets": ["vela"]},
]

## Campaign gates are OFF whenever a Director timeline runs, unless the timeline opts in with
## "--campaign" - the same opt-in shape as "--intro" (intro_director.gd:92-98) - so every EXISTING
## timeline keeps today's open world (BUILD_PLAN.md "Rules for every phase"). Gates are also off
## once the story is finished (`story_done`), which is exactly the state an old save loads into
## (GameState.from_dict defaults `story_done` to true and `campaign_active` to false when those
## keys are missing) and the state a finished campaign save reaches at the real ending.
static func gates_on() -> bool:
	return GameState.campaign_active and not GameState.story_done \
		and (not Director.is_active() or Director.campaign_opt_in())

## True for every planet when gates are off - an old save, a finished story, or a Director
## timeline that did not opt in all see the game's open world, unchanged from today.
static func planet_in_range(planet_id: String) -> bool:
	if not gates_on():
		return true
	if planet_id == "home":
		return true
	var have := GameState.rocket_part_count()
	for tier in TIERS:
		if (tier["planets"] as Array).has(planet_id):
			return have >= int(tier["parts"])
	# Not in any tier's list (e.g. an id typo) - default closed rather than silently open.
	return false

## How many rocket parts unlock this planet. 0 for "home" and for tier 1 planets (open at the
## start). Meaningless when gates are off; callers that only want a range check should use
## `planet_in_range` instead.
static func parts_needed_for(planet_id: String) -> int:
	if planet_id == "home":
		return 0
	for tier in TIERS:
		if (tier["planets"] as Array).has(planet_id):
			return int(tier["parts"])
	return 0

## Which of the rocket's six finish stages (0 rusty/dirty .. 5 gold, BUILD_PLAN.md "rocket range")
## to render. Pinned to 4 - today's clean white rocket - when gates are off, so old saves and every
## existing Director timeline look exactly as they do today (BUILD_PLAN.md "Rules for every phase").
static func finish_stage() -> int:
	if not gates_on():
		return 4
	return clampi(GameState.rocket_part_count(), 0, 5)
