# The mystery jungle planet

Status: lead design, 2026-09-29. Building. Story integration is open (the user: "we'll figure out how to
integrate it into the story"), so the world is built **locked behind a flag** with a dev-menu switch.

## 1. The user's words (2026-09-29)

> "work on building a new mystery planet and we'll figure out how to integrate it into the story. It should
> read more like a full jungle potentially, but more alien like. maybe one resident in there that has a shop but
> isnt a neighbor you have to befriend or anything. like a swamp folk kind of person"

## 2. The world: "The Tangle" (working name)

* **A full alien jungle.** Dense, layered, and strange, not Earth-like: giant spiral-stemmed plants, umbrella
  fungus canopies, broad leaves with odd shapes, hanging glow-vines, root arches you walk under, swampy pools with
  low mist, huge seed pods. Colours are alien (teal, violet, amber, a little magenta) but inside the Moonstone
  palette gates (`STYLE_GUIDE.md`). At night the plants glow softly.
* **Still this game's space look** (`ARCHITECTURE.md` 1.1): thin atmosphere, planets in the sky, seen through
  gaps in the canopy.
* Walkable paths wind through the growth; the jungle is dense but never blocks the player in.
* Ambient motion (swaying fronds, drifting spores, dripping vines) is scenery. Photo subjects still appear only in
  safari mode (the standing rule).
* **Travel:** a new rocket destination. Locked by `GameState.flags["jungle_open"]` (false by default); a dev-menu
  row opens it. The lead decides the story unlock with the user later.

## 3. The resident: a swamp folk shopkeeper

* One resident, **not a neighbour**: no favours, no project, no friendship, no story part. Like Gloop: a
  stallholder with a character.
* **Look:** cute chibi like the cast (`CAST_VARIETY.md`, `feedback`: cute, simple face), clearly swamp folk: round
  and mossy, a reed or lily-pad hat, maybe a little lantern or a staff of reed. Unique silhouette.
* **Voice** (`CAST_VOICES_DRAFT.md` rules): plain English a 10-year-old follows, one consistent personality — slow,
  warm, a little mysterious, loves the swamp; one small habit at most. Working name "Moss".
* **Shop:** a stall by the landing spot. Sells jungle-only goods: a few decorations and clothes (e.g. glow-vine
  arch, spiral fern, mossy stump seat, lily-pad lamp, reed hat, moss cape), priced by the economy tiers
  (`ECONOMY_REPORT.md` Rulings: everyday / most / rare / showpiece), stock rotating daily (4-6 items shown).
* **Hosts the safari** on this world ("Want a look around?"), since there is no neighbour here.

## 4. The safari on The Tangle

Same rules and gates as the five planets (`PLANET_SAFARI_SPEC.md` 11-17): density band, 30% variety cap,
calibration, categories, "???" pages, 2 sights + 3 bonus items. Its own roster, alien-jungle themed: small hoppers,
drifting spore creatures, a big shy canopy grazer, glow-tail climbers, pool dwellers; events like a bloom burst, a
spore rain, a firefly-like swarm, a giant flower opening. Its own scrapbook pages.

## 5. Build

J1 WORLD first (planet, biome, travel, lock), then J2 SAFARI and J3 RESIDENT in parallel on J1's result; the
lead integrates. Lean gates (`CLAUDE.md`), frames looked at, phone-scale Compatibility renderer.

## 6. The user's play of merge27, and rulings (2026-09-30)

User, verbatim points: (1) "Moss looks pretty plain features wise besides the outfit, can we update that a bit to make
him more alien like?" (2) "I'm worried about heat on mobile from all the plants on the planet" (3) "in the cave there
was no review of photos" (4) "Instead of Moss's lens how about we have Moss provide something special for the farewell
party. I dont want the last level to drag on too long ... Bonus points if the thing that Moss provides for the farewell
party ends up being used as the beacons for the meteor level" (5) "Moss's shop is generally not too interesting outside
of the outfits ... maybe he teaches you a skill like how to use your jetpack during the safari? which helps you look
around to help spot rarer events (also solves the meteor beacon problem so that we dont need awkward large cliffs)?
Moss narratively could be a field photographer who retired to try to spot a very rare event on that planet, but
because of that he acts as the 'camera upgrade' shop?"

Lead rulings:
* **Moss is "he"**, a retired field photographer waiting to catch one very rare event on The Tangle. More alien
  features (still cute): e.g. eye stalks or a third eye, glowing freckles, frilled gills, antennae.
* **Moss's shop is the camera shop:** the lenses move from Pip & Pop to Moss (spare film stays at Pip & Pop so
  nobody is stuck early); his jungle outfits and decor stay; he sells **the Hover lesson** (rare tier).
* **Hover:** once learned, in first-person safaris you can hold a button to rise a few metres and hover briefly (a
  small fuel meter), then drift down - to look around and spot rarer events. In the **meteor survey hover is always
  available** (the Professor tells you to use your jetpack), and the tall rocky rises are removed.
* **Story:** The Tangle opens **mid-game, after the 4th part**: Vela hears a strange signal; it appears on the rocket
  map. Optional before the finale. **At the farewell party Moss arrives** (introduced by the Professor if you never
  met him) **with a crate of glow pods** from the jungle as party lights. Later those **glow pods are the beacons**:
  each good photo of a crack plants a pod. No extra trip is added to the finale.
* **Mobile heat:** measure the jungle's render cost against the other planets (triangles, draw calls, instances) on the
  Compatibility renderer and cut ground-plant density on web/mobile if it is over the other planets' budget.
* **Cave:** the photo review must run at the end of every cave visit, like the safaris.

### 6.1 Moss's new photo goods (the user, 2026-09-30: "i like steady grip, moss's field notes (but cheaper), tripod and photo filters")
* **Steady Grip** (most tier ~1,200): walk slowly with the camera raised in safaris and the meteor survey. Flag
  `flags.steady_grip`.
* **Moss's Field Notes** (cheap, everyday tier ~150, buy again each day): Moss tells you which rare event is likely
  today on a planet you pick, and roughly where. Flag `flags.field_notes_day` = the day bought.
* **Tripod** (most tier ~1,000): on the home planet the album camera gets a self-timer: set the camera down, walk
  into the shot, and the photo includes your astronaut. Flag `flags.tripod_owned`.
* **Photo filters** (everyday tier ~300 each; e.g. Warm, Old Film, Dreamy, Night Glow): a look you can apply to home
  album photos, cosmetic only. Flag `flags.filters_owned` (list).
