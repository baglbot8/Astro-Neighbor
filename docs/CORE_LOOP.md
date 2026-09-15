# Core loop: Stranded (DRAFT)

Status: **DRAFT, 2026-09-10. Not approved. Nothing here is built.** The user reviews this page before
any builder works from it. Until it is approved, ARCHITECTURE §1.1 still governs what ships.

## The user's decisions (2026-09-10)

1. **Ending:** you never reach home. When the rocket is complete, you are called to an emergency
   meeting on the Commons. A giant asteroid is heading for the system. You choose to give up your
   rocket to save your friends. After that, the game is decorating your planet and building
   friendships.
2. **No mayor.** Neighbours visit your crash site and ask you for things themselves.
3. **Planets open in groups.** Each new rocket part opens two or three planets. You pick the order.
4. **Travel after the story:** your friends build you a small new ship together, as a thank-you.
5. **Asteroids start and end the story.** There is no black hole. An asteroid strands you at the
   start; you crash your rocket into a giant asteroid at the end.

## Changed after the build plan (2026-09-10)

These replace anything above or below that says otherwise.

* **Rocket parts are inside the rocket.** The rocket never shows missing parts. A part makes the
  rocket fly further, and the picker shows the range.
* **The rocket's finish shows progress** (revised the same day). It starts rusty and dirty. Parts 1
  to 3 each clean it more. Part 4 makes it clean and sparkling. Part 5 turns it gold instead of
  white. The gold and the rust must still pass the palette gates in STYLE_GUIDE.md.
* **Every part gets a short celebration.** When a part is fitted, the camera zooms in on the
  astronaut celebrating, then shows the rocket's new finish. Its sound follows STYLE_GUIDE "Sound
  identity" (no mallet jingle).
* **One project step per neighbour per in-game day.** The three steps of a project happen on three
  different game days. An in-game day is 600 real seconds of play (`environment.gd:26`), and it only
  moves while you play.
* **Orbit stays, renamed Professor Comet, a scientist, not a mayor.** Professor Comet watches the
  sky, sees the asteroid that hits your ship, is the voice that tells you what to do at the start,
  and spots the giant asteroid at the end. No mayor role (no renaming, no running the town). The
  code id `mayor_orbit` can stay so saves do not break; only the name the player sees changes.
  Neighbours still visit your crash site.
* **Old saves keep working.** An old save loads as "story finished".

## The story in five beats

1. **Knocked off course.** On a long survey flight, an asteroid hits your ship. The ship breaks and
   you crash on a small planet far from home. This planet becomes home.
2. **Stranded.** The rocket is broken. It can make one short hop, to the nearest worlds.
3. **Friends and parts.** Each neighbour you befriend gives you one rocket part. You fit it inside the
   rocket. Each part lets the rocket fly further.
4. **The call.** The last part goes on. The rocket is ready to go home. Then the call comes from the
   Commons: a giant asteroid is heading for the system.
5. **The choice.** You send the rocket into the asteroid. The asteroid breaks into a shower of glowing
   shooting stars, the fireworks that end the story. You stay, your friends build you a small new
   ship, and the game goes on.

An asteroid took your ship at the start. At the end, you use your ship to stop an asteroid.

## The loop

**Travel → meet a neighbour → help fix their world → earn their part → fly further.**

- **Help means fixing their world's problem.** It is not a random fetch task. Each world has a need
  that comes from what it already is. You meet the need mostly by placing things on their planet, so
  decorating is how you help, not a score.
- **Neighbours visit you.** Between trips, a neighbour lands at your crash site and asks for something
  on your planet. This replaces the mayor's town tasks.
- **The rocket's range is the progress bar.** No stars and no planet rating during the story.

## Range tiers (a first idea, to test)

| tier | open when | worlds | parts you can earn |
|---|---|---|---|
| 1 | at the start | Commons (shops), Zorp, Bolt | Zorp, Bolt |
| 2 | 2 parts on the rocket | Fen, Grig | Fen, Grig |
| 3 | 4 parts on the rocket | Vela | Vela (the last part) |

Five parts total, one per neighbour world. The worlds overhead in the sky are the map: you always see
the next tier before you can reach it.

## World problems (ideas only, the user picks)

| world | what it is today | a problem that fits |
|---|---|---|
| Zorp | violet hollow, glowing blue rivers | the rivers are dimming; relight them |
| Bolt | chrome yard under a ring | the yard's machines are broken; repair them |
| Fen | the sun never climbs past 11 degrees | always dusk; bring light |
| Grig | dry chalk terraces | too dry; bring water and grow a garden |
| Vela | still frost world | frozen and silent; bring warmth |

## What happens to the systems that ship today

| system | plan |
|---|---|
| Rocket and flight | Stays. Becomes the centre of the story. |
| Favors (fetch / bring / deliver) | Reworked into world problems and visits to your crash site. |
| Decorating | Stays. It is how you help during the story, and the main activity after it. |
| Mayor Orbit | Becomes Professor Comet, a scientist who watches the sky. Guides you from the start. Not a mayor. |
| Space trash | Becomes asteroid rubble and bits of your broken ship. You salvage it as scrap. |
| Planet Score | Off during the story. Open after it. |
| Starport Plaza | Becomes the Commons, the meeting place. |

