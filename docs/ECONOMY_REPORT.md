# Economy and pacing report (2026-09-29, diagnosis only, nothing changed)

Build measured: `.astro_scratch/eco-0929`, an rsync of `safari6-0921/merge23` renamed "AN Eco 0929", imported
headless. Probes added only in that copy: `override.cfg` (autoloads the two test players) and
`tools/eco/eco_probe.gd` + `.tscn` (dumps the catalogue, clock, pickup kinds and gift lists from the running
engine). All Godot runs were one at a time with `taskpolicy -b nice -n 10`.

**How each number was got.** MEASURED = an engine run in the copy. CODE = read from the file:line given.
MODEL = arithmetic on those numbers for an assumed player; nobody has played the game end to end with a timer,
so every playtime figure here is a model, not a measurement.

## Summary

* **Stardust is plentiful and has no job.** The story never asks for stardust. Its only sinks are clothes and
  decorations (33,170 to buy one of each). A typical player earns about 750 a day at first and 1,100-1,300
  later, so money stops mattering at about day 25-30 (8-10 real hours).
* **Scrap has one real sink.** The five parts cost 8 scrap each (40 in all). A single pickup pays 3-6. After
  that, the only thing scrap buys is making your home planet bigger (450 / 950 / 1,700). The camera upgrade that
  was meant to be scrap's second goal (400 / 850) can't be bought, because only the retired space safari sells it.
* **What paces the story is the clock, not money.** A neighbour's steps are 8.5-11.5 real minutes apart. The story
  is about 2-2.5 h at the minimum and 3-4 h for a typical player (MODEL), plus 8-10 h of shopping after it.

## 1. Income (per game day = 20 real minutes)

| source | amount | how often | file | how measured |
|---|---|---|---|---|
| Planet safari, careless player | Bolt 179/164/180, Grig 203/206/161 (mean **182**) | once per planet per day | `safari_review.gd:333` sum of photo prices | MEASURED, seeds 1-3, headless `--fixed-fps 60`, day, not a rare day |
| Planet safari, careful player | Bolt 218/248/265, Grig 271/260/192 (mean **242**) | same | same | MEASURED, same runs |
| Gloop print (best photo of each safari, paid next morning) | best photo 30-50 (mean ~37) | one per safari | `safari_review.gd:406`, `print_table.gd:297` | MEASURED (best price in each run above) |
| Stardust pickups | 5 per world, 9-15 each = ~60 per world | daily on each world you visit | `collectible.gd:47,388` | CODE |
| Favours | 60-140 stardust (+20% for a pal, +40% for a best friend) **plus** a random decoration (mean list price 368, sells for 55) | each neighbour offers one about every 2.18 days; 5 Commons neighbours always, and each story neighbour once their project is done | `favor_system.gd:83-115, 482-493` | CODE; the 368 is MEASURED (probe, weighted over 38 items) |
| Visitor at home | 15 stardust + friendship, gift decoration placed | one per day, once a project has started | `visitor_system.gd:159` | CODE |
| Replay board | 10 per game, first win of the day | up to 5 games | `replay_board.gd:94` | CODE |
| Professor's first task | 15 | once | `professor_ask.gd:43` | CODE |
| Norm's quiz (after the story) | trophies, then a statue; **no stardust**, and the prizes can't be sold (price 0) | 1 day in ~2.7 | `norm_rewards.gd:19`, `norm_system.gd:103` | CODE + probe |
| Cave, meteor survey, home album | nothing | - | STORY_HOME_SPEC 9.2, 9.3 | spec |
| Starting stash | 40 stardust, 5 scrap | once | `game_state.gd:11,15` | CODE |
| **Scrap** pickups | 3-6 each; home 8/day, hub 8/day, the other 5 worlds 2/day each | daily | `collectible.gd:383`, `data/*.tres` | CODE + probe |
| **Scrap** trash at home | 4-10 per piece, 1 piece per 15 real min away, at most 10 | real time | `trash_system.gd:12-13`, `trash_piece.gd:14-15` | CODE |

Safari skill gap: careful earns **1.33x** careless. The whole spread across 12 runs is 161-271. The two planets
paid about the same.

## 2. Sinks

