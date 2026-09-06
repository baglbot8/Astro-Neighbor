# Open cross-domain issues (orchestrator-maintained)

Issues that span builder boundaries. The owning builder fixes them; everyone else should read this before blaming their own code.

## 1. [RESOLVED 2026-09-05] Soft-shadow penumbra dithering — was OWNER: environment builder
**Reported independently by two builders and one critic.**
* The astronaut critic measured a regular "golf-ball" stipple crawling across the helmet dome, with luma sigma inside a flat patch swinging 0.0035 -> 0.0124 between consecutive walking frames while the grass beside it stayed clean.
* The character builder disabled head shadow *casting* on every NPC as a workaround, saying "the environment's soft-shadow penumbra dithered badly across the chest at close range - visible on the player too". That workaround costs every character its head shadow, which is itself a visual defect.

**Now measured precisely by the NPC critic.** High-frequency luma energy (deviation from a 3x3 blur) at noon:

| surface | HF rms |
|---|---|
| player helmet | 0.0687 (p99 0.249, max delta 0.548) |
| NPC shirt (still casting) | 0.0211 |
| NPC head (casting disabled) | 0.0064 |
| same head in a shadowless showcase | 0.0023 |
| ACNH Rosie's head (JPEG reference) | 0.0175 |

The artefact is a static dot grid on smooth toon surfaces (helmet, visor, shirt, tree canopies). Current settings: `environment.gd:404-406` `shadow_bias 0.04`, `shadow_normal_bias 1.8` (very high, also causes peter-panning), `shadow_blur 1.3`, `directional_shadow_max_distance 42`; `project.godot:200 soft_shadow_filter_quality=3`; MSAA 4x; no TAA.
**ROOT CAUSE FOUND AND FIXED.** It was not bias tuning. `light_angular_distance = 1.6` on the sun switched Godot's directional shadow to the PCSS sampler, whose blocker search runs over a disk rotated by `quick_hash(gl_FragCoord.xy)` and returns "fully lit" whenever that disk misses every blocker. On a large smooth surface crossing the terminator that is a per-pixel coin flip, painting a full-amplitude dot grid locked to screen space that crawls as the surface moves. Setting `light_angular_distance = 0` removes the blocker search; `shadow_blur` then gives a uniform penumbra, which is the ACNH look anyway and costs one PCF loop instead of two.
Final settings (`src/world/environment.gd` sun and moon): `light_angular_distance` 0, `directional_shadow_max_distance` 25, `shadow_bias` 0.03, `shadow_normal_bias` 1.0, `shadow_blur` 0.7; `project.godot` `soft_shadow_filter_quality` 4. MSAA unchanged, TAA not needed.
Helmet HF rms at dusk went 0.0383 -> 0.0053 (ACNH reference measures 0.0196-0.0241 with the same tool, `tools/hf_noise.py`). Cast shadows got *better*: shadowed grass 41.3% -> 48.2% darker than lit. No perf cost.

**ACTION REMAINING — both cast-shadow cheats can and should now be reverted** (proved at runtime by flipping them live, without editing either builder's files):
* PLAYER BUILDER: `src/player/astronaut_model.gd:841` sets the helmet `Shell` to `cast_shadow = OFF`. Restored, the shell measures 0.0068-0.0199 HF and is visually spotless. Reverting also fixes a thin detached dark arc the window Rim currently casts on the ground.
* CHARACTER BUILDER: `ChibiModel.head_shadow_cheat` disables casting on the entire head subtree, so ~half of every neighbour's ground shadow is missing and they read as stickers. With the fix, head HF is within +/-0.003 of control. (`ChibiModel._disable_head_self_shadow()` disables shadow casting on the *entire head subtree*, so ~half of every neighbour's ground shadow is missing and they read as stickers).

## 2. `--new-game` must come BEFORE `--planet` on the command line — OWNER: orchestrator (documented, low priority)
`GameState.reset_new_game()` resets `current_planet_id` to "home", so `--planet=zorp --new-game` silently loads home. Every command in the docs now uses the correct order. A more robust fix would be to apply `--planet` after all other Director args in `src/autoload/director.gd`.

## 3. `ERROR: 1 resources still in use at exit` in `--write-movie` captures — OWNER: audio builder (cosmetic)
Appears in any movie-mode capture where audio is playing, including timelines that predate the audio system. The AudioServer still holds a playback when the movie writer quits. Cosmetic; does not affect `tools/check.sh` or normal runs.

## 4. Stella inherits the astronaut's triangle count (24,684 tris) — OWNER: player builder
The character budget is 6k. ~24k comes from `AstronautModel` itself. If the astronaut gets a poly pass, Stella benefits for free.

## 5. `astro_night` cannot be READ from GDScript at runtime — OWNER: everyone (workaround documented)
`RenderingServer.global_shader_parameter_get()` is **editor-only** in Godot 4.7 and pushes `ERROR: This function should never be used outside the editor` on every call. The global still works perfectly *inside shaders*.
* **In a shader**: declare `global uniform float astro_night;` and use it directly. This is the preferred path for anything emissive.
* **In GDScript**: do NOT try to read the global. Derive the night factor from `GameState.time_of_day` (the same clock that drives it) and/or listen to `EventBus.day_phase_changed`. `ProjectSettings.has_setting("shader_globals/astro_night")` can be used to detect that the global exists.

