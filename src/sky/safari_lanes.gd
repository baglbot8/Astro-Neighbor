class_name SafariLanes
extends RefCounted
## THE EIGHT TRIPS, AND THE DRAW. Eight hand-made lanes cover all 21 planet pairs and all 42
## directed trips; who actually turns up on one is a weighted draw off SafariCatalog's 51 sights.
##
## SAFARI6 WAVE 2 (2026-09-22) REWROTE THE MIDDLE OF THIS FILE, because a real person flew the
## safari twice and caught nothing, and wave 1's critic proved why the OPENING of a run was the
## worst of it: at t=0.62 with the crosshair at the lane default, five of eight lanes had exactly
## one sight up and it was the world you had just left, at azimuth 157 - BEHIND you - and three
## lanes had nothing up at all. Measured again here on the wave-1 build (tools/g3_probe.gd, 8
## lanes x 4 hours): AT t=2.0 NOT ONE LANE HAD ANYTHING UP AT ANY HOUR. The first thing a new
## player saw was an empty sky.
##
## WHAT CHANGED, and every one of them is a rule in docs/SAFARI_FLIGHT_SPEC.md:
##
##   R4  THE CLOCK AND THE CONTENT. Every lane's `seconds` is exactly 3x what it was (156-234 s),
##       and the run is no longer five hand-placed fractions that could not emit more than seven
##       entries whatever `seconds` said. SEG_PLAN below is the whole shape of a run: 8 to 10
##       segments, 16 to 18 sights, three clashes.
##   S1  THE FIRST SHOT CANNOT MISS. Every lane opens with one slow, large sight on the `bow`
##       side - which IS safari_run.gd's own starting crosshair - up from t = 0.
##   S2  THE SECOND THING YOU DO IS TURN. One sight at +-40 degrees, just outside the 28-degree
##       window, opening at 6 s.
##   S4  8 to 10 segments of 19.5 to 24.7 s, each with its own backdrop.
##   S5  one nameable landmark per segment, in `segments`, reachable through `segments_for()`.
##   S6  busy and quiet segments, alternating.
##   S7  EXACTLY ONE sight behind the start heading, and `stern_high` is deleted so that is a
##       property of the SIDES table rather than a promise.
##   S8  the biggest set piece opens with the last segment.
##   R5  the third copy of EL_MIN/EL_MAX (this one) now matches safari_run.gd's, so its bridge
##       print - "SAFARI R5 bridge: N cast elevations pulled into -26..26" - is a no-op.
##
## WHAT THIS FILE IS. Data plus small pure helpers. No nodes, no autoload, no state, no saving,
## no randomness that is not seeded. `draw_cast()` hands back dictionaries in the shape
## safari_cast.gd's CAST_* arrays use (id/kind/rarity/hold_sec/title/blurb/focus/scale/t_start/
## t_end/az0/az1/el0/el1/tint_a/tint_b/moments), so the flight code consumes the result with
## `SafariCast.pos_at()` and friends unchanged. `segment` is the one new field and nothing reads
## it yet.
##
## SAY WHAT IS SYNTHETIC. NOTHING IN THIS FILE HAS BEEN FLOWN BY A PERSON. The numbers in this
## round's report come from tools/g3_probe.gd and from headless --auto runs of the real flight -
## geometry, up-counts, clash arithmetic and a greedy model of a player. A greedy model is a
## ceiling on catches, not a player.
##
## READ FIRST, INVENTED SECOND. Every world's limb (WORLD_LIMB) is written off that world's own
## .tres: Fen really has moon_count 0, so no moon sight is on the Long Dusk Drift; Grig really has
## ring_tilt_deg 86.0 and moon_size 0.155; Vela really has sun_disc_size 0.011 and star_density
## 2.6, which is why the Outer Dark has no sun in it.

## Player-facing strings are capped at this. Enforced by `check()`, not by hope.
const MAX_CHARS := 60

## Copied from safari_run.gd so `check()` can prove a swing is possible without importing it.
## If those constants move, this file's self-test is the thing that goes stale, not the game.
const SLEW_MAX_DEG := 55.0

## R5, THE THIRD CONSTANT (safari6 wave 2, spec 7.7). This used to be -52/+56, the OLD reachable
## sky, and every single run printed "SAFARI R5 bridge: N cast elevations pulled into -26..26"
## because safari_run.gd had already tightened to +-FIELD_LOW_DEG and was dragging this file's
## sights back in behind its back. READ, NOT GUESSED: safari_run.gd:146-147 is
## `EL_MIN := -FIELD_LOW_DEG` / `EL_MAX := FIELD_LOW_DEG` with `FIELD_LOW_DEG := 28.0`, so the
## reachable sky is exactly -28..+28 and these are its two numbers. `check()` proves every side
## and every drift lands inside safari_run.gd's bridge window (EL_MIN+2 .. EL_MAX-2), so the
## bridge now moves nothing and its line never prints.
const EL_MIN := -28.0
const EL_MAX := 28.0

## The furthest from level any SIDE's centre may sit. Everything above is derived from it, so
## there is one number to argue with rather than twenty-four.
const EL_SIDE_MAX := 14.0


# ---------------------------------------------------------------- where the worlds are
## How far out a world sits, as an integer. NOT invented: it is CORE_LOOP.md's range tiers
## (tier 1 Commons/Zorp/Bolt, tier 2 Fen/Grig, tier 3 Vela) with home beside the Commons because
## that is where you crashed and where the first hop starts. The only thing depth is used for is
## naming a direction, below.
const DEPTH := {
	"home": 0, "hub": 0,
	"zorp": 1, "bolt": 1,
	"fen": 2, "grig": 2,
	"vela": 3,
}

## THE DIRECTION OF A TRIP, which is how "certain rare events only happen on certain directions"
## is done. Outward (deeper), inward (shallower), or across (same depth). A catalog sight may gate
## on it with its own `dir` field.
const DIR_OUT := "out"
const DIR_IN := "in"
const DIR_CROSS := "cross"


# ---------------------------------------------------------------- the porthole's compass
## WHERE IN THE SKY A SLOT PUTS ITS SIGHT, in degrees. az 0 is dead ahead through the porthole,
## +-180 is astern. `spread` is how far it travels across its window; the travel REVERSES on an
## inbound trip, because flying the other way down the same road means the same thing goes past
## you the other way. Free directional flavour, no extra data.
##
## SAFARI6 WAVE 2 REWROTE THIS TABLE, for three separate reasons, all measured:
##
##  1. R5. Every el centre is now inside +-EL_SIDE_MAX (14), which with the drift below puts every
##     sight inside +-24 and therefore inside safari_run.gd's bridge window of +-26. The old table
##     ran to el 31 and had the bridge dragging 2 to 5 elevations back on EVERY run of all eight
##     lanes (measured, tools/g3_probe.gd on the wave-1 build, 4 hours x 8 lanes).
##  2. S7 - EXACTLY ONE SIGHT BEHIND YOU. `stern_high` is deleted. It and `stern_low` were both
##     in use (the Lantern Lane's `c`, the Long Way Home's `b`), and the probe found the Long Way
##     Home really did put TWO sights behind the start heading. `stern_low` is now reachable only
##     by the world you left, which is the one deliberate look-back.
##  3. S1 and S2. `bow` is new: az 0 / el 4 is safari_run.gd's own starting crosshair
##     (`_az := 0.0`, `_el := 4.0`), so the opener sits exactly where the player is already
##     looking. `near_port` / `near_star` at +-40 are new too: just outside the 28-degree window,
##     so the second sight is NOT on the glass at the default heading and the player has to turn
##     about 20 degrees to bring it in - a turn, not a trek.
##
## No side's azimuth plus half its spread reaches 90 degrees except `stern_low`; `check()` proves
## it, which is what makes "exactly one subject behind the start heading" a property of the table
## rather than a promise.
const SIDES := {
	"bow": {"az": 0.0, "el": 4.0, "spread": 8.0},
	"bow_high": {"az": 5.0, "el": 14.0, "spread": 14.0},
	"bow_low": {"az": -5.0, "el": -13.0, "spread": 14.0},
	"near_port": {"az": -40.0, "el": 5.0, "spread": 18.0},
	"near_star": {"az": 40.0, "el": -4.0, "spread": 18.0},
	"port": {"az": -74.0, "el": 1.0, "spread": 26.0},
	"port_high": {"az": -58.0, "el": 13.0, "spread": 22.0},
	"port_low": {"az": -66.0, "el": -12.0, "spread": 24.0},
	"star": {"az": 74.0, "el": 0.0, "spread": 26.0},
	"star_high": {"az": 58.0, "el": 12.0, "spread": 22.0},
	"star_low": {"az": 66.0, "el": -11.0, "spread": 24.0},
	"stern_low": {"az": 168.0, "el": -12.0, "spread": 22.0},
}


# ---------------------------------------------------------------- THE SHAPE OF A RUN
## S4: "cut the run into 7 to 9 segments of 15-25 seconds, each with its own backdrop". At the 3x
## lengths below (156-234 s) those two halves of the rule FIGHT: nine segments of a 234 s lane are
## 26.0 s each, over the ceiling. The SECONDS band is the one S4 states as the rule, so it wins and
## the count follows from it:
##
##     n_seg = max(8, ceil(seconds / SEG_MAX_SEC))
##
## which gives 8 segments on five lanes, 9 on two and 10 on the Long Way Home - every segment
## between 19.5 and 24.7 s. ONE LANE IS OVER S4's "8 or 9" BY ONE SEGMENT and that is stated here
## rather than hidden: 234 s cannot be cut into 9 pieces of 25 s or less.
const SEG_MAX_SEC := 25.0
const SEG_MIN_COUNT := 8

