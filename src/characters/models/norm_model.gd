class_name NormModel
extends ChibiModel
## NORM — the mystery neighbour ("a normal human"). VARIANT A: the near-miss suit.
##
## docs/CORE_LOOP.md "The mystery neighbour", the user's own words:
##   "astronaut but with a large orange tentacle coming out of a crack from the face mask. Around
##    the arms, and legs there are small tentacles coming out randomly through the astronaut suit"
##   "His suit should look a bit ragged as well"
##   "personality-wise he should try to pretend to be a human but obviously sounds like he's not"
##
## HE IS A CHIBI, NOT AN ASTRONAUT RIG. Stella wraps the player's `AstronautModel`; Norm does not.
## He is built on `ChibiModel` like every other neighbour, so his body is a squat bean with stub
## arms and big round boots — a silhouette the player's 1.42 m astronaut and Stella (who IS that
## astronaut) do not have. That is the FIRST line of defence on "never mistaken for the player":
## before any colour is read, the proportions are already a different creature wearing a suit.
## The second is colour (see the palette block) and the third is the tentacle.
##
## WHY A SUBCLASS TREE AND NOT A `variant` FLAG. `norm_model.gd` (this file, variant A) holds every
## piece of geometry; `norm_heavy_model.gd` (variant B) is a subclass that overrides ONLY `_spec()`
## and `_variant_tweaks()`. Both are kept — the runner-up is never deleted — and B cannot drift
## away from A's rig, which is what a copy-pasted second file always does.
##
## ---------------------------------------------------------------------------- the act
## Every emote is "a person doing a human thing, badly, with a tentacle":
##   wave      — he waves with the TENTACLE for the first 55 %, notices, stuffs it down and finishes
##               with a stiff hand wave.
##   think     — the arms hang; the tentacle curls back and TAPS the side of the helmet.
##   surprised — every small tentacle pops out of the suit at once, then he stuffs them back in.
##   dance     — a rigid, square, on-the-beat "human" dance with the tentacle clamped rigid (and one
##               betrayal wobble per bar).
##   happy     — the hop is real; the tentacle flails, which is the only honest thing he does.
## Idle is where the "randomly through the suit" line lives: each of the eight small tentacles pokes
## out and is pushed back in on its own period, never in unison.
##
## ---------------------------------------------------------------------------- palette (R2.6 gates)
## He has no eyes, so there is no eye-ink exemption. MEASURED (round 1, own pixels, 6.5 m): the only
## swatch above S 0.60 is the R2.2-mandated navy visor, S 0.61-0.68 at V 0.12-0.14 (near-black; the
## player's own visor measures S 0.78-0.86 at V 0.15 in the same scene). Everything else <= S 0.56.
## He is deliberately NOT white (player `#f4f4f8`) and NOT rose (Stella `#e6d2d4`).
## 2026-09-19 round 1: the first draft's putty-oat (#bfb7a2) read as the player's white suit at
## 6.5 m on the phone frame (looked at, not measured). A faded TEAL is the "slightly wrong" suit:
## the right cut, the wrong colour, and it is the complement of the orange tentacle.
const SUIT := Color("#8fb3ac")        ## H 169 S 0.201 V 0.702 — faded teal
const SUIT_DARK := Color("#4f6664")   ## H 175 S 0.225 V 0.400 — trouser block / lower body
const PANEL := Color("#72918c")       ## S 0.214 V 0.569 — chest panel, the middle value
const SCUFF := Color("#6f8581")       ## S 0.165 V 0.522 — rubbed-through streaks
## The two MISMATCHED repair colours. A patch that matches the suit is not a patch; these are the
## two "whatever was in the locker" tones and they also do the mismatched glove and boot.
const PATCH_OCHRE := Color("#b0936a") ## S 0.40 V 0.69 — round 1: #b08a52 rendered S 0.69
const PATCH_SLATE := Color("#6d7b86") ## S 0.187 V 0.525
const HELMET := Color("#a9c0ba")      ## S 0.120 V 0.753 — a greyed teal shell, never the player's white
const HELMET_RIM := Color("#7f8f8a")  ## S 0.111 V 0.561 — collar ring, dent creases
## THE VISOR. R2.2 mandates an OPAQUE NAVY visor with no face on every astronaut. The shipped
## `AstronautModel.VISOR_NAVY` (#1b2450) measures S 0.663, which is over the "no dominant swatch
## above S 0.60" gate; on the player it survives as a tinted lerp. Norm's is the same navy nudged
## to S 0.545 so it passes on its own, and it is still unmistakably the astronaut navy.
const VISOR := Color("#343745")       ## H 229 S 0.24 V 0.27 — round 1: #232b4d (S 0.545) rendered S 0.72 over ~19 % of his pixels
## The crack is PALE: broken glass catches light. The first draft's near-black crack on a navy pane
## was invisible at 6.5 m. 2026-09-19: but not WHITE — round 2's #b9c2d6 rendered near-white and, as a
## ring of points, read as teeth. A blue-grey glass tint, a full value step under white.
const CRACK := Color("#8797ae")       ## H 215 S 0.224 V 0.682 (round 2: #b9c2d6, S 0.136 V 0.839)
## THE TENTACLE. "coral or tangerine orange", and it must not be read as Pop, who is being recoloured
## to a WARM AMBER-ORANGE. Round 2 re-measure, 2026-09-19, each model's own pixels (silhouette mask,
## 2 px eroded), 6.5 m gameplay camera, both renderers: Pop's FINAL color2 fur (#9e856c, cast-0915b
## color2) renders H 28.1-28.5 S 0.56 V 0.70. Round 1 compared against an OLDER color2 (#baa17e,
## H 39.5), and the round-1 tentacle (#db8776) renders H 18.6-19.5 — only ~9 deg from today's Pop.
## So the tentacle moves 6 deg toward CORAL and now renders H 10.0 (Compat) / 11.0 (Forward+) at
## S 0.54-0.55: 17-18 deg from Pop. It also stays
## a full value step brighter than Pop (V ~0.94 vs 0.70) and is a smooth tube where Pop is a fur ball.
## The lighting warms it ~8 deg and the toon ramp lifts S ~1.17x, hence the pinker base swatch.
const TENTACLE := Color("#db7d76")      ## H 4 S 0.46 V 0.86 (round 1: #db8776, H 10)
const TENTACLE_TIP := Color("#e3908a")  ## H 4 S 0.39 V 0.89 — the small tentacles (round 1: #e39b8a)

# ---------------------------------------------------------------------------- shape
## Variant A's helmet: a fairly round bubble, closest in KIND to the player's dome — which is the
## point of this variant. Everything that says "not the player" has to be carried by the colour,
## the chibi body, the crooked seat and the tentacle. Variant B trades that for a boxy helmet.
const HEAD_SEMI_A := Vector3(0.372, 0.348, 0.360)
const HEAD_N_A := 2.3
## CROOKED. The helmet does not sit straight on the collar — it is 7 deg of roll and 4 deg of yaw
## off. `_head.rotation` is overwritten every frame by `_apply_pose`, so the tilt CANNOT live there;
## it lives on a `HelmetTilt` child and everything helmet-shaped hangs off that node.
const HELMET_TILT := Vector3(0.035, 0.070, 0.122)

## Visor lens. A thick oblate superellipsoid seated 0.072 m INTO the shell, so only the front ~20 mm
## stands proud and the rim tucks back under the helmet. (A thin flat pane on a curved shell has its
## corners hanging in the air — see `_se_slab`'s header for the same trap in the other direction.)
const VISOR_SEMI := Vector3(0.250, 0.190, 0.095)
const VISOR_INSET := 0.050
const VISOR_PITCH := -8.0

## THE HOLE the tentacle comes out of, in visor-local metres (x right, y up on the pane). Round 2:
## round 1 seated the tentacle on the helmet SHELL beside the visor, so its flat tube end butted the
## rim and the crack was five loose slivers in the middle of the pane. Now the strand is rooted
## INSIDE the pane at this point, a jagged broken rim rings it, and every crack line starts at it.
const TENT_EXIT := Vector2(0.100, 0.052)

## The big tentacle's SKELETON: straight joints with real bends, so a wave, a tap and a rigid hold
## are three different sets of joint angles on the same nodes. Round 2: the joints carry NO meshes.
## One continuous tube is swept through them every frame (`_rebuild_tent_mesh`), so there are no
## segment seams and the tip is part of the same smooth surface. Round 1 hung a separate tapered
## tube on each of 12 joints and every joint showed a notch plus a light/dark sliver on screen.
## Each row: [length, radius at base, resting bend in radians at that joint].
## Round 1 rebuild: the first draft's 0.335 m x 0.050 m strand read as a 3-pixel orange stub at
## 6.5 m. This one is 0.58 m long and 0.074 m thick at the base, and curls UP and OUT to his right
## into a question-mark hook that clears the helmet's silhouette — the "large orange tentacle".
const TENT_SEGS := [
	[0.150, 0.080, 0.00],
	[0.145, 0.071, 0.05],
	[0.140, 0.062, 0.20],
	[0.125, 0.053, 0.60],
	[0.110, 0.045, 0.90],
	[0.095, 0.038, 1.10],
]
## The tip radius. A hair FATTER than the last joint (0.038), so the end swells into a soft round
## bulb instead of narrowing to a point; the hemisphere that closes it is part of the swept tube.
const TENT_TIP_R := 0.041
## Joints per TENT_SEGS row (see `_build_tentacle`).
const TENT_SUB := 2
## Sweep resolution. 14 sides; 3 rings per joint span through a Catmull-Rom curve, so a 0.55 rad
## joint bend is spread over three rings instead of one hard crease; 4 rings of hemisphere cap.
const TENT_SIDES := 14
const TENT_SPAN_RINGS := 3
const TENT_CAP_RINGS := 4
## How far behind the pane surface the root starts, along the pane's own normal, so the strand
## visibly comes OUT of the glass rather than being glued onto it.
const TENT_ROOT_SINK := 0.070
## The plane the hook curls in: HORIZONTAL, to his right, so the accumulated bend (TENT_SEGS) sweeps
## the strand from "straight up" over to "sideways" — the hook opens to the side, not further upward.
## NORMCLIP fix 2026-09-19 (docs/OPEN_ISSUES.md): round 1's up-curl paired with an OUT_DIR that was
## mostly SIDEWAYS from the root (old `Vector3(1.0, 0.15, -0.36)`), so the strand built horizontal
## reach immediately on leaving the visor — measured (tests/tools/measure_norm_tent.gd, headless,
## every state) 0.51-0.92 m of horizontal reach from Norm's own origin all through y=0.75-1.42, the
## player astronaut's own helmet band (astronaut_model.gd HELMET_CY 1.087 +/- HELMET_R.y 0.335). The
## capsule stop distance (player r0.30 + Norm r0.40 = 0.70 m) minus the player's own helmet poking
## ~0.36 m of that back out leaves only ~0.34 m of slack there — nowhere near enough. Swapping which
## axis is "up" and which is "the curl plane" keeps the same bend SCHEDULE (TENT_SEGS is unchanged:
## still near-straight for the first two joints, curling hard after) but now "near-straight" means
## up the helmet's own crown instead of out over the player's face. Re-measured after: 0.34-0.72 m
## through the same band (idle/talk), still a real but much smaller overshoot, covered the rest of
## the way by widening Norm's capsule (see norm.tscn) rather than flattening the hook further.
const TENT_CURL_DIR := Vector3(1.0, 0.0, 0.0)
## The direction the tentacle LEAVES the hole in: mostly UP the crown, with enough "out of the glass"
## and "to his right" to still read as coming out of a crack and not as a flagpole glued to the dome.
## NORMCLIP fix 2026-09-19: was `Vector3(1.0, 0.15, -0.36)` (mostly sideways) — see TENT_CURL_DIR.
const TENT_OUT_DIR := Vector3(0.22, 0.94, -0.25)

