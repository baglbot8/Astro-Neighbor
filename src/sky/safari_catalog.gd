class_name SafariCatalog
extends RefCounted
## THE ONE SIGHT TABLE. Everything worth photographing out of the porthole, and nothing else.
## 51 sights, one id space.
##
## SAFARI6 WAVE 2 (2026-09-22) CHANGED EXACTLY ONE FIELD IN THIS TABLE: `lanes`, on 30 of the 51
## sights. Nothing else moved - not a weight, not a gate, not a word, not a moment, not a shape.
##
## WHY. A run is 16-18 sights now instead of 6-7 (spec 6.3). Four lanes had 11 to 13 sights in
## their whole roster and eight to twelve of those were ungated, so a 16-sight run would simply
## have run out: the draw would have emitted a short cast and the sky would have gone empty again,
## which is the thing this round exists to stop. Measured, before -> after, ungated rarity-1-or-2
## sights per lane: lantern 10->15, commons 11->16, ringgap 8->22, chalk 12->16, dusk 9->15,
## frost 9->16, longhome 9->19, outerdark 10->18. Rosters 11-18 -> 22-30.
##
## THE RULE THE 30 CHANGES FOLLOW, so a reader can check them rather than trust them:
##   1. ONLY RARITY 1 AND 2 MOVED. Every rarity-3 and rarity-4 sight keeps the lane list its
##      author gave it, because a rare's membership IS its rarity. Measured over 800 runs with
##      every hint heard and five parts: a rarity-4 sight is in the cast in 16.4% of runs against
##      the old build's 18.0%, and in 0.0% of runs untold, both before and after.
##   2. A SIGHT TIED TO A WORLD ONLY GOES ON LANES THAT TOUCH THAT WORLD. Fen's pools, Fen's
##      lamps, Fen's shadow line and Fen's swifts went onto the three other lanes that fly to Fen
##      (the Ring Gap, the Outer Dark, the Long Way Home) and nowhere else. Grig's pebble moons,
##      Vela's lamps, Bolt's ring ice and yard lights, Zorp's moon rim: the same rule.
##   3. A SIGHT TIED TO NOTHING GOES EVERYWHERE. Twelve are: the lantern-fish, the driftlings,
##      the slow snow, the mail run, the frost flowers, the moths, Comet Thistle, the minnows, the
##      kettle, the mail hulk, the sun-sail. A lantern-fish that "drifts the whole way" had no
##      business being barred from four lanes.
##   4. THE FLAVOUR BARS ARE KEPT AND TWO WERE ADDED. No moon sight is on the Long Dusk Drift
##      (fen.tres: moon_count 0) - which is why `crumb_moon` is on seven lanes and not eight. No
##      sun sight is on the Outer Dark (vela.tres: sun_disc_size 0.011) - which is why `star_wind`
##      is on seven. `mirror_moon` LOST the Commons and `tower_swifts` lost the Lantern Lane and
##      the Commons, because Vela's moon and Fen's towers have no business on the inner triangle.
##   5. EVERY SIGNATURE IS STILL ON EXACTLY ONE LANE. SafariLanes.check() refuses otherwise.
##
## WHAT THIS COSTS, SAID PLAINLY: the eight lanes share far more stock than they did. Lane
## character is now carried by the two signatures, by the five weighted favourites in
## safari_lanes.gd's `w`, by the two world limbs and by the segment backdrops - not by what is
## barred. A critic who thinks the lanes now read the same is measuring something real.
##
## WHY THIS FILE CHANGED. Three builders wrote the safari's content in one night and wrote TWO
## systems by accident: this table and `safari_lanes.gd` disagreed on five of eight lane ids, and
## their two sight vocabularies shared 2 ids out of 81. The lead's ruling: keep the LANES file's
## eight lanes, ids and pair coverage; keep THIS file's 51 sights as the one sight table; delete
## the lanes file's private sight copies. So:
##
##   safari_lanes.gd  owns the eight lanes, the trip -> lane lookup, the sky geometry (where in
##                    the porthole a slot points), the run's clock, and THE DRAW.
##   this file        owns what a sight IS: its words, its shape, its rarity, its gates, its
##                    moments, its hint. It knows lane ids as plain strings and nothing else.
##
## The dependency runs ONE WAY: lanes calls catalog. Nothing here imports SafariLanes, so the two
## can never build a cycle of consts again.
##
## WHAT IS IN A SIGHT
##   id / name / kind / rarity          what it is and what the journal files it under.
##   blurb / silhouette                 the haul-card line, and what the journal shows BEFORE you
##                                      catch it: a shape and a rumour, never the answer. <= 60.
##   draw                               ONE OF THE SIX SHAPES THE EYEPIECE ACTUALLY DRAWS. See
##                                      DRAW below. There are no others and none were added.
##   moments                            2-3 things it can be caught DOING, each with a multiplier
##                                      and its own line. Windows are NORMALISED (u0..u1 across
##                                      the sight's window) so the lane owns the clock.
##   lanes / hours / dir / days /       the GATES. All hard. Fail one and the sight is not out
##   needs_hint / needs_story           there tonight. `lanes` is the whole of "which lane can
##                                      show this": a lane with one entry is that lane's own.
##   hint_npc / hint_line               ONLY on a `needs_hint` sight: who tells you, and what
##                                      they say, <= 60 chars, in that neighbour's voice. The
##                                      wiring round reads these off the sight; sky_hints.gd is
##                                      not edited by this round.
##   weight / boost                     the LIKELIHOOD once the gates pass.
##
## WHAT IS SYNTHETIC HERE, SAID PLAINLY
##   * NOTHING IN THIS FILE HAS BEEN FLOWN OR RENDERED. Every sight is data. The numbers in the
##     report come from tools/safari_selftest.gd run headless, not from a frame and not from a
##     phone. No screenshot of any of these 51 sights exists.
##   * `weight`, the moment multipliers and `hold_sec` are still first guesses by their authors.
##     They have been re-checked for CONSEQUENCES (coverage, the clash, the payout band) and not
##     for feel.
##   * Every sight now names one of the six shapes in safari_eyepiece.gdshader. 24 of the 51 used
##     to name `curtain`, `glow` or `cloth`, which the shader does not have and this round is not
##     allowed to add (safari_eyepiece.gdshader belongs to another round tonight). Each of those
##     24 carries a `# RECAST to ...` line saying what it became and why.
## ALL STATIC. No state, no autoload, nothing to save.

const CATALOG_VERSION := 1

# ------------------------------------------------------------------ lanes
## THE EIGHT LANE IDS, and nothing else about them. safari_lanes.gd owns their names, their
## planet pairs, their moods and their geometry; this file only ever needs to know that a lane id
## it writes into a sight's `lanes` list is one of these eight. Listed here (rather than read off
## SafariLanes) so this file has no dependency at all on that one - the arrow points one way.
## tools/safari_selftest.gd proves this list and SafariLanes.LANES.keys() are the same eight.
const LANE_IDS := ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome",
	"outerdark"]

## Direction of travel, which is how "certain rare events only happen on certain directions" gets
## in without 42 routes. Same three words SafariLanes.direction_of() returns: "out" is deeper from
## home, "in" is homeward, "cross" is same-depth. A sight that says "out" or "in" is barred on the
## other one; "cross" trips only carry the ungated sights, which is why a hop between two inner
## worlds is the plainest sky in the game.
const DIR_ANY := "any"
const DIR_OUT := "out"
const DIR_IN := "in"

# ------------------------------------------------------------------ kinds and shapes
## What the journal files a sight under. Player-facing words.
const KINDS := {
	"creature": "Creature",
	"comet": "Comet",
	"aurora": "Lights",
	"wreck": "Wreck",
	"moon": "Moon",
	"ice": "Ice",
	"light": "A light",
	"weather": "Weather",
}

