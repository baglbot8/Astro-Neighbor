class_name RadioSpeaker
extends Node3D
## A speaker that is not standing in front of you — Mayor Orbit on the radio, an announcement, a
## letter read aloud. `DialogueRunner` looks for exactly these four properties on whatever node it
## is handed, so a RadioSpeaker parented to the player gives a normal-looking conversation (name
## tag, comms voice, camera push-in on the astronaut listening) with nobody physically there.
##
##   var radio := RadioSpeaker.make("mayor_orbit_radio", "Mayor Orbit (radio)", "elder", Color("#c9a15c"))
##   player.add_child(radio)
##   radio.position = Vector3(0.0, 0.35, -1.0)     # just in front, so the camera has something to aim at
##   await DialogueRunner.get_or_create(self).say(radio, ["Ahoy?"])
##
## VOICE ROUTING. Every neighbour now talks over comms in their OWN voice (AudioManager "comms
## voices"), and the opening radio call is where the player first hears one - so it has to be Mayor
## Orbit's voice, not a shared "elder" profile. `make()` therefore resolves the voice from the id:
## "mayor_orbit_radio" -> NpcData "mayor_orbit" -> its voice_profile ("mayor_orbit"). The `voice`
## argument is only used when the id names no neighbour (a generic announcement), and a legacy
## profile there ("elder") is still understood by AudioManager.comms_voice_for.

@export var npc_id: String = ""
@export var display_name: String = ""
@export var voice_profile: String = ""
@export var accent_color: Color = Color("#c9a15c")


static func make(id: String, shown_name: String, voice: String, accent: Color) -> RadioSpeaker:
	var s := RadioSpeaker.new()
	s.name = "RadioSpeaker"
	s.npc_id = id
	s.display_name = shown_name
	s.voice_profile = resolve_voice(id, voice)
	s.accent_color = accent
	return s


## The comms voice for a radio speaker id: the neighbour's own voice when the id (minus a "_radio"
## suffix) names one in NpcData, otherwise `fallback` unchanged.
static func resolve_voice(id: String, fallback: String) -> String:
	var d := NpcData.get_data(id.trim_suffix("_radio"))
	if not d.is_empty() and str(d.get("voice_profile", "")) != "":
		return str(d.get("voice_profile"))
	return fallback
