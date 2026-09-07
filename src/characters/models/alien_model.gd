class_name AlienModel
extends ChibiModel
## Zorp — the lavender alien neighbour, and the CONTROL the rest of the cast is read against.
##
## R4 (CAST VARIETY). The complaint that started this pass was that Zorp, Pip, Pop, Grig and Fen
## "fundamentally look the same": all five called `_add_eyestalks`, all five called `_add_wide_grin`,
## all five wore `{"surface": "skin"}` with the cell walls turned up. One creature in five colours.
##
## Zorp is now the plainest member of the cast on purpose. He wears NONE of the hard vocabulary —
## no brow ridge, no heavy lid, no horns, no tusks, no fangs, no shoulder yoke, and no lashes — so
## that everyone else's ridge or crest or plate reads as a CHOICE about that character rather than
## as the house style. Four things changed and each one gives up something another neighbour keeps:
##
##   1. THE EYESTALKS ARE GONE. The eyes came off the stems and back onto the head as two 104 mm
##      balls sunk a THIRD of the way into the shell, so they still break the silhouette at three
##      quarters but they belong to the face instead of hovering above it. At most two neighbours
##      may keep stalks; Zorp gave up his slot.
##   2. HE HAS AN IRIS, and nothing else in the cast does. A pale ball, an amber ring and a dark
##      pupil, with the three radii solved (see the eye block) so all three still read as separate
##      bands at the 7.4 m gameplay camera. Counted in a render at exactly that distance: the head
##      is 74 px across, the eyeball 12 px, and the amber is an 8 px ring around a 5 px pupil — 28
##      amber pixels per eye, which is a warm ring rather than a dark dot. That, not an accessory,
##      is his face's identity.
##   3. THE WIDE TOOTHY GRIN IS GONE — replaced by a small closed smile with a real volumetric lip:
##      a rounded band of muted mauve standing 21 mm proud of the shell with a dark mouth line laid
##      along its crest. It is the one CLOSED ARC the cast is allowed; every other closed mouth has to
##      differ in KIND (a lipless bar, a round slot, an under-bite, no mouth), not merely in width,
##      because at 8 m a closed arc is one dark line and width is the weakest differentiator there
##      is. What makes this one legible at distance is that it has THICKNESS and catches light.
##   4. THE SKIN IS SMOOTH WITH BIG SOFT SPOTS — the user's exact first ask. `surface_scales` is 0,
##      which kills the Voronoi cell walls entirely (they are what has been reading as "rocky
##      texture skin"), and the lattice pitch and spot radius together take 65 mm speckles up to
##      ~210 mm blotches. It costs LESS palette than the pattern it replaces, not more: an A/B on
##      one identical frame (strength 0 vs on, same crop) moves the head crop's saturation mean by
##      +0.028, against the +0.099 the old setting was measured at. See SURF_HEAD.
##
## Kept, because they are the half of him that already worked: lavender, ONE mint antenna with its
## pulse and its think-droop (moved to the crown midline and grown, since it now carries the whole
## spike), the striped space-scarf, the teal tee with its badge, three-fingered mittens, the bean
## torso, and the 5 cm hover with its bob and glow ring — he is the only neighbour who floats and
## that is half his identity. He also keeps his legs and a real walk cycle; the hover is a hover,
## not a substitute for a lower body.
##
## R2.6 (PASTEL AND MATTE). Every albedo below was re-picked against the CURRENT game — the dark
## thin-atmosphere sky and the repainted pastel ground — not the old white-void showcase. The rule
## from the style guide is "desaturate toward the hue's own pastel, never toward brown, and handle
## value separately", so each swatch keeps its hue and loses chroma and top-end value:
##   skin   #a77ff5 S0.48 V0.96 -> #9a80cc S0.37 V0.80   (still lavender, no longer neon)
##   shirt  #5fd0c8 S0.55 V0.82 -> #84bdb5 S0.30 V0.74
##   scarf  #ff8fa8 S0.44 V1.00 -> #c4858f S0.32 V0.77   (V 1.0 pinks were the clipping culprits)
##   trim   #fff1e0 V1.00       -> #e8ddc9 V0.91         (style guide caps near-whites at ~0.92)
##   feet   #7449d4 S0.66       -> #665c93 S0.37 V0.58   (the dark value anchor every AC villager has)
const SKIN := Color("#9a80cc")
const SKIN_DARK := Color("#7c6aa6")
const EYE := Color("#221c2e")
## The iris. Amber is the one warm hue in a cast built out of lavender, teal, mint and rose, so it
## separates from the sclera AND from the skin at a glance; S 0.47 V 0.79 keeps it inside the R2.6
## gate, and it covers ~2 % of his silhouette so it cannot move a palette measurement on its own.
const IRIS := Color("#c99a5e")
const SCLERA := Color("#efe7f7")     ## pale eyeball, so the dark oval reads as a PUPIL
const BULB := Color("#7fffd4")       ## an emissive bulb: a small saturated accent is allowed
const BLUSH := Color("#b3868f")      ## passed but switched off — see `_add_face`'s transparency trap
const MOUTH := Color("#472440")      ## the mouth line laid along the lip's crest
const MOUTH_INNER := Color("#6e3049")
## The lip itself: a muted mauve, ~18 % down in value from the skin and warmer in hue, so the lip
## is a soft SHAPE and the dark line laid inside it is what actually reads as a mouth. It was built
## a full step brighter first (#b98a97) and rendered as lipstick — a bright band on a small closed
## smile is a gender marker, and this cast is deliberately not using those.
const LIP := Color("#a87b8b")
const SCARF_A := Color("#c4858f")
const SCARF_B := Color("#e8ddc9")
const SHIRT := Color("#84bdb5")      ## a proper tee — every AC villager wears clothes
const SHIRT_TRIM := Color("#e8ddc9")
const FOOT := Color("#665c93")
const HOVER := 0.05