## Rejected

- **The giant asteroid as a dot in the sky, growing with each part.** The user said no (2026-09-10).

## Pacing (decided 2026-09-10)

One task per world was too quick. **Each world problem is a project with three steps**, and some
steps need help from another world, so you fly back and forth. Each step also raises your friendship
with that neighbour. Example, Fen:

1. **Find out why.** Fen's old light towers are dead. You walk the planet and find all of them.
2. **Get the parts.** The towers need power cells. Only Bolt makes them, so you help Bolt first.
3. **Light it up.** You fix the towers and place lamps where Fen wants them. Fen gives you the part.

Target: about 1 hour per world, 5 to 6 hours for the story. This is a guess until a real play-through
times it. No step makes you wait real-world hours (a §1.1 tell).

## Scrap and stardust (decided 2026-09-10)

**Scrap** is asteroid rubble and bits of your broken ship.
* **It appears on every world**, now and then, as a pickup. It replaces most stardust pickups.
* **Fitting a rocket part** costs the friend's gift plus scrap.
* **Building items** (lamps, pipes and other fixes for the world problems) costs scrap, and some
  items also cost stardust. The user chose this knowing that gather-then-craft is close to another
  game's habit; the fixes should stay tied to the world problems, not become a general crafting menu.

**Stardust becomes rare.** It comes mostly from helping neighbours. Today it is too common. Measured
from the code on 2026-09-10: you start with 120 (`game_state.gd:7`); 8 shards grow on home, the hub
and Grig each day (`data/*.tres` `collectible_count`); each favor pays 60 to 140
(`favor_system.gd:27-28`), plus 20% or 40% at higher trust; and cleaning space trash pays stardust
(`trash_piece.gd:122`). The new amounts are set when this is built and checked in a play-through.

## Mini-games instead of fetch trips (decided 2026-09-12)

The user, after playing on their phone: flying back and forth for fetch favours "will get old fast and heats up
the phone". So a neighbour's step is something you play ON their world, built on the jetpack the game already
has (rises 5.6 m/s, ceiling 4.6 m, fuel refilled by landing; the worlds are 9.5-14.5 m across).

**Two shapes, and which one a neighbour uses is part of their character.** They picked both (2026-09-12):

1. **Catch the runaways.** Something of theirs comes loose and drifts at glide height - Bolt's bolts off his
   machines, Zorp's river lights, Grig's seed pods off the terraces. You jump, glide and catch N of them
   before they drift over the horizon. Reuses the collectible plumbing; no change to the jetpack.
2. **Ring run.** A chain of hoops loops around the planet 1-4 m up. You fly the course in order, landing to
   refuel, and a finished lap is the step. Needs a course builder and checkpoints.

**They come back as favours.** The first time you play a neighbour's mini-game it is a story step. After that
it can reappear as one of that neighbour's favours, so there is a reason to visit that is not another fetch
trip.

