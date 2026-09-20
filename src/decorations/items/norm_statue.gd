extends DecoItem
## Statue of Norm — Norm's reward after gold, forever after (NORM_SPEC.md §6). A carved likeness of
## Norm himself: when `norm_model.gd` exists (NORM LOOK is designing it in scratch as of 2026-09-19),
## every mesh under it is baked into ONE ArrayMesh here, re-coloured to a single stone tone; until it
## exists, a clean placeholder standing figure — same silhouette job (a small figure on a plinth),
## no ragged-suit detail to fake, since there is no design yet to be faithful to.
##
## BUILT ONCE PER PROCESS (NORM_SPEC §8, "the mesh built once per process"). `_full_mesh()` caches
## the result — PLINTH AND FIGURE COMBINED INTO ONE ArrayMesh — in a `static var`; every `NormStatue`
## instance — one or twenty — calls it and gets back the SAME `ArrayMesh` and the SAME
## (MaterialLib-cached) stone `Material`, so a planet full of statues costs one extra MeshInstance3D
## (one draw call) each and nothing more to build or hold.
##
## R2 FIX 2026-09-19: round 1 built the plinth as a second, per-instance `add_body(kit.commit())`
## call (a fresh mesh every statue, in the ordinary body material) plus the contact-shadow quad every
## `DecoItem` gets - three draws per statue, and 20 of them measured well over the +25 budget. The
## plinth is now baked into the same cached mesh as the figure (one vertex-coloured surface, one
## material, one draw), and `_add_contact_shadow()` is overridden to a no-op below: the plinth is a
## flat-bottomed box already sitting on the ground, so the blob a contact shadow would draw under it
## added nothing worth a whole extra draw call.

const MODEL_PATH := "res://src/characters/models/norm_model.gd"

## Stone palette — S all comfortably under the R2.6 "no swatch above S 0.60" gate, deliberately flat
## and desaturated (an actual carved statue, not a painted figure).
const STONE := Color("#9a968f")       ## S 0.071 V 0.604 — the figure's base tone
const STONE_DARK := Color("#7c7972")  ## S 0.081 V 0.486 — creases, collar, visor band, plinth base
const STONE_LIGHT := Color("#b0aca4") ## S 0.068 V 0.690 — raised surfaces (helmet, shoulders)
const PLINTH := Color("#8f8b85")
const PLINTH_DARK := Color("#726f6a")
## STONE as the linear value the vertex-colour shader expects (DecoKit's plinth colours go through
## the same PlanetMeshKit._lin conversion).
static var STONE_LIN: Color = PlanetMeshKit._lin(STONE)

## Standing height (m) the figure is scaled to, baked or placeholder, so both read as the same size
## of statue and sit flush on the same plinth regardless of the source model's native scale.
const TARGET_HEIGHT := 1.05
const PLINTH_HEIGHT := 0.12
const PLINTH_SIZE := 0.62

static var _cached_mesh: ArrayMesh
## True once the cached mesh actually came from `norm_model.gd` (vs. the placeholder). Read by tests
## and critics to tell which figure is on screen without eyeballing it; gameplay never reads it.
static var _cached_from_model: bool = false
static var _stone_mat: ShaderMaterial


func _init() -> void:
	footprint = 0.55
	collide_radius = 0.36
	collide_height = TARGET_HEIGHT + PLINTH_HEIGHT


func _build() -> void:
	_add(_full_mesh(self), _stone_material(), "Figure", null)


## The plinth sits flat on the ground already (a flat-bottomed box baked into `_full_mesh()`); the
## generic `DecoItem` contact-shadow blob would be a second draw call for a shadow this statue does
## not need. See the R2 FIX note above `MODEL_PATH`.
func _add_contact_shadow() -> void:
	pass


## True once `_full_mesh()` has run and used the real model (vs. the placeholder).
static func built_from_model() -> bool:
	return _cached_from_model


## The shared "carved stone" material — one `ShaderMaterial`, cached by `MaterialLib` (keyed by its
## options), so every statue's `_add` call gets back the literal same resource.
static func _stone_material() -> ShaderMaterial:
	if _stone_mat == null:
		_stone_mat = MaterialLib.toon_vertex_color({
			"rim": 0.06, "spec": 0.04, "spec_size": 90.0, "shade": 0.42,
			"surface": "rock", "surface_strength": 0.55,
		})
	return _stone_mat


