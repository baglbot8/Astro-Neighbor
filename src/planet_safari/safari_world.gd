class_name SafariWorld
extends Node3D
## BASE CLASS FOR A PLANET'S SAFARI CONTENT (docs/PLANET_SAFARI_SPEC.md 5.5, 12.5 and 13.2; builders P3,
## SYS). One script per planet, at `res://src/planet_safari/worlds/<planet_id>.gd`, `extends SafariWorld`.
## PlanetSafari loads it by planet id when a safari starts, adds it as its own child, calls `build`, then
## `tick` every frame, then `go_to_sleep`, and frees it with everything it made. Nothing it builds exists
## outside a safari (the user's rule 5: "unless you're in safari mode the life and events on the
## planet dont happen").
##
## Override what you need; every method has a safe default. See planet_safari.gd's header for the
## full API (subjects, events, places), and `placeholder_world.gd` for a worked example.
##
## ================================================================================ THE MANIFEST (12.5)
## Everything the rest of the game needs to know about a planet's safari WITHOUT running it - who offers
## it, what they say, and every subject it can ever show - is ONE constant in the world script:
##
##   const MANIFEST := {
##       "host":   "zorp",                     # npc_id of the neighbour who offers the safari
##       # the offer, in the neighbour's OWN voice (PlanetSafari.offer_in_conversation):
##       "offer":  "The garden wakes up for three minutes a day...",   # said first
##       "ask":    "Photo safari?",            # the question (answers: "Let's go!" / "Not now")
##       "yes":    "...",                      # after "Let's go!", before the fade
##       "no":     "...",                      # after "Not now" (asked again next talk)
##       "asleep": "...",                      # once a day after today's safari has run
##       # EVERY subject the world can ever register (add_subject ids), in the order the journal lists
##       # them - including rare-day and night-only ones. The journal shows "????" for each until it is
##       # photographed and never shows `name` before then.
##       "roster": [
##           {"id": "mush_hopper", "name": "Mush-hopper",  "tier": "creature",  "category": "creature"},
##           {"id": "spore_bloom", "name": "Spore Bloom",  "tier": "common",    "category": "event"},
##           {"id": "great_bloom", "name": "The Great Bloom", "tier": "rare",   "category": "event"},
##           {"id": "zorp",        "name": "Zorp",         "tier": "neighbour", "category": "neighbour"},
##           {"id": "bulb_bed",    "name": "The Tentacle Bulb Bed", "tier": "sight", "category": "sight"},
##           {"id": "spore_gnome", "name": "A Spore Gnome", "tier": "bonus",    "category": "bonus"},
##       ],
##       # optional: the review's line about each photo, in the host's voice (safari_review.gd
##       # VOICE_LINES shape: "Smudge"/"Fair"/"Fine"/"Gallery" -> [lines with one %s for the name],
##       # "moment" -> a sentence added when the moment was caught, "no_subject" -> [lines]).
##       "review": {...},
##   }
##
## CATEGORY (spec 15.5, the field FIXED BY THE LEAD so the worlds and the journal are built in parallel):
## each roster entry may carry "category": "sight" | "event" | "neighbour" | "creature" | "bonus" - the
## scrapbook section its page sits in (SkyJournal's SCRAPBOOK: Sights, Events, Neighbours, Creatures,
## Bonus, each grouped by planet). A subject may also carry it in its add_subject spec; the roster's wins
## only when the spec has none. AN ENTRY WITHOUT ONE STILL WORKS: `category_from` gives it one from its
## tier (then its subject "kind"), which is exactly today's rosters -
##     "neighbour" -> neighbour · "creature", "night" -> creature · "sight" -> sight · "bonus" -> bonus
##     · "common", "uncommon", "rare", "rare_day" (and anything else) -> event
## What the category changes:
##   "sight"  always there, low rarity (the Antenna Mast, Bolt's Workshop). It pays as usual, but it does
##            NOT count toward the density band (tools/ps_wanderer.gd) or the pacing director below: the
##            director never counts it as "in view", as an encounter, as a regular or as a photo.
##   "bonus"  hidden, small, collector's only (a lost sock on a pipe). Not counted, the same as a sight,
##            and it PAYS NOTHING: SafariPhotoScorer gives its photo price 0, and the review says "A
##            collector's page!" instead of a price.
## Readers: SafariWorld.category_from(entry) / subject_category(subject) / key_category(key), and
## counts_for_pacing(subject) / category_pays(category). A tier "sight" or "bonus" is accepted too
## (TIER_RARITY: rarity 1), so a sight's entry may say {"tier": "sight", "category": "sight"}.
##
## TIERS (spec 11.2 / 12): "creature" (always about), "night" (a night-only creature), "common" (~30 s,
## repeats), "uncommon" (~12 s, repeats), "rare" (once), "rare_day" (1 day in 4), "neighbour" (the host),
## "sight" and "bonus" (spec 15.5, see CATEGORY).
## A subject registered without a "rarity" gets one from its tier (TIER_RARITY: rarity follows the tier),
## and every registered subject carries its "tier". A "rare"/"rare_day" subject that is awake keeps the
## pacing director quiet (below). An id the world registers that the roster does not list is a warning.
## Readers: PlanetSafari.manifest(planet_id) (cached; falls back to PlanetSafari.PLANETS for a world with
## no MANIFEST yet), the journal (SkyJournal.planet_roster, loaded lazily) and the review (the host).
##
## ======================================================================== THE PACING DIRECTOR (13.2)
## A planet this small only stays lively for a wanderer if something steps in when nothing is around
## (the critic: without it only 0-7 of 60 runs met the 20-second rule). `SafariWorld.Pacing` is that
## director, shared by every planet; generalised from Bolt's curious spring-hopper scouts (worlds/bolt.gd,
## R4 round 3), with its measured numbers as the defaults. In `build`:
##
##   pacing = Pacing.new()                    # a Node: add it as a child, it runs itself while awake
##   add_child(pacing)
##   pacing.setup(self)
##   pacing.add_bringer({
##       "id":    "mush_hopper",              # the SUBJECT id it brings (a registered add_subject id)
##       "bring": func(spot: Dictionary) -> bool: ...,   # bring one out NOW; true = it came
##       "ready": func() -> bool: ...,        # optional: one is free to bring (default: always)
##   })                                       # ...one entry per subject it may bring: give it SEVERAL
##   pacing.places = func() -> Array: ...     # optional: world points where other creatures are, or
##                                            # will come into view (burrows, trees, the neighbour)
##
##   `spot` handed to `bring`:
##     "dir"     a unit direction on the sphere: a ground spot a few metres ahead (SPOT_M), clear of
##               props, the pad and every `places` point by CLEAR_M, flat, and in the middle of where
##               the lens WILL be looking when it is up (SPOT_LEAD_SEC ahead, SPOT_FRAME_FRAC of the
##               frame) with a clear line of sight to it. Vector3.ZERO when no ground spot is in view
##               (the lens is on the horizon or the sky): the bringer then decides for itself (Bolt's
##               hopper boings UP into the view) or returns false and the director tries the next one.
##     "ahead"   for LOOKING OVER THE DECK (the "dir" is ZERO): a ground spot SPOT_M ahead along the way the
##               lens looks, with the same clearances but no view test, and
##     "rise"    how high above it something must be to come into the middle of that view (the
##               smallest of RISE_STEP steps up to RISE_MAX_M, with a clear line of sight); -1 when no
##               height up to RISE_MAX_M does. Bolt's hopper boings up to it; a flier comes in at it.
##               "ahead" is Vector3.ZERO and "rise" -1 when there is no such spot either.
##     "lens"    the lens transform SPOT_LEAD_SEC ahead (Transform3D).
##     "lonely"  seconds with nothing clearly in view.
##   Helpers a bringer may call: ground_spot(lift_m), ahead_spot(), rise_into_view(dir, lens),
##   lens_soon(lead_s), in_view_from(xf, q, grow), point_in_frame(q, grow), sight_clear(from, q),
##   creature_ahead(), other_places().
##
## SIGHTS AND BONUS SUBJECTS ARE INVISIBLE TO IT (spec 15.5; CATEGORY above): it skips them when it looks
## round (never "in view", never an encounter, never shy-making, never a regular) and does not count their
## photos toward any share - a mast that is always on screen must not stop it bringing something alive.
##
## WHAT IT DOES, every CHECK_SEC while the planet is awake:
##   LOOKS ROUND with the player's lens through the photo scorer's own test (SafariPhotoScorer.
##     score_subject): `in_view` (the STRICT test: half inside the frame, CLEAR_MIN_SIZE of the frame
##     tall, its centre in the middle CLEAR_FRAME_FRAC) and the looser "new" test (SHY_MIN_SIZE): a
##     subject seen again after REENCOUNTER_OFF_SEC out of view is a NEW ENCOUNTER.
##   ONE NEW THING AT A TIME: after a new encounter, `shy(id)` is true for SHY_SEC for every subject not
##     in view - a world makes its shy creatures keep out of sight while it is (Bolt's crabs, beetles).
##   BRINGS SOMETHING when nothing has been clearly in view for AFTER_SEC, the lens is steady (under
##     STEADY_DEG_S), you are not about to walk into another creature's place (AHEAD_M / AHEAD_DEG /
##     NEAR_M, waived after AHEAD_WAIT_SEC more), nothing clear is still new (SHY), and no rare is near.
##   QUIET ONLY NEAR A RARE (spec 14.1, amending 13.2's planet-wide quiet): while a rare event is up
##     (PlanetSafari.rare_event_up() - any awake subject of tier "rare"/"rare_day", or with no tier rarity 4
##     and kind other than creature/neighbour, or a running event whose spec carries such a "tier") it
##     keeps quiet only (a) while the rare's point is on screen or about to be (inside the frame grown by
##     RARE_FRAME_GROW, not hidden by the planet or a prop), anywhere on the planet, or (b) while the
##     player stands within RARE_NEAR_DEG (great-circle, from the planet centre) of the rare. On the far side the planet stays alive for the
##     player who chose not to go. Near it, THE LAST RESORT: after RARE_LAST_SEC with nothing clearly in
##     view it may bring something, but only with the rare behind the lens (RARE_BEHIND_DEG), so nothing is
##     ever brought in front of it. `rare_near()`, `rare_points()` read the same rule.
##   VARIES BY SHARE (spec 13.2's 30%, 14.2, 14.3 - the director's job, for every planet): the REGULARS are
##     every subject it can bring plus every "creature"/"night" subject that has been awake this safari (so
##     a night-only one is a regular at night only). The SHARERS are the regulars it can bring plus any other
##     regular once it has a photo (`sharers`): a night-only creature no bring can deliver and nobody has found
##     (Bolt's spark-moths on Antenna Hill) would otherwise hold back every bringer for nothing. Each sharer's
##     FAIR share is the sharers' photos split evenly (`fair_count`), counting this safari's photos plus this planet's earlier safaris in this
##     session at CARRY_KEEP per safari back (`tally`; in memory, nothing is saved). Once
##     MIN_PHOTOS_FOR_SHARE photos are taken, a sharer HOLD_OVER photos or more over its fair share is HELD
##     BACK (`held_back`): it is not brought, and `shy(id)` keeps it out of sight (HOLD_BACK_SHY); and one
##     whose share of ALL the photos is over MAX_SHARE (`over_cap`) is not brought either (not made shy for
##     that alone). THE PER-BRING CAP (spec 17.1 rule 7, "pacing never waits forever"): nor is one that one
##     more photo would push over MAX_SHARE (`would_pass_cap`: (tally + 1) / (all + 1) > MAX_SHARE) while any
##     other is eligible. All three are OVER SHARE, and are lifted together once NOTHING has been clearly in
##     view for `cap_wait()` = AFTER_SEC + HOLD_WAIT_SEC, never more than NEVER_WAIT_SEC (20 s, the user's
##     rule; a world that sets HOLD_WAIT_SEC to INF still gets 20): then the LEAST over (`over_by`) may come,
##     and it alone until NEVER_WAIT_SEC, when any over-share one may (least over first). That clock is
##     `nothing`, NOT `lonely`: a bring resets `lonely` (the retry), so a subject that is brought again and
##     again and never seen would otherwise hold the lift off for ever. A world's own
##     `ready` must say only whether one is FREE to bring: a share test inside `ready` is invisible to this
##     rule and can wait for ever (measured, Grig careful seed 1: every ready() false from 81 s to the end,
##     99 s of nothing; Vela careful seed 1, HOLD_WAIT_SEC = INF and only a bird that needs a mast in view
##     under share: 114 s). Of the rest it brings the one furthest UNDER its share first (`deficit`), then
##     puts last the one it brought last time, then the one brought longest ago, then the one seen
##     longest ago, and among exact equals a SHUFFLE seeded by the day, this planet's safari count this session
##     and where the player stands (never the order the world registered its bringers in: the first one
##     brought ends a ten-plate safari one photo ahead, so a fixed first choice is a fixed favourite). Before any photos
##     (a player who takes none, the density gate's wanderer) the shares are of the encounters and nothing
##     is held back: the least met first, exactly as before. With ONE bringer it cannot vary what it
##     brings: give it at least three (a warning says so).
##   Readable: `in_view`, `lonely`, `brought` (id -> times), `encounters` (id -> n), `photos` (id -> n),
##     `last_bring` ({id, t, lonely, on_ground}), `quiet_reason()` (why nothing is being brought now),
##     `nothing` (seconds with nothing clearly in view; brings do not reset it), `pick_order()` (the ready
##     bringers it would try now, best first), `would_pass_cap(id)`, `over_by(id)`, `cap_wait()`,
##     `regulars()`, `sharers()`, `tally(id)`, `fair_count(id)`, `deficit(id)`, `held_back(id)`, `over_cap(id)`,
##     `rare_near()`.
##   `enabled = false` pauses it (a world's own cut-scene).

