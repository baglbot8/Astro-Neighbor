extends SafariWorld
## VELA'S WORLD WAKES UP - THE FROST ARRAY (docs/PLANET_SAFARI_SPEC.md 12.4; builder VELA, 2026-09-25).
## Loaded by PlanetSafari when a safari starts on Vela's Still Frost, freed when it ends: nothing here
## exists outside a safari (the user's rule 5) and nothing on the planet is changed - Vela herself is the
## one thing borrowed (she stops to call the sky, twice) and she is put back exactly where she stood, with
## her wandering as it was, when this node leaves the tree. The masts and their breathing lamps are only
## READ (their places); every light here is a sprite of this node's own, laid over them.
##
## Built from Vela's existing look (planet_props.gd `_vela`: the Long Array of eight identical masts with
## breathing amber lamps, the three half-buried dishes, drift fins, diamond dust, a high sun, dense stars,
## one moon) in the rules of Bolt's round 2 (spec 11-13): the user's TIERS, the density BAND measured by
## tools/ps_wanderer.gd, Facing and Size, "????" secrets, one safari a day offered by the host, the start
## at the pad, every event warned by a sight AND a sound, and the shared pacing director (SafariWorld.
## Pacing, spec 13.2) that varies what it brings and stays quiet while a rare is up.
##
## SCRAPBOOK AND POLISH (builder VELAC, 2026-09-26; spec 15.5 and 16): every roster entry has its scrapbook
## "category"; two SIGHTS (the Eight Masts, the Frozen Lake - the Mirror Field grown into a lake with
## banks and cracks, where the Mirror Moon still rises) and three BONUS things (a snow-astronaut, Vela's
## teacup, a star frozen in the ice) - see SIGHTS AND BONUS; and THE STAGING (spec 16: "the director brings
## seals leaping and chime-birds hovering into empty sky - the birds belong on the masts"): a brought
## chime-bird now lands only on a MAST (an arm end in your view); with no mast in view it does not come at all
## (no hovering, and no fly-over across empty sky: VELAC round 2) - and a brought seal comes up through a
## breathing hole in a skin of ICE, only where that ice is in your view - see _bring_bird and _bring_seal.
##
## ------------------------------------------------------------------------------------ THE TIERS (12.4)
##   creatures        always about, in many places  CHIME-BIRDS on three masts (the lit ones, 2, 5 and
##                                                   8), singing her call-and-response mast to mast;
##                                                   ICE-SEALS sliding on two frosty floes; SNOW-MITES,
##                                                   the roamer, up out of the powder wherever it has
##                                                   gone quiet. The pacing director brings a mite, a
##                                                   chime-bird (only onto a mast arm in view, VELAC)
##                                                   or a seal (up through ice in view, VELAC),
##                                                   and at night a star-krill swarm - whichever has the
##                                                   smallest share of the photos (first one turns daily).
##   common events    several times, ~30 s          the DIAMOND DUST SHOWER at three spots
##   uncommon events  several times, ~12 s          MAST PING on three masts; VELA'S CALL twice
##   rare events      once                          THE MIRROR MOON in the Mirror Field, overlapping
##                                                   Mast Ping (2) on the opposite side of the planet
##   rare day         1 day in 4                    AURORA OVER THE ARRAY
##   night only                                      STAR-KRILL, little glowing krill swimming up out of the
##                                                   floes and the field in a ring; at night the director's
##                                                   fourth bringer
##   the neighbour                                   VELA - out at the Long Array for the three minutes
##                                                   (see _build_vela), pottering by the masts; she
##                                                   waves when you come close, and turns to you, lamps
##                                                   up, when you hold the camera on her for 2 s
## RARITY follows the tier (SafariWorld.TIER_RARITY; no subject here overrides it).
##
## ------------------------------------------------------------------------------------ THE PLACES
## (degrees round the planet from the start beside the pad, bearing from the start heading, + = right;
## radius 14.5: 1 degree = 0.253 m; the safari walk 1.5 m/s = 5.9 deg/s, a quarter round 15 s, the far
## side 30 s.) The Long Array is fixed by the planet (probe --ps-layout, seed 137): masts 1-8 from
## (60, 74) down to (28, 125), the dishes (46-69, 108-146), Vela's home (96, 129). The rest is placed
## here to fill the empty half of the planet and keep subjects apart (logged at build with the distance
## from each to its nearest other place):
##   WEST FLOE     P_FLOES[0]   ice-seals (1), star-krill at night
##   FAR FLOE      P_FLOES[1]   ice-seals (2), star-krill at night
##   MIRROR FIELD  the nearest clear spot to the ANTIPODE of Mast One (the pinged mast at 1:00): it
##                 lands 168 degrees from it (logged) = 42.5 m = 28 s at the safari walk, so its still
##                 reflection (1:05.5-1:11) and that ping's rings (1:05-1:09) cannot both be caught -
##                 by distance and time only; not proved with Bolt's photo-grid probe. Star-krill at night.
##   DUST SPOTS    P_DUST (three), each clear of the other places.
##
## ------------------------------------------------------------------------------------ THE SCHEDULE
## Every timed event is warned WARN (8 s) ahead with a SIGHT and a SOUND that duplicate each other (spec 4):
## a line on screen naming the place, a sound heard anywhere, a glow on YOUR horizon toward it (fading
## once you are near: Bolt's beacons), and the event's own cue (the lamp brightens, the air glitters, the
## ice goes still and glints, the sky hums and a faint curtain shows, Vela turns to the sky).
##   0:10-0:22  MAST PING (1) on Mast Eight, by the start.     0:20-0:50  DIAMOND DUST (1)
##   0:36-0:48  VELA'S CALL (1) at the array.                   1:00-1:15  THE MIRROR MOON (rare), still 1:05.5-1:11
##   1:00-1:12  MAST PING (2) on Mast One - the rare's pair,    1:24-1:54  DIAMOND DUST (2)
##              its rings 1:05-1:09, 168 degrees (42 m, 28 s) away.
##   1:36-1:52  AURORA OVER THE ARRAY (rare day), flaring 1:42-1:47.   2:00-2:12  VELA'S CALL (2)
##   2:20-2:32  MAST PING (3) on Mast Five.                     2:26-2:56  DIAMOND DUST (3)
## The rares are kept SHORT (15 and 16 s): the director stays quiet while one is up, and on this big
## world most of the planet cannot see them (see THE FIELD STIRS BEFORE A RARE, which fills the seconds
## before one starts).
##
## ------------------------------------------------------------------------------------ PHONE BUDGET
## Creatures are herds (safari_herd.gd): birds 3 draw calls (body and two wings), seals 3 (body,
## flippers, holes), mites 1, star-krill 2 (bodies, glows; night only). The floes and the field are one mesh each on the shared toon material the
## masts draw with. Lights are the shipped star shader (beacons, lamp flares) and one additive unshaded
## material (rings, aurora); particles are CPUParticles3D on the shipped sparkle material. No lights, no
## GPU particles. Everything is built in `build` (warmed behind the fade) and only moved, shown or hidden.

const Meshes := preload("res://src/planet_safari/worlds/vela_meshes.gd")
const Herd := preload("res://src/planet_safari/worlds/safari_herd.gd")
const SFX_DIR := "res://assets/audio/sfx/"

## THE MANIFEST (spec 12.5, safari_world.gd). The lines are Vela's own voice (npc_data.gd "vela": formal
## and warm, whole courteous sentences, everything framed as sound and records - "I keep the array and
## its records", "Of course. The request will keep. So will I.", "I do not sleep. I lower my gain and
## drift.").
const MANIFEST := {
	"host": "vela",
	"offer": "Each day, my field wakes and sings for three minutes.",
	"ask": "May I offer you a photo safari?",
	"yes": "Wonderful. Start at the landing pad. I'll be listening.",
	"no": "Of course. The offer will keep until midnight. So will I.",
	"asleep": "The field is quiet today. Do come back tomorrow.",
	"roster": [
		{"id": "chime_bird", "name": "Chime-bird", "tier": "creature", "category": "creature"},
		{"id": "ice_seal", "name": "Ice-seal", "tier": "creature", "category": "creature"},
		{"id": "snow_mite", "name": "Snow-mite", "tier": "creature", "category": "creature"},
		{"id": "vela", "name": "Vela", "tier": "neighbour", "category": "neighbour"},
		{"id": "diamond_dust", "name": "Diamond Dust Shower", "tier": "common", "category": "event"},
		{"id": "mast_ping", "name": "Mast Ping", "tier": "uncommon", "category": "event"},
		{"id": "vela_call", "name": "Vela's Call", "tier": "uncommon", "category": "event"},
		{"id": "mirror_moon", "name": "The Mirror Moon", "tier": "rare", "category": "event"},
		{"id": "aurora", "name": "Aurora over the Array", "tier": "rare_day", "category": "event"},
		{"id": "star_krill", "name": "Star-krill", "tier": "night", "category": "creature"},
		# THE SCRAPBOOK'S SIGHTS AND COLLECTOR'S PAGES (spec 15.5; see SIGHTS AND BONUS below)
		{"id": "eight_masts", "name": "The Eight Masts", "tier": "sight", "category": "sight"},
		{"id": "frozen_lake", "name": "The Frozen Lake", "tier": "sight", "category": "sight"},
		{"id": "snow_astronaut", "name": "A Snow-astronaut", "tier": "bonus", "category": "bonus"},
		{"id": "vela_teacup", "name": "Vela's Teacup", "tier": "bonus", "category": "bonus"},
		{"id": "frozen_star", "name": "A Star in the Ice", "tier": "bonus", "category": "bonus"},
	],
	"review": {
		"no_subject": [
			"Filed: the field itself. Quiet, but a quiet worth keeping.",
			"A still frame of the frost. I shall file it under 'atmosphere'.",
		],
		"Smudge": [
			"Filed: %s. Faint, but received all the same.",
			"A soft signal of %s. It is on the record.",
		],
		"Fair": [
			"Filed: %s. A clear and honest entry.",
			"Received: %s. Clean enough for the archive.",
		],
		"Fine": [
			"Filed: %s. Beautifully clear. Thank you.",
			"Received: %s. The array approves, I believe.",
		],
		"Gallery": [
			"Filed: %s. Exquisite. I shall play it back often.",
			"Received: %s. The finest signal of the day.",
		],
		"moment": " And the timing was impeccable.",
	},
}

# ------------------------------------------------------------------------------ the schedule (s)
const WARN := 8.0
## "mast" = the mast's index (RelayMast<i>; Vela calls it by its ordinal, i + 1). "best" = the rings.
const PING_RUNS := [
	{"id": "mast_ping", "start": 10.0, "end": 22.0, "mast": 7, "best": Vector2(14.0, 18.5)},
	{"id": "mast_ping_2", "start": 60.0, "end": 72.0, "mast": 0, "best": Vector2(65.0, 69.0)},
	{"id": "mast_ping_3", "start": 140.0, "end": 152.0, "mast": 4, "best": Vector2(144.0, 148.5)},
]
const PING_EVERY := 2.2
const PING_RING_SEC := 1.6
const PING_RING_M := 3.2
const DUST_RUNS := [
	{"id": "diamond_dust", "start": 20.0, "end": 50.0, "at": 0},
	{"id": "diamond_dust_2", "start": 84.0, "end": 114.0, "at": 1},
	{"id": "diamond_dust_3", "start": 146.0, "end": 176.0, "at": 2},
]
## Each shower is THICKEST from 12 s to 16.5 s after it starts: the sun catches it and it sparkles.
const DUST_THICK_AT := 12.0
const DUST_THICK_SEC := 4.5
const CALL_RUNS := [
	{"id": "vela_call", "start": 36.0, "end": 48.0},
	{"id": "vela_call_2", "start": 120.0, "end": 132.0},
]
## Within a call: she lifts her face to the sky and calls (rings rise from her) from the start; the array
## ANSWERS, every lamp down the run in turn, from CALL_ANSWER.x to .y after the start.
const CALL_ANSWER := Vector2(3.5, 8.5)
const MIRROR_START := 60.0
const MIRROR_END := 75.0
const MIRROR_STILL := Vector2(65.5, 71.0)
const AURORA_START := 96.0
const AURORA_END := 112.0
const AURORA_FLARE := Vector2(102.0, 107.0)
## Star-krill at night: a swirl rises every KRILL_SWIRL_EVERY for KRILL_SWIRL_SEC.
const KRILL_SWIRL_EVERY := 11.0
const KRILL_SWIRL_SEC := 2.5

# ------------------------------------------------------------------------------ the places
const MAST_H := 3.05
const MAST_N := 8
const BIRD_MASTS := [1, 4, 7]
const ORDINALS := ["ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT"]
const P_FLOES := [Vector2(72.0, -52.0), Vector2(148.0, 20.0)]
const P_DUST := [Vector2(42.0, -22.0), Vector2(128.0, 88.0), Vector2(100.0, -150.0)]
const FLOE_R := 1.9
const FIELD_R := 2.5
## A warning glow sits this far round from you toward its event, just inside your horizon (eye 1.6 m on
## a 14.5 m world: acos(14.5 / 16.1) = 25.8 degrees), and fades out between these two.
const BEACON_AHEAD_DEG := 23.0
const BEACON_NEAR_DEG := 42.0
const BEACON_FULL_DEG := 60.0

# ------------------------------------------------------------------------------ SIZE BANDS (spec 11.1)
## Bolt's rule (worlds/bolt.gd SIZE BANDS): at the 45 degree lens and the subject's USUAL DISTANCE the
## size score is 6 or less, i.e. band.x >= 1.76 x the size there (the scorer's 10 / (1 + x^2) curve),
## and the band is reached by walking in or zooming. size_frac = tan(asin(r / d)) / tan(22.5 deg);
## band.y = 1.645 band.x (Bolt's ratio), capped at 1.
##   subject        radius  usual d  size_frac  band
##   chime-bird     0.16    3.8 m    0.102      0.18-0.30
##   ice-seal       0.40    4.5 m    0.215      0.38-0.62
##   snow-mite      0.15    3.1 m    0.117      0.21-0.35
##   Vela           0.80    6.0 m    0.325      0.57-0.94   (met at 9-10 m; 6 m kept, the stricter)
##   diamond dust   2.20   10.0 m    0.544      0.96-1.00
##   mast ping      1.20   11.0 m    0.265      0.47-0.77
##   Vela's call    1.10    7.0 m    0.384      0.68-1.00
##   mirror moon    1.60    7.8 m    0.506      0.89-1.00
##   aurora         3.00   24.0 m    0.304      0.54-0.88   (it stands 10 m over the array)
##   star-krill     0.60    3.4 m    0.433      0.76-1.00   (a swarm; see below)
## USUAL DISTANCE: the wanderer's median distance while each was photographable (tools/ps_wanderer.gd
## `dists`, 32 runs, 2026-09-25), rounded down, with the spec's 3 m floor for the small creatures. The
## STAR-KRILL are the exception: the wanderer met them at 6.04 m (median, 30 runs, round 2) because the
## home swarms glow over the floes and are seen from afar, but they are PHOTOGRAPHED where the director
## brings them, 3.4 m (the careless player's median photo distance, 16 runs) - and a band set from 6 m
## gave the careless player 16 Fine or Gallery of 20 krill photos. So theirs is set from 3.4 m.
const BAND_BIRD := Vector2(0.18, 0.30)
const BAND_SEAL := Vector2(0.38, 0.62)
const BAND_MITE := Vector2(0.21, 0.35)
const BAND_VELA := Vector2(0.57, 0.94)
const BAND_DUST := Vector2(0.96, 1.00)
const BAND_PING := Vector2(0.47, 0.77)
const BAND_CALL := Vector2(0.68, 1.00)
const BAND_MIRROR := Vector2(0.89, 1.00)
const BAND_AURORA := Vector2(0.54, 0.88)
const BAND_KRILL := Vector2(0.76, 1.00)

# ------------------------------------------------------------------------------ creatures
const BIRD_SCOUTS := 3
const SEAL_PER_FLOE := 2
const SEAL_SCOUTS := 3
const MITE_SCOUTS := 2
## A scout that has been out this long goes home as soon as it is out of view. (Bolt's also waited
## until you were SCOUT_DOWN_M away; here a careful player standing still kept its scouts out and
## photographed the same snow-mite again and again: 33% of its photos, over spec 13.2's 30%.)
const SCOUT_OUT_MIN_SEC := 12.0
const SCOUT_DOWN_M := 5.0
## Stand still with the camera up this close, this long, and the nearest creature turns to you.
const HELLO_M := 6.0
## (2.0 s, not Bolt's 0.8: at 0.8 the careless test player - raise, point, a second, tap - caught a
## hello in most photos and averaged between Fair and Fine; the hello is for the one who waits.)
const HELLO_STILL := 2.0
const HELLO_SEC := 3.5
const HELLO_REST := 6.0
## Walk faster than this within RUSH_M and a seal slips into its hole, a mite hops away.
const RUSH_M := 2.2
const RUSH_SPEED := 0.6
## Chime-birds sing the call-and-response mast to mast: one sings SONG_SEC, then the next answers.
const SONG_SEC := 1.3
const SONG_GAP := 1.6
const BIRD_FLY_SEC := 1.1
const SEAL_SLIDE_SPEED := 0.55
const MITE_HOP_M := Vector2(0.35, 0.7)
const MITE_HOP_H := 0.22
const MITE_AIR_SEC := 0.38
const MITE_POP_SEC := 0.45
const MITE_SINK := 0.34
const SEAL_SINK := 0.5
## SafariLayer.intro_hint shows its control hint for 4.5 s on a phone (5.0 on a desktop).
const INTRO_HINT_SEC := 5.1
const LINE_SEC := 3.6

enum Bird { PERCH, FLY, AWAY }
enum Seal { REST, SLIDE, CLAP, HELLO, DIVE, UNDER, SURFACE, LEAP }
enum Mite { GONE, POP, SIT, CROUCH, AIR, LAND, HELLO }

# ------------------------------------------------------------------------------ state
var pacing: SafariWorld.Pacing
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _building := false
var _sleeping := false
var _eligible: Dictionary = {}
var _prop_mat: ShaderMaterial
var _add_mat: StandardMaterial3D
var _pad_dir := Vector3.UP

var _masts: Array = []            # per mast: {node, dir, lamp (world), up, x (world arm axis), arm (height)}
var _array_mid := Vector3.UP
var _floes: Array[Vector3] = []
var _mirror_dir := Vector3.UP
var _dust_dirs: Array[Vector3] = []
var _home_dir := Vector3.UP

var _bird_herd: Herd
var _birds: Array = []
var _bird_focus: Node3D
var _bird_pick := -1
var _song_i := 0
var _song_next := 2.0
var _notes: CPUParticles3D

var _seal_herd: Herd
var _seals: Array = []
var _seal_focus: Node3D
var _seal_pick := -1

