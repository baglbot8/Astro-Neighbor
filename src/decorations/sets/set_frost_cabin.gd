extends RefCounted
## Frost Cabin - Vela's set (docs/SETS_SPEC.md 2-3). Same columns as set_tinker.gd: id, name, category, rarity,
## price, footprint, icon_color, desc. Footprints equal each scene's DecoItem.footprint.
##
## ONE FAMILY. Every piece is built from the same three motif parts below, in the same colours, so the seven
## sort into one set at a glance: a cranberry KNIT BAND (ribbed cuff with a snow-white stripe, like a scarf
## or a jumper cuff), an ICICLE FRINGE (short pale-ice drips hanging from an edge) and KNITTED SNOW (soft
## white lumps sitting on top of things). Colour story: Vela's pale ice and deep navy, warmed by cranberry
## yarn and old sled wood - cosy against the cold.
const SET := {"id": "frost_cabin", "name": "Frost Cabin", "neighbour": "vela",
	"blurb": "Knitted snow and warm corners for a very still, very cold world.",
	"outfit": ["suit_frost_cabin", "hat_frost_bobble"]}
const PIECES: Array = [
	["frost_cabin_snow_pouf", "Snowball Pouf", "furniture", "common", 290, 0.45, "#e6eef5",
		"A soft knitted snowball. Not cold at all."],
	["frost_cabin_icicle_lamp", "Icicle Lamp", "lights", "common", 390, 0.4, "#bfe0f0",
		"A cluster of icicles that glow pale blue at night."],
	["frost_cabin_snowflake_rug", "Snowflake Rug", "furniture", "uncommon", 850, 1.0, "#9fb8d8",
		"A big round rug with one snowflake knitted in the middle."],
	["frost_cabin_sled_bench", "Sled Bench", "furniture", "uncommon", 1000, 0.85, "#b8875a",
		"An old sled turned into a bench. Still a bit slidey."],
	["frost_cabin_ice_table", "Ice Block Table", "furniture", "uncommon", 1300, 0.75, "#cfe6f2",
		"A clear block of ice with a warm knitted runner on top."],
	["frost_cabin_stove", "Pot-Belly Stove", "lights", "rare", 2700, 0.6, "#3f4a6e",
		"A round little stove with a glowing door. Vela's favourite spot."],
]
const BONUS: Array = ["frost_cabin_aurora_lamp", "Aurora Lamp", "lights", "legendary", 0, 0.55, "#7fe0c8",
	"A slow ribbon of green and violet light. Vela caught it on a very still night."]

# ============================================================================================ the family palette
## Pastel per STYLE_GUIDE R2.6: no swatch above S 0.60, near-whites capped at V ~0.92. The toon + crochet shading
## darkens and the grade re-saturates dark colours: a first navy #3f4a6e rendered as S 0.89 V 0.21 and cranberry
## #b8606a as S 0.72 in the home gallery, so these are lifted until the RENDERED swatches sit at or under S 0.60.
const SNOW := Color("#d9e1ea")
const SNOW_SHADE := Color("#bcc8d6")
const ICE := Color("#b6d3e3")
const ICE_DEEP := Color("#8fb2c9")
const NAVY := Color("#69718f")
const NAVY_DARK := Color("#5a6280")
const KNIT := Color("#bd7179")
const KNIT_DARK := Color("#a3626a")
const WOOD := Color("#b8946e")
const WOOD_DARK := Color("#94806a")
## Night glows (the emissive tint is the vertex colour).
const ICE_GLOW := Color("#8ccbe8")
const EMBER := Color("#eaa665")


# ============================================================================================ the shared motif
## KNIT BAND: a ribbed cranberry cuff `height` tall around a post or body of radius `r`, bottom at `origin`,
## with a snow-white stripe knitted through the middle. `basis` tilts it (default: upright).
static func knit_band(kit: DecoKit, origin: Vector3, r: float, height: float, segments: int = 16,
		basis: Basis = Basis.IDENTITY) -> void:
	var t := r * 0.13 + 0.006  # how far the ribs stand proud of the body
	var h := height
	var xf := Transform3D(basis, origin)
	# bottom rib and top rib (cranberry), each a soft rolled edge
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(r + t * 0.6, 0.0), Vector2(r + t, h * 0.17), Vector2(r + t * 0.75, h * 0.36),
		Vector2(0.0, h * 0.36)]), segments, xf, KNIT)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, h * 0.64), Vector2(r + t * 0.75, h * 0.64), Vector2(r + t, h * 0.83), Vector2(r + t * 0.6, h),
		Vector2(0.0, h)]), segments, xf, KNIT)
	# the white stripe between them
	kit.lathe(PackedVector2Array([
		Vector2(0.0, h * 0.36), Vector2(r + t * 0.8, h * 0.36), Vector2(r + t * 0.8, h * 0.64),
		Vector2(0.0, h * 0.64)]), segments, xf, SNOW)