## One day in this many is a RARE DAY on this planet (PlanetSafari.is_rare_day). 4 = the spec's
## "1 day in 4". Read once, when the safari starts.
var rare_one_in: int = 4
## Optional override of where the safari starts: a unit direction on the sphere. Vector3.ZERO keeps
## the default (beside the landing pad, the way world.gd spawns a player off the pad).
var start_dir: Vector3 = Vector3.ZERO
## Optional override of the start heading: a world direction the player faces at the start (projected
## onto the ground). Vector3.ZERO keeps the default (straight away from the rocket).
var start_heading: Vector3 = Vector3.ZERO

## Set by PlanetSafari before `build` runs.
var safari: PlanetSafari

## The tiers a manifest may use, and the rarity (1..4, the flight's scale) each gives a subject that is
## registered without one. Bolt's own table (worlds/bolt.gd header): creatures and the neighbour 1, a
## night-only creature and common events 2, uncommon events 3, rare events 4.
const TIER_RARITY := {
	"creature": 1, "neighbour": 1, "night": 2, "common": 2, "uncommon": 3, "rare": 4, "rare_day": 4,
	"sight": 1, "bonus": 1,
}
## The tiers that keep the pacing director quiet while they are up.
const QUIET_TIERS := ["rare", "rare_day"]