var _mite_herd: Herd
var _mites: Array = []
var _mite_focus: Node3D
var _mite_pick := -1
var _still := 0.0
var _hello_next := 0.0

var _flares: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _ping_focus: Node3D
var _ping_last := -INF
var _ping_mast := -1

var _call_rings: MeshInstance3D
var _call_mat: StandardMaterial3D
var _call_focus: Node3D
var _vela: Node3D
var _vela_saved := Transform3D()
var _vela_wander_saved := true
var _vela_borrowed := false
var _vela_wave_until := -1.0
var _vela_pose_until := -1.0
var _vela_next_wave := 0.0
var _vela_next_pose := 0.0
var _call_voice_next := 0.0
var _call_step := -1

var _dust_root: Node3D
var _dust_fall: CPUParticles3D
var _dust_glint: CPUParticles3D
var _dust_heavy: CPUParticles3D
var _dust_at := -1

var _field: MeshInstance3D
var _mirror: MeshInstance3D
var _mirror_halo: MeshInstance3D
var _mirror_glints: CPUParticles3D
var _mirror_focus: Node3D
var _beam: MeshInstance3D
var _moon_img: MeshInstance3D
var _beam_mat: StandardMaterial3D

var _aurora_root: Node3D
var _curtains: Array[MeshInstance3D] = []
var _aurora_mat: StandardMaterial3D
var _aurora_focus: Node3D
var _hum: AudioStreamPlayer


var _beacons: Dictionary = {}
var _lines: Array = []
var _line_free_at := 0.0
var _sounds: Array[AudioStreamPlayer] = []


# ======================================================================================== BUILD
func build(s: PlanetSafari) -> void:
	safari = s
	_rng.seed = 12_0925_137
	_prop_mat = PlanetPropMeshes.prop_material()
	_add_mat = _additive_material()
	_find_places()
	_build_floes()
	_build_birds()
	_build_seals()
	_build_mites()
	_build_vela()
	_build_lamps()
	_build_dust()
	_build_mirror()
	_build_sights()
	_build_bonus()
	_build_perches()
	if safari.is_rare_day:
		_build_aurora()
	if safari.is_night:
		_build_krill()
	_register_events()
	pacing = SafariWorld.Pacing.new()
	add_child(pacing)
	pacing.setup(self)
	# A bigger world than Bolt's (radius 14.5 against 10.5): the director steps in two seconds sooner
	# (measured: at Bolt's 12 s, 22 of 32 wander runs kept the longest gap within 20 s).
	pacing.AFTER_SEC = 10.0
	# WHICH ONE, AND WHEN AN OVER-SHARE ONE MAY STILL COME, is the director's (SafariWorld.Pacing: THE PER-BRING
	# CAP, spec 17.1 rule 7). This world's own HOLD_WAIT_SEC = INF and its mite-only cap check are gone (PACE,
	# 2026-09-27): with both, careful seed 1 (a rare day) had snow-mite 2 and seal 1 of 3 photos - both over
	# 30% - and the one subject under share, the chime-bird, comes only to a mast arm in view, so nothing came
	# for the last 114 s of the safari. The staging stays: a bird only on a mast, a seal only up through ice
	# in the picture, a mite's bounce no higher than MITE_RISE_MAX.
	for b: Dictionary in _bringers():
		pacing.add_bringer(b)
	pacing.places = _creature_places
	_building = true
	tick(0.0, 0.0)
	_building = false
	var names := ["floe W", "floe far", "mirror", "dust 1", "dust 2", "dust 3", "home", "array"]
	var pts: Array[Vector3] = [_floes[0], _floes[1], _mirror_dir, _dust_dirs[0], _dust_dirs[1], _dust_dirs[2], _home_dir, _array_mid]
	var rows: Array = []
	for i in pts.size():
		var near := 180.0
		var near_n := ""
		for j in pts.size():
			if j != i:
				var a := rad_to_deg(pts[i].angle_to(pts[j]))
				if a < near:
					near = a
					near_n = names[j]
		rows.append("%s %s (nearest %s %.0f deg)" % [names[i], _pp(pts[i]), near_n, near])
	_log("built rare=%s night=%s: %s; mirror to mast one %.0f deg" % [str(safari.is_rare_day), str(safari.is_night),
		", ".join(rows), rad_to_deg(_mirror_dir.angle_to((_masts[0] as Dictionary)["dir"]))])


## What the pacing director may bring: a seal, a chime-bird, a snow-mite, and at night the star-krill
## too. The ORDER is its tie-break for the first bring of a safari (every share is 0 then), and a careful
## player spends its ten plates mostly on what is brought in rotation - so the first one brought ends up
## with the most photos (measured 30.6% of 320 careful photos for whichever came first, round 1). The
## order therefore turns one step each day: over a week of safaris no creature is always first.
func _bringers() -> Array:
	var out: Array = [
		{"id": "ice_seal", "bring": _bring_seal, "ready": func() -> bool: return _free_scout("seal") >= 0},
		{"id": "chime_bird", "bring": _bring_bird, "ready": func() -> bool: return _free_scout("bird") >= 0},
		{"id": "snow_mite", "bring": _bring_mite, "ready": func() -> bool: return _free_scout("mite") >= 0},
	]
	if safari.is_night:
		out.append({"id": "star_krill", "bring": _bring_krill, "ready": func() -> bool: return _free_scout("krill") >= 0})
	var r := posmod(safari.day, out.size())
	return out.slice(r) + out.slice(0, r)


func _find_places() -> void:
	var p := safari.planet
	_pad_dir = p.data.pad_dir.normalized() if p.data != null else safari.start_dir
	var sum := Vector3.ZERO
	for i in MAST_N:
		var n := p.get_node_or_null("Props/RelayMast%d" % i) as Node3D
		if n == null:
			_masts.append({})
			continue
		var b := n.global_transform.basis.orthonormalized()
		var arm := MAST_H * (0.56 + 0.03 * float((i + 1) % 3)) + 0.035
		_masts.append({"node": n, "dir": p.dir_of(n.global_position), "up": b.y, "x": b.x,
			"lamp": n.global_transform * Vector3(0.0, MAST_H, 0.0), "arm": arm, "base": n.global_position})
		sum += p.dir_of(n.global_position)
	_array_mid = sum.normalized() if sum.length() > 0.01 else safari.dir_from_start(44.0, 100.0)
	for f: Vector2 in P_FLOES:
		_floes.append(_free_near(safari.dir_from_start(f.x, f.y), FLOE_R + 0.4))
	var m0: Dictionary = _masts[0]
	var anti: Vector3 = -(m0["dir"] as Vector3) if not m0.is_empty() else safari.dir_from_start(120.0, -106.0)
	_mirror_dir = _free_near(anti, FIELD_R + 0.4)
	for d: Vector2 in P_DUST:
		_dust_dirs.append(_free_near(safari.dir_from_start(d.x, d.y), 1.0))
	_vela = safari.world.get_node_or_null("NPCs/vela") as Node3D
	_home_dir = (_vela.get("home_dir") as Vector3).normalized() if _vela != null and _vela.get("home_dir") is Vector3 \
		else safari.dir_from_start(96.0, 129.0)


## Places where creatures are or will be (the pacing director keeps its bringing clear of them).
func _creature_places() -> Array:
	var p := safari.planet
	var out: Array = []
	for i: int in BIRD_MASTS:
		var m: Dictionary = _masts[i]
		if not m.is_empty():
			out.append(m["base"])
	for f: Vector3 in _floes:
		out.append(p.surface_point(f))
	if is_instance_valid(_vela):
		out.append(_vela.global_position)
	out.append(p.surface_point(_mirror_dir))
	for c: Array in [[_dust_dirs, DUST_RUNS, "at"]]:
		for run: Dictionary in c[1]:
			if safari.event_running(str(run["id"])):
				out.append(p.surface_point((c[0] as Array)[int(run["at"])]))
	for run: Dictionary in PING_RUNS:
		if safari.event_running(str(run["id"])):
			out.append((_masts[int(run["mast"])] as Dictionary).get("base", Vector3.ZERO))
	return out


# ---------------------------------------------------------------------------------------- floes
## A frosty floe (and the Mirror Field): a flat patch of pale ice laid ON the real terrain - a disc of
## rings x segments whose every vertex is the planet's own surface point lifted 3 cm.
func _ice_patch(label: String, centre: Vector3, r: float, ice: Color, rim: Color, lift: float = 0.03) -> MeshInstance3D:
	var p := safari.planet
	var origin := p.surface_point(centre)
	var t := _tangent_at(centre)
	var rings := 4
	var segs := 20
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wob := PackedFloat32Array()
	for k in segs:
		wob.append(1.0 + 0.12 * sin(float(k) * 1.7 + r) + 0.07 * sin(float(k) * 3.1))
	var dir_at := func(ri: int, k: int) -> Vector3:
		var rho := r * float(ri) / float(rings) * wob[k % segs]
		return _polar(centre, t, rad_to_deg(rho / p.radius), 360.0 * float(k) / float(segs))
	var pt := func(ri: int, k: int) -> Vector3:
		var d: Vector3 = dir_at.call(ri, k)
		return p.surface_point(d) + p.up_at(p.surface_point(d)) * lift - origin
	var col := func(ri: int) -> Color:
		return ice.lerp(rim, pow(float(ri) / float(rings), 2.0))
	for ri in rings:
		for k in segs:
			var a: Vector3 = pt.call(ri, k)
			var b: Vector3 = pt.call(ri, k + 1)
			var c: Vector3 = pt.call(ri + 1, k + 1)
			var d: Vector3 = pt.call(ri + 1, k)
			var ca: Color = col.call(ri)
			var cc: Color = col.call(ri + 1)
			var na: Vector3 = p.ground_normal(dir_at.call(ri, k))
			var nb: Vector3 = p.ground_normal(dir_at.call(ri, k + 1))
			var nc: Vector3 = p.ground_normal(dir_at.call(ri + 1, k + 1))
			var nd: Vector3 = p.ground_normal(dir_at.call(ri + 1, k))
			# wound CLOCKWISE seen from above (Godot's front face), checked against the ground normal
			var tri1: Array = [[a, ca, na], [c, cc, nc], [b, ca, nb]]
			var tri2: Array = [[a, ca, na], [d, cc, nd], [c, cc, nc]]
			if (c - a).cross(b - a).dot(na) > 0.0:
				tri1 = [tri1[0], tri1[2], tri1[1]]
				tri2 = [tri2[0], tri2[2], tri2[1]]
			for v: Array in tri1 + tri2:
				st.set_color(PlanetMeshKit._lin(v[1]))
				st.set_normal(v[2])
				st.add_vertex(v[0])
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = st.commit()
	mi.material_override = _prop_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = origin
	return mi


func _build_floes() -> void:
	for i in _floes.size():
		_ice_patch("Floe%d" % i, _floes[i], FLOE_R, Color("#a3b9cf"), Color("#8ea3bb"))


# ---------------------------------------------------------------------------------------- chime-birds
func _build_birds() -> void:
	var p := safari.planet
	var side := 1.0
	for i: int in BIRD_MASTS:
		var m: Dictionary = _masts[i]
		if m.is_empty():
			continue
		var perch: Vector3 = (m["node"] as Node3D).global_transform * Vector3(0.24 * side, m["arm"], 0.0)
		_birds.append({"scout": false, "mast": i, "perch": perch, "up": m["up"], "state": Bird.PERCH,
			"pos": perch, "face": (m["x"] as Vector3) * side, "from": perch, "to": perch, "timer": 0.0, "fly_t": 1.0,
			"sing": 0.0, "look": 0.0, "flap": 0.0, "phase": _rng.randf_range(0.0, TAU), "hello": 0.0, "shown": true})
		side = -side
	for k in BIRD_SCOUTS:
		_birds.append({"scout": true, "state": Bird.AWAY, "pos": p.surface_point(safari.start_dir) - p.up_at(p.surface_point(safari.start_dir)) * 50.0,
			"up": Vector3.UP, "face": safari.start_fwd, "from": Vector3.ZERO, "to": Vector3.ZERO, "timer": 0.0,
			"fly_t": 1.0, "sing": 0.0, "look": 0.0, "flap": 0.0, "phase": _rng.randf_range(0.0, TAU), "hello": 0.0,
			"out_since": -INF, "shown": false, "dir": safari.start_dir})
	_bird_herd = Herd.new()
	add_child(_bird_herd)
	_bird_herd.setup("ChimeBirds", _birds.size(), [[Meshes.chime_body(), _prop_mat, true],
		[Meshes.chime_wing(), _prop_mat, false], [Meshes.chime_wing(), _prop_mat, false]], _planet_box())
	_bird_focus = Node3D.new()
	_bird_focus.name = "BirdFocus"
	add_child(_bird_focus)
	_notes = _sparkles("SongNotes", 10, 0.9, Color(1.0, 0.86, 0.62, 0.55), 0.06)
	_notes.direction = Vector3.UP
	_notes.spread = 40.0
	_notes.initial_velocity_min = 0.5
	_notes.initial_velocity_max = 0.9
	_notes.gravity = Vector3(0.0, 0.2, 0.0)
	add_child(_notes)
	safari.add_subject({
		"id": "chime_bird", "name": "Chime-bird", "band": BAND_BIRD, "node": _bird_focus,
		"offset": Vector3(0.0, 0.14, 0.0), "radius": 0.16,
		"awake": func() -> bool: return _bird_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _bird_moment(),
		"front": func() -> Vector3: return _front_of(_bird_focus),
	})


func _bird_moment() -> Dictionary:
	if _bird_pick < 0:
		return {"mult": 1.0, "line": ""}
	var b: Dictionary = _birds[_bird_pick]
	if float(b["sing"]) > 0.0:
		return {"mult": 1.7, "line": "singing the call" if not bool(b["scout"]) else "singing to you"}
	if float(b["hello"]) > 0.0:
		return {"mult": 1.5, "line": "tilting its head at you"}
	if int(b["state"]) == Bird.FLY:
		return {"mult": 1.5, "line": "on the wing"}
	return {"mult": 1.0, "line": ""}


func _tick_birds(delta: float) -> void:
	if _bird_herd == null:
		return
	var ppos := safari.player.global_position
	var shy := pacing != null and pacing.shy("chime_bird")
	# the call-and-response: the perched birds sing in turn, mast to mast
	if _t >= _song_next and not _sleeping:
		var perched: Array = []
		for b: Dictionary in _birds:
			if not bool(b["scout"]) and int(b["state"]) == Bird.PERCH:
				perched.append(b)
		if not perched.is_empty():
			_song_i = (_song_i + 1) % perched.size()
			var sb: Dictionary = perched[_song_i]
			sb["sing"] = SONG_SEC
			_notes.global_position = sb["pos"] + (sb["up"] as Vector3) * 0.25
			_notes.restart()
			_notes.emitting = true
			if (sb["pos"] as Vector3).distance_to(ppos) < 18.0:
				AudioManager.play_sfx_at("doot_c_%d" % (_song_i % 4), sb["pos"], -6.0, 0.02)
		_song_next = _t + SONG_SEC + SONG_GAP
	for i in _birds.size():
		var b: Dictionary = _birds[i]
		b["sing"] = maxf(float(b["sing"]) - delta, 0.0)
		b["hello"] = maxf(float(b["hello"]) - delta, 0.0)
		b["timer"] = float(b["timer"]) - delta
		var st: int = b["state"]
		var pos: Vector3 = b["pos"]
		var dist := pos.distance_to(ppos)
		if _sleeping and st != Bird.AWAY and st != Bird.FLY:
			_bird_fly(b, _away_point(pos, b["up"]), Bird.AWAY)
			st = Bird.FLY
		match st:
			Bird.PERCH:
				b["flap"] = 0.0
				# looks about, or at you when you hold still with the camera up close by
				b["look"] = float(b["look"]) - delta
				var up: Vector3 = b["up"]
				if _still >= HELLO_STILL and dist < HELLO_M and float(b["sing"]) <= 0.0:
					var to := ppos - pos
					to -= up * to.dot(up)
					if to.length() > 0.01:
						b["face"] = (b["face"] as Vector3).slerp(to.normalized(), minf(delta * 4.0, 1.0)).normalized()
					if float(b["hello"]) <= 0.0 and _t >= float(b.get("hello_next", 0.0)):
						b["hello"] = HELLO_SEC
						b["hello_next"] = _t + HELLO_SEC + HELLO_REST
				elif float(b["look"]) <= 0.0:
					b["look"] = _rng.randf_range(0.8, 2.2)
					b["face"] = (b["face"] as Vector3).rotated(up, _rng.randf_range(-0.9, 0.9)).normalized()
				var leave := false
				if bool(b["scout"]):
					if _t - float(b["out_since"]) > SCOUT_OUT_MIN_SEC and not _in_frame(pos, 1.2):
						leave = true
					elif shy and not _in_frame(pos, 1.1):
						leave = true
				elif shy and not _in_frame(pos, 1.1):
					leave = true
				if leave:
					_bird_fly(b, _away_point(pos, b["up"]), Bird.AWAY)
			Bird.FLY:
				b["flap"] = float(b["flap"]) + delta * 16.0
				var f := clampf(1.0 - float(b["timer"]) / float(b["fly_t"]), 0.0, 1.0)
				var from: Vector3 = b["from"]
				var to: Vector3 = b["to"]
				var up: Vector3 = b["up"]
				var e := f * f * (3.0 - 2.0 * f)
				b["pos"] = from.lerp(to, e) + up * 0.6 * sin(f * PI) * (0.3 if int(b["next"]) != Bird.AWAY else 0.0)
				var dir := to - from
				dir -= up * dir.dot(up)
				if dir.length() > 0.05:
					b["face"] = (b["face"] as Vector3).slerp(dir.normalized(), minf(delta * 8.0, 1.0)).normalized()
				if float(b["timer"]) <= 0.0:
					b["pos"] = to
					b["state"] = b["next"]
					b["timer"] = float(b.get("next_timer", 0.0))
					if int(b["next"]) == Bird.AWAY:
						b["shown"] = false
					elif bool(b["scout"]):
						# a scout lands turned to you: it came to see you
						var tp := ppos - to
						tp -= up * tp.dot(up)
						if tp.length() > 0.01:
							b["face"] = tp.normalized()
			Bird.AWAY:
				b["flap"] = 0.0
				# a perched bird comes back once nothing new is holding it off (and never while asleep)
				if not bool(b["scout"]) and not shy and not _sleeping and float(b["timer"]) <= 0.0:
					var perch: Vector3 = b["perch"]
					b["shown"] = true
					b["pos"] = _away_point(perch, b["up"])
					_bird_fly(b, perch, Bird.PERCH)
					var m: Dictionary = _masts[int(b["mast"])]
					b["face"] = (m["x"] as Vector3) * (1.0 if (perch - (m["node"] as Node3D).global_position).dot(m["x"]) > 0.0 else -1.0)
		_pose_bird(i, b)
	_bird_pick = _pick_focus(_birds, func(b: Dictionary) -> bool: return bool(b["shown"]) and int(b["state"]) != Bird.AWAY,
		func(b: Dictionary) -> Vector3: return b["pos"], 0.14)
	if _bird_pick >= 0:
		_bird_focus.global_transform = _body_xf(_birds[_bird_pick])


