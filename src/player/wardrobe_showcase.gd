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
## Added 2026-10-21 for the set outfits (docs/SETS_SPEC.md), all read from the catalog:
##   --hats        the row is every HAT instead of every suit, each worn with its set's suit (or the
##                 starter suit) - the hat fit sheet
##   --sets        the five set outfits, suit + hat together
##   --only=<id>   keep only the entries whose suit or hat id contains <id>
##   --per-page=N  entries per row (default 6)
##   --yaw=<deg>   turn every astronaut (0 = facing the camera, 90 = side, 180 = back, 45 = 3/4)
##   --state=<s>   pin an animation state (walk, run, jump, ...) instead of idle
##   --closeup     head-and-shoulders framing (hat fit); --cam-dist=<m> / --cam-pitch=<deg> override
##   --shot=<png>  save the frame after --shot-at=<frames> (default 45) to an absolute path, then quit.
##                 Unlike --write-movie this honours --resolution.
##   --tris        print the whole-astronaut triangle count with each hat (budget 6,000)
##   --swatch=#s/#a,...  try suit/accent pairs that are not in the catalog (colour tuning)
##   --blocking    print each suit's colour-blocking numbers (hue / value / L* gap, nominal swatches)
## Night: Director's --time=<hour> sets the frozen clock (e.g. --time=22).
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
var _frame := 0
var _shot_at := 45
var _shot_path := ""
const TRI_BUDGET := 6000


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_build_env()
	_build_ground()

	var suits := _suits()
	if args.has("--contrast"):
		_print_contrast(suits)
	if args.has("--blocking"):
		_print_blocking()
	if args.has("--tris"):
		_print_tris()
	var entries: Array = suits
	for a: String in args:
		# --swatch=#suit/#accent,#suit/#accent,... : try colours that are not in the catalog yet.
		if a.begins_with("--swatch="):
			entries = []
			for pair: String in a.substr(9).split(","):
				var c := pair.split("/")
				entries.append({"id": pair, "name": pair, "style": {"suit_color": c[0],
						"accent_color": c[1] if c.size() > 1 else "#ff7a59", "visor_tint": "#bfe8ff"}})
	if args.has("--hats"):
		entries = _hat_entries()
	elif args.has("--sets"):
		entries = _set_entries()
	var page := 0
	var per_page := PER_PAGE
	var gameplay := args.has("--gameplay")
	var closeup := args.has("--closeup")
	var yaw_deg := 0.0
	var state := "idle"
	var cam_dist := -1.0
	var cam_pitch := -999.0
	for a: String in args:
		if a.begins_with("--page="):
			page = maxi(a.substr(7).to_int(), 0)
		elif a.begins_with("--per-page="):
			per_page = maxi(a.substr(11).to_int(), 1)
		elif a.begins_with("--only="):
			var wants := a.substr(7).split(",")
			entries = entries.filter(func(e: Dictionary) -> bool:
				for want: String in wants:
					if str(e.get("id", "")).contains(want) or str((e["style"] as Dictionary).get("hat_id", "")).contains(want):
						return true
				return false)
		elif a.begins_with("--yaw="):
			yaw_deg = a.substr(6).to_float()
		elif a.begins_with("--state="):
			state = a.substr(8)
		elif a.begins_with("--cam-dist="):
			cam_dist = a.substr(11).to_float()
		elif a.begins_with("--cam-pitch="):
			cam_pitch = a.substr(12).to_float()
		elif a.begins_with("--shot="):
			_shot_path = a.substr(7)
		elif a.begins_with("--shot-at="):
			_shot_at = maxi(a.substr(10).to_int(), 1)
	var first := page * per_page
	var row: Array = entries.slice(first, mini(first + per_page, entries.size()))
	var facing := (0.0 if args.has("--back") else PI) + deg_to_rad(yaw_deg)

	for i in row.size():
		var entry: Dictionary = row[i]
		var holder := Node3D.new()
		holder.position = Vector3((float(i) - (float(row.size()) - 1.0) * 0.5) * SPACING, 0.0, 0.0)
		holder.rotation.y = facing
		add_child(holder)
		var m := AstronautModel.new()
		m.follow_game_state = false
		m.style_override = entry["style"]
		m.set_meta("entry_id", str(entry.get("id", "")))
		holder.add_child(m)
		m.set_state(state)
		_models.append(m)
		if not closeup:
			add_child(_make_label(str(entry["name"]), holder.position + Vector3(0.0, 1.86, 0.0)))

	var cam := Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	add_child(cam)
	var spread := maxf(float(row.size()) / float(PER_PAGE), 0.34)
	var dist := GAMEPLAY_DIST if gameplay else SHEET_DIST * spread
	var pitch_deg := GAMEPLAY_PITCH_DEG if gameplay else SHEET_PITCH_DEG
	var pivot := Vector3(0.0, 0.78, 0.0)
	if closeup:
		dist = 0.8 + 0.8 * float(row.size())
		pitch_deg = 10.0
		pivot = Vector3(0.0, 1.10, 0.0)
	if cam_dist > 0.0:
		dist = cam_dist
	if cam_pitch > -900.0:
		pitch_deg = cam_pitch
	var pitch := deg_to_rad(pitch_deg)
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


