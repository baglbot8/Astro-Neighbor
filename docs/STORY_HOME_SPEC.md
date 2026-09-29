# Story contract: "Don't Move Out"

Status: **beats and lines drafted 2026-09-26** (the user picked option Three in `STORY_OPTIONS.md`,
with one change). Built after merge9, in the story wave (section 6).
This file wins over `STORY_SPINE_SPEC.md`, `CORE_LOOP.md` and `PHASE5_SPEC.md` on **what the story
says**. `STORY_SPINE_SPEC.md` still wins on **how a part is earned** (the chain, then the photo, then
`_hand_over_part`). Source map of every current line: the lead's inventory of 2026-09-26 (106 items:
80 keep, 11 reword, 13 conflict, 2 remove), summarised in section 4.

## 1. User rulings

* 2026-09-26: option Three. You crash into a little solar system that is packing up to leave,
  because a meteor is coming. You want to fix your ship and leave too. The finale turns everyone's
  getaway ships into the fleet that saves home.
* 2026-09-26, the change: **the neighbours never show they will stay until the finale.** "That should
  be the bigger surprise in the end." At the hand-over they thank you, give the part, and wish you luck
  finding a new home. At most a very slight hint that they love their home. The user's examples:
  "ah I always loved sitting by that tree...I'll miss that", "I'll cherish this photo forever", "wow I
  forgot how nice of a view i have here".
* 2026-09-26: no story reason is needed for planet life only happening in safari mode.
* Standing (`STORY_SPINE_SPEC.md`): each neighbour's chain ends in a photo request on their own world,
  then the part.

* 2026-09-27, after seeing the fleet finale: "can we have astronaut main character appear in the
  final photo as well"; "when they're all celebrating can they not do their celebration jumps in unison,
  it looks odd, stagger their celebrations so it looks more natural"; "after they send their ships to
  destroy the meteor, i still see all the ships after the cutscene?" See ruling 2.14.
* 2026-09-27: "Dont overengineer these rounds, id rather get the actual final results quicker."

## 2. Lead rulings

1. **No mid-game "won back" signs.** Nothing on screen may say a neighbour changed their mind before
   the finale. Boxes stay packed until the finale.
2. **Everyone leaves together, once your ship is fixed.** The Professor says so at the first meeting:
   the convoy waits so nobody is left behind. This is why the neighbours help with parts, why every
   world stays visitable to the end, and why Departure Day comes exactly when the fifth part fits.
   **No clock or countdown anywhere.**
3. **The finale gathering on the Commons (`PHASE5_SPEC.md`) becomes the convoy's meeting.** Its
   staging is reused; its meaning and lines change (section 5.7).
4. **Hints read as goodbye, not as a decision.** Each hint is about **the thing in the photo they asked
   for**. Nostalgia or thanks only; never "maybe I will stay", never "I don't want to go". Each hint
   has a matching callback line in the finale.
5. **The Professor is the only one not packing.** He says the meteor can be pushed with enough ships.
   The neighbours brush it off kindly. He keeps no separate wall: at the finale he borrows **your
   scrapbook** (built, w1c).
6. **The clue is a faint streak in the sky of every world** — the meteor, far off. It is in the back of
   your photos. At the finale the Professor lines up the photos from five worlds and finds where it
   is, and so where to push. **Correction of the lead's earlier idea:** "the creatures all face one
   point in the sky" does not come from the game's Facing score — that score rewards a subject facing
   **the camera**, so good photos show creatures facing you. Dropped. (Optional later: creatures
   sometimes stop and look up at the streak.)
7. **The streak grows with parts, not time.** Faint at 0 parts, clearer at 5. Visual only; nothing
   says how long is left.
8. **The ships survive.** Every ship, yours in front, flies up and nudges the meteor; it breaks into a
   harmless meteor shower; everyone is back on the Commons under it. Your rocket stays your rocket
   after the story: **no skiff** for a new game. A save that already has the old skiff keeps it.
9. **Packing is words and props, not mechanics.** The chains keep their mechanics. Each chain's intro
   gets one line saying "not before I go". Boxes and a few silly signs go on the Commons and near each
   neighbour's home before the finale, and go away after it.
