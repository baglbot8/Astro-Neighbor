extends RefCounted
## FINALE LINES - "Don't Move Out", THE PARTY VERSION (docs/STORY_HOME_SPEC.md §8 and §8.1, the user's own
## order, 2026-09-27; voices per docs/CAST_VOICES_DRAFT.md with §8.1's changes). It replaced §5.7's convoy
## meeting on 2026-09-27: a goodbye party; the neighbours say they are staying and everyone agrees; DJ Nova
## reminds them the meteor is still coming; Vela's idea (knock it off course with his ship); everyone offers
## their ship; Stella: a moving meteor is hard to hit on autopilot; the Professor: "We need a target" - you
## land on it and mark its weak spots (the meteor survey, §9.1/§9.2, `MeteorSurvey.run`); back on the Commons
## the ships fly on autopilot to your beacons while everyone watches; they come back bruised but
## working; Pip and Pop will fix them; a party; the self-timer group photo. Data-only: no logic, so a builder
## that needs the words never has to parse dialogue calls to find them, and this file can be diffed
## straight against the spec text. Every quoted string is a "box" - one call to DialogueRunner.say
## shows one array of boxes as one turn.
##
## Owned by the finale builder; a wording change goes back to the lead against STORY_HOME_SPEC §8.
##
## ============================================================================== SHAPE
## Each beat below is an Array[Dictionary], in spec order, of turns shaped one of:
##   {"speaker": <npc id>, "lines": [<box>, ...]}                    - a spoken turn
##   {"speaker": <npc id>, "camera": <letter>, "lines": [<box>, ...]}  - spoken, camera-tagged
##   {"action": <stage direction>, "id": <what the beat does>}        - not spoken, no box
##   {"speaker": <npc id>, "ask": {"prompt": <box>, "options": [<label>, ...]}} - a DialogueRunner.ask
##   {"toast": <text>}                                                - EventBus.toast_requested, not a box
## `speaker` is the npc id DialogueRunner resolves display name / voice / accent from (npc_data.gd):
## zorp, bolt, fen, grig, vela, pip, pop, mayor_orbit (Professor Comet), dj_nova; "moss" (MOSS_* only) is
## Moss himself (MossNPC, no npc_data entry), spawned for his beat by finale_meeting.gd.
## `camera` is one of the meeting's rule letters (docs/PHASE5_SPEC.md §2: W shoulder, P speaker, U crowd-up,
## S side-on, R pad three-quarter), only where §5.7 tags one ([U], [S]).
## An action's `id` is what finale_meeting.gd / finale_gift.gd key on (the `action` text is the stage
## direction, kept for the trace): "scrapbook" the Professor holds up your scrapbook (unused since §9.1), "silence" nobody
## moves, "pause" a short pause on the whole crowd, "cheer" everyone agrees (each cheers at its own offset),
## "turn" all turn to the player, "launch" the six ships fly off on autopilot (finale_launch.gd plays it),
## "return" the ships and your rocket land back on the Commons, bruised (finale_gift.gd), "party" the
## party (music, everyone celebrating), "photo" the group photo (finale_gift.gd).
##
## Every box is <= 60 characters (the project's LINE_MAX; STORY_HOME_SPEC §2 ruling 12), measured on
## this file by the builder.

## ------------------------------------------------------------------------------------- CALL (home)
## Professor Comet's radio call (RadioSpeaker "mayor_orbit"). Ends on a choice; "A party?" branches to
## CALL_ALREADY below, "On my way" falls straight through to the party with no reply line.
const CALL: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": [
		"Professor Comet here. Oh my. She's GOLD!",
		"You could fly all the way home now.",
	]},
	{"speaker": "mayor_orbit", "lines": [
		"Well. That's the last ship ready to go.",
		"So before everyone leaves: a goodbye party!",
	]},
	{"speaker": "mayor_orbit", "ask": {
		"prompt": "It's on the Commons. Will you come?",
		"options": ["On my way", "A party?"],
	}},
]
## The reply when "A party?" is chosen.
const CALL_ALREADY: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": ["A goodbye party, friend. Everyone will be there."]},
]

## ------------------------------------------------------------------------------------- SIGNAL (home, part 4)
## Vela on the radio after the FOURTH part's celebration (docs/JUNGLE_PLANET_SPEC.md 6: "The Tangle opens
## mid-game, after the 4th part: Vela hears a strange signal; it appears on the rocket map"). finale.gd
## `_run_signal_call` sets GameState flag "jungle_open" as it starts, then plays these; SIGNAL_TOAST after.
## Voice: CAST_VOICES_DRAFT Vela - gentle, dreamy, listens to far-off sounds, his bulb lights up.
const SIGNAL: Array[Dictionary] = [
	{"speaker": "vela", "lines": [
		"Hello? It's Vela. My dishes heard something new.",
		"A strange signal, from a planet I never knew.",
		"I put it on your rocket map. My bulb is curious!",
	]},
]
const SIGNAL_TOAST := "The Tangle is on your rocket map."

