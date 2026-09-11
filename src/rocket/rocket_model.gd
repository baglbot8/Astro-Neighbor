class_name RocketModel
extends Node3D
## The player's rocket: a chunky retro cartoon rocket, 3.2 m from the pad to the tip of the nose.
##
## Shape language (docs/STYLE_GUIDE.md "Shape language corrections"): the hull is a *straight*
## cylinder with crisp shoulder rings and flat panel bands, the fins are flat chamfered plates and
## the nose is a tapered ogive with a hard collar at its base — a structured silhouette, not a stack
## of spheres. Origin sits at the ground contact point, the model faces -Z (hatch, porthole and
## ladder are all on the -Z side) and +Y is up, matching the character/prop convention.
##
## Colour blocking (STYLE_GUIDE "Colour-block the clothing like AC"): the hull is FOUR readable
## blocks, not one near-white value zone — coral-red nose cone, cream barrel, a soft teal belt
## band + shoulder band, and a dark slate engine skirt with slate fin feet (all softened
## 2026-09-11 to pass the palette gates measured on the rocket's own pixels - see the palette
## note). The darks come from real albedo blocks and from a low `shade_floor` on the big cream
## surfaces (darkness from LIGHT, not from muddy albedo), and the cream carries almost no
## specular/rim so it stops clipping to white.
##
## Public API:
##   set_engine(on, power)   flame + smoke + engine light on/off (power scales the burn)
##   set_flame_scale(f)      0 = no flame, 1 = launch flame, >1 = boost
##   open_hatch() / close_hatch()   swings the door on its vertical hinge
##   set_beacon(on)          nose beacon blink
##   set_ladder_deployed(b)  boarding ladder down (parked) / stowed (in flight)
##   hatch_point()           world position a boarding astronaut walks into
##   engine_point()          world position of the nozzle mouth (dust, sfx)
##   triangle_count()        tris in the shipped model (ARCHITECTURE §10 budget check)
##   refresh_finish()        re-read the finish stage and repaint (wired to EventBus part changes)
##   set_finish_stage(n)     paint finish n now: 0 rusty after the crash .. 4 clean .. 5 gold
##   finish_stage()          the finish stage painted right now
##   set_review_mask(on)     REVIEW ONLY: flat magenta hull, for per-region palette scoring
##
## Finish review hook: the user arg `--rocket-finish=N` (after the `--`) pins every rocket in the
## run to stage N (0-5) and ignores part changes. For captures only; nothing in the game passes it.
##
## Finish, in one place (details at each constant): the paint is one spliced pass in the hull's toon
## shader (MaterialLib.rocket_finish_shader) - dust and soot LAYERS, a scorch, rust thresholded on one
## fixed noise field, and at stage 5 the gold's reflection bands. Every finish-painted part has its
## node transform baked into its vertices (_bake_to_hull_space), so that noise is sampled in hull
## space on every part. The stage 4-5 glints are one merged billboard mesh (MaterialLib.rocket_glint)
## that renders on both renderers.

const SMOKE_SHADER := preload("res://src/rocket/smoke_puff.gdshader")
const FLAME_SHADER := preload("res://src/rocket/rocket_flame.gdshader")
## The `set_flame_intensity` value that means "full planet-side burn". Everything else is a ratio
## of it, so the shader's own `intensity` uniform stays a clean 0..1 knob.
const GROUND_FLAME_REF := 1.15
const TOTAL_HEIGHT := 3.2
const HULL_R := 0.62
const HATCH_HALF_ANGLE := deg_to_rad(26.0)
const HATCH_Y0 := 0.60
const HATCH_Y1 := 1.42
const HATCH_OPEN_DEG := 105.0
const PORTHOLE_Y := 1.90
const PORTHOLE_R := 0.24
## Fins sit at +/-60 deg from the hatch centreline and one dead astern. The old [90, 210, 330] put a
## blade straight down the -Z face: it speared the ladder, crossed the doorway and the opening door
## swept through it (rocket critic, ~/.astro_captures/crit_zoom/zoom_rocket_front.png).
const FIN_ANGLES_DEG: Array[float] = [30.0, 150.0, 270.0]
const NOZZLE_MOUTH_Y := 0.06
const BEACON_Y := 3.26
const RIVET_RING_Y := 0.66
const RIVETS_PER_RING := 6
## Rivets are small bumps, not features: past this distance they only ever read as dirt speckle, so
## the whole ring switches off (rocket critic: "rivets read as dark pentagons/dirt at close range").
const RIVET_VISIBLE_M := 15.0
## Segment counts. Kept deliberately low: ARCHITECTURE §10 budgets a prop at 2k tris.
const SEG_BODY := 16
const SEG_RING := 16
const SEG_SMALL := 10

## Palette — four readable colour blocks. CREAM is a clean, cheerful cream (the previous #bcb6a7
## "darkened" hull just read as mud and still rendered at ~0.9 luma); the highlights are pulled out
## of the LIGHTING instead, see `HULL_SHADE_FLOOR` and the near-zero spec/rim below.
# REVISION 2 pass (docs/STYLE_GUIDE.md R2.6): the hull red and teal were S 0.63 / 0.61, over the
# "no dominant swatch above S 0.60" line, and the rocket is a hero prop that fills a good part of
# every launch frame. Pulled toward their own pastels - lighter and softer, same hue, same
# identity - not darkened toward brown. The emissive accents (beacon, engine, cabin) keep their
# saturation: R2.6 allows a bright colour as a lamp.
#
# FINISH pass (2026-09-11), measured PER REGION - only the rocket's own pixels, from a flat-magenta
# mask render of the same camera (docs/OPEN_ISSUES.md 38). The R2.6 numbers above were albedo
# swatches; rendered, the rocket still failed: at the pad, noon, the red's shade side came out
# #cd2a33 (S 0.79), 17.5% of the rocket sat above S 0.68, region sat p90 0.775. The cause is the
# one toon_soft documents (albedo applied twice), so RENDERED chroma is roughly albedo chroma
# SQUARED and a dark side goes far more saturated than its swatch. Pulled once more toward their own
# pastels, hue kept, chosen from two sweeps in the real scene (both renderers, noon and dusk):
#   red  #e07069 -> #d0968f, band #ad514e -> #a6756f   the only red that kept dusk under S 0.60
#   teal #62a7cc -> #88b0c2                            its terminator rendered #4284a3 (S 0.59)
#   navy #3a4459 -> #434650, dark #262d3c -> #2e3036   THE big one: the skirt in shade rendered
#     near-black #080c23 at S 0.75, and under Compatibility it alone pushed region sat p90 to 0.80.
#     At V 0.14 any hue is S 0.7, so a dark block has to be nearly neutral ("dark does not mean
#     saturated", R2.6). Web far-view p90 0.797 -> 0.576 with this navy; it still reads as the dark
#     slate skirt in the frames.
const CREAM := Color("#e9dec5")
const CREAM_SHADE := Color("#c2b596")
const TEAL := Color("#88b0c2")
const TEAL_DARK := Color("#417994")
#   Round 2 (critic, frozen-rocket close view, Forward+ noon): the CLEAN skirt in the hull's own
#   cast shadow still rendered #0f0c20 at S 0.61 over 8.4% of the rocket - lit by the space sky's
#   blue-violet ambient alone, a dark neutral takes the ambient's hue. Lifted x1.35 in linear, same
#   near-neutral hue: #434650 -> #4f515b, #2e3036 -> #3b3d44. It now renders #19142a S 0.50, the
#   S > 0.58 / V < 0.25 share falls 8.4% -> 0.8%, and it still reads as the dark slate block.
const NAVY := Color("#4f515b")
const NAVY_DARK := Color("#3b3d44")
const RED := Color("#d0968f")
const RED_DARK := Color("#a6756f")
## The fins' own red. They shared the nose's material, but a nose faces the noon sun while a fin is a
## vertical plate the sun grazes, so the fin sat in the ramp's mid band, where the squared albedo is
## darkest and most saturated: it rendered #883339-#c14b52 at S 0.61-0.63 over 9-15% of the rocket
## at close range on Forward+ (critic), with the nose fine at S 0.28. Same hue, softer chroma, and a
## higher shade floor so the terminator band on the plate stops going deep red. Swept in the real
## scene: the nose's red with only the floor raised (0.60) still rendered #cb5456 S 0.58 over 10% of
## the rocket; this one renders #c1585e S 0.54 on Forward+ and #d8928c S 0.35 on the web renderer,
## with the S > 0.58 share at 0.5%.
const RED_FIN := Color("#cb9d97")
const FIN_SHADE_FLOOR := 0.52
const FIN_SHADE := 0.40
const METAL := Color("#8d97a6")
const METAL_DARK := Color("#4d5462")
const GLASS_TINT := Color("#8fd4ff")
const CABIN_GLOW := Color("#ffd08a")
const ENGINE_GLOW := Color("#ff9a4d")
const BEACON_COLOR := Color("#ff5d5d")
## Shade floor for the big cream surfaces. The toon shader's default is 0.62, which keeps the shade
## side at 62% of full brightness — on a 0.94-value cream that is still a blown highlight. 0.34 gives
## the hull a genuine dark side without touching the albedo hue.
const HULL_SHADE_FLOOR := 0.34
const DECK_SHADE_FLOOR := 0.38

