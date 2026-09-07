class_name EnvPalette
extends RefCounted
## Keyframed colors and scalars for the 24 h day, built from a PlanetData so every planet gets
## its own dawn / day / dusk / night while sharing the same cozy timing.
## Colors are Gradient resources (offset = hour / 24), scalars are Curve resources.
## Sample with `sky_zenith.sample(EnvPalette.t(hour))` or the helpers below.
##
## THIN ATMOSPHERE (STYLE_GUIDE R2.1). There is no blue dome out here. The sky is deep space
## everywhere except a thin dusty band hugging the planet's limb, and the three sky colours are
## measured as ANGLES ABOVE THAT LIMB, not as elevation:
##   sky_limb   right on the ground silhouette
##   sky_mid    a few degrees up (this is most of what the gameplay camera actually sees)
##   sky_zenith straight up - near black
##   haze       the dusty warm tone mixed INTO the band, at `haze_strength` over `haze_width` rad
## Dawn and dusk still get their golden hour: the band burns warm and widens, under a black sky.

## Deep-space stops. Day is a touch lighter and less saturated than night so a daytime gameplay
## frame does not turn into a wall of vivid navy (R2.6 caps saturation p90 at 0.68); night is free
## to go properly deep because the R2.6 gates are measured on a DAYTIME frame.
const DAY_ZENITH := Color("#0d1330")
const DAY_MID := Color("#161d3e")
const DAY_LIMB := Color("#343650")
const NIGHT_ZENITH := Color("#070a1e")
const NIGHT_MID := Color("#0c1130")
const NIGHT_LIMB := Color("#181d40")
const DAWN_ZENITH := Color("#1b1a3c")
const DAWN_MID := Color("#2c2450")
const DAWN_LIMB := Color("#5c3f57")
const DUSK_ZENITH := Color("#1d1838")
const DUSK_MID := Color("#31234c")
const DUSK_LIMB := Color("#653e4e")
## The dusty band colour. Warm and low-chroma by day, a real sunrise/sunset colour at the edges.
const DAWN_HAZE := Color("#e8a37e")
const DUSK_HAZE := Color("#f0996c")
const DUSK_HAZE_LATE := Color("#b4658a")
const NIGHT_HAZE := Color("#2e3468")
## Per-biome daytime dust, so each world keeps its identity in the one place the sky still has
## colour. Deliberately low chroma (S 0.22-0.32): this is regolith haze, not a painted sky.
const BIOME_DUST := {
	"meadow": Color("#c9ab8e"),
	"violet": Color("#c197ba"),
	"chrome": Color("#cf9f78"),
	"plaza": Color("#d0bb9a"),
	# A rose-amber limb band for Fen's terracotta pan, 13 deg of hue clear of chrome's orange.
	"flats": Color("#d69f8e"),
	# The palest dust in the dict, which is correct for a world that kicks up chalk powder.
	"chalk": Color("#d6c9b4"),
}
## Per-biome tint mixed into the deep-space stops (10%) so Zorp's sky is faintly violet etc.
const BIOME_DEEP := {
	"meadow": Color("#1a2a52"),
	"violet": Color("#2a1a4e"),
	"chrome": Color("#16283f"),
	"plaza": Color("#1c2650"),
	# The first two non-navy deeps. Lerped 10-16% into the stops, a near-black plum gives Fen a sky
	# measurably warmer and darker than anyone else's, and a near-black rust does the same for Grig.
	"flats": Color("#2e1c30"),
	"chalk": Color("#2a1f1c"),
}

## Night fill light. Strongly blue on purpose: the reference night grade washes the whole world in
## blue (grass reads dark teal, sand reads lavender) and only emissives keep their own colour.
const NIGHT_AMBIENT := Color("#4a5cd0")
## Moonlight colour: pale, cool, low energy.
const MOON_LIGHT := Color("#9db0e8")

var sky_zenith: Gradient
var sky_mid: Gradient
var sky_limb: Gradient
var haze: Gradient
var wisp_color: Gradient
var sun_color: Gradient
var sun_glow_color: Gradient
var ambient: Gradient
var fog: Gradient
var moon_light: Gradient

