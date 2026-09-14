class_name ProjectSystem
extends Node
## Neighbour PROJECTS: a world's problem, solved in ordered steps over several game days
## (docs/CORE_LOOP.md "Pacing" and "Changed after the build plan", docs/BUILD_PLAN.md Phase 2 builder E).
## One instance per world, created lazily as a child of /root/World, the same pattern as FavorSystem:
##
##   var projects := ProjectSystem.get_or_create()
##   var handled: bool = await projects.handle_conversation(runner, npc, player)
##   await projects.complete_live_link(runner, npc)   # ALWAYS, before the above - see below
##
## conversation.gd calls `handle_conversation` BEFORE its favor branches and skips them when it returns
## true, so a random favor never competes with a project for the same talk. It calls
## `complete_live_link` even earlier, UNCONDITIONALLY - regardless of a ready favour, a delivery gift
## or anything else - so a LIGHT LINK (see below) always completes the moment you talk to the neighbour
## it names, never waiting on whatever else that talk was about to do. See "conversation: light links".
##
## THE RULES IT ENFORCES
##   * A project STARTS the first time you talk to that neighbour while CampaignData.gates_on().
##     Gates off (an old save, a finished story, a Director run without "--campaign") = inert: every
##     call returns false and nothing is drawn, so today's favors run exactly as before.
##   * ONE STEP PER NEIGHBOUR PER GAME DAY (CORE_LOOP "Changed after the build plan"). Completing a
##     step writes GameState.project_step_day[npc] = GameState.day_count; the next step is only ASKED
##     once day_count is greater. Until then the neighbour says the completed step's "tomorrow" lines.
##   * Friendship per step (GameState.add_friendship), EventBus.project_step_completed per step, and
##     EventBus.project_completed(npc, part_id) when the last step's talk hands over the part as a bag
##     item (the gift the bench needs to fit it).
##   * State is committed BEFORE the lines are spoken, so a talk cut short can never lose progress; a
##     project whose steps are all done but whose part was never handed over hands it over next talk.
##   * A "talk" step can be a LIGHT LINK (its "npc" key) to another neighbour (CORE_LOOP "More
##     mini-games, one per neighbour"): this project's own neighbour still ASKS it, but it is
##     COMPLETED in a conversation with the NAMED one instead - see "conversation: light links" and
##     the STEP SCHEMA's "talk" entry below.
##
## ONE EXCEPTION TO "returns true while a project is active": when a delivery gift addressed to this
## neighbour is in the bag, this runs its own lines and then returns FALSE, so conversation.gd's
## FIRST favor branch - the delivery - opens the gift in the same talk. Without it a Commons
## neighbour's "deliver a gift to Bolt" favor stalls for the whole project (three game days, 30 real
## minutes or more). That branch is exclusive (conversation.gd `if ... elif`), so no favor OFFER can
## follow. It depends on conversation.gd keeping the delivery branch first.
##
## ================================================================================= DEFINITION SCHEMA
## One file per neighbour: res://src/projects/data/<npc_id>.gd, a script with
##
##   static func definition() -> Dictionary
##
## The file is found by the neighbour ids in CampaignData.PARTS (zorp, bolt, fen, grig, vela), so no
## registry needs editing. Every key below is exact; anything marked (optional) may be left out. A
## definition that breaks a rule is rejected with push_error (tools/check.sh fails on it) and that
## neighbour then has no project, so favors run as before.
##
##   {
##     "npc": "bolt",                 NpcData id of the neighbour who runs the project.
##     "part": "part_bolt",           CampaignData.PARTS id handed over when the last step is done.
##     "part_name": "Bolt Gear",      (optional) bag name; defaults to CampaignData.PARTS "name".
##     "part_desc": "...",            (optional) bag description.
##     "part_icon_color": "#ffb05c",  (optional) bag swatch colour.
##     "part_fit_scrap": 10,          Scrap the BENCH charges to fit the part into the rocket. Stored on
##                                    the part's Catalog item as "scrap_cost" (see ITEM).
##     "part_fit_stardust": 0,        (optional) stardust the bench charges on top, as "stardust_cost".
##     "intro": ["...", "..."],       Said once, in the conversation the project starts in, before
##                                    step 0's "ask" lines.
##     "part_lines": ["...", "..."],  Said after the last step's "done" lines, as the part is given.
##     "part_again": ["..."],         (optional) said if the player lost the part (dropped it from the
##                                    bag) before fitting it; the neighbour hands over a new one.
##     "items": [ITEM, ...],          New items this project introduces (may be []).
##     "steps": [STEP, STEP, STEP],   Ordered; CORE_LOOP asks for three.
##   }
##
## ITEM - registered with Catalog.register() when the system starts (every world load, see
## `ensure_items_registered`), so the bag, the bench and placement mode all see it. Keys are Catalog's
## own (src/autoload/catalog.gd) plus the two bench costs:
##
##   {
##     "id": "bolt_yard_fixer",       Required, unique game-wide: prefix it with the npc id.
##     "name": "Yard Fixer",          Required.
##     "kind": "decoration",          "decoration" if a PLACE step places it (then "scene" is required),
##                                    otherwise "project_item" (shows on the bag's Materials tab).
##     "category": "tech",            (optional) "material" by default for project_item.
##     "desc": "...",                 (optional) bag description.
##     "icon_color": "#ff9f43",       (optional) bag swatch colour.
##     "scene": "res://src/decorations/items/<x>.tscn",   decoration only; must exist (any shipped
##                                    decoration scene may be reused).
##     "footprint": 0.7,              (optional) decoration only, metres.
##     "scrap_cost": 6,               Scrap the BENCH charges to build one. 0 or absent = the bench does
##                                    not build this item (it comes from a talk step's "give", say).
##     "stardust_cost": 0,            (optional) stardust the bench charges on top.
##   }
##
## The system adds "project": <npc id>, "price": 0 (never sold in a shop) and "rarity": "common" when
## missing. The bench (builder F) reads "scrap_cost" / "stardust_cost" from Catalog.get_item(id), and
## the same two keys on the PART's Catalog item are the cost of fitting it. `ProjectSystem.bench_items()`
## lists the items the bench should offer right now (projects that have started and are not finished).
##
## STEP - every step has a "type" and "lines"; the other keys depend on the type:
##
##   common:
##     "type": "talk" | "find" | "collect" | "build" | "place" | "minigame"
##     "title": "Find the broken machines"   (optional) short journal line; a default is built.
##     "lines": {
##       "ask":      [...]   said the first time the step comes up (the first talk on a game day it
##                           is unlocked). A talk step's whole content lives here.
##       "progress": [...]   said when you talk while the step is live but not done yet. The system
##                           adds one status line after it, e.g. "(2 of 3 found.)".
##       "done":     [...]   said on the talk that completes the step.
##       "tomorrow": [...]   said when you talk again the SAME game day after this step was completed
##                           (the next step is locked until tomorrow). Unused on the last step.
##       "with":     [...]   "talk" STEP WITH "npc" SET ONLY (see the "talk" entry below): said by the
##                           NAMED neighbour when the link completes, right after THAT talk's own
##                           greeting - replacing "done", which a linked step never speaks. Lives
##                           INSIDE "lines" exactly like the four keys above it, never as a step key
##                           (unlike "hand_over" below). REQUIRED and non-empty whenever "npc" is set;
##                           refused at load if it is empty, missing, or given as a step key instead.
##     }
##     "give": {"item_id": count}     (optional, any type) items handed over when the step is asked.
##                                    The bag's "Drop" button destroys items (inventory.gd), so never
##                                    make a LATER step need a given item unless the bench can also
##                                    build it; a dropped one would otherwise be gone for good. (The
##                                    part is safe: a neighbour re-gives a lost part, see "part_again".)
##                                    See a "talk" step's "hand_over" for the equivalent at the moment
##                                    a light-linked step FINISHES rather than when it is asked.
##     "friendship": 5                (optional) friendship added when the step completes; default
##                                    FRIENDSHIP_PER_STEP.
##
##   "talk"     Completes in the conversation that asks it: "ask" lines, then "done" lines - UNLESS
##              it names another neighbour with the optional "npc": "<id>" key. That makes it a LIGHT
##              LINK (CORE_LOOP "More mini-games, one per neighbour" - a quick, empty-handed trip:
##              Grig needs a seed pouch from Zorp, Vela needs a page from Fen's logbook). With "npc" set:
##                * This step's OWN neighbour still ASKS it exactly as usual ("ask" lines, then
##                  "progress" lines while it waits, then "tomorrow" lines the same day it is done) -
##                  but asking it never completes it; "done" is never spoken for a linked step.
##                * It is completed instead in a conversation with the NAMED neighbour, who says the
##                  step's "with" lines (a "lines" key, see above - NOT a step key) - see
##                  `ProjectSystem.complete_live_link`, which fires this the FIRST time you talk to
##                  them while the link is live, always, right after THAT talk's own greeting
##                  (Conversation.run - see its header) and before anything of their own (their own
##                  project step, a ready favour or a gift still happens right after, in the same talk).
##                "hand_over": {"item_id": count}   (optional STEP key - unlike "with" above) items
##                                       given the moment the link completes, by the NAMED neighbour -
##                                       the "give" for when a step is FINISHED rather than ASKED
##                                       ("give" keeps its own meaning: handed over when this step is
##                                       asked, by the OWN neighbour, unchanged).
##              VALIDATED AT LOAD: "npc" must be a real NpcData id, must not be this project's own
##              "npc", and must live on a world in the same or an earlier CampaignData tier than this
##              project's world (a link never sends the player somewhere still out of range); "lines"
##              needs a non-empty "with" - refused if it is empty or missing, and refused if "with" is
##              given as a step key instead of inside "lines" (the exact shape this schema mistakenly
##              showed once: a def written that way loaded clean and the link completed with nothing
##              said - both are now named, specific push_errors).
##              THE "!": shown over the NAMED neighbour for as long as the link is live, and hidden
##              over this step's own neighbour meanwhile - their "progress" lines should say where to
##              go (`wants_marker`).
##              THE DAY: completing the link counts as THIS PROJECT'S OWN neighbour's step for the day
##              (`GameState.project_step_day[<this project's "npc">]`), exactly like any other step -
##              it never spends the NAMED neighbour's own day lock.
##   "find"     "count": 3             how many markers to visit.
##              "planet": "bolt"       (optional) which world the markers are on; default the
##                                     neighbour's own planet (NpcData "planet").
##              "dirs": [[x,y,z],...]  (optional) planet-local unit directions (Vector3 also accepted);
##                                     left out, the system spreads "count" markers over free, flat
##                                     ground away from the pad, the spawn and each other.
##              "marker_label": "broken machine"   used in toasts: "Found a broken machine (1/3)".
##              Markers appear once the step is asked and stay until it is completed. A marker counts
##              as found when the astronaut walks within ProjectMarkers.VISIT_RADIUS of it; found
##              markers are saved. Marker ids are "s<step>_m<n>", e.g. "s1_m0".
##   "collect"  "item": "gear_bit" | "scrap"   "scrap" reads GameState.scrap (a counter, never the bag).
##              "count": 4
##              "take": true           (optional, default true) the neighbour takes them when done.
##   "build"    "item": "bolt_power_cell"      an ITEM with a "scrap_cost" (the bench builds it).
##              "count": 1
##              "take": true           (optional, default true). Set false when a later PLACE step
##                                     places the same item.
##   "place"    "item": "bolt_yard_fixer"      a decoration ITEM.
##              "planet": "bolt"       (optional) default the neighbour's planet.
##              "spot": "npc" | "pad" | "spawn" | [x,y,z] | "marker:s1_m0"
##                                     where it must stand: the neighbour's HOME spot (not where they
##                                     have wandered to), the rocket pad, the landing spawn, an explicit
##                                     planet-local direction (Vector3 also accepted), or a marker from
##                                     an earlier find step of this project.
##                                     Nothing can be placed within DecorationManager.RESERVED_CLEARANCE
##                                     (3.5 m) of the home, pad or spawn, so "radius" must be well over
##                                     that for those three; `debug_spot_report(npc)` measures how much
##                                     of the ring is placeable.
##              "radius": 5.0          metres, straight line from the placed item's origin to the spot's
##                                     ground point. A ring of this radius is drawn on the ground while
##                                     the step is live.
##              "count": 1             (optional) how many must stand inside the ring.
##   "minigame" A thing you PLAY on the neighbour's world, instead of another fetch trip
##              (docs/CORE_LOOP.md "Mini-games instead of fetch trips", decided 2026-09-12 after the
##              user played on their phone). Built on the jetpack the game already has.
##              "game": "catch"        a kind in MinigameSystem.GAMES.
##              "count": 5             how many to collect; passed to the game as its "count".
##              "planet": "bolt"       (optional) which world it is played on; default the
##                                     neighbour's own.
##              "config": {...}        (optional) handed to MinigameSystem.start() on top of "count",
##                                     "done" and "owner". Its keys belong to the GAME and are
##                                     documented at the top of that game's script - for "catch"
##                                     (src/minigames/catch_game.gd) they are flavour, label,
##                                     label_plural, title, near, near_radius_m, speed, height, seed.
##              The game starts by itself whenever the step is live and the player is on that planet,
##              and is cancelled when the step is completed, the gates go off, or the player leaves.
##              Progress is saved in "found" as "s<step>_g<n>" - the same array a find step's markers
##              use - so a half-played game survives a save, a reload and a trip to another world,
##              with no new GameState field. The step is MET once every one is collected; the
##              neighbour's "done" lines still finish it in a talk, exactly like "find".
##              The kind is checked against MinigameSystem.GAMES at load, which is a REGISTRY, not a
##              promise that the script exists: a build without that game's file logs a warning from
##              MinigameSystem.start() and the step simply never starts. `MinigameSystem.has_game()`
##              is the runtime test.
##
## Writing (docs/STYLE_GUIDE.md "Writing"): each string <= 60 characters, 1-3 strings per list.
##
## ================================================================================= SAVED STATE
## GameState.projects[npc_id] (this file owns the shape; JSON turns ints into floats, so `_state`
## normalises it on every read):
##   {"step": int, "asked": bool, "found": [marker id], "markers": {marker id: [x,y,z]},
##    "days": [game day each step completed], "done": bool, "started_day": int}
##   step     index of the step in progress; == steps.size() once every step is done
##   asked    the neighbour has introduced `step` (its markers / ring are live)
##   markers  directions the system chose for find markers, saved so they never move between loads
##            and a later place step can aim at one
## GameState.project_step_day[npc_id] = the game day of the neighbour's last completed step.
##
## ================================================================================= TEST-ONLY HOOK
## "--project-def=/absolute/path/def.gd" (a USER arg, after the "--") loads one extra definition from
## outside the project and lets it REPLACE the shipped one for its "npc". It is honoured ONLY while a
## Director timeline runs (Director.is_active()), the same gate as FavorSystem.debug_force_template,
## so a stray flag can never change a real game. Off by default; nothing ships that uses it.

