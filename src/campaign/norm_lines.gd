extends RefCounted
## Every word Norm says (docs/NORM_SPEC.md §4, §5, §9 "NQUIZ owns norm_lines.gd"). Static data only,
## `class_name` free (loaded by path, like visitor_lines.gd), nothing here is saved.
##
## Norm's voice (NORM_SPEC.md §1, CORE_LOOP.md "the mystery neighbour"): a normal human, honestly,
## who tries hard to sound like one and gets it a little wrong ("Greetings, fellow Earth person. I
## also have one head."). Short, kind lines. He is NEVER scary and NEVER mocks the player for a wrong
## answer - a miss gets a funny line about himself, not a jab at them.
##
## Consumers (NSYS, NGIFT - docs/NORM_SPEC.md §9): pick a random entry with `.pick_random()`, e.g.
## `NormLines.RIGHT.pick_random()`. `REWARD_LINES` is keyed by the decoration item id NGIFT grants.

## First meeting ever, two short boxes shown once (NORM_SPEC §4.1).
const INTRO: Array[String] = [
	"Greetings, fellow Earth person. I am Norm. A normal human.",
	"I would like to ask you normal human questions. A human custom, I believe.",
]

## The offer box (NORM_SPEC §4.2), asked with OFFER_OPTIONS as a 2-pill `ask()`.
const OFFER := "Care for some normal human questions? Three of them."
const OFFER_OPTIONS: Array[String] = ["Sure!", "Not now"]

## Picked when the player answers "Not now" - he stays, no quiz starts (NORM_SPEC §4.2).
const NOT_NOW: Array[String] = [
	"A human choice. I respect it, as a human would.",
	"Understood. I will stand here. Normally.",
	"No questions today. I will think of better ones.",
]

## Picked after EACH right answer, before the next question (NORM_SPEC §4.3).
const RIGHT: Array[String] = [
	"Correct! A very human thing to know.",
	"Yes! I also knew that. I did.",
	"Right! My tentacle is doing the happy curl.",
	"Correct. Humans are smarter than my notes suggested.",
]

## Picked once, the moment the FIRST wrong answer ends the quiz (NORM_SPEC §4.3). Funny, never mean.
const WRONG: Array[String] = [
	"Incorrect! Do not worry, I am also often incorrect.",
	"Hm. No. My tentacle is shaking its head at both of us.",
	"Wrong! But said with great human confidence. I respect that.",
	"Not quite. I will revise my notes. Possibly yours too.",
]

## Picked after all three answers are right, before the reward box (NORM_SPEC §4.4).
const WIN: Array[String] = [
	"Three for three! A perfectly normal human score.",
	"You know this game better than I know being human.",
	"Excellent! I am filing you under 'suspiciously informed'.",
]

## Picked as he waves and leaves, win or lose (NORM_SPEC §2 "one visit per appearance").
const BYE: Array[String] = [
	"I must go. Normal human errands. Very normal.",
	"Farewell, fellow Earth person! I enjoyed my visit here.",
	"I will return another day, with more questions. Bye now.",
]

## The landing hint (NORM_SPEC §3), one per arrival, rotated by day. No arrow, no HUD marker.
const HINTS: Array[String] = [
	"Something feels a little off here...",
	"You hear someone humming. Badly.",
	"Someone left very human footprints.",
]

## One reward line per item id (NGIFT's `norm_rewards.gd` grants and speaks it), in his voice
## (NORM_SPEC §6). Keys match the decoration ids NGIFT registers: norm_trophy_bronze / _silver /
## _gold / norm_statue.
const REWARD_LINES: Dictionary = {
	"norm_trophy_bronze": [
		"For you! A bronze trophy. I found it. Somewhere honest.",
	],
	"norm_trophy_silver": [
		"Silver this time! You are becoming disturbingly human.",
	],
	"norm_trophy_gold": [
		"Gold! The last rung. I am almost proud. Humans say that.",
	],
	"norm_statue": [
		"A statue of me! Put it anywhere. I will not mind. Much.",
		"Another statue of me. I have lost count. You should keep one.",
	],
}


## Convenience: a random line from any of the arrays above (never REWARD_LINES - index that one by
## item id directly). Callers may also call `.pick_random()` on the const themselves; this exists so
## a caller does not need to null-check an empty array.
static func random_line(lines: Array[String]) -> String:
	if lines.is_empty():
		return ""
	return lines.pick_random()


## The reward line for `item_id`, or a plain fallback if NGIFT ever grants an id with no entry here.
static func reward_line(item_id: String) -> String:
	var lines: Array = REWARD_LINES.get(item_id, [])
	if lines.is_empty():
		return "For you! A normal human gift."
	return str(lines.pick_random())