10. **The old "fix the Professor's telescope" goal is removed** (one live favour line). His telescope
    works; it is how he watches the meteor.
11. **The last act is a photo.** After the shower, you take the group photo of everyone on the
    Commons. It is the scrapbook's last page. Preferred: the player holds the shutter once, with the
    safari camera, and any shot counts. Fallback if that costs too much: the game takes it for you.
13. **Gloop sells copies of your planet photos** (the user, 2026-09-26: "go with 1, Gloop sells copies
    of planet photos"). At the end of each planet safari, **the one best photo of that safari** (highest
    `PrintBag.pay_for`) goes into your satchel as a print; the photo also stays in your scrapbook, so it
    is a copy. Never a bonus (collector) item, never an empty frame. Priced by the existing
    `PrintBag.pay_for` (8 + 46 x rarity + 30 x sharpness), rarity from the subject's roster, sharpness
    from the photo's craft score. Gloop's four-step table loop (hand in, wait, morning payout, chat) is
    unchanged. One print per safari keeps the extra income to roughly a third on top of safari pay
    (a careful safari measured ~140+ stardust; one print pays 8-84); the builder measures the real
    figure and states it.
12. Word rule: the threat is "the meteor" in every new line. Every box is at most **60 characters**
    (the project's LINE_MAX). All lines in section 5 were measured.

14. **The finale, after the user's look (2026-09-27).** (a) **The astronaut is in the last photo**: a
    self-timer shot. The player presses the shutter once, a short 3-2-1 count runs, the view is a
    third-person group shot with the astronaut standing among the neighbours, click; that frame is the
    scrapbook's "Home" page. (b) **Celebrations never in unison**: each character starts its jump or cheer
    at its own offset (a few tenths of a second apart), and neighbours with their own emote use it. (c)
    **Once the ships launch, they are gone from the Commons**: no parked ship remains during the shower,
    HOME, or after the story (they went home; everyone stays).

## 3. The beats

1. **Crash** (intro as built). Professor Comet's radio call adds: a meteor is coming (not soon), and
   most folks are packing. His first task stays: photograph a neighbour and bring it to him on the
   Commons.
2. **The Commons.** Boxes, a silly sign or two. The Professor meets you: everyone flies out together
   once your ship is fixed, so nobody is left behind. Not him: he says it can be pushed.
3. **Each neighbour.** Intro with one "before I go" line, the chain as built, then "one last photo of
   home" on their world's safari. The photo's "done" line carries the slight hint. Then the part,
   thanks, and good luck finding a new home.
4. **Between neighbours.** Packing small talk and kind brush-offs of the Professor. At 2+ parts the
   Professor mutters that the streak is in all your photos.
5. **The fifth part fits. Departure Day.** The Professor radios: the last ship is ready; everyone is
   waiting on the Commons.
6. **The meeting.** Packed ships around the Commons. The Professor borrows your scrapbook, lines up the
   streak from five worlds, and says where to push. One ship can't; six could. Bolt: "Our ships are
   packed." The Professor wishes them safe travels. A pause.
7. **The surprise.** One by one, each neighbour calls back their own hint, and stays.
8. **Your choice.** "Your ship is fixed. You can still go." Give me a moment / Fly with them.
9. **The fleet.** Six ships launch together and nudge the meteor. It breaks into a meteor shower.
10. **Home.** Everyone on the Commons under the shower. You take the group photo. "Welcome home."

## 4. What changes, by file (from the inventory)

| Where | Now | Change |
|---|---|---|
| `src/onboarding/crash_intro.gd` captions | crash radio | keep |
| `src/onboarding/intro_director.gd` `_campaign_call` (w1a) | radio call + first task | add 5.1 lines |
| `src/campaign/professor_ask.gd` (w1a) | in-person first photo | add 5.2 lines |
| `src/hub/buildings/town_hall.gd` `_watch_line` | keeps "something big" secret | replace, 5.3 |
| `src/characters/npc_data.gd` | Professor favour "telescope needs a small repair" | replace, 5.3 |
| `src/characters/npc_data.gd` small talk | no packing | add 5.5 lines, gated pre/post finale |
| `src/projects/data/{zorp,bolt,fen,grig,vela}.gd` (w1b) | intro, photo ask/done, part_lines | 5.4 |
| `src/campaign/finale_lines.gd` + `finale_meeting.gd`, `finale_launch.gd`, `finale_gift.gd` | asteroid discovered at the meeting, your rocket sent alone, friends gift a skiff | 5.7, fleet, no skiff |
| `src/campaign/norm_quiz.gd:210-213` | two skiff questions | replace, 5.6 |
| `src/sky/sky_journal.gd:929-931` (w1c) | dead "Professor Comet asked for this" example | remove |
| `src/planet/props/planet_props.gd` (`_plaza`, `_violet`, `_chrome`, `_fen`, `_grig`, `_vela`) | no packing props | boxes and signs, pre-finale only |
| sky of every world | no streak | faint meteor streak, grows with parts |
| Gloop (`src/spike/gloop_lines.gd`, `src/spike/print_bag.gd`, safari review) | sells space-safari prints; no supply while flights are off | one print per planet safari, 5.8; ruling 13 |

Keep as built: the crash captions, the Day-1 letter, the Professor's intro and Commons door talk, all
chain steps 0-2, Norm's banter and other questions, visitor lines, shopkeepers, UI text.

## 5. Lines

`+` = add this line. `~` = replace the named line. Unmarked = keep as is (shown for context).

### 5.1 The radio call after the crash (`intro_director.gd` `_campaign_call`)

After the box that ends "What a tumble!" and before the ask:

```
+ "Bad timing, I'm afraid. There's a meteor coming."
+ "Oh, not today! Not for ages. But folks are packing."
```

### 5.2 Meeting the Professor on the Commons (`professor_ask.gd`, first meeting only)

After "That crackly voice on the radio? That was me!":

```
+ "Mind the boxes. Everyone's packing to leave."
+ "They'll all fly out together, once your ship is fixed."
+ "Nobody gets left behind. That's how it is here."
+ "Not me, though. I say that meteor can be pushed."
```

His thanks for the photo gains the reason (the user, 2026-09-27: "im not sure why he needed the picture"),
after "A photo of %s, for my records!":

```
+ "I'm tracking that meteor. Every sky you photograph helps."
```

While his task is open and no neighbour photo is in hand, every talk gives a reminder instead of a
favour (`PLANET_SAFARI_SPEC.md` 17.2):

```
+ "Snapped a neighbour yet? On their own world, mind."
+ "Bring the photo here. I'll be charting."
```

### 5.3 The Professor between neighbours

`town_hall.gd` `_watch_line(have)` — replace all three:

```
~ have 0:    "Everyone's packing. I'm charting. That meteor can move."
~ have 1:    "Still out past the ring. Enough ships could nudge it."
~ have 2-3:  "Funny thing. That streak is in all your photos."
~ have 4+:   "Nearly Departure Day. I'm staying, pushing or not."
```

`npc_data.gd` `mayor_orbit.favor.bring` — replace the first box:

```
~ "I'm charting that meteor, and I've run short."
```

### 5.4 The five neighbours (`src/projects/data/*.gd`)

Photo "done" lines carry the hint. "part_lines" carry the thanks and the good luck.

**Zorp** — the Crystal Chime. Hint: it is the sound Zorp falls asleep to.

```
intro:   "Oh no, oh no! My rivers are going DARK!"
         "They used to glow all night! Now: barely."
       + "I can't leave them dark! Not before I go!"
         "You have a jetpack! Please, come look!"
ask:   ~ "One more thing! Before I go... my crystals SING!"
       ~ "Snap one chiming, safari-side! One last photo!"
done:    "You got it! Ringing, and SHARP! Just like that!"
       ~ "...That's the chime I fall asleep to. Every night."
part_lines:
         "The river HUMS again! Do you hear it? Hear it?!"
         "Take this coil - wound from real river-light!"
       + "Good luck out there! Find a home that SINGS!"
         "New fact: you are my best friend. Confirmed!"
```

**Bolt** — his own tune-up on the mast. Hint: the mast fits him exactly.

```
intro:   "Problem detected. Three machines: broken."
       + "Departure is scheduled. I leave nothing broken."
         "Please find them. I will count while you walk."
ask:   ~ "Final item. One photo of home, before departure."
         "Safari mode. I climb the mast. Sparks fly. Catch it."
done:    "My own tune-up, on record now. Precisely."
       ~ "That mast fits me exactly. 412 tune-ups. Hm."
part_lines:
         "Yard fully repaired. Confirmed. Twice."
         "Take this gear. I have three thousand more."
       + "Good luck finding a new home. Probability: high."
         "Logged as: excellent friend. Final answer."
```

**Fen** — the Pool Ripple. Hint: nine years of watching those pools.

```
intro:   "The moths took the light. All five of them."
       + "I will not leave them lost. Not before I go."
         "Guide them home. I only watch. That is the work."
ask:   ~ "One thing more. A photo of home, before I go."
         "Wait at a pool, safari-side. It glows. Then leaps."
done:    "Sharp ripple. I logged it. Twice."
       + "Nine years I have watched those pools. I'll miss that."
part_lines:
         "The dusk is shorter now. I noticed. I notice everything."
         "Take the cell. I have carried it longer than the moths did."
       + "Find a good home out there. One with long dusks."
         "Logged as: neighbour, in full. Rare entry, that."
```

**Grig** — a safari worth 140 stardust on the steps (score ask, no single subject). Hint: he forgot
the view.

```
intro:   "Chalk. Dry chalk. Not one drop of water in it."
         "Nine hundred steps, and every one of them thirsty."
       + "We leave soon. I leave nothing half done."
         "Dowse with me. Feel for the pulse. Find water."
ask:   ~ "Before I go. One safari, here on my steps."
       ~ "140 stardust of photos. At least. I will add it up."
done:    "140. Correctly counted. Best safari yet. Recorded."
       + "Hm. Forgot how good the view is, from up here."
part_lines:
         "Water again. A garden again. Correctly ordered."
         "Take this valve. Cut it myself. Fits your rocket."
       + "Good luck, wherever you land. Count the steps there."
         "Best neighbour on the steps. Recorded. Permanently."
```

**Vela** — the Mirror Moon (Fine; the last part of the game, so the most weight). Hint: she will keep
the photo always.

```
intro:   "Eight masts. Three still lit. Five gone quiet."
         "I keep listening. The others stopped answering."
       + "Before I go, I would hear them all once more."
         "Stand with me. Call, and answer, in turn."
ask:   ~ "One entry remains. My home, before I leave it."
       ~ "The mirror moon, in the ice. Once a safari. Sharp."
done:    "The mirror moon, logged. One record, closed."
       + "I will keep this photo. Always."
part_lines:
         "The array is whole. Every dish, every mast."
         "Take the core. It has waited longer than I have."
         "Go home, or go far. Either way: well listened."
```

"progress", "already_have", "smudge" and "part_again" lines stay as built.

### 5.5 Small talk (`npc_data.gd`)

Two packing lines per neighbour, **only before the finale**; one line **only after it**. The builder
adds the gate (the pools are plain arrays today).

```
zorp  before: "Packing is HARD! Everything I own glows!"
              "The Professor wants to PUSH a meteor. Push! Ha!"
      after:  "I unpacked EVERYTHING! It all still glows!"
bolt  before: "Boxes packed: 212. Boxes labelled: 212."
              "The Professor's plan: noted. Probability: low."
      after:  "Boxes unpacked: 212. Status: staying."
fen   before: "I packed my notes. Nine years. Three boxes."
              "The Professor means well. He always has."
      after:  "Unpacked my notes. Started a tenth year."
grig  before: "Packed. Unpacked. Packed again. Correctly, now."
              "Push a meteor? The numbers don't add up. Not for one ship."
      after:  "Nine hundred and four steps. Still here. Recorded."
vela  before: "I will take the little dish. The rest stays."
              "The Professor asks for ships. Ships are for leaving."
      after:  "Still listening. The sky sounds lighter now."
```

### 5.6 Norm's quiz (`norm_quiz.gd`, after the story only)

Replace `skiff_gift` and `skiff_replaces` (first answer is the right one, as in the file):

```
id "fleet":  "Fellow human, what broke the meteor into a shower?"
             ["Every ship, together", "Your rocket, alone", "A very big net"]
id "streak": "Fellow human, how did the Professor find the meteor?"
             ["In your photos", "A letter from Bolt", "He tripped on it"]
             (shortened 2026-09-27: answer pills are at most 20 characters, measured for the phone)
```

### 5.7 The finale (`finale_lines.gd`, same shape as today)

**CALL** (radio, home):

```
mayor_orbit: "Professor Comet here. Oh my. She's GOLD!"
             "You could fly all the way home now."
mayor_orbit: ~ "Well. That's the last ship ready."
             ~ "Departure Day, then. Everyone's at the Commons."
mayor_orbit ask: ~ "Come and see them off? Everyone's waiting."
                 options ~ ["On my way", "Already?"]
"Already?" reply: ~ "They waited for you, friend. Do come."
```

**MEETING** (Commons; the five packed ships stand around the square):

```
zorp:        "You came! Everyone came! Even Grig came!"
grig:        "Closed the steps. All nine hundred and four."
mayor_orbit: ~ "Thank you all for coming. Before you go..."
             ~ "Look up. Just there, above the pad."
mayor_orbit [U]: ~ "There it is. Our meteor."
mayor_orbit: + "May I borrow your scrapbook, friend?"
{action: the Professor holds up the scrapbook}
mayor_orbit: + "That streak is in your photos from every world."
             + "Five worlds, five angles. Line them up, and..."
             + "...there. That's where it is. And where to push."
mayor_orbit: + "One ship can't move it. Six could."
{action: silence; nobody moves}
bolt:        + "Professor. Our ships are packed."
mayor_orbit: + "I know. I know. Safe travels, all of you."
{action: a long pause}
zorp:        + "...I can't sleep without the chime. I tried."
             + "Zorp is STAYING! Unpack the ship!"
bolt:        + "I measured every mast out there. None fit me."
             + "Recalculating. Staying."
fen:         + "Nine years of notes. I am not done watching."
grig:        + "Nine hundred and four steps. Best view there is."
             + "Staying. Recorded. Permanently."
vela:        + "I have listened to this sky all my life."
             + "I will not leave it now. Well listened, Professor."
pip:         + "We unpacked the lamps already..."
pop:         + "...we never really packed them. Shh."
{action: all turn to the player}
mayor_orbit [S]: ~ "Your ship is fixed. You can still go."
                 ~ "Nobody will ask it of you."
mayor_orbit ask: ~ "What would you like to do?"
                 options ~ ["Give me a moment", "Fly with them"]
```

Removed from today's MEETING: "A giant asteroid...", Bolt "I ran its path forty times", Vela "The
array heard it three nights ago", Fen "Nine years of notes. Nothing this size", Pip/Pop stockroom,
Zorp "Unless something fast hits it", Bolt "Your rocket is fast. Five parts. From us", the old
"She's your way home... only thing that could do it".

**MOMENT** ("Give me a moment"; free roam, then the Professor asks again) — keep all six lines as
built; they read true for the new stakes.

**SEND** ("Fly with them"):

```
bolt:        ~ "Autopilot off. Pilots: all of us. Course: true."
mayor_orbit: ~ "Everyone, to your ships!"
{action: six ships launch together, yours in front; they nudge the meteor; it breaks into a shower}
```

**HOME** (replaces GIFT; everyone back on the Commons under the shower):

```
dj_nova:     "Best. Light show. EVER!"
zorp:        + "We did it! We PUSHED it! Into sparkles!"
mayor_orbit: + "A meteor shower. The safe kind."
             + "And every one of us still here."
fen:         + "I will need a tenth notebook."
grig:        + "Counted the shooting stars. Lost count. First time."
vela:        + "Listen. It sounds like home."
bolt:        + "One item remains. A photo. Everyone. Now."
{action: the player takes the group photo; it becomes the scrapbook's last page}
mayor_orbit: + "Your ship is fixed. You could go anywhere."
             + "But I think you're home. Welcome home."
{toast: "Every world is open. Planet stats are back."}
```

Removed from today's GIFT: every skiff line ("We started her the day you crashed", Bolt's hatch,
Zorp's knees and antenna, Fen's lamp, Grig's ladder, Vela's dish, "You gave up one way home").