## ---- Finish (docs/CORE_LOOP.md "Changed after the build plan": the finish shows progress) ----
## Stage = CampaignData.finish_stage(): 0 straight after the crash, 1-3 one part each and each one
## cleaner, 4 clean with a sparkle (the everyday clean rocket, and what every old save and every
## Director timeline without --campaign gets), 5 gold instead of the cream "white". Parts sit
## inside the hull and are never drawn (same CORE_LOOP section); only the paint changes, so no
## triangles move.
## The dirt is ONE spliced pass in the hull's toon shader (MaterialLib.rocket_finish_shader).
const FINISH_STAGE_COUNT := 6
const FINISH_CLEAN := 4
const FINISH_GOLD := 5
const FINISH_ARG := "--rocket-finish="
## Grime, bleach and scorch scale with wear; stage 4 and 5 are 0, which skips the pass entirely.
const FINISH_WEAR: Array[float] = [1.0, 0.70, 0.45, 0.22, 0.0, 0.0]
## Rust threshold per stage on the shader's noise field, chosen by COVERAGE rather than by eye:
## each is the measured quantile of that field over the cream body (400k area-uniform samples of the
## exact float32 maths, mean 0.504, std 0.110, the mean of the near and far octave) for 28 / 15 / 7 /
## 2.5 % rust, less the 0.015 half-width of the shader's 0.03 edge ramp. So each part roughly halves
## the rust. 2.0 = none. Re-measured for round 2's quieter fine octave (0.2 -> 0.12).
const FINISH_RUST_THR: Array[float] = [0.551, 0.603, 0.655, 0.713, 2.0, 2.0]
## Rust looks GREY as a swatch on purpose: rendered chroma is about albedo chroma squared (see the
## palette note above), and the first rust (#a06a4c, S 0.52) rendered as dark maroon at S 0.73.
## The edge (S 0.29) renders as orange-brown rust at S 0.55-0.58, picked over three real-scene
## sweeps: the redder #b08a6c rendered S 0.63 close up, #b39278 sat at S 0.60-0.62 on the shaded
## lower fins in the far view on the web renderer. The dark core is kept near-neutral (S 0.18, was
## #8b7465 S 0.27) for the navy's reason - dark chroma renders hot - because the S > 0.60 pixels
## left on a crashed rocket were the rust in shade on the lower fins; the lit edge carries the rust
## colour, and close up it still reads as rust.
const RUST := Color("#b2957e")
const RUST_DEEP := Color("#8b7c72")
## The dirt is two LAYERS mixed over the paint (MaterialLib _RF_PASS explains why not a multiply):
## DUST for the mottle and the runs, SOOT for the engine soot and the crash scorch. Both are picked
## for where they RENDER. The slate skirt sits in the hull's own cast shadow, lit only by the space
## sky's blue-violet ambient, and any surface taken below about V 0.15 there renders S > 0.60: the
## first pass's #3d3c40 soot at 0.75 made the crashed skirt #050512-#0e0b1d at S 0.62-0.73.
## Swept (three dust/soot pairs, both renderers, noon): with these the crashed rocket's S > 0.58 /
## V < 0.25 share is 0.0% at every standpoint (was 4-7%), and the soot sits a little above the lifted
## slate, so on the skirt it greys rather than darkens.
const DUST := Color("#8a857d")
const SOOT := Color("#686663")
const GRIME_DEPTH := 0.62
## The flank that scraped the ground: front-right as you walk up to the hatch, so it is in view.
const SCORCH_DIR := Vector2(-0.6, -0.8)
## Stage 5. Only the cream "white" turns gold - the red nose, teal bands and slate skirt keep the
## four colour blocks, so the gold rocket is still this rocket.
## Same squared-chroma rule: the first gold (#d9bb6c, S 0.50) rendered brassy at S 0.66-0.68. This
## one (S 0.40) renders S 0.53. On its own it read pale butter-yellow at gameplay distance (critic):
## at noon the whole hull side sits in one band of the toon ramp, so lighting gives it no value
## structure. Polished metal gets that from what it reflects, so the gold carries two reflection
## bands (MaterialLib _RF_PASS): a pale warm highlight and a darker amber-olive band, placed by the
## view-space normal's x, so they slide over the hull as the camera moves. The dark band is kept
## near-neutral for the navy's reason (dark chroma renders hot) and still reads amber against gold.
const GOLD := Color("#dcc284")
const GOLD_SHADE := Color("#bb9e62")
## Swept in the real scene: a dark band of #8e8563 (S 0.30) rendered amber at S 0.57 - the squared
## albedo again - and pushed the web renderer's near view to a dominant swatch of 0.61. #7e7a66 (S
## 0.19, and darker, for MORE value contrast) renders an olive-bronze band: near-view dominant 0.543
## on Forward+ and 0.450 on the web (worst k-means seed 0.548 / 0.531); with no bands the same
## frames read the flat butter-yellow the critic failed.
const GOLD_HI := Color("#efe3bd")
const GOLD_LO := Color("#7e7a66")
const GOLD_HI_BAND := Vector2(0.20, 0.50)
const GOLD_LO_BAND := Vector2(-0.62, -0.16)
## The toon shade side: a warm olive instead of the shared lavender tint (which greyed the gold's
## dark side toward mauve at dusk) and a deeper floor, so the terminator reads as metal turning away.
const GOLD_SHADE_TINT := Color(0.74, 0.68, 0.50)
const GOLD_SHADE_FLOOR := 0.26
## sd_metal's brushed grain: at the default scale and strength its 320 cycles/m aliased into coarse
## one-pixel vertical streaks that read as straw close up (critic). Finer, and a third of the contrast.
const GOLD_GRAIN_SCALE := 2.0
const GOLD_GRAIN_STRENGTH := 0.35
const GOLD_SPEC := 0.30
const GOLD_SPEC_SIZE := 70.0
const GOLD_RIM := 0.18
const GOLD_RIM_COLOR := Color("#f2dfa6")
## toon_soft's own rim_color default, restored on every stage that is not gold.
const TOON_RIM_COLOR := Color(1.0, 0.97, 0.9)
## Stage 4-5 sparkle glints (star.gdshader's four-point twinkle, MaterialLib.rocket_glint).
const GLINT_WHITE := Color("#fff8ea")
const GLINT_GOLD := Color("#ffeec0")
const GLINT_INTENSITY := 1.4
const GLINT_SIZE := 0.34
## softness 0 shrinks star.gdshader's soft disc to a falloff, so the four points carry the shape: at
## 0.62 the disc filled 62% of the quad and every glint read as a white blob, not a sparkle.
const GLINT_OPTS := {"points": 1.0, "blink": 1.0, "blink_speed": 2.3, "softness": 0.0, "core": 0.07}
## Where the glints sit: (degrees from the hatch (-Z) toward +X, height, radius) - the
## curved_panel convention. Spread round the whole hull so a few face the camera from any side;
## the hull hides the rest, because the sprite depth-tests.
const GLINTS: Array[Vector3] = [
	Vector3(-38.0, 2.02, HULL_R + 0.06),
	Vector3(24.0, 2.74, 0.52),
	Vector3(62.0, 1.30, HULL_R + 0.06),
	Vector3(-30.0, 0.56, 0.74),
	Vector3(17.0, 2.10, HULL_R + 0.10),
	Vector3(150.0, 1.55, HULL_R + 0.06),
	Vector3(-140.0, 2.55, 0.55),
	Vector3(100.0, 0.72, HULL_R + 0.06),
]

## Flame plume. A *mesh* teardrop (crisp cartoon silhouette) painted by rocket_flame.gdshader —
## blue-white throat, orange body, deep orange-red tip — with a blue-white collar flared proud of it
## at the throat, plus a few particle sparks. The old pure-particle plume measured mean rgb
## (0.94, 0.68, 0.58) — salmon and far too thin (rocket critic); the nested-shell mesh plume that
## replaced it rendered as one flat pale-yellow fill, because opaque shells hide what is inside them.
const PLUME_LEN := 1.0
const PLUME_R := 0.44