## WHAT EACH SEGMENT IS MADE OF, by how many segments the lane has. Read it as a score: one row per
## segment, one word per sight that OPENS in it.
##
##   open     S1. The first shot cannot miss: slow, large, dead ahead, up from t = 0.
##   s2       S2. Off to one side, opening at S2_AT_SEC, so the second thing you do is TURN.
##   behind   S7. The world you left, low and astern. THE ONLY sight behind the start heading.
##   clash1-3 R4. Two sights, opposite sides, opening in the same instant. See CLASH_AT_F.
##   cond     THE CONDITIONS SLOT, unchanged in kind from the old build: a rare that is only out
##            because of the hour, the direction, the story or a hint, competing against an empty
##            sky at SafariCatalog.WEIGHT_ALWAYS. If it comes up empty it falls back to an
##            ordinary draw, so the SKY is never short - only the rare is.
##   dest     the world you are arriving at.
##   finale   S8. The biggest set piece, opening with the last segment.
##   ord      an ordinary weighted draw, rarity 1-2.
##
## COUNTS, which are the R4 gate: 17 sights on an 8-segment lane, 18 on a 9 or a 10. Against the
## lane lengths that is one sight per 9.18 s (the Commons Run) to one per 13.0 s (the Long Way
## Home) - the spec's band is "one per 9.3 s easing to about one per 12 s".
##
## EVERY SEGMENT CARRIES A LONG SIGHT, and that is not decoration. The first cut of this table
## gave three segments nothing but a clash, whose two windows are hold + 1.8 s; measured
## (tools/g3_probe.gd) that left 26 to 29 seconds of COMPLETELY EMPTY SKY in a run, in two
## thirteen-second holes - the exact disease this round exists to cure. A clash segment now also
## carries an ordinary draw that spans it, so the spike lands on top of something rather than
## instead of it. Measured again after the change: the report has the number.
##
## BUSY AND QUIET (S6). A row of three is a busy segment, a row of one is quiet, a row of two is
## neither and is there to carry the alternation. The real test is how many sights are UP at once,
## not how many open; tools/g3_probe.gd measures that off the drawn cast, per segment, and it is
## in the report.
const SEG_PLAN := {
	8: [
		["open", "s2"],
		["behind", "clash1"],
		["ord"],
		["cond"],
		["clash2", "ord"],
		["cond"],
		["clash3", "ord"],
		["finale", "dest", "ord"],
	],
	9: [
		["open", "s2"],
		["behind", "clash1"],
		["ord"],
		["cond"],
		["clash2", "ord"],
		["ord"],
		["cond"],
		["clash3", "ord"],
		["finale", "dest", "ord"],
	],
	10: [
		["open", "s2"],
		["behind"],
		["clash1", "ord"],
		["ord"],
		["cond"],
		["clash2", "ord"],
		["ord"],
		["cond"],
		["clash3", "ord"],
		["finale", "dest"],
	],
}

## Where in the run each of the three clashes fires, as a fraction. 0.21 / 0.52 / 0.84 puts them
## 0.31 and 0.32 of the run apart, which is 48 s on the shortest lane and 75 s on the longest - the
## spec's "one per ~60 s, so 3 per run". They are NOT at the middle of their segments: the segment
## is where they land, the fraction is where they fire.
##
## WHY 0.21 AND NOT 0.20. 0.20 is exactly 2/10, so on the ten-segment lane the first clash fired
## in the same instant as its segment's ordinary draw opened, and the probe measured a THREE-body
## moment there with a 63-degree pair that misses by only 0.75 s - a clash whose second half is
## almost free. 0.21 lands 2.3 s inside the segment on that lane and does not change which segment
## any clash belongs to on 8, 9 or 10 (0.21 x 8 = 1.68, x 9 = 1.89, x 10 = 2.1 - segments 1, 1, 2,
## the same three rows of SEG_PLAN as before).
const CLASH_AT_F := [0.21, 0.52, 0.84]

## S2's opening, in seconds, absolute. The spec says the second subject is off to one side "inside
## the next 10 seconds" after S1's first five, so it is a wall-clock number and not a fraction -
## a fraction would put it at 3.5 s on the short lane and 5.6 s on the long one, which is not the
## same lesson twice.
const S2_AT_SEC := 6.0

## HOW THE SIGHTS INSIDE ONE SEGMENT ARE STAGGERED, as a fraction of the segment. The k-th sight
## on the SEGMENT'S OWN CLOCK opens at k * SEG_STAGGER_F into it and they all shut together at the
## segment's end - so a three-sight segment really does have three things up at once and a
## one-sight segment has exactly one.
##
## A clash does NOT take a k: it has its own absolute instant (CLASH_AT_F). That is not a detail.
## With the clash counted, a segment that opens with one started with a hole where nothing was up,
## and the first cut of this table measured 26 to 29 seconds of COMPLETELY EMPTY SKY per run
## (tools/g3_probe.gd) - the exact disease this round exists to cure. With the clash skipped, the
## first sight of every segment opens exactly when the segment does, every window abuts the next,
## and the measured empty sky is 0.0 s on all eight lanes at all four test hours. That is also why
## there is no spill constant: none is needed.
const SEG_STAGGER_F := 0.18

## S8. The set piece opens with the LAST segment, which on these lanes is the last 10.0% to 12.5%
## of the run - inside the spec's "last 10-15%" on every lane, with no number of its own.

# ---------------------------------------------------------------- THE CLASH
## Unchanged in kind from the old build, and the derivation is still the whole of it:
##
##   BOTH WINDOWS OPEN IN THE SAME INSTANT, on opposite sides of the ship. A window lasts exactly
##   as long as ITS OWN sight needs to be held, plus CLASH_GRACE.
##
##     how late you are  =  hold_a + cross + hold_b - (hold_b + CLASH_GRACE)
##                       =  hold_a + cross - CLASH_GRACE
##
## `hold_b` cancels, so the miss depends on nothing but the sight you took first and how far apart
## the two sides are. WHAT CHANGED: there are three of them now instead of one, and CLASH_GRACE
## stays ABSOLUTE at 1.8 s while the run tripled (spec 6.3), so each is the same 3-5 second spike
## it always was - three of them in four minutes instead of one in one minute.
const CLASH_GRACE := 1.8

## The clash's two sides must be far enough apart that even the shortest hold in the catalog
## misses. `check()` refuses any lane whose cross swing is under this. 2.30 = 1.5 (the ruling)
## + CLASH_GRACE - 1.2 (the shortest hold there is).
const CLASH_MIN_CROSS_SEC := 2.30

## Night is 18:00 to 06:00, the same gate safari_cast.gd's home-limb pair already uses. One
## definition, so "reads differently at night" means the same thing everywhere.
const NIGHT_FROM := 18.0
const NIGHT_TO := 6.0

# ---------------------------------------------------------------- the worlds, out of the porthole
## AHEAD and BEHIND, for all 42 directed trips, from 7 pairs of lines instead of 42. `ahead` is
## the destination's face and `behind` is the origin's, so a lane reads the right way round in
## both directions with no duplicated data. Each world has a DAY face and a NIGHT face; that, plus
## the hour gates on the catalog, is how a lane reads differently after dark.
##
## Tints are taken off each world's own .tres (ground/sky/fog/accent), pulled toward the muted end
## STYLE_GUIDE R2.6 asks for - these are a small limb at the edge of the glass, not the sky.
const WORLD_LIMB := {
	"home": {
		"day": {
			"title": "Home, a green thumbprint",
			"blurb": "Everything you own, small enough to cover.",
			"tint_a": "#7fb87f", "tint_b": "#cfe0b4",
			"line": "cloud opens over the meadow",
		},
		"night": {
			"title": "Home after dark, lamps and all",
			"blurb": "Every window you know, from a long way up.",
			"tint_a": "#6fd8a8", "tint_b": "#a87cf2",
			"line": "a light goes on in your own house",
		},
	},
	"hub": {
		"day": {
			"title": "The Commons, plaza wide open",
			"blurb": "From up here it is one big pale ring.",
			"tint_a": "#e2d6bc", "tint_b": "#9fb9a8",
			"line": "the crowd moves like water",
		},
		"night": {
			"title": "The Commons with every lamp lit",
			"blurb": "Somebody is always awake down there.",
			"tint_a": "#ffd27a", "tint_b": "#4c5b8c",
			"line": "the market lights come on in a wave",
		},
	},
	"zorp": {
		"day": {
			"title": "Zorp's hollow under violet cloud",
			"blurb": "Soft purple, and two small moons over it.",
			"tint_a": "#9a7fc4", "tint_b": "#d8c4e6",
			"line": "both moons cross at once",
		},
		"night": {
			"title": "Zorp's rivers, glowing from orbit",
			"blurb": "Blue lines drawn on a dark violet page.",
			"tint_a": "#5fb6d8", "tint_b": "#5a3f8c",
			"line": "a river runs bright end to end",
		},
	},
	"bolt": {
		"day": {
			"title": "Bolt's yard throwing sun back",
			"blurb": "Chrome plates flashing, one after another.",
			"tint_a": "#8fa3bf", "tint_b": "#ffcf96",
			"line": "the whole yard flashes at once",
		},
		"night": {
			"title": "Bolt's ring, black against the stars",
			"blurb": "A dark band with a working world inside it.",
			"tint_a": "#e0894a", "tint_b": "#2a3040",
			"line": "the ring cuts a star in half",
		},
	},
	"fen": {
		"day": {
			"title": "Fen, pink all the way round",
			"blurb": "One long evening, wrapped around a world.",
			"tint_a": "#e08cb4", "tint_b": "#f0c99a",
			"line": "the whole limb goes rose at once",
		},
		"night": {
			"title": "Fen's dark half, warm underneath",
			"blurb": "Not black. Just a very patient sort of dusk.",
			"tint_a": "#ffd27a", "tint_b": "#8e78c0",
			"line": "the dark side glows a little",
		},
	},
	"grig": {
		"day": {
			"title": "Grig's chalk steps from above",
			"blurb": "White stairs cut all the way round it.",
			"tint_a": "#b8b2a4", "tint_b": "#e0d9c6",
			"line": "the terraces line up in shadow",
		},
		"night": {
			"title": "Grig's ring standing on edge",
			"blurb": "A silver blade with a planet behind it.",
			"tint_a": "#c2c6d0", "tint_b": "#3a3f55",
			"line": "both big moons clear the ring",
		},
	},
	"vela": {
		"day": {
			"title": "Vela, frost and a small cold sun",
			"blurb": "Pale blue all over, and hardly any light.",
			"tint_a": "#9fb2c4", "tint_b": "#dde6f0",
			"line": "the frost flashes as you pass",
		},
		"night": {
			"title": "Vela, dark and thick with stars",
			"blurb": "The stars out here are the brightest thing.",
			"tint_a": "#5a7290", "tint_b": "#d8e4e6",
			"line": "the sky goes grainy with stars",
		},
	},
}