## THE SCRAPBOOK'S SECTIONS (spec 15.5), in the order the journal shows them. See CATEGORY in the header.
const CATEGORIES := ["sight", "event", "neighbour", "creature", "bonus"]
## Categories that do not count toward the density band or the pacing director.
const UNCOUNTED_CATEGORIES := ["sight", "bonus"]
## Categories whose photos pay nothing (a collector's page).
const UNPAID_CATEGORIES := ["bonus"]
## A tier's category when the entry names none (today's rosters).
const TIER_CATEGORY := {
	"neighbour": "neighbour", "creature": "creature", "night": "creature", "sight": "sight", "bonus": "bonus",
	"common": "event", "uncommon": "event", "rare": "event", "rare_day": "event",
}


## The scrapbook category of a roster entry or a subject Dictionary: its own "category" when it is one of
## CATEGORIES, else from its "tier" (TIER_CATEGORY), else from its "kind" ("neighbour", "creature",
## "sight", "bonus"), else "event".
static func category_from(entry: Dictionary) -> String:
	var c := str(entry.get("category", ""))
	if CATEGORIES.has(c):
		return c
	var tier := str(entry.get("tier", ""))
	if TIER_CATEGORY.has(tier):
		return str(TIER_CATEGORY[tier])
	var kind := str(entry.get("kind", ""))
	if CATEGORIES.has(kind):
		return kind
	return "event"


## The category of a live subject (a registry Dictionary with "key" = "<planet>:<id>"): the subject's own
## "category", else its roster entry's, else from its tier and kind (category_from).
static func subject_category(s: Dictionary) -> String:
	var c := str(s.get("category", ""))
	if CATEGORIES.has(c):
		return c
	var key := str(s.get("key", ""))
	if key.contains(":"):
		var e := PlanetSafari.roster_entry(key.get_slice(":", 0), key.get_slice(":", 1))
		if CATEGORIES.has(str(e.get("category", ""))):
			return str(e["category"])
	return category_from(s)


## The category of subject key "<planet>:<id>" from its roster entry (category_from), or from `live` (the
## live registry's Dictionary for it, when there is one) for an id the roster does not list; "event" when
## neither knows it.
static func key_category(key: String, live: Dictionary = {}) -> String:
	if not live.is_empty():
		return subject_category(live)
	if not key.contains(":"):
		return "event"
	var e := PlanetSafari.roster_entry(key.get_slice(":", 0), key.get_slice(":", 1))
	return category_from(e) if not e.is_empty() else "event"


## False for a sight or a bonus subject: it never counts toward the density band or the pacing director.
static func counts_for_pacing(s: Dictionary) -> bool:
	return not UNCOUNTED_CATEGORIES.has(subject_category(s))


## False for a category whose photos pay nothing ("bonus").
static func category_pays(category: String) -> bool:
	return not UNPAID_CATEGORIES.has(category)


## A ready-made "front" for add_subject (spec 11.1): the world direction of `node`'s own local axis
## `local_face` (the way its face points in its model; +Z here unless the creature was built another
## way). Read at the instant the shutter fires, so a turning creature is scored as it is then. A
## creature drawn in a MultiMesh herd has no node of its own that turns: give it a Callable that
## returns that creature's face direction from its own state instead.
static func front_of(node: Node3D, local_face: Vector3 = Vector3(0, 0, 1)) -> Callable:
	return func() -> Vector3:
		if not is_instance_valid(node):
			return Vector3.ZERO
		return (node.global_transform.basis * local_face).normalized()


## Called once, behind the black fade, after the player is at the start. Register subjects and
## events here (safari.add_subject / safari.add_event) and build their nodes as children of this
## node. Everything is warmed up (drawn once, tiny, in front of the lens) before the fade lifts.
func build(_safari: PlanetSafari) -> void:
	pass


## Every frame while the planet is awake. `t` = seconds since it woke (0..PlanetSafari.DURATION).
func tick(_t: float, _delta: float) -> void:
	pass