# ----------------------------------------------------------------------------------------- eyes
## THE EYE, solved rather than eyeballed, because three nested lens caps on a sphere have exactly
## one arrangement that reads as an iris and a great many that read as a floating disc.
##
## Everything is measured from the eyeball's CENTRE, along the pupil's aim:
##   EYEBALL_R    the pale ball's radius.
##   EYEBALL_SINK how deep the ball is buried in the head shell, as a fraction of its radius. At
##                0.34 it stands 33 mm proud of a 640 mm head (measured in-engine: centre 18.7 mm
##                inside the shell), which is what breaks the outline at three quarters without the
##                ball reading as glued on.
##   IRIS_*       an amber lens: radius across, half-depth, and how far out its centre sits.
##   PUPIL/_SEAT  the dark lens `_apply_face` drives (blink, wide, squint) plus its seat.
##
## The three radii were chosen by scanning the depth of all three surfaces along the axis and
## finding which one is in front at each lateral radius. Result on a 104 mm ball: a 40.7 mm dark
## pupil, a 15.7 mm amber annulus and a 16.0 mm pale rim, i.e. a pupil that owns the middle and two
## rings that each survive as ~2 px at the 7.4 m camera. The iris rim lands 0.5 mm proud of
## the ball, so the amber emerges from the sclera almost tangentially; push IRIS_SEAT up and you get
## a visible floating collar around it, which is the failure this solve exists to avoid.
const EYE_YAW_A := 22.5              ## degrees off the face midline — wider than the chibi 16.8
const EYE_PITCH_A := 3.0
const EYEBALL_R := 0.052
const EYEBALL_SINK := 0.34
const IRIS_R := 0.036
const IRIS_D := 0.021
const IRIS_SEAT := 0.038
const PUPIL := Vector3(0.022, 0.022, 0.014)
const PUPIL_SEAT := 0.050
## How far the pupil's aim leans off the ball's own outward normal — which is what puts the pupil
## slightly off-centre inside the iris, and it is the cheapest life in the whole face.
## SPLAY IS NEGATIVE, i.e. the pupils converge INWARD very slightly. It was built outward first
## (which is the obvious reading of "don't let them stare dead ahead in parallel") and rendered
## walleyed: divergent pupils read as vacant, convergent ones read as looking at you. Five degrees
## is plenty; the head, not the eyes, does the actual looking (see `_update_look`).
const EYE_SPLAY := -0.09
const EYE_CAST := 0.05
## The "^ ^" and "O O" expression meshes are authored at chibi eye size and sit on the eyeball, not
## on the pupil, so they are scaled to the BALL. `fit_expr` is deliberately NOT used: it normalises
## against the chibi constants, and Zorp's eye is a 104 mm sphere rather than a 75 mm painted oval.
const HAPPY_ON_BALL := 0.86
const ROUND_ON_BALL := 0.76

