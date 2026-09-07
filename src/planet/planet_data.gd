class_name PlanetData
extends Resource
## Describes one tiny planet. One .tres per planet in res://src/planet/data/.
## Planet builder owns mesh/biome fields. Other systems read id/radius/spawn/pad/npcs/buildings.
##
## ============================================================================================
## EVERY SIZE FIELD BELOW IS AUTHORED AT `REFERENCE_RADIUS` (16 m), NOT AT THIS PLANET'S RADIUS.
## ============================================================================================
## STYLE_GUIDE R2.11 shrank the starting planets and asked for a home-planet size UPGRADE, which
## means a planet's radius is no longer a constant the content can be hand-fitted to. So the
## content is written once, for a 16 m world, and `Planet` rescales it for whatever radius the
## planet actually has:
##
##   horizontal feature sizes (plateau_radius, crater radii)  x  radius / 16
##   vertical amplitudes (hill, detail, terrace, plateau,     x  radius / 16
##       crater depth + rim, river depth, water_level)
##   scatter counts (tree / rock / flower_patch)              x (radius / 16)^2   [= surface area]
##
## Vertical scales LINEARLY with radius because the noise frequency is `hill_frequency / radius`:
## the wavelength of every landform is already proportional to the radius, so the amplitude has to
## be too or the ground gets steeper as the planet shrinks — and slope is what kills the decoration
## placement budget. Counts scale with AREA so prop density (props per m^2) is radius-independent.
##
## Consequence to keep in mind when reading a .tres: `tree_count = 26` on a 12 m home planet means
## "26 trees' worth of density", which comes out as 15 actual trees. Look at `Planet.area_scale()`
## / `Planet.vertical_scale()` if a number does not match what you see in game.
##
## Fixed-size things (the 1.4 m astronaut, 5-8 m buildings, DecorationManager.RESERVED_CLEARANCE)
## deliberately do NOT scale — they are real-world sizes and the whole point of a smaller planet is
## that they loom larger on it.

## The radius every size field in this resource is expressed at. Do not change it: it is the unit
## the four .tres files are written in, not a tunable.
const REFERENCE_RADIUS := 16.0

## Home planet radius per `GameState.home_planet_size` level (STYLE_GUIDE R2.11: "add a persisted
## GameState.home_planet_size (an integer level, default 0) and a small table of radii"). Level 0 is
## the starting world; the later "expand your planet" upgrade is a +1 to that integer and nothing
## else. Every other world keeps the radius in its own .tres.
const HOME_RADII: Array[float] = [12.0, 14.0, 16.0, 18.0]
## Only THE shared home resource resolves its radius from GameState. A `.duplicate()` of it, or a
## PlanetData built in code, keeps whatever radius its owner set — `Resource.duplicate()` leaves
## `resource_path` empty, which is the discriminator. This matters: the title screen duplicates
## home.tres and hand-sets a 16 m preview globe (src/ui/title/title_screen.gd), and several
## showcases build their own 16 m test planet. None of those are the player's world, and a size
## upgrade must not silently resize them.
const HOME_DATA_PATH := "res://src/planet/data/home.tres"

@export var id: String = "home"
@export var display_name: String = "Little Orbit"
## For "home" this is only the level-0 fallback — `effective_radius()` is the authority. See
## HOME_RADII above.
@export var radius: float = 16.0
## "meadow" (home), "violet" (Zorp, alien), "chrome" (Bolt, robot), "plaza" (hub),
## "flats" (Fen, salt pan), "chalk" (Grig, terraced stone)
@export var biome: String = "meadow"
@export var seed: int = 1

