class_name PlanetGearTree
extends StaticBody3D
## Gear tree: stacked cogs on a pole. Each gear child rotates (alternating directions, meshing speeds).

var _gears: Array[MeshInstance3D] = []
var _speeds: PackedFloat32Array = PackedFloat32Array()

func add_gear(gear: MeshInstance3D, speed: float) -> void:
	_gears.append(gear)
	_speeds.append(speed)

func _process(delta: float) -> void:
	for i in _gears.size():
		_gears[i].rotate_y(_speeds[i] * delta)
