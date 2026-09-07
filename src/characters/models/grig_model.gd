class_name GrigModel
extends ChibiModel
## Grig — the step-cutter of Grig's Chalk Steps. Older, slower and heavier than anyone else in the
## cast: he has quarried the terraces one riser at a time for longer than he will admit, numbers each
## one, and has firm views about where you put your feet.
##
## Built to docs/NEXT_WORLDS.md's "CREATURE grig" section. Five traits nothing shipped has:
##   1. ONE EYE. A single 0.112 m eyeball on ONE thick central stalk. Every existing neighbour has
##      exactly two (Zorp two matched stalks, Pip long+short, Pop two close-set, Mayor Orbit two on
##      goggle lenses, Bolt and DJ Nova two on a faceplate).
##   2. A TALL NARROW HEAD — 0.490 x 0.860 x 0.470 at n 3.2, nearly twice as tall as it is wide. The
##      geometric inverse of the one cached dome Zorp, Pip, Pop and Mayor Orbit used to share, and a
##      standing stone with a face, which ties him to his planet.
##   3. SQUARE BLUNT TEETH (three) and a TWO-lobed mitt, against everyone else's pointed rows and
##      three-or-zero fingers.
##   4. WORN STONE — a tally collar of chalk slabs on a cord, one notched per terrace cut. The rest
##      of the cast wears cloth (Zorp's scarf, the twins' aprons, the Mayor's waistcoat).
##   5. A LAGGING EYE-TRACK. The stalk arrives a beat after the head turns; nothing else in the cast
##      has a delayed feature, and on one huge eye it reads instantly as thought.
##
## Plus horizontal STRATA BANDS round the head that mirror the contour rings of his own world — the
## strongest available statement that the creature and the planet were designed together.

# ---------------------------------------------------------------------------------- palette
## R2.6 (pastel and matte). He must NOT vanish into his own world: the ground is cool grey chalk
## #b7b4a2 at S 0.115 V 0.718, so Grig separates by HUE (warm clay against cool chalk) and by VALUE
## (the smock and the boots are the dark anchors every AC villager has). No brass anywhere — aged
## brass is Mayor Orbit's, and the two would confuse at distance.
const SKIN := Color("#b99a7e")        ## warm stone-clay, S 0.319 V 0.725
const SKIN_DEEP := Color("#8d735c")   ## S 0.348 V 0.553 — strata, grooves, lid ridge, bare legs
const SCLERA := Color("#ece4d4")      ## the big pale eyeball, so the dark oval becomes a pupil
const EYE := Color("#241d18")
const GRIN := Color("#3a2b22")        ## mouth cavity
const TOOTH := Color("#efe7d6")
const SMOCK := Color("#64798a")       ## a slate-blue mason's smock — the one cool note
const SMOCK_DARK := Color("#4c5c6b")
const TALLY := Color("#cabfa6")       ## the chalk slabs
const FOOT := Color("#5a4f45")
const WEDGE := Color("#8b8578")       ## the cutting wedge at his hip

# ---------------------------------------------------------------------------------- head shape
## A head nearly twice as tall as it is wide with flat chamfered side planes. `head_y` puts the chin
## at 1.1010 - 0.4300 = 0.6710, which is EXACTLY Zorp's chin line (0.8963 - 0.2250), so the shared
## shoulder and collar geometry still meets it.
## R3.3 — REBALANCED. The first build was 490 x 860 mm, nearly twice as tall as wide, and it read as
## a vertical loaf with a small mouth floating on a large blank field — the exact complaint the user
## made about Zorp ("a lot of open space ... shrink that open space down more"). 550 x 660 keeps him
## clearly the TALLEST head in the cast, which is his silhouette, without the blank slab.
const HEAD_SEMI_GRIG := Vector3(0.2750, 0.3300, 0.2500)
const HEAD_N_GRIG := 3.2
## Holds the chin where it was: 1.1010 - 0.4300 = 0.6710, so 0.6710 + 0.3300.
const HEAD_Y_GRIG := 1.0010
## Tessellation. n 3.2 is exactly Zorp's proven exponent, so the DEFAULT (44, 22) would not facet —
## but Zorp's head is 0.45 m tall and this one is 0.86 m, so the same 13 latitude rings would stretch
## to 66 mm bands down the tall front plane. 38 x 26 resolves to 23 x 16 after ChibiModel.DETAIL and
## costs 782 tris against the default's 728. Do NOT raise `head_n` past 3.2 without raising these
## again: above ~3.2 the curvature packs into a narrow chamfer band and the shell renders as a box.
const HEAD_SEGS_GRIG := Vector2i(38, 26)