const NODE_NAME := "ProjectSystem"
const DATA_DIR := "res://src/projects/data/"
const TEST_DEF_ARG := "--project-def="
const STEP_TYPES: PackedStringArray = ["talk", "find", "collect", "build", "place", "minigame"]
const SPOT_WORDS: PackedStringArray = ["npc", "pad", "spawn"]
const SCRAP_ID := "scrap"
## Prefix on every mini-game this system owns, so `MinigameSystem.sync_owners` can tidy up after a
## project without ever touching a game somebody else started (the dev menu's own "dev:" games).
const MINIGAME_OWNER_PREFIX := "project:"
## A finished three-step project alone should make the neighbour a "pal" (FavorSystem.TRUST_PAL = 15):
## 15 / 3 steps = 5 per step.
const FRIENDSHIP_PER_STEP := 5
## Auto-placed find markers. Each one needs this much free, level ground around it
## (Planet.find_free_dir clearance) so the beacon's 0.46 m base plate sits flat.
const MARKER_CLEARANCE_M := 0.9
## ...and keeps this much MORE than DecorationManager.RESERVED_CLEARANCE (3.5 m) from the pad, the
## spawn and every neighbour's home, so the ground right beside a marker is legal to decorate. That is
## what makes a "place" step aimed at "marker:<id>" always achievable.
const MARKER_RESERVED_GAP_M := 1.0
const MARKER_CANDIDATES := 32
const MARKER_TRIES := 600
## Fallback lines when a definition leaves one out.
const DEFAULT_TOMORROW: Array = ["That is enough for one day. Come back tomorrow!"]
const DEFAULT_PART_AGAIN: Array = ["You lost it? Good thing I made a spare."]
## `debug_spot_report` samples the place ring on this grid (metres).
const SPOT_SAMPLE_STEP_M := 0.35

static var _defs: Dictionary = {}
static var _defs_loaded := false

var _markers: ProjectMarkers
var _planet: Planet
## npc id -> whether their live step's objective was met at the last check, so the "ready" toast
## fires once, on the change, and never at load.
var _met_cache: Dictionary = {}
var _refresh_queued := false


## Finds the world's ProjectSystem, creating it under /root/World the first time. Null outside a
## world (a showcase scene has no /root/World): conversation.gd then runs favors as before.
static func get_or_create() -> ProjectSystem:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		return null
	var existing := host.get_node_or_null(NODE_NAME)
	if existing is ProjectSystem:
		return existing as ProjectSystem
	var ps := ProjectSystem.new()
	ps.name = NODE_NAME
	host.add_child(ps)
	return ps


func _ready() -> void:
	ensure_items_registered()
	_markers = ProjectMarkers.new()
	_markers.name = "Markers"
	add_child(_markers)
	_markers.marker_visited.connect(_on_marker_visited)
	EventBus.item_added.connect(_on_progress_signal.unbind(2))
	EventBus.item_removed.connect(_on_progress_signal.unbind(2))
	EventBus.scrap_changed.connect(_on_progress_signal.unbind(2))
	EventBus.decoration_placed.connect(_on_progress_signal.unbind(3))
	EventBus.decoration_removed.connect(_on_progress_signal.unbind(2))
	EventBus.planet_loaded.connect(_on_planet_loaded)
	# A load (GameState.from_dict) or the story's end can switch the gates off while a world is up;
	# redraw so no marker or ring is left standing on a world with no project.
	EventBus.campaign_changed.connect(_queue_refresh)
	# Deferred: when world.gd creates this early in its _ready, the DecorationManager (which the
	# place check and the marker ground test read) does not exist yet.
	_queue_refresh()


