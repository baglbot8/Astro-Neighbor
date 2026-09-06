extends Building
## Star Stage — the open-air event space. A rounded stage platform inside a telescoping bandshell,
## two big speakers with woofers that pump, string lights on two poles (MultiMesh bulbs that glow
## after dusk), a checker dance floor that pulses on the beat, sweeping spotlights and confetti.
##
## Interact ("Party!") toggles party mode: event music, the player dances, the lights come up.
## Interact again to stop; the music returns to the planet's own track.

const PARTY_TRACK := "event"
const BPM := 112.0
const BEAT := 60.0 / BPM

const STAGE_W := 6.60
const STAGE_D := 3.90
const STAGE_H := 0.62
const STAGE_Z := 0.55            # centre of the stage platform
const SHELL_RIBS := 5
const SHELL_R := 3.55
const DOOR_W := 1.10
const DOOR_H := 1.95
const FLOOR_Z := -4.15           # centre of the dance floor
const FLOOR_W := 5.60
const FLOOR_D := 3.40
const FLOOR_TILES := 6
const POLE := Vector3(3.70, 0.0, -3.10)
const POLE_H := 4.30
const BULBS := 9

const SHELL_A := Color("#57b0b2")
const SHELL_B := Color("#3a8189")
const STAGE_TOP := Color("#b28352")
const STAGE_SIDE := Color("#6f4a2c")
const SPEAKER := Color("#5f5866")
const SPEAKER_LIT := Color("#7a7284")
const TILE_A := Color("#e8e2d2")
const TILE_B := Color("#54858c")
const BULB_COLORS: Array[Color] = [Color("#ffd98a"), Color("#ff9ec4"), Color("#8fe4ff")]

var party_active := false

var _woofers: Array[Node3D] = []
var _woofer_rest: PackedFloat32Array = PackedFloat32Array()
var _spots: Array[Node3D] = []
var _spot_lights: Array[SpotLight3D] = []
var _confetti: GPUParticles3D
var _tile_a_mi: MeshInstance3D
var _tile_b_mi: MeshInstance3D
var _bulb_mmi: Array[MultiMeshInstance3D] = []
var _party_lights: Array[OmniLight3D] = []


func _init() -> void:
	building_id = "event_space"
	display_name = "Star Stage"
	ground_sink = 0.14
	ground_radius = 26.0
	# ankle height at the foot of the stage steps, ahead of where DJ Nova stands
	door_local = Vector3(0.0, 0.35, STAGE_Z - STAGE_D * 0.5 - 1.35)
	door_prompt = "Party!"


func _footprint_shapes() -> Array:
	return [
		[_box(Vector3(STAGE_W + 0.4, 1.6, STAGE_D + 0.5)), Vector3(0.0, 0.5, STAGE_Z)],
		[_box(Vector3(SHELL_R * 2.0, 4.6, 1.4)), Vector3(0.0, 2.2, STAGE_Z + 1.55)],
		[Building.cyl_shape(0.30, 4.4), Vector3(POLE.x, 2.0, POLE.z)],
		[Building.cyl_shape(0.30, 4.4), Vector3(-POLE.x, 2.0, POLE.z)],
		Building.step_block(2.5, STAGE_Z - STAGE_D * 0.5, STAGE_Z - STAGE_D * 0.5 - 1.05, 0.62),
	]


