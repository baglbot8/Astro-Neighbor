extends Node
## Which control scheme and UI layout the game is running: DESKTOP or MOBILE.
##
## The game ships for both, so this is the ONE place that decides, and both modes must be
## testable on a desktop machine or nobody will ever check the one they are not sitting in front
## of. Detection order:
##   1. `--ui=mobile` / `--ui=desktop` on the command line (used by every showcase and timeline)
##   2. `GameState.settings["ui_mode"]` if the player has forced one
##   3. auto: touchscreen available and no mouse -> MOBILE, else DESKTOP
##
## Read `Platform.is_mobile()` for behaviour, and connect to `mode_changed` if a node has to
## rebuild its layout. Never test `OS.get_name()` directly - a touchscreen laptop and a desktop
## build running the mobile layout for a screenshot both break that assumption.

signal mode_changed(mobile: bool)

enum Mode { DESKTOP, MOBILE }

## Reference safe-area inset in pixels at the 1280x720 design size. Phones with a notch or a
## home indicator report their own; this is the fallback used when the OS reports nothing.
const FALLBACK_SAFE_INSET := 24.0

## ADDED BY THE MOBILE UI BUILDER (R2.10). `--safe-area=L,T,R,B` forces the inset in viewport
## pixels, so a desktop reviewer can prove the mobile layout keeps clear of a notch and a home
## indicator - macOS reports only the menu-bar strip, and a capture of a phone we do not own is
## otherwise impossible. Negative x means "not set".
var _debug_safe := Vector4(-1.0, 0.0, 0.0, 0.0)

var _mode: Mode = Mode.DESKTOP
var _forced: bool = false


func _ready() -> void:
	_mode = _detect()
	_apply_orientation()
	# Printed on every start. On the web build this is the only way to confirm from outside the
	# game which control scheme a real phone actually got — see the browser note in _detect().
	print("[Platform] ui mode: ", mode_name(), " (forced: ", _forced, ")")
	_apply_renderer_parity()
	_apply_quality_profile()


## LOW-POWER PROFILE for phones and the browser build. Reported from a real iPhone: heavy lag,
## the whole picture blurring into white, and the phone heating up. The project ships desktop
## quality — highest soft-shadow filter, 4x MSAA, 16x anisotropic, and a seven-level additive
## glow — and a phone GPU pays for all of it every frame at full screen resolution. This is
## applied ONLY when the renderer is Compatibility or the UI is mobile, so the desktop build
## the player likes is untouched.
func _apply_quality_profile() -> void:
	if not (is_compatibility_renderer() or is_mobile()):
		return
	var vp := get_viewport()
	if vp != null:
		# MSAA is a per-pixel cost across the whole frame and is the single most expensive
		# setting here on mobile hardware.
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	# Soft shadows at filter quality 4 take many taps per pixel. Hard shadows keep the shape
	# (which is what reads on a small screen) at a fraction of the cost.
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	print("[Platform] low-power profile applied (no MSAA, hard shadows)")


## Compatibility is the renderer WITHOUT a RenderingDevice. True for the web export (forced onto
## WebGL2) and for a desktop run started with `--rendering-driver opengl3`, which is how this
## path is reviewed.
func is_compatibility_renderer() -> bool:
	return RenderingServer.get_rendering_device() == null


## Drives the `astro_compat` global shader uniform. See docs/OPEN_ISSUES.md 32: the two
## renderers do not land the albedo multiply in the same place, so the ground shaders correct
## for it themselves. 0.0 on desktop and mobile, where this is a literal no-op.
func _apply_renderer_parity() -> void:
	var compat := is_compatibility_renderer()
	RenderingServer.global_shader_parameter_set(&"astro_compat", 1.0 if compat else 0.0)
	print("[Platform] renderer: ", "Compatibility (parity correction ON)" if compat else "Forward+")


func _detect() -> Mode:
	var want := Mode.DESKTOP
	var decided := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--safe-area="):
			var parts := a.substr(12).split(",", false)
			if parts.size() == 4:
				_debug_safe = Vector4(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))
		elif a == "--ui=mobile" and not decided:
			_forced = true
			want = Mode.MOBILE
			decided = true
		elif a == "--ui=desktop" and not decided:
			_forced = true
			want = Mode.DESKTOP
			decided = true
	if decided:
		return want
	var pref: String = str(GameState.settings.get("ui_mode", "auto"))
	if pref == "mobile":
		return Mode.MOBILE
	if pref == "desktop":
		return Mode.DESKTOP
	# THE WEB BUILD MUST BE ASKED DIFFERENTLY, and getting this wrong makes the game unplayable on a
	# phone. Neither test below works in a browser: Godot's web export always reports FEATURE_MOUSE
	# (the browser platform claims it whatever the hardware is), and its feature tags are "web" and
	# "html5" but never "mobile". An iPhone in Safari therefore falls all the way through to DESKTOP
	# and gets the keyboard HUD with no touch controls at all. Ask the browser instead.
	if OS.has_feature("web"):
		return Mode.MOBILE if _web_touch_is_primary() else Mode.DESKTOP
	# A touchscreen laptop still has a mouse and keyboard, so require the absence of a mouse
	# before assuming a phone.
	if DisplayServer.is_touchscreen_available() and not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE):
		return Mode.MOBILE
	return Mode.MOBILE if OS.has_feature("mobile") else Mode.DESKTOP


