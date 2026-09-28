class_name PhotoMode
extends RefCounted
## THE PHOTO-MODE GATE (docs/PLANET_SAFARI_SPEC.md 5.3, 7). Written by the lead so every system
## that must step aside during a planet safari reads ONE switch instead of each inventing its own.
## The safari system turns it on and off; the HUD pills, compass pips, "!" markers, mini-game pill,
## journal buttons and J keys read `PhotoMode.active` and hide while it is true. The stick and
## drag-to-look are NOT gated: the player keeps walking and looking.

static var active: bool = false
## Which planet the running safari belongs to ("" when none).
static var planet_id: String = ""


static func begin(planet: String) -> void:
	active = true
	planet_id = planet


static func end() -> void:
	active = false
	planet_id = ""
