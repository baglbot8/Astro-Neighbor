# Norm spec: the mystery neighbour

Status: the contract for the Norm builders, written 2026-09-19 by the lead from the user's words (docs/CORE_LOOP.md
"The mystery neighbour") and a read-only API map of the current code. Builders do not edit it; the lead amends it with
the measurement that justifies a change.

## 1. What the player sees

From the middle of the story on, some days a stranger in a ragged astronaut suit stands somewhere on one world. An
orange tentacle curls out of a crack in his visor. He insists he is a normal human. He wants to ask three questions
"about human things" - really about this game. Answer all three right and he hands over a trophy he "found": bronze,
then silver, then gold, then a statue of himself, every time after that. Miss one and he leaves with a funny line; he
comes back another day. When you land on his world a small notification says something feels off here, without saying
where - he may be on the far side of the planet.

## 2. When and where (NormSystem, `src/campaign/norm_system.gd`)

* **Eligible:** `GameState.rocket_part_count() >= 3` or `GameState.story_done`; not while `GameState.flags["finale_stage"]`
  is 1, 2 or 3; not while onboarding is busy (copy VisitorSystem's `_onboarding_busy()` rule).
* **Which day:** a seeded roll per day, `RandomNumberGenerator` seeded from `hash(["astro_norm", day])`: he comes on 1 day
  in 4, never two days running (the roll for day d is void if day d-1 was a Norm day). The roll is pure: the same save on
  the same day always gives the same answer, before and after a reload.
* **Which world:** a seeded pick from planets that are not "home" and pass `CampaignData.planet_in_range(id)`. Before the
  story is done, only a world whose neighbour the player has met (`GameState.flag("met_<npc>")`; the Commons counts as met
  once the Professor is met, `met_mayor_orbit`). The roll is per day and never looks at where the player stands.
* **Where on it:** a ground spot that passes the same ground rules as visitors (pad, spawn, houses, props, decorations,
  trash, slope). Prefer spots at least 90 degrees round the planet from the landing pad, so the hint matters. The spot is
  seeded too, so it is stable across reloads that day.
* **One visit per appearance:** after the quiz ends (win or lose) he waves, walks a few steps away and is removed once
  out of the camera's view or 8 s later; he does not return that day. "Not now" keeps him there.
* **Never at the same time as a visitor on the same NPC:** Norm never visits home, and visitors only visit home.

State lives in `GameState.flags` (saved with the game), keys prefixed `norm_`:
`norm_last_day` (int, the last day he appeared), `norm_done_day` (int, the day his quiz ended), `norm_wins` (int, quizzes
won), `norm_statues` (int, statues given), `norm_seen_q` (Array of question ids asked since the bank was last reset),
`norm_met` (bool, first meeting done), `norm_today` (Dictionary `{day, planet}`: the day's roll, written once when first
rolled, so meeting a new neighbour later that day cannot move him; lead amendment 2026-09-19 after the NSYS builder
reported the world could change mid-day). No other key; never `visit_today`.

## 3. The landing hint

On `EventBus.planet_loaded` for his world, once the arrival has handed control back (after the flight's touchdown or the
load fade, never under it), emit `EventBus.toast_requested(text, icon)` once per arrival with one of these (rotate by
day): "Something feels a little off here..." / "You hear someone humming. Badly." / "Someone left very human footprints."
No hint after his quiz ended that day. No arrow, no marker on the HUD.

## 4. Talking to him

He is an NPC scene `src/characters/npcs/norm.tscn` (npc.gd root; display name "Norm"; not in npc_data.gd) whose
`visit_host` is the NormSystem, so `Conversation.run` hands the talk to `NormSystem.handle_conversation(runner, npc)`.
His marker is a "?" instead of "!" (an opt-in glyph in npc.gd; every other NPC keeps "!" byte-for-byte), shown until his
quiz ends. He does not wander far (a small radius).

The talk:
1. First meeting ever: two short intro boxes ("Greetings, fellow Earth person. I am Norm. A normal human.").
2. `ask(prompt, ["Sure!", "Not now"])`: "Care for some normal human questions? Three of them." Not now -> a line, he
   stays.
3. Three questions from NormQuiz, each `runner.ask(question, answers)` with three answers in a shuffled order and a 0.6 s
   arm delay. A right answer gets a short reaction; the first wrong answer ends the quiz with a funny line.
4. All three right -> NormRewards gives the next reward (a box with the reward line, the item added, a toast
   "You got: <name>"). Either way he waves and leaves (§2).

## 5. The questions (NormQuiz, `src/campaign/norm_quiz.gd`)

* A bank of at least 40 questions, each `{id, q, answers: [right, wrong, wrong], needs: {met: [...], parts: n, story: bool}}`.
  Answer 0 is the right one in the data; the order is shuffled when asked.
* Only about what this save has seen: `needs` gates each question on met neighbours, parts fitted and story done.
  Topics: neighbours' names, jobs, worlds, looks and sayings; world names and features; ship part names; the mini-games;
  the Professor; the skiff (after the story only).
* Every right answer is TRUE in the game's own data (npc_data.gd, the planet .tres files, campaign_data.gd, the mini-game
  data). Wrong answers are plausible and clearly wrong to a player who played. A test script checks each right answer
  against its source.
