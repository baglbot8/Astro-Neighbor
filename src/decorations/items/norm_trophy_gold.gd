extends DecoItem
## Gold Human Award — Norm's third quiz reward, the top of the trophy ladder before the statues start
## (NORM_SPEC.md §6). Same goblet-on-plinth family as bronze and silver, tallest of the three and
## gold-coloured, with a taller finial so it reads as the clear top rung at a glance.
##
## R2 FIX 2026-09-19: the round-1 colours (S 0.406 / S 0.500 on their own swatch) measured S 0.72 on
## Compatibility in the real home scene - the same lit-face specular boost bronze's comment describes,
## bigger here because gold started closer to the gate. Desaturated toward ~S 0.30 the same way, hue
## and value kept so it still reads brighter/more yellow than bronze (the ladder cue).
const CUP := Color("#d9ca98")      ## S 0.300 V 0.851 - same hue/value as before, desaturated
const CUP_DARK := Color("#b8aa7d") ## S 0.321 V 0.722
const PLINTH := Color("#c7b98d")
const PLINTH_DARK := Color("#b3a578")


func _init() -> void:
	footprint = 0.44
	collide_radius = 0.32
	collide_height = 0.68


func _build() -> void:
	var kit := DecoKit.new()
	kit.rbox(Vector3(0.0, 0.06, 0.0), Vector3(0.46, 0.12, 0.46), 0.05, PLINTH_DARK)
	kit.rbox(Vector3(0.0, 0.155, 0.0), Vector3(0.34, 0.075, 0.34), 0.035, PLINTH)
	kit.cone(Vector3(0.0, 0.19, 0.0), 0.055, 0.034, 0.16, CUP_DARK)
	kit.sphere(Vector3(0.0, 0.37, 0.0), 0.055, CUP_DARK, Vector3.ONE, 12)
	var prof := PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.095, 0.014), Vector2(0.13, 0.11),
		Vector2(0.12, 0.22), Vector2(0.08, 0.26),
	])
	kit.lathe(prof, 20, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.37, 0.0)), CUP, true)
	for s in [-1.0, 1.0]:
		kit.tube(Vector3(0.125 * s, 0.47, 0.0), Vector3(0.19 * s, 0.41, 0.0), 0.018, CUP)
		kit.tube(Vector3(0.19 * s, 0.41, 0.0), Vector3(0.13 * s, 0.375, 0.0), 0.018, CUP)
	# taller star finial with a small ball on top - the "highest tier" cue
	kit.extrude(DecoKit.star_poly(0.055, 0.024, 5), 0.024, CUP_DARK,
		Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.65, 0.0)))
	kit.sphere(Vector3(0.0, 0.7, 0.0), 0.024, CUP, Vector3.ONE, 8)
	add_body(kit.commit())