func _bird_fly(b: Dictionary, to: Vector3, next: int, fly_t: float = BIRD_FLY_SEC, next_timer: float = 0.0) -> void:
	b["from"] = b["pos"]
	b["to"] = to
	b["state"] = Bird.FLY
	b["next"] = next
	b["timer"] = fly_t
	b["fly_t"] = fly_t
	b["next_timer"] = next_timer if next != Bird.AWAY else _rng.randf_range(4.0, 8.0)
	b["sing"] = 0.0
	if next == Bird.AWAY:
		b["perch_k"] = -1


## Up and away from `pos`: 6 m up and 4 m out, off the top of any view that holds it.
func _away_point(pos: Vector3, up: Vector3) -> Vector3:
	var out := up.cross(safari.start_fwd)
	if out.length() < 0.1:
		out = up.cross(Vector3.RIGHT)
	return pos + up * 6.0 + out.normalized() * 4.0


func _body_xf(b: Dictionary) -> Transform3D:
	var up: Vector3 = b["up"]
	var f: Vector3 = b["face"]
	f -= up * f.dot(up)
	if f.length() < 0.01:
		f = _tangent_at(safari.planet.dir_of(b["pos"]))
	return Transform3D(Basis.looking_at(f.normalized(), up), b["pos"])


func _pose_bird(i: int, b: Dictionary) -> void:
	if not bool(b["shown"]) or int(b["state"]) == Bird.AWAY:
		_bird_herd.hide_one(i)
		return
	var xf := _body_xf(b)
	var sing := float(b["sing"])
	if sing > 0.0:
		# sings with its head up and its chest puffed: a tilt back and a swell
		var k := sin(clampf(1.0 - sing / SONG_SEC, 0.0, 1.0) * PI)
		xf.basis = xf.basis * Basis(Vector3.RIGHT, 0.35 * k) * Basis.from_scale(Vector3.ONE * (1.0 + 0.12 * k))
	elif float(b["hello"]) > 0.0:
		xf.basis = xf.basis * Basis(Vector3.FORWARD, 0.3 * sin(float(b["hello"]) * 2.0))
	else:
		xf.basis = xf.basis * Basis.from_scale(Vector3(1.0, 1.0 + 0.03 * sin(_t * 3.0 + float(b["phase"])), 1.0))
	var flying := int(b["state"]) == Bird.FLY
	if flying:
		# in flight it leans into it, body level and head forward (upright in the air read as hanging there)
		xf.basis = xf.basis * Basis(Vector3.RIGHT, -0.55)
	_bird_herd.pose(i, 0, xf)
	var a := sin(float(b["flap"])) * 0.9 if flying else 0.0
	for side in [1, -1]:
		var w := xf * Transform3D(Basis(Vector3.FORWARD, (0.25 + a) * float(side) if flying else 1.35 * float(side)), Vector3(0.05 * float(side), 0.13, 0.0))
		if side < 0:
			w.basis = w.basis * Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
		if not flying:
			# folded: tucked flat along the body
			w = xf * Transform3D(Basis(Vector3.FORWARD, 1.45 * float(side)) * Basis(Vector3.UP, -0.25 * float(side)), Vector3(0.075 * float(side), 0.11, 0.0))
			if side < 0:
				w.basis = w.basis * Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
		_bird_herd.pose(i, 1 if side > 0 else 2, w)


## THE BIRDS BELONG ON THE MASTS (spec 16; builder VELAC). The director used to bring a scout bird down onto
## open snow, or - looking up - HOVERING in mid-air as high as a mast top: a bird in empty sky (the critic's
## frames, 2026-09-26). Round 1 of this fix then sent it FLYING OVER open sky instead, and the critic measured
## that it was still the same staging (28 of 32 careful chime-bird photos were of a bird crossing empty sky
## 1.9-3.4 m over the snow, five crossings a minute in a real watch): so there is no fly-over any more. A scout
## only ever comes to a MAST: it drops in from just over the arm (one second, the landing is "on the wing") and
## lands on a free cross-arm end (both arms of all eight masts, not the three home birds' perches nor the
## teacup's) that the lens WILL see - in the middle BIRD_PERCH_FRAME of the view, with a clear line to it,
## BIRD_PERCH_M from the lens (the wanderer's "recognisable" 5% of the frame is 7.7 m for a bird). With no
## mast arm like that in view it does NOT come: the director asks the next bringer, or waits. And while a
## brought bird is already out in the view it does not bring a second (a bird at 5-7 m is under the
## director's 8% "clearly in view", so the director would otherwise try again every RETRY_SEC).
func _bring_bird(spot: Dictionary) -> bool:
	var i := _free_scout("bird")
	if i < 0 or pacing == null:
		return false
	for ob: Dictionary in _birds:
		if bool(ob["scout"]) and int(ob["state"]) != Bird.AWAY and _in_frame(ob["pos"], 1.2):
			return false
	var lens: Transform3D = spot["lens"]
	var k := _perch_in_view(lens)
	if k < 0:
		return false
	var pc: Dictionary = _perches[k]
	var b: Dictionary = _birds[i]
	var perch: Vector3 = pc["pos"]
	var up: Vector3 = pc["up"]
	b["up"] = up
	b["perch_k"] = k
	b["dir"] = safari.planet.dir_of(perch)
	# in from over the top of the view, a little to one side
	b["pos"] = perch + up * 2.6 + lens.basis.x.normalized() * 1.8
	b["shown"] = true
	_bird_fly(b, perch, Bird.PERCH, 1.0)
	b["out_since"] = _t
	var to := lens.origin - perch
	to -= up * to.dot(up)
	b["face"] = to.normalized() if to.length() > 0.01 else (pc["x"] as Vector3)
	AudioManager.play_sfx_at("doot_c_2", perch, -8.0, 0.1)
	return true


## Every cross-arm end a scout may land on (built once, in _build_birds): {pos, up, x, mast, busy}.
var _perches: Array = []
const BIRD_PERCH_M := Vector2(1.8, 7.5)
const BIRD_PERCH_FRAME := 0.8


func _build_perches() -> void:
	for i in MAST_N:
		var m: Dictionary = _masts[i]
		if m.is_empty():
			continue
		var n := m["node"] as Node3D
		var arms := [[float(m["arm"]), 0.24], [_low_arm(i), 0.29]]
		for a: Array in arms:
			for side in [1.0, -1.0]:
				var pos: Vector3 = n.global_transform * Vector3(float(a[1]) * side, float(a[0]), 0.0)
				var taken := false
				for b: Dictionary in _birds:
					if not bool(b["scout"]) and (b["perch"] as Vector3).distance_to(pos) < 0.2:
						taken = true
				if _teacup_at != Vector3.ZERO and _teacup_at.distance_to(pos) < 0.2:
					taken = true
				if not taken:
					_perches.append({"pos": pos, "up": m["up"], "x": (m["x"] as Vector3) * side, "mast": i})


## The height of mast `i`'s LOWER cross-arm's top (planet_props.gd _relay_mast: a0 = h (0.34 + 0.04 (i % 3)),
## a beam 0.035 thick each way), in the mast's own frame.
func _low_arm(i: int) -> float:
	return MAST_H * (0.34 + 0.04 * float(i % 3)) + 0.04


## The free perch nearest the middle of the view `lens` will have (see _bring_bird), or -1.
func _perch_in_view(lens: Transform3D) -> int:
	if lens == Transform3D():
		return -1
	var fwd := -lens.basis.z
	var best := -1
	var best_s := INF
	for k in _perches.size():
		var pc: Dictionary = _perches[k]
		var busy := false
		for b: Dictionary in _birds:
			if bool(b["scout"]) and int(b["state"]) != Bird.AWAY and int(b.get("perch_k", -1)) == k:
				busy = true
		if busy:
			continue
		var q: Vector3 = (pc["pos"] as Vector3) + (pc["up"] as Vector3) * 0.14
		var dist := lens.origin.distance_to(q)
		if dist < BIRD_PERCH_M.x or dist > BIRD_PERCH_M.y:
			continue
		if not pacing.in_view_from(lens, q, BIRD_PERCH_FRAME) or not pacing.sight_clear(lens.origin, q):
			continue
		var s := rad_to_deg(fwd.angle_to((q - lens.origin).normalized())) + 0.5 * absf(dist - 3.5)
		if s < best_s:
			best_s = s
			best = k
	return best


# ---------------------------------------------------------------------------------------- ice-seals
func _build_seals() -> void:
	var p := safari.planet
	for fi in _floes.size():
		var c: Vector3 = _floes[fi]
		for k in SEAL_PER_FLOE:
			var t := _tangent_at(c)
			var d := _polar(c, t, rad_to_deg(0.8 / p.radius), 180.0 * float(k) + _rng.randf_range(-40.0, 40.0))
			var hole := _polar(c, t, rad_to_deg(1.35 / p.radius), 180.0 * float(k) + 90.0)
			_seals.append({"scout": false, "floe": fi, "dir": d, "hole": hole, "face": _tangent_at(d).rotated(d, _rng.randf_range(0.0, TAU)),
				"state": Seal.REST, "timer": _rng.randf_range(0.5, 3.0), "sink": 0.0, "clap": 0.0, "to": d,
				"phase": _rng.randf_range(0.0, TAU), "hello": 0.0, "hole_shown": true})
	for k in SEAL_SCOUTS:
		_seals.append({"scout": true, "floe": -1, "dir": safari.start_dir, "hole": safari.start_dir, "face": safari.start_fwd,
			"state": Seal.UNDER, "timer": 0.0, "sink": SEAL_SINK, "clap": 0.0, "to": safari.start_dir,
			"phase": _rng.randf_range(0.0, TAU), "hello": 0.0, "hole_shown": false, "out_since": -INF})
	_seal_herd = Herd.new()
	add_child(_seal_herd)
	_seal_herd.setup("IceSeals", _seals.size(), [[Meshes.seal_body(), _prop_mat, true],
		[Meshes.seal_flippers(), _prop_mat, false], [Meshes.seal_ice_hole(), _prop_mat, false]], _planet_box())
	_seal_focus = Node3D.new()
	_seal_focus.name = "SealFocus"
	add_child(_seal_focus)
	safari.add_subject({
		"id": "ice_seal", "name": "Ice-seal", "band": BAND_SEAL, "node": _seal_focus,
		"offset": Vector3(0.0, 0.22, -0.1), "radius": 0.4,
		"awake": func() -> bool: return _seal_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _seal_moment(),
		"front": func() -> Vector3: return _front_of(_seal_focus),
	})


func _seal_moment() -> Dictionary:
	if _seal_pick < 0:
		return {"mult": 1.0, "line": ""}
	var s: Dictionary = _seals[_seal_pick]
	match int(s["state"]):
		Seal.HELLO:
			return {"mult": 1.7, "line": "clapping for you"}
		Seal.CLAP:
			return {"mult": 1.6, "line": "mid-clap"}
		Seal.LEAP:
			return {"mult": 1.6, "line": "leaping out of its hole"}
		Seal.SLIDE:
			if float(s.get("push", 0.0)) > 0.8:
				return {"mult": 1.5, "line": "on a belly-slide"}
	return {"mult": 1.0, "line": ""}


func _tick_seals(delta: float) -> void:
	if _seal_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var shy := pacing != null and pacing.shy("ice_seal")
	var hello_i := -1
	if _still >= HELLO_STILL and _t >= _hello_next and not _sleeping:
		var best := HELLO_M
		for i in _seals.size():
			var sd: Dictionary = _seals[i]
			if int(sd["state"]) != Seal.REST:
				continue
			var dd := p.surface_point(sd["dir"]).distance_to(ppos)
			if dd < best:
				best = dd
				hello_i = i
	for i in _seals.size():
		var s: Dictionary = _seals[i]
		s["timer"] = float(s["timer"]) - delta
		var here := p.surface_point(s["dir"])
		var dist := here.distance_to(ppos)
		var st: int = s["state"]
		if _sleeping and st != Seal.UNDER and st != Seal.DIVE:
			_seal_dive(s)
			st = Seal.DIVE
		var out_ok := st == Seal.REST or st == Seal.SLIDE or st == Seal.CLAP
		if out_ok and not _sleeping:
			var leave := false
			if bool(s["scout"]):
				leave = (_t - float(s["out_since"]) > SCOUT_OUT_MIN_SEC and not _in_frame(here, 1.2)) \
					or (shy and not _in_frame(here, 1.1))
			else:
				leave = (shy and not _in_frame(here, 1.1)) or (dist < RUSH_M and speed > RUSH_SPEED)
			if leave:
				_seal_dive(s)
				st = Seal.DIVE
		match st:
			Seal.REST:
				s["clap"] = 0.0
				if i == hello_i:
					s["state"] = Seal.HELLO
					s["timer"] = HELLO_SEC
					_hello_next = _t + HELLO_SEC + HELLO_REST
				elif float(s["timer"]) <= 0.0:
					var r := _rng.randf()
					if r < 0.3:
						s["state"] = Seal.CLAP
						s["timer"] = 1.4
						if dist < 14.0:
							AudioManager.play_sfx_at("splash", here, -10.0, 0.2)
					elif not bool(s["scout"]):
						# slide to another spot on its floe
						var c: Vector3 = _floes[int(s["floe"])]
						s["to"] = _polar(c, _tangent_at(c), rad_to_deg(_rng.randf_range(0.2, 1.3) / p.radius), _rng.randf_range(0.0, 360.0))
						s["state"] = Seal.SLIDE
					else:
						s["timer"] = _rng.randf_range(1.5, 3.5)
						s["face"] = (s["face"] as Vector3).rotated(s["dir"], _rng.randf_range(-0.8, 0.8)).normalized()
			Seal.SLIDE:
				var to: Vector3 = s["to"]
				var d: Vector3 = s["dir"]
				var want := _toward(d, to)
				s["face"] = (s["face"] as Vector3).slerp(want, minf(delta * 3.0, 1.0)).normalized()
				# a push with the flippers, then a glide: speed pulses
				var push := 0.4 + 0.6 * maxf(0.0, sin(_t * 3.2 + float(s["phase"])))
				s["push"] = push
				if (s["face"] as Vector3).dot(want) > 0.7:
					s["dir"] = p.step_dir(d, to, SEAL_SLIDE_SPEED * push * delta)
				if p.surface_distance(s["dir"], to) < 0.1:
					s["state"] = Seal.REST
					s["timer"] = _rng.randf_range(2.0, 4.5)
			Seal.CLAP:
				s["clap"] = float(s["clap"]) + delta
				if float(s["timer"]) <= 0.0:
					s["state"] = Seal.REST
					s["timer"] = _rng.randf_range(1.5, 4.0)
			Seal.HELLO:
				s["clap"] = float(s["clap"]) + delta
				var want := _toward(s["dir"], p.dir_of(ppos))
				s["face"] = (s["face"] as Vector3).slerp(want, minf(delta * 4.0, 1.0)).normalized()
				if float(s["timer"]) <= 0.0:
					s["state"] = Seal.REST
					s["timer"] = _rng.randf_range(1.5, 3.0)
			Seal.DIVE:
				s["sink"] = minf(float(s["sink"]) + delta * 1.2, SEAL_SINK)
				if float(s["sink"]) >= SEAL_SINK:
					s["state"] = Seal.UNDER
					s["timer"] = _rng.randf_range(4.0, 8.0)
					if bool(s["scout"]):
						s["hole_shown"] = false
			Seal.UNDER:
				if not bool(s["scout"]) and not shy and not _sleeping and float(s["timer"]) <= 0.0 \
						and not (dist < RUSH_M + 1.0 and speed > RUSH_SPEED):
					s["dir"] = s["hole"]
					s["state"] = Seal.SURFACE
			Seal.LEAP:
				# bursts up out of the snow in an arc and flops down on its belly
				var lt := float(s["leap_t"])
				var f := clampf(1.0 - float(s["timer"]) / lt, 0.0, 1.0)
				s["sink"] = 0.0
				s["h"] = 4.0 * float(s["leap_h"]) * f * (1.0 - f)
				s["face"] = (s["face"] as Vector3).slerp(_toward(s["dir"], p.dir_of(ppos)), minf(delta * 4.0, 1.0)).normalized()
				if float(s["timer"]) <= 0.0:
					s["h"] = 0.0
					s["state"] = Seal.REST
					s["timer"] = _rng.randf_range(1.0, 2.0)
					if dist < 14.0:
						AudioManager.play_sfx_at("land", here, -8.0, 0.2)
			Seal.SURFACE:
				s["sink"] = maxf(float(s["sink"]) - delta * 1.1, 0.0)
				var want := _toward(s["dir"], p.dir_of(ppos))
				s["face"] = (s["face"] as Vector3).slerp(want, minf(delta * 3.0, 1.0)).normalized()
				if float(s["sink"]) <= 0.0:
					s["state"] = Seal.REST
					s["timer"] = _rng.randf_range(1.0, 2.5)
		_pose_seal(i, s)
	_seal_pick = _pick_focus(_seals, func(s: Dictionary) -> bool: return float(s["sink"]) < 0.25,
		func(s: Dictionary) -> Vector3: return (s["xf"] as Transform3D).origin if s.has("xf") else p.surface_point(s["dir"]), 0.25)
	if _seal_pick >= 0:
		_seal_focus.global_transform = _seals[_seal_pick]["xf"]


func _seal_dive(s: Dictionary) -> void:
	# back to its hole, then down it
	s["dir"] = s["hole"]
	s["state"] = Seal.DIVE
	s["clap"] = 0.0


