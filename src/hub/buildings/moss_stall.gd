class_name MossStall
extends Building
## MOSS'S STALL on The Tangle (docs/JUNGLE_PLANET_SPEC.md 3, builder J3).
##
## WHERE: the pitch J1 reserved and flattened for it, by the landing pad - `JungleLayout.stall_dir`
## (7.6 m from the pad, 55 degrees off the pad->spawn bearing), front facing `JungleLayout.stall_facing`
## (down the short trail spur toward the pad->spawn walk). The planet already keeps the pitch clear of
## trees, pools, pickups and decorations (Planet._setup_terrain, JungleLayout.STALL_FLAT_RADIUS), so,
## unlike Gloop's table, nothing here has to delete props after the fact.
## HOOK: this building id in jungle.tres `buildings` - World._spawn_buildings loads
## res://src/hub/buildings/moss_stall.tscn and calls attach_to_planet. Planet.building_dir() does not
## know the id, so it reserves nothing twice and paints no plaza path to it.
##
## WHAT IT IS: a hollow-log counter under a lean-to of one enormous leaf held on two crooked poles, a
## reed lantern pole at one end, the day's goods on the counter, and Moss standing at the other end
## (Gloop's lesson: behind a counter, a 1.3 m character is a head over a plank).
##
## THE CAMERA SHOP (MOSS2, 2026-09-30, docs/JUNGLE_PLANET_SPEC.md 6): Moss is a retired field
## photographer, so his shelf leads with CameraGoods.moss_stock() - the next lens tier and the Hover
## lesson, and since GOODS (6.1) the Field Notes, the photo filters, the Tripod and the Steady Grip -
## before the day's swamp finds (MossStock.today(): outfits and decor, unchanged). An old
## camera on a reed tripod stands by his end of the counter to say so from the path.
##
## THE FLOW (one press on the counter or on Moss, `run_flow`): a greeting -> "Want to see my lenses
## and finds?" [Browse / Bye] -> the shelf (ShopPanel) as often as you like -> the
## jungle safari offer once a day through PlanetSafari.offer_in_conversation (the neighbours' hook,
## host "moss" in worlds/jungle.gd's MANIFEST - inert until that manifest exists) -> goodbye.
## It runs on a DialogueRunner like a neighbour's talk (camera push-in, player held), not on the
## hub shops' bare DialogueBox, because it hands the same runner to the safari hook.

const MOSS_SCENE := "res://src/characters/npcs/moss.tscn"
const SHOP_TITLE := "Moss's Lenses & Finds"
## Where Moss stands, stall-local: at the right-hand end of the counter, a little back.
const MOSS_STAND := Vector3(1.28, 0.0, 0.22)
## GameState.flags keys (Moss has no npc_data entry, so no GameState.npc_data either).
const MET_FLAG := "moss_met"
const DAY_FLAG := "moss_talk_day"

# --- palette: Tangle wood and leaf, inside the palette gates (every swatch S <= 0.55)
const LOG := Color("#7a6a5c")
const LOG_DARK := Color("#5e5148")
const LOG_CUT := Color("#c7ad86")
const PLANK := Color("#a4886a")
const PLANK_DARK := Color("#7d6650")
const POLE := Color("#76697a")
const CANOPY := Color("#5f8f86")
const CANOPY_LIGHT := Color("#7ba69c")
const CANOPY_RIB := Color("#9cc7b4")
const MOSS := Color("#7f9468")
const MOSS_LIGHT := Color("#91a877")
const REED := Color("#b8a06a")
const REED_DARK := Color("#8f7a4f")
const CLOTH_A := Color("#6aa58a")
const CLOTH_B := Color("#3f4a5e")
const JAR := Color("#9fc4b8")
const POD := Color("#b8a3cf")
const SIGN := Color("#c7ad86")
const INK := Color("#4a3a2c")
const GLOW_WARM := Color("#ffd489")
const GLOW_COOL := Color("#b8ecd2")

var _moss: Node = null
var _talks: int = 0
var _strands: Array[Node3D] = []


func _init() -> void:
	building_id = "moss_stall"
	display_name = "Moss's Stall"
	ground_sink = 0.05
	ground_radius = 14.0
	footprint_size = Vector3(2.5, 0.95, 0.95)
	footprint_offset = Vector3(-0.30, 0.0, 0.12)
	door_local = Vector3(-0.2, 0.9, -0.75)
	door_prompt = "Talk to Moss"


# ==================================================================================== placement
func attach_to_planet(p: Planet) -> void:
	planet = p
	if p == null or p.data == null:
		return
	ground_radius = p.radius
	var dir := JungleLayout.stall_dir(p.data)
	var facing := JungleLayout.stall_facing(p.data)
	# -Z of the returned basis points along the hint; the counter faces -Z.
	global_transform = p.surface_transform(dir, facing)
	global_position -= global_transform.basis.y * ground_sink
	_add_contact_shadow()
	_on_attached(p, dir)