**Rejected for now:** updraft towers (vents that push you above the jetpack's 4.6 m ceiling). It would change a
tuned number, and the two shapes above cover the need.

## More mini-games, one per neighbour (decided 2026-09-13)

Two shapes will feel repeated by the third world. The user: *"theres probably only so much those 2 mini
games can do before they become redundant"*. Three more were proposed, and they picked all three:

3. **Guide them home.** Things of the neighbour's drift AWAY from you when you come close. You steer them,
   from the far side, into a home spot. The catch game's drifting bodies with the opposite rule.
4. **Signal hunt.** Something is hidden. A pulse at your feet beats faster the closer you are. Find three.
   Calm; walking is enough, flying also works.
5. **Call and response (Simon says).** Stand in a ring near the neighbour. They call a pattern of moves, one
   at a time; each move shows its button and plays its own note. You copy it with the real controls: **Use**,
   **Jump** (tap Fly, or tap Space), **Fly** (hold it until the thruster lights) and **Emote**. The pattern
   grows by one each round. A wrong move only plays the pattern again. No timer: a Fly answer floats you
   down slowly, and the neighbour waits. The ring sits out of talk reach, so Use there never starts a talk.
   **How it got here (same day):** the first pitch copied emotes with the Emote button, but that button
   cannot pick an emote - it cycles wave, happy, dance (`player.gd` `EMOTE_CYCLE`). The user: *"we can make
   the emote game more of a simon says? between Use, Jump, Fly and Emote?"* On both phone and keyboard,
   Jump and Fly are one input told apart by a tap or a hold (`touch_controls.gd` Fly holds "boost" and
   "jump"; `Player.BOOST_GROUND_DELAY` 0.18 s), so all four moves exist on both.

**Each neighbour has a game of their own**, so no game repeats across the story:

| neighbour | game | why it fits |
|---|---|---|
| Bolt | catch the runaways (his bolts) | shipped 2026-09-12 |
| Zorp | ring run along the old river | he loves floating |
| Fen | guide the glow moths home to the pools | the moths carried the pools' light away |
| Grig | signal hunt: dowse for water under the chalk | his world is too dry, and he counts |
| Vela | call and response (Simon says) | her world is frozen and SILENT; she listens to her array |

**Occasional trips to another world, not every project.** The user: *"im fine with occasional steps going to
other worlds but not every one"*. Such a step is a **light link**: quick and empty-handed. You fly there, have
one short talk, and a friend hands you one thing. No collecting and no mini-game on the other world.
Only two projects have one: **Grig** needs a seed pouch from Zorp (a flower that barely drinks), and **Vela**
needs the old warmth readings torn from Fen's logbook. Zorp's and Fen's projects stay on their own worlds.

## Replays from the Commons (decided 2026-09-13)

The user: *"let people play those mini games if they want optionally so they're not just 1 time use and
never seen again"*, and *"in the commons you can pick which game you want and it temporarily takes you to
the world where the game was originally done"*.

* A **game board** stands on the Commons. It lists every mini-game the story has unlocked. A game unlocks
  when its project step is done (`ProjectSystem.played_minigames()`); once the story is over, all of them.
* Pick one, and the rocket flies you to that game's world. The game starts when you land, with the same
  look and size as the story step.
* When it is done, you are offered a flight back to the Commons. Say no, and you stay on that world as
  normal.
* A replay pays a little stardust the first time each game is finished each game day; after that it is
  for fun. The amount is a pacing number (Phase 6), not a promise.
* A replay is never saved. Leave the world, and it ends; nothing is lost.

## Visits and favours (decided 2026-09-13, for Phase 4)

The user picked Phase 4 as proposed, with one change of their own.

* **Friends visit your crash site.** Between trips, a friend is at your crash site when you land at home. They ask
  for one of two things, and neither needs a flight: play their mini-game on your planet (only a game the story has
  already unlocked), or place a gift they brought near your crash site. A visit ends when you fly away, so a
  neighbour is always home when you visit their world.
* **Favours follow the story, per neighbour.** The user: *"When you complete that neighbor's part of the story,
  normal favors can occasionally appear for that neighbor."* So a neighbour offers no favours while their project
  is unfinished. Once they have handed over their part, their ordinary favours come back, now and then, not every
  talk. A neighbour's unlocked mini-game can also come back as one of those favours (decided 2026-09-12).
  Neighbours with no project (the Commons crowd) keep their occasional favours, because they have no part of the
  story to wait for - the lead's call; the user can overrule it.
* **Professor Comet has no mayor job**, and **Starport Plaza is renamed the Commons** everywhere the player reads
  it (both were already decided on 2026-09-10; this phase does them).

## Skips, faster flights and two new looks (asked 2026-09-14)

The user: *"Can we add a speed up or skip option for traveling between planets? after the first time it plays?
because it starts getting a bit tedious especially during fetch quests."* / *"For all skips / speed ups can you have a
pop up that confirms if they want to skip? I accidentally skipped the intro before."* / *"update zorp's look to just
have his whole bottom of his face be a beard of tentacles (mouth not visible) with thicker tentacles than what he has
today. I also want to update professor comet to look more like a professor vs a mayor (e.g. with the cane)"*

* **Every skip asks first.** One shared pop-up ("Keep watching" focused, taps ignored for a moment, the tap that opened
  it can never confirm it) on the crash intro, the radio call, the part celebration, flights, and the finale's
  send-off.
* **Flights after your first one** show a "Skip" button behind that pop-up. The first flight ever always plays in
  full. Changed the same day - the user: *"It feels like we dont need to have both the speed up and skip. People will
  probably just use skip. In which case we dont necessarily need to build the triple speed option."* So there is no
  speed-up and no "Short flights" setting.
* **Zorp** gets a beard of thick tentacles across his whole lower face; his mouth is never visible, and speech and
  feeling move to the tentacles and eyes. **Professor Comet** loses the mayoral top hat and reads as a sky-watching
  scientist, with his cane clearly visible. Changed the same day - the user: *"he looks more like a graduate than a
  professor. Can you make him look more like a professor / scientist like the pokemon professors"*: the lab-coat
  scientist archetype (a long coat over his clothes, the kindly-elder read), in this cast's own shapes, never a copy
  of a particular character. Both builders render two variants; the user sees the winner and the
  runner-up before it ships.

## Mobile data (decided 2026-09-14)

The user: *"I'm conscious of the amount of data this will take when players are not on wifi."* Measured on the live site
that day: about 24 MB on a first open (engine 10.25 MB and game data 13.9 MB over the wire) and again after EVERY update,
because GitHub Pages changes every file's ETag on each deploy; opening the game again with no update costs almost
nothing, and play itself uses no network. The user chose two cuts: **smaller music** (mono at a lower sample rate,
loops still seamless; about 7 MB saved) and **an engine cache** (a strictly versioned service worker that keeps only
the engine, keyed by its hash, with a kill switch; updates then cost about 7 MB instead of 24). A slimmer custom engine
build (about 10 -> 6 MB, big tool downloads and hours of building) is held back.

Also that day: the user picked **Zorp's variant A** (4 long, fat curls in one row), with its phone-camera gap closed.

## Open questions

- **What is in the post-story game** besides decorating and friendship? Not decided.