# ---------------------------------------------------------------- the eight lanes
## COVERING 21 PAIRS WITH 8 LANES. Seven worlds make 21 unordered pairs (42 directed trips). The
## partition is by geography, not arithmetic, and every pair lands in exactly one lane - `check()`
## proves it and `pairs_covered()` prints it:
##
##   lantern    3  home to each of the inner three         home-hub, home-zorp, home-bolt
##   commons    3  the inner triangle among themselves     hub-zorp, hub-bolt, zorp-bolt
##   ringgap    3  anything from Bolt to the outer worlds  bolt-fen, bolt-grig, bolt-vela
##   chalk      2  the inner worlds up to Grig             hub-grig, zorp-grig
##   dusk       2  the inner worlds out to Fen             hub-fen, zorp-fen
##   frost      2  the inner worlds out to Vela            hub-vela, zorp-vela
##   longhome   3  home straight out, the long haul        home-fen, home-grig, home-vela
##   outerdark  3  the outer worlds among themselves       fen-grig, fen-vela, grig-vela
##                                                          = 3+3+3+2+2+2+3+3 = 21
##
## Fields:
##   pairs       the unordered pairs this lane flies, both ways. `direction_of` sorts out which is
##               which, and the lane reads differently each way (landmarks swap, sweeps reverse,
##               direction-gated sights appear or do not).
##   seconds     R4: EXACTLY THREE TIMES the old value, per the spec's "each lane's own value x3".
##               52/56/58/62/62/68/74/78 -> 156/168/174/186/186/204/222/234.
##   segments    S5: one nameable landmark per segment, in order, on the route itself. The count
##               MUST equal `seg_count(seconds)`; `check()` refuses a lane where it does not, so
##               a lane cannot silently lose its backdrop when its length changes.
##   drift/edge  the landmarks that are the LANE's, as opposed to the two worlds': what goes past
##               in the middle, and what sits off to one side the whole way.
##   night       one line: what is different after dark.
##   signatures  TWO CATALOG IDS this lane alone can show. `check()` refuses a signature whose
##               catalog entry lists any other lane.
##   slots       WHERE THE RUN POINTS YOU. `open` is S1 and is `bow` on every lane by law - the
##               spec allows the opener exactly one place to be. `s2` is the first turn. `clash`
##               is THREE port-versus-starboard pairs, one per clash, so each forced choice is a
##               real cross-lane swing. `sweep` is the cycle the ordinary draws walk, and it is
##               what makes one lane's turns feel unlike another's. `finale` is S8's side.
##   w           per-lane weight multipliers on the catalog's own weights.
##               THESE GREW THIS ROUND, ON PURPOSE. Filling 16-18 sights needs a roster of 23-34
##               per lane instead of 11-18, which was bought by widening SafariCatalog's `lanes`
##               lists - and a wider membership means the eight lanes share more stock. Five
##               weighted favourites per lane instead of two is the counterweight: what a lane is
##               MADE OF is now carried by what it is full of, not only by what is barred from it.
##   pay_band    1..4, how far the trip is. Another round's file prices it; this is the hook.
const LANES := {

	"lantern": {
		"name": "the Lantern Lane",
		"mood": "The short hop off your own doorstep.",
		"seconds": 168.0, "pay_band": 1,
		"pairs": [["home", "hub"], ["home", "zorp"], ["home", "bolt"]],
		"drift": "little marker lamps, one every few seconds",
		"edge": "home's weather, turning slowly behind you",
		"night": "After dark home lights up, and the green moon can show.",
		"signatures": ["home_aurora", "green_moon"],
		"segments": ["the doorstep lamps", "the first marker buoy", "the mail gate",
			"the quiet reach", "the second buoy line", "the shoal of lamps",
			"the harbour approach", "the last buoy"],
		"slots": {
			"open": "bow", "s2": "near_star", "finale": "bow_high",
			"clash": [["port", "star"], ["port_low", "star"], ["port", "star_high"]],
			"sweep": ["port_high", "star", "port_low", "near_star", "star_high", "port",
				"bow_high"],
		},
		# The lane is lit and looked-after: its mail runs, its lone driftlings, and the two worlds'
		# own traffic are what it is full of.
		"w": {"mail_run": 2.0, "lantern_fish": 1.6, "ring_ice": 1.4, "zorp_moon_rim": 1.4,
			"yard_lights": 1.3},
	},

	"commons": {
		"name": "the Commons Run",
		"mood": "The busiest sky there is. Watch your window.",
		"seconds": 156.0, "pay_band": 1,
		"pairs": [["hub", "zorp"], ["hub", "bolt"], ["zorp", "bolt"]],
		"drift": "traffic, both ways, closer than you would like",
		"edge": "the Commons' own light, off to one side",
		"night": "At night the yard stays lit and the hulks show up.",
		"signatures": ["scrap_shoal", "orbit_laundry"],
		"segments": ["the plaza glow", "the inbound lane", "the traffic gate",
			"the scrap drift", "the crossing", "the yard smoke", "the outbound lane",
			"the docking beads"],
		"slots": {
			"open": "bow", "s2": "near_port", "finale": "bow_low",
			"clash": [["port_low", "star_low"], ["port", "star"], ["port_high", "star"]],
			"sweep": ["star_low", "port", "star_high", "near_port", "port_low", "star",
				"bow_low"],
		},
		# Traffic is the whole character of it: the mail, the dead hulls and the scrap.
		"w": {"mail_run": 2.5, "mail_hulk": 2.0, "scrap_shoal": 1.6, "chrome_dust": 1.5,
			"ring_ice": 1.4},
	},

	"ringgap": {
		"name": "the Ring Gap",
		"mood": "You go through Bolt's ring, not around it.",
		"seconds": 174.0, "pay_band": 2,
		"pairs": [["bolt", "fen"], ["bolt", "grig"], ["bolt", "vela"]],
		"drift": "ring ice, going the other way, fast",
		"edge": "Bolt's ring cutting the sky in half",
		"night": "At night the ring goes black and only the ice sparks.",
		"signatures": ["ring_kites", "der_anvil"],
		"segments": ["the yard's edge", "the outer ice", "the first gap",
			"the shepherd's shadow", "the ring's middle", "the ice fall", "the far gap",
			"the ring's rim"],
		"slots": {
			"open": "bow", "s2": "near_star", "finale": "bow",
			"clash": [["port", "star_low"], ["port_high", "star"], ["port_low", "star_low"]],
			"sweep": ["port", "star_high", "near_port", "star_low", "port_high", "star",
				"bow_low"],
		},
		# Everything in this lane is ice, and the guest in the ice rides along with it.
		"w": {"ring_ice": 1.5, "ice_guest": 1.5, "ring_kites": 1.6, "chrome_dust": 1.4,
			"yard_lights": 1.4},
	},

	"chalk": {
		"name": "the Chalk Run",
		"mood": "Dry, bright, and loud with dust.",
		"seconds": 186.0, "pay_band": 2,
		"pairs": [["hub", "grig"], ["zorp", "grig"]],
		"drift": "chalk dust that never quite settles",
		"edge": "Grig's ring standing straight up on edge",
		"night": "At night the ring turns silver and the moons take over.",
		"signatures": ["shepherd_moon", "heat_shimmer"],
		"segments": ["the chalk cloud", "the first terrace", "the dust lane", "the white steps",
			"the quarry gap", "the moon row", "the ring on edge", "the chalk rim"],
		"slots": {
			"open": "bow", "s2": "near_port", "finale": "bow_high",
			"clash": [["port", "star"], ["port_low", "star_low"], ["port", "star_low"]],
			"sweep": ["star_high", "port_low", "bow_high", "star", "port", "near_star",
				"star_low"],
		},
		# grig.tres: moon_count 2, moon_size 0.155 - five times Vela's. Moons ARE this lane.
		"w": {"pebble_moons": 2.0, "crumb_moon": 1.5, "shepherd_moon": 1.6, "heat_shimmer": 1.4,
			"chrome_dust": 1.3},
	},

	"dusk": {
		"name": "the Long Dusk Drift",
		"mood": "Slow, pink, and always half dark.",
		"seconds": 186.0, "pay_band": 2,
		"pairs": [["hub", "fen"], ["zorp", "fen"]],
		"drift": "the shadow line, running along with you",
		"edge": "still pools down there catching the low sun",
		"night": "Fen's dusk never ends, so night only moves the lamps.",
		"signatures": ["fen_fog", "star_in_a_pool"],
		"segments": ["the last light", "the shadow line", "the pool country", "the lamp coast",
			"the fog bank", "the tower row", "the long gloaming", "the dusk rim"],
		"slots": {
			"open": "bow", "s2": "near_star", "finale": "bow_low",
			"clash": [["port_low", "star_low"], ["port", "star_high"], ["port", "star"]],
			"sweep": ["port_low", "star", "bow_low", "port_high", "near_star", "star_low",
				"port"],
		},
		# fen.tres has moon_count = 0, so NO moon sight lists this lane at all - not a plain one,
		# not a pair lining up, and nothing to eclipse that low sun. The dusk itself is what it has.
		"w": {"dusk_line": 1.8, "lamp_line": 1.6, "still_pools": 1.6, "fen_fog": 1.4,
			"tower_swifts": 1.4},
	},

	"frost": {
		"name": "the Frost Road",
		"mood": "Long, cold and very quiet.",
		"seconds": 222.0, "pay_band": 3,
		"pairs": [["hub", "vela"], ["zorp", "vela"]],
		"drift": "frost flakes, sparking as they turn",
		"edge": "the sun, small enough to look straight at",
		"night": "At night Vela vanishes and the stars do all the work.",
		"signatures": ["vela_crown", "snow_squall"],
		"segments": ["the frost gate", "the first flakes", "the white lane", "the cold gap",
			"the glass tide", "the still water", "the crown's edge", "the deep cold",
			"the frost rim"],
		"slots": {
			"open": "bow", "s2": "near_port", "finale": "bow_high",
			"clash": [["port", "star_high"], ["port", "star"], ["port_high", "star"]],
			"sweep": ["star", "port_high", "near_star", "port_low", "bow_high", "star_low",
				"port"],
		},
		# The cold is made of ice, and this road is long enough to be all of it.
		"w": {"snow_lane": 2.0, "frost_flowers": 1.6, "vela_lamps": 1.5, "glass_tide": 1.4,
			"frost_moths": 1.4},
	},

	"longhome": {
		"name": "the Long Way Home",
		"mood": "Too far. That is the point of it.",
		"seconds": 234.0, "pay_band": 4,
		"pairs": [["home", "fen"], ["home", "grig"], ["home", "vela"]],
		"drift": "nothing, for a long time, and then something",
		"edge": "the old survey road, if you know where to look",
		"night": "At night home is one small light you keep checking.",
		"signatures": ["seed_barge", "the_returner"],
		"segments": ["the garden gate", "the last buoy", "the empty mile", "the survey road",
			"the old marker", "the long dark", "the drift field", "the turning post",
			"the far beacon", "the landing rim"],
		"slots": {
			"open": "bow", "s2": "near_star", "finale": "bow",
			"clash": [["port_high", "star"], ["port", "star_low"], ["port", "star"]],
			"sweep": ["bow_high", "star_low", "port", "star", "near_port", "port_high",
				"star_high"],
		},
		# The long empty stretch is when the rare things find you: the wreck and the big comet.
		"w": {"der_kettle": 2.0, "comet_thistle": 1.8, "star_wind": 1.5, "dust_veil": 1.5,
			"seed_barge": 1.4},
	},

	"outerdark": {
		"name": "the Outer Dark",
		"mood": "No sun out here. Things make their own.",
		"seconds": 204.0, "pay_band": 3,
		"pairs": [["fen", "grig"], ["fen", "vela"], ["grig", "vela"]],
		"drift": "things that light themselves",
		"edge": "stars, and more stars, and no sun at all",
		"night": "Dark either way. The chime eels are only out after dark.",
		"signatures": ["chime_eels", "long_sleeper"],
		"segments": ["the last sunlight", "the dark gate", "the lit drift", "the humming reach",
			"the sleeper's deep", "the cold shoal", "the glow field", "the far dark",
			"the outer rim"],
		"slots": {
			"open": "bow", "s2": "near_port", "finale": "bow_low",
			"clash": [["port_low", "star"], ["port", "star"], ["port_low", "star_low"]],
			"sweep": ["port_high", "star_low", "port", "bow_low", "star_high", "near_port",
				"star"],
		},
		# vela.tres: sun_disc_size 0.011. Nothing is lit from outside out here, so the things that
		# make their own light are what the lane is.
		"w": {"lantern_fish": 1.8, "mirror_moon": 1.5, "chime_eels": 1.6, "still_pools": 1.4,
			"dusk_line": 1.4},
	},
}


