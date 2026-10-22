extends DecoItem
## Sled Bench (Frost Cabin set) - an old wooden sled stood up on its navy iron runners and given a back: four
## warm wood slats to sit on at knee height, the runners curling up at one end the way a sled's do, a slatted
## backrest whose top rail wears the set's cranberry knit band like a scarf, a knitted seat cushion, snow
## sitting on the backrest, and a row of icicles hanging under the front edge of the seat.

const FC := preload("res://src/decorations/sets/set_frost_cabin.gd")
const SEAT_Y := 0.42
const X0 := -0.6
const X1 := 0.64
const RZ := 0.22
const BACK_Z := 0.25


func _init() -> void:
	footprint = 0.85
	collide_radius = 0.6
	collide_height = 0.9


func _build() -> void:
	var kit := DecoKit.new()
	# --- two iron runners, curled up at the -X end ----------------------------------------------------
	for s in [-1.0, 1.0]:
		var z: float = RZ * float(s)
		JungleMeshes.tube(kit, PackedVector3Array([
			Vector3(X1, 0.03, z), Vector3(0.0, 0.026, z), Vector3(-0.55, 0.026, z), Vector3(-0.72, 0.07, z),
			Vector3(-0.8, 0.2, z), Vector3(-0.78, 0.33, z), Vector3(-0.69, 0.4, z), Vector3(-0.62, 0.36, z)]),
			PackedFloat32Array([0.026, 0.026, 0.026, 0.026, 0.025, 0.024, 0.022, 0.02]),
			PackedColorArray([FC.NAVY]), 7, true)
		# uprights from the runner to the seat
		for x in [-0.42, 0.05, 0.5]:
			kit.tube(Vector3(float(x), 0.03, z), Vector3(float(x), SEAT_Y - 0.03, z * 0.92), 0.026, FC.WOOD_DARK, 7, 1)
	# cross bars under the seat
	for x in [-0.42, 0.5]:
		kit.bar(Vector3(float(x), SEAT_Y - 0.05, -RZ), Vector3(float(x), SEAT_Y - 0.05, RZ), 0.022, FC.WOOD_DARK, 6)
	# --- the seat: four slats -------------------------------------------------------------------------
	for i in 4:
		var z2 := lerpf(-RZ + 0.03, RZ - 0.03, float(i) / 3.0)
		kit.rbox(Vector3((X0 + X1) * 0.5, SEAT_Y, z2), Vector3(X1 - X0, 0.045, 0.11), 0.018, FC.WOOD, Basis.IDENTITY, 1)
	# --- the backrest: two posts, a flat slat and a round top rail ------------------------------------
	for x in [-0.52, 0.56]:
		kit.tube(Vector3(float(x), SEAT_Y - 0.02, BACK_Z), Vector3(float(x), 0.9, BACK_Z + 0.06), 0.03, FC.WOOD_DARK, 7, 1)
	kit.rbox(Vector3(0.02, 0.62, BACK_Z + 0.03), Vector3(1.2, 0.11, 0.04), 0.018, FC.WOOD, Basis(Vector3.RIGHT, -0.1), 1)
	var rail_a := Vector3(-0.6, 0.86, BACK_Z + 0.055)
	var rail_b := Vector3(0.64, 0.86, BACK_Z + 0.055)
	kit.tube(rail_a, rail_b, 0.04, FC.WOOD, 8, 2)
	# the set's knit band wrapped round the rail like a scarf, its tail hanging down
	var along_x := Basis(Vector3.BACK, -PI * 0.5)
	FC.knit_band(kit, Vector3(-0.22, 0.86, BACK_Z + 0.055), 0.04, 0.26, 12, along_x)
	kit.rbox(Vector3(-0.12, 0.72, BACK_Z + 0.1), Vector3(0.1, 0.26, 0.025), 0.012, FC.KNIT, Basis(Vector3.BACK, 0.12), 0)
	kit.rbox(Vector3(-0.105, 0.6, BACK_Z + 0.1), Vector3(0.1, 0.035, 0.03), 0.012, FC.SNOW, Basis(Vector3.BACK, 0.12), 0)
	# snow sitting on the rail
	FC.snow_lump(kit, Vector3(0.3, 0.885, BACK_Z + 0.055), 0.07, Basis.IDENTITY, 0)
	# --- a knitted cushion on the seat (cranberry with a white stripe) -----------------------------------
	var cush := Vector3(0.28, SEAT_Y + 0.055, -0.01)
	kit.rbox(cush, Vector3(0.46, 0.07, 0.36), 0.035, FC.KNIT, Basis(Vector3.UP, 0.08), 1)
	kit.rbox(cush + Vector3(0.0, 0.006, 0.0), Vector3(0.1, 0.07, 0.37), 0.03, FC.SNOW, Basis(Vector3.UP, 0.08), 0)
	# --- icicles under the front edge of the seat ---------------------------------------------------------
	FC.icicle_row(kit, Vector3(X0 + 0.08, SEAT_Y - 0.02, -RZ - 0.03), Vector3(X1 - 0.08, SEAT_Y - 0.02, -RZ - 0.03),
		8, 0.06, 0.15, 0.024, FC.ICE)
	add_body(kit.commit())
