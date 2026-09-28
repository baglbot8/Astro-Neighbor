extends Node3D
## THE NEIGHBOURS' PACKED SHIPS (docs/STORY_HOME_SPEC.md §2 rulings 2 and 8, §3 beats 6 and 9; T2).
## Everyone was packing to leave together once your ship was fixed. At the finale the five getaway ships
## stand parked round the Commons for the goodbye party, fly up on autopilot beside your rocket to knock
## the meteor apart (docs/STORY_HOME_SPEC.md §8.1), and come back down onto their spots under the shower
## BRUISED BUT WORKING (`set_bruised`, `bruised_xf`: soot, scratches and a lean). Procedural, small (1.8-2.2 m against the
## rocket's 3.2 m) and each in its owner's own palette AS SEEN AT NIGHT (see "palettes" below: the finale
## is always at night, so the albedos are the night inversion of the owners' daylight swatches), with a
## crate or two strapped on: they are packed.
##
## OWNED BY THE MEETING. finale_meeting.gd creates this node (by path, no class_name) as a child of
## /root/World/Rocket once the crowd has its spots, and calls `place()`. Parented under the pad node ON
## PURPOSE: VisitorSystem's occluder space (`open_sight`, the meeting's shot search and FinaleLaunch's side
## pick) and the meeting's lens test (`_collect_occluders`) both walk the pad's subtree, so every sight
## line and every camera candidate sees the ships as the solid things they are, with no change to either
## of those files. Nothing under the pad is named "Interactable" or is a Camera3D, the two things
## rocket_pad.gd looks for in its own subtree.
##
## PARKING (`place`). Round the crowd centre, at PARK's azimuth and distance per owner (0 deg is straight
## out behind the crowd, away from the pad; positive is the astronaut's right as they face the crowd), in
## the crowd's own left-to-right order (Grig, Fen | Zorp | Bolt, Vela), hatch toward the square. Each spot
## is searched outward from its preference (AZ_STEPS x RHO_STEPS) until it passes: VisitorSystem's ground
## rules at the centre and four points on FOOT_R (the meeting's `_ground`), PAD_GAP from the pad,
## CROWD_GAP from every crowd spot and step-back spot and the astronaut's mark, SHIP_GAP from the ships
## already parked, and EYE_GAP from every eye of FinaleLaunch's authored send-off path (both sides - the
## side is picked later) unless that eye passes EYE_OVER above the hull. Deterministic: the same crowd on
## the same Commons parks the same ships, so a reload at any stage finds them where they were.
##
## FLIGHT. `set_flame(id, k)` grows a plume under a ship (a glow cone on MaterialLib.glow - the toon
## shader every Commons character already draws, so no new shader compiles). FinaleLaunch moves the ships
## by their transforms and hides them in the flash; FinaleGift (HOME) lands them on `bruised_xf(id)`;
## `park_all()` puts them back upright. They stay parked after the story until the Commons reloads (the
## meeting, which makes this node, only exists at finale stages 1-3).
##
## BRUISES (`set_bruised`). One extra vertex-coloured mesh per ship on the same body material (soot blotches
## and pale scratches on the hatch side, the side the crowd sees): +1 draw a bruised ship, no new material.
##
## HEAT. Per ship: one vertex-coloured body mesh on Building.body_material() (the Commons' own buildings
## draw it, so it is compiled before the meeting), one small glow mesh, and one plume shown only in
## flight: 10 draws parked, 15 flying. No shadows are added beyond what a MeshInstance3D casts by default.

const NODE_NAME := "NeighbourShips"
## The crowd's front row, the astronaut's left to right (finale_meeting.gd FRONT without the Professor).
const OWNERS: PackedStringArray = ["grig", "fen", "zorp", "bolt", "vela"]
## Preferred [azimuth deg, distance m] round the crowd centre. MEASURED against FinaleLaunch's authored
## eyes: its opening eye stands at +-30 deg, 4.4 m (behind the crowd), its faces eye at +-150 deg, 4.8 m;
## these keep >= 3.1 m from both.
const PARK := {"grig": [-118.0, 6.6], "fen": [-74.0, 6.9], "zorp": [0.0, 6.3], "bolt": [74.0, 6.9], "vela": [118.0, 6.6]}
const AZ_STEPS: Array[float] = [0.0, 8.0, -8.0, 16.0, -16.0, 24.0, -24.0, 34.0, -34.0]
const RHO_STEPS: Array[float] = [0.0, 0.7, -0.4, 1.4, 2.1]
## The whole-ring sweep after the neighbourhood: azimuths within +-SWEEP_AZ_MAX of straight behind the crowd
## (never the pad's side), at these distances from the crowd centre.
const SWEEP_AZ_MAX := 150.0
const SWEEP_AZ_STEP := 7.5
const SWEEP_RHO: Array[float] = [5.8, 6.5, 7.2, 7.9, 8.6, 9.4]
const FOOT_R := 0.95
const PAD_GAP := 4.4
const CROWD_GAP := 2.0
const SHIP_GAP := 3.0
const EYE_GAP := 2.4
const EYE_OVER := 1.3
const EYE_GAP_LOW := 4.2
const EYE_LOW_H := 6.0
## The pilot boards here: this far out from the hull's axis, on the hatch side.
const DOOR_M := 1.3
const BLOCK_LAYER := 1 << 3
const FLAME_COLOR := Color("#ffd7a0")

