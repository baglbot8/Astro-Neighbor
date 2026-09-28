extends SafariWorld
## PLACEHOLDER SAFARI CONTENT (builder P3). Proves the API end to end with ONE subject and ONE timed
## event; runs on any planet in PlanetSafari.PLANETS that has no `worlds/<planet_id>.gd` yet. Builder P4
## replaces it for Bolt with `src/planet_safari/worlds/bolt.gd` - nothing else needs to change, and
## this file can stay as the fallback (or be deleted once every safari planet has its own script).
##
##   SUBJECT  "Scrap Sprite" - a little cream cog-ball that bobs and turns a quarter of the way round
##            the planet to the right of the start, all three minutes. Common. Its MOMENT is the top
##            of its bob (x1.4) - so a picture timed at the top beats one timed anywhere else.
##   EVENT    "Pillar of Steam" - on the FAR SIDE, 0:20-0:40, warned 8 s ahead by a line on screen and
##            a hiss, then a column of puffs rises. Its subject is the column itself (uncommon), awake
##            only while the event runs; its moment is the middle five seconds (x1.8).
## Deliberately plain, in the Moonstone palette's cream and amber, so no one mistakes it for content.

const SPRITE_AROUND := 90.0
const SPRITE_BEARING := 90.0
const PILLAR_AROUND := 180.0
const PILLAR_START := 20.0
const PILLAR_END := 40.0
const PILLAR_WARN := 8.0

var _sprite: Node3D
var _sprite_base := Transform3D()
var _pillar: Node3D
var _pillar_glow: MeshInstance3D
var _pillar_dir := Vector3.UP
var _puff_clock := 0.0


func build(s: PlanetSafari) -> void:
	# ---- the subject
	var mat := StandardMaterial3D.new()
	mat.albedo_color = UIStyle.CREAM
	mat.roughness = 0.8
	var amber := StandardMaterial3D.new()
	amber.albedo_color = UIStyle.YELLOW
	amber.roughness = 0.6
	_sprite = Node3D.new()
	_sprite.name = "ScrapSprite"
	add_child(_sprite)
	var ball := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.28
	bm.height = 0.56
	bm.radial_segments = 16
	bm.rings = 8
	ball.mesh = bm
	ball.material_override = mat
	_sprite.add_child(ball)
	var cog := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.30
	tm.outer_radius = 0.42
	tm.rings = 16
	tm.ring_segments = 6
	cog.mesh = tm
	cog.material_override = amber
	cog.rotation_degrees = Vector3(90, 0, 0)
	_sprite.add_child(cog)
	var sd := s.dir_from_start(SPRITE_AROUND, SPRITE_BEARING)
	_sprite_base = s.surface_xform(sd)
	_sprite.global_transform = _sprite_base.translated_local(Vector3(0, 1.2, 0))
	s.add_subject({
		"id": "placeholder_sprite",
		"name": "Scrap Sprite",
		"rarity": 1,
		"band": Vector2(0.18, 0.5),
		"node": _sprite,
		"radius": 0.42,
		"kind": "creature",
		"moment": func(t: float) -> Dictionary:
			return {"mult": 1.4, "line": "at the top of its bob"} if sin(t * 1.6) > 0.9 else {"mult": 1.0, "line": ""},
	})
	# ---- the event
	_pillar_dir = s.dir_from_start(PILLAR_AROUND, 0.0)
	_pillar = Node3D.new()
	_pillar.name = "PillarOfSteam"
	add_child(_pillar)
	_pillar.global_transform = s.surface_xform(_pillar_dir)
	_pillar_glow = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.6
	cm.height = 4.0
	cm.radial_segments = 12
	cm.rings = 1
	_pillar_glow.mesh = cm
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(UIStyle.CREAM, 0.55)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pillar_glow.material_override = glow
	_pillar_glow.position = Vector3(0, 2.0, 0)
	_pillar.add_child(_pillar_glow)
	_pillar.visible = false
	s.add_subject({
		"id": "placeholder_pillar",
		"name": "Pillar of Steam",
		"rarity": 2,
		"band": Vector2(0.35, 0.9),
		"node": _pillar,
		"offset": Vector3(0, 2.0, 0),
		"radius": 1.6,
		"kind": "event",
		"event": "placeholder_pillar",
		"moment": func(t: float) -> Dictionary:
			var mid := (PILLAR_START + PILLAR_END) * 0.5
			return {"mult": 1.8, "line": "at full height"} if absf(t - mid) <= 2.5 else {"mult": 1.0, "line": ""},
	})
	s.add_event({
		"id": "placeholder_pillar",
		"name": "Pillar of Steam",
		"start": PILLAR_START,
		"end": PILLAR_END,
		"warn": PILLAR_WARN,
		"dir": _pillar_dir,
		"when": "any",
		"rare": "any",
		"overlap_ok": true,
		"on_warn": func(_ev: Dictionary) -> void:
			s.announce("Something hisses on the far side...", 3.0)
			AudioManager.play_sfx("shooting_star", -4.0),
		"on_start": func(_ev: Dictionary) -> void:
			_pillar.visible = true
			s.puff_at(s.ground_point(_pillar_dir, 0.3), 24),
		"on_tick": func(_ev: Dictionary, t_in: float, delta: float) -> void:
			var k := clampf(t_in / 3.0, 0.0, 1.0)
			_pillar_glow.scale = Vector3(1.0, maxf(k, 0.05), 1.0)
			_pillar_glow.position.y = 2.0 * k
			_puff_clock -= delta
			if _puff_clock <= 0.0:
				_puff_clock = 0.6
				s.puff_at(s.ground_point(_pillar_dir, 0.2 + 3.5 * k), 8),
		"on_end": func(_ev: Dictionary) -> void:
			s.puff_at(s.ground_point(_pillar_dir, 1.0), 20)
			_pillar.visible = false,
	})


func tick(t: float, _delta: float) -> void:
	if _sprite != null:
		_sprite.global_transform = _sprite_base.translated_local(Vector3(0, 1.2 + 0.25 * sin(t * 1.6), 0)) \
			* Transform3D(Basis(Vector3.UP, t * 0.8), Vector3.ZERO)


func go_to_sleep() -> bool:
	return false
