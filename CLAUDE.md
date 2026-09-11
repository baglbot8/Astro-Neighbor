# Astro Neighbor — working instructions

Loaded into every session, so it is kept short on purpose. The rules are here; the detail lives in
`docs/` (links below). When a rule here and a doc disagree, the newer user instruction wins — ask.

## The user

- Plays and tests on an **iPhone** (Chrome, served from GitHub Pages). The desktop look is the
  reference they like; phone reports are the real test.
- Reports: plain and short (ELI10). Say what you did, whether it worked, and what they do now. When
  they must decide: at most three options, the context to pick fast, and which one you would pick.
- Be honest. Say what failed, what was only tested with fake input, and what is unproven. Never
  oversell a fix. If you told them something wrong, correct it plainly and move on.
- **They push. You never handle git or GitHub credentials.** You commit and build, then give them
  the one push command.

## The game

- Godot 4.7.1 at `/opt/homebrew/bin/godot`, GDScript only.
- **Everything is procedural** — no imported art or audio. Audio comes from `tools/gen/audio/`.
- **Direction since 2026-09-10: its own game, not an Animal Crossing copy.** `docs/ARCHITECTURE.md`
  §1.1 lists the AC tells and which are decided. Keep: the cute chibi cast, the Moonstone palette
  with Baloo 2, the thin-atmosphere space look, and the measured palette gates in `docs/STYLE_GUIDE.md`.
- The web build runs Godot's **Compatibility** renderer. Reproduce phone bugs on the desktop with
  `--rendering-method gl_compatibility` (an engine flag, before the `--`).

## How we work: a lead, builders, and harsh critics

The user asked for this process on this project. It is standing permission to use sub-agents and
Workflow scripts for substantive work — on the cheapest model that fits (next section).

- **The lead** (this main session) plans, splits the work, decides, and reports. It does not do bulk
  building itself.
- **Fan out.** Split work into builders that each own a **disjoint** set of files. Never put two
  agents on one file. A builder that needs someone else's file says so in `needs_from_others`; it
  does not edit it.
- **A builder never grades its own work.** Every build gets an independent critic that did not
  write it.
- **Critics are harsh.** Assume corners were cut. Re-measure instead of trusting the builder's
  numbers. Look at rendered frames, not only the code. Try to break it. Protocol and verdict format:
  `docs/QUALITY_BAR.md`.
- **Loop until PASS.** A FAIL goes back to the builder with the exact blocking list, then the critic
  re-reviews. Cap it at two rounds; if it still fails, stop and re-diagnose rather than loop again.
- **Unknown cause? Diagnose before building.** Read-only investigators first, then an adversarial
  cross-check that tries to refute them, then the fix.
- **Finish with an integration check**: `tools/check.sh`, all seven worlds boot, a real play-through.
- Builders do not edit `docs/` — it is the contract they are graded against. The lead amends a doc,
  with the measurement that justifies it. Builder detail: `docs/AGENT_WORKFLOW.md`.

## Use the cheapest model that can do the job

Added 2026-09-10 at the user's request, to conserve tokens. The lead (Opus) plans, decides and talks
to the user. Work that does not need Opus goes to **separate sub-agent chats on a lower model** — the
Agent tool with `model: "sonnet"` or `"haiku"`, or `agent(prompt, { model: 'sonnet' })` per stage in
a Workflow script. Each sub-agent is its own chat, which also keeps the lead's context small.

- **Haiku** — mechanical, fully specified, nothing to decide: run `tools/check.sh` or a Director
  timeline and report; sync the two copies; grep sweeps and inventories; capture screenshots from a
  given command; convert images or audio; apply an edit the lead already wrote. Add `effort: 'low'`.
- **Sonnet** — moderate work with a clear spec: implement a specified change in one to three files;
  write a generator from a spec; gather and summarise web research; first-draft docs; run an
  existing scorer; critics checking against a written checklist.
- **Opus** — where a wrong answer costs a rework loop: bugs with an unknown cause; design across
  systems; art and UX direction; final judging and synthesis; the adversarial critic on a hard or
  risky change; anything recommended to the user.