# ---------------------------------------------------------------------------------- the one eye
## An eyeball nearly twice Zorp's 0.058, on a stalk nearly twice his 0.026 radius: a thick neck-stalk
## carrying one huge eye rather than two delicate stems.
const EYEBALL_R := 0.112
const STALK_BASE := Vector3(0.006, 0.2574, -0.026)   ## head_semi.y * 0.78, just inside the crown
const STALK_TIP := Vector3(0.0, 0.560, -0.048)
const STALK_R := 0.052
## The LID RIDGE replaces both brow bars. One heavy arc hooding the top of the eyeball — the "quiet
## end of the AC range" cue R2.3 asks for, expressed once instead of twice. Radius 0.130 with a 0.018
## tube puts its inner edge at 0.112, exactly hugging the ball, and its outer edge at 0.148, which
## still clears the pupil at the 1.35x "surprised" widening.
const LID_RING_R := 0.130
const LID_TUBE := 0.018
const LID_TILT := -0.20
## How far the stalk is allowed to trail the head, and how fast it catches up.
## 2.8 rather than the first build's 3.4: measured on a real head turn the faster filter only trailed
## 0.053 rad, which on a 0.226 m stalk moves the eyeball 12 mm and does not read at all. At 2.8 an
## ordinary idle look-around reaches the 0.14 cap, which is 32 mm of drift on a 224 mm eyeball —
## visible as the eye arriving late, which is the whole trait.
const EYE_LAG_MAX := 0.14
const EYE_LAG_RATE := 2.8

# ---------------------------------------------------------------------------------- the mouth
## Small, low and square-toothed, because the head is tall. At the chibi default (-20 deg) the mouth
## would float in the middle of a 0.86 m blank plane and read as a nose; -46 puts it 0.198 m above
## the chin. Rendered grin width is 0.062 * 2 * 1.30 = 0.161 m = 33% of the 0.490 m head, which is
## over the style guide's 16-25% band — see the documented exemption for stalk-eyed neighbours in
## docs/NEXT_WORLDS.md (Zorp already ships at 44%, and with the eye up on a stalk the grin is the
## only thing that makes the blank head read as a face at all).
## Raised from -46: on the shorter head that put the mouth almost under his chin.
const MOUTH_PITCH_GRIG := -26.0
## Widened to fill the face, matching the ruling in docs/OPEN_ISSUES.md 35: on a stalk-eyed
## neighbour the grin is the ONLY thing on the head, so it has to carry it.
const MOUTH_SPREAD := Vector3(1.95, 1.70, 1.0)
const GRIN_SIZE := Vector3(0.062, 0.026, 0.018)
## Three teeth, blunt and near-SQUARE (0.020/0.024/0.018 wide against a 0.0161 height) rather than
## the pointed rows the rest of the cast wears. Odd count and uneven widths, per `_add_wide_grin`.
const GRIN_TEETH: Array = [[-0.038, 0.022], [-0.002, 0.026], [0.034, 0.020], [0.062, 0.016]]

# ---------------------------------------------------------------------------------- skin texture
## THE ZERO-SHADER-EDIT SKIN ROUTE, the same one AlienModel proved: `_matte()` duplicates the opts
## and only fills defaults, so `{"surface": ...}` travels intact through `_add_head_shell` into
## `MaterialLib.toon` and sets `surface_kind`, which is 0 on every neighbour and is why alien skin
## reads as flat plastic.
##
## KIND: `skin`, not `wood`. docs/NEXT_WORLDS.md specifies sd_wood for "horizontal strata" and that
## is not what sd_wood draws — its rings are contours of `length(wpos - g * dot(wpos, g))`, i.e.
## coaxial cylinders around the grain axis, so +Y gives VERTICAL bands wrapping the head and any
## other axis gives concentric rings centred on the ear line. Neither is strata, and at 26 * 0.30 =
## 7.8 cycles/m it would draw about 1.9 of them across the whole head. The horizontal banding is
## therefore built as real geometry instead (see `_add_strata`), and the shell gets the CELLULAR
## `skin` kind, weighted the opposite way from Zorp's: he is spot-dominant (blotches, an animal),
## Grig is EDGE-dominant (crazed cell walls, cracked chalk).
##
## FREQUENCY: sd_skin runs at 7 cycles/unit at scale 1.0, so 2.2 puts 15.4 cells/m — about 7.5
## across the 0.490 m head and 13 down its 0.860 m height. AMPLITUDE IS A PALETTE COST (an A/B on
## one frame moved a head crop's saturation mean by +0.099), so strength stays at 0.9; re-measure in
## src/world/world.tscn, never in a showcase, if it is raised.
const SURF_HEAD := {"surface": "skin", "surface_scale": 2.2, "surface_strength": 0.9,
	"surface_spot": 0.30, "surface_scales": 1.15, "surface_spot_radius": 0.30,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10, "surface_macro_cycles": 2.2,
	"seam_color": SKIN_DEEP}