func _on_attached(p: Planet, _dir: Vector3) -> void:
	_spawn_moss(p)


func _spawn_moss(p: Planet) -> void:
	if not ResourceLoader.exists(MOSS_SCENE):
		push_warning("MossStall: missing " + MOSS_SCENE)
		return
	var n: Node = load(MOSS_SCENE).instantiate()
	n.name = "moss"
	var stand := global_transform * MOSS_STAND
	n.set("stall_home", (stand - p.global_position).normalized())
	n.set("stall", self)
	n.set("planet", p)
	get_parent().add_child(n)
	_moss = n


## The keeper, for the safari world (a "neighbour"-tier subject) and for tests.
func moss() -> Node:
	return _moss if is_instance_valid(_moss) else null


# ==================================================================================== geometry
func _build() -> void:
	var wood := DecoKit.new()
	var body := DecoKit.new()
	var leaf := DecoKit.new()
	var glow := DecoKit.new()
	_build_counter(wood, body, glow)
	_build_canopy(wood, leaf, glow)
	_build_lantern_pole(body, glow)
	_build_yard(wood, body, glow)
	_build_tripod(wood, body, glow)
	add_wood(wood.commit(), Vector3.RIGHT, "Timber")
	add_body(body.commit(), "Goods")
	add_body(leaf.commit(), "Leaf")
	add_glow(glow.commit(), 2.2, "Glow", 0.4)
	# the lantern light sits inside its cage (Building.add_light: never in open air)
	add_light(Vector3(-1.36, 1.86, -0.30), GLOW_WARM, 2.8, 8.0)
	add_light(Vector3(-0.42, 0.82, 0.08), GLOW_COOL, 1.2, 5.0)   # inside the middle jar
	_build_sign()
	animate()


