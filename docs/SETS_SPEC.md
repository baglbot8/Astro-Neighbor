# Furniture sets, matching outfits, and more ways to get them (2026-10-21)

The user, 2026-10-21: *"I think we need more furniture options in the game and maybe in matching sets as well
that people may collect. ... can you make a few more decoration sets and clothes as well. We may also need other
ways for people to get this furniture (e.g. favors) beyond the store since it will take too long to collect what
players want."*

The user was asleep while this was built, so the lead chose the design. Everything here is new content plus three
small systems. Nothing that ships today is removed.

## 1. What ships

* **Five neighbour sets**, one per world neighbour. Each set has **6 pieces** (sold by Pip & Pop, priced in the
  normal tiers) and **1 bonus piece** (never sold; you get it when you own all 6). 35 new decorations.
* **Five matching outfits**: one suit and one hat per set, sold at Suit-Up (Stella), plus **3 extra suits and 2
  extra hats** for general variety. Bolt's suit is the existing `suit_gearworks`, so 4 new set suits.
* **The three older groups also count as sets** on the Sets page (display only, no bonus): the Cozy Home set (the
  12 `COZY` rows), Moss's Tangle goods (the 5 `JUNGLE` rows), Norm's Totally Normal Collection (the 8 `STAMPS`).
* **Three new ways to get furniture** (section 4): neighbour gifts from their own set, the set bonus, and Pip & Pop's
  order book.
* **A Sets page** in the journal that shows each set's progress and where to get the missing pieces.

## 2. The five sets

The set data lives in `src/decorations/sets/set_<id>.gd` (format in section 3). Ids, names, tiers and prices below
are fixed by the lead; a builder may change a footprint (to match the scene) or polish a description, nothing else.
Price tiers are `ECONOMY_REPORT.md` "Rulings": everyday 240-400, most 800-1600, rare 2400-4000.

Each set must read as ONE family: one shared colour story drawn from its neighbour's world, one repeated motif
(a shape, a trim, a joint) that shows on every piece, and the same build grammar. Put the 7 side by side and a
stranger should sort them into the right family. A piece must not be a recolour of an existing decoration.

| set id | name | neighbour | world look to draw from | motif |
|---|---|---|---|---|
| `tinker` | Tinker Workshop | bolt | chrome yard under a ring; brass, steel, warm orange | exposed cogs and rivets, round bolt heads |
| `glowshroom` | Glowshroom Hollow | zorp | violet hollow, glowing blue rivers | mushroom caps, soft spotted domes, blue glow |
| `long_dusk` | Long Dusk | fen | terracotta flat, sun always low, slate blue | woven bands, clay curves, low long shapes |
| `chalk_terrace` | Chalk Terrace | grig | dry staircase of chalk terraces, sage scrub | stacked steps, carved grooves, blocky stone |
| `frost_cabin` | Frost Cabin | vela | still frost world, pale ice, deep navy | knitted snow, icicle drips, cosy against cold |

Pieces (id prefix = set id, so every file is easy to find; `B` = the bonus):

**tinker** (Bolt): `tinker_gear_stool` Gear Stool (furniture, 300) · `tinker_oilcan_lamp` Oil-Can Lamp (lights, 360)
· `tinker_tool_rack` Tool Rack (furniture, 950) · `tinker_workbench` Tinker Workbench (furniture, 1200) ·
`tinker_cog_clock` Cog Clock (fun, 1400) · `tinker_spring_sofa` Spring Sofa (furniture, rare 2800) ·
B `tinker_helper_arm` Helper Arm (tech) - a desk robot arm that slowly sorts bolts.

**glowshroom** (Zorp): `glowshroom_puff_pouf` Puffball Pouf (furniture, 280) · `glowshroom_spore_lantern` Spore
Lantern (lights, 380) · `glowshroom_river_table` River-Stone Table (furniture, 1000) · `glowshroom_crystal_shelf`
Crystal Shelf (furniture, 1300) · `glowshroom_toadstool_lamp` Toadstool Floor Lamp (lights, 1500) ·
`glowshroom_glow_pool` Glow Pool (fun, rare 3000) · B `glowshroom_daybed` Glowshroom Daybed (furniture).

