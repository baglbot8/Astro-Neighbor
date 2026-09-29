class_name CaveRockTex
extends RefCounted
## THE CAVE'S ROCK TEXTURE (CAVE3 2026-09-28, docs/STORY_HOME_SPEC.md 9.5 item 5: "shades of brown ...
## good textures here like our other planets"; STYLE_GUIDE R2.9 rock: "a genuinely rougher microsurface,
## chipped edges, mottled tonal variation at two scales").
##
## Two small tileable greyscale-with-a-warm-drift images, made here from FastNoiseLite at build time (no
## imported art), used by the cave's stone as a TRIPLANAR albedo texture on a plain StandardMaterial3D,
## multiplied with the stone's baked vertex colour. No custom shader on purpose: the cave's look must not
## depend on anything the phone might draw differently (cave_world.gd header, the old cave_lit.gdshader).
## Mipmapped, so the fine grain fades with distance instead of moire-ing (R2.9 "distance fade").
##
##   WALL   sedimentary STRATA (five layers a tile, each its own shade and a slight warm/cool drift, a thin
##          dark bedding line between them, all wavering), mottling at two scales, a fine grain, sparse
##          CRACKS (cellular cell edges, masked so they come in runs, not a net) and pale mineral flecks.
##   FLOOR  packed earth: mottling, grain, a scatter of PEBBLES (cellular cells: a lit cap, a dark rim),
##          a few hairline cracks and dark grit.
## Each is built once per session (static cache): ~65 k pixels in plain GDScript, behind the black fade.

const SIZE := 256
## Five layer shades and warm/cool drifts (value multipliers, all <= 1: the texture only darkens, and the
## stone's vertex colour is authored bright enough for it).
## U1CAVE (9.29, the user: the tunnel "needs more uneven texture"; planets' rock is the bar): the layers
## further apart (0.76-1.0 -> 0.62-1.0), darker bedding lines, a coarser grain and more pits and cracks.
const LAYER_V: Array[float] = [1.0, 0.7, 0.9, 0.62, 0.84]
const LAYER_TINT: Array[Color] = [Color(1.0, 0.98, 0.95), Color(1.0, 0.95, 0.90), Color(0.97, 0.97, 0.98),
	Color(1.0, 0.94, 0.88), Color(0.98, 0.97, 0.96)]

static var _wall: ImageTexture
static var _floor: ImageTexture


static func wall() -> ImageTexture:
	if _wall == null:
		_wall = _make(false)
	return _wall


static func floor_tex() -> ImageTexture:
	if _floor == null:
		_floor = _make(true)
	return _floor


static func _noise_bytes(seed: int, kind: int, freq: float, octaves: int = 3, cell_ret: int = -1) -> PackedByteArray:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.noise_type = kind
	n.frequency = freq
	n.fractal_octaves = octaves
	if kind == FastNoiseLite.TYPE_CELLULAR:
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		n.cellular_return_type = cell_ret
		n.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	var img := n.get_seamless_image(SIZE, SIZE, false, false, 0.1, true)
	if img.get_format() != Image.FORMAT_L8:
		img.convert(Image.FORMAT_L8)
	return img.get_data()


