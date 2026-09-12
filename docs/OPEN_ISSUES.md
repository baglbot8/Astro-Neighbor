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


## 33. [MOSTLY FIXED 2026-09-06] Seven faults found by playing the web build on a real iPhone
Playtested in Chrome on iPhone (which is WebKit, like every iOS browser). Six of the seven are fixed;
the seventh is a judgement call recorded below.

**1 + 5 — laggy, and the phone heated up.** The project ships desktop quality and a phone GPU paid
for all of it: highest soft-shadow filter, 4x MSAA, 16x anisotropic, and a seven-level ADDITIVE glow.
`Platform._apply_quality_profile()` now applies a low-power profile when the renderer is
Compatibility or the UI is mobile — MSAA off (FXAA instead), hard shadows — and `environment.gd`
turns glow and SSAO off on the same condition. Desktop is untouched.

**2 — the camera swung wildly on every button press.** A phone emits an EMULATED mouse event for
each finger, with a `relative` that jumps from the previous position to the new touch point.
`CameraRig` had mouse look armed regardless of platform and `_unhandled_input` accumulated those, so
tapping Jump or Fly threw the camera across the sky. Mouse look is now off when `Platform.is_mobile()`
— on a phone the camera belongs to `TouchControls`, which drives it through `add_look_px()`.

**3 — everything washed out and "blurred with whites".** That was the glow, see 1.

**4 — the sky was black instead of navy.** `sky.gdshader` authors its palette DISPLAY-REFERRED and
pushes it back through the inverse ACES curve so the tonemapper returns it unchanged. That round trip
does not close under Compatibility: measured over the upper sky, Forward+ renders `(29,28,57)` and
Compatibility rendered `(8,5,31)` — flat black on a phone. A gated `compat_sky_gain` (1.35) lifts the
colour BEFORE the inverse curve, where it is steep, so darks recover while the stars, moons and sun
disc — added afterwards — are untouched. Sky now measures within ~15% of Forward+.

**6 — the rocket card said "press Esc" and a phone has no Esc key.** `PadDestinationPicker` now
builds a "Stay here" button (hidden on desktop, the same rule `ItemGridPanel` uses), says "tap a
planet to fly" instead of the keyboard hints, drops the "E" from the Launch pill, and its column is
570 px tall on mobile instead of 470 so the new button is not clipped off the bottom.

**7 — after landing, the joystick only panned the camera.** `TouchControls._on_planet_loaded` cleared
its cached rig but not its pointer state, so a finger held across the flight (or any pointer that
survived the scene swap) left `_stick.active` true. `_pointer_down` refuses the stick while it is
active, so every later touch fell through to the camera zone. It now calls `_release_everything()`
and re-runs `_layout()` on every planet load.

### The foliage gap from item 32 is now fixed too — with the OPPOSITE approach
Item 32 records two failed attempts to correct `planet_foliage` by dividing its light by ALBEDO. Both
rendered the trees white and pink. The reason is arithmetic: a leaf's albedo is dark, so dividing is a
~14x multiply that clips into the ACES shoulder where chroma collapses — which is why the result also
barely responded to a gain. Re-tested with glow off, in case glow was the amplifier. It was not; it
blew out exactly the same way.

What works is a straight LIFT of the shader's own `light_gain` under Compatibility
(`compat_light_boost = 3.6`), which is bounded and cannot explode. Canopy value mean went
**0.293 -> 0.468** against a Forward+ target of 0.513. Saturation is still higher than Forward+
(0.588 vs 0.343), so the browser canopy reads a little richer than the desktop one — that is the
remaining gap, and it is a far better place to be than either black or white.

### Verification
Desktop (Forward+) is untouched by all of it: with every change in, a pixel diff against the same
frame without them differs by **0.23%**, confined to the bounding box `(590,363)-(692,511)`, which is
the astronaut's idle-animation phase — below the **0.32%** run-to-run noise floor measured by running
identical code twice.

**Process note.** One desktop capture in this session differed from its baseline by 97.6% and looked
like a serious regression. Re-running the same code twice produced 12.3% and 12.4%, and an
apples-to-apples comparison in the same directory gave 0.38%. It was a one-off bad run. **Confirm a
regression is repeatable before chasing it**, and compare within one working copy — a capture from a
different directory carries its own RNG and import cache and is not a valid baseline.


## 34. [2026-09-06] Second iPhone playtest — contrast over-correction, black start page, no audio
Item 33's fixes were played on a real iPhone. Four new findings, three fixed.

### The contrast over-correction (mine)
The player reported "all dark colors much darker and light colors much lighter" — grass almost white,
tree tops almost black. Measured whole-frame luma: Forward+ `p05=25 p50=119`, Compatibility
`p05=11 p50=138`. Three of item 33's changes each removed the same wash and stacked up:

* `COMPAT_AMBIENT_SCALE` 0.75 -> **1.0**. The 0.75 cut was fitted while glow was still ON under
  Compatibility. Turning glow off does that job on its own, so the cut was double-counted.
* `compat_light_boost` 3.6 -> **2.0**. 3.6 was fitted to the tree CANOPY crop alone; grass tufts run
  through the same shader with a much lighter albedo and blew out to white at that value. **Fit a
  shared shader against every surface that uses it, not the one crop you are looking at.**

### The sky, properly this time
The crushed darks were the sky, not the ground: **22.2%** of a Compatibility frame sat below luma 15
against **0.0%** on Forward+. Item 33's `compat_sky_gain` was a MULTIPLY, and raising it far enough
to fix the darks turned the sky vivid royal blue — the Earth-like sky R2.1 bans — because the dark
sky is blue-dominant so scaling grows blue fastest.

Replaced with a neutral **`compat_sky_lift = 0.08`**, added before the inverse ACES curve. Sky band
now reads `(79,80,90)` against Forward+'s `(81,79,93)`, and the share of frame below luma 15 is
**0.2%** against 0.0%. Hue preserved, darks recovered.

### The start page was still black
`title_screen.gd` builds its **own** `Environment` and never saw the world's low-power profile, so it
kept the seven-level glow on a phone. Now gated the same way.

### No audio anywhere in the browser
Ruled out first: the engine itself is fine (a `--write-movie` capture on desktop has a full-scale
peak of 32768), and the samples ARE in the export (`assets/audio` is 46 MB on disk, QOA-compressed by
`compress/mode=2`, and the pack contains the paths).

**WRONG CONCLUSION - corrected 2026-09-11, see item 44.** The cause was NOT the browser. What this round
built is real and still ships: iOS suspends an `AudioContext` until a user gesture, Godot's `GodotAudio.ctx`
lives in module scope and **cannot be reached from `JavaScriptBridge.eval()`** (verified by probing
`window.Godot` and `window.Engine`), so a shim in `html/head_include` in `export_presets.cfg` wraps
`AudioContext` **before the engine constructs one**, keeps a registry, and resumes every context on any
pointer, touch, key or visibility event. Re-measured 2026-09-11: the shim works, the context goes suspended
-> running on a real click, and `currentTime` advances.

**The verification was too weak, and the real bug hid behind it for five days.** "The shim captures exactly
one context (48 kHz)" proves a context exists, not that a SOUND comes out. Measured 2026-09-11 on the shipped
build: an analyser on `ctx.destination` read peak 0.000000 while that same context said "running". The real
cause is the web bus graph losing its edge to the destination when the Music and SFX buses are added at
runtime (item 44). The rule now, in CLAUDE.md's tooling traps: put an analyser on `ctx.destination`, read the
peak, and keep a positive control in the same graph.

**Also ruled out 2026-09-11:** the physical ring/silent switch. The user's iPhone has no such switch, and the
same silence reproduces in desktop Chrome, where no such switch exists.

### Still open: lag
The low-power profile helped but did not remove it. Frame cost on a phone is now dominated by the
scene itself rather than post-processing, and the long pause when approaching a planet is procedural
generation (`Planet.prebuild` already caches geometry; the props are rebuilt per visit). The next
lever is cutting MultiMesh instance counts on mobile — thousands of 16 cm grass blades per planet —
which is a visual change and must be measured, not guessed.


## 35. [2026-09-07] Every organic neighbour shared ONE head mesh — fixed, plus alien skin
Found by a 13-agent design pass. The user's words were "it still looks like it's just a reused head
of the old zorp or mayor", and that was **literally true at the mesh level**: `_add_head_shell` calls
`superellipsoid(HEAD_SEMI, HEAD_N, 44, 22)` and `superellipsoid()` caches on its arguments, so Zorp,
Pip, Pop and Mayor Orbit all held the same `ArrayMesh`. Bolt and DJ Nova escaped only because they
build their own `rounded_box` heads.

**Why nobody had fixed it:** a subclass cannot redeclare a parent `const` — it is a hard parse error
("The member HEAD_R already exists in parent class"). `_head.scale` was the only lever and it is
uniform-only, so it shrank the eyestalks, antenna, grin and every face feature along with the dome.

**Fix.** `head_semi` / `head_n` / `head_y` / `head_segs` are instance vars on ChibiModel, defaulting to
the consts, read by `_add_head_shell` and `_orient_on_head`. The crown seam's height is now derived,
`(1 - 0.795^n)^(1/n)`, which returns 0.7351 at the default n = 2.6 — i.e. the 0.735 literal it
replaces — so it stays welded to the shell at any exponent. Zorp, the twins and the Mayor each set
their own shape and the two `_head.scale` hacks are gone.

**EXPONENT — the trap.** The design pass proposed n = 3.6-4.0. Two reviewers independently BUILT it
and rendered it, and at that exponent every head becomes a hard-edged faceted BOX: `superellipsoid()`
samples a UV sphere's uniform angular directions, so a high exponent packs nearly all the curvature
into a narrow chamfer band that a fixed segment count cannot resolve. Shipped at **3.2** with
`head_segs` held at (44, 22). **Raising `head_n` requires raising `head_segs` too.**

### A real shader bug found on the way: v_flat_nrm was in the wrong space
`toon_soft.gdshader` assigned `v_flat_nrm = NORMAL` in **vertex()**, where NORMAL is MODEL space,
while `light()` compares it against fragment's VIEW-space NORMAL:
`dot(normalize(NORMAL) - normalize(v_flat_nrm), LIGHT) * 2.4`. The difference of two unit vectors in
different spaces has magnitude up to 2, so that term was garbage that swung with the camera instead
of with the surface. It stayed hidden for one reason only: `surface_kind` was 0 on every character,
so the branch never ran. `grass_planet.gdshader` and `planet_foliage.gdshader` both already capture
it in fragment; toon_soft now does the same. **This had to be fixed before any character skin.**

