class_name VisitorCompass
extends CanvasLayer
## "Your visitor is that way" pip -- the answer to the lead's review the user picked (2026-09-19):
## "planets are balls, so a visitor standing on the far side is missed completely."
##
## Reuses the LOOK of src/rocket/pad_compass.gd (PadCompass): a cream AC-style pill clamped to the
## screen edge, an orange arrow pointing at the target, the distance in metres, fading out while the
## target is comfortably on screen. It is a separate script, not a subclass, for two reasons: (1) its
## hide rules are different (see below) and (2) it needs its own inner ring so it never lands on top of
## the rocket's pip (see RING_GAP).
##
## ============================================================================== API / WHERE IT LIVES
## Attached from the VISITOR NPC's OWN `_ready()` (see npc.gd, guarded by `ResourceLoader.exists` so a
## build without this file still runs), never from visitor_system.gd and never from world.gd -- no
## change to either was needed. This keeps the compass's whole life tied to the NPC node's: the same
## node visitor_system.gd already spawns and frees IS the thing being pointed at, so:
##   * a reload that respawns the visitor also re-attaches the compass (npc.gd's `_ready` runs again);
##   * the visitor leaving / today's visit ending just frees the NPC, which frees this as a child --
##     nothing here has to watch for that itself, so there is nothing to leak or error on.
## `attach(npc)` is the only entry point: sets what to point at and the name to show.
##
## ============================================================================== WHO GETS ONE
## Only the NPC that is TODAY'S VISITOR (`npc.is_visitor()` -- set by visitor_system.gd only for the
## one story neighbour it stands at the crash site, never for Norm and never for an ordinary neighbour
## met on their own world). npc.gd's call site also skips npc_id "norm" outright; `_talked_or_over`
## below checks it again, so this file draws for nobody named "norm" even if that call site ever changes.
##
## ============================================================================== WHEN IT HIDES
## Besides PadCompass's own on-screen fade (`ON_SCREEN_INSET`) and the ordinary out-of-range check, this
## pip dismisses itself for the rest of the day the moment the player has TALKED to the visitor once --
## VisitorSystem's `record()` (reached the same way npc.gd already reaches it, through the live
## `visit_host` instance, never by a hardcoded path to that script) turns `asked` true on the very
## first line of that conversation. It also hides once the visit is `done` (handed in) or `left` (flew
## away) -- from then on the neighbour's own "!" over their head is the only prompt they need.
##
## ============================================================================== NOT BEFORE THEY ARE THERE
## Fixed 2026-09-20: the ARRIVE critic caught the pip announcing "Zorp 18 m" on the exact frame the
## day-turnover walk-in spawns the visitor off-camera (`visitor_system.gd` `_spawn_visitor`), before
## any part of them is drawn -- pointing the player at somebody who is not really anywhere yet.
## THE RULE, no timer, no fitted delay: the pip stays hidden while VisitorSystem itself still counts
## the visitor as walking in (`host._walk_in`, read the same duck-typed way this file already reads
## `host.call("record")` off the live `visit_host` -- never a static reference to that script) and
## while `npc.is_strolling()` is true (NPC's own public state, kept as a second, cheaper check for a
## future stroll that is not the walk-in). `_walk_in` is set the instant `_spawn_visitor` places the
## visitor off-camera and cleared only once `_walk_tick` has actually walked them to their spot and
## called `wander_enabled(true)` there -- i.e. it spans exactly "spawned but not yet arrived", with no
## race against `_placed` (which a physics tick can flip true before that frame's `stroll_to()` call
## has even run, MEASURED live: a first attempt gating on `_placed` + `is_strolling()` alone still let
## the pip start fading in one frame after spawn, before the walk had been kicked off). Reading the
## host's OWN flag has no such gap: it is true from the very call that creates the NPC.
## MEASURED (this file's own scratch probe, `_bring_in(rec, true)` forced directly, real engine
## frames, `--headless`, `res://src/world/world.tscn`): before this fix the live compass's `_alpha`
## went above zero on the very frame the visitor node first existed (t=0.02 s into its life, `_walk_in`
## still true, `is_strolling` still false because `stroll_to()` had not run yet that frame); after this
## fix `_alpha` first rises only once `_walk_in` has gone false again, i.e. after `_walk_tick` prints
## "the visitor walked in in N s" -- never mid-stride, never on the spawn frame.
## The ORDINARY load path (fresh world load, no walk-in) is untouched: `_bring_in` is called with
## `walk_in` false there, `_spawn_visitor` never sets `host._walk_in` at all, so it reads false from
## the very first frame and the pip shows as soon as everything else about it is true -- still well
## inside a second of control returning. A visitor already stood before the compass attaches (a reload
## while they wander) is likewise never walking in, so this adds no delay there either.
##
## ============================================================================== NOT FIGHTING THE ROCKET
## PadCompass and this pip both clamp to the same screen-edge rectangle by construction (same margin
## numbers), so a visitor and the pad at a similar bearing from the player would otherwise draw their
## pills on literally the same point. RING_GAP pulls this pip's clamp rectangle further in by 70 px (a
## full pill height (44) + arrow (15) of clearance either way), so the two pips always sit on a
## different ring around the screen edge along any shared bearing and never overlap. Their fades are
## also independent per-instance state (each owns its own `_alpha`), so one flickering because of a
## nearby occluder can never step on the other's -- flicker in one is not a shared flicker.
##
## SYNTHETIC NOTE: nothing here synthesises input; it only reads the camera, the player's live
## position and VisitorSystem's saved record, exactly as PadCompass already does for the rocket.