## Base omni ranges (metres at scale 1). Scale them with set_light_range_scale() when the model is
## shrunk — a 5 m beacon range on a 2 m map globe would wash the whole planet warm.
const CABIN_LIGHT_RANGE := 2.6
const BEACON_LIGHT_RANGE := 5.0
const ENGINE_LIGHT_RANGE := 7.0

var _hull_root: Node3D
var _hatch_pivot: Node3D
var _hatch_tween: Tween
var _flame: Node3D
var _plume_outer: MeshInstance3D
var _plume_collar: MeshInstance3D
var _plume_mats: Array[ShaderMaterial] = []
var _plume_caps: Array[float] = []
var _licks: GPUParticles3D
var _flame_glow: MeshInstance3D
var _smoke: GPUParticles3D
var _engine_light: OmniLight3D
var _cabin_light: OmniLight3D
var _beacon_mesh: MeshInstance3D
var _beacon_light: OmniLight3D
var _beacon_mat: ShaderMaterial
var _engine_mat: ShaderMaterial
var _rivets: MultiMeshInstance3D
var _ladder: Node3D
var _hatch_open := false
var _engine_on := false
var _engine_power := 0.0
var _flame_scale := 0.0
var _beacon_on := true
var _smoke_enabled := true
var _flame_mats: Array[ShaderMaterial] = []
var _flame_intensity := 1.15
## Scales the nozzle glow + engine light with `set_flame_intensity` (1.0 on a planet, ~0.35 in space).
var _engine_energy := 1.0
var _time := 0.0
## Every hull material the finish repaints, and the look each was built with (restored at stage 4).
var _finish_mats: Array[ShaderMaterial] = []
var _finish_base: Array[Dictionary] = []
var _finish_stage := -1
var _sparkle: MeshInstance3D
## GeometryInstance3D -> its real material_override while the review mask is on.
var _mask_saved: Dictionary = {}
var _mask_mat: StandardMaterial3D


func _ready() -> void:
	if _hull_root == null:
		_build()
	refresh_finish()


func _enter_tree() -> void:
	if not EventBus.rocket_parts_changed.is_connected(_on_rocket_parts_changed):
		EventBus.rocket_parts_changed.connect(_on_rocket_parts_changed)
	if not EventBus.campaign_changed.is_connected(refresh_finish):
		EventBus.campaign_changed.connect(refresh_finish)
	if _hull_root != null:
		refresh_finish()


func _exit_tree() -> void:
	if EventBus.rocket_parts_changed.is_connected(_on_rocket_parts_changed):
		EventBus.rocket_parts_changed.disconnect(_on_rocket_parts_changed)
	if EventBus.campaign_changed.is_connected(refresh_finish):
		EventBus.campaign_changed.disconnect(refresh_finish)


func _process(delta: float) -> void:
	_time += delta
	if _beacon_mat != null:
		var blink := 0.0
		if _beacon_on:
			blink = pow(maxf(sin(_time * 2.6), 0.0), 6.0)
		_beacon_mat.set_shader_parameter("emission_strength", 0.35 + 5.0 * blink)
		_beacon_light.light_energy = 0.15 + 2.4 * blink
	if _engine_mat != null:
		var flicker := 1.0 + 0.16 * sin(_time * 34.0) + 0.09 * sin(_time * 61.0 + 1.3)
		var burn := _flame_scale * _engine_power
		_engine_mat.set_shader_parameter("emission_strength", 0.25 + 5.5 * burn * flicker)
		_engine_light.light_energy = 4.5 * burn * flicker * _engine_energy
		_engine_light.visible = burn > 0.01
	if _flame != null and _flame.visible:
		_animate_plume()


# ============================================================================= public API
## Turns the engine on/off. `power` (0..1.4) scales flame length, light and smoke output.
func set_engine(on: bool, power: float = 1.0) -> void:
	_engine_on = on
	_engine_power = clampf(power, 0.0, 1.6)
	_licks.emitting = on
	_smoke.emitting = on and _smoke_enabled
	_flame_glow.visible = on
	if on and _smoke_enabled:
		# Buoyancy along the model's own up so exhaust puffs keep drifting instead of freezing in
		# mid-air once the engine cuts (rocket critic: "two smoke puffs hang frozen after landing").
		var pm := _smoke.process_material as ParticleProcessMaterial
		pm.gravity = global_basis.y.normalized() * 0.9
	if not on:
		set_flame_scale(0.0)
	elif _flame_scale <= 0.001:
		set_flame_scale(_engine_power)


## Scales the flame plume (0 = out, 1 = full launch burn). Tween this for a growing ignition.
func set_flame_scale(f: float) -> void:
	_flame_scale = maxf(f, 0.0)
	var s := maxf(_flame_scale, 0.0001)
	# Past 1.0 the plume gets fatter as well as longer, so an ignition burn on the pad (where the
	# jet is cut short by the deck) still reads as a big flame instead of a thin orange line.
	var girth := lerpf(0.62, 1.0, minf(s, 1.0)) + maxf(s - 1.0, 0.0) * 0.30
	_flame.scale = Vector3(girth, s, girth)
	_flame_glow.scale = Vector3.ONE * lerpf(0.32, 0.95, minf(s, 1.2))
	var pm := _smoke.process_material as ParticleProcessMaterial
	pm.initial_velocity_max = 2.2 + 3.4 * s
	_flame.visible = _flame_scale > 0.01


## Current plume scale (what `set_flame_scale` last set). Read across a scene cut so the far side
## can ease the plume from the length it had rather than snapping to its own.
func flame_scale() -> float:
	return _flame_scale


## Swings the door open on its hinge (with the door sfx handled by the caller).
func open_hatch() -> void:
	_swing_hatch(true)


## Swings the door shut.
func close_hatch() -> void:
	_swing_hatch(false)


func is_hatch_open() -> bool:
	return _hatch_open


## Boarding ladder: down while the rocket is parked on a pad, stowed the moment it leaves the
## ground. Flying an interplanetary cruise with the ladder hanging off the hull and dipping into
## the exhaust is exactly the sort of thing a critic screenshots.
func set_ladder_deployed(down: bool) -> void:
	if _ladder == null:
		return
	_ladder.visible = down


## Brightness of the additive flame sprites and the emissive cap on the mesh plume. The default
## reads against a bright daytime sky; the space map turns it down because additive sprites stack to
## white against a dark starfield and a fully-lit plume blooms over the whole rocket.
func set_flame_intensity(f: float) -> void:
	_flame_intensity = f
	# index 0 is the throat blob (kept soft), the rest are spark sprites.
	for i in _flame_mats.size():
		_flame_mats[i].set_shader_parameter("intensity", f * (0.16 if i == 0 else 0.8))
	# 0.55 rather than 0.34 at the bottom: the painted ramp carries its own structure now, so it no
	# longer needs to be dimmed into the floor to stop it blooming into a white disc — and below
	# ~0.5 it stops reading as fire against a starfield and goes a dull grey-orange.
	var k := clampf(f / GROUND_FLAME_REF, 0.55, 1.0)
	for i in _plume_mats.size():
		_plume_mats[i].set_shader_parameter("intensity", k)
		_plume_mats[i].set_shader_parameter("emission_cap", maxf(_plume_caps[i] * k, 0.55))
	# The nozzle throat and the engine's point light have to come down with it, or a dimmed plume
	# still sits inside a big red bloom against the starfield.
	if _engine_mat != null:
		_engine_mat.set_shader_parameter("emission_cap", maxf(1.9 * k, 0.4))
	_engine_energy = k


## Turns the grey exhaust smoke on/off (the space map flies with it off — no atmosphere).
func set_smoke_enabled(on: bool) -> void:
	_smoke_enabled = on
	_smoke.emitting = on and _engine_on


## Enables/disables the blinking nose beacon.
func set_beacon(on: bool) -> void:
	_beacon_on = on


## Scales the reach of the rocket's own point lights (cabin, beacon, engine). The solar-system map
## draws the rocket at ~1/3 scale next to 2 m globes, so it shrinks them to keep the planets' own
## lighting clean.
func set_light_range_scale(f: float) -> void:
	if _cabin_light == null:
		return
	_cabin_light.omni_range = CABIN_LIGHT_RANGE * f
	_beacon_light.omni_range = BEACON_LIGHT_RANGE * f
	_engine_light.omni_range = ENGINE_LIGHT_RANGE * f