# ============================================================================= definitions
## The validated definition for a neighbour, or {} when they have no project.
static func definition_for(npc_id: String) -> Dictionary:
	_load_definitions()
	return _defs.get(npc_id, {})


static func all_definitions() -> Array:
	_load_definitions()
	return _defs.values()


static func _load_definitions() -> void:
	if _defs_loaded:
		return
	_defs_loaded = true
	for p: Dictionary in CampaignData.PARTS:
		var npc := str(p.get("npc", ""))
		var path := DATA_DIR + npc + ".gd"
		if npc == "" or not ResourceLoader.exists(path):
			continue
		var d := _read_definition(load(path), path)
		if not d.is_empty():
			_defs[str(d["npc"])] = d
	var test_path := _test_definition_path()
	if test_path != "":
		var td := _read_definition(_load_script_abs(test_path), test_path)
		if not td.is_empty():
			_defs[str(td["npc"])] = td
			print("ProjectSystem: TEST definition for '%s' loaded from %s (Director run only)" % [td["npc"], test_path])


## The "--project-def=" path, or "" - and always "" unless a Director timeline is running.
static func _test_definition_path() -> String:
	if not Director.is_active():
		return ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(TEST_DEF_ARG):
			return a.substr(TEST_DEF_ARG.length())
	return ""


## Compiles a script from an absolute path outside res:// (the test hook). The source route is used
## because ResourceLoader is not guaranteed to resolve a path outside the project.
static func _load_script_abs(path: String) -> GDScript:
	if not FileAccess.file_exists(path):
		push_error("ProjectSystem: test definition not found: %s" % path)
		return null
	var s := GDScript.new()
	s.source_code = FileAccess.get_file_as_string(path)
	if s.reload() != OK:
		push_error("ProjectSystem: test definition does not compile: %s" % path)
		return null
	return s


static func _read_definition(script: Variant, path: String) -> Dictionary:
	if not (script is GDScript):
		push_error("ProjectSystem: %s is not a script" % path)
		return {}
	var has_def := false
	for m: Dictionary in (script as GDScript).get_script_method_list():
		if str(m.get("name", "")) == "definition":
			has_def = true
			break
	if not has_def:
		push_error("ProjectSystem: %s has no static func definition()" % path)
		return {}
	var raw: Variant = (script as GDScript).call("definition")
	if not (raw is Dictionary):
		push_error("ProjectSystem: %s definition() must return a Dictionary" % path)
		return {}
	var d: Dictionary = (raw as Dictionary).duplicate(true)
	var why := _invalid_reason(d)
	if why != "":
		push_error("ProjectSystem: %s rejected: %s" % [path, why])
		return {}
	return d


## Index into CampaignData.TIERS for `planet_id` (0 = earliest tier gated behind rocket parts), or -1
## for "home" (not in any tier - always reachable, so always earliest). 99 for an id in no tier at all,
## so an unresolvable planet fails a light link's "same or earlier tier" check rather than passing one.
static func _tier_index(planet_id: String) -> int:
	if planet_id == "home":
		return -1
	for idx in CampaignData.TIERS.size():
		if (CampaignData.TIERS[idx]["planets"] as Array).has(planet_id):
			return idx
	return 99


## "" when the definition is usable, otherwise the first rule it breaks. Everything a player could get
## stuck on is checked here, at load, rather than discovered three game days into a project.
static func _invalid_reason(d: Dictionary) -> String:
	var npc := str(d.get("npc", ""))
	if NpcData.get_data(npc).is_empty():
		return "\"npc\" '%s' is not an NpcData id" % npc
	var part := str(d.get("part", ""))
	var part_ok := false
	for p: Dictionary in CampaignData.PARTS:
		if str(p.get("id", "")) == part:
			part_ok = true
	if not part_ok:
		return "\"part\" '%s' is not a CampaignData.PARTS id" % part
	var items: Dictionary = {}
	var raw_items: Variant = d.get("items", [])
	if not (raw_items is Array):
		return "\"items\" must be an Array"
	for it: Variant in raw_items:
		if not (it is Dictionary) or str((it as Dictionary).get("id", "")) == "" or str((it as Dictionary).get("name", "")) == "":
			return "every item needs an \"id\" and a \"name\""
		var item := it as Dictionary
		items[str(item["id"])] = item
		if str(item.get("kind", "project_item")) == "decoration":
			var scene := str(item.get("scene", ""))
			if scene == "" or not ResourceLoader.exists(scene):
				return "decoration item '%s' needs a \"scene\" that exists" % item["id"]
	var steps: Variant = d.get("steps", [])
	if not (steps is Array) or (steps as Array).is_empty():
		return "\"steps\" must be a non-empty Array"
	for i in (steps as Array).size():
		var sv: Variant = (steps as Array)[i]
		if not (sv is Dictionary):
			return "step %d is not a Dictionary" % i
		var s := sv as Dictionary
		var t := str(s.get("type", ""))
		if not STEP_TYPES.has(t):
			return "step %d \"type\" '%s' is not one of %s" % [i, t, str(STEP_TYPES)]
		if not (s.get("lines", {}) is Dictionary):
			return "step %d \"lines\" must be a Dictionary" % i
		if s.has("give") and not (s["give"] is Dictionary):
			return "step %d \"give\" must be a Dictionary of item id -> count" % i
		if s.has("with"):
			return "step %d \"with\" must be inside \"lines\" (\"lines\": {\"with\": [...]}), not a step key" % i
		match t:
			"talk":
				if s.has("npc"):
					var target := str(s["npc"])
					if NpcData.get_data(target).is_empty():
						return "step %d (talk) \"npc\" '%s' is not an NpcData id" % [i, target]
					if target == str(d.get("npc", "")):
						return "step %d (talk) \"npc\" must not be this project's own neighbour" % i
					var owner_tier := _tier_index(str(NpcData.get_data(str(d.get("npc", ""))).get("planet", "")))
					var target_tier := _tier_index(str(NpcData.get_data(target).get("planet", "")))
					if target_tier > owner_tier:
						return "step %d (talk) \"npc\" '%s' lives on a later CampaignData tier than this project's world" % [i, target]
					if s.has("hand_over") and not (s["hand_over"] is Dictionary):
						return "step %d (talk) \"hand_over\" must be a Dictionary of item id -> count" % i
					var with_lines: Variant = (s.get("lines", {}) as Dictionary).get("with", [])
					if not (with_lines is Array) or (with_lines as Array).is_empty():
						return "step %d (talk) \"npc\" is set: \"lines\" needs a non-empty \"with\" (said by the NAMED neighbour when the link completes)" % i
			"find":
				if int(s.get("count", 0)) < 1:
					return "step %d (find) needs \"count\" >= 1" % i
				if s.has("dirs") and (not (s["dirs"] is Array) or (s["dirs"] as Array).size() < int(s["count"])):
					return "step %d (find) \"dirs\" must hold at least \"count\" directions" % i
			"collect", "build":
				var item_id := str(s.get("item", ""))
				if item_id == "" or int(s.get("count", 0)) < 1:
					return "step %d (%s) needs \"item\" and \"count\" >= 1" % [i, t]
				if t == "build":
					var bi: Dictionary = items.get(item_id, {})
					if bi.is_empty() or (int(bi.get("scrap_cost", 0)) <= 0 and int(bi.get("stardust_cost", 0)) <= 0):
						return "step %d (build) item '%s' must be one of this project's items with a \"scrap_cost\"" % [i, item_id]
				elif item_id != SCRAP_ID and not items.has(item_id) and not Catalog.has_item(item_id):
					return "step %d (collect) item '%s' is not in the Catalog" % [i, item_id]
			"place":
				var pi: Dictionary = items.get(str(s.get("item", "")), {})
				if pi.is_empty() or str(pi.get("kind", "")) != "decoration":
					return "step %d (place) \"item\" must be one of this project's decoration items" % i
				if float(s.get("radius", 0.0)) <= 0.0:
					return "step %d (place) needs \"radius\" > 0" % i
				var spot: Variant = s.get("spot", "")
				var spot_ok := spot is Vector3 or (spot is Array and (spot as Array).size() == 3) \
					or (spot is String and (SPOT_WORDS.has(spot) or (spot as String).begins_with("marker:")))
				if not spot_ok:
					return "step %d (place) \"spot\" must be \"npc\", \"pad\", \"spawn\", [x,y,z] or \"marker:<id>\"" % i
			"minigame":
				var game_id := str(s.get("game", ""))
				if not MinigameSystem.GAMES.has(game_id):
					return "step %d (minigame) \"game\" '%s' is not one of %s" % [i, game_id, str(MinigameSystem.GAMES.keys())]
				if int(s.get("count", 0)) < 1:
					return "step %d (minigame) needs \"count\" >= 1" % i
				if s.has("config") and not (s["config"] is Dictionary):
					return "step %d (minigame) \"config\" must be a Dictionary" % i
	return ""


# ============================================================================= catalog
## Registers every project item and every part with the Catalog. Idempotent and cheap, so anyone who
## needs the items (the bench, the bag) may call it; `_ready` does, on every world load.
static func ensure_items_registered() -> void:
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		for it: Dictionary in d.get("items", []):
			var id := str(it["id"])
			if Catalog.has_item(id) and str(Catalog.get_item(id).get("project", "")) == npc:
				continue
			var def := it.duplicate(true)
			def["project"] = npc
			def["price"] = 0
			if not def.has("kind"):
				def["kind"] = "project_item"
			if not def.has("rarity"):
				def["rarity"] = "common"
			if str(def["kind"]) != "decoration" and not def.has("category"):
				def["category"] = "material"
			def["scrap_cost"] = int(def.get("scrap_cost", 0))
			def["stardust_cost"] = int(def.get("stardust_cost", 0))
			Catalog.register(def)
		_register_part(d)


