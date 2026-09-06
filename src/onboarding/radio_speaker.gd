class_name RadioSpeaker
extends Node3D
## A speaker that is not standing in front of you — Mayor Orbit on the radio, an announcement, a
## letter read aloud. `DialogueRunner` looks for exactly these four properties on whatever node it
## is handed, so a RadioSpeaker parented to the player gives a normal-looking conversation (name
## tag, voice blips, camera push-in on the astronaut listening) with nobody physically there.
##
##   var radio := RadioSpeaker.make("mayor_orbit_radio", "Mayor Orbit (radio)", "elder", Color("#c9a15c"))
##   player.add_child(radio)
##   radio.position = Vector3(0.0, 0.35, -1.0)     # just in front, so the camera has something to aim at
##   await DialogueRunner.get_or_create(self).say(radio, ["Ahoy?"])

@export var npc_id: String = ""
@export var display_name: String = ""
@export var voice_profile: String = "elder"
@export var accent_color: Color = Color("#c9a15c")


static func make(id: String, shown_name: String, voice: String, accent: Color) -> RadioSpeaker:
	var s := RadioSpeaker.new()
	s.name = "RadioSpeaker"
	s.npc_id = id
	s.display_name = shown_name
	s.voice_profile = voice
	s.accent_color = accent
	return s