@export_group("Terrain")
## ACNH ground is calm and walkable: keep this SMALL (0.15-0.35 m). Elevation should come from the
## deliberate landforms below (plateaus, crater rims), not from continuous rolling noise.
@export var hill_amplitude: float = 0.24     # meters of vertical displacement
@export var hill_frequency: float = 0.85     # noise frequency (per radius). Low = few broad landforms.
@export var detail_amplitude: float = 0.02
## Terracing: the smooth hill noise is quantised into flat steps `terrace_step` metres apart with a
## crisp bank between them (ACNH cliff grammar). 0 disables it.
@export var terrace_step: float = 0.36
## Fraction of a terrace band used by the bank. Small = crisper edge (0.05 crisp .. 0.5 = no terracing).
@export var terrace_band: float = 0.13
## How strongly the exposed-earth `bank_color` is painted onto TERRACE RISERS (the vertical cut face
## between two terrace steps). 0 = off, which is what the four shipped worlds use: today only crater
## walls and plateau banks get bank paint, so a terraced world is a smooth dome of `ground_color_a`
## with no visible contour lines at all. `Planet` feeds this into `bank_weight()` (which the ground
## shader reads out of COLOR.g) via a bell centred on each riser, so 1.0 draws every step edge as a
## full-strength cut face. Only meaningful when `terrace_step > 0`. [PLANET BUILDER]
@export var terrace_bank: float = 0.0
## Deliberate raised landforms: flat-topped plateaus with a crisp bank.
@export var plateau_count: int = 2
@export var plateau_height: float = 0.72     # metres the plateau top sits above the surrounding ground
@export var plateau_radius: float = 4.6      # metres, including the bank
@export var crater_count: int = 3
## Scales the baked ground occlusion (Planet._bake_color -> COLOR.a: prop contact pools, the concave
## feet of landforms, broad low ground). Per planet, because the four of them sit at different points
## in the tonal band: a violet or steel world starts darker than a meadow and needs less of it.
@export var ground_ao: float = 1.0
@export var water_level: float = -0.35       # meters relative to radius. Water sphere radius = radius + water_level. Set to -99 for no water.
## Icosphere subdivisions. `PlanetMeshBuilder` starts from a 20-face icosahedron and quadruples once
## per level, so the triangle count is 20 * 4^n: 5 = 20,480 tris, 6 = 81,920 tris. (The often-quoted
## "~41k" is the VERTEX count, 10 * 4^n + 2 = 40,962 at level 6 — not triangles.) Facet size matters
## more than the raw count when a world is terraced: edge length is about 1.0515 * radius / 2^n, and
## a riser needs >= 4 vertices across it or the baked bank colour renders as a dashed stipple.
@export var mesh_subdivisions: int = 6

@export_group("Colors")
## Keep base albedos MUTED (HSV S 0.40-0.52, V 0.62-0.75). Light makes things bright, not albedo.
@export var ground_color_a: Color = Color("#5cb45f")   # grass base
@export var ground_color_b: Color = Color("#3f8a4a")   # grass triangle pattern (darker)
## Large-scale shadow tone painted over the ground so genuinely dark values exist (ACNH #3d6e5b).
@export var ground_shadow_color: Color = Color("#3d6e5b")
## Exposed earth on plateau banks / crater walls (the ACNH cliff face).
@export var bank_color: Color = Color("#a97a4f")
@export var ground_color_low: Color = Color("#dbc99c") # sand / low areas near water
@export var rock_color: Color = Color("#cfc9bc")
## The colour this planet READS AS from orbit — its dominant visible surface, not its grass.
## Added for src/world/sky_bodies.gd, which currently paints every globe from `ground_color_a/b`.
## On the hub those two fields are the LAWN, while ~70% of the hub's surface is the cream plaza
## paving that `planet.gd::_make_ground_material()` sets straight on the material — so the hub's
## sky body comes out green-and-tan instead of "the big cream world" its own description promises.
## The environment builder can fix that by sourcing `land_a` from this field. [PLANET BUILDER]
@export var surface_color: Color = Color("#5cb45f")
@export var water_color: Color = Color("#4fc3f7")
@export var water_deep_color: Color = Color("#1e88e5")
@export var foliage_color_a: Color = Color("#4a9a52")
@export var foliage_color_b: Color = Color("#6ec065")
## Canopy undersides / lower tiers. Must be genuinely dark — this is where our dark tones live.
@export var foliage_shadow_color: Color = Color("#2c6045")
@export var trunk_color: Color = Color("#8e5f3d")
@export var flower_colors: PackedColorArray = PackedColorArray([Color("#ff6b9d"), Color("#ffd166"), Color("#ffffff")])