func _pose_seal(i: int, s: Dictionary) -> void:
	var p := safari.planet
	var d: Vector3 = s["dir"]
	var xf := _xf_ground(d, s["face"])
	var sink := float(s["sink"])
	xf.origin -= xf.basis.y * sink
	xf.origin += xf.basis.y * float(s.get("h", 0.0))
	if int(s["state"]) == Seal.LEAP:
		var f := clampf(1.0 - float(s["timer"]) / float(s["leap_t"]), 0.0, 1.0)
		xf.basis = xf.basis * Basis(Vector3.RIGHT, lerpf(0.7, -0.5, f))
	if int(s["state"]) == Seal.SLIDE:
		# rocks a little as it pushes
		xf.basis = xf.basis * Basis(Vector3.FORWARD, 0.06 * sin(_t * 6.4 + float(s["phase"])))
	s["xf"] = xf
	if sink >= SEAL_SINK - 0.001:
		_seal_herd.hide_one(i)
	else:
		_seal_herd.pose(i, 0, xf)
		var fl := xf
		var c := float(s["clap"])
		if c > 0.0:
			# claps: the flippers swing in to meet in front of the chest, three times a second
			var k := absf(sin(c * PI * 3.0))
			fl = xf * Transform3D(Basis(Vector3.RIGHT, -0.5 * k) * Basis.from_scale(Vector3(lerpf(1.0, 0.35, k), 1.0, 1.0)), Vector3(0.0, 0.1 * k, -0.12 * k))
		_seal_herd.pose(i, 1, fl)
	if bool(s["hole_shown"]):
		# a brought seal's ice skin lies on bare snow, a little higher (a home seal's sits under its floe)
		var lift := 0.035 if bool(s["scout"]) else 0.01
		_seal_herd.pose(i, 2, _xf_ground(s["hole"], _tangent_at(s["hole"])).translated_local(Vector3(0.0, lift, 0.0)))
	else:
		_seal_herd.part_node(2).multimesh.set_instance_transform(i, Herd.ZERO)


## THE SEALS ON THE ICE (spec 16; builder VELAC). A brought seal used to pop up out of bare snow, or - looking
## over the snow - LEAP up to 2.3 m out of it into the middle of a raised view: a seal in empty sky (the
## critic's frames, 2026-09-26). Now every seal hole is a breathing hole in a skin of ICE (Meshes.
## seal_ice_hole, the herd's third part), and a scout comes up through one only where that ice will be IN THE
## FRAME: on the director's ground spot (in view by its own test), or - looking a little over the snow - a
## short hop out of a hole on a spot ahead whose ice is inside the frame (it rises at most SEAL_HOP_RISE over
## the director's 0.3 m, so the arc tops out at SEAL_HOP_RISE + 0.35 m with the hole in the picture).
## Anything higher and it does not come: the director asks the next bringer.
## A SECOND SUBJECT FOR THE RAISED VIEWS (spec 17.3 ruling 5): the seal may rise as high as the snow-mite
## (MITE_RISE_MAX, the hole still in the frame), so a view a little over the snow is no longer the mite's
## alone. It was 0.45 against the mite's 0.6, and the mite took 0.416 of careful photos (PACE r2) and 9 of 24
## in this builder's first three Vela safaris (PLANETS, 2026-09-27; the new -14..+4 test-player drift).
const SEAL_HOP_RISE := MITE_RISE_MAX


func _bring_seal(spot: Dictionary) -> bool:
	if _free_scout("seal") < 0 or pacing == null:
		return false
	var d: Vector3 = spot["dir"]
	var leap := 0.0
	var lens: Transform3D = spot["lens"]
	if d == Vector3.ZERO:
		var s2 := _more_ways(spot, SEAL_HOP_RISE)
		var a: Vector3 = s2["ahead"]
		if a == Vector3.ZERO or float(s2["rise"]) < 0.0 or float(s2["rise"]) > SEAL_HOP_RISE + 0.001:
			return false
		# the hole and its ice must be in the picture, not below it
		var g := safari.planet.surface_point(a)
		if not pacing.in_view_from(lens, g + safari.planet.up_at(g) * 0.03, 0.95):
			return false
		d = a
		leap = float(s2["rise"]) + 0.35
	if _near_extra(d, EXTRA_CLEAR_M):
		return false
	var i := _free_scout("seal")
	if i < 0:
		return false
	var s: Dictionary = _seals[i]
	s["dir"] = d
	s["hole"] = d
	s["hole_shown"] = true
	s["h"] = 0.0
	if leap > 0.0:
		s["sink"] = 0.0
		s["state"] = Seal.LEAP
		s["leap_h"] = leap
		s["leap_t"] = 0.5 + 0.45 * sqrt(leap)
		s["timer"] = s["leap_t"]
	else:
		s["sink"] = SEAL_SINK
		s["state"] = Seal.SURFACE
	s["out_since"] = _t
	s["face"] = _toward(d, _player_dir())
	safari.puff_at(safari.planet.surface_point(d) + safari.planet.up_at(safari.planet.surface_point(d)) * 0.2, 12, Color("#dfe6ee"))
	AudioManager.play_sfx_at("splash", safari.planet.surface_point(d), -6.0, 0.1)
	return true


# ---------------------------------------------------------------------------------------- snow-mites
func _build_mites() -> void:
	for k in MITE_SCOUTS:
		_mites.append({"scout": true, "dir": safari.start_dir, "face": safari.start_fwd, "state": Mite.GONE,
			"timer": 0.0, "sink": MITE_SINK, "h": 0.0, "sq": 1.0, "from": safari.start_dir, "to": safari.start_dir,
			"air_h": MITE_HOP_H, "air_t": MITE_AIR_SEC, "big": 0.0, "look": 0.0, "phase": _rng.randf_range(0.0, TAU),
			"out_since": -INF, "next_big": 0.0})
	_mite_herd = Herd.new()
	add_child(_mite_herd)
	_mite_herd.setup("SnowMites", _mites.size(), [[Meshes.mite(), _prop_mat, true]], _planet_box())
	_mite_focus = Node3D.new()
	_mite_focus.name = "MiteFocus"
	add_child(_mite_focus)
	safari.add_subject({
		"id": "snow_mite", "name": "Snow-mite", "band": BAND_MITE, "node": _mite_focus,
		"offset": Vector3(0.0, 0.13, 0.0), "radius": 0.15,
		"awake": func() -> bool: return _mite_pick >= 0,
		"moment": func(_tt: float) -> Dictionary: return _mite_moment(),
		"front": func() -> Vector3: return _front_of(_mite_focus),
	})


func _mite_moment() -> Dictionary:
	if _mite_pick < 0:
		return {"mult": 1.0, "line": ""}
	var m: Dictionary = _mites[_mite_pick]
	match int(m["state"]):
		Mite.HELLO:
			return {"mult": 1.6, "line": "bouncing hello"}
		Mite.AIR:
			# only the big bounce up into your view is a moment; its ordinary little hops are not
			var f := 1.0 - float(m["timer"]) / float(m["air_t"])
			if f > 0.2 and f < 0.8 and float(m["air_h"]) > 0.5:
				return {"mult": 1.5, "line": "a big bounce"}
		Mite.POP:
			return {"mult": 1.4, "line": "popping out of the snow"}
	return {"mult": 1.0, "line": ""}


func _tick_mites(delta: float) -> void:
	if _mite_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var shy := pacing != null and pacing.shy("snow_mite")
	var in_view := pacing == null or pacing.in_view
	for i in _mites.size():
		var m: Dictionary = _mites[i]
		m["timer"] = float(m["timer"]) - delta
		var here := p.surface_point(m["dir"])
		var dist := here.distance_to(ppos)
		var st: int = m["state"]
		if _sleeping and st != Mite.GONE and st != Mite.AIR:
			m["state"] = Mite.GONE
			st = Mite.GONE
		match st:
			Mite.SIT:
				m["h"] = 0.0
				m["look"] = float(m["look"]) + delta
				if float(m["look"]) > 1.0:
					m["look"] = 0.0
					m["face"] = (m["face"] as Vector3).rotated(m["dir"], _rng.randf_range(-0.8, 0.8)).normalized()
				m["sq"] = 1.0 + 0.04 * sin(_t * 4.0 + float(m["phase"]))
				if _t - float(m["out_since"]) > SCOUT_OUT_MIN_SEC and not _in_frame(here, 1.2):
					m["state"] = Mite.GONE
				elif shy and not _in_frame(here, 1.1):
					m["state"] = Mite.GONE
				elif _t - float(m["out_since"]) < SCOUT_OUT_MIN_SEC and not in_view and _t >= float(m["next_big"]) \
						and dist < SCOUT_DOWN_M + 1.0 and pacing != null:
					# "look at me": you look over it, so it bounces up into your view
					m["next_big"] = _t + 1.6
					var h := pacing.rise_into_view(m["dir"], pacing.lens_soon(0.6))
					if h > 0.0 and h <= MITE_RISE_MAX + 0.001:
						_mite_hop(m, m["dir"], h + 0.3, sqrt((h + 0.3) / MITE_HOP_H) * MITE_AIR_SEC)
				elif _still >= HELLO_STILL and dist < HELLO_M and _t >= _hello_next:
					m["state"] = Mite.HELLO
					m["timer"] = HELLO_SEC
					_hello_next = _t + HELLO_SEC + HELLO_REST
					AudioManager.play_sfx_at("ui_tick", here, -10.0, 0.2)
				elif dist < RUSH_M and speed > RUSH_SPEED:
					var away := -_toward(m["dir"], p.dir_of(ppos))
					_mite_hop(m, _polar(m["dir"], away, rad_to_deg(MITE_HOP_M.y / p.radius), 0.0), MITE_HOP_H, MITE_AIR_SEC)
				elif float(m["timer"]) <= 0.0:
					var yaw := _rng.randf_range(0.0, 360.0)
					var to := _polar(m["dir"], _tangent_at(m["dir"]), rad_to_deg(_rng.randf_range(MITE_HOP_M.x, MITE_HOP_M.y) / p.radius), yaw)
					if p.nearest_prop_distance(to) > 0.45:
						_mite_hop(m, to, MITE_HOP_H, MITE_AIR_SEC)
					else:
						m["timer"] = 0.5
			Mite.CROUCH:
				m["sq"] = lerpf(1.0, 0.6, clampf(1.0 - float(m["timer"]) / 0.14, 0.0, 1.0))
				var want := _toward(m["dir"], m["to"])
				if p.surface_distance(m["dir"], m["to"]) > 0.05:
					m["face"] = (m["face"] as Vector3).slerp(want, minf(delta * 12.0, 1.0)).normalized()
				if float(m["timer"]) <= 0.0:
					m["state"] = Mite.AIR
					m["timer"] = float(m["air_t"])
					if dist < 6.0:
						AudioManager.play_sfx_at("jump", here, -18.0, 0.3)
			Mite.AIR:
				var f := clampf(1.0 - float(m["timer"]) / float(m["air_t"]), 0.0, 1.0)
				m["dir"] = (m["from"] as Vector3).slerp(m["to"], f).normalized()
				m["h"] = 4.0 * float(m["air_h"]) * f * (1.0 - f)
				m["sq"] = lerpf(1.3, 1.0, f)
				if float(m["timer"]) <= 0.0:
					m["dir"] = m["to"]
					m["h"] = 0.0
					m["state"] = Mite.LAND
					m["timer"] = 0.16
			Mite.LAND:
				m["sq"] = lerpf(0.6, 1.0, clampf(1.0 - float(m["timer"]) / 0.16, 0.0, 1.0))
				if float(m["timer"]) <= 0.0:
					m["state"] = Mite.SIT
					m["timer"] = _rng.randf_range(0.8, 2.8)
			Mite.HELLO:
				m["face"] = (m["face"] as Vector3).slerp(_toward(m["dir"], p.dir_of(ppos)), minf(delta * 6.0, 1.0)).normalized()
				var bnc := absf(sin((HELLO_SEC - float(m["timer"])) * 7.5))
				m["h"] = 0.07 * bnc
				m["sq"] = lerpf(0.78, 1.15, bnc)
				if float(m["timer"]) <= 0.0 or (dist < RUSH_M and speed > RUSH_SPEED):
					m["h"] = 0.0
					m["state"] = Mite.SIT
					m["timer"] = _rng.randf_range(0.8, 2.0)
			Mite.GONE:
				m["sink"] = minf(float(m["sink"]) + delta * 1.0, MITE_SINK)
				m["h"] = 0.0
				m["sq"] = 0.6
			Mite.POP:
				var f := clampf(1.0 - float(m["timer"]) / MITE_POP_SEC, 0.0, 1.0)
				m["sink"] = MITE_SINK * (1.0 - f)
				m["h"] = 0.18 * sin(f * PI)
				m["sq"] = lerpf(1.35, 1.0, f)
				m["face"] = (m["face"] as Vector3).slerp(_toward(m["dir"], p.dir_of(ppos)), minf(delta * 10.0, 1.0)).normalized()
				if float(m["timer"]) <= 0.0:
					m["sink"] = 0.0
					m["h"] = 0.0
					m["state"] = Mite.LAND
					m["timer"] = 0.16
					if float(m["big"]) > 0.0:
						_mite_hop(m, m["dir"], float(m["big"]), sqrt(float(m["big"]) / MITE_HOP_H) * MITE_AIR_SEC)
					m["big"] = 0.0
		_pose_mite(i, m)
	_mite_pick = _pick_focus(_mites, func(m: Dictionary) -> bool: return float(m["sink"]) < 0.12,
		func(m: Dictionary) -> Vector3: return (m["xf"] as Transform3D).origin if m.has("xf") else p.surface_point(m["dir"]), 0.12)
	if _mite_pick >= 0 and _mites[_mite_pick].has("xf"):
		var xf: Transform3D = _mites[_mite_pick]["xf"]
		_mite_focus.global_transform = Transform3D(xf.basis.orthonormalized(), xf.origin)


func _mite_hop(m: Dictionary, to: Vector3, h: float, air_t: float) -> void:
	m["from"] = m["dir"]
	m["to"] = to
	m["air_h"] = h
	m["air_t"] = air_t
	m["state"] = Mite.CROUCH
	m["timer"] = 0.14


func _pose_mite(i: int, m: Dictionary) -> void:
	var d: Vector3 = m["dir"]
	var xf := _xf_ground(d, m["face"])
	var sink := float(m["sink"])
	if sink >= MITE_SINK - 0.001:
		_mite_herd.hide_one(i)
		m["xf"] = xf
		return
	xf.origin += xf.basis.y * (float(m["h"]) - sink)
	var sq := float(m["sq"])
	var w := 1.0 / sqrt(maxf(sq, 0.2))
	var posed := Transform3D(xf.basis * Basis.from_scale(Vector3(w, sq, w)), xf.origin)
	m["xf"] = xf
	_mite_herd.pose(i, 0, posed)


## A SNOW-MITE STAYS NEAR THE SNOW (VELAC, with THE STAGING): its big bounce up into a raised view rises at
## most MITE_RISE_MAX over the director's 0.3 m (an arc of at most MITE_RISE_MAX + 0.35 m; it was the
## director's 1.85 m, a 2.2 m leap). Looking higher than that is sky, and nothing is brought into it (a chime-bird
## comes only onto a mast in view). (Measured with the bird pass in and the 1.85 m bounce kept: snow-mites were 21 of 66 careful
## photos, 0.32, over spec 14.2's 30% - the mite was the one creature that could come in every view.)
const MITE_RISE_MAX := 0.6


func _bring_mite(spot: Dictionary) -> bool:
	var i := _free_scout("mite")
	if i < 0:
		return false
	spot = _more_ways(spot, MITE_RISE_MAX)
	var m: Dictionary = _mites[i]
	var d: Vector3 = spot["dir"]
	var big := 0.0
	if d == Vector3.ZERO:
		d = spot["ahead"]
		if d == Vector3.ZERO or float(spot["rise"]) < 0.0 or float(spot["rise"]) > MITE_RISE_MAX + 0.001:
			return false
		big = float(spot["rise"]) + 0.35
	if _near_extra(d, EXTRA_CLEAR_M):
		return false
	m["dir"] = d
	m["from"] = d
	m["to"] = d
	m["big"] = big
	m["state"] = Mite.POP
	m["timer"] = MITE_POP_SEC
	m["out_since"] = _t
	m["next_big"] = _t + MITE_POP_SEC + 1.6
	m["face"] = _toward(d, _player_dir())
	var g := safari.planet.surface_point(d)
	safari.puff_at(g + safari.planet.up_at(g) * 0.1, 10, Color("#dfe6ee"))
	AudioManager.play_sfx_at("jump", g, -8.0, 0.2)
	return true


# ---------------------------------------------------------------------------------------- Vela
func _build_vela() -> void:
	if _vela == null:
		return
	_vela_saved = _vela.global_transform
	_vela_wander_saved = bool(_vela.get("_wander_on")) if _vela.get("_wander_on") != null else true
	# SHE KEEPS WATCH AT THE ARRAY for the three minutes (behind the black fade): her home is 96 degrees
	# from the pad, so a visitor starting at the pad met her in 2% of a careful player's photos - and the
	# director's three creatures then made up the rest, one of them over spec 13.2's 30%. At the Long
	# Array she is the pad's neighbour, and her calls go up where the array can answer. She potters
	# about her station; wandering off home is paused, and she is put back exactly where she stood (her
	# wandering as it was) when this node leaves.
	_vela_station = _find_station()
	if _vela_station != Vector3.ZERO:
		if _vela.has_method("wander_enabled"):
			_vela.call("wander_enabled", false)
		(_vela as PlanetBody).place_on_planet(_vela_station, _toward(_vela_station, safari.start_dir))
		_vela_next_potter = 4.0
	safari.add_subject({
		"id": "vela", "name": "Vela", "band": BAND_VELA, "node": _vela, "offset": Vector3(0.0, 0.8, 0.0), "radius": 0.8,
		# While she calls she IS Vela's Call (that subject scores her, with her front): one subject, not two.
		"awake": func() -> bool: return is_instance_valid(_vela) and _vela.is_visible_in_tree() and not _vela_borrowed,
		"moment": func(_tt: float) -> Dictionary:
			if _t < _vela_pose_until:
				return {"mult": 1.8, "line": "lamps up for the camera"}
			if _t < _vela_wave_until:
				return {"mult": 1.6, "line": "waving at you"}
			return {"mult": 1.0, "line": ""},
		"front": func() -> Vector3: return _front_of(_vela),
	})


func _tick_vela() -> void:
	if _vela == null or not is_instance_valid(_vela) or _sleeping or _building:
		return
	var run := _run_at(CALL_RUNS, _t, true)
	if not run.is_empty():
		if not _vela_borrowed:
			_borrow_vela()
		var t0 := float(run["start"])
		var sky := _vela.global_position + safari.planet.up_at(_vela.global_position) * 30.0 \
			+ (safari.planet.surface_point(_array_mid) - _vela.global_position).normalized() * 12.0
		_vela.call("hold_facing", sky)
		_call_focus.global_transform = _vela.global_transform
		if _t >= t0 and _t >= _call_voice_next and _t < t0 + CALL_ANSWER.x:
			_call_voice_next = _t + 0.9
			AudioManager.play_sfx_at("doot_a_%d" % (int(_t) % 4), _vela.global_position, 0.0, 0.05)
		return
	if _vela_borrowed:
		_release_vela(false)
		_vela.call("play_emote", "happy")
		_vela_pose_until = _t + 1.6
	var pl := safari.player
	var dist := _vela.global_position.distance_to(pl.global_position)
	if _vela_station != Vector3.ZERO and _t >= _vela_next_potter and not safari.camera_up:
		# potters about her station: a few steps to look at a mast, then another
		_vela_next_potter = _t + _rng.randf_range(8.0, 14.0)
		var to := _polar(_vela_station, _tangent_at(_vela_station), rad_to_deg(_rng.randf_range(0.5, VELA_POTTER_M) / safari.planet.radius), _rng.randf_range(0.0, 360.0))
		if safari.planet.nearest_prop_distance(to) >= 0.9:
			_vela.call("stroll_to", to)
	if dist < 4.0 and _t >= _vela_next_wave:
		_vela.call("face_player", true)
		_vela.call("play_emote", "wave")
		_vela_wave_until = _t + 1.6
		_vela_next_wave = _t + 7.0
	if safari.camera_up and _still >= HELLO_STILL and dist < 8.0 and _t >= _vela_next_pose:
		var cam := safari.rig.get_view_camera()
		if cam != null:
			var to := (_vela.global_position + safari.planet.up_at(_vela.global_position) * 0.8 - cam.global_position).normalized()
			if to.dot(-cam.global_transform.basis.z) > cos(deg_to_rad(10.0)):
				_vela.call("face_player", true)
				_vela.call("play_emote", "happy")
				_vela_pose_until = _t + 1.8
				_vela_next_pose = _t + 6.0
				_vela_next_wave = maxf(_vela_next_wave, _t + 3.0)


