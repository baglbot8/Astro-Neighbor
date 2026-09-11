
# ART DIRECTION REVISION 2 (2026-09-05) — READ THIS FIRST, IT OVERRIDES EARLIER SECTIONS

The user played the improved build and gave four corrections. Where these conflict with anything below, **these win.**

> *"during rocket animation i'd like to see our planet get smaller and we move through the sky and approach the new planet."*
> *"I think you should always be able to see planets in the distance. since youre an astronaut theres not enough atmosphere so there shouldnt be a full light blue sky and clouds"*
> *"the characters faces look too much like a cute kids tv show like cocomelon and flat pressed into the glass mask. Everything is still a bit too much on the bright color scale and round. Maybe the astronauts mask is just navy blue like you cant see through it"*
> *"The walking also looks a bit stiff like a waddle. Running should have his hands spread out and slightly behind him"*

## R2.1 — THIN ATMOSPHERE. No earth-like blue sky. [ENVIRONMENT BUILDER]
These are tiny airless worlds and the player is in a pressure suit. The bright blue sky with fluffy white clouds is wrong and must go.
* **Daytime sky**: a deep, thin gradient — near-black at the zenith (`#0a0f2e`-ish) softening to a dusty, slightly warm haze right at the horizon (a thin rim, like the Moon or Mars horizon glow). Not black-and-empty; a *thin* atmosphere, so a subtle band of colour hugs the limb and the sun still lights the ground warmly.
* **Stars are visible in daylight**, dimmer than at night but always present, because there is not enough air to scatter them out. Keep them crisp pinpoints.
* **Cut the puffy cloud shells.** At most a few very thin, high, sparse wisps — or none. Grape-cluster cloud puffs are gone for good.
* **Other planets are always in the sky.** Zorp's violet world, Bolt's chrome world with its ring, and the hub must be visible as small distinct bodies from every planet, correctly lit by the sun, slowly drifting, at plausible relative sizes. They are the strongest "I am in space" cue in the whole game and they double as navigation. The space-travel scene already models these worlds — share the look so a planet seen from the ground matches the one you fly to.
* Night gets *more* dramatic: a dense star field, the milky band, the moons, and the neighbouring planets clearly visible.
* Keep the ground lighting warm and readable. The ground is not the problem; the sky is.

## R2.2 — The astronaut's visor is OPAQUE NAVY. No face inside. [PLAYER BUILDER]
The user's own fix for "flat pressed into the glass mask": *"Maybe the astronauts mask is just navy blue like you cant see through it"*. Do exactly that.
* The visor window is a **solid, opaque deep navy** (around `#1b2450`), slightly glossy, with **one crisp specular streak** and a thin accent rim. You cannot see through it at all.
* **Delete the face geometry inside the helmet** (eyes, brows, nose, mouth, blush, hair). Delete the see-through-glass machinery with it. This removes a whole class of bugs at once: the steel-blue tint on the skin, the face going black under a tree, the shadow-receive cheat on the head, and the "cocomelon face squashed against glass" read.
* All personality now comes from **body language and silhouette** — posture, the waddle, emotes, the antenna, the backpack. Expression cues can be carried by a small emissive glyph or indicator on the suit or helmet rim if needed, but keep it subtle.
* The helmet shell stays an opaque rounded shell; the navy window replaces the tinted one.

## R2.3 — Less "cocomelon". Less bright. Less round. [ALL VISUAL BUILDERS]
The user says the characters read like a preschool cartoon and everything is still too bright and too round.
* **Faces (NPCs)**: keep them simple and readable, but drop the baby-doll register — smaller and less glossy eyes relative to the head, no giant white sclera domes, restrained blush (or none on the robots), and no wide permanent grin. Aim for a *quiet* register — calm, knowing, a little dry, like a neighbour who has lived on their rock a long time — rather than the sugary baby-doll end.
* **Palette**: pull saturation and value down another notch across the board. Target **saturation mean 0.36–0.48** (was 0.40–0.52) and **value mean 0.66–0.76** (was 0.70–0.80) on a gameplay frame. Blown highlights **under 5%** (was 8%). Fewer pure-white and pure-pastel surfaces; more mid-tones and more genuinely dark values.
* **Shape**: keep the chunky charm but add structure — flat planes, chamfers, panel lines, tapers and hard edges alongside the curves. If a form can be described as "a ball" or "a bunch of balls", rebuild it. This applies to props, buildings, rocks, foliage and characters alike.

## R2.4 — Locomotion: less stiff waddle, real run pose. [PLAYER BUILDER]
* **Walk** currently reads as a stiff mechanical waddle. Give it weight and follow-through: a real weight shift onto the planted foot, a slight torso counter-rotation against the hips, arms swinging from the shoulder with a lagging elbow and a soft settle at the end of each swing, and a subtle head bob a beat behind the body. Vary the timing slightly rather than a perfect metronome.
* **Run**: the user asked for a specific pose — **arms spread out and held slightly behind the body**, leaning forward, legs driving underneath. Think the classic cartoon "full sprint" silhouette. Bigger forward lean than the walk, longer stride, more vertical bob, dust trailing.
* The difference between walk and run must be obvious in silhouette alone.



### Eye spacing: 28-35% stands. Decision, with the reasoning. [orchestrator ruling]
A builder measured two animal characters on the (now retired) reference screenshots at **55.3%** and **50.4%** of head width between eye centres, versus the 28-35% in this guide, and asked whether the doc is wrong. The doc stands, for two reasons:
1. **Wide-set eyes low on a big round head is the strongest "baby" cue there is** — and the user's standing complaint is that the characters read like "a cute kids tv show like cocomelon". Widening to 50%+ would push directly into the register they rejected.
2. **Those two were animals, and our cast is not.** Their spacing follows animal skull anatomy — eyes set inside a wide face mask, or either side of a muzzle — and no alien, robot or astronaut in this cast has that skull (ARCHITECTURE §1.1: aliens and robots, not animals). So there is no anatomical reason to follow them, and reason 1 is a strong reason not to. The band is bounded from the other side too: at 40% the eyes read wall-eyed ("Character rules").
Keep 28-35% measured as rendered. If a specific character has a genuine animal-mask design reason to go wider, raise it in your report rather than changing the number.