## Limbs are far smaller than the head (a mitt is ~150 mm), so the head's setting would put barely
## one cell on a hand, and texture that stops at the jaw looks like a mask. But this is NOT the head
## preset scaled down: OPEN_ISSUES item 35 records that the head setting rendered the twins' arms as
## CAULIFLOWER, and names the culprit — the cell-EDGE term on a small, strongly curved capsule.
## Grig's head is deliberately edge-dominant, so his limbs are the one place that has to invert his
## own identity: edges nearly off (0.18 against the head's 1.15), spots carrying what little is
## there, finer and much weaker.
const SURF_LIMB := {"surface": "skin", "surface_scale": 6.5, "surface_strength": 0.55,
	"surface_spot": 0.35, "surface_scales": 0.18, "surface_spot_radius": 0.30,
	"surface_near": 7.0, "surface_far": 20.0}
## The smock is cloth, not stone. sd_cloth runs at ~190 cycles/m, which needs the camera inside
## ~1.5 m, so the fade is deliberately short — it is a dialogue-range nicety and it must be gone
## before it can alias at the 7.4 m gameplay camera.
const SURF_CLOTH := {"surface": "cloth", "surface_scale": 0.8, "surface_strength": 0.7,
	"surface_near": 4.0, "surface_far": 12.0}

# ---------------------------------------------------------------------------------- body
## A tapered column, not a bean: 0.88 / 1.16 / 0.86 of the chibi torso gives semi
## (0.1954, 0.2726, 0.1634) — narrow and tall. Its top lands at 0.673, just under the 0.671 chin.
const TORSO_MUL := Vector3(0.88, 1.16, 0.86)
const COLLAR_Y := 0.594
const BELT_Y := 0.318

var _eye_pivot: Node3D             ## everything on the stalk, rotated about the stalk base
var _lid: Node3D
var _tally: Node3D
var _eye_follow_yaw: float = 0.0
var _eye_follow_pitch: float = 0.0
var _tally_follow: float = 0.0


func _init() -> void:
	super()
	# Slow and deliberate — slower than everyone but Mayor Orbit's 0.62. He is the oldest thing on
	# a world made of things he cut himself.
	anim_time_scale = 0.70
	# 0.92 is NOT a fix for the name-marker collision (see the note on `_check_marker_height`); it is
	# here because at 1.0 the stalk tip stands 1.77 m off the ground, taller than the 1.4 m
	# astronaut by a quarter. At 0.92 he tops out at 1.63 m: still the tallest neighbour in the
	# cast, which is the read, without dwarfing the player.
	body_scale = 0.92
	# Planted, not floating. Zorp hovers 5 cm; Grig is a walking piece of the ground.
	hover_height = 0.0
	# The dark pupil has to scale with a 0.112 m eyeball or it becomes a dot ON it. 0.088 x 0.092
	# half-extents put the pupil at 78% of the ball's width — a real pupil on a real sclera, where
	# Zorp's 0.062 on a 0.055 ball is actually WIDER than the ball it sits on.
	eye_w = 0.088
	eye_h = 0.092
	# Deeper than the chibi default so the pupil stands clear of the low-poly ball's front facet.
	eye_d = 0.030
	# Sized to sit INSIDE the grin cavity (half-extents 0.062 x 0.026) at the same proportion Zorp's
	# open mouth sits inside his.
	mouth_w = 0.052
	mouth_h = 0.038
	head_semi = HEAD_SEMI_GRIG
	head_n = HEAD_N_GRIG
	head_y = HEAD_Y_GRIG
	head_segs = HEAD_SEGS_GRIG