## The counter: a fat hollow log lying on its side, flat-topped with a plank, moss creeping over one
## end, and the day's goods on top.
func _build_counter(wood: DecoKit, body: DecoKit, glow: DecoKit) -> void:
	var x0 := -1.20
	var x1 := 0.60
	var r := 0.34
	var L := x1 - x0
	var along := DecoKit.axis_basis(Vector3.RIGHT)   # a lathe's +Y turned to run along +X
	wood.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.90, 0.0), Vector2(r, 0.08),
		Vector2(r * 0.96, L * 0.5), Vector2(r, L - 0.08), Vector2(r * 0.90, L), Vector2(0.0, L)]),
		14, Transform3D(along, Vector3(x0, r, 0.10)), LOG, true)
	# the cut ends: pale rings, the left one hollow (a dark mouth) where something lives
	var out_l := DecoKit.axis_basis(Vector3.LEFT)
	wood.disc(Vector3(x0 - 0.004, r, 0.10), r * 0.86, LOG_CUT, out_l, 16)
	wood.torus(Vector3(x0 - 0.008, r, 0.10), r * 0.60, 0.014, LOG, out_l, 14, 3)
	body.disc(Vector3(x0 - 0.012, r, 0.10), r * 0.42, Color("#2e2a2a"), out_l, 12)
	wood.disc(Vector3(x1 + 0.004, r, 0.10), r * 0.86, LOG_CUT, along, 16)
	for rr: float in [0.25, 0.52]:
		wood.torus(Vector3(x1 + 0.008, r, 0.10), r * rr, 0.010, LOG, along, 14, 3)
	# the plank top and two wedges under it
	wood.rbox(Vector3((x0 + x1) * 0.5, r * 2.0 + 0.035, 0.08), Vector3(x1 - x0 + 0.24, 0.07, 0.56), 0.025, PLANK, Basis.IDENTITY, 1)
	wood.rbox(Vector3((x0 + x1) * 0.5, r * 2.0 - 0.01, -0.19), Vector3(x1 - x0 + 0.10, 0.04, 0.04), 0.012, PLANK_DARK, Basis.IDENTITY, 0)
	# moss creeping over the left end and down the front
	for i in 6:
		var t := float(i) / 5.0
		body.sphere(Vector3(x0 + 0.06 + 0.22 * t, r * 2.0 + 0.07 - 0.05 * t, 0.10 + 0.20 * sin(t * 3.0)), 0.10 - 0.02 * t,
			MOSS if i % 2 == 0 else MOSS_LIGHT, Vector3(1.0, 0.5, 1.0), 8)
	for i in 4:
		var x := x0 + 0.15 + 0.14 * float(i)
		JungleMeshes.tube(body, PackedVector3Array([Vector3(x, r * 2.0 + 0.02, -0.22), Vector3(x + 0.02, r * 1.6, -0.30),
			Vector3(x, r * 1.25 - 0.05 * float(i % 2), -0.33)]), PackedFloat32Array([0.03, 0.022, 0.01]),
			PackedColorArray([MOSS, MOSS, MOSS.darkened(0.12)]), 5, true)
	var top := r * 2.0 + 0.07
	# --- THE GOODS on the counter: what Moss sells, as objects, so the stall reads as a shop -----
	# a folded pond-green suit with a pink cuff, and a dark one under it
	body.rbox(Vector3(0.28, top + 0.05, 0.10), Vector3(0.38, 0.09, 0.30), 0.03, CLOTH_B, Basis(Vector3.UP, 0.12), 1)
	body.rbox(Vector3(0.28, top + 0.13, 0.10), Vector3(0.34, 0.07, 0.26), 0.03, CLOTH_A, Basis(Vector3.UP, -0.05), 1)
	body.rbox(Vector3(0.28, top + 0.13, -0.035), Vector3(0.34, 0.075, 0.03), 0.012, Color("#e6c7cf"), Basis(Vector3.UP, -0.05), 0)
	# three jars of glowing firefly-seeds, stoppered
	for k in 3:
		var p := Vector3(-0.62 + 0.20 * float(k), top, 0.16 - 0.08 * float(k % 2))
		body.cylinder(p, 0.075, 0.07, 0.20 - 0.03 * float(k), JAR, Basis.IDENTITY, 10)
		body.cylinder(p + Vector3(0.0, 0.20 - 0.03 * float(k), 0.0), 0.045, 0.05, 0.04, REED_DARK, Basis.IDENTITY, 8)
		for s in 3:
			glow.sphere(p + Vector3(0.025 * float(s - 1), 0.05 + 0.04 * float(s), 0.02 * float((s + k) % 2)), 0.022,
				GLOW_COOL if k != 1 else GLOW_WARM, Vector3.ONE, 6)
	# a little glow pod lying on a lily pad
	var pad_c := Vector3(-0.15, top + 0.01, 0.12)
	for i in 10:
		var a0 := 0.3 + (TAU - 0.5) * float(i) / 10.0
		var a1 := 0.3 + (TAU - 0.5) * float(i + 1) / 10.0
		body.triangle(pad_c, pad_c + Vector3(cos(a0) * 0.20, 0.0, sin(a0) * 0.20), pad_c + Vector3(cos(a1) * 0.20, 0.0, sin(a1) * 0.20),
			Color("#5f9e6e").darkened(0.05 * float(i % 2)), true)
	body.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.03), Vector2(0.10, 0.12), Vector2(0.06, 0.22), Vector2(0.0, 0.25)]),
		8, Transform3D(Basis(Vector3.FORWARD, 1.2), pad_c + Vector3(0.10, 0.07, 0.0)), POD, false)
	glow.sphere(pad_c + Vector3(-0.02, 0.12, -0.05), 0.02, GLOW_COOL, Vector3(1.0, 1.6, 1.0), 6)
	glow.sphere(pad_c + Vector3(-0.07, 0.10, -0.03), 0.018, GLOW_COOL, Vector3(1.0, 1.6, 1.0), 6)