static func _patch(img: Image, at: Vector2) -> Color:
	var acc := Color(0, 0, 0, 0)
	var n := 0
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var x := clampi(int(at.x) + dx, 0, img.get_width() - 1)
			var y := clampi(int(at.y) + dy, 0, img.get_height() - 1)
			acc += img.get_pixel(x, y)
			n += 1
	return acc / float(n)


## Every hat in the catalog, in catalog order, after a bare-helmet control. A set hat is worn with its
## own set's suit (CATALOG.SETS), so the sheet shows the outfit as it is sold; any other hat is worn
## with the starter suit.
func _hat_entries() -> Array:
	var set_suit := {}
	for r: Array in CATALOG.SUITS:
		if CATALOG.SETS.has(r[0]):
			set_suit[CATALOG.SETS[r[0]]] = {"suit_color": r[5], "accent_color": r[6], "visor_tint": r[7]}
	var out: Array = [{"id": "none", "name": "(no hat)", "style": {"hat_id": ""}}]
	for g: Array in CATALOG.GEAR:
		if str(g[2]) != "hat":
			continue
		var style: Dictionary = {}
		var set_id := str(CATALOG.SETS.get(g[0], ""))
		if set_suit.has(set_id):
			style = (set_suit[set_id] as Dictionary).duplicate()
		style["hat_id"] = g[6]
		out.append({"id": str(g[0]), "name": str(g[1]), "style": style})
	return out


## The five set outfits: each set's suit with its set's hat.
func _set_entries() -> Array:
	var out: Array = []
	for r: Array in CATALOG.SUITS:
		var set_id := str(CATALOG.SETS.get(r[0], ""))
		if set_id == "":
			continue
		var hat := ""
		for g: Array in CATALOG.GEAR:
			if str(CATALOG.SETS.get(g[0], "")) == set_id:
				hat = str(g[6])
		out.append({"id": str(r[0]), "name": str(r[1]),
				"style": {"suit_color": r[5], "accent_color": r[6], "visor_tint": r[7], "hat_id": hat}})
	return out


## `--tris`: the WHOLE astronaut's triangle count with each hat on (STYLE_GUIDE R2.7: under 6,000).
## Measured 2026-10-21: the bare astronaut is already 5,912, so no hat fits under 6,000 - the three
## hats that shipped before the sets (cap, antenna, crown) take it to 6,568-7,272. The second summary
## line therefore also holds the new hats to "no heavier than the heaviest hat already shipping".
const OLD_HATS := ["hat_cap", "hat_antenna", "hat_crown"]


