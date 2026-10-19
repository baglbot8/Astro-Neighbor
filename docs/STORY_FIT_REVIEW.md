# Story fit review: the new opening against the rest of the story

Status: **work list for the words pass, 2026-10-18.** Two read-only Opus reviewers read the early game and the later game
against `docs/INTRO_SPEC.md` (section 11 wins). The lead spot-checked the top findings in the code. Builders do not edit this
file. Line numbers are as of 2026-10-18; **grep for the quoted old text** if a number has moved. Every new box is at most
**60 characters** (fill `%s` with the longest name, 6 letters). No clock, deadline or countdown wording. The threat is "the
meteor". Neighbours never show they will stay before the finale. This round has **no new scenes and no new systems**.

## Rulings (the lead)

1. This is a words pass: text changes, plus the few small logic changes marked **[logic]** below. Nothing else.
2. The finale meteor is **recoloured only** (A7). Do not rescale it in this round; report a side-by-side frame and say if it
   still reads smaller than the cockpit's rock. A rescale needs an exact ratio and the finale's measured framing gates, so it
   is a separate decision.
3. The streak is gone (removed 2026-09-28). `docs/INTRO_SPEC.md` section 11 wrongly said the Professor's streak line still
   plants it; the lead corrects that.
4. Deferred to a later round (option 2, new scenes): the Station letter after the finale, the free potted sprout, hanging the
   group photo beside the parents' photo, DJ Nova reacting to the crash, scrapbook "Page 1", the Commons "!" markers during the
   errands. Do not build them.

## A. Wrong now (must fix)

* **A1** `src/onboarding/intro_director.gd` ~:773, radio call after landing. "Bad timing, I'm afraid. There's a meteor coming."
  reads as news right after you grazed it. -> **"That meteor you clipped? It's heading our way."** Keep the next box ("Oh, not today!
  Not for ages. But folks are packing.").
* **A2** `src/onboarding/cockpit_intro.gd` ~:147 `RADIO_LATE`. "That rock is far bigger than my scope said!" -> **"Wait... is that a
  meteor?! It's huge!"** (no scope was ever mentioned).
* **A3** `src/hub/buildings/town_hall.gd` ~:425 (and the door at ~:381). At 0 parts the telescope says "0 of 5 parts fitted. We're
  flying further now." -> with the patch fitted and 0 parts: **"Your patch holds! Zorp and Bolt are in reach."**; with the patch
  NOT fitted and no parts: **"Your ship needs five parts. None fitted yet."** **[logic]** Walking into the Town Hall door before the
  patch must reach the Professor's errand talk (today the door only does that while his photo task is open): use the same
  `FirstHour.handles("mayor_orbit")` hook the Commons talk uses.
* **A4** `town_hall.gd` ~:466 (2-3 parts). "Funny thing. That streak is in all your photos." -> **"That meteor's a big one. Still far
  off, mind."**
* **A5** `src/campaign/finale_lines.gd` ~:44. "You could fly all the way home now." -> **"You could fly on to the Station now."**
* **A6** part hand-over farewells ("find a new home" is the old premise; you were flying to a job):
  `bolt.gd` ~:110 -> **"Good luck out there. Your odds are good."**; `fen.gd` ~:161 -> **"Safe flying out there. Find lots of sun."**;
  `vela.gd` ~:195 -> **"Safe flying. I'll think of you."**; `zorp.gd` ~:138 -> **"Good luck out there! Snap something that
  sings!"** (all in `src/projects/data/`). Grig's "wherever you land" (~:135) is fine; leave it.
* **A7** `src/campaign/giant_asteroid.gd` (~:8, :30) vs `src/onboarding/cockpit_props.gd` (~:889-892). The finale meteor is a lavender
  rock (`#8a839b`, radius 9.85 m); the cockpit's is grey-brown (about `#82786d`, 36 m). **Recolour the finale's GiantAsteroid with the
  cockpit's `METEOR_BODY/LIGHT/DARK` so it reads as the same rock.** Do not rescale. Re-run the finale's existing gates/probes and look
  at a finale frame next to a cockpit frame.

## B. Confusing, out of order or missing a beat (should fix)

* **B1** `intro_director.gd` ~:745 `CALL_SHIP`. The pad shows "Needs a patch" before anyone says the word. -> **"Your ship needs a patch.
  Till then, only the Commons."** (52)
* **B2 [logic]** Meeting the Professor on the Commons (`src/dialogue/conversation.gd` ~:76-80, `src/characters/npc_data.gd` ~:475-477,
  `src/campaign/professor_ask.gd` ~:175). After the radio he greets you as a stranger ("Oh! Hello! Sorry, I was counting meteors." /
  "I'm Professor Comet..." / "That crackly voice on the radio? That was me!"). When `FirstHour.handles("mayor_orbit")` (the first
  meeting in the new flow), skip the stranger intro and say **"There you are, %s! Professor Comet, in person."** (the chosen name).
  Old saves and every other path keep today's lines.
* **B3** The camera is only reachable through a neighbour's "Photo safari?" question (once per game day, only in a talk that carries
  nothing else), and nobody says to ask. In the photo ask (`first_hour.gd` ~:126) and the Professor's reminder (`professor_ask.gd`
  ~:206) add **"Ask them for a photo safari. Snap them there!"** (45).