## Small tentacles, in [parent index, position, direction, length, base radius] form.
## Parent index: 0 = left arm, 1 = right arm, 2 = left leg, 3 = right leg. Two per limb, at
## different heights and pointing different ways, because four matched pairs read as a manufactured
## part and not as something living inside the suit.
const POKERS := [
	[0, Vector3(-0.044, -0.055, -0.014), Vector3(-0.85, 0.15, -0.50), 0.052, 0.016],
	[0, Vector3(0.012, -0.150, 0.044), Vector3(0.18, -0.30, 0.94), 0.044, 0.013],
	[1, Vector3(0.046, -0.082, 0.020), Vector3(0.88, -0.10, 0.46), 0.049, 0.015],
	[1, Vector3(-0.010, -0.040, -0.046), Vector3(-0.14, 0.34, -0.93), 0.041, 0.013],
	[2, Vector3(-0.050, -0.048, 0.012), Vector3(-0.92, 0.05, 0.39), 0.046, 0.015],
	[2, Vector3(0.020, -0.100, -0.044), Vector3(0.30, -0.22, -0.93), 0.038, 0.012],
	[3, Vector3(0.050, -0.070, -0.016), Vector3(0.93, -0.08, -0.36), 0.047, 0.015],
	[3, Vector3(-0.016, -0.030, 0.048), Vector3(-0.24, 0.26, 0.94), 0.040, 0.013],
]
## How far a small tentacle retracts. Its seat is 12 mm inside the limb, so 0.10 of a 45 mm strand
## is 4.5 mm and sits entirely under the suit: pushed back in, not merely short.
const POKE_MIN := 0.10
## Idle poke: each strand is out for `POKE_OUT_FRAC` of its own period. 0.16 of ~5 s is a strand
## visible for ~0.8 s at a time, and eight staggered periods never line up.
const POKE_OUT_FRAC := 0.30

var _tent: Array[Node3D] = []        ## the big-tentacle joints, base first (no meshes on them)
var _tent_rest: Array[float] = []    ## their resting bends
var _tent_r: Array[float] = []       ## tube radius at each joint's origin
var _tent_last_len := 0.0            ## length of the last joint (the tip sits at its end)
var _tent_pane_n := Vector3.FORWARD  ## the pane's outward normal, in TentSeat space
var _tent_mesh: ArrayMesh
var _tent_body: MeshInstance3D
## Re-sweep buffers (normchk fix 2026-09-19). The ring layout never changes between frames, so the
## index list, the UVs and the ring cos/sin tables are built ONCE and only the positions and normals
## are rewritten in place. Same surface, bit for bit in layout, as `sweep_tube()`.
var _tent_idx := PackedInt32Array()
var _tent_uvs := PackedVector2Array()
var _tent_verts := PackedVector3Array()
var _tent_norms := PackedVector3Array()
var _tent_cs := PackedFloat32Array()
var _tent_sn := PackedFloat32Array()
var _tent_arrays: Array = []
var _wave_bend := 0.28               ## how far the wave curls the hook; B's boxy face needs less
var _pokers: Array[Node3D] = []
var _poker_rest: Array[Basis] = []
var _helmet_tilt: Node3D
var _tap_t := 0.0


# ============================================================================= variant hooks
## The whole palette + helmet shape of one variant, in one place. Variant B overrides this.
func _spec() -> Dictionary:
	return {
		"suit": SUIT, "suit_dark": SUIT_DARK, "panel": PANEL, "scuff": SCUFF,
		"patch_a": PATCH_OCHRE, "patch_b": PATCH_SLATE,
		"helmet": HELMET, "helmet_rim": HELMET_RIM,
		## 2026-09-19: 40 x 20 -> 48 x 24 (+~190 triangles) so the big dent has enough vertices to
		## show as a notch in the outline instead of a blur (see DENTS)
		"head_segs": Vector2i(48, 24),
		"head_semi": HEAD_SEMI_A, "head_n": HEAD_N_A,
		"helmet_tilt": HELMET_TILT,
		"body_scale": 1.0,
		"crown_seam": false,      ## round 1: dropped for the 6000-triangle budget (216 tris)
		"boxy_brow": false,       ## B adds a squared brow visor hood
		"glove_r": PATCH_OCHRE,   ## mismatched right glove
		"boot_r": PATCH_SLATE,    ## mismatched right boot
		"visor_semi": VISOR_SEMI, "visor_inset": VISOR_INSET,
	}


## Anything a variant wants to ADD after the shared build (B bolts on its shoulder plates here).
func _variant_tweaks(_s: Dictionary) -> void:
	pass


# ============================================================================= build
func _init() -> void:
	super()
	var s := _spec()
	head_semi = s["head_semi"]
	head_n = s["head_n"]
	head_segs = s["head_segs"]
	body_scale = s["body_scale"]
	# the sole plate sits 2 mm under y = 0 on the shared chibi foot (ground probe); 3 mm of hover
	# puts every standing state on the ground instead of in it
	hover_height = 0.003
	# He has no eyes, so `blink_hold` and `face_scale` do nothing; left at the defaults on purpose
	# rather than set to a misleading value.


func _build_geometry() -> void:
	var s := _spec()
	_build_suit(s)
	_build_helmet(s)
	_build_limbs(s)
	_variant_tweaks(s)


# ---------------------------------------------------------------------------- suit
func _build_suit(s: Dictionary) -> void:
	var suit: Color = s["suit"]
	var dark: Color = s["suit_dark"]
	var torso_mi := _add_torso_bean(suit, {"chamfer_color": dark})
	# THE TROUSER BLOCK. Three clear value zones down the body (pale chest, mid panel, dark hips) is
	# the AC colour-blocking rule, and it is also the cheapest thing that separates him from the
	# player, whose suit is one near-white value from collar to boot.
	var hip_mi := _se_slab(_torso, Vector2(TORSO_RX * 1.005, TORSO_RZ * 1.005), TORSO_RY * 0.36, TORSO_N,
		_toon(dark, _matte({"rim": 0.02})), Vector3(0.0, TORSO_Y - TORSO_RY * 0.60, 0.0),
		"HipBlock", 20)
	# Chest panel: the suit's control box, flat and squared so the front is not one curve.
	_mi(superellipsoid(Vector3(0.112, 0.082, 0.030), 3.0, 12, 7), _toon(s["panel"], _matte({"rim": 0.02})),
		_torso, Vector3(0.0, TORSO_Y + 0.030, -TORSO_RZ * 0.92), "ChestPanel")
	# Backpack — the one thing that makes his BACK readable, and a different box from the player's.
	_mi(rounded_box(Vector3(0.200, 0.190, 0.098), 0.034, 10), _toon(s["panel"], _matte({"spec": 0.03})),
		_torso, Vector3(0.0, TORSO_Y + 0.010, TORSO_RZ * 0.86), "Pack")
	_mi(rounded_box(Vector3(0.060, 0.058, 0.030), 0.012, 8), _toon(s["patch_b"], _matte({"spec": 0.03})),
		_torso, Vector3(-0.052, TORSO_Y + 0.060, TORSO_RZ * 0.86 + 0.056), "PackLatch")
	_add_rags(s, [_soup(torso_mi), _soup(hip_mi)])


