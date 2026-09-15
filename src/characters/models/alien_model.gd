class_name AlienModel
extends ChibiModel
## Zorp — the lavender alien neighbour, and the one with a BEARD OF TENTACLES.
##
## R6 (2026-09-14, A BEARD OF TENTACLES). The user: "just have his whole bottom of his face be a beard
## of tentacles (mouth not visible) with thicker tentacles than what he has today". Three changes:
##   1. THE MOUTH IS GONE, in every state. `"mouth": false` means no mouth node is built, so talk,
##      happy, surprised and every emote have nothing to open. R5's thin ink line, its winding fix
##      and the open-mouth sizes are deleted with it.
##   2. R5's six thin cheek tentacles became FOUR LONG, FAT, CURLED TENTACLES in one row across the
##      whole lower face — 57-62 mm base radius against R5's 26-30 mm, 34-37 mm at the tip against
##      9-11 mm. Speech and emotion moved into the beard and the eyes (`_animate_extras`).
##   3. The "^ ^" happy eyes, which had never rendered on Zorp, now do (`_wound_outward`): with no
##      mouth the eyes carry more of the face.
## R6.1 (2026-09-14, THE USER PICKED "A"). R6 first shipped eight short curls in two rows ("B"); the
## user looked at both on one sheet and said "I like Zorp A". A had one recorded flaw, fixed here
## without changing its shape — see "THE CHIN" in the beard block.
## R6.2 (2026-09-14, THE CHIN HOLDS THROUGH THE HAPPY EMOTE). A critic's dense phone captures found
## the collar still showing under the beard in every happy frame: the hop tips the head back 9 deg,
## the chin swung back behind the collar with it, and its narrow bottom left the scarf showing
## beside it. The chin now hangs in the TORSO's frame (the exact inverse of the head's rotation) and
## is a little wider and deeper — see "THE CHIN".
## Everything else below is R5 and earlier and still true, except where it talks about the mouth line
## and the six cheek tentacles, which R6 replaced.
##
## R5 (LESS CREEPY, AND THE TENTACLES FINALLY GET BUILT). The user looked at the R4 Zorp and said
## his eyes and lips "look too strange... can we make them less creepy", asked for tall black
## ellipses instead of the eyes, "just leave the line and no lips" for the mouth, and — instead of
## the single antenna, which Pip also wears — three tentacles on each side of the face. Four
## changes, and each one is a deletion except the last:
##
##   1. THE IRIS AND THE SCLERA ARE GONE, replaced by ONE solid near-black ellipse per eye, 116 mm
##      tall by 68 mm wide (1.71 : 1). The sclera is what was doing the damage, and it is worth
##      being precise about why, because "add an iris" reads like a warmth move on paper: a PALE
##      BALL carrying a small dark PUPIL is the anatomy of a prey animal's eye, and the R4 build
##      stacked an amber annulus around that pupil, which is specifically a goat/bird read. Rendered
##      close up it was three concentric bands — cream, ochre, black — sitting proud of the head as
##      two balls stuck on, and that is what "creepy" meant. A flat ink shape has no ball, no ring
##      and nothing to stare with. The R4 note claimed the iris was "his face's identity"; it was,
##      and that was the problem. The eye is now the only face part with any ink in it, so the glint
##      is load-bearing — see the eye block for why it was re-authored rather than left alone.
##   2. THE LIP IS GONE. R4 built a 33 mm-thick mauve band standing 21 mm proud of the shell with a
##      dark seam along its crest, on the argument that thickness is what survives at 8 m. It does
##      survive — it survives as LIPSTICK, because a warm band is the only warm thing on a face with
##      no nose and no blush, and it takes a specular highlight along its top edge. What the user
##      was pointing at when they said "the line" was the 9.6 mm seam, so the seam is all that is
##      left: a 22 mm ink arc on the bare shell, `_smile_arc`'s curve at a thinner tube than the
##      default. The OPEN mouth (dark ellipse, interior, tongue) is untouched and still reads.
##   3. THE ANTENNA IS GONE, and this one is a cast decision rather than a Zorp decision. Pip wears
##      an antenna too, the user noticed the duplication, and Pip's is DIALOGUE-LOCKED — six shipped
##      lines in npc_data.gd talk about it — so Pip's cannot move. Zorp's could, so Zorp's went, and
##      the antenna is now unique to Pip. The mint accent survives in the hover ring, which is where
##      BULB still gets used.
##   4. SIX FACE TENTACLES, three a side. This is the one trait the user named two rounds ago that
##      nobody had ever shipped — docs/OPEN_ISSUES.md tracked it as zero call sites, and explicitly
##      ruled Zorp out as its home on the grounds that he was the deliberate control who spends none
##      of the vocabulary budget. The user has now overridden that, so Zorp is NOT the control any
##      more, and the ruling and the CAST_VARIETY row that depends on it are both stale.
##
## He does still wear none of the HARD vocabulary — no brow ridge, no heavy lid, no horns, no tusks,
## no fangs, no shoulder yoke, no lashes — so everyone else's ridge or crest still reads as a choice
## rather than as the house style. The tentacles are soft vocabulary and they are his alone.
##
## R4 SKIN, kept: SMOOTH WITH BIG SOFT SPOTS — the user's exact first ask. `surface_scales` is 0,
## which kills the Voronoi cell walls entirely (they are what has been reading as "rocky texture
## skin"), and the lattice pitch and spot radius together take 65 mm speckles up to ~210 mm blotches.
## It costs LESS palette than the pattern it replaces, not more: an A/B on one identical frame
## (strength 0 vs on, same crop) moves the head crop's saturation mean by +0.028, against the +0.099
## the old setting was measured at. See SURF_HEAD.
##
## Kept, because they are the half of him that already worked: lavender, the striped space-scarf, the
## teal tee with its badge, three-fingered mittens, the bean torso, and the 5 cm hover with its bob
## and glow ring — he is the only neighbour who floats and that is half his identity. He also keeps
## his legs and a real walk cycle; the hover is a hover, not a substitute for a lower body. The
## think-droop and the talk-perk the antenna used to carry did NOT die with it: `_animate_extras`
## drives the same EXTRA_A channel into the beard, so "think" still slackens something and "talk"
## still moves it.
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
## THE EYE INK, and after R5 it is the whole eye rather than a pupil inside one. S 0.21 V 0.18 — a
## near-black that is still violet, not a pure #000, so the shade term has something to do and the
## ellipse does not read as a die-cut hole. `_add_face` builds the oval material from it at
## spec 0.0 / rim 0.0 / shade 0.08, i.e. deliberately flat: a specular lobe on a 116 mm ink shape is
## the shine that made the R4 lip read as lipstick, and it would do the same to an eye.
const EYE := Color("#221c2e")
const BLUSH := Color("#b3868f")      ## passed but switched off — see `_add_face`'s transparency trap
const SCARF_A := Color("#c4858f")
const SCARF_B := Color("#e8ddc9")
const SHIRT := Color("#84bdb5")      ## a proper tee — every AC villager wears clothes
const SHIRT_TRIM := Color("#e8ddc9")
const FOOT := Color("#665c93")
const HOVER := 0.05
## Mint. This WAS the antenna bulb's emissive; the antenna is gone and this is now purely the hover
## glow's accent (`_build_glow_ring`, `_animate_extras`). It is kept because a small saturated accent
## is allowed and because deleting it with the antenna is a compile error, not a cleanup.
const BULB := Color("#7fffd4")