## The lean-to: two crooked poles at the back and ONE enormous heart-leaf laid over them, sloping
## down to the back so the gameplay camera (above and in front) sees under it.
func _build_canopy(wood: DecoKit, leaf: DecoKit, glow: DecoKit) -> void:
	var poles := [Vector3(-1.30, 0.0, 0.62), Vector3(1.55, 0.0, 0.58)]
	for ip in poles.size():
		var b: Vector3 = poles[ip]
		var lean := -0.10 if ip == 0 else 0.12
		JungleMeshes.tube(wood, PackedVector3Array([b, b + Vector3(lean * 0.4, 0.8, 0.02), b + Vector3(lean, 1.6, -0.02),
			b + Vector3(lean * 1.3, 2.25, 0.02)]), PackedFloat32Array([0.075, 0.06, 0.055, 0.045]),
			PackedColorArray([POLE.darkened(0.1), POLE, POLE, POLE.lightened(0.05)]), 7, true)
		# root feet
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.5
			var o := Vector3(cos(a), 0.0, sin(a))
			JungleMeshes.tube(wood, PackedVector3Array([b + Vector3(0, 0.18, 0), b + o * 0.16 + Vector3(0, 0.05, 0), b + o * 0.28 + Vector3(0, -0.03, 0)]),
				PackedFloat32Array([0.05, 0.035, 0.02]), PackedColorArray([POLE, POLE.darkened(0.1), POLE.darkened(0.2)]), 5, true)
	# the cross-pole the leaf rests on
	JungleMeshes.tube(wood, PackedVector3Array([Vector3(-1.43, 2.12, 0.60), Vector3(0.10, 2.20, 0.62), Vector3(1.72, 2.14, 0.58)]),
		PackedFloat32Array([0.04, 0.045, 0.04]), PackedColorArray([POLE, POLE, POLE]), 6, true)
	# THE LEAF: a big heart blade running front-to-back (tip at the back), folded along its midrib,
	# arched up in the middle, then a second smaller one crossing it for a layered, grown roof.
	var base := Vector3(0.12, 2.28, -0.55)
	var length := 2.35
	var rise := 0.30
	var droop := 0.95
	var fold := 0.16
	var widths := PackedFloat32Array([0.55, 1.35, 1.62, 1.55, 1.25, 0.75, 0.0])
	JungleMeshes.blade(leaf, base, Vector3(0.0, 0.0, 1.0), length, widths, rise, droop, fold,
		CANOPY_LIGHT, CANOPY, 0.16)
	var widths2 := PackedFloat32Array([0.30, 0.62, 0.72, 0.6, 0.35, 0.0])
	JungleMeshes.blade(leaf, Vector3(-0.95, 2.36, 0.20), Vector3(-0.35, 0.0, 1.0), 1.6, widths2, 0.2, 0.7, 0.2,
		CANOPY, CANOPY_LIGHT.darkened(0.05), 0.14)
	# the pale midrib and six side veins riding on the big leaf (the blade's own centreline maths, so
	# they sit ON it), which is what turns a green sheet into a leaf at 6 m
	var rib := PackedVector3Array()
	var rib_r := PackedFloat32Array()
	var rib_c := PackedColorArray()
	var n := widths.size()
	for i in n:
		var t := float(i) / float(n - 1)
		var y := rise * 4.0 * t * (1.0 - t) * 0.5 + rise * t * 0.5 - droop * t * t
		rib.append(base + Vector3(0.0, y + fold * widths[i] + 0.02, length * t))
		rib_r.append(lerpf(0.045, 0.012, t))
		rib_c.append(CANOPY_RIB)
	JungleMeshes.tube(leaf, rib, rib_r, rib_c, 5, true)
	for i in [1, 2, 3]:
		for sx: float in [-1.0, 1.0]:
			var a: Vector3 = rib[i]
			var w: float = widths[i] * 0.78
			var t2 := (float(i) + 0.8) / float(n - 1)
			var y2 := rise * 4.0 * t2 * (1.0 - t2) * 0.5 + rise * t2 * 0.5 - droop * t2 * t2
			var b := base + Vector3(sx * w, y2 + 0.03, length * t2)
			var m := (a + b) * 0.5 + Vector3(0.0, 0.03, 0.0)
			JungleMeshes.tube(leaf, PackedVector3Array([a, m, b]), PackedFloat32Array([0.018, 0.013, 0.008]),
				PackedColorArray([CANOPY_RIB, CANOPY_RIB, CANOPY_RIB.darkened(0.1)]), 4, false)
	# WARES ON STRINGS along the leaf's front edge - what makes it read as a shop from the path:
	# a dried-pod pair, a jar of glowing seeds, a fern bundle, a little lily lamp, another pod pair.
	for k in 5:
		var x := -0.95 + 0.50 * float(k)
		var edge_t := clampf(absf(x) / 1.6, 0.0, 1.0)
		var top := Vector3(x, 2.20 - 0.14 * edge_t, -0.50 + 0.10 * edge_t)
		var drop := 0.34 + 0.08 * float(k % 2)
		var hang := top - Vector3(0.0, drop, 0.0)
		leaf.cylinder(hang, 0.006, 0.006, drop, INK, Basis.IDENTITY, 4)
		match k:
			0, 4:
				for j in 2:
					var p := hang + Vector3(0.05 * (float(j) * 2.0 - 1.0), -0.05 - 0.05 * float(j), 0.0)
					leaf.lathe(PackedVector2Array([Vector2(0.0, -0.10), Vector2(0.05, -0.07), Vector2(0.055, 0.0),
						Vector2(0.03, 0.05), Vector2(0.0, 0.06)]), 8, Transform3D(Basis.IDENTITY, p), POD if j == 0 else Color("#c7a88a"), false)
			1:
				leaf.cylinder(hang - Vector3(0.0, 0.16, 0.0), 0.06, 0.055, 0.16, JAR, Basis.IDENTITY, 10)
				leaf.cylinder(hang - Vector3(0.0, 0.01, 0.0), 0.035, 0.04, 0.03, REED_DARK, Basis.IDENTITY, 8)
				for j in 3:
					glow.sphere(hang + Vector3(0.02 * float(j - 1), -0.11 + 0.03 * float(j), 0.0), 0.02, GLOW_COOL, Vector3.ONE, 6)
			2:
				for j in 5:
					var a2 := -0.4 + 0.2 * float(j)
					leaf.bar(hang, hang + Vector3(sin(a2) * 0.10, -0.30, cos(a2) * 0.02), 0.012, MOSS if j % 2 == 0 else CANOPY, 4)
				leaf.torus(hang - Vector3(0.0, 0.04, 0.0), 0.03, 0.01, REED_DARK, Basis.IDENTITY, 8, 3)
			3:
				for i2 in 8:
					var a0 := 0.3 + (TAU - 0.4) * float(i2) / 8.0
					var a1 := 0.3 + (TAU - 0.4) * float(i2 + 1) / 8.0
					var c := hang + Vector3(0.0, 0.0, 0.0)
					leaf.triangle(c, c + Vector3(cos(a0) * 0.11, -0.04, sin(a0) * 0.11), c + Vector3(cos(a1) * 0.11, -0.04, sin(a1) * 0.11),
						Color("#6f9a6c"), true)
				glow.sphere(hang - Vector3(0.0, 0.07, 0.0), 0.045, GLOW_WARM, Vector3(1.0, 1.2, 1.0), 8)