func _build_geometry() -> void:
	_add_torso_bean(SMOCK, _with(SURF_CLOTH, {"size_mul": TORSO_MUL, "chamfer_color": SMOCK_DARK}))
	_build_belt()
	# TWO fingers. Zorp has three, the twins none — a two-lobed mitt is a third hand silhouette.
	_add_arms(SMOCK, SKIN, 2, SURF_LIMB, SURF_CLOTH)
	_add_legs(SKIN_DEEP, FOOT, SURF_LIMB)
	_add_head_shell(SKIN, SURF_HEAD)
	_add_strata()

	# `blush: false` and `nose: false` are the switches the robots already use. Passing a TRANSPARENT
	# blush colour instead does not work — the toon material is opaque, so an alpha-0 colour renders
	# as two BLACK ovals on the cheeks. The colour below is inert; the flag is what matters.
	_add_face(EYE, GRIN, SKIN_DEEP, {"mouth_inner": Color("#5a3a2e"), "nose": false, "blush": false})
	_make_cyclops()
	_build_stalk()
	_build_mouth()
	_build_tally_collar()
	_build_wedge()


# ================================================================================= the one eye
## CYCLOPS SURGERY — spelled out because getting it wrong is a crash and not a cosmetic bug. The
## warning is in `_add_eyestalks`' own docstring (chibi_model.gd:903-910) and in the completeness
## critic's note on Fen in docs/NEXT_WORLDS.md: an eye that is not in the arrays is invisible to the
## whole expression system, and an INDEX that outlives its node is worse.
##
## `_add_face()` always builds exactly TWO eyes (`for i in 2`, chibi_model.gd:718) and appends one
## entry per eye to FOUR parallel arrays — `_eyes`, `_eye_ovals`, `_eye_happy`, `_eye_round` — plus
## one brow per eye to `_brows`. `_apply_face()` walks every one of those arrays EVERY FRAME to drive
## blink, squint, the happy "^" and the surprise "O". So it is not enough to free the second eye:
## an index left pointing at a freed node is a dangling reference that fires on the very next blink.
##
## The order below is deliberate:
##   1. Free the brows FIRST, while their parents are still alive, and clear `_brows`. Brow 0 belongs
##      to the SURVIVING eye, so it has to go explicitly — it cannot be left to die with eye 1. With
##      the eye up on a stalk the brow bars are the only marks left on the head and they read as a
##      second pair of eyes, which puts the animal face straight back; the lid ridge replaces them.
##   2. Drop index 1 from all four eye arrays BEFORE anything is freed, so there is never a window
##      in which an array holds a freed node. `_eye_flat` is guarded too: `_add_face` never fills it
##      (only the robots' `_add_flat_eyes` does), but a guard costs nothing and a future base-class
##      change that starts filling it would otherwise take this model down silently.
##   3. Detach the dead eye from the tree and THEN queue_free it. `remove_child` is immediate, so it
##      stops rendering this frame rather than at the end of the idle frame; `queue_free` alone is
##      deferred and would leave a visible second eye for one frame at spawn.
## Its children (Oval, Glint, Happy, Round) are freed with it, which is why they must already be out
## of the arrays.
func _make_cyclops() -> void:
	for b: Node3D in _brows:
		# Detached, not just queued: `queue_free` alone runs at the END of the frame, so the brow bar
		# would render for one frame on a face that is not supposed to have one — and on Grig it
		# would render up on the STALK, because the surviving eye gets re-parented there next.
		var bp := b.get_parent()
		if bp != null:
			bp.remove_child(b)
		b.queue_free()
	_brows.clear()
	if _eyes.size() < 2:
		return
	var dead: Node3D = _eyes[1]
	_eyes.remove_at(1)
	_eye_ovals.remove_at(1)
	_eye_happy.remove_at(1)
	_eye_round.remove_at(1)
	if _eye_flat.size() > 1:
		_eye_flat.remove_at(1)
	var parent := dead.get_parent()
	if parent != null:
		parent.remove_child(dead)
	dead.queue_free()
	# The surviving eye's happy arc and surprise ball are authored at chibi defaults (0.042 ring,
	# 0.043 x 0.048 ball) and are NOT scaled by eye_w/eye_h, so on a pupil this size both expressions
	# would visibly SHRINK the eye at the moment it is meant to be most readable. Scale their parent
	# nodes — not the meshes — so the states land at the resting pupil's width.
	if not _eye_happy.is_empty():
		_eye_happy[0].scale = Vector3(1.85, 1.85, 1.0)
	if not _eye_round.is_empty():
		_eye_round[0].scale = Vector3(2.05, 1.92, 1.0)