## 6. Decoration emissives still blow out to shapeless white at night — OWNER: decoration builder (verify against the real environment)
The night gallery capture shows lamps, the star projector, the beacon and the supply-crate window rendering as featureless white blobs with large halos. The environment builder added a hue-preserving `emission_cap` and the `astro_night` global to `toon_soft.gdshader`, but decorations use their own `deco_glow.gdshader`, which must adopt the same cap and night scaling (see issue 5 for how to read the global). **Judge this in the real game with the real environment, not in the standalone gallery showcase**, whose lighting is not representative.

## 7. [FIXED 2026-09-05 by orchestrator] Emote soft-lock in player.gd
`Player.play_emote()` set `_emote` and relied entirely on the model's `emote_finished` signal to clear it. That signal only fires while the model is still in the emote state, so anything that overwrote the model state in the same frame killed it — the known case is the landing handler setting `"land"`, which is not in `AstronautModel.EMOTE_DURATIONS`. `_emote` then stayed set forever and `_physics_process` refused **every** `interact` for the rest of the session. Found by the rocket critic, who worked around it by deleting a `play_emote("happy")` call.
**Fix**: `player.gd` now stores `_emote_deadline` when an emote starts and force-clears it in `_physics_process` past `duration + EMOTE_GRACE`, with a warning. Regression test: `tests/emote_probe.tscn` reproduces the exact collision and exits non-zero if `_emote` is still set after 8 s.
The rocket builder may restore its `play_emote("happy")` on arrival.

## 8. [FIXED 2026-09-05 by orchestrator] Arrival banner covered the descending rocket
The HUD banner is anchored centre-top and holds ~3.5 s, exactly where and when the rocket flies its landing descent. `rocket_pad.gd` sets `GameState.set_flag("rocket_arriving", true)` in `_prepare_arrival` and clears it at touchdown and on every exit path; `hud.gd::_on_planet_loaded` now reads that flag and parks the banner small in the top-left corner while it is set, so the landing stays the hero shot.

## 9. [DONE 2026-09-05 by orchestrator] Journal hotkey
The favours journal was reachable only through pause -> Favours. Added a `journal` action to `project.godot` (**J** on keyboard, D-pad down on gamepad) and `src/onboarding/journal_hotkey.gd`, wired into `src/onboarding/onboarding.tscn`. It polls `Input` rather than using `_unhandled_input`, because the Director drives tests with `Input.action_press()`, which sets the action state but emits no `InputEvent` — an event-based handler is invisible to every test timeline. Verified with `tests/director/journal_hotkey.json`.
**UI BUILDER: please add `["journal", "journal"]` to the HUD control-hints strip** so players can discover it.

## 10. PENDING HANDOVER — rocket pad hint should go through HintChannel — OWNER: rocket builder
The rocket's "Follow the arrows to the rocket pad" toast fires up to 3x per planet visit, 20 s apart, and lands over conversations (the integration critic caught it firing directly over the mayor's opening line). The onboarding builder shipped a well-mannered hint channel: shown once ever, persisted in `GameState.flags`, never during a dialogue/shop/bag/pause/cutscene or a scene fade, minimum 3.6 s between hints. Replace the body of `_update_hint()` in `src/rocket/rocket_pad.gd` with:
```gdscript
func _update_hint(_delta: float) -> void:
	if _cutscene or _busy or _found or _player_distance() < FOUND_RANGE:
		HintChannel.mark_acted("rocket_pad")
		return
	HintChannel.request("rocket_pad", "Follow the arrows to the rocket pad — press E to fly!",
		"star", HINT_DELAY)
```
Then delete `_hints_left`, `_hint_timer`, `HINT_REPEAT`, `HINT_MAX` and the `rocket_hint_seen` flag. The onboarding side already calls `HintChannel.mark_acted("rocket_pad")` when the player boards. (Deferred because the rocket builder was mid-run.)

## 11. PENDING — Town Hall bulletin board should open the journal — OWNER: hub builder
`JournalPanel.open_over(town_hall)` is ready and the panel hosts itself under `World/HUD`, so a `Node3D` caller works. One line on the existing bulletin-board Interactable gives the journal a second, diegetic home.

## 12. [DONE 2026-09-05 by orchestrator] Save file turned every integer into a float
`SaveManager` round-trips through JSON, which has no integer type, so a reloaded inventory read `{"deco_moon_lamp": 2.0}` and the same applied to counts nested inside `favors` and `npcs`. Every consumer cast with `int()`, which hid it, but the dictionaries stayed dirty and anything that compared or stringified a count saw "2.0".
`src/autoload/game_state.gd` now coerces on load: `_ints()` for the flat inventory and `_deep_ints()` for the nested dictionaries (whole floats only — genuine fractions are left alone). Regression test: `tests/save_int_probe.tscn`, prints `SAVEINT PASS` and exits non-zero on failure.