## The reed lantern pole at the left end: tall, bent at the top, with a lily-pad shade over a
## warm glowing bulb. This is what finds the stall at night (the nights are long).
func _build_lantern_pole(body: DecoKit, glow: DecoKit) -> void:
	var b := Vector3(-1.62, 0.0, -0.30)
	var pts := PackedVector3Array([b, b + Vector3(0.0, 0.9, 0.0), b + Vector3(0.02, 1.8, 0.0), b + Vector3(0.10, 2.25, 0.0),
		b + Vector3(0.24, 2.36, 0.0)])
	JungleMeshes.tube(body, pts, PackedFloat32Array([0.045, 0.04, 0.035, 0.03, 0.025]),
		PackedColorArray([REED_DARK, REED, REED, REED, REED_DARK]), 7, true)
	for y: float in [0.6, 1.2, 1.75]:
		body.torus(b + Vector3(0.0, y, 0.0), 0.042, 0.012, REED_DARK, Basis.IDENTITY, 10, 3)
	# the lantern hangs from the bent tip
	var hang := b + Vector3(0.26, 2.30, 0.0)
	var lamp := Vector3(hang.x, 1.86, hang.z)
	body.cylinder(lamp + Vector3(0.0, 0.14, 0.0), 0.006, 0.006, hang.y - lamp.y - 0.12, INK, Basis.IDENTITY, 4)
	# lily-pad shade
	for i in 12:
		var a0 := 0.4 + (TAU - 0.6) * float(i) / 12.0
		var a1 := 0.4 + (TAU - 0.6) * float(i + 1) / 12.0
		var c := lamp + Vector3(0.0, 0.18, 0.0)
		body.triangle(c, c + Vector3(cos(a0) * 0.24, -0.07, sin(a0) * 0.24), c + Vector3(cos(a1) * 0.24, -0.07, sin(a1) * 0.24),
			Color("#5f9e6e").darkened(0.05 * float(i % 2)), true)
	# the bulb, and a woven reed cage round it
	glow.sphere(lamp, 0.13, GLOW_WARM, Vector3(1.0, 1.2, 1.0), 12)
	for k in 5:
		var a := TAU * float(k) / 5.0
		body.bar(lamp + Vector3(cos(a) * 0.115, 0.12, sin(a) * 0.115), lamp + Vector3(cos(a) * 0.105, -0.12, sin(a) * 0.105), 0.008, REED_DARK, 4)
	body.torus(lamp + Vector3(0.0, -0.12, 0.0), 0.10, 0.014, REED_DARK, Basis.IDENTITY, 10, 3)