## One thick central stalk, one huge eye, and a heavy lid ridge over it — all re-parented under a
## pivot AT THE STALK BASE so `_animate_extras` can lag the whole assembly as one piece.
func _build_stalk() -> void:
	_add_eyestalks([{"base": STALK_BASE, "tip": STALK_TIP, "r": STALK_R, "splay": 0.0}],
		SKIN, SCLERA, EYEBALL_R)
	_eye_pivot = _node("EyePivot", _head, STALK_BASE)
	# The lid ridge: a single arc hooding the ball, in the deep skin tone so it reads as bone rather
	# than as a second dark mark. Built before the re-parent so it travels with everything else.
	_lid = _node("LidRidge", _head, STALK_TIP + Vector3(0.0, 0.006, -0.030))
	_lid.rotation.x = LID_TILT
	_mi(arc_tube(LID_RING_R, LID_TUBE, deg_to_rad(14.0), deg_to_rad(166.0), 14, 6),
		_toon(SKIN_DEEP, _matte({"rim": 0.02})), _lid, Vector3.ZERO, "Ridge")
	# `_add_eyestalks` parents the stem and the eyeball to `_head` and re-positions `_eyes[0]` (which
	# lives under `_face`). `_face` sits at the head origin with no rotation, so head-local and
	# face-local are the same frame and the transforms below carry across untouched.
	var riders: Array[Node3D] = []
	var stem := _head.get_node_or_null("EyeStalk0") as Node3D
	var ball := _head.get_node_or_null("Eyeball0") as Node3D
	if stem != null:
		riders.append(stem)
	if ball != null:
		riders.append(ball)
	if not _eyes.is_empty():
		riders.append(_eyes[0])
	riders.append(_lid)
	for n: Node3D in riders:
		_adopt(n, _eye_pivot, STALK_BASE)


