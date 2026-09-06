class_name MobileUI
extends RefCounted
## Shared constants and helpers for the MOBILE front end (docs/STYLE_GUIDE.md R2.10).
##
## The game ships two front ends from one build. `Platform` decides which; this file holds the
## numbers the mobile one is built from, so a reviewer can find every magic value in one place
## and so the touch widgets, the HUD and the full-screen panels cannot drift apart.
##
## NEVER test `OS.get_name()`. Everything here routes through `Platform`, which can be forced with
## `--ui=mobile` / `--ui=desktop`, so the layout nobody is sitting in front of is still reviewable.
##
## ---------------------------------------------------------------------------------------------
## THE dp MATH, because "48 dp" has to become a number of GODOT PIXELS somewhere.
## `project.godot` uses `canvas_items` stretch from a 1280x720 base with aspect `expand`, so the
## logical viewport is `window / min(w/1280, h/720)`:
##     2340x1080 -> scale 1.500 -> 1560 x 720 logical
##     2556x1179 -> scale 1.638 -> 1561 x 720 logical
## Both representative phones therefore land on the SAME 720-tall logical viewport, which is why
## every number below is authored in logical pixels and holds on both.
## A 6.7" 2340x1080 panel is ~385 ppi (15.2 px/mm) and ~2.4x density, so:
##     1 logical px = 1.5 physical px = 0.099 mm = 0.63 dp
##     48 dp = 115 physical px = 7.6 mm = 77 logical px
##     9 mm  = 137 physical px        = 91 logical px
## `MIN_TOUCH` is 88, i.e. 55 dp / 8.7 mm - above the 48 dp floor the spec asks for, and the
## visible art is allowed to be smaller than the hit area (see the `*_HIT_R` constants).

# ----------------------------------------------------------------------------- metrics
## Smallest square a finger is ever asked to hit, in logical pixels. See the dp math above.
const MIN_TOUCH := 88.0
## Padding kept between a control and the safe-area edge.
const EDGE := 18.0

## Floating movement stick. `RING_R` is the drawn ring; `TRAVEL` is how far the knob can leave the
## centre before the push counts as 1.0.
const STICK_RING_R := 78.0
const STICK_KNOB_R := 34.0
const STICK_TRAVEL := 62.0
## Below this fraction of TRAVEL the stick reads as "no push" (a resting thumb must not walk).
const STICK_DEADZONE := 0.14
## Fraction of a full push at which the walk becomes a run. Chosen so the speed curve is CONTINUOUS
## across it - see `TouchStick._emit_move`.
const STICK_RUN_AT := 0.60

## Primary (context) button and its Jump / Boost satellites: drawn radius, then hit radius.
const PRIMARY_R := 66.0
const PRIMARY_HIT_R := 78.0
const SAT_R := 44.0
const SAT_HIT_R := 54.0

## Small round HUD buttons (bag / journal / pause) - drawn, then hit.
const HUD_BTN_R := 34.0
const HUD_BTN_HIT_R := 46.0

# ----------------------------------------------------------------------------- transparency (R2.10)
## "Transparency is a requirement, not a nicety." Idle 0.35-0.5, ~0.85 while actually touched, and
## fading further after a few seconds of no input, so the world stays appreciable through them.
## These are the FINAL on-screen opacities: every widget draws its shapes fully opaque and carries
## the whole transparency in `modulate.a`, so the number in this file is exactly the number a
## screenshot measures. (An earlier pass multiplied a per-shape alpha by the layer alpha and the
## controls arrived at 0.28 - visibly wrong against the spec and unreadable over the grass.)
const ALPHA_IDLE := 0.45
const ALPHA_ACTIVE := 0.88
const ALPHA_DIM := 0.24
## The bag / journal / pause discs are HUD chrome, not thumb controls: R2.10's transparency rule
## names "the stick and satellites", and a small icon you have to FIND has to stay findable. They
## sit between the controls and the (opaque) pills, and they do not sink as far when idle.
const ALPHA_CHROME := 0.72
const ALPHA_CHROME_DIM := 0.46
## Seconds of no touch at all before the controls sink from ALPHA_IDLE to ALPHA_DIM.
const IDLE_FADE_DELAY := 4.0
## Alpha per second, going up (a touch snaps them back) and down (a slow settle).
const ALPHA_RATE_UP := 9.0
const ALPHA_RATE_DOWN := 1.6