## Is the browser's PRIMARY pointer a finger? `(pointer: coarse)` is the standard CSS test for
## exactly that and is what distinguishes a phone or tablet from a touchscreen laptop, which still
## reports `(pointer: fine)` because its mouse is the primary pointer. Falls back to Godot's own
## touchscreen probe if the eval is unavailable. The player can always override this from the
## settings menu, which calls set_mobile().
func _web_touch_is_primary() -> bool:
	var res: Variant = JavaScriptBridge.eval(
		"(navigator.maxTouchPoints > 0 && window.matchMedia('(pointer: coarse)').matches) ? 1 : 0", true)
	if res == null:
		return DisplayServer.is_touchscreen_available()
	return int(res) == 1


func is_mobile() -> bool:
	return _mode == Mode.MOBILE


func is_desktop() -> bool:
	return _mode == Mode.DESKTOP


func mode_name() -> String:
	return "mobile" if is_mobile() else "desktop"


## Switches layout at runtime. Used by the settings menu and by test timelines so a desktop
## machine can capture and review the mobile UI.
func set_mobile(mobile: bool, remember: bool = true) -> void:
	var want: Mode = Mode.MOBILE if mobile else Mode.DESKTOP
	if want == _mode:
		return
	_mode = want
	if remember:
		GameState.settings["ui_mode"] = mode_name()
	_apply_orientation()
	mode_changed.emit(is_mobile())


## ADDED BY THE MOBILE UI BUILDER (R2.10). Forces the safe-area inset (left, top, right, bottom in
## viewport pixels) so a showcase or a review run on a desktop can prove the mobile layout keeps
## clear of a notch and a home indicator. Pass a negative x to go back to the real inset.
func set_debug_safe_area(inset: Vector4) -> void:
	_debug_safe = inset


## ADDED BY THE MOBILE UI BUILDER (R2.10). The three-way UI-mode control in the pause menu's
## Settings writes through here: "auto" has to be expressible, and `set_mobile` can only say one of
## the two concrete modes. Re-runs detection so picking "auto" lands on whatever this machine
## actually is, and emits `mode_changed` so every layout rebuilds without a restart.
func set_ui_mode(mode: String) -> void:
	var m := mode.to_lower()
	if m != "auto" and m != "mobile" and m != "desktop":
		push_warning("Platform.set_ui_mode: unknown mode '%s'" % mode)
		return
	GameState.settings["ui_mode"] = m
	var was := _mode
	_forced = false
	_mode = _detect() if m == "auto" else (Mode.MOBILE if m == "mobile" else Mode.DESKTOP)
	if _mode == was:
		return
	_apply_orientation()
	mode_changed.emit(is_mobile())


## What the player has chosen: "auto" | "desktop" | "mobile" (NOT the resolved mode - use
## `mode_name()` for that). The settings control reads this so "Auto" stays selected.
func ui_mode_setting() -> String:
	return str(GameState.settings.get("ui_mode", "auto"))


## The user asked to play in landscape. Locked on mobile so a phone never flips to portrait
## mid-game; left alone on desktop, where the player owns their window.
##
## Guarded on `OS.has_feature("mobile")` (MOBILE UI BUILDER): a desktop display server has no
## orientation to set and pushed a "Orientation not supported by this display server" warning on
## every single `--ui=mobile` review run, which is exactly the run this mode exists to make easy.
func _apply_orientation() -> void:
	if not is_mobile() or not OS.has_feature("mobile"):
		return
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)


## Safe-area inset in VIEWPORT pixels, so UI can keep clear of a notch or a home indicator.
## Returns zero on desktop. Every mobile HUD element must respect this.
func safe_area_insets() -> Vector4:
	if not is_mobile():
		return Vector4.ZERO
	# `--safe-area=L,T,R,B` (MOBILE UI BUILDER): a forced inset so a desktop reviewer can see the
	# mobile layout keep clear of a notch and a home indicator without owning the phone.
	if _debug_safe.x >= 0.0:
		return _debug_safe
	var win: Rect2i = Rect2i(Vector2i.ZERO, DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0 or win.size.x <= 0:
		return Vector4(FALLBACK_SAFE_INSET, FALLBACK_SAFE_INSET, FALLBACK_SAFE_INSET, FALLBACK_SAFE_INSET)
	var scale: float = float(get_viewport().get_visible_rect().size.x) / float(win.size.x)
	return Vector4(
		maxf(0.0, float(safe.position.x)) * scale,
		maxf(0.0, float(safe.position.y)) * scale,
		maxf(0.0, float(win.size.x - safe.end.x)) * scale,
		maxf(0.0, float(win.size.y - safe.end.y)) * scale)