## Turns off the cabin and beacon point lights (their emissive materials still glow). The space map
## uses this so a 1 m rocket does not tint a whole miniature planet.
func set_local_lights_enabled(on: bool) -> void:
	if _cabin_light == null:
		return
	_cabin_light.visible = on
	_beacon_light.visible = on


## World position an astronaut walks into when boarding (the middle of the doorway).
func hatch_point() -> Vector3:
	return to_global(Vector3(0.0, (HATCH_Y0 + HATCH_Y1) * 0.5 - 0.25, -HULL_R * 0.35))


## World position of the nozzle mouth (ground dust, ignition sfx).
func engine_point() -> Vector3:
	return to_global(Vector3(0.0, NOZZLE_MOUTH_Y, 0.0))


## Triangles in the built model. `include_fx` adds the flame plume meshes (hidden whenever the
## engine is off) and the stage 4-5 sparkle glints (hidden below stage 4, and billboards, not hull).
## Used by the showcase's `--tris` report against the §10 2k prop budget.
func triangle_count(include_fx: bool = false) -> int:
	var total := 0
	for n in _walk(self):
		if not include_fx and (n == _sparkle or (_flame != null and _flame.is_ancestor_of(n))):
			continue
		if n is MultiMeshInstance3D:
			var mmi := n as MultiMeshInstance3D
			total += mesh_triangles(mmi.multimesh.mesh) * mmi.multimesh.instance_count
		elif n is MeshInstance3D:
			total += mesh_triangles((n as MeshInstance3D).mesh)
	return total


