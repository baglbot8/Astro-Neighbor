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
			pip.variant = "pip"
			pip.skin = Color("#93c169")
			pip.antenna_count = 1
			pip.bounce_phase = 0.0
			return pip
		"pop":
			var pop := TwinModel.new()
			pop.variant = "pop"
			pop.skin = Color("#c1ca70")
			pop.antenna_count = 2
			pop.bounce_phase = 0.85
			return pop
		"stella":
			return TailorModel.new()
		"mayor_orbit":
			return MayorModel.new()
		"dj_nova":
			return DJModel.new()
		"fen":
			return FenModel.new()
		"grig":
			return GrigModel.new()
		"vela":
			return VelaModel.new()
		_:
			# NOTE: an unregistered id lands here silently, so a typo in an npc id or a new
			# neighbour whose case was never added ships as a generic alien with no error.
			return AlienModel.new()