## 13. [DONE 2026-09-05 by orchestrator] PlacementController.blocked_reason()
The HUD now shows the player *why* a placement spot is refused, but it was reading `_dir` / `_footprint` off the controller via `Object.get()` as a fallback. Added the proper accessor `PlacementController.blocked_reason() -> String`, which calls the same `DecorationManager.spot_block_reason()` query the ghost's red tint uses, so the pill and the tint cannot disagree.

## 14. [DONE 2026-09-05 by orchestrator] HUD control hints
`boost` shares the jump key and was labelled "boost" next to "jump" — two verbs on one key with no explanation. Now reads "hold to fly". Also added `journal` / "favours" so the new J hotkey is discoverable.

## 15. [DONE 2026-09-05 by orchestrator] Sky bodies: ring radii and the hub's colour
Two handovers from the planet and rocket builders, both in `src/world/sky_bodies.gd`:
* **Ring radii** were 1.32x / 2.05x the body radius while the real `PlanetRing` on Bolt is 28 m / 39 m on a 13 m planet = **2.15x / 3.00x**. The ringed world in the sky did not match the one you land on, and it left a visible delta at the rocket journey's departure cut. Now driven by `RING_INNER_SCALE` / `RING_OUTER_SCALE` consts set to the real ratio.
* **The hub rendered green-and-tan in the sky** while being a cream plaza on the ground, because `_apply_biome` sampled `ground_color_a` (the lawn) and the plaza paving is set on the material and never reaches `PlanetData`. The planet builder added `PlanetData.surface_color` carrying each planet's dominant visible tone; `land_a` now prefers it.

## 16. [DONE 2026-09-05 by orchestrator] Environment hooks for the rocket journey
Added two of the three the rocket builder asked for:
* `Environment.get_sky_body_direction(id) -> Vector3` (backed by new `SkyBodies.direction_of`) so the launch climb aims at the world the player can actually see, instead of looking up `SkyBodies/Sky_<id>` by node name.
* `Environment.refresh()` — forces a full re-apply for the current hour, so the arrival half of a journey is settled before its first frame instead of calling `_process(0.0)`.
Not added: `sun_direction_for(planet_id, hour)`. The rocket duplicates the sun-arc constants to predict a destination's terminator before that planet exists; that is a real duplication but the arc lives inside `environment.gd`'s per-frame state, and pulling it out cleanly is a bigger change than this pass warranted. Left documented on both sides.

## 17. OPEN — sunlit foliage cannot reach its authored saturation — OWNER: environment builder
The planet builder isolated this with debug renders and proved it is not theirs: a 22% crown-albedo cut, a 1.6x light-gain change and a chroma boost from S 0.42 to S 0.69 each moved the **rendered** crown saturation by <= 0.03. The cause is ACES (white 6) plus the colour grade — the RRT matrix mixes ~35% of green into red, so a saturated green desaturates hard at high value. Canopy crowns measure `#95b48d` S 0.22-0.29 where the reference sits nearer S 0.40. If the last of that saturation is wanted on sunlit foliage it needs the tonemapper or the grade, both of which the environment owns.

## 18. [DONE 2026-09-06 by orchestrator] Shared surface-detail library for R2.9
The user asked that large surfaces on important things carry material character ("metal things should have a sheen, clothes might have a fabricy pattern... wood will have a wood groove pattern... rock should have a rougher texture, grass as plump softeness"). Rather than have six builders each invent a private version, the vocabulary is centralised:
* **`src/shaders/surface_detail.gdshaderinc`** — `sd_cloth`, `sd_metal`, `sd_wood`, `sd_rock`, `sd_foliage`, plus `sd_sheen` / `sd_cloth_sheen` and, critically, **`sd_lod()`**, which every fine pattern must be multiplied by. A high-frequency pattern with no mip chain beats against the pixel grid and produces the circular moire that already had to be fixed once on the planet ground; the fade is not optional.
* **`toon_soft.gdshader`** exposes `surface_kind` (0 none / 1 cloth / 2 metal / 3 wood / 4 rock / 5 foliage), `surface_strength`, `surface_lod_near`, `surface_lod_far`, `surface_grain_dir`, and applies the sheen in `light()`. Detail is model-space (a `v_objpos` varying), so a pattern does not swim across a character as they walk. **Off by default** — nothing changes until a material opts in.
* **`MaterialLib.toon()`** takes `{"surface": "cloth"|"metal"|"wood"|"rock"|"foliage"}` plus optional `surface_strength`, `surface_near`, `surface_far`, `grain_dir`. **`MaterialLib.metal()` opts in automatically**; pass `{"surface": "none"}` to decline.
Tuned against a proof sheet (`~/.astro_captures/cmp/r29_surface_proof.png`, `showcase/surface_detail.tscn`): the metal sheen was lifting a mid-blue plate to pale blue, which is the "wet plastic across a whole panel" R2.6 forbids, so `aniso` came down from 0.55 to 0.20 and the grain carries the read instead; wood's board hash was quantised on both axes and drew visible rectangles, now keyed off the across-grain axis only.
**BUILDERS: adopt this rather than writing your own.** Scope it per R2.9 — the astronaut, the neighbours, the ground, buildings and the rocket always; small decoration items and background scatter never.