### sd_skin — a cellular pattern, because rock is the wrong shape
`sd_rock` was tried first and rejected: it is fbm, so it produces MOTTLING, and its tint amplitude
tops out near 6% — invisible at gameplay distance. Spots and scales are CELLULAR. `sd_skin` runs one
3x3x3 cellular pass and reads two things from it: distance to the nearest feature point gives round
spots, and the gap to the second nearest gives the ridge between cells, which is what reads as
scales. Only some cells get a spot, so the skin is blotchy rather than a regular polka dot.
`tint` and `height` deliberately share one signed term — a first version where they disagreed made
the lighting fight the albedo, which is why every other sd_* in that file pairs them.

**AMPLITUDE IS A PALETTE COST, and it is measured.** An A/B on one identical frame (strength 0.0 vs
on) moved Zorp's head-crop saturation mean by **+0.099**. The tint multiplies the albedo, and
darkening a colour RAISES its HSV saturation, so a strong pattern pushes straight at the R2.6 gate.
Shipped amplitude is about 30% lower than the first pass, at **+0.073**. **Re-measure in
`src/world/world.tscn`, not a showcase, before raising it** — the showcase's own lighting reads
about +0.10 higher than the documented world figure, so a showcase number cannot be compared against
the gate at all.

> **SUPERSEDED 2026-09-07 (see item 37).** Most of that **+0.099** was not amplitude, it was a BUG:
> `sd_skin`'s spot term carried a DC offset that did not track `surface_spot_radius`, so raising the
> radius applied a flat 1–6% albedo DARKENING to the whole material — and darkening is exactly what
> raises HSV saturation. `MaterialLib` now derives the DC from the radius (`spot_dc()`), and the
> eight shipped skin materials measure within ±0.0003 of neutral. **The saturation figure above
> should be re-measured rather than trusted**; the cost of the pattern itself is much lower than
> +0.099. Do NOT set `surface_spot_dc` by hand — set the radius and let the DC follow.

**Limbs need their own preset.** The head setting rendered the twins' arms as cauliflower: an arm is
a small, strongly curved capsule, and the cell-EDGE term is what does it. Limbs run finer, weaker,
and with the edges nearly off — spots only. `_add_arms` / `_add_legs` take `hand_opts` /
`sleeve_opts` / `leg_opts` for this; the boot materials are deliberately excluded.

### Deliberately NOT shipped
* **Nostrils.** The user asked for "big nostrils". Both reviewers built the proposed asymmetric raked
  slits and reported that in a real render they read as exactly what the spec said they must not — a
  NOSE, because two dark marks above a wide mouth is the universal nostril glyph. It also contradicts
  `reference/Alien References.webp`, where no creature has one. Raised with the user rather than
  decided here.
* **A 2.05x grin.** Proposed, built, and rendered as a black gaping hole with the teeth stretched
  into fangs. Shipped at 1.85 x 1.55 with four uneven blunt teeth instead of three.
* **Mayor Orbit's cheek bars.** Geometrically fine, but a reviewer's capture showed the 150 mm bar
  sitting on the cheek's silhouette edge, reading as a brown stick glued to his face.

### Still open
Mayor Orbit is **6130 triangles against a 6000 budget** — pre-existing, not caused by this change
(the baseline was already 6130), but it should be paid down; his top hat is four cylinders at
seg 18/16/16/14. Stella is 8176, also pre-existing and far over. And `docs/STYLE_GUIDE.md:216`'s
"mouth = 16-25% of head width" gate is written for a face with eyes ON it; the stalk-eyed neighbours
ship well over it deliberately, and that exemption should be written into the style guide the way the
eye-spacing one was rather than left implicit.

See `docs/NEXT_WORLDS.md` for the measured build spec that produced Fen and Grig.


## 36. [2026-09-07] Two rules the Fen / Grig build measured, so nobody re-derives them

### Water goes in BOWLS, never on shelves
`decoration_manager.gd` refuses any spot with `h0 < water_radius + SHORE_MARGIN` (0.18 m) and
repeats the test on all six rim samples, so the shore skirt is measured in METRES OF GROUND, not in
metres of water. On a broad flat shelf a 0.18 m margin reaches a long way inland and eats the
placement budget; in a steep bowl it is a thin ring.

Measured over six candidate worlds at fp 0.6, 4000 Fibonacci samples, against a synthetic home
baseline of 75.8% free:

    Fen    water 5.6%  shore refusal  2.5%   free 70.5%   <- craters: steep bowls
    Thrum  water 0.6%  shore refusal 20.5%   free 61.4%   <- flooded terrace shelves
    Umbo   water 0.5%  shore refusal 23.7%   free 47.8%
    Squill water 26.5% shore refusal  6.7%   free 45.7%   (own fix -0.44: 46.4%, shore 26.1%)

Squill, Thrum and Umbo all put their waterline on a shelf and all three were cut. Lowering
`water_level` does not rescue a shelf world: it converts water refusal into shore refusal at
roughly one for one. This is the same trap `planet.gd`'s own `RIVER_MASK_LO` comment records from
Zorp's rescue.

### A terrace riser needs ~3-4 icosphere edges across it, and `mesh_subdivisions` is the only lever
`terrace_bank` is baked PER VERTEX into `COLOR.g` in `_bake_color()` and read in
`grass_planet.gdshader` as `smoothstep(0.36, 0.52, v_color.g)`. The planet is an icosphere, so
edge length is `1.0515 * radius / 2^mesh_subdivisions`. Grig at r 9.5 / subdiv 5 gives a 0.312 m
edge against a riser that measures 0.500 m wide at the shader's own paint threshold: **1.60
vertices per riser.** Many risers then contain no vertex at all and vanish; the rest render as a
dashed stipple — precisely the "smooth pale dome" outcome `terrace_bank` exists to prevent.

**Fix it with `mesh_subdivisions`, NOT with `terrace_band`.** `_terrace()` and `_terrace_bank()`
share the same `w`, so raising `terrace_band` widens the real quantisation ramp and physically
flattens the staircase. Measured on Grig (24 great circles, 1 cm steps):

    band 0.055 -> riser 0.500 m,  slope 23.0 deg median,  bank coverage  6.37%   <- shipped
    band 0.103 -> riser 0.920 m,  slope 13.8 deg,         coverage      11.83%
    band 0.140 -> riser 1.280 m,  slope 10.1 deg,         coverage      16.00%

`DecorationManager.MAX_SLOPE_DEG` is 16, so both wider bands drop the risers BELOW the refusal
threshold: they stop being cut cliffs, start accepting props, and the world becomes a smooth dome
with ochre stripes. Grig ships subdiv 6 (0.156 m edge = 3.20 verts per riser, ~82k tris, the same
as every other world). Note 3.20 does not reach the >= 4 bar the critic set; reaching it would need
subdiv 7 at ~164k tris. The genuinely correct fix is to compute the band in the shader from world
position instead of reading `COLOR.g`, which is a `grass_planet.gdshader` edit and out of scope.


## 36. [2026-09-07] Two new worlds shipped: Fen's Long Dusk and Grig's Chalk Steps
Built to the measured spec in `docs/NEXT_WORLDS.md` by seven agents on strictly disjoint files. Four
worlds became six; seven neighbours became nine.

**Fen's Long Dusk** (id `fen`, biome `flats`, R 13.0) — a near-flat pan of 14 crater pools under a sun
that peaks at **11 degrees**, so everything throws a long shadow all day. Nothing else in the game is
flat and nothing else has a low sun. Its water works where three other proposals' did not, and the
reason is recorded as a rule worth keeping: **water goes in bowls, never on shelves.** `SHORE_MARGIN`
(0.18 m) punishes any waterline sitting on a broad flat shelf — the three rejected designs either
drowned the decoration budget or produced no water at all. Fen gets 5.6% coverage for 2.5% shore
refusal because its water is in steep crater bowls.

**Grig's Chalk Steps** (id `grig`, biome `chalk`, R 9.5) — a small dry world of concentric stepped
shelves under a near-edge-on razor ring and two moons. The steps only exist because of the one engine
change below; without it he is a smooth pale dome.

### The engine change both worlds needed: terrace banks
`bank_color` was only ever painted on crater walls and plateau banks. `PlanetData.terrace_bank`
(default 0.0, so all four shipped worlds are byte-identical) plus `Planet._terrace_bank()` feeding
both `bank_weight()` and `_bake_color()` paints the riser between two treads. Measured at 6-9% of
Grig's surface — a strong read without swamping the world. No shader edit: `grass_planet.gdshader`
already paints `bank_weight` with `bank_color` and already suppresses it inside the sand band.

### Seven new PlanetData fields, all defaulted to today's hardcoded values
`sun_peak_elev_deg`, `sun_disc_size`, `moon_size`, `star_density`, `ring_inner_scale`,
`ring_outer_scale`, `ring_tilt_deg`. The last three replace literals in `environment.gd`, and the
middle three are uniforms `sky.gdshader` has always declared but `_apply()` has never set for any
planet — so a per-world sky was four `set_shader_parameter` calls away the whole time.

### Registries: the part that decides whether a world exists at all
Adding a planet id means teaching **sixteen** hardcoded lists. Some failures are silent — a world
that builds fine but is unreachable, invisible in the sky, or drawn as the wrong globe — and one is a
hard crash: `space_travel._build_orbits()` indexes `LAYOUT[id]` with no guard. Both globe shaders had
to go to `hint_range(0, 5)` with real mode-4 and mode-5 branches, because their `_:` fallback sets
mode 3 and both new worlds would otherwise draw as the green-and-cream hub everywhere.

`PlanetScore.TRUST_NPCS` went from 2 entries to 4. That **halves the trust component of every
existing save's home rating** and is a deliberate rebalance, not an oversight.

