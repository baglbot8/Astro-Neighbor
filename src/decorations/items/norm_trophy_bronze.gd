extends DecoItem
## Bronze Human Award — Norm's first quiz reward (NORM_SPEC.md §6). A small stepped plinth with a
## chunky goblet cup, bronze all over. Same shape family as the silver and gold trophies (goblet on
## a plinth) so the ladder reads as "one thing getting better", scaled up and re-coloured per tier -
## bronze is the shortest and plainest of the three.

## S picked with a LOT of headroom under the R2.6 "no swatch above S 0.60" gate (measured, not
## guessed, 2026-09-19: gameplay-distance close-up captures on home, both renderers). Round 1 used
## S 0.52/0.55 (rendered up to S 0.62 on Forward+'s shadow term); round 2 used S 0.40/0.42 (still hit
## S 0.626 on the Compatibility renderer's LIT face - the parity-correction pass boosts saturation on
## lit bronze more than Forward+ does, same family of effect NORM LOOK's VISOR comment describes for
## norm_model.gd). This round measured clean on both: p90 0.34 (Forward+) / 0.39 (Compatibility).
const CUP := Color("#b2987d")      ## S 0.298 V 0.698
const CUP_DARK := Color("#8f7661") ## S 0.322 V 0.561
const PLINTH := Color("#c7b98d")   ## S 0.291 V 0.780 - matches the other stone/wood plinths in the set
const PLINTH_DARK := Color("#b3a578")


func _init() -> void:
	footprint = 0.4
	collide_radius = 0.28
	collide_height = 0.5


func _build() -> void:
	var kit := DecoKit.new()
	# plinth: two stepped rounded boxes
	kit.rbox(Vector3(0.0, 0.05, 0.0), Vector3(0.42, 0.1, 0.42), 0.04, PLINTH_DARK)
	kit.rbox(Vector3(0.0, 0.13, 0.0), Vector3(0.3, 0.06, 0.3), 0.025, PLINTH)
	# goblet stem
	kit.cone(Vector3(0.0, 0.16, 0.0), 0.045, 0.03, 0.1, CUP_DARK)
	kit.sphere(Vector3(0.0, 0.27, 0.0), 0.045, CUP_DARK, Vector3.ONE, 10)
	# cup bowl (a shallow lathed goblet)
	var prof := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.075, 0.01), Vector2(0.1, 0.09),
		Vector2(0.09, 0.16), Vector2(0.06, 0.19),
	])
	kit.lathe(prof, 16, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.27, 0.0)), CUP, true)
	# two handles
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.095 * s, 0.34, 0.0), Vector3(0.145 * s, 0.3, 0.0), 0.014, CUP)
		kit.tube(Vector3(0.145 * s, 0.3, 0.0), Vector3(0.1 * s, 0.28, 0.0), 0.014, CUP)
	add_body(kit.commit())
