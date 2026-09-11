# CAST_VARIETY.md — the standing contract for how the neighbours differ

**Status:** written 2026-09-07, at the END of the cast-variety pass, from the six binding rulings and
the shipped result. It is a CONTRACT, not a plan: everything in the tables below is measured off the
code as it stands. See `docs/OPEN_ISSUES.md` item 37 for what the pass fixed and what is still open.

> **Historical note.** Nine build agents were told to read a `docs/CAST_VARIETY.md` that did not
> exist; all nine reported it missing and worked from the six rulings quoted in their briefs plus
> `synthesis.md` / `critic.md` in the session scratchpad. Those two source documents were never in
> the repo and are now gone. This file exists so the next pass has the contract in version control.

## Why this file exists

The user's complaint was that five of the neighbours were one creature in five colours:

> "Too many of the alien characters fundamentally look the same (Zorp, pip, pop, grig and fen). Eye
> stalks, rocky texture skin with spots, same open mouth, all have more male attributes than female.
> They need to vary more across the board."

The mechanical cause was that all five called the same three helpers — `_add_eyestalks`,
`_add_wide_grin`, and `{"surface": "skin"}`. **The failure mode is convergence: a shared helper is
the path of least resistance, so every new character drifts toward the same three calls.** The caps
below exist to make that drift visible.

## The six rulings (binding on every agent that touches a character)

1. **Gender is a shape vocabulary, not accessories.** What read as male was heavy brows, lid ridges,
   toothy grins, blunt jaws and broad wedges. The fix is WIDENING that vocabulary — plates, drapes,
   ribs, asymmetry, growth — not adding lashes. **Lashes on at most ONE character in the whole cast.**
   Prefer eye shape, head shape, proportion, palette and manner: they cost no parts, and they still read
   at 8 m where a lash or a surface pattern does not (see "The other differentiators, which are free").
2. **Cap the hard vocabulary.** No character may wear more than TWO of
   {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke}, and at least one of the three elders
   (Fen, Grig, Mayor Orbit) wears NONE. The cast total must go DOWN, not be re-sorted onto one
   character.