## Triangles in any mesh, indexed or not. Public so the showcase's `--tris` report can use it.
static func mesh_triangles(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			var verts: Variant = arr[Mesh.ARRAY_VERTEX]
			if verts is PackedVector3Array:
				t += (verts as PackedVector3Array).size() / 3
	return t


static func _walk(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_walk(c))
	return out


## A toon material with an explicit `shade_floor`, so a surface can be given a genuinely dark shade
## side without muddying its albedo (STYLE_GUIDE: "darkness must come from LIGHT and SHADOW").
## Shared with the landing pad.
static func deep_toon(color: Color, opts: Dictionary, floor_level: float) -> ShaderMaterial:
	var m := MaterialLib.toon(color, opts).duplicate() as ShaderMaterial
	m.set_shader_parameter("shade_floor", floor_level)
	return m


# ============================================================================= finish
## Re-reads which finish to paint and paints it: the `--rocket-finish=N` review pin if this run
## passed one, else CampaignData.finish_stage() - which is 4, the clean rocket, whenever the story's
## gates are off (an old save, a finished story, a Director timeline without --campaign). Wired to
## EventBus.rocket_parts_changed and campaign_changed, so fitting a part repaints the hull live.
func refresh_finish() -> void:
	var forced := _forced_finish_arg()
	var stage := forced if forced >= 0 else CampaignData.finish_stage()
	if stage != _finish_stage:
		var source := "--rocket-finish" if forced >= 0 else "CampaignData"
		print("[RocketModel] finish stage %d (%s)" % [stage, source])
	set_finish_stage(stage)


## Paints finish `stage` (clamped to 0-5) immediately. Public so a cutscene can hold the old finish
## and then show the new one; the next part change or refresh_finish() puts the real stage back.
func set_finish_stage(stage: int) -> void:
	if _hull_root == null:
		return
	_finish_stage = clampi(stage, 0, FINISH_STAGE_COUNT - 1)
	var wear: float = FINISH_WEAR[_finish_stage]
	var gold := _finish_stage == FINISH_GOLD
	for i in _finish_mats.size():
		var m := _finish_mats[i]
		var base: Dictionary = _finish_base[i]
		var gold_col: Color = base["gold"]
		var as_gold := gold and gold_col.a > 0.0
		m.set_shader_parameter("rf_wear", wear)
		m.set_shader_parameter("rf_rust_thr", FINISH_RUST_THR[_finish_stage])
		m.set_shader_parameter("rf_gold", 1.0 if as_gold else 0.0)
		m.set_shader_parameter("albedo", gold_col if as_gold else base["albedo"])
		m.set_shader_parameter("surface_kind", MaterialLib.SURFACE_KINDS["metal"] if as_gold else 0)
		m.set_shader_parameter("spec_size", GOLD_SPEC_SIZE if as_gold else base["spec_size"])
		# A crashed hull has lost what little gloss its paint had: the spec goes first; the rim,
		# which is also what separates the hull from a dark sky, mostly stays.
		var spec := GOLD_SPEC if as_gold else float(base["spec"]) * (1.0 - 0.85 * wear)
		var rim := GOLD_RIM if as_gold else float(base["rim"]) * (1.0 - 0.5 * wear)
		m.set_shader_parameter("spec_strength", spec)
		m.set_shader_parameter("rim_strength", rim)
		m.set_shader_parameter("rim_color", GOLD_RIM_COLOR if as_gold else TOON_RIM_COLOR)
		m.set_shader_parameter("shade_tint", GOLD_SHADE_TINT if as_gold else base["tint"])
		m.set_shader_parameter("shade_floor", GOLD_SHADE_FLOOR if as_gold else base["floor"])
		# Weathered bare metal is dull: oxidised, it loses its reflectance and goes matte grey. At the
		# clean 0.55 the porthole and door-window rims render near-black (metallic takes the diffuse
		# with it), and dark metal islands left between rust patches read as leopard print (critic).
		m.set_shader_parameter("metallic", float(base["metallic"]) * (1.0 - wear))
	if _sparkle != null:
		_sparkle.material_override = MaterialLib.rocket_glint(GLINT_GOLD if gold else GLINT_WHITE,
			GLINT_INTENSITY, GLINT_SIZE, GLINT_OPTS)
		_sparkle.visible = _finish_stage >= FINISH_CLEAN and _mask_saved.is_empty()


## The finish stage painted right now (0-5), or -1 before the model is built.
func finish_stage() -> int:
	return _finish_stage


func _on_rocket_parts_changed(_count: int) -> void:
	refresh_finish()


## `--rocket-finish=N` (user arg, after the `--`): REVIEW ONLY. Pins every rocket in the run to
## stage N and ignores part changes, so a capture can show any finish without a save holding N
## parts. -1 when absent. Nothing in the shipped game passes it.
static func _forced_finish_arg() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(FINISH_ARG):
			return clampi(int(a.substr(FINISH_ARG.length())), 0, FINISH_STAGE_COUNT - 1)
	return -1


## REVIEW ONLY. `on` paints every hull surface flat unshaded magenta and hides the sparkle, so a
## frame captured from the same camera is an exact mask of the rocket's pixels for per-region
## palette scoring (docs/OPEN_ISSUES.md 38: score per region, never the whole frame). `off` restores.
func set_review_mask(on: bool) -> void:
	if _hull_root == null:
		return
	if on and _mask_saved.is_empty():
		if _mask_mat == null:
			_mask_mat = StandardMaterial3D.new()
			_mask_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_mask_mat.albedo_color = Color(1.0, 0.0, 1.0)
			_mask_mat.disable_fog = true
		for n in _walk(_hull_root):
			if n is GeometryInstance3D and n != _sparkle:
				var gi := n as GeometryInstance3D
				_mask_saved[gi] = gi.material_override
				gi.material_override = _mask_mat
	elif not on and not _mask_saved.is_empty():
		for gi: GeometryInstance3D in _mask_saved:
			if is_instance_valid(gi):
				gi.material_override = _mask_saved[gi]
		_mask_saved.clear()
	if _sparkle != null:
		_sparkle.visible = not on and _finish_stage >= FINISH_CLEAN


## A hull material the finish repaints: `deep_toon` moved onto the finish shader and remembered with
## the look it was built with, so stage 4 restores it exactly. `rust_bias` is how readily the surface
## rusts (bare metal more than paint); `fade` how far its paint bleaches at full wear; `gold`
## (alpha > 0) is what it turns at stage 5 - only the cream "white" of the hull does; `scorch` how
## much of the crash scorch it takes (0 on the dark skirt, nozzle and fin feet, which it only blackened).
func _finish_mat(color: Color, opts: Dictionary, floor_level: float, rust_bias: float, fade: float,
		gold: Color = Color(0.0, 0.0, 0.0, 0.0), scorch: float = 1.0) -> ShaderMaterial:
	var m := deep_toon(color, opts, floor_level)
	m.shader = MaterialLib.rocket_finish_shader()
	m.set_shader_parameter("rf_rust_bias", rust_bias)
	m.set_shader_parameter("rf_fade", fade)
	m.set_shader_parameter("rf_rust_color", RUST)
	m.set_shader_parameter("rf_rust_deep", RUST_DEEP)
	m.set_shader_parameter("rf_dust_color", DUST)
	m.set_shader_parameter("rf_soot_color", SOOT)
	m.set_shader_parameter("rf_grime_depth", GRIME_DEPTH)
	m.set_shader_parameter("rf_scorch", scorch)
	m.set_shader_parameter("rf_scorch_dir", SCORCH_DIR)
	m.set_shader_parameter("rf_gold_hi", GOLD_HI)
	m.set_shader_parameter("rf_gold_lo", GOLD_LO)
	m.set_shader_parameter("rf_gold_hi_band", GOLD_HI_BAND)
	m.set_shader_parameter("rf_gold_lo_band", GOLD_LO_BAND)
	if gold.a > 0.0:
		m.set_shader_parameter("surface_scale", GOLD_GRAIN_SCALE)
		m.set_shader_parameter("surface_strength", GOLD_GRAIN_STRENGTH)
	_finish_mats.append(m)
	# MaterialLib.toon's own defaults for anything the opts leave out (rim 0.09, spec 0.05, size 60);
	# the shade tint, floor and metallic are read back off the built material.
	_finish_base.append({"albedo": color, "gold": gold, "spec": float(opts.get("spec", 0.05)),
		"rim": float(opts.get("rim", 0.09)), "spec_size": float(opts.get("spec_size", 60.0)),
		"tint": m.get_shader_parameter("shade_tint"), "floor": floor_level,
		"metallic": float(m.get_shader_parameter("metallic"))})
	return m


## Bakes every finish-painted part's node transform into its vertices and gives the node the inverse
## of its parents, so the part renders exactly where it did while the finish shader's v_objpos (the
## mesh's own vertex position) is HULL space on every part. Without this the porthole rim, the door
## window rim, the handle and the ladder - cylinders built at their own origin - all read y = 0 and
## took the engine skirt's full soot and ground-level rust, and the three fins, one shared mesh in
## their pivots' frames, rusted identically. Triangle count unchanged. The hatch pivot is closed
## here, so the door parts keep swinging with it.
func _bake_to_hull_space() -> void:
	for n in _walk(_hull_root):
		var mi := n as MeshInstance3D
		# The type test first: a typed Array[ShaderMaterial].has() pushes an ERROR when handed the
		# glass StandardMaterial3D.
		if mi == null or mi == _sparkle or not (mi.material_override is ShaderMaterial) \
				or not _finish_mats.has(mi.material_override):
			continue
		var chain := Transform3D.IDENTITY
		var p: Node = mi
		while p != _hull_root:
			chain = (p as Node3D).transform * chain
			p = p.get_parent()
		if chain.is_equal_approx(Transform3D.IDENTITY):
			continue
		mi.mesh = _baked(mi.mesh, chain)
		mi.transform = mi.transform * chain.affine_inverse()


static func _baked(mesh: Mesh, xf: Transform3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	var nb := xf.basis.inverse().transposed()
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in v.size():
			v[i] = xf * v[i]
		arr[Mesh.ARRAY_VERTEX] = v
		if arr[Mesh.ARRAY_NORMAL] is PackedVector3Array:
			var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for i in nn.size():
				nn[i] = (nb * nn[i]).normalized()
			arr[Mesh.ARRAY_NORMAL] = nn
		if arr[Mesh.ARRAY_TANGENT] is PackedFloat32Array:
			var tt: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT]
			for i in range(0, tt.size() - 3, 4):
				var t3 := (xf.basis * Vector3(tt[i], tt[i + 1], tt[i + 2])).normalized()
				tt[i] = t3.x
				tt[i + 1] = t3.y
				tt[i + 2] = t3.z
			arr[Mesh.ARRAY_TANGENT] = tt
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


# ============================================================================= build
func _build() -> void:
	_hull_root = Node3D.new()
	_hull_root.name = "Hull"
	add_child(_hull_root)

	# Big cream surfaces: no specular blob, barely any rim, a deep shade floor. This is where the
	# blown-highlight budget is won (STYLE_GUIDE: blown luma > 0.92 must stay under 8%).
	# Each hull colour is a finish material (see "Finish"): the same toon look as before at stage 4,
	# plus how readily it rusts and how far its paint bleaches when the rocket is crashed-dirty.
	# Bare metal rusts first, painted hull last; saturated paints (red, teal) bleach the most.
	var cream := _finish_mat(CREAM, {"shade": 0.54, "rim": 0.08, "spec": 0.04, "spec_size": 50.0,
		"softness": 0.40}, HULL_SHADE_FLOOR, 0.0, 0.15, GOLD)
	var cream_shade := _finish_mat(CREAM_SHADE, {"shade": 0.55, "rim": 0.08, "spec": 0.03},
		HULL_SHADE_FLOOR, 0.04, 0.15, GOLD_SHADE)
	var teal := _finish_mat(TEAL, {"shade": 0.50, "rim": 0.12, "spec": 0.10, "spec_size": 90.0}, 0.40,
		0.02, 0.25)
	var teal_dark := deep_toon(TEAL_DARK, {"shade": 0.52, "rim": 0.10, "spec": 0.06}, 0.36)
	var no_gold := Color(0.0, 0.0, 0.0, 0.0)
	# Rust biases are set by stage-0 COVERAGE per part (the same float32 replica of the field, sampled
	# over each part in hull space): rust has to read as patches ON a surface, never as a surface with
	# holes in it (critic: "metal spots on rust"). The low skirt, nozzle and fin feet sit where the
	# field's height bias is largest; at +0.05-0.06 they were 69-81% rust at stage 0 and read as black
	# holes close up. At -0.07: skirt 33%, nozzle 29%, fin feet 39%.
	var navy := _finish_mat(NAVY, {"shade": 0.46, "rim": 0.16, "spec": 0.10, "spec_size": 80.0}, 0.42,
		-0.07, 0.20, no_gold, 0.0)
	var navy_dark := _finish_mat(NAVY_DARK, {"shade": 0.40, "rim": 0.10, "spec": 0.06}, 0.42,
		-0.07, 0.15, no_gold, 0.0)
	# Sun-faded red: 0.35 against 0.20 moved the crashed rocket's worst dominant swatch from S 0.58 to
	# 0.56 over noon, dusk and both renderers, and on the pastel red it reads dusty, not mauve.
	var red := _finish_mat(RED, {"shade": 0.50, "rim": 0.14, "spec": 0.10, "spec_size": 110.0}, 0.40,
		0.0, 0.35)
	var red_dark := _finish_mat(RED_DARK, {"shade": 0.50, "rim": 0.10, "spec": 0.06}, 0.40,
		0.04, 0.35)
	# The fins stand in the low, rust-heavy band of the field: at bias 0 the lower half of each plate
	# was 51% rust at stage 0 and read as light paint spots on dark rust close up. At -0.04: 26% of
	# the plate, 37% of its lower half.
	var fin := _finish_mat(RED_FIN, {"shade": FIN_SHADE, "rim": 0.14, "spec": 0.10, "spec_size": 110.0},
		FIN_SHADE_FLOOR, -0.04, 0.35)
	# Trim: -0.02, a touch below the paint. The rims are thin rings on the rocket's face; at +0.03 they
	# were mostly rust around near-black metal islands (the leopard print). Stage-0 coverage at -0.02:
	# porthole rim 2%, door-window rim 5%, handle 47%, ladder 43%, nose collar 9%.
	var metal := _finish_mat(METAL, {"metallic": 0.55, "roughness": 0.5, "spec": 0.22,
		"spec_size": 120.0, "rim": 0.20}, 0.44, -0.02, 0.20)
	var metal_dark := deep_toon(METAL_DARK, {"metallic": 0.7, "roughness": 0.38, "spec": 0.2,
		"rim": 0.16}, 0.40)

	_build_skirt(navy, navy_dark)
	_build_hull(cream, teal, metal)
	_build_nose(red, red_dark, metal)
	_build_fins(fin, navy_dark)
	_build_porthole(metal)
	_build_hatch(cream, cream_shade, teal, metal)
	_build_ladder(metal)
	_build_rivets(cream_shade)
	_bake_to_hull_space()
	_build_sparkle()
	_build_beacon()
	_build_flame()
	_build_collision()
	set_flame_scale(0.0)
	_licks.emitting = false
	_smoke.emitting = false
	_flame_glow.visible = false


func _build_skirt(navy: Material, dark: Material) -> void:
	# Tapered engine housing: a crisp shoulder at the top, a hard flat step at 0.50. This is the
	# rocket's dark colour block — it anchors the silhouette and supplies the frame's dark tones.
	var profile := PackedVector2Array([
		Vector2(0.30, 0.16), Vector2(0.50, 0.24), Vector2(0.68, 0.46),
		Vector2(0.70, 0.54), Vector2(0.63, 0.59), Vector2(HULL_R, 0.63),
	])
	RocketMeshLib.mi(RocketMeshLib.lathe(profile, SEG_BODY), navy, _hull_root, Vector3.ZERO, "Skirt")
	# Nozzle: stubby, flared, dark metal, with an emissive throat.
	var nozzle := PackedVector2Array([
		Vector2(0.20, 0.42), Vector2(0.24, 0.30), Vector2(0.33, 0.14),
		Vector2(0.40, NOZZLE_MOUTH_Y), Vector2(0.34, 0.03),
	])
	RocketMeshLib.mi(RocketMeshLib.lathe(nozzle, SEG_RING), dark, _hull_root, Vector3.ZERO, "Nozzle")
	_engine_mat = MaterialLib.glow(ENGINE_GLOW, 0.3, Color("#3a2118")).duplicate() as ShaderMaterial
	_engine_mat.set_shader_parameter("emission_day_scale", 1.0)
	var throat := RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.0, 0.04), Vector2(0.20, 0.05), Vector2(0.30, 0.09)]), SEG_SMALL)
	RocketMeshLib.mi(throat, _engine_mat, _hull_root, Vector3(0.0, NOZZLE_MOUTH_Y, 0.0), "EngineThroat")
	_engine_light = OmniLight3D.new()
	_engine_light.name = "EngineLight"
	_engine_light.position = Vector3(0.0, -0.25, 0.0)
	_engine_light.light_color = ENGINE_GLOW
	_engine_light.omni_range = ENGINE_LIGHT_RANGE
	_engine_light.light_energy = 0.0
	_engine_light.shadow_enabled = false
	_engine_light.visible = false
	add_child(_engine_light)