# ------------------------------------------------------------------------------------ palettes
## THE SHIPS ARE ONLY EVER SEEN AT NIGHT (the meeting holds the clock at night; the ships exist only in the
## finale), and the Commons' night turns a mid-tone albedo royal blue: the night ambient, the moon and the
## night colour grade (environment.gd GRADE_NIGHT) all lean blue. MEASURED (critic, round 1, and again here:
## 1280x720, gl_compatibility, ships-shown minus ships-hidden masks, the meeting's first box): with the
## owners' daylight swatches as albedos, Zorp's lilac, Fen's slate and Bolt's teal all rendered as the same
## royal blue, S 0.68-0.75 median (hue 213-231), against R2.6's "no dominant swatch above S 0.60"; a neutral
## grey #a0a0a0 hull rendered #3a5691 (S 0.60) and even white rendered S 0.22-0.30, on the moonlit side and
## on the shaded side alike.
##
## So NIGHT_PAL is not tuned: it is the exact per-channel inverse of that measured night transfer. Every hull
## was painted flat grey at 0x40/0x70/0xa0/0xd0/0xff and rendered on its parking spot at the meeting's night
## hour (the transfer curve, per channel, grey albedo -> rendered colour); each swatch's target is its
## owner's DAYLIGHT swatch (DAY_PAL: hue and saturation kept, value = the night value a grey of the same
## value renders at), and the albedo is read back off the curve. Grig's ship stands under the plaza lamps,
## so his inverse uses his own spot's curve; the other four share the median of theirs. The result looks
## warm and pale as an albedo and renders as the owner's own colour at night: MEASURED on the same frames,
## ship median S 0.05-0.33, p90 <= 0.44, Zorp lilac, Bolt teal, Fen slate, Grig clay, Vela ivory, crates
## cardboard - on the side facing the crowd and on the moonlit side. Re-derive (do not hand-edit) if the
## night palette, the grade or the finale hour ever changes.
##
## The owners' daylight swatches (from each character model, src/characters/models/*_model.gd) - the targets.
const DAY_PAL := {
	"zorp": {"body": Color("#8f7bbf"), "dark": Color("#6f6199"), "band": Color("#7fb0aa"), "trim": Color("#ddd3c1"),
		"leg": Color("#5f567f")},
	"bolt": {"body": Color("#76aaa5"), "dark": Color("#5b8783"), "band": Color("#b89872"), "trim": Color("#9ea8b5"),
		"leg": Color("#5d6a78")},
	"fen": {"body": Color("#6f86ad"), "dark": Color("#56698a"), "band": Color("#b99690"), "trim": Color("#8f6f68"),
		"leg": Color("#4a4f66")},
	"grig": {"body": Color("#b39a80"), "dark": Color("#8a735e"), "band": Color("#64798a"), "trim": Color("#d4ccb6"),
		"leg": Color("#5a4f45")},
	"vela": {"body": Color("#d0c6b4"), "dark": Color("#b0a592"), "band": Color("#a8837a"), "trim": Color("#6e5a6b"),
		"leg": Color("#4e414d")},
	"all": {"crate": Color("#b49c78"), "strap": Color("#5b4a3a"), "port": Color("#2b3148")},
}
## The albedos actually painted: DAY_PAL through the measured night inverse (above). "glow" is emissive (the
## lamps) and is not inverted.
const PAL := {
	"zorp": {"body": Color("#deb5bf"), "dark": Color("#c49a99"), "band": Color("#d1efaa"), "trim": Color("#ffffbd"),
		"leg": Color("#b6927f"), "crate": Color("#fdda75"), "strap": Color("#b4882e"), "port": Color("#7b7348"),
		"glow": Color("#8fe8cf")},
	"bolt": {"body": Color("#c9e9a5"), "dark": Color("#b2c683"), "band": Color("#ffd66f"), "trim": Color("#ebe7b5"),
		"leg": Color("#b4a578"), "crate": Color("#fdda75"), "strap": Color("#b4882e"), "port": Color("#7b7348"),
		"glow": Color("#ffd98a")},
	"fen": {"body": Color("#c3c3ad"), "dark": Color("#ada28a"), "band": Color("#ffd48e"), "trim": Color("#e0a966"),
		"leg": Color("#a38c66"), "crate": Color("#fdda75"), "strap": Color("#b4882e"), "port": Color("#7b7348"),
		"glow": Color("#ffd9a0")},
	"grig": {"body": Color("#e1c380"), "dark": Color("#bb9f5f"), "band": Color("#9ca48a"), "trim": Color("#fff6b2"),
		"leg": Color("#928046"), "crate": Color("#e2c579"), "strap": Color("#937b33"), "port": Color("#625f48"),
		"glow": Color("#f2d9a6")},
	"vela": {"body": Color("#ffffb3"), "dark": Color("#fae490"), "band": Color("#f4bf77"), "trim": Color("#c5966b"),
		"leg": Color("#a8814d"), "crate": Color("#fdda75"), "strap": Color("#b4882e"), "port": Color("#7b7348"),
		"glow": Color("#d8a25c")},
}

