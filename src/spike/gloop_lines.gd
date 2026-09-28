class_name GloopLines
extends RefCounted
## Gloop's voice, in one place so the table and the neighbour cannot drift apart.
##
## THE VOICE: friendly, a bit slow, and everything is food. Gloop does not understand telescopes;
## Gloop understands whether a picture is JUICY. Every line is under 60 characters (the writing rule
## in docs/STYLE_GUIDE.md) and none of them is a shop line — there is no menu, no price list and no
## "welcome, valued customer".

const NAME := "Gloop"
## Berry gel, the model's own GEL swatch — the dialogue name tag matches the character.
const ACCENT := Color("#b4718f")
const VOICE := "alien"

## First meeting.
const INTRO := [
	"Oh. Hello, there.",
	"I am Gloop. I sell pictures of our worlds.",
	"You bring me photos. I sell them. You get coins.",
]

## Walking up with nothing to hand in.
const IDLE_GREET := [
	"Mmm. Hello. Got some photos for me?",
	"Oh! You. Sit down. Or do not. Fine.",
	"No photos today? Come back later, then.",
	"The worlds are full of pictures. Go take some.",
	"I like a good clear photo. Very good.",
]

## Small talk, when there is nothing to trade.
const SMALL_TALK := [
	"Night is long here. Good. More to look at.",
	"Stars stay out in the morning. Did you know?",
	"Someone bought a blurry one once. Brave.",
	"I have a little star inside me. It's my pet.",
	"Morning light is thin. Soft, like fog.",
	"Slow down. The sky is not going anywhere.",
	"Everyone is packing. Not me. I am too wet.",
]

## What Gloop says about a print as it takes it, keyed by how good it is.
const TAKE_GREAT := [
	"Ooh, a great one!",
	"Mmm. This is a really good photo.",
	"Oh, I love this one. Very clear.",
]
const TAKE_GOOD := [
	"Nice one.",
	"Mmm. A good photo. I will put it out.",
	"Sweet shot. Someone will want this.",
]
const TAKE_WEAK := [
	"A bit blurry. I'll still try.",
	"Soft, but that's alright. I will try.",
	"Not the clearest. Someone might like it.",
]

const TAKE_DONE := [
	"Good. On the table they go. Sleep well.",
	"I will show them off until they sell.",
	"Come back in the morning. I will have coins.",
]

## Waiting: handed in today, nothing to pay out yet.
const WAITING := [
	"Not yet. They're still on the table.",
	"Patience. Selling takes all night.",
	"Come in the morning. Bring nothing. Just come.",
]

## The morning payout.
const PAYOUT_OPEN := [
	"Morning. Here. Your coins. Still warm.",
	"Ah! Good. A busy night. Sit. Take these.",
	"Morning, morning. The table is empty. Good.",
]

## Who bought the best one, and why. `%s` is the buyer's name; the reason follows on its own line.
## Reasons are opinions about the PICTURE, never about money — that is what makes the payout a
## nudge for the next night instead of a receipt.
const BUYERS := [
	["Fen", "He bought two. Says the light was wrong."],
	["Zorp", "He shouted. Then he bought it. Loud sale."],
	["Grig", "He looked for ten minutes. Then paid."],
	["Pip", "She hung it in the shop. Free advert."],
	["Pop", "He liked the fuzzy edge. I did not argue."],
	["Vela", "He said the focus was honest. Whatever that is."],
	["Bolt", "He measured it first. Then bought it."],
	["The Professor", "He wants more of the same, but sharper."],
	["Grig", "He bought one to take with him. Then another."],
	["Vela", "He held it a long time. Then said nothing."],
]


## A stable pick from a list, seeded so the same print always gets the same buyer.
static func pick(list: Array, seed_text: String) -> Variant:
	if list.is_empty():
		return ""
	return list[absi(hash(seed_text)) % list.size()]


## A random pick, for lines with no reason to be stable.
static func any(list: Array) -> String:
	if list.is_empty():
		return ""
	return str(list[randi() % list.size()])


## Gloop's reaction to one print, by what it is worth.
static func take_line(pay: int, seed_text: String) -> String:
	if pay >= 55:
		return str(pick(TAKE_GREAT, seed_text))
	if pay >= 30:
		return str(pick(TAKE_GOOD, seed_text))
	return str(pick(TAKE_WEAK, seed_text))
