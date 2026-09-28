class_name SafariHeard
extends RefCounted
## WIRE round (2026-09-21, scratch only). WHICH HINTS THIS PLAYER HAS ACTUALLY HEARD, keyed by
## SafariCatalog sight id, and the one line a neighbour says back when you bring the photo home.
##
## WHY THIS FILE EXISTS. The merged build had TWO hint systems that did not know about each other:
##
##   sky_hints.gd    5 hints, its own ids ("hint_bolt_moon"), its own subjects, its own routes and
##                   hour windows, a heard set persisted in GameState.flags, a journal
##                   "heard about, not seen" page, and a catch reaction. It is what
##                   conversation.gd already calls, so it is the MOUTH that works.
##   safari_catalog  10 hinted sights ("green_moon", "shy_one", ...) with `needs_hint`,
##                   `hint_npc` and `hint_line` on the sight itself, gated by
##                   SafariCatalog.passes() against ctx["hints"]. It is the CONTENT that is real.
##
## Four of sky_hints' five hints are the same THING as a catalog sight written twice - its green
## moon and the catalog's `green_moon` share a word-for-word line - and the catalog's other six
## hinted rares had no mouth at all. So: the catalog is the content, sky_hints stays the mouth,
## and this file is the seam. It owns the heard set in the catalog's vocabulary, so
## `SafariLanes.draw_cast(..., {"heard": SafariHeard.heard_ids()})` is the whole gate.
##
## WHAT IS AUTHORED HERE, said out loud: the ten CATCH_LINES below. The catalog gives every hinted
## sight a neighbour and a hint line but no reaction, and a reaction is what makes catching one
## mean something to the neighbour who told you. They are written to the project's 60-character
## player-words budget and `lines_ok()` measures them rather than trusting them.
##
## SAY WHAT IS SYNTHETIC: the heard set here has never been filled by a real conversation on a
## phone. Every proof in this round's report drives it through `SkyHints.maybe_hint_line`, which is
## the same function conversation.gd calls, but from code.

## Player words. Same budget as SkyHints.LINE_MAX; repeated here so this file measures itself.
const LINE_MAX := 60

## GameState.flags keys. Flags are in `to_dict()`, so both survive a save and a reload.
const F_HEARD := "safari_heard"
const F_THANKED := "safari_thanked"


## THE REACTION. One line per hinted catalog sight, in that sight's own neighbour's voice, said
## once, the first time you talk to them after the photo is in the journal.
const CATCH_LINES := {
	"green_moon": "The green moon. You found it. I am logging that.",
	"the_returner": "It came back, then. My book was right. Good.",
	"long_sleeper": "You photographed it asleep. Do not wake it.",
	"green_flash": "The green flash! Nobody believed me. Nobody.",
	"orbit_laundry": "That is my customer's washing. Keep the photo.",
	"shy_one": "IT IS REAL! Years! YEARS I looked for that!",
	"ice_guest": "Somebody is in there. I said so. Thank you.",
	"star_in_a_pool": "The whole sun in one pool. That is the one.",
	"der_anvil": "I asked you not to. It does look well, though.",
	"barnacle_calf": "A calf, let go and drifting. Lovely record.",
}


# ------------------------------------------------------------------ the heard set
static func _dict(key: String) -> Dictionary:
	var v: Variant = GameState.flags.get(key, {})
	return v if v is Dictionary else {}


## Every catalog sight id whose hint this player has heard. This is exactly what
## SafariLanes.make_ctx wants for `heard`, and it is the only gate on a hinted rare.
static func heard_ids() -> Array:
	return _dict(F_HEARD).keys()


static func is_heard(sight_id: String) -> bool:
	return _dict(F_HEARD).has(sight_id)


## Idempotent. Records the day it was heard (for the journal page) and adds the journal's
## "heard about, not seen" page, the same page sky_hints.gd has always made for its own five.
static func mark_heard(sight_id: String) -> void:
	var e := SafariCatalog.by_id(sight_id)
	if e.is_empty() or not bool(e.get("needs_hint", false)):
		return
	var d := _dict(F_HEARD)
	if d.has(sight_id):
		return
	d[sight_id] = GameState.day_count
	GameState.flags[F_HEARD] = d
	var journal := _find_journal()
	if journal != null and journal.has_method("register_hint"):
		journal.call("register_hint", journal_subject(e), {
			"npc_id": str(e.get("hint_npc", "")),
			"line": str(e.get("hint_line", "")),
			"day": GameState.day_count,
		})


