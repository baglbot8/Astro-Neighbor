class_name BuildBench
extends Interactable
## The crash-site workbench (docs/BUILD_PLAN.md Phase 2 builder F). Spawned by world.gd only on home,
## as /root/World/BuildBench, next to the rocket pad. Interacting opens ShopPanel's "build" mode
## (src/ui/shop/shop_panel.gd, mine this phase too), which reads what to build straight off
## ProjectSystem (builder E) and the bag - this file does not know what any project needs.
##
## PLACEMENT. `Planet.find_free_dir_near` around `planet.data.pad_dir` already keeps clear of the
## pad's own reserved zone (Planet.PAD_FLAT_RADIUS 4.0 + 1.0 = 5.0 m, planet.gd `_add_reserved("pad",
## ...)`) and, with room to spare, the pad's "Fly" interactable (rocket_pad.gd: reach 4.2 m) - so the
## bench can never land ON the pad or crowd the thing you fly with, without a hand-picked number for
## either. `register_prop` afterward keeps every later decoration and find-marker off the spot too.
##
## LOOK: a procedural workbench built from DecoKit primitives (grey/metal, matching the scrap pickup's
## own palette per catalog.gd's comment on "scrap" - the bench reads as made from the same wreck the
## scrap comes from), not a crafting table - CLAUDE.md "its own game, not an Animal Crossing copy".
## A StaticBody3D on layer 4 (`DecoItem._make_collider`'s "decoration" layer, which the player's own
## collision_mask already includes - player.gd:190) keeps the astronaut from walking through it.

## Surface-distance band around the pad the bench is allowed to land in (see the class doc above for
## why the floor is already guaranteed by the pad's own reserved zone).
const BENCH_NEAR_M := 9.0
const BENCH_CLEARANCE_M := 1.1
const FOOTPRINT := 0.85
## Arbitrary RNG salt, just needs to not collide with another home-planet prop's own salt.
const PLACEMENT_SALT := 0x8E4C4

var planet: Planet
var _visual: Node3D


func _ready() -> void:
	super._ready()
	prompt_text = "Build"
	reach = 2.6
	require_facing = false
	add_to_group("build_bench")
	planet = get_tree().get_first_node_in_group("planet")
	_place()
	_build_visual()
	_build_collider()
	# Same idea as TrashPiece's own shape (trash_piece.gd): the reach check itself is pure distance
	# (player.gd `_update_interact_target`, no physics query), so this is not load-bearing for being
	# found - it exists so the Area3D's own bounds are never degenerate for anything that inspects it.
	var probe := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.0, 0.7)
	probe.shape = box
	probe.position = Vector3(0.0, 0.5, 0.0)
	add_child(probe)


## Picks a spot a short walk from the pad, faces the bench roughly toward it, and reserves the
## ground so nothing else (a later decoration, a project's find marker) lands on top of it.
func _place() -> void:
	if planet == null:
		push_warning("BuildBench: no Planet in group 'planet' - staying at the origin")
		return
	var rng := planet.make_rng(PLACEMENT_SALT)
	var pad := planet.data.pad_dir.normalized()
	var dir := Vector3.ZERO
	# `find_free_dir_near` samples uniformly over the WHOLE sphere and keeps only the draws that
	# land inside the band (planet.gd `_find_free_dir`'s `band_max_m` check) - on a small, crowded
	# home planet the 9 m band around the pad can legitimately come up empty in the default 32
	# tries. MEASURED 2026-09-11: with 32 tries the very first placement missed and fell through to
	# `find_free_dir`'s planet-wide search, landing the bench 33 m away - on the far side of the
	# planet, nowhere near "near the pad" (captures/BUILD_BENCH debug_report, pad_dist_m=33.32).
	# Widening the band (never falling back to an unrelated spot) keeps every landing a short walk
	# from the pad, and more tries per band makes finding one in a 9-14-21 m band overwhelmingly
	# likely rather than leaving it to a single roll of 32.
	for band_m in [BENCH_NEAR_M, BENCH_NEAR_M * 1.6, BENCH_NEAR_M * 2.4]:
		dir = planet.find_free_dir_near(rng, pad, band_m, BENCH_CLEARANCE_M, 200)
		if dir != Vector3.ZERO:
			break
	if dir == Vector3.ZERO:
		# Every band came up empty (an extremely crowded planet): land ON the pad direction rather
		# than not exist - tools/check.sh's headless boot needs this node regardless, and this is
		# still closer to "near the pad" than a planet-wide random spot would be.
		dir = pad
	planet.register_prop(dir, FOOTPRINT)
	var hint := planet.surface_point(pad) - planet.surface_point(dir)
	transform = planet.surface_transform(dir, hint)