## THE SIX SHAPES, and the branch number each one is in safari_eyepiece.gdshader's `shape()`.
## These ARE the shader: kind 0 is the comet branch, 1 the drift pod, 2 the ice chunks, 3 the
## derelict hull, 4 the moon rim, and anything else falls to the limb branch, which is 5.
## NO SHAPE WAS ADDED. This round is not allowed to touch the shader (another round owns it
## tonight), so every sight that used to name `curtain`, `glow` or `cloth` was re-cast onto one of
## these six instead - see the `# RECAST` notes in the table.
const DRAW := {"comet": 0, "pod": 1, "ice": 2, "derelict": 3, "moonrim": 4, "limb": 5}

## SHAPES ROUND (2026-09-21). `draw` is now only HALF of how a sight looks. src/sky/safari_shapes.gd
## carries twelve more numbers per sight - counts, sizes, amplitudes and one rotation - which is
## what makes an aurora, a lamp line, a fog bank and a heat shimmer four different pictures on
## this one `limb` branch instead of four tints of the same curtains. Three sights changed `draw`
## in that round and the change is recorded here AND there: still_pools ice->limb,
## sun_dogs ice->comet, barnacle_calf ice->pod. Nothing else in this file was touched.

## The eyepiece holds THREE subjects at once (safari_eyepiece.gdshader: `uniform int n_subj :
## hint_range(0, 3)`, and safari_run.gd's `for i in 3`).
##
## SAFARI6 WAVE 2, AND READ THIS BEFORE BELIEVING tools/safari_selftest.gd's ITEM 2. That item
## counts OVERLAPPING WINDOWS and calls the result "on the glass". It is not the same thing: a
## slot is only taken by a sight within 1.65 score units (11.55 degrees) of the crosshair
## (safari_run.gd:1012), and the run now deliberately puts three sights up at once on opposite
## sides of the ship (spec S6). MEASURED the right way, over all eight lanes at four hours, every
## 0.5 s, against a grid of 36 azimuths x 3 elevations covering the whole reachable sky
## (tools/g3_probe.gd): THE MOST SIGHTS EVER INSIDE THE 11.55-DEGREE DRAW DISC AT ONE INSTANT IS
## TWO. The flight's own accounting agrees from the other side - a real 168 s autopilot run on the
## Compatibility renderer printed "mark slots overflowed for 0.00 sight-seconds".
##
## So this constant is still right and item 2's failure is item 2's. Flagged to the lead; the
## self-test is not G3's file.
const MAX_ON_GLASS := 3

## rarity 1..4. The old file stopped at 3; the hinted rares needed a rung above "Rare", and
## safari_scoring.gd now pays for all four.
const RARITY_NAMES := ["", "Common", "Uncommon", "Rare", "Hardly ever"]

## Half the glass's field of view, degrees. Unchanged from safari_cast.gd so the two agree.
const FIELD_HALF_DEG := 7.0

