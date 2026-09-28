class_name SafariShapes
extends RefCounted
## HOW EACH OF THE 51 SIGHTS IS DRAWN (2026-09-21, shapes round, spike, scratch only).
##
## WHY THIS FILE EXISTS. The first contact sheet of all 51 sights through the real glass came back
## as SIX PICTURES. Every sight on a branch of safari_eyepiece.gdshader's `shape()` drew the
## identical composition and differed only in two tint colours and one scale. Ten sights drew the
## same aurora curtains on the same limb; ten drew the same row of lenses; ten drew the same four
## ice lumps; eight drew the same dark disc with the same sliver. The content critic's "about 38%
## are re-cast onto the limb branch" was right about the cause and too kind about the size of it.
##
## It was worse than repeated branches. safari_run.gd sets `sN_seed` from the SLOT index
## (float(i) * 3.7 + 1.3), so the sight's own identity never reached the shader at all: two
## different sights caught in the same slot got byte-identical noise.
##
## WHAT THIS FILE IS. One row per sight id: the branch, twelve shape knobs, the two tints, the
## scale, and the sight's OWN seed. `apply()` is the only call a caller needs; it sets every
## `sN_*` uniform for one slot. The knobs are amplitudes, counts and angles - not new shader
## branches - which is why 51 distinct pictures cost about what 6 did.
##
## THE ROTATION, f2.w, is the single cheapest thing in here: one mat2 multiply that turns a hull
## onto a different diagonal, stands a school of eels on end, or points a comet at another corner.
##
## WHAT IS SYNTHETIC, SAID PLAINLY
##  * Every number here was set by eye against the contact sheet, on a desktop M5 running the
##    Compatibility renderer at the porthole's real phone size (1094 px). NONE of it has been seen
##    on a phone, and none of it has been seen during an actual flight: the sheet freezes `t` and
##    `run` so two tiles differ only by the sight.
##  * The sheet renders each sight CENTRED, IN FOCUS and ALONE. In a real run a sight is
##    off-centre, usually soft, and sometimes has two others over it.
##  * Nothing here has been play-tested for feel. It is graded on "can a second person tell these
##    two apart", which is what this round was asked for, and on nothing else.
##
## THE THREE RECASTS. Three sights changed `draw` because their old branch could not be made to
## look like them at any knob setting. safari_catalog.gd's `draw` fields were updated to match and
## tools/safari_shapes_selftest.gd proves the two files agree. Ids, rarities, moments, gates and
## hint lines were NOT touched.
##   still_pools    ice -> limb      flat sky-holding pools are wide bright patches lying ON a
##                                   world, not four chunks tumbling in space.
##   sun_dogs       ice -> comet     two false suns are two hard glare stars with a halo ring;
##                                   the comet branch draws exactly that with tails off, rays on.
##   barnacle_calf  ice -> pod       it is an animal. A crusted single body on the pod branch has
##                                   a lopsided lumpy silhouette with a hard rim; an ice chunk has
##                                   a faceted one with a lit face.
## Four more sights kept their branch but were REBUILT inside it, which is a bigger visual change
## than the three recasts: chrome_dust, snow_lane, snow_squall and scrap_shoal were four tumbling
## lumps each and are now swarms (fine hard glints, slow soft flakes, dense streaks, and bits
## around two chunks); yard_lights was one dead hull and is now a lit gantry with a glasshouse.
## ALL STATIC. No state, no autoload, nothing to save.

const SHAPES_VERSION := 2