# ---------------------------------------------------------------- the weights, and their reasons
## A HEARD HINT IS THE WHOLE POINT OF HEARING A HINT. A hinted sight's own catalog weight is 3-9
## against an everyday thing's 90-115; heard, it is lifted so it is actually in the running in the
## conditions slot. It never becomes a sure thing: the slot also holds "nothing tonight" at
## SafariCatalog.WEIGHT_ALWAYS, so even a lifted rare has to beat an ordinary sky.
##
## HINT_LIFT is the PER-BOOST unit (what a `hint_boost` of 1.0 is worth), multiplied by the
## sight's own `hint_boost`, so rarity 4 keeps the 1.36-1.5x its own author already gave it over
## an ordinary hinted rare. MEASURED in an earlier round (tools/rare_probe.gd, 2000-6000 told
## runs): at a flat 6.0 a rarity-4 sight was takeable in 4.5% of told runs; wired to `hint_boost`
## at HINT_LIFT 3.0 it reached 8.3%; HEADLINE_PUSH, below, does the rest. Untold runs stay 0.0%
## throughout, since `passes()` gates a needs_hint sight to nothing before any weight is applied.
const HINT_LIFT := 3.0

## THE HEADLINE SIGHT, ON TOP OF hint_boost. The six rarity-4 sights only ever reach a slot on
## trips where their OWN hour/direction/story gates pass at all - measured independently of any
## weight (tools/rare_probe2.gd, 4000 uniform trips, hints heard): only 17.7% of trips have ANY
## rarity-4 sight eligible in the first place. That ceiling is set entirely by SafariCatalog's own
## gates, which this file does not own. MEASURED (tools/rare_probe.gd, 6000 told runs): 1.0 left a
## rarity-4 sight takeable in 8.3% of told runs; 4 reached 14.7%; 8 reached 17.1%; 12 reached
## 17.9%; 24 reached 18.5% - each doubling past 12 bought well under a point. 12 is where the
## curve goes flat, so it is where the push stops.
##
## SAFARI6 WAVE 2 NOTE, SAID PLAINLY: those numbers were measured on a FIVE-slot run in which a
## rare could land in slot `a`, slot `b` or the conditions slot. This round's run has 16-18 sights,
## and if a rare could land in any of them it would stop being rare. So rarity 3 and 4 are now
## barred from every ordinary draw and can only reach TWO places: the conditions slot and S8's
## finale. That is one fewer door than the old build had, not fifteen more. The before/after rate
## is in the report, measured on the same seeds.
const HEADLINE_PUSH := 12.0

## A LANE'S OWN SIGHT IS THE THING YOU REMEMBER THE LANE BY, so it is lifted to four. MEASURED,
## which is why the number is here: without it the Lantern Lane showed one of its own two only
## 10% of the time and the Long Way Home 14%, which is not a lane with a character, it is a lane
## with a footnote.
const SIGNATURE_W := 4.0

## A SIGHT IS LIFTED ONCE, by the larger of the two lifts, never by both. Kept from the round-1
## lanes file with its measurement: stacking them (4 x 6) put the green moon in 93% of the runs
## that met its own hour and direction gates, and a thing you see nine times in ten is not a rare.

## The sky gets more generous as the story goes: every rocket part adds a fifth to a RARE sight's
## weight, so a finished rocket (five parts) doubles it. Commons and uncommons are untouched -
## what grows is the chance of something worth telling a neighbour about.
const STORY_W_PER_PART := 0.2

## SOMETHING IS IN SEASON. The in-game day picks one of the six SHAPES and doubles it for that
## day, cycling every six days. A week of flying one lane is not the same week twice, and it is
## the cheapest possible version of "more or less likely depending on the conditions".
const SEASON_W := 2.0
const SEASON_KINDS := 6

## HOW FAR A SIGHT CLIMBS OR FALLS across its window, in degrees, for a `slow` one; `mid` is twice
## it and `fast` three times. DERIVED, not chosen: `_place` centres the drift on the side's own
## elevation, so the steepest sight (fast, 3x) reaches EL_SIDE_MAX + 1.5 x PLACE_DRIFT_DEG, and
## that has to land inside the band `_place` may write, which is EL_MIN+4 .. EL_MAX-4 = +-24. So
##
##     PLACE_DRIFT_DEG = (EL_MAX - 4 - EL_SIDE_MAX) * 2 / 3 = (28 - 4 - 14) * 2 / 3 = 6.667
##
## and NOTHING IS EVER CLAMPED - which matters, because a clamp is how a climbing sight silently
## becomes a level one. The old value (26/3) was set against the old +-56 sky and did clamp.
const PLACE_DRIFT_DEG := (EL_MAX - 4.0 - EL_SIDE_MAX) * 2.0 / 3.0


# ---------------------------------------------------------------- lookups
static func hour_in(from_h: float, to_h: float, h: float) -> bool:
	return SafariCatalog.hour_in(from_h, to_h, h)


static func is_night(hour: float) -> bool:
	return hour_in(NIGHT_FROM, NIGHT_TO, hour)