## A clear spot on the walk side of the Long Array, VELA_STATION_M in from its middle masts toward the
## pad, at least 1.2 m from every prop.
const VELA_STATION_M := 2.6
const VELA_POTTER_M := 2.2
var _vela_station := Vector3.ZERO
var _vela_next_potter := 0.0


func _find_station() -> Vector3:
	var p := safari.planet
	for i: int in [3, 4, 2, 5]:
		var m: Dictionary = _masts[i]
		if m.is_empty():
			continue
		var d := p.step_dir(m["dir"], safari.start_dir, VELA_STATION_M)
		var free := _free_near(d, 1.2)
		if p.nearest_prop_distance(free) >= 1.2:
			return free
	return Vector3.ZERO


func _borrow_vela() -> void:
	_vela_borrowed = true
	if _vela.has_method("wander_enabled"):
		_vela.call("wander_enabled", false)
	if _vela is CharacterBody3D:
		(_vela as CharacterBody3D).velocity = Vector3.ZERO
	_vela.call("play_emote", "wave")
	_queue_line("Vela: \"Excuse me a moment. I am going to call the sky.\"")
	AudioManager.play_sfx("doot_a_1", -4.0)


## Gives Vela back to her own script. `home` also puts her back where she stood before the safari.
func _release_vela(home: bool) -> void:
	if _vela == null or not is_instance_valid(_vela):
		return
	if _vela_borrowed:
		if _vela.has_method("release_facing"):
			_vela.call("release_facing")
		if _vela.has_method("wander_enabled") and (home or _vela_station == Vector3.ZERO):
			_vela.call("wander_enabled", _vela_wander_saved)
	_vela_borrowed = false
	if home:
		if _vela.has_method("wander_enabled"):
			_vela.call("wander_enabled", _vela_wander_saved)
		_vela.global_transform = _vela_saved
		if _vela is CharacterBody3D:
			(_vela as CharacterBody3D).velocity = Vector3.ZERO


# ---------------------------------------------------------------------------------------- lamps: ping and call
func _build_lamps() -> void:
	for i in MAST_N:
		var f := MeshInstance3D.new()
		f.name = "Flare%d" % i
		var q := QuadMesh.new()
		q.size = Vector2(1.1, 1.1)
		f.mesh = q
		f.material_override = MaterialLib.glow_sprite(Color("#e0b27a"), 2.0, {"softness": 0.0, "core": 0.18}).duplicate() as ShaderMaterial
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		f.visible = false
		add_child(f)
		var m: Dictionary = _masts[i]
		if not m.is_empty():
			f.global_position = (m["lamp"] as Vector3) + (m["up"] as Vector3) * 0.08
		_flares.append(f)
	_ring_mat = _add_mat.duplicate() as StandardMaterial3D
	_ring = MeshInstance3D.new()
	_ring.name = "PingRing"
	_ring.mesh = Meshes.ring()
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)
	_ping_focus = Node3D.new()
	_ping_focus.name = "PingFocus"
	add_child(_ping_focus)
	safari.add_subject({
		"id": "mast_ping", "name": "Mast Ping", "band": BAND_PING, "node": _ping_focus, "radius": 1.2,
		"awake": func() -> bool: return _any_running(PING_RUNS),
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(PING_RUNS, _t, false)
			var best: Vector2 = run.get("best", Vector2.ZERO)
			if not run.is_empty() and _t >= best.x and _t < best.y and _t - _ping_last < 1.2:
				return {"mult": 1.9, "line": "sending out its ring"}
			return {"mult": 1.0, "line": ""},
	})
	_call_mat = _add_mat.duplicate() as StandardMaterial3D
	_call_rings = MeshInstance3D.new()
	_call_rings.name = "CallRing"
	_call_rings.mesh = Meshes.ring()
	_call_rings.material_override = _call_mat
	_call_rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_call_rings.visible = false
	add_child(_call_rings)
	_call_focus = Node3D.new()
	_call_focus.name = "CallFocus"
	add_child(_call_focus)
	if _vela != null:
		safari.add_subject({
			"id": "vela_call", "name": "Vela's Call", "band": BAND_CALL, "node": _call_focus,
			"offset": Vector3(0.0, 1.0, 0.0), "radius": 1.1,
			"awake": func() -> bool: return _any_running(CALL_RUNS),
			"moment": func(_tt: float) -> Dictionary:
				var run := _run_at(CALL_RUNS, _t, false)
				if not run.is_empty():
					var k := _t - float(run["start"])
					if k >= CALL_ANSWER.x and k < CALL_ANSWER.y:
						return {"mult": 2.0, "line": "the array answering her"}
				return {"mult": 1.0, "line": ""},
			"front": func() -> Vector3: return _front_of(_vela),
		})


func _tick_lamps(delta: float) -> void:
	var lit := PackedFloat32Array()
	lit.resize(MAST_N)
	# ---- Mast Ping: its lamp gathers itself through the warning, then flares with a ring every PING_EVERY
	var run := _run_at(PING_RUNS, _t, true)
	if not run.is_empty() and not _sleeping:
		var mi := int(run["mast"])
		var m: Dictionary = _masts[mi]
		if not m.is_empty():
			_ping_mast = mi
			_ping_focus.global_position = (m["lamp"] as Vector3) - (m["up"] as Vector3) * 0.3
			var t0 := float(run["start"])
			if _t < t0:
				lit[mi] = 0.25 + 0.35 * (1.0 - (t0 - _t) / WARN) * (0.6 + 0.4 * sin(_t * 5.0))
			else:
				var k := fmod(_t - t0, PING_EVERY)
				if k < delta + 0.0001 or _t - _ping_last >= PING_EVERY:
					_ping_last = _t
					_ring.global_transform = Transform3D(Basis.looking_at(_tangent_at(safari.planet.dir_of(m["lamp"])), m["up"]), m["lamp"])
					if (m["lamp"] as Vector3).distance_to(safari.player.global_position) < 26.0:
						_sound_once("skiff_reveal", 1.35, -8.0).play()
				var rk := clampf((_t - _ping_last) / PING_RING_SEC, 0.0, 1.0)
				lit[mi] = maxf(1.0 - rk * 0.7, 0.3)
				_ring.visible = rk < 1.0
				if _ring.visible:
					var rad := lerpf(0.25, PING_RING_M, 1.0 - pow(1.0 - rk, 2.0))
					var xf := _ring.global_transform
					xf.basis = xf.basis.orthonormalized() * Basis.from_scale(Vector3(rad, 1.0, rad))
					_ring.global_transform = xf
					_ring_mat.albedo_color = Color(1.0, 0.82, 0.55, 0.85 * (1.0 - rk))
	else:
		_ring.visible = false
		_ping_mast = -1
	# ---- Vela's Call: rings rise from her while she calls; the array answers lamp by lamp
	var crun := _run_at(CALL_RUNS, _t, false)
	if not crun.is_empty() and not _sleeping and is_instance_valid(_vela):
		var k := _t - float(crun["start"])
		var up := safari.planet.up_at(_vela.global_position)
		var rk := fmod(k, 1.1) / 1.1
		_call_rings.visible = k < CALL_ANSWER.y + 1.0
		if _call_rings.visible:
			var tng := _tangent_at(safari.planet.dir_of(_vela.global_position))
			var rad := lerpf(0.3, 1.1, rk)
			_call_rings.global_transform = Transform3D(Basis.looking_at(tng, up).orthonormalized() * Basis.from_scale(Vector3(rad, 1.0, rad)),
				_vela.global_position + up * (1.2 + 1.6 * rk))
			_call_mat.albedo_color = Color(1.0, 0.85, 0.6, 0.8 * (1.0 - rk))
		if k >= CALL_ANSWER.x and k < CALL_ANSWER.y:
			# the answer runs down the array and back: each lamp flares as the wave passes it
			var wave := (k - CALL_ANSWER.x) / (CALL_ANSWER.y - CALL_ANSWER.x) * 2.0
			for i in MAST_N:
				var pos := float(i) / float(MAST_N - 1)
				var w := wave if wave <= 1.0 else 2.0 - wave
				lit[i] = maxf(lit[i], clampf(1.0 - absf(w - pos) * 4.0, 0.0, 1.0))
			var step := int(wave * float(MAST_N))
			if step != _call_step:
				_call_step = step
				var mm: Dictionary = _masts[clampi(step if wave <= 1.0 else 2 * MAST_N - step - 1, 0, MAST_N - 1)]
				if not mm.is_empty() and (mm["lamp"] as Vector3).distance_to(safari.player.global_position) < 30.0:
					AudioManager.play_sfx_at("doot_c_%d" % (step % 4), mm["lamp"], -6.0, 0.0)
	else:
		_call_rings.visible = false
	# ---- the aurora's flare wakes the lamps faintly too
	for i in MAST_N:
		var f := _flares[i]
		f.visible = lit[i] > 0.02
		if f.visible:
			(f.material_override as ShaderMaterial).set_shader_parameter("fade", lit[i])


# ---------------------------------------------------------------------------------------- diamond dust
func _build_dust() -> void:
	_dust_root = Node3D.new()
	_dust_root.name = "DiamondDust"
	add_child(_dust_root)
	_dust_fall = _sparkles("DustFall", 90, 5.0, Color(1.0, 1.0, 1.0, 0.5), 0.07)
	_dust_fall.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust_fall.emission_sphere_radius = 1.8
	_dust_fall.position = Vector3(0.0, 2.6, 0.0)
	_dust_fall.direction = Vector3.DOWN
	_dust_fall.spread = 25.0
	_dust_fall.initial_velocity_min = 0.25
	_dust_fall.initial_velocity_max = 0.6
	_dust_fall.gravity = Vector3(0.0, -0.08, 0.0)
	_dust_root.add_child(_dust_fall)
	# the thick fall, only while the sun catches it (CPUParticles3D has no amount_ratio in 4.7)
	_dust_heavy = _dust_fall.duplicate() as CPUParticles3D
	_dust_heavy.name = "DustHeavy"
	_dust_heavy.amount = 110
	_dust_heavy.emitting = false
	_dust_root.add_child(_dust_heavy)
	_dust_glint = _sparkles("DustGlint", 14, 1.6, Color(1.0, 0.97, 0.9, 0.8), 0.22)
	_dust_glint.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust_glint.emission_sphere_radius = 1.6
	_dust_glint.position = Vector3(0.0, 1.6, 0.0)
	_dust_glint.gravity = Vector3.ZERO
	_dust_glint.initial_velocity_max = 0.1
	_dust_root.add_child(_dust_glint)
	var focus := Node3D.new()
	focus.name = "DustFocus"
	focus.position = Vector3(0.0, 1.5, 0.0)
	_dust_root.add_child(focus)
	_move_dust(0)
	safari.add_subject({
		"id": "diamond_dust", "name": "Diamond Dust Shower", "band": BAND_DUST, "node": focus, "radius": 2.2,
		"awake": func() -> bool: return _any_running(DUST_RUNS),
		"moment": func(_tt: float) -> Dictionary:
			var run := _run_at(DUST_RUNS, _t, false)
			if not run.is_empty():
				var k := _t - float(run["start"])
				if k >= DUST_THICK_AT and k < DUST_THICK_AT + DUST_THICK_SEC:
					return {"mult": 1.8, "line": "catching the sun"}
			return {"mult": 1.0, "line": ""},
	})


func _move_dust(at: int) -> void:
	if at == _dust_at or at < 0 or at >= _dust_dirs.size():
		return
	_dust_at = at
	var d := _dust_dirs[at]
	_dust_root.global_transform = _xf(d, _tangent_at(d))


func _tick_dust(_delta: float) -> void:
	var run := _run_at(DUST_RUNS, _t, true)
	if run.is_empty() or _sleeping:
		_dust_fall.emitting = false
		_dust_heavy.emitting = false
		_dust_glint.emitting = false
		return
	_move_dust(int(run["at"]))
	var k := _t - float(run["start"])
	# the warning: the first glints hang in the air; then the fall; thickest while the sun catches it
	var thick := k >= DUST_THICK_AT and k < DUST_THICK_AT + DUST_THICK_SEC
	_dust_glint.emitting = true
	_dust_glint.color = Color(1.0, 0.97, 0.9, 0.95 if thick else 0.6)
	_dust_fall.emitting = k >= 0.0
	_dust_heavy.emitting = thick


# ---------------------------------------------------------------------------------------- the mirror moon
func _build_mirror() -> void:
	_field = _ice_patch("MirrorField", _mirror_dir, FIELD_R, Color("#9fb3c9"), Color("#8ea3bb"))
	var p := safari.planet
	var g := p.surface_point(_mirror_dir)
	var up := p.up_at(g)
	# the reflection: a pale, faintly lit disc lying on the ice (steady on the shared pulse shader - the
	# lamps' own - so it is no new shader), and a soft halo just above it
	_mirror = MeshInstance3D.new()
	_mirror.name = "Mirror"
	var kit := PlanetMeshKit.new()
	kit.cylinder(Vector3.ZERO, 1.35, 1.35, 0.012, Color.WHITE, Basis.IDENTITY, 32)
	_mirror.mesh = kit.commit()
	_mirror.material_override = PlanetPropMeshes.pulse_material(Color("#dfe6f0"), 0.9, 0.6, 0, 0.8, Color("#dfe6f0"))
	_mirror.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mirror)
	_mirror.global_transform = Transform3D(Basis.looking_at(_tangent_at(_mirror_dir), p.ground_normal(_mirror_dir)), g + up * 0.045)
	_mirror.visible = false
	_mirror_halo = MeshInstance3D.new()
	_mirror_halo.name = "MirrorHalo"
	var q := QuadMesh.new()
	q.size = Vector2(3.0, 1.6)
	_mirror_halo.mesh = q
	_mirror_halo.material_override = MaterialLib.glow_sprite(Color("#c9d6ea"), 1.2, {"softness": 0.0, "core": 0.1}).duplicate() as ShaderMaterial
	_mirror_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mirror_halo)
	_mirror_halo.global_position = g + up * 0.35
	_mirror_halo.visible = false
	# the moon's own image IN the ice: a round pale disc that always faces the lens, sitting on the
	# field (a flat disc alone is a thin line from eye height)
	_moon_img = MeshInstance3D.new()
	_moon_img.name = "MoonImage"
	var mq := QuadMesh.new()
	mq.size = Vector2(1.3, 1.3)
	_moon_img.mesh = mq
	_moon_img.material_override = MaterialLib.glow_sprite(Color("#d3dcea"), 1.0, {"softness": 0.82, "core": 0.5}).duplicate() as ShaderMaterial
	_moon_img.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_moon_img)
	_moon_img.global_position = g + up * 0.55
	_moon_img.visible = false
	# the moonbeam: a pale column of light standing on the field, seen from far across the frost
	_beam_mat = _add_mat.duplicate() as StandardMaterial3D
	_beam = MeshInstance3D.new()
	_beam.name = "MoonBeam"
	_beam.mesh = Meshes.beam(9.0, 1.9)
	_beam.material_override = _beam_mat
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_beam.global_transform = Transform3D(Basis.looking_at(_tangent_at(_mirror_dir), up), g)
	_beam.visible = false
	_mirror_glints = _sparkles("MirrorGlints", 16, 1.4, Color(0.9, 0.95, 1.0, 0.7), 0.12)
	_mirror_glints.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_mirror_glints.emission_box_extents = Vector3(FIELD_R * 0.7, 0.08, FIELD_R * 0.7)
	_mirror_glints.gravity = Vector3.ZERO
	_mirror_glints.initial_velocity_max = 0.05
	add_child(_mirror_glints)
	_mirror_glints.global_transform = Transform3D(Basis.looking_at(_tangent_at(_mirror_dir), up), g + up * 0.12)
	_mirror_focus = Node3D.new()
	_mirror_focus.name = "MirrorFocus"
	add_child(_mirror_focus)
	_mirror_focus.global_position = g + up * 0.8
	safari.add_subject({
		"id": "mirror_moon", "name": "The Mirror Moon", "band": BAND_MIRROR, "node": _mirror_focus, "radius": 1.6,
		"event": "mirror_moon",
		"moment": func(_tt: float) -> Dictionary:
			if _t >= MIRROR_STILL.x and _t < MIRROR_STILL.y:
				return {"mult": 2.4, "line": "perfectly still"}
			return {"mult": 1.0, "line": ""},
	})


func _tick_mirror(_delta: float) -> void:
	if not bool(_eligible.get("mirror_moon", false)) or _sleeping:
		return
	var warn := _t >= MIRROR_START - WARN and _t < MIRROR_START
	var on := _t >= MIRROR_START and _t < MIRROR_END
	_mirror_glints.emitting = warn or on
	_mirror.visible = on
	_mirror_halo.visible = on
	_moon_img.visible = on
	_beam.visible = warn or on
	if _beam.visible:
		# one ribbon turned to face the lens about its own upright (a crossed pair showed a hard line
		# edge-on)
		var cam := safari.rig.get_view_camera() if safari.rig != null else null
		if cam != null:
			var bu := _beam.global_transform.basis.y.normalized()
			var to := cam.global_position - _beam.global_position
			to -= bu * to.dot(bu)
			if to.length() > 0.05:
				_beam.global_transform = Transform3D(Basis.looking_at(-to.normalized(), bu), _beam.global_position)
		var bl := 0.25 * (1.0 - (MIRROR_START - _t) / WARN) if warn else \
			clampf((_t - MIRROR_START) / 2.0, 0.0, 1.0) * clampf((MIRROR_END - _t) / 2.0, 0.0, 1.0) * 0.45
		_beam_mat.albedo_color = Color(1.0, 1.0, 1.0, bl)
	if on:
		var fade_in := clampf((_t - MIRROR_START) / 3.0, 0.0, 1.0) * clampf((MIRROR_END - _t) / 2.0, 0.0, 1.0)
		var still := _t >= MIRROR_STILL.x and _t < MIRROR_STILL.y
		# ripples settle: the disc wobbles and swells until the still window, then holds round and bright
		var wob := 0.0 if still else 0.08 * sin(_t * 5.0) * (1.0 - clampf((_t - MIRROR_START) / (MIRROR_STILL.x - MIRROR_START), 0.0, 1.0))
		var s := lerpf(0.4, 1.0, fade_in)
		var xf := _mirror.global_transform
		xf.basis = xf.basis.orthonormalized() * Basis.from_scale(Vector3(s * (1.0 + wob), 1.0, s * (1.0 - wob)))
		_mirror.global_transform = xf
		(_mirror_halo.material_override as ShaderMaterial).set_shader_parameter("fade", fade_in * (1.0 if still else 0.6))
		# the image trembles with the ripples, then holds perfectly round and clear while still
		_moon_img.scale = Vector3(1.0 + wob * 2.0, 1.0 - wob * 2.0, 1.0)
		(_moon_img.material_override as ShaderMaterial).set_shader_parameter("fade", fade_in * (0.75 if still else 0.45))