# ----------------------------------------------------------------------------------------- mouth
## THE VOLUMETRIC LIP. `_smile_arc`'s hairline arc is replaced by a band of real thickness that is
## half-buried in the shell, plus a thinner dark tube running along its crest at CONSTANT clearance.
##
## Built from `taper_tube`, not `arc_tube`, and that is not a style preference. `arc_tube`'s triangle
## winding is inverted relative to every other primitive in the project — measured here: its 360 deg
## sweep has signed volume +0.00024074 against TorusMesh's -0.00024074, with all 78 vertex normals
## still pointing outward. On the thin dark bars it is used for (smiles, brows, lid ridges) that is
## invisible, which is why it has never been fixed. A 33 mm-thick lip half-sunk into the head is
## exactly the case where it would stop being invisible, so this uses the primitive that was built
## for fat solids and whose winding matches Godot's.
##
## UNIFORM RADIUS, ON PURPOSE. A tapered lip (fuller in the middle) was built first and thrown away:
## its crest is a curved 3-D line whose distance from the arc centre varies, so the dark mouth line
## either sinks into the lip at the centre or floats off it at the ends — there is no constant
## offset that follows a tapering tube. With a constant radius the crest is a plain concentric arc
## and the mouth line sits at a fixed 1.8 mm clearance along its whole length.
##
## The lip's tube centre sits 4.4 mm proud of the shell at its corners and 4.6 mm at its centre, so
## it hugs the face to within 0.2 mm over a 110 mm span and its front stands 21 mm out. Solved
## against the head superellipsoid first and then confirmed in-engine at +4.6 mm / +21.1 mm.
const MOUTH_PITCH_A := -18.0
const LIP_ARC_R := 0.098             ## 109.6 mm wide, 16.8 mm of sag
const LIP_HALF := 34.0               ## degrees each side of straight down
const LIP_TUBE := 0.0165
const LIP_Z := -0.006                ## negative is proud: `_orient_on_head` puts -Z along the normal
const SEAM_HALF := 27.0              ## shorter than the lip, so the line stops before the corners
const SEAM_TUBE := 0.0048
const SEAM_Z := LIP_Z - (LIP_TUBE - SEAM_TUBE) - 0.0018

# --------------------------------------------------------------------------------------- antenna
## One antenna, on the crown MIDLINE now the stalks are gone, and long enough to carry the whole
## spike of the silhouette by itself. The length is not a guess: the two eyestalks it replaces
## topped out around 1.51 m above the ground (tip at 0.512 head-local, plus a 55 mm eyeball), and
## the bulb now tops out at 1.485 m — measured in-engine, walking the transform chain — so the
## outline keeps the height it had with one mint point instead of two white balls. `stalk_r` went up
## with the length because a 270 mm stem on a 30 mm stalk is a wire holding a 96 mm ball; at the
## 7.4 m camera the image scale is 0.116 px/mm, so that is three pixels of stalk under a ten-pixel
## bulb. It is
## seated with `_crown_row`, which returns a tilt child whose parent already holds the placement,
## because writing a rotation onto a node `_orient_on_head` has posed destroys that placement — and
## `_animate_extras` writes rotations onto the antenna pivot every frame.
##
## `curve` is negative so the stem curls FORWARD, over the face: `taper_tube` bends toward its own
## +Z, and at the crown seat +Z points out of the back of the head.
const ANTENNA_LEAN := 0.12           ## static forward lean, on the crown seat's tilt child
const ANTENNA_REST_TILT := -0.16     ## `_animate_extras` reads this back as the "rest_tilt" meta
const ANTENNA_LEN := 0.270
const ANTENNA_BULB := 0.048
const ANTENNA_CURL := 0.26