## The one shared PLINTH + FIGURE mesh (NORM_SPEC §8). Built the first time any statue asks for it;
## every call after returns the same `ArrayMesh` instance without touching `norm_model.gd` or
## rebuilding the plinth again. `tree_anchor` is only used the first time, to host the model instance
## while it is baked — a `Node3D.global_transform` read is only valid inside the SceneTree, and the
## statue's own `self` is already there (a `DecoItem`'s `_build()` runs from `_ready()`, after it
## entered the tree).
static func _full_mesh(tree_anchor: Node3D) -> ArrayMesh:
	if _cached_mesh != null:
		return _cached_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var pkit := DecoKit.new()
	pkit.rbox(Vector3(0.0, PLINTH_HEIGHT * 0.5, 0.0), Vector3(PLINTH_SIZE, PLINTH_HEIGHT, PLINTH_SIZE), 0.05, PLINTH_DARK)
	pkit.rbox(Vector3(0.0, PLINTH_HEIGHT + 0.03, 0.0), Vector3(PLINTH_SIZE * 0.78, 0.06, PLINTH_SIZE * 0.78), 0.03, PLINTH)
	_append_arraymesh(st, pkit.commit(), Transform3D.IDENTITY)

	var figure: ArrayMesh = null
	if ResourceLoader.exists(MODEL_PATH):
		figure = _bake_from_model(tree_anchor)
	_cached_from_model = figure != null
	if figure == null:
		figure = _placeholder_mesh()
	# Not turned: the figure faces -Z, the model's own facing and the same front every decoration has
	# (the crater bench's backrest is at +Z). Which way a placed statue looks is the player's yaw.
	var figure_xf := Transform3D(Basis.IDENTITY, Vector3(0.0, PLINTH_HEIGHT + 0.06, 0.0))
	_append_arraymesh(st, figure, figure_xf)

	_cached_mesh = st.commit()
	return _cached_mesh


## Appends every triangle of `mesh` into `st`, transformed by `xf`, keeping the source mesh's own
## per-vertex colours (both the plinth's `DecoKit` output and the placeholder/baked figure already
## carry the colours they should render in — this is a geometry merge, not a recolour). Same "walk
## every surface, keep index order, rebuild normals through the basis" shape as
## `_append_mesh_instance()` below, generalised to take a mesh directly instead of a `MeshInstance3D`.
static func _append_arraymesh(st: SurfaceTool, mesh: ArrayMesh, xf: Transform3D) -> void:
	if mesh == null:
		return
	var nb: Basis = xf.basis.inverse().transposed()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts == null or verts.is_empty():
			continue
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		# A non-indexed surface stores null here, and a typed read of null throws (normchk 2026-09-19:
		# every statue shipped as a bare plinth).
		var idx_v: Variant = arrays[Mesh.ARRAY_INDEX]
		var idx: PackedInt32Array = idx_v if idx_v != null else PackedInt32Array()
		var order := idx if idx.size() > 0 else _sequential(verts.size())
		for i in order.size():
			var vi := order[i]
			var n := Vector3.UP
			if norms != null and norms.size() > vi:
				n = (nb * norms[vi]).normalized()
			st.set_normal(n)
			st.set_color(cols[vi] if cols != null and cols.size() > vi else STONE)
			st.add_vertex(xf * verts[vi])


# ============================================================================================ bake from the real model
## Loads `norm_model.gd`, builds it (`rebuild()` is its own public "(re)build the whole model,
## normally called from `_ready`" API — called directly here since the model never enters the scene
## tree, exactly like `_ready`'s own `if not _built: rebuild()` guard would), poses it with whatever
## pose `rebuild()` leaves it in (its own idle/rest pose — CharacterModel exposes no "hold this pose"
## call, so this is the one pose available to bake), then walks every `MeshInstance3D` under it and
## appends its triangles — transformed into the model's own local space — into one `SurfaceTool`,
## discarding every original material and vertex colour for a single stone tone (NORM_SPEC §6: "baked
## into ONE ArrayMesh with one stone material" — a carved likeness, not a repaint of the suit).
##
## Returns null on ANY failure (wrong base class, `rebuild()` missing, no mesh found) so the caller
## falls back to the clean placeholder rather than shipping a broken or empty statue. `tree_anchor`
## briefly parents the model (removed again before returning) purely so `global_transform` reads
## resolve during the bake; the model is never left attached anywhere.
static func _bake_from_model(tree_anchor: Node3D) -> ArrayMesh:
	var script: Variant = load(MODEL_PATH)
	if not (script is GDScript):
		return null
	var model: Node3D = (script as GDScript).new()
	if model == null or not (model is CharacterModel):
		if model != null:
			model.free()
		return null
	if tree_anchor != null and tree_anchor.is_inside_tree():
		tree_anchor.add_child(model)
	if model.has_method("rebuild"):
		model.call("rebuild")
	elif model.has_method("_ready"):
		model.call("_ready")
	var mesh_instances: Array = []
	_collect_mesh_instances(model, mesh_instances)
	if mesh_instances.is_empty():
		if model.get_parent() != null:
			model.get_parent().remove_child(model)
		model.free()
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any_tris := false
	for mi: MeshInstance3D in mesh_instances:
		if _append_mesh_instance(st, mi, model):
			any_tris = true
	if model.get_parent() != null:
		model.get_parent().remove_child(model)
	model.free()
	if not any_tris:
		return null
	return _regrounded_and_scaled(st.commit())