**long_dusk** (Fen): `long_dusk_clay_pots` Clay Pot Pair (plants, 320) · `long_dusk_woven_mat` Woven Mat (furniture,
340) · `long_dusk_lantern` Dusk Lantern (lights, 900) · `long_dusk_bench` Terracotta Bench (furniture, 1100) ·
`long_dusk_lounger` Sun Lounger (furniture, 1450) · `long_dusk_parasol` Sunset Parasol (furniture, rare 2600) ·
B `long_dusk_sundial` Long-Shadow Sundial (fun) - its shadow always points to dusk.

**chalk_terrace** (Grig): `chalk_terrace_step_stool` Step Stool (furniture, 260) · `chalk_terrace_planter` Terrace
Planter (plants, 350) · `chalk_terrace_pillar_lamp` Pillar Lamp (lights, 1050) · `chalk_terrace_stair_shelf` Stair
Shelf (furniture, 1250) · `chalk_terrace_table` Carved Stone Table (furniture, 1550) · `chalk_terrace_basin` Rock
Basin Fountain (fun, rare 3200) · B `chalk_terrace_arch` Terrace Arch (signs).

**frost_cabin** (Vela): `frost_cabin_snow_pouf` Snowball Pouf (furniture, 290) · `frost_cabin_icicle_lamp` Icicle
Lamp (lights, 390) · `frost_cabin_snowflake_rug` Snowflake Rug (furniture, 850) · `frost_cabin_sled_bench` Sled
Bench (furniture, 1000) · `frost_cabin_ice_table` Ice Block Table (furniture, 1300) · `frost_cabin_stove` Pot-Belly
Stove (lights, rare 2700) · B `frost_cabin_aurora_lamp` Aurora Lamp (lights) - a slow ribbon of light.

Bonus pieces are rarity `legendary`, price 0, and should be the most charming piece in the set (a little motion is
welcome: a slow turn, a sway, a pulse - cheap, in `_process` or a shader, the way existing items animate).

## 3. Data format (the contract between builders)

```gdscript
# src/decorations/sets/set_tinker.gd
extends RefCounted
const SET := {"id": "tinker", "name": "Tinker Workshop", "neighbour": "bolt",
	"blurb": "...", "outfit": ["suit_gearworks", "hat_tinker_goggles"]}
# Same columns as decoration_catalog.gd's tables: id, name, category, rarity, price, footprint, icon_color, desc
const PIECES: Array = [ [...], ... ]   # the 6 sold pieces
const BONUS: Array = [...]              # one row, price 0
```

* Scenes are `src/decorations/items/<id>.tscn` + `.gd`, extending `DecoItem`, built with `DecoKit`, exactly like
  the Cozy set (`tea_table.gd` is a good model). `footprint` in the row must equal the scene's `DecoItem.footprint`.
* The catalog registers each piece as `deco_<id>` with `"set": "<set id>"`. The bonus also gets
  `"source": "set"` and price 0, so no shop stocks it and `Catalog.random_reward_decoration` never draws it.
* Outfit ids: `suit_gearworks` (exists), `suit_glowshroom`, `suit_long_dusk`, `suit_chalk_terrace`,
  `suit_frost_cabin`; hats `hat_tinker_goggles`, `hat_toadstool`, `hat_dusk_sunhat`, `hat_chalk_headlamp`,
  `hat_frost_bobble`. Clothing defs carry `"set": "<set id>"` too.

## 4. Three new ways to get furniture

1. **Neighbours give from their own set.** When a favour from a set's neighbour pays out, the reward item is a
   piece of THAT set (or its outfit) that the player has never collected, picked at random. When nothing is left
   they fall back to today's random roll. The Commons crowd (Pip, Pop, Stella, Mayor Orbit, DJ Nova, Moss, Gloop,
   Norm - whoever gives favours) gives from the Cozy Home set the same way. The stardust reward, trust bonuses and
   the signature legendary are unchanged. The toast names the set: "You got a Cog Clock! (Tinker Workshop 3/6)".
2. **Set bonus.** The moment the player has collected all 6 pieces of a neighbour set, they get its bonus piece
   (into the bag), a toast "Tinker Workshop complete! Bolt sent a Helper Arm", and the `quest_complete` sound. Once
   only (a GameState flag).
3. **Pip & Pop's order book.** Cosmo Depot gets an "Order" choice beside buy and sell: any piece of any set the
   player has collected at least one piece of, at its normal price, any day - no waiting for the daily rotation.
   Bonus pieces and source-only goods (Moss, Norm) are never in it.