Default a new sub-agent to Sonnet; drop to Haiku for pure busywork; choose Opus on purpose and be
able to say why. A cheap agent's result is still checked — if it is uncertain, contradicts a
measurement, or fails its critic twice, redo that step on Opus. A critic on a hard problem is at
least as capable as the builder it grades. Hand big reads (long files, logs) to a cheap agent that
returns the conclusion, not the dump.

## Evidence rules (each one cost this project at least one wasted round — `docs/OPEN_ISSUES.md` 33-39)

- **Measure, don't reason.** Bisect in the engine. Three confident, worked-out explanations of one
  bug were each measured false before the real cause was found.
- **Bisect forward** from a setup that works, adding one thing at a time — not backward from the
  broken scene.
- **Confirm a problem repeats** before chasing it, and only compare captures from the same folder.
- **Look at the picture.** A metric has improved while the art got worse three times.
- **No fitted constants or magic gains.** Every fix that held was an exact inversion with no free
  parameter; every tuned knob was later reverted.
- **Score per region**, never the whole frame — a ground error and a sky error cancelled out.
- **Judge in the real game scene.** A showcase must match gameplay lighting, camera and spawn.
- **Say what is synthesised.** `debug_touch` never goes through real input, and
  `Input.action_press()` sends no InputEvent — neither proves a real finger works.
- **Check the phone runs the current build** before trusting a phone report:
  `curl -s https://baglbot8.github.io/Astro-Neighbor/ | grep astro-build` must show the latest commit.
  A cached service worker once froze the phone on a two-day-old build.
- When something goes wrong in a non-obvious way, **write the lesson into `docs/OPEN_ISSUES.md`**.

## Tooling traps

- `tools/snap.sh` puts extra args after the `--`, so **engine flags are silently ignored**. Call
  `godot` directly when the renderer or resolution matters, and check the `[Platform] renderer:`
  line in every run.
- zsh does not split an unquoted variable — a variable holding flags passes as one ignored argument.
  Write engine flags literally.
- `src/ui/title/title_screen.gd` starts the game whenever the Director is active, so a timeline
  aimed at the title captures the game instead. Use `showcase/ui_title.tscn`.
- `src/world/environment.gd` rewrites the environment every frame; a one-shot edit is undone before
  the capture. Change the per-frame write.
- `--freeze` only stops the turntable, and captures differ by ~55,000 px run to run. Do not
  pixel-diff small changes.
- macOS stops drawing a covered window: pass `--always-on-top --position 100,100` before the `--`.
- Never run `tools/gen/audio/build_all.py` while other builders are working — it regenerates every
  asset.

## Shipping

- Edit in this folder. The git copy is `Astro Neighbor Repo/Astro Neighbor/` — sync `src/`,
  `assets/`, `docs/`, `tools/` and this file into it before committing, and run web exports there.
- Before any commit: `tools/check.sh` prints CHECK PASSED and all seven worlds boot headless
  (`godot --headless --path . --quit-after 2 res://showcase/planet_<id>.tscn` for home, zorp, bolt,
  hub, fen, grig, vela).
- Commit messages record **why**, with the numbers.
- Web: `tools/publish_web.sh` in the git copy, then the user runs `git push origin main gh-pages`.
  Its self-destructing service worker and build stamp are load-bearing; do not remove them.

## Where things live

- Design contracts: `docs/ARCHITECTURE.md` (§1.1 identity), `docs/STYLE_GUIDE.md` (art rules and
  palette gates), `docs/QUALITY_BAR.md` (critic protocol), `docs/AGENT_WORKFLOW.md` (builders),
  `docs/CAST_VARIETY.md` (character uniqueness rules).
- Known problems and every past wrong turn: `docs/OPEN_ISSUES.md`.
- The new story campaign (2026-09-10): `docs/CORE_LOOP.md` (what the game is) and
  `docs/BUILD_PLAN.md` (phases, builders, file owners). CORE_LOOP's "Changed after the build plan" section wins over
  anything older in either file.
