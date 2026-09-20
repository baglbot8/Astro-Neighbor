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
			# 2026-09-15: Pip rides a saucer now (pip_model.gd), not the Pip half of TwinModel.
			return PipModel.new()
		"pop":
			# 2026-09-15: Pop is his own fuzzy-monster model now, not the Pop half of TwinModel.
			return PopFluffModel.new()
		"stella":
			return TailorModel.new()
		"mayor_orbit":
			return MayorModel.new()
		"dj_nova":
			return DJModel.new()
		"fen":
			# 2026-09-15: Fen's third look (fen_vine_model.gd): vine limbs and a petal collar.
			return FenVineModel.new()
		"grig":
			return GrigModel.new()
		"vela":
			return VelaModel.new()
		"norm":
			return NormModel.new()
		_:
			# NOTE: an unregistered id lands here silently, so a typo in an npc id or a new
			# neighbour whose case was never added ships as a generic alien with no error.
			return AlienModel.new()
