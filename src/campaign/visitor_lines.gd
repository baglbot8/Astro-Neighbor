extends RefCounted
## What a VISITING neighbour says and brings (src/campaign/visitor_system.gd - read that header first).
## Static data only; nothing here is saved.
##
## WRITING (docs/STYLE_GUIDE.md "Writing"): every line <= 60 characters, 1-3 lines per list, and in that
## neighbour's own voice as their small_talk in src/characters/npc_data.gd has it:
##   Zorp  enthusiastic, curious about Earth, loves floating       Bolt  literal, kind, counts things
##   Fen   terse and weathered, watches the light, keeps a log      Grig  blunt, cuts and numbers steps
##   Vela  formal and warm, hears the sky rather than sees it
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
			"Surprise! I floated over! Your planet is TINY!",
			"I brought my rings. Fly the old course here?",
		],
		"progress_play": ["Keep flying! The rings are very patient!"],
		"done_play": [
			"Every ring, on YOUR planet! Fact: you are great.",
		],
		"ask_gift": [
			"Surprise! I floated over! I brought a present!",
			"Put it somewhere nice. Earth people do that, yes?",
		],
		"progress_gift": ["Did you place it yet? My antenna is fizzing."],
		"again_gift": ["You lost it? I brought a spare. I always do!"],
		"done_gift": ["It looks perfect there! I will tell everyone."],
		"bye": ["I will float here a little longer. Bliss!"],
	},
	"bolt": {
		"ask_play": [
			"Hello. I flew here. One flight. Zero problems.",
			"Some bolts came with me. Please catch them.",
		],
		"progress_play": ["Bolts still airborne. I am counting them."],
		"done_play": ["All caught. Counted. Correct. Thank you."],
		"ask_gift": [
			"Hello. I flew here. I carried one gift.",
			"Please place it. Level ground is best.",
		],
		"progress_gift": ["The gift is not placed yet. I checked twice."],
		"again_gift": ["Gift missing. I brought a spare. I plan ahead."],
		"done_gift": ["Placed. Angle acceptable. Happiness: 91 percent."],
		"bye": ["Visit logged. I will stand here efficiently."],
	},
	"fen": {
		"ask_play": [
			"Your sun climbs so high here. I came to see it.",
			"A few moths followed me. Guide them home?",
		],
		"progress_play": ["Come at them sideways. They run from you."],
		"done_play": ["All home. Noted. Your planet gets a page now."],
		"ask_gift": [
			"Your sun climbs so high here. I came to see it.",
			"I brought you something. Put it where it suits.",
		],
		"progress_gift": ["No hurry. Place it when a spot feels right."],
		"again_gift": ["Lost it? I brought two. I always bring two."],
		"done_gift": ["Good spot. It will catch the evening light."],
		"bye": ["I will sit a while. The light here is kind."],
	},
	"grig": {
		"ask_play": [
			"Your ground has no steps. Odd. Restful, though.",
			"Water hides under here too. Dowse for it.",
		],
		"progress_play": ["Walk slow. Listen for the pulse."],
		"done_play": ["Springs found. Counted twice. Correct."],
		"ask_gift": [
			"Your ground has no steps. Odd. Restful, though.",
			"I brought this. Set it down level. Level.",
		],
		"progress_gift": ["Not placed yet? Pick a flat spot. Then place."],
		"again_gift": ["Lost it? I cut a spare. Mind the corners."],
		"done_gift": ["Level. Well placed. I approve. Mostly."],
		"bye": ["Go on. I am studying your lack of steps."],
	},
	"vela": {
		"ask_play": [
			"Good day. Your planet hums in a lovely key.",
			"Would you answer my signal? Stand in the ring.",
		],
		"progress_play": ["The channel is still open. Do try again."],
		"done_play": ["Received, every signal. Thank you, truly."],
		"ask_gift": [
			"Good day. Your planet hums in a lovely key.",
			"I brought a gift. Place it wherever you like.",
		],
		"progress_gift": ["No hurry at all. The gift will wait for you."],
		"again_gift": ["Misplaced? I brought a second. Here you are."],
		"done_gift": ["It sits beautifully there. I shall log it."],
		"bye": ["I shall listen to your sky a while longer."],
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