var sun_energy: Curve
var moon_energy: Curve
var ambient_energy: Curve
var night: Curve          # 0 day .. 1 night (stars, moons, fireflies)
var sun_glow: Curve       # horizon glow around the sun, peaks at sunrise / sunset
var fog_density: Curve
var glow_intensity: Curve
var haze_strength: Curve  # how strongly the dust band is mixed in
var haze_width: Curve     # angular thickness of the band, radians above the limb
var wisp_amount: Curve    # thin high dust streaks (all that is left of the clouds)
var vignette: Curve
var saturation: Curve     # post grade
var dof_amount: Curve     # far depth-of-field radius; 0 always now (stars must stay pinpoints)

## Normalized gradient position for an hour.
static func t(hour: float) -> float:
	return fposmod(hour, 24.0) / 24.0

func build(data: PlanetData) -> void:
	# Sky colors are display-referred (the sky shader inverts the tonemapper), so what is
	# written here is what shows on screen.
	var deep: Color = BIOME_DEEP.get(data.biome, BIOME_DEEP["meadow"]) as Color
	var dust: Color = BIOME_DUST.get(data.biome, BIOME_DUST["meadow"]) as Color
	var day_zen := DAY_ZENITH.lerp(deep, 0.16)
	var day_mid := DAY_MID.lerp(deep, 0.16)
	var day_limb := DAY_LIMB.lerp(deep, 0.10)
	var night_zen := NIGHT_ZENITH.lerp(deep, 0.10)
	var night_mid := NIGHT_MID.lerp(deep, 0.14)
	var night_limb := NIGHT_LIMB.lerp(deep, 0.14)

	sky_zenith = _grad([
		[0.0, night_zen], [4.6, night_zen], [5.6, DAWN_ZENITH.lerp(night_zen, 0.4)],
		[6.6, DAWN_ZENITH.lerp(day_zen, 0.35)], [8.2, day_zen], [16.5, day_zen],
		[18.0, day_zen.lerp(DUSK_ZENITH, 0.5)], [19.1, DUSK_ZENITH],
		[20.3, night_zen.lerp(DUSK_ZENITH, 0.35)], [21.0, night_zen], [24.0, night_zen]])
	sky_mid = _grad([
		[0.0, night_mid], [4.6, night_mid], [5.6, DAWN_MID.lerp(night_mid, 0.4)],
		[6.6, DAWN_MID.lerp(day_mid, 0.3)], [8.2, day_mid], [16.5, day_mid],
		[18.0, day_mid.lerp(DUSK_MID, 0.5)], [19.1, DUSK_MID],
		[20.3, night_mid.lerp(DUSK_MID, 0.35)], [21.0, night_mid], [24.0, night_mid]])
	sky_limb = _grad([
		[0.0, night_limb], [4.6, night_limb], [5.4, DAWN_LIMB.lerp(night_limb, 0.5)],
		[6.2, DAWN_LIMB], [7.4, day_limb.lerp(DAWN_LIMB, 0.35)], [8.6, day_limb], [16.5, day_limb],
		[17.9, day_limb.lerp(DUSK_LIMB, 0.55)], [18.8, DUSK_LIMB], [19.6, DUSK_LIMB.lerp(NIGHT_LIMB, 0.4)],
		[20.5, night_limb], [24.0, night_limb]])
	haze = _grad([
		[0.0, NIGHT_HAZE], [4.7, NIGHT_HAZE], [5.5, DAWN_HAZE.lerp(NIGHT_HAZE, 0.35)],
		[6.2, DAWN_HAZE], [7.4, dust.lerp(DAWN_HAZE, 0.4)], [9.0, dust], [16.4, dust],
		[17.8, dust.lerp(DUSK_HAZE, 0.6)], [18.7, DUSK_HAZE], [19.4, DUSK_HAZE_LATE],
		[20.5, NIGHT_HAZE], [24.0, NIGHT_HAZE]])
	# The wisps are dust filaments in the band, so they take the band's own colour, lightened.
	wisp_color = _grad([
		[0.0, Color("#3a4278")], [4.7, Color("#3a4278")], [6.2, Color("#f2c3a6")],
		[9.0, dust.lightened(0.22)], [16.4, dust.lightened(0.22)], [18.7, Color("#f5b593")],
		[20.5, Color("#3a4278")], [24.0, Color("#3a4278")]])

	var sun_day: Color = data.sun_color
	sun_color = _grad([
		[0.0, Color("#6a78d8")], [4.8, Color("#6a78d8")], [5.6, Color("#ffa07a")], [6.6, Color("#ffc29a")],
		[8.0, sun_day.lerp(Color("#ffe0b8"), 0.4)], [10.0, sun_day], [15.5, sun_day], [17.2, Color("#ffd8a6")],
		[18.4, Color("#ffc493")], [19.2, Color("#e8a0a4")], [19.9, Color("#9a7ac8")], [20.6, Color("#6a78d8")], [24.0, Color("#6a78d8")]])
	sun_glow_color = _grad([
		[0.0, Color("#6c62c8")], [4.8, Color("#6c62c8")], [5.6, Color("#ff9d7a")], [6.4, Color("#ffc39a")],
		[8.0, Color("#f0d3b0")], [16.5, Color("#f0d3b0")], [18.0, Color("#ffbf7c")], [18.8, Color("#ff9460")],
		[19.6, Color("#e06a96")], [20.6, Color("#6c62c8")], [24.0, Color("#6c62c8")]])

	# Night ambient is desaturated slate-blue, not vivid indigo: the reference night meadow is a
	# dark teal-grey (34,80,104), not a glowing green.
	var amb_day: Color = data.ambient_color
	ambient = _grad([
		[0.0, NIGHT_AMBIENT], [4.8, NIGHT_AMBIENT], [5.8, Color("#a08498")], [6.8, Color("#d8c0c4")],
		[8.5, amb_day], [16.5, amb_day], [18.0, Color("#e8c0aa")], [18.9, Color("#b0839a")],
		[19.8, Color("#6a6494")], [20.8, NIGHT_AMBIENT], [24.0, NIGHT_AMBIENT]])
	# Distance fog is now a faint DUST tone, not the old pale-blue aerial perspective. Washing the
	# far hillside toward sky blue is an "Earth atmosphere" cue and it was part of what made the
	# blues pop (R2.6); a trace atmosphere barely veils anything at 20 m.
	var fog_day := dust.darkened(0.28)
	fog = _grad([
		[0.0, Color("#161c40")], [4.8, Color("#161c40")], [5.8, Color("#c08878")], [6.8, Color("#dcae94")],
		[8.5, fog_day], [16.5, fog_day], [18.0, Color("#d8a184")], [18.9, Color("#c07a6c")],
		[19.8, Color("#4a4278")], [20.8, Color("#161c40")], [24.0, Color("#161c40")]])
	moon_light = _grad([
		[0.0, MOON_LIGHT], [24.0, MOON_LIGHT]])

	sun_energy = _curve([[0.0, 0.0], [4.9, 0.0], [5.6, 0.45], [6.5, 0.95], [8.0, 1.75], [12.0, 1.95], [16.5, 1.8],
		[18.0, 1.45], [18.9, 1.05], [19.6, 0.45], [20.2, 0.0], [24.0, 0.0]])
	moon_energy = _curve([[0.0, 0.9], [4.6, 0.9], [5.8, 0.28], [6.6, 0.0], [18.6, 0.0], [19.4, 0.34], [20.4, 0.9], [24.0, 0.9]])
	# Day ambient is deliberately low so the sun (and therefore the cast shadows) do the work.
	# Nudged up ~13% from the blue-sky version because the sky itself no longer contributes any
	# fill (environment.gd drops ambient_light_sky_contribution to 0.10); without it the shadow
	# side would fall straight through the 40-55% band the style guide holds us to.
	ambient_energy = _curve([[0.0, 0.68], [4.8, 0.68], [6.0, 0.46], [8.0, 0.34], [17.0, 0.34], [17.8, 0.38],
		[18.8, 0.58], [20.2, 0.68], [21.0, 0.70], [24.0, 0.70]])
	night = _curve([[0.0, 1.0], [4.6, 1.0], [5.6, 0.55], [6.4, 0.0], [18.4, 0.0], [19.2, 0.45], [20.4, 1.0], [24.0, 1.0]])
	sun_glow = _curve([[0.0, 0.0], [4.8, 0.0], [5.5, 0.6], [6.2, 1.0], [7.4, 0.4], [9.0, 0.06], [16.0, 0.06],
		[17.5, 0.45], [18.6, 1.0], [19.4, 0.7], [20.3, 0.0], [24.0, 0.0]])
	fog_density = _curve([[0.0, 0.10], [5.0, 0.10], [6.2, 0.17], [9.0, 0.10], [17.0, 0.10], [18.7, 0.18], [20.4, 0.10], [24.0, 0.10]])
	glow_intensity = _curve([[0.0, 1.0], [4.8, 1.0], [6.4, 0.55], [8.0, 0.4], [17.0, 0.4], [18.8, 0.6], [20.3, 1.0], [24.0, 1.0]])
	# The band is a THIN rim by day and a wide golden hour at the edges.
	haze_strength = _curve([[0.0, 0.20], [4.8, 0.20], [5.6, 0.55], [6.3, 0.80], [8.0, 0.44], [16.4, 0.44],
		[17.8, 0.66], [18.7, 0.84], [19.7, 0.5], [20.6, 0.20], [24.0, 0.20]])
	haze_width = _curve([[0.0, 0.040], [4.8, 0.040], [6.2, 0.072], [8.5, 0.046], [16.5, 0.046],
		[18.6, 0.076], [19.8, 0.056], [20.8, 0.040], [24.0, 0.040]])
	# A few very thin, high, sparse filaments - never puffy clouds (R2.1).
	var wisp_base: float = clampf(data.cloud_density, 0.0, 1.0) * 0.16
	wisp_amount = _curve([[0.0, wisp_base * 0.4], [4.8, wisp_base * 0.4], [6.4, wisp_base],
		[9.0, wisp_base], [18.0, wisp_base], [19.6, wisp_base * 0.8], [20.6, wisp_base * 0.4], [24.0, wisp_base * 0.4]])
	vignette = _curve([[0.0, 0.42], [5.0, 0.42], [7.0, 0.26], [17.5, 0.26], [19.5, 0.36], [20.5, 0.42], [24.0, 0.42]])
	# Slightly under 1.0 by day: R2.6 asks every visual system to stop the colours popping, and the
	# grade is the one lever the environment owns that touches the whole frame.
	saturation = _curve([[0.0, 0.78], [4.8, 0.78], [6.4, 1.0], [8.0, 1.0], [17.0, 1.0], [18.8, 1.0],
		[20.4, 0.78], [24.0, 0.78]])
	# Far DOF is off at ALL hours now. Stars are visible in daylight too (R2.1) and the sky sits at
	# the far plane, so any far blur turns every star into a 3-4 px blob.
	dof_amount = _curve([[0.0, 0.0], [24.0, 0.0]])

## Builds a Gradient from [[hour, Color], ...] (hours ascending, must start at 0 and end at 24).
static func _grad(keys: Array) -> Gradient:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for k in keys:
		offsets.append(float(k[0]) / 24.0)
		colors.append(k[1])
	g.offsets = offsets
	g.colors = colors
	return g

## Builds a Curve from [[hour, value], ...] with eased (zero-tangent) interpolation.
static func _curve(keys: Array) -> Curve:
	var c := Curve.new()
	c.min_value = 0.0
	c.max_value = 2.0
	for k in keys:
		c.add_point(Vector2(float(k[0]) / 24.0, float(k[1])))
	c.bake_resolution = 256
	return c