3. **Do not write declared sexes into code comments.** Exactly one neighbour's gender is stated in
   shipped text (`npc_data.gd`, Pop is Pip's brother). Everything else being unmarked is an asset.
   Describe SHAPES and MANNER, not "clearly feminine" / "clearly masculine".
4. **The legless floating character must not be the designated-female one.** Making the only
   character denied legs the one woman is the genie/mermaid trope. (Resolved: Vela walks, on a real
   jointed leg with a lander-pad foot, and is presented as neutral.)
5. **At most TWO** keep eyestalks; **at most TWO** keep the wide toothy grin; `sd_skin` on **at most
   TWO** at genuinely opposite settings; and **ONE character has NO surface pattern at all**, which
   is what makes everyone else's pattern read as a choice.
6. **Closed mouths must differ in KIND, not width** — a straight lipless bar, a round toothless slot,
   an under-bite, no mouth — because at 8 m a closed arc is one dark line and width is the weakest
   possible differentiator. **At most ONE closed arc across the whole cast.**

## The shipped cast — who holds which scarce slot

Every cell below is verifiable with `grep` in `src/characters/models/`. If you are adding or
reworking a neighbour, **check this table first**; if your change fills a slot that is already full,
something else has to give it up.

| slot (cap) | holders | how they differ from each other |
|---|---|---|
| **eyestalks** (2) | Grig, Fen | Grig: ONE, a cyclops on a 0.560 m trunk. Fen: THREE, graded 0.407/0.319/0.240 m and swept across the crown |
| **wide toothy grin** (2) | Grig, Fen | Grig: an under-bite (`row_sign: -1`) with a corner tusk. Fen: four blunt upper teeth, no lower row |
| **`sd_skin`** (2, opposite) | Zorp, Grig | Zorp `surface_scales` 0.0 / `spot_radius` 0.74 — smooth with big soft blobs. Grig `surface_scales` 1.35 / `spot` 0.0 — dry craze, no spots at all |
| **`sd_scales`** (kind 8) | Fen | true overlapping shingles; a different SILHOUETTE, not a different speckle |
| **`sd_foliage`** (fur) | Pip | `surface_scale` 2.6 / strength 0.42, plus real fur fringe geometry |
| **no surface at all** (exactly 1) | **Pop** | the deliberate blank that makes everyone else's pattern read as a choice |
| **the single closed arc** (1) | **Zorp** | a volumetric 110 mm lip, earned by being a solid rather than an ink line |
| **lashes** (≤1) | **nobody** | zero across the cast |
| **hard vocabulary** (≤2 each) | Fen: none · Vela: none · Zorp: none | ruling 2's elder clause is satisfied by **Fen** |

Closed mouths, by KIND (ruling 6): Zorp = the one arc · Pop = a straight lipless bar ·
Vela = `mouth: false`, none at all · Grig = an under-bite.

## The other differentiators, which are free

These cost no triangles and no slots, and they are the first place to reach before adding parts:

* **Head exponent and proportion.** `head_n` runs 2.8 (Pip) / 3.0 (Pop) / 3.2 (Zorp, Mayor) /
  3.6 (Fen). `head_semi` does more work than any surface: Fen's (0.410, 0.170, 0.260) wide flat wedge
  is unlike anything else shipped.
* **Eye shape.** A circle in a pale sclera (Pip) against a raked solid almond with no sclera at all
  (Pop) is a bigger difference than any pattern. Note Pop's point is on the OUTER corner — built at
  the inner corner it renders as a scowl, which is why the rake is 12 degrees and not 20.
* **Manner.** `blink_hold` alone separates Fen (1.55 — a blink every 4.7–7.8 s) from the cast's 3–5 s.
* **Palette temperature**, and **body proportion** (Pop is 1.10 wide, Pip 0.94).

## Rules that bit during the build — do not re-derive these

* **Surface detail cannot carry species identity at gameplay distance.** The library's own header
  records that a 10 % albedo change arrives as ~1.5 % on screen. Treat "skin" as a fourth-order
  detail axis: **if two characters are still distinct with every surface switched off, the cast
  works; if any pair collapses, that pair needs a geometric fix, not a shader parameter.**
* **`sd_scales` and `sd_skin` are not comparable at equal strength.** `sd_skin`'s spot term fires on
  ~5 % of the surface; `sd_scales` tints AND bump-perturbs every fragment. A strength that is safe on
  skin renders as bubbles on scales. Fen went 0.85 → 0.45 → **3.10 scale / 0.24 strength**, and the
  first two were both rejected on a render as "blackberry".
* **`--headless --quit-after N` does not check a character.** It only loads what the boot scene
  reaches. Use `--import` (class registration), `tools/check.sh` (load errors) and
  `tools/capture.sh` (anything visual). Every real bug in this pass was invisible to every numeric
  test and visible in the first render.
* **`tools/capture.sh` is NOT deterministic** — two runs of the same scene with identical code differ
  by ~55,000 pixels at 1280x720. Judge renders by LOOKING at them; a before/after pixel diff smaller
  than that is meaningless.
* **The triangle budget is 6000 per neighbour**, checked only by
  `godot --headless --path . res://showcase/characters_lineup.tscn -- --stats`. A new neighbour must
  be added to BOTH `ORDER` and `LABELS` in `src/characters/showcase/lineup_showcase.gd` or it is
  invisible to QA. An id missing from `NpcModels.make()` silently returns a generic `AlienModel`, so
  a typo ships as a duplicate Zorp.

## Still unclaimed (see OPEN_ISSUES 37)

* **Tentacles / horns around the head** — the one trait the user named that nobody shipped.
  `_add_tendril_ring` and `_add_horn` both exist and have **zero call sites**.
* **A character that reads as YOUNG.** Costs no geometry; nobody stands on that axis.