## The three minutes are up: start everything's "last puff" and hiding. PlanetSafari puffs at every
## subject that is awake either way, and fades out SLEEP_SEC later and frees this node. Return true
## when this script hides its own things over those seconds; false (the default) and PlanetSafari
## hides every awake subject's node just after its puff.
func go_to_sleep() -> bool:
	return false


# ================================================================================ THE PACING DIRECTOR
class Pacing extends Node:
	## Bolt's measured values (worlds/bolt.gd, R4 round 3), each named for what it was there. A world may
	## change any of them after `setup`.
	## Nothing clearly in view this long and something is brought (Bolt's CURIOUS_AFTER_SEC).
	var AFTER_SEC := 12.0
	var CHECK_SEC := 0.2
	## The strict "clearly in view" test (Bolt's CURIOUS_MIN_SIZE_FRAC / CURIOUS_FRAME_FRAC).
	var CLEAR_MIN_SIZE := 0.08
	var CLEAR_FRAME_FRAC := 0.9
	## The looser "new encounter" test and the shy rule (Bolt's SHY_SEC / SHY_MIN_SIZE_FRAC /
	## REENCOUNTER_OFF_SEC).
	var SHY_SEC := 9.0
	var SHY_MIN_SIZE := 0.05
	var REENCOUNTER_OFF_SEC := 10.0
	## Only while the lens turns slower than this (degrees a second): a pop mid-turn lands behind you.
	var STEADY_DEG_S := 25.0
	## Not while walking toward another creature's place (Bolt's SCOUT_AHEAD_M / _DEG / _WAIT_SEC, SCOUT_NEAR_M).
	var AHEAD_M := 9.0
	var AHEAD_DEG := 60.0
	var NEAR_M := 6.0
	var AHEAD_WAIT_SEC := 1.5
	## After a bring, the next may come this long later if the first was not seen (Bolt's SCOUT_RETRY_SEC).
	var RETRY_SEC := 3.0
	## The ground spot (Bolt's SCOUT_POP_M / _POP_YAW / _FRAME_FRAC / _LEAD_POP_SEC / SCOUT_CLEAR_M,
	## HOPPER_PAD_CLEAR_DEG; the prop and slope limits of its _scout_spot).
	var SPOT_M: Array = [3.6, 4.4, 2.9, 5.1]
	var SPOT_YAW: Array = [0.0, 8.0, -8.0, 16.0, -16.0]
	var SPOT_FRAME_FRAC := 0.7
	var SPOT_LEAD_SEC := 0.35
	var SPOT_LIFT_M := 0.3
	var CLEAR_M := 4.0
	var PAD_CLEAR_DEG := 15.0
	var PROP_CLEAR_M := 0.55
	var MAX_SLOPE_DEG := 12.0
	## Looking over the deck: how high something may rise into the view, in steps (Bolt's SCOUT_BIG_MAX_M
	## less its SCOUT_BIG_SPARE, and its 0.15 m search step).
	var RISE_MAX_M := 1.85
	var RISE_STEP := 0.15
	## Spec 13.2: no single subject more than this share of a careful player's photos.
	var MAX_SHARE := 0.30
	## Photos before the photo share is trusted over the encounter share.
	var MIN_PHOTOS_FOR_SHARE := 3
	## QUIET ONLY NEAR A RARE (spec 14.1): the director keeps quiet for a rare only while the player is
	## within this great-circle angle of it (the lead's "about 70 degrees").
	var RARE_NEAR_DEG := 70.0
	## ...and never brings anything while the rare is on screen or about to be: its point inside the frame
	## grown by this, now or SPOT_LEAD_SEC ahead (anywhere on the planet).
	var RARE_FRAME_GROW := 1.3
	## THE LAST RESORT near a rare: after this long with nothing clearly in view it may bring something,
	## but only with the rare BEHIND the lens (more than RARE_BEHIND_DEG off where it looks, now and
	## SPOT_LEAD_SEC ahead), so nothing is ever brought in front of it. 16 s = the 20-second rule less the
	## RETRY_SEC (3 s) a bring may take to be seen and the 1 s to come up. INF turns it off.
	var RARE_LAST_SEC := 16.0
	var RARE_BEHIND_DEG := 90.0
	## VARIES BY SHARE (spec 14.3): a regular this many photos over its fair share is HELD BACK.
	var HOLD_OVER := 0.5
	## A held-back subject may still be brought when nothing else can and nothing has been clearly in view
	## for AFTER_SEC + this (12 + 4 = 16 s: inside the 20-second rule with a bring's RETRY_SEC to spare);
	## after that long `shy` stops holding it back too.
	var HOLD_WAIT_SEC := 4.0
	## PACING NEVER WAITS FOREVER (spec 17.1 rule 7): whatever a world sets HOLD_WAIT_SEC or AFTER_SEC to,
	## an over-share subject is lifted after at most this long with nothing clearly in view (the user's
	## 20-second rule). See `cap_wait()`.
	const NEVER_WAIT_SEC := 20.0
	## `shy(id)` is also true for a held-back subject (it keeps out of sight the way it does for ONE NEW THING
	## AT A TIME). false = held back from being brought only.
	var HOLD_BACK_SHY := true
	## This planet's earlier safaris in this session count toward the shares at this weight per safari
	## back (0.5: the last one at half, the one before at a quarter). In memory only: nothing is saved.
	var CARRY_KEEP := 0.5
	static var _carry: Dictionary = {}
	## Safaris started on each planet this session (seeds the SHUFFLE of VARIES BY SHARE in the header).
	static var _starts: Dictionary = {}
	## The tiers of the creatures that share the photos with what the director brings (regulars()).
	const REGULAR_TIERS := ["creature", "night"]

	var enabled := true
	var world: SafariWorld
	var safari: PlanetSafari
	var places: Callable = Callable()

	var in_view := true
	var lonely := 0.0
	## Seconds with nothing clearly in view. Unlike `lonely`, a bring does not reset it: it is the clock of
	## the over-share lift (`cap_wait`).
	var nothing := 0.0
	var brought: Dictionary = {}
	var encounters: Dictionary = {}
	var photos: Dictionary = {}
	var last_bring: Dictionary = {}

	var _bringers: Array = []
	var _last_brought_t: Dictionary = {}
	var _view_ids: Dictionary = {}
	var _last_view: Dictionary = {}
	var _shy_until := -INF
	var _shy_clear_until := -INF
	var _clock := 0.0
	var _lens_fwd := Vector3.FORWARD
	var _lens_turn := 0.0
	var _t := 0.0
	var _quiet := ""
	var _awake_regulars: Dictionary = {}
	var _carry_in: Dictionary = {}
	var _carried := false
	var _held: Dictionary = {}
	var _turn := 0
	var _over_waiting := false
	var _said_stuck := false

	func setup(w: SafariWorld) -> void:
		world = w
		safari = w.safari
		name = "Pacing"
		if safari != null and not safari.photo_taken.is_connected(_on_photo):
			safari.photo_taken.connect(_on_photo)
		if safari != null:
			_carry_in = (_carry.get(safari.planet_id, {}) as Dictionary).duplicate()
			var n := int(_starts.get(safari.planet_id, 0))
			_starts[safari.planet_id] = n + 1
			_turn = safari.day + n

	## See THE PACING DIRECTOR in the file header for the entry's keys.
	func add_bringer(spec: Dictionary) -> void:
		var id := str(spec.get("id", ""))
		if id == "" or not (spec.get("bring") is Callable):
			push_warning("SafariWorld.Pacing.add_bringer: an entry needs an \"id\" and a \"bring\" Callable")
			return
		_bringers.append(spec)

	func bringer_ids() -> Array:
		return _bringers.map(func(b: Dictionary) -> String: return str(b["id"]))

	## True while the shy creature `id` should keep out of sight and `id` itself is not in view: something
	## else NEW was just seen (ONE NEW THING AT A TIME), or `id` is HELD BACK over its share (VARIES BY
	## SHARE; not after `cap_wait()` with nothing clearly in view).
	func shy(id: String) -> bool:
		if _view_ids.has(id) or not _awake():
			return false
		if _t < _shy_until:
			return true
		return HOLD_BACK_SHY and nothing < cap_wait() and _held.has(id)

	## How long nothing must have been clearly in view before an OVER-SHARE subject may be brought:
	## AFTER_SEC + HOLD_WAIT_SEC, never more than NEVER_WAIT_SEC (spec 17.1 rule 7).
	func cap_wait() -> float:
		return minf(AFTER_SEC + HOLD_WAIT_SEC, NEVER_WAIT_SEC)

	## Why nothing is being brought right now ("" = it would bring on the next check).
	func quiet_reason() -> String:
		return _quiet

	func _ready() -> void:
		if _bringers.size() == 1:
			push_warning("SafariWorld.Pacing: one bringer (%s) cannot vary what it brings (spec 13.2): give it several" % str(_bringers[0]["id"]))

	func _awake() -> bool:
		return safari != null and is_instance_valid(safari) and safari.phase == PlanetSafari.Phase.AWAKE

	func _on_photo(p: Dictionary) -> void:
		var key := str(p.get("subject_key", ""))
		if key == "":
			return
		var id := key.get_slice(":", 1)
		# a sight or a bonus photo is not the director's business (spec 15.5)
		if SafariWorld.UNCOUNTED_CATEGORIES.has(SafariWorld.key_category(key, safari.subject(key))):
			return
		photos[id] = int(photos.get(id, 0)) + 1
		_update_held()

	func _process(delta: float) -> void:
		if not _awake() or not enabled:
			return
		_t = safari.elapsed
		_clock -= delta
		var checked := _clock <= 0.0
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if checked:
			_clock = CHECK_SEC
			_look_round(cam)
			_update_held()
			if cam != null:
				var f := -cam.global_transform.basis.z
				_lens_turn = rad_to_deg(f.angle_to(_lens_fwd)) / CHECK_SEC
				_lens_fwd = f
		lonely = 0.0 if in_view else lonely + delta
		nothing = 0.0 if in_view else nothing + delta
		if not checked:
			return
		_quiet = _why_quiet()
		if _quiet != "":
			return
		var order := pick_order()
		if order.is_empty():
			_quiet = "over share, waits %.1f s" % cap_wait() if _over_waiting else "nothing ready"
			# a world whose every ready() says no for this long has a rule of its own this one cannot lift
			# (a share test inside `ready`: see THE PER-BRING CAP): say so once, so a log shows it
			if not _over_waiting and nothing >= NEVER_WAIT_SEC and not _said_stuck:
				_said_stuck = true
				print("[Pacing] STUCK t=%.1f: every bringer's ready() is false after %.1f s of nothing (photos %s)" % [
					_t, nothing, str(photos)])
			return
		var lens := lens_soon(SPOT_LEAD_SEC)
		var spot := {"dir": ground_spot(SPOT_LIFT_M), "lens": lens, "lonely": lonely, "ahead": Vector3.ZERO,
			"rise": -1.0}
		if spot["dir"] == Vector3.ZERO:
			var a := ahead_spot()
			if a != Vector3.ZERO:
				spot["ahead"] = a
				spot["rise"] = rise_into_view(a, lens)
		for b: Dictionary in order:
			var ok: Variant = (b["bring"] as Callable).call(spot)
			if bool(ok):
				var id := str(b["id"])
				brought[id] = int(brought.get(id, 0)) + 1
				_last_brought_t[id] = _t
				last_bring = {"id": id, "t": _t, "lonely": lonely, "on_ground": spot["dir"] != Vector3.ZERO}
				print("[Pacing] brings %s t=%.1f after %.1f s quiet%s (brought %s, photos %s)" % [id, _t, lonely,
					(", OVER SHARE after %.1f s of nothing (%s)" % [nothing, "least over" if nothing < NEVER_WAIT_SEC else "any"]) if _is_over(id) else "", str(brought), str(photos)])
				# the next may come RETRY_SEC from now if this one is not seen
				lonely = AFTER_SEC - RETRY_SEC
				return
		_quiet = "no bringer could"

	func _why_quiet() -> String:
		if lonely < AFTER_SEC:
			return "not lonely"
		if _lens_turn > STEADY_DEG_S:
			return "lens turning"
		if safari.rare_event_up():
			var why := _rare_quiet()
			if why != "":
				return why
		if _t < _shy_clear_until:
			return "something new still"
		if lonely < AFTER_SEC + AHEAD_WAIT_SEC and creature_ahead():
			return "creature ahead"
		return ""

	## Why the director keeps quiet for a rare that is up ("" = it need not; QUIET ONLY NEAR A RARE in the
	## header). Called only while PlanetSafari.rare_event_up().
	func _rare_quiet() -> String:
		var pl := safari.player
		if not is_instance_valid(pl) or safari.planet == null:
			return "rare event up"
		var lens := lens_soon(SPOT_LEAD_SEC)
		var here := safari.planet.dir_of(pl.global_position)
		var near: Array = []
		for q: Vector3 in rare_points():
			if (in_view_from(lens, q, RARE_FRAME_GROW) or point_in_frame(q, RARE_FRAME_GROW)) and sight_clear(lens.origin, q):
				return "rare in view"
			if rad_to_deg(here.angle_to(safari.planet.dir_of(q))) < RARE_NEAR_DEG:
				near.append(q)
		if near.is_empty():
			return ""
		if lonely < RARE_LAST_SEC:
			return "rare event near"
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		var views: Array = [lens]
		if cam != null:
			views.append(cam.global_transform)
		for q: Vector3 in near:
			for xf: Transform3D in views:
				if rad_to_deg((-xf.basis.z).angle_to(q - xf.origin)) < RARE_BEHIND_DEG:
					return "rare event near, in front"
		return ""

	## True while a rare event is up and the player stands within RARE_NEAR_DEG (great-circle, from the
	## planet centre) of where it is: the director's "near the rare" (spec 14.1).
	func rare_near() -> bool:
		if not _awake() or not safari.rare_event_up():
			return false
		var pl := safari.player
		if not is_instance_valid(pl) or safari.planet == null:
			return true
		var here := safari.planet.dir_of(pl.global_position)
		for q: Vector3 in rare_points():
			if rad_to_deg(here.angle_to(safari.planet.dir_of(q))) < RARE_NEAR_DEG:
				return true
		return false

	## Where each rare that is up is (world points): every awake subject that keeps the director quiet
	## (PlanetSafari.rare_event_up's own test) at its scored point, and every running event whose spec
	## carries a rare "tier", on the ground at its "dir".
	func rare_points() -> Array:
		var out: Array = []
		for s: Dictionary in safari.awake_subjects():
			var tier := str(s.get("tier", ""))
			var rare := SafariWorld.QUIET_TIERS.has(tier) or (tier == "" and int(s.get("rarity", 1)) >= 4
				and not ["creature", "neighbour"].has(str(s.get("kind", ""))))
			var q := SafariPhotoScorer.subject_point(s)
			if rare and q != Vector3.ZERO:
				out.append(q)
		for ev: Dictionary in safari._events:
			if SafariWorld.QUIET_TIERS.has(str(ev.get("tier", ""))) and bool(ev["eligible"]) \
					and bool(ev["started"]) and not bool(ev["ended"]) and (ev.get("dir", Vector3.ZERO) as Vector3) != Vector3.ZERO:
				out.append(safari.planet.surface_point(ev["dir"]))
		return out

	## The ready bringers the director would try now, best first (VARIES BY SHARE and THE PER-BRING CAP in
	## the header): every one under share, and - once nothing has been clearly in view for `cap_wait()` -
	## the over-share ones after them, the least over first. A world's own bring (Vela's stir before a rare)
	## asks this too, so it keeps the same rule.
	func pick_order() -> Array:
		var ready: Array = []
		for b: Dictionary in _bringers:
			var rc: Variant = b.get("ready", Callable())
			if rc is Callable and (rc as Callable).is_valid() and not bool((rc as Callable).call()):
				continue
			ready.append(b)
		var waited := nothing >= cap_wait()
		var last_id := str(last_bring.get("id", ""))
		var here := safari.player.global_position.snapped(Vector3.ONE) if is_instance_valid(safari.player) else Vector3.ZERO
		var rows: Array = []
		_over_waiting = false
		for b: Dictionary in ready:
			var id := str(b["id"])
			var over := _is_over(id)
			if over and not waited:
				_over_waiting = true
				continue
			rows.append([1.0 if over else 0.0, over_by(id) if over else 0.0, 1.0 if id == last_id else 0.0,
				-deficit(id), float(_last_brought_t.get(id, -INF)), float(_last_view.get(id, -INF)),
				float(hash("%s|%d|%s" % [id, _turn, str(here)])), b])
		# THE LEAST OVER FIRST, AND ALONE until NEVER_WAIT_SEC: from cap_wait() only the least-over one(s) may
		# come (the rule's "bring the least-over one"); a view it cannot come into waits for it, and only at
		# NEVER_WAIT_SEC may the next over-share one come instead. (Measured on Vela, careful seeds 1 and
		# 901-910: it did not change the snow-mite's share, 43% without it and 45% with it - there the lift
		# goes to the mite because nothing else can come into a raised view, which no order changes.)
		if waited and nothing < NEVER_WAIT_SEC:
			var least := INF
			for r: Array in rows:
				if r[0] > 0.5:
					least = minf(least, float(r[1]))
			rows = rows.filter(func(r: Array) -> bool: return r[0] < 0.5 or float(r[1]) <= least + 0.0001)
		if rows.size() > 1:
			rows.sort_custom(func(a: Array, c: Array) -> bool:
				for k in 7:
					if a[k] != c[k]:
						return a[k] < c[k]
				return false)
		return rows.map(func(r: Array) -> Dictionary: return r[7])

	## True while `id` is OVER SHARE: held back, over the cap, or one more photo would pass the cap.
	func _is_over(id: String) -> bool:
		return held_back(id) or over_cap(id) or would_pass_cap(id)

	# ------------------------------------------------------------ THE PER-BRING CAP (spec 17.1 rule 7)
	## True while one more photo of `id` would push it over MAX_SHARE of all the photos ((tally + 1) /
	## (all + 1), counted as `over_cap` counts), once MIN_PHOTOS_FOR_SHARE photos are taken. The director
	## does not bring it while another eligible subject is under share; see `cap_wait()`.
	func would_pass_cap(id: String) -> bool:
		if _photo_total() < MIN_PHOTOS_FOR_SHARE:
			return false
		return (tally(id) + 1.0) / (_tally_total() + 1.0) > MAX_SHARE

	## How far over MAX_SHARE one more photo of `id` would put it (negative = still under): the order of
	## the over-share subjects once they are lifted, the least over first.
	func over_by(id: String) -> float:
		return (tally(id) + 1.0) / (_tally_total() + 1.0) - MAX_SHARE

	## All the photos counted toward the shares: this safari's plus the carried ones (`tally`).
	func _tally_total() -> float:
		var tot := 0.0
		for k: String in photos:
			tot += tally(k)
		for k: String in _carry_in:
			if not photos.has(k):
				tot += tally(k)
		return tot

	# ---------------------------------------------------------------------- VARIES BY SHARE (spec 14.3)
	## Photos of `id` counted toward its share: this safari's, plus what is carried over from this
	## planet's earlier safaris in this session (CARRY_KEEP).
	func tally(id: String) -> float:
		return float(photos.get(id, 0)) + float(_carry_in.get(id, 0.0))

	## The subjects that share the photos fairly: every subject the director can bring, and every
	## creature ("creature" / "night" tier) that has been awake this safari - so a night-only one counts
	## at night and not by day.
	func regulars() -> Array:
		var out: Array = bringer_ids()
		for id: String in _awake_regulars:
			if not out.has(id):
				out.append(id)
		return out

	## The regulars the photos are shared among: every bringer (the director can bring it), and every other
	## regular once it has a photo (the player has found it). A night-only creature the director cannot
	## bring and nobody has found yet (Bolt's spark-moths up on Antenna Hill) does not pull everyone's
	## fair share down: it would hold back every bringer for a subject no bring can deliver.
	func sharers() -> Array:
		var bring := bringer_ids()
		return regulars().filter(func(r: String) -> bool: return bring.has(r) or tally(r) > 0.0)

	## The photos `id` would have if the sharers' photos (tally) were shared evenly (0 when `id` is not
	## one of them).
	func fair_count(id: String) -> float:
		var regs := sharers()
		if regs.is_empty() or not regs.has(id):
			return 0.0
		var tot := 0.0
		for r: String in regs:
			tot += tally(r)
		return tot / float(regs.size())

	## How far `id` is under its fair share, in photos (negative = over). Before MIN_PHOTOS_FOR_SHARE
	## photos, by the encounters instead (a player who takes none): the least met comes first.
	func deficit(id: String) -> float:
		if _photo_total() < MIN_PHOTOS_FOR_SHARE:
			return -share_of(id)
		return fair_count(id) - tally(id)

	## True while `id` is HELD BACK: a sharer HOLD_OVER photos or more over its fair share, once
	## MIN_PHOTOS_FOR_SHARE photos are taken. It is not brought (unless nothing has been clearly in view
	## for `cap_wait()`; then the least over first), and `shy(id)` keeps it out of sight (HOLD_BACK_SHY).
	func held_back(id: String) -> bool:
		if _photo_total() < MIN_PHOTOS_FOR_SHARE:
			return false
		var regs := sharers()
		if not regs.has(id) or regs.size() < 2:
			return false
		return tally(id) >= fair_count(id) + HOLD_OVER

	## True while `id` is OVER THE CAP: once MIN_PHOTOS_FOR_SHARE photos are taken, its share of ALL the
	## photos (tally, events and the neighbour included) is over MAX_SHARE. It is not brought (unless nothing
	## has been clearly in view for `cap_wait()`), but it is not kept shy for this alone: with
	## three regulars and few other photos, an even split is itself about MAX_SHARE each (Bolt by day).
	func over_cap(id: String) -> bool:
		var n := _photo_total()
		if n < MIN_PHOTOS_FOR_SHARE:
			return false
		var tot := _tally_total()
		return tot > 0.0 and tally(id) / tot > MAX_SHARE

	## Refreshes the held-back set `shy` reads (every CHECK_SEC and after each photo).
	func _update_held() -> void:
		_held.clear()
		for id: String in regulars():
			if held_back(id):
				_held[id] = true

	func _photo_total() -> int:
		var n := 0
		for k: String in photos:
			n += int(photos[k])
		return n

	func _exit_tree() -> void:
		if _carried or safari == null or not is_instance_valid(safari) or safari.planet_id == "":
			return
		_carried = true
		var out := {}
		for k: String in _carry_in:
			out[k] = float(_carry_in[k]) * CARRY_KEEP
		for k: String in photos:
			out[k] = float(out.get(k, 0.0)) + float(photos[k])
		_carry[safari.planet_id] = out

	## The share of the photos so far that are of subject `id` (of the encounters, before
	## MIN_PHOTOS_FOR_SHARE photos). What the variety rule reads.
	func share_of(id: String) -> float:
		var tot_p := 0
		for k: String in photos:
			tot_p += int(photos[k])
		if tot_p >= MIN_PHOTOS_FOR_SHARE:
			return float(photos.get(id, 0)) / float(tot_p)
		var tot_e := 0
		for k: String in encounters:
			tot_e += int(encounters[k])
		return float(encounters.get(id, 0)) / float(maxi(tot_e, 1))

	## LOOKS ROUND (see the header): `in_view`, the new encounters and the shy timers.
	func _look_round(cam: Camera3D) -> void:
		_view_ids.clear()
		if cam == null:
			in_view = true
			return
		in_view = false
		var frame := get_viewport().get_visible_rect().size
		var space := safari._space()
		var ex := safari._exclude()
		for sj: Dictionary in safari.awake_subjects():
			if not SafariWorld.counts_for_pacing(sj):
				continue   # a sight or a bonus subject (spec 15.5)
			if REGULAR_TIERS.has(str(sj.get("tier", ""))):
				_awake_regulars[str(sj.get("id", ""))] = true
			var e := SafariPhotoScorer.score_subject(cam, frame, sj, safari.focus_m, space, ex, _t)
			if e.is_empty() or float(e["inside_frac"]) < 0.5:
				continue
			var size_frac := float(e["size_frac"])
			var clear := size_frac >= CLEAR_MIN_SIZE and point_in_frame(SafariPhotoScorer.subject_point(sj), CLEAR_FRAME_FRAC)
			if clear:
				in_view = true
			if size_frac < SHY_MIN_SIZE:
				continue
			var id := str(sj.get("id", ""))
			_view_ids[id] = true
			if _t - float(_last_view.get(id, -INF)) >= REENCOUNTER_OFF_SEC:
				encounters[id] = int(encounters.get(id, 0)) + 1
				_shy_until = _t + SHY_SEC
				if clear:
					_shy_clear_until = _t + SHY_SEC
			_last_view[id] = _t

	## True when world point `q` projects inside the frame grown by `grow` (1.0 = the frame itself).
	func point_in_frame(q: Vector3, grow: float) -> bool:
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam == null or cam.is_position_behind(q):
			return false
		var frame := get_viewport().get_visible_rect().size
		var sp := cam.unproject_position(q)
		var half := frame * 0.5 * grow
		return absf(sp.x - frame.x * 0.5) <= half.x and absf(sp.y - frame.y * 0.5) <= half.y

	## Where the lens will be `lead` seconds from now if the player keeps walking as they are.
	func lens_soon(lead: float) -> Transform3D:
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam == null:
			return Transform3D()
		var xf := cam.global_transform
		if is_instance_valid(safari.player):
			xf.origin += safari.player.get_tangent_velocity() * lead
		return xf

	## True when world point `q` is inside the frame grown by `grow`, seen from lens transform `xf`.
	func in_view_from(xf: Transform3D, q: Vector3, grow: float) -> bool:
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam == null:
			return false
		var loc := xf.affine_inverse() * q
		if loc.z > -0.05:
			return false
		var frame := get_viewport().get_visible_rect().size
		var tv := tan(deg_to_rad(cam.fov) * 0.5)
		var th := tv * frame.x / maxf(frame.y, 1.0)
		return absf(loc.x / -loc.z) <= th * grow and absf(loc.y / -loc.z) <= tv * grow

	## A clear line from `from` to `q` (a hit within 0.3 m of `q` counts as reaching it).
	func sight_clear(from: Vector3, q: Vector3) -> bool:
		var space := safari._space()
		if space == null:
			return true
		var rq := PhysicsRayQueryParameters3D.create(from, q, 0xFFFFFFFF, safari._exclude())
		rq.collide_with_areas = false
		var hit := space.intersect_ray(rq)
		return hit.is_empty() or (hit["position"] as Vector3).distance_to(q) <= 0.3

	## The other creatures' places, from the world's `places` Callable ([] without one).
	func other_places() -> Array:
		if places.is_valid():
			var v: Variant = places.call()
			if v is Array:
				return v
		return []

	## A ground spot where something brought up `lift_m` high would be seen (see "spot" in the header),
	## or Vector3.ZERO when there is none.
	func ground_spot(lift_m: float) -> Vector3:
		var p := safari.planet
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam == null or p == null:
			return Vector3.ZERO
		var lens := lens_soon(SPOT_LEAD_SEC)
		var pd := p.dir_of(lens.origin)
		var fwd := -lens.basis.z
		fwd -= pd * fwd.dot(pd)
		if fwd.length() < 0.01:
			return Vector3.ZERO
		fwd = fwd.normalized()
		for m: float in SPOT_M:
			for yaw: float in SPOT_YAW:
				var dirn := fwd.rotated(pd, deg_to_rad(yaw))
				var d := p.step_dir(pd, (pd * cos(0.5) + dirn * sin(0.5)).normalized(), m)
				if not _spot_clear(d):
					continue
				var ground := p.surface_point(d)
				var body := ground + p.up_at(ground) * lift_m
				if not in_view_from(lens, body, SPOT_FRAME_FRAC) or not sight_clear(lens.origin, body):
					continue
				return d
		return Vector3.ZERO

	## A ground spot SPOT_M ahead along the way the lens looks (nearest first, then turned SPOT_YAW), clear
	## of props, the pad, steep ground and every `places` point - with NO view test. Vector3.ZERO if none.
	func ahead_spot() -> Vector3:
		var p := safari.planet
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam == null or p == null:
			return Vector3.ZERO
		var lens := lens_soon(SPOT_LEAD_SEC)
		var pd := p.dir_of(lens.origin)
		var fwd := -lens.basis.z
		fwd -= pd * fwd.dot(pd)
		if fwd.length() < 0.01:
			fwd = -lens.basis.y - pd * (-lens.basis.y).dot(pd)
			if fwd.length() < 0.01:
				return Vector3.ZERO
		fwd = fwd.normalized()
		for m: float in SPOT_M:
			for yaw: float in SPOT_YAW:
				var d := p.step_dir(pd, (pd * cos(0.5) + fwd.rotated(pd, deg_to_rad(yaw)) * sin(0.5)).normalized(), m)
				if _spot_clear(d):
					return d
		return Vector3.ZERO

	## How high above ground spot `d` a body must be to be in the middle SPOT_FRAME_FRAC of the view from
	## `lens`, with a clear line of sight: 0 when it already is at SPOT_LIFT_M, -1 when no height up to
	## RISE_MAX_M is (Bolt's _big_apex, without its spare).
	func rise_into_view(d: Vector3, lens: Transform3D) -> float:
		var p := safari.planet
		var ground := p.surface_point(d)
		var n := p.ground_normal(d)
		var h := 0.0
		while h <= RISE_MAX_M + 0.001:
			var body := ground + n * (SPOT_LIFT_M + h)
			if in_view_from(lens, body, SPOT_FRAME_FRAC):
				return h if sight_clear(lens.origin, body) else -1.0
			h += RISE_STEP
		return -1.0

	func _spot_clear(d: Vector3) -> bool:
		var p := safari.planet
		if p.nearest_prop_distance(d) < PROP_CLEAR_M or p.ground_normal(d).angle_to(d) > deg_to_rad(MAX_SLOPE_DEG):
			return false
		var pad := p.data.pad_dir.normalized() if p.data != null else Vector3.ZERO
		if pad != Vector3.ZERO and rad_to_deg(d.angle_to(pad)) < PAD_CLEAR_DEG:
			return false
		var ground := p.surface_point(d)
		for q: Vector3 in other_places():
			if ground.distance_to(q) < CLEAR_M:
				return false
		return true

	## True when another creature's place is within NEAR_M of the player, or within AHEAD_M and inside
	## AHEAD_DEG of the way they are walking (or looking, standing still): it is about to be seen anyway.
	func creature_ahead() -> bool:
		var pl := safari.player
		if not is_instance_valid(pl):
			return false
		var up := safari.planet.up_at(pl.global_position)
		var way := pl.get_tangent_velocity()
		if way.length() < 0.3:
			var cam := safari.rig.get_view_camera() if safari.rig != null else null
			way = -cam.global_transform.basis.z if cam != null else Vector3.ZERO
		way -= up * way.dot(up)
		if way.length() < 0.01:
			return false
		way = way.normalized()
		for q: Vector3 in other_places():
			var to := q - pl.global_position
			if to.length() < NEAR_M:
				return true
			if to.length() > AHEAD_M:
				continue
			to -= up * to.dot(up)
			if to.length() < 0.01 or rad_to_deg(way.angle_to(to.normalized())) <= AHEAD_DEG:
				return true
		return false