static func _hash(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


static func _make(is_floor: bool) -> ImageTexture:
	var big := _noise_bytes(71 if is_floor else 17, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.012, 3)
	var mid := _noise_bytes(72 if is_floor else 18, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.045, 2)
	var fine := _noise_bytes(73 if is_floor else 19, FastNoiseLite.TYPE_VALUE, 0.4, 2)
	var warp := _noise_bytes(74 if is_floor else 20, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.02, 2)
	var edge := _noise_bytes(75 if is_floor else 21, FastNoiseLite.TYPE_CELLULAR, 0.016, 1,
		FastNoiseLite.RETURN_DISTANCE2_SUB)
	var mask := _noise_bytes(76 if is_floor else 22, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.012, 1)
	var pdist := PackedByteArray()
	var pval := PackedByteArray()
	if is_floor:
		pdist = _noise_bytes(77, FastNoiseLite.TYPE_CELLULAR, 0.06, 1, FastNoiseLite.RETURN_DISTANCE)
		pval = _noise_bytes(78, FastNoiseLite.TYPE_CELLULAR, 0.06, 1, FastNoiseLite.RETURN_CELL_VALUE)
	var out := PackedByteArray()
	out.resize(SIZE * SIZE * 3)
	var L := LAYER_V.size()
	for y in SIZE:
		for x in SIZE:
			var i := y * SIZE + x
			var nb := float(big[i]) / 255.0
			var nm := float(mid[i]) / 255.0
			var nf := float(fine[i]) / 255.0
			var nw := float(warp[i]) / 255.0
			# cracks read the cell edges at a wobbling offset, so they wander instead of running straight
			var ex := posmod(x + roundi((nw - 0.5) * 30.0), SIZE)
			var ey := posmod(y + roundi((nb - 0.5) * 30.0), SIZE)
			var ne := float(edge[ey * SIZE + ex]) / 255.0
			var mk := float(mask[i]) / 255.0
			# mottling at two scales and a fine grain (R2.9 rock)
			var val := (1.0 + 0.26 * (nb - 0.5)) * (1.0 + 0.22 * (nm - 0.5)) * (1.0 + 0.34 * (nf - 0.5)) \
				* (1.0 + 0.14 * (_hash(x, y, 11) - 0.5))
			var tint := Color(1, 1, 1)
			if is_floor:
				# a scatter of pebbles: only some cells hold one, a soft lit cap shading off to its edge
				var pd := float(pdist[i]) / 255.0
				var pv := float(pval[i]) / 255.0
				if pv > 0.74:
					var r := lerpf(0.3, 0.42, (pv - 0.74) / 0.26)
					if pd < r:
						var k := pd / r
						val = (1.06 - 0.16 * k * k) * (1.0 + 0.08 * (nf - 0.5))
						tint = Color(1.0, 0.97, 0.94) if pv > 0.87 else Color(0.97, 0.96, 0.96)
					elif pd < r + 0.05:
						val *= 0.86
				# a few hairline cracks
				if mk > 0.72 and ne < 0.03:
					val *= lerpf(0.7, 1.0, ne / 0.03)
				if _hash(x, y, 3) > 0.988:
					val *= 0.82
			else:
				# strata: layer index from the wavering height, a thin dark bedding line at each boundary
				var lv := fposmod(float(y) / float(SIZE) + (nw - 0.5) * 0.14, 1.0) * float(L)
				var li := int(lv) % L
				var fr := lv - floorf(lv)
				val *= LAYER_V[li]
				tint = LAYER_TINT[li]
				var d := minf(fr, 1.0 - fr)
				if d < 0.035:
					val *= lerpf(0.5, 1.0, d / 0.035)
				# a thin darker streak inside some layers (the planets' bedded rock has them)
				var st := absf(fr - 0.55 - (nm - 0.5) * 0.2)
				if li % 2 == 1 and st < 0.02:
					val *= lerpf(0.72, 1.0, st / 0.02)
				# cracks, in short runs where the mask allows
				if mk > 0.58 and ne < 0.04:
					val *= lerpf(0.5, 1.0, ne / 0.04)
				# pits and pale mineral flecks
				var hh := _hash(x, y, 7)
				if hh > 0.988:
					val = minf(val * 1.15 + 0.06, 1.0)
				elif hh < 0.014:
					val *= 0.66
			val = clampf(val * 0.94, 0.0, 1.0)
			out[i * 3] = int(clampf(val * tint.r, 0.0, 1.0) * 255.0)
			out[i * 3 + 1] = int(clampf(val * tint.g, 0.0, 1.0) * 255.0)
			out[i * 3 + 2] = int(clampf(val * tint.b, 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGB8, out)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