## Chunky low-poly workbench: four splayed legs, a tabletop, a shelf of scrap underneath, a small
## vice, and a bent work-lamp arm - a strong enough silhouette to read as "the build spot" from
## across the crash site, without being a single AC-style crafting table.
func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var frame := Color("#726c86")   # dark metal - trash_piece.gd's own "dark" can tone
	var top := Color("#9295ac")     # UI panel-edge grey (STYLE_GUIDE Moonstone) - cohesive with the HUD
	var crate := Color("#8a8496")   # scrap-metal grey - catalog.gd "scrap" icon_color
	var rust := Color("#c2703f")    # rust accent - trash_piece.gd `_build_scrap`'s own bolt color
	var lamp := Color("#5f92cc")    # the astronaut's own jacket-panel blue (game_state.gd panel_color)
	var kit := DecoKit.new()
	var legs := [Vector2(-0.42, -0.24), Vector2(0.42, -0.24), Vector2(-0.42, 0.24), Vector2(0.42, 0.24)]
	for lp: Vector2 in legs:
		kit.tube(Vector3(lp.x * 1.12, 0.0, lp.y * 1.12), Vector3(lp.x, 0.74, lp.y), 0.05, frame, 8)
	kit.tube(Vector3(-0.42, 0.26, -0.24), Vector3(0.42, 0.26, -0.24), 0.028, frame, 6)
	kit.tube(Vector3(-0.42, 0.26, 0.24), Vector3(0.42, 0.26, 0.24), 0.028, frame, 6)
	kit.rbox(Vector3(0.0, 0.8, 0.0), Vector3(1.12, 0.09, 0.64), 0.035, top)
	# A shelf of scrap waiting to be built into something, under the tabletop.
	kit.rbox(Vector3(0.0, 0.34, 0.0), Vector3(0.94, 0.05, 0.52), 0.02, frame)
	kit.rbox(Vector3(-0.26, 0.42, 0.1), Vector3(0.18, 0.12, 0.15), 0.03, crate, Basis(Vector3.UP, 0.4))
	kit.rbox(Vector3(0.1, 0.4, -0.06), Vector3(0.15, 0.09, 0.17), 0.03, crate, Basis(Vector3.UP, -0.3))
	kit.sphere(Vector3(0.3, 0.38, 0.14), 0.05, rust, Vector3.ONE, 6)
	# A small vice clamped to the front edge.
	kit.rbox(Vector3(-0.4, 0.87, 0.3), Vector3(0.11, 0.08, 0.1), 0.02, frame)
	kit.tube(Vector3(-0.4, 0.87, 0.26), Vector3(-0.4, 0.87, 0.36), 0.018, top, 6)
	# A bent work-lamp arm rising off the back edge, curling forward over the table.
	kit.tube(Vector3(0.38, 0.84, -0.3), Vector3(0.38, 1.2, -0.3), 0.03, frame, 8)
	kit.tube(Vector3(0.38, 1.2, -0.3), Vector3(0.14, 1.3, -0.02), 0.03, frame, 8)
	kit.dome(Vector3(0.1, 1.26, -0.02), 0.09, lamp, 0.8, Basis(Vector3.RIGHT, deg_to_rad(120.0)))
	_add_mesh(kit.commit(), DecoItem.metal_material())
	# The bulb, on its own emissive surface - DecoItem.glow_material() reads the shared night uniform
	# (deco_glow.gdshader / ARCHITECTURE.md 9.1), so it warms up after dusk with zero script here.
	var glow := DecoKit.new()
	glow.sphere(Vector3(0.1, 1.21, 0.02), 0.045, Color("#ffdca0"), Vector3.ONE, 8)
	_add_mesh(glow.commit(), DecoItem.glow_material())
	# A gear cut into the front apron: reads as a mechanical build station at a glance, not a picnic
	# table (CLAUDE.md "its own game, not an Animal Crossing copy").
	var gear := DecoKit.new()
	gear.extrude(DecoKit.gear_poly(0.11, 0.03, 8), 0.02, frame.darkened(0.12),
		Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.0, 0.58, 0.325)))
	_add_mesh(gear.commit(), DecoItem.metal_material())


func _add_mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visual.add_child(mi)
	return mi


## Blocks the player from walking through the bench. Layer 4 (1 << 3) is DecoItem's own "decoration"
## blocking layer (deco_item.gd `_make_collider`), already in the player's collision_mask
## (player.gd:190), so this is the same convention every placed decoration uses - not a new one.
func _build_collider() -> void:
	var body := StaticBody3D.new()
	body.name = "Blocker"
	body.collision_layer = 1 << 3
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.6, 0.75)
	cs.shape = shape
	cs.position = Vector3(0.0, 0.8, 0.0)
	body.add_child(cs)
	add_child(body)


## Opens the bench's build/fit panel. `player` is only forwarded to `interacted` (matches every other
## Interactable's contract); the panel itself needs no player reference.
func interact(player: Node3D) -> void:
	var shop := get_tree().root.get_node_or_null("World/HUD/ShopPanel") as ShopPanel
	if shop == null:
		push_warning("BuildBench: no /root/World/HUD/ShopPanel to open")
		return
	shop.open([], "build", "Build Bench")
	interacted.emit(player)


## One-line state dump for a Director timeline to assert against - position (is it near the pad,
## not on it?) plus the two currencies and the bag/rocket state the bench's actions change.
func debug_report(tag: String = "") -> void:
	var pad_dist := -1.0
	if planet != null:
		pad_dist = planet.surface_distance(planet.dir_of(global_position), planet.data.pad_dir.normalized())
	print("BUILD_BENCH %s pos=%s pad_dist_m=%.2f scrap=%d stardust=%d rocket_parts=%s inventory=%s" % [
		tag, str(global_position), pad_dist, GameState.scrap, GameState.stardust,
		str(GameState.rocket_parts), str(GameState.inventory)])