# ----------------------------------------------------------------------------------------- eyes
## R5 — ONE TALL INK ELLIPSE PER EYE, seated flat ON the shell. No ball, no ring, no lens stack.
## 116 mm tall by 68 mm wide is 1.71 : 1, which is inside the 1.6-2.0 the brief asked for and is
## also where the shape stops being ambiguous: below about 1.4 a "tall" oval just reads as a circle
## that has been squashed by the blink, because `_apply_face` drives `oval.scale.y` down for blinks
## and a near-round eye spends part of every cycle indistinguishable from a wide one.
##
## THE BROW IS ALREADY OFF and there is no `_drop_brow` to go looking for: `_add_face` is called
## with `"brows": false`, which is a per-eye spec switch `_build_eye` reads, so no brow is ever
## built. Nothing to remove for R5's "drop the brow".
##
## WHY THE YAW MOVED 22.5 -> 20.0, with the arithmetic, because eye spacing is a REVIEWED metric and
## moving one silently is how a style-guide band gets broken. On this shell (semi 0.3200/0.2250/
## 0.2720, n 3.2) the surface point at yaw 22.5 has x = 0.11133, so the two centres are 222.7 mm
## apart = 34.8 % of the 640 mm head — the very TOP of the mandated 28-35 % band, and it was tuned
## for a 104 mm-wide pale ball. The new eye is only 68 mm wide, so at 22.5 the gap between the two
## INNER EDGES opens from 119 mm to 155 mm and the face reads wall-eyed: the eyes stop being a pair.
## At yaw 20.0 the surface x is 0.09828 (s = 53.85, s^(-1/3.2) = 0.28773), centres 196.6 mm = 30.7 %
## of head width — mid-band — and the inner gap comes back to 128.6 mm, within 8 mm of what R4
## shipped.
##
## MEASURED AS RENDERED, because the style guide's band is on the rendered figure and the projection
## widens the geometric one. Connected-component pass over the near-black pixels in the portrait
## capture: two blobs 29 x 51 and 28 x 51 px, centres 94.6 px apart, on a head 277 px wide at the
## eye row. That is 34.2 % — inside the 28-35 % band, at its top, and 0.6 points BELOW where the R4
## build's geometry already sat before its own projection widened it further. As-rendered aspect is
## 1.76 : 1 and 1.82 : 1 against the 1.71 authored (the ellipse curves away at its sides, so the
## silhouette loses width before it loses height), still inside the 1.6-2.0 asked for. Eye width is
## 10.5 % of head width rendered against 10.6 % authored.
const EYE_YAW_A := 20.0
const EYE_PITCH_A := 3.0             ## vertical middle of the face
const EYE_W := 0.034                 ## half-width  ->  68 mm  = 10.6 % of head width
const EYE_H := 0.058                 ## half-height -> 116 mm  = 25.8 % of head height
const EYE_D := 0.016                 ## half-depth
## INSET IS POSITIVE, i.e. the eye node sits 6 mm INSIDE the shell, and it must stay that way.
## The oval's 16 mm half-depth then stands 10 mm proud at the centre while its zero-depth RIM is
## buried. Over the ellipse's 58 mm half-height this flat forehead only recedes 2.9 mm (solved on
## the shell: at x = 0.09828 the surface z goes from -0.26999 at the eye's own height to -0.26706
## at 58 mm up), so the rim is still 3.1 mm under the surface at the top and the bottom. Pushing the
## inset negative to seat the eye proud is the obvious "make it pop" move and it is wrong here: on a
## nearly flat forehead a proud tall ellipse shows a floating collar at its extremes, which is the
## exact failure the deleted iris solve was written to avoid.
const EYE_INSET := 0.006
## The "^ ^" and "O O" expression meshes are authored at chibi eye size, so they are fitted to THIS
## eye by hand. `fit_expr` is still not used — it normalises against the chibi constants, which is
## the wrong reference for a 116 mm ellipse.
##   HAPPY_FIT  the happy arc is `arc_tube(0.042, 0.0115, 24deg, 156deg)` = 99.8 mm wide at 1.0;
##              0.72 gives 72 mm against a 68 mm eye, a hair wider, which is what a smiling arc
##              closing over an eye should be.
##   ROUND_FIT  the surprise ball is authored 86 x 96 mm; (0.79, 0.81) gives 68 x 78 mm — so on
##              "surprised" the eye gets SHORTER and ROUNDER than it is at rest. That inversion is
##              the whole point: with a tall resting ellipse, a taller surprised one reads as
##              nothing, and the "O O" only lands if the shape actually changes kind.
## BOTH KEEP Z AT 1.0. The z of those nodes is their standoff from the shell plus their own solid
## depth; squashing it buries them. Checked: Round sits at eye-local z -0.002 with a 16 mm half-
## depth so its front is 12 mm proud of the shell, Happy at z -0.004 with an 11.5 mm tube radius
## (unscaled in z) so its front is 9.5 mm proud. Both clear.
const HAPPY_FIT := 0.72
const ROUND_FIT := Vector2(0.79, 0.81)

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