## out / in / cross, off DEPTH. An unknown world is treated as depth 0.
static func direction_of(from_id: String, to_id: String) -> String:
	var a: int = int(DEPTH.get(from_id, 0))
	var b: int = int(DEPTH.get(to_id, 0))
	if b > a:
		return DIR_OUT
	if b < a:
		return DIR_IN
	return DIR_CROSS


## THE LOOKUP. Which of the eight lanes is this trip? Order does not matter; the pair does.
static func lane_id_for(from_id: String, to_id: String) -> String:
	for lid in LANES:
		for p in LANES[lid]["pairs"]:
			if (p[0] == from_id and p[1] == to_id) or (p[0] == to_id and p[1] == from_id):
				return lid
	return ""


## The lane itself, as a plain copy, with the trip's own `id`, `direction`, `from` and `to` added.
## Falls back to the Lantern Lane so a bad pair cannot crash a flight.
static func lane_for(from_id: String, to_id: String) -> Dictionary:
	var lid := lane_id_for(from_id, to_id)
	if lid == "":
		lid = "lantern"
	var out: Dictionary = (LANES[lid] as Dictionary).duplicate(true)
	out["id"] = lid
	out["from"] = from_id
	out["to"] = to_id
	out["direction"] = direction_of(from_id, to_id)
	return out


static func seconds_for(from_id: String, to_id: String) -> float:
	return float(lane_for(from_id, to_id).get("seconds", 168.0))


# ---------------------------------------------------------------- S4/S5: the segments
## How many backdrops this run is cut into. See SEG_MAX_SEC for why the seconds band wins over
## S4's "8 or 9".
static func seg_count(seconds: float) -> int:
	return maxi(SEG_MIN_COUNT, int(ceil(seconds / SEG_MAX_SEC - 0.0001)))


## The score for a run of this length: one row of roles per segment.
static func seg_plan(seconds: float) -> Array:
	var n := seg_count(seconds)
	return SEG_PLAN.get(n, SEG_PLAN[SEG_MIN_COUNT])


## How many sights the plan emits, before any gate can come up short.
static func planned_sights(seconds: float) -> int:
	var n := 0
	for row in seg_plan(seconds):
		for role in row:
			n += 2 if str(role).begins_with("clash") else 1
	return n


## S5: the run's segments, in order, with their real seconds and the landmark each one is named
## after. A HUD, a haul card or a critic can print this as-is. NOTHING IN THE FLIGHT DRAWS IT YET
## - see `needs_from_others` in this round's report.
static func segments_for(from_id: String, to_id: String) -> Array:
	var lane := lane_for(from_id, to_id)
	var seconds := float(lane["seconds"])
	var names: Array = lane.get("segments", [])
	var n := seg_count(seconds)
	var seg := seconds / float(n)
	var plan := seg_plan(seconds)
	var out: Array = []
	for i in n:
		var roles: Array = plan[i] if i < plan.size() else []
		var opens := 0
		for role in roles:
			opens += 2 if str(role).begins_with("clash") else 1
		out.append({
			"i": i,
			"name": str(names[i]) if i < names.size() else "",
			"t0": seg * float(i),
			"t1": seg * float(i + 1),
			"opens": opens,
			"roles": roles,
		})
	return out


## WHAT IS AHEAD, WHAT IS BEHIND, WHAT DRIFTS PAST - for the trip, the right way round, at this
## hour. Short lines a HUD or a haul card can print as-is.
static func landmarks(from_id: String, to_id: String, hour: float) -> Dictionary:
	var lane := lane_for(from_id, to_id)
	var face := "night" if is_night(hour) else "day"
	return {
		"lane": str(lane["name"]),
		"mood": str(lane["mood"]),
		"ahead": str(_limb_face(to_id, face)["title"]),
		"behind": str(_limb_face(from_id, face)["title"]),
		"drift": str(lane["drift"]),
		"edge": str(lane["edge"]),
		"night": str(lane["night"]),
		"segments": (lane.get("segments", []) as Array).duplicate(),
	}


static func _limb_face(world_id: String, face: String) -> Dictionary:
	var w: Dictionary = WORLD_LIMB.get(world_id, WORLD_LIMB["home"])
	return w.get(face, w["day"])


## Every sight this lane could EVER show, gates aside. One line, one file: the catalog's own
## `lanes` field is the whole of it.
static func roster(lane_id: String) -> Array:
	return SafariCatalog.lane_roster(lane_id)


## How long it takes to swing between two slot sides, at the scope's top speed.
static func swing_sec(side_a: String, side_b: String) -> float:
	var a: Dictionary = SIDES[side_a]
	var b: Dictionary = SIDES[side_b]
	var daz: float = absf(wrapf(float(b["az"]) - float(a["az"]), -180.0, 180.0))
	var del: float = absf(float(b["el"]) - float(a["el"]))
	return maxf(daz, del) / SLEW_MAX_DEG


## The longest hold any sight this lane can draw needs. Used by the geometry test and by the
## critic's clash test.
static func max_hold_on(lane_id: String) -> float:
	var m := 1.4
	for e in roster(lane_id):
		m = maxf(m, float(e.get("hold_sec", 1.5)))
	return m


## The shortest one, which is the case that is hardest on the clash (see CLASH_GRACE).
static func min_hold_on(lane_id: String) -> float:
	var m := 99.0
	for e in roster(lane_id):
		m = minf(m, float(e.get("hold_sec", 1.5)))
	return m


## THE CLASH'S TWO WINDOWS for a given pair of holds. Both open at the same instant; each shuts
## `CLASH_GRACE` after its own hold would be done. `which` is 0, 1 or 2.
static func clash_windows(seconds: float, hold_a: float, hold_b: float,
		which: int = 0) -> Array:
	var t0: float = float(CLASH_AT_F[clampi(which, 0, CLASH_AT_F.size() - 1)]) * seconds
	return [[t0, t0 + hold_a + CLASH_GRACE], [t0, t0 + hold_b + CLASH_GRACE]]


## HOW LATE THE SECOND CATCH IS, in seconds, if you take A the moment it opens and then swing.
## Positive means you miss it. `hold_b` cancels out; see the derivation at CLASH_GRACE.
static func clash_miss_sec(lane_id: String, hold_a: float, which: int = 0) -> float:
	var cs: Array = LANES[lane_id]["slots"]["clash"][clampi(which, 0, 2)]
	return hold_a + swing_sec(str(cs[0]), str(cs[1])) - CLASH_GRACE


# ---------------------------------------------------------------- the weighted draw
## Everything the draw is allowed to know. Anything missing takes a sane default, so
## `draw_cast("home", "zorp")` works on its own for a test run.
static func make_ctx(hour: float = 9.5, day: int = 1, parts: int = 0,
		heard: Array = []) -> Dictionary:
	return {"hour": hour, "day": day, "parts": parts, "heard": heard}


## The catalog's own context for this lane and trip, so there is exactly one set of gates.
static func _cat_ctx(lane: Dictionary, ctx: Dictionary) -> Dictionary:
	return SafariCatalog.make_ctx(str(lane.get("id", "")), float(ctx.get("hour", 9.5)),
		int(ctx.get("day", 1)), str(lane.get("direction", SafariCatalog.DIR_ANY)),
		ctx.get("heard", []), int(ctx.get("parts", 0)))


## The weight of one catalog sight on one lane, or 0 if it cannot be there at all. Every
## multiplier is named above with its reason; there are no bare numbers in this function.
static func weight_of(e: Dictionary, lane: Dictionary, ctx: Dictionary) -> float:
	var w := SafariCatalog.weight_for(e, _cat_ctx(lane, ctx))
	if w <= 0.0:
		return 0.0
	w *= float((lane.get("w", {}) as Dictionary).get(str(e["id"]), 1.0))
	var lift := 1.0
	if (lane.get("signatures", []) as Array).has(str(e["id"])):
		lift = maxf(lift, SIGNATURE_W)
	if bool(e.get("needs_hint", false)):
		lift = maxf(lift, HINT_LIFT * float(e.get("hint_boost", 1.0)))
	w *= lift
	if int(e.get("rarity", 1)) >= 4:
		w *= HEADLINE_PUSH
	if int(e.get("rarity", 1)) >= 3:
		w *= 1.0 + STORY_W_PER_PART * float(int(ctx.get("parts", 0)))
	if SafariCatalog.shape_kind(e) == int(ctx.get("day", 1)) % SEASON_KINDS:
		w *= SEASON_W
	return w


## ONE WEIGHTED PICK out of a lane's roster, with every filter this round needs in one place.
## `opt` keys, all optional:
##   min_rarity / max_rarity  the rarity band. THE ORDINARY DRAWS CAP AT 2 - see HEADLINE_PUSH.
##   conditional              only sights that are out BECAUSE of something (the conditions slot).
##   empty_w                  the weight of nothing happening. Only the conditions slot uses it.
##   no_hinted                keep a heard, lifted rare out of this pick entirely (the clash).
##   paces                    only these `pace` words ("slow"/"mid"/"fast"). [] means any.
##   min_scale                only sights at least this big. 0 means any.
static func _pick(lane: Dictionary, ctx: Dictionary, used: Dictionary,
		rng: RandomNumberGenerator, opt: Dictionary = {}) -> Dictionary:
	var min_rarity: int = int(opt.get("min_rarity", 1))
	var max_rarity: int = int(opt.get("max_rarity", 4))
	var conditional: bool = bool(opt.get("conditional", false))
	var empty_w: float = float(opt.get("empty_w", 0.0))
	var no_hinted: bool = bool(opt.get("no_hinted", false))
	var paces: Array = opt.get("paces", [])
	var min_scale: float = float(opt.get("min_scale", 0.0))
	var picks: Array = []
	var ws: Array = []
	var total := empty_w
	for e in roster(str(lane.get("id", ""))):
		var sid := str(e["id"])
		if used.has(sid):
			continue
		var r: int = int(e.get("rarity", 1))
		if r < min_rarity or r > max_rarity:
			continue
		if conditional and not SafariCatalog.is_conditional(e):
			continue
		if no_hinted and bool(e.get("needs_hint", false)):
			continue
		if not paces.is_empty() and not paces.has(str(e.get("pace", "mid"))):
			continue
		if float(e.get("scale", 1.0)) < min_scale:
			continue
		var w := weight_of(e, lane, ctx)
		if w <= 0.0:
			continue
		picks.append(e)
		ws.append(w)
		total += w
	if total <= 0.0 or picks.is_empty():
		return {}
	var r2 := rng.randf() * total
	for i in picks.size():
		r2 -= float(ws[i])
		if r2 <= 0.0:
			return picks[i]
	return {}   # the empty slice won


