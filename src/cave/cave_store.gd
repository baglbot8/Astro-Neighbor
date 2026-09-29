class_name CaveStore
extends RefCounted
## THE CAVE'S PAGES (docs/STORY_HOME_SPEC.md 9.3, builder CAVE 2026-09-28).
##
## One page per cave subject, like a planet's scrapbook pages: blank ("???") until photographed, then
## the best photo taken of it. "Best" = the higher grade (Smudge < Fair < Fine < Gallery), then the
## higher craft. No pay, no quest, no count toward anything else in the story.
##
## STATIC AND STATELESS, the HomeAlbumStore idiom: every call reads and writes straight through to
## `GameState.flags[F_CAVE]`, so a reload never has an in-memory copy to fall out of sync with, and
## nothing outside src/cave/ needs to know the key exists. The scrapbook's "Cave" tab (sky_journal.gd)
## only reads ROSTER, `record_for` and `filled_count`. This file names no other game class on purpose:
## SkyJournal is an autoload and loads whatever it names at boot.
##
## Record: {id, name, grade, grade_idx, craft, day, hour, thumb_b64}. The thumbnail is a small WebP in
## base64 (JSON has no bytes) - the same technique sky_journal.gd and HomeAlbumStore use.

const F_CAVE := "cave_journal"
const THUMB_W := 384
const THUMB_QUALITY := 0.8
const GRADES: Array[String] = ["Smudge", "Fair", "Fine", "Gallery"]

## Every page, in the order the scrapbook shows them. `tier` feeds the safari's rarity (SafariWorld.TIER_RARITY).
## CAVE2 (2026-09-28, 9.4): the grey critters gave way to rainbow ones; ids a save may still hold from
## the first cave (glow_moth, pebble_snail, nook_mouse) are simply no longer pages.
const ROSTER: Array[Dictionary] = [
	{"id": "glow_crystals", "name": "Glow crystals", "tier": "sight"},
	{"id": "prism_moth", "name": "Prism moth", "tier": "creature"},
	{"id": "opal_snail", "name": "Opal snail", "tier": "creature"},
	{"id": "rainbow_beetle", "name": "Rainbow beetle", "tier": "rare"},
	{"id": "glimmer_newt", "name": "Glimmer newt", "tier": "creature"},
	{"id": "star_fossil", "name": "Star fossil", "tier": "rare"},
	{"id": "crystal_pool", "name": "Crystal pool", "tier": "sight"},
	{"id": "meteor_piece", "name": "The meteor piece", "tier": "uncommon"},
	{"id": "drift_jellies", "name": "Drift jellies", "tier": "creature"},
	{"id": "crystal_bloom", "name": "Crystal bloom", "tier": "rare"},
	{"id": "moth_dance", "name": "Moth dance", "tier": "rare"},
	{"id": "aurora_ray", "name": "Aurora ray", "tier": "rare"},
	# CAVE3 (2026-09-28, 9.5 item 6: "more things to photograph" along the halls)
	{"id": "glow_caps", "name": "Glow caps", "tier": "sight"},
	{"id": "pulse_crystals", "name": "Pulse crystals", "tier": "sight"},
	{"id": "lantern_worms", "name": "Lantern worms", "tier": "sight"},
	{"id": "drip_pool", "name": "Drip pool", "tier": "sight"},
	{"id": "peek_mole", "name": "Peek mole", "tier": "creature"},
	{"id": "sleepy_bats", "name": "Sleepy bats", "tier": "creature"},
	{"id": "rainbow_spire", "name": "Rainbow spire", "tier": "uncommon"},
	{"id": "geode", "name": "Rainbow geode", "tier": "uncommon"},
]

## One visit a day, like the safaris (9.4): the game day the last visit STARTED.
const F_VISIT_DAY := "cave_visit_day"
## The treasure chest (9.4): the day its suit was taken. Absent = still closed and full.
const F_CHEST := "cave_chest_found"