# ------------------------------------------------------------------------------------------ skin
## R4 SKIN — "Some should have smooth skin, but have big spots."
##
## `surface_scales` 0.0 is the whole first half of that. In sd_skin the scale term is the Voronoi
## CELL WALL, and it is what has been reading as "rocky texture skin with spots" on five characters
## at once; at 0.0 both its tint contribution and its roughness contribution drop out of the shader
## (the roughness gate matters — before R4 a character who asked for smooth skin still carried the
## full wall pattern in roughness, and toon_soft widens its spec lobe by roughness, so the walls
## came back as ghosts).
##
## The second half is size, and it is a two-number change because blob size is set by the LATTICE
## PITCH as well as by the radius. sd_skin runs at 7 cells per unit at `surface_scale` 1.0, so:
##   scale 1.60 (the old value) -> 89 mm cells -> at radius 0.36, ~65 mm speckles
##   scale 1.00 (now)           -> 143 mm cells -> at radius 0.74, blobs 159 mm across at half
##                                 amplitude and 211 mm at their full extent
## About 3.5 cells span the 640 mm head and the pick rate is 0.478, so roughly a third of him is
## blotch — dappled, not stained, and readable at the 7.4 m gameplay camera where the old speckle
## collapsed into noise.
##
## AMPLITUDE IS A PALETTE COST, measured not guessed: the tint MULTIPLIES the albedo, and darkening
## a colour RAISES its HSV saturation, so a strong pattern pushes straight at the R2.6 gate. The old
## setting was measured at +0.099 saturation mean for turning the pattern on. THIS one was measured
## the same way — one identical frame, one identical 200x160 head crop, `surface_strength` 0.0 vs
## 1.0 — and costs +0.028 (0.432 -> 0.460), with value mean moving -0.012 and blown highlights at
## 0.0 % either way. Two things bought that back: `surface_scales` 0.0 drops the cell walls, which
## were doing most of the darkening, and the R4 shader fix centres the spot term on zero
## (`surface_spot_dc` is DERIVED from the radius by `MaterialLib.spot_dc`, 0.3205 at 0.74), so the
## mean albedo is now unchanged and only the swing costs anything. At spot 1.25 and strength 1.0 the
## swing is a tint of 0.899 to 1.214 — 10 % down in the gaps, 21 % up in the blotches. The dominant
## swatch measures S 0.55, under the 0.60 gate. Re-measure if you raise either.
##
## The limbs need their own pitch: `objpos` is per-mesh, so a 152 mm mitten at the head's setting
## would carry one blob or none and the two hands would be identical. Scale 2.90 puts 49 mm cells on
## a mitten — two or three blotches each — which keeps the hands part of the same animal without
## pretending a hand is a head. Spots that stop at the jaw look like a mask.
const SURF_HEAD := {"surface": "skin", "surface_scale": 1.00, "surface_strength": 1.00,
	"surface_spot": 1.25, "surface_scales": 0.0, "surface_spot_radius": 0.74,
	"surface_near": 9.0, "surface_far": 26.0, "surface_macro": 0.10}
const SURF_LIMB := {"surface": "skin", "surface_scale": 2.90, "surface_strength": 0.95,
	"surface_spot": 1.15, "surface_scales": 0.0, "surface_spot_radius": 0.74,
	"surface_near": 7.0, "surface_far": 20.0}

var _antenna: Node3D
var _bulb_mat: ShaderMaterial
var _glow_ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _bob: float = 0.0


func _init() -> void:
	super()
	hover_height = HOVER
	# The model-wide eye size IS the pupil, so `_build_eye`'s expression scaling comes out at
	# exactly 1.0 and the "^ ^" / "O O" meshes keep the size they were authored at. They are then
	# scaled to the BALL below, which is the thing they actually sit on.
	eye_w = PUPIL.x
	eye_h = PUPIL.y
	eye_d = PUPIL.z
	# A SMALL mouth. The wide grin is gone, so the open-mouth ellipse that drives talking shrinks
	# with it — 80 mm across at full open on a 640 mm head, against the 274 mm the grin needed.
	mouth_w = 0.044
	mouth_h = 0.030
	# R3.2 — HIS OWN HEAD, low and flat. Until now every organic neighbour shared ONE cached head
	# mesh, which is exactly why the user said it "still looks like it's just a reused head".
	#
	# 640 x 450 x 544 mm, against the shared 749 x 652 x 691. The height is what does the work: the
	# blank band between the top of the grin and the crown drops by about 40%, and the front surface
	# stops bulging — measured recession from the apex out to 60% / 80% of half-width falls from
	# 32 / 79 mm to about 12 / 40 mm. That flattening is the "flatten it out" the user asked for.
	#
	# EXPONENT: the design pass proposed n = 4.0, and two independent reviewers each built it and
	# rendered it — at 4.0 with this tessellation the head reads as a hard-edged faceted BOX, because
	# superellipsoid() samples a UV sphere's uniform angular directions while a high exponent packs
	# all the curvature into a narrow chamfer band. 3.2 keeps most of the flattening and still reads
	# as a blob. Do not raise it without also raising head_segs.
	head_semi = Vector3(0.3200, 0.2250, 0.2720)
	head_n = 3.2
	# Holds the chin exactly where it rendered before (0.945 - 0.3258 * 0.84 = 0.6713), so the scarf,
	# the torso and the hover are all untouched.
	head_y = 0.8963