## Merges `extra` over a copy of `base`, so a const opts dict can be reused with a couple of keys
## added. `_matte()` duplicates again downstream, so nothing here mutates a constant.
static func _with(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	for key: Variant in extra:
		o[key] = extra[key]
	return o


## Moves `n` under `pivot` while keeping its world placement, given that `pivot` sits at `origin` in
## the same (unrotated) parent frame.
func _adopt(n: Node3D, pivot: Node3D, origin: Vector3) -> void:
	var xf := n.transform
	var parent := n.get_parent()
	if parent != null:
		parent.remove_child(n)
	pivot.add_child(n)
	n.transform = xf
	n.position = xf.origin - origin


# ================================================================================= head detail
## PANEL GROOVES as horizontal STRATA — thin bands that wrap the WHOLE head, mirroring the contour
## rings of Grig's own planet.
##
## docs/NEXT_WORLDS.md specifies three `arc_tube`s placed with `_orient_on_head`, but an arc_tube
## sweeps in the tangent plane at one point, so it draws a stripe across the FRONT of the face and
## stops — it cannot wrap. The band below is the same trick `_add_head_shell` already uses for the
## crown seam, and it wraps 360 degrees for the same 110 tris.
##
## The arithmetic: on the head superellipsoid, the horizontal half-extents at height `frac * semi.y`
## are `semi.xz * (1 - |frac|^n)^(1/n)`. Building the band at that size times `STRATA_PROUD` welds it
## to the shell and buries everything outside the protruding rim, so only a band shows. Sharing the
## head's own exponent keeps the band's cross-section identical to the shell's, which the crown
## seam's fixed 2.8 only approximates.
##
## THE NUMBERS ARE SET BY WHAT SURVIVES 7.4 m, not by taste. A band of y-semi `t` oversized by `s`
## shows over the height where `(1 - (dy/t)^n)^(1/n) > 1/s`, i.e. `|dy| < t * (1 - s^-n)^(1/n)`. The
## first build used t 0.009 / s 1.008 and measured a 5.7 mm visible line — 0.67 px at the gameplay
## camera's ~117 px/m, which is below Nyquist and would shimmer rather than read. t 0.024 / s 1.035
## gives a 23.7 mm band standing 8.6 mm proud: ~2.8 px tall and ~1 px of relief, which holds. It is
## also 3.5% of the head's half-width, almost exactly the 2.9% his planet's 0.279 m risers are of its
## 9.5 m radius — the creature banded at his own world's proportion.
##
## Heights: 0.50 / 0.20 / -0.12 of the y semi-axis, which lands them at 0.215 / 0.086 / -0.052
## head-local. With the crown seam at 0.351 that is four lines at an even ~0.133 m pitch down the
## face, and the lowest still clears the mouth at -0.232. Grading a stack of horizontals at a
## constant pitch is exactly what his terraces do.
const STRATA_FRACS: Array = [0.50, 0.20, -0.12]
const STRATA_T := 0.024
const STRATA_PROUD := 1.035

func _add_strata() -> void:
	var m := _toon(SKIN_DEEP, _matte({"rim": 0.02}))
	for frac: float in STRATA_FRACS:
		var k: float = pow(maxf(1.0 - pow(absf(frac), head_n), 1e-4), 1.0 / head_n)
		var semi := Vector3(head_semi.x * k * STRATA_PROUD, STRATA_T, head_semi.z * k * STRATA_PROUD)
		_mi(superellipsoid(semi, head_n, 18, 5), m, _head,
			Vector3(0.0, head_semi.y * frac, 0.0), "Strata")


## The grin, dropped to the bottom of the tall face and given three blunt square teeth.
func _build_mouth() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_GRIG, 0.004)
	# Applied to the parent Mouth node, NOT to the smile arc: `_apply_face` rewrites the arc's own
	# scale every frame to drive the open/closed blend.
	mouth_node.scale = MOUTH_SPREAD
	_add_wide_grin(mouth_node, GRIN, TOOTH, GRIN_SIZE, GRIN_TEETH)


# ================================================================================= worn stone
## THE TALLY COLLAR — five flat chamfered chalk slabs hanging on a cord, one notched per terrace he
## has cut. Nobody in the cast wears stone. Graded so the centre slab hangs lowest, which reads as a
## worn working object rather than a neat five-piece necklace.
func _build_tally_collar() -> void:
	_tally = _node("TallyCollar", _torso, Vector3(0.0, COLLAR_Y, 0.0))
	var cord := _mi(torus(0.150, 0.172, 18, 5), _toon(SKIN_DEEP, _matte({"spec": 0.03})),
		_tally, Vector3(0.0, 0.004, 0.0), "Cord")
	cord.scale = Vector3(1.06, 0.55, 0.88)
	var m_slab := _toon(TALLY, _matte({"rim": 0.03}))
	var m_notch := _toon(TALLY.darkened(0.34), _matte({"spec": 0.0}))
	for i in 5:
		var off := float(i - 2)
		var ang := off * 0.26
		var drop := 0.030 + 0.016 * (2.0 - absf(off))
		var slab := _node("Slab%d" % i, _tally,
			Vector3(sin(ang) * 0.175, -drop, -cos(ang) * 0.148))
		slab.rotation = Vector3(0.10, ang, -0.06 * off)
		_mi(rounded_box(Vector3(0.050, 0.072, 0.014), 0.008, 10), m_slab, slab, Vector3.ZERO, "Slab")
		# Not every slab is notched — an even five would read as decoration rather than as a count.
		if i % 2 == 0:
			_mi(rounded_box(Vector3(0.030, 0.006, 0.004), 0.002, 6), m_notch, slab,
				Vector3(0.0, -0.018, -0.008), "Notch")


## A hard waist so the smock ends on an edge instead of fading into the hips, and something for the
## wedge to hang from.
func _build_belt() -> void:
	var semi := Vector3(TORSO_RX * TORSO_MUL.x, TORSO_RY * TORSO_MUL.y, TORSO_RZ * TORSO_MUL.z)
	_mi(superellipsoid(Vector3(semi.x * 1.03, 0.018, semi.z * 1.03), 3.0, 16, 5),
		_toon(SMOCK_DARK, _matte({"rim": 0.02})), _torso, Vector3(0.0, BELT_Y, 0.0), "Belt")