## ROUND 4 (2026-09-21, "the five families"). The 51 were distinct on the fingerprint test and
## still came back from the reviewer as five families that read as one picture each. Density,
## size and tint are not differences a person NAMES; shape, motion, count and direction are. Six
## new meanings on knobs that already existed - no new uniform, no new branch - carry the fix, and
## each family member now has a one-word answer to "what is different about that one":
##
##   ice  f3.w  SWARM FORM  0 cloud  1 band  2 flakes  3 wall  4 shards
##        chrome_dust BAND (a thin diagonal ribbon of hard glints), snow_lane FLAKES (fat soft
##        ones that hang still, one in a while enormous), snow_squall WALL (a hard straight front
##        with streaks behind it), scrap_shoal SHARDS (small angular lit chips round two chunks).
##   pod  f3.x > 1   LANTERN   the body goes nearly dark and the lamp blinks right out
##                             between beats, every body on its own phase.   lantern_fish
##   pod  f2.z < 0   DARK FLECK  the body HIDES sky and catches one hot rim.  tower_swifts
##   pod  f3.y < 0   HOLLOW    a ring of glow with the middle taken out.      shy_one
##   limb f3.y > 1   SLABS     flat hard-edged pools lying on the ground.     still_pools
##   limb f3.z > 0 with lamps  HALOED  a warm core inside a big cold halo.    vela_lamps
##
## And three that are only new numbers: the star's wind takes the comet branch's new PARALLEL comb
## (core and rays both 0) instead of being a third fan; the Returner gets a wide fork AND a coma
## ring; the long sleeper is stretched to 4.4:1 so it is long where the shy one is hollow.
##
## WHAT IS SYNTHETIC IN ROUND 4, SAID PLAINLY: the same as round 3. Every number was set by eye
## against the contact sheet, frozen at one `t`, centred, in focus, alone, on a desktop M5 in the
## Compatibility renderer at the porthole's real 1094 px. None of it has been seen on a phone and
## none of it has been seen during an actual flight. The forms that MOVE (the wall's front, the
## lanterns' blink, the hollow's breath) are the ones the frozen sheet judges worst.

## The six branches, by the int `shape()` switches on. Must match SafariCatalog.DRAW.
const DRAW := {"comet": 0, "pod": 1, "ice": 2, "derelict": 3, "moonrim": 4, "limb": 5}