var planet: Planet
var note := ""
var _ships: Dictionary = {}
var _parked: Dictionary = {}
var _flames: Dictionary = {}
var _heights: Dictionary = {}
## True after `send_home` (no longer called since §8.1: the ships come back).
var gone := false
var _bruised: Dictionary = {}
## Bruised: the lean a landed ship keeps (deg), and the marks' colours.
const LEAN_DEG := 4.0
const SOOT := Color("#2b2522")
const SCRATCH := Color("#efe3cc")


# ============================================================================= parking
## Parks the five ships. `centre` is the crowd centre on the ground, `pad_ground` the pad's, `right` a
## tangent at the centre pointing to the astronaut's right as they face the crowd, `avoid` every ground
## point a ship must keep CROWD_GAP from, `eyes` FinaleLaunch.eye_samples(), and `ground` the meeting's
## ground test (a surface direction -> "" when clear).
func place(p: Planet, centre: Vector3, pad_ground: Vector3, right: Vector3, avoid: Array, eyes: PackedVector3Array, ground: Callable) -> void:
	planet = p
	var up_c := planet.dir_of(centre)
	var away := _tangent(centre - pad_ground, up_c, right.cross(up_c))
	var r := _tangent(right, up_c, away.cross(up_c))
	var notes := PackedStringArray()
	for id in OWNERS:
		var ship := _ships.get(id) as Node3D
		if ship == null:
			ship = make_ship(id)
			ship.name = "Ship_" + id
			add_child(ship)
			_ships[id] = ship
			_flames[id] = ship.get_node_or_null("Flame")
			_heights[id] = float(ship.get_meta("height", 2.0))
		var pref: Array = PARK[id]
		var found := false
		var chosen := Vector3.ZERO
		var tried := 0
		var why := ""
		var whys := {}
		for c: Vector2 in _candidates(float(pref[0]), float(pref[1])):
			tried += 1
			var d := _park_dir(up_c, away, r, c.x, c.y)
			var w := _spot_problem(id, d, pad_ground, avoid, eyes, ground)
			if w == "":
				chosen = d
				found = true
				break
			if why == "":
				why = w
			var wk := w.get_slice(":", 0).get_slice("@", 0)
			whys[wk] = int(whys.get(wk, 0)) + 1
		if not found:
			chosen = _park_dir(up_c, away, r, float(pref[0]), float(pref[1]))
			push_warning("NeighbourShips: no clear spot for %s's ship (first problem: %s); parking on its preferred spot" % [id, why])
		var face := centre - planet.surface_point(chosen)
		var xf := planet.surface_transform(chosen, face)
		_parked[id] = xf
		ship.global_transform = xf
		ship.visible = true
		notes.append("%s:%s@%.1fm/%d%s" % [id, "ok" if found else "FORCED(" + why + ")", planet.surface_point(chosen).distance_to(centre), tried,
			"" if found else " " + str(whys)])
	note = " ".join(notes)