## R2.7 — THE ASTRONAUT READS AS A SCUBA DIVER. Fix the suit. [PLAYER BUILDER]

> *"The astronaut character reads more like a scuba diver. I added some references for astronauts."*

New references: `reference/astronaut 1.jpeg`, `astronaut 2.jpeg`, `astronaut 3.jpeg`. **Read all three before touching the model.** Here is why ours reads as a diver and what the references actually do:

**Our mistake:** the helmet is a *tight shell hugging the head* with a small window in it — that is a wetsuit hood with a dive mask. Every real-astronaut reference instead has a **big rigid bubble sitting ON TOP of a neck ring**, clearly wider than the head inside it, with a large visor filling most of the front.

**What every reference has, and we must have:**
1. **A big bubble helmet on a neck ring.** A near-spherical dome noticeably wider than the head and wider than the shoulders are thick, meeting the suit at a **visible collar/neck ring** — a distinct band, not a smooth blend. This single change is most of the fix.
2. **A large dark visor** filling roughly the front two-thirds of the dome as a big oval, near-black or gold-amber, with **one or two crisp comma-shaped white highlights** (see astronaut 2's two clean highlight shapes). Keep it opaque per R2.2 — the references are opaque or near-opaque too, which is exactly why they read as astronauts.
3. **Side ear-pods**: a short cylindrical housing on each side of the helmet where it meets the collar. Small, but they are a strong astronaut signal and we have none.
4. **Orange/amber accent bands on the limbs** — a ring at the bicep and forearm, at the thigh and shin, and around the boot cuffs. The references use 4-8 of these. Ours has piping down the torso instead, which reads as a wetsuit zip. **Bands around limbs, not stripes down the middle.**
5. **A chest control panel** — a rectangular box on the chest with a few small buttons or dials.
6. **A backpack (life-support pack)** that reads clearly from the side and back as a box or a pair of cylinders behind the shoulders.
7. **Puffy, softly segmented limbs** — a few subtle ribs or seams at the elbows, knees and waist so the suit reads as thick fabric over a pressure layer, not as skin-tight neoprene.
8. **Off-white / cream suit**, never pure white (this also serves R2.6).

Keep the chibi proportions from "Character rules", keep the opaque visor (R2.2), keep the four colour zones, and stay under the 6,000-tri budget.

## R2.8 — JETPACK BOOST [PLAYER BUILDER]

> *"let's add a small jetpack boost (with puff clouds coming out from the backpack) that if held helps the astronaut go higher and float a bit toward the ground while moving. It should be about as fast as sprinting while floating in the air, and may also help with hopping over tall decor or something"*

A new core traversal verb. Requirements:
* **Hold to boost.** Held from a jump (or from the ground) it pushes the astronaut higher, then lets them **float down slowly** while still moving. Horizontal speed while floating is **about sprint speed (~7 m/s)**, so boosting is a real way to travel, not just a jump extender.
* **Clears tall decorations.** It must be enough to hop over the tall props and decorations, which is the user's stated use.
* **Puff clouds from the backpack.** Soft cartoon puffs from the pack's nozzles — the same painted-puff language as the rocket's exhaust, not a particle soup. Small thruster glow is fine. This is the main visual read, so make it charming.
* **Limited, and it recharges.** Give it a small fuel budget with a clear HUD read so it feels like a resource rather than free flight, and refill it on the ground. Pick sensible numbers, tune them by playing, and state them in your report.
* **Pose**: a distinct in-air boost pose, legs trailing, arms out for balance — readable in silhouette against the jump and fall poses.
* **Input**: bind a new action rather than overloading an existing one; `jump` held while airborne is the natural fit. Add it to `project.godot`'s input map for keyboard and gamepad, and add it to the HUD control hints.
* **Sound**: a soft looping thruster while held, using `AudioManager`.
* It must not break spherical gravity, must not let the player leave the planet or get stuck off-surface, and must be disabled while any modal UI is open or during a cutscene.




## R2.11 — SMALLER STARTING PLANETS, with room to grow later. [PLANET BUILDER]

> *"it might be best to shrink the planet sizes down a bit so more fits on the screen. We can maybe make an upgrade later to make your planet bigger but for the start, planets can be smaller which will help get them in view as players familiarize themselves and dont have a lot of decor."*

**The reasoning is sound and it is a real fix, not just a mobile one.** With three starter decorations a 16 m planet reads as empty, and on a phone you see a slice of it. A smaller world puts more of the player's own decorating on screen at once, makes the horizon curve read as a *planet* rather than a hill, and shortens the walk between everything while they are still learning.

**Current radii**: home 16, zorp 13, bolt 13, hub 26.

**Constraints — this is not a free scale, and shrinking blindly will break things:**
* **Fixed-size things do not shrink with the planet.** The astronaut is 1.4 m, buildings are 5-8 m, `RESERVED_CLEARANCE` is 3.5 m and `PICKUP_REACH` 2.6 m. On a smaller sphere those occupy proportionally more of the surface, so **decoration placement budget drops fastest of all** — Zorp already had to be rescued from 20% placeable to 57%, and that was at radius 13. **Re-run the placement survey after any change** (`showcase/planet_survey.tscn`) and keep every planet comparable to home's ~70%.
* **The hub is the hard floor.** It carries four buildings of 5-8 m plus a plaza and five NPCs. It can come down, but far less proportionally than the others.
* Terrain amplitude, prop counts, crater and plateau sizes, spawn/pad separation and `HUB_BUILDING_DIRS` spacing are all tuned to the current radii and all need re-tuning.
* The sky bodies and the space-travel globes read each planet's radius; check both still look right.

**Ship the upgrade path now, even though the upgrade itself is later.** Home's radius must come from `GameState` rather than being a constant in the `.tres`, so a later "expand your planet" upgrade is a data change and not a rebuild:
* Add a persisted `GameState.home_planet_size` (an integer level, default 0) and a small table of radii.
* `world.gd` / `Planet` resolves home's radius from that level at load, falling back to the `.tres` value for the other worlds.
* The geometry cache key in `Planet` already includes the radius, so a size change invalidates it correctly — verify that.
* Everything that scales off radius must read it at runtime, not bake it.

**Judge it by looking, not only by arithmetic**: on a phone-sized viewport a player standing at spawn should see a satisfying amount of their own world, and a placed decoration must still be clearly legible (R2.10's limit).

## R2.10 — MOBILE. Landscape only, transparent touch controls. [UI + PLAYER BUILDERS]

> *"I want to make a mobile version of this game (but I want to make sure that it also works on computer well as well. So it has a computer version and mobile version UI for example)... I'd prefer to play the game in horizontal view, not have the UI taking too much space on the screen. We should zoom out the camera a bit more but not so much that we cant appreciate the decor and details."*
> *"go with landscape only, build the touch controls and mobile UI, but make them slightly transparent so that people can still appreciate the background."*

**LANDSCAPE ONLY, decided from a mockup.** Both orientations were rendered over a real game frame (`~/.astro_captures/cmp/mobile_orientation.png`). The world is a small sphere, and what makes it read as a planet is the horizon curving away on both sides — portrait cuts exactly that. In the portrait mock a lamp post and a bunting pole filled the frame and the plaza was gone entirely; the player cannot judge their own decorating. Landscape also puts the controls in the bottom corners over ground that carries no information. `Platform` locks `SCREEN_LANDSCAPE` on handhelds; desktop keeps its resizable window.

**One game, two front ends.** `Platform` (autoload) decides: `Platform.is_mobile()`, `Platform.is_desktop()`, `Platform.mode_changed(mobile)`, `Platform.safe_area_insets() -> Vector4`. Detection order is `--ui=mobile` / `--ui=desktop` on the command line, then `GameState.settings["ui_mode"]`, then auto. **Never test `OS.get_name()` directly** — a touchscreen laptop and a desktop build rendering the mobile layout for a screenshot both break that. Every mobile layout must be reviewable on a desktop machine with `--ui=mobile`, or the half nobody is sitting in front of will never get checked.

**Touch controls — transparent, and out of the way:**
* **Left thumbstick** for movement: a floating stick that appears where the thumb lands inside a generous bottom-left zone, rather than a fixed ring the player has to find. Analogue, so a small push walks and a full push runs (this replaces the Shift key — there is no run button).
* **Right action cluster**: one large primary button (context-sensitive — Talk / Enter / Place / Pick up / Fly, matching the interact prompt), with Jump and Boost as smaller satellites. Hold the boost button to fly, exactly as holding the key does.
* **Camera**: drag anywhere on the open right-hand side of the screen to orbit; pinch to zoom.
* **Transparency is a requirement, not a nicety.** Idle opacity around 0.35-0.5 for the stick and satellites, rising to roughly 0.85 while a control is actually being touched, and fading further down after a few seconds of no input. The background must stay appreciable through them. Panels that must be readable (the top bar, dialogue, shops) stay opaque — this rule is about the *controls*.
* **Touch targets at least 9 mm** (about 48 dp) with generous invisible padding; visual size can be smaller than the hit area.
* Respect `Platform.safe_area_insets()` — nothing under a notch or a home indicator.

**Mobile HUD must take less space than the desktop one:**
* The keyboard hint strip is **desktop-only**. It currently draws across the bottom of the mobile mock, which is exactly the "UI taking too much space" the user objected to.
* Stardust and clock shrink into the safe area at the top. Bag and journal become small buttons rather than key hints.
* Full-screen panels (bag, shop, journal, pause) get bigger touch targets and larger type, and must not need a mouse.
* Toasts and the interact prompt must not sit under the thumbs.

**Camera framing:**
* Pull the default back so the world reads on a small screen, **but not so far that decorations stop being appreciable** — that is the explicit limit. Mobile should sit further back than desktop; tune both by looking, and state the numbers.
* Desktop currently defaults to 6.5 m at 28 deg with a 4-10 m zoom range. Mobile wants more distance and probably a slightly higher pitch so the ground reads. Verify a placed decoration is still clearly legible at the chosen distance on a phone-sized viewport.

**Test at real phone sizes** — 2340x1080 and 2556x1179 landscape are representative — as well as at 1280x720 and 1920x1080 for desktop.

## R2.9 — SURFACE TEXTURE. No large flat untextured areas on important things. [ALL VISUAL BUILDERS]

> *"I want to minimize larger surfaces on important things that dont have a 'texture' to them, so that nothing looks too flat / cheap. Notably things like the astronaut's helmet/clothes or houses and the ground."*
> *"metal things should have a sheen, clothes might have a fabricy pattern/texture, wood will have a wood groove pattern/texture, rock should have a rougher texture, grass as plump softeness."*
> *"Non-important things like decor items and small pieces dont necessarily need this."*

**The rule.** Any surface that is **large on screen** and belongs to something the player looks at closely — the astronaut, the neighbours, the buildings, the ground, the rocket — must carry material character. A big untextured area reads as cheap regardless of how good the colour is.

**This does NOT undo R2.6 (pastel and matte).** They are different axes and it is important not to confuse them:
* **Matte** = no big blown specular blob, no wet plastic sheen across a whole panel. That still holds.
* **Texture** = fine surface character: weave, grain, roughness, a soft anisotropic sheen. Adds detail *without* adding a hotspot.
A metal panel can be matte and still have a soft directional sheen that shifts as you walk past. Fabric can be matte and still show a weave. Get the detail from **roughness, normal and subtle albedo variation**, not from raising specular strength.

**Per-material targets:**
| material | what it needs |
|---|---|
| **metal** (helmet hardware, rocket hull, Bolt's plates, robot shells, lamp posts) | a soft **anisotropic sheen** that travels as the view moves, fine brushed grain, slightly darker micro-scratches near edges. Not a mirror, not a hotspot. |
| **cloth / suit** (the astronaut's suit, NPC clothing, awnings, flags, bunting) | a fine **woven weave** at close range that fades out with distance, soft fibre roughness, and a gentle sheen only at grazing angles. Seams and stitching where panels meet. |
| **wood** (benches, signs, doors, fences, market stalls, tree trunks) | **directional grain** running along the plank, with knots and a subtle colour drift between boards. The grain direction must follow the geometry, not the world axes. |
| **rock / stone** (rocks, cliffs, plateau banks, plaza paving, meteorites) | a genuinely **rougher** microsurface, chipped edges, mottled tonal variation at two scales. Stone should never read as smooth plastic. |
| **grass / foliage** | **plump softness** — a soft, slightly translucent read with fine tuft/blade detail, not a hard flat dome. Leaves want a hint of subsurface warmth where the sun passes through. |
| **glass** (visor, windows, water) | keeps its gloss. This is the one place a real highlight belongs. |

**Scope. Do not gold-plate everything.** Spend the detail where the player looks:
* **Always**: the astronaut, the neighbours, the four planets' ground, the buildings, the rocket.
* **Usually**: anything over roughly a metre that the camera regularly gets close to.
* **Not needed**: small decoration items, distant props, background scatter. A moon lamp does not need a weave.

**How to build it.** Everything in this project is procedural, so this is shader work, not texture files: triplanar or object-space noise, derivative-based detail, and **distance fade** so the fine pattern never aliases or moires (see how the ground's `pc_detail_lod` solves exactly that — a fine pattern with no mip chain beats against the pixel grid and produces circular moire). Keep it cheap; the budget is 14 ms and we currently sit near 1 ms.

**It must not break the palette gates.** Re-measure after: whole-frame saturation p90 <= 0.68, saturation mean 0.36-0.48, ground-crop value mean 0.66-0.76, luma p05 0.30-0.42, range >= 0.50, blown < 5%.

**Shared implementation.** `src/shaders/surface_detail.gdshaderinc` provides the common functions and `MaterialLib` exposes them, so every builder gets the same vocabulary and one place to tune it. Use those rather than inventing a private version.

## R2.6 — PASTEL AND MATTE. The colours pop too much. [ALL VISUAL BUILDERS]

> *"The colors are popping too much but maybe we move to more pastel or matte colors to tone it down? The space scenes look good but on the planets in teh daytime its very strikingly bright especially greens whites and blues"*

Measured once, when this note was written, on a real home-planet daytime frame and on a reference frame (one of the retired screenshots — see the reference table below), and the user's read is exactly right. **The problem is not the average — it is the loud tail.** Our mean saturation (0.488) already sat on the reference frame's (0.477); what was wrong is that our most saturated colours were far more intense than anything in it. The reference column is that one-off historical measurement, kept so the targets make sense — do not re-measure against it. The TARGETS underneath are the rule.

| | OURS | reference frame (one-off, historical) | action |
|---|---|---|---|
| **saturation p90** (the loud tail) | **0.811** | 0.673 | **this is the headline number — get it to <= 0.68** |
| grass green | `#2d9c67` **S 0.71** | `#5eb972` S 0.49 | pull green saturation to ~0.45-0.52 |
| shadow green | `#0f6247` **S 0.84** | `#3d6e5b` S 0.44 | dark does not mean saturated - to ~0.45 |
| sky blue | `#48a5da` **S 0.67** | `#79bce2` S 0.46 | (largely resolved by R2.1's thin-atmosphere sky) |
| near-white | `#fbf5de` **V 0.99** | `#d8e4e6` V 0.90 | no near-clipping whites - cap ~0.92 |
| luma p95 | **0.968** | 0.921 | pull the top of the range down |

**TARGETS (these replace the earlier saturation numbers):**
* **saturation p90 <= 0.68** — the single most important gate for this note. Nothing in a gameplay frame should scream.
* saturation mean **0.36-0.48**, and **no dominant swatch above S 0.60**.
* value mean **0.66-0.76**; **luma p95 <= 0.93**; blown highlights **< 5%**.
* Greens, whites and blues are the named offenders. Check them by name every pass.

**HOW to get there (do not repeat the mud mistake):**
* **Desaturate toward the hue's own pastel, do not darken toward brown.** A pastel green is a *lighter, softer* green, not a muddy one. Reduce chroma while keeping hue; adjust value separately.
* **Go matte.** Cut specular and gloss on natural surfaces — grass, foliage, rock, cloth, painted metal. `MaterialLib.toon`'s `spec` should sit near 0.05 for anything organic, with rim kept low. Reserve real gloss for genuinely shiny things: the visor, water, polished chrome, glass. The toon fake specular that paints a white ellipse on flat top faces should go.
* **Saturated accents must be small.** A bright colour is fine as a lamp, a sign, a flower or a seam light — a few percent of the frame. It is not fine across a whole hillside, plaza or sky.
* Keep the identity of each planet: home stays green, Zorp stays violet, Bolt stays steel, the hub stays cream. Pastel means *softer*, never washed out or grey.
* The **space scenes are working — do not touch them.** The user called them out as good. This note is about planet daytime surfaces.

## R2.5 — The rocket flight is one continuous journey. [ROCKET BUILDER]
* No cut from "leaving" to "arriving". As the rocket climbs, **the home planet must visibly shrink below and behind you**, the sky must darken into space, and the **destination planet must grow ahead** as you approach it.
* The camera stays with the rocket through the whole trip so the trip reads as travel, not a scene change. If the map screen stays, it should feel like part of the same continuous move.
* Keep the destination arrival as the hero beat, framed on the lit face of the planet.

# Astro Neighbor — Visual & Feel Style Guide

The target is **Astro Neighbor's own look: soft, chunky, warm and alive, on tiny airless worlds under a space sky** — saturated but pastel (R2.6 caps the loud tail), structured rather than bubbly, cute rather than sugary. ARCHITECTURE §1 defines the quality bar in measured terms, and §1.1 lists what this game is *not*.

**Reference images (`reference/`) are not all targets.** Before you build, look at the ones this table marks for your kind of work, and know which kind each one is:

| file | what it is | use it for |
|---|---|---|
| `astronaut 1-3.jpeg` | astronaut suit references | **a target**: the suit, bubble helmet, neck ring, ear-pods and limb bands (R2.7) |
| `Alien References.webp` | a sheet of 18 cartoon aliens | the *range* of creature shapes — eye counts, stalks, horns, limbs — for the cast (CAST_VARIETY.md). Shape vocabulary, not a style to trace |
| `Menu and text reference 1-2.jpg` | menu concept screens from LittleBigPlanet Karting (per their captions) | UI layout ideas only |
| `AC Characters.png` (+ `.avif`), `AC Reference 2-6` | Animal Crossing: New Horizons screenshots | **Retired** (ARCHITECTURE §1.1). Not a target and not a ruler. The numbers in this guide are the rule |

## Shape language
* **Round everything.** No sharp boxes. Beveled/rounded edges, capsules, squashed spheres. If you use BoxMesh, wrap it in a rounded look (use CSG or SurfaceTool with bevels, or scale a SphereMesh/CapsuleMesh).
* **Chunky proportions.** Characters: head ≈ 45% of total height, big round helmet, tiny body, stubby limbs, oversized boots/gloves. Props: thick legs, fat silhouettes, exaggerated features (a lamp's bulb is huge, a sign's post is thick).
* **Tiny-planet scale.** Trees ~2.5–3.5 m, buildings 5–8 m, the planet curves visibly in every shot.
* **Readable silhouettes** at 1280×720 from the gameplay camera (6.5 m away, 28° elevation).


## Character rules — chibi cute (MANDATORY, user-mandated)
The user reviewed the first astronaut and asked for it to be much *cuter*. That still stands: chibi proportions and simple faces are this game's character look, and the user wants to keep them. What changed on 2026-09-10 is the yardstick — the original request compared the characters to Animal Crossing's, and ARCHITECTURE §1.1 retires that comparison. The numbers below are the yardstick now. Every character (player, every neighbour, shopkeepers) follows these rules. Critics grade cuteness first.
* **Chibi proportions** (height H ≈ 1.4 m): head/helmet ≈ 0.50 H tall and slightly wider than tall; **no neck**; torso = a short rounded bean ≈ 0.26 H; legs stubby ≈ 0.12 H; big round feet ≈ 0.10 H; arms short (hands reach the waist) ending in round mitten spheres ≈ 0.09 H. Silhouette reads like a plush toy; from the gameplay camera the head must look bigger than the body.
* **Simple flat face.** Measured rule (supersedes earlier estimates): eyes = two small vertical ovals (≈ 12% of head height tall, 8% wide), very dark (#2a2320 / navy), with **centres 28–35% of head width apart** (NOT 40% — that reads wall-eyed), placed at the vertical middle of the face (not high). One small white highlight dot upper-right per eye; blink = squash to a line; happy = closed "^ ^" arcs; surprised = round "O O". Tiny nose (dot/triangle). Mouth = a small curved line **16–25% of head width** (NOT 5% — that reads as a pinprick); talk = small round "o". Blush = two soft pink ovals (#ffb3c1, ~50% alpha) low on the cheeks, wider than tall. Optional thin eyebrow arcs for expression. NO giant glossy anime eyes, NO multiple big reflections in the eyes.
* **Colour-block the clothing.** A chibi character reads at distance because the outfit has 2–3 clear colour zones (e.g. a blue-and-white blocked shirt, solid blue trousers, white shoes). A near-white suit with only thin trim reads as a blank blob at gameplay distance — give every suit a real secondary colour zone (chest/sleeve panel or trousers), not just piping.
* **Inside an opaque helmet, disable shadow receive on the face/hair** so the face stays readable, and tint the visor by *multiplying* (absorption) rather than alpha-blending — alpha blending washes near-black eyes to steel blue.
* **Hair** = big chunky shapes with clear silhouette (bowl cut + bangs, side sweep, twin puffs, tuft), saturated colours. Not strands.
* **Astronaut helmet** = an opaque, rounded white shell (suit colour) slightly wider than tall, with one big round **front visor window** (≈ 65% of the front) of *lightly* tinted glass (alpha ≈ 0.22) so the whole face is clearly visible, a thin accent-colour rim ring around the window, and one large crisp diagonal white highlight streak on the glass. From behind it is a clean white dome (small accent panel OK). Never a fully transparent dark bubble.
* **Aliens/robots** follow the same eye/mouth/blush grammar (robots draw it on their screen as pixels), same chibi proportions, and the same rounded plush silhouette.
* **Motion**: idle breathing bob, blink every 3–5 s, head bob on walk, waddle; happy = hop with "^ ^" eyes; talk = mouth "o" pulsing.


## MEASURED art-direction targets (user-mandated — these are numbers, not opinions)

**The method: compare characters, background shapes, colour palettes and textures *individually*, with numbers, against the TARGETS below and R2.6.** It comes from the user's review of the first playable build, which found the planet lumpy, everything way too bright and oversaturated, and the shapes too bubbly. That same note also named another game as the thing to compare against; that part is **superseded** (2026-09-10, ARCHITECTURE §1.1). The original words, kept for the record only — *superseded as a target*: *"the planet feels lumpy... Everything looks way too bright and oversaturated. The shapes are all too bubbly."*

`tools/palette.py` measures any image or crop. The table records numbers measured once, when this section was written: the reference column on the retired screenshots, our column on our first build. The reference column is a one-off historical measurement that explains where the targets came from, not something to re-measure against. The TARGETS underneath are the rule:

| metric | reference frames (one-off, historical) | OUR first build | verdict |
|---|---|---|---|
| luma p05 (darkest 5%) | 0.32 – 0.45 | 0.56 | we have **no dark tones at all** |
| luma range (p95 − p05) | 0.52 – 0.60 | 0.36 – 0.39 | our range is ~40% too small |
| value (HSV V) mean | 0.74 | 0.88 | ~19% too bright |
| pixels with luma < 0.15 | 0.1 – 0.6 % | 0.0 % | nothing is ever dark |
| grass base colour | `#4ca84f` V0.66 / `#5eb972` V0.73 | `#a8e189` V0.89 | grass is 35% too bright |
| grass shadow colour | `#3d6e5b` V0.43 (24% of frame!) | absent | shadows do not exist |
| saturation mean | 0.48 | 0.38 (home) / **0.56 (zorp)** | violet planet is neon |

**TARGETS every scene must hit** (measure with `tools/palette.py`, day-time gameplay shot, HUD included):
* luma p05 **0.30 – 0.42**, luma range **≥ 0.50**, value mean **0.70 – 0.80**
* at least **15% of the frame** below luma 0.45 (that is shadowed grass, tree undersides, dark foliage)
* blown highlights (luma > 0.92) **under 8%**
* saturation mean **0.40 – 0.52** on every planet, including Zorp and Bolt. Zorp's grass must be a *muted* violet (target ≈ `#8a5fc4`, S≈0.52, V≈0.72) — never `#bb43f1` S0.72 V0.95.
* **Darken every base albedo by roughly 20–25%** from the first pass and let light, not albedo, create brightness.


### How to hit the palette targets WITHOUT ruining the art (learned the hard way)
The first attempt hit every number by **muddying the albedo** — the hub plaza turned chocolate brown, Bolt's chrome turned beige with random red/green tiles, and tree canopies grew dark blotches that read as mould. Numbers in band, art ruined. Do not repeat this.
* **Darkness must come from LIGHT and SHADOW, not from brown albedo.** Keep base colours clean and cheerful; get luma p05 down with real cast shadows, a darker shade-side ramp, ambient occlusion, limb/distance darkening and darker *undersides*. A surface in shadow should look like the same happy colour in shade, never like dirt.
* **Never introduce mud.** If a swatch's hue drifts toward brown/grey while you are darkening it, you are doing it wrong — reduce value and keep the hue and a decent chroma instead.
* **Variation must be tasteful and low-contrast.** Panel/tile variety means a few percent of value difference or a subtle hue shift, NOT saturated red and green tiles scattered on a chrome planet, and NOT random dark patches on a leaf canopy. Random high-contrast speckle reads as damage or noise.
* **Keep each planet's identity**: the hub is a bright, welcoming cream-and-green plaza; Bolt is COOL blue-grey chrome with warm orange seam lights; Zorp is muted violet; home is fresh green. Meeting a metric is never a reason to change what a place *is*.

## Shape language corrections — "not bubbly"

Our shapes are **rounded but structured**: they have flat planes, clear edges and tiered silhouettes. They are NOT clusters of soap bubbles. "Structured", in words: a **flat base** that sits on the ground, a **tiered** or stepped silhouette instead of one blob, **crisp edges** where one surface meets the next, **chamfers** and panel lines alongside the curves, and a darker flat underside (R2.3 "Shape"). Our own shipped props show it; study them. In `src/planet/props/planet_prop_meshes.gd`: `puff_tree` (2-3 slightly flattened canopy tiers with scalloped rims, a crisp rim edge and a dark flat underside), `mushroom_tree` (a wide flattened cap with a dark gilled underside), `topiary` (clipped tiers with dark undersides), `pebble_rock` (flat-shaded faceted domes with clear ground contact, deliberately not spheres) and `chalk_core` (a squat faceted plug with a chamfered top and bottom and a recessed band). `showcase/planet_canopy.tscn` orbits a home-planet tree and `showcase/planet_rock.tscn` a home-planet rock, both under gameplay lighting.
* **Trees**: a distinct canopy silhouette — a broad, slightly flattened dome or a stack of 2–3 tiers with a visible flat-ish underside and a crisp outline, a darker underside colour, and a straight tapering trunk. NOT 4–5 overlapping equal spheres. Pine/conifer types have clear stacked cones.
* **Clouds**: soft **flat** puffs with a defined silhouette and a flat base, drifting as a layer. NOT grape-clusters of intersecting spheres (our first build's clouds read as bunches of balls, which is the single most "bubbly" element on screen).
* **Bushes/rocks**: flattened domes with a clear ground contact and a slightly faceted top, not perfect spheres.
* **Terrain**: the ground is **mostly flat, walkable and calm**, with occasional *distinct* raised areas and crisp edges — not continuous rolling lumps. On our tiny planets, keep large calm flat regions (the horizon should read as a clean arc), reduce hill amplitude sharply, and make any elevation change a deliberate readable landform (a plateau, a crater rim, a shoreline) instead of noise. **The horizon silhouette must be a smooth arc, not a wobbly lumpy line.**
* Keep the chunky/rounded charm, but every object needs a **readable silhouette with structure**, not a blob.

## Texture / surface corrections
Surfaces carry a subtle *painted* texture: the grass has small scattered triangle tufts (already good in our build) plus gentle large-scale colour variation and a slightly darker, cooler tone in the distance. Add gentle large-scale value variation (not more noise) and keep the distant ground slightly darker/cooler so the planet reads as a form.

## Color
Saturated pastels with warm light. Never grey defaults. Palette anchors:
| Use | Hex |
|---|---|
| Meadow grass A / B (triangle pattern) | `#7ed957` / `#5cc44a` |
| Sand / path | `#efe0b5` |
| Sky day top / horizon | `#4fa8ff` / `#bfe6ff` |
| Sunset | `#ff9a76` → `#ffd1a1` → `#6a5bc9` |
| Night sky top / horizon | `#0b1040` / `#26307a` |
| Violet planet grass A/B | `#a56cff` / `#8a4fe8`, rivers `#3ec6ff` glowing |
| Chrome planet plates | `#8fa3bf` / `#6f819c`, accent lights `#ff8a3d`, oil `#1c1f2b` |
| Hub tiles | `#f6efe2` / `#e9dcc3`, lawn `#8fe07a` |
| Astronaut suit / accent | `#f4f4f8` / `#ff7a59`, visor `#6fc3ff` |
| Zorp (alien) skin | `#b28dff`, eyes `#1a1233`, antenna bulb `#7fffd4` glow |
| Bolt (robot) shell | `#7fd8d0`, accents `#ff9f43`, screen `#1a2333` with `#7cf` pixels |
| UI — **Moonstone** (shipped; `src/ui/theme/ui_style.gd` is the source of truth) | panel `#e9eaf1`, panel edge `#9295ac`, item card `#eef0f6`, body text dark slate `#2c2f42`, soft text `#6d7288`, name tag `#4c5b8c`, the ONE accent amber `#f0a64a`; stardust stays gold `#ffe27a`. Font **Baloo 2** (bundled; the committed theme does not load it yet — see ARCHITECTURE §6). It replaced the old cream box (`#fff8e1`, brown text `#6b5232`, name tag `#4c6fff`, yellow `#ffcc33`), which read as a lift of another game; cool grey is the one hue that cannot clash with any planet, so one palette covers every world |
| Stardust | `#ffe27a` with `#fff6c8` sparkle |

Lighting: warm sun (`#fff4d6`), cool tinted shadows (toon shader shade_tint lavender). Soft shadows on. Subtle bloom (glow strength ~0.6, threshold ~1.0) so emissives glow, ACES tonemap, slight vignette, SSAO light. Depth of field: mild, far only.

## Materials
Use `MaterialLib.toon(color)` for nearly everything. Emissive via `MaterialLib.glow`. Visors/windows: `MaterialLib.glass`. Metal: `MaterialLib.metal`. Ground uses dedicated shaders (grass triangle pattern — small triangles in two greens, triplanar on the sphere, with subtle noise variation and a lighter ring near paths/water). Water: animated, two-tone with foam ring at the shoreline and sparkle highlights.

## Motion & feel (this is where "AAA" lives)
* Every interaction has **anticipation + follow-through**: jump squashes before takeoff and stretches in the air; landing squashes + dust puff; picking up an item does a little hop + sparkle + "pop" sound + toast.
* Idle life: breathing bob (2 s cycle, 2% scale), blink every 3–5 s, occasional head tilt; NPCs look at the player when within 5 m.
* Walk: 4-frame-feel waddle — body bob, arm swing, slight lean into turns; run: bigger lean, faster bob, small dust trail.
* Camera: smooth-damped follow (position lerp ~8/s, rotation ~6/s), gentle push-in during dialogue, never snaps.
* UI: panels pop in with a 0.25 s back-ease scale from 0.9→1, buttons scale 1.05 on focus with a soft "tick" sound, dialogue text typewriter 40 chars/s, name tag bounces in. The voice is NOT tied to the typewriter — see "Sound identity".
* Transitions: fade to deep navy; rocket liftoff shakes camera; landing has a bounce.
* Particles: stardust sparkle (small yellow quads, additive), tree shake leaves, dust puffs, rocket smoke (soft grey puffs) + flame (additive orange/blue), fireflies at night, shooting stars.

## Sound (AUDIO BUILDER)
Warm, soft, spacious pluck/pad music; short bright SFX. Music per world, looping seamlessly: `meadow_day` / `meadow_night` (home), `violet` (Zorp), `chrome` (Bolt), `hub`, `dust` (Fen), `chalk` (Grig), `frost` (Vela), `space` (rocket), `event` (event space), `title`. Dialogue voice and the start of the game follow "Sound identity" below. Two parts of the old spec here are retired: the per-profile voice blips (alien = warbly high, robot = square-wave bleeps, astro = soft "mm", elder = low slow, kid = high fast), and marimba as a named lead ("Sound identity" rule 6). Pads and plucks stay; rule 6 rules out a plucked *ukulele*, not a pluck.

### Sound identity (decided 2026-09-10, revised the same day and again 2026-09-11 after the user listened — binding on all new audio work)
The user named the voices and the start jingle as two of the things that make the game read as an Animal Crossing rip-off (ARCHITECTURE §1.1). Both were replaced 2026-09-10 with a first pass (a per-neighbour comms voice cast, a new title track "sonar"). She then listened on her phone and cut it back twice. 2026-09-10: keep Zorp's comms voice but drop the other nine for one shared, neutral "doot", and go back to the ORIGINAL title track. 2026-09-11, after hearing the three doot flavours: *"I like the third doot voice and let's have all neighbors have that voice too"* — so Zorp's voice goes off too, and flavour C ships for every speaker. These rules keep later audio work from drifting back to what she rejected — per-letter/animalese babble, and a bouncy mallet/whistle jingle that ISN'T the original.

**Voice: one shared, neutral doot for every speaker — Zorp's comms channel is one const away.**
1. **No speech-like pitched syllable babble ("animalese").** No voice sound is built from vowel-formant filters or a pitched syllable contour meant to read as talking, for anyone but Zorp. This is the rule the old per-letter blip (13-16 a second, animalese) broke, and it is also why the doot below is a plain non-vocal tone, not a quieter animalese.
2. **Zorp doots too — one voice for everyone (decided 2026-09-11, after the user listened to the three doot flavours).** *"I like the third doot voice and let's have all neighbors have that voice too."* So his comms channel is OFF: `AudioManager.ZORP_COMMS_ENABLED := false` sends him down the same doot path as everyone else, with no framing. Nothing is deleted — his scheduler (`voices.py` `v_zorp`, `AudioManager.comms_open_line`/`comms_reveal`/`comms_close_line`/`comms_hold`), his five `voice_zorp_*.wav` and the shared key-up/key-down/over/bed files all stay — so flipping that one const brings his transmission voice back. Measured live by the critic on 2026-09-11: with it true he plays key-up → gesture → key-down again and every other speaker keeps dooting.
3. **Every speaker: one shared, neutral "doot", flavour C, no framing.** The rule started 2026-09-10 with the user's *"generic doot doot doot noises as the letters are being written out and then we dont have unique voices for each"*, and on 2026-09-11 she picked flavour C by ear and extended it to Zorp as well. So EVERY speaker — all ten neighbours, Professor Comet's radio intro, hub/shop greetings — plays ONE shared tone as its letters type, at most once every 2 revealed letters (spaces and punctuation never trigger one), with NO key-up/key-down/static framing (`AudioManager.DOOT_FRAMING_ENABLED` — one const, default off, switchable if a later round wants framing back). The doot is deliberately non-vocal: no formants, no vowel colour, no per-neighbour timbre — `tools/gen/audio/voices.py` `render_doot("c", ...)` / `doot_variants()`, flavour C being a very short muted "tik-doo" (a soft filtered click attack into a short tone), with 4 pre-baked pitch variants (±3%) shipped as `doot_c_0..3.wav` so playback can rotate and avoid repeating the same sample. Measured 2026-09-11: -20.0 dBFS RMS and -20.717 LUFS, within 0.035 dB of the flavour A files it replaces (-20.681 LUFS), so `AudioManager.DOOT_DB` stays at -9.0 — no fitted gain. Flavours A and B stay as generator code, and `doot_a_0..3.wav` stay on disk, unused.
4. **The unused comms voices are kept as code, not shipped.** `tools/gen/audio/voices.py` still has a full, distinct-timbre generator per neighbour (`v_bolt` … `v_vela`, each labelled `# not shipped - the user kept only Zorp's comms voice, 2026-09-10`) and the "no two neighbours share a timbre" design behind them, so the cast can come back if a later round wants unique voices again. Their WAV files are deleted from `assets/audio/sfx/`. Zorp's own comms set (`voice_zorp_*`, `comms_key_up/down`, `comms_over`, `comms_bed`) is the exception: those files STAY on disk, unused, so `ZORP_COMMS_ENABLED` can bring his voice back in one line (rule 2). The 25 legacy `voice_{alien,astro,elder,kid,robot}_{0..4}.wav` files also stay on disk because `showcase/audio_board.gd` still hardcodes and preflight-checks them — note its `play_voice_blip("alien")` now plays a doot, since "alien" resolves to zorp.

**The start of the game: the original track, kept on purpose.**
5. **Take A "sonar" was tried and rejected.** A first pass replaced the title with a short signal-style sonic logo (three pings, Eb major, 64 bpm, no percussion) handing off to a spacious looping bed — a genuinely different idiom from the old bouncy mallet start. The user listened and said: *"For the music - I still like the Old music so lets go with that."* So `assets/audio/music/title.wav` is the ORIGINAL track again — `track_title_legacy` in `tools/gen/audio/music.py`, selected via `TITLE_VARIANT = "legacy"` in the `TITLE_VARIANTS` dict, byte-identical to the last committed `title.wav`, looping from sample 0 (no separate loop-in intro). Takes A "sonar" (`track_title_sonar`), B "radio" (`track_title_radio`) and C "orbit" (`track_title_orbit`) all still exist as generator functions, each labelled `# rejected by the user 2026-09-10 after listening; not shipped`.
6. **The original title's mallet/whistle sound is NOT something to remove.** It is part of the track the user chose to keep. Do not lead OTHER new audio with bouncy mallets, plucked ukulele or a whistled tune — that rule still applies everywhere else. Honest status, read from the code on 2026-09-10:
   * **Music** (`tools/gen/audio/music.py`): marimba in `meadow_day`, `hub` and `dust`; vibraphone in `meadow_day`, `hub` and `chalk`; glockenspiel in `meadow_night`, `hub` and `space`; the title's own mallet/whistle idiom (kept, see above).
   * **SFX jingles** (`tools/gen/audio/sfx.py`): `quest_accept` (a three-note marimba arpeggio plus a bell) and `quest_complete` (a five-note marimba arpeggio plus a bell, a vibraphone chord and a glockenspiel run), fired from `favor_system.gd:241` and `:310`, `town_hall.gd:376` and `player_home.gd:264` (ARCHITECTURE §1.1). Shorter mallet SFX too: `ui_confirm` and `ui_cancel` (two marimba notes each), `collect_stardust` and `shooting_star` (glockenspiel).

   Whether the planet tracks are re-scored, or the SFX jingles replaced, is **not decided**. Do not add more.

**Verifying it.** No agent can hear. Verify what you can measure: render spectrograms with `tools/gen/audio/viz.py` and look at them; measure duration, peak, RMS, spectral centroid and bandwidth with numpy; read the code path that triggers each sound; and count in-engine how many sound events fire per line of dialogue, reported next to that line's character count, so a per-letter pattern cannot hide. Whether it *sounds good* is the user's call, which is why audio work ships with listening demos for them to judge.

## Writing
Warm and playful, short lines (≤ 60 chars per line, max 3 lines per box). NPCs have distinct voices: Zorp = enthusiastic and curious about Earth things ("Do you also photosynthesize?"), Bolt = literal, kind, counts things, loves gears, Mayor Orbit = grandfatherly robot, Pip & Pop = finishing each other's sentences, Stella = fashion-forward, DJ Nova = hype.

## Non-negotiables (critics will fail you)
* No default white/grey materials, no placeholder cubes, no "TODO" visuals, no z-fighting, no floating props, no clipping into terrain.
* Nothing flat-shaded unless it's a stylistic facet on a crystal.
* Text never overflows; UI works at 1280×720 and 1920×1080 windows.
* No console errors or warnings.