* **B4** `intro_director.gd` ~:215, arriving on the Commons: "You made it to The Commons! Ask around for help." -> **"You made it to
  %s! Go find the Professor."** (use the planet's name as today).
* **B5** `src/projects/data/zorp.gd` ~:130. After the parcel talk ("Glow bulbs! Thank you..." / "But bulbs won't be enough...") his
  project intro says "Oh no, oh no! My rivers are going DARK!" as if it were news (the Professor already said it). -> **"My rivers are
  going dark. Little by little."** (43). Also make sure `first_hour.gd`'s three delivery boxes and this line do not both say "Oh ho!".
* **B6** `src/projects/data/bolt.gd` ~:103-104. Two hellos in a row ("Hello. You are visitor number one." / "Hello. I have a problem.")
  and "We leave soon." (clashes with "not for ages", leans toward a deadline). Keep his short flat voice: drop one hello; replace
  "We leave soon." with no-deadline wording such as **"Before we all go, I will fix them."**; the problem line **"I have a problem. 3
  machines are broken."** if it fits his existing text.
* **B7** `src/projects/data/grig.gd` ~:264-265. The only photo ask that is a score goal. Line 1 -> **"Before I go. One last look from my
  hill."** (39). Keep the "225 stardust" line.
* **B8** `npc_data.gd` ~:448 Stella: "Is that a camera on your belt? So cool, darling!" (the astronaut model shows no camera). ->
  **"Do I spy a camera, darling? How lovely!"** (40).
* **B9** `finale_lines.gd` ~:146 DJ Nova: "Uh... just a reminder that METEOR'S still coming for us!" -> **"Uh... reminder? The METEOR is still
  coming for us!"** (50).
* **B10** `town_hall.gd` ~:464 (4+ parts). "Nearly Departure Day. I'm staying, pushing or not." ("Departure Day" appears nowhere else and
  reads like a countdown). -> **"Ships nearly packed. I'm staying, pushing or not."** (49).
* **B11** `src/spike/gloop_lines.gd` ~:39 and ~:91. Gloop "Everyone is packing. Not me. I am too wet." breaks "only the Professor is not
  packing", and the Grig buyer line ("He bought one to take with him.") is wrong after the finale. First check which of these are
  actually reachable (the reviewer saw only WAITING/TAKE/PAYOUT/BUYERS wired in `print_table.gd`). For reachable lines: **"Everyone is
  packing. My boxes keep going soggy."** (47), an after-the-finale variant **"Everyone unpacked. Good. Fewer soggy boxes."** (43), and
  gate the Grig buyer line on `GameState.story_done`. Leave unreachable lines alone and say so.
* **B12 [logic]** `src/hub/buildings/player_home.gd` ~:361-364 Day-1 letter. It repeats the radio call, says "Dear neighbour," instead
  of the chosen name (`_who()` exists), and its "one hop to the Commons" line is false if read after the patch. -> "Dear %s," (use
  `_who()`); before the patch keep **"Your rocket can still make one hop: to the Commons."**; after the patch **"Glad that patch is
  holding!"**; add a last line **"P.S. Did your little plant survive the bump?"** (44) before the signature.
* **B13** `src/campaign/norm_quiz.gd` ~:167-170 "Fellow human, which ship part gets fitted first?": a kid answers "the patch" and the
  answers leave the patch out. -> **"Fellow human, which neighbour's part got fitted first?"** (53).

## C. Cheap payoffs for the cockpit's seeds (included; still no new scenes)