### 5.8 Gloop (`gloop_lines.gd`)

```
INTRO:      ~ "I am Gloop. I sell pictures. Of the sky."  ->  "I am Gloop. I sell pictures. Of our worlds."
IDLE_GREET: ~ "The sky is full. Go get me a slice."        ->  "The worlds are full. Go get me a slice."
SMALL_TALK: + "Everyone is packing. Not me. I am too wet."
BUYERS:     + ["Grig", "He bought one to take with him. Then another."]
            + ["Vela", "She held it a long time. Then said nothing."]
```

Review screen toast when the copy is made: `+ "A copy for Gloop's table."`

The two new buyer lines are slight hints too (rule 2.4). After the finale they still read fine.

## 6. Build plan (after merge9; at most four Godot processes, `CLAUDE.md`)

* **T1 words** (Sonnet, one critic): 5.1-5.6 and the dead sky_journal example. Files: `intro_director.gd`,
  `professor_ask.gd`, `town_hall.gd`, `npc_data.gd`, `projects/data/*.gd`, `norm_quiz.gd`,
  `sky_journal.gd`. Gate: every new box <= 60 chars; a new game and a save copy both reach each line
  (Director or probe); `tools/check.sh` passes.
* **T2 finale** (Opus, harsh critic; the risky one): 5.7, the five neighbour ships (procedural, each in
  its owner's palette, `STYLE_GUIDE.md` gates), the fleet launch, no skiff for a new save, an old skiff
  save still loads, the last photo. Files: `finale_lines.gd`, `finale_meeting.gd`, `finale_launch.gd`,
  `finale_gift.gd`, `finale_state.gd` if needed, new `src/campaign/neighbour_ships.gd`. Gate: a real
  run through the whole finale, frames looked at.
* **T3 set dressing and the streak** (Sonnet builder, Opus critic for the look): boxes and signs in the
  six `planet_props.gd` functions (pre-finale only), the meteor streak in every world's sky (grows with
  parts; `environment.gd` rewrites the sky every frame, so change the per-frame write). Gate: frames
  before and after the finale; palette gates; frame time on the web renderer.