# ------------------------------------------------------------------ the cast
## 51 sights. Everyday first, then weekly, then rare, then the hinted ones.
##
## `weight` is a plain draw weight. As a rule of thumb the author used: 100 = you see it most
## trips on its lane, 45 = about weekly, 14 = rare, 4 = hardly ever. Untested.
const SIGHTS: Array = [

	# ---------------------------------------------------------- everyday (rarity 1)
	{
		"id": "lantern_fish", "name": "Lantern-fish, drifting between worlds",
		"kind": "creature", "draw": "pod", "rarity": 1, "weight": 110,
		"blurb": "They drift the whole way. No hurry at all.",
		"silhouette": "A line of soft dots, blinking out of step.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.52, "scale": 1.10, "hold_sec": 1.6,
		"tint_a": "#9be8d0", "tint_b": "#cfe0ff", "boost": {"night": 1.4, "dusk": 1.2},
		"moments": [
			{"u0": 0.30, "u1": 0.52, "mult": 1.5, "line": "one blinks in time with your lamp"},
			{"u0": 0.66, "u1": 0.84, "mult": 1.8, "line": "the whole school turns at once"},
		],
	},
	{
		"id": "driftlings", "name": "A pod of driftlings",
		"kind": "creature", "draw": "pod", "rarity": 1, "weight": 100,
		"blurb": "Five of them, riding the lane the way you are.",
		"silhouette": "Five round shapes, keeping pace with something.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.55, "scale": 1.10, "hold_sec": 2.0,
		"tint_a": "#9be8d0", "tint_b": "#cfe0ff", "boost": {},
		"moments": [
			{"u0": 0.38, "u1": 0.62, "mult": 2.0, "line": "one turns and looks back at you"},
			{"u0": 0.78, "u1": 0.94, "mult": 1.3, "line": "the pod closes up tight"},
		],
	},
	{
		"id": "home_aurora", "name": "Home's own lights, from above",
		"kind": "aurora", "draw": "limb", "rarity": 1, "weight": 105,
		"blurb": "You have never seen your lights from outside.",
		"silhouette": "A bright edge with something waving over it.",
		"lanes": ["lantern"], "hours": [18.0, 6.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.18, "scale": 1.35, "hold_sec": 1.2,
		"tint_a": "#6fd8a8", "tint_b": "#a87cf2", "boost": {},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.5, "line": "the curtain folds over itself"},
			{"u0": 0.70, "u1": 0.88, "mult": 1.7, "line": "it lights up your own back garden"},
		],
	},
	{
		"id": "dust_veil", "name": "Home's dust veil, lit edge-on",
		"kind": "weather", "draw": "limb", "rarity": 1, "weight": 105,
		"blurb": "Daylight through thin air, seen from the side.",
		"silhouette": "A bright edge with a haze standing off it.",
		"lanes": ["lantern", "longhome"], "hours": [6.0, 18.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.18, "scale": 1.35, "hold_sec": 1.2,
		"tint_a": "#ffcf96", "tint_b": "#ef85bc", "boost": {},
		"moments": [
			{"u0": 0.30, "u1": 0.54, "mult": 1.5, "line": "the veil flares as you cross it"},
			{"u0": 0.72, "u1": 0.90, "mult": 1.4, "line": "your own shadow crosses the haze"},
		],
	},
	{
		"id": "zorp_moon_rim", "name": "First light on Zorp's little moon",
		"kind": "moon", "draw": "moonrim", "rarity": 1, "weight": 95,
		"blurb": "You arrive with the morning. So does it.",
		"silhouette": "A dark circle with one bright edge.",
		"lanes": ["lantern", "commons", "chalk", "frost"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 1.00, "scale": 1.20, "hold_sec": 1.4,
		"tint_a": "#f2e2c4", "tint_b": "#b9c4d8", "boost": {"dawn": 1.6},
		"moments": [
			{"u0": 0.40, "u1": 0.72, "mult": 1.4, "line": "the rim catches fire"},
			{"u0": 0.80, "u1": 0.95, "mult": 1.2, "line": "a violet river shows through"},
		],
	},
	{
		"id": "ring_ice", "name": "Through the gap in Bolt's ring",
		"kind": "ice", "draw": "ice", "rarity": 1, "weight": 115,
		"blurb": "Ice the size of houses, going the other way.",
		"silhouette": "Tumbling blocks, all in one flat plane.",
		"lanes": ["ringgap", "commons", "lantern"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.25, "scale": 1.40, "hold_sec": 1.3,
		"tint_a": "#dfe6f2", "tint_b": "#cfbb96", "boost": {},
		"moments": [
			{"u0": 0.28, "u1": 0.50, "mult": 1.6, "line": "one tumbles end over end"},
			{"u0": 0.64, "u1": 0.86, "mult": 1.5, "line": "two of them knock and spin apart"},
		],
	},
	{
		"id": "chrome_dust", "name": "Chrome dust off Bolt's yard",
		"kind": "weather", "draw": "ice", "rarity": 1, "weight": 90,
		"blurb": "Filings from the yard, catching the light.",
		"silhouette": "A thin bright smear, drifting sideways.",
		"lanes": ["commons", "ringgap", "chalk", "lantern"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.35, "scale": 1.25, "hold_sec": 1.4,
		"tint_a": "#cfd8e6", "tint_b": "#ffcf96", "boost": {"day": 1.3},
		# RECAST to `ice`: filings catching the light are four lit, hard-edged bodies.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.4, "line": "the whole cloud turns silver at once"},
			{"u0": 0.70, "u1": 0.90, "mult": 1.5, "line": "it parts around your nose"},
		],
	},
	{
		"id": "lamp_line", "name": "Fen's lamps, all in one line",
		"kind": "light", "draw": "limb", "rarity": 1, "weight": 100,
		"blurb": "Every tower Fen ever lit, in one long line.",
		"silhouette": "A string of little lights along a dark edge.",
		"lanes": ["dusk", "ringgap", "outerdark", "longhome"], "hours": [16.0, 7.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.22, "scale": 1.30, "hold_sec": 1.5,
		"tint_a": "#ffd27a", "tint_b": "#a87cf2", "boost": {},
		# RECAST to `limb`: the limb's thin lit air shell IS a line of light on a dark curve.
		"moments": [
			{"u0": 0.30, "u1": 0.52, "mult": 1.4, "line": "a whole coast lights at once"},
			{"u0": 0.68, "u1": 0.88, "mult": 1.6, "line": "every lamp doubles in the water"},
		],
	},
	{
		"id": "pebble_moons", "name": "Grig's three pebble moons",
		"kind": "moon", "draw": "moonrim", "rarity": 1, "weight": 95,
		"blurb": "Three small grey ones, in a tidy row.",
		"silhouette": "Three little discs, evenly spaced.",
		"lanes": ["chalk", "ringgap", "outerdark", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.90, "scale": 0.80, "hold_sec": 1.4,
		"tint_a": "#d8d2c4", "tint_b": "#9aa3ad", "boost": {},
		"moments": [
			{"u0": 0.36, "u1": 0.60, "mult": 1.5, "line": "all three line up for a second"},
			{"u0": 0.74, "u1": 0.92, "mult": 1.3, "line": "the middle one has a dent in it"},
		],
	},
	{
		"id": "snow_lane", "name": "A lane of very slow snow",
		"kind": "ice", "draw": "ice", "rarity": 1, "weight": 105,
		"blurb": "Not falling. Just hanging there, being snow.",
		"silhouette": "A soft field of specks that never lands.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.30, "scale": 1.20, "hold_sec": 1.3,
		"tint_a": "#e6f0fa", "tint_b": "#9fb8d8", "boost": {},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.4, "line": "your wash sets the whole lane spinning"},
			{"u0": 0.70, "u1": 0.90, "mult": 1.3, "line": "one flake is the size of a door"},
		],
	},
	{
		"id": "first_light", "name": "First light along the rim",
		"kind": "light", "draw": "moonrim", "rarity": 1, "weight": 100,
		"blurb": "The star comes up over the edge of a world.",
		"silhouette": "A hot spark sitting on a dark curve.",
		"lanes": ["lantern", "chalk", "frost", "commons", "ringgap", "longhome"], "hours": [4.0, 9.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.98, "scale": 1.00, "hold_sec": 1.4,
		"tint_a": "#ffe3a8", "tint_b": "#ff9f6e", "boost": {"dawn": 1.8},
		# RECAST to `moonrim`: a dark disc with the sun just coming round it, exactly.
		"moments": [
			{"u0": 0.38, "u1": 0.62, "mult": 1.6, "line": "the spark stretches into a thread"},
			{"u0": 0.74, "u1": 0.92, "mult": 1.4, "line": "the whole rim goes warm at once"},
		],
	},
	{
		"id": "mail_run", "name": "The mail run, going the other way",
		"kind": "light", "draw": "pod", "rarity": 1, "weight": 95,
		"blurb": "Little lamps, all in a hurry. Wave anyway.",
		"silhouette": "Three quick lights in single file.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.75, "scale": 0.85, "hold_sec": 1.2,
		"tint_a": "#ffd27a", "tint_b": "#8fd0ff", "boost": {"day": 1.3},
		# RECAST to `pod`: the pod is bodies in a loose line, each on its own clock.
		"moments": [
			{"u0": 0.34, "u1": 0.56, "mult": 1.5, "line": "the last one flashes hello at you"},
			{"u0": 0.70, "u1": 0.90, "mult": 1.3, "line": "a parcel is tied on with string"},
		],
	},

	{
		"id": "dusk_line", "name": "The shadow line crawling over Fen",
		"kind": "weather", "draw": "limb", "rarity": 1, "weight": 100,
		"blurb": "Fen's day and night, side by side, all the time.",
		"silhouette": "A soft edge between a lit half and a dark one.",
		"lanes": ["dusk", "ringgap", "outerdark", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.20, "scale": 1.50, "hold_sec": 1.4,
		"tint_a": "#ef85bc", "tint_b": "#6a5f8c", "boost": {},
		# RECAST to `limb`: a curved world with a lit edge and a dark one.
		"moments": [
			{"u0": 0.30, "u1": 0.54, "mult": 1.5, "line": "it crosses a whole sea at once"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.7, "line": "the lamps come on behind it"},
		],
	},
	{
		"id": "still_pools", "name": "Fen's pools, holding the same sky",
		"kind": "light", "draw": "limb", "rarity": 1, "weight": 95,
		"blurb": "Still water, from a long way up. Very tidy.",
		"silhouette": "Bright patches in a dark place, perfectly flat.",
		"lanes": ["dusk", "ringgap", "outerdark", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.24, "scale": 1.15, "hold_sec": 1.4,
		"tint_a": "#ffcf96", "tint_b": "#8fb6ff", "boost": {},
		# RECAST to `ice`: four flat lit faces with dark between them, from orbit.
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.6, "line": "every pool lights at the same moment"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.5, "line": "one of them has a little boat on it"},
		],
	},
	{
		"id": "low_sun_glare", "name": "The low sun, straight down the lane",
		"kind": "light", "draw": "comet", "rarity": 1, "weight": 95,
		"blurb": "Fen's sun never climbs. You fly right into it.",
		"silhouette": "A flat white glare with a world underneath.",
		"lanes": ["dusk", "chalk", "ringgap", "longhome"], "hours": [8.0, 17.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.98, "scale": 1.10, "hold_sec": 1.5,
		"tint_a": "#ffe3a8", "tint_b": "#ef85bc", "boost": {"day": 1.3},
		# RECAST to `comet`: a hot core with a coma and a glare streaking off it.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.6, "line": "the glare narrows to one hot line"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.5, "line": "a tower cuts it in half"},
		],
	},
	{
		"id": "tower_swifts", "name": "Swifts off Fen's towers",
		"kind": "creature", "draw": "pod", "rarity": 1, "weight": 90,
		"blurb": "They ride the shadow line and never land.",
		"silhouette": "Quick dark flecks that will not hold still.",
		"lanes": ["dusk", "ringgap", "outerdark", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.46, "scale": 0.85, "hold_sec": 1.6,
		"tint_a": "#6a5f8c", "tint_b": "#ffcf96", "boost": {"dusk": 1.4},
		# RECAST to `pod`: quick bodies in a loose line that never hold still.
		"moments": [
			{"u0": 0.30, "u1": 0.52, "mult": 1.9, "line": "the whole flock turns and goes dark"},
			{"u0": 0.68, "u1": 0.90, "mult": 2.0, "line": "one keeps pace with your porthole"},
		],
	},
	{
		"id": "frost_flowers", "name": "Frost flowers on a drifting rock",
		"kind": "ice", "draw": "ice", "rarity": 1, "weight": 95,
		"blurb": "Ice grew into little bunches. Vela likes these.",
		"silhouette": "A rock with pale feathery bits on one side.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.38, "scale": 0.90, "hold_sec": 1.5,
		"tint_a": "#e6f0fa", "tint_b": "#bfe6ff", "boost": {},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.6, "line": "a whole face of it is in bloom"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.5, "line": "one bunch snaps off and sails away"},
		],
	},
	{
		"id": "yard_lights", "name": "Bolt's yard, still working at night",
		"kind": "light", "draw": "derelict", "rarity": 1, "weight": 95,
		"blurb": "He said he finished hours ago. The lights say no.",
		"silhouette": "A cluster of work lights that never go off.",
		"lanes": ["ringgap", "commons", "lantern"], "hours": [16.0, 7.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.26, "scale": 1.05, "hold_sec": 1.4,
		"tint_a": "#ffd27a", "tint_b": "#8fb6ff", "boost": {"night": 1.3},
		# RECAST to `derelict`: a dark hull with a lamp that will not go out.
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.7, "line": "a shower of sparks goes up"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.4, "line": "the big crane swings right round"},
		],
	},

	{
		"id": "vela_lamps", "name": "Vela's lamps, under the frost",
		"kind": "light", "draw": "limb", "rarity": 1, "weight": 95,
		"blurb": "Warm windows, under an awful lot of ice.",
		"silhouette": "Soft dots glowing up through something white.",
		"lanes": ["frost", "longhome", "ringgap", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.22, "scale": 1.10, "hold_sec": 1.4,
		"tint_a": "#ffd27a", "tint_b": "#bfe6ff", "boost": {"night": 1.3},
		# RECAST to `limb`: soft light coming up through the limb's own shell.
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.6, "line": "one window opens and somebody waves"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.4, "line": "the ice over them glows right through"},
		],
	},
	{
		"id": "crumb_moon", "name": "A moon about the size of a shed",
		"kind": "moon", "draw": "moonrim", "rarity": 1, "weight": 92,
		"blurb": "Too small to be a moon. It is a moon anyway.",
		"silhouette": "A tiny lump with its own tiny shadow.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.86, "scale": 0.55, "hold_sec": 1.4,
		"tint_a": "#d8d2c4", "tint_b": "#9aa3ad", "boost": {},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.5, "line": "it turns over once, proudly"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.4, "line": "somebody has left a flag on it"},
		],
	},
	{
		"id": "star_wind", "name": "The star's wind, combing the dust",
		"kind": "weather", "draw": "comet", "rarity": 1, "weight": 92,
		"blurb": "Everything loose out here points the same way.",
		"silhouette": "Long soft streaks, all combed one way.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.60, "scale": 1.35, "hold_sec": 1.4,
		"tint_a": "#ffe3a8", "tint_b": "#cfe0ff", "boost": {},
		# RECAST to `comet`: the dust tail is a long streak combed one way.
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.5, "line": "your own dust joins the comb"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.4, "line": "it bends around something you cannot see"},
		],
	},

	# ---------------------------------------------------------- weekly (rarity 2)
	{
		"id": "ring_kites", "name": "Kites feeding on the ring",
		"kind": "creature", "draw": "pod", "rarity": 2, "weight": 22,
		"blurb": "Flat, wide, and they only come for the ice.",
		"silhouette": "Wide flat shapes that vanish edge-on.",
		"lanes": ["ringgap"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.50, "scale": 1.15, "hold_sec": 2.4,
		"tint_a": "#ef85bc", "tint_b": "#ffcf96", "boost": {},
		# RECAST to `pod`: a pod body is a lens: wide flat, and gone edge-on.
		"moments": [
			{"u0": 0.36, "u1": 0.60, "mult": 2.1, "line": "one folds a wing right past the glass"},
			{"u0": 0.72, "u1": 0.90, "mult": 1.5, "line": "they stack up into a ladder"},
		],
	},
	{
		"id": "frost_moths", "name": "Frost moths, out for the week",
		"kind": "creature", "draw": "pod", "rarity": 2, "weight": 26,
		"blurb": "Paper-thin. Vela says they only get one week.",
		"silhouette": "Pale flutters that keep leaving the frame.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [18.0, 6.0],
		"dir": DIR_ANY, "days": [5, 6], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.45, "scale": 0.90, "hold_sec": 2.0,
		"tint_a": "#e6f0fa", "tint_b": "#c4a8f2", "boost": {"night": 1.5},
		# RECAST to `pod`: pale bodies that flutter out of the frame.
		"moments": [
			{"u0": 0.30, "u1": 0.52, "mult": 1.9, "line": "one settles flat against your glass"},
			{"u0": 0.66, "u1": 0.88, "mult": 1.6, "line": "the frost on their wings lights up"},
		],
	},
	{
		"id": "puddle_hoppers", "name": "Puddle-hoppers, off for the night",
		"kind": "creature", "draw": "pod", "rarity": 2, "weight": 22,
		"blurb": "They leave Zorp's rivers and come back by dawn.",
		"silhouette": "Small bright shapes climbing away from a river.",
		"lanes": ["dusk", "lantern", "commons", "chalk", "frost"], "hours": [15.0, 22.0],
		"dir": DIR_OUT, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "below", "focus": 0.48, "scale": 0.95, "hold_sec": 2.0,
		"tint_a": "#8fd0ff", "tint_b": "#a87cf2", "boost": {"dusk": 1.7},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.8, "line": "one carries a drop of river with it"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.5, "line": "they hop off each other to climb"},
		],
	},
	{
		"id": "comet_thistle", "name": "Comet Thistle crosses the lane",
		"kind": "comet", "draw": "comet", "rarity": 2, "weight": 22,
		"blurb": "Straight across your bow, and gone.",
		"silhouette": "A bright head with a long soft comma behind.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "ahead", "focus": 0.92, "scale": 1.00, "hold_sec": 2.6,
		"tint_a": "#8fd0ff", "tint_b": "#f0c78a", "boost": {},
		"moments": [
			{"u0": 0.38, "u1": 0.62, "mult": 1.8, "line": "the tail splits in two"},
			{"u0": 0.76, "u1": 0.94, "mult": 1.4, "line": "the head throws off a little one"},
		],
	},
	{
		"id": "minnow_comets", "name": "Minnow comets, three of them",
		"kind": "comet", "draw": "comet", "rarity": 2, "weight": 20,
		"blurb": "Tiny ones. Grig says they used to be one.",
		"silhouette": "Three short streaks travelling together.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.88, "scale": 0.80, "hold_sec": 2.2,
		"tint_a": "#cfe0ff", "tint_b": "#f0c78a", "boost": {},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.7, "line": "all three tails point the same way"},
			{"u0": 0.70, "u1": 0.90, "mult": 1.5, "line": "the small one overtakes the big one"},
		],
	},
	{
		"id": "vela_crown", "name": "Vela's frost crown",
		"kind": "aurora", "draw": "limb", "rarity": 2, "weight": 24,
		"blurb": "Cold light standing up off a cold world.",
		"silhouette": "A pale ring of light over a white edge.",
		"lanes": ["frost"], "hours": [17.0, 7.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.20, "scale": 1.40, "hold_sec": 1.8,
		"tint_a": "#bfe6ff", "tint_b": "#e2d0ff", "boost": {"night": 1.4},
		# RECAST to `limb`: the lit shell over a white edge is the crown.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.7, "line": "the crown closes into a full ring"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.5, "line": "it turns pink for about a second"},
		],
	},
	{
		"id": "der_kettle", "name": "The kettle-shaped derelict",
		"kind": "wreck", "draw": "derelict", "rarity": 2, "weight": 20,
		"blurb": "Somebody else was stranded out here first.",
		"silhouette": "A round hull with a spout. Honestly, a kettle.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.70, "scale": 1.05, "hold_sec": 2.8,
		"tint_a": "#c8b79a", "tint_b": "#ffd27a", "boost": {},
		"moments": [
			{"u0": 0.36, "u1": 0.60, "mult": 1.9, "line": "her lamp is still blinking"},
			{"u0": 0.74, "u1": 0.94, "mult": 1.4, "line": "somebody painted a face on the spout"},
		],
	},
	{
		"id": "mail_hulk", "name": "The old mail hulk",
		"kind": "wreck", "draw": "derelict", "rarity": 2, "weight": 20,
		"blurb": "Retired, and still full of everyone's post.",
		"silhouette": "A long boxy hull with hatches down the side.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.66, "scale": 1.10, "hold_sec": 2.4,
		"tint_a": "#b8a37f", "tint_b": "#8fd0ff", "boost": {},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.8, "line": "a hatch drifts open and letters spill"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.4, "line": "the old route is still painted on"},
		],
	},
	{
		"id": "shepherd_moon", "name": "The shepherd moon in the gap",
		"kind": "moon", "draw": "moonrim", "rarity": 2, "weight": 23,
		"blurb": "A small grey thing keeping the gap open.",
		"silhouette": "A little disc with ice piled on one side.",
		"lanes": ["chalk"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "ahead", "focus": 0.88, "scale": 0.85, "hold_sec": 2.0,
		"tint_a": "#c9ccd6", "tint_b": "#eef1f7", "boost": {},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.7, "line": "ice piles up against its edge"},
			{"u0": 0.74, "u1": 0.92, "mult": 1.4, "line": "it shoulders a block out of the way"},
		],
	},
	{
		"id": "mirror_moon", "name": "Vela's mirror moon",
		"kind": "moon", "draw": "moonrim", "rarity": 2, "weight": 21,
		"blurb": "So smooth you can find yourself in it.",
		"silhouette": "A disc too bright and too even to be rock.",
		"lanes": ["frost", "outerdark", "longhome", "ringgap"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.96, "scale": 1.05, "hold_sec": 2.2,
		"tint_a": "#e6f0fa", "tint_b": "#9fb8d8", "boost": {},
		"moments": [
			{"u0": 0.36, "u1": 0.60, "mult": 1.8, "line": "your own lamp looks back at you"},
			{"u0": 0.74, "u1": 0.94, "mult": 1.5, "line": "the whole star fits on its face"},
		],
	},
	{
		"id": "fen_fog", "name": "Fog sitting on Fen's pools",
		"kind": "weather", "draw": "limb", "rarity": 2, "weight": 24,
		"blurb": "It settles at dusk and does not move all night.",
		"silhouette": "Flat white patches lying in the low places.",
		"lanes": ["dusk"], "hours": [15.0, 23.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.24, "scale": 1.45, "hold_sec": 1.8,
		"tint_a": "#ffcf96", "tint_b": "#cfd8e6", "boost": {"dusk": 1.6},
		# RECAST to `limb`: flat white lying in the low places of the world below.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.6, "line": "the last sun turns the fog gold"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.5, "line": "a tower pokes up through the top"},
		],
	},
	{
		"id": "heat_shimmer", "name": "The star's shimmer, close in",
		"kind": "weather", "draw": "limb", "rarity": 2, "weight": 22,
		"blurb": "The sky wobbles. Your glass does not like it.",
		"silhouette": "Everything behind it goes wavy and warm.",
		"lanes": ["chalk"], "hours": [9.0, 16.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.80, "scale": 1.30, "hold_sec": 1.8,
		"tint_a": "#ffe3a8", "tint_b": "#ff9f6e", "boost": {"day": 1.5},
		# RECAST to `limb`: the limb's curtains lean and fold: that is the shimmer.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.6, "line": "a world behind it bends in half"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.4, "line": "the wobble settles for one clear beat"},
		],
	},

	{
		"id": "glass_tide", "name": "Vela's ice fog, coming in",
		"kind": "weather", "draw": "limb", "rarity": 2, "weight": 22,
		"blurb": "It rolls off the frost and swallows the view.",
		"silhouette": "A low white wall with nothing behind it.",
		"lanes": ["frost", "dusk", "outerdark", "longhome", "ringgap"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "below", "focus": 0.28, "scale": 1.40, "hold_sec": 1.8,
		"tint_a": "#e6f0fa", "tint_b": "#bfe6ff", "boost": {},
		# RECAST to `limb`: a low white wall standing on the limb, nothing behind it.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.7, "line": "it closes over a whole valley"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.6, "line": "the top of it glitters like glass"},
		],
	},
	{
		"id": "sun_dogs", "name": "Two false suns, one either side",
		"kind": "light", "draw": "comet", "rarity": 2, "weight": 21,
		"blurb": "Ice in the way makes the star into three.",
		"silhouette": "Three bright spots in a row. One is the real one.",
		"lanes": ["frost", "chalk", "commons", "lantern", "ringgap"], "hours": [8.0, 17.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "ahead", "focus": 0.97, "scale": 1.10, "hold_sec": 2.0,
		"tint_a": "#ffe3a8", "tint_b": "#bfe6ff", "boost": {"day": 1.4},
		# RECAST to `ice`: it IS ice in the way; the lit edges are the false suns.
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.8, "line": "all three line up dead level"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.6, "line": "the false ones go rainbow at the edge"},
		],
	},
	{
		"id": "scrap_shoal", "name": "A shoal of ship scrap",
		"kind": "wreck", "draw": "ice", "rarity": 2, "weight": 21,
		"blurb": "Bits of somebody's bad day, drifting together.",
		"silhouette": "A loose crowd of small sharp shapes.",
		"lanes": ["commons"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.44, "scale": 1.05, "hold_sec": 2.0,
		"tint_a": "#b8a37f", "tint_b": "#cfd8e6", "boost": {},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 2.1, "line": "a piece of your own ship goes by"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.5, "line": "the whole shoal turns over together"},
		],
	},

	{
		"id": "sun_sail", "name": "An old sun-sail, still catching light",
		"kind": "wreck", "draw": "derelict", "rarity": 2, "weight": 22,
		"blurb": "Nobody aboard. It is still going somewhere.",
		"silhouette": "A huge thin sheet, bright on one side only.",
		"lanes": ["lantern", "commons", "ringgap", "chalk", "dusk", "frost", "longhome", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.58, "scale": 1.50, "hold_sec": 2.2,
		"tint_a": "#ffe3a8", "tint_b": "#cfd8e6", "boost": {},
		# RECAST to `derelict`: the hull is rim-lit along one edge only, and dark otherwise.
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 1.8, "line": "the whole sail turns edge-on and vanishes"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.6, "line": "there is a patch sewn into the middle"},
		],
	},

	# ---------------------------------------------------------- rare (rarity 3)
	{
		"id": "chime_eels", "name": "Chime eels, in single file",
		"kind": "creature", "draw": "pod", "rarity": 3, "weight": 9,
		"blurb": "Nose to tail, and the radio hums when they pass.",
		"silhouette": "A long wavy line that hums on your radio.",
		"lanes": ["outerdark"], "hours": [19.0, 5.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "abeam", "focus": 0.58, "scale": 1.20, "hold_sec": 2.6,
		"tint_a": "#a87cf2", "tint_b": "#9be8d0", "boost": {"night": 1.4},
		"moments": [
			{"u0": 0.32, "u1": 0.56, "mult": 2.0, "line": "the line ties itself in a loop"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.7, "line": "they all hum the same note at you"},
		],
	},
	{
		"id": "seed_barge", "name": "A seed barge, still green inside",
		"kind": "wreck", "draw": "derelict", "rarity": 3, "weight": 8,
		"blurb": "Nobody came back for it. It kept growing anyway.",
		"silhouette": "A wide hull with green showing at the seams.",
		"lanes": ["longhome"], "hours": [0.0, 24.0],
		"dir": DIR_IN, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "slow", "place": "abeam", "focus": 0.64, "scale": 1.15, "hold_sec": 2.8,
		"tint_a": "#8fbf86", "tint_b": "#c8b79a", "boost": {},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 2.0, "line": "a vine has grown out of a window"},
			{"u0": 0.72, "u1": 0.92, "mult": 1.6, "line": "the whole hold is in flower"},
		],
	},
	{
		"id": "comet_marrow", "name": "Comet Marrow, running ahead",
		"kind": "comet", "draw": "comet", "rarity": 3, "weight": 8,
		"blurb": "Same direction as you, and faster. Show-off.",
		"silhouette": "A streak pointing the same way you are going.",
		"lanes": ["frost", "outerdark", "chalk"], "hours": [0.0, 24.0],
		"dir": DIR_OUT, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "mid", "place": "ahead", "focus": 0.96, "scale": 0.95, "hold_sec": 3.0,
		"tint_a": "#f0c78a", "tint_b": "#8fd0ff", "boost": {},
		"moments": [
			{"u0": 0.34, "u1": 0.58, "mult": 1.9, "line": "the dust tail curls right over"},
			{"u0": 0.74, "u1": 0.94, "mult": 1.6, "line": "it outruns you and you let it"},
		],
	},
	{
		"id": "snow_squall", "name": "A squall of dry snow",
		"kind": "weather", "draw": "ice", "rarity": 3, "weight": 8,
		"blurb": "It comes across fast and then it is just gone.",
		"silhouette": "A white wall moving faster than it should.",
		"lanes": ["frost"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": false, "needs_story": 0,
		"pace": "fast", "place": "abeam", "focus": 0.32, "scale": 1.35, "hold_sec": 2.0,
		"tint_a": "#e6f0fa", "tint_b": "#9fb8d8", "boost": {},
		# RECAST to `ice`: a field of chunks crossing the glass fast.
		"moments": [
			{"u0": 0.30, "u1": 0.54, "mult": 1.9, "line": "it swallows a moon and gives it back"},
			{"u0": 0.70, "u1": 0.92, "mult": 1.6, "line": "the far edge is a clean straight line"},
		],
	},

	# ------ hinted rares (rarity 3). Gated on having heard the hint.
	{
		"id": "ice_guest", "name": "Ice, with somebody inside",
		"kind": "ice", "draw": "ice", "rarity": 3, "weight": 9,
		"blurb": "Chunks off an old tail. One of them is not empty.",
		"silhouette": "A block of ice with a shadow in the middle.",
		"lanes": ["frost", "ringgap", "outerdark"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "vela", "hint_line": "Look inside the ice. One of them is not empty.",
		"pace": "mid", "place": "abeam", "focus": 0.40, "scale": 0.95, "hold_sec": 2.2,
		"tint_a": "#cfe6f2", "tint_b": "#8fb6ff", "boost": {}, "hint_boost": 2.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.5, "line": "the shape inside is still only a shadow"},
			{"u0": 0.34, "u1": 0.58, "mult": 1.7, "line": "the sun lights up what is inside"},
			{"u0": 0.72, "u1": 0.92, "mult": 2.1, "line": "whoever it is is fast asleep"},
		],
	},
	{
		"id": "star_in_a_pool", "name": "The star, caught in a pool",
		"kind": "light", "draw": "limb", "rarity": 3, "weight": 9,
		"blurb": "One still pool, holding the whole sun. Briefly.",
		"silhouette": "One tiny hot dot down on a dark world.",
		"lanes": ["dusk"], "hours": [15.0, 20.0],
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "fen", "hint_line": "At dusk one pool holds the whole sun. Just one.",
		"pace": "fast", "place": "below", "focus": 0.26, "scale": 0.70, "hold_sec": 1.6,
		"tint_a": "#ffe3a8", "tint_b": "#ef85bc", "boost": {"dusk": 2.0}, "hint_boost": 2.2,
		# RECAST to `limb`: one hot point down on the dark world below.
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.6, "line": "the pool is only just catching it"},
			{"u0": 0.36, "u1": 0.56, "mult": 2.2, "line": "the pool holds the whole sun at once"},
			{"u0": 0.72, "u1": 0.90, "mult": 1.6, "line": "a bird crosses it and breaks it"},
		],
	},
	{
		"id": "der_anvil", "name": "Bolt's old lifter, the Anvil",
		"kind": "wreck", "draw": "derelict", "rarity": 3, "weight": 9,
		"blurb": "He will not talk about why it is still up there.",
		"silhouette": "A heavy square hull with its arms folded in.",
		"lanes": ["ringgap"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "bolt", "hint_line": "Do not photograph my old lifter. Please.",
		"pace": "slow", "place": "abeam", "focus": 0.62, "scale": 1.00, "hold_sec": 2.4,
		"tint_a": "#b8a37f", "tint_b": "#ffd27a", "boost": {}, "hint_boost": 2.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.5, "line": "the arms are still folded up tight"},
			{"u0": 0.34, "u1": 0.58, "mult": 1.8, "line": "the hold doors swing open"},
			{"u0": 0.72, "u1": 0.92, "mult": 2.0, "line": "his name is still on the door"},
		],
	},
	{
		"id": "barnacle_calf", "name": "A barnacle calf, leaving home",
		"kind": "creature", "draw": "pod", "rarity": 3, "weight": 8,
		"blurb": "It grew on a comet. Now it wants its own one.",
		"silhouette": "A lumpy shell that is somehow going somewhere.",
		"lanes": ["frost", "outerdark", "longhome"], "hours": [0.0, 24.0],
		"dir": DIR_OUT, "days": [], "needs_hint": true, "needs_story": 1,
		"hint_npc": "mayor_orbit", "hint_line": "The young ones let go of the comet. Outbound.",
		"pace": "slow", "place": "abeam", "focus": 0.44, "scale": 0.90, "hold_sec": 2.6,
		"tint_a": "#cfe6f2", "tint_b": "#ffcf96", "boost": {}, "hint_boost": 2.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.6, "line": "it is still holding on with one foot"},
			{"u0": 0.32, "u1": 0.56, "mult": 1.8, "line": "it lets go of the comet at last"},
			{"u0": 0.70, "u1": 0.92, "mult": 2.1, "line": "it opens up like a small hand"},
		],
	},

	# ---------------------------------------------------------- hardly ever (rarity 4), all hinted
	{
		"id": "green_moon", "name": "The green moon, back toward home",
		"kind": "moon", "draw": "moonrim", "rarity": 4, "weight": 4,
		"blurb": "Bolt was right. It only does this before dawn.",
		"silhouette": "A moon somebody swears goes green. Nobody knows when.",
		"lanes": ["lantern"], "hours": [2.0, 5.0],
		"dir": DIR_IN, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "bolt", "hint_line": "Saw a green moon out your way. Cannot say when.",
		"pace": "slow", "place": "behind", "focus": 0.95, "scale": 1.15, "hold_sec": 2.6,
		"tint_a": "#7fe0a0", "tint_b": "#d6ffe6", "boost": {}, "hint_boost": 3.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.6, "line": "you catch it just clearing home's edge"},
			{"u0": 0.34, "u1": 0.62, "mult": 2.2, "line": "it goes green as it clears the dust"},
			{"u0": 0.74, "u1": 0.94, "mult": 1.8, "line": "home sits right underneath it"},
		],
	},
	{
		"id": "the_returner", "name": "The comet that comes back",
		"kind": "comet", "draw": "comet", "rarity": 4, "weight": 3,
		"blurb": "Grig has the date written down. Grig was right.",
		"silhouette": "A streak in an old drawing, dated and filed.",
		"lanes": ["longhome"], "hours": [0.0, 24.0],
		"dir": DIR_ANY, "days": [3], "needs_hint": true, "needs_story": 2,
		"hint_npc": "grig", "hint_line": "It is due back. I have the date in my book.",
		"pace": "mid", "place": "ahead", "focus": 0.94, "scale": 1.10, "hold_sec": 3.0,
		"tint_a": "#d6c0ff", "tint_b": "#f0c78a", "boost": {}, "hint_boost": 3.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.7, "line": "just a smudge, exactly where Grig said"},
			{"u0": 0.32, "u1": 0.58, "mult": 2.3, "line": "the tail matches Grig's old drawing"},
			{"u0": 0.72, "u1": 0.94, "mult": 1.9, "line": "it is early. Grig will be delighted"},
		],
	},
	{
		"id": "long_sleeper", "name": "The long sleeper",
		"kind": "creature", "draw": "pod", "rarity": 4, "weight": 3,
		"blurb": "Bigger than your ship, and sound asleep.",
		"silhouette": "Something very large that the Professor still tracks.",
		"lanes": ["outerdark"], "hours": [20.0, 4.0],
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 3,
		"hint_npc": "mayor_orbit", "hint_line": "Something big is out there, asleep. I track it.",
		"pace": "slow", "place": "below", "focus": 0.36, "scale": 1.60, "hold_sec": 3.2,
		"tint_a": "#7fa8e0", "tint_b": "#a87cf2", "boost": {"night": 1.5}, "hint_boost": 3.0,
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.7, "line": "you work out how big it is, slowly"},
			{"u0": 0.30, "u1": 0.56, "mult": 2.0, "line": "it breathes once, very slowly"},
			{"u0": 0.70, "u1": 0.94, "mult": 2.4, "line": "one eye opens, then thinks better of it"},
		],
	},
	{
		"id": "green_flash", "name": "The green flash off a rim",
		"kind": "light", "draw": "moonrim", "rarity": 4, "weight": 3,
		"blurb": "Stella says blink and you have missed it. True.",
		"silhouette": "A green spark pilots argue about at the shop.",
		"lanes": ["frost", "lantern", "chalk"], "hours": [4.0, 8.0],
		"dir": DIR_OUT, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "stella", "hint_line": "Heading out at dawn, watch the rim. Green. Once.",
		"pace": "fast", "place": "ahead", "focus": 1.00, "scale": 0.60, "hold_sec": 1.2,
		"tint_a": "#7fe0a0", "tint_b": "#ffe3a8", "boost": {"dawn": 2.0}, "hint_boost": 3.0,
		# RECAST to `moonrim`: the hairline where the sun grazes a rim, which the branch draws.
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.4, "line": "the rim is still plain gold"},
			{"u0": 0.40, "u1": 0.58, "mult": 2.4, "line": "green, for about half a second"},
			{"u0": 0.74, "u1": 0.90, "mult": 1.7, "line": "the rim goes gold again and that is it"},
		],
	},
	{
		"id": "orbit_laundry", "name": "Somebody's laundry, frozen in orbit",
		"kind": "wreck", "draw": "derelict", "rarity": 4, "weight": 4,
		"blurb": "Pip and Pop are still holding the ticket for it.",
		"silhouette": "Flat stiff shapes on a line. Pip swears it is washing.",
		"lanes": ["commons"], "hours": [0.0, 24.0],
		# REACHABILITY FIX (docs/STORY_SPINE_SPEC.md S3 row, the map's finding): was `DIR_IN`, which
		# on the Commons Run's depth-based direction_of() means ONLY zorp->hub / bolt->hub - and
		# those are the lane's two errand-only directions (safari_transit.gd:52-55: every trip TO
		# the Commons is a one-tap errand, so draw_cast never runs for them). The sight could never
		# actually appear. `DIR_ANY` matches its lane-mate `scrap_shoal` (:685) and makes it
		# reachable on the directions that ARE real photo flights: hub->zorp, hub->bolt, and
		# zorp<->bolt.
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 0,
		"hint_npc": "pip", "hint_line": "A customer left washing up there. Still got the ticket.",
		"pace": "slow", "place": "abeam", "focus": 0.42, "scale": 1.00, "hold_sec": 2.2,
		"tint_a": "#ffd6e8", "tint_b": "#cfe0ff", "boost": {}, "hint_boost": 3.0,
		# RECAST to `derelict`: stiff flat shapes hung off a snapped mast.
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.6, "line": "you think it is wreckage at first"},
			{"u0": 0.32, "u1": 0.58, "mult": 2.0, "line": "still pegged to the line, all of it"},
			{"u0": 0.72, "u1": 0.94, "mult": 2.3, "line": "one sock is very slowly getting away"},
		],
	},
	{
		"id": "shy_one", "name": "The shy one",
		"kind": "creature", "draw": "pod", "rarity": 4, "weight": 3,
		"blurb": "Zorp has looked for years. You got it first try.",
		"silhouette": "A glow that goes out the moment you look at it.",
		"lanes": ["lantern", "dusk", "outerdark"], "hours": [21.0, 3.0],
		"dir": DIR_ANY, "days": [], "needs_hint": true, "needs_story": 1,
		"hint_npc": "zorp", "hint_line": "There IS one that hides! I have looked for YEARS!",
		"pace": "mid", "place": "abeam", "focus": 0.50, "scale": 0.75, "hold_sec": 1.8,
		"tint_a": "#c4a8f2", "tint_b": "#9be8d0", "boost": {"night": 1.6}, "hint_boost": 3.0,
		# RECAST to `pod`: the pod's moment is one body turning; this one turns away.
		"moments": [
			{"u0": 0.08, "u1": 0.26, "mult": 1.7, "line": "a glow you are not sure you saw"},
			{"u0": 0.34, "u1": 0.56, "mult": 2.1, "line": "it goes dark the second you find it"},
			{"u0": 0.70, "u1": 0.92, "mult": 2.4, "line": "it lights up again to see if you left"},
		],
	},
]