| sink | cost | notes |
|---|---|---|
| Decorations (Cosmo Depot) | 33 for sale, **120-1,500**, median 460, **18,710** for one of each | 11 on the shelf a day: the 3 cheapest plus 8 drawn by the day (`deco_store.gd:13-14,359`). 9 more are never sold (5 legendaries, 4 of Norm's). |
| Clothes (Suit-Up) | 21 for sale, **220-1,500**, median 580, **14,460** for all | the whole list, every day (`clothes_store.gd:313`) |
| **Total, stardust** | **33,170** | cosmetic only |
| Rocket part fit | **8 scrap** each, 40 in all, 0 stardust | `data/*.gd` `part_fit_scrap`; no story item costs anything (`scrap_cost` is absent everywhere) |
| Home planet growth | **450 / 950 / 1,700 scrap** (3,100) | `game_state.gd:159`; the price was set against the old 1,500 s day |
| Camera upgrade | 400 / 850 **scrap**, +3 plates each | `safari_scoring.gd:269`. **Cannot be bought:** `buy_film_upgrade` is only called from `safari_flight.gd:300` and `safari_run.gd:2535`, which belong to the space safari, and that is switched off (`safari_transit.gd:26`) |
| Extra film | 23 stardust a plate | same: space safari only. The planet safari has no way to buy film (`planet_safari.gd:520`) |
| Selling | 15% of list price | `shop_panel.gd:49` |

## 3. Time

* **The day** is 1,200 real seconds: 10 min light, 10 min dark (`world_clock.gd:48-57`; the probe confirms
  `DAY_LENGTH_SEC` = 1014.08).
* **Step gate:** 720 game minutes between a neighbour's steps (`project_system.gd:306`). MEASURED with
  `WorldClock.real_seconds_between`: **8.5 min** (08:00 to 20:00) to **11.5 min** (20:00 to 08:00). The comment
  there, "12.5 real minutes", is stale (it assumes the 1,500 s day).
* **Once a day:** each planet's safari (3:00 plus ~1 min for the fade and review, `planet_safari.gd:121`), the cave
  (3:00), and each replay payout. Five safaris take about 20-22 min, so late in the story the clock caps the day
  before the "once a day" rule does.
* **The part ladder** (`campaign_data.gd:27-29`): Commons, Zorp and Bolt are open at the start; Fen and Grig at
  2 parts; Vela at 4. Each neighbour has 4 steps: 3 steps, then a photo on their own planet. That makes 3 gates,
  so **at least ~30 min per neighbour**. Neighbours in the same tier run in parallel. Grig's step 2 needs a flight to
  Zorp, and Vela's needs Fen. A photo step accepts any photo already in the scrapbook (`project_system.gd:1362`),
  so a good earlier safari can clear it at once.

| stretch | minimum (MODEL) | typical (MODEL) |
|---|---|---|
| Crash, intro, the Professor's first task | 10 min | 15-20 min |
| Tier 1: Zorp and Bolt in parallel | 35-40 min | 50-60 min |
| Tier 2: Fen and Grig in parallel | 35-40 min | 50-70 min |
| Tier 3: Vela alone | 35 min | 40-50 min |
| Finale (party, survey 2:15, fleet, photo) | 12 min | 15-20 min |
| **Story** | **~2.2 h (about 7 game days)** | **~3-3.7 h (about 9-11 days)** |
| Post-game, until you can buy one of everything | - | **+6-8 h** |

"Typical" adds the misses to the minimum: a subject not caught (so the photo step waits for tomorrow's safari),
a gate that opens after you have flown off, and time spent decorating. CORE_LOOP's target was 5-6 h for the
story. At this model the story comes in shorter than that target, and the waits between steps are carried by
safaris and decorating.

## 4. The curve (MODEL, typical player)

Assumptions: a careless-to-careful average of **210** a safari plus a **37** print; 60% of the stardust pickups
found; one favour taken a day in the story and two after it.

| day | open worlds | safaris | stardust / day | running total | what that buys |
|---|---|---|---|---|---|
| 1 | home, hub, bolt | 1 | ~350 | ~350 | the first decoration (120-250) after the first safari |
| 2-4 | + zorp | 2 | ~740 | ~2,600 | a few cheap decorations or one outfit |
| 5-8 | + fen, grig | 3 | ~1,075 | ~6,900 | about 40% of the median price list |
| 9-11 | + vela, finale | 3-4 | ~1,250 | ~10,600 | roughly a third of everything |
| 12+ | all, 10 neighbours with favours | 4-5 | ~1,400 | one of everything at about **day 28** (~9 h) | after that, money only buys duplicates |

**Scrap, typical player** (60% of pickups plus trash): 55-75 a day. The first part fit (8) is paid on day 1. The home
reaches 450 on about day 7, 1,400 on about day 20, and 3,100 on about day 45 (15 h). Someone who sweeps every
world earns about 126 a day and gets there on day 25. **Scrap is never the bottleneck in the story.** After the
story it is the slowest goal in the game.

## 5. Problems, ranked by how much a player would feel them

1. **Stardust never matters for progress.** No story step, part or fit costs stardust, so safari pay only buys
   cosmetics. Good photos earn you nothing you need. With 33k of cosmetics, it takes about 9 h before the number
   stops mattering at all.
2. **The camera upgrade and extra film are dead sinks.** They were built for the space safari and switched off
   with it. On the planet safari you get 10 plates forever. The user ran out of film on his first safari
   (PLANET_SAFARI_SPEC 17.2), and nothing lets him earn more.
3. **Parts cost almost nothing.** 8 scrap is one or two pickups, so scrap is meaningless for the whole story, and
   the "salvage your broken ship" fantasy has no weight.
4. **Grig's "140 stardust" step no longer tests anything.** All 6 Grig runs cleared it (careless 161-206, careful
   192-271). When it was set on 09-26 the careless median was 116, and Grig's safari has gained content since.
5. **The small thank-yous feel stingy next to a safari.** A visitor's whole visit pays 15, a replay 10, the Professor
   15, while one 3-minute safari pays ~200 and a favour 60-140 plus a decoration.
6. **Stale timing comments:** the step gate (`project_system.gd:25,302`) and the home-growth pricing
   (`game_state.gd:138-156`) still assume the 1,500 s day. With the 1,200 s day, scrap comes in about 25% faster
   than those prices assumed.
7. **After the story, earning continues with nothing new to buy** once the list is done (at about 9 h): the cave,
   Norm and the album pay nothing, and you can't sell Norm's prizes. This is the same open post-game question
   as in CORE_LOOP.

Not a problem: the first purchase comes after the first safari, a few minutes in. No single income dwarfs the others:
safari pay, pickups and favours are each about a third.

## 6. Balance options

**A. Wire up what already exists (small, 2-3 files).** This is my pick.
* Sell the camera upgrade (`GameState.buy_film_upgrade`, 400 / 850 scrap, 10 -> 13 -> 16 plates) at the
  home build bench or Pip & Pop, so it applies to planet safaris. It reuses `safari_scoring.gd:269` unchanged. The UI
  goes in the bench's owner file (`build_bench.gd` / `shop_panel.gd` build mode).
* Raise the part fit from 8 scrap to a ladder: **30 / 60 / 90 / 120 / 150** (450 in total) in `data/*.gd`
  `part_fit_scrap`, in fit order. At about 60 a day, each part takes about half a day of honest sweeping,
  without a hard wall.
* Re-set Grig's target from a fresh 5-seed run of each player (it is probably around 200 now).
* What it changes: scrap becomes the story's currency with two visible goals, and a good photographer can
  earn more shots. Stardust stays cosmetic.

**B. Make stardust matter in the story.** Part fits also cost stardust: **150 / 300 / 450 / 600 / 750** (2,250,
`part_fit_stardust`, already read by `shop_panel.gd:505`). That is about 2-3 days of typical income per tier, so
careful photos finish the story sooner. The risk is a new wait if the player spent everything on clothes. Pair it
with option A's camera upgrade.

**C. Stretch the cosmetic curve.** Cut the stardust pickups from 9-15 to 5-9 (`collectible.gd:388`) and favour pay
from 60-140 to 40-90 (`favor_system.gd:83-84`, since favours also give a decoration). Following the 2026-09-21
ruling, raise the cheapest decorations (anything under 200 goes to 200). Leave safari pay alone. This moves "one
of everything" from about 9 h to about 12-13 h, but it does not give money a job.

**Pick: A, with B's stardust fit costs if the user wants photos to matter to the story.** A only reconnects
existing code and numbers, and it fixes problems 2-4. B is the fix for problem 1. C is optional polish once the
user has played.

## What was not measured

* Every playtime and the curve are models. There was no timed human play-through.
* The safari runs are synthetic test players, headless. The logs report the `forward_plus` renderer; the scores
  use the same maths on either renderer. Only day-time runs, no rare day, no night, and only 2 of the 5 planets.
* The favour rate per player, the pickup find rate (60%) and the favours taken a day are assumptions.

## Rulings (the user, 2026-09-29)

Verbatim: "I would choose 3, but also we should raise the prices of everything. Most things should take a couple
days of saving for stardust so that players cant just play through the game and not ever think about having to make
a tough choice with money. Right now its an after thought. We should either lower the amount that you can earn
throughout a day or raise the cost of things so that rare / expensive things, takes a few days of savings. They also
need to earn money by a few methods in case the safari gets old. Saving for money or resources is a big part of a game
like animal crossing or harvest moon, and our game should be balanced like that. i.e. the more time you put in the more
rewards you get."

Lead targets (measured against a "typical full day" D = what a mixed player earns in one game day, target D ~ 800):
* **Option 3:** camera upgrades and extra film are sold for **stardust** (a shop the player already visits), plus
  option 1's scrap part fits (30/60/90/120/150) and a re-measured Grig target.
* **Price tiers:** everyday items ~0.3-0.5 D; most items ~1-2 D ("a couple days"); rare items ~3-5 D; a few
  showpieces ~7+ D. Camera upgrades sit in the 1.5-5 D range so they are a real choice against decor.
* **Earnings:** trim safari pay if needed so D ~ 800 for a mixed player, and more time in = more reward (every
  extra safari, favour or sale still pays; no hard daily cap beyond the existing once-per-planet safari).
* **At least three other ways to earn**, each able to give ~150-300 on a day the player skips safaris: favours, Gloop
  prints, mini-game replays, selling found items or spare scrap, Norm's quiz. A player who never safaris earns at
  least ~40% of D.