## The first of several pick attempts that comes back with something. This is how "slow AND large,
## else slow, else anything" is written without a fallback buried in an if-tree, and it is why a
## lane whose roster runs thin still fills its slot instead of leaving a hole in the sky.
static func _pick_first(lane: Dictionary, ctx: Dictionary, used: Dictionary,
		rng: RandomNumberGenerator, tries: Array) -> Dictionary:
	for opt in tries:
		var e := _pick(lane, ctx, used, rng, opt)
		if not e.is_empty():
			return e
	return {}


## Lay a chosen sight into a slot: its window, its sweep across the sky, its moments in real
## seconds. `sweep_sign` is +1 outbound and -1 inbound, so the same thing crosses the porthole the
## other way when you fly the other way.
static func _place(e: Dictionary, slot_side: String, t0: float, t1: float,
		sweep_sign: float, slot_key: String, segment: String = "") -> Dictionary:
	var side: Dictionary = SIDES.get(slot_side, SIDES["port"])
	var half := float(side["spread"]) * 0.5 * sweep_sign
	var el_c := float(side["el"])
	# HOW FAR IT CLIMBS OR FALLS across its window, in degrees. Read off the catalog's own two
	# words rather than a per-sight drift field that could go out of step with them:
	#   `pace`  slow / mid / fast  is how far it travels: one, two or three times the base.
	#   `place` below / ahead / abeam / behind is which way: a thing low over a world settles
	#           DOWN, a thing you are flying at holds its height, anything else rises past you.
	# PLACE_DRIFT_DEG is derived from R5's own limits so this never clamps - see its comment.
	var paces := {"slow": 1.0, "mid": 2.0, "fast": 3.0}
	var ways := {"below": -1.0, "ahead": 0.0, "abeam": 1.0, "behind": 1.0}
	var dr: float = PLACE_DRIFT_DEG * float(paces.get(str(e.get("pace", "mid")), 2.0)) \
		* float(ways.get(str(e.get("place", "abeam")), 1.0))
	var out := {
		"id": str(e["id"]),
		"kind": SafariCatalog.shape_kind(e),
		"rarity": int(e.get("rarity", 1)),
		"hold_sec": float(e.get("hold_sec", 1.5)),
		"title": str(e.get("name", "")),
		"blurb": str(e.get("blurb", "")),
		"silhouette": str(e.get("silhouette", "")),
		"journal_kind": str(e.get("kind", "creature")),
		"focus": float(e.get("focus", 0.5)),
		"scale": float(e.get("scale", 1.0)),
		"tint_a": str(e.get("tint_a", "#ffffff")),
		"tint_b": str(e.get("tint_b", "#ffffff")),
		"hours": e.get("hours", [0.0, 24.0]),
		"t_start": t0, "t_end": t1,
		"az0": float(side["az"]) - half,
		"az1": float(side["az"]) + half,
		"el0": clampf(el_c - dr * 0.5, EL_MIN + 4.0, EL_MAX - 4.0),
		"el1": clampf(el_c + dr * 0.5, EL_MIN + 4.0, EL_MAX - 4.0),
		"side": slot_side,
		"slot": slot_key,
		"segment": segment,
		"moments": [],
	}
	# Moments are stored NORMALISED in the catalog so one sight works on a 19 s window and a 27 s
	# one; here they become real seconds.
	var span := t1 - t0
	for m in e.get("moments", []):
		out["moments"].append({
			"t0": t0 + float(m["u0"]) * span,
			"t1": t0 + float(m["u1"]) * span,
			"mult": float(m["mult"]),
			"line": str(m["line"]),
		})
	return out


## THE RUN'S CAST, in order. Route in, conditions in; a list of entries out, shaped exactly like
## safari_cast.gd's, ready for safari_run.gd.
##
## The same trip on the same in-game day in the same in-game hour gives the same sky - the seed is
## (lane, from, to, day, whole hour). The sky does not rearrange itself because you turned round
## and went back five minutes later; it does by the next hour, and it does on the next day.
##
## THE SHAPE OF IT IS SEG_PLAN, and nothing else. Walk the segments in order; for each role in a
## segment, draw for it and lay it down. That is the whole function, which is the point: the old
## one had five hand-placed fractions and could not emit more than seven entries whatever
## `seconds` said (spec 6.3's first trap).
static func draw_cast(from_id: String, to_id: String, ctx: Dictionary = {}) -> Array:
	var c := ctx.duplicate(true) if not ctx.is_empty() else make_ctx()
	var d := make_ctx()
	for k in ["hour", "day", "parts", "heard"]:
		if not c.has(k):
			c[k] = d[k]
	var lane := lane_for(from_id, to_id)
	var seconds := float(lane["seconds"])
	var hour := float(c["hour"])
	var face := "night" if is_night(hour) else "day"
	var sweep_sign := -1.0 if str(lane["direction"]) == DIR_IN else 1.0

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%s|%d|%d" % [lane["id"], from_id, to_id, int(c["day"]),
		int(floor(hour))])

	var slots: Dictionary = lane["slots"]
	var sweep: Array = slots["sweep"]
	var names: Array = lane.get("segments", [])
	var plan := seg_plan(seconds)
	var n_seg := plan.size()
	var seg := seconds / float(n_seg)

	var out: Array = []
	var used := {}
	var sweep_i := 0

	# ---- SP4: THE GUARANTEE (docs/STORY_SPINE_SPEC.md 2.3). While an ask is open, every photo
	# flight on its pointed lane, in either direction, departing inside its hours, carries that
	# sight - not a lottery. `PhotoAsks.for_trip()` is the ONE place that rule lives (the lead's
	# helper); this file only asks it and obeys. Marked `used` here, before the four named slots
	# are reserved below, so S1's opener, S2, the finale and the clash pairs never draw the same
	# id a second time and the guarantee never displaces any of them - it is filled from a plain
	# `ord` slot instead, once the segment walk reaches one (see the `"ord"` case below).
	var forced: Array[String] = PhotoAsks.for_trip(str(lane["id"]), from_id, to_id, hour)
	for fid in forced:
		used[fid] = true
	var forced_i := 0

	# ---- RESERVE THE FOUR NAMED SIGHTS BEFORE THE SEGMENT WALK.
	# The walk goes in time order, so the three clashes (segments 1, 4 and 6 on an 8-segment lane)
	# would otherwise draw SIX uncommons before the finale in the last segment ever picks. Measured
	# on the Lantern Lane, which carries five ungated uncommons: the finale fell through both of
	# its rarity-2 attempts and came up with `snow_lane`, a common - S8 asks for the biggest set
	# piece and got whatever was left. Reserving is the fix, and it costs nothing: the same four
	# roles, the same weighted draws, simply taken first.
	var res := {}
	res["open"] = _pick_first(lane, c, used, rng, [
		{"max_rarity": 2, "paces": ["slow"], "min_scale": 1.0},
		{"max_rarity": 2, "paces": ["slow"]},
		{"max_rarity": 2},
	])
	_use(used, res["open"])
	# S8. RARITY 2 OR 3, NEVER 4. Two measurements decided the cap, both on the same 320-run sweep
	# with every hint heard and five parts (tools/g3_probe.gd):
	#   uncapped, a rarity-4 sight was in 30.0% of runs against the old build's 18.1% - the
	#   headline sight stops being a headline;
	#   capped at 2, `snow_squall` becomes UNREACHABLE. It is rarity 3, it is the Frost Road's own
	#   signature, and it carries no hour, direction, day, story or hint gate, so `is_conditional`
	#   is false and the conditions slot will not take it. Rarity 3 at the finale is its only door.
	res["finale"] = _pick_first(lane, c, used, rng, [
		{"min_rarity": 2, "max_rarity": 3, "min_scale": 1.1},
		{"min_rarity": 2, "max_rarity": 3},
		{"max_rarity": 2},
	])
	_use(used, res["finale"])
	res["s2"] = _pick_first(lane, c, used, rng, [
		{"max_rarity": 2, "min_scale": 0.9},
		{"max_rarity": 2},
	])
	_use(used, res["s2"])
	# THE CONDITIONS SLOT, unchanged in kind: a rare that is only out because of the hour, the
	# direction, the story or a hint, against an empty sky at the weight of an everyday thing. If
	# the empty sky wins, an ordinary draw takes the slot instead - the RARE is what was withheld,
	# not the sight, so the sky is never short.
	#
	# THERE ARE TWO OF THEM, and that is a correction, not a widening. The old five-slot run gave a
	# rare THREE doors - slot `a`, slot `b` and the conditions slot, because `a` and `b` drew with
	# no rarity cap. This round caps every ordinary draw at rarity 2, so with one conditions slot a
	# rare had one door and the measured rate fell below the build it replaces: over 800 runs
	# (tools/g3_probe.gd, every hint heard, five parts) a rarity-3 sight was in 35.6% of runs
	# against the old build's 46.1%, and for a player who has heard nothing 8.5% against 13.5%.
	# Two independent conditions slots put it back. The rate is measured, not asserted: the report
	# carries the after number on the same sweep.
	var conds: Array = []
	var cond_keys: Array = []
	for row in plan:
		for role in row:
			if str(role) != "cond":
				continue
			var ec := _pick(lane, c, used, rng, {
				"min_rarity": 3, "conditional": true, "empty_w": SafariCatalog.WEIGHT_ALWAYS})
			var key := "c"
			if ec.is_empty():
				ec = _pick(lane, c, used, rng, {"max_rarity": 2})
				key = "ord"
			_use(used, ec)
			conds.append(ec)
			cond_keys.append(key)
	var cond_i := 0

	for i in n_seg:
		var t0: float = seg * float(i)
		var t1: float = seg * float(i + 1)
		# every sight on the segment's own clock shuts when the segment does, and the next
		# segment's first one opens in the same instant, so the sky never goes empty at a seam.
		var shut: float = minf(t1, seconds)
		var seg_name: String = str(names[i]) if i < names.size() else ""
		var roles: Array = plan[i]
		# THE STAGGER COUNTS ONLY THE ROLES THAT USE THE SEGMENT'S CLOCK. A clash has its own
		# absolute instant (CLASH_AT_F) and must not push the sight beside it later, or a segment
		# that opens with a clash starts with a hole where nothing is up.
		var k := 0
		for j in roles.size():
			var role := str(roles[j])
			var at: float = t0 + float(k) * SEG_STAGGER_F * seg
			if not role.begins_with("clash"):
				k += 1
			match role:
				"open":
					# S1. Dead ahead, up from the first frame, and SLOW AND LARGE if the lane has
					# one - the first shutter press must not be able to miss.
					var e: Dictionary = res["open"]
					if not e.is_empty():
						out.append(_place(e, str(slots["open"]), 0.0, shut, sweep_sign,
							"open", seg_name))
				"s2":
					# S2. Just outside the window, so the second thing the player does is turn.
					var e2: Dictionary = res["s2"]
					if not e2.is_empty():
						out.append(_place(e2, str(slots["s2"]), S2_AT_SEC, shut, sweep_sign,
							"s2", seg_name))
				"behind":
					# S7. The world you left, low and astern. The ONE sight behind you.
					out.append(_world_entry(from_id, face, "behind", "stern_low", at, shut,
						sweep_sign, seg_name))
				"dest":
					out.append(_world_entry(to_id, face, "ahead", "bow_low", at, seconds,
						sweep_sign, seg_name))
				"finale":
					# S8. The biggest set piece, opening with the last segment and running to the
					# end of the lane. Reserved above; see the note there for the rarity cap.
					var ef: Dictionary = res["finale"]
					if not ef.is_empty():
						out.append(_place(ef, str(slots["finale"]), t0, seconds, sweep_sign,
							"finale", seg_name))
				"cond":
					var ec: Dictionary = conds[cond_i] if cond_i < conds.size() else {}
					var ck: String = str(cond_keys[cond_i]) if cond_i < cond_keys.size() else "ord"
					cond_i += 1
					if not ec.is_empty():
						out.append(_place(ec, str(sweep[sweep_i % sweep.size()]), at, shut,
							sweep_sign, ck, seg_name))
						sweep_i += 1
				"ord":
					# SP4: an open ask on this trip's lane/hours fills the next plain `ord` slot
					# instead of the usual random pick - see the note above `draw_cast`.
					if forced_i < forced.size():
						var fe := SafariCatalog.by_id(str(forced[forced_i]))
						forced_i += 1
						if not fe.is_empty():
							out.append(_place(fe, str(sweep[sweep_i % sweep.size()]), at, shut,
								sweep_sign, "ord", seg_name))
							sweep_i += 1
					else:
						var eo := _pick(lane, c, used, rng, {"max_rarity": 2})
						if not eo.is_empty():
							used[str(eo["id"])] = true
							out.append(_place(eo, str(sweep[sweep_i % sweep.size()]), at, shut,
								sweep_sign, "ord", seg_name))
							sweep_i += 1
				_:
					if role.begins_with("clash"):
						_draw_clash(out, used, lane, c, rng, int(role.substr(5)) - 1,
							seconds, sweep_sign, seg_name)

	# SP4 SAFETY NET. Every SEG_PLAN row set (8, 9, 10 segments) carries at least one `ord` slot,
	# so this never fires today - but the guarantee must hold even if a future SEG_PLAN edit ever
	# left one out, rather than silently breaking a promise a neighbour's dialogue already made.
	while forced_i < forced.size():
		var fe2 := SafariCatalog.by_id(str(forced[forced_i]))
		forced_i += 1
		if not fe2.is_empty():
			out.append(_place(fe2, str(sweep[sweep_i % sweep.size()]), 0.0, seconds, sweep_sign,
				"ord", ""))
			sweep_i += 1

	out.sort_custom(func(a, b): return float(a["t_start"]) < float(b["t_start"]))
	return out


