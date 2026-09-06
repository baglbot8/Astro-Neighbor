class_name PlanetSurvey
extends Node
## Headless placement-decorability survey for the PLANET builder.
##
## The integration critic found Zorp effectively undecoratable (20.1% of the sphere free at a 0.6 m
## footprint against home's 70.5%), which is a planet-side problem: too many props, too much slope,
## too much water and shore. This scene answers the same question the game does — it asks the real
## `DecorationManager.spot_block_reason()` — so a change to a planet's terrain or prop budget can be
## measured instead of guessed.
##
## Run: godot --headless --path . res://showcase/planet_survey.tscn
## Prints one line per planet per footprint, plus the breakdown of WHY spots are refused.

const SAMPLES := 4000
const FOOTPRINTS: Array[float] = [0.6, 0.9]

func _ready() -> void:
	for id in ["home", "hub", "zorp", "bolt"]:
		_survey(id)
	get_tree().quit()

func _survey(id: String) -> void:
	var path := "res://src/planet/data/%s.tres" % id
	var data: PlanetData = load(path)
	var planet: Planet = load("res://src/planet/planet.tscn").instantiate()
	planet.name = "Planet"
	planet.data = data
	add_child(planet)
	var deco := DecorationManager.new()
	deco.name = "Decorations"
	add_child(deco)
	deco.planet = planet
	# Same rule inputs the live manager caches on _ready (no NPCs or placed items in a fresh world).
	deco.set("_reserved_cache", planet.get_reserved_dirs())
	for fp in FOOTPRINTS:
		var counts: Dictionary = {}
		var free := 0
		for i in SAMPLES:
			# Deterministic near-uniform sphere sampling (Fibonacci spiral).
			var t := (float(i) + 0.5) / float(SAMPLES)
			var y := 1.0 - 2.0 * t
			var r := sqrt(maxf(0.0, 1.0 - y * y))
			var phi := float(i) * 2.399963229728653
			var d := Vector3(cos(phi) * r, y, sin(phi) * r)
			var why := deco.spot_block_reason(d, fp)
			if why == "":
				free += 1
			else:
				counts[why] = int(counts.get(why, 0)) + 1
		var parts: Array[String] = []
		var keys: Array = counts.keys()
		keys.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
		for k in keys:
			parts.append("%s %.1f%%" % [k, 100.0 * float(counts[k]) / float(SAMPLES)])
		print("SURVEY %-5s fp %.1f: free %5.1f%%   (%s)" % [id, fp, 100.0 * float(free) / float(SAMPLES), ", ".join(parts)])
	deco.queue_free()
	planet.queue_free()