func _box(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


# R2.9: split by material. The stage deck is the single biggest surface here and the player stands
# on it, so it gets real timber grain running ALONG the planks - which on this model is +X, the way
# the three plank seams already run. The bandshell, the speaker cabinets and the DJ console are
# painted sheet, so they take the panel preset; the speaker grilles are cloth; the kerb, the steps
# and the pole bases are stone.
const DECK_GRAIN := Vector3(1.0, 0.0, 0.0)
# sd_wood's rings are contours of the distance from the grain axis THROUGH THE MODEL ORIGIN, so the
# ring frequency you get on screen depends on how fast that distance changes across the part. On the
# Town Hall door, 2.9 m out from the axis, it barely changes and the default `scale` is right. On
# this deck it changes 1:1 along Z, so the default put 220 grain lines across 3.9 m - a third of a
# pixel each at the door, i.e. invisible mush. `scale` 0.45 brings it to ~12 lines per metre, an
# 8 cm plank grain that is 14 px at the door.
const DECK_OPTS := {"scale": 0.45, "strength": 1.3}
# Bandshell ribs: courses across the arch at 1.5 per metre so a 0.67 m panel is 26 px from across
# the plaza, and a second family at 0.6 per metre for the ribs' own width.
const SHELL_OPTS := {
	"seam_mode": 1, "pitch_a": 1.5, "pitch_b": 0.6, "seam_strength": 0.8,
	"macro_scale": 2.4, "macro_amount": 0.40,
}
# The grille is a woven cloth panel stretched over the woofers; its seams are the frame edges.
const GRILLE_OPTS := {"pitch_a": 1.1, "pitch_b": 1.1, "seam_strength": 1.4}


func _build() -> void:
	var kit := DecoKit.new()        # stone: kerb, steps, pole bases
	var deck := DecoKit.new()       # the timber stage deck, its cheeks and the backstage door leaf
	var shell := DecoKit.new()      # painted sheet: bandshell ribs, beam, DJ console
	var metal := DecoKit.new()      # poles, bronze, the gold finial, hardware
	var deco := DecoKit.new()       # planters
	_build_stage(kit, deck)
	_build_shell(shell, deck, metal)
	_build_poles(kit, metal)
	_build_yard(shell, deco)
	add_wall(kit.commit(), "Stonework")
	add_wood(deck.commit(), DECK_GRAIN, "Timber", DECK_OPTS)
	add_panel(shell.commit(), "Bandshell", SHELL_OPTS)
	add_metal(metal.commit(), "Hardware")
	add_body(deco.commit(), "Planters")
	_build_speakers()
	_build_floor()
	_build_bulbs()
	_build_spots()
	_build_confetti()
	_build_glow()
	animate()


# ----------------------------------------------------------------------------- geometry
func _build_stage(kit: DecoKit, deck: DecoKit) -> void:
	deck.rbox(Vector3(0.0, -0.32, STAGE_Z), Vector3(STAGE_W + 0.10, 1.00, STAGE_D + 0.10), 0.10, STAGE_SIDE, Basis.IDENTITY, 0)
	deck.rbox(Vector3(0.0, STAGE_H - 0.30, STAGE_Z), Vector3(STAGE_W, 0.62, STAGE_D), 0.14, STAGE_SIDE, Basis.IDENTITY, 0)
	deck.rbox(Vector3(0.0, STAGE_H - 0.02, STAGE_Z), Vector3(STAGE_W - 0.10, 0.10, STAGE_D - 0.10), 0.04, STAGE_TOP, Basis.IDENTITY, 0)
	deck.rbox(Vector3(0.0, STAGE_H + 0.02, STAGE_Z - STAGE_D * 0.5 + 0.04), Vector3(STAGE_W - 0.10, 0.06, 0.10), 0.02, Color("#e0c391"), Basis.IDENTITY, 0)
	# three plank seams so the deck is not one flat slab
	for i in 3:
		deck.rbox(Vector3(0.0, STAGE_H + 0.015, STAGE_Z - 1.1 + float(i) * 1.1), Vector3(STAGE_W - 0.3, 0.02, 0.035), 0.008, STAGE_SIDE, Basis.IDENTITY, 0)
	build_steps(kit, 2.20, STAGE_Z - STAGE_D * 0.5, 1.00, STAGE_H, 0.20)
	# warm timber cheeks either side of the steps, so they read as stage steps not a concrete block
	for s in [-1.0, 1.0]:
		deck.rbox(Vector3(1.28 * s, STAGE_H - 0.24, STAGE_Z - STAGE_D * 0.5 - 0.52), Vector3(0.16, 0.62, 1.10), 0.05, STAGE_SIDE, Basis.IDENTITY, 0)


## The bandshell: five arch ribs of shrinking radius stepping backwards, with a solid inner shell.
## Telescoping arches read as built structure from any angle and give the stage a dark interior.
func _build_shell(kit: DecoKit, deck: DecoKit, metal: DecoKit) -> void:
	var back := STAGE_Z + STAGE_D * 0.5
	for i in SHELL_RIBS:
		var t := float(i) / float(SHELL_RIBS - 1)
		var r: float = SHELL_R - t * 0.85
		var z: float = back - 0.30 - t * 0.70
		var col: Color = SHELL_A.lerp(SHELL_B, t)
		kit.extrude(Building.arch_ring_poly(r * 1.62, r * 1.30, 0.22, 12), 0.30, col,
				Transform3D(Basis.IDENTITY, Vector3(0.0, STAGE_H - 0.10, z)))
	# solid inner shell behind the ribs, so the stage has a dark backdrop to read against
	kit.extrude(Building.arch_poly((SHELL_R - 0.85) * 1.62, (SHELL_R - 0.85) * 1.30), 0.30, SHELL_B.darkened(0.14),
			Transform3D(Basis.IDENTITY, Vector3(0.0, STAGE_H - 0.10, back + 0.55)))
	# a backstage door in the shell, with its rounded frame
	build_door(kit, Vector3(0.0, STAGE_H, back + 0.40), DOOR_W, DOOR_H, SHELL_A.lightened(0.28), STAGE_TOP, STAGE_SIDE, deck, metal)
	# a star finial on the crown of the outer arch
	metal.extrude(DecoKit.star_poly(0.36, 0.15, 5), 0.14, GOLD,
			Transform3D(Basis.IDENTITY, Vector3(0.0, STAGE_H - 0.10 + SHELL_R * 1.30 + 0.42, back - 0.30)))
	# a beam across the arch, with the sign hanging from it over the stage
	kit.rbox(Vector3(0.0, STAGE_H + 3.10, back - 0.32), Vector3(5.10, 0.17, 0.22), 0.05, SHELL_B, Basis.IDENTITY, 0)
	var plate := build_hanging_sign(kit, Vector3(0.0, STAGE_H + 3.00, back - 0.44), 2.55, 0.60,
			Color("#f6ecd6"), SHELL_B, 0.0, 0.22, null, metal)
	add_label("STAR STAGE", plate + Vector3(0.0, 0.0, -0.13), 0.27, Color("#2f5a5f"))
	set_meta("sign_plate", plate)


func _build_poles(kit: DecoKit, metal: DecoKit) -> void:
	for s in [-1.0, 1.0]:
		var base := Vector3(POLE.x * s, ground_y(Vector2(POLE.x, POLE.z).length()) - 0.02, POLE.z)
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.31, 0.10), Vector2(0.15, 0.16), Vector2(0.0, 0.17)]),
				18, Transform3D(Basis.IDENTITY, base), STONE_DEEP)
		metal.cone(base + Vector3(0.0, 0.12, 0.0), 0.095, 0.065, POLE_H - 0.12, Color("#d9d2c2"), Basis.IDENTITY, 12)
		metal.torus(base + Vector3(0.0, POLE_H * 0.52, 0.0), 0.10, 0.035, BRONZE, Basis.IDENTITY, 12)
		metal.sphere(base + Vector3(0.0, POLE_H + 0.05, 0.0), 0.11, GOLD, Vector3(1.0, 1.1, 1.0), 12)
		metal.rbox(base + Vector3(-0.30 * s, POLE_H - 0.14, 0.0), Vector3(0.62, 0.07, 0.07), 0.025, BRONZE, Basis.IDENTITY, 0)