func _build_hull(cream: Material, teal: Material, metal: Material) -> void:
	# Straight-sided body: the silhouette is a cylinder, not a bulge.
	var profile := PackedVector2Array([
		Vector2(HULL_R, 0.62), Vector2(HULL_R, 1.98), Vector2(0.615, 2.08),
		Vector2(0.60, 2.18), Vector2(0.575, 2.28), Vector2(0.575, 2.34),
	])
	RocketMeshLib.mi(RocketMeshLib.lathe(profile, SEG_BODY), cream, _hull_root, Vector3.ZERO, "Body")
	# Two saturated teal belts — the hull's secondary colour zone. Without them the rocket is a
	# single near-white value zone next to AC props that each carry 3-4 colour blocks.
	_band(teal, 0.63, 0.815, HULL_R + 0.013, "BeltBand")
	_band(teal, 1.85, 1.98, HULL_R + 0.013, "ShoulderBand")
	RocketMeshLib.mi(RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.585, 2.285), Vector2(0.585, 2.335)]), SEG_RING), metal, _hull_root, Vector3.ZERO, "NoseCollar")


## One flat colour band wrapped around the hull (a 2-point lathe: no wasted end caps).
func _band(mat: Material, y0: float, y1: float, r: float, node_name: String) -> void:
	RocketMeshLib.mi(RocketMeshLib.lathe(PackedVector2Array([Vector2(r, y0), Vector2(r, y1)]), SEG_RING),
		mat, _hull_root, Vector3.ZERO, node_name)


func _build_nose(red: Material, dark: Material, metal: Material) -> void:
	var profile := PackedVector2Array([
		Vector2(0.575, 2.34), Vector2(0.560, 2.46), Vector2(0.480, 2.68),
		Vector2(0.360, 2.89), Vector2(0.215, 3.07), Vector2(0.0, 3.20),
	])
	RocketMeshLib.mi(RocketMeshLib.lathe(profile, SEG_BODY), red, _hull_root, Vector3.ZERO, "Nose")
	# A hard darker ring just above the collar keeps the cone reading as built, not moulded.
	RocketMeshLib.mi(RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.566, 2.42), Vector2(0.552, 2.50)]), SEG_RING), dark, _hull_root, Vector3.ZERO, "NoseBand")
	RocketMeshLib.mi(RocketMeshLib.lathe(PackedVector2Array([
		Vector2(0.05, 3.16), Vector2(0.075, 3.22)]), SEG_SMALL), metal, _hull_root, Vector3.ZERO, "BeaconPost")


func _build_fins(red: Material, dark: Material) -> void:
	# Flat chamfered plates: crisp leading edge, flat foot on the ground, dark navy shoe.
	var poly := PackedVector2Array([
		Vector2(0.45, 0.00), Vector2(1.18, 0.00), Vector2(1.22, 0.16),
		Vector2(0.94, 0.48), Vector2(0.70, 0.86), Vector2(0.64, 1.16),
		Vector2(0.55, 1.16), Vector2(0.53, 0.44),
	])
	var mesh := RocketMeshLib.prism(poly, 0.058, 0.038)
	var foot := PackedVector2Array([
		Vector2(0.70, 0.00), Vector2(1.17, 0.00), Vector2(1.17, 0.10), Vector2(0.70, 0.10)])
	var foot_mesh := RocketMeshLib.prism(foot, 0.082, 0.028)
	for i in FIN_ANGLES_DEG.size():
		var pivot := Node3D.new()
		pivot.name = "Fin%d" % i
		pivot.rotation.y = deg_to_rad(FIN_ANGLES_DEG[i])
		_hull_root.add_child(pivot)
		RocketMeshLib.mi(mesh, red, pivot, Vector3.ZERO, "Plate")
		RocketMeshLib.mi(foot_mesh, dark, pivot, Vector3.ZERO, "Foot")


func _build_porthole(metal: Material) -> void:
	var root := Node3D.new()
	root.name = "Porthole"
	root.position = Vector3(0.0, PORTHOLE_Y, 0.0)
	_hull_root.add_child(root)
	# Ring frame: a flat collar, not a torus donut.
	var ring := RocketMeshLib.mi(RocketMeshLib.cylinder(PORTHOLE_R + 0.075, PORTHOLE_R + 0.085, 0.07, 14),
		metal, root, Vector3(0.0, 0.0, -HULL_R - 0.005), "Rim")
	ring.rotation.x = deg_to_rad(90.0)
	# The glass is deliberately matte-ish: a clearcoat porthole threw a big blown white blob across
	# the rocket's face in every pad shot.
	var glass := RocketMeshLib.mi(RocketMeshLib.cylinder(PORTHOLE_R, PORTHOLE_R, 0.03, 10),
		MaterialLib.glass(GLASS_TINT, 0.46, {"roughness": 0.32, "metallic": 0.0}), root,
		Vector3(0.0, 0.0, -HULL_R - 0.035), "Glass")
	glass.rotation.x = deg_to_rad(90.0)
	var inner_mat := MaterialLib.glow(CABIN_GLOW, 1.1, Color("#8a6a3c")).duplicate() as ShaderMaterial
	inner_mat.set_shader_parameter("emission_day_scale", 0.55)
	inner_mat.set_shader_parameter("emission_cap", 1.4)
	var inner := RocketMeshLib.mi(RocketMeshLib.cylinder(PORTHOLE_R - 0.02, PORTHOLE_R - 0.02, 0.02, 10),
		inner_mat, root, Vector3(0.0, 0.0, -HULL_R + 0.03), "CabinDisc")
	inner.rotation.x = deg_to_rad(90.0)
	_cabin_light = OmniLight3D.new()
	_cabin_light.name = "CabinLight"
	_cabin_light.position = Vector3(0.0, 0.0, -HULL_R - 0.35)
	_cabin_light.light_color = CABIN_GLOW
	_cabin_light.light_energy = 0.8
	_cabin_light.omni_range = CABIN_LIGHT_RANGE
	_cabin_light.shadow_enabled = false
	root.add_child(_cabin_light)


