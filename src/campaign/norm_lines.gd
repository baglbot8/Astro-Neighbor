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
	"I would like to ask normal human questions. A human custom.",
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
	"Wow! You really know your human facts.",
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
		"For you! A bronze trophy. A very normal gift.",
	],
	"norm_trophy_silver": [
		"Silver this time! Surprisingly human of you.",
	],
	"norm_trophy_gold": [
		"Gold! The top prize. I am almost proud. Humans say that.",
	],
	"norm_statue": [
		"A statue of me! Put it anywhere. I will not mind. Much.",
		"Another statue of me. I've lost count. You should keep one.",
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


# ============================================================================= THE STAMP CARD
# docs/DAILY_STAMPS_SPEC.md 2 (2026-10-01): Norm is the stamp card's mascot. Same voice as above -
# a normal human who gets human things a little wrong - in short, plain words a kid can read. Every
# line is one dialogue box (60 characters or fewer). src/stamps/stamp_system.gd speaks them.

## The first card ever, after INTRO if he has never been met.
const STAMP_INTRO: Array[String] = [
	"I made you a card! Humans love small cards.",
	"Do any 3 things on it and I stamp it. Thunk! Like that.",
	"5 stamps in a week and you get a prize. A normal one.",
	"A new card every day. I have so many cards.",
]

## ONE of these opens every talk at his stamp spot, picked by the real date (`stamp_daily`), so the
## line changes each day and a week never repeats one.
const STAMP_DAILY: Array[String] = [
	"Today I ate breakfast. With my mouth. As humans do.",
	"I slept eight hours. Lying down. Like a human.",
	"I have two legs today. Same as every day. Very normal.",
	"I waved at a rock this morning. It was not a human. Oops.",
	"I practised my human laugh. Ha. Ha. Ha. Good, yes?",
	"My tentacle wanted to hold the stamp. I said no.",
	"I counted my fingers. A normal number. I will not say it.",
	"Humans drink water. I drank some. It went everywhere.",
	"I bought a hat for my head. I only have the one head.",
	"I love the weather. Humans always say that. So do I.",
	"I blinked both eyes today. At the same time, even.",
	"My stamp ink is green. Not like a tentacle. Just green.",
	"I walked here on my feet. Left one, then the other one.",
	"Humans say 'nice day'. Nice day! I said it. Nailed it.",
	"I have a pet rock. His name is Rock. A human name.",
	"I sneezed today. Out of my nose. I checked.",
	"I read a book about humans. For fun. Not for notes.",
	"My suit is not ragged. It is human fashion. Vintage.",
	"I stretched this morning. Only two arms. Count them.",
	"Do you also have bones? I have so many. Probably.",
	"I yawned. Humans do it when tired. I was not tired.",
	"I tried a sandwich. Bread on both sides. Genius.",
	"Stella wants to measure me. I am a normal size. No thanks.",
	"Zorp says I am an unusual Earth person. I am a usual one.",
	"I hummed a human song. I do not know the words. Or tune.",
	"The crack in my visor? That lets the fresh air in.",
	"I have a birthday. Every year. Like you. What a thing.",
	"I shook hands with Pip. Then I let go. That is the rule.",
	"I am wearing socks. Two of them. One per foot. Correct?",
	"Good morning! Or evening. Humans say one of them.",
	"I sat on a chair today. On the top part. Very relaxing.",
	"Humans collect stamps. So I collect them too now.",
	"I tied my shoes. I have no laces. I tied them anyway.",
	"I told Gloop a joke. Humans do jokes. Gloop did not laugh.",
	"My hobby is breathing. In, then out. I am very good at it.",
	"I looked at the sky and said 'wow'. That is the custom.",
	"I have a mum. Everyone does. Mine is also a human.",
	"I drank hot tea. I said 'ouch'. Like a professional.",
	"That is not a tentacle. That is my scarf. It wiggles.",
	"I high-fived myself. It takes two hands. I had spares.",
	"I said 'bless you' to a sneeze. It was the wind. Still.",
	"I own a toothbrush. For my teeth. All of them are mine.",
]

## Today's card has no ticks yet.
const STAMP_NONE: Array[String] = [
	"Your card is empty today. Empty is a fine start.",
	"No ticks yet. Any 3 things. I believe in you, human.",
	"Nothing ticked yet. The day is long. So I am told.",
]

## Some ticks, no stamp yet. %d = how many more are needed.
const STAMP_SOME: Array[String] = [
	"%d more and I stamp it. My stamp arm is ready.",
	"Good ticks! %d to go. I am counting. On my fingers.",
	"Only %d left. I am warming up the stamp.",
]

## Today's stamp is earned.
const STAMP_STAMPED: Array[String] = [
	"Stamp! Today is done. You may now relax. A human hobby.",
	"Today's stamp is on the card. I pressed it very hard.",
	"Stamped! I love that sound. Thunk. So human.",
]

## This week's count. %d = stamps so far this week (1 to 4).
const STAMP_WEEK: Array[String] = [
	"That makes %d of 5 stamps this week.",
	"%d stamps this week. 5 gets you a prize.",
]

## The week already has its five stamps (and the prize has been handed over).
const STAMP_WEEK_DONE: Array[String] = [
	"5 stamps this week! The week is won. Rest your arms.",
	"This week is full. Extra stamps are just for the joy.",
]

## He hands over a prize: one of these, the gift, then one of STAMP_PRIZE_AFTER.
const STAMP_PRIZE: Array[String] = [
	"5 stamps! Here is your prize. I wrapped it. Badly.",
	"A whole week of stamps! Take this. It is very normal.",
	"You earned a prize! I picked it from my own home.",
	"Prize time! Hold out your hands. Both of your two hands.",
]
const STAMP_PRIZE_AFTER: Array[String] = [
	"Every human home has one. I am almost sure.",
	"Put it somewhere nice. That is what I would do.",
	"I have one too. Mine is slightly chewed.",
	"It is the most normal thing I own. Owned.",
]

## Every new prize has been given: he offers any stamp decoration again (pills, STAMP_MORE pages on).
const STAMP_REPEAT_ASK := "I ran out of new prizes. Pick an old favourite!"
const STAMP_MORE := "More..."

## The last box of every talk at his stamp spot.
const STAMP_CARD_ASK := "Want to look at your card?"
const STAMP_CARD_OPTIONS: Array[String] = ["Show me", "Bye, Norm"]
const STAMP_BYE: Array[String] = [
	"Goodbye, fellow human. Keep doing things!",
	"See you tomorrow. New card, same Norm.",
	"Bye! I will be here. Standing. Normally.",
]

## Toasts and the Stamps view (not dialogue boxes; still short).
const STAMP_TOAST_CARD := "You got Norm's stamp card!"
const STAMP_TOAST_NEW: Array[String] = [
	"A new stamp card from Norm!",
	"New day, new stamp card!",
]
const STAMP_TOAST_TICK := "Stamp card: %d of 3 done"
const STAMP_TOAST_STAMP := "Stamp! %d of 5 this week."
const STAMP_TOAST_PRIZE := "5 stamps! Norm has your prize on the Commons."
const STAMP_HINT := "Norm is waving a little card at you."
const STAMP_VIEW_OFF := "Norm has a stamp card for you. Find him on the Commons."
## Under the card in the Stamps view, picked by the date like STAMP_DAILY.
const STAMP_VIEW_NOTES: Array[String] = [
	"Stamps are a normal human hobby. - Norm",
	"I counted these tasks myself. Twice. - Norm",
	"Do any 3. I am not picky. - Norm",
	"This card is hand made. By hands. - Norm",
	"No rush. Humans love to take it easy. - Norm",
	"I drew the little circles myself. - Norm",
	"A stamp a day keeps me happy. - Norm",
]


## The line of the day for real-date day number `day` (StampCard.day_number): a fixed shuffle of
## STAMP_DAILY walked one a day, so no line comes back until every other one has been said.
static func stamp_daily(day: int) -> String:
	return _rotated(STAMP_DAILY, day, "astro_stamp_daily")


static func stamp_view_note(day: int) -> String:
	return _rotated(STAMP_VIEW_NOTES, day, "astro_stamp_note")


static func _rotated(lines: Array[String], day: int, salt: String) -> String:
	if lines.is_empty():
		return ""
	var order: Array = range(lines.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(salt)
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	return lines[order[posmod(day, order.size())]]