# ----------------------------------------------------------------------------- camera by touch
## Drag-to-orbit and pinch-to-zoom go through `CameraRig`'s public touch API - `add_look_px` and
## `add_zoom` - which the player builder added for this front end. The rig owns the pixel-to-degree
## constants, the sensitivity setting, both invert toggles and the pitch clamp, and it owns the
## MOBILE FRAMING too (8.6 m at 34 deg against the desktop 7.4 m at 28 deg), so there is
## deliberately no distance or degrees-per-pixel number on this side to drift out of step.
##
## Fraction of the viewport width that belongs to the movement stick (left) - the rest of the
## screen is camera drag. Landscape puts both thumbs over ground that carries no information.
const STICK_ZONE_W := 0.42
## The stick zone only starts this far down the screen, so the HUD row at the top stays reachable.
const STICK_ZONE_TOP := 0.30
## Camera drag ignores the top strip, where the stardust / clock / buttons live.
const CAM_ZONE_TOP := 0.24

# ----------------------------------------------------------------------------- panels on mobile
## Type is scaled up on a phone held at arm's length. Applied by duplicating the shared Theme.
const FONT_SCALE := 1.2
## Button types whose vertical padding is opened up so a pill clears MIN_TOUCH.
const BIG_BUTTON_TYPES: PackedStringArray = ["Button", "Pill", "PillPrimary", "PillBlue", "PillOrange", "Choice"]
const SMALL_BUTTON_TYPES: PackedStringArray = ["PillSmall", "Tab", "TabActive"]
const BIG_BUTTON_MARGIN := Vector2(34.0, 26.0)
const SMALL_BUTTON_MARGIN := Vector2(24.0, 15.0)

static var _platform: Node
static var _theme: Theme

# ----------------------------------------------------------------------------- platform access
## The `Platform` autoload, looked up once. Static so widgets can ask without holding a reference
## (UIStyle uses the same trick for AudioManager) - and so this file still loads in a tool script.
static func _plat() -> Node:
	if is_instance_valid(_platform):
		return _platform
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return null
	_platform = loop.root.get_node_or_null("Platform")
	return _platform


## True when the game is running its mobile front end (see `Platform`).
static func is_mobile() -> bool:
	var p := _plat()
	return p != null and bool(p.call("is_mobile"))


## Safe-area inset in viewport pixels: left, top, right, bottom. Zero on desktop.
static func safe_area() -> Vector4:
	var p := _plat()
	return p.call("safe_area_insets") if p != null else Vector4.ZERO


## Connects `cb` to `Platform.mode_changed` (no-op when the autoload is missing).
static func on_mode_changed(cb: Callable) -> void:
	var p := _plat()
	if p == null:
		return
	var sig: Signal = p.get("mode_changed")
	if not sig.is_connected(cb):
		sig.connect(cb)


# ----------------------------------------------------------------------------- theme
## The shared Theme with mobile type sizes and mobile button padding. Built once by scaling the
## desktop theme rather than shipping a second .tres, so a palette change in `build_theme.gd`
## can never leave the two front ends looking different.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var base := UIStyle.theme()
	# Shallow duplicate: the font-size table is copied by value, StyleBoxes are shared references,
	# so any box we actually change is duplicated first (below).
	var t := base.duplicate() as Theme
	t.default_font_size = int(round(float(base.default_font_size) * FONT_SCALE))
	for type in t.get_font_size_type_list():
		for n in t.get_font_size_list(type):
			var v := t.get_font_size(n, type)
			if v > 4:  # "Card" is deliberately 1 px (the card draws its own content)
				t.set_font_size(n, type, int(round(float(v) * FONT_SCALE)))
	for type in BIG_BUTTON_TYPES:
		_pad_button(t, type, BIG_BUTTON_MARGIN)
	for type in SMALL_BUTTON_TYPES:
		_pad_button(t, type, SMALL_BUTTON_MARGIN)
	_theme = t
	return _theme


## Opens up every state's stylebox on one Button type so the pill grows to a thumb-sized target.
static func _pad_button(t: Theme, type: String, margin: Vector2) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		if not t.has_stylebox(state, type):
			continue
		var sb := t.get_stylebox(state, type)
		if sb == null:
			continue
		var box := sb.duplicate() as StyleBox
		box.content_margin_left = margin.x
		box.content_margin_right = margin.x
		box.content_margin_top = margin.y
		box.content_margin_bottom = margin.y
		if state == "pressed" or state == "hover_pressed":
			box.content_margin_top = margin.y + 2.0
			box.content_margin_bottom = margin.y - 2.0
		t.set_stylebox(state, type, box)