## Around the stall: a woven mat where customers stand, a basket of pods, a stack of stepping stones
## by the counter, and a reed bundle leaning on the back pole.
func _build_yard(wood: DecoKit, body: DecoKit, glow: DecoKit) -> void:
	# the mat, low and wide in front of the counter
	var mat_c := Vector3(-0.30, 0.03, -0.95)
	body.rbox(mat_c, Vector3(1.9, 0.04, 0.9), 0.03, Color("#a89468"), Basis.IDENTITY, 1)
	for i in 6:
		body.rbox(mat_c + Vector3(-0.78 + 0.31 * float(i), 0.025, 0.0), Vector3(0.05, 0.02, 0.86), 0.01, Color("#8a7650"), Basis.IDENTITY, 0)
	# a basket of pods behind Moss
	var bk := Vector3(1.62, 0.0, -0.05)
	body.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.20, 0.0), Vector2(0.26, 0.24), Vector2(0.24, 0.27), Vector2(0.0, 0.27)]),
		12, Transform3D(Basis.IDENTITY, bk), Color("#a4886a"), false)
	body.torus(bk + Vector3(0.0, 0.26, 0.0), 0.25, 0.022, Color("#7d6650"), Basis.IDENTITY, 12, 3)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var p := bk + Vector3(cos(a) * 0.10, 0.26, sin(a) * 0.10)
		body.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.08, 0.03), Vector2(0.085, 0.10), Vector2(0.05, 0.18), Vector2(0.0, 0.20)]),
			8, Transform3D(Basis(Vector3(cos(a), 0.0, sin(a)).cross(Vector3.UP).normalized(), 0.35), p), POD, false)
		glow.sphere(p + Vector3(cos(a) * 0.05, 0.10, sin(a) * 0.05), 0.016, GLOW_COOL, Vector3(1.0, 1.8, 1.0), 5)
	# a bundle of reeds leaning on the right pole
	for k in 5:
		var off := Vector3(0.06 * float(k - 2), 0.0, 0.03 * float(k % 2))
		var b2 := Vector3(1.78, 0.0, 0.70) + off
		wood.bar(b2, b2 + Vector3(-0.22 + 0.03 * float(k), 1.35 + 0.1 * float(k % 3), -0.05), 0.018, REED if k % 2 == 0 else REED_DARK, 5)
	# three stepping stones up the spur toward the counter
	for k in 3:
		body.rbox(Vector3(-0.2 + 0.25 * float(k % 2), 0.02, -1.75 - 0.55 * float(k)), Vector3(0.42, 0.06, 0.34), 0.05,
			Color("#8f978b"), Basis(Vector3.UP, 0.3 * float(k)), 1)


## THE OLD CAMERA: a boxy field camera with a lens on a three-legged reed tripod, standing just
## behind the counter's end at Moss's side (inside the stall's footprint, so nobody walks through it),
## pointed out at the jungle - he is still waiting for his rare sight.
func _build_tripod(wood: DecoKit, body: DecoKit, glow: DecoKit) -> void:
	var foot := Vector3(0.86, 0.0, 0.55)
	var head := foot + Vector3(0.0, 1.02, 0.0)
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.4
		wood.bar(head, foot + Vector3(cos(a) * 0.26, 0.0, sin(a) * 0.26), 0.016, REED if k != 1 else REED_DARK, 5)
	wood.bar(head, head + Vector3(0.0, 0.06, 0.0), 0.022, REED_DARK, 6)
	# the camera looks out past the path, a little up (the canopy is where rare things live)
	var aim := Basis(Vector3.UP, 0.55) * Basis(Vector3.RIGHT, 0.12)
	var c := head + Vector3(0.0, 0.14, 0.0)
	body.rbox(c, Vector3(0.24, 0.16, 0.16), 0.03, Color("#4a4452"), aim, 1)
	body.rbox(c + aim * Vector3(-0.05, 0.10, 0.02), Vector3(0.08, 0.05, 0.08), 0.015, Color("#5c5566"), aim, 1)
	body.rbox(c + aim * Vector3(0.0, 0.0, 0.0), Vector3(0.245, 0.05, 0.165), 0.01, PLANK, aim, 0)
	var lens_axis := aim * Vector3(0.0, 0.0, -1.0)
	var lens_b := DecoKit.axis_basis(lens_axis)
	body.cylinder(c + lens_axis * 0.07, 0.058, 0.066, 0.13, Color("#3a3640"), lens_b, 12)
	body.torus(c + lens_axis * 0.20, 0.056, 0.010, PLANK_DARK, lens_b, 12, 3)
	glow.disc(c + lens_axis * 0.206, 0.040, GLOW_COOL, lens_b, 12)
	# a moss tuft on top: it has stood here a long time
	body.sphere(c + aim * Vector3(0.06, 0.09, 0.03), 0.045, MOSS, Vector3(1.0, 0.5, 1.0), 8)


## A small wooden sign on a stake at the counter's front-left, lettered "MOSS".
func _build_sign() -> void:
	var sk := DecoKit.new()
	var at := Vector3(-1.05, 0.0, -0.62)
	sk.bar(at, at + Vector3(0.0, 1.05, 0.0), 0.028, LOG_DARK, 6)
	var plate := at + Vector3(0.0, 1.05, -0.03)
	sk.rbox(plate, Vector3(0.58, 0.24, 0.05), 0.04, SIGN, Basis(Vector3.FORWARD, 0.06), 1)
	sk.sphere(plate + Vector3(0.24, 0.10, -0.03), 0.05, MOSS, Vector3(1.0, 0.6, 0.8), 8)
	add_wood(sk.commit(), Vector3.RIGHT, "Sign")
	var l := add_label("MOSS", plate + Vector3(0.0, 0.0, -0.035), 0.16, INK)
	l.rotation.z = 0.06


# =================================================================================== the flow
func _on_door(player: Node3D) -> void:
	await run_flow(player)


