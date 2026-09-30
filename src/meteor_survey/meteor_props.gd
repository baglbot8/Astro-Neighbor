class_name MeteorProps
extends RefCounted
## THE SURVEY'S THINGS (builder METEOR): static builders for the weak-point outcrops, their plumes and
## beacons, the scattered crust shards and the sky's planets. Everything is a few shared-material shapes
## (planet_safari.gd RULES FOR CONTENT: no GPU particles, no new lights).

const FX_SHADER := preload("res://src/meteor_survey/meteor_fx.gdshader")
const BEACON_GLOW_SHADER := preload("res://src/meteor_survey/meteor_beacon_glow.gdshader")
const SKY_SHADER := preload("res://src/meteor_survey/meteor_sky_planet.gdshader")
const LAVA_SHADER := preload("res://src/meteor_survey/meteor_lava.gdshader")

## Warm orange plume = a weak point still to mark; an amber beacon (pole, lamp, beam) = marked.
const WARM := Color("#ff8a3d")
const MOLTEN := Color("#ffb46a")
## The target beacon's colour: the Moonstone accent amber, the same value as FinaleLaunch.BEACON_COLOR, so the
## beacons the player plants here are the ones the ships fly to in the send-off (lead, 2026-09-28: "warm
## amber, not near-white pink").
const BEACON := Color("#f0a64a")
const SHARD_ROCK := Color("#4e4866")
const POLE_METAL := Color("#b8c4d6")

static var _fx_cache: Dictionary = {}


static func fx(tint: Color, energy: float, fade_mode: int, pulse_speed: float = 1.5, pulse_amount: float = 0.2,
		fade_power: float = 1.6) -> ShaderMaterial:
	var key := "%s|%.2f|%d|%.2f|%.2f|%.2f" % [tint.to_html(), energy, fade_mode, pulse_speed, pulse_amount, fade_power]
	if _fx_cache.has(key):
		return _fx_cache[key]
	var m := ShaderMaterial.new()
	m.shader = FX_SHADER
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("fade_mode", fade_mode)
	m.set_shader_parameter("pulse_speed", pulse_speed)
	m.set_shader_parameter("pulse_amount", pulse_amount)
	m.set_shader_parameter("fade_power", fade_power)
	_fx_cache[key] = m
	return m


static func rock_material() -> ShaderMaterial:
	return MaterialLib.toon(SHARD_ROCK, {"surface": "rock", "surface_macro": 0.4, "shade": 0.5})


## A jagged crust shard: an irregular `sides`-gon prism that narrows to a leaning, chipped top. Flat facets
## (a stylistic facet on a crystal-like rock), with its base sunk `sink` below the ground.
static func shard_mesh(rng: RandomNumberGenerator, height: float, width: float, sides: int = 6,
		sink: float = 0.35) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25)) * height
	var rings: Array = []
	var levels := [[-sink, 1.0], [height * 0.45, 0.72], [height * 0.85, 0.34]]
	for lv: Array in levels:
		var y: float = lv[0]
		var k: float = lv[1]
		var ring: Array = []
		for i in range(sides):
			var a := TAU * float(i) / sides + rng.randf_range(-0.2, 0.2)
			var r := width * k * rng.randf_range(0.8, 1.15)
			var t := clampf((y + sink) / (height + sink), 0.0, 1.0)
			ring.append(Vector3(cos(a) * r, y, sin(a) * r) + lean * t)
		rings.append(ring)
	var tip := Vector3(rng.randf_range(-0.1, 0.1) * width, height, rng.randf_range(-0.1, 0.1) * width) + lean
	# Each face is wound outward from the shard's OWN leaning axis at its height (spec 9.6.5, "certain rocks have
	# see-through parts"): the old per-face test used the vertical axis through the origin, and on a leaning
	# shard the upper faces on the far side of the lean point toward that axis, so they were wound inward and
	# culled - holes you could see through (builder METEOR3 measured it: 184 of 1930 faces, in 58 of the level's 64 small rocks, wound inward; 0 after).
	var axis_at := func(y: float) -> Vector3:
		return Vector3(lean.x, 0.0, lean.z) * clampf((y + sink) / (height + sink), 0.0, 1.0) + Vector3(0.0, y, 0.0)
	for li in range(rings.size() - 1):
		var lo: Array = rings[li]
		var hi: Array = rings[li + 1]
		for i in range(sides):
			var j := (i + 1) % sides
			var ya: float = (lo[i] as Vector3).y
			var yb: float = (hi[i] as Vector3).y
			var ref: Vector3 = axis_at.call((ya + yb) * 0.5)
			_tri_from(st, lo[i], lo[j], hi[j], ref)
			_tri_from(st, lo[i], hi[j], hi[i], ref)
	var top: Array = rings[-1]
	for i in range(sides):
		var ref_t: Vector3 = axis_at.call((top[i] as Vector3).y)
		_tri_from(st, top[i], top[(i + 1) % sides], tip, ref_t - Vector3(0.0, 0.3, 0.0))
	# The base is closed too: a tilted shard (the geode's shell, the outcrop halves on a swell) lifts part of its
	# sunk base out of the ground, and an open base showed the culled inside.
	var base: Array = rings[0]
	var bc := Vector3.ZERO
	for v: Vector3 in base:
		bc += v
	bc /= float(sides)
	for i in range(sides):
		_tri_from(st, base[i], base[(i + 1) % sides], bc, bc + Vector3.UP)
	st.generate_normals()
	return st.commit()


## One triangle wound so its face points AWAY from `inside` (a point inside the solid).
static func _tri_from(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n := (b - a).cross(c - a)
	# Godot's front face is clockwise seen from outside, i.e. the geometric normal (b-a)x(c-a) points INTO the
	# solid for a front face; flip when it points out.
	if n.dot((a + b + c) / 3.0 - inside) > 0.0:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


## A cylinder collider for a shard or an outcrop, on its own StaticBody3D.
static func collider(radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	cs.shape = cyl
	cs.position = Vector3(0, height * 0.5 - 0.3, 0)
	body.add_child(cs)
	return body


## A WEAK POINT: a boulder split in two, leaning apart, with molten light in the gap and a glow on the
## ground where the split runs out. Local Y up, origin on the ground. Returns the root; the split's
## centre is at SPLIT_Y (what the photo scores against).
const SPLIT_Y := 1.0
static func outcrop(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var mat := rock_material()
	for side in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.name = "Half%s" % ("L" if side < 0.0 else "R")
		mi.mesh = shard_mesh(rng, rng.randf_range(1.9, 2.3), 0.85, 7, 0.4)
		mi.material_override = mat
		mi.position = Vector3(side * 0.62, 0.0, 0.0)
		mi.rotation = Vector3(0.0, rng.randf_range(-0.3, 0.3), -side * deg_to_rad(13.0))
		root.add_child(mi)
	# The split: a tall thin slab of light between the halves, and its glow spilling onto the ground.
	var slab := MeshInstance3D.new()
	slab.name = "Split"
	# A thin four-sided blade of light, flattened into the gap (thin across X), brightest at the ground
	# and fading up with soft edges - a solid white box read as a panel, not a crack (first phone frame).
	var blade := CylinderMesh.new()
	blade.top_radius = 0.06
	blade.bottom_radius = 0.16
	blade.height = 2.1
	blade.radial_segments = 4
	blade.rings = 1
	blade.cap_top = false
	blade.cap_bottom = false
	slab.mesh = blade
	slab.material_override = fx(Color("#ff9a4a"), 1.2, 1, 2.2, 0.18, 0.7)
	slab.position = Vector3(0.0, 1.0, 0.0)
	slab.scale = Vector3(0.8, 1.0, 4.2)
	root.add_child(slab)
	var pool := MeshInstance3D.new()
	pool.name = "Pool"
	var q := QuadMesh.new()
	q.size = Vector2(4.2, 4.2)
	q.orientation = PlaneMesh.FACE_Y
	pool.mesh = q
	pool.material_override = fx(WARM, 0.55, 2, 2.2, 0.18, 2.2)
	pool.position = Vector3(0.0, 0.06, 0.0)
	root.add_child(pool)
	root.add_child(collider(1.05, 2.4))
	return root


## The soft warm column over an UNMARKED weak point, so it can be found from over the horizon.
const PLUME_H := 13.0
static func plume() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Plume"
	var c := CylinderMesh.new()
	# Taller and brighter higher up than it was (9 m, fade 1.4, energy 0.42), for spec 9.6.4 ("the higher up vantage
	# point should let you see further for the red lights"): a crack 50-60 deg round the rock sits at the horizon
	# from a lookout, so what shows is the column's UPPER part, which the old fade had all but put out.
	c.top_radius = 0.6
	c.bottom_radius = 0.9
	c.height = PLUME_H
	c.radial_segments = 16
	c.rings = 1
	c.cap_top = false
	c.cap_bottom = false
	mi.mesh = c
	mi.material_override = fx(WARM, 0.5, 1, 1.1, 0.25, 0.85)
	mi.position = Vector3(0.0, PLUME_H * 0.5 + 0.8, 0.0)
	return mi


## THE TARGET BEACON placed on a marked weak point: a ring round the outcrop, one of MOSS'S GLOW PODS planted
## on its edge with its amber glow, and a thin beam straight up (the ships fly to these, spec 9.1). The pods are
## the ones Moss brought to the goodbye party as its lights (docs/JUNGLE_PLANET_SPEC.md 6, the user: "Bonus
## points if the thing that Moss provides for the farewell party ends up being used as the beacons"), so the
## pod is `glow_pod()` - the same builder finale_meeting.gd plants round the Commons. Amber (BEACON), in
## meteor_beacon_glow's MIXED light, not meteor_fx's additive one: additive, the glow and the ring's edge read
## cream-white whatever the energy (that shader's header has the measurements). The pod's glow is the same
## camera-facing glow the send-off shows on the rock, so the beacon planted here is the one seen there.
## Child names: Ring, Pod, Lamp (the glow), Beam.
static func beacon() -> Node3D:
	var root := Node3D.new()
	root.name = "Beacon"
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var t := TorusMesh.new()
	t.inner_radius = 1.75
	t.outer_radius = 1.95
	t.rings = 48
	t.ring_segments = 8
	ring.mesh = t
	ring.material_override = beacon_mat(2, 0.85, 3.0, 0.25)
	ring.position = Vector3(0.0, 0.12, 0.0)
	ring.scale = Vector3(1.0, 0.35, 1.0)
	root.add_child(ring)
	# The pod stands where the old pole did (on the ring, 1.85 m out), 1.25x a party pod so it still reads from
	# the survey's usual 6-12 m. Its own Lamp is the beacon's blinking lamp (blink 5.0, like the old lamp).
	var pod := glow_pod(1.25, 5.0, 0.45)
	pod.name = "Pod"
	pod.position = Vector3(1.85, 0.0, 0.0)
	root.add_child(pod)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var b := CylinderMesh.new()
	b.top_radius = 0.05
	b.bottom_radius = 0.16
	b.height = 40.0
	b.radial_segments = 12
	b.rings = 1
	b.cap_top = false
	b.cap_bottom = false
	beam.mesh = b
	beam.material_override = beacon_mat(1, 0.9, 5.0, 0.3, 0.9)
	beam.position = Vector3(1.85, POD_H * 1.25 + 20.0, 0.0)
	root.add_child(beam)
	return root


## Height of a glow pod at scale 1 (JungleMeshes.seed_pod variant 0: 1.22 x 0.85 m, plus its tip).
const POD_H := 1.15
## The Tangle's own pod colours (jungle_props.gd POD_SHELL / POD_CAP: gold husk, indigo cap).
const POD_SHELL := Color("#9e7d4c")
const POD_CAP := Color("#4b3d5c")
## The light inside a glow pod's shell (BEACON, a touch deeper so the shell's own gold still shows).
const POD_INNER := Color("#e08a2c")


## ONE OF MOSS'S GLOW PODS: the Tangle's own seed-pod mesh (JungleMeshes.seed_pod, the pods that stand in
## the jungle) with its seams lit amber, and the beacon's camera-facing amber glow ("Lamp") round its middle.
## Used for the goodbye party's lights (finale_meeting.gd) and for the survey beacon above, so the pod the
## player plants on the meteor is visibly the one from the party. Three draws (body, seams, glow quad), no
## light, no shadow from the glow. `blink_speed` / `blink_amount` pulse the glow (a party pod breathes slowly,
## a beacon blinks).
static func glow_pod(size: float = 1.0, blink_speed: float = 1.2, blink_amount: float = 0.25) -> Node3D:
	var root := Node3D.new()
	root.name = "GlowPod"
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = JungleMeshes.seed_pod(POD_SHELL, POD_CAP, 0)
	# The shell glows from inside (a warm amber emission under the bloom threshold, so it keeps its hue): at
	# night a plain lit shell read as a dark rock (first party frame, choice_02).
	body.set_surface_override_material(0, MaterialLib.toon_vertex_color({"emission": POD_INNER, "emission_strength": 0.55, "shade": 0.2}))
	if body.mesh.get_surface_count() > 1:
		body.set_surface_override_material(1, MaterialLib.flat_unlit(BEACON))
	body.scale = Vector3.ONE * size
	root.add_child(body)
	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	var q := QuadMesh.new()
	# 2.4x the pod's width, so the halo shows round the shell (the half of the quad behind the shell is hidden
	# by depth, which is what makes it read as light from inside, not a disc in front).
	q.size = Vector2(2.4, 2.4) * size
	lamp.mesh = q
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lamp.material_override = beacon_mat(0, 0.5, blink_speed, blink_amount)
	lamp.position = Vector3(0.0, POD_H * 0.55 * size, 0.0)
	root.add_child(lamp)
	return root


## The beacon seen from afar, for the send-off (FinaleLaunch._build_beacons puts one on a QuadMesh per beacon):
## a camera-facing amber disc and halo that MIX over the rock rather than add to it (meteor_beacon_glow.gdshader
## says why). One shared material.
static func beacon_glow() -> ShaderMaterial:
	return beacon_mat(0, 0.6, 2.4, 0.45)


## A meteor_beacon_glow material in BEACON amber: `shape` 0 camera-facing glow, 1 faded beam, 2 plain surface;
## `opacity` is the halo's (0) or the surface's (1, 2). Cached per argument set.
static func beacon_mat(shape: int, opacity: float, blink_speed: float, blink_amount: float,
		fade_power: float = 1.6) -> ShaderMaterial:
	var key := "beacon|%d|%.2f|%.2f|%.2f|%.2f" % [shape, opacity, blink_speed, blink_amount, fade_power]
	if _fx_cache.has(key):
		return _fx_cache[key]
	var m := ShaderMaterial.new()
	m.shader = BEACON_GLOW_SHADER
	m.set_shader_parameter("tint", BEACON)
	m.set_shader_parameter("shape", shape)
	m.set_shader_parameter("halo", opacity)
	m.set_shader_parameter("blink_speed", blink_speed)
	m.set_shader_parameter("blink_amount", blink_amount)
	m.set_shader_parameter("fade_power", fade_power)
	_fx_cache[key] = m
	return m


## A planet in the sky: a sphere with the sky shader (and a flat ring when `ring_col` is not transparent).
static func sky_planet(radius: float, base: Color, band: Color, rim: Color, light_dir: Vector3,
		bands: float, ring_col: Color = Color.TRANSPARENT) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 48
	s.rings = 24
	mi.mesh = s
	var m := ShaderMaterial.new()
	m.shader = SKY_SHADER
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("band_color", band)
	m.set_shader_parameter("rim_color", rim)
	m.set_shader_parameter("light_dir", light_dir)
	m.set_shader_parameter("bands", bands)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	if ring_col.a > 0.0:
		var ring := MeshInstance3D.new()
		ring.name = "Ring"
		var t := TorusMesh.new()
		t.inner_radius = radius * 1.35
		t.outer_radius = radius * 1.85
		t.rings = 64
		t.ring_segments = 4
		ring.mesh = t
		ring.material_override = fx(ring_col, 0.35, 0, 0.3, 0.05)
		ring.scale = Vector3(1.0, 0.02, 1.0)
		ring.rotation = Vector3(deg_to_rad(18.0), 0.0, deg_to_rad(-12.0))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring)
	return root


# ======================================================================================== LANDMARKS
## THE LANDMARKS (builder METEOR2, spec 9.5.2: "the meteor needs some occasional recognizable landmarks (e.g.
## large crystal spikes or lava fountain) just so you have a sense of where you've already been"). Five big
## things, each a different SHAPE and a different COLOUR, so any one is known at a glance and from over the
## horizon (4.5-7.5 m tall; on a 22 m rock a 7 m thing shows ~26 m away): teal crystal spires, a red lava
## fountain, a pale stone arch you can walk under, a violet geode and a cream balanced-stone stack. None is a
## photo subject and none glows the cracks' orange-amber. Local Y up, origin on the ground. Each root carries
## meta "look_y" (where its middle is, for a camera) and the fountain carries "blobs" for the level to animate.
const LM_TEAL := Color("#2f9c90")
const LM_TEAL_GLOW := Color("#35d6c4")
const LM_LAVA := Color("#ff4a36")
const LM_LAVA_CORE := Color("#ffc44a")
const LM_ARCH_STONE := Color("#8e87a4")
const LM_VIOLET := Color("#a978f0")
const LM_VIOLET_GLOW := Color("#b98cff")
const LM_SAND := Color("#b3a58f")
const LM_SAND_DARK := Color("#857766")
const LM_NAMES: Array[String] = ["spires", "fountain", "arch", "geode", "stack"]


static func landmark(kind: String, rng: RandomNumberGenerator) -> Node3D:
	match kind:
		"spires":
			return _lm_spires(rng)
		"fountain":
			return _lm_fountain(rng)
		"arch":
			return _lm_arch(rng)
		"geode":
			return _lm_geode(rng)
		_:
			return _lm_stack(rng)


static func _crystal(albedo: Color, glow: Color) -> ShaderMaterial:
	return MaterialLib.toon(albedo, {"emission": glow, "emission_strength": 0.45, "shade": 0.35, "rim": 0.25,
		"spec": 0.35, "spec_size": 40.0, "roughness": 0.35})


static func _mesh_node(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


## TEAL CRYSTAL SPIRES: five tall faceted prisms from one root, the tallest 7 m, leaning out like a fan.
static func _lm_spires(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LandmarkSpires"
	var mat := _crystal(LM_TEAL, LM_TEAL_GLOW)
	var specs := [[7.2, 0.75, 0.0, 0.0], [5.2, 0.6, 0.9, 0.35], [4.4, 0.55, -1.0, -0.3], [3.3, 0.45, 0.3, -0.95],
		[2.6, 0.4, -0.5, 1.0]]
	for s: Array in specs:
		var h: float = s[0]
		var m := shard_mesh(rng, h, float(s[1]), 6, 0.4)
		var pos := Vector3(float(s[2]), 0.0, float(s[3]))
		var lean := Vector3(float(s[3]), 0.0, -float(s[2])) * 0.16
		_mesh_node(root, m, mat, pos, lean)
	var base_mat := rock_material()
	for i in range(4):
		var a := TAU * float(i) / 4.0 + 0.4
		_mesh_node(root, shard_mesh(rng, 0.9, 0.7, 5, 0.3), base_mat, Vector3(cos(a), 0.0, sin(a)) * 1.5)
	root.add_child(collider(1.2, 6.0))
	root.set_meta("look_y", 3.2)
	return root


## LAVA FOUNTAIN: a squat dark cone with a red-hot crater, a short bright spout, and molten blobs that arc
## out and fall (moved by MeteorSurveyLevel._animate_landmarks; `blobs` meta = [{node, phase, angle}]).
static func _lm_fountain(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LandmarkFountain"
	# The body is a lumpy volcano of its own (not a CylinderMesh) so the lava can lie ON it: `_volcano_point` is
	# the one surface both are built from. Closed at the top by the crater wall running down under the pool.
	var cone_mat := MaterialLib.toon(Color("#3a3040"), {"surface": "rock", "surface_macro": 0.5, "shade": 0.5,
		"emission": Color("#ff3a24"), "emission_strength": 0.12})
	var vn := FastNoiseLite.new()
	vn.seed = rng.randi()
	vn.frequency = 0.9
	_mesh_node(root, _volcano_mesh(vn), cone_mat, Vector3.ZERO)
	# LAVA (spec 9.6.5, the user: "the volcano's lava lines look just like red sticks stuck to the mountain ... less
	# straight and more natural"). Seven flows leave the rim, wander down the flank (each its own meander), swell
	# and thin as they go, and three of them fork. Ribbons laid on the surface, in meteor_lava's flowing glow.
	var lava_mat := lava_material()
	var flows := MeshInstance3D.new()
	flows.name = "LavaFlows"
	flows.mesh = _lava_flows_mesh(rng, vn)
	flows.material_override = lava_mat
	flows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flows)
	var pool := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.6, 2.6)
	q.orientation = PlaneMesh.FACE_Y
	pool.mesh = q
	pool.material_override = fx(LM_LAVA, 0.9, 2, 3.0, 0.2, 1.2)
	pool.position = Vector3(0.0, 2.32, 0.0)
	root.add_child(pool)
	var disc := CylinderMesh.new()
	disc.top_radius = 0.92
	disc.bottom_radius = 0.92
	disc.height = 0.1
	disc.radial_segments = 16
	_mesh_node(root, disc, MaterialLib.glow(LM_LAVA, 2.6), Vector3(0.0, 2.25, 0.0))
	var spout := CylinderMesh.new()
	spout.top_radius = 0.12
	spout.bottom_radius = 0.42
	spout.height = 3.2
	spout.radial_segments = 12
	spout.rings = 1
	spout.cap_top = false
	spout.cap_bottom = false
	_mesh_node(root, spout, fx(LM_LAVA_CORE, 1.1, 1, 6.0, 0.3, 0.8), Vector3(0.0, 2.3 + 1.6, 0.0))
	var blob_mesh := SphereMesh.new()
	blob_mesh.radius = 0.2
	blob_mesh.height = 0.4
	blob_mesh.radial_segments = 8
	blob_mesh.rings = 4
	var blob_mat := MaterialLib.glow(Color("#ff7a3a"), 3.0)
	var blobs: Array = []
	for i in range(12):
		var b := _mesh_node(root, blob_mesh, blob_mat, Vector3(0.0, 2.3, 0.0))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		blobs.append({"node": b, "phase": float(i) / 12.0 + rng.randf_range(-0.03, 0.03),
			"angle": TAU * float(i) * 0.382 + rng.randf_range(-0.2, 0.2), "reach": rng.randf_range(2.6, 3.6)})
	root.set_meta("blobs", blobs)
	root.add_child(collider(2.4, 2.6))
	root.set_meta("look_y", 2.6)
	return root


## Blob i at `t` 0..1 through its arc (local to the fountain): up out of the crater, over, and down the flank.
static func fountain_blob_pos(b: Dictionary, t: float) -> Vector3:
	var a := float(b["angle"])
	var r := 0.2 + float(b["reach"]) * t
	var y := 2.3 + 11.0 * t * (0.72 - t)
	return Vector3(cos(a) * r, maxf(y, 0.1), sin(a) * r)


## THE VOLCANO'S SURFACE (local, origin on the ground): `f` 0 at the rim, 1 at the foot (sunk below the ground),
## `a` the angle round. A concave flank (steep near the rim, spreading at the foot) with low lumps, so no straight
## generator line is left for the lava to follow.
const VOLCANO_RIM_Y := 2.3
const VOLCANO_FOOT_Y := -0.4
const VOLCANO_RIM_R := 0.95
const VOLCANO_FOOT_R := 3.5
static func _volcano_point(noise: FastNoiseLite, a: float, f: float) -> Vector3:
	var y := lerpf(VOLCANO_RIM_Y, VOLCANO_FOOT_Y, f)
	var r := VOLCANO_RIM_R + (VOLCANO_FOOT_R - VOLCANO_RIM_R) * pow(f, 1.35)
	var lump := noise.get_noise_2d(cos(a) * 2.2 + f * 1.6, sin(a) * 2.2 - f * 1.1)
	r *= 1.0 + 0.1 * lump * smoothstep(0.0, 0.25, f)
	return Vector3(cos(a) * r, y, sin(a) * r)


const VOLCANO_SIDES := 30
const VOLCANO_RINGS := 10
static func _volcano_mesh(noise: FastNoiseLite) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for j in range(VOLCANO_RINGS + 1):
		var f := float(j) / VOLCANO_RINGS
		var ring: Array = []
		for i in range(VOLCANO_SIDES):
			ring.append(_volcano_point(noise, TAU * float(i) / VOLCANO_SIDES, f))
		rings.append(ring)
	var inside := Vector3(0.0, 0.8, 0.0)
	for j in range(VOLCANO_RINGS):
		for i in range(VOLCANO_SIDES):
			var k := (i + 1) % VOLCANO_SIDES
			_tri_from(st, rings[j][i], rings[j][k], rings[j + 1][k], inside)
			_tri_from(st, rings[j][i], rings[j + 1][k], rings[j + 1][i], inside)
	# The crater: the rim turns in and down to a floor just under the lava pool (closed, nothing to see through).
	var floor_c := Vector3(0.0, VOLCANO_RIM_Y - 0.25, 0.0)
	for i in range(VOLCANO_SIDES):
		var k := (i + 1) % VOLCANO_SIDES
		var a: Vector3 = rings[0][i]
		var b: Vector3 = rings[0][k]
		var ai := Vector3(a.x * 0.78, floor_c.y, a.z * 0.78)
		var bi := Vector3(b.x * 0.78, floor_c.y, b.z * 0.78)
		var above := Vector3(0.0, VOLCANO_RIM_Y + 3.0, 0.0)
		_tri_from(st, a, b, bi, above)
		_tri_from(st, a, bi, ai, above)
		_tri_from(st, ai, bi, floor_c, above)
	st.generate_normals()
	return st.commit()


static func _volcano_normal(noise: FastNoiseLite, a: float, f: float) -> Vector3:
	var p := _volcano_point(noise, a, f)
	var da := _volcano_point(noise, a + 0.02, f) - p
	var df := _volcano_point(noise, a, f + 0.02) - p
	var n := da.cross(df).normalized()
	return n if n.dot(Vector3(p.x, 0.0, p.z)) > 0.0 else -n


## The flows as one mesh. UV.x runs across a ribbon (0..1), UV.y along it in metres from the rim (the shader
## scrolls its crust breaks down UV.y), COLOR.r is the flow's heat (1 fresh at the rim, fading to the tip).
static func _lava_flows_mesh(rng: RandomNumberGenerator, noise: FastNoiseLite) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_flows := 7
	for fi in range(n_flows):
		var a0 := TAU * float(fi) / n_flows + rng.randf_range(-0.3, 0.3)
		var wander := rng.randf_range(0.18, 0.34) * (1.0 if rng.randf() < 0.5 else -1.0)
		var freq := rng.randf_range(5.0, 8.0)
		var phase := rng.randf_range(0.0, TAU)
		var drift := rng.randf_range(-0.35, 0.35)
		var f_end := rng.randf_range(0.72, 0.97)
		var w0 := rng.randf_range(0.2, 0.29)
		var path := func(f: float) -> float:
			return a0 + drift * f + wander * sin(f * freq + phase) * f
		_lava_ribbon(st, noise, path, 0.03, f_end, w0, rng.randi())
		# Three flows fork partway: the branch peels off to one side and thins out sooner.
		if fi % 2 == 0 and fi < 6:
			var fb := rng.randf_range(0.35, 0.55)
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var ab: float = path.call(fb)
			var spread := rng.randf_range(0.28, 0.45) * side
			var bfreq := rng.randf_range(6.0, 9.0)
			var branch := func(f: float) -> float:
				var k := clampf((f - fb) / (1.0 - fb), 0.0, 1.0)
				return ab + spread * sqrt(k) + 0.08 * sin(f * bfreq) * k
			_lava_ribbon(st, noise, branch, fb, minf(fb + rng.randf_range(0.3, 0.42), 0.95), w0 * 0.62, rng.randi())
	return st.commit()


static func _lava_ribbon(st: SurfaceTool, noise: FastNoiseLite, path: Callable, f0: float, f1: float, w0: float,
		seed_i: int) -> void:
	var steps := 22
	var wn := FastNoiseLite.new()
	wn.seed = seed_i
	wn.frequency = 2.5
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_v := 0.0
	var prev_heat := 1.0
	var along := 0.0
	var prev_c := Vector3.ZERO
	for s in range(steps + 1):
		var t := float(s) / steps
		var f := lerpf(f0, f1, t)
		var a: float = path.call(f)
		var c := _volcano_point(noise, a, f)
		var r := Vector2(c.x, c.z).length()
		# Width: swells and pinches along the flow (its own noise), tapers to a point at the tip.
		var w := w0 * (1.0 + 0.45 * wn.get_noise_1d(f * 10.0)) * (1.0 - 0.35 * f) * minf(1.0, (1.0 - t) * 4.0 + 0.05)
		if s == 0 and f0 > 0.05:
			w *= 0.3   # a fork starts thin, out of its parent
		var da := w / maxf(r, 0.3)
		var nl := _volcano_normal(noise, a - da, f)
		var nr := _volcano_normal(noise, a + da, f)
		var pl := _volcano_point(noise, a - da, f) + nl * 0.035
		var pr := _volcano_point(noise, a + da, f) + nr * 0.035
		if s > 0:
			along += c.distance_to(prev_c)
		var heat := lerpf(1.0, 0.35, t)
		if s > 0:
			var quad := [[prev_l, 0.0, prev_v, prev_heat], [prev_r, 1.0, prev_v, prev_heat], [pr, 1.0, along, heat],
				[pl, 0.0, along, heat]]
			for idx in [0, 1, 2, 0, 2, 3]:
				var q: Array = quad[idx]
				st.set_color(Color(float(q[3]), 0.0, 0.0))
				st.set_uv(Vector2(float(q[1]), float(q[2])))
				st.set_normal(nl)
				st.add_vertex(q[0])
		prev_l = pl
		prev_r = pr
		prev_v = along
		prev_heat = heat
		prev_c = c


## The lava's own material (meteor_lava.gdshader): opaque, unshaded, a hot core and dark cooling edges with crust
## breaks drifting downhill. One shared material.
static func lava_material() -> ShaderMaterial:
	if _fx_cache.has("lava"):
		return _fx_cache["lava"]
	var m := ShaderMaterial.new()
	m.shader = LAVA_SHADER
	_fx_cache["lava"] = m
	return m


## STONE ARCH: a pale chunky arch of eleven blocks, 7.6 m across and 4.6 m high; walk under it.
static func _lm_arch(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LandmarkArch"
	var mat := MaterialLib.toon(LM_ARCH_STONE, {"surface": "rock", "surface_macro": 0.45, "shade": 0.45})
	var mat_dark := MaterialLib.toon(LM_ARCH_STONE.darkened(0.18), {"surface": "rock", "surface_macro": 0.45, "shade": 0.45})
	var span := 3.8
	var n := 11
	for i in range(n):
		var a := PI * (float(i) + 0.5) / float(n)
		var pos := Vector3(cos(a) * span, sin(a) * span * 1.08 + 0.2, 0.0)
		var box := BoxMesh.new()
		box.size = Vector3(1.45 * rng.randf_range(0.9, 1.1), 1.2 * rng.randf_range(0.9, 1.15), 1.4 * rng.randf_range(0.85, 1.1))
		var rot := Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.12, 0.12), a - PI * 0.5)
		_mesh_node(root, box, mat if i % 2 == 0 else mat_dark, pos, rot)
	for side in [-1.0, 1.0]:
		var foot := shard_mesh(rng, 1.4, 1.1, 7, 0.4)
		_mesh_node(root, foot, mat_dark, Vector3(side * span, 0.0, 0.0))
		var body := collider(0.85, 3.2)
		body.position = Vector3(side * span, 0.0, 0.0)
		root.add_child(body)
	root.set_meta("look_y", 2.4)
	return root


## VIOLET GEODE: a ring of dark slabs split open outward, full of tall glowing violet crystals.
static func _lm_geode(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LandmarkGeode"
	var shell := rock_material()
	for i in range(9):
		var a := TAU * float(i) / 9.0 + rng.randf_range(-0.12, 0.12)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var mi := _mesh_node(root, shard_mesh(rng, rng.randf_range(1.7, 2.3), 0.95, 6, 0.4), shell, dir * 2.7)
		mi.basis = Basis(dir.cross(Vector3.UP).normalized(), deg_to_rad(-40.0)) * Basis(Vector3.UP, rng.randf_range(0.0, TAU))
	var mat := _crystal(LM_VIOLET, LM_VIOLET_GLOW)
	var specs := [[5.4, 0.75, 0.0, 0.0], [4.2, 0.62, 0.9, 0.6], [3.8, 0.6, -0.9, 0.7], [3.4, 0.55, 0.4, -1.0],
		[2.8, 0.5, -1.1, -0.5], [2.4, 0.45, 1.3, -0.5], [2.0, 0.4, -0.3, 1.4], [1.6, 0.35, 1.5, 0.9]]
	for s: Array in specs:
		var pos := Vector3(float(s[2]), 0.0, float(s[3]))
		_mesh_node(root, shard_mesh(rng, float(s[0]), float(s[1]), 6, 0.3), mat, pos,
			Vector3(float(s[3]), 0.0, -float(s[2])) * 0.22)
	root.add_child(collider(2.6, 3.0))
	root.set_meta("look_y", 2.2)
	return root


## BALANCED STACK: four cream stones piled on a thin neck, 7.5 m tall, a wide flat cap on top.
static func _lm_stack(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LandmarkStack"
	var light := MaterialLib.toon(LM_SAND, {"surface": "rock", "surface_macro": 0.5, "shade": 0.45})
	var dark := MaterialLib.toon(LM_SAND_DARK, {"surface": "rock", "surface_macro": 0.5, "shade": 0.45})
	# [radius, height scale, y centre, material 0 light / 1 dark]
	var specs := [[1.7, 0.7, 0.8, 1], [0.75, 1.3, 2.2, 0], [1.35, 0.72, 3.5, 1], [1.0, 0.8, 4.75, 0], [1.75, 0.34, 5.85, 1]]
	for s: Array in specs:
		var sm := SphereMesh.new()
		sm.radius = float(s[0])
		sm.height = float(s[0]) * 2.0
		sm.radial_segments = 9
		sm.rings = 5
		var mi := _mesh_node(root, sm, light if int(s[3]) == 0 else dark, Vector3(rng.randf_range(-0.12, 0.12),
			float(s[2]), rng.randf_range(-0.12, 0.12)), Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(0.0, TAU),
			rng.randf_range(-0.1, 0.1)), Vector3(1.0, float(s[1]), 1.0))
		mi.name = "Stone"
	root.add_child(collider(1.5, 6.2))
	root.set_meta("look_y", 3.4)
	return root