### Grig was rebuilt once, for the reason the user already gave us
The first build was 490 x 860 mm — nearly twice as tall as wide — with a small mouth on a large blank
field. That is exactly the complaint made about Zorp ("a lot of open space ... shrink that open space
down more"). Rebalanced to 550 x 660 with a grin at 1.95 x 1.70 and four uneven teeth. He is still
the tallest head in the cast, which is his silhouette; he is no longer a loaf.

### Verified
Headless boot clean; both worlds load with zero script errors; both creatures build and register
(`fen` 5834 tris, `grig` 5042, budget 6000). Mayor Orbit remains 6130 and Stella 8176 — both
pre-existing and untouched by this work.

**A build agent was flagged by a security classifier.** Its diff was reviewed line by line before
anything was committed: every change is in game source, there are no network calls, no credential
access, no writes outside the project and no `OS.execute`. The finding appears to be a false positive.


## 37. [2026-09-07] Cast variety pass — five aliens that were one creature, a robot neighbour, and four silent rendering bugs

### What the user asked for
> "Too many of the alien characters fundamentally look the same (Zorp, pip, pop, grig and fen). Eye
> stalks, rocky texture skin with spots, same open mouth, all have more male attributes than female.
> They need to vary more across the board. [...] We also need to add another neighbour that's a
> robotic like being and planet, just to balance out aliens to robots."

All five called the same three helpers — `_add_eyestalks`, `_add_wide_grin`, `{"surface": "skin"}` —
so the species read as one creature in five colours.

### What the cast looks like now, against the six binding rulings
| ruling | cap | shipped |
|---|---|---|
| eyestalks | at most 2 | 2 — Grig (one, cyclops) and Fen (three, graded) |
| wide toothy grin | at most 2 | 2 — Grig and Fen |
| `sd_skin` | at most 2, at opposite settings | 2 — Zorp (`surface_scales` 0.0, `spot_radius` 0.74: smooth, big spots) and Grig (`surface_scales` 1.35, `spot` 0.0: craze, no spots) |
| no surface at all | exactly 1 | Pop |
| lashes | at most 1 character | **zero** across the cast |
| hard vocabulary {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke} | ≤2 each, and one elder with none | Fen and Vela carry **none**; every reworked model passes `brows: false` |
| closed mouths differing in KIND | at most 1 closed arc | Zorp holds the single arc; Pop is a straight lipless bar, Vela has `mouth: false` (none), Grig is an under-bite |

Vela is the new robot-like neighbour (`vela_model.gd`, 5832 tris) on the new frost world
`src/planet/data/vela.tres` — a dish-headed listener whose eyes sit in a hoop at the dish's focus.

### Four bugs that every numeric test passed and only a render caught
1. **Flat superellipsoids do not render, and two shared helpers built them on every character.**
   `superellipsoid()` projects SphereMesh vertex *directions* radially, so the mesh only reaches its
   equatorial radius if a vertex row lies ON the equator — and Godot puts rows at `v = j/(rings+1)`,
   so an EVEN ring count has none. `_segs(6, 4)` resolves to 4. Measured: the crown seam asked for
   half-x 0.203600 and built **0.076166 (37.4%)**; the waist chamfer asked 0.214300 and built
   **0.066913 (31.2%)**. Both sat buried inside their own shells, so **every character in the game
   was missing both of its documented hard edges** — which is part of why heads read rounder than
   R2.3 asks for. Fixed with `ChibiModel._se_slab()`: build near-round, squash with a node scale,
   force the resolved ring count ODD so one row lands on the equator, inherit the parent's exponent
   and radial count, and sit `SEAM_PROUD` (2%) out so it cannot z-fight into a dashed line.
2. **`sand_band = 0.0` floods a dry world with `sand_color` instead of removing the beach.** On a dry
   world `wr = radius - 50`, so the shader test becomes `smoothstep(-49.88, -50.00, h)` — edge0 above
   edge1, an inverted ramp that clamps to 0 for every `h`, leaving `sand_t = 1` everywhere. **Grig
   shipped as a featureless tan ball**: `color_a`/`b`/`c` and the ochre `bank_color` terrace risers
   were never drawn. Fixed to 0.30. Palette barely moves (saturation mean 0.194 → 0.193) and luma
   range improves 0.606 → 0.647.
3. **Fen's `sd_scales` read as a blackberry, not a reptile.** `sd_scales` tints and bump-perturbs
   EVERY fragment where `sd_skin`'s spot term fires on ~5%, so the two are not comparable at equal
   `surface_strength`. 0.85 was rejected, 0.45 shipped, and 0.45 was still bubbles at both the 6.5 m
   gameplay distance and in close-up. Now 3.10/0.24 (~13 scales across the head).
4. **`_eye_mesh("almond")` is not an almond.** An exponent below 2 pulls the diagonals in while the
   axes stay at 1.0, so it is a rounded OCTAHEDRON — a four-pointed diamond, not a lens. Nothing
   used it; the comment and the `shape` docs now say what it actually builds, and point at Pop's
   `_cut_almond_eyes()` for the real lens recipe.

### `tools/capture.sh` IS NOT DETERMINISTIC — this invalidates before/after pixel diffs
Two captures of the same scene with **identical code** differ by **~55,000 pixels**
(`--face=dj_nova --freeze`, 1280x720): neither the idle animation phase nor the framing is pinned.
Any A/B smaller than that is invisible to the harness, and a pixel-diff number from it means nothing.
This was found the hard way while testing the `arc_tube` winding, where an apparent "72,037 changed
pixels" turned out to be mostly capture noise. **Pinning the capture seed and pose would make
render-based review actually reviewable, and is the single highest-value tooling fix available.**

### `arc_tube` is wound inside-out, and is deliberately left that way
Confirmed by signed volume in one deterministic run: `arc_tube` (360° sweep) **+0.15783** against
`TorusMesh` −0.19582, `BoxMesh` −1.00000, `superellipsoid` −4.75974, `taper_tube` −0.04161. Under
`cull_back` every smile, brow, lid ridge and headband draws its FAR wall. Silhouettes are unaffected
and normals still point outward, so nothing renders as a hole. Flipping it repaints a feature on all
nine shipped neighbours at once, and — per the point above — **it cannot currently be A/B reviewed**.
It needs a deterministic capture first and then its own review pass; it is not integration cleanup.

### Also shipped
* A `frost` music track (`tools/gen/audio/music.py`), because `vela.tres` asked for one that did not
  exist and `AudioManager` degrades to silence with only a `push_warning`.
* **The audio budget is now effectively full.** `build_all.py` gates each track at 6 MiB and all of
  `assets/audio` at 60 MB; the other ten tracks already spend 57.0 MB. The first `frost` build (8
  bars at 54 bpm, 35.5 s, 6.31 MB) failed BOTH gates. It ships at 4 bars / 58 bpm — 16.6 s, 2.9 MB —
  and the directory now sits at **59.9 MB of 60**. An eighth world cannot have a music track without
  raising that budget deliberately.
* `deco_whisper_array` — a fifth price-0 legendary, because the other four were already assigned and
  `FavorSystem.SIGNATURE_REWARD` silently skips a neighbour with no entry, so Vela's `thanks` line
  promised a gift nothing could grant.
* `showcase/surface_detail.gd` now covers `skin` and `scales` (7 kinds, row geometry derived).

### Still open
* **Mayor Orbit is 6352 triangles against a 6000 budget** (was 6130 before this pass; the crown seam
  and waist chamfer are now real geometry and cost him ~220). Stella is 8176. Both were already over
  and both are out of this pass's scope, but the seam fix moved every character up by ~200–430 tris,
  so the budget is tighter than it was. All eight in-scope neighbours pass: zorp 5318, bolt 5176,
  pip 4940, pop 5450, dj_nova 5884, fen 5854, grig 5304, vela 5832.
* **Grig and Fen hold BOTH remaining eyestalk slots AND both wide-grin slots.** That is inside every
  cap, but it means the two characters who kept the old vocabulary kept all of it. They read as
  clearly different creatures today (a one-stalk cyclops with a quarried crown against a
  three-stalk scaled elder in a shawl), so this is recorded rather than changed — but if the cast
  ever reads uniform again, that pairing is where to look first.
* **The strata bands on Grig have never rendered**, for bug 1's reason. The working version was
  built and deliberately reverted: three visible horizontals on a rounded form read as barrel hoops,
  and with the R4 craze underneath, as woven wicker. Making them visible is a design pass with its
  own review, not a side effect. Lead for whoever takes it: fewer bands — one heavy line low on the
  face reads as a stratum, three read as a barrel.
* **A headless boot does not catch a broken character model.** `godot --headless --quit-after N` only
  loads what the boot scene reaches, so an unregistered `class_name`, a parse error in a model file,
  or a model that renders as garbage all pass it silently. The checks that actually bite are
  `--import` (class registration), `tools/check.sh` (load errors) and `tools/capture.sh` (anything
  visual). Every real bug in this pass was invisible to every numeric test and visible in the first
  render.
* **TENTACLES AND HORNS ARE THE ONE NAMED TRAIT NOBODY SHIPPED.** The user listed five: smooth
  skin with big spots (Zorp), just scaly (Fen), antennae with eyes on the head (Pop), a furry body
  (Pip) — and *"maybe they have tentacles or horns around their head"*. `grep '_add_tendril_ring('`
  and `grep '_add_horn('` across `src/characters/models/` return **zero call sites**: both helpers
  were built for this pass and neither was ever called. The critic rated it `[high]` and said it
  "does more for the silhouette axis than any crown in the three plans".
  It was NOT added during integration, deliberately, and here is the honest reason: there is no
  cheap home for it. Horns are capped by the hard-vocabulary ruling. Tentacles are not capped, but
  a 2-joint barbel is ~80 tris each (`taper_tube` at 4x5, two joints), so a modest four-barbel jaw
  is ~320 — and the only character it suits thematically is **Fen, who has 146 tris of headroom**
  (5854 of 6000). The characters with room are the wrong homes: Zorp is the deliberate control that
  spends none of the vocabulary budget, Grig is mineral and quarried, Pop is the grey-alien
  archetype, Pip is the furry one. Adding it therefore means either paying down triangles somewhere
  first, or the critic's own suggestion — a tentacled LOWER body replacing a bean-on-two-stubs,
  which needs `_apply_pose` handling (it writes `_leg_l`/`_leg_r` every frame; hide the leg meshes
  and hang two tendrils off each so the walk cycle still drives them). Both are a design pass with a
  render review, not integration cleanup. **This is the top candidate for the next pass.**
* **Nothing in the cast reads as YOUNG** (critic, `[low]`, also unclaimed). The twins are the only
  characters proportioned as children. It costs no geometry — `head_semi`, `body_scale`,
  `face_scale`, `anim_time_scale` — and it is a stronger 8 m cut-out difference than any crown.
* **`docs/CAST_VARIETY.md` was never written.** Nine build agents were told to read it as their plan
  and all nine reported it absent; they worked from the six rulings quoted in their briefs and from
  `synthesis.md` / `critic.md` in the session scratchpad. Whatever step was meant to write that file
  did not run, and the judged plan is not in the repo.


## 37. [2026-09-07] The five aliens were one creature in five colours — fixed, and a second robot added
The user: "Too many of the alien characters fundamentally look the same (Zorp, pip, pop, grig and
fen). Eye stalks, rocky texture skin with spots, same open mouth, all have more male attributes than
female." True at the code level: all five model files called the same three helpers —
`_add_eyestalks`, `_add_wide_grin`, `{"surface": "skin"}` — and only the numbers differed.

