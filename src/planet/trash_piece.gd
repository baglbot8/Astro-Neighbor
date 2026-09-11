class_name TrashPiece
extends Interactable
## One piece of space junk sitting on the home planet (docs/ARCHITECTURE.md §11). Spawned and tracked
## by TrashSystem, never through the decoration catalog/inventory — it is not an item you own.
## Static (junk does not float like a Collectible), small idle wobble on the wrapper only.
## `interact()` cleans it up: removes it from GameState.trash_home, pays a small scrap finder's
## fee (BUILD_PLAN Phase 1 "D": space trash pays scrap, not stardust - it IS asteroid/ship debris),
## plays sfx, and frees itself.

const KINDS: PackedStringArray = ["can", "scrap", "wrapper"]
# FIRST GUESS, BUILD_PLAN Phase 6 tunes it from a timed play-through (matches the randi_range(3, 6)
# comment on collectible.gd's own scrap pickup) - a bit richer than a plain pickup since cleaning up
# takes noticing the trash and walking to it, but still small next to GameState.STARTING_SCRAP (5).
const CLEANUP_REWARD_MIN := 4
const CLEANUP_REWARD_MAX := 10

var kind: String = "can"
var trash_id: String = ""
var _visual: Node3D
var _picked := false
var _t := 0.0
var _phase := 0.0
var _animated := false


func setup(p_kind: String, p_id: String) -> void:
	kind = p_kind if KINDS.has(p_kind) else "can"
	trash_id = p_id
	name = "Trash_" + p_id
	prompt_text = "Clean up"
	reach = 2.4
	require_facing = false
	add_to_group("trash_pieces")
	_phase = randf() * TAU
	_build_visual()


func _ready() -> void:
	super._ready()
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.5
	shape.shape = s
	shape.position = Vector3(0.0, 0.25, 0.0)
	add_child(shape)
	set_process(_animated)


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	_visual.rotation.y = randf() * TAU
	add_child(_visual)
	match kind:
		"can":
			_build_can()
		"scrap":
			_build_scrap()
		"wrapper":
			_build_wrapper()
			_animated = true
		_:
			_build_can()


## A crushed drink can: a squat cylinder with a pinched waist and a torn rim.
func _build_can() -> void:
	var kit := DecoKit.new()
	var body := Color("#a9a4b8")
	var dark := Color("#726c86")
	kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.18, 0.05), Vector2(0.1, 0.14),
		Vector2(0.17, 0.22), Vector2(0.13, 0.3), Vector2(0.09, 0.32),
	]), 12, Transform3D.IDENTITY, body)
	kit.disc(Vector3(0.0, 0.32, 0.0), 0.07, dark, Basis.IDENTITY, 10)
	_add_mesh(kit.commit(), DecoItem.metal_material())


## A bent sheet of hull plating with a bolt still sticking out of it.
func _build_scrap() -> void:
	var kit := DecoKit.new()
	var metal := Color("#8a8496")
	var rust := Color("#c2703f")
	kit.rbox(Vector3(0.0, 0.05, 0.0), Vector3(0.5, 0.05, 0.34), 0.03, metal, Basis(Vector3.RIGHT, deg_to_rad(9.0)))
	kit.tube(Vector3(-0.12, 0.02, 0.05), Vector3(-0.12, 0.24, 0.02), 0.025, metal, 6)
	kit.sphere(Vector3(-0.12, 0.25, 0.015), 0.045, rust, Vector3(1.0, 0.7, 1.0), 6)
	_add_mesh(kit.commit(), DecoItem.metal_material())
	var glow := DecoKit.new()
	glow.rbox(Vector3(0.16, 0.052, -0.05), Vector3(0.14, 0.01, 0.1), 0.01, rust)
	_add_mesh(glow.commit(), DecoItem.body_material())


## A crumpled foil wrapper — bright, so it reads as clutter against the grass at a glance.
func _build_wrapper() -> void:
	var kit := DecoKit.new()
	var foil := Color("#ff9f43")
	kit.sphere(Vector3(0.0, 0.07, 0.0), 0.14, foil, Vector3(1.3, 0.55, 1.1), 7)
	kit.sphere(Vector3(0.08, 0.1, 0.05), 0.06, foil.darkened(0.12), Vector3(1.0, 0.6, 1.0), 6)
	_add_mesh(kit.commit(), DecoItem.body_material())


func _add_mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visual.add_child(mi)
	return mi


func _process(delta: float) -> void:
	if _picked:
		return
	_t += delta
	_visual.rotation.z = sin(_t * 1.6 + _phase) * 0.05   # wrapper: light breeze-shuffle


func interact(player: Node3D) -> void:
	if _picked:
		return
	_picked = true
	enabled = false
	set_focused(false)
	GameState.remove_trash(trash_id)
	var reward := randi_range(CLEANUP_REWARD_MIN, CLEANUP_REWARD_MAX)
	GameState.add_scrap(reward)
	AudioManager.play_sfx("pickup_item")
	EventBus.toast_requested.emit("Cleaned up! +%d Scrap" % reward, "scrap")
	interacted.emit(player)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.25, 1.25, 1.25), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_visual, "scale", Vector3(0.01, 0.01, 0.01), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