func _build_geometry() -> void:
	_add_torso_bean(SHIRT, {"chamfer_color": SHIRT.darkened(0.20)})
	# hem: a band of bare skin under the tee so the bean still reads as a body. Superellipsoid, so
	# the tee ends on a hard horizontal edge instead of fading into another sphere.
	_mi(superellipsoid(Vector3(TORSO_RX * 0.93, TORSO_RY * 0.44, TORSO_RZ * 0.95), 2.9, 16, 8),
		_toon(SKIN, _matte({})), _torso, Vector3(0.0, TORSO_Y - 0.142, 0.0), "Hem")
	# chest motif, the way AC tees carry one — a flat chamfered badge with a bevelled rim, not the
	# six-ball star the first pass used (R2.3: "if a form can be described as a bunch of balls...").
	var emblem := _node("Emblem", _torso, Vector3(0.0, TORSO_Y + 0.012, -TORSO_RZ * 0.93))
	_mi(rounded_box(Vector3(0.108, 0.108, 0.020), 0.030, 12), _toon(SHIRT_TRIM, _matte({"rim": 0.03})),
		emblem, Vector3.ZERO, "Badge").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.062, 0.062, 0.022), 0.016, 10), _toon(SHIRT.darkened(0.22), _matte({})),
		emblem, Vector3(0.0, 0.0, -0.006), "Inlay").rotation.z = PI * 0.25
	_add_arms(SHIRT, SKIN, 3, SURF_LIMB)
	_add_legs(SKIN_DARK, FOOT, SURF_LIMB)
	_add_head_shell(SKIN, SURF_HEAD)

	# NO NOSE, NO BLUSH, NO BROWS. The first two are mammal cues on a creature that is meant not to
	# be one; the brows are the hard vocabulary Zorp is the control for. All three are BOOLEAN
	# switches — you cannot turn a face part off by passing it a transparent colour, because
	# `toon_soft` is opaque and an alpha-0 blush renders as two BLACK ovals on the cheeks. Three
	# files have hit that trap.
	_add_face(EYE, MOUTH, BLUSH, {
		"nose": false, "blush": false, "brows": false, "mouth_inner": MOUTH_INNER,
		"eyes": [_eye_spec(-1.0), _eye_spec(1.0)],
	})
	_dress_eyes()
	_build_lip()
	_build_scarf()

	var seat: Node3D = _crown_row(1, 90.0, 90.0, 0.0, 0.014)[0]
	seat.rotation.x = -ANTENNA_LEAN
	_antenna = _add_antenna(seat, Vector3.ZERO, ANTENNA_REST_TILT, SKIN_DARK, BULB,
		ANTENNA_LEN, ANTENNA_BULB, {"stalk_r": 0.018, "curve": -ANTENNA_CURL})
	_bulb_mat = _antenna.get_meta("bulb_mat") as ShaderMaterial

	_build_glow_ring()


# ================================================================================= eyes on the head
## Where one eyeball sits and where its pupil looks: [ball centre, aim], both in head-local space.
##
## Solved on the head superellipsoid with `se_point`/`se_normal` — the same surface `_add_head_shell`
## builds — so changing `head_semi` or `head_n` moves the eyes with the shell instead of leaving two
## balls floating where the old head used to be.
func _eye_rig(sx: float) -> PackedVector3Array:
	var yaw := deg_to_rad(EYE_YAW_A * sx)
	var pitch := deg_to_rad(EYE_PITCH_A)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var p := se_point(dir, head_semi, head_n)
	var outward := se_normal(p, head_semi, head_n)
	return PackedVector3Array([
		p - outward * (EYEBALL_R * EYEBALL_SINK),
		(outward + Vector3(EYE_SPLAY * sx, -EYE_CAST, 0.0)).normalized(),
	])


## The spec `_add_face` builds one eye from. `pos` is passed, which is what tells `_build_eye` to
## place the eye outright instead of seating it on the head — the pupil belongs to the BALL, not to
## the shell, and the ball is already off the shell.
func _eye_spec(sx: float) -> Dictionary:
	var rig := _eye_rig(sx)
	return {"w": PUPIL.x, "h": PUPIL.y, "d": PUPIL.z, "pos": rig[0] + rig[1] * PUPIL_SEAT}


