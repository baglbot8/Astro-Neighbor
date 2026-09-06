class_name Building
extends Node3D
## Base class for every hub building and the player's home habitat.
##
## Subclasses implement `_build()` (geometry) and optionally `_animate(t, delta)` and
## `_on_door(player)`. Everything else is shared plumbing:
##   * placement on the planet — `attach_to_planet(planet)` puts the origin exactly on the flattened
##     disc at `planet.building_dir(building_id)` with the door facing the plaza centre (the spawn
##     point), sunk by `ground_sink` so the curved ground never shows a gap under a flat plinth
##   * a StaticBody3D footprint on layer 7 (building), mask 0
##   * a door `Interactable` (prompt "Enter", reach 3.0) plus any extra interactables a subclass adds
##   * night response: emissive windows/signs ride the `astro_night` global shader parameter
##     (docs/ARCHITECTURE.md 9.1) through hub_glow.gdshader; lamp lights follow the same clock via
##     `EventBus.day_phase_changed` and a slow poll so dusk ramps smoothly
##   * shop-flow helpers: the HUD's DialogueBox / ShopPanel, toasts, and a re-entrancy guard
##
## Model convention: origin at the ground contact point, +Y up, the door faces -Z.
## Scale: 5-8 m tall, footprints under ~6 m so they sit inside the 7 m flattened disc.

const GLOW_SHADER := preload("res://src/hub/hub_glow.gdshader")
const FLAG_SHADER := preload("res://src/decorations/flag_wave.gdshader")
## R2.9 surface detail for building shells. See the "R2.9 surface detail" block further down.
const SURFACE_SHADER := preload("res://src/hub/hub_surface.gdshader")
## Matches `surface_kind` in hub_surface.gdshader and MaterialLib.SURFACE_KINDS.
const SURFACE_KINDS := {"none": 0, "cloth": 1, "metal": 2, "wood": 3, "rock": 4, "foliage": 5, "rubber": 6}

## Used when the planet does not know this id (planet.building_dir returned zero).
const FALLBACK_DIRS := {
	"town_hall": Vector3(0.0, 1.0, 0.0),
	"deco_store": Vector3(0.62, 0.72, 0.31),
	"clothes_store": Vector3(-0.62, 0.72, 0.31),
	"event_space": Vector3(0.0, 0.72, -0.69),
	"player_home": Vector3(-0.4, 0.85, 0.35),
}

## Shared architectural palette. Muted enough for the measured targets (docs/STYLE_GUIDE.md) but
## never muddy: the darks come from the roofs, the eave undersides, the wood and the cast shadows.
const CREAM := Color("#d9cbad")
const CREAM_LIT := Color("#e4d7bc")
const CREAM_DEEP := Color("#c0aa83")
const CREAM_SHADE := Color("#93805f")
const STONE := Color("#c1b6a1")
const STONE_DEEP := Color("#9c9179")
const WOOD := Color("#c08b52")
const WOOD_DARK := Color("#8a5f37")
const WOOD_DEEP := Color("#6a4726")
const TEAL := Color("#3f9e9a")
const TEAL_DEEP := Color("#2c706e")
const GOLD := Color("#e8b849")
const GOLD_DEEP := Color("#b98c2f")
const METAL := Color("#93a3ba")
const METAL_DARK := Color("#5d6678")
## Warm dark bronze for lanterns and brackets — blue-grey metal reads as plastic at this scale.
const BRONZE := Color("#5b4e42")
const LEAF := Color("#3f8a4e")
const LEAF_UNDER := Color("#2d6b47")
const TERRACOTTA := Color("#c9714b")
const WINDOW_WARM := Color("#ffd489")
const TEXT_BROWN := Color("#6b5232")

## Seconds between clock polls, so dusk ramps instead of stepping at the phase boundary.
const NIGHT_POLL := 0.25
const NIGHT_FADE := 1.5
## Global trim on building lamp lights so a plaza full of them does not blow out the night.
const LIGHT_SCALE := 0.55

@export var building_id: String = ""
## Shown on the hanging sign and in dialogue.
@export var display_name: String = ""
## Metres the whole building is pushed into the ground. The planet surface curves away from the
## contact point (~0.15 m over a 5 m wide plinth on the 26 m hub), so every building buries its
## apron a little and nothing floats at the corners.
@export var ground_sink: float = 0.16
## Radius of the planet this building lives on, used by `ground_y()` to follow the curved ground.
@export var ground_radius: float = 26.0
## Footprint collider, full extents in local space (x = width, y = height, z = depth).
@export var footprint_size: Vector3 = Vector3(5.0, 4.0, 4.0)
@export var footprint_offset: Vector3 = Vector3(0.0, 0.0, 0.0)
## Where the door interactable sits (local). The door faces -Z, so this is usually a negative z.
@export var door_local: Vector3 = Vector3(0.0, 1.1, -2.6)
@export var door_prompt: String = "Enter"

var planet: Planet
var door: Interactable

var _t: float = 0.0
var _animated: bool = false
var _busy: bool = false
var _lights: Array[OmniLight3D] = []
var _light_energy: PackedFloat32Array = PackedFloat32Array()
var _night: float = 0.0
var _night_target: float = 0.0
var _poll: float = 0.0
var _env: Node = null
var _rng := RandomNumberGenerator.new()

static var _glow_mat: ShaderMaterial
## Cache of R2.9 building materials, keyed by their option dictionary. Five buildings share about
## a dozen of these between them, so they must never be built per mesh.
static var _surface_mats: Dictionary = {}


func _ready() -> void:
	_rng.seed = hash(building_id if building_id != "" else name)
	if display_name == "":
		display_name = UIStyle.pretty_id(building_id)
	_build()
	_make_footprint()
	door = add_interactable("Door", door_local, door_prompt, 3.0, _on_door)
	_night = night_factor()
	_night_target = _night
	_apply_night()
	EventBus.day_phase_changed.connect(_on_phase_changed)
	set_process(_animated or not _lights.is_empty())