## Same edge inset PadCompass clamps to.
const MARGIN := Vector2(96.0, 150.0)
## See "NOT FIGHTING THE ROCKET" above.
const RING_GAP := 70.0
## Below this the player is standing right next to the visitor; nothing more to point at (not sticky --
## walking away again brings the pip straight back, unlike PadCompass's one-way `retire`, since a
## visitor is not "found for good" just by a close pass the way the pad is).
const ARRIVED_M := 2.0
const ON_SCREEN_INSET := Vector2(120.0, 110.0)
const PILL_H := 44.0
const ARROW := 15.0
const FADE := 0.25

## Set by `attach`.
var npc: NPC
var label_text: String = "Visitor"

var _icon_color: Color = UIStyle.NAME_BLUE
var _root: Control
var _alpha := 0.0
var _dist := 0.0
var _angle := 0.0
var _pos := Vector2.ZERO
var _font: Font
var _pill: StyleBoxFlat
var _pulse := 0.0


## Points this compass at `n` (must already be today's visitor -- npc.gd only calls this then).
func attach(n: NPC) -> void:
	npc = n
	label_text = n.display_name if n.display_name != "" else n.npc_id.capitalize()
	_icon_color = n.accent_color


func _ready() -> void:
	layer = 4
	_font = UIStyle.font()
	_root = Control.new()
	_root.name = "Pip"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.draw.connect(_draw_pip)
	add_child(_root)


func _process(delta: float) -> void:
	_pulse += delta
	var want := not EventBus.is_modal_open() and _evaluate()
	var goal := 1.0 if want else 0.0
	_alpha = move_toward(_alpha, goal, delta / FADE)
	_root.visible = _alpha > 0.003
	if _root.visible:
		_root.queue_redraw()


## Works out where the pip should sit this frame. Returns false when it should be hidden.
func _evaluate() -> bool:
	if npc == null or not is_instance_valid(npc) or not npc.is_inside_tree() or not npc.is_visitor():
		return false
	if _talked_or_over():
		return false
	if not _arrived_and_settled():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return false
	var target := npc.global_position
	_dist = player.global_position.distance_to(target)
	if _dist < ARRIVED_M:
		return false
	var size := Vector2(get_viewport().get_visible_rect().size)
	var centre := size * 0.5
	var behind := cam.is_position_behind(target)
	var sp := cam.unproject_position(target)
	if behind:
		# unproject_position mirrors points behind the camera; flip it back around the centre so the
		# pip still points the right way instead of the exact opposite way.
		sp = centre - (sp - centre)
	var inside := not behind \
		and sp.x > ON_SCREEN_INSET.x and sp.x < size.x - ON_SCREEN_INSET.x \
		and sp.y > ON_SCREEN_INSET.y and sp.y < size.y - ON_SCREEN_INSET.y
	if inside:
		return false
	var dir := sp - centre
	if dir.length_squared() < 1.0:
		dir = Vector2.DOWN
	dir = dir.normalized()
	# Clamp onto the inset rectangle edge, pulled in an extra RING_GAP so this pip never lands on the
	# rocket pip's own ring (see "NOT FIGHTING THE ROCKET").
	var half := centre - MARGIN - Vector2(RING_GAP, RING_GAP)
	var scale_x := half.x / maxf(absf(dir.x), 0.0001)
	var scale_y := half.y / maxf(absf(dir.y), 0.0001)
	_pos = centre + dir * minf(scale_x, scale_y)
	_angle = dir.angle()
	return true