## The journal's own page shape for a catalog sight. ONE definition, used by the "heard about, not
## seen" page above and by safari_haul.gd when the photo lands, so a heard page and a caught page
## are the same page and the catch fills it instead of opening a second one.
##
## BOOK round (2026-09-21): three fields added, and all three are things the catalog had already
## written that no player could read anywhere.
##   kind_label   the catalog's own word for what it is ("Creature", "Wreck", "Ice"). The page used
##                to print SkyEvents.kind_name(kind), which only knows Aurora/Comet/Ringed pass, so
##                every creature in the book was labelled "Aurora".
##   silhouette   the line the catalog wrote for an UNCAUGHT page ("Five round shapes, keeping pace
##                with something."). All 51 existed and nothing in the game ever showed one.
##   draw         the catalog's shape id, so a page can ask for the same six shapes the glass draws.
static func journal_subject(e: Dictionary, world_id: String = "", where_line: String = "") -> Dictionary:
	return {
		"id": str(e.get("id", "")),
		"title": str(e.get("name", "A sight")),
		"kind": page_kind(e),
		"kind_label": SafariCatalog.kind_name(str(e.get("kind", "creature"))),
		"draw": str(e.get("draw", "pod")),
		"rarity": int(e.get("rarity", 1)),
		"world": world_id,
		"where": where_line if where_line != "" else "out between the worlds",
		"blurb": str(e.get("blurb", "")),
		"silhouette": str(e.get("silhouette", "")),
		"tint_a": str(e.get("tint_a", "#ffffff")),
		"tint_b": str(e.get("tint_b", "#ffffff")),
	}


## SafariCatalog draw-shape -> the journal's PageArt kind. Two alphabets that both start at 0 (see
## safari_haul.gd's header); the shapes PageArt cannot draw fall to a number it does not match,
## which draws the plain tinted disc rather than the WRONG silhouette.
const PAGE_KIND := {
	"comet": SkyEvents.KIND_COMET,
	"ice": SkyEvents.KIND_RING,
	"moonrim": SkyEvents.KIND_RING,
	"limb": SkyEvents.KIND_AURORA,
}


static func page_kind(e: Dictionary) -> int:
	var draw := str(e.get("draw", "pod"))
	return int(PAGE_KIND.get(draw, 90 + int(SafariCatalog.DRAW.get(draw, 1))))


# ------------------------------------------------------------------ the neighbour's mouth
## Has this sight been photographed? The journal is the record, so a reload that keeps the journal
## keeps the reaction correct too.
static func is_caught(sight_id: String) -> bool:
	var journal := _find_journal()
	if journal == null or not journal.has_method("has_shot"):
		return false
	return bool(journal.call("has_shot", sight_id))


## Every hinted catalog sight this npc is the voice of. A neighbour can have more than one.
static func sights_of(npc_id: String) -> Array:
	var out: Array = []
	for e in SafariCatalog.all():
		if bool(e.get("needs_hint", false)) and str(e.get("hint_npc", "")) == npc_id:
			out.append(e)
	return out


## THE ONE LINE THIS NPC SAYS THIS TALK, or "". Reaction first (you brought back something they
## told you about), then, on a roll, one hint they have not given yet. Never both in one talk -
## same rule sky_hints.gd already had, and that file's `maybe_hint_line` is what calls this.
static func line_for(npc_id: String, chance: float, rng: RandomNumberGenerator = null) -> String:
	var mine := sights_of(npc_id)
	if mine.is_empty():
		return ""
	var thanked := _dict(F_THANKED)
	for e in mine:
		var sid := str(e["id"])
		if is_caught(sid) and not thanked.has(sid):
			thanked[sid] = true
			GameState.flags[F_THANKED] = thanked
			return str(CATCH_LINES.get(sid, "You found it. I knew it was real."))
	var unheard: Array = []
	for e in mine:
		if not is_heard(str(e["id"])):
			unheard.append(e)
	if unheard.is_empty():
		return ""
	var roll: float = rng.randf() if rng != null else randf()
	if roll >= chance:
		return ""
	var pick: Dictionary = unheard[0]
	if unheard.size() > 1:
		var i: int = (rng.randi() if rng != null else randi()) % unheard.size()
		pick = unheard[i]
	mark_heard(str(pick["id"]))
	return str(pick.get("hint_line", ""))


# ------------------------------------------------------------------ test hooks and budgets
## Used by the round's probes and by tools/safari_wire_check.gd. Not called by the game.
static func debug_reset() -> void:
	GameState.flags[F_HEARD] = {}
	GameState.flags[F_THANKED] = {}


## Every player-facing string this file owns, measured rather than trusted.
static func lines_ok() -> bool:
	for k in CATCH_LINES:
		if str(CATCH_LINES[k]).length() > LINE_MAX:
			return false
	return CATCH_LINES.size() == SafariCatalog.hinted_ids().size()


static func longest_line() -> int:
	var n := 0
	for k in CATCH_LINES:
		n = maxi(n, str(CATCH_LINES[k]).length())
	return n


## BOOK round: /root/SkyJournal FIRST. The journal is an autoload now, so this is a direct hit on
## every scene - the world, the safari flight, the title - instead of a whole-tree search that
## found nothing outside the two showcase scenes. The search is kept as the fallback so a showcase
## that builds its own journal by hand still works.
static func _find_journal() -> Node:
	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return null
	var root := (loop as SceneTree).root
	var n := root.get_node_or_null("SkyJournal")
	if n != null:
		return n
	return root.find_child("SkyJournal", true, false)