func _process(delta: float) -> void:
	_t += delta
	if _animated:
		_animate(_t, delta)
	if _lights.is_empty():
		return
	_poll -= delta
	if _poll <= 0.0:
		_poll = NIGHT_POLL
		_night_target = night_factor()
	if absf(_night - _night_target) > 0.002:
		_night = lerpf(_night, _night_target, clampf(delta * NIGHT_FADE, 0.0, 1.0))
		_apply_night()


# ============================================================================================ hooks
## Build the geometry. Override in every building.
func _build() -> void:
	pass


## Per-frame animation; call `animate()` from `_build()` to enable it.
func _animate(_time: float, _delta: float) -> void:
	pass


## Door interaction. Override to open a shop or a dialogue.
func _on_door(_player: Node3D) -> void:
	pass


## Marks the building as animated so `_process` ticks `_animate`.
func animate() -> void:
	_animated = true


# ============================================================================================ placement
## Places the building on `p` at its fixed direction, doors facing the plaza centre (the spawn
## point), sitting exactly on the flattened disc.
func attach_to_planet(p: Planet) -> void:
	planet = p
	if p == null:
		return
	var dir := p.building_dir(building_id)
	if dir == Vector3.ZERO:
		dir = (FALLBACK_DIRS.get(building_id, Vector3.UP) as Vector3).normalized()
	var here := p.surface_point(dir)
	var centre := p.surface_point(p.data.spawn_dir.normalized())
	var toward_plaza := centre - here
	if toward_plaza.length_squared() < 0.0001:
		toward_plaza = Vector3.FORWARD
	# -Z of the returned basis points along the hint, and the model's door faces -Z.
	global_transform = p.surface_transform(dir, toward_plaza)
	global_position -= global_transform.basis.y * ground_sink
	_on_attached(p, dir)


## Called after the transform is set, for anything that needs the planet (extra props, npc anchors).
func _on_attached(_p: Planet, _dir: Vector3) -> void:
	pass


## World-space point a shopkeeper / the player should look at when this building is used.
func door_point() -> Vector3:
	return to_global(door_local)


## Collision volumes for the footprint body, as `[Shape3D, local_position]` pairs. The default is a
## single box from `footprint_size` / `footprint_offset`; round buildings override this with a
## cylinder, and anything with steps adds a low block so the player stops at the bottom step
## instead of walking through it.
func _footprint_shapes() -> Array:
	var box := BoxShape3D.new()
	box.size = footprint_size
	return [[box, footprint_offset + Vector3(0.0, footprint_size.y * 0.5, 0.0)]]


## A low blocking slab in front of the door so the player stops at the steps.
static func step_block(w: float, front_z: float, back_z: float, h: float = 0.5) -> Array:
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, absf(back_z - front_z))
	return [box, Vector3(0.0, h * 0.5 - 0.1, (front_z + back_z) * 0.5)]


static func cyl_shape(r: float, h: float) -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	return c


func _make_footprint() -> void:
	var body := StaticBody3D.new()
	body.name = "Footprint"
	# Layer 7 = "building" (docs/ARCHITECTURE.md 8). Buildings never query, only block.
	body.collision_layer = 1 << 6
	body.collision_mask = 0
	for entry: Array in _footprint_shapes():
		var cs := CollisionShape3D.new()
		cs.shape = entry[0]
		cs.position = entry[1]
		body.add_child(cs)
	add_child(body)


# ============================================================================================ interaction
## Adds an Interactable (layer 5) at `local_pos` wired to `handler(player)`.
func add_interactable(node_name: String, local_pos: Vector3, prompt: String, reach: float, handler: Callable) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.position = local_pos
	it.prompt_text = prompt
	it.reach = reach
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(reach * 0.5, 0.4)
	cs.shape = sphere
	it.add_child(cs)
	add_child(it)
	it.interacted.connect(handler)
	return it


# ============================================================================================ build helpers
## Adds a chunky vertex-coloured toon mesh (walls, roofs, wood, stone).
func add_body(mesh: Mesh, part_name: String = "Body", parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, body_material(), part_name, parent)


## Adds a vertex-coloured metallic mesh (poles, brackets, dishes, speakers).
func add_metal(mesh: Mesh, part_name: String = "Metal", parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, metal_material(), part_name, parent)


# -------------------------------------------------------------------------- R2.9 surface detail
# The user: "I want to minimize larger surfaces on important things that dont have a 'texture' to
# them, so that nothing looks too flat / cheap. Notably things like the astronaut's helmet/clothes
# or HOUSES and the ground."
#
# A building's shell is the biggest single surface in the game, so it is split by MATERIAL rather
# than committed as one mesh: plaster walls, painted metal panels, timber and cloth each get their
# own DecoKit and their own material. That costs 2-4 extra draw calls per building (the hub sits
# near 700) and buys every wall a microsurface, every plank its grain along its own long axis, and
# every roof and dome its panel seams.
#
# Which preset to use:
#   add_wall  - plaster, render, cut stone, painted masonry. The default for a shop's shell.
#   add_panel - painted metal: domes, hipped roofs, speaker cabinets, habitat shells.
#   add_wood  - anything sawn: doors, signs, crates, decks, boards, stall timbers. Pass the
#               plank's OWN long axis in model space, never a world axis.
#   add_cloth - awnings, bunting, flags, speaker grilles.
# Small trim, tiny props and background scatter stay on plain `add_body` - R2.9 says explicitly not
# to gold-plate those.

## Plaster / render / cut stone. Rough microsurface close up, masonry courses that hold at plaza
## distance, and a slow tonal drift so a 5 m wall is never one flat swatch.
func add_wall(mesh: Mesh, part_name: String = "Walls", opts: Dictionary = {}, parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, wall_material(opts), part_name, parent)


