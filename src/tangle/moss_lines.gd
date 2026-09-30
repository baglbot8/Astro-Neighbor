class_name MossLines
extends RefCounted
## MOSS's voice, in one place so the stall and the swamp-folk keeper cannot drift apart
## (docs/JUNGLE_PLANET_SPEC.md 3, docs/CAST_VOICES_DRAFT.md 2).
##
## WHO: the one resident of The Tangle. A shopkeeper with a character, NOT a neighbour - no favours,
## no project, no friendship, no story part (Gloop's pattern, src/spike/gloop_lines.gd).
## MOSS2 (2026-09-30, docs/JUNGLE_PLANET_SPEC.md 6): Moss is "he", a RETIRED FIELD PHOTOGRAPHER who
## took pictures on every world and came to the Tangle to wait for one very rare sight. What that
## sight is stays his secret (it is not a safari subject - no line here names a real event, so no
## line can go stale when the roster changes). That is why his stall is the CAMERA SHOP: his old
## lenses, and the Hover lesson (HOVER_TAUGHT), next to his swamp finds.
##
## THE VOICE, one row of the CAST_VOICES table:
##   smartness  old and wise about the swamp and about pictures, simple about everything else
##   trait      slow, warm, a little mysterious; loves the swamp; patient - he has waited years
##   habit      "the swamp" talks to Moss ("The swamp says...") - at most one line in four
## Plain whole sentences a 10-year-old follows. No game-system words (no "safari", no "stock", no
## "stardust" in Moss's mouth - the shop panel shows the prices; a safari is "a photo trip"). Every
## line <= 60 characters, checked by `longest()` in the probe.

const NAME := "Moss"
## The name tag matches the model's own cloak moss (MossModel.MOSS).
const ACCENT := Color("#6b8448")
## Fen's comms voice: the slow, wise one. Moss is slow and warm too; a voice of Moss's own would be
## new wavs from tools/gen/audio (not run while other builders work - CLAUDE.md), so this borrows one,
## exactly as Gloop borrows Zorp's ("alien").
const VOICE := "fen"

## First meeting (three boxes, like every neighbour's intro).
const INTRO := [
	"Oh. A visitor. The swamp said you were coming.",
	"I'm Moss. Long ago, I took pictures on every world.",
	"Now I live here, waiting to see one very rare thing.",
]

## The first talk of a new day.
const GREET := [
	"Welcome back, little star-walker.",
	"Ah, you again. Slow down, sit a while.",
	"I watched the trees all night. Still no luck. Hello!",
	"The swamp says good morning to you.",
	"You smell like rocket smoke. Welcome back.",
	"Hello, friend. Taken any good pictures lately?",
]

## Talking again later the same day.
const AGAIN := [
	"Back again? Good. I'm not going anywhere.",
	"Hello again. I'm still watching the trees.",
	"Still here? The Tangle is nice, isn't it?",
]

## The question before the shelf. Answers: SHOP_OPTIONS.
const ASK := "Want to see my lenses and finds?"
const SHOP_OPTIONS := ["Browse", "Bye"]
const ASK_AGAIN := "Anything else catch your eye?"

## After something was bought. `%s` is the item's name.
const BOUGHT := [
	"The %s. Good. It likes you.",
	"Take care of the %s. It is very old.",
	"The %s! The swamp will miss it a little.",
]
## Clothes are put on at once (Suit-Up's rule), so Moss says something about the look instead.
const BOUGHT_WEAR := [
	"Oh, the %s suits you. Very swampy.",
	"Look at you in the %s. Like a lily pad!",
]
## After a lens from his camera bag. `%s` is the lens's name.
const BOUGHT_LENS := [
	"My old %s. It saw a lot. Now it's yours.",
	"The %s! Now your camera holds more pictures.",
]
## The Hover lesson, taught right after it is bought (CameraGoods KIND_LESSON). Once, in order: it is
## the only place the game tells you the jetpack can lift you on a photo trip.
## NOTE for the hover builder: the second line names the JUMP button. If hover ends up on another
## control, change that one line here.
const HOVER_TAUGHT := [
	"Now, a little trick from my picture days.",
	"On a photo trip, tap Hover. Your jetpack lifts you up.",
	"Up high, you see more. Rare things hide from low eyes.",
	"Watch the little meter. When it's empty, you float down.",
]

## GOODS (2026-09-30, docs/JUNGLE_PLANET_SPEC.md 6.1): after Moss's new photo goods.
## The Steady Grip: what it does, once, right after it is bought.
const BOUGHT_GRIP := [
	"My old grip. It kept my hands still for years.",
	"Now you can walk slowly with your camera up.",
]
## The Tripod (the self-timer at home is another builder's).
const BOUGHT_TRIPOD := [
	"My old tripod. Stand it by your home camera.",
	"Start the timer, then jump in the picture!",
]
## A filter. `%s` is the filter's name.
const BOUGHT_FILTER := [
	"The %s. Your home pictures will look lovely.",
	"Ah, the %s. I used that one on every world.",
]
## The Field Notes: said just before he asks which world (FieldNotes.run).
const BOUGHT_NOTES := "Let me open my notebook. The swamp tells me things."
## The extra pill once today's notes are bought (ask again about any world, same day).
const NOTES_OPTION := "Notes"

## Looked, bought nothing.
const JUST_LOOKING := [
	"Nothing today? That's all right.",
	"Just looking is fine. Looking is free.",
]

## Leaving.
const BYE := [
	"Walk slowly. The roots like to trip people.",
	"Come back tomorrow. I'll find new things.",
	"Bye, friend. Keep your eyes open. Rare things are shy.",
	"Mind the puddles on your way out.",
]

## When the panel is missing (no HUD in a test scene).
const NO_SHELF := "My shelf fell in the pond. Try again later."

## THE SAFARI OFFER - for builder J2's `worlds/jungle.gd` MANIFEST (host "moss"), in Moss's voice.
## Not read by this file's code: PlanetSafari.offer_in_conversation speaks the manifest's lines.
const SAFARI_MANIFEST_LINES := {
	"offer": "The Tangle wakes up for three minutes a day.",
	"ask": "Want to take some pictures?",
	"yes": "Go softly. It starts by your rocket.",
	"no": "No hurry. The swamp will wait for you.",
	"asleep": "The Tangle is asleep now. Come back tomorrow.",
}


## A line from `pool`, picked by `key` so a reload does not re-roll it mid-day.
static func pick(pool: Array, key: String) -> String:
	if pool.is_empty():
		return ""
	return str(pool[posmod(key.hash(), pool.size())])


## Longest line in the file (the <= 60 rule), for the probe.
static func longest() -> int:
	var n := 0
	for pool: Array in [INTRO, GREET, AGAIN, BOUGHT, BOUGHT_WEAR, JUST_LOOKING, BYE, HOVER_TAUGHT, [ASK, ASK_AGAIN, NO_SHELF],
			BOUGHT_GRIP, BOUGHT_TRIPOD, [BOUGHT_NOTES]]:
		for l: Variant in pool:
			n = maxi(n, str(l).replace("%s", "Glow-Vine Arch").length())
	for l: Variant in BOUGHT_FILTER:
		n = maxi(n, str(l).replace("%s", "Night Glow Filter").length())
	for l: Variant in BOUGHT_LENS:
		n = maxi(n, str(l).replace("%s", "Zoom Lens Kit").length())
	for l: Variant in SAFARI_MANIFEST_LINES.values():
		n = maxi(n, str(l).length())
	return n