## THE ONE PRESS. Public, because moss_npc.gd routes Moss's own interact straight here.
func run_flow(player: Node3D = null) -> void:
	# Never during a safari (or its fade-in): measured in the J3 run, an interact press in the half
	# second between "Let's go!" and the fade reached this counter and opened the shelf over the
	# safari's camera UI.
	if _busy or PhotoMode.active or PlanetSafari.current != null:
		return
	var npc := moss() as Node3D
	if npc == null:
		return
	var runner := DialogueRunner.get_or_create(self)
	if runner == null or runner.is_active():
		return
	_busy = true
	_talks += 1
	runner.begin(npc, player)
	if npc.has_method("attend"):
		npc.call("attend", player)
	var day := GameState.day_count
	if not GameState.flag(MET_FLAG):
		GameState.set_flag(MET_FLAG)
		GameState.flags[DAY_FLAG] = day
		await runner.say(npc, MossLines.INTRO)
		if npc.has_method("play_emote"):
			npc.call("play_emote", "wave")
	elif int(GameState.flags.get(DAY_FLAG, -1)) != day:
		GameState.flags[DAY_FLAG] = day
		await runner.say(npc, [MossLines.pick(MossLines.GREET, "greet%d" % day)])
	else:
		await runner.say(npc, [MossLines.pick(MossLines.AGAIN, "again%d_%d" % [day, _talks])])
	var prompt := MossLines.ASK
	var looked := false
	var bought_any := false
	while true:
		# GOODS: once today's Field Notes are bought, a "Notes" pill asks about any world again today.
		var opts: Array = MossLines.SHOP_OPTIONS.duplicate()
		var notes_on := CameraGoods.notes_today()
		if notes_on:
			opts.insert(1, MossLines.NOTES_OPTION)
		var choice: int = await runner.ask(npc, prompt, opts)
		if notes_on and choice == 1:
			await FieldNotes.run(runner, npc)
			prompt = MossLines.ASK_AGAIN
			continue
		if choice != 0:
			break
		looked = true
		var bought: Array = await _browse(runner, npc)
		if not bought.is_empty():
			bought_any = true
			await _after_buying(runner, npc, bought, day)
		prompt = MossLines.ASK_AGAIN
	if looked and not bought_any:
		await runner.say(npc, [MossLines.pick(MossLines.JUST_LOOKING, "look%d_%d" % [day, _talks])])
	# THE JUNGLE SAFARI, once a day: the same hook every neighbour's talk ends with. It says nothing
	# at all unless worlds/jungle.gd's MANIFEST names "moss" as the host.
	await PlanetSafari.offer_in_conversation(runner, npc)
	if PlanetSafari.current == null:
		await runner.say(npc, [MossLines.pick(MossLines.BYE, "bye%d_%d" % [day, _talks])])
	runner.finish()
	if npc.has_method("release"):
		npc.call("release")
	_busy = false


## What Moss says after a visit to the shelf. The Hover lesson is taught in full whenever it was bought
## (it is the only place the game explains hovering); otherwise one line about the last thing bought.
func _after_buying(runner: DialogueRunner, npc: Node3D, bought: Array, day: int) -> void:
	if bought.has(CameraGoods.HOVER_ID):
		await runner.say(npc, MossLines.HOVER_TAUGHT)
		if npc.has_method("play_emote"):
			npc.call("play_emote", "happy")
	# GOODS (docs/JUNGLE_PLANET_SPEC.md 6.1): the Steady Grip and the Tripod are explained once, when bought.
	if bought.has(CameraGoods.GRIP_ID):
		await runner.say(npc, MossLines.BOUGHT_GRIP)
	if bought.has(CameraGoods.TRIPOD_ID):
		await runner.say(npc, MossLines.BOUGHT_TRIPOD)
	var said := [CameraGoods.HOVER_ID, CameraGoods.GRIP_ID, CameraGoods.TRIPOD_ID, CameraGoods.NOTES_ID]
	var last := ""
	for id: Variant in bought:
		if not said.has(str(id)):
			last = str(id)
	# The Field Notes: bought today -> Moss asks which world and tells (FieldNotes.run). Last, so the
	# tip is the thing the player leaves with.
	if bought.has(CameraGoods.NOTES_ID):
		if last != "":
			await _say_bought(runner, npc, last, day)
		await runner.say(npc, [MossLines.BOUGHT_NOTES])
		await FieldNotes.run(runner, npc)
		return
	if last == "":
		return
	await _say_bought(runner, npc, last, day)