## WHAT THE TWELVE KNOBS MEAN, per branch. f2.w is ALWAYS the rotation in radians.
##   comet     f1 core, tails, rays, nuclei      f2 tail len, static fork, dust curve, ROT
##             f3 halo ring, nucleus spread, tail bearing, -
##   pod       f1 count, long axis, short axis, spacing   f2 arc, scatter, fin/wing, ROT
##             f3 lamp, crust, motion streak, wobble
##             (round 4: fin < 0 = DARK FLECK; lamp > 1 = LANTERN; crust < 0 = HOLLOW)
##   ice       f1 chunks, chunk size, swarm, swarm scale  f2 bit streak, spines, spread, ROT
##             f3 backlight, bit hardness, tumble rate, SWARM FORM
##             (round 4: form 0 cloud, 1 band, 2 flakes, 3 wall, 4 shards)
##   derelict  f1 half length, half height, bridge, fins  f2 mast, sheets, sheet size, ROT
##             f3 lamp, lit hold, gantry arm, -
##   moonrim   f1 radius, phase, pebbles (a row), ring band       f2 craters, mirror, cusp flare, ROT
##             f3 earthshine, -, -, -
##   limb      f1 curtains, height, count, broadness/lean f2 haze wedge, slant, ripple, ROT
##             f3 lamps, lamp width, fog bank, terminator
##             (round 4: lamp width > 1 = flat SLABS; fog > 0 with lamps = cold HALOES)
##             (height, count and broadness are shared by curtains, lamps and the wedge: they all
##              mean "how far up", "how many along the limb" and "how wide")
const ROWS := {
# ---------------------------------------------------------------- pod: schools, flocks, animals
# BLINKING. Six small dim bodies strung out in a long line; what you see is six LAMPS going on
# and off out of step. f3.x = 2 is lantern mode.
"lantern_fish":  {"draw": "pod", "scale": 1.10, "seed": 1.30,
	"f1": [6.0, 0.048, 0.040, 0.300], "f2": [0.070, 0.030, 0.00, 0.10],
	"f3": [2.00, 0.00, 0.00, 0.85]},
# ROUND. Five fat, nearly circular bodies in a tight bowed clump, no lights at all.
"driftlings":    {"draw": "pod", "scale": 1.10, "seed": 2.10,
	"f1": [5.0, 0.125, 0.118, 0.230], "f2": [0.230, 0.000, 0.00, -0.12],
	"f3": [0.00, 0.00, 0.00, 0.85]},
"mail_run":      {"draw": "pod", "scale": 1.00, "seed": 3.40,
	"f1": [3.0, 0.170, 0.034, 0.400], "f2": [0.000, 0.000, 0.20, 0.45],
	"f3": [0.00, 0.00, 0.90, 0.30]},
# DARK. The reviewer: "tower_swifts is so faint it barely renders" - it was a #6a5f8c body glowing
# on a #05050c sky, which is nothing. f2.z = -1 makes each one a HOLE in the star field with a hot
# rim down its lit edge, which is what "quick dark flecks" has to mean out here.
"tower_swifts":  {"draw": "pod", "scale": 1.00, "seed": 4.70,
	"f1": [6.0, 0.072, 0.030, 0.235], "f2": [0.000, 0.330, -1.00, -0.40],
	"f3": [0.00, 0.00, 0.80, 1.30]},
"ring_kites":    {"draw": "pod", "scale": 1.15, "seed": 5.90,
	"f1": [4.0, 0.180, 0.050, 0.340], "f2": [0.090, 0.050, 1.20, 0.18],
	"f3": [0.00, 0.00, 0.00, 0.70]},
"frost_moths":   {"draw": "pod", "scale": 1.05, "seed": 7.20,
	"f1": [6.0, 0.075, 0.048, 0.220], "f2": [0.000, 0.340, 1.60, -0.60],
	"f3": [0.00, 0.00, 0.00, 1.60]},
# CLIMBING. Four bodies on a steeply inclined line (ROT -1.15 rad) with a long trail behind each,
# so the whole sight has a DIRECTION: away from the river and up.
"puddle_hoppers": {"draw": "pod", "scale": 1.05, "seed": 8.50,
	"f1": [4.0, 0.080, 0.050, 0.330], "f2": [0.170, 0.040, 0.30, -1.15],
	"f3": [0.00, 0.00, 0.95, 1.10]},
"chime_eels":    {"draw": "pod", "scale": 1.00, "seed": 9.80,
	"f1": [4.0, 0.240, 0.022, 0.220], "f2": [0.080, 0.000, 0.00, -1.05],
	"f3": [0.35, 0.00, 0.00, 0.40]},
"barnacle_calf": {"draw": "pod", "scale": 1.00, "seed": 11.1,
	"f1": [1.0, 0.220, 0.170, 0.000], "f2": [0.000, 0.000, 0.30, 0.40],
	"f3": [0.00, 1.00, 0.00, 0.50]},
# LONG. 4.4:1, a solid body that hides stars, with a big trailing fin. The moment opens one eye.
"long_sleeper":  {"draw": "pod", "scale": 1.05, "seed": 12.4,
	"f1": [1.0, 0.640, 0.145, 0.000], "f2": [0.000, 0.000, 0.95, -0.14],
	"f3": [0.00, 0.28, 0.00, 0.22]},
# HOLLOW. f3.y = -1: no body at all, a ring of glow with a dark middle, breathing. The moment
# fills the middle back in - "it lights up again to see if you left".
"shy_one":       {"draw": "pod", "scale": 1.00, "seed": 13.7,
	"f1": [1.0, 0.330, 0.290, 0.000], "f2": [0.000, 0.000, 0.00, 0.75],
	"f3": [0.00, -1.00, 0.00, 0.80]},

# ---------------------------------------------------------------- comet: cores, tails, glares
# COMMA. ONE tail, strongly curved, off a hard bright head. fork 0 at rest: the split is its
# moment ("the tail splits in two"), not its resting shape.
"comet_thistle": {"draw": "comet", "scale": 1.10, "seed": 2.60,
	"f1": [1.0, 1.00, 0.00, 1.0], "f2": [1.150, 0.000, 0.560, 0.00],
	"f3": [0.00, 0.00, 2.50, 0.00]},
"minnow_comets": {"draw": "comet", "scale": 0.95, "seed": 3.90,
	"f1": [1.0, 1.00, 0.00, 3.0], "f2": [0.550, 0.000, 0.180, 0.50],
	"f3": [0.00, 0.62, 2.20, 0.00]},
"comet_marrow":  {"draw": "comet", "scale": 1.05, "seed": 5.20,
	"f1": [1.0, 1.00, 0.00, 1.0], "f2": [0.520, 0.000, 0.080, 0.00],
	"f3": [0.00, 0.00, -0.70, 0.00]},
# FORKED. The headline rare: a wide V of two straight ion tails, no dust curve, and a coma RING
# round the head that no other comet here has.
"the_returner":  {"draw": "comet", "scale": 1.20, "seed": 6.50,
	"f1": [1.0, 1.00, 0.00, 1.0], "f2": [2.100, 0.620, 0.000, 0.25],
	"f3": [0.45, 0.00, 2.90, 0.00]},
"low_sun_glare": {"draw": "comet", "scale": 1.00, "seed": 7.80,
	"f1": [1.0, 0.00, 1.00, 1.0], "f2": [1.000, 0.000, 0.000, 0.35],
	"f3": [0.00, 0.00, 0.00, 0.00]},
"sun_dogs":      {"draw": "comet", "scale": 1.00, "seed": 9.10,
	"f1": [1.0, 0.00, 0.90, 2.0], "f2": [1.000, 0.000, 0.000, 0.00],
	"f3": [1.00, 0.50, 0.00, 0.00]},
# PARALLEL. No head and no glare, so it takes the comet branch's comb: six lanes that run right
# out of the field and never meet. f3.y is the gap between them, f2.z their sag.
"star_wind":     {"draw": "comet", "scale": 1.15, "seed": 10.4,
	"f1": [0.0, 1.00, 0.00, 1.0], "f2": [2.200, 0.300, 0.120, -0.25],
	"f3": [0.00, 0.50, 2.50, 0.00]},

# ---------------------------------------------------------------- ice: chunks and swarms
"ring_ice":      {"draw": "ice", "scale": 1.00, "seed": 1.70,
	"f1": [4.0, 0.105, 0.00, 9.0], "f2": [0.000, 0.00, 0.320, 0.20],
	"f3": [0.00, 0.50, 0.350, 0.00]},
"frost_flowers": {"draw": "ice", "scale": 1.00, "seed": 3.00,
	"f1": [1.0, 0.130, 0.18, 22.0], "f2": [0.000, 1.00, 0.100, 0.15],
	"f3": [0.00, 0.80, 0.120, 0.00]},
"ice_guest":     {"draw": "ice", "scale": 1.05, "seed": 4.30,
	"f1": [1.0, 0.260, 0.00, 9.0], "f2": [0.000, 0.00, 0.050, -0.20],
	"f3": [0.10, 0.50, 0.100, 0.00]},
# SHARDS (form 4). Small angular lit chips with hard edges, crowding round two real chunks.
"scrap_shoal":   {"draw": "ice", "scale": 1.00, "seed": 5.60,
	"f1": [2.0, 0.055, 1.00, 9.0], "f2": [0.000, 0.00, 0.380, 0.80],
	"f3": [0.00, 0.85, 0.600, 4.00]},
# BAND (form 1). A long thin diagonal ribbon of very fine hard glints. Nothing else is a ribbon.
"chrome_dust":   {"draw": "ice", "scale": 1.00, "seed": 6.90,
	"f1": [0.0, 0.105, 1.30, 19.0], "f2": [0.450, 0.00, 0.260, 0.55],
	"f3": [0.00, 1.00, 0.300, 1.00]},
# FLAKES (form 2). Fat, soft, and they DO NOT MOVE. About one cell in fourteen is a monster.
"snow_lane":     {"draw": "ice", "scale": 1.00, "seed": 8.20,
	"f1": [0.0, 0.105, 1.05, 3.4], "f2": [0.000, 0.00, 0.360, 0.00],
	"f3": [0.00, 0.05, 0.100, 2.00]},
# WALL (form 3). A hard straight leaning front with streaks packed behind it.
"snow_squall":   {"draw": "ice", "scale": 1.00, "seed": 9.50,
	"f1": [0.0, 0.105, 1.25, 13.0], "f2": [0.950, 0.00, 0.420, 0.30],
	"f3": [0.00, 0.35, 0.200, 3.00]},

# ---------------------------------------------------------------- derelict: things built, and dead
"der_kettle":    {"draw": "derelict", "scale": 1.00, "seed": 2.40,
	"f1": [0.170, 0.100, 1.30, 0.30], "f2": [0.00, 0.0, 0.020, 0.55],
	"f3": [1.00, 0.00, 0.00, 0.00]},
"mail_hulk":     {"draw": "derelict", "scale": 1.05, "seed": 3.70,
	"f1": [0.380, 0.042, 0.60, 1.30], "f2": [1.20, 0.0, 0.020, -0.14],
	"f3": [0.70, 0.00, 0.00, 0.00]},
"der_anvil":     {"draw": "derelict", "scale": 1.10, "seed": 5.00,
	"f1": [0.220, 0.065, 0.40, 0.30], "f2": [0.00, 0.0, 0.020, 0.08],
	"f3": [0.60, 0.00, 1.00, 0.00]},
"seed_barge":    {"draw": "derelict", "scale": 1.05, "seed": 6.30,
	"f1": [0.280, 0.085, 0.80, 0.60], "f2": [0.40, 0.0, 0.020, 0.18],
	"f3": [0.50, 1.00, 0.00, 0.00]},
"yard_lights":   {"draw": "derelict", "scale": 1.05, "seed": 7.60,
	"f1": [0.300, 0.075, 1.00, 0.50], "f2": [0.70, 0.0, 0.020, -0.10],
	"f3": [2.20, 0.70, 0.90, 0.00]},
"sun_sail":      {"draw": "derelict", "scale": 1.10, "seed": 8.90,
	"f1": [0.060, 0.018, 0.00, 0.00], "f2": [0.50, 1.0, 0.300, -0.35],
	"f3": [0.20, 0.00, 0.00, 0.00]},
"orbit_laundry": {"draw": "derelict", "scale": 1.00, "seed": 10.2,
	"f1": [0.070, 0.016, 0.00, 0.00], "f2": [0.80, 4.0, 0.085, -0.08],
	"f3": [0.15, 0.00, 0.00, 0.00]},

# ---------------------------------------------------------------- moonrim: moons and their rims
"zorp_moon_rim": {"draw": "moonrim", "scale": 1.00, "seed": 1.90,
	"f1": [0.340, 0.820, 0.0, 0.00], "f2": [1.00, 0.00, 0.00, 0.30],
	"f3": [0.055, 0.00, 0.00, 0.00]},
# THREE, IN A TIDY ROW (G5b): the moon and two pebbles. 3.0 pebbles drew four discs in a loose
# cluster, and the name, the blurb and Grig's ask all count three.
"pebble_moons":  {"draw": "moonrim", "scale": 1.00, "seed": 3.20,
	"f1": [0.130, 0.550, 2.0, 0.00], "f2": [1.00, 0.00, 0.00, -0.20],
	"f3": [0.050, 0.00, 0.00, 0.00]},
"first_light":   {"draw": "moonrim", "scale": 1.05, "seed": 4.50,
	"f1": [0.440, 0.975, 0.0, 0.00], "f2": [0.50, 0.00, 0.00, 0.90],
	"f3": [0.030, 0.00, 0.00, 0.00]},
"crumb_moon":    {"draw": "moonrim", "scale": 1.00, "seed": 5.80,
	"f1": [0.085, 0.450, 0.0, 0.00], "f2": [1.00, 0.00, 0.00, 1.20],
	"f3": [0.060, 0.00, 0.00, 0.00]},
"shepherd_moon": {"draw": "moonrim", "scale": 1.00, "seed": 7.10,
	"f1": [0.160, 0.550, 0.0, 1.00], "f2": [0.80, 0.00, 0.00, 0.12],
	"f3": [0.050, 0.00, 0.00, 0.00]},
"mirror_moon":   {"draw": "moonrim", "scale": 1.00, "seed": 8.40,
	"f1": [0.270, 0.250, 0.0, 0.00], "f2": [0.00, 1.00, 0.00, -0.50],
	"f3": [0.100, 0.00, 0.00, 0.00]},
"green_moon":    {"draw": "moonrim", "scale": 1.10, "seed": 9.70,
	"f1": [0.400, -0.100, 0.0, 0.00], "f2": [1.00, 0.00, 0.00, -0.35],
	"f3": [0.090, 0.00, 0.00, 0.00]},
"green_flash":   {"draw": "moonrim", "scale": 1.00, "seed": 11.0,
	"f1": [0.200, 0.950, 0.0, 0.00], "f2": [0.40, 0.00, 1.00, 1.50],
	"f3": [0.020, 0.00, 0.00, 0.00]},

# ---------------------------------------------------------------- limb: the world below
"home_aurora":   {"draw": "limb", "scale": 1.00, "seed": 2.20,
	"f1": [1.00, 1.050, 5.0, 0.550], "f2": [0.00, 0.000, 0.00, 0.00],
	"f3": [0.00, 0.00, 0.00, 0.00]},
"vela_crown":    {"draw": "limb", "scale": 1.00, "seed": 3.50,
	"f1": [1.00, 0.380, 3.0, 0.180], "f2": [0.00, -0.050, 0.00, 0.00],
	"f3": [0.00, 0.00, 0.30, 0.00]},
"dust_veil":     {"draw": "limb", "scale": 1.00, "seed": 4.80,
	"f1": [0.00, 0.620, 1.0, 0.260], "f2": [1.00, 0.550, 0.00, -0.18],
	"f3": [0.00, 0.00, 0.00, 0.00]},
"heat_shimmer":  {"draw": "limb", "scale": 1.00, "seed": 6.10,
	"f1": [0.00, 0.820, 1.0, 0.028], "f2": [1.00, 0.100, 0.55, 0.00],
	"f3": [0.00, 0.00, 0.00, 0.00]},
"glass_tide":    {"draw": "limb", "scale": 1.00, "seed": 7.40,
	"f1": [0.00, 0.300, 1.0, 0.350], "f2": [0.00, 0.400, 0.00, 0.12],
	"f3": [0.00, 0.00, 1.00, 0.55]},
# BANK. No lamps at all now: a lumpy white ridge lying in the hollows, with ridges and gaps you
# can count. The lamps were what made it a third "warm glow on a rim".
"fen_fog":       {"draw": "limb", "scale": 1.00, "seed": 8.70,
	"f1": [0.00, 0.300, 3.0, 0.300], "f2": [0.00, 0.000, 0.00, -0.05],
	"f3": [0.00, 0.00, 1.00, 0.00]},
"lamp_line":     {"draw": "limb", "scale": 1.00, "seed": 10.0,
	"f1": [0.00, 0.300, 6.0, 0.300], "f2": [0.00, 0.000, 0.00, 0.06],
	"f3": [1.60, 0.00, 0.00, 0.00]},
# HALOES. Small warm cores, each inside a big COLD halo, because the light is coming up through
# ice. f3.z (fog) is what turns the halo on.
"vela_lamps":    {"draw": "limb", "scale": 1.00, "seed": 11.3,
	"f1": [0.00, 0.300, 6.0, 0.300], "f2": [0.00, 0.000, 0.00, 0.04],
	"f3": [2.40, 0.02, 0.22, 0.00]},
# SLABS. f3.y = 2: flat hard-edged strips lying ON the ground with a specular line in each, which
# is what still water looks like from orbit and what a round glow can never look like.
"still_pools":   {"draw": "limb", "scale": 1.00, "seed": 12.6,
	"f1": [0.00, 0.300, 4.0, 0.300], "f2": [0.00, 0.000, 0.00, -0.08],
	"f3": [1.50, 2.00, 0.00, 0.00]},
"star_in_a_pool": {"draw": "limb", "scale": 1.00, "seed": 13.9,
	"f1": [0.00, 0.300, 1.0, 0.300], "f2": [0.00, 0.050, 0.00, 0.00],
	"f3": [2.30, 0.10, 0.00, 0.00]},
"dusk_line":     {"draw": "limb", "scale": 1.00, "seed": 15.2,
	"f1": [0.00, 0.300, 4.0, 0.300], "f2": [0.00, 0.000, 0.00, 0.10],
	"f3": [0.90, 0.00, 0.00, 1.00]},
}


