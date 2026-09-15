extends RefCounted
## FINALE LINES (docs/PHASE5_SPEC.md §3 "Home is here", word for word). Data-only: no logic, so a
## builder that needs the words never has to parse dialogue_box calls to find them, and this file can
## be diffed straight against the spec text. Every quoted string in §3 is a "box" - one call to
## DialogueBox.show_lines / DialogueRunner.say shows one array of boxes as one turn.
##
## docs/BUILD_PLAN.md Phase 5, builder L0 (this file), owned afterwards by K (flow), K2 (meeting) and
## G (gift) as they consume it - they do not edit it; a wording change goes back to the lead against
## PHASE5_SPEC.md §3.
##
## ============================================================================== SHAPE
## Each beat below is an Array[Dictionary], in spec order, of turns shaped one of:
##   {"speaker": <npc id>, "lines": [<box>, ...]}                    - a spoken turn
##   {"speaker": <npc id>, "camera": <letter>, "lines": [<box>, ...]}  - spoken, camera-tagged (§2)
##   {"action": <stage direction>}                                    - not spoken, no box
##   {"speaker": <npc id>, "ask": {"prompt": <box>, "options": [<label>, ...]}} - a DialogueRunner.ask
##   {"toast": <text>}                                                - EventBus.toast_requested, not a box
## `speaker` is the npc id DialogueRunner already resolves display name / voice / accent from
## (npc_data.gd): zorp, bolt, fen, grig, vela, pip, pop, mayor_orbit (Professor Comet), dj_nova.
## `camera` is one of the meeting beat's own rule letters (§2: W shoulder, P speaker, U crowd-up,
## S side-on, R pad three-quarter) - "" where §3 names no camera for that line. The final ask of the
## Meeting beat continues the S framing in the prose but the spec text tags no letter on the ask line
## itself, so it is left "" here rather than guessed; the meeting builder decides what that ask keeps.
##
## Every box is <= 60 characters (checked below in a comment, not code - this is data only). None in
## this build ran long enough to need flagging or rewording.

## ------------------------------------------------------------------------------------- CALL (home)
## Professor Comet's radio call (RadioSpeaker "mayor_orbit"). Ends on a choice; "What is it?" branches
## to CALL_WHAT_IS_IT below, "On my way" falls straight through to the Meeting beat with no reply line.
const CALL: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": [
		"Professor Comet here. Oh my. She's GOLD!",
		"You could fly all the way home now.",
	]},
	{"speaker": "mayor_orbit", "lines": [
		"But hold on. Something big is on my scope.",
		"I checked twice. Then I found my glasses.",
	]},
	{"speaker": "mayor_orbit", "ask": {
		"prompt": "Come to the Commons? I'm calling everyone.",
		"options": ["On my way", "What is it?"],
	}},
]
## The reply when "What is it?" is chosen.
const CALL_WHAT_IS_IT: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": ["Better seen than said. Do come. Nobody panic."]},
]

## ------------------------------------------------------------------------------------- MEETING (Commons)
## Sequential; the last entry is the Send/Moment choice (see MOMENT and SEND below for the branches).
const MEETING: Array[Dictionary] = [
	{"speaker": "zorp", "lines": ["You came! Everyone came! Even Grig came!"]},
	{"speaker": "grig", "lines": ["Closed the steps. All nine hundred and four."]},
	{"speaker": "mayor_orbit", "lines": [
		"Thank you all for coming. Now, look up.",
		"Just there, above the pad. See it?",
	]},
	{"speaker": "mayor_orbit", "camera": "U", "lines": ["A giant asteroid. It's headed for our worlds."]},
	{"speaker": "bolt", "lines": ["I ran its path forty times. Five worlds. Every time."]},
	{"speaker": "vela", "lines": [
		"The array heard it three nights ago.",
		"I filed it under 'unexplained'. I was wrong.",
	]},
	{"speaker": "fen", "lines": ["Nine years of notes. Nothing this size, ever."]},
	{"speaker": "pip", "lines": ["We could hide in the stockroom..."]},
	{"speaker": "pop", "lines": ["...no, we couldn't. It's full of lamps."]},
	{"speaker": "zorp", "lines": ["Unless something fast hits it first. VERY fast."]},
	{"action": "all turn to the rocket"},
	{"speaker": "bolt", "camera": "S", "lines": ["Your rocket is fast. Five parts. From us."]},
	{"speaker": "mayor_orbit", "camera": "S", "lines": [
		"She's your way home. Nobody will ask it of you.",
		"But she's the only thing that could do it.",
	]},
	{"speaker": "mayor_orbit", "ask": {
		"prompt": "It's your rocket. What would you like to do?",
		"options": ["Give me a moment", "Send her"],
	}},
]

## ------------------------------------------------------------------------------------- MOMENT (free roam)
## "Give me a moment": free roam, a line each, then the Professor re-asks (MEETING's last entry again).
const MOMENT: Array[Dictionary] = [
	{"speaker": "mayor_orbit", "lines": ["Take all the time you need. We'll be right here."]},
	{"speaker": "zorp", "lines": ["Whatever you choose, you're still my best friend."]},
	{"speaker": "bolt", "lines": ["Friendship does not need a rocket. I checked."]},
	{"speaker": "fen", "lines": ["Sit a while. The sky will wait. It always has."]},
	{"speaker": "grig", "lines": ["Steps can be cut again. A world cannot."]},
	{"speaker": "vela", "lines": ["Take your time. Good answers are rarely quick."]},
]

## ------------------------------------------------------------------------------------- SEND (send-off)
## "Send her": two boxes before ignition (the crowd steps back, the ladder stows, the astronaut waves).
const SEND: Array[Dictionary] = [
	{"speaker": "bolt", "lines": ["Autopilot set. Passengers: zero. Course: true."]},
	{"speaker": "mayor_orbit", "lines": ["Everyone, stand back from the pad!"]},
]

## ------------------------------------------------------------------------------------- GIFT
## Ends with a toast, not a spoken box (EventBus.toast_requested, per FinaleGift.finished).
const GIFT: Array[Dictionary] = [
	{"speaker": "dj_nova", "lines": ["Best. Light show. EVER!"]},
	{"speaker": "zorp", "lines": [
		"One more! Did you see?",
		"Okay. Don't look at the pad.",
		"...Now look at the pad!",
	]},
	{"speaker": "mayor_orbit", "lines": [
		"We started her the day you crashed.",
		"Everyone gave a piece.",
	]},
	{"speaker": "bolt", "lines": [
		"One gold panel fell off your rocket. I kept it.",
		"It is the hatch now. Polished 88 times.",
	]},
	{"speaker": "zorp", "lines": [
		"It has knees! Three! Like you, but more!",
		"The antenna is mine. It glows when happy.",
	]},
	{"speaker": "fen", "lines": ["The lamp on the front is mine. For long dusks."]},
	{"speaker": "grig", "lines": [
		"I cut the ladder. Eleven rungs. All numbered.",
		"Small. Won't reach your old home.",
		"Reaches all of ours.",
	]},
	{"speaker": "vela", "lines": ["The little dish is mine. I will always hear you."]},
	{"speaker": "mayor_orbit", "lines": [
		"You gave up one way home.",
		"So we built you another. Welcome home.",
	]},
	{"toast": "Every world is open. Planet stats are back."},
]