## 19. THE ALBEDO IS APPLIED TWICE — the root cause of the whole saturation problem. HIGHEST PRIORITY.
**Godot 4.7 multiplies `DIFFUSE_LIGHT` by `ALBEDO` *after* `light()` returns.** Every toon `light()` in this project composes the *finished* surface colour and hands it to `DIFFUSE_LIGHT`, so the albedo lands twice. Found by the planet builder; **independently reproduced by the orchestrator**: a shader writing a constant `DIFFUSE_LIGHT = vec3(0.20)` with `ALBEDO = (1.0, 0.5, 0.25)` renders **orange (143,103,74)**, not neutral grey.

Squaring is invisible on a neutral surface and catastrophic on a chromatic one, and it is **worst in shadow**, where albedo is already low. A leaf green of linear `(0.074, 0.342, 0.223)` becomes `(0.005, 0.117, 0.050)` — saturation 0.78 -> **0.95**, red crushed to 1/255. That is exactly the `#065f33` S 0.94 a critic measured on the first bush in the game.

**This is the root cause of the user's standing "the colors are popping too much" note.** Every pastel pass so far has been re-authoring albedos to compensate for a renderer bug.

**Status by shader** (`pc_light_term` / `pc_albedo_floor` in `planet_common.gdshaderinc` is the correct helper):
* FIXED: `crystal.gdshader`, `planet_foliage.gdshader`
* NOT FIXED: `toon_soft.gdshader` (every prop, character and building), `grass_planet`, `plaza_tiles`, `metal_plates`, `water`, `planet_glow_pulse`, `globe`, `hub_glow`, `astro_visor`, `astro_shell`, `flag_wave`, `deco_glow`

**Why it is not simply fixed yet.** The orchestrator applied it to `toon_soft` and measured: hub saturation p90 0.532 -> 0.442, which is the right direction — but **every colour in the game was authored against the doubled behaviour**, so the fix alone leaves surfaces washed out and hue-shifted. In a hub before/after the wooden bench lost its brown entirely and the flower-bed soil went from rich earth to pale grey. A central chroma-restore compensation was tried and rejected: it recovered the numbers but drifted the whole frame yellow. **The change was reverted rather than ship a visible regression.**

**How this must be done:** one dedicated pass that fixes the divide **and** re-authors the palette together, per material, with measurement — not shader-by-shader and not albedo-blind. Expect every base colour to need more chroma than it has now, because the artists were unknowingly relying on the squaring. The prize is large: the correct pipeline makes shadows behave, which is the thing the last four tone passes were all fighting.

## 20. [DONE 2026-09-06 by orchestrator] Surface-detail library, second pass
The astronaut builder adopted the shared library (`src/shaders/surface_detail.gdshaderinc`) and reported seven issues from real use. Six are fixed centrally so nobody has to work around them again:
1. **The metal sheen popped.** `s.aniso` was not multiplied by `lod` while the function early-returns at the fade edge, so it held at full amplitude then snapped to zero — a pop on any part crossing that distance and a visible ring on a surface spanning it. Now faded in with `smoothstep(0.0, 0.25, lod)`.
2. **`sd_metal` was being handed a view-space normal.** It picks its brush axis from the normal it is given, so the axis re-picked as the camera orbited and the grain flipped in patches and crawled. `toon_soft` now passes a model-space `v_objnorm` varying, and the function documents the requirement.
3. **`ROUGHNESS` was near a no-op.** The toon `light()` computes its own specular from `spec_size`/`spec_strength` and never read `ROUGHNESS`, so the `rough` half of every `sd_*` result did nothing (a rock spent 0.38 of roughness budget against only 0.135 of tint). The toon lobe is now widened by `ROUGHNESS`.
4. **Added `sd_rubber`** (kind 6) for boots, gloves, hoses and mats. `sd_rock` was tried first and is authored for cliffs — at 6.5 and 46 cycles/m it gives only 1.5 and 11 cycles across a 0.24 m boot, moving the albedo under 3%.
5. **Added `sd_seams`**, generalised from the astronaut's local implementation: ring and gore seams with a topstitch bead, creased along the part's own axes. R2.9's cloth row asks for seams and `sd_cloth` had none. **The half-period gore phase default is deliberate** — at phase 0 a gore lands on the centre-front of a torso, which is the vertical placket R2.7 calls a wetsuit zip.
6. **`sd_sheen` was backwards for curved parts.** A `pow(N·H, 18)` lobe is 0.26 at 20 degrees off-axis, so it read on flat plates (where it once lifted a mid-blue panel to pale) and vanished on a helmet. Broadened to pow 8 at lower amplitude, so it reads as a sheen on both.
7. **Header now warns about Nyquist**: `sd_cloth` at ~190 cycles/m needs the camera inside ~1.5 m at 720p. On a character judged at the 6.5 m gameplay camera it is invisible, and cranking `strength` only buys aliasing — seams and larger forms are what carry 4-10 m.

