class_name NormRewards
extends RefCounted
## Norm's reward ladder (NORM_SPEC.md §6): bronze, silver, gold, then a statue of himself forever
## after. Owns the four item definitions and the grant flow; NSYS calls `grant()` when a quiz is won.
##
##   NormRewards.ensure_items_registered()          # idempotent, safe to call every world load
##   var id := NormRewards.next_reward_id()          # "norm_trophy_bronze" | ... | "norm_statue"
##   var id2 := await NormRewards.grant(runner, npc) # gives it, says the line, toasts, bumps counters
##
## REWARD-POOL LEAK (NORM_SPEC §6, api_map.json risk #1): every def here carries `"source": "norm"`.
## `Catalog.random_reward_decoration` (src/autoload/catalog.gd) filters that field out — the one
## additive line this builder owns there — so these four never enter the ordinary favour-reward
## draw, the same way project items are kept out by their own `"project"` field. Price 0 already
## keeps them out of `Catalog.store_items` (which filters `price > 0`), so no separate flag is
## needed for that half.

## Ladder order by `GameState.flags["norm_wins"]` (0-indexed); index 3+ (gold done) is the statue,
## forever, per NORM_SPEC "then `norm_statue` every time, with no limit".
const REWARD_LADDER: Array[String] = [
	"norm_trophy_bronze",
	"norm_trophy_silver",
	"norm_trophy_gold",
	"norm_statue",
]

const SCENE_DIR := "res://src/decorations/items/"

## Registered verbatim via Catalog.register(); `duplicate(true)` before handing one out so nothing
## downstream can mutate the shared const dictionary.
const ITEM_DEFS := {
	"norm_trophy_bronze": {
		"id": "norm_trophy_bronze", "name": "Bronze Human Award", "kind": "decoration",
		"category": "fun", "rarity": "common", "price": 0, "source": "norm",
		"desc": "Awarded for excellent human-ness. Bronze tier, but he means it.",
		"scene": "res://src/decorations/items/norm_trophy_bronze.tscn",
		"footprint": 0.4, "icon_color": "#c08a5c",
	},
	"norm_trophy_silver": {
		"id": "norm_trophy_silver", "name": "Silver Human Award", "kind": "decoration",
		"category": "fun", "rarity": "uncommon", "price": 0, "source": "norm",
		"desc": "Awarded for excellent human-ness. Silver tier. Very human of you.",
		"scene": "res://src/decorations/items/norm_trophy_silver.tscn",
		"footprint": 0.42, "icon_color": "#c7ced9",
	},
	"norm_trophy_gold": {
		"id": "norm_trophy_gold", "name": "Gold Human Award", "kind": "decoration",
		"category": "fun", "rarity": "rare", "price": 0, "source": "norm",
		"desc": "Awarded for excellent human-ness. Gold tier. The highest tier a human can get.",
		"scene": "res://src/decorations/items/norm_trophy_gold.tscn",
		"footprint": 0.44, "icon_color": "#d9c581",
	},
	"norm_statue": {
		"id": "norm_statue", "name": "Statue of Norm", "kind": "decoration",
		"category": "fun", "rarity": "legendary", "price": 0, "source": "norm",
		"desc": "A carved likeness of a normal human. He gave you another one. He will give you more.",
		"scene": "res://src/decorations/items/norm_statue.tscn",
		"footprint": 0.55, "icon_color": "#9a968f",
	},
}

## Loaded by path at runtime, not `preload`d (NQUIZ owns it; this builder's contract is to keep
## working even mid-build, before it lands — `ResourceLoader.exists` first, see `_reward_line`).
## Its public API (NORM_SPEC §9, confirmed against the delivered file): `static func
## reward_line(item_id: String) -> String`, keyed by these same four ids, never empty.
const NORM_LINES_PATH := "res://src/campaign/norm_lines.gd"

## Used only if norm_lines.gd is missing or its `reward_line()` call fails for any reason, so
## `grant()` still says something in Norm's voice rather than an empty box.
const _FALLBACK_LINES := {
	"norm_trophy_bronze": "A bronze trophy. I found it. Human customs demand I give it to you now.",
	"norm_trophy_silver": "Silver this time. You are doing human things correctly.",
	"norm_trophy_gold": "Gold. The highest tier a human can get. I am proud, in the human way.",
	"norm_statue": "I had no more trophies, so I made this. It is me. Please display it prominently.",
}

static var _registered := false


## Registers the four reward items with Catalog, idempotently. Anyone who needs the items may call
## it (mirrors ProjectSystem.ensure_items_registered's contract); cheap once already done.
static func ensure_items_registered() -> void:
	if _registered and Catalog.has_item("norm_statue"):
		return
	for id: String in ITEM_DEFS:
		if not Catalog.has_item(id):
			Catalog.register((ITEM_DEFS[id] as Dictionary).duplicate(true))
	_registered = true


## Next reward for the current `norm_wins` count. Clamped, so win 3, 4, 5... all give the statue.
static func next_reward_id() -> String:
	var wins := int(GameState.flags.get("norm_wins", 0))
	var idx := clampi(wins, 0, REWARD_LADDER.size() - 1)
	return REWARD_LADDER[idx]


## Gives the next reward: registers items if needed, adds it to the bag, says the reward line
## through `runner` (skipped if `runner` is null — used by dev-menu callers that don't have one),
## toasts "You got: <name>", and bumps `norm_wins` (always) and `norm_statues` (only for the statue).
## Returns the item id granted. Awaitable; callers use `await NormRewards.grant(...)`.
static func grant(runner: DialogueRunner, npc: Node3D) -> String:
	ensure_items_registered()
	var id := next_reward_id()
	var def := Catalog.get_item(id)
	GameState.add_item(id, 1)
	GameState.flags["norm_wins"] = int(GameState.flags.get("norm_wins", 0)) + 1
	if id == "norm_statue":
		GameState.flags["norm_statues"] = int(GameState.flags.get("norm_statues", 0)) + 1
	var line := _reward_line(id)
	if runner != null and npc != null and line != "":
		await runner.say(npc, [line])
	var display := str(def.get("name", id))
	EventBus.toast_requested.emit("You got: %s" % display, "gift")
	return id


## `NormLines.reward_line(id)` (NQUIZ, norm_lines.gd), loaded by path so a missing file never breaks
## the build. Falls back to `_FALLBACK_LINES` if the file isn't there or the call fails, so `grant()`
## never says nothing.
static func _reward_line(id: String) -> String:
	if ResourceLoader.exists(NORM_LINES_PATH):
		var script: Variant = load(NORM_LINES_PATH)
		if script is GDScript and (script as GDScript).has_method("reward_line"):
			var line: Variant = (script as GDScript).call("reward_line", id)
			if line is String and not (line as String).is_empty():
				return line
	return str(_FALLBACK_LINES.get(id, ""))