* Written in Norm's voice ("Fellow human, which neighbour..."). A question is at most 90 characters, an answer at most
  20, so the pills fit the phone.
* No repeat until the eligible unseen questions run below three; then `norm_seen_q` resets.
* API: `static func pick(rng: RandomNumberGenerator, n: int = 3) -> Array[Dictionary]` (eligible, unseen, marks them seen)
  and `static func run(runner: DialogueRunner, npc: Node3D) -> bool` (asks three, true when all right; awaitable).

## 6. The rewards (NormRewards, `src/campaign/norm_rewards.gd`, and four decorations)

* Ladder by `norm_wins`: 0 -> `norm_trophy_bronze`, 1 -> `norm_trophy_silver`, 2 -> `norm_trophy_gold`, then
  `norm_statue` every time, with no limit (`GameState.add_item` has no cap).
* Names and descriptions: "Bronze Human Award" / "Silver Human Award" / "Gold Human Award" / "Statue of Norm"
  ("Awarded for excellent human-ness." and similar, in his voice). Placeable decorations, price 0, so never in the shop.
* They must NEVER enter the favour-reward draw: each def carries `"source": "norm"`, and
  `Catalog.random_reward_decoration` skips any item whose `source` is not empty (one additive filter in catalog.gd).
* Looks: small cups on plinths, a clear bronze/silver/gold step, palette gates kept (no swatch above S 0.60). The statue is
  Norm himself, posed, in one stone material, baked into ONE shared mesh (load the model by path when it exists; a plain
  placeholder otherwise) so a planet full of statues stays cheap: one draw per statue, the mesh built once per process.
* API: `static func next_reward_id() -> String`, `static func grant(runner: DialogueRunner, npc: Node3D) -> String`
  (gives it, says the line, emits the toast, bumps the counters), `static func ensure_items_registered() -> void`.

## 7. Dev menu (dev_menu.gd, a "Norm" section on the Story tab)

Rows call NormSystem statics by path (`_hook_row`), and nothing there saves:
`debug_today() -> String` (a note row: "Today: Norm on <world>" or "no Norm today" and why),
`debug_bring_here() -> String` (Norm appears on the current world now), `debug_send_away() -> String`,
`debug_set_wins(n: int) -> String` (0-3; shows what the next reward is), `debug_give_rewards() -> String` (one of each
reward into the inventory), `debug_reset() -> String` (clears every `norm_` key).

## 8. Heat and look budgets

* Norm's model: <= 6000 triangles, like every neighbour. One extra NPC on one world.
* 20 statues placed on home: at most +25 draws and +0.5 ms over none (Compatibility, paired, spread stated).
* No new `.gdshader`. Decorations use materials already drawn in the game where they can.

## 9. Builders (disjoint files)

| key | owns | depends on |
|---|---|---|
| NORM LOOK | `src/characters/models/norm_model.gd` (scratch until the user picks) | - |
| NSYS | `norm_system.gd`, `npcs/norm.tscn`, the opt-in "?" in `npc.gd`, the attach line in `world.gd` | NQUIZ, NGIFT APIs (§5, §6) |
| NQUIZ | `norm_quiz.gd`, `norm_lines.gd` (every Norm line and hint text) | - |

`norm_lines.gd` (static data, `class_name` free, loaded by path) holds every word Norm says, as consts other files read:
`INTRO: Array[String]`, `OFFER: String`, `OFFER_OPTIONS: Array[String]`, `NOT_NOW: Array[String]`, `RIGHT: Array[String]`
(one picked per right answer), `WRONG: Array[String]` (one picked at the end), `WIN: Array[String]`, `BYE: Array[String]`,
`HINTS: Array[String]` (§3), and `REWARD_LINES: Dictionary` (item id -> Array[String]). Every box is one to two short
lines in his voice; he is never scary or mean, and the player is never mocked for a wrong answer.
| NGIFT | `norm_rewards.gd`, `src/decorations/items/norm_*`, the filter in `catalog.gd` | the look, loaded by path |
| NDEV | `dev_menu.gd` Norm section | NSYS API (§7) |