# ------------------------------------------------------------------ lookups
static func all() -> Array:
	return SIGHTS


static func by_id(sight_id: String) -> Dictionary:
	for e in SIGHTS:
		if str(e["id"]) == sight_id:
			return e
	return {}


static func kind_name(kind: String) -> String:
	return str(KINDS.get(kind, "Something"))


static func rarity_name(r: int) -> String:
	return RARITY_NAMES[clampi(r, 1, 4)]


static func silhouette(e: Dictionary) -> String:
	return str(e.get("silhouette", "Something you have not caught yet."))


## The shader branch this sight is drawn with, 0..5. This is the number safari_run.gd writes into
## `s0_kind` / `s1_kind` / `s2_kind`; there is no other kind number anywhere.
static func shape_kind(e: Dictionary) -> int:
	return int(DRAW.get(str(e.get("draw", "pod")), 1))


## Every sight a lane can ever show, gates aside. The pre-flight card and the self-test use it.
static func lane_roster(lane: String) -> Array:
	var out: Array = []
	for e in SIGHTS:
		if Array(e.get("lanes", [])).has(lane):
			out.append(e)
	return out


# ------------------------------------------------------------------ hints
## A hint names a THING and half of a WHERE or a WHEN, never both, and never the id. It is the
## only place a hinted rare is ever mentioned, so a player who talks to nobody does not know it
## exists. RULING 5: the hint now lives ON THE SIGHT (`hint_npc`, `hint_line`), not in a table of
## its own and not in sky_hints.gd, which this round does not edit. The wiring round reads these
## two fields off the sight and puts the line in that neighbour's mouth.
##
## Ten sights are hinted and all ten carry a line. One line was REWRITTEN this round: green_flash
## used to say "Coming in at dawn..." while its own gate is `dir: out`, so the hint told you to
## fly the one direction on which the sight cannot appear. It now says "Heading out at dawn".
static func hint_for(sight_id: String) -> Dictionary:
	var e := by_id(sight_id)
	if e.is_empty() or not bool(e.get("needs_hint", false)):
		return {}
	return {"npc": str(e.get("hint_npc", "")), "line": str(e.get("hint_line", ""))}


