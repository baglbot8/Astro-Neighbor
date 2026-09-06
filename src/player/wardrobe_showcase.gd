extends Node3D
## showcase/astronaut_wardrobe.tscn — every suit the clothes shop sells, worn, under the REAL
## gameplay lighting, so the dome/visor contrast law (AstronautModel.DOME_MIN_V) can be judged with
## eyes rather than argued about.
##
## Why this scene exists: the integration critic found that wearing the shop's Deep Space Suit
## (#2e3760) rendered the helmet shell DARKER than the opaque visor pane, so the character's single
## most important read — a dark window in a light shell — inverted and the head became one black
## ball. Three suits in the catalog are dark enough to do that and several more get close, and no
## showcase existed that would have caught it: the turntable's four hand-written variants happened
## to be light. This one reads the shop's own catalog, so a suit added there shows up here.
##
## LIGHTING: instantiates res://src/world/environment.tscn exactly like the turntable does
## (docs/AGENT_WORKFLOW.md: a showcase whose lighting differs from the game is worse than none).
##
## Flags (after "--"):
##   --page=N      which row of PER_PAGE suits to show (0-based; default 0)
##   --gameplay    the real gameplay camera distance/pitch instead of the contact-sheet framing
##   --back        show the row from behind (the angle the gameplay camera actually lives at)
##   --contrast    print the albedo dome/visor table for every suit and quit-worthy numbers
const CATALOG := preload("res://src/hub/clothing_catalog.gd")

const PER_PAGE := 6
const SPACING := 1.45
## Contact-sheet camera: far enough that a row of PER_PAGE fits, close enough that each helmet is
## ~200 px tall at 720p — bigger than gameplay, which is the point of a contact sheet.
const SHEET_DIST := 6.1
const SHEET_PITCH_DEG := 12.0
## The real gameplay camera. REFERENCED, not copied, so R2.10's move from 6.5 m to 7.4 m cannot leave
## the wardrobe judging suits at a distance the game no longer uses.
const GAMEPLAY_DIST := CameraRig.DIST_DEFAULT
const GAMEPLAY_PITCH_DEG := CameraRig.PITCH_DEFAULT_DEG

var _models: Array[AstronautModel] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_build_env()
	_build_ground()

	var suits := _suits()
	if args.has("--contrast"):
		_print_contrast(suits)
	var page := 0
	var gameplay := args.has("--gameplay")
	for a: String in args:
		if a.begins_with("--page="):
			page = maxi(a.substr(7).to_int(), 0)
	var first := page * PER_PAGE
	var row: Array = suits.slice(first, mini(first + PER_PAGE, suits.size()))
	var facing := 0.0 if args.has("--back") else PI

	for i in row.size():
		var entry: Dictionary = row[i]
		var holder := Node3D.new()
		holder.position = Vector3((float(i) - (float(row.size()) - 1.0) * 0.5) * SPACING, 0.0, 0.0)
		holder.rotation.y = facing
		add_child(holder)
		var m := AstronautModel.new()
		m.follow_game_state = false
		m.style_override = entry["style"]
		holder.add_child(m)
		m.set_state("idle")
		_models.append(m)
		add_child(_make_label(str(entry["name"]), holder.position + Vector3(0.0, 1.72, 0.0)))

	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	add_child(cam)
	var dist := GAMEPLAY_DIST if gameplay else SHEET_DIST
	var pitch := deg_to_rad(GAMEPLAY_PITCH_DEG if gameplay else SHEET_PITCH_DEG)
	var pivot := Vector3(0.0, 0.78, 0.0)
	cam.look_at_from_position(pivot + Vector3(0.0, sin(pitch), cos(pitch)) * dist, pivot, Vector3.UP)


## The shop's own suit list, in shop order, as {name, style} rows.
func _suits() -> Array:
	var out: Array = []
	for r: Array in CATALOG.SUITS:
		out.append({
			"id": str(r[0]),
			"name": str(r[1]),
			"style": {"suit_color": r[5], "accent_color": r[6], "visor_tint": r[7]},
		})
	return out


## Prints the albedo relationship the contrast law guarantees. The renders are the real evidence;
## this is the cheap regression check that runs headless in tools/check.sh time.
func _print_contrast(suits: Array) -> void:
	print("WARDROBE  %-22s %-9s %-9s %-9s  dome_v visor_v ratio" % ["suit", "suit_col", "dome", "visor"])
	var worst := 99.0
	for e: Dictionary in suits:
		var r := AstronautModel.contrast_row(e["style"])
		worst = minf(worst, float(r["ratio"]))
		print("WARDROBE  %-22s #%-8s #%-8s #%-8s  %.3f  %.3f   %.2fx" % [
			e["name"], r["suit"], r["dome"], r["visor"], r["dome_v"], r["visor_v"], r["ratio"]])
	print("WARDROBE  worst dome:visor value ratio = %.2fx over %d suits" % [worst, suits.size()])


func _build_env() -> void:
	if not ResourceLoader.exists("res://src/world/environment.tscn"):
		PlayerShowcaseEnv.add_to(self)
		return
	var env: Node = load("res://src/world/environment.tscn").instantiate()
	env.name = "Environment"
	var data := PlanetData.new()
	data.id = "home"
	data.radius = 16.0
	env.set("data_override", data)
	env.set("time_scale", 0.0)
	add_child(env)


## The same measured stage green as the turntable (see its note: the nominal swatch renders neon).
func _build_ground() -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 9.0
	mesh.bottom_radius = 9.4
	mesh.height = 0.3
	mesh.radial_segments = 48
	mi.mesh = mesh
	mi.material_override = MaterialLib.toon(Color("#6fa860"), {"shade": 0.5, "spec": 0.05})
	mi.position.y = -0.15
	add_child(mi)


func _make_label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 34
	l.outline_size = 10
	l.pixel_size = 0.0042
	l.modulate = Color("#fff8e1")
	l.outline_modulate = Color("#6b5232")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	return l


func _process(delta: float) -> void:
	for m in _models:
		m.tick(delta, 0.0)