* **C1 [logic]** The chosen name is never used after the first hour. `finale_lines.gd` ~:236 -> **"But I think you're home. Welcome home,
  %s."**; `src/campaign/finale_gift.gd` ~:362 says the lines unformatted, so format them from `GameState.player_style["name"]`
  (fallback "Astro"). Also use it in ~:203 ("Wonderful work, friend!") only if it reads well; one use is enough.
* **C2** `finale_gift.gd` ~:1178 "The last page of your scrapbook." -> **"One more for your photo wall."**
* **C3** `first_hour.gd` ~:120, right after "A photographer? Splendid!" add **"Rock photos for the Station can wait a bit."** (43).
* **C4** `first_hour.gd` ~:129, after the parcel box add **"Bolt's yard is open too. He'd love a visitor."** (45).
* **C5** `first_hour.gd` ~:123 "Help them, and they will help fix your ship." -> **"Help them, and each will give a part for your
  ship."** (51).
* **C6** `finale_lines.gd` ~:88-92 `MOSS_ARRIVE`: Moss (a retired field photographer) never notices you are one too. Add **"Another
  photographer. The swamp told me."** (39) in his voice.
* **C7** `norm_quiz.gd`: one new question about the opening, following the existing entry schema (including its `needs {}`): **"Fellow
  human, what was your new job going to be?"** with answers **"Mineral photos" / "Moon farming" / "Being human"** (correct: the first).

## Checks the builder runs and a critic repeats

1. `tools/check.sh` CHECK PASSED; all seven worlds boot headless.
2. A script lists EVERY changed or added text box in the touched files and fails any over 60 characters (fill `%s` with "Sprout"); no
   deadline/clock words in new text; "the meteor" is the only threat word.
3. The earlier probes still pass with updated expectations where a line changed: `showcase/first_hour_probe` (expects 114/114),
   `showcase/first_hour_pass` (45/45), `showcase/name_picker_lines`, the cockpit line check.
4. The real opening still runs end to end (`tests/director/flow_full_real.json`) and the first-meeting talk with the new name line
   works (B2) with the old greeting still intact for old saves and after the patch.
5. Frames: the finale meteor next to the cockpit meteor (A7); the Town Hall door before and after the patch (A3).
6. Finale lines and `FinaleGift` formatting with a name (C1) in the real finale probe, plus a run with no name set.

## Result (2026-10-18, the words pass landed)

Built by one Opus builder, passed an independent critic (no blocking defects), then six polish edits. All A, B and C items
landed; deviations: **B3** reads "Chat with them. They'll offer a photo safari." (the player cannot ask for a safari; a neighbour
offers it once per game day in a talk that carries nothing else); **B4** applies only when the campaign arrival is the hub;
**B6** Bolt keeps "Before we go, I will not leave them broken." (the player finds the machines); **C3** reads "Your ship's log
mentions the Station. That can wait a bit." (how the Professor knows); **C4** is folded into the fitting talk ("Zorp and Bolt are in
reach now. Bolt loves visitors."); **C6** Moss says "And you take pictures too. I can always tell."; the Day-1 letter P.S. is "P.S.
Hope everything in your cabin survived the bump!" (the Professor cannot know about the plant); the patch toast is "Patch fitted!";
the parcel box starts "Oh, and a parcel for Zorp."; Grig's intro "We leave soon." became "Before we go, I leave no job half done."
(same clash as Bolt). The fitting talk is 14 boxes with his greeting. The blank-name guard (`_player_name()` falls back to
"Astro") also fixes "Now then, ." in the dispatch.

**A7 is partial.** The finale meteor now uses the cockpit's grey-brown palette. By day it reads as the same rock (finale
rgb(104,85,74) vs cockpit rgb(120,94,87)); at night, when the party happens, the moon and planet light turn it navy
rgb(51,56,92) and low-contrast, and it is much smaller on screen (about 10 degrees against a rock that fills the window). Options
for a later round: (1) a night-lighting exemption for this one body (a fixed light or an emission floor matching the noon colour,
one material, no framing change; risk: it may look like it glows); (2) matching the cockpit's smooth toon facets (low value at party
distance); (3) an exact-ratio rescale of the radius AND every camera distance, which touches the finale's measured framing and
needs every finale gate re-run. Lead pick: (1).

**Unproven:** whether a neighbour offers "Photo safari?" in the first plain talk after Zorp's project talk (needs real play);
the Day-1 letter variants and the finale photo card were never opened in a running game, only checked as text; no real finger.