## Every beard JOINT pivot, flat, in build order, and its animation constants (BP_STRIDE per joint,
## same order). `_build_tentacles` clears both; `ChibiModel.rebuild()` has no idea they exist.
var _tentacles: Array[Node3D] = []
var _beard_params := PackedFloat32Array()
## The chin's pivot, at the head's origin. `_animate_extras` gives it the inverse of the head's basis
## every frame, so the chin keeps the torso's orientation (see THE CHIN). Rebuilt with the beard.
var _chin_pivot: Node3D
var _glow_ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _bob: float = 0.0
## A SEPARATE clock from `_bob`, and this is not tidiness — see `_animate_extras`.
var _sway: float = 0.0
var _ripple: float = 0.0             ## the talk ripple and the happy wag
var _quiver: float = 0.0             ## the surprised shiver


func _init() -> void:
	super()
	hover_height = HOVER
	# THE EYE'S SIZE LIVES HERE AND NOWHERE ELSE. `_apply_face` rewrites `oval.scale` from
	# `_eye_size[i]` every single frame, and `_build_eye` fills `_eye_size` from the spec's w/h/d,
	# which default to these three — so the spec omits them, anything assigned to `oval.scale` by
	# hand is gone by frame 1, and this is the one place the number can be authored.
	#
	# Leaving them model-wide (rather than per-spec) also keeps `_build_eye`'s `expr` at exactly
	# (1, 1, 1), which is what the HAPPY_FIT / ROUND_FIT numbers are measured against.
	eye_w = EYE_W
	eye_h = EYE_H
	eye_d = EYE_D
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
	# files have hit that trap. And since R6, NO MOUTH: the beard covers the whole lower face, so no
	# mouth node is built at all (the mouth colour argument is unused) and no state can show one.
	_add_face(EYE, EYE, BLUSH, {
		"nose": false, "blush": false, "brows": false, "mouth": false,
		"eyes": [_eye_spec(-1.0), _eye_spec(1.0)],
	})
	_fit_eyes()
	_build_scarf()
	_build_tentacles()
	_build_glow_ring()


# ================================================================================= eyes on the head
## The spec `_add_face` builds one eye from. NO `pos` KEY — that is the change that matters. R4
## passed one, which told `_build_eye` to place the eye outright, because the pupil belonged to a
## ball floating off the shell rather than to the shell. With the ball gone the eye is a shape ON
## the head again, so it is seated by `_orient_on_head` on the same superellipsoid
## `_add_head_shell` builds, and it travels with `head_semi` / `head_n` for free.
##
## No w/h/d either: those come from the model-wide `eye_w`/`eye_h`/`eye_d` set in `_init`, which is
## what holds `_build_eye`'s expression scaling at exactly 1.0.
func _eye_spec(sx: float) -> Dictionary:
	return {"yaw": EYE_YAW_A * sx, "pitch": EYE_PITCH_A, "inset": EYE_INSET}


## The three things about the ink ellipse the base class cannot know: it needs a denser mesh than a
## pupil does, its glint has to be re-authored against a non-uniform scale, and its expression
## meshes are authored at chibi size. Everything else about the eye is `_build_eye`'s.
func _fit_eyes() -> void:
	for i in _eye_ovals.size():
		var oval := _eye_ovals[i]
		# MESH DENSITY. `_eye_mesh("oval")` returns `sphere(1.0, 14, 8)`, which after DETAIL 0.60
		# resolves to 8 radial x 5 rings — roughly a 12-sided silhouette. That is invisible on the
		# 44 mm pupil it was chosen for, and visibly polygonal on a 116 mm ellipse: you can see flat
		# sides on the R4 sclera, which was smaller than this. 18/11 resolves to 11 x 7, a ~16-sided
		# outline. Swapping `.mesh` is safe — `_apply_face` only ever writes `.scale` and
		# `.visible` — and the Glint is a CHILD of the oval, so it survives the swap.
		oval.mesh = sphere(1.0, 18, 11)
		# THE GLINT IS THE ONLY THING SAYING "EYE" RATHER THAN "HOLE", now the sclera is gone, so it
		# is worth the seven lines. `_add_glint` parents a unit sphere to the oval at local
		# (0.36, 0.40, -0.52) scale (0.19, 0.15, 0.72) — and those are OVAL-LOCAL, so they inherit
		# the oval's non-uniform scale. Left alone on a 68 x 116 mm eye they come out as a
		# 12.9 x 17.4 mm vertical STREAK, which reads as a second, smaller eye highlight bar.
		# Re-authored to 13.6 x 13.3 mm — a round dot — 11.6 mm out and 26.7 mm up from the centre.
		# Checked: the ellipse's half-width at y = 26.7 mm is 30.2 mm and the dot spans 4.8-18.4 mm,
		# so it is comfortably inside the outline; and its front face lands 6.7 mm proud of the eye
		# surface at that point, so the eye cannot swallow it. Both eyes' glints sit on the SAME
		# side — a highlight comes from one light, and mirroring them reads as a squint.
		var glint := oval.get_node_or_null("Glint") as MeshInstance3D
		if glint != null:
			glint.position = GLINT_AT
			glint.scale = GLINT_R
		# X and Y only. Z is these nodes' standoff plus their own depth — see ROUND_FIT's note.
		_eye_happy[i].scale = Vector3(HAPPY_FIT, HAPPY_FIT, 1.0)
		# see `_wound_outward`: without this his happy eyes do not render at all
		var arc := _eye_happy[i].get_node_or_null("Arc") as MeshInstance3D
		if arc != null and arc.mesh is ArrayMesh:
			arc.mesh = _wound_outward(arc.mesh as ArrayMesh)
		_eye_round[i].scale = Vector3(ROUND_FIT.x, ROUND_FIT.y, 1.0)
		_glint_the_round_eye(_eye_round[i])