# ---------------------------------------------------------------------------------------- the aurora
func _build_aurora() -> void:
	var p := safari.planet
	_aurora_root = Node3D.new()
	_aurora_root.name = "Aurora"
	add_child(_aurora_root)
	var g := p.surface_point(_array_mid)
	var up := p.up_at(g)
	var along := _tangent_at(_array_mid)
	var m0: Dictionary = _masts[0]
	var m7: Dictionary = _masts[7]
	if not m0.is_empty() and not m7.is_empty():
		var a := (m0["base"] as Vector3) - (m7["base"] as Vector3)
		a -= up * a.dot(up)
		if a.length() > 0.1:
			along = a.normalized()
	_aurora_root.global_transform = Transform3D(Basis.looking_at(along.cross(up), up), g + up * 10.0)
	_aurora_mat = _add_mat.duplicate() as StandardMaterial3D
	for k in 5:
		var c := MeshInstance3D.new()
		c.name = "Curtain%d" % k
		c.mesh = Meshes.curtain(9.0, 7.0, k)
		c.material_override = _aurora_mat
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_aurora_root.add_child(c)
		c.position = Vector3((float(k) - 2.0) * 3.2, float(k % 2) * 1.2, -1.5 * cos(float(k) * 1.3))
		c.rotation = Vector3(0.0, 0.35 * sin(float(k) * 2.1), 0.0)
		_curtains.append(c)
	_aurora_focus = Node3D.new()
	_aurora_focus.name = "AuroraFocus"
	_aurora_root.add_child(_aurora_focus)
	_aurora_focus.position = Vector3(0.0, 3.0, 0.0)
	_aurora_root.visible = false
	_hum = _sound("comms_bed", 0.6, -14.0, true)
	safari.add_subject({
		"id": "aurora", "name": "Aurora over the Array", "band": BAND_AURORA, "node": _aurora_focus, "radius": 3.0,
		"event": "aurora",
		"moment": func(_tt: float) -> Dictionary:
			if _t >= AURORA_FLARE.x and _t < AURORA_FLARE.y:
				return {"mult": 2.2, "line": "the curtains flaring"}
			return {"mult": 1.0, "line": ""},
	})


func _tick_aurora(_delta: float) -> void:
	if _aurora_root == null or not bool(_eligible.get("aurora", false)):
		return
	var warn := _t >= AURORA_START - WARN and _t < AURORA_START
	var on := _t >= AURORA_START and _t < AURORA_END and not _sleeping
	_aurora_root.visible = (warn or on) and not _sleeping
	if not _aurora_root.visible:
		if _hum.playing:
			_hum.stop()
		return
	if not _hum.playing:
		_hum.play()
	var level := 0.0
	if warn:
		level = 0.3 * (1.0 - (AURORA_START - _t) / WARN)
	else:
		level = clampf((_t - AURORA_START) / 4.0, 0.0, 1.0) * clampf((AURORA_END - _t) / 3.0, 0.0, 1.0) * 0.45
		if _t >= AURORA_FLARE.x and _t < AURORA_FLARE.y:
			level = 0.75
	_hum.volume_db = lerpf(-24.0, -10.0, level)
	_aurora_mat.albedo_color = Color(1.0, 1.0, 1.0, level)
	for k in _curtains.size():
		var c := _curtains[k]
		c.rotation.y = 0.35 * sin(float(k) * 2.1) + 0.12 * sin(_t * 0.4 + float(k))
		c.scale = Vector3(1.0, 1.0 + 0.12 * sin(_t * 0.7 + float(k) * 1.7), 1.0)


# ---------------------------------------------------------------------------------------- star-krill
## STAR-KRILL, the night-only creature: little glowing krill that swim up out of the ice in a slow ring,
## circle, and sink back. (Round 1 drew them as a cloud of sparkle particles, which had no face to score
## and no shape to recognise; its "best" photo was really of the seals beside it.) A SWARM is KRILL_PER
## krill circling one spot. The home swarms hover over the two floes and the Mirror Field; KRILL_SCOUTS
## more are the pacing director's fourth bringer at night (they rise out of the snow where you look).
## Every KRILL_SWIRL_EVERY the ring spins faster and lifts (the moment); stand still with the camera up
## close by and the swarm turns to look at you. ONE herd, two draw calls: the bodies on the shared toon
## material, their glows on the shipped star shader.
const KRILL_PER := 6
const KRILL_SCOUTS := 2
const KRILL_RING_M := Vector2(0.24, 0.5)
const KRILL_H := Vector2(0.3, 1.05)
const KRILL_SPIN := 0.6
const KRILL_RISE_SEC := 1.2
const KRILL_GLOW_M := 0.34
## The subject: the middle of the ring, and a sphere that holds it.
const KRILL_MID_H := 0.68
const KRILL_R := 0.6
enum Krill { GONE, RISE, OUT, SINK }

var _krill_herd: Herd
var _krill_focus: Node3D
var _krill_sw: Array = []
var _krill_head: Array[Vector3] = []
var _krill_pos: Array[Vector3] = []
var _krill_pick := -1


func _build_krill() -> void:
	for d: Vector3 in [_floes[0], _floes[1], _mirror_dir]:
		_krill_sw.append({"scout": false, "dir": d, "home": d, "state": Krill.RISE, "k": 0.0, "ang": _rng.randf_range(0.0, TAU),
			"lift": 0.0, "hello": 0.0, "timer": 0.0, "out_since": -INF})
	for k in KRILL_SCOUTS:
		_krill_sw.append({"scout": true, "dir": safari.start_dir, "home": safari.start_dir, "state": Krill.GONE, "k": 0.0,
			"ang": _rng.randf_range(0.0, TAU), "lift": 0.0, "hello": 0.0, "timer": 0.0, "out_since": -INF})
	var n := _krill_sw.size() * KRILL_PER
	_krill_head.resize(n)
	_krill_pos.resize(n)
	for i in n:
		_krill_head[i] = safari.start_fwd
		_krill_pos[i] = Vector3.ZERO
	_krill_herd = Herd.new()
	add_child(_krill_herd)
	var glow := QuadMesh.new()
	glow.size = Vector2(KRILL_GLOW_M, KRILL_GLOW_M)
	_krill_herd.setup("StarKrill", n, [[Meshes.krill(), _prop_mat, false],
		[glow, MaterialLib.glow_sprite(Color("#c3d6ec"), 1.4, {"softness": 0.0, "core": 0.2, "blink": 0.25, "blink_speed": 2.0}), false]],
		_planet_box())
	_krill_focus = Node3D.new()
	_krill_focus.name = "KrillFocus"
	add_child(_krill_focus)
	safari.add_subject({
		"id": "star_krill", "name": "Star-krill", "band": BAND_KRILL, "node": _krill_focus, "radius": KRILL_R,
		"awake": func() -> bool: return _krill_pick >= 0 and not _sleeping,
		"moment": func(_tt: float) -> Dictionary: return _krill_moment(),
		"front": func() -> Vector3: return _krill_front(),
	})


func _krill_swirl() -> bool:
	return fmod(_t, KRILL_SWIRL_EVERY) < KRILL_SWIRL_SEC


func _krill_moment() -> Dictionary:
	if _krill_pick < 0:
		return {"mult": 1.0, "line": ""}
	var sw: Dictionary = _krill_sw[_krill_pick]
	if float(sw["hello"]) > 0.0:
		return {"mult": 1.7, "line": "gathering to look at you"}
	if int(sw["state"]) == Krill.RISE:
		return {"mult": 1.5, "line": "rising out of the ice"}
	if _krill_swirl():
		return {"mult": 1.5, "line": "rising in a swirl"}
	return {"mult": 1.0, "line": ""}


## The way the krill nearest the lens is facing (Bolt's spark-moths: one small swimmer of the swarm is
## what a close photo looks at).
func _krill_front() -> Vector3:
	if _krill_pick < 0:
		return Vector3.ZERO
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var lens := cam.global_position if cam != null else safari.player.global_position
	var best := -1
	var best_d := INF
	for j in KRILL_PER:
		var i := _krill_pick * KRILL_PER + j
		var dd := _krill_pos[i].distance_to(lens)
		if dd < best_d:
			best_d = dd
			best = i
	return _krill_head[best] if best >= 0 else Vector3.ZERO


func _tick_krill(delta: float) -> void:
	if _krill_herd == null:
		return
	var p := safari.planet
	var ppos := safari.player.global_position
	var speed := safari.player.get_tangent_velocity().length()
	var shy := pacing != null and pacing.shy("star_krill")
	var swirl := _krill_swirl()
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var lens := cam.global_position if cam != null else ppos
	for s in _krill_sw.size():
		var sw: Dictionary = _krill_sw[s]
		sw["timer"] = float(sw["timer"]) - delta
		sw["hello"] = maxf(float(sw["hello"]) - delta, 0.0)
		var g := p.surface_point(sw["dir"])
		var up := p.up_at(g)
		var mid := g + up * (KRILL_MID_H + float(sw["lift"]))
		var dist := mid.distance_to(ppos)
		var st: int = sw["state"]
		if _sleeping and st != Krill.GONE:
			st = Krill.SINK
			sw["state"] = st
		match st:
			Krill.RISE:
				sw["k"] = minf(float(sw["k"]) + delta / KRILL_RISE_SEC, 1.0)
				if float(sw["k"]) >= 1.0:
					sw["state"] = Krill.OUT
			Krill.SINK:
				sw["k"] = maxf(float(sw["k"]) - delta / KRILL_RISE_SEC, 0.0)
				sw["hello"] = 0.0
				if float(sw["k"]) <= 0.0:
					sw["state"] = Krill.GONE
					sw["timer"] = _rng.randf_range(4.0, 8.0)
			Krill.GONE:
				# a home swarm comes back up once nothing new is holding it off (never while asleep)
				if not bool(sw["scout"]) and not shy and not _sleeping and float(sw["timer"]) <= 0.0 \
						and not (dist < RUSH_M + 1.0 and speed > RUSH_SPEED):
					sw["state"] = Krill.RISE
			Krill.OUT:
				var leave := false
				if bool(sw["scout"]):
					leave = (_t - float(sw["out_since"]) > SCOUT_OUT_MIN_SEC and not _in_frame(mid, 1.2)) \
						or (shy and not _in_frame(mid, 1.1))
				else:
					# a home swarm dives if you rush it; a brought one (like the brought seals) does not, or a
					# wanderer walking on toward the spot would send it down before it is up
					leave = (shy and not _in_frame(mid, 1.1)) or (dist < RUSH_M and speed > RUSH_SPEED)
				if leave:
					sw["state"] = Krill.SINK
				elif _still >= HELLO_STILL and dist < HELLO_M and _t >= _hello_next and float(sw["hello"]) <= 0.0:
					sw["hello"] = HELLO_SEC
					_hello_next = _t + HELLO_SEC + HELLO_REST
					AudioManager.play_sfx_at("collect_stardust", mid, -14.0, 0.1)
		_pose_krill(s, sw, g, up, swirl, lens, delta)
	_krill_pick = _pick_focus(_krill_sw, func(sw: Dictionary) -> bool: return float(sw["k"]) > 0.5,
		func(sw: Dictionary) -> Vector3:
			var gg := p.surface_point(sw["dir"])
			return gg + p.up_at(gg) * float(sw["lift"]), KRILL_MID_H)
	if _krill_pick >= 0:
		var sw: Dictionary = _krill_sw[_krill_pick]
		var gg := p.surface_point(sw["dir"])
		_krill_focus.global_position = gg + p.up_at(gg) * (KRILL_MID_H + float(sw["lift"]))


## Each krill of swarm `s` on its ring: its place, its heading (along its swim, or toward the lens while
## the swarm says hello) and its body and glow in the herd.
func _pose_krill(s: int, sw: Dictionary, g: Vector3, up: Vector3, swirl: bool, lens: Vector3, delta: float) -> void:
	var k := float(sw["k"])
	var hello := float(sw["hello"]) > 0.0
	var spin := KRILL_SPIN * (2.2 if swirl else 1.0) * (0.25 if hello else 1.0)
	sw["ang"] = float(sw["ang"]) + spin * delta
	var x := _tangent_at(safari.planet.dir_of(g))
	x = (x - up * x.dot(up)).normalized()
	var z := up.cross(x).normalized()
	var ease := k * k * (3.0 - 2.0 * k)
	for j in KRILL_PER:
		var i := s * KRILL_PER + j
		if k <= 0.0:
			_krill_herd.hide_one(i)
			continue
		var fj := float(j) / float(KRILL_PER - 1)
		var fh := fmod(fj * 3.7 + 0.13, 1.0)
		var a := float(sw["ang"]) + TAU * float(j) / float(KRILL_PER)
		var r := lerpf(KRILL_RING_M.x, KRILL_RING_M.y, fj) * (0.85 if hello else 1.0)
		var h := lerpf(KRILL_H.x, KRILL_H.y, fh) + 0.05 * sin(_t * 1.7 + float(j) * 1.3) + (0.3 if swirl else 0.0)
		var radial := x * cos(a) + z * sin(a)
		var pos := g + up * ((h + float(sw["lift"])) * ease) + radial * r * lerpf(0.3, 1.0, ease)
		var want := up.cross(radial).normalized()
		if hello:
			var to := lens - pos
			to -= up * to.dot(up) * 0.7
			if to.length() > 0.01:
				want = to.normalized()
		elif int(sw["state"]) == Krill.RISE:
			want = (want + up * 0.6).normalized()
		elif int(sw["state"]) == Krill.SINK:
			want = (want - up * 0.6).normalized()
		var head := _krill_head[i].slerp(want, minf(delta * 5.0, 1.0)).normalized() if _krill_head[i].length() > 0.5 else want
		_krill_head[i] = head
		_krill_pos[i] = pos
		var side := head.cross(up)
		var body_up := up if side.length() > 0.05 else head.cross(x).normalized()
		var sc := lerpf(0.5, 1.0, ease)
		var xf := Transform3D(Basis.looking_at(head, body_up) * Basis.from_scale(Vector3.ONE * sc), pos)
		_krill_herd.pose(i, 0, xf)
		var gl := (1.25 if swirl or hello else 1.0) * ease
		_krill_herd.pose(i, 1, Transform3D(Basis.from_scale(Vector3.ONE * maxf(gl, 0.001)), pos))


func _bring_krill(spot: Dictionary) -> bool:
	var i := _free_scout("krill")
	if i < 0:
		return false
	spot = _more_ways(spot, -1.0)
	var d: Vector3 = spot["dir"]
	var lift := 0.0
	if d == Vector3.ZERO:
		# you are looking over the snow: they rise higher, up into the middle of your view
		d = spot["ahead"]
		if d == Vector3.ZERO or float(spot["rise"]) < 0.0:
			return false
		lift = maxf(float(spot["rise"]) - KRILL_MID_H + 0.3, 0.0)
	var sw: Dictionary = _krill_sw[i]
	sw["dir"] = d
	sw["lift"] = lift
	sw["state"] = Krill.RISE
	sw["k"] = 0.0
	sw["out_since"] = _t
	var g := safari.planet.surface_point(d)
	for j in KRILL_PER:
		_krill_head[i * KRILL_PER + j] = Vector3.ZERO
	safari.puff_at(g + safari.planet.up_at(g) * 0.1, 10, Color("#dfe6ee"))
	AudioManager.play_sfx_at("collect_stardust", g, -10.0, 0.1)
	return true


# ======================================================================================== SIGHTS AND BONUS
## THE SCRAPBOOK'S NEW PAGES (spec 15.5; builder VELAC, 2026-09-26). Two SIGHTS (always there, rarity 1, they
## pay as usual) and three BONUS things (small, tucked away, a collector's page: they pay nothing). Neither
## kind counts toward the density band or the pacing director (safari_world.gd CATEGORY), so none is in
## `_creature_places`; nothing is brought on top of the snow-astronaut or the frozen star (_near_extra).
##   THE EIGHT MASTS    the Long Array itself (the real props): scored on a sphere EIGHT_MASTS_R round the
##                      middle of the run, lamp-high, so a photo has to take in several masts. No front.
##   THE FROZEN LAKE    the Mirror Field, grown into a lake: the same ice, now with snow banks round its
##                      shore and pale cracks across it (_build_lake_shore). The Mirror Moon still rises on
##                      it; while the moon is up the lake is not a subject (the moon is the photo), so a
##                      photo of the rare is never named after the ice under it. No front.
##   A SNOW-ASTRONAUT   a snowman in a helmet, round the back of the ArrayDish farthest from the start: walk
##                      round the dish to meet it. Front = its visor.
##   VELA'S TEACUP      on the LOWER cross-arm of Mast FOUR (TEACUP_MAST, no bird lives there), at the arm end
##                      farther from the start, 0.8-1 m up: look closely at the masts. No front (a cup).
##   A STAR IN THE ICE  a small star frozen in a puddle of ice beside the FrostStone farthest from the start,
##                      on the stone's far side; it glints faintly (the shipped star shader). No front.
## Nothing here exists outside a safari (the user's rule 5): built with the rest and freed with it; the snow-
## astronaut blocks the player (and sight rays) with a small cylinder on the NPC layer (1 << 2), as Bolt's
## workshop does.
## SIZE BANDS by the rule of SIZE BANDS above (6 or less at the usual distance at the 45 degree lens), the
## usual distance being where a curious wanderer first frames it (stated picks, and the Eight Masts' from
## the logged start-to-array distance):
##   subject          radius  usual d  size_frac  band        d_in at 45 deg
##   eight masts      2.00    9.0 m    0.540      1.00-1.00   5.2 m   (logged: 11.5 m from the start's eye)
##   frozen lake      1.50    8.0 m    0.461      0.81-1.00   4.5 m
##   snow-astronaut   0.42    4.0 m    0.254      0.45-0.74   2.3 m
##   Vela's teacup    0.08    2.5 m    0.077      0.14-0.22   1.4 m
##   star in the ice  0.17    2.5 m    0.165      0.29-0.48   1.4 m
const EIGHT_MASTS_R := 2.0
const EIGHT_MASTS_H := 1.4
const LAKE_R := 1.5
const LAKE_FOCUS_H := 0.3
const BAND_MASTS := Vector2(1.0, 1.0)
const BAND_LAKE := Vector2(0.81, 1.0)
const BAND_SNOWMAN := Vector2(0.45, 0.74)
const BAND_TEACUP := Vector2(0.14, 0.22)
const BAND_STAR := Vector2(0.29, 0.48)
const SNOWMAN_R := 0.42
const TEACUP_R := 0.08
const STAR_R := 0.17
const TEACUP_MAST := 3
const STAR_PUDDLE_R := 0.75
## Nothing the director brings comes up within this of the snow-astronaut or the frozen star.
const EXTRA_CLEAR_M := 1.0