## Painted metal: the Town Hall dome, Suit-Up's roof, the habitat shell, speaker cabinets.
## Soft travelling sheen plus panel seams; deliberately NOT a hotspot (R2.6).
func add_panel(mesh: Mesh, part_name: String = "Panels", opts: Dictionary = {}, parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, panel_material(opts), part_name, parent)


## Timber. `grain` is the plank's long axis in MODEL space.
func add_wood(mesh: Mesh, grain: Vector3 = Vector3.UP, part_name: String = "Wood",
		opts: Dictionary = {}, parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, wood_material(grain, opts), part_name, parent)


## Cloth: awnings, bunting, flags, speaker grilles.
func add_cloth(mesh: Mesh, part_name: String = "Cloth", opts: Dictionary = {}, parent: Node3D = null) -> MeshInstance3D:
	return _add(mesh, cloth_material(opts), part_name, parent)


## Adds a vertex-coloured emissive mesh. `strength` is the night-time emission; it drops to ~14 %
## by day through the `astro_night` global. `pulse_speed` > 0 makes it breathe.
## `day_dark` = 1 marks the mesh as window glass: dark slate while the sun is up, warm after dusk.
func add_glow(mesh: Mesh, strength: float = 2.2, part_name: String = "Glow", pulse_speed: float = 0.0,
		depth: float = 0.3, day_dark: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := _add(mesh, glow_material(), part_name, parent)
	mi.set_instance_shader_parameter("glow_strength", strength)
	mi.set_instance_shader_parameter("pulse_speed", pulse_speed)
	mi.set_instance_shader_parameter("pulse_depth", depth)
	mi.set_instance_shader_parameter("phase", _rng.randf() * TAU)
	mi.set_instance_shader_parameter("force_on", 0.0)
	mi.set_instance_shader_parameter("day_dark", day_dark)
	return mi


## Adds a translucent glass mesh (shop windows, portholes, lantern panes).
func add_glass(mesh: Mesh, tint: Color, alpha: float = 0.3, part_name: String = "Glass", parent: Node3D = null) -> MeshInstance3D:
	var mi := _add(mesh, MaterialLib.glass(tint, alpha), part_name, parent)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Adds a waving cloth mesh built with `DecoKit.flag_panel` / `flag_emblem`.
func add_flag(mesh: Mesh, part_name: String = "Flag", amp: float = 0.11, speed: float = 2.4, parent: Node3D = null) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = FLAG_SHADER
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("wave_amp", amp)
	m.set_shader_parameter("wave_speed", speed)
	return _add(mesh, m, part_name, parent)


## Adds a lamp light that costs nothing by day (energy scales with the night factor).
##
## IMPORTANT: put the light INSIDE solid geometry (a wall, a parapet, a lantern cage, the stage
## deck). An OmniLight3D floating in open air renders a visible dark sphere at its own position in
## this renderer; buried in a mesh the artifact is hidden and, because these lights cast no shadows,
## the illumination is exactly the same.
func add_light(pos: Vector3, color: Color, energy: float = 1.4, light_range: float = 6.0, parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "Lamp"
	l.position = pos
	l.light_color = color
	l.light_energy = 0.0
	l.omni_range = light_range
	l.omni_attenuation = 2.0
	l.shadow_enabled = false
	l.light_specular = 0.2
	l.visible = false
	(parent if parent else self).add_child(l)
	_lights.append(l)
	_light_energy.append(energy)
	return l


## A small light that is always on — shop-window interiors are lit at every hour.
## Same rule as `add_light`: bury it in the surrounding geometry, never in open air.
func add_interior_light(pos: Vector3, color: Color, energy: float = 1.0, light_range: float = 4.0,
		parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "InteriorLamp"
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.omni_attenuation = 1.8
	l.shadow_enabled = false
	l.light_specular = 0.15
	(parent if parent else self).add_child(l)
	return l


func _add(mesh: Mesh, mat: Material, part_name: String, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	(parent if parent else self).add_child(mi)
	return mi


## Empty pivot for animated parts (dish yaw, turntables, sweeping spotlights).
func pivot(part_name: String, pos: Vector3 = Vector3.ZERO, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = part_name
	n.position = pos
	(parent if parent else self).add_child(n)
	return n


# ============================================================================================ materials
static func body_material() -> ShaderMaterial:
	return MaterialLib.toon_vertex_color({"rim": 0.13, "spec": 0.10, "shade": 0.46, "softness": 0.34})


## Poles, brackets, dishes, hardware. Brushed grain plus the shared travelling sheen (R2.9's metal
## row). The toon specular came down from 0.6 to 0.42 and the rim from 0.40 to 0.30 when the sheen
## went on, so the total highlight energy is unchanged and R2.6 still holds.
static func metal_material() -> ShaderMaterial:
	return surface_material({
		"kind": "metal", "strength": 0.85, "scale": 0.35,
		"near": 3.0, "far": 12.0,
		"macro_scale": 3.2, "macro_amount": 0.05,
		"metallic": 0.5, "roughness": 0.4, "spec": 0.42, "spec_size": 150.0, "rim": 0.30,
	})


## Plaster / render / cut stone (R2.9's rock row: "a genuinely rougher microsurface, chipped edges,
## mottled tonal variation at two scales").
##   fine  sd_rock at `scale` 0.75, which moves its three frequencies from 6.5 / 19 / 46 cycles/m
##         down to 4.9 / 14 / 34 - trowel-and-render scale rather than cliff scale, and safe out to
##         ~6.4 m instead of ~4.7 m. Faded to nothing by 18 m, well before it could alias.
##   macro 2.6 cycles/m tonal drift, holding to 48 m. This is the band that matters at plaza
##         distance and it is what a rendered ACNH wall actually has (reference/AC Reference 4:
##         the round white house is smooth, with a soft brushy tonal drift, not masonry).
##   seams OFF by default. Two reasons, both from looking at it: ACNH puts a rendered wall's
##         structure into mouldings and frames rather than joints, and sd_seams' topstitch bead -
##         right on cloth, and a good rivet line on panelled metal - reads as a ladder of dashes
##         climbing a plaster wall. Seams live in `panel_material` and `cloth_material`; a building
##         that genuinely wants ashlar passes its own `seam_mode`.
##
## The amplitudes look large because the surface is bright. Measured: a cream wall lands at display
## luma 0.88, up on the compressive shoulder of the ACES curve, so this whole recipe only moves its
## luma std from 0.0127 to 0.0240 and its 5-95 range from 0.036 to 0.080 (Town Hall front wall at
## 5 m). One notch higher was tried and rejected - at std 0.035 the darker patches start reading as
## damp staining rather than render.
static func wall_material(opts: Dictionary = {}) -> ShaderMaterial:
	var o := {
		"kind": "rock", "strength": 2.2, "scale": 0.75, "near": 5.0, "far": 18.0,
		"macro_scale": 2.6, "macro_amount": 0.55,
		"seam_mode": 0,
		"roughness": 0.90, "spec": 0.10, "rim": 0.13,
	}
	o.merge(opts, true)
	return surface_material(o)


## Painted metal panels: domes, hipped roofs, cabinets, the habitat shell. Seams ON - this is the
## one place sd_seams' topstitch is a feature, because on sheet metal it reads as a rivet line. The
## sheen carries the "metal" read at range; the grain is a close-range bonus. Specular stays low: a
## big painted panel must never grow a wet hotspot (R2.6).
static func panel_material(opts: Dictionary = {}) -> ShaderMaterial:
	var o := {
		"kind": "metal", "strength": 1.6, "scale": 0.35, "near": 3.0, "far": 14.0,
		"macro_scale": 2.4, "macro_amount": 0.45,
		"seam_mode": 1, "seam_strength": 0.85, "pitch_a": 1.30, "pitch_b": 0.70,
		"seam_far": 40.0,
		"metallic": 0.25, "roughness": 0.55, "spec": 0.16, "spec_size": 110.0, "rim": 0.16,
	}
	o.merge(opts, true)
	return surface_material(o)


## Timber (R2.9's wood row). `grain` is the plank's own long axis in MODEL space - a world axis
## would run the grain across half the planks in the building.
##
## `scale` 2.2 does two things. It pushes sd_wood's rings from 26 to 57 cycles/m, ~14 grain lines
## across a 1.2 m door leaf and still 5 px apart at 8 m. And because the ring frequency scales
## while the fbm WARP stays a fixed 2.6 cycles of wander, a higher scale makes the grain read as
## long parallel lines rather than the wormy blobs it gives at 1.0 - which is what the door and the
## Campsite sign in reference/AC Reference 2 and 4 actually look like.
## Strength is well above the walls': in ACNH wood grain is the strongest texture in the frame.
static func wood_material(grain: Vector3 = Vector3.UP, opts: Dictionary = {}) -> ShaderMaterial:
	var o := {
		"kind": "wood", "strength": 1.0, "scale": 2.2, "near": 4.0, "far": 15.0,
		"grain_dir": grain.normalized() if grain.length_squared() > 0.0 else Vector3.UP,
		"macro_scale": 1.8, "macro_amount": 0.09,
		"roughness": 0.92, "spec": 0.06, "rim": 0.10,
	}
	o.merge(opts, true)
	return surface_material(o)


## Awnings, bunting, flags, speaker grilles (R2.9's cloth row).
##
## sd_cloth runs at 190 cycles/m and needs the camera inside ~1.1 m at 720p. `scale` 0.16 moves the
## weave to ~30 cycles/m, which is 5.8 px per thread at the door - visible, and above Nyquist. 0.30
## was tried first and put it at 3 px per thread at 5 m, right on the limit, where it read as a
## moire checker; the fade then finishes it off by 8 m. Its fbm fibre term lands at 6.7 cycles/m
## and gives the soft cloth mottle that survives further out.
## Seams ON and strong: R2.9's cloth row asks for "seams and stitching where panels meet", and a
## sewn panel joint is the term that still reads from across the plaza.
static func cloth_material(opts: Dictionary = {}) -> ShaderMaterial:
	var o := {
		"kind": "cloth", "strength": 3.0, "scale": 0.16, "near": 2.0, "far": 8.0,
		"macro_scale": 2.6, "macro_amount": 0.35,
		"seam_mode": 1, "seam_strength": 1.3, "pitch_a": 0.0, "pitch_b": 2.1,
		"seam_far": 34.0,
		"roughness": 0.95, "spec": 0.04, "rim": 0.14,
	}
	o.merge(opts, true)
	return surface_material(o)


## Builds (and caches) a vertex-coloured hub building material on `hub_surface.gdshader`. Prefer
## the presets above; this is the escape hatch when one of them needs a tweak.
static func surface_material(opts: Dictionary) -> ShaderMaterial:
	var key := str(opts)
	if _surface_mats.has(key):
		return _surface_mats[key]
	var m := ShaderMaterial.new()
	m.shader = SURFACE_SHADER
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("surface_kind", SURFACE_KINDS.get(str(opts.get("kind", "none")), 0))
	m.set_shader_parameter("surface_strength", opts.get("strength", 1.0))
	m.set_shader_parameter("surface_scale", opts.get("scale", 1.0))
	m.set_shader_parameter("surface_lod_near", opts.get("near", 3.0))
	m.set_shader_parameter("surface_lod_far", opts.get("far", 11.0))
	m.set_shader_parameter("surface_grain_dir", opts.get("grain_dir", Vector3.UP))
	m.set_shader_parameter("seam_mode", opts.get("seam_mode", 0))
	m.set_shader_parameter("seam_strength", opts.get("seam_strength", 0.55))
	m.set_shader_parameter("seam_axis_a", opts.get("axis_a", Vector3.UP))
	m.set_shader_parameter("seam_axis_b", opts.get("axis_b", Vector3.RIGHT))
	m.set_shader_parameter("seam_pitch_a", opts.get("pitch_a", 1.2))
	m.set_shader_parameter("seam_pitch_b", opts.get("pitch_b", 0.0))
	m.set_shader_parameter("seam_gores", opts.get("gores", 16.0))
	m.set_shader_parameter("seam_phase", opts.get("seam_phase", 0.5))
	m.set_shader_parameter("seam_near", opts.get("seam_near", 15.0))
	m.set_shader_parameter("seam_far", opts.get("seam_far", 36.0))
	m.set_shader_parameter("macro_scale", opts.get("macro_scale", 0.0))
	m.set_shader_parameter("macro_amount", opts.get("macro_amount", 0.055))
	m.set_shader_parameter("macro_near", opts.get("macro_near", 20.0))
	m.set_shader_parameter("macro_far", opts.get("macro_far", 48.0))
	m.set_shader_parameter("ramp_softness", opts.get("softness", 0.34))
	m.set_shader_parameter("shade_strength", opts.get("shade", 0.46))
	m.set_shader_parameter("rim_strength", opts.get("rim", 0.13))
	m.set_shader_parameter("spec_strength", opts.get("spec", 0.10))
	m.set_shader_parameter("spec_size", opts.get("spec_size", 60.0))
	m.set_shader_parameter("roughness", opts.get("roughness", 0.85))
	m.set_shader_parameter("metallic", opts.get("metallic", 0.0))
	_surface_mats[key] = m
	return m


## One shared emissive material for every glowing building surface (per-instance intensity).
static func glow_material() -> ShaderMaterial:
	if _glow_mat == null:
		_glow_mat = ShaderMaterial.new()
		_glow_mat.shader = GLOW_SHADER
	return _glow_mat


# ============================================================================================ shared shapes
## An arch polygon (flat-bottomed rectangle with a semicircular top), centred on x, base at y = 0.
static func arch_poly(w: float, h: float, steps: int = 12) -> PackedVector2Array:
	var hw := w * 0.5
	var straight: float = maxf(h - hw, 0.02)
	var out := PackedVector2Array([Vector2(-hw, 0.0), Vector2(hw, 0.0), Vector2(hw, straight)])
	for i in range(1, steps):
		var a: float = PI * float(i) / float(steps)
		out.append(Vector2(cos(a) * hw, straight + sin(a) * hw))
	out.append(Vector2(-hw, straight))
	return out


## The ring between two concentric arches — the raised frame around a door or window.
static func arch_ring_poly(w: float, h: float, thickness: float, steps: int = 12) -> PackedVector2Array:
	var outer := arch_poly(w + thickness * 2.0, h + thickness, steps)
	var inner := arch_poly(w, h, steps)
	var polys := Geometry2D.clip_polygons(outer, _shift(inner, Vector2(0.0, -0.001)))
	return polys[0] if polys.size() > 0 else outer


## A chunky rounded window frame built from four bars around an opening `w` x `h` centred on
## `centre`, standing `thickness` proud of the wall. Crisp and dependable (a clipped ring polygon
## loses its hole), and it gives the frame real corner blocks like the reference shopfronts.
func build_window_frame(kit: DecoKit, centre: Vector3, w: float, h: float, thickness: float,
		depth: float, color: Color) -> void:
	var t := thickness
	kit.rbox(centre + Vector3(0.0, h * 0.5 + t * 0.5, 0.0), Vector3(w + t * 2.0, t, depth), t * 0.35, color, Basis.IDENTITY, 0)
	kit.rbox(centre + Vector3(0.0, -h * 0.5 - t * 0.5, 0.0), Vector3(w + t * 2.0, t, depth), t * 0.35, color, Basis.IDENTITY, 0)
	for sx in [-1.0, 1.0]:
		kit.rbox(centre + Vector3((w * 0.5 + t * 0.5) * sx, 0.0, 0.0), Vector3(t, h, depth), t * 0.35, color, Basis.IDENTITY, 0)
		for sy in [-1.0, 1.0]:
			kit.sphere(centre + Vector3((w * 0.5 + t * 0.5) * sx, (h * 0.5 + t * 0.5) * sy, 0.0),
					t * 0.62, color.lightened(0.10), Vector3(1.0, 1.0, depth / (t * 1.24)), 10)


## An ACNH shop awning: a faceted quarter-barrel of alternating stripes springing from the wall face
## at `z_face` and `top_y`, reaching `depth` out along -Z, with a chunky rolled front edge and two
## brackets. Flat facets and a crisp front bar — structured, not a bubble.
func build_awning(kit: DecoKit, w: float, depth: float, top_y: float, z_face: float,
		stripes: int, color_a: Color, color_b: Color, edge_color: Color = Color.TRANSPARENT,
		center_x: float = 0.0) -> void:
	const STEPS := 6
	const SWEEP := 1.30            # radians of arc (~75 deg): out and down, never a full half-pipe
	var edge: Color = edge_color if edge_color != Color.TRANSPARENT else color_a.darkened(0.22)
	for i in stripes:
		var x0: float = center_x - w * 0.5 + w * float(i) / float(stripes)
		var x1: float = center_x - w * 0.5 + w * float(i + 1) / float(stripes)
		var c: Color = color_a if i % 2 == 0 else color_b
		for j in STEPS:
			var t0: float = SWEEP * float(j) / float(STEPS)
			var t1: float = SWEEP * float(j + 1) / float(STEPS)
			var p0 := Vector3(0.0, top_y - depth * (1.0 - cos(t0)), z_face - depth * sin(t0))
			var p1 := Vector3(0.0, top_y - depth * (1.0 - cos(t1)), z_face - depth * sin(t1))
			kit.quad(Vector3(x0, p0.y, p0.z), Vector3(x1, p0.y, p0.z), Vector3(x1, p1.y, p1.z), Vector3(x0, p1.y, p1.z), c)
	# rolled front edge (the valance) and two brackets back to the wall
	var ey := top_y - depth * (1.0 - cos(SWEEP))
	var ez := z_face - depth * sin(SWEEP)
	kit.capsule(Vector3(center_x, ey, ez), 0.075, w, edge, Basis(Vector3(0.0, 0.0, 1.0), PI * 0.5))
	for s in [-1.0, 1.0]:
		var bx: float = center_x + w * 0.46 * s
		kit.bar(Vector3(bx, top_y + 0.04, z_face + 0.05), Vector3(bx, ey + 0.06, ez), 0.035, edge, 6)
	kit.rbox(Vector3(center_x, top_y + 0.07, z_face - 0.07), Vector3(w + 0.12, 0.14, 0.20), 0.045, edge, Basis.IDENTITY, 0)


## A hipped roof: two trapezoid slopes, two triangular hips, a flat dark underside and a crisp
## fascia band at the eaves. Flat planes and hard edges — the structured silhouette the style guide
## asks for, and the shaded slope plus the dark eaves carry real dark tones into the frame.
func build_hip_roof(kit: DecoKit, w: float, d: float, h: float, ridge_len: float, y: float,
		cz: float, top: Color, under: Color) -> void:
	var hw := w * 0.5
	var hd := d * 0.5
	var rx := ridge_len * 0.5
	var a := Vector3(-hw, y, cz - hd)
	var b := Vector3(hw, y, cz - hd)
	var c := Vector3(hw, y, cz + hd)
	var e := Vector3(-hw, y, cz + hd)
	var r0 := Vector3(-rx, y + h, cz)
	var r1 := Vector3(rx, y + h, cz)
	kit.quad(a, b, r1, r0, top)                       # front slope
	kit.quad(c, e, r0, r1, top.darkened(0.06))        # back slope
	kit.triangle(a, r0, e, top.darkened(0.13))        # left hip
	kit.triangle(b, c, r1, top.darkened(0.13))        # right hip
	kit.quad(a, b, c, e, under)                       # flat underside
	# fascia band around the eaves and a ridge cap
	kit.rbox(Vector3(0.0, y - 0.06, cz - hd), Vector3(w + 0.06, 0.16, 0.14), 0.04, under, Basis.IDENTITY, 0)
	kit.rbox(Vector3(0.0, y - 0.06, cz + hd), Vector3(w + 0.06, 0.16, 0.14), 0.04, under, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.rbox(Vector3(hw * s, y - 0.06, cz), Vector3(0.14, 0.16, d + 0.06), 0.04, under, Basis.IDENTITY, 0)
	kit.capsule(Vector3(0.0, y + h + 0.02, cz), 0.075, ridge_len, top.lightened(0.14), Basis(Vector3(0.0, 0.0, 1.0), PI * 0.5))


## A sagging string of triangular pennants between two points. `swing` parents them to a node the
## caller rocks, so the bunting has a little life.
func build_bunting(kit: DecoKit, from: Vector3, to: Vector3, sag: float, count: int, colors: Array) -> void:
	var pts: Array[Vector3] = []
	for i in count + 1:
		var u := float(i) / float(count)
		pts.append(from.lerp(to, u) + Vector3(0.0, -sin(u * PI) * sag, 0.0))
	for i in count:
		kit.bar(pts[i], pts[i + 1], 0.013, Color("#b09a7c"), 5)
	for i in count:
		var mid: Vector3 = (pts[i] + pts[i + 1]) * 0.5
		var col: Color = colors[i % colors.size()]
		var half := (pts[i + 1] - pts[i]).length() * 0.42
		var side := (pts[i + 1] - pts[i]).normalized()
		kit.triangle(mid - side * half, mid + side * half, mid + Vector3(0.0, -0.30, 0.0), col)


static func _shift(p: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in p:
		out.append(v + by)
	return out


## Local y of the planet surface `d` metres out from the building's contact point. The flattened
## disc is a spherical cap, so a flat plinth 4 m wide already sits 0.3 m above the ground at its rim
## on the 26 m hub. Free-standing props (lantern posts, mailboxes, planters off the plinth) place
## their base here so nothing floats and nothing sinks.
func ground_y(d: float) -> float:
	var r: float = maxf(ground_radius, 1.0)
	return ground_sink - (r - sqrt(maxf(r * r - d * d, 0.0)))


## Two shallow stone tiers in front of the door: `w` wide, reaching `depth` out along -Z from
## `front_z`, with the top tier's surface at `top_y`. Each tier is a deep buried slab, so the
## curved ground never shows daylight underneath.
func build_steps(kit: DecoKit, w: float, front_z: float, depth: float, top_y: float = 0.0,
		tier_h: float = 0.16, center_x: float = 0.0) -> void:
	const BURY := 0.7
	for i in 2:
		var t := float(i)
		var tw: float = w + t * 0.5
		var td: float = depth * (0.5 + t * 0.5)
		var cz: float = front_z - td * 0.5
		var top: float = top_y - t * tier_h
		kit.rbox(Vector3(center_x, top - BURY * 0.5, cz), Vector3(tw, BURY, td), 0.05,
				STONE if i == 0 else STONE_DEEP, Basis.IDENTITY, 0)
		# a nosing bevel along the front edge so each tier reads as a step, not a slab
		kit.rbox(Vector3(center_x, top - 0.045, cz - td * 0.5 + 0.04), Vector3(tw - 0.10, 0.07, 0.10), 0.025,
				STONE.lightened(0.10), Basis.IDENTITY, 0)


## Arched door in a wall whose outer face is at `at.z`; everything protrudes toward -Z (outward).
## A raised rounded frame, a dark reveal, a planked leaf with battens and a round brass knob.
##
## R2.9: `wood_kit` and `metal_kit` let the caller send the LEAF to a timber material (vertical
## grain, the plank's own long axis) and the knob to a metal one, while the frame and the reveal
## stay with the wall. Omit them and the whole door lands in `kit` exactly as before.
func build_door(kit: DecoKit, at: Vector3, w: float, h: float, frame_color: Color = CREAM_LIT,
		leaf_color: Color = WOOD, groove_color: Color = WOOD_DARK,
		wood_kit: DecoKit = null, metal_kit: DecoKit = null) -> void:
	var wk: DecoKit = wood_kit if wood_kit != null else kit
	var mk: DecoKit = metal_kit if metal_kit != null else kit
	# dark reveal recessed into the wall
	kit.extrude(arch_poly(w + 0.06, h + 0.03), 0.14, CREAM_SHADE, Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.0, 0.05)))
	# leaf, sitting in the reveal
	wk.extrude(arch_poly(w, h), 0.10, leaf_color, Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.0, -0.02)))
	# three vertical plank grooves + two battens (AC Reference 4's door)
	for i in 2:
		var x: float = (float(i) - 0.5) * w * 0.38
		wk.rbox(at + Vector3(x, h * 0.46, -0.075), Vector3(0.022, h * 0.90, 0.014), 0.006, groove_color, Basis.IDENTITY, 0)
	for i in 2:
		var y: float = h * (0.20 + float(i) * 0.40)
		wk.rbox(at + Vector3(0.0, y, -0.085), Vector3(w * 0.86, 0.10, 0.035), 0.018, leaf_color.darkened(0.14), Basis.IDENTITY, 0)
		wk.rbox(at + Vector3(0.0, y - 0.055, -0.082), Vector3(w * 0.86, 0.02, 0.02), 0.006, groove_color, Basis.IDENTITY, 0)
	mk.sphere(at + Vector3(w * 0.30, h * 0.42, -0.10), 0.06, GOLD, Vector3(1.0, 1.0, 0.7), 12)
	# raised frame in front of everything
	kit.extrude(arch_ring_poly(w, h, 0.18), 0.20, frame_color, Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.0, -0.08)))


## A hanging shop sign in front of a wall face at `anchor.z`: an optional bracket arm reaching out
## along -Z, two hangers and a rounded plate with a rim and bolt heads.
## Returns the plate centre so the caller can park a Label3D just in front of it.
##
## R2.9: pass `wood_kit` to send the arm and the timber rim to a wood material (the rim's grain
## runs the long way round the plate) and `metal_kit` for the hangers and the bolt heads. The
## painted plate itself stays in `kit`. Omit them and everything lands in `kit` as before.
func build_hanging_sign(kit: DecoKit, anchor: Vector3, plate_w: float, plate_h: float,
		plate_color: Color = CREAM_LIT, rim_color: Color = WOOD, arm: float = 0.0,
		drop: float = 0.30, wood_kit: DecoKit = null, metal_kit: DecoKit = null) -> Vector3:
	var wk: DecoKit = wood_kit if wood_kit != null else kit
	var mk: DecoKit = metal_kit if metal_kit != null else kit
	var reach: float = maxf(arm, 0.0)
	if reach > 0.0:
		wk.rbox(anchor + Vector3(0.0, 0.0, -reach * 0.5), Vector3(0.09, 0.09, reach), 0.03, WOOD_DARK, Basis.IDENTITY, 0)
		mk.sphere(anchor + Vector3(0.0, 0.0, -reach), 0.07, GOLD_DEEP, Vector3.ONE, 10)
	var bar_z: float = anchor.z - reach
	var plate_c := Vector3(anchor.x, anchor.y - drop - plate_h * 0.5, bar_z)
	for s in [-1.0, 1.0]:
		var x: float = plate_w * 0.34 * s
		mk.bar(anchor + Vector3(x, -0.02, -reach), plate_c + Vector3(x, plate_h * 0.5, 0.0), 0.024, METAL_DARK, 6)
	wk.extrude(DecoKit.round_rect_poly(plate_w + 0.14, plate_h + 0.14, 0.15, 5), 0.09, rim_color,
			Transform3D(Basis.IDENTITY, plate_c))
	kit.extrude(DecoKit.round_rect_poly(plate_w, plate_h, 0.11, 5), 0.16, plate_color,
			Transform3D(Basis.IDENTITY, plate_c))
	for i in 4:
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var sy: float = -1.0 if i < 2 else 1.0
		mk.sphere(plate_c + Vector3(plate_w * 0.42 * sx, plate_h * 0.28 * sy, -0.09), 0.03, GOLD_DEEP, Vector3.ONE, 8)
	return plate_c


## A crisp 3D label in the UI theme font, unshaded so it reads at any time of day.
func add_label(text: String, at: Vector3, height_m: float = 0.28, color: Color = TEXT_BROWN,
		parent: Node3D = null) -> Label3D:
	var l := Label3D.new()
	l.name = "Label"
	l.text = text
	l.font = UIStyle.font()
	l.font_size = 96
	l.pixel_size = height_m / 96.0
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(1.0, 0.98, 0.92, 0.85)
	l.shaded = false
	l.double_sided = false
	l.no_depth_test = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = at
	l.rotation.y = PI          # faces -Z like the rest of the model
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(l)
	return l


## A chunky potted plant: tapered terracotta pot, a rim, dark soil and two tiers of structured
## foliage with a flat dark underside (docs/STYLE_GUIDE.md "Shape language corrections").
func build_planter(kit: DecoKit, at: Vector3, s: float = 1.0, pot_color: Color = TERRACOTTA,
		leaf_top: Color = LEAF, leaf_under: Color = LEAF_UNDER) -> void:
	kit.cone(at, 0.29 * s, 0.34 * s, 0.42 * s, pot_color, Basis.IDENTITY, 14)
	kit.torus(at + Vector3(0.0, 0.42 * s, 0.0), 0.34 * s, 0.055 * s, pot_color.lightened(0.12), Basis.IDENTITY, 16)
	kit.disc(at + Vector3(0.0, 0.40 * s, 0.0), 0.31 * s, Color("#4a3a2c"), Basis.IDENTITY, 14)
	kit.lobed_dome(at + Vector3(0.0, 0.62 * s, 0.0), 0.48 * s, 0.34 * s, leaf_top, leaf_under, 7, 0.13, 0.70, 0.4, 20, 3, 0.045 * s)
	kit.lobed_dome(at + Vector3(0.0, 0.86 * s, 0.0), 0.32 * s, 0.28 * s, leaf_top.lightened(0.08), leaf_under, 6, 0.14, 0.72, 1.1, 18, 3, 0.035 * s)


## A lantern post: dark metal stem, a tapered cage and a warm pane. Returns the pane centre so the
## caller can add the glow mesh and the light there.
func build_lantern_post(kit: DecoKit, at: Vector3, h: float = 2.15) -> Vector3:
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.20, 0.0), Vector2(0.18, 0.07), Vector2(0.075, 0.12), Vector2(0.0, 0.13)]),
			14, Transform3D(Basis.IDENTITY, at), BRONZE)
	kit.cone(at + Vector3(0.0, 0.10, 0.0), 0.075, 0.055, h - 0.42, Color("#8d99ae"), Basis.IDENTITY, 12)
	kit.torus(at + Vector3(0.0, h * 0.46, 0.0), 0.085, 0.03, BRONZE, Basis.IDENTITY, 12)
	var head := at + Vector3(0.0, h - 0.20, 0.0)
	# four corner bars + a capped roof: an AC lantern cage, not a solid block
	kit.rbox(head + Vector3(0.0, -0.20, 0.0), Vector3(0.34, 0.09, 0.34), 0.035, BRONZE, Basis.IDENTITY, 0)
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		kit.rbox(head + Vector3(sin(a) * 0.145, 0.0, cos(a) * 0.145), Vector3(0.045, 0.36, 0.045), 0.014, BRONZE, Basis(Vector3.UP, -a), 0)
	kit.rbox(head + Vector3(0.0, 0.22, 0.0), Vector3(0.42, 0.075, 0.42), 0.03, BRONZE, Basis.IDENTITY, 0)
	kit.cone(head + Vector3(0.0, 0.25, 0.0), 0.20, 0.035, 0.20, BRONZE, Basis(Vector3.UP, PI * 0.25), 4)
	kit.sphere(head + Vector3(0.0, 0.47, 0.0), 0.05, GOLD_DEEP, Vector3.ONE, 8)
	return head