static func _collect_mesh_instances(node: Node, out: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for c in node.get_children():
		_collect_mesh_instances(c, out)


## Appends one `MeshInstance3D`'s triangles to `st`, transformed from its local space into `root`'s
## own local space (`root` has no parent, so its `global_transform` IS that space — the same "bake
## the node transform into the vertices" trick `RocketModel` uses, MaterialLib.gd's rocket-finish
## comment). Every vertex is written flat stone; only position and normal survive from the source.
static func _append_mesh_instance(st: SurfaceTool, mi: MeshInstance3D, root: Node3D) -> bool:
	var mesh := mi.mesh
	if mesh == null:
		return false
	var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
	var nb: Basis = xf.basis.inverse().transposed()
	var wrote := false
	for s in mesh.get_surface_count():
		# NOTE: `surface_get_primitive_type` is not implemented on the PrimitiveMesh family
		# (SphereMesh/TorusMesh/CapsuleMesh - measured: chibi_model.gd's sphere()/torus() helpers
		# return these, not ArrayMesh) - it throws "Nonexistent function" there, so it is not called.
		# Every mesh chibi_model.gd builds is triangles (icospheres, lathes, primitive meshes); a
		# non-triangle surface would just bake in as a harmless degenerate strip, not corrupt output.
		var arrays := mesh.surface_get_arrays(s)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts == null or verts.is_empty():
			continue
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		# A non-indexed surface stores null here, and a typed read of null throws (normchk 2026-09-19:
		# every statue shipped as a bare plinth).
		var idx_v: Variant = arrays[Mesh.ARRAY_INDEX]
		var idx: PackedInt32Array = idx_v if idx_v != null else PackedInt32Array()
		var order := idx if idx.size() > 0 else _sequential(verts.size())
		for i in order.size():
			var vi := order[i]
			var n := Vector3.UP
			if norms != null and norms.size() > vi:
				n = (nb * norms[vi]).normalized()
			st.set_normal(n)
			# LINEAR, like every DecoKit colour (PlanetMeshKit._lin): the toon shader treats vertex COLOR
			# as linear, so the raw sRGB value rendered the figure near-white (normchk 2026-09-19).
			st.set_color(STONE_LIN)
			st.add_vertex(xf * verts[vi])
			wrote = true
	return wrote


static func _sequential(n: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(n)
	for i in n:
		out[i] = i
	return out


## Rescales the baked figure to `TARGET_HEIGHT`, sits its lowest vertex on y=0 and centres it on X/Z
## — so the statue is the same size and stands flush on its plinth whatever the source model's
## native scale and root offset were.
static func _regrounded_and_scaled(mesh: ArrayMesh) -> ArrayMesh:
	if mesh.get_surface_count() == 0:
		return mesh
	var aabb := mesh.get_aabb()
	if aabb.size.y <= 0.0001:
		return mesh
	var scale := TARGET_HEIGHT / aabb.size.y
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var center_x := aabb.position.x + aabb.size.x * 0.5
	var center_z := aabb.position.z + aabb.size.z * 0.5
	var out := SurfaceTool.new()
	out.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vi in verts.size():
		var v := verts[vi]
		out.set_normal(norms[vi] if norms != null and norms.size() > vi else Vector3.UP)
		out.set_color(cols[vi] if cols != null and cols.size() > vi else STONE)
		out.add_vertex(Vector3((v.x - center_x) * scale, (v.y - aabb.position.y) * scale, (v.z - center_z) * scale))
	return out.commit()


# ============================================================================================ placeholder
## A clean, faceless standing figure in a loose spacesuit silhouette — used until `norm_model.gd`
## exists. Deliberately plain: there is no ragged-suit design to be faithful to yet, so it does not
## guess at one.
static func _placeholder_mesh() -> ArrayMesh:
	var kit := DecoKit.new()
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.09 * s, 0.0, 0.0), Vector3(0.09 * s, 0.42, 0.0), 0.075, STONE_DARK)
		kit.rbox(Vector3(0.09 * s, 0.035, 0.03), Vector3(0.12, 0.07, 0.21), 0.03, STONE_DARK)
	kit.rbox(Vector3(0.0, 0.62, 0.0), Vector3(0.34, 0.32, 0.2), 0.12, STONE)
	kit.rbox(Vector3(0.0, 0.46, 0.0), Vector3(0.36, 0.05, 0.22), 0.02, STONE_DARK, Basis.IDENTITY, 0)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.21 * s, 0.74, 0.0), Vector3(0.24 * s, 0.4, 0.03), 0.055, STONE)
		kit.sphere(Vector3(0.245 * s, 0.375, 0.035), 0.06, STONE_LIGHT, Vector3.ONE, 10)
	kit.torus(Vector3(0.0, 0.82, 0.0), 0.15, 0.035, STONE_DARK, Basis.IDENTITY, 16, 5)
	kit.sphere(Vector3(0.0, 0.95, 0.0), 0.16, STONE_LIGHT, Vector3.ONE, 14)
	kit.rbox(Vector3(0.0, 0.94, -0.13), Vector3(0.2, 0.09, 0.05), 0.03, STONE_DARK, Basis.IDENTITY, 0)
	return kit.commit()