var _masts_focus: Node3D
var _lake_focus: Node3D
var _snowman: Node3D
var _snowman_dir := Vector3.ZERO
var _teacup: MeshInstance3D
var _teacup_at := Vector3.ZERO
var _star: Node3D
var _star_dir := Vector3.ZERO
var _star_glint: MeshInstance3D


func _build_sights() -> void:
	var p := safari.planet
	# THE EIGHT MASTS: a sphere round the middle of the run, lamp-high
	var mid := p.surface_point(_array_mid)
	_masts_focus = Node3D.new()
	_masts_focus.name = "EightMastsFocus"
	add_child(_masts_focus)
	_masts_focus.global_position = mid + p.up_at(mid) * EIGHT_MASTS_H
	safari.add_subject({
		"id": "eight_masts", "name": "The Eight Masts", "category": "sight", "band": BAND_MASTS,
		"node": _masts_focus, "radius": EIGHT_MASTS_R,
		"awake": func() -> bool: return not _sleeping,
	})
	# THE FROZEN LAKE: the Mirror Field with a shore
	_build_lake_shore()
	var g := p.surface_point(_mirror_dir)
	_lake_focus = Node3D.new()
	_lake_focus.name = "FrozenLakeFocus"
	add_child(_lake_focus)
	_lake_focus.global_position = g + p.up_at(g) * LAKE_FOCUS_H
	safari.add_subject({
		"id": "frozen_lake", "name": "The Frozen Lake", "category": "sight", "band": BAND_LAKE,
		"node": _lake_focus, "radius": LAKE_R,
		"awake": func() -> bool: return not _sleeping and not safari.event_running("mirror_moon"),
	})
	_log("sights: eight masts at %s (%.1f m from the start), frozen lake at %s" % [_pp(_array_mid),
		_masts_focus.global_position.distance_to(p.surface_point(safari.start_dir) + p.up_at(p.surface_point(safari.start_dir)) * 1.5),
		_pp(_mirror_dir)])


## Snow banks round the lake's shore and pale cracks across its ice: ONE mesh on the shared toon material,
## every vertex placed on the real terrain (as _ice_patch does).
func _build_lake_shore() -> void:
	var p := safari.planet
	var c := _mirror_dir
	var origin := p.surface_point(c)
	var t := _tangent_at(c)
	var kit := PlanetMeshKit.new()
	# (first build: 16 banks of 0.3-0.4 m in near-white #c9d3dd read as a ring of big white pillows in the
	# phone frame; now low, small and close to the powder's own blue, so the shore reads as a lip, not a fence)
	var bank := Color("#98a9c5")
	var bank_shade := Color("#8a9cba")
	var crack := Color("#c3d0dd")
	# the banks: low, flat drifts of snow in a broken ring just outside the ice
	for k in 24:
		var psi := 360.0 * float(k) / 24.0 + _rng.randf_range(-5.0, 5.0)
		var rho := (FIELD_R * 1.08 + _rng.randf_range(-0.05, 0.12)) / p.radius
		var d := _polar(c, t, rad_to_deg(rho), psi)
		var gp := p.surface_point(d)
		var up := p.ground_normal(d)
		var out := (gp - origin)
		out -= up * out.dot(up)
		var basis := Basis.looking_at(out.normalized() if out.length() > 0.01 else t, up)
		var r := _rng.randf_range(0.15, 0.21)
		kit.sphere(gp - origin, r, bank if k % 3 != 0 else bank_shade, Vector3(2.3, 0.24, 0.9), 12, basis)
	# the cracks: a few thin, jagged lines lying on the ice (the ice patch is lifted 0.03 m)
	for k in 5:
		var psi0 := 72.0 * float(k) + _rng.randf_range(-20.0, 20.0)
		var prev := Vector3.ZERO
		var steps := 4
		for j in steps + 1:
			var rho := (0.25 + (FIELD_R * 0.78 - 0.25) * float(j) / float(steps)) / p.radius
			var d := _polar(c, t, rad_to_deg(rho), psi0 + _rng.randf_range(-9.0, 9.0))
			var q := p.surface_point(d) + p.up_at(p.surface_point(d)) * 0.045 - origin
			if j > 0:
				var up := p.up_at(origin + q)
				var side := (q - prev).cross(up).normalized() * (0.03 - 0.004 * float(j))
				kit.quad(prev - side, prev + side, q + side * 0.8, q - side * 0.8, crack)
			prev = q
	var mi := MeshInstance3D.new()
	mi.name = "LakeShore"
	mi.mesh = kit.commit()
	mi.material_override = _prop_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = origin


func _build_bonus() -> void:
	var p := safari.planet
	var props := p.get_node_or_null("Props")
	# A SNOW-ASTRONAUT round the back of the dish farthest from the start
	var dish: Node3D = _farthest_prop(props, "ArrayDish")
	if dish != null:
		_snowman_dir = _behind(p.dir_of(dish.global_position), [1.6, 1.9, 2.2, 2.6], 0.75)
	if _snowman_dir == Vector3.ZERO:
		_snowman_dir = _free_near(safari.dir_from_start(70.0, 140.0), 0.9)
	var body := StaticBody3D.new()
	body.name = "SnowAstronaut"
	body.collision_layer = 1 << 2
	body.collision_mask = 0
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = Meshes.snow_astronaut()
	mi.material_override = _prop_mat
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.24
	cyl.height = 0.95
	cs.shape = cyl
	cs.position = Vector3(0.0, 0.475, 0.0)
	body.add_child(cs)
	add_child(body)
	# it faces out from the dish, a little toward the way round from the start
	var from_dish := _toward(_snowman_dir, p.dir_of(dish.global_position)) * -1.0 if dish != null else _toward(_snowman_dir, safari.start_dir)
	body.global_transform = _xf_ground(_snowman_dir, from_dish).translated_local(Vector3(0.0, -0.03, 0.0))
	_snowman = body
	safari.add_subject({
		"id": "snow_astronaut", "name": "A Snow-astronaut", "category": "bonus", "band": BAND_SNOWMAN,
		"node": _snowman, "offset": Vector3(0.0, 0.5, 0.0), "radius": SNOWMAN_R,
		"awake": func() -> bool: return not _sleeping,
		"front": func() -> Vector3: return _front_of(_snowman),
	})
	# VELA'S TEACUP on Mast FOUR's lower cross-arm, the end farther from the start
	var m: Dictionary = _masts[TEACUP_MAST] if _masts.size() > TEACUP_MAST else {}
	if not m.is_empty():
		var n := m["node"] as Node3D
		var start_g := p.surface_point(safari.start_dir)
		var best := -INF
		for side in [1.0, -1.0]:
			var q: Vector3 = n.global_transform * Vector3(0.27 * side, _low_arm(TEACUP_MAST), 0.0)
			if q.distance_to(start_g) > best:
				best = q.distance_to(start_g)
				_teacup_at = q
		_teacup = MeshInstance3D.new()
		_teacup.name = "VelasTeacup"
		_teacup.mesh = Meshes.teacup()
		_teacup.material_override = _prop_mat
		add_child(_teacup)
		_teacup.global_transform = Transform3D(Basis.looking_at(_tangent_at(p.dir_of(_teacup_at)), m["up"]), _teacup_at)
		safari.add_subject({
			"id": "vela_teacup", "name": "Vela's Teacup", "category": "bonus", "band": BAND_TEACUP,
			"node": _teacup, "offset": Vector3(0.0, 0.04, 0.0), "radius": TEACUP_R,
			"awake": func() -> bool: return not _sleeping,
		})
	# A STAR IN THE ICE beside the frost stone farthest from the start, on its far side
	var stone: Node3D = _farthest_prop(props, "FrostStone")
	if stone != null:
		_star_dir = _behind(p.dir_of(stone.global_position), [1.2, 1.5, 1.8, 2.1], STAR_PUDDLE_R + 0.05)
	if _star_dir == Vector3.ZERO:
		_star_dir = _free_near(safari.dir_from_start(150.0, -60.0), STAR_PUDDLE_R + 0.3)
	_ice_patch("StarPuddle", _star_dir, STAR_PUDDLE_R, Color("#b0c3d6"), Color("#9cb1c7"), 0.035)
	var sg := p.surface_point(_star_dir)
	var sup := p.ground_normal(_star_dir)
	_star = MeshInstance3D.new()
	_star.name = "FrozenStar"
	(_star as MeshInstance3D).mesh = Meshes.frozen_star()
	(_star as MeshInstance3D).material_override = _prop_mat
	(_star as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_star)
	_star.global_transform = Transform3D(Basis.looking_at(_tangent_at(_star_dir).rotated(sup, 0.4), sup), sg + sup * 0.04)
	_star_glint = MeshInstance3D.new()
	_star_glint.name = "StarGlint"
	var gq := QuadMesh.new()
	gq.size = Vector2(0.34, 0.34)
	_star_glint.mesh = gq
	_star_glint.material_override = MaterialLib.glow_sprite(Color("#e8d6a8"), 1.0, {"softness": 0.0, "core": 0.25}).duplicate() as ShaderMaterial
	_star_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_star_glint)
	_star_glint.global_position = sg + sup * 0.07
	safari.add_subject({
		"id": "frozen_star", "name": "A Star in the Ice", "category": "bonus", "band": BAND_STAR,
		"node": _star, "offset": Vector3(0.0, 0.03, 0.0), "radius": STAR_R,
		"awake": func() -> bool: return not _sleeping,
	})
	_log("bonus: snow-astronaut at %s (behind %s), teacup on mast %d at %.2f m up, star at %s (by %s)" % [
		_pp(_snowman_dir), dish.name if dish != null else "-", TEACUP_MAST + 1,
		(_teacup_at - p.surface_point(p.dir_of(_teacup_at))).length() if _teacup_at != Vector3.ZERO else -1.0,
		_pp(_star_dir), stone.name if stone != null else "-"])


## Of `props`' children named `prefix`<n>, the one farthest round the planet from the start.
func _farthest_prop(props: Node, prefix: String) -> Node3D:
	if props == null:
		return null
	var best: Node3D = null
	var best_a := -1.0
	for n in props.get_children():
		if n is Node3D and str(n.name).begins_with(prefix):
			var a := safari.start_dir.angle_to(safari.planet.dir_of((n as Node3D).global_position))
			if a > best_a:
				best_a = a
				best = n
	return best


## A clear, flat spot `dists` metres from ground point `c` on the side AWAY from the start (within 60 degrees
## of straight behind, nearest to straight behind first), `clear_m` from every prop and 3 m from every
## creature place; Vector3.ZERO when there is none.
func _behind(c: Vector3, dists: Array, clear_m: float) -> Vector3:
	var p := safari.planet
	var away := -_toward(c, safari.start_dir)
	var places: Array = _creature_places()
	for psi: float in [0.0, 20.0, -20.0, 40.0, -40.0, 60.0, -60.0]:
		for m: float in dists:
			var d := p.step_dir(c, (c * cos(0.3) + away.rotated(c, deg_to_rad(psi)) * sin(0.3)).normalized(), m)
			if p.nearest_prop_distance(d) < clear_m or p.ground_normal(d).angle_to(d) > deg_to_rad(10.0):
				continue
			var crowded := false
			for q: Vector3 in places:
				if p.surface_point(d).distance_to(q) < 3.0:
					crowded = true
			if not crowded:
				return d
	return Vector3.ZERO


## True when ground spot `d` is within `margin` m of the snow-astronaut or the star's puddle.
func _near_extra(d: Vector3, margin: float) -> bool:
	var p := safari.planet
	if _snowman_dir != Vector3.ZERO and p.surface_distance(d, _snowman_dir) < 0.3 + margin:
		return true
	if _star_dir != Vector3.ZERO and p.surface_distance(d, _star_dir) < STAR_PUDDLE_R + margin:
		return true
	return false


func _tick_extras() -> void:
	if _star_glint != null and is_instance_valid(_star_glint):
		# a slow glint, now and then brighter, as if the light caught it
		var k := 0.22 + 0.12 * sin(_t * 1.3) + 0.35 * maxf(0.0, sin(_t * 0.37)) ** 8.0
		_star_glint.visible = not _sleeping
		(_star_glint.material_override as ShaderMaterial).set_shader_parameter("fade", k)


# ======================================================================================== SCHEDULE
func _register_events() -> void:
	# [kind, id, name, start, end, dir, rare, colour, warning line]
	var ev: Array = []
	for run: Dictionary in PING_RUNS:
		var m: Dictionary = _masts[int(run["mast"])]
		var d: Vector3 = m.get("dir", _array_mid)
		ev.append(["mast_ping", run["id"], "Mast Ping", run["start"], run["end"], d, "any", Color("#e0b27a"),
			"A lamp gathers itself on MAST %s, down the Long Array..." % ORDINALS[int(run["mast"])]])
	for run: Dictionary in DUST_RUNS:
		var d: Vector3 = _dust_dirs[int(run["at"])]
		ev.append(["diamond_dust", run["id"], "Diamond Dust Shower", run["start"], run["end"], d, "any", Color("#dfe8f2"),
			"The air begins to glitter over %s..." % _place_name(d)])
	for run: Dictionary in CALL_RUNS:
		ev.append(["vela_call", run["id"], "Vela's Call", run["start"], run["end"], _vela_station if _vela_station != Vector3.ZERO else _home_dir,
			"any", Color("#e8c28f"), ""])
	ev.append(["mirror_moon", "mirror_moon", "The Mirror Moon", MIRROR_START, MIRROR_END, _mirror_dir, "any", Color("#c9d6ea"),
		"The ice on %s is going perfectly still..." % _place_name(_mirror_dir)])
	ev.append(["aurora", "aurora", "Aurora over the Array", AURORA_START, AURORA_END, _array_mid, "only", Color("#9fcfbe"),
		"The sky over the LONG ARRAY begins to hum..."])
	for e: Array in ev:
		var kind: String = e[0]
		var id: String = e[1]
		var beacon: MeshInstance3D = _beacons[kind] if _beacons.has(kind) else _make_beacon(kind, e[7])
		var line: String = e[8]
		var dir: Vector3 = e[5]
		var ok := safari.add_event({
			"id": id, "name": e[2], "start": e[3], "end": e[4], "warn": WARN, "dir": dir,
			"when": "any", "rare": e[6], "overlap_ok": true,
			"on_warn": func(_e: Dictionary) -> void:
				beacon.set_meta("on", true)
				beacon.set_meta("dir", dir if kind != "vela_call" or not is_instance_valid(_vela) else safari.planet.dir_of(_vela.global_position))
				_warn_sound(kind)
				if line != "":
					_queue_line(line),
			"on_start": func(_e: Dictionary) -> void:
				_on_start(kind, dir),
			"on_end": func(_e: Dictionary) -> void:
				beacon.set_meta("on", false),
		})
		_eligible[id] = ok


## The warning's SOUND, heard anywhere on the planet (the line and the glow are its sight).
func _warn_sound(kind: String) -> void:
	match kind:
		"mast_ping":
			_sound_once("skiff_reveal", 0.8, -6.0).play()
		"diamond_dust":
			_sound_once("finale_shower", 1.25, -10.0).play()
		"vela_call":
			AudioManager.play_sfx("doot_a_0", -4.0)
		"mirror_moon":
			_sound_once("finale_hero_star", 0.7, -8.0).play()
		"aurora":
			_sound_once("comms_over", 0.6, -6.0).play()


func _on_start(kind: String, dir: Vector3) -> void:
	var p := safari.planet
	match kind:
		"diamond_dust":
			_sound_once("shooting_star", 1.4, -12.0).play()
		"mirror_moon":
			safari.puff_at(p.surface_point(dir) + p.up_at(p.surface_point(dir)) * 0.3, 14, Color("#dfe6f0"))
			_sound_once("finale_hero_star", 0.9, -6.0).play()


func _run_at(runs: Array, tt: float, with_warn: bool) -> Dictionary:
	for run: Dictionary in runs:
		var s0 := float(run["start"]) - (WARN if with_warn else 0.0)
		if tt >= s0 and tt < float(run["end"]) and bool(_eligible.get(str(run["id"]), false)):
			return run
	return {}


func _any_running(runs: Array) -> bool:
	for run: Dictionary in runs:
		if safari.event_running(str(run["id"])):
			return true
	return false


# ---------------------------------------------------------------------------------------- beacons
## Bolt's warning glow (worlds/bolt.gd): a soft star on YOUR horizon toward its event, hidden while the
## camera is up so it never ends up in a photograph.
func _make_beacon(id: String, colour: Color) -> MeshInstance3D:
	var b := MeshInstance3D.new()
	b.name = "Beacon_" + id
	var q := QuadMesh.new()
	# taller than Bolt's (0.55 x 1.5): on this bigger world the horizon dips 26 degrees, and its top has
	# to stand over that line to be seen with the lens held level (warning frames, 2026-09-25)
	q.size = Vector2(0.8, 2.6)
	b.mesh = q
	b.material_override = MaterialLib.glow_sprite(colour, 1.6, {"softness": 0.0, "core": 0.12}).duplicate() as ShaderMaterial
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.set_meta("on", false)
	b.set_meta("level", 0.0)
	b.visible = false
	add_child(b)
	_beacons[id] = b
	return b


