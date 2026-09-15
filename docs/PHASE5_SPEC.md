# Phase 5 spec: "Home is here"

Status: the contract for the Phase 5 builders, written 2026-09-14 by an Opus design panel (three proposals - story,
art, systems - two judges, one synthesis) and reviewed by the lead. Builders do not edit it; the lead amends it with
the measurement that justifies a change. Section numbers (§1-§10) are cited by docs/BUILD_PLAN.md Phase 5.

**Open questions, defaults applied until the user says otherwise (2026-09-14):** the ending plays at NIGHT (the user chose this on
2026-09-14; see §0); saves from before the campaign keep the white
rocket; the ending saves the game itself at its four checkpoints (never in a Director or dev-menu run).

**Base: STORY** (the judges' totals tied; it wins on the phone: the loss set up, friends in frame, a gentle choice), grafted with SYSTEMS's save and heat rules and ART's readability gates.

**Departures (lead amends BUILD_PLAN):** the send-off stays in the Commons scene like `CrashIntro`, not `space_travel.*`. Dropped: forced nightfall, the picker limit, the pad-Use re-ask and board work (not needed).

## 0. Lead amendments after build round 1 (2026-09-14)

These replace anything below that says otherwise. Each comes from a measurement in round 1.

* **L1 rock palette (§9 L, L1 checklist item 2).** The absolute "rock S <= 0.20" cannot pass at dusk or night with any
  palette: a plain grey control rock in the same frame measured S 0.35 at dusk and 0.52 at night from the sky and fill
  tint, and the noon frame's S p90 is 0.79 with or without the rock (the sky). New gate, per region at noon, dusk and
  night: the rock's S exceeds a same-frame grey control rock by at most 0.20 (measured +0.19 / +0.03 / +0.04); the rock
  adds at most +0.02 to the frame's S p90; at most 1% of rock pixels blown (V >= 0.95); lit-face luma, as the MEAN of
  the rock's brighter half, 0.30-0.60 (measured 0.558-0.574 at noon on frames the critic judged a friendly grey; the
  first wording said "median", a lead error: the toon ramp's flat top makes the median 0.683 at noon, 0.40 at night).
* **L1 break-up (L1 item 4).** Seam openings between touching chunks are 0.5-1.5 m from 0 to 0.4 s, then the chunks
  shrink. Where zig-zag seams interlock, nearest vertices stay 0.27-0.30 m apart; that is accepted, because the chunks
  keep the whole mesh's vertices exactly.
* **L2 scene gates (§7, §9 L).** Every absolute scene number becomes relative to the SAME camera path and hour without
  the finale objects (rock, rocket effects, shower): frame S p90 at most +0.03; the crowd crop's p05 within +-0.03 of that
  control; the sky part at most +0.7 ms and +40 draws over the control. The harness measured the Commons sky view at
  4.1-4.3 ms with and without the shower; §7's 2.5 ms came from the space-flight scene, a different baseline.
* **The ending always plays at night (the user, 2026-09-14: "go with the always switch to night option").** When
  the Commons loads at finale stages 1-3, the hour is set to night (21:00) before the first frame is drawn, and the
  clock holds there through the meeting, free roam, the send-off and the gift; it runs again after DONE. The meeting
  (K2) owns the switch. Every "noon, dusk and night" check in K2, L2 and G becomes night only. This replaces the
  "whatever time it is" default in the status note above.
* **K call framing (K items 6-7).** The gold rocket in frame applies to the Call that follows the fifth part's
  celebration, at the bench beside the rocket. A Call started by loading a stage-0 save plays wherever the astronaut
  stands, radio beside them: from a title-spawn load the rocket was behind the camera, and two rounds could not swing
  the rig onto it reliably for what is an edge case.
* **L1 accepted (2026-09-14, lead).** After the "mean" correction above, every L1 item has passed an Opus critic on
  the shipped file (sha1 2cf163a8): rock S over a grey control +0.19 / +0.03 / +0.05, frame S p90 +0.003 at most, 0%
  blown, lit face mean 0.558-0.574 at noon and 0.351-0.360 at night, seams 0.512-1.485 m, hashes equal, 800 triangles,
  +1/+2 draws. No rebuild.
* **HEAT-LOAD re-gated (2026-09-14, lead).** "The warm-up frame ends within 2.0 s of the scene change" cannot be met
  from shader_warmup.gd: world build and the first draw already take ~2.2 s before it starts, warm-up on or off. The
  player-facing gate is: no frame over 100 ms is visible once the load fade starts lifting (measured: on, worst
  18-20 ms; off, a 1045-1057 ms frame at fade 0.88). First dusk: the lamps, sky globes and moon are warm (18:30 +4.3 ms
  against +45.6 off); the last +20.6-22.6 ms at 19:30 is night_life.gd's firefly preprocess (120 simulation steps on
  the first emit), which is not a shader and not this file - accepted, and filed for heat wave 2.