func _build_hatch(cream: Material, shade: Material, teal: Material, metal: Material) -> void:
	# Frame recessed into the hull so the doorway reads even when the door is open.
	var frame := RocketMeshLib.curved_panel(HULL_R - 0.03, HULL_R + 0.02, HATCH_Y0 - 0.06, HATCH_Y1 + 0.06,
		HATCH_HALF_ANGLE + deg_to_rad(4.0), 7)
	RocketMeshLib.mi(frame, shade, _hull_root, Vector3.ZERO, "HatchFrame")
	var dark_hole := RocketMeshLib.curved_panel(HULL_R - 0.10, HULL_R - 0.04, HATCH_Y0, HATCH_Y1, HATCH_HALF_ANGLE, 5)
	RocketMeshLib.mi(dark_hole, deep_toon(Color("#241f2c"), {"shade": 0.2, "rim": 0.0, "spec": 0.0}, 0.28),
		_hull_root, Vector3.ZERO, "HatchWell")

	var hinge_pos := Vector3(HULL_R * sin(HATCH_HALF_ANGLE), 0.0, -HULL_R * cos(HATCH_HALF_ANGLE))
	_hatch_pivot = Node3D.new()
	_hatch_pivot.name = "HatchPivot"
	_hatch_pivot.position = hinge_pos
	_hull_root.add_child(_hatch_pivot)
	var door := RocketMeshLib.curved_panel(HULL_R + 0.005, HULL_R + 0.055, HATCH_Y0, HATCH_Y1, HATCH_HALF_ANGLE, 7)
	RocketMeshLib.mi(door, cream, _hatch_pivot, -hinge_pos, "Door")
	# A teal kick panel across the bottom of the door repeats the belt colour on the face you look at.
	var kick := RocketMeshLib.curved_panel(HULL_R + 0.055, HULL_R + 0.070, HATCH_Y0 + 0.04, HATCH_Y0 + 0.26,
		HATCH_HALF_ANGLE - deg_to_rad(3.0), 5)
	RocketMeshLib.mi(kick, teal, _hatch_pivot, -hinge_pos, "DoorKick")
	# Door window + handle so the open door still reads as a door.
	var win_mat := MaterialLib.glass(GLASS_TINT, 0.46, {"roughness": 0.32, "metallic": 0.0})
	var win := RocketMeshLib.mi(RocketMeshLib.cylinder(0.12, 0.12, 0.03, 10), win_mat, _hatch_pivot,
		-hinge_pos + Vector3(0.0, HATCH_Y1 - 0.22, -HULL_R - 0.07), "DoorWindow")
	win.rotation.x = deg_to_rad(90.0)
	var win_ring := RocketMeshLib.mi(RocketMeshLib.cylinder(0.155, 0.16, 0.04, 10), metal, _hatch_pivot,
		-hinge_pos + Vector3(0.0, HATCH_Y1 - 0.22, -HULL_R - 0.06), "DoorWindowRim")
	win_ring.rotation.x = deg_to_rad(90.0)
	var handle := RocketMeshLib.mi(RocketMeshLib.cylinder(0.028, 0.028, 0.17, 6), metal, _hatch_pivot,
		-hinge_pos + Vector3(-0.20, HATCH_Y0 + 0.30, -HULL_R - 0.09), "Handle")
	handle.rotation.z = deg_to_rad(90.0)


func _build_ladder(metal: Material) -> void:
	var root := Node3D.new()
	root.name = "Ladder"
	_ladder = root
	_hull_root.add_child(root)
	for side: float in [-1.0, 1.0]:
		var rail := RocketMeshLib.mi(RocketMeshLib.cylinder(0.026, 0.026, 0.60, 6), metal, root,
			Vector3(0.15 * side, 0.30, -HULL_R - 0.12), "Rail")
		rail.rotation.x = deg_to_rad(6.0)
	for i in 3:
		var rung := RocketMeshLib.mi(RocketMeshLib.cylinder(0.022, 0.022, 0.30, 5), metal, root,
			Vector3(0.0, 0.13 + 0.19 * float(i), -HULL_R - 0.12), "Rung%d" % i)
		rung.rotation.z = deg_to_rad(90.0)


func _build_rivets(mat: Material) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	# Small and hull-coloured: dark metal beads at this size read as dirt speckle, not hardware.
	mm.mesh = RocketMeshLib.sphere(0.026, 6, 2)
	mm.instance_count = RIVETS_PER_RING
	for i in RIVETS_PER_RING:
		var a := TAU * float(i) / float(RIVETS_PER_RING)
		var p := Vector3(cos(a) * (HULL_R + 0.016), RIVET_RING_Y, sin(a) * (HULL_R + 0.016))
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.7, 1.0)), p))
	_rivets = MultiMeshInstance3D.new()
	_rivets.name = "Rivets"
	_rivets.multimesh = mm
	_rivets.material_override = mat
	_rivets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rivets.visibility_range_end = RIVET_VISIBLE_M
	_rivets.visibility_range_end_margin = 4.0
	_rivets.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_hull_root.add_child(_rivets)


## The stage 4-5 sparkle: GLINTS as ONE merged mesh on MaterialLib.rocket_glint (star.gdshader's
## four-point twinkle, billboarded in its vertex function). All four corners of a glint sit on its
## centre; UV names the corner and UV2.x is its blink phase, spread evenly so they twinkle in turn
## rather than together. One draw call, 2 triangles a glint, hidden below stage 4.
## It replaced a MultiMesh on star.gdshader that drew nothing under Compatibility - the web build the
## phone runs - while still costing its draw call (critic probe; MaterialLib "rocket glints").
func _build_sparkle() -> void:
	if MaterialLib.rocket_glint_shader() == null:
		return
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var phases := PackedVector2Array()
	var idx := PackedInt32Array()
	var corners: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
	for i in GLINTS.size():
		var g := GLINTS[i]
		var a := deg_to_rad(g.x)
		var at := Vector3(g.z * sin(a), g.y, -g.z * cos(a))
		var first := verts.size()
		for c in corners:
			verts.append(at)
			uvs.append(c)
			phases.append(Vector2(float(i) / float(GLINTS.size()), 0.0))
		idx.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_TEX_UV2] = phases
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	# The vertices are only the centres, so pad the cull box by a glint: a glint at the edge of the
	# view must not be culled while its quad is still on screen.
	mesh.custom_aabb = mesh.get_aabb().grow(GLINT_SIZE)
	_sparkle = MeshInstance3D.new()
	_sparkle.name = "Sparkle"
	_sparkle.mesh = mesh
	_sparkle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sparkle.visible = false
	_hull_root.add_child(_sparkle)


func _build_beacon() -> void:
	_beacon_mat = MaterialLib.glow(BEACON_COLOR, 1.0, Color("#d2554e")).duplicate() as ShaderMaterial
	_beacon_mat.set_shader_parameter("emission_day_scale", 1.0)
	_beacon_mat.set_shader_parameter("emission_cap", 5.0)
	_beacon_mesh = RocketMeshLib.mi(RocketMeshLib.sphere(0.075, 8, 3), _beacon_mat, _hull_root,
		Vector3(0.0, BEACON_Y, 0.0), "Beacon")
	_beacon_light = OmniLight3D.new()
	_beacon_light.name = "BeaconLight"
	_beacon_light.position = Vector3(0.0, BEACON_Y, 0.0)
	_beacon_light.light_color = BEACON_COLOR
	_beacon_light.omni_range = BEACON_LIGHT_RANGE
	_beacon_light.light_energy = 0.0
	_beacon_light.shadow_enabled = false
	_hull_root.add_child(_beacon_light)


# ============================================================================= flame
## Teardrop plume profile (radius, y) from the tip UP to the nozzle mouth, so the shape hangs
## downward from the engine. Enough rows that the shoulder is a shaped curve rather than a cone,
## and so `rocket_flame.gdshader`'s axial ramp (which walks the profile through UV.y) has the
## resolution to put its colour stops where they belong.
static func _plume_profile(w: float, l: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -1.00 * l), Vector2(0.20 * w, -0.84 * l), Vector2(0.44 * w, -0.68 * l),
		Vector2(0.68 * w, -0.50 * l), Vector2(0.88 * w, -0.33 * l), Vector2(1.00 * w, -0.19 * l),
		Vector2(0.95 * w, -0.11 * l), Vector2(0.80 * w, -0.045 * l), Vector2(0.66 * w, 0.0),
	])


## The hot collar: a short flared skirt that sits PROUD of the body over the first fifth of the
## plume and tucks back inside at its lip. Nested shells are invisible — this one is deliberately
## the outermost thing at the throat, which is how the blue-white core actually gets seen.
static func _collar_profile(w: float, l: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.90 * w, -0.21 * l), Vector2(1.02 * w, -0.19 * l), Vector2(1.03 * w, -0.15 * l),
		Vector2(0.86 * w, -0.05 * l), Vector2(0.60 * w, 0.02 * l),
	])