## See "NOT BEFORE THEY ARE THERE" above. True once `npc` is really standing somewhere, not merely
## spawned this frame and not still walking in from off-camera. Checks the host's own `_walk_in` flag
## first (no race against `_placed`/`is_strolling()` -- see the header measurement), `is_strolling()`
## second as a cheap belt-and-braces for any other future stroll.
func _arrived_and_settled() -> bool:
	if not bool(npc.get("_placed")):
		return false
	var host: Node = npc.visit_host
	if host != null and is_instance_valid(host) and bool(host.get("_walk_in")):
		return false
	return not npc.is_strolling()


## True once today's visit no longer needs pointing to: talked to already, handed in, or they left.
## Reads VisitorSystem only through the live `visit_host` instance npc.gd already holds -- this file
## never names visitor_system.gd by path, same rule the header there asks every caller but conversation.gd
## and npc.gd to follow.
func _talked_or_over() -> bool:
	if npc.npc_id == "norm":
		return true
	var host: Node = npc.visit_host
	if host == null or not is_instance_valid(host) or not host.has_method("record"):
		return true
	var rec: Dictionary = host.call("record")
	if rec.is_empty() or str(rec.get("npc", "")) != npc.npc_id:
		return true
	return bool(rec.get("asked", false)) or bool(rec.get("done", false)) or bool(rec.get("left", false))


func _draw_pip() -> void:
	var text := "%s  %d m" % [label_text, roundi(_dist)]
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, UIStyle.SIZE_SMALL)
	var pill_w := text_size.x + 74.0
	var bob := 1.0 + 0.05 * sin(_pulse * 4.2)
	var a := _alpha
	var rect := Rect2(_pos - Vector2(pill_w, PILL_H) * 0.5 * bob, Vector2(pill_w, PILL_H) * bob)
	# Keep the whole pill (and the room its arrow needs) inside the frame -- same fix pad_compass.gd
	# needed for the wide planets.
	var screen := Vector2(_root.size)
	var pad := Vector2(ARROW + 12.0, 10.0)
	rect.position.x = clampf(rect.position.x, pad.x, maxf(screen.x - rect.size.x - pad.x, pad.x))
	rect.position.y = clampf(rect.position.y, pad.y, maxf(screen.y - rect.size.y - pad.y, pad.y))
	_pos = rect.position + rect.size * 0.5
	if _pill == null:
		_pill = UIStyle.make_pill_style()
	_pill.bg_color = Color(UIStyle.CREAM, a)
	_pill.border_color = Color(UIStyle.CREAM_EDGE, a)
	_pill.shadow_color = Color(UIStyle.SHADOW_COLOR, UIStyle.SHADOW_COLOR.a * a)
	_root.draw_style_box(_pill, rect)
	# Direction arrow on the outward side of the pill -- identical to the rocket's.
	var tip := _pos + Vector2.from_angle(_angle) * (pill_w * 0.5 * bob + ARROW + 5.0)
	var base := _pos + Vector2.from_angle(_angle) * (pill_w * 0.5 * bob + 3.0)
	var perp := Vector2.from_angle(_angle + PI * 0.5) * ARROW
	_root.draw_colored_polygon(PackedVector2Array([tip, base + perp, base - perp]), Color(UIStyle.ORANGE, a))
	# A little dot in the neighbour's own accent colour stands in for the rocket's glyph, at the left of
	# the pill -- deliberately not a rocket, so the two pips read as different things at a glance even
	# before either one's text is legible.
	var g := rect.position + Vector2(26.0, rect.size.y * 0.5)
	_root.draw_circle(g, 9.0, Color(_icon_color, a))
	_root.draw_circle(g, 9.0, Color(UIStyle.TEXT_BROWN, a * 0.5), false, 1.5)
	_root.draw_string(_font, rect.position + Vector2(48.0, rect.size.y * 0.5 + 6.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, UIStyle.SIZE_SMALL, Color(UIStyle.TEXT_BROWN, a))