## ICICLE FRINGE: `count` drips hanging from a ring of radius `r` around `origin` (in the basis XZ plane), lengths
## `len_min`..`len_max` in one fixed irregular pattern, so every fringe in the set has the same "hand".
## `arc` < TAU spreads them over part of the ring, ends included.
static func icicle_fringe(kit: DecoKit, origin: Vector3, r: float, count: int, len_min: float, len_max: float,
		thick: float, color: Color = ICE, basis: Basis = Basis.IDENTITY, arc: float = TAU, arc_start: float = 0.0) -> void:
	var full := absf(arc - TAU) < 0.001
	for i in count:
		var f := (float(i) + 0.5) / float(count) if full else float(i) / float(maxi(count - 1, 1))
		var a := arc_start + arc * f
		var k := icicle_hand(i)
		var p := origin + basis * Vector3(cos(a) * r, 0.0, sin(a) * r)
		icicle(kit, p, lerpf(len_min, len_max, k), thick * lerpf(0.8, 1.15, k), color, basis)


## A straight row of drips from `a` to `b` (both ends included), same hand as the ring fringe.
static func icicle_row(kit: DecoKit, a: Vector3, b: Vector3, count: int, len_min: float, len_max: float,
		thick: float, color: Color = ICE, phase: int = 0) -> void:
	for i in count:
		var k := icicle_hand(i + phase)
		var p := a.lerp(b, float(i) / float(maxi(count - 1, 1)))
		icicle(kit, p, lerpf(len_min, len_max, k), thick * lerpf(0.8, 1.15, k), color)


## One drip: a short fat collar and a long point, hanging DOWN from `top` along -basis.y.
static func icicle(kit: DecoKit, top: Vector3, length: float, thick: float, color: Color,
		basis: Basis = Basis.IDENTITY) -> void:
	var down := basis * Basis(Vector3.RIGHT, PI)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.004), Vector2(thick, -0.004), Vector2(thick * 0.7, length * 0.35),
		Vector2(0.0, length)]), 7, Transform3D(down, top), color, true)


## The fixed irregular length pattern every fringe in the set shares (0..1).
static func icicle_hand(i: int) -> float:
	const HAND := [0.55, 1.0, 0.3, 0.75, 0.15, 0.9, 0.45, 0.65, 0.2, 0.85]
	return HAND[i % HAND.size()]


## KNITTED SNOW: a soft lump of snow sitting ON a surface at `base` (three overlapping squashed puffs). Each puff dips
## 0.13 x size below `base`, so a lump on the ground must be raised by that much or it pokes under the item's base.
static func snow_lump(kit: DecoKit, base: Vector3, size: float, basis: Basis = Basis.IDENTITY, seed_i: int = 0) -> void:
	var offs := [Vector3(0.0, 0.0, 0.0), Vector3(0.55, 0.0, 0.25), Vector3(-0.45, 0.0, 0.35)]
	var sc := [1.0, 0.7, 0.62]
	for j in 3:
		var o: Vector3 = offs[(j + seed_i) % 3] * size
		var s: float = size * float(sc[j])
		kit.sphere(base + basis * (o + Vector3(0.0, s * 0.42, 0.0)), s, SNOW, Vector3(1.0, 0.55, 1.0), 10, basis)


## A double-sided ribbon through `path`, `widths` tall along `up` at each point, coloured `bottom`..`top`
## across its width (aurora curtains). Both faces are emitted because the glow shader culls back faces.
static func ribbon(kit: DecoKit, path: PackedVector3Array, widths: PackedFloat32Array, up: Vector3,
		bottom: Color, top: Color) -> void:
	var n := path.size()
	for side in 2:
		var base := kit.vertex_count()
		for i in n:
			var tan := (path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]).normalized()
			var nrm := tan.cross(up).normalized()
			if side == 1:
				nrm = -nrm
			kit._push(path[i], nrm, bottom, Vector2(float(i) / float(n - 1), 0.0))
			kit._push(path[i] + up * widths[i], nrm, top, Vector2(float(i) / float(n - 1), 1.0))
		var idx := PackedInt32Array()
		for i in n - 1:
			var a := i * 2
			if side == 0:
				idx.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
			else:
				idx.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
		kit._push_indices(base, idx)