## ------------------------------------------------------------------------------------- MOSS (the party)
## MEETING's "moss" action (docs/JUNGLE_PLANET_SPEC.md 6: "At the farewell party Moss arrives (introduced by
## the Professor if you never met him) with a crate of glow pods from the jungle as party lights"). Moss is a
## retired field photographer (§6 rulings); voice: MossLines (slow, warm, "the swamp says" at most once).
## NEW when GameState flag "moss_met" is false, MET when true; then ARRIVE, the pods fly out, then LEAVE.
const MOSS_NEW: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": [
		"Oh my! Everyone, this is Moss, from The Tangle.",
		"He takes photos. He hardly ever leaves his swamp!",
	]},
]
const MOSS_MET: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": ["Moss! All the way from The Tangle!"]},
]
const MOSS_ARRIVE: Array[Dictionary] = [
	{"speaker": "moss", "lines": [
		"The swamp told me there was a party.",
		"So I brought glow pods. They shine all night.",
	]},
]
const MOSS_LEAVE: Array[Dictionary] = [
	{"speaker": "moss", "lines": ["Too many feet for me. Goodnight, all."]},
]

## ------------------------------------------------------------------------------------- MEETING (the party)
## The goodbye party on the Commons at night; the five packed ships stand round the square
## (neighbour_ships.gd). Sequential; the last entry is the choice (MOMENT and SEND below are the branches).
const MEETING: Array[Dictionary] = [
	# The party.
	{"speaker": "mayor_orbit", "lines": [
		"You made it! Welcome to the goodbye party!",
		"One last night together, before everyone goes.",
	]},
	{"speaker": "dj_nova", "lines": ["YO! Last party on the Commons. Make it LOUD!"]},
	{"speaker": "zorp", "lines": ["Oh ho! A party! My moustache is wiggling!"]},
	{"speaker": "grig", "lines": ["Hmph. I closed my stairs for the day. For this."]},
	# Moss arrives with a crate of glow pods for the party lights (docs/JUNGLE_PLANET_SPEC.md 6); the words are
	# MOSS_PARTY below (finale_meeting.gd `_moss_beat` picks MET or NEW from GameState flag "moss_met").
	{"action": "Moss walks in with a crate of glow pods; they fly out round the square as party lights; he goes home", "id": "moss"},
	{"speaker": "mayor_orbit", "lines": [
		"Before you all fly off, a little toast.",
		"To the kindest neighbours in the whole sky.",
	]},
	{"action": "a short pause; nobody says anything", "id": "pause"},
	# One by one: they are staying.
	{"speaker": "zorp", "lines": [
		"Hmm. May an old fellow say something?",
		"The chime on my world. I fall asleep to it.",
		"I can't leave it. I'm staying!",
	]},
	{"speaker": "bolt", "lines": [
		"I have news too. I checked 212 other masts.",
		"None of them fit me like mine. I am staying.",
	]},
	{"speaker": "fen", "lines": [
		"I sprouted by my pool. My roots are there.",
		"I'm not going either. I'm staying.",
	]},
	{"speaker": "grig", "lines": [
		"Best view there is, from the top of my hill.",
		"I'm staying. Somebody had to say it.",
	]},
	{"speaker": "vela", "lines": [
		"I look at my photo of home every night.",
		"My bulb is glowing. I'm staying too!",
	]},
	{"speaker": "pip", "lines": ["Don't tell anyone. We never packed the lamps."]},
	{"speaker": "pop", "lines": ["I kept my box open. Now I can unpack! Yay!"]},
	{"speaker": "stella", "lines": ["Then I'm staying too, darling. Obviously."]},
	{"speaker": "mayor_orbit", "lines": ["Then... everyone is staying?"]},
	{"action": "everyone agrees: a cheer, each at its own moment", "id": "cheer"},
	# The reminder, looking up at the meteor.
	{"speaker": "dj_nova", "camera": "U", "lines": ["Uh... just a reminder that METEOR'S still coming for us!"]},
	{"action": "silence; nobody moves", "id": "silence"},
	# Vela's idea; everyone offers their ship.
	{"speaker": "vela", "lines": [
		"Oh! My bulb just lit up. I have an idea!",
		"My ship could knock the meteor off course!",
	]},
	{"speaker": "mayor_orbit", "lines": [
		"A brave idea, Vela. But one ship won't do it.",
		"That meteor is far too big.",
	]},
	{"speaker": "bolt", "lines": ["Then take my ship too. That makes 2."]},
	{"speaker": "zorp", "lines": ["And mine! She's old, like me, but she flies!"]},
	{"speaker": "fen", "lines": ["Take mine as well. Slow, but steady."]},
	{"speaker": "grig", "lines": ["Hmph. Mine too. Bring it back in one piece."]},
	{"speaker": "mayor_orbit", "lines": ["Every ship! Nobody aboard, mind. Autopilot."]},
	# Stella's worry; the Professor's answer: a target (docs/STORY_HOME_SPEC.md §9.1 - this replaced "I can
	# track its path with your photos" on 2026-09-28).
	{"speaker": "stella", "lines": [
		"Autopilot, darling? At a meteor that moves?",
		"That will be very hard to hit.",
	]},
	{"speaker": "mayor_orbit", "lines": [
		"Quite right, Stella. We need a target.",
		"Someone has to land on it and mark its weak spots.",
		"Plant Moss's glow pods there. Autopilots see the glow!",
	]},
	# You.
	{"action": "all turn to the player", "id": "turn"},
	{"speaker": "mayor_orbit", "camera": "S", "lines": [
		"Your rocket is the fastest ship we have.",
		"And nobody takes a better photo than you.",
	]},
	{"speaker": "mayor_orbit", "ask": {
		"prompt": "Will you land on the meteor and mark it?",
		"options": ["Give me a moment", "I'll go!"],
	}},
]