## ONE CLASH. Two sights, opposite sides, opening in the same instant, each window as long as its
## own hold plus CLASH_GRACE.
##
## NEVER A HINTED RARE, kept from the old build with its measurement: a hinted sight tangled in
## the forced choice was takeable in only ~5-6% of runs (tools/rare_probe.gd), so `no_hinted`
## keeps it out of BOTH picks and it only ever shows up somewhere it can actually be taken.
##
## RARITY 2 IF THE LANE HAS TWO LEFT, else rarity 1. The old build demanded rarity 2 on both and
## simply emitted NOTHING when the pool ran dry; with three clashes a run and four lanes carrying
## only five ungated uncommons (measured off the catalog after this round's widening: lantern 5,
## commons 6, chalk 6, dusk 6) that would have silently dropped clashes. A clash between two
## commons is a smaller prize, but it is still the same forced choice, and a missing clash is not.
## Mark a drawn sight used, if there was one.
static func _use(used: Dictionary, e) -> void:
	if e is Dictionary and not (e as Dictionary).is_empty():
		used[str((e as Dictionary)["id"])] = true


static func _draw_clash(out: Array, used: Dictionary, lane: Dictionary, c: Dictionary,
		rng: RandomNumberGenerator, which: int, seconds: float, sweep_sign: float,
		seg_name: String) -> void:
	var cs: Array = lane["slots"]["clash"][clampi(which, 0, 2)]
	var tries := [{"min_rarity": 2, "max_rarity": 2, "no_hinted": true},
		{"max_rarity": 2, "no_hinted": true}]
	var ea := _pick_first(lane, c, used, rng, tries)
	if ea.is_empty():
		return
	# marked used BEFORE the second pick, or the clash can draw the same sight twice - which is
	# exactly what it did on 338 of the first 1200 test runs of an earlier round.
	used[str(ea["id"])] = true
	var eb := _pick_first(lane, c, used, rng, tries)
	if eb.is_empty():
		used.erase(str(ea["id"]))
		return
	used[str(eb["id"])] = true
	var win := clash_windows(seconds, float(ea["hold_sec"]), float(eb["hold_sec"]), which)
	var tag := "" if which == 0 else str(which + 1)
	out.append(_place(ea, str(cs[0]), win[0][0], win[0][1], sweep_sign,
		"clash%s_a" % tag, seg_name))
	out.append(_place(eb, str(cs[1]), win[1][0], win[1][1], sweep_sign,
		"clash%s_b" % tag, seg_name))


## A world's limb as a cast entry. Rarity 1: it is always there, so it cannot be worth much - but
## the night face and the day face are different pictures with different words, which is the
## cheapest honest version of "the lane reads differently at night".
static func _world_entry(world_id: String, face: String, role: String, side_key: String,
		t0: float, t1: float, sweep_sign: float, seg_name: String = "") -> Dictionary:
	var f := _limb_face(world_id, face)
	var side: Dictionary = SIDES[side_key]
	var half := float(side["spread"]) * 0.5 * sweep_sign
	var el_c := float(side["el"])
	var span := t1 - t0
	# R5: clamped like `_place`, so the one entry in the cast that is not drawn from the catalog
	# cannot be the one that wakes safari_run.gd's bridge. It was: bow_low sat at el -26 and the
	# +-5 spread below put the arriving world at -31 on every run of every lane.
	var lo: float = EL_MIN + 4.0
	var hi: float = EL_MAX - 4.0
	return {
		"id": "limb_%s_%s_%s" % [world_id, face, role],
		"kind": int(SafariCatalog.DRAW["limb"]), "rarity": 1, "hold_sec": 1.4,
		"title": str(f["title"]), "blurb": str(f["blurb"]),
		"silhouette": "", "journal_kind": "weather",
		"focus": 0.15, "scale": 1.40,
		"tint_a": str(f["tint_a"]), "tint_b": str(f["tint_b"]),
		"hours": [0.0, 24.0],
		"t_start": t0, "t_end": t1,
		"az0": float(side["az"]) - half, "az1": float(side["az"]) + half,
		"el0": clampf(el_c + 5.0, lo, hi), "el1": clampf(el_c - 5.0, lo, hi),
		"side": side_key, "slot": role,
		"segment": seg_name,
		"world": world_id, "role": role,
		"moments": [{"t0": t0 + span * 0.35, "t1": t0 + span * 0.70, "mult": 1.5,
			"line": str(f["line"])}],
	}


# ---------------------------------------------------------------- self-check (data only)
## Every unordered pair of the seven worlds, and which lane flies it. Proves the 21.
static func pairs_covered() -> Dictionary:
	var ids: Array = DEPTH.keys()
	ids.sort()
	var out := {}
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			out["%s-%s" % [ids[i], ids[j]]] = lane_id_for(str(ids[i]), str(ids[j]))
	return out