## The parts of the eye the base class has no concept of: the pale ball behind it, the amber iris in
## front of it, and the aim.
func _dress_eyes() -> void:
	var m_ball := _toon(SCLERA, _matte({"spec": 0.05, "rim": 0.02}))
	var m_iris := _toon(IRIS, _matte({"spec": 0.06, "rim": 0.02}))
	for i in _eyes.size():
		var sx := -1.0 if i == 0 else 1.0
		var rig := _eye_rig(sx)
		_mi(sphere(EYEBALL_R, 16, 9), m_ball, _face, rig[0], "Eyeball%d" % i)
		var eye: Node3D = _eyes[i]
		eye.basis = Basis.looking_at(rig[1], Vector3.UP)
		# THE IRIS IS A CHILD OF THE PUPIL, not a sibling, and that is the whole reason it works:
		# `_apply_face` rewrites the pupil's scale every frame to drive blink, squint and wide, so
		# anything parented to it inherits those for free. A sibling iris would sit wide open behind
		# a shut eye. Its offsets are expressed in the pupil's own units for the same reason — the
		# pupil's scale is not ours to assume.
		var oval := _eye_ovals[i]
		var iris := _mi(sphere(1.0, 14, 8), m_iris, oval,
			Vector3(0.0, 0.0, (PUPIL_SEAT - IRIS_SEAT) / PUPIL.z), "Iris")
		iris.scale = Vector3(IRIS_R / PUPIL.x, IRIS_R / PUPIL.y, IRIS_D / PUPIL.z)
		# The expression meshes replace the whole eye, so they are sized to the ball rather than to
		# the pupil. Scaled in X and Y only: Z is their standoff from the eyeball and is already right.
		_eye_happy[i].scale = Vector3(HAPPY_ON_BALL, HAPPY_ON_BALL, 1.0)
		_eye_round[i].scale = Vector3(ROUND_ON_BALL, ROUND_ON_BALL, 1.0)


# ================================================================================ the closed smile
## Replaces the default hairline arc with a lip that has volume, and keeps `_mouth_open` — the
## ellipse that drives talking — exactly where `_add_mouth` put it, so the talk / happy / surprised
## blend still runs. `_apply_face` fades this whole group out as the mouth opens (see SMILE_HIDE_AT),
## which is why it must be assigned to `_mouth_smile` rather than merely added to the mouth node.
func _build_lip() -> void:
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, MOUTH_PITCH_A, 0.002)
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		_mouth_smile.queue_free()
	# The group's origin is the mouth node's origin, and both arcs are anchored so their ENDS land
	# at y = 0 — so when `_apply_face` squashes this group's Y the smile collapses toward its own
	# corners, which is what the arc it replaces did.
	var lip := _node("Lip", mouth_node, Vector3.ZERO)
	_mouth_smile = lip
	_arc_band(lip, _toon(LIP, _matte({"spec": 0.05, "rim": 0.03})),
		LIP_HALF, LIP_TUBE, LIP_Z, 10, 10, "Band")
	_arc_band(lip, _toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06}),
		SEAM_HALF, SEAM_TUBE, SEAM_Z, 8, 8, "MouthLine")


## ONE ARC OF TUBE at ring radius LIP_ARC_R, swept `half` degrees each side of straight down, built
## from `taper_tube` so the winding matches every other solid in the project.
##
## `taper_tube` grows along its own +Y and bends toward its own +Z, so the node is planted at the
## arc's left end with +Y along the tangent there and +Z along the centripetal direction. That is
## not an approximation: the tube's tangent at arc length u is `t0*cos(u) + n0*sin(u)`, which
## expands to `(-sin(a0+u), cos(a0+u), 0)` — the exact tangent of the circle it is meant to trace.
##
## The anchor is LIP_ARC_R's, not `half`'s, so a shorter sweep (the mouth line) stays CONCENTRIC
## with the lip instead of becoming its own circle. Concentric plus constant tube radius is what
## gives the mouth line a fixed clearance over the lip's crest along its whole length.
func _arc_band(parent: Node3D, mat: Material, half: float, tube_r: float, z: float,
		segs: int, sides: int, n: String) -> MeshInstance3D:
	var anchor_y := LIP_ARC_R * cos(deg_to_rad(LIP_HALF))
	var a0 := deg_to_rad(270.0 - half)
	var sweep := deg_to_rad(2.0 * half)
	var t0 := Vector3(-sin(a0), cos(a0), 0.0)          ## tangent at the left end
	var n0 := Vector3(-cos(a0), -sin(a0), 0.0)         ## centripetal, toward the arc's centre
	var band := _node(n, parent, Vector3(LIP_ARC_R * cos(a0), anchor_y + LIP_ARC_R * sin(a0), z))
	band.basis = Basis(t0.cross(n0), t0, n0)
	return _mi(taper_tube(LIP_ARC_R * sweep, tube_r, tube_r, sweep, segs, sides), mat,
		band, Vector3.ZERO, "Tube")