## The part is a bag item until the bench fits it. Keys another system already set on the part's
## Catalog entry are kept; the definition's fitting cost wins because it is per-neighbour data.
static func _register_part(d: Dictionary) -> void:
	var part_id := str(d["part"])
	var existing := Catalog.get_item(part_id)
	if str(existing.get("project", "")) == str(d["npc"]):
		return
	var def := existing.duplicate(true)
	def["id"] = part_id
	def["name"] = str(d.get("part_name", def.get("name", part_name(part_id))))
	def["kind"] = str(def.get("kind", "rocket_part"))
	def["category"] = str(def.get("category", "material"))
	def["rarity"] = str(def.get("rarity", "legendary"))
	def["price"] = 0
	def["desc"] = str(d.get("part_desc", def.get("desc", "A rocket part from %s. It goes inside the rocket." % _npc_name(str(d["npc"])))))
	def["icon_color"] = str(d.get("part_icon_color", def.get("icon_color", NpcData.get_data(str(d["npc"])).get("accent", "#f0a64a"))))
	def["project"] = str(d["npc"])
	def["scrap_cost"] = int(d.get("part_fit_scrap", def.get("scrap_cost", 0)))
	def["stardust_cost"] = int(d.get("part_fit_stardust", def.get("stardust_cost", 0)))
	Catalog.register(def)


## CampaignData.PARTS "name" for a part id ("Bolt Gear"), or the id.
static func part_name(part_id: String) -> String:
	var def := Catalog.get_item(part_id)
	if def.has("name"):
		return str(def["name"])
	for p: Dictionary in CampaignData.PARTS:
		if str(p.get("id", "")) == part_id:
			return str(p.get("name", part_id))
	return part_id


## Catalog defs the bench should offer now: items with a bench cost from every project that has
## started and is not finished. Empty when gates are off (no projects run).
static func bench_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not CampaignData.gates_on():
		return out
	ensure_items_registered()
	for d: Dictionary in all_definitions():
		var st := _state(str(d["npc"]))
		if st.is_empty() or bool(st["done"]):
			continue
		for it: Dictionary in d.get("items", []):
			var def := Catalog.get_item(str(it["id"]))
			if int(def.get("scrap_cost", 0)) > 0 or int(def.get("stardust_cost", 0)) > 0:
				out.append(def)
	return out


# ============================================================================= queries
## True while this neighbour's project has started and the part has not been handed over.
static func has_active_project(npc_id: String) -> bool:
	if not CampaignData.gates_on() or definition_for(npc_id).is_empty():
		return false
	var st := _state(npc_id)
	return not st.is_empty() and not bool(st["done"])


## True when the neighbour may introduce their next step today (CORE_LOOP: one step per game day).
static func step_unlocked(npc_id: String) -> bool:
	if not GameState.project_step_day.has(npc_id):
		return true
	return GameState.day_count > int(GameState.project_step_day[npc_id])


## Every mini-game the story has unlocked, for the Commons replay board (docs/CORE_LOOP.md "Replays
## from the Commons", decided 2026-09-13). A game unlocks when the project has moved PAST its
## "minigame" step. With the campaign gates off (the story is finished, or an old save that loads as
## finished) every mini-game step in every definition counts, because there is no story left to lock
## it. One entry per step: {"npc", "step", "game", "planet", "count", "config"} - the same values
## `_start_minigame` hands to MinigameSystem.start(), minus the save-bound "owner" and "done", so a
## replay host can start the very game the story step played. Read-only: it never writes state.
static func played_minigames() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var story_over := not CampaignData.gates_on()
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		var st := _state(npc)
		var steps: Array = d["steps"]
		for i in steps.size():
			var step: Dictionary = steps[i]
			if str(step["type"]) != "minigame":
				continue
			if not story_over:
				if st.is_empty() or (not bool(st["done"]) and int(st["step"]) <= i):
					continue
			out.append({
				"npc": npc,
				"step": i,
				"game": str(step.get("game", "")),
				"planet": _step_planet(npc, step),
				"count": maxi(1, int(step.get("count", 1))),
				"config": (step.get("config", {}) as Dictionary).duplicate(true),
			})
	return out


## For the "!" over a neighbour (npc.gd reads FavorSystem today; see the builder report):
## -1 = no project opinion (fall back to favors), 0 = hide it, 1 = show it.
## A LIGHT LINK naming `npc_id` (a "talk" step elsewhere whose "npc" is them) wins first and
## unconditionally: shown for as long as that link is live, checked before this neighbour's own
## project gets an opinion at all (`_live_links_targeting`). The link's own PROJECT OWNER shows
## nothing over themselves meanwhile - the ordinary "asked, not yet met" case below already covers it,
## since a live link's `_step_met` stays false until `_finish_link` runs.
func wants_marker(npc_id: String) -> int:
	if not CampaignData.gates_on():
		return -1
	if not _live_links_targeting(npc_id).is_empty():
		return 1
	var d := definition_for(npc_id)
	if d.is_empty():
		return -1
	var st := _state(npc_id)
	if st.is_empty():
		return 1
	if bool(st["done"]):
		return 1 if _part_lost(d) else -1
	var i := int(st["step"])
	if i >= (d["steps"] as Array).size():
		return 1
	if not step_unlocked(npc_id):
		return 0
	if not bool(st["asked"]):
		return 1
	return 1 if _step_met(npc_id, d, i) else 0


## One short line per active project for a journal: "Bolt: Find the broken machines (1/3)".
func summary() -> Array[String]:
	var out: Array[String] = []
	if not CampaignData.gates_on():
		return out
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		var st := _state(npc)
		if st.is_empty() or bool(st["done"]):
			continue
		var steps: Array = d["steps"]
		var i := int(st["step"])
		if i >= steps.size():
			out.append("%s: has your %s" % [_npc_name(npc), part_name(str(d["part"]))])
		elif not step_unlocked(npc):
			out.append("%s: come back tomorrow" % _npc_name(npc))
		elif not bool(st["asked"]):
			out.append("%s: has something to ask you" % _npc_name(npc))
		else:
			var pr := _progress(npc, d, i)
			out.append("%s: %s (%d/%d)" % [_npc_name(npc), _step_title(steps[i]), pr.x, pr.y])
	return out