## Every sight id that has to be heard about before it can be drawn.
static func hinted_ids() -> Array:
	var out: Array = []
	for e in SIGHTS:
		if bool(e.get("needs_hint", false)):
			out.append(str(e["id"]))
	return out


## Every hint a player on this lane could have heard, so the pre-flight card can show them.
## `known` is the neighbour ids the player has met; empty means everybody, which is what a
## headless test run uses.
static func hints_for_lane(lane: String, known: Array = []) -> Array:
	var out: Array = []
	for e in lane_roster(lane):
		if not bool(e.get("needs_hint", false)):
			continue
		var npc := str(e.get("hint_npc", ""))
		if not known.is_empty() and not known.has(npc):
			continue
		out.append({"id": str(e["id"]), "npc": npc, "line": str(e.get("hint_line", ""))})
	return out


# ------------------------------------------------------------------ conditions
## Does this hour fall inside [from, to)? Wraps over midnight. Same rule as safari_lanes.gd.
static func hour_in(from_h: float, to_h: float, h: float) -> bool:
	if is_equal_approx(from_h, 0.0) and is_equal_approx(to_h, 24.0):
		return true
	var x := fposmod(h, 24.0)
	if from_h <= to_h:
		return x >= from_h and x < to_h
	return x >= from_h or x < to_h