* **T4 Gloop** (Sonnet, one critic): ruling 13 and 5.8. Files: `src/spike/print_bag.gd` (a
  `from_planet_photo` maker beside `from_sky`), `src/spike/gloop_lines.gd`, and the one hook at the end
  of the safari review (`src/planet_safari/review/safari_review.gd`, owned by nobody else in this wave).
  Gate: one real safari in a renamed copy puts exactly one print in the satchel; a bonus-only or empty
  safari puts none; next morning Gloop pays `pay_for` of it; stardust per careful safari with and
  without the print, measured and stated.

## 7. Open, not story

* Gloop: decided (ruling 13).
* The switched-off space safari flight could carry the fleet flight later. Not planned.

## 8. The user's play of merge11 (2026-09-27): what changes next

User, verbatim on the finale: "The finale was a bit confusing ... it felt a bit rushed ... everyone's leaving >
look at this scrapbook 'five planets. everytime' (hard to understand) > everyone get in your ships > crash
(nobody's hurt?) > picture immediately." The new shape, from the user:

1. Professor Comet throws a **goodbye party** on the Commons for everyone moving out.
2. At the party, one by one, the neighbours reveal they wanted to tell everyone they are **staying**
   (the hints pay off here). Everyone agrees.
3. The Professor has **bad news**: the big meteor he has been tracking through your photos will hit the
   system and destroy the planets. They can't stay.
4. **Vela: "I have an idea!"** (he is a lightbulb): knock it off course with his ship. The Professor: one ship
   won't be enough.
5. **Everyone volunteers their ship.** The new plan: break the meteor up.
6. Ships on **autopilot**; everyone watches from the Commons as the meteor becomes a meteor shower.
7. The ships **come back bruised but working**. **Pip and Pop** offer to fix everyone's ships.
8. **A party** to celebrate. (The self-timer group photo stays as its closing moment.)

Consequence for the early story (lead): the meteor must be a **worry, not a certainty**, before the party:
folks leave because it *might* hit; the Professor is tracking it through your photos to be sure. The radio
call and packing lines get a small wording pass for this.

Other items from the same play: every neighbour's dialogue and behaviour get a fresh voice pass (plain
English, one consistent personality that fits their current look and planet; `CAST_VOICES_DRAFT.md`,
drafted for the user's approval first); Grig's safari felt empty; photos on the home planet at any time into
a separate 25-photo album that is never auto-replaced.

### 8.1 User rulings (2026-09-27, later)

* **Finale, amended by the user:** the Professor does NOT reveal the meteor will hit (it is already known).
  After the staying reveal, **Nova: "uh just a reminder that METEOR'S still coming for us!"**; Vela gives his
  idea; everyone offers their ship; **Stella** says it will be hard to hit a moving meteor on autopilot; the
  **Professor** says he can track its path with all the photos the player has taken, and it is the best shot
  they've got to save their solar system. Then as in section 8 (autopilot, shower, ships back bruised, Pip and
  Pop fix them, party, group photo). So the early story keeps "a meteor is coming".
