# Astro Neighbor — Quality Bar & Critic Protocol

The standard is **Astro Neighbor's own, and it is measured** (ARCHITECTURE §1): the palette and character gates below, under 14 ms a frame, zero console errors, nothing that floats, clips or pops. Charming, polished, alive, zero jank. It is not "as good as" or "like" another game — ARCHITECTURE §1.1 lists the Animal Crossing tells this game is moving away from, and step 4 checks for them. Critics are adversarial: assume the builder cut corners and go find where.

## Critic procedure (mandatory, in order)
1. Read `docs/ARCHITECTURE.md`, `docs/STYLE_GUIDE.md`, and the builder's report.
2. Run `tools/check.sh` (and the component's showcase scene). Any error/warning = automatic FAIL.
3. **Look at it.** Run `tools/capture.sh <showcase or world scene> <name> <frames> [director]` and open several PNG frames with the Read tool (first, middle, last, and around any action). Do not grade from code alone. For gameplay, write/use a Director timeline under `tests/director/` to walk, jump, interact, open menus.
4. Judge it as this game. Ask: does this frame pass every measured gate below, would it sit comfortably next to the best frames the game already ships, and does it read as *ours* — a tiny planet with its horizon arc, a space sky with neighbouring worlds, an astronaut / alien / robot cast? Then the **identity check** against the ARCHITECTURE §1.1 "is not" list. It blocks only on the two DECIDED items, and only on what *this change* adds: a new speech-like pitched syllable babble ("animalese" — a sound event per typed character, or any per-neighbour voice built from vowel-formant filters for anyone but Zorp), or a new bouncy mallet / whistle start jingle that ISN'T the original track. Zorp's comms voice (`dialogue_box.gd` via `AudioManager.comms_*`), the shared neutral "doot" for every other speaker, and the ORIGINAL title track (`assets/audio/music/title.wav`, `TITLE_VARIANT = "legacy"`) are what ship as of 2026-09-10; a change that did not touch them is not failed for them, and neither is a change that keeps using them as-is. If the change extends an OPEN or UNDER REVIEW system, that is **not** a blocking defect: list it under Non-blocking as an identity flag, so the orchestrator can weigh it against the pending decision. `reference/` images are targets only where STYLE_GUIDE's reference table says so (the astronaut suit).
5. Read the code for the things a screenshot can't show: performance (MultiMesh use, material caching), typed GDScript, contract compliance, edge cases (walk fully around the planet, spam inputs, planet with 0 npcs, empty inventory, save/load round-trip).
6. Write the verdict.

## Verdict format
```
VERDICT: PASS | FAIL
Score: visual X/10, feel X/10, function X/10, code X/10
Blocking defects (must fix):
  1. [file:line or frame] concrete description, what it should be instead
Non-blocking polish:
  - ...
Evidence: list of frames/paths you looked at
```
PASS requires every score ≥ 8 and zero blocking defects. Be specific: "the tree canopy is a single flat-shaded sphere — needs 3–5 overlapping puffs with the toon ramp and darker underside" beats "trees look bad".

## Character rule (user-mandated, overrides everything else for characters)
The characters stay **cute** — chibi proportions, simple faces, matte toon materials. That is the user's standing call and it is not changing. What changed is the yardstick. On 2026-09-04 the user asked for the characters to be compared side by side with Animal Crossing's and made "nearly indistinguishable"; on 2026-09-10 they asked to differentiate, so the game is not called a rip-off (ARCHITECTURE §1.1). The later instruction wins: cute is graded against docs/STYLE_GUIDE.md "Character rules" and docs/CAST_VARIETY.md, not against another game. For ANY character (astronaut, every neighbour, shopkeepers, mannequins):
1. Capture a close-up (face + full body, front, 3/4, back) and a gameplay-distance shot.
2. Build a side-by-side sheet with `python3 tools/compare.py OUT.png "OURS=<capture>:<crop>" ...` against the shipped cast (`showcase/characters_lineup.tscn`), so the character is judged as a member of THIS cast.
3. Read the sheet. The verdict questions are: *does it hit every rule in STYLE_GUIDE "Character rules" and R2.3* — eye size/shape/placement (≈ 12% of head height tall, 8% wide, centres 28-35% of head width apart, at mid-face), head shape, body squatness (head ≈ 0.50 H, no neck, stubby limbs), matte toon materials, chunky hair, tiny nose, a mouth 16-25% of head width, restrained blush; *is it cute at gameplay distance*; and *does it read as an astronaut / alien / robot of this cast*, distinct from every other neighbour (CAST_VARIETY caps)? A miss on any of those FAILS.
4. Include the sheet path in Evidence.

## IMPORTANT: measure the GROUND, not the whole frame (added after the space-sky landed)
Now that the sky is a dark thin-atmosphere space sky (R2.1), a whole-frame measurement is misleading: a frame that is 40% near-black sky will always show a low `value mean` and a low `luma p05` no matter how well-lit the ground is. Chasing those numbers whole-frame would make a builder over-brighten the ground and undo R2.6.

**So: apply the value/luma gates to a GROUND CROP** — the lower-middle of a gameplay frame, excluding sky and HUD. A good default at 1280x720 is `:200,300,1080,640`, e.g.
```
python3 tools/palette.py "ground=$HOME/.astro_captures/snaps/now_home.png:200,300,1080,640"
```
* **Ground crop** must hit: value mean 0.66-0.76, luma p05 0.30-0.42, luma range >= 0.50, blown < 5%.
* **Small planets need a shorter crop.** On the 13 m worlds (Zorp, Bolt) the planet's horizon sits inside the default crop at the 28 deg gameplay camera, so its top rows are sky, not ground. Measured on Bolt: rows 300-368 of the crop carry 13-17% sub-0.30 pixels while the deck itself contributes 0.0%. Use `:200,380,1080,640` there and say which crop you used - do not brighten the ground to compensate for sky in the sample.
* **Whole frame** is still the right place to judge **saturation p90 <= 0.68**, saturation mean 0.36-0.48, and no dominant swatch above S 0.60 — those are about colour intensity, which the dark sky does not distort.
* Report both, and say which crop you used.

## Mobile gate (R2.10)
Review every mobile change on a desktop machine with `--ui=mobile` at a real phone aspect (2340x1080 or 2556x1179 landscape), and confirm the desktop layout still passes at 1280x720 and 1920x1080. Fail if: the touch controls are opaque enough to hide the world behind them; the keyboard hint strip appears on mobile; anything sits under a notch or a home indicator, or under the thumbs; a touch target is under ~48 dp; the camera is pulled back so far that a placed decoration is no longer legible; or any screen requires a mouse. Portrait is out of scope - the game is landscape only.

## Surface-texture gate (R2.9)
Fail any **important** surface that is large on screen and carries no material character: the astronaut's helmet and suit, the neighbours, building walls and roofs, the ground, the rocket hull. Metal needs a travelling sheen and fine grain; cloth a weave and seams; wood directional grain with knots; rock a genuinely rough microsurface; grass and foliage a plump, soft, slightly translucent read. Glass keeps its gloss.
This is NOT a licence to undo R2.6 — texture comes from roughness, normal and subtle albedo variation, never from raising specular into a blown hotspot. Judge it at gameplay distance AND at conversation distance, and confirm the fine pattern fades with distance rather than moireing. Small decoration items and background scatter are exempt.

## Astronaut and jetpack gates (R2.7, R2.8)
Fail the astronaut if the helmet is a tight shell rather than a **big bubble on a visible neck ring**, if the visor is not a large dark oval with crisp comma highlights, if there are no side ear-pods, or if the limbs lack **accent bands** (a stripe down the torso is a wetsuit zip, not a spacesuit). Compare directly against `reference/astronaut 1-3.jpeg` with `tools/compare.py`.
Fail the jetpack if it does not clear tall decorations, if float speed is not about sprint speed, if the backpack puffs are a particle soup rather than painted cartoon puffs, if fuel has no clear HUD read, or if it can strand the player off the surface.

## REVISION 2 gates (these supersede the older numbers)
**Headline gate: `saturation p90 <= 0.68`** on any planet daytime gameplay frame (`tools/palette.py` prints it). Ours was 0.811 (a reference frame measured once, when this gate was set, read 0.673 — a historical number, not one to re-measure against) and the user called the colours "popping too much". Also fail if any dominant swatch is above S 0.60, if luma p95 > 0.93, or if grass/white/sky-blue read as vivid rather than pastel. Natural surfaces must be matte (spec ~0.05); gloss is reserved for the visor, water, chrome and glass. Space scenes are exempt - the user says they already look good.

Read "ART DIRECTION REVISION 2" at the top of docs/STYLE_GUIDE.md. New pass/fail numbers for any gameplay frame: **saturation mean 0.36-0.48**, **value mean 0.66-0.76**, **blown highlights < 5%**, luma p05 0.30-0.42, luma range >= 0.50. Also fail a component if: the sky is earth-blue with puffy clouds; no neighbouring planets are visible in the sky; the astronaut's visor is transparent or has a face behind it; the run pose does not have the arms spread and swept behind; or the rocket trip cuts rather than showing the home planet shrink and the destination grow.

## Palette check (user-mandated, MANDATORY for every visual component)
The user said everything looked *"way too bright and oversaturated"* and *"too bubbly"*, and asked that agents compare *"characters, background shapes, color palettes, textures individually"*. So:
1. Run `python3 tools/palette.py "OURS=<your gameplay capture>"`.
2. Compare against the MEASURED targets table in docs/STYLE_GUIDE.md. A component FAILS if its scene has luma p05 > 0.45, luma range < 0.48, value mean > 0.82, or saturation mean outside 0.38–0.54.
3. Run `python3 tools/compare.py` sheets for shapes too, not just characters: our tree, rock and ground next to the shipped versions on the other planets. Judge silhouette structure against STYLE_GUIDE "Shape language corrections" — tiered/flat-based/crisp, not bubbly.
4. Put the palette numbers and the sheet paths in Evidence.

## Visual checklist
- [ ] Silhouettes read clearly from the gameplay camera; forms are rounded and chunky
- [ ] Toon ramp visible (lit side / cool shadow side); soft shadows cast on the ground
- [ ] Colors match STYLE_GUIDE palette; no default grey/white, no clashing hues
- [ ] Ground has the triangle grass pattern (or the biome's equivalent), not a flat color
- [ ] Nothing floats, clips, z-fights, or pops; props sit exactly on the curved ground with correct up vector
- [ ] Emissives glow with bloom at night; day has warm sun and sky gradient with clouds
- [ ] Particles present where the style guide asks (sparkles, dust, smoke, fireflies)
- [ ] Characters: expressive face, blink, idle bob, correct proportions (head ≈ 45%)
- [ ] UI: rounded Moonstone panels, dark slate text, one amber accent (STYLE_GUIDE Color), consistent font, nothing overflows, focus visible, pop animation. (Baloo 2 is the chosen face, but the committed theme still renders the old system font, and the bundled `Baloo2.ttf` has only the Regular weight — ARCHITECTURE §6 "Known gap". This is a non-blocking note: say which face you saw; do not fail a change on it.)

## Feel checklist
- [ ] Movement responsive (<100 ms to start), smooth acceleration/deceleration, turns lean
- [ ] Jump has squash/stretch and landing puff; can't double jump; can't get stuck
- [ ] Camera smooth, never clips terrain, no jitter when walking around the planet (including over the "poles")
- [ ] Interactions have feedback: sound + animation + toast
- [ ] Dialogue typewriter; advancing feels snappy; the change adds no speech-like pitched syllable babble ("animalese"). Voice work itself is judged against STYLE_GUIDE "Sound identity" (Zorp's framed comms voice; a shared neutral, non-vocal doot for everyone else, no per-neighbour timbre, no framing) — this ships as of 2026-09-10, and a change that keeps using it as-is is not failed for it
- [ ] Placement mode: ghost preview, rotation, blocked spots, confirm sound, item appears with a pop

## Function checklist
- [ ] `tools/check.sh` clean
- [ ] Director play-through (walk/jump/interact/menu) completes without errors
- [ ] Save → quit → load restores stardust, inventory, placed decorations, favors, style
- [ ] Every planet loads; rocket round-trip home→hub→zorp→bolt→home works
- [ ] Favor lifecycle: offer → accept → progress → complete → reward toast + inventory
- [ ] Shops: buy decreases stardust, item appears in inventory; clothes change the model immediately
- [ ] 60 fps: `capture.sh` prints CPU/GPU ms per frame — must be < 14 ms average at 1280×720

## Code checklist
- [ ] Follows ARCHITECTURE contracts and node paths; no cross-domain edits
- [ ] Typed GDScript, no warnings, no magic numbers without a const/@export
- [ ] MaterialLib used; MultiMesh for repeated small things; no per-frame allocations in hot loops
- [ ] Showcase scene exists and is representative

## Automatic FAIL triggers
Any placeholder geometry or "TODO" in a shipped path · console errors/warnings · missing showcase scene · builder claims done but a listed feature is absent · text overflow · frame time > 16 ms · player can fall through or leave the planet · a change that adds speech-like pitched syllable babble ("animalese") or a bouncy mallet/whistle start jingle that isn't the original track (the two DECIDED items in ARCHITECTURE §1.1; Zorp's comms voice, the shared doot, and the original title track that ship as of 2026-09-10 do not count, since they are what the user chose after listening) · anything that would embarrass us in a screenshot a player shares.
