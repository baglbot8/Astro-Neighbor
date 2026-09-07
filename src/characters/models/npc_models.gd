class_name NpcModels
extends RefCounted
## One place that maps a neighbour id to its procedural model, so the NPC scenes, the lineup showcase
## and any future mannequin all build the same character.
##
##   var m := NpcModels.make("bolt")     # -> RobotModel


## Builds the model for a neighbour id (unknown ids fall back to the alien).
static func make(npc_id: String) -> CharacterModel:
	match npc_id:
		"bolt":
			return RobotModel.new()
		"pip":
			var pip := TwinModel.new()
			pip.skin = Color("#93c169")
			pip.antenna_count = 1
			pip.stalk_style = "tall"
			pip.bounce_phase = 0.0
			return pip
		"pop":
			var pop := TwinModel.new()
			pop.skin = Color("#c1ca70")
			pop.antenna_count = 2
			pop.stalk_style = "closeset"
			pop.bounce_phase = 0.85
			return pop
		"stella":
			return TailorModel.new()
		"mayor_orbit":
			return MayorModel.new()
		"dj_nova":
			return DJModel.new()
		_:
			return AlienModel.new()
