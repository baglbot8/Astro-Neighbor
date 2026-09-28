class_name SkyPrint
extends RefCounted
## SPIKE ROUND 2 (2026-09-20, scratch only). What a good look through the telescope leaves you
## holding.
##
## A print is DATA plus a small preview image. The image is not painted by hand: it is the real
## eyepiece shader rendered into a 256x256 SubViewport at the sharpness you actually held, so a
## soft print LOOKS soft on the card. See SkyWatch._render_preview().
##
## ROUND 2: WHAT A PRINT IS FOR CHANGED. The user, 2026-09-20: "should we have taking photos more
## important than just giving you money?" So the two halves now do different jobs and are never
## mixed into one score the player has to decode:
##
##   RARITY    1..3, from the forecast. This is the COIN. Gloop prices a copy on it.
##   SHARPNESS 0..1, what you held at the eyepiece. This is the PRIZE. It sets the grade, it is what
##             the journal keeps its best-per-sight on, and it is what a neighbour reacts to when
##             you give them one for their wall.
##
## `quality` (sharpness x rarity) is still here because Gloop's table already prices on it, but it
## is no longer what the card shouts and no longer what sets the grade.
##
## TRAVEL IS IN THE SHARPNESS, NOT A BONUS. Round 1 gave a +12% nudge for being on the right world,
## which the reviewer measured as "the trip buys 12%" - finding 4. It is now a CEILING instead: off
## the world the forecast names, the air, the angle and the distance cap you at OFF_WORLD_CAP, so
## Fine and Gallery are things you can only bring back from the trip. Nothing is added anywhere;
## one rule, no free parameter beyond the cap itself.

## Grades are on SHARPNESS now, not on sharpness x rarity.
const GRADES := ["Smudge", "Fair", "Fine", "Gallery"]
const GRADE_FAIR := 0.35
const GRADE_FINE := 0.60
const GRADE_GALLERY := 0.82

## The best sharpness a print can have when you did NOT travel to the world the forecast names.
## Below GRADE_FINE on purpose: from home you can get a Fair print of anything, and nothing better.
const OFF_WORLD_CAP := 0.58

var event_id := ""
var title := ""
var kind := 0
var world := ""
var day := 0
var hour := 0.0
var rarity := 1
var sharpness := 0.0
var quality := 0.0
var grade := "Smudge"
var on_world := false
## 0..1. How full the plate was when the shutter closed. A short exposure is grainy, and its grain
## has already been taken out of `sharpness` by SkyWatch before this is built.
var exposure := 0.0
## Real seconds the player spent at the eyepiece on this sight. For the report, not for scoring.
var seconds := 0.0
## WIRE (2026-09-21). THE MOMENT, in words: "one turns and looks back at you". A safari catch can
## have one; a tripod print never does, so this is "" for every telescope print and nothing that
## reads it has to branch. It is deliberately NOT in `quality` and NOT in the price — the moment is
## the prize, rarity is the coin (see this header's RARITY/SHARPNESS split).
var moment := ""
## True only for a plate that was ruined. A failed watch does NOT make a SkyPrint at all in the
## spike, so this stays false; it exists so a caller can branch without knowing that.
var failed := false
## WIRE (2026-09-21). The moment multiplier the shutter caught, 1.0 for a tripod print and for a
## safari catch with no moment open. Carried so Gloop's table can price a copy with SafariScoring
## without re-deriving it from the words in `moment`.
var moment_mult := 1.0
## True only for a print made by a safari flight. The one thing that tells Gloop's table which
## pricing rule this print belongs to (see print_bag.gd `pay_for`); nothing else branches on it.
var from_safari := false
var preview: Image


## Builds a print. `held_sharpness` is what SkyWatch measured over the exposure. `watched_on_world`
## is whether you were standing on the world the forecast named.
static func make(ev: Dictionary, held_sharpness: float, watched_on_world: bool, day_n: int,
		hour_n: float, exposure_frac: float = 1.0, secs: float = 0.0) -> SkyPrint:
	var p := SkyPrint.new()
	p.event_id = str(ev.get("id", ""))
	p.title = str(ev.get("title", "A sight"))
	p.kind = int(ev.get("kind", 0))
	p.world = str(ev.get("world", ""))
	# WIRE (2026-09-21): FOUR rungs. The catalog's six best sights are rarity 4 ("Hardly ever") and
	# this clamp priced and labelled every one of them as a plain rare.
	p.rarity = clampi(int(ev.get("rarity", 1)), 1, 4)
	p.day = day_n
	p.hour = hour_n
	p.on_world = watched_on_world
	p.exposure = clampf(exposure_frac, 0.0, 1.0)
	p.seconds = secs
	var s := clampf(held_sharpness, 0.0, 1.0)
	if not watched_on_world:
		s = minf(s, OFF_WORLD_CAP)
	p.sharpness = s
	p.quality = s * float(p.rarity)
	p.grade = grade_for(s)
	return p


## SHARPNESS -> a word. Rarity does not enter: a perfectly held common sight is a Gallery print and
## a rare one you fumbled is a Smudge. The rare one still pays more; it is just not better WORK.
static func grade_for(sharp: float) -> String:
	if sharp < GRADE_FAIR:
		return GRADES[0]
	if sharp < GRADE_FINE:
		return GRADES[1]
	if sharp < GRADE_GALLERY:
		return GRADES[2]
	return GRADES[3]


## PLACEHOLDER price, kept from round 1 so the card is not blank. Money is Gloop's file; the real
## number is PrintBag.pay_for(). Gloop sells a COPY - the print itself stays in your journal.
func sale_hint() -> int:
	return int(round(8.0 + 46.0 * ((float(rarity) - 1.0) / 2.0) + 30.0 * sharpness))


func sharpness_text() -> String:
	return "%d%%" % int(round(sharpness * 100.0))


## One line under 60 characters, for a toast or a neighbour.
func short_line() -> String:
	var t := title
	if t.length() > 30:
		t = t.substr(0, 29).strip_edges() + "."
	return "%s - %s, %s" % [grade, t, sharpness_text()]


func summary() -> String:
	return "%s - %s, sharpness %s, rarity %d, exposure %d%%, %.1fs, quality %.2f" % [
		grade, title, sharpness_text(), rarity, int(round(exposure * 100.0)), seconds, quality]