## ------------------------------------------------------------------------------------- MOMENT (free roam)
## "Give me a moment": free roam, a line each, then the Professor re-asks (MEETING's last entry again).
const MOMENT: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": ["Take all the time you need. We'll be right here."]},
	{"speaker": "zorp", "lines": ["Whatever you choose, you're still my best friend."]},
	{"speaker": "bolt", "lines": ["I ran the odds on a meteor landing. They are good."]},
	{"speaker": "fen", "lines": ["Sit in the warm with me a while. Then decide."]},
	{"speaker": "grig", "lines": ["Hmph. Nobody's pushing. Your call. Fair's fair."]},
	{"speaker": "vela", "lines": ["Take your time. Good answers are rarely quick."]},
]

## ------------------------------------------------------------------------------------- SEND (after the survey)
## "I'll go!" runs the meteor survey (finale.gd, `MeteorSurvey.run`); back on the Commons, two turns; everyone
## steps back and the six ships fly off on autopilot to your beacons, your rocket in front, while everyone
## watches from the Commons (finale_launch.gd); they hit the meteor and it breaks into a shower.
const SEND: Array[Dictionary] = [
	{"speaker": "bolt", "lines": ["Five beacons, locked! I counted twice."]},
	{"speaker": "mayor_orbit", "lines": [
		"Wonderful work, friend! Autopilot on.",
		"Every ship, to your beacons. Stand back!",
	]},
	{"action": "six ships fly off on autopilot to your five beacons, yours in front; everyone watches from the Commons; the meteor breaks into a shower", "id": "launch"},
]

## ------------------------------------------------------------------------------------- HOME (the ships come back; the party)
## Everyone on the Commons under the shower. Ends with a toast, not a spoken box.
const HOME: Array[Dictionary] = [
	{"speaker": "dj_nova", "lines": ["Best. Light show. EVER!"]},
	{"speaker": "zorp", "lines": ["Ho ho! We did it! It's all sparkles now!"]},
	{"speaker": "mayor_orbit", "lines": [
		"A meteor shower. The safe kind.",
		"Our whole solar system is safe.",
	]},
	{"action": "a short pause, looking up", "id": "pause"},
	{"speaker": "fen", "lines": ["Look up, friends. Lights, coming down."]},
	{"action": "the ships and your rocket come back and land, bruised but working", "id": "return"},
	{"speaker": "bolt", "lines": ["They all came back! 37 dents. Still working."]},
	{"speaker": "grig", "lines": ["Hmph. Scratched. ...Worth it."]},
	{"speaker": "pip", "lines": [
		"Dents? Bring them to Cosmo Depot, customers!",
		"Pop and I will fix every ship. For free!",
	]},
	{"speaker": "pop", "lines": ["I'm good at fixing! Oops. I'm mostly good."]},
	{"speaker": "mayor_orbit", "lines": ["Well then. I'd say this calls for a party."]},
	{"speaker": "dj_nova", "lines": ["A REAL party this time! Everybody dance!"]},
	{"action": "the party: music, everyone celebrating", "id": "party"},
	{"speaker": "vela", "lines": ["Listen. It sounds like home."]},
	{"speaker": "bolt", "lines": ["One more thing. A photo of all 11 of us."]},
	{"action": "the player takes the group photo; it becomes the scrapbook's last page", "id": "photo"},
	{"speaker": "mayor_orbit", "lines": [
		"Your ship still flies. You could go anywhere.",
		"But I think you're home. Welcome home.",
	]},
	{"toast": "Every world is open. Planet stats are back."},
]