## The spots tried for one ship, in order: the neighbourhood of its preference (AZ_STEPS x RHO_STEPS),
## then a sweep of the whole ring (SWEEP_AZ x SWEEP_RHO, away from the pad's side) nearest the preference
## first.
func _candidates(az: float, rho: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for dr in RHO_STEPS:
		for da in AZ_STEPS:
			out.append(Vector2(az + da, rho + dr))
	var sweep: Array[Vector2] = []
	var a := -SWEEP_AZ_MAX
	while a <= SWEEP_AZ_MAX + 0.01:
		for rr: float in SWEEP_RHO:
			sweep.append(Vector2(a, rr))
		a += SWEEP_AZ_STEP
	sweep.sort_custom(func(p: Vector2, q: Vector2) -> bool:
		return absf(p.x - az) + 6.0 * absf(p.y - rho) < absf(q.x - az) + 6.0 * absf(q.y - rho))
	out.append_array(sweep)
	return out


func _park_dir(up_c: Vector3, away: Vector3, right: Vector3, az_deg: float, rho: float) -> Vector3:
	var a := deg_to_rad(az_deg)
	var v := (away * cos(a) + right * sin(a)).normalized()
	var ang := rho / maxf(planet.radius, 1.0)
	return (up_c * cos(ang) + v * sin(ang)).normalized()


func _spot_problem(id: String, d: Vector3, pad_ground: Vector3, avoid: Array, eyes: PackedVector3Array, ground: Callable) -> String:
	var p := planet.surface_point(d)
	if p.distance_to(pad_ground) < PAD_GAP:
		return "pad"
	for q: Vector3 in avoid:
		if p.distance_to(q) < CROWD_GAP:
			return "crowd"
	for other: String in _parked:
		if other != id and p.distance_to((_parked[other] as Transform3D).origin) < SHIP_GAP:
			return "ship:" + other
	var up := planet.dir_of(p)
	var h := float(_heights.get(id, 2.0))
	for e: Vector3 in eyes:
		var v := e - p
		var over := v.dot(up)
		var flat := (v - up * over).length()
		# A low eye (the opening and the faces frame, the crane's first metres) looks out across the ground:
		# a ship there lifts off right beside the lens (MEASURED, first run: Zorp's ship 2.5 m from the
		# opening eye filled a third of the frame at 2.0 s), so it keeps EYE_GAP_LOW.
		var gap := EYE_GAP_LOW if over < EYE_LOW_H else EYE_GAP
		if flat < gap and over < h + EYE_OVER + (EYE_LOW_H if over < EYE_LOW_H else 0.0):
			return "launch-eye"
	if ground.is_valid():
		var g := str(ground.call(d))
		if g != "":
			return g
		var xf := planet.surface_transform(d)
		for k in 4:
			var ang := TAU * float(k) / 4.0 + 0.4
			var t := xf.basis.x * cos(ang) + xf.basis.z * sin(ang)
			var d2 := (d + t * (FOOT_R / planet.radius)).normalized()
			var g2 := str(ground.call(d2))
			if g2 != "" and g2 != "pad" and g2 != "landing":
				return g2 + "@rim"
	return ""


# ============================================================================= queries
func ids() -> PackedStringArray:
	return OWNERS


func ship(id: String) -> Node3D:
	var s: Variant = _ships.get(id, null)
	return s as Node3D if s != null and is_instance_valid(s) else null


func parked(id: String) -> Transform3D:
	return _parked.get(id, Transform3D.IDENTITY)


func height_of(id: String) -> float:
	return float(_heights.get(id, 2.0))


## Where `id`'s pilot stands to board: DOOR_M out from the hull on the hatch side, as a surface direction.
func door_dir(id: String) -> Vector3:
	if not _parked.has(id) or planet == null:
		return Vector3.ZERO
	var xf: Transform3D = _parked[id]
	return planet.dir_of(xf.origin - xf.basis.z.normalized() * DOOR_M)


## True when a surface direction is within `clear` metres of a parked ship's footprint (for a released
## neighbour's wander test).
func blocks(dir: Vector3, clear: float = 0.6) -> bool:
	if planet == null or gone:
		return false
	var p := planet.surface_point(dir)
	for id: String in _parked:
		if p.distance_to((_parked[id] as Transform3D).origin) < FOOT_R + clear:
			return true
	return false


## The fleet has flown (docs/STORY_HOME_SPEC.md ruling 2.14 (c), the user 2026-09-27: "after they send their
## ships to destroy the meteor, i still see all the ships after the cutscene?"). Every ship is freed - no
## parked ship during the shower, HOME or after the story; they went home, everyone stays. Idempotent.
## `park_all` does nothing after this (HOME's `stage_home` calls it), and `blocks` is false.
func send_home() -> void:
	gone = true
	for id: String in _ships:
		var s := ship(id)
		if s != null:
			s.queue_free()
	_ships.clear()
	_flames.clear()


## Every ship back on its spot, visible, plume off: upright, or leaning on `bruised_xf` once bruised.
## Nothing after `send_home`.
func park_all() -> void:
	if gone:
		return
	for id: String in _parked:
		var s := ship(id)
		if s == null:
			continue
		s.global_transform = bruised_xf(id) if is_bruised(id) else _parked[id]
		s.visible = true
		set_flame(id, 0.0)


## Bruised but working (docs/STORY_HOME_SPEC.md §8.1: "the ships come back bruised but working"): soot and
## scratches on the hull, on or off. Idempotent.
func set_bruised(id: String, on: bool) -> void:
	var s := ship(id)
	if s == null:
		return
	var b := s.get_node_or_null("Bruise") as Node3D
	if on and b == null:
		b = _make_bruise(id, float(s.get_meta("hull_r", 0.7)), float(s.get_meta("height", 2.0)))
		s.add_child(b)
	if b != null:
		b.visible = on
	_bruised[id] = on


func is_bruised(id: String) -> bool:
	return bool(_bruised.get(id, false))


## Where a bruised ship stands once it has landed: its parked spot, leaning LEAN_DEG about a ground axis of
## its own (fixed per owner, so a reload would lean it the same way).
func bruised_xf(id: String) -> Transform3D:
	var xf: Transform3D = _parked.get(id, Transform3D.IDENTITY)
	var ang := float(OWNERS.find(id) * 73 % 360)
	var ax := (xf.basis.x * cos(deg_to_rad(ang)) + xf.basis.z * sin(deg_to_rad(ang))).normalized()
	return Transform3D(Basis(ax, deg_to_rad(LEAN_DEG)) * xf.basis, xf.origin)


## The bruise node: "Marks" (soot and scratches, one draw). No smoke: a puff sphere rendered as a solid blue
## ball at night (MEASURED on the first run's HOME frames), not a wisp.
static func _make_bruise(id: String, hull_r: float, h: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Bruise"
	var kit := PlanetMeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	# The hatch faces -Z (the crowd); marks spread over the front half, a little proud of the hull.
	for i in 5:
		var a := deg_to_rad(-90.0 + rng.randf_range(-70.0, 70.0))
		var y := rng.randf_range(0.55, maxf(0.7, h * 0.62))
		var n := Vector3(cos(a), 0.0, sin(a))
		var basis := Basis.looking_at(n, Vector3.UP)
		kit.sphere(n * (hull_r * 0.97) + Vector3(0.0, y, 0.0), rng.randf_range(0.13, 0.22), SOOT, Vector3(1.0, 0.75, 0.22), 10, basis)
	for i in 3:
		var a2 := deg_to_rad(-90.0 + rng.randf_range(-55.0, 55.0))
		var y2 := rng.randf_range(0.6, maxf(0.75, h * 0.55))
		var n2 := Vector3(cos(a2), 0.0, sin(a2))
		var b2 := Basis.looking_at(n2, Vector3.UP) * Basis(Vector3.FORWARD, rng.randf_range(-0.6, 0.6))
		kit.rounded_box(n2 * (hull_r * 1.0) + Vector3(0.0, y2, 0.0), Vector3(0.34, 0.035, 0.03), 0.01, SCRATCH, b2)
	var marks := MeshInstance3D.new()
	marks.name = "Marks"
	marks.mesh = kit.commit()
	marks.material_override = Building.body_material()
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(marks)
	return root


func set_all_visible(v: bool) -> void:
	for id: String in _ships:
		var s := ship(id)
		if s != null:
			s.visible = v


## The plume under `id`'s ship at strength `k` (0 = off). A flicker rides on it from the ship's own clock.
func set_flame(id: String, k: float, t: float = 0.0) -> void:
	var fv: Variant = _flames.get(id, null)
	var f := fv as Node3D if fv != null and is_instance_valid(fv) else null
	if f == null:
		return
	if k <= 0.01:
		f.visible = false
		return
	var fl := 1.0 + 0.09 * sin(t * 31.0 + float(id.hash() % 7)) + 0.05 * sin(t * 57.0)
	f.scale = Vector3(0.75 + 0.25 * k, k * fl, 0.75 + 0.25 * k)
	f.visible = true


# ============================================================================= the models
## One ship, built procedurally: origin at ground contact, +Y up, hatch facing -Z. Children: "Body" (the
## vertex-coloured hull, legs, hatch and crates - one draw), "Glow" (lamps, one draw), "Flame" (hidden
## until flight), "Blocker" (a StaticBody3D on the decoration layer, so the astronaut bumps into it).
static func make_ship(id: String) -> Node3D:
	var root := Node3D.new()
	var pal: Dictionary = PAL.get(id, PAL["bolt"])
	var kit := PlanetMeshKit.new()
	var glow := PlanetMeshKit.new()
	var info := {}
	match id:
		"zorp":
			info = _zorp(kit, glow, pal)
		"fen":
			info = _fen(kit, glow, pal)
		"grig":
			info = _grig(kit, glow, pal)
		"vela":
			info = _vela(kit, glow, pal)
		_:
			info = _bolt(kit, glow, pal)
	_crates(kit, float(info.get("crate_r", 0.7)), int(info.get("crates", 1)), pal)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = kit.commit()
	body.material_override = Building.body_material()
	root.add_child(body)
	var gm := MeshInstance3D.new()
	gm.name = "Glow"
	gm.mesh = glow.commit()
	gm.material_override = MaterialLib.glow(pal["glow"], 1.3)
	gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gm)
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	var cone := CylinderMesh.new()
	cone.top_radius = float(info.get("nozzle_r", 0.26)) * 0.9
	cone.bottom_radius = 0.02
	cone.height = 1.1
	cone.radial_segments = 8
	cone.rings = 1
	flame.mesh = cone
	flame.material_override = MaterialLib.glow(FLAME_COLOR, 2.4)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The cone hangs from a pivot at the nozzle's mouth, so scaling the pivot grows it downward.
	var pivot := Node3D.new()
	pivot.name = "Flame"
	pivot.position = Vector3(0.0, float(info.get("nozzle_y", 0.14)), 0.0)
	flame.name = "Cone"
	flame.position = Vector3(0.0, -0.55, 0.0)
	pivot.add_child(flame)
	pivot.visible = false
	root.add_child(pivot)
	var blocker := StaticBody3D.new()
	blocker.name = "Blocker"
	blocker.collision_layer = BLOCK_LAYER
	blocker.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = float(info.get("hull_r", 0.7)) + 0.12
	cyl.height = 1.7
	cs.shape = cyl
	cs.position = Vector3(0.0, 0.85, 0.0)
	blocker.add_child(cs)
	root.add_child(blocker)
	root.set_meta("height", float(info.get("height", 2.0)))
	root.set_meta("hull_r", float(info.get("hull_r", 0.7)))
	root.set_meta("owner", id)
	return root


## Three or four splayed legs from `r0` at height `y0` out to feet on the ground at `r1`, with round pads.
static func _legs(kit: PlanetMeshKit, n: int, r0: float, y0: float, r1: float, col: Color, pad: Color, phase: float = 0.0, thick: float = 0.06) -> void:
	for k in n:
		var ang := phase + TAU * float(k) / float(n)
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var top := dir * r0 + Vector3.UP * y0
		var foot := dir * r1 + Vector3.UP * 0.07
		var axis := (top - foot)
		var leg_len := axis.length()
		var b := Basis(Quaternion(Vector3.UP, axis.normalized()))
		kit.cylinder(foot, thick * 1.15, thick * 0.9, leg_len, col, b, 6)
		kit.cylinder(dir * r1 + Vector3.UP * 0.0, 0.15, 0.12, 0.07, pad, Basis.IDENTITY, 8)


## A hatch on the -Z face at height `y` of a hull whose radius there is `r`: a darker plate, a frame and
## a small dark porthole.
static func _hatch(kit: PlanetMeshKit, r: float, y: float, w: float, h: float, plate: Color, frame: Color, port: Color) -> void:
	kit.rounded_box(Vector3(0.0, y, -r - 0.015), Vector3(w + 0.08, h + 0.08, 0.05), 0.02, frame)
	kit.rounded_box(Vector3(0.0, y, -r - 0.04), Vector3(w, h, 0.05), 0.03, plate)
	kit.cylinder(Vector3(0.0, y + h * 0.18, -r - 0.07), 0.085, 0.085, 0.03, port, Basis(Vector3.RIGHT, PI * 0.5), 10)


static func _nozzle(kit: PlanetMeshKit, y: float, r: float, col: Color) -> void:
	kit.cylinder(Vector3(0.0, y - 0.14, 0.0), r * 1.15, r * 0.8, 0.16, col, Basis.IDENTITY, 10)


## One or two crates strapped against the hull on the +X side, on the ground: the ship is packed.
static func _crates(kit: PlanetMeshKit, hull_r: float, n: int, pal: Dictionary) -> void:
	var x := hull_r + 0.26
	for i in n:
		var s := 0.44 - 0.08 * float(i)
		var c := Vector3(x - 0.02 * float(i), 0.08 + s * 0.5 + (0.44 * float(i)), 0.10 - 0.06 * float(i))
		var b := Basis(Vector3.UP, 0.18 - 0.3 * float(i))
		kit.rounded_box(c, Vector3(s, s, s), 0.03, pal["crate"], b)
		kit.rounded_box(c, Vector3(s + 0.02, 0.05, s + 0.02), 0.01, pal["strap"], b)
		kit.rounded_box(c, Vector3(0.05, s + 0.02, s + 0.02), 0.01, pal["strap"], b)


static func _zorp(kit: PlanetMeshKit, glow: PlanetMeshKit, p: Dictionary) -> Dictionary:
	var prof := PackedVector2Array([Vector2(0.0, 0.30), Vector2(0.50, 0.30), Vector2(0.70, 0.45), Vector2(0.80, 0.75),
		Vector2(0.78, 1.10), Vector2(0.66, 1.38), Vector2(0.46, 1.58), Vector2(0.22, 1.70), Vector2(0.0, 1.72)])
	kit.lathe(prof, 8, Transform3D.IDENTITY, p["body"], false)
	kit.cylinder(Vector3(0.0, 0.29, 0.0), 0.52, 0.52, 0.02, p["dark"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 0.70, 0.0), 0.83, 0.84, 0.16, p["band"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 1.64, 0.0), 0.30, 0.10, 0.16, p["trim"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 1.78, 0.0), 0.03, 0.02, 0.36, p["leg"], Basis.IDENTITY, 6)
	glow.sphere(Vector3(0.0, 2.18, 0.0), 0.085, p["glow"], Vector3.ONE, 8)
	_nozzle(kit, 0.30, 0.30, p["leg"])
	_hatch(kit, 0.79, 0.98, 0.40, 0.46, p["dark"], p["trim"], p["port"])
	_legs(kit, 3, 0.62, 0.52, 1.0, p["leg"], p["dark"], PI / 3.0)
	return {"height": 2.27, "hull_r": 0.82, "nozzle_y": 0.16, "nozzle_r": 0.28, "crate_r": 0.8, "crates": 2}


static func _bolt(kit: PlanetMeshKit, glow: PlanetMeshKit, p: Dictionary) -> Dictionary:
	var prof := PackedVector2Array([Vector2(0.0, 0.34), Vector2(0.60, 0.34), Vector2(0.64, 0.40), Vector2(0.64, 1.30),
		Vector2(0.58, 1.40), Vector2(0.40, 1.56), Vector2(0.40, 1.70), Vector2(0.0, 1.70)])
	kit.lathe(prof, 8, Transform3D(Basis(Vector3.UP, PI / 8.0), Vector3.ZERO), p["body"], false)
	kit.cylinder(Vector3(0.0, 0.62, 0.0), 0.67, 0.67, 0.12, p["band"], Basis(Vector3.UP, PI / 8.0), 8)
	kit.cylinder(Vector3(0.0, 1.12, 0.0), 0.67, 0.67, 0.08, p["band"], Basis(Vector3.UP, PI / 8.0), 8)
	kit.cylinder(Vector3(0.0, 1.69, 0.0), 0.44, 0.44, 0.06, p["dark"], Basis(Vector3.UP, PI / 8.0), 8)
	# A short exhaust stack and a stubby antenna mast on the lid.
	kit.cylinder(Vector3(0.22, 1.72, 0.12), 0.09, 0.08, 0.26, p["trim"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(-0.16, 1.72, 0.10), 0.025, 0.02, 0.38, p["trim"], Basis.IDENTITY, 6)
	glow.sphere(Vector3(-0.16, 2.12, 0.10), 0.06, p["glow"], Vector3.ONE, 8)
	glow.sphere(Vector3(0.0, 1.30, -0.63), 0.07, p["glow"], Vector3(1.0, 1.0, 0.5), 8)
	_nozzle(kit, 0.34, 0.30, p["leg"])
	_hatch(kit, 0.60, 0.88, 0.42, 0.44, p["dark"], p["band"], p["port"])
	_legs(kit, 4, 0.56, 0.52, 0.98, p["leg"], p["dark"], PI / 4.0, 0.065)
	return {"height": 2.18, "hull_r": 0.67, "nozzle_y": 0.20, "nozzle_r": 0.28, "crate_r": 0.66, "crates": 2}


static func _fen(kit: PlanetMeshKit, glow: PlanetMeshKit, p: Dictionary) -> Dictionary:
	var prof := PackedVector2Array([Vector2(0.0, 0.32), Vector2(0.46, 0.32), Vector2(0.56, 0.55), Vector2(0.54, 1.35),
		Vector2(0.42, 1.70), Vector2(0.24, 1.95), Vector2(0.0, 2.02)])
	kit.lathe(prof, 6, Transform3D.IDENTITY, p["body"], false)
	kit.cylinder(Vector3(0.0, 0.31, 0.0), 0.48, 0.48, 0.02, p["dark"], Basis.IDENTITY, 6)
	# The shawl: a cloth wrap round the middle with a hanging tail at the back.
	kit.cylinder(Vector3(0.0, 0.98, 0.0), 0.60, 0.58, 0.26, p["band"], Basis.IDENTITY, 6)
	kit.rounded_box(Vector3(0.18, 0.86, 0.56), Vector3(0.18, 0.40, 0.05), 0.02, p["trim"], Basis(Vector3.UP, 0.3))
	kit.cylinder(Vector3(0.0, 1.98, 0.0), 0.06, 0.04, 0.12, p["leg"], Basis.IDENTITY, 6)
	# The hooded lamp on the front, over the hatch: a dark hood over a warm bulb.
	kit.rounded_box(Vector3(0.0, 1.62, -0.50), Vector3(0.24, 0.10, 0.20), 0.03, p["leg"])
	glow.sphere(Vector3(0.0, 1.53, -0.50), 0.075, p["glow"], Vector3.ONE, 8)
	_nozzle(kit, 0.32, 0.26, p["leg"])
	_hatch(kit, 0.555, 1.18, 0.34, 0.20, p["dark"], p["trim"], p["port"])
	_hatch(kit, 0.555, 0.72, 0.34, 0.26, p["dark"], p["trim"], p["port"])
	_legs(kit, 3, 0.48, 0.52, 0.92, p["leg"], p["dark"], 0.0, 0.05)
	return {"height": 2.10, "hull_r": 0.60, "nozzle_y": 0.18, "nozzle_r": 0.24, "crate_r": 0.62, "crates": 1}


static func _grig(kit: PlanetMeshKit, glow: PlanetMeshKit, p: Dictionary) -> Dictionary:
	# Stepped stone tiers, like his nine hundred and four steps.
	kit.cylinder(Vector3(0.0, 0.26, 0.0), 0.80, 0.76, 0.42, p["dark"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 0.68, 0.0), 0.66, 0.62, 0.40, p["body"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 1.08, 0.0), 0.50, 0.46, 0.36, p["body"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 1.44, 0.0), 0.32, 0.28, 0.22, p["band"], Basis.IDENTITY, 8)
	kit.cylinder(Vector3(0.0, 1.66, 0.0), 0.16, 0.10, 0.12, p["trim"], Basis.IDENTITY, 8)
	# Chalk tally marks on the middle tier, beside the hatch.
	for i in 4:
		var a := 0.55 + 0.11 * float(i)
		kit.rounded_box(Vector3(sin(a) * 0.645, 0.88, -cos(a) * 0.645), Vector3(0.03, 0.22, 0.02), 0.005, p["trim"], Basis(Vector3.UP, -a))
	kit.rounded_box(Vector3(sin(0.72) * 0.65, 0.88, -cos(0.72) * 0.65), Vector3(0.36, 0.03, 0.02), 0.005, p["trim"], Basis(Vector3.UP, -0.72) * Basis(Vector3.FORWARD, 0.5))
	glow.sphere(Vector3(0.0, 1.80, 0.0), 0.07, p["glow"], Vector3.ONE, 8)
	_nozzle(kit, 0.26, 0.30, p["leg"])
	_hatch(kit, 0.64, 0.86, 0.38, 0.40, p["dark"], p["band"], p["port"])
	_legs(kit, 4, 0.66, 0.36, 0.98, p["leg"], p["dark"], PI / 4.0, 0.08)
	return {"height": 1.87, "hull_r": 0.80, "nozzle_y": 0.12, "nozzle_r": 0.28, "crate_r": 0.80, "crates": 2}


static func _vela(kit: PlanetMeshKit, glow: PlanetMeshKit, p: Dictionary) -> Dictionary:
	var prof := PackedVector2Array([Vector2(0.0, 0.30), Vector2(0.52, 0.30), Vector2(0.66, 0.50), Vector2(0.70, 0.90),
		Vector2(0.60, 1.35), Vector2(0.40, 1.66), Vector2(0.16, 1.84), Vector2(0.0, 1.86)])
	kit.lathe(prof, 10, Transform3D.IDENTITY, p["body"], false)
	kit.cylinder(Vector3(0.0, 0.28, 0.0), 0.60, 0.62, 0.14, p["trim"], Basis.IDENTITY, 10)
	kit.cylinder(Vector3(0.0, 1.12, 0.0), 0.66, 0.64, 0.08, p["band"], Basis.IDENTITY, 10)
	# The little dish on a mast (the one she takes with her).
	kit.cylinder(Vector3(0.0, 1.84, 0.0), 0.03, 0.03, 0.22, p["leg"], Basis.IDENTITY, 6)
	var dish := PackedVector2Array([Vector2(0.05, 2.02), Vector2(0.22, 2.07), Vector2(0.34, 2.16), Vector2(0.30, 2.17), Vector2(0.18, 2.10), Vector2(0.0, 2.08)])
	kit.lathe(dish, 10, Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3(0.0, 0.70, -0.72)), p["dark"], false, true)
	# Three taupe fins that are also her legs.
	for k in 3:
		var ang := TAU * float(k) / 3.0 + PI / 3.0
		var b := Basis(Vector3.UP, ang)
		kit.rounded_box(b * Vector3(0.0, 0.42, 0.74), Vector3(0.06, 0.62, 0.34), 0.02, p["band"], b * Basis(Vector3.RIGHT, 0.28))
		kit.cylinder(b * Vector3(0.0, 0.0, 0.86), 0.12, 0.10, 0.06, p["leg"], Basis.IDENTITY, 8)
	glow.sphere(Vector3(0.0, 1.42, -0.52), 0.06, p["glow"], Vector3(1.0, 1.0, 0.5), 8)
	_nozzle(kit, 0.28, 0.28, p["leg"])
	_hatch(kit, 0.69, 0.80, 0.38, 0.40, p["dark"], p["band"], p["port"])
	return {"height": 2.20, "hull_r": 0.70, "nozzle_y": 0.14, "nozzle_r": 0.26, "crate_r": 0.74, "crates": 1}


# ============================================================================= the scrapbook prop
## The Professor's borrowed scrapbook, open, pages toward -Z, for the meeting's "holds up the scrapbook"
## beat: two cream pages with small photos on them in a navy cover. About 0.36 x 0.26 m. One draw.
static func make_scrapbook() -> MeshInstance3D:
	var kit := PlanetMeshKit.new()
	var cover := Color("#4c5b8c")
	var page := Color("#e6dfcf")
	for side in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, side * 0.22)
		var c := b * Vector3(side * 0.095, 0.0, 0.0)
		kit.rounded_box(c + b * Vector3(0.0, 0.0, 0.012), Vector3(0.19, 0.26, 0.016), 0.006, cover, b)
		kit.rounded_box(c, Vector3(0.175, 0.245, 0.012), 0.004, page, b)
		# Photos on the page: the streak is in every one of them.
		var cols: Array[Color] = [Color("#7d8fb3"), Color("#9a86b8"), Color("#8fa38e")]
		for i in 2:
			var pc := c + b * Vector3(-0.02 + 0.045 * float(i), 0.05 - 0.10 * float(i), -0.008)
			kit.rounded_box(pc, Vector3(0.10, 0.07, 0.004), 0.002, cols[(i + int(side > 0.0)) % 3], b)
			kit.rounded_box(pc + b * Vector3(0.0, 0.0, -0.003), Vector3(0.07, 0.006, 0.002), 0.001, Color("#e9e2c8"), b * Basis(Vector3.FORWARD, 0.35))
	var mi := MeshInstance3D.new()
	mi.name = "Scrapbook"
	mi.mesh = kit.commit()
	mi.material_override = Building.body_material()
	return mi


static func _tangent(v: Vector3, up: Vector3, fallback: Vector3) -> Vector3:
	var t := v - up * v.dot(up)
	if t.length_squared() < 1e-6:
		t = fallback - up * fallback.dot(up)
	return t.normalized()