## A GLINT ON THE "O O" SURPRISE EYE, because without one --state=surprised is the one pose where
## Zorp goes back to being creepy — and creepy is the exact thing R5 was written to fix.
##
## WHAT GOES WRONG WITHOUT IT. `_apply_face` swaps expressions by VISIBILITY: it hides the Oval and
## shows `_eye_round`. The resting glint is a CHILD of the Oval, so it is hidden along with it, and
## `_build_eye` gives the Round node a bare solid Ball and no highlight of its own. On every other
## neighbour that is survivable — their resting eye is a small dark pupil on a pale sclera, so the
## surprise ball is a small dark mark on a face that still has whites in it. On Zorp there is no
## sclera left: the eye IS the ink, 68 x 78 mm of it, and with the glint gone the pose is two flat
## black holes. The critic's word for it was "creepy", which is the user's word from R5.
##
## THE FIX IS LOCAL. The clean place for it is `_build_eye`, which already knows the highlight
## material and could give the Round node a glint the same way it gives the Oval one, but
## chibi_model.gd is off limits this round; if it opens up, the fix there is one `_add_glint` call
## against the Ball's parent and this function goes away.
##
## PARENTED TO THE ROUND NODE, NOT TO THE BALL. The Ball carries the non-uniform scale that makes
## the ellipse (0.043 x 0.048 x d, i.e. 0.90 : 1), so a unit sphere hung off it comes out as a
## squashed dash rather than a dot — the same trap the resting glint's re-authoring above is about,
## and the reason `Round` (whose own 0.79 / 0.81 is nearly uniform) is the right parent. The 0.79 /
## 0.81 is then divided back out below so what lands on screen is a dot and not a 2.5 % ellipse.
##
## PLACED TO MATCH THE RESTING GLINT IN WORLD TERMS, not in fractions of its own eye: the highlight
## comes from one light, and a highlight that jumps when an expression changes reads as the eye
## having MOVED. Resting glint centre is (0.34, 0.46, -0.52) of the oval's (34, 58, 16) mm
## half-extents, i.e. (11.6, 26.7, -8.3) mm in the eye's frame; the Round node sits at
## (0, 3, -2) mm in that same frame, so the local offset is ((11.6 - 0) / 0.79,
## (26.7 - 3) / 0.81, (-8.3 + 2) / 1.0). Solved from the constants below rather than typed in, so
## it tracks EYE_W / EYE_H / EYE_D and ROUND_FIT if any of them move again.
##
## CHECKED AGAINST THE BALL IT SITS ON, because a highlight that clips out of its own eye or sinks
## into it is worse than none. In Round-local units the ball is an ellipsoid of radii
## (0.043, 0.048, 0.016) and the dot's centre lands at (0.0146, 0.0292, -0.0063) — normalised
## (0.34, 0.61), r^2 = 0.49, comfortably inside the outline, and even the corner of the dot's
## bounding box is at r^2 = 0.90. Depth: the ball's front surface at that point is at z = -0.0115
## and the dot's front face at -0.0178, so it stands 6.4 mm proud — within 0.3 mm of the 6.7 mm the
## resting glint stands proud of the resting eye, so it catches the same amount of light.
##
## `_eye_happy` DELIBERATELY GETS NOTHING. The "^ ^" arc is a 23 mm stroke, not a mass — there is no
## hole for a highlight to rescue — and a specular dot on an eye that is drawn CLOSED reads as an
## error rather than as life. NOT verified in a render, and it is worth saying so: --state=happy
## pitches the head far enough back that the lineup camera sees the underside of the chin and not
## the face at all, at 2.4 s, 3.2 s and 4.6 s. So this is an argument, not a measurement — if the
## happy pose is ever re-aimed and the arcs turn out to need life, the same helper works on
## `_eye_happy[i]` with HAPPY_FIT in place of ROUND_FIT.
const GLINT_AT := Vector3(0.34, 0.46, -0.52)   ## oval-local centre of the resting glint
const GLINT_R := Vector3(0.20, 0.115, 0.72)    ## oval-local radii of the resting glint

func _glint_the_round_eye(round_eye: Node3D) -> void:
	if round_eye.get_node_or_null("Glint") != null:
		return
	var fs := face_scale
	# The resting glint expressed in the EYE's frame: the oval sits at the eye's origin and carries
	# scale (eye_w * fs, eye_h * fs, eye_d), and GLINT_AT / GLINT_R are fractions of that.
	var eye_sz := Vector3(EYE_W * fs, EYE_H * fs, EYE_D)
	var centre := GLINT_AT * eye_sz
	var radii := GLINT_R * eye_sz
	var rs := Vector3(ROUND_FIT.x, ROUND_FIT.y, 1.0)
	var dot := _mi(sphere(1.0, 8, 4), _toon(GLINT, {"spec": 0.0, "rim": 0.0, "shade": 0.02}),
		round_eye, (centre - round_eye.position) / rs, "Glint")
	dot.scale = radii / rs