* **Voices:** `CAST_VOICES_DRAFT.md` approved ("All the voice lines look good"), pronouns as drafted (Pip she,
  Fen he, Vela he), with changes: **Fen is younger, not a grandparent** (and gets a slight smile so he is less
  stoic); **Grig** gets a slight top eyelid so his normal face reads a little grumpy; **Zorp** drops the
  getting-Earth-wrong jokes (too close to Norm) and becomes a **quirky grandpa** (his tentacles read as a
  moustache). Sections 5.4/5.5 lines are superseded by the voice rewrite where they differ; the hint *subjects*
  stay.
* **Home album:** photos on the home planet any time, into a separate 25-photo album. When full, the player
  **picks an old photo to throw away** before the new one saves. The scrapbook also gets a way to **clear out
  photos** in bulk, not only one by one.

## 9. The grand finale: the meteor survey, and the cave (user rulings 2026-09-28)

User: "we need one 'finale' level. The final 'level' just happens to be one of the neighbor's planets. It
doesnt feel like a grand finale." Picked: **3 (survey the meteor) + A (a cave on your home planet, post-game)**,
with the lead's picks on all three questions.

### 9.1 The finale, new middle
Party -> staying reveal -> Nova's reminder -> Vela's idea -> everyone offers their ship -> Stella: hard to
hit a moving meteor on autopilot -> **the Professor: "We need a target. Someone has to land on it and mark
its weak spots."** (this REPLACES "he can track its path with all your photos") -> **the meteor survey
level** -> back on the Commons -> the ships fly on autopilot **to your beacons** -> meteor shower -> ships back
bruised -> Pip and Pop fix them -> party -> group photo.

