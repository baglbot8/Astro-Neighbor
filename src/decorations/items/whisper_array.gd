extends DecoItem
## Whisper Array — Vela's signature gift. Three little dishes on a faceted mast, sweeping the sky
## together on one slow turntable, with an amber status lamp at the collar.
##
## WHY IT IS NOT THE SATELLITE DISH AGAIN. The catalog already sells `satellite_dish`: ONE big
## parabolic on a tripod, cream, motionless. This is the opposite reading of the same idea and the
## contrast is the point — an ARRAY is several small ears that only mean something together, which
## is what the Long Array is and what Vela does. Three dishes at 120 degrees, all fixed to one mast
## that turns as a unit, so the thing that reads at 6.5 m is the SWEEP, not any single dish.
##
## PALETTE IS VELA'S, NOT THE STORE'S. Pale ice-blue structure with a plum-grey mast (her own two
## body tones) and exactly one warm accent: the amber collar lamp. Amber is the only warm colour
## allowed on the frost world and it is the colour of her rim lamps, so the gift carries the same
## rule the planet does. Everything else on this prop is cold.
##
## The sweep is deliberately slower than any other animated decoration (0.16 rad/s, a turn every
## ~39 s, against the Ring-Planet Globe's 0.5). On the quietest world in the game a trophy that
## spins at a normal rate reads as machinery; at this rate it reads as listening.

## Vela's own limb tone is #6e5a6b, and that is what this was first built at. On HER world it is
## right; on a green lawn a 40 mm pole at V 0.431 reads as a black stick, because a thin vertical
## against a mid-value background loses its own colour. Lifted one step so it still reads plum and
## not black — the darker tone stays for the collar and booms, where it is a detail on top of pale.
const MAST := Color("#8a7487")
const MAST_DARK := Color("#6e5a6b")
const PAN := Color("#cfd9e4")         ## pale ice, her collector-plate tone
const PAN_RIM := Color("#aebccc")
const PAD := Color("#8b93a4")
const AMBER := Color("#ffc46a")       ## the one warm colour, shared with her trail chevron

## Three dishes, 120 degrees apart, each tipped up off the mast axis.
const DISH_COUNT := 3
const DISH_TILT_DEG := 34.0
const DISH_R := 0.175
const DISH_Y := 0.86
const BOOM := 0.20

var _turntable: Node3D


func _init() -> void:
	footprint = 0.62
	collide_radius = 0.40
	collide_height = 1.15


func _build() -> void:
	# ---- lander pad and mast: the fixed half
	var kit := DecoKit.new()
	# A flat pad with a chamfered rim, the same "struck plate" grammar as her own foot.
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.40, 0.0), Vector2(0.40, 0.045),
		Vector2(0.33, 0.075), Vector2(0.0, 0.075)]), 16, Transform3D.IDENTITY, PAD)
	# Faceted mast — 6 segments, so it reads as a machined hexagonal shaft and not a pipe.
	kit.cone(Vector3(0.0, 0.06, 0.0), 0.062, 0.042, 0.76, MAST, Basis.IDENTITY, 6)
	kit.torus(Vector3(0.0, 0.30, 0.0), 0.070, 0.018, MAST_DARK, Basis.IDENTITY, 6, 4)
	add_body(kit.commit())

	# ---- the turntable: pad-mounted collar, boom arms and the three dishes
	_turntable = pivot("Turntable", Vector3(0.0, DISH_Y, 0.0))
	var t := DecoKit.new()
	t.torus(Vector3.ZERO, 0.055, 0.020, MAST_DARK, Basis.IDENTITY, 8, 4)
	for i in DISH_COUNT:
		var yaw := TAU * float(i) / float(DISH_COUNT)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		# Boom arm out to the dish, then the dish tipped up and outward along it.
		var seat := dir * BOOM
		t.tube(Vector3.ZERO, seat, 0.016, MAST_DARK, 6, 2)
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(-DISH_TILT_DEG))
		# The collector: a shallow cone with a cut rim, not a dome — a struck plate has an edge.
		t.cone(seat, DISH_R, DISH_R * 0.30, 0.052, PAN, basis, 14)
		t.torus(seat + basis.y * 0.052, DISH_R * 0.30, 0.014, PAN_RIM, basis, 10, 4)
		# The feed, on a short stalk at the focus.
		t.tube(seat + basis.y * 0.020, seat + basis.y * 0.115, 0.009, MAST_DARK, 6, 2)
		t.sphere(seat + basis.y * 0.125, 0.026, PAN_RIM, Vector3.ONE, 8)
	add_body(t.commit(), "Dishes", _turntable)

	# ---- the one warm thing on it
	var glow := DecoKit.new()
	glow.torus(Vector3(0.0, 0.30, 0.0), 0.070, 0.011, AMBER, Basis.IDENTITY, 8, 4)
	add_glow(glow.commit(), 2.0, "Collar", 0.55, 0.30)
	add_light(Vector3(0.0, 0.34, 0.0), AMBER, 0.85, 3.4)
	animate()


func _animate(t: float, _delta: float) -> void:
	# One turn every ~39 s. See the header: the slowness is the characterisation.
	_turntable.rotation.y = t * 0.16