## THE CUTTING WEDGE at his hip — deliberately GREY, not brass. Brass is Mayor Orbit's and the two
## would read as the same accessory at gameplay distance.
func _build_wedge() -> void:
	var hip := _node("Wedge", _torso, Vector3(0.192, 0.300, 0.006))
	hip.rotation = Vector3(0.0, 0.12, -0.20)
	_mi(superellipsoid(Vector3(0.036, 0.086, 0.022), 2.2, 8, 5), _toon(WEDGE, _matte({"spec": 0.08})),
		hip, Vector3.ZERO, "Head")
	_mi(rounded_box(Vector3(0.020, 0.075, 0.018), 0.006, 8), _toon(SKIN_DEEP, _matte({})),
		hip, Vector3(0.0, 0.074, 0.0), "Haft")


# ================================================================================= animation
func _animate_extras(delta: float) -> void:
	# THE LAGGING EYE-TRACK. The pivot sits INSIDE `_head`, so its rotation is added on top of the
	# head's own. Rotating it toward HEAD_YAW would make the eye OVERSHOOT the turn; what reads as
	# thought is the eye holding still in world space and then catching up. So the pivot is driven by
	# the DIFFERENCE between a lagged copy of the head angle and the head's current angle: the moment
	# the head turns, that difference is large and negative, which cancels the head's rotation and
	# pins the eye where it was; as the filter catches up the difference decays to zero and the eye
	# arrives. Clamped so it can trail by at most 0.14 rad — past that the stalk reads as broken
	# rather than as slow.
	var yaw := pose(P.HEAD_YAW)
	var pitch := pose(P.HEAD_PITCH)
	var k := 1.0 - exp(-EYE_LAG_RATE * delta)
	_eye_follow_yaw = lerpf(_eye_follow_yaw, yaw, k)
	_eye_follow_pitch = lerpf(_eye_follow_pitch, pitch, k)
	if _eye_pivot != null:
		_eye_pivot.rotation.y = clampf((_eye_follow_yaw - yaw) * 0.9, -EYE_LAG_MAX, EYE_LAG_MAX)
		_eye_pivot.rotation.x = clampf((_eye_follow_pitch - pitch) * 0.7,
			-EYE_LAG_MAX * 0.6, EYE_LAG_MAX * 0.6)
	# The lid ridge is the only expression the face has above the grin: it hoods down when he is
	# thinking (EXTRA_A goes to -1) and lifts a little while he talks (EXTRA_A goes to +1).
	if _lid != null:
		var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
		var talk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
		_lid.rotation.x = LID_TILT - 0.26 * think + 0.10 * talk
	# The tally slabs swing on their cord: same first-order trick, driven by the torso roll at 0.4x.
	# `_torso_pivot` applies -TORSO_ROLL, so a positive difference here is the slabs hanging behind
	# the body as it rolls out from under them.
	if _tally != null:
		var roll := pose(P.TORSO_ROLL)
		_tally_follow = lerpf(_tally_follow, roll, 1.0 - exp(-5.2 * delta))
		_tally.rotation.z = clampf((roll - _tally_follow) * 0.4, -0.24, 0.24)


# ================================================================================= QA
## MARKER HEIGHT — measured, not guessed, and it does NOT come out the way the spec predicts.
##
## `NPC.MARKER_HEIGHT` is 1.52 and npc.gd:477 places the '!' at `Vector3(0, MARKER_HEIGHT *
## _body_scale, 0)` while `ChibiModel.rebuild()` sets `scale = Vector3.ONE * body_scale`. BOTH are
## multiplied by the same factor, so body_scale cancels out entirely and the marker always lands at
## 1.52 in MODEL space. docs/NEXT_WORLDS.md's fix ("either set body_scale 0.92 (tip 1.528)") cannot
## work for that reason — and 1.528 is above 1.52 even on its own arithmetic.
##
## In model space Grig's crown is at 1.531, his stalk tip at 1.661 and the top of his eyeball at
## 1.773, so the marker would be drawn inside his head no matter what body_scale is. This needs a
## per-model marker height in npc.gd (see the report's `needs_from_others`); ~1.95 clears him.
## Returns the model-space height the marker must clear, so a showcase or a test can assert on it.
func marker_clearance() -> float:
	return head_y + STALK_TIP.y + EYEBALL_R