### 9.2 The meteor survey level
* A small, strange rock: first-person, the planet-safari camera, scoring and walk. Looks unlike any world
  (dark crust, glowing seams, the system's planets huge in its sky).
* **5 glowing cracks** (weak points), spread so all 5 need the whole time. **2 minutes.**
* A crack is marked by a photo of it at **Fair or better**: a target beacon appears on it; a Smudge says
  why and lets you try again. Film enough for 5 plus misses (e.g. 12).
* **If time runs out, retry right away, as often as you like.** No game over; the Professor encourages.
* **Never saved in the scrapbook**, never replayable after the finale. Pays nothing.
* API (lead stub, `src/meteor_survey/meteor_survey.gd`): `MeteorSurvey.run(tree) -> await` returns when all
  5 are marked (the finale then continues).

### 9.3 The cave (post-game)
* The morning after the finale, on your home planet: a meteor piece has cracked open **a cave entrance**.
* The cave: winding paths down, lit by **glowing meteor crystals**; you carry **a small lantern** - dark
  enough to feel different, never scary. Aesthetically unlike every planet.
* Gentle things to photograph (crystal clusters, cave critters, a few rarer sights); photos go to their
  own **"Cave" section of the scrapbook**, with "???" pages like the others. For fun: no pay, no quests.
* Enter and leave any time after the story.

### 9.4 The cave, after the user's play (2026-09-28)

User: "the cave is so white / bright that having the lantern doesnt seem necessary. The lantern also jitters
when walking. I dont mind the whiteness of the cave but then we dont need the lantern. ... more rainbowy
creatures in the cave to contrast the whiteness ... a couple path option points ... Is there a time limit in the
cave? we may need one which then makes choosing a route seem more important ... one cave area can lead to a big
open space or a dead end with like a treasure in it with an outfit, etc." Rulings (lead defaults):
* **No lantern.** Keep the bright white cave.
* **Rainbow creatures** that pop against the white (prismatic, iridescent), replacing or joining the current
  critters; a few rarer ones.
* **Branches:** at least two fork points. One route opens into **a big open chamber** (the best views and the
  rarer sights); one ends at **a dead end with a treasure chest holding an outfit piece** (found once, then the
  chest is open and empty); a third short branch may hold a small rare subject.
* **A time limit: 3 minutes per visit**, shown like the safari clock, so the route matters; when it ends, a
  gentle "time to head back up" and you are back at the entrance. **One visit per day**, like the safaris.
  About 12 film.
* **More route choice (the user, 2026-09-28):** "more than just one option to take a turn of direction and maybe
  some different heights / directions ... the road slopes downward in one and upwards in another ... or curves left
  and curves right. We should make sure people can get to the end of the cave in the time limit but not
  necessarily have time to go back and try all the different routes assuming they take some photos along the
  way." So: several forks (not one), branches that clearly differ - one slopes down, one climbs, one curves left,
  one right; any single route from the entrance to its end fits in 3:00 with photos on the way (measure: a
  walker taking ~6 photos reaches every route's end with time left), but the whole cave does not fit in one
  visit.

### 9.5 The user's play of merge18/19 (2026-09-28)

1. HUD: "when you get enough stardust into the thousands, the star window starts overlapping with the scraps menu."
2. Meteor survey: "a large place and navigating it is a bit confusing. We may need to add on an extra 15 seconds.
   I played pretty efficiently ... and just barely made it in time. ... the meteor needs some occasional
   recognizable landmarks (e.g. large crystal spikes or lava fountain)". -> clock 2:15; distinct landmarks.
3. "There was a random Play board on the meteor - that needs to be removed." (An easter egg on a planet is a
   nice idea for a future post-game thing - logged, not built.)
4. The meteor's textures are plain next to the planets: beef them up.
5. Cave: "almost too white ... shades of brown but lots of crystals (like a teal color and occasional rainbow
   ones) light up the cave a lot so it's not scary ... good textures here like our other planets."
6. Cave: "doesnt have a lot of things popping up ... mostly walking down the long halls with nothing major to look
   at or take photos of" -> many more subjects along the halls (something new every ~10-15 s of walking).
7. "The journal only shows the denominator of pictures as 1, but there are more when i go to the Cave page."

### 9.6 The user's play of merge20 (2026-09-28), verbatim points
1. "theres always a random white line in the sky even during cutscenes. That should be removed." -> remove the
   meteor streak (its clue role ended when the survey replaced the photo-tracking line).
2. The neighbours' ships carry their packing boxes into flight: boxes stay on the ground or vanish for landing.
3. Ship "dents" look like black balls: use scratches and rusted parts like the player's ship at the start.
4. The survey still feels like luck finding the last crack: at least 2 climbable high points (rocky ramps) placed
   with a crack spot visible in the distance, so you can see the red lights further; after a first fail the
   Professor hints to climb them. (Multiple tries are fine.)
5. The volcano's lava lines look like straight red sticks: make them flow naturally. Some rocks have see-through
   parts: fix.
6. The meteor needs steam haze and rising white dots that appear and fade: more intense.
7. Cave: darker, so the crystal glow pops much more.
8. Some crystals sit on smooth flat pedestals and grow straight up, so they look like trophies or photo subjects:
   background crystals grow from the ground at angles, no pedestals.
