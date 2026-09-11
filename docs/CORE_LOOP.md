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

## Open questions

- **What is in the post-story game** besides decorating and friendship? Not decided.