## The four phases the `boost` table keys on.
static func phase_of(hour: float) -> String:
	var x := fposmod(hour, 24.0)
	if x >= 5.0 and x < 9.0:
		return "dawn"
	if x >= 9.0 and x < 16.0:
		return "day"
	if x >= 16.0 and x < 20.0:
		return "dusk"
	return "night"


## The flight context. Every field has a safe default so a caller can pass a partial dictionary.
##   lane   String    one of LANE_IDS
##   hour   float     0..24, in-game
##   day    int       in-game day counter; `days` gates on day % 7
##   dir    String    "out" | "in" | "cross" | "any"
##   hints  Array     sight ids whose hint the player has heard
##   parts  int       rocket parts fitted, 0..5: how far the story has got
static func make_ctx(lane: String, hour: float, day: int = 0, dir: String = DIR_ANY,
		hints: Array = [], parts: int = 0) -> Dictionary:
	return {"lane": lane, "hour": hour, "day": day, "dir": dir, "hints": hints, "parts": parts}


## The hard gates. True means the thing could be out there tonight.
static func passes(e: Dictionary, ctx: Dictionary) -> bool:
	var lane := str(ctx.get("lane", ""))
	if not Array(e.get("lanes", [])).has(lane):
		return false
	var hrs: Array = e.get("hours", [0.0, 24.0])
	if not hour_in(float(hrs[0]), float(hrs[1]), float(ctx.get("hour", 12.0))):
		return false
	var want_dir := str(e.get("dir", DIR_ANY))
	var got_dir := str(ctx.get("dir", DIR_ANY))
	if want_dir != DIR_ANY and got_dir != DIR_ANY and want_dir != got_dir:
		return false
	var days: Array = e.get("days", [])
	if not days.is_empty() and not days.has(int(ctx.get("day", 0)) % 7):
		return false
	if int(ctx.get("parts", 0)) < int(e.get("needs_story", 0)):
		return false
	if bool(e.get("needs_hint", false)) and not Array(ctx.get("hints", [])).has(str(e["id"])):
		return false
	return true