func _print_tris() -> void:
	var worst := 0
	var old_max := 0
	var new_max := 0
	for e: Dictionary in _hat_entries():
		var m := AstronautModel.new()
		m.follow_game_state = false
		m.style_override = e["style"]
		add_child(m)
		var total := 0
		var hat_tris := 0
		for mi: MeshInstance3D in _meshes(m):
			var t := mi.mesh.get_faces().size() / 3
			total += t
			if str(m.get_path_to(mi)).contains("Helmet/Hat/"):
				hat_tris += t
		worst = maxi(worst, total)
		if OLD_HATS.has(e["id"]):
			old_max = maxi(old_max, hat_tris)
		elif e["id"] != "none":
			new_max = maxi(new_max, hat_tris)
		print("TRIS  %-20s total=%5d  hat=%5d  %s" % [e["id"], total, hat_tris, "OK" if total < TRI_BUDGET else "OVER BUDGET"])
		remove_child(m)
		m.free()
	print("TRIS  worst=%d budget=%d -> %s" % [worst, TRI_BUDGET, "PASS" if worst < TRI_BUDGET else "FAIL"])
	print("TRIS  heaviest new hat=%d tris, heaviest pre-sets hat=%d -> %s" % [new_max, old_max,
			"no heavier" if new_max <= old_max else "HEAVIER"])


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append(n as MeshInstance3D)
	for c: Node in n.get_children():
		out.append_array(_meshes(c))
	return out


## `--blocking`: docs/STYLE_GUIDE.md "Character rules" - the accent must differ from the suit in BOTH
## hue and value. Prints the hue gap, the HSV value gap and the CIE L* gap of every suit row.
func _print_blocking() -> void:
	var rows: Array = CATALOG.SUITS + CATALOG.JUNGLE_SUITS + CATALOG.STAMP_SUITS
	print("BLOCKING  %-20s %-8s %-8s  dHue   dV    dL*" % ["suit", "suit", "accent"])
	for r: Array in rows:
		var a := Color(str(r[5]))
		var b := Color(str(r[6]))
		var dh := absf(a.h - b.h) * 360.0
		dh = minf(dh, 360.0 - dh)
		if a.s < 0.05 or b.s < 0.05:
			dh = -1.0
		print("BLOCKING  %-20s %s %s  %5.1f  %.2f  %5.1f" % [r[0], r[5], r[6], dh, absf(a.v - b.v), absf(_lstar(a) - _lstar(b))])


static func _lstar(c: Color) -> float:
	var l := c.srgb_to_linear()
	var y := 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b
	return 116.0 * pow(y, 1.0 / 3.0) - 16.0 if y > 0.008856 else 903.3 * y


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
	var speed := 0.0
	for m in _models:
		var st := m.get_state()
		speed = 1.0 if st in ["walk", "carry_walk"] else (1.67 if st == "run" else 0.0)
		m.tick(delta, speed)
	_frame += 1
	if _shot_path != "" and _frame == _shot_at:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot_path)
		print("WARDROBE shot -> %s (%dx%d)" % [_shot_path, img.get_width(), img.get_height()])
		# Rendered-colour probes: mean of a 9x9 patch on the torso's side (suit cloth) and on the dome
		# crown, so "how does this suit actually render" is a number, not an impression.
		var cam := get_viewport().get_camera_3d()
		# unproject_position answers in the viewport's logical size; the image is the window's pixels.
		var k := Vector2(img.get_size()) / get_viewport().get_visible_rect().size
		for m in _models:
			var tp := cam.unproject_position(m.to_global(Vector3(0.17, 0.47, -0.16))) * k
			var dp := cam.unproject_position(m.to_global(Vector3(0.0, 1.30, 0.20))) * k
			print("WARDROBE probe %-22s at %s torso #%s  dome #%s" % [str(m.get_meta("entry_id", "")), str(tp),
					_patch(img, tp).to_html(false), _patch(img, dp).to_html(false)])
		get_tree().quit()