static func visited_today() -> bool:
	return int(GameState.flags.get(F_VISIT_DAY, -1)) == GameState.day_count


static func mark_visit() -> void:
	GameState.flags[F_VISIT_DAY] = GameState.day_count


static func chest_found() -> bool:
	return GameState.flags.has(F_CHEST)


## Opens the chest for good: the outfit into the bag (the inventory's Clothes tab, where "Wear" is)
## and the wardrobe, the chest marked found. Idempotent: a second call gives nothing.
static func take_chest(item_id: String) -> bool:
	if chest_found():
		return false
	GameState.flags[F_CHEST] = GameState.day_count
	if not GameState.wardrobe.has(item_id):
		GameState.wardrobe.append(item_id)
	if int(GameState.inventory.get(item_id, 0)) <= 0:
		GameState.add_item(item_id, 1)
	return true


## The cave exists (and its tab shows) once the story is over.
static func unlocked() -> bool:
	return GameState.story_done or count_filled_raw() > 0


static func roster_entry(id: String) -> Dictionary:
	for e: Dictionary in ROSTER:
		if str(e["id"]) == id:
			return e
	return {}


## {} for a blank page.
static func record_for(id: String) -> Dictionary:
	var recs := _records()
	var r: Variant = recs.get(id, {})
	return (r as Dictionary).duplicate(true) if r is Dictionary else {}


static func filled_count() -> int:
	var n := 0
	for e: Dictionary in ROSTER:
		if not record_for(str(e["id"])).is_empty():
			n += 1
	return n


static func count_filled_raw() -> int:
	return _records().size()


## Files one PlanetSafari photo (planet_safari.gd `_photo_record`: subject_key "cave:<id>", grade,
## grade_idx, craft, image). Returns "new" (first page of it), "better" (replaced a worse one),
## "kept" (the page already holds a photo at least as good) or "" (not a cave subject).
static func offer_photo(photo: Dictionary) -> String:
	var key := str(photo.get("subject_key", ""))
	if not key.begins_with("cave:"):
		return ""
	# A kind met in two places is two subjects, one page: "glow_caps@2" files to "glow_caps" (CAVE3).
	var id := key.get_slice(":", 1).get_slice("@", 0)
	if roster_entry(id).is_empty():
		return ""
	var old := record_for(id)
	var gi := int(photo.get("grade_idx", 0))
	var craft := float(photo.get("craft", 0.0))
	if not old.is_empty():
		var ogi := int(old.get("grade_idx", 0))
		if gi < ogi or (gi == ogi and craft <= float(old.get("craft", 0.0))):
			return "kept"
	var rec := {
		"id": id,
		"name": str(roster_entry(id)["name"]),
		"grade": str(photo.get("grade", GRADES[clampi(gi, 0, 3)])),
		"grade_idx": gi,
		"craft": craft,
		"day": GameState.day_count,
		"hour": GameState.time_of_day,
		"thumb_b64": encode_image(photo.get("image")),
	}
	var recs := _records()
	recs[id] = rec
	GameState.flags[F_CAVE] = recs
	return "new" if old.is_empty() else "better"


static func encode_image(img_v: Variant) -> String:
	if not (img_v is Image):
		return ""
	var img := (img_v as Image).duplicate() as Image
	if img.is_empty():
		return ""
	if img.get_width() > THUMB_W:
		var h := maxi(1, int(round(float(img.get_height()) * THUMB_W / float(img.get_width()))))
		img.resize(THUMB_W, h, Image.INTERPOLATE_BILINEAR)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var bytes := img.save_webp_to_buffer(true, THUMB_QUALITY)
	return Marshalls.raw_to_base64(bytes) if not bytes.is_empty() else ""


static func _records() -> Dictionary:
	var v: Variant = GameState.flags.get(F_CAVE, {})
	return (v as Dictionary).duplicate(true) if v is Dictionary else {}