## IS THIS SIGHT HERE BECAUSE OF SOMETHING? Anything with an hour gate, a direction gate, a story
## gate or a hint behind it. The lane's seventh slot takes nothing else, which is what makes a
## seven-sight trip mean something.
static func is_conditional(e: Dictionary) -> bool:
	var hrs: Array = e.get("hours", [0.0, 24.0])
	if not (is_equal_approx(float(hrs[0]), 0.0) and is_equal_approx(float(hrs[1]), 24.0)):
		return true
	if str(e.get("dir", DIR_ANY)) != DIR_ANY:
		return true
	return int(e.get("needs_story", 0)) > 0 or bool(e.get("needs_hint", false)) \
		or not Array(e.get("days", [])).is_empty()


## How likely, once the gates pass. 0.0 means it cannot appear. The lane multiplies this by its
## own flavour weight and nothing else - ONE number per sight, one draw.
static func weight_for(e: Dictionary, ctx: Dictionary) -> float:
	if not passes(e, ctx):
		return 0.0
	var w := float(e.get("weight", 10))
	var boost: Dictionary = e.get("boost", {})
	w *= float(boost.get(phase_of(float(ctx.get("hour", 12.0))), 1.0))
	return maxf(w, 0.0)


## Everything that could show up, heaviest first. Read-only; the pre-flight card uses it.
static func eligible(ctx: Dictionary) -> Array:
	var out: Array = []
	for e in SIGHTS:
		if weight_for(e, ctx) > 0.0:
			out.append(e)
	out.sort_custom(func(a, b): return weight_for(a, ctx) > weight_for(b, ctx))
	return out