func _build_flame() -> void:
	_flame = Node3D.new()
	_flame.name = "Flame"
	_flame.position = Vector3(0.0, NOZZLE_MOUTH_Y, 0.0)
	add_child(_flame)

	# ONE painted silhouette, not nested shells. `rocket_flame.gdshader` carries the structure the
	# style guide asks for — hot blue-white throat, white-gold, orange body, deep orange-red tip,
	# a view-facing hot centre and a crisp painted rim — because an orange shell with a hot core
	# tucked inside it only ever renders as the shell (integration critic: "a paper cutout").
	_plume_outer = _flame_shell("PlumeBody", _plume_profile(PLUME_R, PLUME_LEN), 18, {})
	# The collar is the one piece of real geometry: it sits OUTSIDE the body at the throat, so the
	# hot core is a shape you can see rather than one hidden under an orange skin.
	_plume_collar = _flame_shell("PlumeCollar", _collar_profile(PLUME_R, PLUME_LEN), 16, {
		"core_color": Color("#e4f4ff"), "hot_color": Color("#cfe9ff"), "body_color": Color("#a4d3f7"),
		"deep_color": Color("#79b6ea"), "tip_color": Color("#5f9fd8"),
		"edge_color": Color("#3f7fbe"), "edge_strength": 0.5, "edge_width": 0.5,
		"gain_hot": 1.12, "gain_tip": 0.95, "emission_cap": 1.25, "lick": 0.0, "ripple": 0.02,
		"face_gain": 0.30,
	})

	# A soft additive blob right at the throat welds the plume to the nozzle. Small and dim: the
	# old 0.42 m blob at 0.28 intensity was the big red halo the plume was floating inside.
	var glow_mesh := RocketMeshLib.sphere(0.28, 10, 5)
	var glow_mat := MaterialLib.glow_sprite(Color("#ff9a4a"), _flame_intensity * 0.16, {"softness": 0.9, "core": 0.10}).duplicate() as ShaderMaterial
	glow_mesh.material = glow_mat
	_flame_mats.append(glow_mat)
	_flame_glow = MeshInstance3D.new()
	_flame_glow.name = "FlameGlow"
	_flame_glow.mesh = glow_mesh
	_flame_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.add_child(_flame_glow)

	_licks = _make_licks()
	_flame.add_child(_licks)

	_smoke = GPUParticles3D.new()
	_smoke.name = "Smoke"
	_smoke.amount = 34
	# Short-lived: a 2.1 s puff with heavy damping just stopped dead and hung in the air after the
	# engine cut. 1.3 s + buoyancy means every puff is still rising when it fades out.
	_smoke.lifetime = 1.3
	_smoke.local_coords = false
	_smoke.emitting = false
	_smoke.position = Vector3(0.0, NOZZLE_MOUTH_Y, 0.0)
	_smoke.visibility_aabb = AABB(Vector3(-14, -30, -14), Vector3(28, 60, 28))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.24
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 34.0
	pm.initial_velocity_min = 1.8
	pm.initial_velocity_max = 4.2
	pm.gravity = Vector3.ZERO
	pm.damping_min = 0.8
	pm.damping_max = 1.6
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	pm.angular_velocity_min = -60.0
	pm.angular_velocity_max = 60.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.30))
	grow.add_point(Vector2(0.35, 1.0))
	grow.add_point(Vector2(1.0, 1.35))
	var grow_t := CurveTexture.new()
	grow_t.curve = grow
	pm.scale_curve = grow_t
	var grad := Gradient.new()
	grad.set_color(0, Color(0.70, 0.68, 0.68, 0.0))
	grad.set_color(1, Color(0.36, 0.35, 0.40, 0.0))
	grad.add_point(0.10, Color(0.80, 0.78, 0.77, 0.78))
	grad.add_point(0.45, Color(0.56, 0.54, 0.58, 0.40))
	var grad_t := GradientTexture1D.new()
	grad_t.gradient = grad
	pm.color_ramp = grad_t
	_smoke.process_material = pm
	var puff := QuadMesh.new()
	puff.size = Vector2(1.05, 1.05)
	puff.material = make_puff_material(Color("#e2ddd6"), Color("#9b96a4"), 0.85, 0.8)
	_smoke.draw_pass_1 = puff
	add_child(_smoke)


## One lathe shell running `rocket_flame.gdshader`. `overrides` re-points any of its uniforms.
func _flame_shell(node_name: String, profile: PackedVector2Array, seg: int,
		overrides: Dictionary) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = FLAME_SHADER
	for key: String in overrides:
		mat.set_shader_parameter(key, overrides[key])
	mat.set_shader_parameter("intensity", _flame_intensity / GROUND_FLAME_REF)
	_plume_mats.append(mat)
	_plume_caps.append(float(overrides.get("emission_cap", 2.0)))
	var mi := RocketMeshLib.mi(RocketMeshLib.lathe(profile, seg), mat, _flame, Vector3.ZERO, node_name)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Small orange sparks flicking off the plume edge — motion on top of the solid silhouette.
func _make_licks() -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.name = "FlameLicks"
	gp.amount = 22
	gp.lifetime = 0.42
	gp.local_coords = true
	gp.emitting = false
	gp.visibility_aabb = AABB(Vector3(-3, -8, -3), Vector3(6, 10, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 16.0
	pm.initial_velocity_min = 3.4
	pm.initial_velocity_max = 6.2
	pm.gravity = Vector3.ZERO
	pm.damping_min = 1.4
	pm.damping_max = 2.4
	pm.scale_min = 0.55
	pm.scale_max = 1.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(0.4, 0.7))
	shrink.add_point(Vector2(1.0, 0.0))
	var shrink_t := CurveTexture.new()
	shrink_t.curve = shrink
	pm.scale_curve = shrink_t
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.86, 0.55, 0.95))
	grad.set_color(1, Color(0.93, 0.38, 0.12, 0.0))
	grad.add_point(0.45, Color(1.0, 0.58, 0.18, 0.75))
	var grad_t := GradientTexture1D.new()
	grad_t.gradient = grad
	pm.color_ramp = grad_t
	gp.process_material = pm
	var quad := QuadMesh.new()
	# Small: at 0.26 these read as soft bubbles drifting off the plume rather than as sparks.
	quad.size = Vector2(0.15, 0.15)
	var fmat := MaterialLib.glow_sprite(Color("#ffd7a0"), _flame_intensity * 0.8, {"softness": 0.55, "core": 0.34}).duplicate() as ShaderMaterial
	quad.material = fmat
	_flame_mats.append(fmat)
	gp.draw_pass_1 = quad
	return gp


## Cartoon flicker: the plume breathes in length and girth and shears a little side to side, so a
## solid mesh flame still reads as fire.
func _animate_plume() -> void:
	var wob := 1.0 + 0.10 * sin(_time * 22.0) + 0.05 * sin(_time * 37.0 + 1.1)
	var wob2 := 1.0 + 0.07 * sin(_time * 26.0 + 2.2)
	_plume_outer.scale = Vector3(wob2, wob, wob2)
	# The collar rides the body's girth (so it stays proud of it) but keeps its own length.
	_plume_collar.scale = Vector3(wob2, 1.0, wob2)
	_plume_outer.rotation.z = 0.035 * sin(_time * 14.0)


## Soft billboarded smoke material (shared by the pad's dust ring).
static func make_puff_material(lit: Color, shade: Color, softness: float = 0.55, opacity: float = 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SMOKE_SHADER
	m.set_shader_parameter("lit_color", lit)
	m.set_shader_parameter("shade_color", shade)
	m.set_shader_parameter("edge_softness", softness)
	m.set_shader_parameter("opacity", opacity)
	return m


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Blocker"
	body.collision_layer = 1 << 3          # decoration layer: the player bumps into it
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = HULL_R + 0.06
	cyl.height = 2.3
	shape.shape = cyl
	shape.position = Vector3(0.0, 1.15, 0.0)
	body.add_child(shape)
	add_child(body)


func _swing_hatch(want_open: bool) -> void:
	if _hatch_pivot == null or _hatch_open == want_open:
		return
	_hatch_open = want_open
	if _hatch_tween != null and _hatch_tween.is_valid():
		_hatch_tween.kill()
	_hatch_tween = create_tween()
	var target := -deg_to_rad(HATCH_OPEN_DEG) if want_open else 0.0
	_hatch_tween.tween_property(_hatch_pivot, "rotation:y", target, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if want_open else Tween.EASE_IN)