## RAGGED, the user's word ("His suit should look a bit ragged as well").
## 2026-09-19 polish: the round-2 rags were small FLAT discs (5 cm) in colours one value step from
## the suit, and at the 6.5 m phone camera none of them read (looked at, phone frame). Everything
## below is now a DECAL painted onto the real mesh (see `_decal`) — it follows the curve exactly,
## so it can be big without floating off the bean — and every mark is a VALUE step, not only a hue
## step, from what it sits on:
##   - a big mismatched PATCH on his right chest, with a dark stitched border round it;
##   - a jagged dark TEAR in the pale chest, with a paler flap of suit hanging out of it (dark on light);
##   - a TORN HEM: the pale suit's lower edge breaks into uneven tatters over the dark trousers;
##   - rubbed SCUFFS in the trouser colour; a second patch on his left side and one on his back.
## The frayed cuffs are on the arms (`_add_fringe`); the dent and helmet scuffs on the shell.
func _add_rags(s: Dictionary, soups: Array) -> void:
	var suit: Color = s["suit"]
	var dark: Color = s["suit_dark"]
	var ink := dark.darkened(0.36)           ## the tear's inside and the stitching
	var st_a := _decal_begin()
	var st_b := _decal_begin()
	var st_ink := _decal_begin()
	var st_scuff := _decal_begin()
	var st_pale := _decal_begin()
	# PATCHES: [yaw deg, height, polygon, surface tool, roll]. A dark border 20 % bigger sits under
	# each one, and a few stitches cross the border, so it reads as sewn on and not as a pocket.
	var p_chest := PackedVector2Array([Vector2(-0.044, -0.034), Vector2(-0.004, -0.040), Vector2(0.042, -0.036),
		Vector2(0.046, 0.030), Vector2(0.006, 0.038), Vector2(-0.040, 0.034)])
	var p_side := PackedVector2Array([Vector2(-0.040, -0.036), Vector2(0.036, -0.040), Vector2(0.042, 0.032),
		Vector2(-0.036, 0.040)])
	var p_back := PackedVector2Array([Vector2(-0.046, -0.030), Vector2(0.040, -0.036), Vector2(0.046, 0.034),
		Vector2(-0.040, 0.038)])
	var patches := [
		[53.0, 0.468, p_chest, st_a, 0.12],
		[-92.0, 0.440, p_side, st_b, -0.16],
		[168.0, 0.500, p_back, st_a, 0.22],
	]
	for row: Array in patches:
		var ray := _torso_ray(row[0], row[1])
		var poly: PackedVector2Array = row[2]
		var rot: float = row[4]
		_decal(st_ink, _fan2d(_scaled2d(poly, 1.20), 2, rot), soups, ray, 0.003, 0.08)
		_decal(row[3], _fan2d(poly, 2, rot), soups, ray, 0.0055, 0.08)
		# stitches: short dark bars straddling the patch edge, at uneven spacing
		for k: float in [0.12, 0.45, 0.70, 0.93]:
			var i := int(k * poly.size()) % poly.size()
			var a := poly[i].lerp(poly[(i + 1) % poly.size()], fmod(k * 3.7, 1.0))
			var out := a.normalized() * 0.011
			_decal(st_ink, _ribbon2d(PackedVector2Array([(a - out).rotated(rot), (a + out).rotated(rot)]), 0.005, 0.005),
				soups, ray, 0.0075, 0.08)
	# THE TEAR — a jagged gash in the pale chest, on his left (clear of the chest panel), and a flap of
	# the suit, a shade paler, hanging down out of it.
	var gash := PackedVector2Array([Vector2(-0.056, 0.002), Vector2(-0.036, 0.018), Vector2(-0.016, 0.012),
		Vector2(0.000, 0.030), Vector2(0.018, 0.016), Vector2(0.036, 0.024), Vector2(0.058, 0.000),
		Vector2(0.034, -0.016), Vector2(0.014, -0.012), Vector2(-0.004, -0.026), Vector2(-0.022, -0.012),
		Vector2(-0.040, -0.010)])
	var tear_ray := _torso_ray(-46.0, 0.478)
	_decal(st_ink, _fan2d(gash, 2, -0.30), soups, tear_ray, 0.004, 0.07)
	var flap := PackedVector2Array([Vector2(-0.020, 0.010), Vector2(0.016, 0.006), Vector2(0.010, -0.030),
		Vector2(-0.004, -0.038), Vector2(-0.016, -0.020)])
	_decal(st_pale, _fan2d(flap, 1, -0.30, Vector2(0.008, -0.014)), soups, tear_ray, 0.006, 0.07)
	# THE TORN HEM — a band of pale suit laid over the line where the suit meets the dark trousers,
	# with an UNEVEN bottom edge: mostly short, a few long tatters, never a regular zig-zag.
	_add_hem(st_pale, soups)
	# SCUFFS: long rubbed streaks in the trouser colour, the layer under the worn-through pale one.
	var scuffs := [
		[74.0, 0.392, PackedVector2Array([Vector2(-0.046, 0.012), Vector2(-0.008, 0.000), Vector2(0.042, -0.014)]), 0.013],
		[-30.0, 0.372, PackedVector2Array([Vector2(-0.040, -0.006), Vector2(0.004, 0.004), Vector2(0.044, 0.012)]), 0.011],
		[205.0, 0.430, PackedVector2Array([Vector2(-0.050, 0.012), Vector2(0.050, -0.010)]), 0.012],
	]
	for row: Array in scuffs:
		var w: float = row[3]
		_decal(st_scuff, _ribbon2d(row[2], w, w * 0.45), soups, _torso_ray(row[0], row[1]), 0.004, 0.07)
	_decal_commit(st_a, s["patch_a"], _torso, "Patch")
	_decal_commit(st_b, Color(s["patch_b"]).lightened(0.18), _torso, "PatchB")
	_decal_commit(st_ink, ink, _torso, "TearInk")
	_decal_commit(st_scuff, dark, _torso, "Scuff")
	_decal_commit(st_pale, suit.lightened(0.10), _torso, "Hem")


## The torn hem. Columns every ~10 deg (unevenly) round the front and sides; each has a top row just
## above the pale/dark seam, a middle row just below it, and a bottom point at its own depth.
const HEM_COLS := [
	## [yaw deg, tatter depth below the seam m]
	[-118.0, 0.004], [-106.0, 0.012], [-97.0, 0.006], [-86.0, 0.024], [-78.0, 0.018], [-70.0, 0.005],
	[-59.0, 0.009], [-50.0, 0.016], [-41.0, 0.030], [-34.0, 0.012], [-22.0, 0.004], [-12.0, 0.010],
	[-3.0, 0.004], [8.0, 0.014], [17.0, 0.026], [26.0, 0.008], [37.0, 0.005], [48.0, 0.012],
	[58.0, 0.028], [66.0, 0.014], [77.0, 0.005], [88.0, 0.020], [100.0, 0.008], [116.0, 0.004],
]
const HEM_Y0 := 0.30

func _add_hem(st: SurfaceTool, soups: Array) -> void:
	var tris := PackedVector2Array()
	var col: Array[PackedVector2Array] = []
	for c: Array in HEM_COLS:
		var u := deg_to_rad(float(c[0])) * TORSO_ARC_R
		var seam := _hem_seam_y(float(c[0])) - HEM_Y0
		col.append(PackedVector2Array([Vector2(u, seam + 0.014), Vector2(u, seam - 0.004),
			Vector2(u, seam - 0.004 - float(c[1]))]))
	for i in col.size() - 1:
		var a := col[i]
		var b := col[i + 1]
		for r in 2:
			tris.append_array([a[r], a[r + 1], b[r + 1], a[r], b[r + 1], b[r]])
	_decal(st, tris, soups, _torso_ray(0.0, HEM_Y0), 0.004, 0.0)


## Where the pale torso disappears into the dark hip block along `yaw_deg`: the height at which the
## torso's surface point falls inside the hip slab. Both are the same analytic superellipsoids
## `_add_torso_bean` and `_build_suit` build, so this is exact to their tessellation (a few mm).
static func _hem_seam_y(yaw_deg: float) -> float:
	var d := Vector2(sin(deg_to_rad(yaw_deg)), -cos(deg_to_rad(yaw_deg)))
	var n := TORSO_N
	var slab_y := TORSO_Y - TORSO_RY * 0.60
	var thick := TORSO_RY * 0.36
	var lo := slab_y
	var hi := TORSO_Y
	var den := pow(absf(d.x) / TORSO_RX, n) + pow(absf(d.y) / TORSO_RZ, n)
	for _i in 18:
		var y := (lo + hi) * 0.5
		var rho := pow(maxf(1.0 - pow(absf(y - TORSO_Y) / TORSO_RY, n), 0.0) / den, 1.0 / n)
		var f := pow(absf(d.x * rho) / (TORSO_RX * 1.005), n) + pow(absf(y - slab_y) / thick, n) \
			+ pow(absf(d.y * rho) / (TORSO_RZ * 1.005), n)
		if f < 1.0:
			lo = y
		else:
			hi = y
	return lo


# ---------------------------------------------------------------------------- decals
## A DECAL here is a thin painted shape laid ON an existing mesh: it is drawn as 2-D triangles
## (metres; u along the surface to his right, v up), each 2-D point is turned into a ray by a
## `ray` Callable, and the ray is intersected with the target mesh's REAL triangles (the "soup").
## The decal vertex is the outermost hit lifted `lift` along the mesh's own interpolated normal, and
## it takes that normal too, so it shades exactly like the surface under it. A flat disc (round 2)
## on a 12-sided bean floats ~1 cm off at its edges once it is big enough to read at 6.5 m.
## Built once per model; the ray tests are pre-filtered to the triangles near each decal.
const TORSO_ARC_R := 0.205   ## metres of surface per radian of yaw on the bean (its mean radius)

