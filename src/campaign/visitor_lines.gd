extends RefCounted
## What a VISITING neighbour says and brings (src/campaign/visitor_system.gd - read that header first).
## Static data only; nothing here is saved.
##
## WRITING (docs/STYLE_GUIDE.md "Writing"): every line <= 60 characters, 1-3 lines per list, and in that
## neighbour's own voice (docs/CAST_VOICES_DRAFT.md, approved 2026-09-27, with STORY_HOME_SPEC.md 8.1):
##   Zorp  quirky, excitable grandpa gardener ("Oh ho!")   Bolt  literal fix-it robot; the ONLY one who counts
##   Fen   young, calm, sunny flower (sun and water)        Grig  grumpy stair carver, soft inside ("Hmph.")
##   Vela  gentle, shy lightbulb (he); says when he glows
## No line names a key or a button: the player may be on a phone. The one control a line needs (the bag,
## to place a gift) is named by visitor_system.gd through MobileUI.bag_hint(), outside these tables.
##
## Keys per neighbour:
##   ask_play       the first talk of a PLAY visit (their mini-game, on your planet)
##   progress_play  a talk while that game is still going
##   done_play      the talk that hands it in
##   ask_gift       the first talk of a GIFT visit; the gift is handed over right after these lines
##   progress_gift  a talk while the gift is not standing on your planet yet
##   again_gift     that talk, when the gift is not in the bag either (dropped): a spare is handed over
##   done_gift      the talk after it is placed
##   bye            any later talk the same day, once the visit is done

const LINES := {
	"zorp": {
		"ask_play": [
			"Surprise! I flew over! Your planet is so small!",
			"I brought my rings. Fly the old river path here?",
		],
		"progress_play": ["Keep flying! The rings will wait for you!"],
		"done_play": ["Every ring, on YOUR planet! Oh ho, well done!"],
		"ask_gift": [
			"Surprise! I flew over! I brought a present!",
			"Put it somewhere nice. Somewhere sunny, maybe.",
		],
		"progress_gift": ["Did you put it out yet? My moustache is twitching."],
		"again_gift": ["Lost it? I brought a spare. I always do!"],
		"done_gift": ["It looks perfect there! I'll tell everyone."],
		"bye": ["I'll sit here a little longer. Lovely spot!"],
	},
	"bolt": {
		"ask_play": [
			"Hello. I flew here. 1 flight. 0 problems.",
			"Some bolts came with me. Please catch them.",
		],
		"progress_play": ["The bolts are still flying. I am counting."],
		"done_play": ["You caught them all. I counted. Thank you."],
		"ask_gift": [
			"Hello. I flew here. I brought 1 gift.",
			"Please put it down. Flat ground is best.",
		],
		"progress_gift": ["The gift is not out yet. I checked twice."],
		"again_gift": ["The gift is missing? I brought a spare."],
		"done_gift": ["Good spot. I am 91 percent happy. That is a lot."],
		"bye": ["I will stand here now. Standing is my hobby."],
	},
	"fen": {
		"ask_play": [
			"Your sun climbs so high here! I came to see it.",
			"A few moths followed me. Guide them home?",
		],
		"progress_play": ["Come at them sideways. They're a bit shy."],
		"done_play": ["All home! Thank you. Your planet is lovely."],
		"ask_gift": [
			"Your sun climbs so high here! I came to see it.",
			"I brought you something. Put it somewhere sunny.",
		],
		"progress_gift": ["No hurry. Put it where it feels right."],
		"again_gift": ["Lost it? That's okay. I brought another one."],
		"done_gift": ["Good spot! It'll get lots of sun there."],
		"bye": ["I'll sit in your sun a while. It's so warm."],
	},
	"grig": {
		"ask_play": [
			"Your ground has no stairs. Odd. Restful, though.",
			"Water hides under here too. Let's find it.",
		],
		"progress_play": ["Walk slow. Feel for the pulse."],
		"done_play": ["Found them all. Good work. Hmph."],
		"ask_gift": [
			"Your ground has no stairs. Odd. Restful, though.",
			"I brought this. Put it on flat ground.",
		],
		"progress_gift": ["Not out yet? Pick a flat spot. Then put it down."],
		"again_gift": ["Lost it? Hmph. I made a spare. Here."],
		"done_gift": ["Flat. Neat. I like it. Mostly."],
		"bye": ["Go on. I'm just looking at your ground."],
	},
	"vela": {
		"ask_play": [
			"Hello. Your planet hums a pretty tune.",
			"Want to answer my calls? Stand in the ring.",
		],
		"progress_play": ["The signal is still open. Try again?"],
		"done_play": ["You answered them all! Thank you. I'm glowing."],
		"ask_gift": [
			"Hello. Your planet hums a pretty tune.",
			"I brought a gift. Put it anywhere you like.",
		],
		"progress_gift": ["No hurry at all. The gift will wait."],
		"again_gift": ["Lost it? Oh, that's okay. I brought another."],
		"done_gift": ["It looks lovely there. My bulb flickered."],
		"bye": ["I'll listen to your sky a little longer."],
	},
}

## What each neighbour brings on a GIFT visit: existing shop decorations (src/decorations/
## decoration_catalog.gd), never a price-0 legendary (those are FavorSystem.SIGNATURE_REWARD) and never a
## project item. Why each suits them:
##   zorp  Floating Orb Light ("refuses to touch its own stand": he floats for hours), Alien Plant Pot
##         (his own plant "grew sideways"), Crystal Cluster Lamp (his world is crystals; he named one
##         after you)
##   bolt  Supply Crate (tidy, countable), Control Console ("every button blinks": a machine to
##         maintain), Wayfinder Signpost ("points two ways at once, twice as helpful" - literal)
##   fen   Moon Lamp (light, from the man who lives in a dusk that never ends), Crater Bench (he tells
##         everyone to sit)
##   grig  Oxygen Tank Planter (a garden that needs little water), Moon Rock Garden (raked, ordered)
##   vela  Satellite Dish ("listens patiently to the whole sky"), Star Projector (the sky, indoors)
const GIFTS := {
	"zorp": ["deco_orb_light", "deco_alien_plant_pot", "deco_crystal_lamp"],
	"bolt": ["deco_supply_crate", "deco_control_console", "deco_signpost"],
	"fen": ["deco_moon_lamp", "deco_crater_bench"],
	"grig": ["deco_oxygen_planter", "deco_moon_rock_garden"],
	"vela": ["deco_satellite_dish", "deco_star_projector"],
}

## A short noun for the progress status line, per game kind ("(2 of 3 caught.)").
const STATUS_VERBS := {
	"catch": "caught", "rings": "flown", "guide": "home", "hunt": "found", "call": "answered",
}


static func lines(npc_id: String, key: String) -> Array:
	var per: Dictionary = LINES.get(npc_id, {})
	return (per.get(key, []) as Array).duplicate()