## Gives `control` the mobile theme when the mobile front end is active, and puts its own theme
## back when it is not. Call it at the TOP of a panel's `_ready`, before it builds its children, so
## minimum sizes are measured once - and again from a `Platform.mode_changed` handler.
##
## REVERSIBLE on purpose: the UI-mode setting can be flipped at runtime, and a panel that could
## only ever go one way would be stuck at phone type on a computer for the rest of the session.
## The scene's original Theme is remembered the first time through.
static func apply_theme(control: Control) -> void:
	if control == null:
		return
	if not control.has_meta("base_theme"):
		control.set_meta("base_theme", control.theme)
	control.theme = theme() if is_mobile() else (control.get_meta("base_theme") as Theme)


## Scales a number for the current front end (`d` on desktop, `m` on mobile).
static func pick(d: float, m: float) -> float:
	return m if is_mobile() else d


## Interact prompts are authored for a keyboard and some of them carry a key hint - the placement
## controller's is "Place - Q/R turn". On a phone there is no Q or R, and the rotate buttons are on
## screen anyway, so everything from the first separator is dropped. Desktop text is untouched.
## (If `src/decorations/placement_controller.gd` ever splits the verb from the hint properly this
## can go - see the report.)
static func clean_prompt(text: String) -> String:
	if not is_mobile():
		return text
	var cut := text.find(" · ")
	return text.substr(0, cut).strip_edges() if cut > 0 else text


# ----------------------------------------------------------------------------- test hooks
## Synthesises a real press-and-release at `pos` (viewport coordinates) and pushes it through the
## ordinary input pipeline, so a Director timeline can exercise a Control the way a FINGER does.
##
## On a phone this is the exact path a touch takes: Godot's `emulate_mouse_from_touch` (on by
## default) turns finger 0 into these events, which is how every Button, tab and card in the
## full-screen panels is tappable without any of them knowing about touch. A timeline cannot
## deliver either - `Input.action_press` sets action state but emits no InputEvent - so this is how
## "no screen requires a mouse" gets PROVED rather than asserted.
## `pos` is in VIEWPORT (canvas) coordinates - the 1560x720 logical space every Control lives in.
## `Viewport.push_input` maps an incoming event into that space with the inverse of the stretch
## transform, so the event has to be authored in WINDOW pixels or a tap in a 2340x1080 window lands
## about a third of the way up and to the left of where it was aimed. (It did, the first time.)
static func synth_tap(pos: Vector2) -> void:
	var loop := Engine.get_main_loop() as SceneTree
	if loop != null and loop.root != null:
		pos = loop.root.get_final_transform() * pos
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.position = pos
	down.global_position = pos
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = pos
	up.global_position = pos
	up.pressed = false
	Input.parse_input_event(up)


# ----------------------------------------------------------------------------- drawing helpers
## A soft round control plate: filled disc, darker rim, and a subtle inner highlight arc so the
## button reads as a rounded cap rather than a flat circle. Alpha is carried by the control's
## `modulate`, so one number (see ALPHA_*) controls how much world shows through.
static func draw_disc(ci: CanvasItem, center: Vector2, radius: float, fill: Color, edge: Color,
		rim: float = 4.0, alpha: float = 1.0) -> void:
	ci.draw_circle(center, radius, Color(fill, alpha))
	ci.draw_arc(center, radius - rim * 0.5, 0.0, TAU, 64, Color(edge, alpha), rim, true)
	ci.draw_arc(center, radius - rim * 1.9, deg_to_rad(200.0), deg_to_rad(340.0), 24,
		Color(UIStyle.WHITE, 0.55 * alpha), 2.0, true)


## Chunky rounded chevron / arrow glyph used by the Jump and rotate buttons.
static func draw_chevron(ci: CanvasItem, center: Vector2, span: float, color: Color,
		rotation_rad: float = 0.0) -> void:
	var pts := PackedVector2Array([
		Vector2(-span, span * 0.42), Vector2(0.0, -span * 0.5), Vector2(span, span * 0.42)])
	var out := PackedVector2Array()
	for p in pts:
		out.append(center + p.rotated(rotation_rad))
	ci.draw_polyline(out, color, maxf(3.0, span * 0.30), true)
