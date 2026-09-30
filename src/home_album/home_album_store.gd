class_name HomeAlbumStore
extends RefCounted
## THE HOME ALBUM'S STORAGE (docs/STORY_HOME_SPEC.md 8.1, builder HOMEALBUM 2026-09-27).
##
## A separate, freeform photo album for the player's OWN home planet, taken any time - no life or
## event system, no film limit, no score, no quest. Up to MAX_PHOTOS; nothing is ever auto-replaced
## (unlike the planet-safari scrapbook's one-best-shot-per-subject slot in sky_journal.gd). When the
## album is full the caller (home_album_camera.gd) must delete a photo first - `add_photo` refuses
## and warns rather than silently overwriting anything.
##
## STATIC AND STATELESS ON PURPOSE: every call reads/writes straight through to
## `GameState.flags[F_HOME_ALBUM]`, the same "a Dictionary this autoload keeps" idiom
## planet_safari's own journal uses for its flags (sky_journal.gd F_JOURNAL/F_PLANET) - so there is
## no separate in-memory copy to fall out of sync with a reload, and `GameState.from_dict` (a file
## this builder does not own) never needs to know this key exists.
##
## IMAGES: the same technique sky_journal.gd already uses for its own scrapbook thumbnails
## (`_encode_planet_thumb` / `_decode_planet_thumb`) - a small WebP, base64, living inside the JSON
## save, because JSON has no bytes of its own. Re-implemented here rather than called on SkyJournal
## so this builder's files stay self-contained (SkyJournal is owned elsewhere except for its one new
## "Home" section, which reads this store's records directly).

const MAX_PHOTOS := 25
const F_HOME_ALBUM := "home_album"
const F_SEQ := "home_album_seq"

## The stored thumbnail's width; a captured frame taller/wider than this is downsized before it is
## ever kept, so 25 photos cost the save file kilobytes, not megabytes.
const THUMB_W := 480
const THUMB_LOSSY := true
const THUMB_QUALITY := 0.82


## Every photo, oldest first, as {id, thumb_b64, day, hour} (+ "filter" once one was chosen). Duplicated so a caller can freely
## mutate its own copy.
static func list() -> Array:
	var out: Array = []
	for r in _raw_records():
		if r is Dictionary:
			out.append((r as Dictionary).duplicate(true))
	return out


static func count() -> int:
	return _raw_records().size()


static func is_full() -> bool:
	return count() >= MAX_PHOTOS


## {} for an id the album does not hold.
static func get_photo(id: String) -> Dictionary:
	for r: Dictionary in list():
		if str(r.get("id", "")) == id:
			return r
	return {}


## Adds `img` as a new photo. Returns its new id, or "" (and a warning) when the album is already
## full - the caller must throw one away first (spec 8.1: "the player picks an old photo to throw
## away before the new one saves"), or the image failed to encode.
static func add_photo(img: Image) -> String:
	if is_full():
		push_warning("HomeAlbumStore.add_photo: the album already holds %d; delete one first" % MAX_PHOTOS)
		return ""
	var b64 := encode_image(img)
	if b64 == "":
		push_warning("HomeAlbumStore.add_photo: the image failed to encode; nothing saved")
		return ""
	var id := _next_id()
	var recs := _raw_records().duplicate(true)
	recs.append({
		"id": id,
		"thumb_b64": b64,
		"day": GameState.day_count,
		"hour": GameState.time_of_day,
	})
	GameState.flags[F_HOME_ALBUM] = recs
	return id


## FILTERS (docs/JUNGLE_PLANET_SPEC.md 6.1, builder HOMECAM 2026-09-30): one look per photo, stored as
## the record's "filter" id beside the untouched `thumb_b64` - the original is always kept, and the
## look is drawn on top (HomeAlbumFilters). "" (or a record from before filters existed) is no filter.
static func get_filter(rec: Dictionary) -> String:
	var f := str(rec.get("filter", ""))
	return f if HomeAlbumFilters.is_known(f) else ""


## Sets photo `id`'s filter ("" clears it). False for an unknown photo or filter id. Ownership is
## the caller's check (the album only offers owned filters); this only refuses ids it cannot draw.
static func set_filter(id: String, filter_id: String) -> bool:
	if id == "" or not HomeAlbumFilters.is_known(filter_id):
		return false
	var recs := _raw_records().duplicate(true)
	for r in recs:
		if r is Dictionary and str((r as Dictionary).get("id", "")) == id:
			(r as Dictionary)["filter"] = filter_id
			GameState.flags[F_HOME_ALBUM] = recs
			return true
	return false


## True when a photo with that id existed and was removed.
static func delete_photo(id: String) -> bool:
	if id == "":
		return false
	var recs := _raw_records()
	var kept: Array = []
	var found := false
	for r: Dictionary in recs:
		if str(r.get("id", "")) == id:
			found = true
		else:
			kept.append(r)
	if found:
		GameState.flags[F_HOME_ALBUM] = kept
	return found


## Deletes every id in `ids` (extras or unknown ids are ignored). Returns how many were removed -
## the scrapbook's bulk "Delete selected" (spec 8.1: "a way to clear out photos in bulk").
static func delete_many(ids: Array) -> int:
	var wanted: Dictionary = {}
	for i in ids:
		wanted[str(i)] = true
	var recs := _raw_records()
	var kept: Array = []
	var removed := 0
	for r: Dictionary in recs:
		if wanted.has(str(r.get("id", ""))):
			removed += 1
		else:
			kept.append(r)
	GameState.flags[F_HOME_ALBUM] = kept
	return removed


## Empties the whole album. Returns how many photos were in it.
static func clear_all() -> int:
	var n := count()
	GameState.flags[F_HOME_ALBUM] = []
	return n


## Image -> a small WebP, base64 (see the header). "" when there is nothing to encode.
static func encode_image(img_v: Variant) -> String:
	if not (img_v is Image):
		return ""
	var img := (img_v as Image).duplicate() as Image
	if img.is_empty():
		return ""
	if img.get_width() > THUMB_W:
		var h := maxi(1, int(round(float(img.get_height()) * THUMB_W / float(maxi(img.get_width(), 1)))))
		img.resize(THUMB_W, h, Image.INTERPOLATE_BILINEAR)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	var bytes := img.save_webp_to_buffer(THUMB_LOSSY, THUMB_QUALITY)
	if bytes.is_empty():
		return ""
	return Marshalls.raw_to_base64(bytes)


## The decoded photo, or null (a corrupt/empty record - shown as a blank card by the caller).
static func decode_image(rec: Dictionary) -> Image:
	var b64 := str(rec.get("thumb_b64", ""))
	if b64 == "":
		return null
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var err := img.load_webp_from_buffer(bytes)
	return img if err == OK and not img.is_empty() else null


static func _raw_records() -> Array:
	var raw: Variant = GameState.flags.get(F_HOME_ALBUM, [])
	return raw if raw is Array else []


## A counter kept beside the records (F_SEQ), not derived from the clock or from the array's own
## size - a clock has second resolution (two shots in the same second would collide) and the size
## repeats an id after a delete. Never reset, so an id is unique for the life of the save.
static func _next_id() -> String:
	var seq := int(GameState.flags.get(F_SEQ, 0)) + 1
	GameState.flags[F_SEQ] = seq
	return "home_%d" % seq