## World positions of the live find step's markers for this neighbour (empty when none are shown on
## this planet). For a HUD pointer or a test probe.
func marker_positions(npc_id: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if _markers == null:
		return out
	for key: String in _markers.marker_ids():
		if key.begins_with(npc_id + ":"):
			out.append(_markers.marker_position(key))
	return out


## World ground point of the live place step's spot on this planet, or Vector3.INF.
func place_spot_position(npc_id: String) -> Vector3:
	var d := definition_for(npc_id)
	var st := _state(npc_id)
	if d.is_empty() or st.is_empty() or _planet == null:
		return Vector3.INF
	var i := int(st["step"])
	var steps: Array = d["steps"]
	if i >= steps.size() or str((steps[i] as Dictionary)["type"]) != "place":
		return Vector3.INF
	var step: Dictionary = steps[i]
	if _step_planet(npc_id, step) != GameState.current_planet_id:
		return Vector3.INF
	var spot := _spot_dir(npc_id, d, step, st)
	return Vector3.INF if spot == Vector3.ZERO else _planet.surface_point(spot)


# ============================================================================= conversation
## The contract conversation.gd is wired against. Returns TRUE whenever this neighbour has an active
## project - including "come back tomorrow" - so the favor branches are skipped; false when gates are
## off, the neighbour has no project, or it is finished. See the header for the one delivery case.
func handle_conversation(runner: DialogueRunner, npc: NPC, _player: Node3D) -> bool:
	if runner == null or npc == null or not CampaignData.gates_on():
		return false
	var npc_id := npc.npc_id
	var d := definition_for(npc_id)
	if d.is_empty():
		return false
	var st := _state(npc_id)
	if st.is_empty():
		_start(npc_id)
		await _say(runner, npc, d.get("intro", []))
	elif bool(st["done"]):
		if not _part_lost(d):
			return false
		await _regive_part(runner, npc, d)
		return _handled(npc_id)
	st = _state(npc_id)
	var steps: Array = d["steps"]
	var i := int(st["step"])
	if i >= steps.size():
		# Every step is done but the part was never handed over: the talk that finished the last
		# step was cut short after its commit. Hand it over now.
		await _hand_over_part(runner, npc, npc_id, d)
		return _handled(npc_id)
	if not step_unlocked(npc_id):
		var tomorrow: Array = _lines(steps[i - 1], "tomorrow") if i > 0 else []
		await _say(runner, npc, tomorrow if not tomorrow.is_empty() else DEFAULT_TOMORROW)
		return _handled(npc_id)
	var step: Dictionary = steps[i]
	if not bool(st["asked"]):
		var given := _ask(npc_id, d, i)
		var met := _step_met(npc_id, d, i)
		# A step that is not met yet ends on its status line ("(You have 5 of 12 scrap.)"), so the
		# player leaves the talk knowing the number, not only the request.
		await _say(runner, npc, _lines(step, "ask") + ([] if met else _status_lines(npc_id, d, i)))
		for item_id: String in given:
			AudioManager.play_sfx("pickup_item")
			EventBus.toast_requested.emit("You got %s!" % _count_name(item_id, int(given[item_id])), item_id)
		if met:
			await _complete(runner, npc, d, i)
	elif _step_met(npc_id, d, i):
		await _complete(runner, npc, d, i)
	else:
		await _say(runner, npc, _lines(step, "progress") + _status_lines(npc_id, d, i))
	return _handled(npc_id)


func _start(npc_id: String) -> void:
	GameState.projects[npc_id] = {"step": 0, "asked": false, "found": [], "markers": {}, "days": [],
		"done": false, "started_day": GameState.day_count}


## Commits "step i has been asked": hands over its "give" items and puts its markers / ring on the
## world. Returns the items given ({id: count}) so the talk can toast them after the lines.
func _ask(npc_id: String, d: Dictionary, i: int) -> Dictionary:
	var st := _state(npc_id)
	st["asked"] = true
	var step: Dictionary = (d["steps"] as Array)[i]
	var given: Dictionary = {}
	var give: Dictionary = step.get("give", {})
	for item_id: String in give:
		var n := int(give[item_id])
		if n > 0:
			GameState.add_item(item_id, n)
			given[item_id] = n
	_show_step_world(npc_id, d, i, st)
	_met_cache[npc_id] = _step_met(npc_id, d, i)
	return given


## Completes step i: state first (take items, record the day, advance), then the lines, then the
## part hand-over if it was the last step.
func _complete(runner: DialogueRunner, npc: NPC, d: Dictionary, i: int) -> void:
	var npc_id := npc.npc_id
	var st := _state(npc_id)
	var steps: Array = d["steps"]
	var step: Dictionary = steps[i]
	_take(step)
	(st["days"] as Array).append(GameState.day_count)
	st["step"] = i + 1
	st["asked"] = false
	GameState.project_step_day[npc_id] = GameState.day_count
	GameState.add_friendship(npc_id, int(step.get("friendship", FRIENDSHIP_PER_STEP)))
	_clear_step_world(npc_id, i)
	_met_cache.erase(npc_id)
	EventBus.project_step_completed.emit(npc_id, i)
	await _say(runner, npc, _lines(step, "done"))
	npc.play_emote("happy")
	AudioManager.play_sfx("friendship_up", -4.0)
	EventBus.toast_requested.emit("%s's project: %d of %d done" % [_npc_name(npc_id), i + 1, steps.size()],
		str(d["part"]))
	if i + 1 >= steps.size():
		await _hand_over_part(runner, npc, npc_id, d)


## `actor` speaks the "part_lines" and plays the happy emote; `owner_id` is whose project state
## advances. The normal (unlinked) flow always passes the same NPC for both (`handle_conversation`
## and `_complete`) - but a light link's LAST step hands the part over through whichever neighbour the
## player is actually talking to (`_finish_link`), while the state stays the project owner's.
func _hand_over_part(runner: DialogueRunner, actor: NPC, owner_id: String, d: Dictionary) -> void:
	var st := _state(owner_id)
	var part_id := str(d["part"])
	st["done"] = true
	st["step"] = (d["steps"] as Array).size()
	st["asked"] = false
	GameState.add_item(part_id)
	EventBus.project_completed.emit(owner_id, part_id)
	await _say(runner, actor, d.get("part_lines", []))
	actor.play_emote("happy")
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit("You got the %s!" % part_name(part_id), part_id)


## The bag's "Drop" button destroys an item (inventory.gd `_hook_action`), so a part dropped before
## it was fitted would end the campaign. The neighbour hands over another one instead.
func _regive_part(runner: DialogueRunner, npc: NPC, d: Dictionary) -> void:
	var part_id := str(d["part"])
	GameState.add_item(part_id)
	var again: Array = d.get("part_again", [])
	await _say(runner, npc, again if not again.is_empty() else DEFAULT_PART_AGAIN)
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit("You got the %s!" % part_name(part_id), part_id)


static func _part_lost(d: Dictionary) -> bool:
	var part_id := str(d["part"])
	return not GameState.rocket_parts.has(part_id) and not GameState.has_item(part_id)


## True, except in the one delivery case in the header.
func _handled(npc_id: String) -> bool:
	var favors := FavorSystem.get_or_create()
	if favors == null:
		return true
	var delivery := favors.delivery_for(npc_id)
	return delivery.is_empty() or not GameState.has_item(str(delivery.get("target_item", "")))


static func _say(runner: DialogueRunner, npc: NPC, lines: Array) -> void:
	if lines.is_empty():
		return
	await runner.say(npc, lines)


static func _lines(step: Dictionary, key: String) -> Array:
	var out: Array = []
	for l: Variant in (step.get("lines", {}) as Dictionary).get(key, []):
		out.append(str(l))
	return out


# ============================================================================= conversation: light links
## A LIGHT LINK: a "talk" step with an "npc" key sends the player to ANOTHER neighbour once, quick and
## empty-handed, for one short talk (CORE_LOOP "More mini-games, one per neighbour": Grig needs a seed
## pouch from Zorp, Vela needs a page from Fen's logbook). This section is the half of it that runs in
## the NAMED neighbour's own conversation, not the project's own neighbour's - see the STEP SCHEMA
## header's "talk" entry for the full shape.
##
## ORDER - the simplest one that satisfies "never swallows their own project, favour hand-in or gift"
## (the brief): `Conversation.run` calls `complete_live_link` UNCONDITIONALLY, before anything else -
## even a favour of theirs that is ready to hand in - so a live link always completes in this exact
## talk. `complete_live_link` only SAYS the link's lines and returns; it never tells `Conversation.run`
## the talk is "handled", so whatever that neighbour would otherwise have said (their own project step,
## a ready favour, a gift) still runs immediately after, in the SAME talk, exactly as if the link had
## not happened.

## Every live link that names `npc_id` as who finishes it: {"owner", "step", "def"} for each project
## whose current step is an asked, not-yet-linked "talk" step naming `npc_id`. Empty almost always -
## cheap to call on every talk and every marker poll (all_definitions() is a handful of dictionaries).
func _live_links_targeting(npc_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not CampaignData.gates_on():
		return out
	for d: Dictionary in all_definitions():
		var owner := str(d["npc"])
		var st := _state(owner)
		if st.is_empty() or bool(st["done"]) or not bool(st["asked"]):
			continue
		var steps: Array = d["steps"]
		var i := int(st["step"])
		if i >= steps.size():
			continue
		var step: Dictionary = steps[i]
		if str(step["type"]) != "talk" or str(step.get("npc", "")) != npc_id:
			continue
		out.append({"owner": owner, "step": i, "def": d})
	return out


## Called by conversation.gd on EVERY talk, with whoever the player is actually facing. Completes
## every live link that names them, in order, before that neighbour's own conversation branch runs.
## A no-op almost always (empty `_live_links_targeting`), so it costs nothing on an ordinary talk.
func complete_live_link(runner: DialogueRunner, npc: NPC) -> void:
	if runner == null or npc == null:
		return
	for link: Dictionary in _live_links_targeting(npc.npc_id):
		await _finish_link(runner, npc, str(link["owner"]), link["def"] as Dictionary, int(link["step"]))


## Completes link step `i` of `owner_id`'s project, spoken by `actor` (the NAMED neighbour physically
## in front of the player - `owner_id`'s own NPC is not even in this scene). State first, exactly like
## `_complete`: the step advances, the day is spent and "hand_over" items are in the bag BEFORE a
## single line is spoken, so a talk cut short never loses progress. "with" lines replace "done" (never
## spoken here - "done" is authored in the OWNER's voice); friendship and the day both still credit the
## OWNER, never `actor` (the brief's day rule: a link never spends the named neighbour's own day).
func _finish_link(runner: DialogueRunner, actor: NPC, owner_id: String, d: Dictionary, i: int) -> void:
	var st := _state(owner_id)
	var steps: Array = d["steps"]
	var step: Dictionary = steps[i]
	var found: Array = st["found"]
	var mark := _link_mark(i)
	if not found.has(mark):
		found.append(mark)
	(st["days"] as Array).append(GameState.day_count)
	st["step"] = i + 1
	st["asked"] = false
	GameState.project_step_day[owner_id] = GameState.day_count
	GameState.add_friendship(owner_id, int(step.get("friendship", FRIENDSHIP_PER_STEP)))
	var given: Dictionary = {}
	var hand_over: Dictionary = step.get("hand_over", {})
	for item_id: String in hand_over:
		var n := int(hand_over[item_id])
		if n > 0:
			GameState.add_item(item_id, n)
			given[item_id] = n
	_clear_step_world(owner_id, i)
	_met_cache.erase(owner_id)
	EventBus.project_step_completed.emit(owner_id, i)
	await _say(runner, actor, _lines(step, "with"))
	for item_id: String in given:
		AudioManager.play_sfx("pickup_item")
		EventBus.toast_requested.emit("You got %s!" % _count_name(item_id, int(given[item_id])), item_id)
	actor.play_emote("happy")
	AudioManager.play_sfx("friendship_up", -4.0)
	EventBus.toast_requested.emit("%s's project: %d of %d done" % [_npc_name(owner_id), i + 1, steps.size()],
		str(d["part"]))
	if i + 1 >= steps.size():
		await _hand_over_part(runner, actor, owner_id, d)


## The saved mark for a completed light-link step, in the same `found` array a find/minigame step's
## marks live in ("s<i>_m<n>" / "s<i>_g<n>") - so a link, once completed, needs no new save field and
## a save/reload mid-project can never re-ask it. Only ever read or written before the step advances
## past `i`, so it can never collide with a later step reusing the same index differently.
static func _link_mark(i: int) -> String:
	return "s%d_link" % i


# ============================================================================= step logic
static func _step_met(npc_id: String, d: Dictionary, i: int) -> bool:
	var step: Dictionary = (d["steps"] as Array)[i]
	if str(step["type"]) == "talk" and not step.has("npc"):
		return true
	var pr := _progress(npc_id, d, i)
	return pr.x >= pr.y


## (have, need) for step i.
static func _progress(npc_id: String, d: Dictionary, i: int) -> Vector2i:
	var step: Dictionary = (d["steps"] as Array)[i]
	var need := maxi(1, int(step.get("count", 1)))
	match str(step["type"]):
		"talk":
			if step.has("npc"):
				# A light link: met only once the NAMED neighbour's conversation has completed it
				# (`_finish_link`), never by this project's own neighbour asking or re-asking it.
				var st := _state(npc_id)
				return Vector2i(1, 1) if (st.get("found", []) as Array).has(_link_mark(i)) else Vector2i(0, 1)
			return Vector2i(1, 1)
		"find":
			var st := _state(npc_id)
			var n := 0
			for m in need:
				if (st.get("found", []) as Array).has("s%d_m%d" % [i, m]):
					n += 1
			return Vector2i(n, need)
		"collect", "build":
			return Vector2i(mini(_have(str(step["item"])), need), need)
		"place":
			return Vector2i(mini(_count_placed_near(npc_id, d, step), need), need)
		"minigame":
			# Same shape as "find": one saved mark per thing collected, so a half-played game needs
			# no new save field and survives a reload (see the MINIGAME block in the header).
			var mst := _state(npc_id)
			var gn := 0
			for m in need:
				if (mst.get("found", []) as Array).has(_minigame_mark(i, m)):
					gn += 1
			return Vector2i(gn, need)
	return Vector2i(0, need)


static func _have(item_id: String) -> int:
	# Scrap is a counter, not a bag item - GameState.item_count("scrap") is always 0 (lead, Phase 1).
	return GameState.scrap if item_id == SCRAP_ID else GameState.item_count(item_id)


## Items of the step's kind standing within "radius" metres (straight line) of the spot. On the
## step's planet this is the brief's check: DecorationManager.get_instances() and each node's
## global_position. Anywhere else it reads the saved positions (planet-local, GameState
## .placed_decorations) - same chord distance, so a neighbour visiting home in Phase 4 sees the
## same answer.
static func _count_placed_near(npc_id: String, d: Dictionary, step: Dictionary) -> int:
	var item := str(step["item"])
	var radius := float(step["radius"])
	var pid := _step_planet(npc_id, step)
	var st := _state(npc_id)
	var spot := _spot_dir(npc_id, d, step, st)
	if spot == Vector3.ZERO:
		return 0
	var n := 0
	var tree := Engine.get_main_loop() as SceneTree
	var planet: Planet = tree.get_first_node_in_group("planet") as Planet if tree != null else null
	var deco: DecorationManager = tree.root.get_node_or_null("World/Decorations") as DecorationManager if tree != null else null
	if pid == GameState.current_planet_id and planet != null and deco != null:
		var center := planet.surface_point(spot)
		for rec: Dictionary in deco.get_instances():
			if str(rec["item"]) != item:
				continue
			var node: Node3D = rec["node"]
			if is_instance_valid(node) and node.global_position.distance_to(center) <= radius:
				n += 1
		return n
	for e: Dictionary in GameState.placed_decorations.get(pid, []):
		if str(e.get("item", "")) != item:
			continue
		var pos := GameState.vec3_from_array(e.get("pos", [0.0, 0.0, 0.0]))
		if pos.distance_to(spot * pos.length()) <= radius:
			n += 1
	return n


static func _take(step: Dictionary) -> void:
	var t := str(step["type"])
	if (t != "collect" and t != "build") or not bool(step.get("take", true)):
		return
	var item := str(step["item"])
	var count := int(step["count"])
	if item == SCRAP_ID:
		GameState.spend_scrap(count)
	else:
		GameState.remove_item(item, count)


## The planet a find / place step happens on (default: the neighbour's own world).
static func _step_planet(npc_id: String, step: Dictionary) -> String:
	return str(step.get("planet", NpcData.get_data(npc_id).get("planet", "")))


## Planet-local unit direction of a place step's spot, or Vector3.ZERO when it cannot be resolved yet
## (a "marker:" spot whose find step never ran on this planet). Planets sit at the world origin with
## no rotation (DecorationManager and every placement path already rely on it), so a planet-local
## direction is also the world direction from the planet's centre.
static func _spot_dir(npc_id: String, _d: Dictionary, step: Dictionary, st: Dictionary) -> Vector3:
	var spot: Variant = step.get("spot", "npc")
	if spot is Vector3:
		return (spot as Vector3).normalized()
	if spot is Array:
		return _vec(spot as Array)
	var word := str(spot)
	if word == "npc":
		var hd: Variant = NpcData.get_data(npc_id).get("home_dir", Vector3.UP)
		return (hd as Vector3).normalized() if hd is Vector3 else Vector3.UP
	if word == "pad" or word == "spawn":
		var path := "res://src/planet/data/%s.tres" % _step_planet(npc_id, step)
		if not ResourceLoader.exists(path):
			return Vector3.ZERO
		var pd := load(path) as PlanetData
		return (pd.pad_dir if word == "pad" else pd.spawn_dir).normalized()
	if word.begins_with("marker:"):
		var markers: Dictionary = st.get("markers", {})
		var mid := word.substr(7)
		return _vec(markers[mid]) if markers.has(mid) else Vector3.ZERO
	return Vector3.ZERO


## "(2 of 3 found.)" and friends, spoken in the neighbour's box after their "progress" lines - the same
## shape as conversation.gd's favor progress summary.
static func _status_lines(npc_id: String, d: Dictionary, i: int) -> Array:
	var step: Dictionary = (d["steps"] as Array)[i]
	var pr := _progress(npc_id, d, i)
	match str(step["type"]):
		"find":
			return ["(%d of %d found.)" % [pr.x, pr.y]]
		"collect":
			return ["(You have %d of %d %s.)" % [pr.x, pr.y, _item_name(str(step["item"]), pr.y)]]
		"build":
			return ["(You have %d of %d %s.)" % [pr.x, pr.y, _item_name(str(step["item"]), pr.y)],
				"(The bench by your rocket builds it.)"]
		"place":
			return ["(%d of %d placed inside the ring.)" % [pr.x, pr.y]]
		"minigame":
			return ["(%d of %d so far.)" % [pr.x, pr.y], "(Use your jetpack - they fly high.)"]
	return []


static func _step_title(step: Dictionary) -> String:
	if step.has("title"):
		return str(step["title"])
	var n := int(step.get("count", 1))
	match str(step["type"]):
		"find":
			var label := str(step.get("marker_label", "marker"))
			return "Find %d %s" % [n, label + "s" if n != 1 and not label.ends_with("s") else label]
		"collect":
			return "Bring %s" % _count_name(str(step["item"]), n)
		"build":
			return "Build %s" % _count_name(str(step["item"]), n)
		"place":
			return "Place %s" % _count_name(str(step["item"]), n)
		"minigame":
			# The game's own noun when the definition gave one, so the journal reads "Get all 5
			# bolts" rather than naming the machinery. Writers should just set "title".
			var noun := str((step.get("config", {}) as Dictionary).get("label_plural", ""))
			if noun == "":
				return "Play %s" % str(step.get("game", "")).capitalize()
			return "Get all %d %s" % [n, noun]
	return "Talk"


# ============================================================================= world: markers and rings
func _on_planet_loaded(_planet_id: String) -> void:
	_queue_refresh()


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh_world.call_deferred()


## Redraws every live find marker and place ring that belongs on the current planet.
func _refresh_world() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	# Mini-games first: this cancels one whose step is no longer live here, and it deliberately runs
	# BEFORE the loop below, which restarts (or keeps) the one that still is. `_sync_minigames`
	# computes the same live set the loop does, so a game that should still be running is never
	# stopped and respawned under the player.
	_sync_minigames()
	_planet = get_tree().get_first_node_in_group("planet") as Planet
	_markers.clear_markers()
	_markers.clear_zones()
	if _planet == null:
		return
	_markers.setup(_planet)
	if not CampaignData.gates_on():
		return
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		var st := _state(npc)
		if st.is_empty() or bool(st["done"]) or not bool(st["asked"]):
			continue
		var i := int(st["step"])
		if i >= (d["steps"] as Array).size():
			continue
		_show_step_world(npc, d, i, st)
		_met_cache[npc] = _step_met(npc, d, i)


func _show_step_world(npc_id: String, d: Dictionary, i: int, st: Dictionary) -> void:
	if _planet == null or _markers == null:
		return
	var step: Dictionary = (d["steps"] as Array)[i]
	if _step_planet(npc_id, step) != GameState.current_planet_id:
		return
	match str(step["type"]):
		"find":
			var found: Array = st["found"]
			for mid: String in _ensure_marker_dirs(npc_id, step, i, st):
				_markers.show_marker("%s:%s" % [npc_id, mid], _vec(st["markers"][mid]), found.has(mid))
		"place":
			var spot := _spot_dir(npc_id, d, step, st)
			if spot != Vector3.ZERO:
				_markers.show_zone("%s:s%d_zone" % [npc_id, i], spot, float(step["radius"]),
					_step_met(npc_id, d, i))
		"minigame":
			_start_minigame(npc_id, d, i)


func _clear_step_world(npc_id: String, i: int) -> void:
	var ms := MinigameSystem.find()
	if ms != null:
		ms.stop_owner(_minigame_owner(npc_id, i), "step completed")
	if _markers == null:
		return
	var prefix := "%s:s%d_" % [npc_id, i]
	_markers.clear_markers(prefix)
	_markers.clear_zones(prefix)


## The ids of step i's markers, choosing and saving their directions the first time (they must be on
## the step's planet for that, which `_show_step_world` guarantees).
func _ensure_marker_dirs(npc_id: String, step: Dictionary, i: int, st: Dictionary) -> Array[String]:
	var count := int(step["count"])
	var ids: Array[String] = []
	var markers: Dictionary = st["markers"]
	var missing := false
	for n in count:
		var mid := "s%d_m%d" % [i, n]
		ids.append(mid)
		if not markers.has(mid):
			missing = true
	if missing:
		var dirs: Array[Vector3] = []
		if step.has("dirs"):
			for v: Variant in step["dirs"]:
				dirs.append((v as Vector3).normalized() if v is Vector3 else _vec(v as Array))
		else:
			dirs = _pick_marker_dirs(npc_id, i, count)
		for n in count:
			var mid := ids[n]
			if not markers.has(mid):
				var v := dirs[n]
				markers[mid] = [v.x, v.y, v.z]
	return ids


## Spreads `count` markers over the planet: free, level ground (Planet.find_free_dir), clear of every
## reserved zone by MARKER_RESERVED_GAP_M more than decorations need, then chosen by farthest-point
## sampling from the landing pad and spawn - so "find them all" means walking the planet, not
## turning on the spot. Seeded by npc, step and planet, so the same save always gets the same spots
## (they are saved anyway once chosen).
func _pick_marker_dirs(npc_id: String, i: int, count: int) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([npc_id, i, _planet.data.id, _planet.data.seed])
	var deco := get_tree().root.get_node_or_null("World/Decorations") as DecorationManager
	var reserved := _planet.get_reserved_dirs()
	var keep_off := DecorationManager.RESERVED_CLEARANCE + MARKER_RESERVED_GAP_M
	var candidates: Array[Vector3] = []
	for _attempt in MARKER_TRIES:
		if candidates.size() >= MARKER_CANDIDATES:
			break
		var v := _planet.find_free_dir(rng, MARKER_CLEARANCE_M, 8, false)
		if v == Vector3.ZERO:
			continue
		var ok := true
		for r: Vector3 in reserved:
			if _planet.surface_distance(v, r) < keep_off:
				ok = false
				break
		if ok and deco != null and deco.ground_block_reason(v, MARKER_CLEARANCE_M) != "":
			ok = false
		if ok:
			candidates.append(v)
	var seeds: Array[Vector3] = [_planet.data.spawn_dir.normalized(), _planet.data.pad_dir.normalized()]
	var chosen: Array[Vector3] = []
	while chosen.size() < count:
		var best := Vector3.ZERO
		var best_d := -1.0
		for c: Vector3 in candidates:
			if chosen.has(c):
				continue
			var dmin := INF
			for s: Vector3 in seeds + chosen:
				dmin = minf(dmin, _planet.surface_distance(c, s))
			if dmin > best_d:
				best_d = dmin
				best = c
		if best == Vector3.ZERO:
			# Not enough good ground: a find step must still be finishable, so take any free spot.
			best = _planet.find_free_dir(rng, MARKER_CLEARANCE_M, 64, true)
			if best == Vector3.ZERO:
				best = _planet.random_surface_dir(rng, seeds + chosen, 20.0)
			push_warning("ProjectSystem: %s step %d marker %d fell back to rough ground" % [npc_id, i, chosen.size()])
		chosen.append(best)
	return chosen


func _on_marker_visited(key: String) -> void:
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return
	var npc_id := parts[0]
	var mid := parts[1]
	var d := definition_for(npc_id)
	var st := _state(npc_id)
	if d.is_empty() or st.is_empty() or bool(st["done"]):
		return
	var found: Array = st["found"]
	if not found.has(mid):
		found.append(mid)
	var i := int(st["step"])
	if i >= (d["steps"] as Array).size():
		return
	var step: Dictionary = (d["steps"] as Array)[i]
	var pr := _progress(npc_id, d, i)
	var label := str(step.get("marker_label", "marker"))
	if pr.x >= pr.y:
		EventBus.toast_requested.emit("All %d found! Go and tell %s." % [pr.y, _npc_name(npc_id)], "")
	else:
		EventBus.toast_requested.emit("Found %s %s (%d/%d)" % [_article(label), label, pr.x, pr.y], "")


## Items, scrap or decorations changed: re-check every live collect / build / place step, recolour
## place rings, and toast once when a step becomes ready to hand in.
func _on_progress_signal() -> void:
	if not CampaignData.gates_on():
		return
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		var st := _state(npc)
		if st.is_empty() or bool(st["done"]) or not bool(st["asked"]):
			continue
		var i := int(st["step"])
		var steps: Array = d["steps"]
		if i >= steps.size():
			continue
		var t := str((steps[i] as Dictionary)["type"])
		# "minigame" joins talk and find here: nothing an item or a decoration does can move it, and
		# its own "ready" toast is fired by `_on_minigame_finished`.
		if t == "talk" or t == "find" or t == "minigame":
			continue
		var met := _step_met(npc, d, i)
		if t == "place" and _markers != null:
			_markers.set_zone_met("%s:s%d_zone" % [npc, i], met)
		var was: bool = bool(_met_cache.get(npc, met))
		_met_cache[npc] = met
		if met and not was:
			EventBus.toast_requested.emit("Ready! Go and tell %s." % _npc_name(npc), "")


# ============================================================================= world: mini-games
## A "minigame" step (see the MINIGAME block in the header). This system is the HOST: it starts the
## game, saves what the game reports, and cancels it when the step is no longer live. It never
## touches the game's insides, and the game knows nothing about projects - all of it goes through
## MinigameSystem's public contract.
##
## The owner string "project:<npc>:<step>" is how a running game is matched back to the step that
## started it, and its "project:" prefix is what keeps `sync_owners` off a game the dev menu started.
static func _minigame_owner(npc_id: String, i: int) -> String:
	return "%s%s:%d" % [MINIGAME_OWNER_PREFIX, npc_id, i]


## The saved mark for the n-th thing collected in step i. Deliberately "g", so it can never collide
## with a find step's "s<i>_m<n>" markers in the same `found` array.
static func _minigame_mark(i: int, n: int) -> String:
	return "s%d_g%d" % [i, n]


## ["bolt", 1] from "project:bolt:1", or [] when the owner is not one of ours.
static func _owner_parts(owner_id: String) -> Array:
	if not owner_id.begins_with(MINIGAME_OWNER_PREFIX):
		return []
	var rest := owner_id.substr(MINIGAME_OWNER_PREFIX.length())
	var cut := rest.rfind(":")
	if cut <= 0:
		return []
	return [rest.substr(0, cut), int(rest.substr(cut + 1))]


## The world's MinigameSystem with this system listening to it. Connected here rather than in
## `_ready` so a world with no mini-game step live never grows the node at all.
func _minigames() -> MinigameSystem:
	var ms := MinigameSystem.get_or_create()
	if ms == null:
		return null
	if not ms.progress_changed.is_connected(_on_minigame_progress):
		ms.progress_changed.connect(_on_minigame_progress)
	if not ms.finished.is_connected(_on_minigame_finished):
		ms.finished.connect(_on_minigame_finished)
	return ms


## Starts (or keeps) step i's game. `MinigameSystem.start` is a no-op when the same owner is already
## running, so this is safe to call on every refresh.
func _start_minigame(npc_id: String, d: Dictionary, i: int) -> void:
	if _step_met(npc_id, d, i):
		return
	var ms := _minigames()
	if ms == null:
		return
	var step: Dictionary = (d["steps"] as Array)[i]
	var cfg: Dictionary = (step.get("config", {}) as Dictionary).duplicate(true)
	cfg["owner"] = _minigame_owner(npc_id, i)
	cfg["npc"] = npc_id
	cfg["count"] = maxi(1, int(step.get("count", 1)))
	cfg["done"] = _progress(npc_id, d, i).x
	ms.start(str(step.get("game", "")), cfg)


## Cancels a project-owned game that is not a live step on THIS planet any more - the step was
## completed, the gates went off, the save was reloaded, or the player flew away. Never creates the
## MinigameSystem, so a world without one stays without one.
func _sync_minigames() -> void:
	var ms := MinigameSystem.find()
	if ms == null:
		return
	var live := PackedStringArray()
	if CampaignData.gates_on():
		for d: Dictionary in all_definitions():
			var npc := str(d["npc"])
			var st := _state(npc)
			if st.is_empty() or bool(st["done"]) or not bool(st["asked"]):
				continue
			var i := int(st["step"])
			var steps: Array = d["steps"]
			if i >= steps.size():
				continue
			var step: Dictionary = steps[i]
			if str(step["type"]) != "minigame" or _step_planet(npc, step) != GameState.current_planet_id:
				continue
			if _step_met(npc, d, i):
				continue
			live.append(_minigame_owner(npc, i))
	ms.sync_owners(MINIGAME_OWNER_PREFIX, live)


## The game collected one more. Written to `found` straight away - this is the ONLY thing that makes
## a half-played game survive a save or a flight, and it must not wait for the finish signal.
func _on_minigame_progress(_kind: String, done: int, total: int) -> void:
	var ms := MinigameSystem.find()
	if ms == null:
		return
	var parts := _owner_parts(ms.running_owner())
	if parts.is_empty():
		return
	var npc_id: String = parts[0]
	var i: int = parts[1]
	var d := definition_for(npc_id)
	var st := _state(npc_id)
	if d.is_empty() or st.is_empty() or bool(st["done"]) or int(st["step"]) != i:
		return
	var found: Array = st["found"]
	for n in total:
		var mid := _minigame_mark(i, n)
		var want := n < done
		if want and not found.has(mid):
			found.append(mid)
		elif not want and found.has(mid):
			found.erase(mid)
	_met_cache[npc_id] = _step_met(npc_id, d, i)


## The game reports it is over. Success only: a cancel is not a failure and changes nothing.
func _on_minigame_finished(_kind: String, success: bool, config: Dictionary) -> void:
	if not success:
		return
	var parts := _owner_parts(str(config.get("owner", "")))
	if parts.is_empty():
		return
	var npc_id: String = parts[0]
	var i: int = parts[1]
	var d := definition_for(npc_id)
	var st := _state(npc_id)
	if d.is_empty() or st.is_empty() or bool(st["done"]) or int(st["step"]) != i:
		return
	# Belt and braces. Every mark is normally already written by `_on_minigame_progress`; this makes
	# "the game says it is finished" and "the step is met" the same thing even if a game reports a
	# finish without a final progress call.
	var need := maxi(1, int(((d["steps"] as Array)[i] as Dictionary).get("count", 1)))
	var found: Array = st["found"]
	for n in need:
		var mid := _minigame_mark(i, n)
		if not found.has(mid):
			found.append(mid)
	_met_cache[npc_id] = true
	EventBus.toast_requested.emit("That's all of them! Go and tell %s." % _npc_name(npc_id), "")


# ============================================================================= state
## The live, normalised state dictionary for a neighbour (edits persist), or {} when not started.
## JSON gives floats back for every int, and GameState.from_dict stores `projects` as it comes.
static func _state(npc_id: String) -> Dictionary:
	var raw: Variant = GameState.projects.get(npc_id)
	if not (raw is Dictionary):
		return {}
	var st: Dictionary = raw
	st["step"] = int(st.get("step", 0))
	st["asked"] = bool(st.get("asked", false))
	st["done"] = bool(st.get("done", false))
	st["started_day"] = int(st.get("started_day", GameState.day_count))
	var found: Array = []
	for f: Variant in st.get("found", []):
		found.append(str(f))
	st["found"] = found
	var days: Array = []
	for x: Variant in st.get("days", []):
		days.append(int(x))
	st["days"] = days
	var markers: Dictionary = {}
	var raw_markers: Variant = st.get("markers", {})
	if raw_markers is Dictionary:
		for k: Variant in raw_markers:
			var v: Variant = (raw_markers as Dictionary)[k]
			if v is Array and (v as Array).size() == 3:
				markers[str(k)] = [float(v[0]), float(v[1]), float(v[2])]
	st["markers"] = markers
	return st


# ============================================================================= helpers
static func _vec(a: Array) -> Vector3:
	if a.size() != 3:
		return Vector3.ZERO
	return Vector3(float(a[0]), float(a[1]), float(a[2])).normalized()


static func _npc_name(npc_id: String) -> String:
	return str(NpcData.get_data(npc_id).get("display_name", npc_id.capitalize()))


## "3 Gear Bits" / "1 Yard Fixer" / "10 scrap".
static func _count_name(item_id: String, count: int) -> String:
	return "%d %s" % [count, _item_name(item_id, count)]


static func _item_name(item_id: String, count: int) -> String:
	if item_id == SCRAP_ID:
		return "scrap"
	var base := str(Catalog.get_item(item_id).get("name", item_id.capitalize()))
	if count != 1 and not base.ends_with("s"):
		return base + "s"
	return base


static func _article(word: String) -> String:
	return "an" if word != "" and "aeiou".contains(word.substr(0, 1).to_lower()) else "a"


# ============================================================================= QA helpers
## One line per project: what a critic or a Director timeline needs to see. Prints only.
##   {"t": 5, "call": {"node": "/root/World/ProjectSystem", "method": "debug_report", "args": ["after"]}}
func debug_report(tag: String = "") -> void:
	print("PROJECTS %s day=%d gates=%s planet=%s scrap=%d" % [tag, GameState.day_count, CampaignData.gates_on(),
		GameState.current_planet_id, GameState.scrap])
	for d: Dictionary in all_definitions():
		var npc := str(d["npc"])
		var st := _state(npc)
		var i := int(st.get("step", 0))
		var steps: Array = d["steps"]
		var live := "-"
		if not st.is_empty() and i < steps.size():
			var pr := _progress(npc, d, i)
			var step: Dictionary = steps[i] as Dictionary
			live = "%s %d/%d met=%s" % [str(step["type"]), pr.x, pr.y, _step_met(npc, d, i)]
			if str(step["type"]) == "talk" and step.has("npc"):
				live += " link_to=%s" % str(step["npc"])
		print("  %s state=%s live=[%s] unlocked=%s step_day=%s friendship=%d part_in_bag=%d fitted=%s markers_shown=%d marker=%d" % [
			npc, JSON.stringify(st), live, step_unlocked(npc), str(GameState.project_step_day.get(npc, "-")),
			int(GameState.npc_data(npc).get("friendship", 0)), GameState.item_count(str(d["part"])),
			GameState.rocket_parts.has(str(d["part"])), marker_positions(npc).size(), wants_marker(npc)])


## wants_marker() for any npc id, even one with no project of their own - a light link's TARGET,
## typically, which `debug_report` above never prints because its loop is over project OWNERS only.
## Prints only.
func debug_marker(npc_id: String) -> void:
	print("MARKER %s wants_marker=%d live_links=%s" % [npc_id, wants_marker(npc_id), JSON.stringify(_live_links_targeting(npc_id))])


## played_minigames(), printed - for a critic checking exactly when a game unlocks for the Commons
## replay board. Prints only.
func debug_played_minigames() -> void:
	print("PLAYED_MINIGAMES %s" % JSON.stringify(played_minigames()))


## How much of each place step's ring is legal to decorate, measured with the real placement rules
## (DecorationManager.spot_block_reason) on a grid inside the ring. For choosing a "spot" and a
## "radius" that a player can actually satisfy. Must run on the step's planet. Prints only.
func debug_spot_report(npc_id: String) -> void:
	var d := definition_for(npc_id)
	var deco := get_tree().root.get_node_or_null("World/Decorations") as DecorationManager
	if d.is_empty() or _planet == null or deco == null:
		print("SPOT %s: no definition, planet or DecorationManager" % npc_id)
		return
	deco.refresh_rule_caches()
	var st := _state(npc_id)
	var steps: Array = d["steps"]
	for i in steps.size():
		var step: Dictionary = steps[i]
		if str(step["type"]) != "place":
			continue
		if _step_planet(npc_id, step) != GameState.current_planet_id:
			print("SPOT %s step %d: on planet '%s', not here" % [npc_id, i, _step_planet(npc_id, step)])
			continue
		var spot := _spot_dir(npc_id, d, step, st)
		if spot == Vector3.ZERO:
			print("SPOT %s step %d: spot %s not resolvable yet" % [npc_id, i, str(step.get("spot"))])
			continue
		var radius := float(step["radius"])
		var fp := DecorationManager.footprint_for(str(step["item"]))
		var center := _planet.surface_point(spot)
		var xf := _planet.surface_transform(spot)
		var reasons: Dictionary = {}
		var total := 0
		var free := 0
		var nearest_free := INF
		var steps_r := int(ceil(radius / SPOT_SAMPLE_STEP_M))
		for ix in range(-steps_r, steps_r + 1):
			for iz in range(-steps_r, steps_r + 1):
				var off := Vector2(ix, iz) * SPOT_SAMPLE_STEP_M
				if off.length() > radius:
					continue
				var dd := (spot + (xf.basis.x * off.x + xf.basis.z * off.y) / _planet.radius).normalized()
				if _planet.surface_point(dd).distance_to(center) > radius:
					continue
				total += 1
				var why := deco.spot_block_reason(dd, fp)
				if why == "":
					free += 1
					nearest_free = minf(nearest_free, off.length())
				else:
					reasons[why] = int(reasons.get(why, 0)) + 1
		print("SPOT %s step %d item=%s spot=%s radius=%.2f footprint=%.2f samples=%d placeable=%.1f%% nearest_free=%.2fm blocked=%s" % [
			npc_id, i, step["item"], str(step.get("spot")), radius, fp, total,
			100.0 * float(free) / float(maxi(total, 1)), nearest_free, JSON.stringify(reasons)])