### The four-axis rule that now holds
No two characters share an eye arrangement, a crown, a skin treatment or a mouth. Enforced caps:
eyestalks on exactly TWO (Fen, Grig), the wide grin on exactly TWO (Fen, Grig), `sd_skin` on exactly
TWO at genuinely opposite settings (Zorp spot-only, Grig edge-only), and ONE character with no
surface pattern at all (Pop) — which is what makes everyone else's pattern read as a choice.

| | eyes | crown | skin | mouth |
|---|---|---|---|---|
| Zorp | on the head, amber iris | one tall antenna | smooth, big soft spots | small closed lip |
| Pip | big round, on the head | fur ruff + her one antenna | fuzzy | round, toothless, tongue |
| Pop | raked almond | two flat paddle antennae | none at all | flat slot, no teeth |
| Fen | 3 graded stalks, all animated | — | overlapping shingle scales | wide grin |
| Grig | one eye on a trunk | stone capital | cracked craze, no spots | grin + under-bite tusks |
| Vela | lenses in a joined hoop | dish head | brushed metal | no mouth |

### On "more male attributes than female"
The reframe that made this tractable, and it came from an adversarial critic rather than from the
design pass: what reads as male here is a SHAPE VOCABULARY — heavy brows, lid ridges, toothy grins,
blunt jaws, broad wedges — not a set of declared sexes. Every design proposal opened by promising
"proportion and manner, not accessories" and then reached for EYELASHES on two or three characters
each. Lashes are an accessory and the most stereotyped cue available.

