extends DecoItem
## Ice Block Table (Frost Cabin set) - a waist-high table cut from one block of ice: a chunky clear pedestal
## (a pale frozen core inside a glossy shell), a thick ice slab on top with icicles dripping from its long
## edges, and the set's cranberry knitted runner laid across it with white stripes and tassels hanging over
## both ends. On it a navy mug of cocoa with a marshmallow and a little heap of knitted snow.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const TOP_Y := 0.62
const SLAB := Vector3(1.0, 0.1, 0.66)
## The slab is a deeper ice than the set's pale ICE: under a noon sun the pale one read as white plastic.
const SLAB_ICE := Color("#a4c6dc")


func _init() -> void:
	footprint = 0.75
	collide_radius = 0.48
	collide_height = 0.7


func _build() -> void:
	var kit := DecoKit.new()
	# --- the frozen core of the pedestal and a snow drift round its foot -------------------------------
	kit.rbox(Vector3(0.0, 0.29, 0.0), Vector3(0.4, 0.5, 0.32), 0.07, FC.ICE_DEEP, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, 0.04, 0.0), Vector3(0.66, 0.08, 0.5), 0.04, FC.ICE, Basis.IDENTITY, 1)
	FC.snow_lump(kit, Vector3(0.27, 0.014, -0.2), 0.1, Basis.IDENTITY, 0)
	# --- the slab: a pale ice top, its frosted underside a touch deeper --------------------------------
	kit.rbox(Vector3(0.0, TOP_Y - SLAB.y * 0.5, 0.0), SLAB, 0.04, SLAB_ICE, Basis.IDENTITY, 1)
	kit.rbox(Vector3(0.0, TOP_Y - SLAB.y + 0.012, 0.0), SLAB - Vector3(0.06, 0.0, 0.06) + Vector3(0.0, -0.075, 0.0),
		0.012, FC.ICE_DEEP, Basis.IDENTITY, 0)
	# --- icicles dripping from both long edges ---------------------------------------------------------
	for s in [-1.0, 1.0]:
		var z: float = (SLAB.z * 0.5 - 0.03) * float(s)
		FC.icicle_row(kit, Vector3(-0.42, TOP_Y - SLAB.y + 0.01, z), Vector3(0.42, TOP_Y - SLAB.y + 0.01, z),
			7, 0.05, 0.14, 0.024, FC.ICE, 0 if s < 0.0 else 3)
	# --- the knitted runner across the top, over both ends, with tassels -------------------------------
	var rw := 0.26
	kit.rbox(Vector3(0.0, TOP_Y + 0.008, 0.0), Vector3(SLAB.x + 0.02, 0.02, rw), 0.008, FC.KNIT, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		var ex: float = (SLAB.x * 0.5 + 0.012) * float(s)
		kit.rbox(Vector3(ex, TOP_Y - 0.07, 0.0), Vector3(0.02, 0.16, rw), 0.008, FC.KNIT, Basis.IDENTITY, 0)
		for k in 4:
			var tz := lerpf(-rw * 0.4, rw * 0.4, float(k) / 3.0)
			kit.cone(Vector3(ex, TOP_Y - 0.19, tz), 0.008, 0.02, 0.05, FC.SNOW, Basis.IDENTITY, 6)
	# white stripes across the runner
	for x in [-0.3, 0.3]:
		kit.rbox(Vector3(float(x), TOP_Y + 0.013, 0.0), Vector3(0.05, 0.016, rw + 0.004), 0.006, FC.SNOW, Basis.IDENTITY, 0)
	# --- a mug of cocoa with a marshmallow, and a heap of knitted snow ---------------------------------
	var mug := Vector3(0.18, TOP_Y + 0.018, 0.02)
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.055, 0.11), Vector2(0.045, 0.11), Vector2(0.044, 0.092),
		Vector2(0.0, 0.092)]), 12, Transform3D(Basis.IDENTITY, mug), FC.NAVY)
	kit.disc(mug + Vector3(0.0, 0.094, 0.0), 0.044, Color("#8a5f48"), Basis.IDENTITY, 10)
	kit.rbox(mug + Vector3(0.012, 0.106, -0.006), Vector3(0.034, 0.026, 0.034), 0.01, FC.SNOW, Basis(Vector3.UP, 0.4), 0)
	kit.torus(mug + Vector3(0.066, 0.055, 0.0), 0.028, 0.009, FC.NAVY, Basis(Vector3.RIGHT, PI * 0.5), 8, 3)
	FC.snow_lump(kit, Vector3(-0.22, TOP_Y + 0.016, -0.04), 0.06, Basis.IDENTITY, 2)
	add_body(kit.commit())

	# --- the clear ice shell round the core: glossy, so the block reads as ice, not plastic -------------
	var shell := DecoKit.new()
	shell.rbox(Vector3(0.0, 0.31, 0.0), Vector3(0.52, 0.56, 0.42), 0.08, FC.ICE, Basis.IDENTITY, 1)
	shell.rbox(Vector3(0.0, TOP_Y - SLAB.y * 0.5 - 0.004, 0.0), SLAB + Vector3(0.03, 0.012, 0.03), 0.05, FC.ICE,
		Basis.IDENTITY, 1)
	add_glass(shell.commit(), Color("#cfe6f2"), 0.4, "IceShell")