@export_group("Sky")
@export var sky_top_color: Color = Color("#4fa8ff")
@export var sky_horizon_color: Color = Color("#bfe6ff")
@export var ground_horizon_color: Color = Color("#6fbf73")
@export var sun_color: Color = Color("#fff4d6")
@export var ambient_color: Color = Color("#cfe5ff")
@export var fog_color: Color = Color("#bfe6ff")
@export var has_ring: bool = false
@export var ring_color: Color = Color("#ffcf8a")
## Ring geometry, as MULTIPLES OF THE PLANET RADIUS, handed to `PlanetRing` by
## `environment.gd::_build_ring()`. The defaults are Bolt's shipped hoop (1.7R .. 2.9R at 42 deg),
## which that function currently hardcodes; leaving them alone keeps Bolt byte-identical. A tight
## pair (e.g. 1.22 / 1.52) with a near-edge-on tilt reads as a razor band rather than a hoop, which
## is how a second ringed world avoids looking like the first one. [ENVIRONMENT]
@export var ring_inner_scale: float = 1.7
@export var ring_outer_scale: float = 2.9
## Tilt of the ring plane in degrees. 0 = ring in the planet's equatorial plane (seen edge-on from
## the surface at the equator); 90 = fully face-on overhead.
@export var ring_tilt_deg: float = 42.0
@export var moon_count: int = 1
@export var cloud_density: float = 0.5
## Elevation of the sun above the horizon at LOCAL NOON, in degrees. Replaces the hardcoded constant
## in `environment.gd` (the shipped four all ran at 52.0). This is the single strongest per-world
## light lever there is: shadow length is 1 / tan(elev) times the caster's height, so 52 deg gives a
## 0.8x shadow and 11 deg gives a 5.1x one. Below ~20 deg, `directional_shadow_max_distance` (25.0)
## must be raised or long shadows are clipped mid-frame. [ENVIRONMENT]
@export var sun_peak_elev_deg: float = 52.0
## Angular radius of the sun disc drawn by `sky.gdshader`. 0.026 is the shader's own default, which
## is what every planet has silently used because `environment.gd::_apply()` has never set the
## uniform. Larger = a bigger, closer, hazier star. [ENVIRONMENT]
@export var sun_disc_size: float = 0.026
## Angular radius of the moons in `sky.gdshader` (same units as `sun_disc_size`); 0.055 is the
## shader default. Inert when `moon_count` is 0. [ENVIRONMENT]
@export var moon_size: float = 0.055
## Multiplier on the star field density in `sky.gdshader`. 1.0 is the shader default; raise it for a
## thin-atmosphere world where the stars stay visible by day. [ENVIRONMENT]
@export var star_density: float = 1.0

@export_group("Points of interest")
## Unit direction from planet center. spawn = where player first appears. pad = rocket landing pad.
@export var spawn_dir: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var pad_dir: Vector3 = Vector3(0.55, 0.75, 0.35)
## npc ids that live here, e.g. ["zorp"]. Each npc has its own home_dir set by the character builder in npc data.
@export var npcs: PackedStringArray = PackedStringArray()
## building ids placed here (hub only): "town_hall", "deco_store", "clothes_store", "event_space", "player_home"
@export var buildings: PackedStringArray = PackedStringArray()
@export var music_track: String = "meadow_day"

@export_group("Props")
## Scatter counts, per REFERENCE_RADIUS (see the header): the real count is this x (radius / 16)^2.
@export var tree_count: int = 14
@export var rock_count: int = 10
@export var flower_patch_count: int = 8
## Collectibles are a DAILY QUOTA, not scatter — they do not scale with the planet's area, because
## "find eight shards" is a gameplay promise and a smaller world just makes it a shorter walk.
@export var collectible_count: int = 8
@export var collectible_kind: String = "stardust_shard"


# ================================================================================= size resolution
## Radius level for the home planet, read from GameState when it exists. Kept behind a lookup rather
## than a direct `GameState.` reference so tools, the headless survey and any scene that runs without
## the autoloads still resolve a planet.
static func home_size_level() -> int:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null or loop.root == null:
		return 0
	var gs := loop.root.get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.get("home_planet_size"))


## Radius (metres) for a home-planet size level, clamped to the table.
static func home_radius_for_level(level: int) -> float:
	return HOME_RADII[clampi(level, 0, HOME_RADII.size() - 1)]


## THE radius of `d`: the home planet resolves it from `GameState.home_planet_size` so the future
## "expand your planet" upgrade is a data change; every other world keeps its authored value.
## Idempotent — safe to call as often as you like, including on a resource already resolved.
static func effective_radius(d: PlanetData) -> float:
	if d == null:
		return REFERENCE_RADIUS
	if d.id == "home" and d.resource_path == HOME_DATA_PATH:
		return home_radius_for_level(home_size_level())
	return d.radius


## Writes `effective_radius()` back onto the resource so everything that reads `data.radius`
## (world.gd's pad step-off, environment.gd's sky band, the rocket's approach maths, the geometry
## cache key) sees the same number without every one of them having to know about the upgrade.
## `load()` hands out one shared instance per .tres, so this resolves the planet for the whole game.
static func resolve_size(d: PlanetData) -> float:
	if d == null:
		return REFERENCE_RADIUS
	d.radius = effective_radius(d)
	return d.radius