## Everything one slot of the eyepiece needs for one sight, resolved. `e` is a SafariCatalog sight.
## Tints and scale still come from the catalog (they are content); the twelve knobs, the branch and
## the sight's own seed come from here.
static func row(id_or_sight) -> Dictionary:
	var id: String = str(id_or_sight["id"]) if id_or_sight is Dictionary else str(id_or_sight)
	var e: Dictionary = id_or_sight if id_or_sight is Dictionary else _catalog(id)
	var r: Dictionary = ROWS.get(id, {})
	var draw: String = str(r.get("draw", e.get("draw", "pod")))
	return {
		"id": id,
		"kind": int(DRAW.get(draw, 1)),
		"draw": draw,
		"scale": float(r.get("scale", e.get("scale", 1.0))),
		"seed": float(r.get("seed", 1.3)),
		"a": Color(str(e.get("tint_a", "#9be8d0"))),
		"b": Color(str(e.get("tint_b", "#cfe0ff"))),
		"f1": _v4(r.get("f1", [0.0, 0.0, 0.0, 0.0])),
		"f2": _v4(r.get("f2", [0.0, 0.0, 0.0, 0.0])),
		"f3": _v4(r.get("f3", [0.0, 0.0, 0.0, 0.0])),
	}


## THE ONE CALL A CALLER NEEDS. Sets every `sN_*` uniform for slot `slot` from a catalog sight.
## `pos` is in field radii, `blur` 0 (sharp) to 1, `moment` 0..1 - exactly what safari_run.gd
## already computes; this replaces the eight set_shader_parameter lines it writes today.
##
## `zoom` (safari6, 2026-09-21) is the MAGNIFICATION - SafariRun.glass_zoom(). It is 1.0 with the
## scope raised, at the 7-degree field every number in this file was drawn against, and 0.25 with it
## lowered at 28. It multiplies the position AND the scale by the same factor, which is the exact
## statement that a sight keeps its true ANGULAR size while the window changes width: the wide view
## shows the same picture, smaller and further off, and not one knob in ROWS has to be retuned. A
## caller that does not pass it (the contact sheet, the bench) gets the old behaviour exactly.
static func apply(mat: ShaderMaterial, slot: int, sight: Dictionary, pos: Vector2,
		blur: float, moment: float, zoom: float = 1.0) -> void:
	var r := row(sight)
	mat.set_shader_parameter("s%d_kind" % slot, int(r["kind"]))
	mat.set_shader_parameter("s%d_pos" % slot, pos * zoom)
	mat.set_shader_parameter("s%d_blur" % slot, blur)
	mat.set_shader_parameter("s%d_scale" % slot, float(r["scale"]) * zoom)
	mat.set_shader_parameter("s%d_moment" % slot, moment)
	mat.set_shader_parameter("s%d_seed" % slot, float(r["seed"]))
	mat.set_shader_parameter("s%d_a" % slot, r["a"])
	mat.set_shader_parameter("s%d_b" % slot, r["b"])
	mat.set_shader_parameter("s%d_f1" % slot, r["f1"])
	mat.set_shader_parameter("s%d_f2" % slot, r["f2"])
	mat.set_shader_parameter("s%d_f3" % slot, r["f3"])


## Park an unused slot off the field, the way safari_run.gd already does.
static func clear_slot(mat: ShaderMaterial, slot: int) -> void:
	mat.set_shader_parameter("s%d_pos" % slot, Vector2(9.0, 9.0))


static func _v4(a) -> Vector4:
	var v: Array = a
	return Vector4(float(v[0]), float(v[1]), float(v[2]), float(v[3]))


static func _catalog(id: String) -> Dictionary:
	for e in SafariCatalog.SIGHTS:
		if str(e["id"]) == id:
			return e
	return {}