# ------------------------------------------------------------------------------------- the beard
## R6 — THE TENTACLE BEARD. Chubby strands mirrored in pairs across the whole lower face, seated where
## the mouth used to be and hanging over the chin. There is no mouth under them: `_add_face` is called
## with `"mouth": false`, so no mouth node is ever built and no state can show one. Speech and emotion
## live in `_animate_extras`.
##
## [yaw_deg, pitch_deg, front_deg, splay_deg, drop, base_r, tip_r, curl_rad], every row mirrored.
##   yaw/pitch   where the root sits, solved on the head shell (`_orient_on_head`), so it follows
##               `head_semi` / `head_n`. Pitch -16 to -24 is the old mouth line (the mouth sat at -20).
##   front       the azimuth the strand leans and CURLS toward (`_hang_basis`): 90 straight forward,
##               0 straight out to the side.
##   splay       how far off straight-down the root leans before the curl starts.
##   drop        length. base_r / tip_r its radius at each end. curl the total turn, root to tip.
##
## ONE ROW OF FOUR: two long inner strands under the eyes that curl forward, and two outer ones at
## the cheeks that curl out and up. Together they span the lower face cheek to cheek.
##
## NO CENTRE STRAND, on purpose. An odd count puts the longest strand on the midline, hanging down
## the chest like a trunk, and that single long dangling limb is the whole Cthulhu read.
##
## THE CHIN (R6.1), the fix for A's one flaw. On the phone camera (34 deg down, 2556x1179
## --ui=mobile) the inner pair hung apart in a "^", and the pink scarf collar showing through that gap
## read as an open mouth, with the two strands as mandibles either side of it. Three fixes were
## rendered in the real game on Zorp's world and rejected before this one:
##   * inner pair turned fully forward or crossed inward (front 90-105, yaw 6-7): the two strands
##     fused into one trunk, and the collar still showed between them and the outer pair;
##   * a filler in the beard's own tint behind the strands: the whole lower face became one lump
##     and the four curls stopped reading as four;
##   * the same filler darker (a recess): the gap came back as a dark "^", which is a mouth again.
## What holds is a CHIN: one head-spotted superellipsoid under the jaw, set back behind the strands
## and down over the front of the collar, so what shows between the tentacles is more of his face. The inner pair is also tipped 7 deg toward the middle (front 65 -> 72, yaw
## 9 -> 8), which narrows the "^" without closing it. Measured on the phone frames, the collar-pink
## pixels with beard or skin on BOTH sides of them within 25 px (the "between the tentacles" count)
## went from 62 / 108 / 47 / 96 / 62 to 0 / 0 / 0 / 0 / 0 in idle / talk / talk +0.17 s / surprised /
## happy; the scarf still shows at the sides and back.
## R6.2: that 0 was one frame 0.5 s into each state. Captured densely (38 frames: idle, 14 talk
## frames 0.11 s apart, 8 surprised, 12 happy 0.13 s apart), the collar still showed under the face
## in every happy frame, because the chin is part of the head and the happy pose tips the head back
## (HEAD_PITCH -0.16): the chin's bottom swung BACK behind the collar's front, and the camera looking
## down saw the collar in front of it. Two changes, each measured in the real game on Zorp's world:
##   * the chin hangs from `_chin_pivot`, whose basis is set every frame to the exact inverse of the
##     head's, so the chin stays where the torso put it while the face tips, rolls and turns above
##     it. No gain, no tuned angle. Alone it cut the count of collar pixels under the face (columns
##     within 34 px of the eyes' centre, from the eye line down to the sweater) from 313 to 97 over
##     the 12 happy frames, and the rest was the collar showing beside the chin's narrow bottom;
##   * the chin is wider and deeper, 0.17 x 0.09 -> 0.20 x 0.10 with its centre 10 mm lower (bottom
##     y -0.38 -> -0.40), which covers the collar between the inner and outer strands. Over a
##     74-frame timeline (the one above plus a second happy at a shifted phase, wave, dance, think
##     and a second surprised) that left 0 such pixels in every frame but 4 of the 12 dance frames
##     (1-2 px each). The in-between size (0.20 x 0.09, bottom -0.38) left 6 / 5 in the two
##     happies and 6 in idle.
## COST: 4 strands x 3 joints + the chin = 13 draws against the eight-curl beard's 16; 5678
## triangles in characters_lineup --stats against 5854, inside the 6000 budget.
const BEARD := [
	[8.0, -21.0, 72.0, 3.0, 0.175, 0.062, 0.037, 1.40],
	[31.0, -19.0, 25.0, 7.0, 0.150, 0.057, 0.034, 2.00],
]
## How far the root sits inside the shell, as a fraction of its base radius — enough that the round
## root cap emerges from the skin rather than resting on it.
const BEARD_INSET := 0.55
## Nested joints per strand; each is one draw call.
const BEARD_JOINTS := 3
## Tube resolution, authored directly rather than through DETAIL (the cast helpers' 4-6 sides read
## as square rods at this thickness). Inner joints get one ring fewer and a one-ring dome — their end
## is hidden inside the next joint and only has to fill the gap when the joint bends.
const BEARD_SIDES := 8
const BEARD_RINGS := 3
const BEARD_DOME := 2
## THE CHIN (see above): centre and semi-axes in head space. Its top sits inside the shell, its front
## (z -0.21) behind the strands' roots (about -0.24), and its bottom (y -0.40) below the scarf's top
## stripe, which otherwise peeked out under the beard as a cream line when the head tips back.
## R6.2: 30 mm wider, 20 mm taller, and it hangs in the torso's frame (`_chin_pivot`).
const CHIN_POS := Vector3(0.0, -0.30, -0.11)
const CHIN_SEMI := Vector3(0.20, 0.10, 0.10)
const CHIN_N := 3.0
## The rest angle of the root joint, tipping the whole strand slightly outward off the face.
const BEARD_ROOT_LEAN := 0.04
## The widest seat yaw in BEARD. A strand's share of the sideways SPREAD (surprise, happy) is its yaw
## over this, so the inner pair barely moves and the beard never parts down the middle — a parted
## beard shows the pink collar behind it, and a pink gap under the eyes reads as an open mouth.
const BEARD_OUTER_YAW := 31.0

## THE BEARD'S COLOUR AND SKIN, both picked on renders, not on swatches.
##   * TINT #9282b6 keeps SKIN's hue (259 against 261 deg), sits between SKIN and SKIN_DARK in value
##     (V 0.71) and drops saturation from 0.37 to 0.29. Rendered side by side in one pose: at SKIN the
##     beard melted into the face; at SKIN_DARK (the first build) it read as a bluer, heavier animal
##     clamped over his chin; at the plain halfway point #8b75b9 it looked right but the lit render
##     pushes a darker lavender UP in saturation, and the head crop's beard swatch came out at S 0.60
##     (0.64 in its shadow) — on the gate. Measured at #9282b6 on the same crop (510,120,770,380 of a
##     1280x720 portrait): beard swatch S 0.42-0.46, crop saturation mean 0.462 / 0.472 and p90
##     0.559 / 0.562 on Compatibility / Forward+, against today's R5 face at 0.498 / 0.519 and 0.722 /
##     0.718. #9786ba (lighter again) measured lower still but read as a milky white moustache.
##   * R6.1 #9586b4 (S 0.26, V 0.71, hue 260). Four long strands leave more of the head skin
##     showing between them than eight short curls did, and at #9282b6 the same crop measured
##     saturation mean 0.473 / 0.471 (Compatibility idle / talk) and 0.487 / 0.495 (Forward+), over
##     the 0.48 gate on Forward+. At #9586b4, rendered in the same session with the same cameras:
##     0.449 / 0.451 and 0.468 / 0.468, p90 0.559-0.641. Side by side the strands are a touch greyer
##     and do not go milky. (Same-frame re-renders of one build vary by about +-0.01.)
##   * SURF_BEARD keeps the skin family (spots that stop at the jaw read as a mask) but at a coarser
##     pitch and 0.6 strength. At SURF_LIMB's 49 mm cells every strand carried a row of dark speckles
##     that read as SUCKERS, and the pattern broke at every joint (each segment is its own mesh, and
##     the pattern is in object space), so the strands looked ribbed like caterpillars.
const BEARD_TINT := Color("#9586b4")
const SURF_BEARD := {"surface": "skin", "surface_scale": 1.30, "surface_strength": 0.60,
	"surface_spot": 1.00, "surface_scales": 0.0, "surface_spot_radius": 0.74,
	"surface_near": 7.0, "surface_far": 20.0}

## Stride of `_beard_params`, one row per joint: k, period, phase, rest_x, spread_x, spread_z, root.
const BP_STRIDE := 7


func _build_tentacles() -> void:
	# LOAD-BEARING. `ChibiModel.rebuild()` frees every child but knows nothing about these arrays;
	# without the clear a second rebuild leaves freed nodes that `_animate_extras` touches next tick.
	_tentacles.clear()
	_beard_params = PackedFloat32Array()
	var m_tent := _toon(BEARD_TINT, _matte(SURF_BEARD))
	var strand := 0
	for t: Array in BEARD:
		for sx: float in [-1.0, 1.0]:
			var seat := _node("Tentacle%d" % strand, _head, Vector3.ZERO)
			# `_orient_on_head` for the POSITION only; its basis faces outward and would hang the
			# strand back under the chin, so the basis is replaced (never `.rotation`, see R5).
			_orient_on_head(seat, float(t[0]) * sx, float(t[1]), float(t[5]) * BEARD_INSET)
			seat.basis = _hang_basis(sx, float(t[3]), float(t[2]))
			# SPREAD, solved from the frame rather than guessed: a joint's +rotation.x swings its hang
			# (-Y) toward -Z and +rotation.z toward +X, so the sideways direction (sx, 0, 0) maps to
			# (-side.z, side.x) in the seat's own axes. Weighted by yaw — see BEARD_OUTER_YAW.
			var side := seat.basis.inverse() * Vector3(sx, 0.0, 0.0)
			var w := clampf(float(t[0]) / BEARD_OUTER_YAW, 0.0, 1.0)
			_build_strand(seat, m_tent, t, Vector2(-side.z, side.x) * w, strand)
			strand += 1
	# THE CHIN. Head-spotted so it reads as more face, not as a lump of beard. Its colour is exactly
	# halfway from SKIN to BEARD_TINT, no new hue. At SKIN it read best in Compatibility, but it sits
	# in the head's shadow, and Forward+ rendered it a deep violet block (swatches S 0.60-0.66, head
	# crop p90 0.708 in talk); a raised shadow_floor on it changed nothing measurable. At BEARD_TINT
	# it merged with the strands into one grey lump. Halfway, over three Forward+ renders per state:
	# talk mean 0.477-0.484 / p90 0.669-0.677, idle 0.466-0.471 / 0.602-0.607.
	_chin_pivot = _node("ChinPivot", _head, Vector3.ZERO)
	_mi(superellipsoid(CHIN_SEMI, CHIN_N, 14, 8), _toon(SKIN.lerp(BEARD_TINT, 0.5), _matte(SURF_HEAD)), _chin_pivot, CHIN_POS, "Chin")


## ONE strand of BEARD_JOINTS nested pivots. The curl is BACK-LOADED (it grows with t squared), so a
## strand hangs first and its END turns out. Each child pivot sits exactly where its parent's tube
## ends and is turned by the angle that tube ended at, so the strand is continuous in position and
## direction and the joints disappear at rest.
func _build_strand(seat: Node3D, mat: Material, t: Array, spread: Vector2, idx: int) -> void:
	var drop := float(t[4])
	var r0 := float(t[5])
	var r1 := float(t[6])
	var curl := float(t[7])
	var seg := drop / float(BEARD_JOINTS)
	var cursor := seat
	var prev_c := 0.0
	for j in BEARD_JOINTS:
		var ta := float(j) / float(BEARD_JOINTS)
		var tb := float(j + 1) / float(BEARD_JOINTS)
		var c := curl * (tb * tb - ta * ta)
		var last := j == BEARD_JOINTS - 1
		var pos := Vector3.ZERO if j == 0 else _beard_end(seg, prev_c, _rings_for(false))
		var node := _node("Joint%d" % j, cursor, pos)
		node.rotation.x = BEARD_ROOT_LEAN if j == 0 else prev_c
		_mi(_beard_tube(seg, lerpf(r0, r1, ta), lerpf(r0, r1, tb), c, last, j == 0), mat, node,
			Vector3.ZERO, "Seg")
		prev_c = c
		# k grows down the strand and sums to 3 over the joints: nested joints add up, so a small
		# angle per joint moves the tip rather than shearing the root.
		var k := float(j + 1) * 6.0 / float(BEARD_JOINTS * (BEARD_JOINTS + 1))
		_beard_params.append_array([k, 1.55 + 0.17 * float(idx) + 0.21 * float(j),
			fmod(0.618 * float(idx) + 0.317 * float(j), 1.0), node.rotation.x, spread.x, spread.y,
			1.0 if j == 0 else 0.0])
		_tentacles.append(node)
		cursor = node


static func _rings_for(last: bool) -> int:
	return BEARD_RINGS if last else BEARD_RINGS - 1


## Where a beard tube of this length and curl ends, in its own space — the same path `_beard_tube`
## walks, so a child pivot placed here cannot drift off its parent's end.
static func _beard_end(length: float, curl: float, n: int) -> Vector3:
	var p := Vector3.ZERO
	for i in range(1, n + 1):
		var a := curl * (float(i) - 0.5) / float(n)
		p += Vector3(0.0, -cos(a), -sin(a)) * (length / float(n))
	return p



static var _beard_cache: Dictionary = {}

## A HANGING, TAPERING, CURLING TUBE with a round domed end. It runs down -Y from the origin and turns
## toward -Z (the outward side `_hang_basis` sets up). `root` swaps the flat top cap for a round one,
## so the strand grows out of the face instead of showing a cut edge where it enters the skin.
## Wound CLOCKWISE seen from outside, which is Godot's front face under `toon_soft`'s cull_back.
static func _beard_tube(length: float, r0: float, r1: float, curl: float, last: bool, root: bool) -> ArrayMesh:
	var key := "%.4f|%.4f|%.4f|%.4f|%s|%s" % [length, r0, r1, curl, last, root]
	if _beard_cache.has(key):
		return _beard_cache[key]
	var n := _rings_for(last)
	var dome_n := BEARD_DOME if last else 1
	var sides := BEARD_SIDES
	var rings: Array[PackedVector3Array] = []
	var norms: Array[PackedVector3Array] = []
	if root:
		var rr := PackedVector3Array()
		var rn := PackedVector3Array()
		for s in sides:
			var b := TAU * float(s) / float(sides)
			var d := (Vector3.RIGHT * cos(b) + Vector3.FORWARD * sin(b)) * 0.7071 + Vector3.UP * 0.7071
			rr.append(d * r0)
			rn.append(d)
		rings.append(rr)
		norms.append(rn)
	var p := Vector3.ZERO
	var tang := Vector3.DOWN
	var slope := (r1 - r0) / maxf(length, 1e-5)
	for i in n + 1:
		if i > 0:
			var a := curl * (float(i) - 0.5) / float(n)
			p += Vector3(0.0, -cos(a), -sin(a)) * (length / float(n))
		var ai := curl * float(i) / float(n)
		tang = Vector3(0.0, -cos(ai), -sin(ai))
		var r := lerpf(r0, r1, float(i) / float(n))
		var n2 := Vector3.RIGHT.cross(tang).normalized()
		var ring := PackedVector3Array()
		var nr := PackedVector3Array()
		for s in sides:
			var b := TAU * float(s) / float(sides)
			var radial := Vector3.RIGHT * cos(b) + n2 * sin(b)
			ring.append(p + radial * r)
			nr.append((radial - tang * slope).normalized())
		rings.append(ring)
		norms.append(nr)
	var n2e := Vector3.RIGHT.cross(tang).normalized()
	for k in range(1, dome_n + 1):
		var phi := (float(k) / float(dome_n + 1)) * PI * 0.5
		var ring := PackedVector3Array()
		var nr := PackedVector3Array()
		for s in sides:
			var b := TAU * float(s) / float(sides)
			var d := ((Vector3.RIGHT * cos(b) + n2e * sin(b)) * cos(phi) + tang * sin(phi)).normalized()
			ring.append(p + d * r1)
			nr.append(d)
		rings.append(ring)
		norms.append(nr)
	var verts := PackedVector3Array()
	var vn := PackedVector3Array()
	var uv := PackedVector2Array()
	for i in rings.size():
		verts.append_array(rings[i])
		vn.append_array(norms[i])
		for s in sides:
			uv.append(Vector2(float(i) / float(rings.size()), float(s) / float(sides)))
	var apex := verts.size()
	verts.append(p + tang * r1)
	vn.append(tang)
	uv.append(Vector2(1.0, 0.5))
	var top := verts.size()
	verts.append(Vector3.UP * r0 if root else Vector3.ZERO)
	vn.append(Vector3.UP)
	uv.append(Vector2(0.0, 0.5))
	var idx := PackedInt32Array()
	for i in rings.size() - 1:
		for s in sides:
			var a0 := i * sides + s
			var a1 := i * sides + (s + 1) % sides
			var b0 := (i + 1) * sides + s
			var b1 := (i + 1) * sides + (s + 1) % sides
			idx.append_array([a0, b1, b0, a0, a1, b1])
	var lastr := (rings.size() - 1) * sides
	for s in sides:
		idx.append_array([lastr + s, lastr + (s + 1) % sides, apex])
		idx.append_array([top, (s + 1) % sides, s])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = vn
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_beard_cache[key] = mesh
	return mesh


## THE "^ ^" ARC, TURNED RIGHT WAY OUT. `arc_tube` in chibi_model.gd is wound inside-out (its own
## docs say so), and under cull_back only the far wall draws. On Zorp's flat ink eye that far wall
## is buried in the shell, so before R6 his happy eyes rendered as NOTHING — a blank face in happy,
## wave and dance. With the mouth gone the eyes carry the expression, so it is fixed here, locally:
## the source mesh is shared with other characters and is copied, never edited.
static func _wound_outward(src: ArrayMesh) -> ArrayMesh:
	var key := "wound|%d" % src.get_instance_id()
	if _beard_cache.has(key):
		return _beard_cache[key]
	var arr: Array = src.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var flipped := PackedInt32Array()
	flipped.resize(idx.size())
	@warning_ignore("integer_division")
	var tris := idx.size() / 3
	for t in tris:
		flipped[t * 3] = idx[t * 3]
		flipped[t * 3 + 1] = idx[t * 3 + 2]
		flipped[t * 3 + 2] = idx[t * 3 + 1]
	arr[Mesh.ARRAY_INDEX] = flipped
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_beard_cache[key] = out
	return out



## EXPRESSION WITHOUT A MOUTH. Everything reads pose channels the cast already drives, so every state
## and emote gets beard motion for free and blends in and out with the pose:
##   idle       a slow lean down every strand, no two in step.
##   talk       (EXTRA_A 1) a ripple travels down each strand, and on every syllable (MOUTH_OPEN
##              pulsing) the tips flick out — the beat the open mouth used to carry.
##   happy      (EYE_HAPPY: happy, wave, dance) every strand curls up and wags, the outer ones perk out.
##   surprised  (EYE_ROUND) the beard fans out stiff and quivers.
##   think      (EXTRA_A -1) the strands go limp and slow down.
## The spread terms are per strand (BEARD_OUTER_YAW), so no state ever parts the beard in the middle.
func _animate_extras(delta: float) -> void:
	_bob += delta
	# soft hover bob (the whole model floats; the glow ring stays on the ground)
	_root.position.y = hover_height + sin(TAU * _bob / 2.6) * 0.022
	var think := clampf(-pose(P.EXTRA_A), 0.0, 1.0)
	var talk := smoothstep(0.3, 1.0, pose(P.EXTRA_A))
	var flick := talk * clampf((pose(P.MOUTH_OPEN) - 0.45) / 0.55, 0.0, 1.0)
	var happy := clampf(pose(P.EYE_HAPPY), 0.0, 1.0)
	var surpr := clampf(pose(P.EYE_ROUND), 0.0, 1.0)
	# INTEGRATED clocks, not `_bob * rate`: a rate multiplied into an absolute clock jumps the phase
	# the instant an emote blends in, and the strands would snap.
	_sway += delta * (1.0 + 0.5 * talk + 1.1 * happy - 0.4 * think)
	_ripple += delta * 2.1
	_quiver += delta * 9.0
	# THE CHIN stays in the torso's frame: `_apply_pose` has just written this frame's head rotation.
	if _chin_pivot:
		_chin_pivot.basis = _head.basis.inverse()
	var still := 1.0 - 0.8 * surpr
	var rest_mul := 1.0 - 0.5 * think
	for i in _tentacles.size():
		var o := i * BP_STRIDE
		var k := _beard_params[o]
		var ph := _beard_params[o + 2]
		var spx := _beard_params[o + 4]
		var spz := _beard_params[o + 5]
		var root := _beard_params[o + 6]
		var w := TAU * (_sway / _beard_params[o + 1] + ph)
		var j := float(i % BEARD_JOINTS)
		var rx := _beard_params[o + 3] * rest_mul + 0.026 * k * sin(w) * still
		var rz := 0.020 * k * sin(w * 0.71 + 1.4) * still
		rx += talk * 0.12 * k * sin(TAU * (_ripple + ph) - 1.2 * j) + flick * 0.16 * k
		rx += happy * (k * (0.10 + 0.07 * sin(TAU * (_ripple * 1.6 + ph))) + 0.22 * root * spx)
		rz += happy * 0.22 * root * spz
		rx += surpr * (0.50 * root * spx + 0.02 * k * sin(TAU * _quiver + ph * 5.0))
		rz += surpr * 0.50 * root * spz
		_tentacles[i].rotation = Vector3(rx, 0.0, rz)
	if _ring_mat:
		var a := 0.24 + 0.10 * sin(TAU * _bob / 2.6 + 1.2)
		_ring_mat.albedo_color = Color(BULB.r, BULB.g, BULB.b, a)


## THE FRAME A STRAND HANGS IN, built in head-local space so it owes nothing to the shell's normal
## at the seat. Two angles, both in degrees:
##   splay  how far off straight-down the strand leans, toward `front`. Small — 3-7 deg — because
##          the back-loaded curl turns the tip another 80-115 deg the same way.
##   front  the AZIMUTH of that lean in the head's XZ plane: 0 is straight out to the side, 90 is
##          straight forward. The inner pair (72) curls forward, the outer pair (25) out toward
##          the cheeks.
##
## The basis is built rather than eulered because the two angles are a direction, not a rotation
## order: -Y is the hang, and -Z is the outward direction the nested joints lean and curl toward (a
## joint's +X rotation tips it toward local -Z). `xb = yb.cross(zb)` keeps
## it right-handed — the same identity Basis.IDENTITY satisfies.
func _hang_basis(sx: float, splay_deg: float, front_deg: float) -> Basis:
	var outv := Vector3(sx * cos(deg_to_rad(front_deg)), 0.0, -sin(deg_to_rad(front_deg))).normalized()
	var s := deg_to_rad(splay_deg)
	var yb := -(Vector3.DOWN * cos(s) + outv * sin(s)).normalized()
	var zb := -(outv - yb * outv.dot(yb)).normalized()
	return Basis(yb.cross(zb), yb, zb)


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