func _build_yard(kit: DecoKit, deco: DecoKit) -> void:
	build_planter(deco, Vector3(-3.05, ground_y(3.9) - 0.02, -1.42), 1.05, TERRACOTTA, Color("#4a9a5e"), Color("#25603e"))
	build_planter(deco, Vector3(3.05, ground_y(3.9) - 0.02, -1.42), 1.0, TERRACOTTA.darkened(0.08))
	# a DJ console on the stage for dj_nova to stand behind
	var c := Vector3(-2.05, STAGE_H, STAGE_Z + 0.20)
	kit.rbox(c + Vector3(0.0, 0.42, 0.0), Vector3(1.55, 0.84, 0.62), 0.10, SPEAKER, Basis.IDENTITY, 0)
	kit.rbox(c + Vector3(0.0, 0.86, 0.0), Vector3(1.66, 0.10, 0.72), 0.04, SPEAKER_LIT, Basis.IDENTITY, 0)
	kit.rbox(c + Vector3(0.0, 0.90, -0.12), Vector3(1.10, 0.03, 0.34), 0.01, Color("#3a3648"), Basis.IDENTITY, 0)
	for i in 2:
		kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.16, 0.03), Vector2(0.0, 0.035)]),
				16, Transform3D(Basis.IDENTITY, c + Vector3(-0.28 + float(i) * 0.56, 0.92, -0.12)), Color("#464154"))


# ----------------------------------------------------------------------------- animated parts
func _build_speakers() -> void:
	for s in [-1.0, 1.0]:
		var at := Vector3(2.55 * s, STAGE_H, STAGE_Z - 0.55)
		var kit := DecoKit.new()
		kit.rbox(at + Vector3(0.0, 0.10, 0.0), Vector3(1.34, 0.20, 1.04), 0.05, SPEAKER.darkened(0.25), Basis.IDENTITY, 0)
		kit.rbox(at + Vector3(0.0, 1.18, 0.0), Vector3(1.20, 2.00, 0.92), 0.14, SPEAKER, Basis.IDENTITY, 1)
		kit.rbox(at + Vector3(0.0, 2.22, 0.0), Vector3(1.30, 0.12, 1.00), 0.04, SPEAKER_LIT, Basis.IDENTITY, 0)
		add_panel(kit.commit(), "Speaker%d" % int(s), {}, null)
		# R2.9: the grille is a cloth panel stretched over the woofers, not more painted cabinet -
		# its own mesh so it gets the weave and the frame seams instead of sheet-metal grain.
		var gk := DecoKit.new()
		gk.rbox(at + Vector3(0.0, 1.18, -0.47), Vector3(1.06, 1.84, 0.05), 0.04, SPEAKER_LIT, Basis.IDENTITY, 0)
		add_cloth(gk.commit(), "Grille%d" % int(s), GRILLE_OPTS, null)
		for i in 2:
			var wp := at + Vector3(0.0, 0.72 + float(i) * 0.92, -0.50)
			var node := pivot("Woofer%d%d" % [int(s), i], wp)
			var wk := DecoKit.new()
			var r: float = 0.40 if i == 0 else 0.30
			wk.lathe(PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.92, -0.03), Vector2(r * 0.55, -0.11), Vector2(r * 0.30, -0.13), Vector2(0.0, -0.08)]),
					20, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO), Color("#8d84a6"))
			wk.torus(Vector3(0.0, 0.0, 0.01), r * 1.02, 0.05, Color("#454055"), Basis(Vector3.RIGHT, PI * 0.5), 20)
			wk.sphere(Vector3(0.0, 0.0, -0.075), r * 0.34, Color("#e0d8ea"), Vector3(1.0, 1.0, 0.6), 14)
			add_metal(wk.commit(), "WooferCone", node)
			_woofers.append(node)
			_woofer_rest.append(node.position.z)


## Checker dance floor: a laid slab with a checker of two vertex-coloured tile meshes on top, each
## with its own emissive material so the light and dark squares pulse against each other on the
## beat. The slab underneath is what makes it read as a floor rather than tiles dropped on the plaza.
func _build_floor() -> void:
	var ka := DecoKit.new()
	var kb := DecoKit.new()
	var tw: float = FLOOR_W / float(FLOOR_TILES)
	var td: float = FLOOR_D / float(FLOOR_TILES - 2)
	for ix in FLOOR_TILES:
		for iz in FLOOR_TILES - 2:
			var x: float = -FLOOR_W * 0.5 + tw * (float(ix) + 0.5)
			var z: float = FLOOR_Z - FLOOR_D * 0.5 + td * (float(iz) + 0.5)
			var y := ground_y(Vector2(x, z).length())
			# tiles abut exactly, so the checker reads as one laid floor and not as cards on the plaza
			var kit: DecoKit = ka if (ix + iz) % 2 == 0 else kb
			var col: Color = TILE_A if (ix + iz) % 2 == 0 else TILE_B
			kit.rbox(Vector3(x, y - 0.03, z), Vector3(tw, 0.11, td), 0.008, col, Basis.IDENTITY, 0)
	_tile_a_mi = add_glow(ka.commit(), 0.0, "TilesA", 0.0, 0.0)
	_tile_b_mi = add_glow(kb.commit(), 0.0, "TilesB", 0.0, 0.0)
	# R2.9: the dance floor is 5.6 x 3.4 m and the player stands on it, so it is not one of the
	# small pieces the note exempts. hub_glow carries an opt-in laid-tile microsurface for exactly
	# this; every other emissive on the shader (panes, sign halos, bulbs) leaves it at zero.
	for mi in [_tile_a_mi, _tile_b_mi]:
		mi.set_instance_shader_parameter("surface_amount", 1.6)
		mi.set_instance_shader_parameter("surface_macro", 0.30)
	# a chunky kerb, in short segments that each sit on the curved ground
	var edge := DecoKit.new()
	var seg := 8
	for s in [-1.0, 1.0]:
		for i in seg:
			var z2: float = FLOOR_Z - FLOOR_D * 0.5 - 0.22 + (FLOOR_D + 0.44) * (float(i) + 0.5) / float(seg)
			var x2: float = (FLOOR_W * 0.5 + 0.22) * s
			edge.rbox(Vector3(x2, ground_y(Vector2(x2, z2).length()) - 0.03, z2),
					Vector3(0.24, 0.20, (FLOOR_D + 0.44) / float(seg) + 0.03), 0.05, STONE_DEEP, Basis.IDENTITY, 0)
		for i in seg + 2:
			var x3: float = -FLOOR_W * 0.5 - 0.22 + (FLOOR_W + 0.44) * (float(i) + 0.5) / float(seg + 2)
			var z3: float = FLOOR_Z + (FLOOR_D * 0.5 + 0.22) * s
			edge.rbox(Vector3(x3, ground_y(Vector2(x3, z3).length()) - 0.03, z3),
					Vector3((FLOOR_W + 0.44) / float(seg + 2) + 0.03, 0.20, 0.24), 0.05, STONE_DEEP, Basis.IDENTITY, 0)
	add_wall(edge.commit(), "FloorKerb")


## Party bulbs on a sagging wire between the two poles, one MultiMesh per bulb colour.
func _build_bulbs() -> void:
	var left := Vector3(-POLE.x + 0.30, ground_y(Vector2(POLE.x, POLE.z).length()) - 0.02 + POLE_H - 0.14, POLE.z)
	var right := Vector3(POLE.x - 0.30, left.y, POLE.z)
	var wire := DecoKit.new()
	var prev := left
	for i in range(1, 15):
		var u := float(i) / 14.0
		var p := left.lerp(right, u) + Vector3(0.0, -sin(u * PI) * 0.85, 0.0)
		wire.bar(prev, p, 0.018, Color("#4a4453"), 5)
		prev = p
	add_metal(wire.commit(), "LightWire")

	var sphere := SphereMesh.new()
	sphere.radius = 0.105
	sphere.height = 0.235
	sphere.radial_segments = 12
	sphere.rings = 7
	for c in BULB_COLORS.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = sphere
		var slots: Array[Transform3D] = []
		for i in BULBS:
			if i % BULB_COLORS.size() != c:
				continue
			var u := (float(i) + 1.0) / float(BULBS + 1)
			var p := left.lerp(right, u) + Vector3(0.0, -sin(u * PI) * 0.85 - 0.13, 0.0)
			slots.append(Transform3D(Basis.IDENTITY, p))
		mm.instance_count = slots.size()
		for i in slots.size():
			mm.set_instance_transform(i, slots[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Bulbs%d" % c
		mmi.multimesh = mm
		mmi.material_override = MaterialLib.glow(BULB_COLORS[c], 2.6)
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_bulb_mmi.append(mmi)
	# two warm lamps buried in the stage deck: they wash the dance floor and the shell the way the
	# festoon bulbs suggest, without a lamp floating in open air
	for s in [-1.0, 1.0]:
		add_light(Vector3(2.1 * s, 0.05, STAGE_Z - 1.30), Color("#ffd9a8"), 1.9, 9.0)


## Two spotlights on the shell crown. They exist only while the party is on.
func _build_spots() -> void:
	for s in [-1.0, 1.0]:
		var at := Vector3(1.75 * s, STAGE_H + 3.05, STAGE_Z + 1.25)
		var yaw := pivot("SpotYaw%d" % int(s), at)
		var kit := DecoKit.new()
		kit.rbox(Vector3(0.0, 0.12, 0.0), Vector3(0.22, 0.24, 0.22), 0.06, BRONZE, Basis.IDENTITY, 0)
		kit.lathe(PackedVector2Array([Vector2(0.10, 0.0), Vector2(0.16, -0.26), Vector2(0.24, -0.46), Vector2(0.22, -0.50), Vector2(0.13, -0.30), Vector2(0.07, -0.04)]),
				16, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-42.0)), Vector3.ZERO), SPEAKER_LIT)
		add_metal(kit.commit(), "SpotBody", yaw)
		var l := SpotLight3D.new()
		l.name = "Spot"
		l.rotation = Vector3(deg_to_rad(-132.0), 0.0, 0.0)
		l.light_color = Color("#ffd6ea") if s < 0.0 else Color("#a8e4ff")
		l.light_energy = 6.0
		l.spot_range = 13.0
		l.spot_angle = 15.0
		l.spot_angle_attenuation = 0.6
		l.shadow_enabled = false
		l.visible = false
		yaw.add_child(l)
		_spots.append(yaw)
		_spot_lights.append(l)
	# extra colour wash that only exists during the party
	for s in [-1.0, 1.0]:
		var o := OmniLight3D.new()
		o.name = "PartyGlow"
		# inside the speaker cabinets, so the colour wash has no visible lamp in mid air
		o.position = Vector3(2.55 * s, STAGE_H + 1.18, STAGE_Z - 0.55)
		o.light_color = Color("#ff9ec4") if s < 0.0 else Color("#8fe4ff")
		o.light_energy = 0.0
		o.omni_range = 8.0
		o.shadow_enabled = false
		o.visible = false
		add_child(o)
		_party_lights.append(o)


func _build_confetti() -> void:
	_confetti = GPUParticles3D.new()
	_confetti.name = "Confetti"
	_confetti.amount = 72
	_confetti.lifetime = 3.4
	_confetti.position = Vector3(0.0, STAGE_H + 3.6, STAGE_Z - 0.6)
	_confetti.local_coords = false
	_confetti.emitting = false
	_confetti.visible = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(3.2, 0.2, 1.6)
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 22.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.4
	pm.gravity = Vector3(0.0, -1.6, 0.0)
	pm.angular_velocity_min = -220.0
	pm.angular_velocity_max = 220.0
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var g := Gradient.new()
	g.set_color(0, Color("#ffd98a"))
	g.add_point(0.35, Color("#ff9ec4"))
	g.add_point(0.7, Color("#8fe4ff"))
	g.set_color(g.get_point_count() - 1, Color("#b79ade"))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	_confetti.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.10, 0.14)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = m
	_confetti.draw_pass_1 = q
	add_child(_confetti)


func _build_glow() -> void:
	var glow := DecoKit.new()
	var plate: Vector3 = get_meta("sign_plate", Vector3(0.0, 3.3, -1.9))
	glow.extrude(DecoKit.round_rect_poly(2.90, 0.88, 0.18, 5), 0.05, Color("#8fe4d8"),
			Transform3D(Basis.IDENTITY, plate + Vector3(0.0, 0.0, 0.10)))
	# console LEDs
	var c := Vector3(-2.05, STAGE_H, STAGE_Z + 0.20)
	for i in 5:
		glow.rbox(c + Vector3(-0.44 + float(i) * 0.22, 0.90, -0.30), Vector3(0.10, 0.03, 0.06), 0.012,
				BULB_COLORS[i % BULB_COLORS.size()], Basis.IDENTITY, 0)
	add_glow(glow.commit(), 2.4, "SignGlow", 1.2, 0.25)


# ----------------------------------------------------------------------------- animation
func _animate(t: float, _delta: float) -> void:
	var pulse := 0.0
	if party_active:
		pulse = 0.5 + 0.5 * sin(t * TAU / BEAT)
	else:
		pulse = 0.0
	for i in _woofers.size():
		var amp: float = 0.055 * pulse * (1.0 if i % 2 == 0 else 0.7)
		_woofers[i].position.z = _woofer_rest[i] - amp
		_woofers[i].scale = Vector3.ONE * (1.0 + amp * 0.6)
	if _tile_a_mi:
		_tile_a_mi.set_instance_shader_parameter("glow_strength", 1.05 * pulse * pulse)
		_tile_a_mi.set_instance_shader_parameter("force_on", 1.0 if party_active else 0.0)
	if _tile_b_mi:
		var off: float = 0.5 + 0.5 * sin(t * TAU / BEAT + PI)
		_tile_b_mi.set_instance_shader_parameter("glow_strength", 1.05 * off * off * (1.0 if party_active else 0.0))
		_tile_b_mi.set_instance_shader_parameter("force_on", 1.0 if party_active else 0.0)
	if not party_active:
		return
	for i in _spots.size():
		var dir: float = 1.0 if i == 0 else -1.0
		_spots[i].rotation.z = sin(t * 0.9 * dir + float(i)) * 0.42
		_spots[i].rotation.y = sin(t * 0.55 * dir) * 0.34
	for i in _party_lights.size():
		_party_lights[i].light_energy = 1.4 + 1.1 * (0.5 + 0.5 * sin(t * TAU / BEAT + PI * float(i)))


# ----------------------------------------------------------------------------- party mode
func _on_door(player: Node3D) -> void:
	if _busy:
		return
	set_party(not party_active, player)


## Turns the party on or off: music, lights, confetti, and the player's dance emote.
func set_party(on: bool, player: Node3D = null) -> void:
	if on == party_active:
		return
	party_active = on
	for l in _spot_lights:
		l.visible = on
	for o in _party_lights:
		o.visible = on
		if not on:
			o.light_energy = 0.0
	if _confetti:
		_confetti.visible = on
		_confetti.emitting = on
	for mmi in _bulb_mmi:
		mmi.set_instance_shader_parameter("force_on", 1.0 if on else 0.0)
	if on:
		AudioManager.play_music(PARTY_TRACK)
		toast("The lights come up. Let's dance!", "stardust")
		if player and player.has_method("play_emote"):
			player.play_emote("dance")
		door.prompt_text = "Stop the party"
	else:
		var track := "hub"
		if planet != null and planet.data != null and planet.data.music_track != "":
			track = planet.data.music_track
		AudioManager.play_music(track)
		toast("Party over. Same time tomorrow?", "")
		door.prompt_text = "Party!"
	EventBus.interact_prompt_changed.emit(door.prompt_text if door.is_focused() else "")


func _exit_tree() -> void:
	# never leave the event track playing on the way out of the plaza
	if party_active:
		party_active = false