## The data this file owns, measured. Returns a list of problems; empty is good.
##
## LANDMINE, AND IT IS WRITTEN HERE SO NOBODY IS FOOLED TWICE: THIS FUNCTION PASSING IS NOT
## EVIDENCE. It was green through the round in which a real person flew the safari twice and
## caught nothing. It can prove the table is consistent with itself. It cannot see the sky.
static func check() -> Array:
	var problems: Array = []

	# --- the eight lane ids are the eight the catalog writes against ---
	var mine: Array = LANES.keys()
	mine.sort()
	var theirs: Array = (SafariCatalog.LANE_IDS as Array).duplicate()
	theirs.sort()
	if mine != theirs:
		problems.append("lane ids differ from the catalog's: %s vs %s" % [str(mine), str(theirs)])

	# --- 21 pairs, each in exactly one lane ---
	var cover := pairs_covered()
	for k in cover:
		if str(cover[k]) == "":
			problems.append("pair %s is on no lane" % k)
	var seen := {}
	for lid in LANES:
		for p in LANES[lid]["pairs"]:
			var key := "%s-%s" % [p[0], p[1]] if str(p[0]) < str(p[1]) else "%s-%s" % [p[1], p[0]]
			if seen.has(key):
				problems.append("pair %s is in two lanes" % key)
			seen[key] = lid
	if cover.size() != 21:
		problems.append("expected 21 pairs, got %d" % cover.size())

	# --- R5: no side's centre is further from level than EL_SIDE_MAX, and nothing but the one
	#     look-back reaches 90 degrees off the bow (S7) ---
	for sk in SIDES:
		var s: Dictionary = SIDES[sk]
		if absf(float(s["el"])) > EL_SIDE_MAX:
			problems.append("side %s sits at el %.1f, past EL_SIDE_MAX %.1f"
				% [sk, float(s["el"]), EL_SIDE_MAX])
		var reach: float = absf(float(s["az"])) + float(s["spread"]) * 0.5
		var behind: bool = sk.begins_with("stern")
		if behind and reach <= 90.0:
			problems.append("side %s is called stern but only reaches %.1f deg" % [sk, reach])
		if not behind and reach >= 90.0:
			problems.append("side %s reaches %.1f deg, which is behind the player" % [sk, reach])
	# the steepest a sight can be placed, and it must be inside safari_run.gd's bridge window
	var steep: float = EL_SIDE_MAX + PLACE_DRIFT_DEG * 3.0 * 0.5
	if steep > EL_MAX - 2.0:
		problems.append("a fast sight can reach el %.1f, past the bridge's %.1f"
			% [steep, EL_MAX - 2.0])

	# --- every signature is a real catalog sight, and only this lane can show it ---
	for lid2 in LANES:
		var lane: Dictionary = LANES[lid2]
		var sigs: Array = lane["signatures"]
		if sigs.size() != 2:
			problems.append("%s has %d signatures, wanted 2" % [lid2, sigs.size()])
		for sid in sigs:
			var e := SafariCatalog.by_id(str(sid))
			if e.is_empty():
				problems.append("%s names %s, which is not a catalog sight" % [lid2, sid])
				continue
			var lanes: Array = e.get("lanes", [])
			if lanes != [lid2]:
				problems.append("%s's signature %s is also on %s" % [lid2, sid, str(lanes)])
		# --- every lane weight names a sight that lane can actually show ---
		for sid2 in (lane["w"] as Dictionary):
			if not Array(SafariCatalog.by_id(str(sid2)).get("lanes", [])).has(lid2):
				problems.append("%s weights %s, which is not on it" % [lid2, sid2])

		# --- R4 and S4: the clock, the segments and the count ---
		var sec := float(lane["seconds"])
		var n_seg := seg_count(sec)
		if not SEG_PLAN.has(n_seg):
			problems.append("%s wants %d segments and there is no plan for that many"
				% [lid2, n_seg])
			continue
		var seg := sec / float(n_seg)
		if seg < 15.0 or seg > SEG_MAX_SEC:
			problems.append("%s segments are %.1f s, outside 15-%.0f" % [lid2, seg, SEG_MAX_SEC])
		var names: Array = lane.get("segments", [])
		if names.size() != n_seg:
			problems.append("%s has %d segment names for %d segments"
				% [lid2, names.size(), n_seg])
		var n_sights := planned_sights(sec)
		if n_sights < 14 or n_sights > 18:
			problems.append("%s plans %d sights, outside 14-18" % [lid2, n_sights])
		# exactly one sight behind the start heading, and it is the world you left
		var behind_roles := 0
		var opens := 0
		var has_open := false
		var has_finale := false
		var has_dest := false
		for row in seg_plan(sec):
			for role in row:
				opens += 1
				if str(role) == "behind":
					behind_roles += 1
				elif str(role) == "open":
					has_open = true
				elif str(role) == "finale":
					has_finale = true
				elif str(role) == "dest":
					has_dest = true
		if behind_roles != 1 or not has_open or not has_finale or not has_dest:
			problems.append("%s's plan has behind=%d open=%s finale=%s dest=%s"
				% [lid2, behind_roles, has_open, has_finale, has_dest])
		# S8: the set piece opens with the last segment, which must be the last 10-15%
		var last_f: float = float(n_seg - 1) / float(n_seg)
		if last_f < 0.85 or last_f > 0.90:
			problems.append("%s's finale opens at %.3f of the run, outside the last 10-15%%"
				% [lid2, last_f])
		# S2 lands between 5 and 15 s
		if S2_AT_SEC < 5.0 or S2_AT_SEC > 15.0:
			problems.append("S2 opens at %.1f s, outside 5-15" % S2_AT_SEC)

		# --- S1: the opener is dead ahead ---
		var sl: Dictionary = lane["slots"]
		if str(sl["open"]) != "bow":
			problems.append("%s opens on %s, not the bow" % [lid2, str(sl["open"])])
		for key in ["open", "s2", "finale"]:
			if not SIDES.has(str(sl[key])):
				problems.append("%s's %s side %s is not in SIDES" % [lid2, key, str(sl[key])])
		for sw in (sl["sweep"] as Array):
			if not SIDES.has(str(sw)):
				problems.append("%s sweeps through %s, which is not in SIDES" % [lid2, str(sw)])

		# --- the three clashes ---
		var cl: Array = sl["clash"]
		if cl.size() != CLASH_AT_F.size():
			problems.append("%s has %d clash pairs, wanted %d" % [lid2, cl.size(),
				CLASH_AT_F.size()])
		for ci in cl.size():
			var pair: Array = cl[ci]
			var cross := swing_sec(str(pair[0]), str(pair[1]))
			if cross < CLASH_MIN_CROSS_SEC:
				problems.append("%s clash %d cross is only %.2f s" % [lid2, ci + 1, cross])
			var worst_miss := clash_miss_sec(lid2, min_hold_on(lid2), ci)
			if worst_miss < 1.5:
				problems.append("%s clash %d misses by only %.2f s" % [lid2, ci + 1, worst_miss])
			# the clash fires inside the segment whose plan carries it
			var ft: float = float(CLASH_AT_F[ci])
			var in_seg := int(floor(ft * float(n_seg)))
			var row2: Array = seg_plan(sec)[in_seg]
			if not row2.has("clash%d" % (ci + 1)):
				problems.append("%s clash %d fires at f=%.2f, in segment %d, whose roles are %s"
					% [lid2, ci + 1, ft, in_seg, str(row2)])
			# and you can reach ONE of the two from anywhere the ordinary draws leave you
			var reachable := true
			var froms: Array = (sl["sweep"] as Array).duplicate()
			froms.append(str(sl["open"]))
			froms.append(str(sl["s2"]))
			for fr in froms:
				var near: float = minf(swing_sec(str(fr), str(pair[0])),
					swing_sec(str(fr), str(pair[1])))
				if near > CLASH_GRACE:
					reachable = false
					problems.append("%s clash %d: from %s the nearer side is %.2f s away, past the"
						% [lid2, ci + 1, str(fr), near]
						+ " %.2f s grace" % CLASH_GRACE)
			if not reachable:
				pass
		# --- every ordinary window is long enough for the worst swing plus the longest hold ---
		var hold := max_hold_on(lid2)
		var worst_swing := 180.0 / SLEW_MAX_DEG
		var shortest_ord: float = (1.0 - 2.0 * SEG_STAGGER_F) * seg
		if shortest_ord < worst_swing + hold:
			problems.append("%s's tightest ordinary window is %.1f s, under swing %.2f + hold %.2f"
				% [lid2, shortest_ord, worst_swing, hold])

	# --- every player-facing string inside MAX_CHARS ---
	for wid in WORLD_LIMB:
		for face in WORLD_LIMB[wid]:
			for k2 in ["title", "blurb", "line"]:
				var s2 := str(WORLD_LIMB[wid][face][k2])
				if s2.length() > MAX_CHARS:
					problems.append("%s.%s.%s is %d chars" % [wid, face, k2, s2.length()])
	for lid3 in LANES:
		for k3 in ["name", "mood", "drift", "edge", "night"]:
			var s3 := str(LANES[lid3][k3])
			if s3.length() > MAX_CHARS:
				problems.append("%s.%s is %d chars" % [lid3, k3, s3.length()])
		for nm in (LANES[lid3]["segments"] as Array):
			if str(nm).length() > MAX_CHARS or str(nm).is_empty():
				problems.append("%s segment name %s is %d chars" % [lid3, nm, str(nm).length()])

	return problems