## The weight at which a sight is out on very nearly every trip: the top weight in the table
## (lantern-fish, 110), not a tuned number. safari_lanes.gd reuses it as the weight of THE SKY
## BEING EMPTY in the conditions slot, so "nothing rare tonight" is as ordinary as an everyday
## sight, and a seventh sight has to beat that to happen.
const WEIGHT_ALWAYS := 110.0


## THE HIGHEST MOMENT MULTIPLIER ANYBODY ACTUALLY WROTE. Read off the table, never typed: this is
## what safari_scoring.gd's MOMENT_CEILING has to equal, or six authored moments get silently
## clamped (which is exactly what the reviewer caught: the ceiling was 2.2 and six moments were
## 2.3-2.4, five of them on the hinted top rares).
static func max_authored_moment() -> float:
	var best := 1.0
	for e in SIGHTS:
		for m in e.get("moments", []):
			best = maxf(best, float(m["mult"]))
	return best


# ------------------------------------------------------------------ moments
## `u` is 0..1 across the sight's window; the LANE owns the seconds. The moment running now, or {}.
static func moment_at(e: Dictionary, u: float) -> Dictionary:
	for m in e.get("moments", []):
		if u >= float(m["u0"]) and u <= float(m["u1"]):
			return m
	return {}


## 0..1: how deep into a moment we are, for the shader to open the thing up and close it again.
static func moment_strength(e: Dictionary, u: float) -> float:
	var m := moment_at(e, u)
	if m.is_empty():
		return 0.0
	var a := float(m["u0"])
	var b := float(m["u1"])
	return sin(clampf((u - a) / maxf(b - a, 0.0001), 0.0, 1.0) * PI)


## The best multiplier this sight can pay, for the journal's "you have not caught its best yet".
static func best_mult(e: Dictionary) -> float:
	var best := 1.0
	for m in e.get("moments", []):
		best = maxf(best, float(m["mult"]))
	return best


## PLACEHOLDER, carried over from safari_cast.gd so the haul card is not blank. The money round
## owns what a copy is worth; nothing here is a price.
static func value_of(e: Dictionary, hold_quality: float, moment_mult: float) -> float:
	return float(e["rarity"]) * clampf(hold_quality, 0.0, 1.0) * maxf(moment_mult, 1.0)


# ------------------------------------------------------------------ self-check
## Called by tools/safari_selftest.gd and by tests, never by the game. Returns a list of
## problems; empty is good.
static func problems() -> Array:
	var out: Array = []
	var seen := {}
	var per_lane := {}
	for lane_id in LANE_IDS:
		per_lane[lane_id] = 0
	for e in SIGHTS:
		var sight_id := str(e["id"])
		if seen.has(sight_id):
			out.append("duplicate id: " + sight_id)
		seen[sight_id] = true
		if not KINDS.has(str(e["kind"])):
			out.append(sight_id + ": unknown kind " + str(e["kind"]))
		if not DRAW.has(str(e.get("draw", ""))):
			out.append(sight_id + ": draws with a shape the eyepiece does not have: "
				+ str(e.get("draw", "")))
		if int(e["rarity"]) < 1 or int(e["rarity"]) > 4:
			out.append(sight_id + ": rarity out of range")
		var lanes: Array = e.get("lanes", [])
		if lanes.is_empty():
			out.append(sight_id + ": no lane can show it")
		for lane in lanes:
			if not LANE_IDS.has(str(lane)):
				out.append(sight_id + ": unknown lane " + str(lane))
			else:
				per_lane[str(lane)] = int(per_lane[str(lane)]) + 1
		if str(e["blurb"]).length() > 60:
			out.append(sight_id + ": blurb over 60")
		if str(e["silhouette"]).length() > 60:
			out.append(sight_id + ": silhouette over 60")
		if str(e["name"]).length() > 60:
			out.append(sight_id + ": name over 60")
		var moments: Array = e.get("moments", [])
		if moments.size() < 2 or moments.size() > 3:
			out.append(sight_id + ": needs 2-3 moments")
		for m in moments:
			if str(m["line"]).length() > 60:
				out.append(sight_id + ": moment line over 60")
			if float(m["u0"]) < 0.0 or float(m["u1"]) > 1.0 or float(m["u0"]) >= float(m["u1"]):
				out.append(sight_id + ": bad moment window")
		# RULING 5: the hint lives on the sight, and every hinted sight has to carry both halves.
		if bool(e.get("needs_hint", false)):
			var npc := str(e.get("hint_npc", ""))
			var line := str(e.get("hint_line", ""))
			if npc == "":
				out.append(sight_id + ": hinted and nobody tells you")
			if line == "":
				out.append(sight_id + ": hinted and no line written")
			if line.length() > 60:
				out.append("%s: hint line is %d chars" % [sight_id, line.length()])
		else:
			if e.has("hint_npc") or e.has("hint_line"):
				out.append(sight_id + ": carries a hint it does not need")
	for lane_id in LANE_IDS:
		if int(per_lane[lane_id]) < 8:
			out.append("lane %s has only %d sights" % [lane_id, per_lane[lane_id]])
	return out