## 21. [DONE 2026-09-06 by orchestrator] Surface-detail library, third pass — and a shared-file collision
The hub builder adopted the library and reported seven more findings. All seven are in:
1. **`scale`** on every material — multiplies the frequencies, so a pattern can be moved into a band that survives the distance it is actually viewed at. This was the most-requested knob and the header already recommended the technique without providing it.
2. **`sd_macro(objpos, cycles_per_m, amount, lod)`** plus **`sd_fbm01()`** — a low-frequency tonal band. It is the ONLY term that survives past ~20 m on a large surface (2.6 cycles/m is still ~13 px/cycle at 22 m) and it is what stops a big wall or hillside reading as one flat swatch. `sd_fbm`'s two octaves sum to 0.75, so the raw `fbm - 0.5` biased surfaces ~1.6% dark; `sd_fbm01` normalises.
3. **`sd_panel_seams()`** — `sd_seams`' gore family is angular, so on a flat 5 m wall the spacing varies ~3x from centre to corner. This drives two uniform ring families along the part's own axes, each weighted by how much the surface faces that axis, which also keeps vertical joints off roofs.
4. **`stitch_amount` on the seam functions.** The topstitch bead is right on cloth and reads as a rivet line on sheet metal, but on plaster it draws a ladder of dashes climbing the wall — the hub builder had to disable seams on plaster entirely rather than lose the groove. 0 = groove only.
5. **`knot_amount` on `sd_wood`.** The default 0.55 reads as wandering marbling; 0.15-0.25 gives the combed parallel lines ACNH's doors and signs have.
6. **Documented that `sd_wood`'s ring frequency is geometry-dependent** — rings are contours of distance from the grain axis *through the model origin*, so the on-screen frequency depends on the part. The same default gave 26 c/m on a door and 220 lines across a 3.9 m stage deck (a third of a pixel each, invisible mush).
7. **Header warning: bright surfaces crush this library.** A cream wall renders at display luma ~0.88, up on the ACES (white 6) shoulder, so a 10% albedo change arrives as ~1.5% on screen. Dark timber on the linear part of the curve needs a fraction of the same numbers. Without this note, anyone adopting the library on a light surface concludes it "does nothing" and either gives up or cranks into aliasing.

**Also fixed: a shared-file collision, and a language limitation worth knowing.** Two builders needed `scale` at the same time and the planet builder wrote calls against an extended signature while I was extending it under a different name. **Godot's shading language has no user function overloading and no default arguments**, so a wrapper-plus-`_ex` scheme does not compile — every function has exactly one signature. The plain names now carry the extended forms, every call site in the project was swept and topped up with explicit defaults, and the header states the rule: **if you extend a signature, update every caller in the same change.**

## 22. [DONE 2026-09-06 by orchestrator] Surface-detail library, fourth pass — the bump channel was dead
The planet builder adopted the library across all four grounds and found three real defects in it, plus a process lesson.

**A third of the library did nothing.** `SdSurface.bump`'s dominant term is along the normal, and `normalize(N + N*k) == N` — so **`bump` is a literal no-op on any large flat surface**, which is exactly where it was most needed (a ground, a wall). And even where it did tilt a normal, `toon_soft`'s ramp **saturates**: `mix(shadow_col, ALBEDO, lit)` returns exactly `ALBEDO` once `lit == 1`, which is most of a sunlit surface, so a perturbed normal changed nothing outside a narrow band at the terminator. Fixes:
* `SdSurface` gains **`height`**, the raw signed field the tint was built from, so a caller can take screen-space derivatives and tilt by the *tangential* gradient. The planet builder's `pc_surface_grad` (a Mikkelsen surface gradient, two derivatives and no extra noise samples) is the worked implementation.
* `toon_soft` gains **`detail_light`**: the detail's slope comes back as a multiplier centred on 1.0 and hard-clamped to 0.80-1.22, so it reads in full daylight while adding no energy and never making a hotspot. R2.6 holds — nothing here raises specular.

**Every material was quietly darkening the surface it textured.** `sd_fbm`'s two octaves sum to 0.75, so `fbm - 0.5` biases dark; two grass bands at strength 2.7 took the home ground crop from value 0.676 to 0.653, straight out of the gate. All material bodies now use the normalised `sd_fbm01`. Worth knowing on top of that: **ACES is concave, so even a mean-preserving multiplicative texture renders ~1% darker than the flat surface it replaced** — on the meadow that needs a ~1.02 gain put back, while on the cream plaza it needs none, because cream sits on the compressive shoulder where the loss is nil.

`surface_strength`'s `hint_range` was widened to 0-4: hint ranges are advisory in Godot, and a near-white boulder needed 3.2 to move its albedo at all (same ACES-shoulder reason as item 21.7).