## Triangle soup of a mesh instance in its PARENT's space: [positions, normals], three per triangle.
static func _soup(mi: MeshInstance3D) -> Array:
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null:
		idx = arr[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		for i in v.size():
			idx.append(i)
	var xf := mi.transform
	var nb := xf.basis.inverse().transposed()
	var pp := PackedVector3Array()
	var nn := PackedVector3Array()
	for i in idx:
		pp.append(xf * v[i])
		nn.append((nb * nr[i]).normalized())
	return [pp, nn]


## The soups cut down to the triangles near `c` (a decal only ever lands within `radius` of its
## centre), so a decal costs a few hundred ray tests instead of thousands.
static func _soups_near(soups: Array, c: Vector3, radius: float) -> Array:
	var out := []
	var r2 := radius * radius
	for soup: Array in soups:
		var pp: PackedVector3Array = soup[0]
		var nn: PackedVector3Array = soup[1]
		var sp := PackedVector3Array()
		var sn := PackedVector3Array()
		for t in range(0, pp.size(), 3):
			if pp[t].distance_squared_to(c) < r2 or pp[t + 1].distance_squared_to(c) < r2 \
					or pp[t + 2].distance_squared_to(c) < r2:
				sp.append_array([pp[t], pp[t + 1], pp[t + 2]])
				sn.append_array([nn[t], nn[t + 1], nn[t + 2]])
		out.append([sp, sn])
	return out


## The OUTERMOST hit of the ray on any soup: [point, interpolated normal], or [] on a miss.
static func _ray_soups(soups: Array, o: Vector3, d: Vector3) -> Array:
	var best := -1.0
	var bp := Vector3.ZERO
	var bn := Vector3.ZERO
	for soup: Array in soups:
		var pp: PackedVector3Array = soup[0]
		var nn: PackedVector3Array = soup[1]
		for t in range(0, pp.size(), 3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(o, d, pp[t], pp[t + 1], pp[t + 2])
			if hit == null:
				continue
			var h: Vector3 = hit
			var dist := (h - o).dot(d)
			if dist > best:
				best = dist
				bp = h
				var w := _bary(h, pp[t], pp[t + 1], pp[t + 2])
				bn = (nn[t] * w.x + nn[t + 1] * w.y + nn[t + 2] * w.z).normalized()
	return [] if best < 0.0 else [bp, bn]


static func _bary(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var den := d00 * d11 - d01 * d01
	if absf(den) < 1e-12:
		return Vector3(1.0, 0.0, 0.0)
	var v := (d11 * d20 - d01 * d21) / den
	var w := (d00 * d21 - d01 * d20) / den
	return Vector3(1.0 - v - w, v, w)


static func _decal_begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Lays 2-D triangles `tris` onto `soups`. `extent` > 0 pre-filters the soup round the decal's
## centre ray (0 = use the whole soup, for long decals like the hem).
static func _decal(st: SurfaceTool, tris: PackedVector2Array, soups: Array, ray: Callable,
		lift: float, extent: float) -> void:
	var use := soups
	if extent > 0.0:
		var r0: Array = ray.call(Vector2.ZERO)
		var h0 := _ray_soups(soups, r0[0], r0[1])
		if not h0.is_empty():
			use = _soups_near(soups, h0[0], extent + 0.10)
	var cache := {}
	for t in range(0, tris.size() - 2, 3):
		var hv: Array = []
		for k in 3:
			var p2 := tris[t + k]
			if not cache.has(p2):
				var r: Array = ray.call(p2)
				cache[p2] = _ray_soups(use, r[0], r[1])
			hv.append(cache[p2])
		if (hv[0] as Array).is_empty() or (hv[1] as Array).is_empty() or (hv[2] as Array).is_empty():
			continue
		var pts: Array[Vector3] = []
		var nrm: Array[Vector3] = []
		for h: Array in hv:
			nrm.append(h[1])
			pts.append((h[0] as Vector3) + (h[1] as Vector3) * lift)
		# Godot's front face: `(b - a) x (c - a)` points INTO the surface (see `_tri_out`)
		if (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(nrm[0] + nrm[1] + nrm[2]) > 0.0:
			pts = [pts[0], pts[2], pts[1]]
			nrm = [nrm[0], nrm[2], nrm[1]]
		for k in 3:
			st.set_normal(nrm[k])
			st.set_uv(Vector2.ZERO)
			st.add_vertex(pts[k])


func _decal_commit(st: SurfaceTool, color: Color, parent: Node3D, node_name: String) -> MeshInstance3D:
	return _mi(st.commit(), _toon(color, _matte({"rim": 0.0, "spec": 0.0})), parent, Vector3.ZERO, node_name)


## A ray from the bean's vertical axis at height `y0 + v`, out along yaw `yaw0 + u / TORSO_ARC_R`.
static func _torso_ray(yaw0_deg: float, y0: float) -> Callable:
	var yaw0 := deg_to_rad(yaw0_deg)
	return func(p: Vector2) -> Array:
		var yaw := yaw0 + p.x / TORSO_ARC_R
		return [Vector3(0.0, y0 + p.y, 0.0), Vector3(sin(yaw), 0.0, -cos(yaw))]


## A ray from the helmet's centre (TILT-node space) through (yaw, pitch), offset by (u, v) metres.
func _shell_ray(yaw0_deg: float, pitch0_deg: float) -> Callable:
	var r := (head_semi.x + head_semi.y + head_semi.z) / 3.0
	var yaw0 := deg_to_rad(yaw0_deg)
	var pitch0 := deg_to_rad(pitch0_deg)
	return func(p: Vector2) -> Array:
		var yaw := yaw0 + p.x / (r * cos(pitch0))
		var pitch := pitch0 + p.y / r
		return [Vector3.ZERO, Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))]


## A fan over a star-shaped polygon, cut into `rings` bands so no triangle edge is long enough to
## sink into a curved surface. `rot` spins it and `at` moves it (both in the 2-D decal plane).
static func _fan2d(poly: PackedVector2Array, rings: int, rot: float = 0.0, at: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for k in rings:
		var f0 := float(k) / float(rings)
		var f1 := float(k + 1) / float(rings)
		for i in n:
			var p := poly[i]
			var q := poly[(i + 1) % n]
			var a1 := at + (p * f1).rotated(rot)
			var b1 := at + (q * f1).rotated(rot)
			if k == 0:
				out.append_array([at, a1, b1])
			else:
				var a0 := at + (p * f0).rotated(rot)
				var b0 := at + (q * f0).rotated(rot)
				out.append_array([a0, a1, b1, a0, b1, b0])
	return out


static func _scaled2d(poly: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p * k)
	return out


## A ribbon along a 2-D polyline, width tapering `w0` -> `w1`, mitred at every bend so the pieces
## share their edges and read as one line.
static func _ribbon2d(pts: PackedVector2Array, w0: float, w1: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	var side: Array[Vector2] = []
	for i in n:
		var d_in := (pts[i] - pts[i - 1]).normalized() if i > 0 else Vector2.ZERO
		var d_out := (pts[i + 1] - pts[i]).normalized() if i < n - 1 else Vector2.ZERO
		var d := (d_in + d_out).normalized()
		var w := lerpf(w0, w1, float(i) / float(maxi(n - 1, 1)))
		side.append(Vector2(-d.y, d.x) * w * 0.5)
	for i in n - 1:
		var a := pts[i] + side[i]
		var b := pts[i] - side[i]
		var c := pts[i + 1] - side[i + 1]
		var d2 := pts[i + 1] + side[i + 1]
		out.append_array([a, b, c, a, c, d2])
	return out


# ---------------------------------------------------------------------------- helmet
func _build_helmet(s: Dictionary) -> void:
	# `_add_head_shell` parents straight to `_head`, whose rotation is rewritten every frame, so the
	# shell is built by hand onto the tilt node instead.
	_helmet_tilt = _node("HelmetTilt", _head, Vector3.ZERO)
	_helmet_tilt.rotation = s["helmet_tilt"]
	var helmet: Color = s["helmet"]
	var rim: Color = s["helmet_rim"]
	# REAL DENTS pushed into the shell mesh (round 2). Round 1 faked them with flat dark facets laid
	# on the curve; only their middles cleared the shell, so each read as a pointed LEAF DECAL.
	# The dent is also DARKENED through vertex colour: the geometry alone measured invisible under the
	# toon ramp (looked at, round 2 close-up), because the ramp has too few bands for a 2 cm hollow.
	var shell_mat := MaterialLib.toon_vertex_color(_matte({"spec": 0.05})).duplicate() as ShaderMaterial
	shell_mat.set_shader_parameter("albedo", helmet)
	shell_mat.set_shader_parameter("shadow_floor", CHAR_SHADOW_FLOOR)
	shell_mat.set_shader_parameter("shade_floor", CHAR_SHADE_FLOOR)
	var shell := _mi(_dented_shell(head_semi, head_n, head_segs, DENTS), shell_mat, _helmet_tilt, Vector3.ZERO, "Shell")
	_add_helmet_wear(s, [_soup(shell)])
	if bool(s["crown_seam"]):
		var frac := pow(1.0 - pow(0.795, head_n), 1.0 / head_n)
		_se_slab(_helmet_tilt, Vector2(head_semi.x * 0.795, head_semi.z * 0.795) * SEAM_PROUD,
			head_semi.y * 0.10, head_n, _toon(rim, _matte({"rim": 0.02})),
			Vector3(0.0, head_semi.y * frac, 0.012), "CrownSeam", mini(head_segs.x, 30))
	# Repair tape just below the big dent — the clearest "this has been fixed by hand" read on the helmet.
	var tape := _node("Tape", _helmet_tilt, Vector3.ZERO)
	_place_on_shell(tape, 64.0, 34.0, 0.0)   ## ~31 deg (0.54 rad) from the big dent's centre, where exp(-(th/r)^8) is 0: the shell is undented
	var t1 := _mi(superellipsoid(Vector3(0.062, 0.013, 0.006), 2.4, 10, 5),
		_toon(s["patch_a"], _matte({"rim": 0.0})), tape, Vector3.ZERO, "TapeA")
	t1.rotation.z = 0.55
	var t2 := _mi(superellipsoid(Vector3(0.056, 0.012, 0.006), 2.4, 10, 5),
		_toon(s["patch_a"], _matte({"rim": 0.0})), tape, Vector3(0.006, -0.016, 0.0), "TapeB")
	t2.rotation.z = -0.32
	# Collar ring, at the base of the shell. It is the part that says "this is a HELMET on a body"
	# rather than "this is a head", and it sits on the BODY, not the tilt node, so a crooked helmet
	# visibly sits crooked ON a straight collar.
	_mi(torus(0.150, 0.208, 18, 7), _toon(rim, _matte({"spec": 0.06})),
		_torso, Vector3(0.0, head_y - head_semi.y * 0.88, 0.0), "Collar")
	_build_visor(s)


## The helmet's dents: [yaw deg, pitch deg, depth m, radius rad, (profile power, default 2),
## (wall shadow colour)]. Depth is a real inward push of the shell's vertices along their normals,
## and the normals are tilted by the push's slope, so the toon ramp shades the hollow too.
## The dent floor's colour multiplier (a soft, round, darker hollow; never a hard-edged decal).
## 2026-09-19 polish, round 3 (critic round 1: "the helmet dent does not read at the 6.5 m phone
## camera"): the big dent had been put at yaw -100, which is BEHIND the outline the default camera
## sees, so the front view showed a smooth dome and only the small dent's teal smudge. Measured by a
## yaw sweep in the front view at 6.5 m (yaw +95..110 = his right, the upper-LEFT edge on screen; yaw
## -110..-165 never reached the outline): the big dent now sits ON that outline, so it bites a notch
## out of the dome's silhouette. 170 mm deep at yaw 102, pitch 41. Profile exp(-(th / r)^8): a flat floor and a steep wall, i.e. a
## pressed-in bite with a crisp edge. Its floor is darkened, its UPPER wall (which faces down, out of
## the light) darker still, and its lower wall left lit, so the hollow is shaded by depth. The old
## fold-line decal is gone: at 6.5 m it read as a letter 'f'. The small crown dent (yaw 46) is gone
## too: it only ever showed as a teal smudge.
## It is deliberately NOT on the front of the dome: a mark above the visor sits where an eye would
## be, and the first try there (a curved crease) read as a closed, winking eye (looked at, 1.6 m).
const DENT_SHADE := Color(0.46, 0.50, 0.50)
const DENT_WALL := "#3e4a48"   ## the shadowed upper wall's multiplier (S 0.14; a grey, not a colour)
const DENTS := [
	[102.0, 41.0, 0.170, 0.28, 8.0, DENT_WALL],
	[-40.0, -14.0, 0.016, 0.20],
]


## The helmet's wear, painted onto the dented shell in one dark colour: two sets of short parallel
## SCRATCHES (the dent's old fold-line decal is gone, see DENTS) (parallel lines read as
## scratches; one long line on a dome reads as a brow).
func _add_helmet_wear(s: Dictionary, soups: Array) -> void:
	var st := _decal_begin()
	# scratches: [yaw, pitch, angle deg, lengths]
	for sc: Array in [[18.0, 56.0, 24.0, [0.070, 0.052, 0.036]], [-58.0, -4.0, -32.0, [0.048, 0.060]]]:
		var t2 := PackedVector2Array()
		var ang := deg_to_rad(float(sc[2]))
		var along := Vector2(cos(ang), sin(ang))
		var lens: Array = sc[3]
		for i in lens.size():
			var off := along.orthogonal() * (0.016 * float(i)) + along * (0.008 * float(i))
			var half := along * float(lens[i]) * 0.5
			t2.append_array(_ribbon2d(PackedVector2Array([off - half, off + half]), 0.007, 0.004))
		_decal(st, t2, soups, _shell_ray(sc[0], sc[1]), 0.003, 0.08)
	_decal_commit(st, Color(s["helmet_rim"]).darkened(0.32), _helmet_tilt, "HelmetWear")

## The helmet shell with DENTS pressed into it: every vertex within ~2.5 dent radii of a dent centre
## is pushed in along its normal by a Gaussian bump, and its normal is tilted by the bump's slope
## (a height field's normal is (-h', 1)), so the shading follows the dent instead of the old shape.
## Built per model (not cached): it is one mesh per Norm.
static func _dented_shell(semi: Vector3, n: float, segs: Vector2i, dents: Array) -> ArrayMesh:
	var arr: Array = superellipsoid(semi, n, segs.x, segs.y).surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var mean_r := (semi.x + semi.y + semi.z) / 3.0
	var cols := PackedColorArray()
	cols.resize(verts.size())
	cols.fill(Color.WHITE)
	for dent: Array in dents:
		var yaw := deg_to_rad(float(dent[0]))
		var pitch := deg_to_rad(float(dent[1]))
		var dc := se_point(Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)), semi, n).normalized()
		var depth: float = dent[2]
		var sigma: float = dent[3]
		var pw: float = float(dent[4]) if dent.size() > 4 else 2.0
		for i in verts.size():
			var u := verts[i].normalized()
			var th := acos(clampf(u.dot(dc), -1.0, 1.0))
			if th > sigma * 2.5:
				continue
			var g := exp(-pow(th / sigma, pw))
			var nrm := norms[i]
			verts[i] -= nrm * depth * g
			var away := u - dc
			away = (away - nrm * away.dot(nrm))
			# floor shade, plus the WALL on the dent's upper side (it faces down, out of the light)
			# darkened further, and the lower wall left lit: a hollow, shaded by where light falls
			var shade := DENT_SHADE
			if dent.size() > 5 and away.length() > 1e-6:
				var wall := 4.0 * g * (1.0 - g)          ## 1 on the wall, 0 on the floor and outside
				var upness := clampf(away.normalized().dot(Vector3.UP) * 1.4, -1.0, 1.0)
				shade = DENT_SHADE.lerp(Color(dent[5]), clampf(wall * upness, 0.0, 1.0))
				shade = shade.lerp(Color.WHITE, clampf(-wall * upness, 0.0, 1.0) * 0.25)
			cols[i] = cols[i] * Color(1.0, 1.0, 1.0).lerp(shade, g if dent.size() <= 5 else clampf(g * 1.6, 0.0, 1.0))
			if away.length() > 1e-6:
				var slope := depth * (pw * pow(th, pw - 1.0) / pow(sigma, pw)) * g / mean_r
				norms[i] = (nrm - away.normalized() * slope).normalized()
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


## `_orient_on_head` for a node parented to the TILT node instead of `_head` — same maths, same
## surface, so the helmet's furniture rides the crooked seat with it.
func _place_on_shell(node: Node3D, yaw_deg: float, pitch_deg: float, inset: float) -> void:
	var yaw := deg_to_rad(yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	var d := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var p := se_point(d, head_semi, head_n)
	var outward := se_normal(p, head_semi, head_n)
	node.position = p - outward * inset
	node.basis = Basis.looking_at(outward, Vector3.UP)


func _build_visor(s: Dictionary) -> void:
	var visor := _node("Visor", _helmet_tilt, Vector3.ZERO)
	_place_on_shell(visor, 0.0, VISOR_PITCH, s["visor_inset"])
	# Local axes here: +X right across the pane, +Y up it, -Z straight out of the face.
	_mi(superellipsoid(s["visor_semi"], 2.2, 16, 9),
		_toon(VISOR, _matte({"spec": 0.10, "spec_size": 60.0, "rim": 0.05})),
		visor, Vector3.ZERO, "Pane")
	# Rim ring over the pane/shell seam. Without it the intersection of two coarse superellipsoids
	# rendered as a jagged, torn edge (round 1 close-up), which read as damage in the wrong place.
	var vs: Vector3 = s["visor_semi"]
	var rim := _mi(torus(0.88, 1.0, 28, 6), _toon(s["helmet_rim"], _matte({"spec": 0.05})),
		visor, Vector3(0.0, 0.0, -0.004), "VisorRim")
	rim.rotation.x = PI * 0.5
	rim.scale = Vector3(vs.x * 1.0, 0.35, vs.y * 1.0)
	_add_crack(visor, s)


## THE CRACK — broken GLASS round the hole, never teeth.
## 2026-09-19 polish: round 2 ringed the hole with eleven pale points, evenly spread, long and white
## on the navy pane; with the orange strand coming out of the middle, the critic saw a mouth full of
## fangs in think, surprised and dance. Everything that made that read is removed:
##   - no ring: FOUR glass CHIPS with gaps of bare pane between them (angles 150-320 deg, the side the
##     strand does not cover), each a different size and each with a BLUNT, slanted outer edge,
##     never a point;
##   - they are shorter (at most 0.104 m from the hole's centre, was 0.140);
##   - the tint is a pale BLUE-GREY glass (`CRACK`), a clear step down from white;
##   - the crack lines run on from the chips, and two short cross-cracks join them (the "spider web"
##     every picture of broken glass has), which is the shape the eye reads as a cracked pane.
## All of it is flat ribbon lying 4 mm proud of the pane's own curved front, one mesh.
const CRACK_CHIPS := [
	## polygons in polar [angle deg from +x (his right), radius m] round the exit point; the inner
	## edge (radius CRACK_RIM_IN) is under the tentacle.
	[[150.0, 0.058], [178.0, 0.058], [176.0, 0.090], [161.0, 0.103], [152.0, 0.082]],
	[[196.0, 0.058], [214.0, 0.058], [213.0, 0.084], [201.0, 0.094]],
	[[236.0, 0.058], [263.0, 0.058], [266.0, 0.079], [250.0, 0.090], [240.0, 0.076]],
	[[298.0, 0.058], [316.0, 0.058], [313.0, 0.072], [302.0, 0.077]],
]
const CRACK_RIM_IN := 0.058      ## the tube's radius at the pane is ~0.075, so this edge is hidden
## Crack lines: [start (polar [deg, r] on a chip's outer edge), offsets FROM THE EXIT..., start width,
## end width]. They stay inside ~80 % of the pane.
const CRACK_LINES := [
	[[161.0, 0.100], [Vector2(-0.150, -0.040), Vector2(-0.180, -0.090), Vector2(-0.225, -0.100), Vector2(-0.245, -0.135)], 0.010, 0.003],
	[[250.0, 0.088], [Vector2(-0.045, -0.140), Vector2(-0.070, -0.165), Vector2(-0.060, -0.185)], 0.009, 0.003],
	[[176.0, 0.088], [Vector2(-0.140, 0.052), Vector2(-0.185, 0.060), Vector2(-0.215, 0.080)], 0.009, 0.003],
	[[307.0, 0.075], [Vector2(0.050, -0.100), Vector2(0.066, -0.132)], 0.008, 0.003],
]
## The two cross-cracks that join neighbouring lines (offsets from the exit).
const CRACK_WEB := [
	[Vector2(-0.176, -0.083), Vector2(-0.128, -0.118), Vector2(-0.066, -0.158)],
	[Vector2(-0.170, 0.056), Vector2(-0.192, 0.004), Vector2(-0.162, -0.042)],
]

func _add_crack(visor: Node3D, s: Dictionary) -> void:
	var semi: Vector3 = s["visor_semi"]
	var e: Vector2 = s.get("tent_exit", TENT_EXIT)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var behind := Vector3(e.x, e.y, 1.0)   ## any point well behind the pane: faces point away from it
	var tris := PackedVector2Array()
	# the chips: a fan from each chip's own middle (every chip is convex)
	for chip: Array in CRACK_CHIPS:
		var poly := PackedVector2Array()
		var mid := Vector2.ZERO
		for pr: Array in chip:
			var p := _polar(pr)
			poly.append(p)
			mid += p
		mid /= float(poly.size())
		for i in poly.size():
			tris.append_array([e + mid, e + poly[i], e + poly[(i + 1) % poly.size()]])
	# the lines, each starting ON a chip so the break is one connected thing
	for line: Array in CRACK_LINES:
		var pts := PackedVector2Array([e + _polar(line[0]) * 0.96])
		for p: Vector2 in line[1]:
			pts.append(e + p)
		tris.append_array(_ribbon2d(pts, line[2], line[3]))
	for web: Array in CRACK_WEB:
		var pts := PackedVector2Array()
		for p: Vector2 in web:
			pts.append(e + p)
		tris.append_array(_ribbon2d(pts, 0.006, 0.004))
	for t in range(0, tris.size() - 2, 3):
		_tri_out(st, _on_pane(tris[t], semi), _on_pane(tris[t + 1], semi), _on_pane(tris[t + 2], semi), behind)
	_mi(st.commit(), _toon(CRACK, _matte({"rim": 0.0, "spec": 0.0})), visor, Vector3.ZERO, "Crack")


static func _polar(pr: Array) -> Vector2:
	var a := deg_to_rad(float(pr[0]))
	return Vector2(cos(a), sin(a)) * float(pr[1])


## A point on the visor lens's curved front face, 4 mm proud, in visor-local space (-Z is out).
static func _on_pane(xy: Vector2, semi: Vector3) -> Vector3:
	return Vector3(xy.x, xy.y, -(_pane_front(xy, semi) + 0.004))


## How far the visor lens's front face stands from the pane's centre plane at (x, y).
static func _pane_front(xy: Vector2, semi: Vector3) -> float:
	var n := 2.2
	var u := pow(clampf(absf(xy.x) / semi.x, 0.0, 1.0), n) + pow(clampf(absf(xy.y) / semi.y, 0.0, 1.0), n)
	return semi.z * pow(maxf(1.0 - u, 0.0), 1.0 / n)


# ---------------------------------------------------------------------------- the big tentacle
## A joint chain rooted INSIDE the visor pane at the hole, with ONE smooth tube swept through it.
## Round-tipped, no suckers, no ridges: the brief is explicit that it must read friendly, never slimy.
func _build_tentacle() -> void:
	var s := _spec()
	var visor := _helmet_tilt.get_node("Visor") as Node3D
	var semi: Vector3 = s["visor_semi"]
	var e: Vector2 = s.get("tent_exit", TENT_EXIT)
	var seat := _node("TentSeat", _helmet_tilt, Vector3.ZERO)
	# the seat is ON the pane's front surface at the hole; the root runs back into the glass from it
	seat.position = visor.transform * Vector3(e.x, e.y, -_pane_front(e, semi))
	# +Y grows out of the hole (the sweep runs along +Y like every tube primitive); +Z is the curl
	# plane, because a positive rotation.x on a joint swings its +Y toward +Z. So positive bends =
	# the hook curls up and out to his right.
	var t0: Vector3 = (s.get("tent_out", TENT_OUT_DIR) as Vector3).normalized()
	var cz := (TENT_CURL_DIR - t0 * TENT_CURL_DIR.dot(t0)).normalized()
	seat.basis = Basis(t0.cross(cz).normalized(), t0, cz)
	_tent_pane_n = (seat.basis.inverse() * (visor.basis * Vector3(0.0, 0.0, -1.0))).normalized()
	# `rebuild()` frees the old joints but not these lists: without the clear, a second build swept
	# the tube through 24 joints (old chain + new) — a double-length strand, measured in the statue
	# bake (normchk fix 2026-09-19).
	_tent.clear()
	_tent_rest.clear()
	_tent_r.clear()
	_tent_idx = PackedInt32Array()
	var prev_len := 0.0
	var parent: Node3D = seat
	for i in TENT_SEGS.size():
		var row: Array = TENT_SEGS[i]
		var r_a: float = row[1]
		var r_b: float = TENT_SEGS[i + 1][1] if i + 1 < TENT_SEGS.size() else TENT_TIP_R
		for k in TENT_SUB:
			var length: float = float(row[0]) / float(TENT_SUB)
			var bend: float = float(row[2]) / float(TENT_SUB)
			var joint := _node("Tent%d_%d" % [i, k], parent, Vector3(0.0, prev_len, 0.0))
			joint.rotation.x = bend
			_tent.append(joint)
			_tent_rest.append(bend)
			_tent_r.append(lerpf(r_a, r_b, float(k) / float(TENT_SUB)))
			parent = joint
			prev_len = length
	_tent_last_len = prev_len
	_wave_bend = float(s.get("tent_wave_bend", 0.28))
	# ONE colour down the whole strand (round 1: a darker base and a paler tip block read as the
	# bands of a bendy straw).
	_tent_mesh = ArrayMesh.new()
	_tent_body = _mi(_tent_mesh, _toon(TENTACLE, _matte({"spec": 0.06})), seat, Vector3.ZERO, "TentBody")
	_rebuild_tent_mesh()


## Re-sweeps the tube through the joints' CURRENT pose. Called once per tick after the joints move,
## but only while he can be seen (`_tent_should_rebuild`).
## Cost: ~520 vertices of arithmetic and one surface upload; there is one Norm in the game.
func _rebuild_tent_mesh() -> void:
	if _tent_mesh == null:
		return
	# control points in TentSeat space: root (inside the glass), every joint origin, the tip end
	var ctrl := PackedVector3Array()
	var rad := PackedFloat32Array()
	ctrl.append(-_tent_pane_n * TENT_ROOT_SINK)
	rad.append(_tent_r[0] * 1.02)
	var m := Transform3D.IDENTITY
	for i in _tent.size():
		m = m * _tent[i].transform
		ctrl.append(m.origin)
		rad.append(_tent_r[i])
	ctrl.append(m * Vector3(0.0, _tent_last_len, 0.0))
	rad.append(TENT_TIP_R)
	# a Catmull-Rom curve THROUGH those points: tangent-continuous, so no joint has a crease
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	var last := ctrl.size() - 1
	for i in last:
		var p0 := ctrl[maxi(i - 1, 0)]
		var p1 := ctrl[i]
		var p2 := ctrl[i + 1]
		var p3 := ctrl[mini(i + 2, last)]
		var steps := 2 if i == 0 else TENT_SPAN_RINGS
		for k in steps:
			var t := float(k) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			pts.append(0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
			radii.append(lerpf(rad[i], rad[i + 1], t))
	pts.append(ctrl[last])
	radii.append(rad[last])
	tent_rebuilds += 1
	_tent_mesh.clear_surfaces()
	_tent_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _sweep_tent(pts, radii))


## `sweep_tube(pts, radii, TENT_SIDES, TENT_CAP_RINGS, Vector3.RIGHT)`, the same vertices in the same
## order, but without re-allocating anything per frame (normchk fix 2026-09-19: the per-frame sweep
## measured 0.166 ms a call headless, most of it building the 580-entry index list and UVs again from
## temporary arrays). Two exact rewrites of the per-vertex maths, no approximation:
##   * the side normal `(radial - tang * slope).normalized()`: `radial` is a unit vector at right
##     angles to the unit `tang`, so its length is exactly sqrt(1 + slope^2) for the whole ring;
##   * the cap normal `radial * cos + tang * sin` is already unit length.
func _sweep_tent(pts: PackedVector3Array, radii: PackedFloat32Array) -> Array:
	var sides := TENT_SIDES
	var cap_rings := TENT_CAP_RINGS
	var n := pts.size()
	var rings := n + cap_rings - 1
	var nv := rings * (sides + 1) + 1
	if _tent_idx.is_empty() or _tent_verts.size() != nv:
		var ref: Array = sweep_tube(pts, radii, sides, cap_rings, Vector3.RIGHT)
		_tent_idx = ref[Mesh.ARRAY_INDEX]
		_tent_uvs = ref[Mesh.ARRAY_TEX_UV]
		_tent_verts = ref[Mesh.ARRAY_VERTEX]
		_tent_norms = ref[Mesh.ARRAY_NORMAL]
		_tent_cs.resize(sides + 1)
		_tent_sn.resize(sides + 1)
		for j in sides + 1:
			_tent_cs[j] = cos(TAU * float(j) / float(sides))
			_tent_sn[j] = sin(TAU * float(j) / float(sides))
		_tent_arrays = ref
		return ref
	var verts := _tent_verts
	var norms := _tent_norms
	var cs := _tent_cs
	var sn := _tent_sn
	var n1 := Vector3.RIGHT
	var tang := Vector3.UP
	var w := 0
	for i in n:
		var ia := maxi(i - 1, 0)
		var ib := mini(i + 1, n - 1)
		tang = (pts[ib] - pts[ia]).normalized()
		n1 = (n1 - tang * n1.dot(tang)).normalized()
		var n2 := n1.cross(tang)
		var slope := (radii[ib] - radii[ia]) / maxf(pts[ib].distance_to(pts[ia]), 1e-5)
		var inv := 1.0 / sqrt(1.0 + slope * slope)
		var p := pts[i]
		var r := radii[i]
		var n1r := n1 * r
		var n2r := n2 * r
		var n1k := n1 * inv
		var n2k := n2 * inv
		var tk := tang * (slope * inv)
		for j in sides + 1:
			verts[w] = p + n1r * cs[j] + n2r * sn[j]
			norms[w] = n1k * cs[j] + n2k * sn[j] - tk
			w += 1
	var end := pts[n - 1]
	var re := radii[n - 1]
	var n2e := n1.cross(tang)
	for k in range(1, cap_rings):
		var phi := PI * 0.5 * float(k) / float(cap_rings)
		var cph := cos(phi)
		var sph := sin(phi)
		var c := end + tang * (re * sph)
		var a := n1 * cph
		var b := n2e * cph
		var ts := tang * sph
		for j in sides + 1:
			var rad := a * cs[j] + b * sn[j]
			verts[w] = c + rad * re
			norms[w] = rad + ts
			w += 1
	verts[w] = end + tang * re
	norms[w] = tang
	_tent_verts = verts
	_tent_norms = norms
	_tent_arrays[Mesh.ARRAY_VERTEX] = verts
	_tent_arrays[Mesh.ARRAY_NORMAL] = norms
	return _tent_arrays


## A SMOOTH TUBE along a polyline, with per-point radius and a hemisphere closing the far end; the
## near end is left OPEN (it is always buried: in the glass, or 12 mm inside a sleeve). Frames are
## parallel-transported, so the tube never twists, and normals are analytic (radial, tilted by the
## taper), so the toon ramp shades it as one continuous surface. Winding matches `taper_tube`.
static func sweep_tube(pts: PackedVector3Array, radii: PackedFloat32Array, sides: int,
		cap_rings: int, n1_start: Vector3) -> Array:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var cs := PackedFloat32Array()
	var sn := PackedFloat32Array()
	for j in sides + 1:
		cs.append(cos(TAU * float(j) / float(sides)))
		sn.append(sin(TAU * float(j) / float(sides)))
	var n := pts.size()
	var n1 := n1_start
	var tang := Vector3.UP
	for i in n:
		var ia := maxi(i - 1, 0)
		var ib := mini(i + 1, n - 1)
		tang = (pts[ib] - pts[ia]).normalized()
		n1 = (n1 - tang * n1.dot(tang)).normalized()
		var n2 := n1.cross(tang)
		var slope := (radii[ib] - radii[ia]) / maxf(pts[ib].distance_to(pts[ia]), 1e-5)
		for j in sides + 1:
			var radial := n1 * cs[j] + n2 * sn[j]
			verts.append(pts[i] + radial * radii[i])
			norms.append((radial - tang * slope).normalized())
			uvs.append(Vector2(float(i) / float(n), float(j) / float(sides)))
	var end := pts[n - 1]
	var r := radii[n - 1]
	var n2e := n1.cross(tang)
	for k in range(1, cap_rings):
		var phi := PI * 0.5 * float(k) / float(cap_rings)
		for j in sides + 1:
			var radial := n1 * cs[j] + n2e * sn[j]
			verts.append(end + tang * (r * sin(phi)) + radial * (r * cos(phi)))
			norms.append((radial * cos(phi) + tang * sin(phi)).normalized())
			uvs.append(Vector2(1.0, float(j) / float(sides)))
	var rings := n + cap_rings - 1
	for i in rings - 1:
		for j in sides:
			var a2 := i * (sides + 1) + j
			var b2 := (i + 1) * (sides + 1) + j
			idx.append_array([a2, b2 + 1, b2, a2, a2 + 1, b2 + 1])
	var pole := verts.size()
	verts.append(end + tang * r)
	norms.append(tang)
	uvs.append(Vector2(1.0, 0.5))
	var lr := (rings - 1) * (sides + 1)
	for j in sides:
		idx.append_array([lr + j, lr + j + 1, pole])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays


# ---------------------------------------------------------------------------- limbs
func _build_limbs(s: Dictionary) -> void:
	var suit: Color = s["suit"]
	var dark: Color = s["suit_dark"]
	_add_arms(suit, suit.darkened(0.06))
	_add_legs(dark, dark.darkened(0.18))
	# MISMATCHED GLOVE AND BOOT. `_add_arms` / `_add_legs` colour both sides the same, so the right
	# hand and the right foot are repainted here. It is one of the loudest "ragged" cues there is
	# and it costs nothing.
	_repaint(_hand_r, ["Mitten"], s["glove_r"], {"spec": 0.02})
	_repaint(_leg_r, ["Foot", "ToeCap"], s["boot_r"], {"spec": 0.06})
	_repaint(_leg_r, ["Sole"], Color(s["boot_r"]).darkened(0.34), {"spec": 0.0})
	var fringe := Color(s["suit"]).lightened(0.30)
	for arm: Node3D in [_arm_l, _arm_r]:
		_add_fringe(arm, fringe, 1.0 if arm == _arm_r else -1.0)
	_build_pokers(s)
	_build_tentacle()


static func _repaint(root: Node3D, names: Array, color: Color, opts: Dictionary) -> void:
	for n: String in names:
		var mi := root.get_node_or_null(NodePath(n)) as MeshInstance3D
		if mi != null:
			mi.material_override = _toon(color, _matte(opts))


## FRAYED CUFF. 2026-09-19 polish: round 2's two 3 mm threads were invisible at 6.5 m. Now the
## sleeve ends in a pale, RAGGED FRINGE that hangs over the top of the mitten: a short skirt whose
## bottom edge is cut to uneven lengths (a few long tatters, mostly short), in a paler thread tone so
## it shows on both the ochre glove and the suit-coloured one.
##
## WHERE THE SLEEVE ENDS. The sleeve capsule (r 0.055) meets the mitten (a 0.076 x 0.081 x 0.068
## superellipsoid centred 0.205 m down the arm) at ~0.137 m; the chibi's "Cuff" ring sits INSIDE the
## mitten and never shows. So the fringe starts hidden inside the sleeve at 0.118 m, comes out at
## the seam, and every tatter tip is placed 7 mm outside the mitten's own surface at that height —
## computed from the mitten's formula, not tuned — so no pose can push the glove through it (the
## hand never moves relative to the arm).
const FRINGE_TOP := 0.118
const FRINGE_SEAM := 0.137
## [angle deg round the arm (0 = front, + = outward for the right arm), tatter length below the seam m]
const FRINGE_COLS := [
	[0.0, 0.014], [27.0, 0.030], [52.0, 0.012], [80.0, 0.022], [104.0, 0.040], [131.0, 0.016],
	[160.0, 0.010], [188.0, 0.026], [214.0, 0.013], [243.0, 0.034], [270.0, 0.018], [300.0, 0.011],
	[331.0, 0.024],
]

func _add_fringe(arm: Node3D, color: Color, side: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hand_y := -ARM_LEN - 0.030
	var rows: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array(), PackedVector3Array()]
	var cols := FRINGE_COLS.size()
	for i in cols + 1:
		var c: Array = FRINGE_COLS[i % cols]
		var a := deg_to_rad(float(c[0])) * side
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var y_tip := -FRINGE_SEAM - float(c[1])
		rows[0].append(Vector3(0.0, -FRINGE_TOP, 0.0) + dir * 0.050)
		rows[1].append(Vector3(0.0, -FRINGE_SEAM, 0.0) + dir * (maxf(_mitten_r(dir, -FRINGE_SEAM - hand_y), 0.046) + 0.007))
		rows[2].append(Vector3(0.0, y_tip, 0.0) + dir * (_mitten_r(dir, y_tip - hand_y) + 0.007))
	for i in cols:
		for r in 2:
			var axis_a := Vector3(0.0, rows[r][i].y, 0.0)
			_tri_out(st, rows[r][i], rows[r + 1][i], rows[r + 1][i + 1], axis_a)
			_tri_out(st, rows[r][i], rows[r + 1][i + 1], rows[r][i + 1], axis_a)
	_mi(st.commit(), _toon(color, _matte({"rim": 0.0, "spec": 0.0})), arm, Vector3.ZERO, "Fringe")


## The mitten's horizontal radius along `dir` at height `dy` above its centre (the same
## superellipsoid `_add_arms` builds: semi HAND_R, HAND_R * 1.06, HAND_R * 0.90, exponent HAND_N).
static func _mitten_r(dir: Vector3, dy: float) -> float:
	var sy := HAND_R * 1.06
	var k := pow(maxf(1.0 - pow(absf(dy) / sy, HAND_N), 0.0), 1.0 / HAND_N)
	var den := pow(absf(dir.x) / HAND_R, HAND_N) + pow(absf(dir.z) / (HAND_R * 0.90), HAND_N)
	return k * pow(den, -1.0 / HAND_N)


## The eight small tentacles that come out of the suit at the arms and legs.
## Round 2: round 1's tapered tube + separate ball read as orange CARROT STICKS at close-up — a
## pointed taper, a seam, and a bud the same width as the stick. Now each is one short, fat, smooth
## tube (the same sweep as the big one) that SWELLS into a round head: a little round-headed worm.
## They are also the big tentacle's paler tip tone, because at their size the toon shade band
## covers more of them and the base orange rendered redder than the big strand.
func _build_pokers(_s: Dictionary) -> void:
	# `rebuild()` frees the old nodes but not these lists; without the clear a second build keeps the
	# freed strands in them (the statue bake calls rebuild() on an already-built model).
	_pokers.clear()
	_poker_rest.clear()
	var parents: Array[Node3D] = [_arm_l, _arm_r, _leg_l, _leg_r]
	var m_out := _toon(TENTACLE_TIP, _matte({"spec": 0.05}))
	for i in POKERS.size():
		var row: Array = POKERS[i]
		var parent: Node3D = parents[int(row[0])]
		var dir: Vector3 = (row[2] as Vector3).normalized()
		# seated 12 mm INSIDE the limb, so a retracted strand is entirely under the suit
		var n := _node("Poker%d" % i, parent, (row[1] as Vector3) - dir * 0.012)
		var rest := _basis_from_up(dir)
		n.basis = rest
		_mi(_poker_mesh(float(row[3]) * 1.9, float(row[4]) * 2.3), m_out, n, Vector3.ZERO, "Strand")
		n.set_meta("period", 4.1 + 0.83 * float(i) + 0.31 * float(i % 3))
		n.set_meta("phase", fmod(0.618 * float(i + 1), 1.0))
		_pokers.append(n)
		_poker_rest.append(rest)
	_apply_pokers(0.0)


## One small tentacle: a straight smooth tube that narrows a little and then swells into a round
## head. 9 sides, 4 body rings + 3 cap rings = 99 triangles; cached per size.
static func _poker_mesh(length: float, r0: float) -> ArrayMesh:
	var key := "norm_poker|%.4f|%.4f" % [length, r0]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var head := r0 * 0.95
	var body := length - head
	var pts := PackedVector3Array([Vector3.ZERO, Vector3(0.0, body * 0.40, 0.0),
		Vector3(0.0, body * 0.75, 0.0), Vector3(0.0, body, 0.0)])
	var radii := PackedFloat32Array([r0, r0 * 0.82, r0 * 0.86, head])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sweep_tube(pts, radii, 9, 3, Vector3.RIGHT))
	_mesh_cache[key] = mesh
	return mesh


# ============================================================================= animation
func _animate_extras(delta: float) -> void:
	_tap_t += delta
	_animate_tentacle()
	if _tent_should_rebuild():
		_rebuild_tent_mesh()
	_apply_pokers(clampf(pose(P.EXTRA_B), 0.0, 1.0))


## HEAT (2026-09-19). The tube re-sweep costs 0.17 ms a frame on the desktop (round 2, headless), and
## it ran every frame wherever Norm was, on screen or not. Now it only runs when he could be SEEN:
## visible in the tree, within TENT_LIVE_DIST of the camera, and the strand's bounding sphere inside
## the camera's frustum. Otherwise the tube HOLDS its last shape. The joints keep animating (they
## are a few Basis writes), so the frame he comes back into view the tube is re-swept from the pose
## he is in NOW — it looks exactly as if it had never stopped.
## With no camera at all (a headless QA probe) there is nothing to judge by, so it keeps rebuilding.
const TENT_LIVE_DIST := 20.0
## The strand's reach from its seat: 0.765 m of joints + the 0.041 m tip, rounded up, plus 0.3 m of
## slack because the camera rig moves AFTER the NPCs in the frame (one frame of camera travel).
const TENT_REACH := 1.1
## QA counter: how many times the tube has been re-swept (the critic's probe reads it).
var tent_rebuilds := 0

func _tent_should_rebuild() -> bool:
	if _tent_body == null or not is_inside_tree():
		return true
	if not is_visible_in_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return true
	var c := _tent_body.global_position
	if cam.global_position.distance_to(c) > TENT_LIVE_DIST:
		return false
	var r := TENT_REACH * _tent_body.global_basis.get_scale().x
	for pl: Plane in cam.get_frustum():
		if pl.distance_to(c) > r:
			return false
	return true


## EXTRA_A is the tentacle's ACT CHANNEL, and it is the whole performance:
##    0  idle sway        1  talk bob        2  wave (he waves with it, then hides it)
##    3  tap the helmet   -1 clamp it rigid (the "dance like a human" lie)
##    4  flail (happy / surprised — the only time he stops pretending)
## `pose()` is a blended float, so the modes cross-fade into each other instead of snapping.
func _animate_tentacle() -> void:
	if _tent.is_empty():
		return
	var act := pose(P.EXTRA_A)
	var rigid := clampf(-act, 0.0, 1.0)                       ## -1 -> 1
	var talk := clampf(act, 0.0, 1.0) * clampf(2.0 - act, 0.0, 1.0)
	var wave := clampf(act - 1.0, 0.0, 1.0) * clampf(3.0 - act, 0.0, 1.0)
	var tap := clampf(act - 2.0, 0.0, 1.0) * clampf(4.0 - act, 0.0, 1.0)
	var flail := clampf(act - 3.0, 0.0, 1.0)
	var idle := clampf(1.0 - rigid - wave - tap - flail, 0.0, 1.0)
	for i in _tent.size():
		var j := _tent[i]
		# the tip moves most; halved per joint because there are twice as many joints as rows
		var w := 0.5 * (0.35 + 1.5 * float(i) / float(maxi(_tent.size() - 1, 1)))
		var ph := _time * TAU
		var bend := 0.0
		var yaw := 0.0
		bend += idle * 0.085 * w * sin(ph / 2.6 + float(i) * 0.7)
		yaw += idle * 0.070 * w * sin(ph / 3.4 + float(i) * 1.1)
		bend += talk * 0.13 * w * sin(ph * 1.05 + float(i) * 0.8)
		# the wave: a wide side-to-side sweep, so it reads as a HAND wave done with the wrong limb
		yaw += wave * 0.52 * w * sin(ph * 1.6)
		bend += wave * (_wave_bend * w - 0.10 * w * cos(ph * 1.6))
		# the tap: curl back toward the helmet and knock, twice a second
		# round 1: the old NEGATIVE bend straightened the hook out sideways and it never touched the
		# helmet. A positive bend folds the hook back over his crown, and the knock rides on top.
		bend += tap * (0.30 * w + 0.10 * w * maxf(0.0, sin(ph * 2.0)))
		bend += flail * 0.40 * w * sin(ph * 2.4 + float(i) * 1.4)
		yaw += flail * 0.34 * w * sin(ph * 3.1 + float(i) * 0.9)
		# rigid: he holds it as still as a person holds an arm they are pretending is not there,
		# and fails once a bar (the 0.05 term).
		var amp := 1.0 - 0.92 * rigid
		var betray := rigid * 0.05 * w * maxf(0.0, sin(ph / 2.0) - 0.85) * 7.0
		j.rotation.x = _tent_rest[i] + bend * amp + betray
		j.rotation.z = yaw * amp


## Each strand's own poke cycle, plus a floor from EXTRA_B (1.0 = everything out at once).
func _apply_pokers(forced: float) -> void:
	for i in _pokers.size():
		var n := _pokers[i]
		var period: float = n.get_meta("period", 5.0)
		var phase: float = n.get_meta("phase", 0.0)
		var u := fposmod(_time / period + phase, 1.0)
		# a smooth bump that is 1 at the middle of its window and 0 everywhere else
		var own := 0.0
		if u < POKE_OUT_FRAC:
			own = sin(PI * u / POKE_OUT_FRAC)
		var poke := maxf(own, forced)
		n.transform.basis = _poker_rest[i].scaled(Vector3(1.0, lerpf(POKE_MIN, 1.0, poke), 1.0))


# ============================================================================= the act
## He tries to move like a human and slips. Each override calls the chibi pose first, so the body
## still reads as one of the neighbours, then bends it toward "a person doing this on purpose".
func _pose_idle(p: PackedFloat32Array) -> void:
	super(p)
	# a HUMAN stands still, so he over-corrects: less sway than anyone else in the cast
	p[P.TORSO_ROLL] *= 0.45
	p[P.HEAD_ROLL] *= 0.45
	p[P.EXTRA_A] = 0.0


## TOE DIP (round 1, vertex-exact probe qa_norm/ground.tscn): the shared chibi walk plants a foot that
## reaches ~0.15 m ahead of its pivot, and at full stride its toe went 31 mm into the ground; happy and
## surprised kick the legs and dipped 13 / 11 mm. Same (1 - cos)-style lift Pop uses, from the leg's
## own pitch, so it adds nothing when the foot is flat.
const TOE_REACH := FOOT_R * 1.22 + 0.030

func _toe_lift(p: PackedFloat32Array) -> void:
	p[P.LEG_L_LIFT] += TOE_REACH * absf(sin(p[P.LEG_L_PITCH]))
	p[P.LEG_R_LIFT] += TOE_REACH * absf(sin(p[P.LEG_R_PITCH]))


func _pose_walk(p: PackedFloat32Array) -> void:
	super(p)
	_toe_lift(p)


func _pose_talk(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	p[P.EXTRA_A] = 1.0


## FIRST HE WAVES WITH THE TENTACLE, THEN HE REMEMBERS. The switch is at 55 % of the 1.4 s emote.
func _pose_wave(p: PackedFloat32Array, t: float) -> void:
	var swap := 0.55 * EMOTE_DURATIONS["wave"]
	var human := clampf((t - swap) / 0.22, 0.0, 1.0)
	_pose_idle(p)
	# the hand wave, faded IN over the second half only
	var w := sin(TAU * (t - swap) * 3.6)
	p[P.ARM_R_ROLL] = lerpf(ARM_REST_ROLL, 2.35 + 0.4 * w, human)
	p[P.ARM_R_PITCH] = -0.2 * human
	p[P.ARM_R_YAW] = 0.28 * w * human
	p[P.HEAD_ROLL] = -0.16 * human
	p[P.HEAD_YAW] = 0.10
	p[P.TORSO_ROLL] = 0.07 * human
	# ...and a small flinch as he switches: the body drops a beat when he realises
	p[P.BODY_Y] += -0.022 * sin(PI * clampf((t - swap) / 0.30, 0.0, 1.0))
	p[P.EXTRA_A] = lerpf(2.0, 0.0, human)


## TAPPING HIS HELMET WITH THE TENTACLE. The arms deliberately stay down: a human would raise a
## hand, and he has not thought of that.
func _pose_think(p: PackedFloat32Array, t: float) -> void:
	_pose_idle(p)
	var u := clampf(t / 0.4, 0.0, 1.0)
	p[P.ARM_L_ROLL] = ARM_REST_ROLL + 0.04
	p[P.ARM_R_ROLL] = ARM_REST_ROLL + 0.04
	p[P.HEAD_ROLL] = 0.18 * u
	p[P.HEAD_PITCH] = -0.10 * u
	p[P.HEAD_YAW] = -0.22 * u
	p[P.TORSO_PITCH] = 0.05 * u
	p[P.EXTRA_A] = 3.0 * u


func _pose_happy(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	_toe_lift(p)
	p[P.EXTRA_A] = 4.0
	p[P.EXTRA_B] = 0.45          ## a few strands escape while he bounces


## A STIFF "HUMAN" DANCE. Square, on the beat, no waddle roll, no squash — the opposite of the
## villager bop every other neighbour does, which is exactly the joke.
func _pose_dance(p: PackedFloat32Array, t: float) -> void:
	var beat := TAU * t * 2.0
	var step := signf(sin(beat * 0.5))                ## a SQUARE wave: he snaps between two poses
	var settle := clampf(absf(sin(beat * 0.5)) * 6.0, 0.0, 1.0)
	p[P.BODY_Y] = 0.018 * absf(sin(beat))
	p[P.SQUASH] = 1.0
	p[P.TORSO_YAW] = 0.22 * step * settle
	p[P.TORSO_ROLL] = 0.0
	p[P.TORSO_PITCH] = 0.04
	p[P.ARM_L_ROLL] = 1.15 + 0.55 * clampf(step, 0.0, 1.0) * settle
	p[P.ARM_R_ROLL] = 1.15 + 0.55 * clampf(-step, 0.0, 1.0) * settle
	p[P.ARM_L_PITCH] = -0.35 * clampf(step, 0.0, 1.0) * settle
	p[P.ARM_R_PITCH] = -0.35 * clampf(-step, 0.0, 1.0) * settle
	p[P.LEG_L_LIFT] = 0.045 * clampf(step, 0.0, 1.0) * settle
	p[P.LEG_R_LIFT] = 0.045 * clampf(-step, 0.0, 1.0) * settle
	p[P.HEAD_YAW] = 0.16 * step * settle
	p[P.HEAD_ROLL] = 0.0
	p[P.EXTRA_A] = -1.0                               ## clamp the tentacle: nothing to see here
	p[P.EXTRA_B] = 0.0


## EVERY TENTACLE POPS OUT, THEN HE STUFFS THEM BACK IN. The pop is instant, the tuck takes 0.45 s.
func _pose_surprised(p: PackedFloat32Array, t: float) -> void:
	super(p, t)
	_toe_lift(p)
	var d: float = EMOTE_DURATIONS["surprised"]
	var tuck := clampf((t - 0.55 * d) / 0.45, 0.0, 1.0)
	p[P.EXTRA_B] = 1.0 - tuck
	p[P.EXTRA_A] = 4.0 * (1.0 - tuck)
	# the tuck itself: shoulders clamp down and the body shrinks, which is what selling the
	# "nobody saw that" beat needs
	p[P.ARM_L_ROLL] = lerpf(p[P.ARM_L_ROLL], 0.10, tuck)
	p[P.ARM_R_ROLL] = lerpf(p[P.ARM_R_ROLL], 0.10, tuck)
	p[P.SQUASH] = lerpf(p[P.SQUASH], 0.97, tuck)


# ============================================================================= QA
## MODEL SPACE, not world: `npc.gd` places the marker at `marker_clearance() * body_scale` while
## `ChibiModel.rebuild()` scales the model by the same factor, so body_scale cancels (see the same
## note in grig_model.gd and vela_model.gd).
##
## THE CROWN IS NOT AUTOMATICALLY THE HIGHEST POINT ON THIS MODEL: the big tentacle rears in walk,
## happy and think, and `BODY_Y` lifts the whole body in happy / surprised. Round 1 measured the
## worst case over all eight states (240 frames each, qa_norm/measure.tscn in the scratch copy):
## 1.638 m (surprised, the helmet at the top of the jump; the tentacle's own worst is 1.627 in
## happy). 1.660 = that + 22 mm.
## NORMCLIP fix 2026-09-19: the tentacle's OUT/CURL direction changed (it now rises up the crown
## first instead of out sideways first, to stop it reaching through the player's helmet — see
## TENT_CURL_DIR/TENT_OUT_DIR). Re-measured the same way (tests/tools/measure_norm_crowny.gd,
## headless, all 8 states, 240 frames each): the tentacle's own worst is now 1.665 (happy), 27 mm
## HIGHER than round 1's, because "straight up first" spends more of its reach on height instead of
## on lateral curl. 1.690 = that + ~25 mm, keeping the same safety-margin practice as round 1.
## npc.gd puts the "!" at +0.18 and its dot's lower edge ~0.05 above this, so the dot still clears
## everything by >= 65 mm.
const MARKER_TOP := 1.690

func marker_clearance() -> float:
	return MARKER_TOP