## One line about the item `last` just bought (a lens, a filter, a swamp find or a suit).
func _say_bought(runner: DialogueRunner, npc: Node3D, last: String, day: int) -> void:
	if last.begins_with(CameraGoods.FILTER_ID_PREFIX):
		var fdef: Dictionary = {}
		for f: Dictionary in CameraGoods.FILTERS:
			if CameraGoods.FILTER_ID_PREFIX + str(f["id"]) == last:
				fdef = f
		await runner.say(npc, [MossLines.pick(MossLines.BOUGHT_FILTER, last + str(day)) % str(fdef.get("name", "filter"))])
		return
	if last.begins_with("camera_lens_"):
		var lens_name: String = str(CameraGoods.LENS_NAMES[clampi(int(last.trim_prefix("camera_lens_")) - 1, 0,
			CameraGoods.LENS_NAMES.size() - 1)])
		await runner.say(npc, [MossLines.pick(MossLines.BOUGHT_LENS, last + str(day)) % lens_name])
		return
	var def: Dictionary = Catalog.get_item(last)
	var pool: Array = MossLines.BOUGHT_WEAR if str(def.get("kind", "")) == "clothing" else MossLines.BOUGHT
	await runner.say(npc, [MossLines.pick(pool, last + str(day)) % str(def.get("name", "that"))])


## Opens the shelf: Moss's camera goods (CameraGoods.moss_stock: Field Notes, filters, Tripod, Steady
## Grip, the next lens, the Hover lesson) in front of today's swamp
## finds. Returns every id bought this visit, in order ([] for none).
func _browse(runner: DialogueRunner, npc: Node3D) -> Array:
	var panel := shop()
	if panel == null:
		await runner.say(npc, [MossLines.NO_SHELF])
		return []
	var box := dialogue()
	if box != null:
		box.hide_box()
	await get_tree().process_frame
	var bought: Array[String] = []
	var on_buy := func(item_id: String) -> void:
		bought.append(item_id)
		var def: Dictionary = Catalog.get_item(item_id)
		if str(def.get("kind", "")) == "clothing":
			_wear(item_id)
	panel.purchased.connect(on_buy)
	panel.open(CameraGoods.moss_stock() + MossStock.today(), "buy", SHOP_TITLE, MossLines.NAME)
	await panel.closed
	if panel.purchased.is_connected(on_buy):
		panel.purchased.disconnect(on_buy)
	await get_tree().process_frame
	return bought


## Suit-Up's rule (clothes_store.gd `_wear`): a garment goes in the wardrobe and on at once.
func _wear(item_id: String) -> void:
	var def: Dictionary = Catalog.get_item(item_id)
	if def.is_empty():
		return
	if not GameState.wardrobe.has(item_id):
		GameState.wardrobe.append(item_id)
	var style: Dictionary = def.get("style", {})
	for k: Variant in style.keys():
		GameState.player_style[k] = style[k]
	EventBus.player_style_changed.emit()
	toast("Now wearing the %s!" % str(def.get("name", "new outfit")), item_id)


func _animate(_time: float, _delta: float) -> void:
	pass


# ================================================================================ dev / capture
## EVERYTHING BELOW IS SYNTHETIC: hooks a Director timeline uses to frame the stall. None of them goes
## through real input, and none proves a finger on a phone works. Named dev_* so that is never in doubt.

## Stands the player at stall-local (x, 0, z) facing stall-local (ax, 0.6, az), camera `cam` metres
## back (the print table's framing helper, same rules).
func dev_look_from(x: float, z: float, ax: float, az: float, cam: float = 4.0) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or planet == null:
		return
	var to_dir := planet.dir_of(to_global(Vector3(x, 0.0, z)))
	var stand := planet.surface_point(to_dir)
	p.call("place_on_planet", to_dir, to_global(Vector3(ax, 0.60, az)) - stand, 0.06)
	var rig := get_node_or_null("/root/World/CameraRig")
	if rig != null and rig.has_method("reseat_behind_player"):
		if cam > 0.0 and rig.has_method("debug_set_framing"):
			rig.call("debug_set_framing", cam, -1.0)
		rig.call("reseat_behind_player")


## Starts the flow as if the player pressed interact on the counter.
func dev_press() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	run_flow(p)


## One line for a timeline to assert against: where the stall and Moss are, and today's shelf.
func dev_report(tag: String = "") -> void:
	var shelf := CameraGoods.moss_stock() + MossStock.today()
	var names: Array = []
	for d: Dictionary in shelf:
		names.append("%s=%d(%s)" % [d.get("id", ""), int(d.get("price", 0)), MossStock.tier_of(int(d.get("price", 0)))])
	var m := moss() as Node3D
	var md := -1.0
	if m != null:
		md = m.global_position.distance_to(global_position)
	print("MOSSSTALL %s day=%d stardust=%d moss_dist=%.2f hover_learned=%s film_upgrades=%d depot=%s shelf=%s" % [tag,
		GameState.day_count, GameState.stardust, md, str(GameState.flags.get(CameraGoods.HOVER_FLAG, false)),
		GameState.film_upgrades, str(CameraGoods.depot_stock().map(func(d: Dictionary) -> String: return str(d.get("id", "")))),
		", ".join(names)])
