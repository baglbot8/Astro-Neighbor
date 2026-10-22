extends DecoItem
## Puffball Pouf (Glowshroom Hollow, Zorp's set) - a squat lilac puffball, just the right height to sit
## on, freckled with pale spots, with three tiny glowing-gilled mushrooms sprouting round its foot. It
## breathes out very slowly - a little sigh.
##
## GLOWSHROOM GRAMMAR (shared by all seven pieces): soft lathed domes and fat flared stems, pale spots
## on every cap, and a blue glow under the caps (gills) or in the water. Zorp's violet hollow palette.

const PUFF := Color("#b3a0d6")
const PUFF_DARK := Color("#9682bf")
const CAP := Color("#9a82cc")
const STEM := Color("#dcd3e3")
const SPOT := Color("#ece4f2")
const GILL := Color("#7fc8f0")
const MOSS := Color("#6a7fa8")
const R := 0.25
const H := 0.2
const CY := 0.2

var _puff: Node3D


func _init() -> void:
	footprint = 0.45
	collide_radius = 0.26
	collide_height = 0.42


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	# --- a mossy ring at the foot, and three tiny mushrooms ----------------------------------------
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.0), Vector2(0.27, 0.03), Vector2(0.0, 0.035)]), 16,
		Transform3D.IDENTITY, MOSS)
	var tiny := [[Vector3(0.24, 0.0, -0.17), 0.06, 0.1], [Vector3(-0.27, 0.0, -0.1), 0.05, 0.08], [Vector3(0.1, 0.0, 0.27), 0.045, 0.07]]
	for t in tiny:
		var b: Vector3 = t[0]
		var r: float = t[1]
		var h: float = t[2]
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.45, 0.0), Vector2(r * 0.32, h * 0.6), Vector2(r * 0.3, h),
			Vector2(0.0, h)]), 8, Transform3D(Basis.IDENTITY, b), STEM)
		_cap(kit, glow, b + Vector3(0.0, h, 0.0), r, r * 0.7, CAP, 2, r * 20.0, 10)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.0, "Gills", 0.5, 0.25)

	# --- the puffball itself, on a pivot so it can sigh ---------------------------------------------
	_puff = pivot("Puff")
	var pk := DecoKit.new()
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0)])
	for i in 9:
		var a := lerpf(-1.15, PI * 0.5, float(i) / 8.0)
		prof.append(Vector2(cos(a) * R, CY + sin(a) * H))
	pk.lathe(prof, 20, Transform3D.IDENTITY, PUFF)
	# a soft dimple ring on top where you sit
	pk.torus(Vector3(0.0, CY + H * 0.9, 0.0), 0.1, 0.012, PUFF_DARK, Basis.IDENTITY, 14, 3)
	for k in 9:
		var th := lerpf(0.55, 1.75, fmod(float(k) * 0.618 + 0.13, 1.0))
		var ph := float(k) * 2.39996 + 0.4
		var n := Vector3(sin(th) * cos(ph) / R, cos(th) / H, sin(th) * sin(ph) / R).normalized()
		var p := Vector3(R * sin(th) * cos(ph), CY + H * cos(th), R * sin(th) * sin(ph))
		var s := 0.022 + 0.012 * fmod(float(k) * 0.37, 1.0)
		pk.rbox(p, Vector3(s * 2.0, s * 0.55, s * 2.0), s, SPOT, DecoKit.axis_basis(n), 0)
	add_body(pk.commit(), "Puffball", _puff)
	add_ground_glow(0.7, Color("#7fc8f0"), 0.14)
	animate()


func _animate(time: float, _delta: float) -> void:
	# a long slow sigh: squash a touch and spread, then fill back up
	var s := 0.5 - 0.5 * cos(time * 0.9)
	s = s * s
	_puff.scale = Vector3(1.0 + 0.02 * s, 1.0 - 0.035 * s, 1.0 + 0.02 * s)


## A spotted mushroom cap (the set's motif) whose rim sits at `base`, with glowing blue gills under it.
func _cap(kit: DecoKit, glow: DecoKit, base: Vector3, r: float, h: float, col: Color, spots: int, seed_a: float, segs: int) -> void:
	var prof := PackedVector2Array([Vector2(r * 0.96, -h * 0.08)])
	for i in 7:
		var a := PI * 0.5 * float(i) / 6.0
		prof.append(Vector2(cos(a) * r, sin(a) * h))
	kit.lathe(prof, segs, Transform3D(Basis.IDENTITY, base), col)
	glow.lathe(PackedVector2Array([Vector2(r * 0.22, 0.0), Vector2(r * 0.6, -h * 0.05), Vector2(r * 0.95, -h * 0.08)]), segs,
		Transform3D(Basis.IDENTITY, base), GILL)
	for k in spots:
		var th := lerpf(0.3, 1.1, fmod(float(k) * 0.618 + 0.2, 1.0))
		var ph := seed_a + float(k) * 2.39996
		var n := Vector3(sin(th) * cos(ph) / r, cos(th) / h, sin(th) * sin(ph) / r).normalized()
		var p := base + Vector3(r * sin(th) * cos(ph), h * cos(th), r * sin(th) * sin(ph))
		var s := r * 0.16
		kit.rbox(p, Vector3(s * 2.0, s * 0.55, s * 2.0), s, SPOT, DecoKit.axis_basis(n), 0)