## Striped space-scarf where a neck would be (there is none — it sits on the shoulders).
func _build_scarf() -> void:
	var m_a := _toon(SCARF_A, _matte({"spec": 0.03}))
	var m_b := _toon(SCARF_B, _matte({"spec": 0.03}))
	var scarf := _node("Scarf", _torso, Vector3(0.0, TORSO_Y + TORSO_RY * 0.74, 0.0))
	# one collar with a flat top face and a chamfered edge, wrapped by thin stripes: fabric with a
	# fold in it, not a stack of donuts
	_mi(superellipsoid(Vector3(0.176, 0.076, 0.160), 3.0, 14, 8), m_a, scarf, Vector3(0.0, -0.012, 0.0), "Collar")
	for i in 3:
		var stripe := _mi(torus(0.150, 0.188, 18, 5), m_b, scarf, Vector3(0.0, 0.012 - 0.034 * i, 0.0), "Stripe")
		stripe.scale = Vector3(0.99 - 0.05 * i, 0.30, 0.90 - 0.05 * i)
	# a short tail hanging over the left shoulder
	var tail := _node("Tail", scarf, Vector3(-0.115, -0.048, -0.115))
	tail.rotation = Vector3(-0.22, 0.30, 0.30)
	for i in 3:
		var seg := _mi(rounded_box(Vector3(0.075, 0.052, 0.032), 0.016, 10), m_b if i % 2 == 0 else m_a, tail, Vector3(0.008 * i, -0.05 * i, 0.0), "Seg")
		seg.rotation.z = 0.06 * i


func _build_glow_ring() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(0.72, 0.72)
	q.orientation = PlaneMesh.FACE_Y
	_glow_ring = MeshInstance3D.new()
	_glow_ring.name = "HoverGlow"
	_glow_ring.mesh = q
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, 0.30)
	_ring_mat.albedo_texture = soft_dot_texture()
	_ring_mat.disable_receive_shadows = true
	_glow_ring.material_override = _ring_mat
	_glow_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_ring.position = Vector3(0.0, 0.012, 0.0)
	add_child(_glow_ring)


func _animate_extras(delta: float) -> void:
	_bob += delta
	# soft hover bob (the whole model floats; the glow ring stays on the ground)
	_root.position.y = hover_height + sin(TAU * _bob / 2.6) * 0.022
	var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	var perk := clampf(pose(P.EXTRA_A), 0.0, 1.0)
	if _antenna:
		var rest: float = _antenna.get_meta("rest_tilt", -0.16)
		_antenna.rotation.z = rest - 0.95 * droop + 0.10 * perk
		_antenna.rotation.x = 0.55 * droop + 0.06 * sin(TAU * _bob * 0.7)
	if _bulb_mat:
		var rate := 1.6 if perk > 0.4 else 2.6
		var pulse := 0.5 + 0.5 * sin(TAU * _bob / rate)
		_bulb_mat.set_shader_parameter("emission_strength", (0.6 + 1.2 * pulse) * (1.0 - 0.6 * droop))
	if _ring_mat:
		var a := 0.24 + 0.10 * sin(TAU * _bob / 2.6 + 1.2)
		_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, a)


## Small radial falloff texture used for the hover glow (shared, generated once).
static var _dot_tex: ImageTexture

static func soft_dot_texture() -> ImageTexture:
	if _dot_tex:
		return _dot_tex
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / n * 2.0 - 1.0
			var v := (float(y) + 0.5) / n * 2.0 - 1.0
			var d := sqrt(u * u + v * v)
			var a := clampf(1.0 - smoothstep(0.15, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex
