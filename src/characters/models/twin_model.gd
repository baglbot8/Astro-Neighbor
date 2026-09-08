class_name TwinModel
extends ChibiModel
## Pip & Pop — the Cosmo Depot twins (our Timmy & Tommy).
##
## R4 (CAST VARIETY). Before this pass the twins were differentiated ONLY above the collar: same
## `body_scale` 0.80, same torso, same apron, same neckband, hem, badge and rear bow, same eyestalks,
## same wide toothy grin, same `sd_skin`. The only differences were one stalk 134 mm taller and one
## extra antenna — which is a head-swap, not a pair of characters, and it is the exact failure the
## user named. They also shared a LITERAL cached ArrayMesh for the head, because `superellipsoid()`
## caches on its arguments and both passed (0.3420, 0.2320, 0.2760, 3.2, 44, 22).
##
## A twin pair only reads as a pair when the BODIES differ, so the split now starts at the skeleton:
##
##            PIP                                 POP
##   body     0.86, torso (0.94, 1.10, 0.94)      0.76, torso (1.10, 0.90, 1.08)
##            tall, narrow, high-waisted          wide, low, square, planted
##   head     0.616 w x 0.536 h, n 2.8            0.712 w x 0.408 h, n 3.0
##            aspect 1.15, soft, no crown seam    aspect 1.75, hard, crown seam kept
##   eyes     round pupil in a pale sclera,       raked solid almond, no sclera, no iris
##            hooded by a sleepy half-lid
##   crown    ONE curved matte knob feeler        TWO flat matte paddle blades, raked back
##                                                PLUS two giant swept horns at the temples
##   mouth    small round toothless slot          straight lipless bar
##   skin     sd_foliage (soft down)              NOTHING AT ALL
##   outline  broken by fur at jaw + shoulders    hard edges, now with a horned silhouette
##   garment  long gathered apron, dusty rose     short square waist apron + belly plate
##   manner   heavy lids over a FAST blink        wide-open eyes over a SLOW blink
##            (drowsy but fighting it)            blinks 0.6x as often, 8 % slower
##
## R5 (USER REQUEST). Two accessories were asked for by name — "make Pip's eyes half lidded like
## it's sleepy" and "Pop can get giant horns on each side of its head" — and both touch the standing
## hard-vocabulary cap, so the old paragraph here is amended rather than deleted. What it used to say
## was: "Neither twin gets lashes, brows, horns, tusks or a shoulder yoke: they are CHILDREN, and the
## standing ruling is that the cast's total of that hard vocabulary must go DOWN, not be re-sorted."
## That first clause is now FALSE and the ruling it cites is knowingly overridden:
##   * POP wears HORNS. 1 of his allowed 2 from {brow ridge, heavy lid, horns, tusks, fangs,
##     shoulder yoke} — he had zero before (no brow bar, no lid, no teeth of any kind, and his
##     plastron is a belly plate, not a shoulder yoke), so he is legal with one slot spare.
##   * PIP wears a LID. Counted here as 1 of her 2, conservatively: it is a soft skin-tone hood and
##     not Grig's bone ridge, but "heavy lid" is in the capped set by name and the honest place to
##     record a judgement call is next to the thing it excuses. She also had zero before.
## Cast-wide that is 4 -> 6 uses of the hard vocabulary, i.e. UP, which is the opposite of what
## CAST_VARIETY ruling 2 asks for. The user asked for both explicitly, so they ship — but the two
## ledgers that track it are now stale and belong to files this pass does not own:
## docs/CAST_VARIETY.md:64 ("Fen: none · Vela: none · Zorp: none") and docs/OPEN_ISSUES.md:611
## ("Fen and Vela carry none; every reworked model passes `brows: false`") both need a row saying
## Pop: horns (1 of 2) and Pip: sleepy lid (1 of 2). Whoever owns those files must add it.
##
## Everything ELSE separating the twins is still proportion, head shape, eye shape, palette
## temperature and manner, which is how Animal Crossing does it and which costs no dialogue edits —
## `npc_data.gd:228` ("That's my brother Pop. He has two antennae.") stays true word for word, and
## the horns are seated at the TEMPLES, far outboard of the paddles, precisely so that line and the
## five others about the antennae keep describing something the player can still see.
##
## DIALOGUE-LOCKED, DO NOT TOUCH: the antenna COUNT. Six shipped player-facing lines depend on it
## (npc_data.gd 228, 229, 241, 288, 297, 304 — "One antenna. Best antenna. Fact." / "Two antennae,
## two opinions. Both mine."). This pass changes the antennae's FORM, never their number, and both
## twins stop wearing the glowing bulb that made Zorp, Pip, Pop and Bolt read identically up top.

## R2.6 (PASTEL AND MATTE). Greens are one of the three offenders the user named by hue, and the
## twins are entirely green, so they got the biggest pull. Pip #8ed85a S0.58 V0.85 -> #93c169
## S0.46 V0.76; Pop #c2dd5c S0.59 V0.87 -> #c1ca70 S0.45 V0.79; apron #f7e8c6 V0.97 -> #d6c9a8
## V0.84 (no near-clipping whites); star #ffcc33 S0.80 -> #d9b96e S0.49. Hue is preserved in every
## case — pastel, not mud. Measured on a real noon frame afterwards: Pip head crop saturation mean
## 0.472 / value 0.739, Pop 0.394 / 0.744, 0 % blown, no dominant swatch above S 0.46.
const APRON := Color("#d6c9a8")
const STAR := Color("#d9b96e")
const EYE := Color("#231e2a")
const MOUTH := Color("#452c20")
const SCLERA := Color("#f2f4e6")     ## pale eyeball; the face's dark oval becomes the pupil
## R2.6 gate: every new colour below is under S 0.46 and V 0.85, checked at authoring time.
## PIP is the WARM half of the pair and POP the COOL half — palette temperature is one of the five
## non-accessory cues carrying them apart, so these must never converge.
const PIP_TRIM := Color("#c49a9c")   ## dusty rose apron trim  S 0.21 V 0.77
## THE RUFF MUST NOT BE HER SKIN COLOUR. The first build used #9fbf7e — one step off the body — and
## rendered as nothing: the fins were there, they simply had no edge to read against, so the only
## thing visible was a few stray spikes that looked like grass growing out of her jaw. Fur is a
## SILHOUETTE cue, and a silhouette needs a value step. #c3d3a2 is 0.83 value against the body's
## 0.76 and 0.24 saturation against 0.46, so the ruff reads as a pale fringe both against the head
## and against the night sky, which is where the broken outline actually has to work.
const PIP_FUR := Color("#c3d3a2")    ## S 0.24 V 0.83
const PIP_KNOB := Color("#c98f74")   ## warm coral feeler tip — matte, NOT an emissive bulb
const PIP_TONGUE := Color("#cf8490") ## S 0.36 V 0.81; the parent's #e8788f is S 0.48, over the gate
## PIP'S SLEEPY LID GETS NO COLOUR CONSTANT, AND THAT IS THE DECISION, NOT AN OMISSION.
## It is built in `skin` — her own body green, at her own `PIP_SURF_HEAD` downy nap — because the
## whole risk in this part is that it reads as a BROW. A dark bar above an eye is a brow; brows are
## the capped hard vocabulary; and this character has none precisely to stay off the angry register.
## The lid only needs a VALUE STEP against the forehead to read as a separate form, and it gets that
## from its own terminator: `shade` is lifted from `_matte`'s 0.30 to 0.36 in `_build_sleepy_lids`,
## which darkens the shaded top of the dome without darkening its albedo. The lower edge needs no
## help at all — it cuts across a V 0.95 sclera. If a render ever shows it melting into the
## forehead, the sanctioned next step is `skin.darkened(0.07)` and NOT one step further.
##
## PIP'S LID GEOMETRY — five numbers, solved against the eye `_build_eye` actually makes, not
## guessed. Her eye spec is w = h = 0.0345, d = 0.020, `face_scale` 1.08, `sclera_mul` 1.40, so in
## the EYE NODE's local frame (local -Z is the head's outward normal, +Y is up):
##     sclera  semi (0.05216, 0.05216, 0.02400) at z -0.01100, front face z -0.03500
##     pupil   semi (0.03726, 0.03726, 0.02000) at z -0.03160, front face z -0.05160
##   the VISIBLE eye is the sclera: 104.3 mm tall on a 616 mm head.
##
## AN OPAQUE CONVEX SOLID STOPS OCCLUDING AT ITS OWN SILHOUETTE RIM, where its surface has only
## reached its CENTRE depth. So a lid works only if its centre is already in front of the eye at the
## height you want its edge — which is why LID_SEMI.z is 0.0330 rather than a thin plate laid on the
## eye. Solved for the actual crossover of lid-surface against pupil-surface (and, out past the
## pupil, against sclera-surface), column by column across the eye, the visible lid edge lands at:
##     x -0.045 -> y +0.0072   (43.1 % of the eye covered)  INNER corner on the model's +x eye
##     x -0.015 -> y +0.0116   (38.9 %)
##     x  0.000 -> y +0.0120   (38.5 %)
##     x +0.015 -> y +0.0104   (40.0 %)
##     x +0.030 -> y +0.0066   (43.7 %)
##     x +0.045 -> y +0.0030   (47.1 %)                     OUTER corner on the model's +x eye
## i.e. 38-47 %, centred on the 35-45 % the brief asks for and only running past it in the last
## 3 mm of the outer corner, where it is the roll doing its job — see LID_ROLL_DEG. LID_SEMI.x
## 0.0660 overhangs the 0.05216 sclera by 14 mm so no white can peek round the sides, and the back
## pole lands at z +0.0100, well inside the head, so the lid grows out of the brow rather than
## floating in front of it.
##
## WHY IT IS WIDE AND SHALLOW (132 x 76 mm) AND NOT THE 124 x 96 THE FIRST BUILD USED. This was
## settled by rendering all three, not by argument. At 96 mm tall the lid's own silhouette stayed in
## front of the forehead all the way up to y +0.0928 — 40 mm ABOVE the top of the eyeball — and what
## it rendered as was two pale domes perched over the eyes: bulging brow-balls, or a pair of little
## hats, not skin. The eyeball itself only stands 8 mm proud of the shell at its top, so a form that
## is going to read as a LID has to vanish into the forehead at about the height the eye does.
## A 60 mm version (top at y +0.0588) fixed the dome but overshot: the lid's upper surface went
## nearly horizontal and read as a flat awning with a hard lit edge. 76 mm tops out at y +0.0708 —
## 19 mm above the eyeball — and is the one that reads as a heavy fold with a lid crease above it.
## The trade behind all three: a lid whose pole sits high above the crossing meets the eye at a
## steep angle and gives a crisp lid line, so every millimetre flatter softens that line.
const LID_POS := Vector3(0.0, 0.0330, -0.0230)
const LID_SEMI := Vector3(0.0660, 0.0380, 0.0330)
## SLEEPY AND ANGRY ARE ONE ROTATION APART AND THIS IS IT. An angry lid slants DOWN toward the NOSE;
## a sleepy one sits flat or drops very slightly toward the OUTSIDE. `_orient_on_head` ends in
## `Basis.looking_at(outward, Vector3.UP)`, and this file already records at `_cut_almond_eyes` that
## for BOTH eyes that basis's local +X points toward the MODEL's own +X — so "outboard" is
## `signf(_eyes[i].position.x)`, not "left eye / right eye". Reasoning from left-and-right here
## produces one correct eye and one wrong one, which renders as a wink. A negative roll about +Z
## drops local +X, so `LID_ROLL_DEG * signf(position.x)` drops the OUTER end on both sides.
## Measured differential across the eye at -4 deg on the wide lid: the outer corner's edge sits
## 4.2 mm LOWER than the inner corner's, so the lid line runs level across the inside of the eye and
## falls away only outboard. That stays deliberately modest — the brief's own words are "flat or
## slants VERY SLIGHTLY down toward the outside" — and this file's history is two separate scowls
## shipped by overdoing exactly this axis (Pop's almond point built at the inner corner, and his
## rake at 20 deg before it had to come back to 12).
const LID_ROLL_DEG := -4.0
## WHERE THE LID GOES WHEN SHE OPENS HER EYES — up and BACK, into the head, not merely up.
## At rest the lid's front pole is at z -0.0560 and stands well clear of the face. Retracted, its
## centre goes to eye-local (0, +0.0590, +0.0350) and, sampled over the whole dome against the real
## head superellipsoid, its closest approach to the shell is still 4.9 mm BEHIND it — so the entire
## fold is inside the forehead and nothing at all is drawn over the expression. In the render:
## `--state=happy` shows the full arcs and `--state=surprised` the full balls, with no lid anywhere.
## Retracting up-only, or back by less, leaves a skin-coloured bump on her brow in every happy frame.
const LID_RETRACT := Vector3(0.0, 0.0260, 0.0580)
## POP'S APRON INVERTS THE PAIR'S: tan body with a darker tan edging, against Pip's cream body
## with a dusty-rose trim.
## Same shop uniform, opposite way round. The practical reason is that his apron is CUT SHORT to
## clear the plastron, and a small bright-cream panel low on a wide body rendered as underwear —
## the tan reads as cloth at that size where the cream did not. His trim then has to go DARKER than
## the apron rather than lighter: a cream waistband, hem and bow on a small tan panel put three
## bright bars round his hips and the eye went straight to them instead of to the belly plate.
const POP_APRON := Color("#d4b87e")
const POP_TRIM := Color("#a8905e")  ## a DARKER tan, so trim reads as edging and not as bright bands
const POP_BLADE := Color("#6f8f92")  ## teal-slate paddles  S 0.24 V 0.57 — nothing else wears this
const POP_PLATE := Color("#7e968b")  ## belly plate  S 0.16 V 0.59 against a V 0.79 body
const POP_PLATE_RIM := Color("#56675f")
## POP'S HORNS ARE COOL BONE, AND THAT IS A RULING RATHER THAN A PREFERENCE. Fifty lines up, this
## file states that Pip is the WARM half of the pair and Pop the COOL half and that the two "must
## never converge". Two 400 mm warm-ivory horns are the largest single block of colour he owns after
## his own body, and warm bone would drag him straight across that line. So the bone is greened off:
##   #b7bca9  S 0.10 V 0.74   pale bone with a green cast   — the shaft bands
##   #818873  S 0.15 V 0.53   the keratin ring              — the alternating bands
## Both inside the R2.6 gate (S <= 0.46, V <= 0.85), and at S 0.10-0.15 they are by a wide margin
## the most DESATURATED thing on him, which is what bone should be against a S 0.45 body and what
## keeps them readable as a silhouette against the night sky. The 0.74/0.53 VALUE step is what makes
## the banding read as rings rather than as noise; two colours across four bands puts the dark one
## on the tip, so each horn ends in a dark point — the same read Mayor Orbit's brass tips use.
const POP_HORN := Color("#b7bca9")
const POP_HORN_BAND := Color("#818873")

## PIP'S SKIN — `sd_foliage`, and the choice of FUNCTION is the point, not the settings.
## The ruling is that `sd_skin` may appear on at most TWO characters at genuinely opposite settings
## (Zorp spot-dominant, Grig edge-dominant), because five characters sharing one surface function is
## half of why the species read as one creature in five colours. sd_foliage is a two-octave
## tuft-plus-clump fbm whose normal term puffs OUTWARD along the clump, so on a body it reads as
## soft down rather than as cells — which is the close-range companion to the fur geometry below.
## Kind 5 is already wired and no character uses it.
## `surface_scale` 2.6, not the 0.9 the plan asked for: sd_foliage's clump octave runs at
## 7 * scale cycles/m, so scale 0.9 puts 160 mm blotches on a 616 mm head and it rendered as
## vertical smears — mould, not down. At 2.6 the clump is 60 mm and the tuft octave 13 mm, which is
## a fine even nap that survives to conversation range and disappears cleanly at gameplay range.
const PIP_SURF_HEAD := {"surface": "foliage", "surface_scale": 2.6, "surface_strength": 0.42,
	"surface_near": 8.0, "surface_far": 22.0}
## Finer and much weaker on the limbs, for the same reason the old skin preset was: an arm is a
## small, strongly curved capsule, and a pattern tuned for a 616 mm head renders as cauliflower on
## a 90 mm limb.
const PIP_SURF_LIMB := {"surface": "foliage", "surface_scale": 3.6, "surface_strength": 0.34,
	"surface_near": 6.0, "surface_far": 18.0}

## POP'S SKIN — NONE. Deliberately, and it is the single cheapest thing in this pass.
## He is the one character in the cast with no surface pattern at all, which is what makes everyone
## else's pattern read as a CHOICE rather than as the default the engine happens to apply. It is
## also the user's own "some should have smooth skin" and it buys R2.6 headroom (turning sd_skin on
## measured +0.099 saturation mean in OPEN_ISSUES 35). An empty dict is not a stylistic shrug here;
## do not "improve" it by adding a faint grain, because then nobody in the cast is smooth.
const POP_SURF := {}

## WHICH TWIN THIS IS: "pip" or "pop". Everything structural — body scale, torso proportions, head
## shape, eye shape, crown, mouth, garment, surface — branches on this ONE value.
##
## An empty string RESOLVES from `antenna_count`, which `NpcModels.make()` already sets to 1 for Pip
## and 2 for Pop. That is deliberate: it makes this file correct on its own, today, with no edit to
## a file this pass does not own, and an explicit `variant` still wins when one is set.
@export var variant: String = ""
## Body colour (Pip: leaf green, Pop: yellow-green). Set by `NpcModels.make()`.
@export var skin: Color = Color("#93c169")
## 1 for Pip, 2 for Pop. DIALOGUE-LOCKED — see the class docstring.
##
## THE GEOMETRY NO LONGER READS THIS AS A COUNT. Pip's build makes exactly one antenna and Pop's
## exactly two, because the count is a fact about WHICH TWIN this is, stated in six shipped lines —
## it is not a dial. Leaving it as a loop bound meant a stray `antenna_count = 3` would silently
## make a line of dialogue false. It survives as the `variant` fallback and as documentation.
@export var antenna_count: int = 1
## Idle-bounce phase offset in seconds so the twins never bob in sync.
@export var bounce_phase: float = 0.0
var _antennae: Array[Node3D] = []
## PIP'S TWO SLEEPY LIDS, in `_eyes` order, plus each one's authored resting position.
##
## THESE ARE DELIBERATELY NOT IN ANY OF THE BASE CLASS'S ARRAYS. `_apply_face` walks `_eye_ovals`,
## `_eye_happy`, `_eye_round`, `_eye_flat`, `_eye_size` and `_brows` every single frame and rewrites
## scale, visibility and position on all of them; a lid registered in any of those would be squashed
## by the blink and stretched by EYE_WIDE. Owning them here is what lets `_animate_extras` retract
## them for the expressions AFTER `_apply_face` has run — see `tick()`'s call order.
## `_lid_home` exists because the retract is an OFFSET applied every frame: reading the current
## position and adding to it would integrate the offset and launch the lid off the head in ~1 s.
var _lids: Array[Node3D] = []
var _lid_home: Array[Vector3] = []
var _is_pip := true
var _t: float = 0.0


func _init() -> void:
	super()
	# Only what cannot depend on `variant` lives here: `_init()` runs at `.new()`, BEFORE
	# `NpcModels.make()` assigns the exports. Everything species-specific is in `_resolve_variant`.
	#
	# 0.70 with inherited face metrics made the twins two ~3 px dark dots at the 6.5 m camera. Timmy
	# and Tommy are only a little shorter than Tom Nook and their faces are *not* scaled down with
	# them, so their face features are scaled UP to compensate for the body scale. Spacing stays a
	# fixed % of head width, so the AC grammar is unchanged; 1.08 is the largest face_scale that
	# keeps the resting mouth inside the mandated 16-25 % of head width.
	face_scale = 1.08


## `variant` arrives as an @export, so it is only readable AFTER `.new()` returns — which is after
## `_init()` and before `_ready()`. `rebuild()` reads `body_scale`, `head_y`, `head_semi` and
## `head_n` before it calls `_build_geometry()`, so resolving inside `_build_geometry` is already
## too late for four of the six numbers that matter. Hence both hooks:
##   * `_ready()`, because it reads `blink_hold` for the first blink interval BEFORE calling
##     `rebuild()`, and blink rate is one of this pair's differentiators;
##   * `rebuild()`, so a caller that flips `variant` and rebuilds by hand gets the new body too.
## `_resolve_variant()` is idempotent, so running it twice costs nothing.
func _ready() -> void:
	_resolve_variant()
	super()


func rebuild() -> void:
	_resolve_variant()
	super()


## THE WHOLE SKELETON SPLIT. Everything here is a proportion, not a part — this is the half of the
## difference that survives being reduced to a black cut-out at 8 m.
func _resolve_variant() -> void:
	if variant.is_empty():
		variant = "pop" if antenna_count >= 2 else "pip"
	_is_pip = variant != "pop"
	if _is_pip:
		# TALL, NARROW, HIGH-WAISTED. head_n 2.8 is the roundest head in the cast.
		#
		# HEAD SIZE IS A MEASURED CLIMBDOWN, NOT THE VALUE THE PLAN ASKED FOR. The plan specified
		# head_semi (0.2560, 0.2380, 0.2500), a 0.512 m head against the twins' shipping 0.684 — a
		# 25 % reduction — while simultaneously calling for "the largest eyes in the cast". This
		# file's own history says why that fails: "0.70 with inherited face metrics made the twins
		# two ~3 px dark dots at the 6.5 m camera", which is the whole reason `face_scale` exists.
		# 0.616 m splits the twins on head SHAPE at similar overall size instead of on size:
		# aspect 1.15 (round) against Pop's 1.75 (wide slab), which is two genuinely different
		# cached meshes without walking back toward the legibility failure.
		body_scale = 0.86
		head_semi = Vector3(0.3080, 0.2680, 0.2720)
		head_n = 2.8
		# Chin seated 10 mm INTO the torso top. Her torso is 1.10 tall, so its top is at
		# 0.40 + 0.235 * 1.10 = 0.6585; chin 0.6485 -> head_y = 0.6485 + 0.2680.
		head_y = 0.9165
		# A TRUE CIRCLE, and only 12.1 % of head width. R2.3 rejected the baby-doll register at
		# 12.3 % of head width, so "big round eyes" is bought with SHAPE (circular, in a pale
		# sclera) and not with area: 0.0345 x 0.0345 at face_scale 1.08 renders 74.5 mm across on a
		# 616 mm head = 12.1 % wide by 13.9 % of head height, inside the R2.3 band on both axes.
		# Against every other neighbour's vertical OVAL, a circle is unmistakable at gameplay range.
		eye_w = 0.0345
		eye_h = 0.0345
		eye_d = 0.020
		mouth_w = 0.047
		mouth_h = 0.042
		# 0.45: she crinkles shut better than twice as often as anyone else. This is the whole of
		# "the cheerful one" and it costs zero triangles — see `blink_hold`'s docstring for why a
		# resting-happy-arc state does NOT work (a character parked on the arcs never blinks).
		blink_hold = 0.45
		anim_time_scale = 1.08
	else:
		# WIDE, LOW, SQUARE, PLANTED. The two of them side by side is the cast's clearest
		# dimorphism, which is the entire point of a twin pair.
		body_scale = 0.76
		head_semi = Vector3(0.3560, 0.2040, 0.2900)
		head_n = 3.0
		# His torso is 0.90 tall, so its top is at 0.40 + 0.235 * 0.90 = 0.6115; chin 0.6015.
		head_y = 0.8055
		# AREA-MATCHED TO R2.3, not width-matched. A raked slit 0.0950 x 0.0734 as rendered has
		# area pi/4 * 0.0950 * 0.0734 = 0.00548 m2 against the R2.3-approved 0.075 x 0.094 eye's
		# 0.00554 — the same eye area — even though it is wider across, because it is much shorter
		# proportionally. Width alone would fail the gate; the gate is about the baby-doll read, and
		# a wide flat wedge is its opposite.
		eye_w = 0.0440
		eye_h = 0.0340
		eye_d = 0.018
		mouth_w = 0.062
		mouth_h = 0.030
		blink_hold = 1.7
		anim_time_scale = 0.92


func _build_geometry() -> void:
	_antennae.clear()
	# `rebuild()` can run more than once on a live model (a caller flipping `variant`), and the old
	# nodes are freed with the tree it replaces — so these have to be dropped here, next to
	# `_antennae`, or `_animate_extras` walks two freed lids on the first tick after a rebuild.
	_lids.clear()
	_lid_home.clear()
	if _is_pip:
		_build_pip()
	else:
		_build_pop()
	# deterministic (not random) idle phase so the pair bounces visibly out of sync
	_time = bounce_phase


# ================================================================================== PIP
func _build_pip() -> void:
	var dark := skin.darkened(0.18)
	# TORSO: narrow and tall, and the waist chamfer is OFF. The chamfer is a hard horizontal edge
	# ringing the bean; keeping it on Pop and dropping it here is a free "soft against hard" cue on
	# the largest single surface either character has.
	_add_torso_bean(skin, {"size_mul": Vector3(0.94, 1.10, 0.94), "waist_chamfer": false}
		.merged(PIP_SURF_HEAD))
	# Shoulders follow the torso in BOTH axes. `_arm_l`/`_arm_r` are seated by `rebuild()` at the
	# shared SHOULDER const; only their ROTATION is written per frame, so moving them here is safe.
	# Left where they were, a 0.94-wide torso would wear its arms 6 % outboard of its own shell.
	_seat_shoulders(0.94, 1.10)
	_add_arms(skin, skin, 0, PIP_SURF_LIMB, PIP_SURF_LIMB)
	_add_legs(dark, skin.darkened(0.34), PIP_SURF_LIMB)
	# NO CROWN SEAM. The seam is a chamfer band that makes the top of the head read as a PLANE —
	# exactly right for Pop's slab and exactly wrong for the roundest head in the cast.
	var head_opts := PIP_SURF_HEAD.duplicate()
	head_opts["crown_seam"] = false
	_add_head_shell(skin, head_opts)

	# TWO BIG ROUND EYES ON THE HEAD, low and wide — the eyestalks are gone (-412 tris). yaw 19 /
	# pitch -5 puts the centres 185 mm apart on a 616 mm head = 30.0 % geometric, inside the
	# mandated 28-35 % band. The pale sclera is a SIBLING of the dark pupil, not a parent (see
	# `_build_eye`); at sclera_mul 1.40 the visible eye is 104 mm = 16.9 % of head width, close to
	# what the twins already showed before this pass — their eyestalks carried 96 mm sclera balls
	# on a 684 mm head, 14.0 %. "Big round eyes" is therefore bought almost entirely with SHAPE: a
	# true circle where the whole cast wears vertical ovals, on the roundest head in the cast.
	#
	# NO BROWS AND NO LASHES. Brows are the hard vocabulary and lashes are the single most
	# stereotyped cue available; both twins are children and get neither.
	#
	# NO GLINT EITHER, and that is a consequence of the lid rather than a taste call. `_add_glint`
	# hangs a proud lens dot at oval-local (0.36, 0.40, -0.52) scaled (0.19, 0.15, 0.72), which in
	# host space puts its FRONT face at z -0.0564 — 4.4 mm in front of the lid surface at that
	# (x, y). Left on, it would render as a bone-white speck sitting ON her closed eyelid. It is
	# dead geometry in the other two states as well: `happy` and `surprised` hide the oval the glint
	# is parented to. Dropping it also happens to be right: a sleepy eye has no catchlight.
	var eyes: Array = []
	for sx: float in [-1.0, 1.0]:
		eyes.append({"yaw": 19.0 * sx, "pitch": -5.0, "brow": false, "fit_expr": true,
			"glint": false, "sclera": SCLERA, "sclera_mul": 1.40})
	_add_face(EYE, MOUTH, PIP_TRIM, {"eyes": eyes, "nose": false, "blush": false, "brows": false,
		"mouth_inner": Color("#7a3941")})
	_build_round_slot_mouth()
	_build_sleepy_lids()

	_build_fur()
	_build_pip_apron()

	# EXACTLY ONE ANTENNA, dialogue-locked. Its FORM changes, never its count: a curved matte stem
	# with a knob cap, in warm coral, instead of the straight capsule and always-emissive ball that
	# Zorp, Pip, Pop and Bolt all wore. `glow: false` is the load-bearing half — an antenna that
	# glows is Bolt's organ and Zorp's organ, and three of them is the repetition being fixed.
	# `curve` bends the stem toward +Z, so the feeler arcs backward over the crown rather than
	# standing up as another straight spike.
	_antennae.append(_add_antenna(_head, Vector3(0.0, head_semi.y - 0.012, -0.030), 0.0,
		skin.darkened(0.28), PIP_KNOB, 0.165, 0.030,
		{"tip": "knob", "glow": false, "stalk_r": 0.010, "curve": 0.42}))


## HER MOUTH: a small ROUND TOOTHLESS SLOT with a tongue. Not a grin, and not a closed arc.
##
## The wide toothy grin exists (see `_add_wide_grin`'s own docstring) only to stop a blank
## STALK-EYED dome reading as an eyeless monster. Her eyes are back on her face, so the exemption
## no longer applies to her and the grin goes (-252 tris).
##
## It is not a `_smile_arc` either. At 8 m a closed arc is ONE DARK LINE, so a cast where six
## neighbours all wear one is separated only by mouth WIDTH — the weakest possible differentiator on
## a face you see for two seconds. Closed mouths must differ in KIND: this is a round hole, Pop's is
## a straight bar with zero curvature, and at most one closed arc survives anywhere in the cast.
##
## The slot is assigned to `_mouth_smile` so `_apply_face`'s SMILE_HIDE_AT crossfade still runs: the
## resting slot fades out as `_mouth_open` widens, instead of a thin line being drawn across a
## talking mouth (the "two mouths" bug the crossfade exists to prevent).
func _build_round_slot_mouth() -> void:
	var fs := face_scale
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, -22.0, 0.004)
	_free_default_smile()
	# 0.047 half-width at face_scale 1.08 renders 101.5 mm on a 616 mm head = 16.5 %, just inside
	# the mandated 16-25 % resting-mouth band.
	var slot := _node("Slot", mouth_node, Vector3(0.0, 0.0, -0.004))
	var m_slot := _toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06})
	_mi(superellipsoid(Vector3(0.047 * fs, 0.031 * fs, 0.013), 2.2, 14, 8), m_slot, slot,
		Vector3.ZERO, "Cavity")
	# The tongue sits PROUD of the cavity, not inside it: nested, it pokes through the low-poly
	# cavity's facets as stray specks (the same failure `_add_mouth` documents for its interior).
	_mi(sphere(1.0, 10, 5), _toon(PIP_TONGUE, {"spec": 0.0, "rim": 0.0, "shade": 0.12}), slot,
		Vector3(0.0, -0.012 * fs, -0.010), "Tongue").scale = \
		Vector3(0.026 * fs, 0.013 * fs, 0.011)
	# `_apply_face` overwrites this node's SCALE every frame, so nothing here may carry one.
	_mouth_smile = slot


## HER SLEEPY HALF-LIDS — the user asked for "eyes half lidded like it's sleepy", and the whole of
## the difficulty is that the same part, one degree of rotation away, is a scowl.
##
## A POST-PASS OVER `_add_face`'S WORK, NOT AN EYE SPEC KEY. `_build_eye` has no lid concept and
## chibi_model.gd is off limits this pass, so this walks `_eyes` afterwards the way
## `_cut_almond_eyes` walks `_eye_ovals`. All of the solved numbers live on LID_POS / LID_SEMI /
## LID_ROLL_DEG next to the palette block; read those before touching anything here.
##
## IT IS A DOME, NOT A PLATE, and it is parented to the EYE, not to the oval. Both matter:
##   * A flat plate laid over a bulging eye can only occlude where it is physically in front, and
##     the pupil already stands 47.6 mm proud of the eye node — a plate thin enough to look like
##     skin would be behind the pupil across the middle of the eye and the "lid" would render as
##     two crescents at the corners. A squashed ellipsoid whose CENTRE sits at z -0.0280 is in
##     front of the pupil everywhere above its own silhouette rim, which is what draws one clean
##     edge across the eye.
##   * `_apply_face` rewrites `oval.scale` every frame from `_eye_size`. Anything parented under the
##     oval is squashed by the blink and stretched by EYE_WIDE — the lid would pump like a bellows.
##     Under `_eyes[i]` nothing in the base class touches it, which is the point: it is ours to
##     animate, and `_animate_extras` does exactly that.
##
## SURVIVING THE BLINK NEEDS NO CODE, and here is why rather than an assertion that it does.
## `_update_blink` drives `_eye_open` into `oval.scale.y` and nothing else — the sclera and the lid
## are both untouched. As the pupil squashes, its front surface at any given height RECEDES, so the
## lid/pupil crossover slides smoothly down from y +0.0110 to about y +0.0020 (48 % of the eye) at
## full blink and back up again. No discontinuity, nothing to pop, and the visible result is her lid
## sinking as she blinks. Free acting.
func _build_sleepy_lids() -> void:
	# `.merged()` does not overwrite existing keys — the same idiom `_build_pip`'s torso call uses —
	# so spec / rim / shade below win and the four `surface*` keys come from PIP_SURF_HEAD. That
	# puts the SAME sd_foliage nap on the lid as on the head, which is most of what sells it as her
	# own skin folding over rather than as a separate object stuck on the eye.
	var m_lid := _toon(skin, _matte({"spec": 0.02, "rim": 0.03, "shade": 0.36}
		.merged(PIP_SURF_HEAD)))
	for i in _eyes.size():
		# Pip's eyes carry no `slant_deg`, so today `_eyes[i]` IS `_build_eye`'s host and this
		# lookup finds nothing. It is here because the day someone gives her a slant, `_build_eye`
		# moves the oval, both expression meshes and the brow onto a `Slant` child and rolls THAT —
		# and a lid left behind on the eye node would be the single part of the eye that does not
		# follow the roll, which reads as the lid sliding off her face.
		var host: Node3D = _eyes[i]
		var slant := host.get_node_or_null("Slant") as Node3D
		if slant != null:
			host = slant
		var lid := _node("Lid", host, LID_POS)
		# The roll is about the lid's OWN centre (the node origin and the dome centre coincide), so
		# this tips the lid line without walking the dome sideways off the sclera.
		lid.rotation.z = deg_to_rad(LID_ROLL_DEG * signf(_eyes[i].position.x))
		# The node SCALE is what makes this an ellipsoid — the same trick `_build_eye` uses for the
		# sclera, and the reason there is no bespoke mesh here to blow the shared cache on.
		# Measured with `--stats`: the two lids MINUS the two glints dropped above is a net +188,
		# taking Pip from 4940 to 5128 of the 6000 budget.
		_mi(sphere(1.0, 18, 10), m_lid, lid, Vector3.ZERO, "Cap").scale = LID_SEMI
		_lids.append(lid)
		_lid_home.append(lid.position)


## FUR, AS SILHOUETTE — the user asked for it by name and a shader cannot answer it. She is the only
## broken outline in the cast: every other neighbour, ours and the robots', is a closed smooth
## curve, so a ragged edge is the strongest single 8 m read available and nobody else can take it.
##
## `fur_ring` fins are three-sided PYRAMIDS at 4 triangles each, never double-sided quads —
## `toon_soft` is `render_mode cull_back` and MaterialLib has no cull_disabled material, so a quad
## fringe simply vanishes when the camera walks round the character.
##
## THE SHOULDER RINGS ARE THE LOAD-BEARING ONES. A crown-and-jaw-only ruff was rejected: it claims
## an "inverted teardrop" silhouette while putting nothing at the shoulder, so the cut-out stays a
## plain bean with a ragged head. Widening her at the shoulders is what makes the taper real.
func _build_fur() -> void:
	var m_fur := _toon(PIP_FUR, _matte({"spec": 0.02}))
	# JAW RUFF. Seated at 62 % of the way down the head, where the shell's own half-width is
	# head_semi.x * (1 - 0.62^n)^(1/n) = 0.2763; the ring sits just inside that so the fins emerge
	# from the shell rather than floating off it. The head is 0.308 x 0.272 in plan, so the node is
	# squashed in Z to match — `fur_ring` builds a CIRCULAR ring and an unsquashed one would stand
	# 36 mm off the cheeks and bury itself in the chin.
	var ruff := _node("NeckRuff", _head, Vector3(0.0, -head_semi.y * 0.80, 0.0))
	# THE FINS HANG, THEY DO NOT STAND. `fur_ring` builds every fin rising slightly along +Y, and
	# at the jaw line that renders as a ring of upward triangles directly under the mouth — a SAW,
	# or a row of teeth, which is the opposite of soft. A half turn about X (still a rotation, so
	# the pyramids' winding is untouched) drops them into a hanging fringe instead. Seated at 80 %
	# of the way down the head rather than 62 %, so it reads as a neck ruff and not as a beard.
	ruff.rotation.x = PI
	ruff.scale = Vector3(1.0, 1.0, head_semi.z / head_semi.x)
	_mi(fur_ring(0.222, 0.086, 0.038, 30, 0.42), m_fur, ruff, Vector3.ZERO, "Fins")
	# SHOULDER TUFTS. `arc_deg` 240 leaves the gap centred on the ring's local +Z; the yaw below
	# turns that gap INBOARD, so no fin is built inside the torso. These ride `_arm_l`/`_arm_r`,
	# whose rotation is animated and whose children therefore follow the arm for free.
	for side: Array in [[-1.0, _arm_l], [1.0, _arm_r]]:
		var tuft := _node("ShoulderTuft", side[1], Vector3(0.0, -0.004, 0.0))
		tuft.rotation.y = -PI * 0.5 * float(side[0])
		_mi(fur_ring(0.060, 0.050, 0.040, 18, 0.40, 240.0), m_fur, tuft, Vector3.ZERO, "Fins")
	# FRINGE — a short 150-degree row of fur hanging over the brow, which is also the only thing
	# either twin has where a brow would be.
	#
	# TWO EARLIER PLACEMENTS RENDERED NOTHING, and both failures are worth writing down.
	#   * A fur ring only shows if `ring_r` is close to the head's half-width AT THAT HEIGHT. The
	#     first attempt put a 74 mm ring deep inside a shell whose semi-axes there are 272-308 mm,
	#     so the fins never reached the surface at all.
	#   * A ring high on the crown DOES emerge, but its front fins point at the camera and are seen
	#     end-on: they read as a scatter of white specks on the forehead, not as hair. Fur only
	#     reads when its fins are broadside to the viewer, which means hanging DOWN across the face
	#     or standing OUT at the silhouette — the neck ruff and the shoulder tufts respectively.
	# So: seated at 36 % height, where the shell solves to 0.3016 half-width, with the fins turned
	# over to hang. `rotation.z`, NOT `rotation.x`: a half turn about Z flips Y (fins drop) while
	# leaving +Z alone, so the arc's gap stays at the BACK and the 150-degree row lands across the
	# front. Turning it about X would drop the fins and swing the gap round to the front with them,
	# which builds the fringe on the back of her head.
	var lock := _node("Fringe", _head, Vector3(0.0, head_semi.y * 0.36, 0.0))
	lock.rotation.z = PI
	lock.scale = Vector3(1.0, 1.0, head_semi.z / head_semi.x)
	_mi(fur_ring(0.290, 0.048, 0.046, 17, 0.35, 150.0), m_fur, lock, Vector3.ZERO, "Fins")


## HER APRON: cut LONG, SOFT and GATHERED, in a dusty-rose trim.
## Against Pop's stiff square waist apron this is a real garment difference rather than a recolour,
## and garment cut is one of the cues that survives the character being reduced to a cut-out.
func _build_pip_apron() -> void:
	var m_apron := _toon(APRON, _matte({"spec": 0.02}))
	var m_trim := _toon(PIP_TRIM, _matte({}))
	var k := Vector3(0.94, 1.10, 0.94)
	# Exponent 2.6, not the 3.1 of the old hard-edged bib: a soft-cornered panel hanging low, and it
	# is sized off HER torso multipliers so it cannot float off a bean it was not cut for.
	var a_semi := Vector3(TORSO_RX * k.x * 0.90, TORSO_RY * k.y * 0.86, TORSO_RZ * k.z * 0.95)
	var a_pos := Vector3(0.0, TORSO_Y - 0.062, -0.026)
	_mi(superellipsoid(a_semi, 2.6, 16, 9), m_apron, _torso, a_pos, "Apron")
	# GATHERS: four vertical ridges standing proud of the panel, so the fabric reads as folded cloth
	# rather than as one flat plate.
	#
	# A FOLD IS A NARROW COPY OF THE APRON'S OWN PROFILE, NOT A RIB LAID ON TOP OF IT. The first
	# build used a rib at a fixed z, and it shipped the exact failure `_add_plastron`'s docstring
	# records for the same mistake, inverted: the apron's front RECEDES toward its top and bottom,
	# so a fixed-z rib is buried across the middle and pokes THROUGH at both ends. Rendered, it was
	# a row of white spikes rising out of the hem — a picket fence, not a gather.
	# Same exponent and the same y and z semi-axes means the identical vertical profile, so the
	# ridge hugs the panel over its whole length; 1.02 in z is the only thing that lifts it, and
	# 0.99 in y guarantees it can never reach past the apron's own edge.
	var m_fold := _toon(APRON.darkened(0.13), _matte({"spec": 0.0}))
	var f_mesh := superellipsoid(Vector3(0.022, a_semi.y * 0.99, a_semi.z * 1.02), 2.6, 10, 7)
	for i in 4:
		_mi(f_mesh, m_fold, _torso, a_pos + Vector3(lerpf(-0.112, 0.112, float(i) / 3.0), 0.0, 0.0),
			"Fold")
	var band := _mi(torus(0.140, 0.184, 20, 6), m_trim, _torso,
		Vector3(0.0, TORSO_Y + 0.152, 0.0), "Neckband")
	band.scale = Vector3(1.0, 0.6, 1.0)
	# A soft rolled hem, not the hard chamfered plate Pop wears.
	_mi(torus(0.150, 0.196, 18, 6), m_trim, _torso, Vector3(0.0, TORSO_Y - 0.196, -0.010), "Hem") \
		.scale = Vector3(1.0, 0.45, 1.0)
	_build_badge(_torso, Vector3(0.0, TORSO_Y - 0.020, -TORSO_RZ * k.z - 0.012), APRON)
	_build_apron_bow(m_trim, TORSO_RX * k.x, TORSO_RZ * k.z, TORSO_Y - 0.055)


# ================================================================================== POP
func _build_pop() -> void:
	var dark := skin.darkened(0.18)
	# TORSO: wide, low and square, with the waist chamfer KEPT so the bean has a hard horizontal
	# edge round it. NO surface dict anywhere on him — see POP_SURF.
	_add_torso_bean(skin, {"size_mul": Vector3(1.10, 0.90, 1.08)})
	_seat_shoulders(1.10, 0.90)
	_add_arms(skin, skin, 0, POP_SURF, POP_SURF)
	_add_legs(dark, skin.darkened(0.34), POP_SURF)
	# FEET PLANTED WIDE. `_apply_pose` rewrites `_leg_l.position` and `_leg_r.position` EVERY FRAME
	# from the shared HIP_X const, so widening the stance by moving the leg pivots is silently
	# undone on the next tick. Offsetting the leg's MESH CHILDREN instead is a rigid offset inside
	# the leg's own frame, which survives the pose and still swings correctly with the walk cycle.
	for side: Array in [[-1.0, _leg_l], [1.0, _leg_r]]:
		for c: Node in (side[1] as Node3D).get_children():
			(c as Node3D).position.x += 0.017 * float(side[0])
	_add_head_shell(skin, POP_SURF)

	# TWO SLANTED ALMOND WEDGES flat on the head — the stereotypical grey-alien eye the user named
	# by description. yaw 21 / pitch 4 puts the centres 220 mm apart on a 712 mm head = 30.9 %,
	# inside the 28-35 % band; yaw 17 would have measured 24.8 % because his head is so much wider
	# than the one the band was calibrated on. Solid ink, NO sclera and NO iris, one small dull
	# glint — the hardest, flattest face in the cast against Pip's pale round one.
	#
	# NO BROWS: two dark bars over two raked almonds is a scowl, and the almond's own pointed inner
	# corner already does everything a brow would.
	var eyes: Array = []
	for sx: float in [-1.0, 1.0]:
		# 12 degrees of rake, not the 20 the first build used. RAKE DIRECTION IS FACE GRAMMAR: an
		# eye whose inner end sits LOW is the angry-brow configuration, and the grey-alien wrap
		# (inner low, sweeping up and out to the temple) is structurally that same shape. Rendered
		# at 20 degrees Pop is scowling, on a character who is a child shopkeeper and who
		# deliberately has no brows precisely to avoid that read. 12 degrees is still visibly
		# slanted — nobody else in the cast has a raked eye at all — without tipping into a glare.
		eyes.append({"yaw": 21.0 * sx, "pitch": 4.0, "brow": false, "fit_expr": true,
			"slant_deg": 12.0 * sx})
	_add_face(EYE, MOUTH, POP_TRIM, {"eyes": eyes, "nose": false, "blush": false, "brows": false,
		"mouth_inner": Color("#7a3941")})
	_cut_almond_eyes()
	_build_bar_mouth()

	# CROWN: both glowing bulb antennae replaced by TWO FLAT MATTE PADDLE BLADES in teal-slate.
	# Still exactly two — "Two antennae. Double the listening!" — and nothing else in the game wears
	# a non-glowing blade, so the count survives while the organ stops being Zorp's and Bolt's.
	#
	# THE RAKE IS ON THE SEAT, NOT ON THE ANTENNA. `_crown_row` hands back tilt CHILDREN whose
	# parents hold the placement with +Y along the head's real outward normal, so rotating them
	# cannot destroy the seating (writing rotation on an `_orient_on_head`-posed node rebuilds its
	# basis from euler and throws the placement away — a bug three files here have written by hand).
	# And `_animate_extras` writes `rotation.z` on the ANTENNA pivot every frame, so a rake written
	# there would be fighting the animation. rotation.x +0.35 on the seat's child tips the blade
	# toward +Z, which is backward: raked back, and therefore never readable as an ear.
	# The stem is 115 mm, not the 85 mm of the first build: at 85 mm the blade sat almost on the
	# crown and rendered as a teal BLOCK bolted to his head rather than as an antenna, and the rake
	# had nothing to swing on. 0.52 rad of rake reads unmistakably as "leaning back" in profile;
	# 0.35 was still close enough to vertical to read as a pair of ears, which is the one thing
	# these must never be.
	for sx: float in [-1.0, 1.0]:
		var seat: Node3D = _crown_row(1, 62.0, 62.0, 52.0 * sx)[0]
		seat.rotation.x = 0.52
		_antennae.append(_add_antenna(seat, Vector3.ZERO, 0.0, POP_BLADE.darkened(0.22),
			POP_BLADE, 0.115, 0.042, {"tip": "paddle", "glow": false, "stalk_r": 0.008}))
	_build_pop_horns()

	# PLASTRON — a contrasting belly plate with a hard rim, two scute seams and a navel. Six of the
	# eighteen reference creatures wear one and nothing in this game does: Zorp's badge and the
	# twins' star are emblems on CLOTHING, which is the opposite statement. This says "this is its
	# body, not its shirt", and it is a large flat value contrast, so it reads at gameplay distance.
	# `torso_mul` is not optional — the helper solves the torso's own superellipsoid for the plate's
	# depth, and passing the wrong bean sinks the plate inside it.
	# Broad and shallow, to match the build it is on: 0.150 half-width against his 0.244-half torso
	# is 61 % of the chest. The first build's 0.140 x 0.150 was TALLER than it was wide, which on a
	# wide low body reads as a bib rather than as a shell, and it also hung down into the apron.
	# Lifted to y 0.462 so the plate INCLUDING ITS RIM (0.327 -> 0.597) clears the waist apron
	# (0.147 -> 0.317). The rim is `size3 + rim_w`, 15 mm larger on every side, and forgetting it is
	# what left the apron's top edge crossing the plate and notching a V out of its bottom corners.
	# outright: his torso is only 0.90 tall, so there is no room for the two to be approximate.
	_add_plastron(POP_PLATE, POP_PLATE_RIM, Vector3(0.158, 0.120, 0.022), true,
		{"torso_mul": Vector3(1.10, 0.90, 1.08), "y": 0.462, "seams": 2, "spec": 0.04})
	_build_pop_apron()


## HIS EYE. `_eye_mesh("almond")` is `superellipsoid(Vector3.ONE, 1.55, ...)`, and an exponent below
## 2 does NOT draw an almond: it pulls the diagonals in while the axes stay at 1.0, which is a
## rounded OCTAHEDRON — a four-pointed diamond with points at top, bottom and both ends. It would
## read as a gemstone, not as an eye, so the shared helper is left alone for whoever wants a diamond
## and the lens is cut here in two parts:
##   * the body is a ROUNDED RECTANGLE at n 2.4 — flat top and bottom edges, soft corners, which is
##     what gives the wedge its hard graphic edge when scaled to 0.044 x 0.030;
##   * plus one CONE that carries the taper out to a point, so it is an almond and not a lozenge.
## Both live in the oval's own UNIT space, so `_apply_face`'s per-frame `oval.scale` — including the
## blink squash and the EYE_WIDE term — carries them correctly with no extra bookkeeping.
##
## THE POINT IS ON THE OUTER CORNER, WHICH IS NOT WHAT THE PLAN SAID, AND THE REASON IS IN A RENDER.
## The plan specified the point at the INNER corner, reasoning from human eye anatomy (the inner
## canthus). Built that way and rendered, it is a SCOWL: the eye's top edge slopes down toward the
## midline and terminates in a sharp downward hook right beside the nose, which is the exact shape
## of an angry eyebrow — and this character deliberately has no brows precisely because "two dark
## bars over two raked almonds is a scowl". Putting the point outboard instead gives the canonical
## grey: a fat rounded lobe low and near the nose, tapering up and back to a point at the temple.
## Same two primitives, same rake, and it reads curious rather than hostile.
##
## WHICH WAY IS OUTBOARD: `_orient_on_head` ends in `Basis.looking_at(outward, Vector3.UP)`, and for
## BOTH eyes that basis's local +X comes out pointing toward the model's own +X. So outboard is
## local +X for the eye on the model's right and local -X for the one on its left — sign(yaw). The
## rake is the same sign: `slant_deg` +20 on the right eye rotates local +X up, lifting the pointed
## outer end and dropping the round inner one.
func _cut_almond_eyes() -> void:
	var m_eye := _toon(EYE, {"spec": 0.0, "rim": 0.0, "shade": 0.08})
	for i in _eye_ovals.size():
		var oval := _eye_ovals[i]
		oval.mesh = superellipsoid(Vector3.ONE, 2.4, 16, 9)
		var outer := 1.0 if _eyes[i].position.x > 0.0 else -1.0
		# taper_tube grows along +Y, so the cone is turned to lie along the eye's long axis. Its
		# base is buried well inside the lens (x 0.30) and it runs out to x 1.52, so the two shapes
		# read as one continuous taper instead of a spike stuck on a blob; the base radius is 0.86
		# of the lens half-height for the same reason. Total span 2.52 units = 120 mm as rendered,
		# 16.8 % of a 712 mm head.
		var tip := _node("Canthus", oval, Vector3(0.30 * outer, 0.0, 0.0))
		tip.rotation.z = -PI * 0.5 * outer
		_mi(taper_tube(1.22, 0.86, 0.04, 0.0, 3, 5), m_eye, tip, Vector3.ZERO, "Point")


## HIS HORNS — asked for by name: "Pop can get giant horns on each side of its head".
##
## WHERE THE SPACE IS, AND WHY THE PADDLES SURVIVE. His shipped `_crown_row(1, 62, 62, 52 * sx)`
## seats each paddle at head-local (+/-0.0845, 0.1963, -0.0660) — only 24 % of the way out to his own
## half-width of 0.356. Everything from x +/-0.09 to x +/-0.36 is empty crown on both sides, which is
## why the study of the shipped render called the temples "an enormous amount of unused silhouette".
## The horns go THERE and sweep OUT; the paddles keep the vertical. That division of labour is the
## whole reason both can exist: the horns own the width, the antennae own the height. Nothing about
## the paddle loop above changes by a single character, because the user asked to ADD horns and six
## shipped dialogue lines depend on there being exactly two antennae to look at.
##
## MEASURED AGAINST HIS REAL HEAD, solved on the actual superellipsoid (semi 0.3560, 0.2040, 0.2900,
## n 3.0) rather than eyeballed, and quoted in HEAD-LOCAL metres unless it says "rendered" (his
## `body_scale` is 0.76, so rendered = head-local x 0.76):
##   seat point   (+/-0.2858, 0.1600, -0.0143), outward normal (+/-0.5145, 0.8575, -0.0024)
##   pivot        (+/-0.2652, 0.1257, -0.0142) after the 0.040 inset
##   aim          (+/-0.7648, 0.6269, 0.1485) — out, up and slightly back; 38.8 deg above horizontal
##   tip          (+/-0.5436, 0.3461, 0.1567)
##   SPAN         0.826 m rendered, tip to tip, against a head 0.541 m wide and a body 1.064 m tall.
##                The horns make him 53 % wider than his own head and 78 % as wide as he is tall,
##                which is what "dominant in the silhouette" has to mean to survive the 6.5 m camera.
##   tip height   0.875 m rendered, BELOW the paddle blades' 0.898 m — so the antennae still crown
##                him and are not swallowed by the thing that was added next to them.
##   clearance    the closest the horn surface ever comes to the paddle stem or blade is 0.074 m
##                rendered (sampled surface-to-surface along the whole horn). They cannot clip.
##   base seating the base cap is a flat disc perpendicular to the aim, which the tilt has swung
##                about 23 deg off the surface tangent, so its high side lifts ~27 mm off the shell.
##                At `_add_horn`'s default 0.012 inset that is a visible floating gap; at 0.040 the
##                whole 78 mm rim solves to at least 0.6 mm INSIDE the shell all the way round,
##                and there is still ~0.36 m of horn outside the head.
##
## THE SIGN CONVENTION, WHICH IS THE NUMBER ONE WAY THIS GETS BUILT BACKWARDS.
## `_add_horn` sets `pivot.basis = _basis_from_up(outward)`, and `_basis_from_up` branches on
## `absf(up.x) < 0.9`. Here |n.x| = 0.5145, so BOTH horns take the `Vector3.RIGHT` branch — no flip,
## no special case. That yields z axes of (0, 0.0028, 1.0) on BOTH sides, i.e. world +Z, which is
## BACKWARD (the model faces -Z). So `curl` sweeps both horns back symmetrically for free, and
## `tilt.x` needs no sign either — it maps +Y toward that shared +Z and tips both back equally.
## `tilt.z` is the one that DOES need the sign: the two pivot bases are mirror images in their X
## axes ((0.857, -0.514, 0) on the +x side, (0.857, +0.514, 0) on the -x side), so a negative
## `rot_z` on the +x side rakes that horn OUTWARD and the mirrored value does the same on the left.
## Positive would stand them both up instead.
##
## THE HORNS ARE FOUR-SIDED AND THAT IS DELIBERATE. `_add_horn` builds each band as
## `taper_tube(..., 4, 6)`, and DETAIL 0.60 resolves that to 3 segments and FOUR sides; `taper_tube`
## puts its cross-section corners on the aim frame's +/-X and +/-Z, so each horn carries a hard keel
## along its top and bottom edge and flat facets on the diagonals. On Pop specifically that is right
## rather than a defect to be smoothed away: he is the slab head, the flat paddle, the straight bar
## mouth, the hard almond, the one character in the cast with no surface pattern at all — his own
## docstring calls him "the hardest edge in the cast". A faceted, keeled horn is on-brand for him
## and would be wrong on anybody else. It is also not fixable from here in any case: `sides` is
## hardcoded to 6 inside `_add_horn` and chibi_model.gd is off limits this pass.
##
## THEY DO NOT ANIMATE, so the pivots are discarded rather than appended to `_antennae`. That array
## is swayed every frame by `_animate_extras`; horn is bone and bone does not wobble.
##
## COST: 4 bands x 2 horns, each band 3 segs x 4 sides x 2 + two 4-triangle caps = 32 tris, so +256
## measured, taking Pop from 5450 to 5706 of the 6000 budget. That leaves him 294 spare — the
## tightest character in the cast after this change. A fifth band would be another 64 and is still
## legal at 5770; there is no room for a sixth, and reaching for more SIDES to smooth the facets is
## not an option anyway (see the paragraph above).
func _build_pop_horns() -> void:
	for sx: float in [-1.0, 1.0]:
		_add_horn(_head, Vector3(sx, 0.56, -0.05), Vector3(0.16, 0.0, -0.34 * sx),
			4, 0.40, 0.078, [POP_HORN, POP_HORN_BAND],
			# NOTE THE TRAP: `_add_horn`'s `opts.surface` is the `_matte` OPTIONS dict, not the R2.9
			# surface-detail string. `{"surface": "foliage"}` here would be a type error waiting to
			# happen. And there is deliberately no surface pattern in it: Pop is the cast's one
			# unpatterned character (CAST_VARIETY ruling 5, "exactly 1") and 0.8 m of horn is far
			# too much of him to break that on.
			{"curl": 0.60, "inset": 0.040, "tip_r": 0.011,
			"surface": {"spec": 0.06, "rim": 0.04, "shade": 0.34}})


## HIS MOUTH: a straight LIPLESS BAR. Zero curvature is unmistakable against Pip's round hole at any
## distance, which is the point — closed mouths in this cast differ in KIND, never in width. It is
## also the deadpan register his ten shipped lines were written in.
##
## The tongue is not lost: `_add_mouth` already built Lip / Inner / Tongue underneath as
## `_mouth_open`, so talking still opens a real mouth with a tongue in it. There are no teeth
## anywhere on him.
func _build_bar_mouth() -> void:
	var fs := face_scale
	var mouth_node := _face.get_node_or_null("Mouth") as Node3D
	if mouth_node == null:
		return
	_orient_on_head(mouth_node, 0.0, -19.0, 0.004)
	_free_default_smile()
	# 0.130 is a FULL width (rounded_box takes full extents) -> 140 mm rendered on a 712 mm head =
	# 19.7 %, inside the mandated 16-25 % band.
	var bar := _node("Bar", mouth_node, Vector3(0.0, 0.0, -0.004))
	_mi(rounded_box(Vector3(0.130 * fs, 0.011 * fs, 0.014), 0.0045, 10),
		_toon(MOUTH, {"spec": 0.0, "rim": 0.0, "shade": 0.06}), bar, Vector3.ZERO, "Slot")
	_mouth_smile = bar


## HIS APRON: SHORT and SQUARE, cut back to a waist apron so the plastron is not hidden behind it.
## No neckband — a waist apron has no bib to hang from, and dropping it recovers the strap that
## would otherwise cross the belly plate.
func _build_pop_apron() -> void:
	var m_apron := _toon(POP_APRON, _matte({"spec": 0.02}))
	var m_trim := _toon(POP_TRIM, _matte({}))
	var k := Vector3(1.10, 0.90, 1.08)
	# Exponent 3.6 for hard square corners, with the segment count raised to match: a high
	# superellipsoid exponent packs all the curvature into a narrow chamfer band, so it needs MORE
	# segments, not fewer, or the panel ships faceted (the mistake `head_n`'s docstring records).
	#
	# IT IS A FRONT PANEL, NOT A WRAP. The first build gave it 96 % of the torso's own half-depth
	# and sat it on the centre line, so it wrapped the whole lower body and rendered as a big bright
	# cream mass round his hips — a nappy. Pulling the centre forward with a smaller half-depth puts
	# its back face INSIDE the bean and its front 18 mm proud of the torso surface at that height
	# (the torso's own front solves to z -0.1522 at y 0.240), so all that is visible is a square
	# panel hanging off the front of the waist. That is also what keeps the plastron visible, which
	# is the whole reason his apron was cut down in the first place.
	_mi(superellipsoid(Vector3(TORSO_RX * k.x * 0.82, TORSO_RY * k.y * 0.40, 0.125),
		3.6, 24, 12), m_apron, _torso, Vector3(0.0, TORSO_Y - 0.168, -0.045), "Apron")
	_mi(rounded_box(Vector3(0.330, 0.040, 0.330), 0.012, 12), m_trim, _torso,
		Vector3(0.0, TORSO_Y - 0.084, 0.0), "Waistband")
	# A slim trim ON THE APRON FRONT, not a bar across the whole body. The full-width version
	# framed the cream panel top and bottom and the result read as a nappy.
	_mi(rounded_box(Vector3(0.240, 0.024, 0.080), 0.008, 12), m_trim, _torso,
		Vector3(0.0, TORSO_Y - 0.232, -0.150), "Hem")
	_build_badge(_torso, Vector3(0.0, TORSO_Y - 0.156, -0.178), POP_APRON)
	_build_apron_bow(m_trim, TORSO_RX * k.x, TORSO_RZ * k.z, TORSO_Y - 0.084)


# ================================================================================== shared parts
## Moves the arm roots to follow this twin's torso multipliers. The shared SHOULDER const is sized
## for an unscaled bean, so a 1.10-wide torso wears its arms inside its own shell and a 0.94-wide
## one wears them floating outboard. `rebuild()` seats these nodes and `_apply_pose` only ever
## writes their ROTATION, so a position written here survives every frame.
func _seat_shoulders(kx: float, ky: float) -> void:
	# SHOULDER.y is 44.7 % of the way up the default bean's half-height; hold that FRACTION so the
	# arms sit at the same place on the body rather than at the same absolute height.
	var y := TORSO_Y + TORSO_RY * ky * ((SHOULDER.y - TORSO_Y) / TORSO_RY)
	_arm_l.position = Vector3(-SHOULDER.x * kx, y, SHOULDER.z)
	_arm_r.position = Vector3(SHOULDER.x * kx, y, SHOULDER.z)


## Drops `_add_mouth`'s default smile ARC and clears the reference before it dies. Order matters:
## `_apply_face` walks `_mouth_smile` every frame, and `queue_free` does not take effect until the
## end of the frame, so the node is hidden first and the field nulled BEFORE the free is queued —
## otherwise `rebuild()`'s own closing `_apply_pose` call touches a node already scheduled to die.
func _free_default_smile() -> void:
	if _mouth_smile != null and is_instance_valid(_mouth_smile):
		var dead := _mouth_smile
		_mouth_smile = null
		dead.visible = false
		dead.queue_free()


## The Cosmo Depot badge: a chamfered plate with an inlay, turned 45 degrees. Both twins wear it —
## it is the shop's mark, not a personal one, and it is the one thing about the uniform that SHOULD
## be identical on the pair.
func _build_badge(parent: Node3D, pos: Vector3, base: Color) -> void:
	var logo := _node("Logo", parent, pos)
	_mi(rounded_box(Vector3(0.086, 0.086, 0.016), 0.024, 12), _toon(STAR, _matte({"spec": 0.05})),
		logo, Vector3.ZERO, "Badge").rotation.z = PI * 0.25
	_mi(rounded_box(Vector3(0.046, 0.046, 0.018), 0.012, 10), _toon(base.darkened(0.24), _matte({})),
		logo, Vector3(0.0, 0.0, -0.004), "Inlay").rotation.z = PI * 0.25


## Rear detail: the apron's waist strings tied in a bow, so the back view is not a blank green bean.
## `rx` / `rz` are this twin's own torso half-extents, so the tie sits on the bean each of them
## actually has.
##
## THE TIE MUST BE SIZED FROM THE TORSO, NOT HARDCODED. The shipped 0.300 width was cut for an
## unscaled bean; on a re-proportioned one it reaches past the torso's own silhouette AT THE DEPTH
## IT SITS AT and its two ends poke out through the FRONT, where they render as a pair of pale dots
## either side of the belly. They were visible on both twins and looked like buttons. The torso is a
## superellipsoid, so its half-width at z = 0.86 * rz is rx * (1 - 0.86^n)^(1/n) = 0.6125 * rx;
## sizing the tie to 92 % of that keeps it hidden behind the body at any set of multipliers.
func _build_apron_bow(m_trim: Material, rx: float, rz: float, y: float) -> void:
	var bow := _node("ApronBow", _torso, Vector3(0.0, y, rz + 0.010))
	var tie_w := 2.0 * rx * pow(1.0 - pow(0.86, TORSO_N), 1.0 / TORSO_N) * 0.92
	_mi(rounded_box(Vector3(tie_w, 0.048, 0.030), 0.012, 12), m_trim, _torso,
		Vector3(0.0, y, rz * 0.86), "WaistTie")
	for sx: float in [-1.0, 1.0]:
		var loop := _mi(superellipsoid(Vector3(0.050, 0.036, 0.024), 2.8, 8, 5), m_trim, bow,
			Vector3(0.052 * sx, 0.010, 0.0), "Loop")
		loop.rotation.z = 0.42 * sx
		var tail := _mi(rounded_box(Vector3(0.036, 0.090, 0.024), 0.010, 10), m_trim, bow,
			Vector3(0.038 * sx, -0.062, 0.0), "Tail")
		tail.rotation.z = 0.26 * sx
	_mi(rounded_box(Vector3(0.046, 0.040, 0.028), 0.012, 10), _toon(STAR, _matte({"rim": 0.02})),
		bow, Vector3.ZERO, "Knot")


# ================================================================================== animation
## NEITHER TWIN PULSES A BULB ANY MORE, so there is no `emission_strength` loop here.
## Both crown organs are built with `glow: false`; `_add_antenna` still hands back a `bulb_mat`
## meta (a matte material with the uniform present) precisely so a caller that kept the old pulse
## would be inert rather than crashing, but writing to it would be dead code, so it is gone.
##
## The visible tell is MOTION instead, and the two of them move differently: Pip's single feeler
## sways nearly three times as far as Pop's stiff blades, and his two counter-rotate against each
## other rather than swinging together.
func _animate_extras(delta: float) -> void:
	_t += delta
	var wob := sin(TAU * (_t + bounce_phase) / (1.5 if _is_pip else 2.1))
	var amp := 0.17 if _is_pip else 0.06
	var droop := clampf(-pose(P.EXTRA_A), 0.0, 1.0) * (0.75 if _is_pip else 0.30)
	for i in _antennae.size():
		var a := _antennae[i]
		var rest: float = a.get_meta("rest_tilt", 0.0)
		a.rotation.z = rest + amp * wob * (1.0 if i == 0 else -1.0) - droop
	_retract_lids()


## PIP'S LIDS GET OUT OF THE WAY FOR `happy` AND `surprised`. Without this her expressions simply
## stop existing, which the brief correctly calls a fail — measured at rest, the happy "^" arc
## reaches y +0.036 and the surprised ball y +0.041, both far above a lid edge at +0.0120, so the
## lid buries the entire expression and all she does is keep her sleepy face while smiling.
##
## IT HAS TO BE A POST-PASS, and `_animate_extras` is the only place it can be. `tick()` runs
## `_apply_pose` — and therefore `_apply_face` — BEFORE `_animate_extras`, so anything written here
## is the last word for the frame and cannot be fought by the base class on the same tick. That is
## the same reason Fen's `_ripple_blink` lives in this hook.
##
## THE x2.2 IS LOAD-BEARING AND IS NOT A FUDGE. `_apply_face` swaps the oval out for the arc or the
## ball on a HARD `> 0.5` test, so the lid has to be ALREADY CLEAR by the time the channel crosses
## 0.5 — it cannot be merely on its way. x2.2 saturates the retract at 0.4545, one blend step early.
## Writing `if pose(P.EYE_HAPPY) > 0.5` instead buys a frame of buried arc every single time she
## smiles. No extra smoothing state is needed either: `_pose` is already lerped at `_blend_rate`, so
## the lid rolls up over roughly 0.2 s and reads as her opening her eyes.
##
## AND `blink_hold` STAYS AT 0.45. It will be tempting to slow it down, because a sleepy character
## "should" blink slowly. Two reasons not to, and they are both in the pair rather than in her.
## First, blink rate is one of only five non-accessory cues carrying the twins apart at all (Pip
## 0.45 against Pop 1.7) and slowing her converges them on the one differentiator that costs zero
## triangles. Second, a heavy lid over a FAST blink reads as drowsy-fighting-it, which is better
## acting than uniformly slow and which agrees with her shipped dialogue — npc_data.gd gives Pip the
## chatty, over-caffeinated voice, so a character who is heavy-lidded and still blinking twice as
## fast as her brother is the one reading that keeps the model and the writing in the same room.
func _retract_lids() -> void:
	if _lids.is_empty():
		return
	var open_amt := clampf(maxf(pose(P.EYE_HAPPY), pose(P.EYE_ROUND)) * 2.2, 0.0, 1.0)
	for i in mini(_lids.size(), _lid_home.size()):
		_lids[i].position = _lid_home[i] + LID_RETRACT * open_amt