The rules that shipped instead: **lashes on zero characters cast-wide**; no character wears more than
TWO of {brow ridge, heavy lid, horns, tusks, fangs, shoulder yoke}; at least one of the three elders
wears none (Fen); and **no code comment declares a character's sex**. Exactly one neighbour's gender
is stated in shipped text (npc_data.gd:228 — Pop is Pip's brother) and everything else being unmarked
is an asset, not a gap.

Also rejected: all three proposals made the new robot a legless floating bell skirt AND designated her
female. Making the only character denied legs the one woman is the genie/mermaid trope. **Vela walks.**

### Two real bugs found underneath
* **`sd_skin`'s DC constant was ~6x too large, and it is a function of `spot_radius`, not a constant.**
  The measured mean of the spot term is 0.035 at the shipping radius against a hardcoded 0.22, so the
  alien skin was a flat ~6% albedo DARKENING rather than a pattern — that darkening is exactly the
  +0.099 saturation cost recorded in item 35. It is now a uniform derived by `MaterialLib.spot_dc()`
  from a fitted curve. Every shipped skin material now centres to within +/-0.0003 of 1.0, with the
  pattern amplitude untouched. Spots above radius ~0.55 also used to shatter into polygonal shards,
  because the spot was read off `f1` after the cellular loop and so was clipped by its own cell.
* **Flat superellipsoids never rendered their hard edges**, so every character in the game was missing
  both of the chamfers its own comments document.
* **Per-eye size was impossible**: `_apply_face` rewrites `oval.scale` every frame from the single
  model-wide `eye_w`/`eye_h`, so anything authored per-eye was overwritten on frame 1. A fifth
  parallel array `_eye_size` fixes it — and `GrigModel._make_cyclops()` has to drop index 1 from that
  one too, or the next blink is a dangling index.

### Verified
All SEVEN worlds boot clean. All ten neighbours render with distinct triangle counts, so no id is
silently falling back to a generic `AlienModel` (that fallback is why an unregistered id ships as a
duplicate Zorp). `tools/check.sh` passes.

### STILL OPEN
1. **The three robot files were not touched.** `mayor_model.gd`, `robot_model.gd` and `dj_model.gd`
   are byte-identical to the pre-pass copies, so Bolt and DJ Nova are still the same robot to within
   5 mm on every shared number. Cast-wide that leaves FOUR closed smile arcs against a cap of one and
   FIVE characters with no surface pattern against a cap of one, and the hard-vocabulary cast TOTAL
   went 7 -> 8 rather than down. The five aliens the user named are fixed; the robots are the same
   problem one room over.
2. **Tentacles and horns were named by the user and did not ship.** Of the five traits asked for,
   three did (smooth-with-big-spots on Zorp, just-scaly on Fen, antennae-with-eyes-on-the-head on
   Pop) and fur did on Pip. A tentacle fringe and a horn crown are still unclaimed — and a horn ring
   was deliberately vetoed mid-build because Fen and Grig would then have worn the same part.
3. **Mayor Orbit is 6352 triangles against a 6000 budget**, up from 6130. He was already over; the
   shared hard-edge fix added ~220 to him. Stella is 8176, unchanged.
4. **`tools/capture.sh` is not deterministic** — two captures of the same scene with identical code
   differ by ~55,000 pixels at 1280x720, because neither the idle animation phase nor the framing is
   pinned. Every render-based review in this project is quietly weaker than it looks.


## 38. [2026-09-08] Renderer parity: two engine bugs, and the three wrong answers on the way

The user tested on an iPhone five times and reported the same thing every time: "all dark colors are
much darker and light colors are much lighter", "all the plants very black", "certain grass ... comes
out very white". Three previous rounds "fixed" it and none of them reached the phone. This entry is
the whole account, because the wrong turns cost more than the fix.

### Nothing reached the phone for two days, and the cause was a service worker
Builds published before 2026-09-06 21:00 shipped Godot's PWA service worker. Its fetch handler is
cache-first with NO revalidation over `CACHEABLE_FILES`, which is `["index.wasm","index.pck"]` - the
entire game. A device that loaded the site in that window cached the whole build and served it from
disk forever. Turning the PWA option off only stopped NEW visitors registering it, and deleting the
worker file makes it worse: a 404 fails the update check, so the old registration survives. See
item 37's fix - `tools/publish_web.sh` now publishes a self-destructing worker, permanently.
**Every "still broken" report before that fix landed was a frozen 2026-09-06 build, not a live bug.**

### BUG A - the write transfer
Compatibility applies `srgb_to_linear()` to whatever `fragment()` writes to ALBEDO and EMISSION.
Forward+ instead converts `source_color` uniforms at CPU upload. The two break even ONLY when a
source_color uniform goes straight to ALBEDO with no maths in between. Every shader here does maths,
so under Compatibility it composes in DISPLAY space and every multiplicative term becomes t^2.2.
Measured 2.09x contrast expansion, pivoting on the untinted colour - the user's S-curve exactly.

Probe, unshaded quads, LINEAR tonemap, v = 0.0667..1.0:
    ALBEDO = literal        F+ [73,102,124,141,156,170,188,213,231,255]
                            C  [12, 32, 50, 68, 85,102,128,170,204,255]
    ALBEDO = pc_out(lit)    both [73,102,124,141,156,170,188,213,231,255]   MAXDIFF 0
Fix: `pc_in()` / `pc_out()` in `src/shaders/planet_common.gdshaderinc`, recipe at lines 84-104.
`pc_s2l`/`pc_l2s` are the exact IEC 61966-2-1 curves, not `pow(2.2)` - the piecewise toe matters
precisely where the user's complaint lives. They are MACROS, not functions: `global uniform float
astro_compat;` declared inside the include collides with shaders that declare their own, and Godot's
shader parser is single-pass so an include function cannot see a later uniform.

### BUG B - the shadow pass, which is what made every measurement lie
Under Compatibility a directional light with `shadow_enabled = true` is drawn in a SEPARATE ADDITIVE
PASS, and that pass is combined with the base pass in sRGB-ENCODED space:

    C_linear = s2l( l2s(ambient) + l2s(direct) )        instead of        ambient + direct

    run                  Forward+       Compatibility
    ambient only        60, 68, 77      60, 68, 77       ratio 1.000
    direct only         83, 78, 69      82, 79, 70             1.026
    BOTH               101,102,101     142,146,146             2.163
Predicted-then-measured within 1 code at three ambient energies, nothing fitted. The single toggle is
`DirectionalLight3D.shadow_enabled`; with shadows off both renderers agree exactly.

This is why every isolated harness matched (`l2s(0) = 0`, so one term round-trips perfectly) and why
the two shaders showed different signatures: when direct dominates the residual is a FLAT offset
(hub, +22..+30); when an albedo ramp scales both together it is a CURVE peaking near v=0.2 (home).
Fix: `_no_cast_shadows` in `src/world/environment.gd`, gating the sun's and moon's `shadow_enabled`
under Compatibility, applied AT THE PER-FRAME WRITE.

### THREE WRONG ANSWERS, all confident, all measured false
1. **"The double-albedo divergence" (this file's own items 19 and 32).** MEASURED FALSE. Both
   renderers multiply DIFFUSE_LIGHT by ALBEDO exactly once, and `light()` sees the same ALBEDO the
   engine multiplies by. Specular is never multiplied by albedo in either. Items 19/32 are wrong and
   should be read as retracted.
2. **"Compatibility's ambient is 7-8x too strong; fix with `srgb_to_linear()/PI` on the CPU."**
   MEASURED FALSE. Ambient IN ISOLATION is byte-identical on both renderers. That hunt obtained
   "ambient" by differencing two runs, which the encoded blend inflates by exactly the factor it
   attributed to PI. Implemented verbatim it makes ambient-only 16x too dark.
3. **`pc_light_term` divide-vs-no-divide explains the two signatures.** Killed three times, finally
   with an explanation (see BUG B).

### THE IRON RULE THAT MADE THE DIFFERENCE
**If it needs a gain, a scale or a tuned constant to pass, it is wrong.** `compat_gain`,
`compat_light_boost` and `COMPAT_AMBIENT_SCALE` are all retired. Do not revive them - a measured
COMPAT_AMBIENT_SCALE of 0.15 takes planet GAP 46 -> 2.8 while pushing SAT GAP 0.0097 -> 0.1135, i.e.
it trades a luma error for a saturation error and calls it progress. Both real fixes above are
transfer inversions with no free parameter, which is why they held where three fitted fixes did not.

### METHODOLOGY THAT ACTUALLY WORKED, and one that did not
* **Bisect FORWARD from a harness that matches, not backward from the scene that fails.** Two rounds
  of backward elimination cleared the quality profile, fog, ambient and the whole post chain and
  still missed it, because the gate was a COMBINATION (shadow + ambient + sun) that no single removal
  isolates. Adding elements one at a time to a maxdiff-0 harness found it.
* **SCORE PER REGION, NEVER WHOLE-FRAME.** On home the ground was +0.24 saturation and the sky -0.19;
  the celebrated whole-frame SAT GAP of 0.0097 was those two errors cancelling. A whole-frame score
  would have called the successful round a regression.
* Gate per converted shader: region-masked MAE <= 2 codes, p95 <= 4, region SAT gap <= 0.01, and two
  independent captures agreeing to within 1 code.

### TOOLING TRAPS THAT COST EIGHT AGENTS A ROUND EACH - fix or route around
1. **`tools/snap.sh` cannot pass engine flags.** It appends extra args AFTER the `--` separator, so
   `--rendering-method gl_compatibility` becomes a GAME arg and is silently ignored; you get a
   Forward+ render and believe it is Compatibility. Call godot directly when the renderer matters,
   and check the `[Platform] renderer:` line in every run.
2. **zsh does not word-split an unquoted variable.** Flags held in `$flags` are passed as ONE
   argument and ignored. Write engine flags literally. (Same defect already noted in
   `publish_web.sh`'s parent-args comment.)
3. **`src/ui/title/title_screen.gd:56` auto-starts the game whenever `Director.is_active()`**, so any
   director timeline aimed at the title scene captures the IN-GAME world instead. This is why four
   separate fixes for "the start screen is black" changed nothing - they were all measuring
   `sky.gdshader` while the bug was in `title_sky.gdshader`. Use `showcase/ui_title.tscn`. An agent
   caught it by setting `zenith_color` to bright red and seeing ZERO pixels change.
4. **`environment.gd::_apply()` rewrites ambient, adjustments and the grade LUT EVERY FRAME** from
   the palette, so a one-shot Environment edit in a frozen clone is undone before the capture lands.
   Three rounds of false negatives came from this. Patch at the per-frame write.
5. **`--freeze` only zeroes the turntable** (`lineup_showcase.gd:80`); poses, hovers and sways keep
   running, so two captures of the same command still differ. Read images, do not diff them.


## 39. [2026-09-08] "I can't move after landing" was a CAMERA bug, not an input bug

Reported three playtests running: "when I landed on the first planet, I couldnt move anymore, the
move joystick just moved the camera" / "coming out of a spaceship on new planet still doesnt let me
move" / "I can move again by hitting pause and resume."

The user's first description was literally accurate and we spent two rounds treating it as figurative.

### The cause
`RocketPad._journey_arrival` plays `p.play_emote("happy")` 0.35 s after the thaw. `Player.play_emote`
calls `CameraRig.orbit_front()`, which by design tweens the camera round to a three-quarter FRONT
view - 180 - ORBIT_YAW_DEG(26) = **154 degrees** off the astronaut's facing - so the player can see
the pose. Movement is resolved against the camera heading. So for roughly two seconds after every
landing, "forward" pointed 150 degrees away from where the astronaut faced, and pushing forward
walked them backwards into the rocket.

`pause -> resume` "fixed" it because it burns time, not because it reset anything.

Measured, 1.0 s forward push, displacement along the astronaut's facing:
    delay after control returns   +0.00   +0.75    +1.50    +2.50
    before                        +3.67   +1.78    -0.99    +3.35     <- backwards at 1.5 s
    after                         +3.64   +3.69    +3.66    +3.66
20/20 positive across four planets, head_err 0.0 deg at every mark. One to two seconds is exactly a
human's thumb-planting delay, which is why every playtest hit it and no scripted test did.

### The same defect fires outside a landing
Any player-triggered emote does it: 9 of 12 pushes negative across three planets, peak heading error
154.0 deg. Fixed generally rather than with a second special case.

### THE TRAP THAT MADE A RIG-ONLY FIX A FALSE CLAIM
`CameraRig.get_planar_forward()` is NOT what movement resolved against.
`Player._camera_planar_forward()` read the live viewport camera's own basis
(`-cam.global_transform.basis.z`). **Changing the rig alone measured as a complete no-op** - the
probe printed head_err 0.0 deg while the astronaut still walked backwards. The real coupling was in
`player.gd`. Anyone touching movement direction must check BOTH.

Fix: `get_planar_forward()` returns `_fwd_saved` (the heading the player left the camera on) whenever
a cinematic - emote orbit or dialogue focus - is driving `_fwd`; `Player._camera_planar_forward()`
asks the rig instead of reading the camera. Gated on the rig owning the active camera, so
`jetpack_showcase --chase/--side` keeps its documented camera-relative behaviour. The emote camera is
untouched and still swings its full 154 deg - only the CONTROL basis was separated from it.
`LANDING_ORBIT_GRACE` (3.5 s) survives as a backstop, now normally exited by the player's first real
input (gameplay live AND `Input.get_vector` past 0.2 deflection, so a resting thumb does not count).

### Also fixed here
`camera_rig.gd`'s dialogue-focus branch slerped about an un-normalised axis: 5,579
"must be normalized" errors in a 125 s run with the intro dialogue held open. Now 0. Invisible in
normal play, which is why it survived so long.

### STILL OPEN, and only the user can close it
The second half of this bug is a TOUCH bug and no agent can test it. `TouchControls._input()` returns
early while the controls are hidden, and `_release_everything()` clears `_pointers` when the landing
cutscene hides them, so a finger already resting on the glass has no entry for the rest of its life -
`_pointer_move` and `_pointer_up` both return on `if not _pointers.has(id)`. `_adopt_late_pointer`
now adopts such a drag as a late touch-down (guarded `if id < 0` so a desktop mouse hover cannot
steer, and limited to the stick/camera roles so a resting thumb cannot fire Jump).

Every "finger" in every measurement is `debug_touch`/`debug_drag` calling `_pointer_down`/
`_pointer_move` directly - **nothing has ever exercised `_input()`**. The premise, that iOS WebKit
keeps delivering `touchmove` for a finger whose `touchstart` was swallowed, is read off two lines of
Godot source and has never been observed. USER TEST: land while holding your thumb on the stick and,
without lifting, drag. Walking = fixed. Nothing until you lift and re-plant = the adoption is not
reaching the real event path, and it needs a different mechanism.


## 40. [2026-09-11] Phase 1 (Stranded start): builder D STOPPED after two critic fails - the scrap looks like a golf tee

Per the user's rule for this phase ("If a step fails its critic twice, stop that step, write down why, and go
on with whatever does not depend on it"), builder D (scrap and economy) is stopped. It is NOT reverted: what
it built works and stays in the tree.

**What passed (critic, both rounds, measured live):**
* Scrap is on all seven worlds. home and hub now spawn 8 pickups a day, ALL scrap; zorp, bolt, fen, grig and
  vela spawn 10 a day with scrap as one of five kinds (2 scrap a day). home, hub and grig have no stardust shards.
* Picking up scrap and cleaning a trash piece both pay scrap (seen live: "Cleaned up! +9 Scrap", pill 5 -> 14,
  stardust unchanged at 40).
* The HUD scrap pill sits beside stardust at 1280x720 and at --ui=mobile 1560x720 without touching the clock,
  the bag/journal/pause buttons or the touch controls.
* Reward numbers are named and marked as first guesses for BUILD_PLAN Phase 6. Only D's files changed.

**Why it failed (round 2, blocking, item 3 "its own look"):** the pickup mesh (collectible.gd `_build_visual()`,
scrap case) and the matching litter piece (trash_piece.gd `_build_scrap()`) are a flat rounded plate plus a
~0.19-0.22 m thin vertical tube plus a small ball on top. At the real 28-degree gameplay camera it reads as a
golf tee or a marker pin, not "a bent metal plate, a bolt, a scorched panel bit". Identical on all seven worlds,
so it is systemic. The critic's suggested fix: cut the "bolt" to a stub about as tall as the plate is thick,
and give the plate a bend or a dent so it reads as torn hull rather than a coaster.

**Depends on it:** nothing functional. Phase 2 spends scrap through GameState (builder A, passed), which works.
**Also left open in D's area:** builder C's critic found the nearest scrap 18.6 m from the crash site on a new
campaign game, while the Professor says the rock scattered scrap "all over the place". A few pieces should sit
within about 6-10 m of the pad. Not done, because the step is stopped.

## 41. [2026-09-11] Phase 1 lead fixes, and what is still open at the Commons

**Fixed by the lead after the Phase 1 final check:**
* `town_hall.gd` wrote "Mayor Orbit" by hand in all six `say()` calls of the door flow. The door's
  Interactable (reach 3.0 m) sits about 0.9 m from the Professor and usually wins over his own TalkArea
  (2.6 m), so this was the name most players saw at the Commons. It now reads
  `NpcData.get_data("mayor_orbit").display_name` through `_prof_name()`.
* Fetch favors asked for scrap. Scrap is a counter (`GameState.scrap`), not a bag item, so
  `GameState.item_count("scrap")` is always 0 and such a favor could never finish. home and hub grow ONLY
  scrap since Phase 1, so every Commons neighbour's fetch was a soft-lock, and 1 in 5 fetches elsewhere.
  `favor_system.gd` `_local_collectible()` now skips scrap; Commons neighbours offer bring and deliver only.
  Probe, 60 rolls per neighbour: no neighbour asks for scrap or stardust_shard, and every bring material
  grows on a tier-1 world (moon_flower and crystal_chunk on zorp, gear_bit on bolt).
* The dormant fallback in `_foreign_material()` returned "stardust_shard", which no world grows now. It
  returns `MATERIALS[0]`.

**Still open (BUILD_PLAN Phase 4, builder I owns town_hall.gd):** walking up to the Professor at the Commons
usually opens the Town Hall door flow, not his own talk. That flow is still the mayor's job (rename your
planet, planet stats) and its lines still sound like a mayor ("Stamped, sealed and filed."). CORE_LOOP says
no mayor role. Only the name is fixed here.

## 42. [2026-09-11] Phase 2 (Bolt's project): what passed, what the lead wired, what is still open

**Passed, round 1 each:** E project system (Opus critic), N part celebration (Opus critic), F build bench
(Sonnet critic), G Bolt's project (Sonnet critic). Integration: check.sh, seven worlds and three existing
timelines clean; old saves and Director runs without `--campaign` unchanged.

**Wired by the lead after the builders (their needs_from_others):**
* `world.gd` creates ProjectSystem on every world load, before the bench. Without it E's critic measured 0 find
  markers after a reload until the first talk, and project items showed nameless in the bag.
* `npc.gd` `_refresh_marker` asks `ProjectSystem.wants_marker` first. Bolt showed "!" through every locked day
  of his project (critic captures c06-c09b).
* `catalog.gd` `random_reward_decoration` skips items that carry "project". The critic measured a project fix in
  the favor reward pool, with the campaign off too.
* `inventory.gd`: no Drop for project items and parts (Drop destroyed them); a part shows a disabled "Fit it at
  the bench".
* `conversation.gd`: a favour ready to hand in goes before the project, or a Phase 1 campaign save loaded by this
  build would have it held for three game days. E's one exception is accepted: `handle_conversation` returns
  false when a delivery gift for that neighbour is in the bag, so the delivery branch must stay first.
* The `part_fitted` sound: take A "power-up" (`tools/gen/audio/sfx.py`): a latch, a rising hum, one warm chord,
  the comms two-beep, a sparkle. 3.2 s, -3 dBFS peak, -18 dBFS RMS (friendship_up is -18.8). No mallets. Takes B
  and C stay as code for the user to pick by ear (`PART_FITTED_TAKE`).

**The lead's wiring failed its critic twice, so that step stopped (the user's rule for this phase).**
* Round 1 (Opus critic) FAILED the `npc.gd` "!": `wants_marker() == 0` hid it while a talk would still hand in
  a ready favour or open a gift (cases E3, E7, E9). The round-2 fix `_favor_ready_here()` makes the same two
  checks conversation.gd makes before the project. It PASSED in every state, and three traps correctly stay
  hidden (a gift not in the bag, Bolt's own favour half done, a gift Bolt gave for Zorp).
* Round 2 FAILED a new change: `shop_panel.gd` `_try_fit` closing the bench after a fit (added because the
  unbroken play-through found the celebration waits until the bench is closed). A finger tap worked. With E,
  Enter or pad A the bench re-opened one physics frame later, invisible, with input blocked until a blind Esc
  (4 of 4 keyboard runs). The chain: `confirm_dialog.gd:123` answers Yes on `is_action_just_pressed("interact")`;
  `close_panel()` drops the modal count in that frame; `player.gd:369-381` held `interact_pressed` false while
  the modal was open, so on the next physics frame the still-held key reads as a new press and
  `player.gd:487-488` interacts with the bench again; the re-open lands inside the 0.18 s `UIStyle.pop_out`,
  whose end callback (`ui_style.gd:254-257`) hides the panel regardless.
* **Reverted.** The bench stays open after Fit, as builder F's critic passed it; the celebration starts when
  the player closes the bench. The critic measured two fixes (all four input paths, check.sh 46/46), NOT
  applied: (a) in `_try_fit`, wait while `Input.is_action_pressed("interact")` before `close_panel()`;
  (b) the root cause, in `player.gd` `_on_modal_changed`, set `_interact_was_pressed =
  Input.is_action_pressed("interact")`. (b) also covers any other menu closed with E next to an
  interactable - for example a talk closed with a held E beside the NPC may re-open it (not tested).
* Latent: `UIStyle.pop_out` hides its control in an unconditional end callback, so any `open_panel()` within
  0.18 s of `close_panel()` gives an open, invisible, input-blocking panel (`item_grid_panel.gd:537-568`). A
  defensive fix kills the running close tween in `open_panel`.

**Lead decision:** on the Compatibility renderer the space-sky navy (#131334, S 0.61-0.62, about 27% of the
frame) fails "no dominant swatch above S 0.60" by 0.01-0.02 in the celebration's two shots. Gameplay frames and
Forward+ pass. It is the same miss as Phase 1 R's 0.60-0.63. Accepted for now: the sky is the shipped look and
the miss depends on how much sky a shot frames. A later art pass may lower the Compatibility sky saturation.

**Still open:**
* One part opens no new world. Tier 2 needs 2 parts and Phase 2 builds only Bolt's, so BUILD_PLAN's "the picker
  shows a longer range" is not true yet: it shows "Rocket parts 1/5" and Fen and Grig still need 2. Zorp's part
  comes in Phase 3.
* The whole Bolt loop now runs unbroken in ONE Director run (scratchpad `phase2/loop/bolt_loop_run4.log`, 299 s,
  0 errors): 4 real flights through the pad picker, 3 game days, the find markers, the build at the bench (11 ->
  5 scrap), the placement in the ring, the part, the fit (11 -> 3 scrap), the celebration, finish stage 0 -> 1,
  "Rocket parts 1/5". The trick was a probe that taps only when the dialogue has finished typing; fixed-interval
  taps skip lines mid-type (40 chars/s). Still synthetic: Director taps, teleports instead of walking, and
  day_count and scrap set by the Director. No human has timed it.
* `deco_store.gd:204-208` builds the Cosmo Depot window display from `items_of_kind("decoration")` with no
  "project" filter. Bolt's regulator stays out only because its footprint (0.9) is over the 0.85 cutoff; a
  Phase 3 project decoration with a smaller footprint would show in the window (display only, not buyable).
* The disabled "Fit it at the bench" hint in the bag is pale grey on a pale pill; its contrast was not measured.
* Time is an estimate, not a timed run: the day gate alone is 2 x 600 s = 20 min; the Bolt critical path is about
  27 min. "About an hour" is plausible only with in-between play.
* After the part, Bolt offers random favours again (Phase 4, builder J).
* Celebration: the camera rig's near-geometry fade ghosts props during the shot (a see-through dome in the
  integration's close-up), and camera_rig.gd has no public way to suspend it. No fist-pump pose exists
  (astronaut_model.gd). In the Fly-gateway layout the FLY plate covers the helmet; the bench's spot, 6.47 m from
  the pad, avoids that layout.
* The place ring is hard to see from 6.5-8 m on Bolt's 10.5 m planet. The placement ghost sits 3.35 m ahead of
  the player (`PlacementController.FORWARD_DIST`), leaving 0.65 m of slack inside Bolt's 4 m ring.
* The bench's palette and triangle budget were not measured.
* `item_grid_panel.gd` reads the empty-state text before `ShopPanel.open()` sets its mode; F worked around it in
  shop_panel.gd. The real fix is in the shared base class.

**The desktop save was not protected.** Builders and critics were told never to write it, and to copy it aside
and restore it if they had to. On 2026-09-11 it was still deleted and rewritten several times: a Director run
that goes through the title with `--new-game` deletes it (`title_screen.gd:89`), and several agents restored
from backups that were already test data. No copy of the user's pre-Phase-1 desktop save survives; every backup
in scratch is a day-1 campaign test save. Lesson: an agent run must not share the real user folder at all. Point
`HOME` at a scratch folder or rename `config/name` in a scratch copy, as the ship check did, and never go
through the title in a shared folder.

## 43. [2026-09-11] One voice for everyone (doot C), and a clean rocket until the asteroid hits

**The user, after listening to the three doots:** "I like the third doot voice and let's have all neighbors have
that voice too." And: "in the intro cutscene the rocket should be normal / clean looking before it hits the
asteroid, then it becomes rusted and dirty." Both built by one builder each, both PASSED round 1.

* **V (voice).** Flavour C ships as `doot_c_0..3` (4 pre-baked +-3% pitch variants, `voices.py`
  `render_doot("c")`). Zorp takes the doot path too, behind one const `ZORP_COMMS_ENABLED := false` in
  `audio_manager.gd`; his comms scheduler, his five `voice_zorp_*` files and the key-up/down/over/bed framing
  all stay on disk, so one line brings his radio voice back - the critic flipped it live and got exactly his
  old gesture back, with every other speaker still dooting. Loudness: A -20.681 LUFS, C -20.717 LUFS, a
  0.035 dB difference, so `DOOT_DB` stays at -9.0 with the measurement in the comment instead of a guessed
  number. The critic re-rendered all four files from `voices.py` and got byte-identical SHA-256.
* **I (intro).** The borrowed rocket is painted clean (stage 4) from the start of the shot through the whole
  cruise, then steps down one finish stage at a time to `CampaignData.finish_stage()` across the contact
  flash's own 0.28 s life, starting at the hit (7.02 s). Rust is first readable 0.16 s after the hit and the
  hull is fully rusty by 0.36 s. Every exit path ends at finish 0: natural end, a skip before the hit, a skip
  after it, a skip *during* the step, and leaving mid-shot. The Opus critic diffed the camera trace against a
  rebuilt pre-change binary: max difference 0.00000000 over 260 frames on both renderers, so nothing else in
  the shot moved.

**Lessons:**
* **A discrete visual swap timed with a VFX cue is not automatically hidden by it.** The contact flash is a
  small quad at the contact point, not a wash over the hull, so the first attempt - one instant swap on the
  flash frame - was a measured, visible pop. Stepping the change across the VFX's own lifetime reads as the
  hit doing the damage.
* `--resolution` is silently ignored when `--write-movie` is used (now in CLAUDE.md's tooling traps).

**Open / watch:**
* `RocketModel.refresh_finish()` is connected to `campaign_changed` and `rocket_parts_changed` and repaints to
  `CampaignData.finish_stage()`. Neither fires during the shot today (both come from `reset_new_game()` and
  `from_dict()`, which run before the world is built), but the intro's clean paint is a one-shot with no
  re-assert: one such signal during the shot would snap the hull rusty mid-cruise.
* `showcase/audio_board.gd` `play_voice_blip("alien")` now plays a doot instead of Zorp's comms gesture
  (`LEGACY_VOICES` maps alien -> zorp). Expected, not a bug.
* `voices.py` `SHIPPED_VOICE_NAMES` still lists `voice_zorp_*` and the comms framing files, so a full
  `build_all --voices` keeps regenerating them. Deliberate while one const can bring Zorp's voice back.
* Neither change has been proven with a real finger, a real key press, or on the phone.

## 44. [2026-09-11] Three phone reports, diagnosed: silent web audio, where the heat really is, and neighbours stuck on their own buildings

Three investigators plus an Opus skeptic who re-measured every claim that decides what gets built. The fixes
are being built separately; this item records what was MEASURED.

**1. The web build is silent for everyone - not the phone, not iOS, not the ring switch.**
An analyser tap on `ctx.destination` in the SHIPPED build (a93925d, local export byte-identical to the live
page) read peak 0.000000 at 20 s and again at 83 s, while the AudioContext said "running" and the title music
was "playing"; a positive-control oscillator at gain 0.03 in the same graph read 0.029999999. The NATIVE
desktop build is loud: `--write-movie` of `showcase/ui_title.tscn` wrote PCM peak 19520/32768 (-4.5 dBFS),
959,487 of 960,000 samples non-zero. The break is WEB-ONLY.
Cause, from the live edge list: at startup `audio_manager.gd:110-115` adds the Music and SFX buses. The
exported `index.js` `Bus.connect()` begins `this.getOutputNode().disconnect()`, and the engine re-points
Master's output into each new bus, ending at Master -> SFX -> Music -> Master, a closed loop with NO edge to
`ctx.destination`. The only node still reaching the destination is the software-mixer AudioWorkletNode, which
carries nothing while `audio/general/default_playback_type.web` is 1 (Sample). PROOF BY REPAIR: reconnecting
Master to the destination in the live page took the peak from 0.000000 to 0.495.
Measured FALSE, do not chase: "music is stuck at -40 dB because volume_db after play() is ignored" (the live
music sample's gains are 1.0/1.0; an SFX sample read 0.501 = -6 dB); "the title track plays once because loop
is false" (the source is replaced every 33 s); "the AudioContext never unlocks" (measured suspended -> running
on a real click, currentTime advancing 1.003 s per second).
Open, untested: the SFX bus's output goes into the MUSIC bus, not Master, so the SFX slider may be scaled by
the music slider.
**Item 34's audio conclusion was WRONG.** It blamed the browser ("iOS suspends an AudioContext") and verified
only that the unlock shim captured a context - never that a sound came out. The shim works and still ships; the
silence had a different cause and sat undetected for five days. The rule that follows is now in CLAUDE.md: put
an analyser on `ctx.destination` and read the peak, with a positive control, the same way we look at the picture.

**2. The heat is not the flights, and nothing accumulates.**
All numbers are this Mac under gl_compatibility at 1280x720: ratios transfer to a phone, absolutes do not, and
NOTHING was measured on a phone.
* The flight cutscene is the CHEAPEST thing in the game: 1.82 ms/frame and 49 draw calls, against 4.10 ms and
  240 draws standing on home - 0.44x gameplay cost. The user's theory that flights cause the heat is wrong.
* Planet hops leak nothing: 8-10 hops through the real `JourneyState.swap_scene` return node counts exactly
  (hub 1704, zorp 833, bolt 857), orphans 0, texture memory flat, static memory flat after the first revisit.
* The largest single item in the frame was the REALTIME SKY RADIANCE cubemap, re-rendered at 256 px every frame
  to feed an ambient weight of 0.10 (`environment.gd:452-453`, `:460`). INCREMENTAL measured -1.063 and
  -1.053 ms on hub (22.6% and 22.2% of the frame), twice, tightly; an earlier run's -1.48 ms did NOT reproduce.
* Loads are bursts, not a drain: first-ever hub 1022-1324 ms; repeats 399.8 ms cold, 165.6 ms with the geometry
  cache warm. `Planet.prebuild()` is called from exactly one place (`journey_state.gd:366`), so only a rocket
  arrival gets a warm cache; a save load or a Director load rebuilds everything.
* `planet.gd:549` scatters props inside `prebuild()` and `planet.gd:574` scatters the identical deterministic
  set again in `_build()`: hub 38-42 ms, zorp/bolt 6-12 ms of duplicated work per prebuilt visit.
* First-visit shader compiles are the biggest stalls: hub first frame 1879 ms, then 221, settling at 16.6 ms; a
  repeat visit's first frame is 69 ms. Under Compatibility Godot writes NO shader cache, so whether the phone
  re-pays this on every page load is unknown - and it is the best candidate for heat that BUILDS while
  quest-hopping, which is exactly what the user reports ("everywhere, it builds up").
* Not levers: shadows are already off under Compatibility (`_no_cast_shadows`), glow and SSAO off, fog
  0.01-0.05 ms, and the per-frame environment rewrite is 0.013-0.018 ms - below the noise floor.
* The remaining big lever is `run/max_fps` 60 -> 30 (`project.godot:17`): measured to land frames at exactly
  33.3 ms, halving frames rendered, at the cost of visible smoothness on pans and flights. The user chose to
  try the free fix first (2026-09-11).
* `platform.gd:104` printed "3D scale 0.5" while `platform.gd:96` set 0.75 - one string that misled two briefs
  and an investigator.

**3. Five hub neighbours are stuck on their own buildings, not just the Professor.**
`npc_data.gd` gives mayor_orbit home_offset_m 3.2 with home_side_m 0.0 - dead centre on the Town Hall's door
axis - while `town_hall.gd:59`'s step_block spans 2.93-4.05 m out along it, and `building_base.gd:415-426`
bakes every footprint shape into one StaticBody3D "Footprint" on layer 7, which `npc.gd:81` carries in its
collision mask. His home spot is inside the steps. `npc.gd`'s `if planet.surface_distance(r, home_dir) <
OWN_ZONE_M: continue` then skips avoidance of his OWN building entirely, and `_spot_blocked` never consults the
real collider. Measured over 75 s: Footprint contact in 150 of 150 samples, walking in place 13-14 s at a
stretch, longest freeze 34.5 s, about half a metre travelled. Stella freezes 18 s, DJ Nova 33 s, and Pip and
Pop never move at all - their home spots are blocked too. 40-60% of every hub NPC's wander disc is rejected by
`_spot_blocked` (pip 103/200, pop 119/200, stella 92/200, mayor_orbit 121/200, dj_nova 80/200), partly because
`planet.gd:1143-1147` discards each reserved zone's real radius and `npc.gd` falls back to a flat 2.6 m for
buildings that reserve up to 7.0 m.

**Trap found here (now in CLAUDE.md):** `--skip-title` makes `title_screen._auto_start()` call
`reset_new_game()`, which resets `current_planet_id` to "home" AFTER the Director parsed `--planet=`, so a
"hub" test silently measures the empty home planet. Run `res://src/world/world.tscn -- --planet=hub` instead.

### Fixed 2026-09-12, each with an independent critic

* **Web audio (PASS round 1).** One line: `audio/general/default_playback_type.web = 0` (Stream) in
  project.godot. Two web builds exported from ONE tree differing only in that section: title music peak at
  `ctx.destination` 0.000000 without it, 0.509995 with it (builder) and 0.570404 (critic, whose analyser sat
  IN SERIES on every edge into the destination, so an engine disconnect would kill the tap too); positive
  control 0.030000 in both graphs. In-game SFX measured as well: footsteps 0.286774, UI tick 0.354691. Both
  sliders scale the peak, and SFX is NOT scaled by the music slider despite the SFX -> Music edge (Music at
  0%: music 0.000000, footsteps still 0.286774). Native is unchanged (PCM peak 19520/32768, RMS -18.09 dBFS;
  the builder's 32760 figure did NOT reproduce - do not quote it). Latency identical in both builds:
  baseLatency 5.33 ms, outputLatency 24 ms. `audio_manager.gd` needed no change.
  STILL TRUE AFTER THE FIX: the bus graph is still severed (the sever is logged in the fixed build too);
  Stream routes around it through the worklet mixer, so anything that opts back into Sample playback on the
  web would be silent again. The CPU cost of Stream mode is unmeasured (the browser pane runs at ~1 fps), and
  nothing is proven on the phone.
* **Sky radiance (PASS round 1).** `sky.process_mode = PROCESS_MODE_INCREMENTAL`. Re-measured saving about
  0.7-0.8 ms/frame on hub and home - smaller again than the 1.06 ms that replaced the first 1.48 ms, so quote
  0.7-0.8 ms. Pictures agree to <= 0.007 RGB (0-255) and <= 0.003 top-1% luma across bolt and home, day and
  night, both renderers. A confound found on the way: `night_life.gd` uses an unseeded RNG, so fireflies and
  shooting stars alone move a night capture by up to 82 code values between two runs of the SAME sky mode -
  freeze NightLife before comparing night frames.
* **Stuck neighbours (FAIL round 1, PASS round 2).** Round 1 moved two home offsets (mayor_orbit 3.2 -> 4.6,
  stella 3.0 -> 3.6) and the contacts stopped - but the critic measured the Professor, Pip and Pop travelling
  0.00 m in 95 s: they had stopped hitting the building by not moving at all, with `_path_blocked` rejecting
  100% of the spots `_spot_blocked` allowed. Round 2 fixed the class in `npc.gd`: `_resolve_home_dir` now
  pushes a bad home offset clear of the real Footprint (`_clear_of_own_building`), and `_pick_wander_target`
  is a two-pass picker with an away-from-the-building sampling bias whose relaxed pass still refuses water,
  the own building and props (0.35 m buffer) and only drops the soft reserved-zone test. Critic's own 95 s
  soak on hub, campaign off AND on: all five neighbours 0 Footprint contacts, 0 walk-in-place frames, 18-34 m
  travelled each, against a pre-fix baseline it reproduced itself (pip/pop 0.00 m; mayor 9009 contact frames
  and 56.9 s standing on the steps). Decisive metric - accepted spots whose capsule really overlaps a
  building, per 200 picks: 18/17/54/68/92 before, 0/0/0/0/0 after, and still 0/0/0/0/0 with the OLD bad data.
  Open from this round: the npc_data.gd offset edits are now redundant (the code clears a bad offset by
  itself); the Professor's pass-0 disc is 199/200 blocked so he lives on the relaxed fallback, and tightening
  that pass later would refreeze him (first cause is prop and reserved radii, `planet.gd`); the relaxed pass
  checks only the NPC's OWN building, not others; `home_offset_m = 0.0` still drops an NPC below the planet
  (pre-existing); Pip and Pop's pushed-out home sits 0.06 m inside a prop circle; `_pick_wander_target` costs
  804 us/call for the Professor against 264 us before; `_own_building_checked` latches on its first lookup and
  is safe only because `world.gd` spawns NPCs before buildings; and the Town Hall's own front-yard decor (two
  lanterns, a noticeboard, a flagpole) shares the exact band its steps occupy.

---

## 45. [2026-09-12] Planet loads did duplicated work: the prop scatter ran twice, and only rockets warmed the cache

Item 44 section 2 measured two wastes in every planet load. Both are now fixed, each with an independent
critic (round 1 FAILED on a real bug; round 2 PASSED 9/9/9/9). All timings are headless on this Mac; the
pictures were scored on both renderers. Nothing was measured on a phone.

### The measuring instrument came first, and it is kept

`showcase/planet_perf.tscn` -> `src/planet/showcase/planet_perf_probe.gd`, inert without `--planetperf`.
It builds the REAL `src/world/world.tscn` at `/root/World` and reports, per visit, `prebuild_ms`,
`world_ms`, `PlanetProps.populate_calls` (a new static counter) and the geometry-cache size, across four
phases: COLD_NOPRE (a plain world load), COLD_PRE (a rocket arrival), WARM_NOPRE, WARM_PRE. `--pp-dump`
writes every prop transform, every MultiMesh instance transform and the registered prop dirs/radii at full
float precision.
Two properties that make it evidence rather than decoration, both verified: the dump is BYTE-IDENTICAL
between two runs of the same tree, and auto-generated node names (`@MultiMeshInstance3D@964`) are replaced
by the child's index, because that counter is process-wide and would otherwise differ on ~1800 lines while
the geometry was identical.
THE TIMING TRAP THAT BIT THREE AGENTS: cross-run absolute timings drift 3-25 ms with machine load, the same
size as the effect being measured. Use the paired in-process control `world_ms(COLD_PRE) - world_ms(WARM_PRE)`
(immune to load, both halves in one process), or take the noise floor from the phases whose code did not change.

### Waste 1: props were scattered twice per cold-cache prebuilt visit — fixed by handing them over

`prebuild()` scattered props on a throwaway planet (the ground bake needs their contact-shade pools) and threw
them away; `_build()` then ran the identical seeded scatter again. It now detaches the finished `Props` and
`Collectibles` nodes into a static `_props_cache` — at most ONE pending hand-off — and `_build()` adopts them.
Bit-identical by construction: the live planet gets literally the same nodes.
Measured, critic's own numbers, medians of 5: `world_ms` on COLD_PRE hub 195.4 -> 153.2, zorp 116.8 -> 103.3,
bolt 113.8 -> 105.4. Noise floor from code-identical phases: 0.3-1.8 ms, so the effect is 8-42x the floor.
The scatter dumps are `cmp`-identical for hub, zorp and bolt. `populate_calls` is 1 per visit, was 2.
**Correction to the original brief:** only COLD_PRE was doubled. WARM_PRE was already 1, because `prebuild()`
early-returns on a cache hit.
**Honest framing:** this removes the prebuild PENALTY. Before, a rocket arrival did MORE total work than a
plain load (hub 432 vs 385 ms); now COLD_PRE total ~= COLD_NOPRE total. It does not make a cold load cheaper.

### The hand-off carried player state, and that FAILED round 1

`planet_props.gd:2408-2412` builds a Collectible node only `if not Collectible.was_picked_today(...)`, which
reads `GameState.picked_collectibles` and `GameState.day_count`. A prebuild taken under different player state
parks a WRONG `Collectibles` node, and `_build()` adopted it. Measured end to end through the real title, a
real save and the real `_continue_game()` (zorp, `zorp_0/1/2` picked on day 1): 10 live collectibles instead
of 7, every picked one back. Quit to title, press Continue, farm them again.
THE FIX IS A STATE STAMP, NOT A RE-FILTER. The hand-off stores `day_count` and a duplicated copy of that
planet's picked list; `_build()` refuses a mismatched hand-off, frees it, and scatters fresh. A re-filter could
only REMOVE collectibles, and the second direction runs the other way: with the day rolling over between
prebuild and build, collectibles that should respawn were MISSING (measured 7 where 10 was correct). Both
directions were reproduced with paired negative controls — the fix turned off brings both bugs back.
`_geo_cache` is deliberately still reused on a mismatch: the mesh does not depend on player state. Cost of
landing on the mismatch path: +30-60 ms over a warm load, because a planet's worth of prop nodes is `free()`d
synchronously, still far below the ~200 ms of a cold mesh build.
Out-of-tree orphans do not free themselves: without the `tree_exiting` hook an unclaimed hand-off leaked 569
ObjectDB instances. The parked nodes are held OUT of the tree on purpose — in the tree, a whole planet's worth
of solid props would sit in the shared physics space during the cruise (measured 65 bodies, 0 in a space while
pending, 73 after adoption).

### A real key collision found on the way, and closed

`title_screen.gd:178-182` builds the title globe from `home.tres.duplicate()` with `radius = 16.0` and
`collectible_count = 0`. The duplicate's empty `resource_path` makes `PlanetData.effective_radius` return 16.0
verbatim, and `HOME_RADII[2]` is also 16.0 — so a player with a level-2 home shared a geometry-cache key with
the title globe, while collectibles DO change the bake (`_collectibles()` calls `register_prop` for every one,
picked or not). Measured before: both keys `home|11|6|16.000`. `collectible_count` is now part of `_geo_key`;
after: `...|16.000|8` vs `...|16.000|0`. The symptom was never seen on screen — the globe is built before any
prebuild runs — so this is closed at the key level only.

### Waste 2: only rocket arrivals warmed the geometry cache — now every entry does, but read what it buys

`Planet.prebuild()` had exactly one caller (`journey_state.gd` `prewarm_destination`, reached from
`rocket_pad.gd:1042` and `space_travel.gd:1002`). `SceneRouter._transition_to` now prebuilds
`GameState.current_planet_id` after the fade-out, before every entry into `world.tscn`.
**IT DOES NOT MAKE A LOAD SHORTER.** Measured: hub cold world build alone 413.8 ms; prebuild + build
245.7 + 156.2 = 401.9 ms. Both halves happen behind the same solid fade. What it buys is that the cache is
left warm, so a second load of the same planet in one session is ~2.4x faster (hub 385 -> 161 ms), and every
entry point now gets the warm path instead of only rocket arrivals.

### THE TITLE SCREEN MUST NEVER PREBUILD — a round-1 idea that measured out as a regression

It looked like free CPU time. Three measurements killed it, and the reasoning is written into
`title_screen.gd` so nobody re-adds it:
1. It runs BEFORE `SaveManager.load_game()`, so it scatters against an empty GameState — this is what caused
   the collectible bug above.
2. It is wasted for any upgraded home: `effective_radius` reads `GameState.home_planet_size`, still 0 at title
   time. Measured title-time key `home|11|6|12.000|8` against the post-load `home|11|6|16.000|8`; the whole
   ~232 ms bake is thrown away.
3. THE PREMISE WAS WRONG. "Idle" is not the same as "still". The title is ANIMATING — orbiting rocket, turning
   globe, panning camera, sparkles — and the load it would have saved sits inside a solid black fade where a
   stall is invisible by design. Measured prebuild stall: home 232.4 ms, hub 243.0. So it moved a ~240 ms
   freeze OUT of the screen where it cannot be seen and INTO the one where it can.

### NAMING A `class_name` INSIDE AN AUTOLOAD LOADS IT FOR EVERY SCENE IN THE PROJECT

Writing `Planet.prebuild(data)` directly in `scene_router.gd` (an autoload) made that autoload's script resolve
the whole 68 KB `Planet` class at parse time for every scene, and the forced early load leaked **331 ObjectDB
instances, 29 resources still in use and 64 RIDs across 4 RendererDummy types** in
`showcase/characters_lineup.tscn` — a scene with no connection to SceneRouter. It made `tools/check.sh` FAIL.
Reproduced 3/3 by a builder and again independently by a critic; both clean trees report nothing. The fix is
to call it dynamically: `load("res://src/planet/planet.gd").call("prebuild", data)`. The same reference inside
a plain scene script (not an autoload) does NOT leak.

### Ruled out, so nobody repeats the work

**`_build()` must NOT write its freshly built mesh into `_geo_cache`.** It looks free — the title globe would
warm the home cache for nothing — but the title builds from a MUTATED duplicate, and the key cannot see every
mutated field. It would hand a level-2 home player the title globe's collectible-free ground bake.

### Not caused by this change, and now settled

Director play-throughs do not render identically twice. Measured same-tree run-to-run divergence: pristine
BEFORE 0.13-1.11%, AFTER 0.05-0.18% on named captures; on a 25 s movie BEFORE 0.58-1.09% and AFTER 0.62-1.34%,
not compounding, frame counts identical. A contributing cause, pre-existing: `collectible.gd:42` and
`trash_piece.gd:34,52` draw their bob/spin phase from the UNSEEDED global `randf()`. Freeze or seed those before
pixel-diffing a play-through.

### Still open

* Nothing here was measured on a phone, on the Compatibility renderer's timing, or on the web build.
* An unclaimed hand-off survives an unrelated world load (measured: hub's ~80 nodes stayed resident through a
  full zorp visit). Correct, bounded to one planet, and freed at exit — but it is a whole planet held in memory.
* `prebuild()` is a landmine if ever called from a node's `_ready`: `loop.root.add_child(tmp)` fails with
  "Parent node is busy setting up children" and every prop placement then returns identity. Both current call
  sites await first; nothing guards it.
* During prebuild the scratch planet joins group `"planet"`, so for one synchronous frame two planets sit at
  the origin and `PlanetProps.planet_under()`'s nearest-planet fallback is a coin flip. No path exercises it.
* The state stamp covers the one player-state read that exists in the scatter today. Nothing enforces that a
  future addition to the scatter declares itself.

### TRIED AND REVERTED: warming the destination's shaders during the cruise

Built, measured, failed its critic, and REMOVED. Recorded so nobody builds it again without beating these
numbers. The idea: under Compatibility Godot writes no shader cache, so the first arrival on a world pays a
large one-shot pipeline compile; `prebuild()` now parks the destination's real prop MeshInstance3Ds out of the
tree for the whole cruise, so rendering them once into an offscreen SubViewport during the flight should
compile those pipelines while the GPU is idle (the flight is 1.82 ms/frame against gameplay's 4.10).

IT WORKED, AND IT STILL WAS NOT WORTH IT. The mechanism is real: attaching the departure planet's Environment
to the warm-up viewport (so the compiled VARIANTS match) cut the warm-up's own cost from 316-319 ms to
194-200 ms for the same gain, which is the proof that variants are what matter. Arrival frame 0 improved and
the stall did NOT merely move to frame 1 - the critic checked the first 40 frames. But:
* IT RELOCATES THE STALL, IT DOES NOT REMOVE IT. Critic's medians: hub arrival f0..f5 1043.9 -> 849.8 ms
  (-194) against a seam cost of 140.2 -> 322.5 ms (+182). Zorp arrival 498.5 -> 286.6 ms (-212) against a seam
  cost of 142.6 -> 377.1 ms (+235), ranges non-overlapping - on zorp it ADDS MORE THAN IT SAVES. The held seam
  frame grows from ~1 frame (~150 ms) to ~3 frames (~360-410 ms), and the flight itself gets 0.22-0.27 s longer.
* IT WARMED WORLDS THAT WERE ALREADY RESIDENT. `_geo_cache` is written only by `prebuild()`, never by
  `_build()`, so the world loaded at process start is never in it: every flight HOME did the whole warm-up for
  nothing (+41 ms at that cut, and the home arrival measured worse in both runs). Fixable with a set of ids
  already drawn this process - but it does not change the relocation arithmetic above.
* THE CLAIM "A REVISIT COSTS 18-20 ms" DID NOT REPRODUCE, and it is the number a player decision was resting
  on. The critic could not get it by any route: a second zorp arrival by rocket in the same process was
  395.2 ms against 487.4 for the first, only ~19% cheaper. The GPU compile IS one-shot (home's second load
  206 ms against 3044 ms at startup), but the residual arrival cost is 200-400 ms of CPU SCENE BUILDING, not
  20 ms. "Shader compiles do not accumulate" is therefore UNPROVEN, and the phone-heat question stays open.
Verdict: a wash on total work, a new cross-file coupling, and its motivating premise unproven. Reverted to the
state that passed the items 1-2 critic. Anyone retrying it must measure the SEAM cost, not only the arrival.