func _tick_beacons(delta: float) -> void:
	var pd := _player_dir()
	for id: String in _beacons:
		var b: MeshInstance3D = _beacons[id]
		var target: Vector3 = b.get_meta("dir", Vector3.UP)
		if id == "vela_call" and _vela_borrowed and is_instance_valid(_vela):
			target = safari.planet.dir_of(_vela.global_position)
		var ang := rad_to_deg(pd.angle_to(target))
		var want := smoothstep(BEACON_NEAR_DEG, BEACON_FULL_DEG, ang) if bool(b.get_meta("on", false)) and not _sleeping else 0.0
		if safari.camera_up:
			want = 0.0
		var lv := move_toward(float(b.get_meta("level", 0.0)), want, delta * (4.0 if safari.camera_up else 1.5))
		b.set_meta("level", lv)
		b.visible = lv > 0.01
		if not b.visible:
			continue
		var tdir := target - pd * target.dot(pd)
		if ang > 165.0 or tdir.length() < 0.05:
			var cam := safari.rig.get_view_camera() if safari.rig != null else null
			var cf := -cam.global_transform.basis.z if cam != null else safari.start_fwd
			tdir = cf - pd * cf.dot(pd)
		if tdir.length() < 0.001:
			tdir = _tangent_at(pd)
		var a := deg_to_rad(minf(BEACON_AHEAD_DEG, ang))
		var along := (pd * cos(a) + tdir.normalized() * sin(a)).normalized()
		b.global_position = safari.ground_point(along, 1.3)
		(b.material_override as ShaderMaterial).set_shader_parameter("fade", lv * (0.72 + 0.28 * sin(_t * 3.4)))


# ======================================================================================== TICK
func _queue_line(text: String) -> void:
	var due := maxf(_t, INTRO_HINT_SEC)
	if not _lines.is_empty():
		due = maxf(due, float(_lines[-1][0]) + LINE_SEC)
	elif _t < _line_free_at:
		due = maxf(due, _line_free_at)
	_lines.append([due, text])


func tick(t: float, delta: float) -> void:
	_t = t
	if not _lines.is_empty() and not _building and _t >= float(_lines[0][0]) and not _sleeping:
		safari.announce(str(_lines[0][1]), 3.5)
		_line_free_at = _t + LINE_SEC
		_lines.pop_front()
	var speed := safari.player.get_tangent_velocity().length() if is_instance_valid(safari.player) else 0.0
	_still = (_still + delta) if (safari.camera_up and speed < 0.15) else 0.0
	_tick_birds(delta)
	_tick_seals(delta)
	_tick_mites(delta)
	_tick_vela()
	_tick_lamps(delta)
	_tick_dust(delta)
	_tick_mirror(delta)
	_tick_aurora(delta)
	_tick_krill(delta)
	_tick_beacons(delta)
	_tick_stir()
	_tick_extras()


## THE FIELD STIRS BEFORE A RARE (builder VELA). The director stays quiet while a rare is up (spec 13.2),
## and on this big world a rare on the far side is out of sight of most of it: with nothing brought in
## the seconds before, a wanderer who had seen nothing for a while went 21-25 s (measured: 26 of 32 runs
## within 20 s). So STIR_BEFORE seconds before each rare starts - still in its warning, before it is up
## - if nothing has been clearly in view for STIR_LONELY seconds, the world itself brings one creature
## where you look, the way the director would; if that one is not seen within STIR_RETRY seconds (you
## turned away) it tries again. At most STIR_MAX per rare; never while the rare is up.
## Round 2 (critic, seeds 41-70: 25/30 within 20 s, worst 28.75 s on seed 45): the stir never fired on
## seed 45 because the wanderer was LOOKING UP (pitch +23..+26 deg through a zoomed lens) - no ground
## spot, and the first spot ahead needed more than the director's 1.85 m rise, so every try failed
## (traced: 292 failed tries at 56-60 s, "dir=false ahead=true rise=-1"). Each bringer now tries MORE
## WAYS (_more_ways: every clear spot ahead, nearest first; VELAC: a bird now comes only to a mast arm in view
## and a seal only up through ice in view - see THE STAGING at _bring_bird and _bring_seal), the
## window opens 8 s before (room for a third try after two that were not seen), and it is checked every
## Pacing CHECK_SEC instead of every frame.
const STIR_BEFORE := 8.0
const STIR_LONELY := 3.0
const STIR_RETRY := 1.5
const STIR_MAX := 3
var _stirred: Dictionary = {}     # rare id -> [times brought, last time]
var _stir_clock := 0.0


func _tick_stir() -> void:
	if pacing == null or _sleeping or _building or _t < _stir_clock:
		return
	_stir_clock = _t + pacing.CHECK_SEC
	for row: Array in [["mirror_moon", MIRROR_START], ["aurora", AURORA_START]]:
		var id: String = row[0]
		var t0: float = row[1]
		var st: Array = _stirred.get(id, [0, -INF])
		if int(st[0]) >= STIR_MAX or _t - float(st[1]) < STIR_RETRY or not bool(_eligible.get(id, false)) \
				or _t < t0 - STIR_BEFORE or _t >= t0:
			continue
		if pacing.in_view or pacing.lonely < STIR_LONELY:
			continue
		# not on top of the director's own bring (it resets `lonely` to AFTER_SEC - RETRY_SEC, which
		# reads as lonely here: seed 65 brought a seal at 87.8 s and the stir a second thing at 88.1 s)
		if _t - float(pacing.last_bring.get("t", -INF)) < pacing.RETRY_SEC:
			continue
		var lens := pacing.lens_soon(pacing.SPOT_LEAD_SEC)
		var spot := {"dir": pacing.ground_spot(pacing.SPOT_LIFT_M), "lens": lens, "lonely": pacing.lonely,
			"ahead": Vector3.ZERO, "rise": -1.0}
		if spot["dir"] == Vector3.ZERO:
			var a := pacing.ahead_spot()
			if a != Vector3.ZERO:
				spot["ahead"] = a
				spot["rise"] = pacing.rise_into_view(a, lens)
		# the director's own order and its per-bring cap (SafariWorld.Pacing.pick_order): the one furthest
		# under its share first, and an over-share one only once nothing has been in view for cap_wait()
		for row2: Dictionary in pacing.pick_order():
			var c: Callable = row2["bring"]
			if bool(c.call(spot)):
				_stirred[id] = [int(st[0]) + 1, _t]
				_log("the field stirs before %s: t=%.1f after %.1f s quiet" % [id, _t, pacing.lonely])
				break


## The three minutes are up: the birds fly off, the seals slip into their holes, the mites under the
## powder; everything else goes in PlanetSafari's puff; Vela is handed back at once and put back where
## she stood when this node leaves (behind the black fade).
func go_to_sleep() -> bool:
	_sleeping = true
	for s in _sounds:
		s.stop()
	get_tree().create_timer(PlanetSafari.SLEEP_PUFF_HIDE_SEC).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		for n: Node3D in [_ring, _call_rings, _mirror, _mirror_halo, _moon_img, _beam, _aurora_root]:
			if n != null and is_instance_valid(n):
				n.visible = false
		for f in _flares:
			f.visible = false
		for pr: CPUParticles3D in [_dust_fall, _dust_heavy, _dust_glint, _mirror_glints, _notes]:
			if pr != null and is_instance_valid(pr):
				pr.emitting = false)
	if _vela_borrowed:
		_release_vela(false)
	return true


func _exit_tree() -> void:
	_release_vela(true)


# ======================================================================================== HELPERS
var _more_cache: Dictionary = {}   # [frame, max rise] -> the spot it found, so one director check pays once

## MORE WAYS (critic round 1, seed 45). The director's `spot` gives up when there is no ground spot in
## view and the FIRST clear spot ahead would need more than RISE_MAX_M to rise into the middle of the
## view. Before a bringer gives up, this tries EVERY clear spot ahead (the director's SPOT_M distances,
## nearest first, and its SPOT_YAW turns) and keeps the one needing the least rise, up to `max_rise`
## (-1 = the director's RISE_MAX_M). Returns `spot` unchanged when it already works or nothing does.
func _more_ways(spot: Dictionary, max_rise: float) -> Dictionary:
	if (spot["dir"] as Vector3) != Vector3.ZERO or float(spot["rise"]) >= 0.0 or pacing == null:
		return spot
	var top := pacing.RISE_MAX_M if max_rise < 0.0 else max_rise
	var key := "%d:%.2f" % [Engine.get_process_frames(), top]
	if _more_cache.has(key):
		var c: Dictionary = _more_cache[key]
		return spot if c.is_empty() else c
	_more_cache.clear()
	var p := safari.planet
	var lens: Transform3D = spot["lens"]
	var best := {}
	if p != null and lens != Transform3D():
		var pd := p.dir_of(lens.origin)
		var fwd := -lens.basis.z
		fwd -= pd * fwd.dot(pd)
		if fwd.length() < 0.01:
			fwd = -lens.basis.y - pd * (-lens.basis.y).dot(pd)
		if fwd.length() >= 0.01:
			fwd = fwd.normalized()
			var dists: Array = pacing.SPOT_M.duplicate()
			dists.sort()
			var best_h := INF
			for m: float in dists:
				for yaw: float in pacing.SPOT_YAW:
					var d := p.step_dir(pd, (pd * cos(0.5) + fwd.rotated(pd, deg_to_rad(yaw)) * sin(0.5)).normalized(), m)
					if not pacing._spot_clear(d):
						continue
					var g := p.surface_point(d)
					var n := p.ground_normal(d)
					var h := 0.0
					while h <= top + 0.001 and h < best_h:
						var body := g + n * (pacing.SPOT_LIFT_M + h)
						if pacing.in_view_from(lens, body, pacing.SPOT_FRAME_FRAC) and pacing.sight_clear(lens.origin, body):
							best_h = h
							best = spot.duplicate()
							best["ahead"] = d
							best["rise"] = h
							break
						h += pacing.RISE_STEP
	_more_cache[key] = best
	return spot if best.is_empty() else best


## The first scout of `kind` ("bird", "seal", "mite", "krill") that is home and free to be brought, or -1.
func _free_scout(kind: String) -> int:
	var items: Array = _birds if kind == "bird" else (_seals if kind == "seal" else (_mites if kind == "mite" else _krill_sw))
	for i in items.size():
		var it: Dictionary = items[i]
		if not bool(it.get("scout", false)):
			continue
		match kind:
			"bird":
				if int(it["state"]) == Bird.AWAY and float(it["timer"]) <= 0.0:
					return i
			"seal":
				if int(it["state"]) == Seal.UNDER:
					return i
			"mite":
				if int(it["state"]) == Mite.GONE and float(it["sink"]) >= MITE_SINK - 0.01:
					return i
			"krill":
				if int(it["state"]) == Krill.GONE:
					return i
	return -1


func _in_frame(q: Vector3, grow: float) -> bool:
	return pacing.point_in_frame(q, grow) if pacing != null else false


## Of `items` that `ok` accepts, the one nearest the middle of the view that the lens can see (Bolt's
## `_pick_focus`); -1 when none is out.
func _pick_focus(items: Array, ok: Callable, pos_of: Callable, lift: float) -> int:
	var cam := safari.rig.get_view_camera() if safari.rig != null else null
	var cands: Array = []
	for i in items.size():
		if not bool(ok.call(items[i])):
			continue
		var pnt: Vector3 = pos_of.call(items[i])
		var score := 1000.0
		if cam != null:
			var to := pnt - cam.global_position
			var dist := to.length()
			var ang := rad_to_deg((-cam.global_transform.basis.z).angle_to(to / maxf(dist, 0.001)))
			score = ang + dist * 0.05 if ang < 35.0 else 100.0 + dist
		cands.append([score, i, pnt])
	if cands.is_empty():
		return -1
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	if cam == null or pacing == null:
		return int(cands[0][1])
	for k in mini(cands.size(), 4):
		if float(cands[k][0]) >= 100.0:
			break
		var pnt: Vector3 = cands[k][2]
		if pacing.sight_clear(cam.global_position, pnt + safari.planet.up_at(pnt) * lift):
			return int(cands[k][1])
	return int(cands[0][1])


func _front_of(n: Node3D) -> Vector3:
	if n == null or not is_instance_valid(n):
		return Vector3.ZERO
	return (-n.global_basis.z).normalized()


func _planet_box() -> AABB:
	var p := safari.planet
	var rr := p.radius + 9.0
	return AABB(p.global_position - Vector3.ONE * rr, Vector3.ONE * rr * 2.0)


## One additive, unshaded, vertex-coloured material (the rings and the aurora): the one new material
## here, and every node using it is built now and warmed behind the fade.
func _additive_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.disable_receive_shadows = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	return m


## CPU sparkles on the shipped sparkle material (the planet's own diamond dust draws with it).
func _sparkles(label: String, amount: int, life: float, colour: Color, size: float) -> CPUParticles3D:
	var pr := CPUParticles3D.new()
	pr.name = label
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = PlanetPropMeshes.sparkle_material(Color(1.0, 1.0, 1.0, 0.6))
	pr.mesh = q
	pr.amount = amount
	pr.lifetime = life
	pr.local_coords = true
	pr.color = colour
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color(1, 1, 1, 1))
	ramp.add_point(0.7, Color(1, 1, 1, 0.8))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	pr.color_ramp = ramp
	pr.emitting = false
	return pr


func _place_name(d: Vector3) -> String:
	var rows: Array = [
		["the NEAR DRIFTS", _dust_dirs[0]], ["the HIGH DRIFTS", _dust_dirs[1]], ["the BACK DRIFTS", _dust_dirs[2]],
		["the LANDING PAD", safari.start_dir], ["the LONG ARRAY", _array_mid], ["VELA'S LOOKOUT", _home_dir],
		["the WEST FLOE", _floes[0]], ["the FAR FLOE", _floes[1]], ["the FROZEN LAKE", _mirror_dir],
		["the FAR SIDE", -safari.start_dir]]
	var best := ""
	var best_a := INF
	for row: Array in rows:
		var a := d.angle_to(row[1])
		if a < best_a:
			best_a = a
			best = str(row[0])
	if rad_to_deg(best_a) > 35.0:
		# nothing named near: say which way from the pad
		best = "the FAR SIDE" if rad_to_deg(d.angle_to(safari.start_dir)) > 120.0 else "the open frost"
	return best


func _player_dir() -> Vector3:
	return safari.planet.dir_of(safari.player.global_position) if is_instance_valid(safari.player) else safari.start_dir


func _tangent_at(d: Vector3) -> Vector3:
	var t := safari.start_fwd - d * safari.start_fwd.dot(d)
	if t.length() < 0.01:
		t = Vector3.RIGHT - d * d.x
	return t.normalized()


func _polar(centre: Vector3, ref: Vector3, rho_deg: float, psi_deg: float) -> Vector3:
	var r := (ref - centre * ref.dot(centre)).normalized()
	var h := r.rotated(centre, -deg_to_rad(psi_deg)).normalized()
	var a := deg_to_rad(rho_deg)
	return (centre * cos(a) + h * sin(a)).normalized()


func _xf(d: Vector3, fwd: Vector3) -> Transform3D:
	return safari.planet.surface_transform(d.normalized(), fwd)


func _xf_ground(d: Vector3, fwd: Vector3) -> Transform3D:
	var xf := _xf(d, fwd)
	var n := safari.planet.ground_normal(d.normalized())
	var f := -xf.basis.z
	f = (f - n * f.dot(n)).normalized()
	xf.basis = Basis.looking_at(f, n)
	return xf


func _toward(d: Vector3, target: Vector3) -> Vector3:
	var t := target - d * target.dot(d)
	return t.normalized() if t.length() > 0.001 else _tangent_at(d)


func _free_near(dir: Vector3, clear_m: float) -> Vector3:
	var p := safari.planet
	if p.nearest_prop_distance(dir) >= clear_m and rad_to_deg(dir.angle_to(_pad_dir)) > 15.0:
		return dir
	var t := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
	for ring_deg in [3.0, 6.0, 9.0, 12.0, 15.0, 20.0]:
		for k in 8:
			var d := dir.rotated(t.rotated(dir, TAU * float(k) / 8.0), deg_to_rad(ring_deg)).normalized()
			if p.nearest_prop_distance(d) >= clear_m and rad_to_deg(d.angle_to(_pad_dir)) > 15.0:
				return d
	return dir


func _sound(sfx: String, pitch: float, db: float, loop: bool = false) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.name = "Snd_" + sfx
	var st: Variant = load(SFX_DIR + sfx + ".wav") if ResourceLoader.exists(SFX_DIR + sfx + ".wav") else null
	if st is AudioStreamWAV and loop:
		var w := (st as AudioStreamWAV).duplicate() as AudioStreamWAV
		var bytes := 2 if w.format == AudioStreamWAV.FORMAT_16_BITS else 1
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / (bytes * (2 if w.stereo else 1))
		st = w
	a.stream = st as AudioStream
	a.pitch_scale = pitch
	a.volume_db = db
	a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(a)
	_sounds.append(a)
	return a


func _sound_once(sfx: String, pitch: float, db: float) -> AudioStreamPlayer:
	var nm := "Once_" + sfx
	var a := get_node_or_null(nm) as AudioStreamPlayer
	if a == null:
		a = _sound(sfx, pitch, db)
		a.name = nm
	a.pitch_scale = pitch
	a.volume_db = db
	return a


func _pp(d: Vector3) -> String:
	var around := rad_to_deg(safari.start_dir.angle_to(d))
	var t := d - safari.start_dir * d.dot(safari.start_dir)
	var bearing := 0.0
	if t.length() > 1e-5:
		bearing = -rad_to_deg(safari.start_fwd.signed_angle_to(t.normalized(), safari.start_dir))
	return "(%.1f, %.1f)" % [around, bearing]


func _log(msg: String) -> void:
	print("[VelaSafari] " + msg)


## Everything a test needs to find the subjects and places (probes read it; nothing else does).
func debug_places() -> Dictionary:
	return {
		"floes": _floes.duplicate(), "mirror": _mirror_dir, "dust": _dust_dirs.duplicate(), "home": _home_dir,
		"array_mid": _array_mid, "masts": _masts.map(func(m: Dictionary) -> Vector3: return m.get("dir", Vector3.ZERO)),
		"lamps": _masts.map(func(m: Dictionary) -> Vector3: return m.get("lamp", Vector3.ZERO)),
		"birds": _birds.map(func(b: Dictionary) -> Vector3: return b["pos"]),
		"bird_states": _birds.map(func(b: Dictionary) -> int: return int(b["state"])),
		"seals": _seals.map(func(s: Dictionary) -> Vector3: return s["dir"]),
		"seal_states": _seals.map(func(s: Dictionary) -> int: return int(s["state"])),
		"mites": _mites.map(func(m: Dictionary) -> Vector3: return m["dir"]),
		"krill": _krill_sw.map(func(k: Dictionary) -> Vector3: return k["dir"]),
		"eligible": _eligible.duplicate(),
		"snowman": _snowman_dir, "star": _star_dir, "teacup": _teacup_at, "masts_focus": _masts_focus.global_position \
			if _masts_focus != null else Vector3.ZERO,
		"perches": _perches.map(func(pc: Dictionary) -> Vector3: return pc["pos"]),
		"brought": pacing.brought.duplicate() if pacing != null else {},
	}