**PROCESS LESSON — an edit to `surface_detail.gdshaderinc` can break the entire game at once.** While extending `sd_seams` I left a reference to a parameter I had not yet added. A single unknown identifier in the include failed **every shader that includes it** — `toon_soft` (all props, characters and buildings), all three ground shaders, `planet_foliage`, `hub_surface`, `hub_glow`, `astro_shell` — and the whole game rendered unshaded white. A builder mid-run cannot work around it (declaring the missing symbol ahead of the include collides with `sd_panel_seams`'s own parameter). **Any edit to that file must be followed by `tools/check.sh` before anything else is done**, and this is why the file now states that Godot has no overloading and no default arguments, so extending a signature means updating every caller in the same change.

Still open from that report, deliberately not done: an `sd_bark()` (or an angular across-grain mode) — `sd_wood`'s rings are contours of distance from the grain axis, which on a lathed trunk *is* the radius, so rings come out constant and the planet builder had to squash model space to get bark. Worth adding when something else needs it.

## 23. [DONE 2026-09-06 by orchestrator] J was bound to two actions at once
When I added the favours-journal hotkey I put it on **J**, which was already `camera_left`. The journal won — it opens a modal, which then blocks camera input — so keyboard camera-pan on J had silently never worked. The player builder found it while adding mouse look and correctly did not unilaterally rebind another owner's action; they added **H** as a working alias instead.
Resolved by removing J from `camera_left`. Mouse look is now the primary camera control and H covers the keyboard fallback, so J is purely the journal, which matches both the convention and the HUD hint strip ("J favours"). Verified with `tests/director/journal_hotkey.json`.
**Lesson for the input map, which the orchestrator owns:** check for an existing binding before adding one. A duplicate does not error — the loser just silently stops working.

## 24. [DONE 2026-09-06 by orchestrator] Planet.prebuild — the arrival hitch
The rocket builder measured the journey properly and located the user's "freezing and jumping on approach" precisely: **every phase of the trip is a locked 60 fps and there are exactly two bad frames, both scene swaps.** The departure was 61 ms of loading plus 25 ms of build (they fixed it with threaded prewarm, ~4x cheaper). The arrival was 0.2-5 ms of loading and **400-850 ms of `world.gd::_ready()`**, of which `Planet._build()` is the bulk — an icosphere with two GDScript callables per vertex, plus `create_trimesh_shape()`. They could not fix it: `_ready` is atomic and `src/planet/` was not theirs.

Implemented their concrete ask. `Planet` now has a static geometry cache keyed by `id|seed|subdivisions|radius`, and `Planet.prebuild(data)` fills it. The scratch planet is parented into the tree briefly — prop placement reads global transforms and a detached node returns identity plus an error per call — is never rendered, and is freed immediately; everything it produces is deterministic, so the geometry matches what the live planet will build. `_build()` picks up both the mesh and the trimesh shape when they are warm.

Wired into `RocketJourney.prewarm_destination`, so it runs while the space scene is still showing its **held seam frame**, where a stall is invisible by design (`_await_steady_frame`).

**Measured on Zorp: a cold build is 384 ms, a prebuilt one is 91 ms — 76% saved.**

Still open if the arrival is ever felt again: the remaining ~91 ms is prop instancing and the water shell, and `world.gd::_ready()` also spends 18 ms on the player, 25 on the pad and up to 380 on hub NPCs and buildings. Staging `world.gd::_ready()` across a few frames would be the belt-and-braces version.

## 25. [DONE 2026-09-06 by orchestrator] Planet size upgrade would have buried every decoration
The planet-size builder shipped `GameState.home_planet_size` so a later "expand your planet" upgrade is a data change, and flagged the landmine it leaves: `DecorationManager.restore()` re-applies each saved decoration's raw **local** transform, which is a fixed distance from the planet's centre. Growing home from 12 m to 14 m would drop every placed item 2 m underground. They could not fix it — `src/decorations/` was not theirs — so they added `Planet.reseat_local(local_pos)` (preserves direction and yaw, corrects only the distance) and handed it over.
Wired into `restore()`. Verified by `tests/reseat_probe.tscn`: at radius 12 -> 16 a saved position is **4.00 m below ground** raw and **0.0000 m** after re-seating, with the direction preserved to within 1e-4. It is a no-op when the radius has not changed, so nothing moves in normal play.
**This had to land before the upgrade is ever enabled**, which is why it was done now rather than with the upgrade.

## 26. OPEN — camera zoom-out should be a fraction of planet radius — OWNER: player/camera builder
The camera's `MOBILE_DIST_MAX = 13.0` was chosen against the old radii. On the new 10.5 m Zorp and Bolt it puts the eye 11.2 m above a 10.5 m world with the entire limb in frame and sky on both sides — the astronaut becomes a speck. The planet builder rendered it. Suggested fix: cap zoom as a fraction of `planet.radius` (roughly <= 0.75 R) rather than a fixed metre value, so it stays sane across a 10.5 m Bolt, a 21 m hub, and a home planet that can grow to 18 m. The defaults themselves (desktop 7.4 m, mobile 8.6 m) still look right at the new sizes.

## 27. OPEN — small follow-ups from the planet shrink
* `src/world/sky_bodies.gd`: two stale comments quoting the old radii (the header's measured band figures and `BODY_DISTANCE`'s "the biggest planet is R=26"). Placement adapts automatically — it is a fraction of a band measured from the live radius — so this is comment-only. Bolt's ring can clip the top of frame at slot fraction 0.88; pre-existing at the old radius too.
* `src/rocket/space_travel.gd`: the map's `LAYOUT` globe radii (home 2.2 / hub 3.2 = 0.69) now match the real proportions (12/21 = 0.57) slightly less well. Approximate by design and reads fine; cosmetic only.
* `src/characters/npc_data.gd`: Zorp's and Bolt's coarse fallback `home_dir` values are 5.6-6.0 m from spawn at the new radius, down from 7.4. They are wander anchors only and the NPCs sit correctly in every frame, but the character owner may want to widen them.

## 28. [DONE 2026-09-06 by orchestrator] Zoom-out is now a fraction of the planet, not a fixed distance
Issue 26 closed. `CameraRig.dist_max()` caps full zoom-out at `DIST_MAX_RADIUS_FRAC = 0.75` of the live planet radius, on top of the per-platform metre cap. A fixed cap could not survive worlds of different sizes: `MOBILE_DIST_MAX` 13 m on the new 10.5 m Zorp and Bolt put the whole limb in frame with sky either side and reduced the astronaut to a speck, and home can now *grow* to 18 m through `GameState.home_planet_size`. Also silenced `Platform._apply_orientation`'s warning on desktop `--ui=mobile` runs (it guarded on `is_mobile()`, which is the review case, rather than on `OS.has_feature("mobile")`), and updated ARCHITECTURE §6's camera numbers.

## 29. OPEN — stale hardcoded 6.5 m / 28 deg camera constants in other builders' showcases
The camera builder updated their own three showcases to reference `CameraRig.DIST_DEFAULT` / `PITCH_DEFAULT_DEG` instead of copying the numbers. These still hold the old values and are now lies, which matters because **this project has twice shipped bad art that was judged in an unrepresentative showcase**: `src/planet/showcase/planet_showcase.gd` (`CAM_DISTANCE 6.5`, `CAM_ELEVATION_DEG 28`), `src/characters/showcase/lineup_showcase.gd` (`GAMEPLAY_DIST`/`GAMEPLAY_PITCH`), `showcase/environment_showcase.gd` (header comment), and `src/world/environment.gd` (`CAMERA_LOOK_DISTANCE := 6.5`, which the moon arcs are tuned against — that one changes what the player sees, not just a showcase). Each owner should reference the rig's constants.

## 30. OPEN — wide flat decorations can hide the player from the camera fade
The camera fade is physics-based, so it only sees a prop's collider. `deco_star_flag` has `collide_radius = 0.28` around its pole while the banner reaches ~0.9 m sideways, so the banner can cover the astronaut and never fade. Same shape problem on the holo sign and the nebula rug. Pre-existing, not caused by the camera change. Fix in `src/decorations/items/`: give the visual extent a collider, or mark the banner non-blocking but present on layer 4.


## 31. [DONE 2026-09-06 by orchestrator] Web export rendered black grass and flowers — MultiMesh wipes vertex COLOR under Compatibility
Tested by building and running the HTML5 export, then reproduced far faster on desktop with
`godot --path . --rendering-driver opengl3`, which is the way to test this without a browser.

**Symptom.** In the browser (and under `opengl3`) every grass tuft and every flower rendered as a
solid black silhouette. Trees, bushes, rocks and the ground were fine.

**Root cause, bisected in-engine rather than guessed.** Three probes, each rendered and measured:
1. Replacing the foliage shader's `base` with a constant colour made the grass render correctly, so
   `light()` was innocent and the fault was upstream in `v_col`.
2. Replacing `INSTANCE_CUSTOM.rgb` with magenta left the grass black, so the per-instance tint was
   innocent too — which meant `step(0.5, COLOR.a)` was returning 0 even though `grass_tuft()` bakes
   `COLOR.a = 1.0`.
3. Rendering `vec3(COLOR.a)` directly showed grass **white** under Forward+ and **black** under
   Compatibility, while trees stayed white under both.

So: **under the Compatibility (WebGL2) renderer a MultiMesh always reads an instance-colour vertex
attribute and multiplies it into `COLOR`. With `use_colors` off that attribute is never supplied and
`COLOR` arrives as `(0,0,0,0)`**, wiping the mesh's baked vertex colour. Forward+ tolerates the
missing attribute, which is why this only ever appeared in the browser build.

**Fix.** `PlanetProps._multimesh()` now sets `mm.use_colors = true` and writes `Color.WHITE` to every
instance, making the multiply a no-op. The per-instance tint stays in custom data. Verified: Forward+
frames are pixel-identical apart from player animation phase (max diff confined to the astronaut);
Compatibility renders grass and flowers correctly on home, Zorp, Bolt and the hub.

**Ruled out by direct test, so nobody repeats the work:** custom `light()` functions work fine under
Compatibility; `INSTANCE_CUSTOM` read in `vertex()` works fine; `pc_detail_lod`'s `dFdx`/`dFdy`
derivatives agree between renderers to within 2% (clump-band LOD mean 0.870 Forward+ vs 0.854
Compatibility). Reading `INSTANCE_CUSTOM` in `fragment()` does **not** compile under Compatibility
("Unknown identifier"), but no shader in this project does that.

**Also fixed while testing:** pointer lock threw `WrongDocumentError` in a browser; `CameraRig` now
refuses to grab the cursor under `OS.has_feature("web")` or `Platform.is_mobile()`. And
`project.godot` line 223 had a comment mashed into it with its spaces stripped
(`Compatibility-SSAOandsomeglowmodesareunavailablethere.renderer/rendering_method="forward_plus"`),
so the key parsed as garbage and `renderer/rendering_method` was never actually set — desktop worked
only because `forward_plus` is the default. Repaired with real `;` comment lines.



## 32. PARTLY FIXED 2026-09-06 — the browser build's ground was pale and washed out
The ground is fixed. One gap remains (foliage, below), and it is left open **deliberately**: the
obvious correction for it was built, measured, looked at, and reverted because it blew the trees out
to white. Read the "do not do this" section before touching it.

### What was wrong
Under the Compatibility (WebGL2) renderer that the web export is forced onto, the ground rendered far
too pale and desaturated. Measured on the home ground crop `(250,470)-(1050,640)`:
Forward+ **V 0.609 / S 0.519**, Compatibility **V 0.772 / S 0.307** — failing R2.6's saturation gate
of 0.40-0.52. The same cast showed on Zorp's violet ground.

### What it actually was — two independent differences
1. **The albedo multiply does not land in the same place.** Proven with a probe: `ALBEDO = vec3(0.25)`
   in `fragment()` and `DIFFUSE_LIGHT = vec3(1.0)` in `light()` renders `(182,182,183)` under
   Forward+ and `(87,92,105)` under Compatibility. Critically the direction is **not the same for
   every shader**: measured against Forward+, `grass_planet` carries one albedo too FEW (too bright)
   while `planet_foliage` carries one too MANY (too dark, canopy V 0.309 vs 0.513). That opposition is
   why the single global `pc_diffuse_out()` correction tried earlier could never have worked.
2. **Ambient reaches the surface far more strongly.** Turning `ambient_light_energy` to 0 drops the
   ground's value mean by 0.129 under Forward+ but by 0.212 under Compatibility.

### The fix that shipped
* `grass_planet.gdshader` applies the albedo once more, gated on the new `astro_compat` global shader
  uniform (`src/autoload/platform.gd` sets it to 1.0 only when `RenderingServer.get_rendering_device()`
  is null, i.e. Compatibility). A `compat_gain` uniform is there as a trim; it currently sits at 1.0.
* `src/world/environment.gd` scales ambient by `COMPAT_AMBIENT_SCALE = 0.75`, again only under
  Compatibility.

Result on the ground: **V 0.772 -> 0.680** and **S 0.307 -> 0.569** against a Forward+ target of
0.609 / 0.519. Verified on home, Zorp, Bolt and the hub, and **Forward+ is untouched** — a pixel diff
of before against after confines every changed pixel to the bounding box `(584,362)-(693,512)`, which
is the astronaut's idle-animation phase.

### DO NOT do this to the foliage (it was tried twice)
The canopy is still too dark and too saturated in the browser (V 0.293 / S 0.614 against 0.513 /
0.343). The arithmetically "correct" correction — divide `planet_foliage`'s light by ALBEDO under
Compatibility, mirroring the ground — **moves the numbers the right way and ruins the picture**: it
took the canopy to V 0.678 / S 0.325, which looks like a match on paper, while the trees, bushes and
grass tufts rendered **white and pink**. Dividing by a dark canopy albedo is a large multiplier that
drives the colour into the ACES shoulder, where chroma collapses; the giveaway was that the result
barely responded to `compat_gain` at all, because it was already clipping.

This is the third time in this project that a palette metric improved while the art got worse. The
canopy needs its own brightness constants re-derived (`light_gain 0.36`, `shade_floor 0.70`,
`ambient_damp 0.24`) against a captured frame under both renderers, not a corrective multiply — the
same job as item 19.

### Ruled out, so nobody repeats the work
SSAO (identical to three decimal places with it off), tonemap mode (LINEAR moves Forward+ the wrong
way), sky-vs-colour ambient source (moves Compatibility 0.772 -> 0.778), the `AO` channel (forcing
`AO = 1.0` moves Forward+ 0.609 -> 0.616 and Compatibility 0.772 -> 0.776, so neither renderer leans
on it), `pc_detail_lod`'s `dFdx`/`dFdy` derivatives, and the `sd_fbm` noise itself.

### Cosmetic, separate cause
The atmosphere's warm limb haze is dimmer in the browser. That is the glow difference — Compatibility
supports fewer glow modes — and is unrelated to the albedo and ambient issues above.