**"Collected" means ever owned**, not "in the bag now": placing or selling a piece must not undo progress. GameState
keeps a saved record of every decoration and clothing id the player has ever had. An old save fills it once on load
from the bag, every placed decoration on every planet, and the wardrobe.

## 5. The Sets page

A "Sets" tab or page in the journal (`src/ui/journal/journal_panel.gd`). One row or card per set: name, neighbour,
`n/6`, each piece with a tick when collected and its name greyed when not, the bonus shown as a mystery ("???")
until earned, and one line saying where pieces come from ("Pip & Pop · Bolt's favours"). It must fit and be
readable on a phone (`--ui=mobile` at 2340x1080) and on desktop at 1280x720, with touch targets of at least 48 dp.

## 6. Gates (every critic checks these; builders get them up front)

Art (sets and hats):
* Every piece builds with no errors, and its triangle count (`showcase/decorations_gallery.tscn -- --tris`) is no
  higher than the most expensive existing decoration in the same rarity.
* Look at the pieces in the real game scene (the gallery parade on the real home planet, day AND `--night`), at
  gameplay distance and close up. They take the crochet look like every other placed decoration (`STYLE_GUIDE.md`
  "Crochet look"), keep to the palette gates in `STYLE_GUIDE.md`, and lights glow at night.
* The 7 pieces of a set read as one family (section 2), and each reads as what its name says at gameplay distance.
* Scale is right next to the astronaut (1.4 m tall): a stool is knee-high, a table waist-high, a lamp taller.
* Each piece places, rotates and picks back up in the real home world without clipping into the ground.
* Hats sit on the helmet with no gap and no poke-through at any turn angle, keep the opaque visor visible, and fit
  the chibi silhouette. Suits keep the colour-blocking rule (accent differs in hue AND value).

Systems:
* A favour from Bolt pays a Tinker piece you have never had; once all are had it falls back to the old roll.
* Collecting the 6th piece gives the bonus once, and never again after a save and reload.
* Placing or selling a piece keeps it "collected"; an old save (no record) fills the record on load.
* The order book lists only pieces of started sets, never bonus/Moss/Norm goods, charges the price, refuses when
  short of stardust.
* The Sets page is right after a save and reload, and fits on a phone.
* `tools/check.sh` passes; all seven worlds boot.

## 7. Who owns which files

| builder | owns |
|---|---|
| SETS-A | `tinker` + `glowshroom`: their `sets/set_*.gd` and 14 `items/<id>.gd/.tscn` |
| SETS-B | `long_dusk` + `chalk_terrace`: same |
| SETS-C | `frost_cabin`: same (7 scenes) |
| WARDROBE | `src/hub/clothing_catalog.gd`, `src/player/astronaut_model.gd` (hats), the wardrobe showcase |
| SYSTEMS | `decoration_catalog.gd`, `catalog.gd`, new `src/decorations/deco_sets.gd`, `game_state.gd`, `favor_system.gd`, `deco_store.gd`, `shop_panel.gd`, `journal_panel.gd` |

Nobody else edits these. If you need a change in someone else's file, put it in `needs_from_others`.

## 8. What was built (2026-10-22)

All five lanes PASSED their critics (SETS-A after one fix round: three lamps did not read as lit at night).
* 35 set decorations, 776-1,938 tris each, every one under the most expensive existing decoration of its rarity.
* No new set piece uses an OmniLight. At night a decoration's OmniLight turns nearby crochet surfaces black in
  stitch-row stripes (seen on the shipped Reading Lamp and Cosmic Mushrooms, both renderers; cause not found -
  `OPEN_ISSUES.md`). The set lamps glow through emissive parts, a halo and a ground glow instead.
* Clothes: 4 set suits + suit_gearworks tagged, 5 set hats, 2 extra hats (Flower Crown, Orbit Ring), 3 extra
  suits (Cherry Pop, Lemon Lime, Orchid). Frost Cabin's suit is glacier blue, not pale ice: AstronautModel's
  SUIT_TINT turns a pale ice suit grey, too close to Chalk Terrace.
* Systems: `src/decorations/deco_sets.gd`; `tests/sets_probe.tscn` proves the section 6 systems gates headless.
  Cosmo Depot's menu is now Buy / Sell / Order / Leave (Leave moved from index 2 to 3).
* Known small: a gifted suit or hat also lands in the bag, so it can be sold (the stamp-card pattern); the set
  pieces were placed only through synthesised DecorationManager calls; no phone test yet.