* **DEV item 2.** "With finale_state.gd renamed, the rows grey out" becomes: with BOTH finale files renamed, the game
  boots and the Finale rows grey out; with a stub finale_state.gd missing one §10 function, only that row greys out.
  Renaming finale_state.gd alone made finale.gd fail to compile; world.gd now checks the loaded script before calling
  attach.
* **M1 skiff.** "Dome <= 0.35 x drum width" means the dome's HEIGHT (built 0.21x). The spec's colours rendered off-gate
  (navy #1b2450 at S 0.91; slate #6f7fa8 went royal blue in shade), so the skiff ships slate #7f8699, navy #62667a and
  gold #b8a06e, with every dominant swatch S <= 0.55 on both renderers.
* **M2 chase.** Chase offsets scale by model_height() / 3.2 (exactly 1.0 for the rocket); the "gate" is the pad's
  existing ground-clearance clamp.

## 1. State machine (K)
`GameState.flags["finale_stage"]`, read through `int()` (JSON returns floats); inert unless `CampaignData.gates_on()`.

| stage | written, then checkpoint | on a load or arrival |
|---|---|---|
| 0 NONE | - | 5 parts: the call after calm (on the Commons, write 1) |
| 1 CALLED | call's last box | Commons: crowd staged, meeting after calm. Elsewhere: toast "Everyone is waiting on the Commons." |
| 2 MET | meeting's last box, before the ask | Commons: crowd on saved spots, the Professor's "!" re-asks. Elsewhere: as 1 |
| 3 SENT | "Send her", before ignition | Commons: send-off replays (skippable), then gift. Elsewhere: write 2 |
| 4 DONE | gift's last box, before control returns | normal game |

- `checkpoint()` saves only if `can_save()`: no Director (unless `--finale-allow-save`), no debug call or `--finale=` (Engine meta `finale_dev_run`); SaveManager has no guard.
- A craft on every pad: gold rocket at 0-3, skiff at 4. `finish_story()` is idempotent.
- `flags["finale_spots"]`: the axis and each NPC's planet-local spot, re-checked on load.

## 2. Beats
**Call (home, ~25 s, K).** On `PartCelebration.finished` with 5 parts, or a stage-0 load with 5 parts, once PartCelebration's calm test holds 1.5 s. A `RadioSpeaker` (`mayor_orbit`) hangs 1.2 m to the rocket's side (copy `_hang_campaign_radio`'s rule), framing the gold rocket.

**Meeting (the Commons, K2).** Staged as the Commons loads, so you land to a waiting crowd; nothing is hidden.
- Axis `h`: 24 candidates 15° apart round the pad, landing side first. Front row 6.0 m out, 1.0 m apart: Grig, Fen, Zorp, Professor, Bolt, Vela. Back row 7.4 m, in the gaps: Pip, Pop, Stella, DJ Nova. The astronaut walks to a mark 3.6 m out, facing them.
- Slots pass visitor_system's ground rules (plus the board), sliding 0.5 m up to 3 times; head sight lines tested on real triangles per camera rule; passes framed, framed-spot, near.
- Friends spawn as visitors (`visit_host` = the meeting); the Commons five get those fields before their first physics frame; no wandering. Clock held (`Environment.time_scale` 0, restored on every exit) except in free roam.
- Own `Camera3D`, clock-driven (`MAX_STEP` 0.05), from 2.0 s of scene time, blends ≤35°/s, ≤2.5 m/s. **W** over the astronaut's shoulder (front heads ≥10% of phone frame height, back ≥7%); **P** the speaker (head ≥18%); **U** beside the crowd looking up (rock ≥20%); **S** side-on: crowd one half, astronaut and rocket the other; **R** the pad three-quarter with the crowd. Heads 20-60% from the top, clear of the measured box and pill rects.

**Choice (K2).** `ask(prof, prompt, ["Give me a moment", "Send her"], 0.6)`: focus on "moment", presses ignored 0.6 s after the pills show, cancel = moment, no timer, no "keep it". Moment: free roam (flying allowed), a line each, the Professor re-asks. Send: stage 3, two boxes, the crowd steps back 1 m, the ladder stows, the astronaut waves.

**Send-off, one shot, 22 s ±2 (L).** Borrows the pad's rocket (public API only); own camera seeded from the meeting's, far 400 m, `--finale-trace=<file>`; one balanced "cutscene" modal; physics on (12 s watchdog).
- 0-2.5 s: wide from 2.5 m up behind the crowd, vFOV 50: front heads, whole rocket, half the rock. Ignition 1.0 s: `rocket_ignite`, `CrashFx.dust_ring()`, shake ≤0.075.
- 2.5-7.5 s: lift-off, the camera craning to ~12 m, rocket ≥8% of frame height; 7.5-11 s it eases to a stop, letting her go, plume ≥3 px wide.
- 11.0 s: `CrashFx.flash()` hides the rocket; rock ≥18% of frame height. By 11.4 s chunks part 0.5-1.5 m over the gold core; by 13 s they warm, shrink (scale, never fade) and become streak heads.
- 12.5-18 s: waves at 12.5, 14.5 and 16.5 s; 10-14 streaks on screen at peak; five hero stars 15-18 s.
- 13-22 s: the camera swings down to a low three-quarter front of the upturned faces, streaks pouring over them; cheers, DJ Nova dances; settling on the gift frame, pad unseen.
- Skip on CrashIntro's contract, armed at 0.6 s: navy fade, idempotent `apply_end_state()`, input after release. Stragglers every 8-12 s until the gift ends. Music fades at ignition; `hub` returns with control.

**Gift (~45 s, G).** After ≥4 s with the pad outside the frustum (logged), a tarp-covered lump hiding the skiff stands on it. Grig and Bolt pull the tarp, which slides and scales off. After the last box: `finish_story()`, `rocket_pad.adopt_model(skiff)`, 1.1 s hand-back, toast; control 4.5-6.5 m from the pad (outside Fly reach); the pad flies the skiff straight away.

## 3. Lines ("/" = new line; each quote is one box)
**Call (radio):** Prof "Professor Comet here. Oh my. She's GOLD! / You could fly all the way home now."; "But hold on. Something big is on my scope. / I checked twice. Then I found my glasses."; asks "Come to the Commons? I'm calling everyone." [On my way / What is it?]; What is it: "Better seen than said. Do come. Nobody panic."
**Meeting:** Zorp "You came! Everyone came! Even Grig came!"; Grig "Closed the steps. All nine hundred and four."; Prof "Thank you all for coming. Now, look up. / Just there, above the pad. See it?"; Prof (U) "A giant asteroid. It's headed for our worlds."; Bolt "I ran its path forty times. Five worlds. Every time."; Vela "The array heard it three nights ago. / I filed it under 'unexplained'. I was wrong."; Fen "Nine years of notes. Nothing this size, ever."; Pip "We could hide in the stockroom..."; Pop "...no, we couldn't. It's full of lamps."; Zorp "Unless something fast hits it first. VERY fast."; all turn to the rocket; Bolt (S) "Your rocket is fast. Five parts. From us."; Prof (S) "She's your way home. Nobody will ask it of you. / But she's the only thing that could do it."; Prof asks "It's your rocket. What would you like to do?"
**Moment:** Prof "Take all the time you need. We'll be right here."; Zorp "Whatever you choose, you're still my best friend."; Bolt "Friendship does not need a rocket. I checked."; Fen "Sit a while. The sky will wait. It always has."; Grig "Steps can be cut again. A world cannot."; Vela "Take your time. Good answers are rarely quick."
**Send:** Bolt "Autopilot set. Passengers: zero. Course: true."; Prof "Everyone, stand back from the pad!"
**Gift:** Nova "Best. Light show. EVER!"; Zorp "One more! Did you see? / Okay. Don't look at the pad. / ...Now look at the pad!"; Prof "We started her the day you crashed. / Everyone gave a piece."; Bolt "One gold panel fell off your rocket. I kept it. / It is the hatch now. Polished 88 times."; Zorp "It has knees! Three! Like you, but more! / The antenna is mine. It glows when happy."; Fen "The lamp on the front is mine. For long dusks."; Grig "I cut the ladder. Eleven rungs. All numbered. / Small. Won't reach your old home. / Reaches all of ours."; Vela "The little dish is mine. I will always hear you."; Prof "You gave up one way home. / So we built you another. Welcome home." Toast "Every world is open. Planet stats are back."

## 4. Looks
**Asteroid (L).** CrashAsteroid's recipe scaled: `faceted_blob` squashed (1.14, 0.84, 1), sunk shoulder, 3 craters, dark undersides, #8a839b, S ≤0.20, no fire. Radius 11 m, ≤1,500 tris, `PlanetPropMeshes.rock_material()`. One mesh until the flash frame, then 10 pre-cut chunks with identical vertices (material `duplicate()`s share the Shader; emission warms to #ffe0a0) round a `MaterialLib.glow("#ffe0a0")` core. 130 m from the crowd centre, 24° above its horizontal, 20° off the pad bearing: ~10° across, ≤162 m from anywhere on the Commons (far plane 300 m). Tumble ≤3°/s, ≤8 painted puffs. Fill: a shadowless DirectionalLight3D culled to `CrashAsteroid.FILL_LAYER` (20), from the crowd centre at the brighter of sun and moon's energy (planetshine, no fitted ratio). Commons, stages 1-3 only.

**Shower (L).** A meteor shower, not fireworks. One MultiMesh or GPUParticles3D of ≤160 streaks, `star_streak.gdshader`, per-instance colour (no instance uniforms, item 55), on a 60-90 m shell round the crowd. Streaks start 8-150° from the radiant (the rock's centre), weighted to 15-60°, and move straight away within 2°: no gravity, droop or round burst. Warm white #fff1d6, the rocket's gold #f2d28a, lavender tails #b9b0d6, intensity 1.3-1.6. Five hero stars: slow long quads in each friend's accent, core S ≤0.45, crossing the faces frame.

**Skiff (M1).** An upright squat lander, 2.3 m tall, drum Ø1.7 m, three splayed knee-jointed legs on round pads within Ø2.4 m. Flat chamfered base ring, faceted panel-lined barrel, low faceted canopy in the visor's opaque navy #1b2450 with one crisp streak, dome ≤0.35 × drum width. Never a bubble (R2.3), nose cone, fins, tall hull, saucer or wings. Slate-blue #6f7fa8 body, cream #d9d2c0 base. Pieces: Bolt's gold hatch plate, Zorp's antenna with a muted aqua bulb, Fen's hooded lamp, Grig's numbered chalk ladder (11 rungs), Vela's dish. Flies like the rocket: origin at ground contact, hatch -Z, thrust +Y, plume at 0.7. Look from `FinaleState.has_ship()` at `_ready` (guarded load) or `--rocket-look=`. All public RocketModel methods work in both looks (finish calls no-op), plus `look()`, `set_look()`, `model_height()`. Tris and draws ≤ the rocket's, using only materials it already draws.

## 5. Sound (lead generates later; builders check `sfx_exists`)
New: `finale_impact` (soft low thoom with filtered noise, 0.4 s after the flash), `finale_shower` (airy high shimmer swelling per wave over a resolving pad), `finale_hero_star` (filtered swish, pitched per star), `skiff_reveal` (tarp whoosh into a warm two-chord pad). Reuse `rocket_ignite`, `rocket_loop`. No mallet or glockenspiel, so not `shooting_star` or `quest_complete`.

## 6. After the story
DONE sets `finale_stage` 4, `finale_ship` true and `story_done` true (campaign stays active), emits `campaign_changed` once, restores the clock, checkpoints. `story_done` already does the rest (planets, favours, board, Planet stats, visits). New: every pad and flight builds the skiff; the crowd, rock and stragglers never spawn again; the pad compass and board strings say "ship".

## 7. Heat budget
Mac, gl_compatibility, 1280x720, medians paired in one run, stating the smallest detectable difference; phone unmeasured. Reference (item 44): flight 1.82 ms/49 draws, home gameplay 4.10 ms/240.
- Call: ≤ home gameplay +0.2 ms, +0 draws; send-off ground ends and gift ≤ meeting (skiff ≤ rocket).
- Meeting: ≤ Commons gameplay at the same camera +0.6 ms and +62 draws (friends ≤60, one measured first; rock 2).
- Send-off sky part (camera ≥20° up): ≤2.5 ms, ≤90 draws.
- No new `.gdshader`; every Shader is already drawn in Commons gameplay or warmed by a real 2 cm quad 1 m before the meeting camera in its first box. No frame >50 ms from 2 s after a load to control return; no new shadows, screen effects or transparency fades; `max_fps` stays.

## 8. Builders (disjoint)
**Lead first:** the guarded `world.gd` hook after VisitorSystem; `visits_on()` false at stages 1-3; optional `arm_delay` on `DialogueBox.show_choice` and `DialogueRunner.ask` (default 0); `campaign/finale_lines.gd` verbatim from §3 (Haiku).
- **K flow**, Sonnet, Opus critic: new `campaign/finale_state.gd`, `campaign/finale.gd`; `ui/pause/dev_menu.gd`.
- **M1 skiff**, Opus: `rocket/rocket_model.gd`, new `rocket/skiff_mesh_lib.gd`.
- **K2 meeting**, Opus: `campaign/finale_meeting.gd`.
- **L send-off**, Opus: `campaign/finale_launch.gd`, `giant_asteroid.gd`, `star_shower.gd`.
- **M2 wiring**, Sonnet: `rocket/rocket_pad.gd`, `rocket/space_travel.gd`, `rocket/journey_state.gd`, `minigames/replay_board.gd`, `minigames/replay_board_panel.gd`: `adopt_model()`, the skiff in flight (chase offsets scale by `model_height()/3.2` only if under gate), wording.
- **G gift**, Sonnet, Opus critic: `campaign/finale_gift.gd`.

Builders own `showcase/finale_<id>*` and `tests/director/finale_<id>*`. Order: lead; K + M1; K2 + L, and M2 once M1 passes; G; integration.
**Contracts:** `FinaleState` (static): `stage()`, `set_stage(n)`, `checkpoint()`, `can_save()`, `has_ship()`, `spots()`, `set_spots(d)`, `finish_story()`. `FinaleMeeting`: `crowd_ids()`, `npc(id)`, `axis()`, `mark()`, `asteroid()`, `camera()`, `camera_to(rule, ids, seconds)`, `say(id, lines)`, `ask(id, prompt, options)`, `chose_send`. `FinaleLaunch`: `play(meeting)`, `apply_end_state()`, `finished(skipped)`. `GiantAsteroid`: `place(crowd_centre, axis, planet)`, `centre()`, `break_at(t)`. `FinaleGift`: `play(meeting)`, `finished`. `rocket_pad.adopt_model(model)`.

## 9. Critic checklists
All: QUALITY_BAR verdict; renamed scratch copy, real save hashed before and after; renderer line checked; phone frames 2556x1179 `--ui=mobile` via `--capture-dir`, never `--write-movie`; every §2, §4 and §7 number re-measured.
- **K:** 5x7 stage × world matrix (right action, a craft on every pad); SIGKILL in and between every beat, then reload: no soft-lock, double commit or lost ending; 2.0 on disk reads 2; no save from Director or debug runs; old and finished saves unaffected; no visitor at 1-3; clock restored on every exit; dev rows by real taps.
- **K2:** over 12 decoration layouts no head >20% covered, nothing hidden; 0 Footprint contacts over the meeting and 120 s of roam; trace ≤35°/s, no step >2× median; a real 10 taps/s touch train never sends her; cancel = moment; flying away and back restores crowd and "!".
- **L:** no cut in the trace; real-InputEvent skips at 0.3, 1, 6, 11, 15 and 21 s match the natural end; the not-fireworks list; per region at 12.0, 19.0 and 22.0 (NightLife frozen): sky blown <5%, streak core luma ≥ sky p95 +0.25, the rock and scene gates as amended in §0 (relative to a same-frame control; lit face as the MEAN of the brighter half, 0.30-0.60; night only); stall log; cute, not scary.
- **M1:** compare.py sheet beside the rocket at gameplay distance and 3 m: not the rocket, a bubble or a saucer, but of this cast; palette on its own pixels in Commons and home day light, both renderers; every public method error-free; flag off, rocket mesh arrays hash identical; sits on all seven decks.
- **M2:** skiff home→Zorp→Commons→Fen→home: no seam pop, frame-height share ≥70% of the rocket's at seam and touchdown, hatch hops land; Fly right after `adopt_model`, 0 orphans; flag off, traces within noise.
- **G:** frustum log; nothing fades or toggles in view; DONE checkpointed before control, one `campaign_changed`; each friend's piece in frame on their box.
- **Integration (lead):** `tools/check.sh`, seven worlds boot, a real play-through from Vela's bench fit to DONE on desktop and Compatibility `--ui=mobile`, then the phone's build stamp.

## 10. Debug API
Static in `src/campaign/finale_state.gd`, called by a new "Finale" section in `dev_menu.gd` via `load(FINALE_STATE_PATH).call(name)`; each sets `finale_dev_run`, returns toast text, travels by `SceneRouter.go_to_planet`:
- `debug_reset_before_finale()`: campaign on, story not done, parts 1-4, Vela's part and its scrap in the bag, stage 0, ship and spots cleared; home.
- `debug_start_call()` (5 parts, stage 0; home); `debug_start_meeting()` (stage 1; Commons); `debug_start_choice()` (stage 2; Commons); `debug_start_sendoff()` (stage 3; Commons); `debug_start_gift()` (stage 3, send-off ended; Commons); `debug_after_story()` (stage 4, story done, ship; home).
- `debug_report(tag := "")` prints `FINALE <tag> stage= planet= parts= story_done= ship= gates= visits= can_save=`.

CLI: `--finale=reset|call|meeting|choice|sendoff|gift|after` (with `--campaign` under the Director), `--finale-allow-save`, `--finale-trace=<file>`, `--rocket-look=rocket|skiff`.