# ============================================================================================ day / night
## 0 in full daylight, 1 at full night. Reads the Environment when it exists (so the buildings and
## the sky always agree) and falls back to the same curve derived from GameState.time_of_day.
func night_factor() -> float:
	if _env == null or not is_instance_valid(_env):
		_env = get_tree().root.find_child("Environment", true, false)
	if _env and _env.has_method("get_night_factor"):
		return float(_env.get_night_factor())
	return night_from_hour(GameState.time_of_day)


## The EnvPalette night curve (src/world/env_palette.gd): 0 from 06:24 to 18:24, 1 by 20:24.
static func night_from_hour(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	if h < 4.6 or h >= 20.4:
		return 1.0
	if h < 6.4:
		return 1.0 - smoothstep(4.6, 6.4, h)
	if h < 18.4:
		return 0.0
	return smoothstep(18.4, 20.4, h)


func _on_phase_changed(_phase: String) -> void:
	_night_target = night_factor()
	_poll = NIGHT_POLL
	if not is_processing():
		set_process(true)


func _apply_night() -> void:
	for i in _lights.size():
		var e: float = _light_energy[i] * _night * LIGHT_SCALE
		_lights[i].light_energy = e
		_lights[i].visible = e > 0.02


# ============================================================================================ UI helpers
func dialogue() -> DialogueBox:
	return get_node_or_null("/root/World/HUD/DialogueBox") as DialogueBox


func shop() -> ShopPanel:
	return get_node_or_null("/root/World/HUD/ShopPanel") as ShopPanel


func toast(text: String, icon: String = "") -> void:
	EventBus.toast_requested.emit(text, icon)


## Speaks a few lines and waits for the player to read them. No-op when the HUD is absent.
func say(speaker: String, lines: Array, voice: String = "alien", accent: Color = Color("#5b7cff")) -> void:
	var box := dialogue()
	if box == null:
		return
	await box.show_lines(speaker, lines, voice, accent)


## Asks a question and returns the chosen index (-1 on cancel, -1 when there is no HUD).
func ask(prompt: String, options: Array) -> int:
	var box := dialogue()
	if box == null:
		return -1
	var idx: int = await box.show_choice(prompt, options)
	# The box lingers for a moment after a choice; close it now so the next modal opens cleanly.
	box.hide_box()
	await get_tree().process_frame
	return idx


## Guards a whole shop flow so a second `interact` cannot start it twice.
func begin_flow(player: Node3D) -> bool:
	if _busy:
		return false
	_busy = true
	if player and player.has_method("face_toward"):
		player.face_toward(door_point())
	AudioManager.play_sfx("door_open", -6.0)
	return true


func end_flow() -> void:
	_busy = false
