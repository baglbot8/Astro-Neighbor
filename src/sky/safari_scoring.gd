class_name SafariScoring
extends RefCounted
## NUMBERS (2026-09-21, scratch only). Score, price and film for the photo safari. Written
## alongside a round that is still wiring the flight itself (safari_run.gd, safari_cast.gd,
## sky_hints.gd, sky_journal.gd, src/rocket/*) — this file does not touch any of those. It is the
## contract the flight code adopts when that round is ready: see the "API" section of the report
## for the exact calls.
##
## WHERE THE OLD NUMBERS CAME FROM. Two other places already price a print:
##   sky_print.gd  SkyPrint.grade_for()  — grades on sharpness alone, thresholds 0.35/0.60/0.82.
##                 SkyPrint.sale_hint()  — its own docstring calls it "PLACEHOLDER... kept from
##                 round 1 so the card is not blank."
##   print_bag.gd  PrintBag.pay_for()    — 8 + 46*rarity(0..1) + 30*sharpness(0..1). Its own
##                 docstring: "a worthless blur is 8, a perfect rare is 84."
## Neither is deleted here (both belong to files this round does not touch). This file is the
## replacement the reviewer's measurement asks for.
##
## THE MEASURED IMBALANCE. The reviewer: skill is worth 11 stardust across its whole range while
## rarity is worth 46. Rarity's 46 is print_bag.gd's full coefficient — a sight really is forecast
## anywhere from common to rare, so that coefficient is fully realised every run. Sharpness's 30
## is NOT fully realised: the hold mechanic and the off-world cap mean a real run's sharpness
## rarely spans the full 0..1 the coefficient assumes, so only ~11 of the possible 30 ever shows up
## in a payout. Bumping the sharpness coefficient alone would not fix this — the coefficient was
## never the bottleneck, the REALISED RANGE was. So this file folds in the one thing that already
## swings a full, real range every single catch: whether you caught the moment
## (SafariCast.moment_at / value_of's `moment_mult`, 1.0 with no moment up to the cast's own
## ceiling). Catching a moment is a binary a run actually hits and misses, unlike sharpness which
## tends to sit high once a player has the hang of the aim.

# =====================================================================================  SCORE

## Player-facing grade names. Kept from sky_print.gd (its docstring: "today's names are Fair, Fine,
## Gallery — keep or improve them"); Smudge kept too since sky_print.gd already ships it as the
## floor grade and nothing about tonight's brief asks to rename it.
const GRADES := ["Smudge", "Fair", "Fine", "Gallery"]

## THE HIGHEST MOMENT MULTIPLIER ANYBODY ACTUALLY WROTE. It used to be 2.2, read off the old
## two-route cast. The merged catalog has SIX moments above that - 2.3 and 2.4, five of them on
## the hinted top rares - so the ceiling was silently clamping the best thing in the game down to
## the value of its own second best. It is now 2.4, which is SafariCatalog.max_authored_moment().
## tools/safari_selftest.gd fails if the two ever differ again, so a new moment cannot be written
## into the catalog and quietly lost.
const MOMENT_CEILING := 2.4
## A shot with no moment window active carries this multiplier (SafariCast.value_of's own
## `maxf(moment_mult, 1.0)` floor) — repeated here so this file has no hidden dependency on that
## one's internals.
const MOMENT_FLOOR := 1.0

## SKILL_MOMENT: sharpness and the moment you caught, blended 50/50 into one 0..1 number. The
## split is exactly even on purpose — the brief says catching the moment matters as much as
## holding steady ("a creature turning to look at you is worth more than the same creature
## drifting" is about WHEN you shoot, not just how steady you are), so neither axis is allowed to
## drown out the other. The moment's share is scaled by MOMENT_CEILING so a shot with the single
## best moment in the whole cast, held at zero focus, contributes exactly as much as a flawless
## hold with no moment at all — the two halves are worth the same at their own maximums, no
## fitted weight beyond that stated equality.
static func skill_moment(sharpness: float, moment_mult: float) -> float:
	var sharp := clampf(sharpness, 0.0, 1.0)
	var mm := clampf(moment_mult, MOMENT_FLOOR, MOMENT_CEILING)
	var moment_share := (mm - MOMENT_FLOOR) / (MOMENT_CEILING - MOMENT_FLOOR)
	return clampf((sharp + moment_share) * 0.5, 0.0, 1.0)


## Grade thresholds, all read straight off the skill_moment scale's own geometry — no number here
## is invented separately from what it means:
##   FAIR    0.25  a coin-flip hold (sharpness 0.5) with no moment at all lands exactly here.
##   FINE    0.50  half the combined scale — a FLAWLESS hold with no moment ever caught tops out
##                 right at this line, not above it: pure steadiness alone cannot reach Gallery.
##   GALLERY 0.80  needs real contribution from BOTH halves together (e.g. a 0.9 hold plus the
##                 cast's second-best moment, or a 0.7 hold plus its very best) — reachable, but
##                 never by focus alone. This is the grade system's answer to "should catching the
##                 moment matter" (CLAUDE.md history, sky_print.gd's own round-2 rationale): yes,
##                 for the top grade, not just for money.
const GRADE_FAIR := 0.25
const GRADE_FINE := 0.50
const GRADE_GALLERY := 0.80

## GRADE_FLOOR[i]: the minimum skill_moment that earns GRADES[i]. Reused (not re-typed) for the
## price table below, so the table and the grade the player sees always agree with each other.
const GRADE_FLOOR := [0.0, GRADE_FAIR, GRADE_FINE, GRADE_GALLERY]


## The grade name the player sees on a print. Rarity never enters this: a perfectly-timed common
## catch is a Gallery print and a fumbled rare is a Smudge (kept from sky_print.gd's round-2
## design — the rare one still pays more below, it is just not better WORK).
static func grade_for(sharpness: float, moment_mult: float) -> String:
	var s := skill_moment(sharpness, moment_mult)
	if s < GRADE_FAIR:
		return GRADES[0]
	if s < GRADE_FINE:
		return GRADES[1]
	if s < GRADE_GALLERY:
		return GRADES[2]
	return GRADES[3]


## rarity 1..4 -> 0..1. FOUR rungs, not three: the catalog's six top sights are rarity 4
## ("Hardly ever") and the old clamp to 1..3 priced every one of them as a plain rare. Evenly
## spaced, so each rung up is worth exactly a third of PAY_RARITY and rarity 4 always outpays
## rarity 3 by the same amount that 3 outpays 2.
static func rarity_frac(rarity: int) -> float:
	return clampf((float(clampi(rarity, 1, 4)) - 1.0) / 3.0, 0.0, 1.0)


## ONE quality number a print is worth, folding in sharpness, the moment and rarity together — see
## PRICES below for why the coefficients are sized the way they are. This is what Gloop pays on;
## it is not what sets the grade (see grade_for) — grade is the player's WORK, this number is the
## SALE, and the two are allowed to disagree (a Fine common with a great moment can out-earn a
## Fair rare with none, which is the fix: skill+moment now outweighs rarity in the money too, not
## only in the label).
static func quality_of(rarity: int, sharpness: float, moment_mult: float) -> float:
	return PAY_BASE + PAY_SKILL_MOMENT * skill_moment(sharpness, moment_mult) + PAY_RARITY * rarity_frac(rarity)


# =====================================================================================  PRICES
## What Gloop pays for a COPY of a print (the print itself stays in the journal - unchanged from
## sky_print.gd's split). Same shape as the old print_bag.gd formula (base + skill term + rarity
## term) so the change is legible as a rebalance, not a rewrite.
##
##   print_bag.gd  8 + 46*rarity_frac + 30*sharpness       rarity 46, skill REALISED about 11
##   round 1 here  6 + 24*rarity_frac + 54*skill_moment    rarity 24, skill 54 - the right SHAPE
##   round 2 here  4 + 20*rarity_frac + 45*skill_moment    same shape, scaled - but that scale was
##                                                         solved from TWO player models and only
##                                                         held for those two (merge critic)
##   now         3.6 + 18*rarity_frac + 40.5*skill_moment  the SAME numbers times 0.9, this time
##                                                         chosen off a FAMILY of player models
##
## WHY IT MOVED AGAIN. The merge critic re-priced the content under their own trip model and got a
## steady trip of 103 - outside the 60-100 band - then showed that seven defensible readings of
## "steady" spanned 85 to 111. The round-2 numbers had been solved from exactly two models, so of
## course they held for those two: that is the fitted constant CLAUDE.md warns about.
##
## HOW THE SCALE WAS GOT THIS TIME, as an INTERVAL and not a point:
##   * The RATIO is untouched, because all three constants move by ONE factor: 40.5 / 18 = 45 / 20
##     = 54 / 24 = 2.25 exactly. Skill plus moment still outweighs rarity better than two to one,
##     which is the one thing round 1 existed to fix. There is one free number here, not three.
##   * The SCALE k was swept over EIGHT models of a player (sharpness 0.45 / 0.55 / 0.65; the
##     moment taken at a random shutter instant inside the sight's own window, or on one plate in
##     four, or one in three, or never; limb sights counted and not counted) plus the great model,
##     over 600-900 drawn trips each. Every price is linear in k, so each model's trip pay is just
##     its k = 1 value times k, and "every steady model inside 60-100 AND great inside 150-200" is
##     an INTERVAL, not a point. Taking the tighter end from each of the two tools that measured it
##     (tools/safari_selftest.gd, and a separate sweep whose great player heard only half the
##     hints):
##         k >= 0.874   the great model's floor       - binding from below
##         k <= 0.925   the sharpest steady (0.65)    - binding from above
##     k = 0.90 is the middle of that interval, and is the same scale the merge critic landed on
##     independently. What the self-test then measures at 0.90: the seven steady models span
##     73.9 to 97.3 (2.7 under the ceiling, 13.9 over the floor) and the great trip pays 161.6
##     (11.6 over its floor, 38.4 under its ceiling). Nothing was solved backwards from a target,
##     and the self-test re-runs the whole family and prints every number in it every time.
##   * ONE MODEL IS DELIBERATELY EXCLUDED, said out loud so it can be argued with: a player who
##     lands each sight's BEST moment on all four plates while holding only 0.55 pays 117.1, above
##     the band. Timing every moment is the great player's defining skill, so that is a
##     moment-hunter with shaky hands, not a steady player. No scale fixes it either - putting
##     117.1 under 100 needs k <= 0.77, which drops the great trip to 138, under its own floor.
##   * WHAT THIS STILL DOES NOT BUY, plainly: the brief wanted the cheapest decoration (120) to be
##     about TWO ordinary trips. At k = 0.90 the steady family pays 74-97, so a decoration is
##     1.2-1.6 trips. Genuinely two trips wants the middle steady at 60, i.e. k = 0.61, and the
##     great trip would then pay 109 - far under its own 150 floor. The two bands the brief set
##     cannot BOTH hold and also mean two trips; 120 would have to drop to about 160-180, or the
##     great band reopen. That is a ruling for the lead, not a build decision, and the self-test
##     prints the trips-per-decoration number every run so it can never go quiet again.
##
## PAY_BASE = 3.6: a genuinely bad print (Smudge, common) still is not worthless. Gloop takes it
##   off your hands for about a sixth of an average catch, so a dud is a near-zero, never a loss.
## PAY_RARITY = 18: rarity's full common->hardly-ever swing, over FOUR rungs, so each rung up is
##   worth 6 and rarity 4 always outpays rarity 3.
## PAY_SKILL_MOMENT = 40.5: skill_moment's full 0..1 swing, realised in full every catch.
## The 3.6+18+40.5 = 62 ceiling is what a perfect shot of the rarest thing in the game fetches.
const PAY_SCALE := 0.90     ## the ONE free number. The three below are 4 / 20 / 45 times it, so
                            ## the shape can never drift when the scale is re-argued.
const PAY_BASE := 4.0 * PAY_SCALE
const PAY_RARITY := 20.0 * PAY_SCALE
const PAY_SKILL_MOMENT := 45.0 * PAY_SCALE

## Continuous price (what Gloop actually pays for a real catch - call this from the flight code).
static func price_of(rarity: int, sharpness: float, moment_mult: float) -> int:
	return int(round(quality_of(rarity, sharpness, moment_mult)))


## Table price - the FLOOR of each named grade at each rarity, i.e. what a print is guaranteed to
## fetch once it has made that grade (a real catch inside the grade can pay a little more, up to
## the next grade's floor). This is what a shop label or a sell-preview shows, since it can be
## known before the exact skill_moment number is. Built from GRADE_FLOOR and rarity_frac - no
## number here is typed twice.
static func table_price(grade: String, rarity: int) -> int:
	var idx := GRADES.find(grade)
	if idx < 0:
		idx = 0
	return int(round(PAY_BASE + PAY_SKILL_MOMENT * GRADE_FLOOR[idx] + PAY_RARITY * rarity_frac(rarity)))


## The payout table the brief asked for: a bad (skill_moment 0.0), an average (0.5 - exactly the
## Fine floor) and a perfect (1.0) shot, of every rarity the catalog uses. Computed, not
## hand-typed, so it can never drift from the formula above.
##   BAD      common  4  uncommon 10  rare 16  hardly ever 22
##   AVERAGE  common 24  uncommon 30  rare 36  hardly ever 42
##   PERFECT  common 44  uncommon 50  rare 56  hardly ever 62
## Skill's swing at a fixed rarity (4->44, or 22->62: +40.5) beats rarity's swing at a fixed skill
## (4->22, or 44->62: +18) by 2.25 to 1, and every step up in rarity is worth 6.
static func example_payout_table() -> Array:
	var rows: Array = []
	for tag_frac in [["bad", 0.0], ["average", 0.5], ["perfect", 1.0]]:
		var tag: String = tag_frac[0]
		var sm: float = tag_frac[1]
		var row := {"shot": tag}
		for r_name_val in [["common", 1], ["uncommon", 2], ["rare", 3], ["hardly_ever", 4]]:
			var rn: String = r_name_val[0]
			var rv: int = r_name_val[1]
			row[rn] = int(round(PAY_BASE + PAY_SKILL_MOMENT * sm + PAY_RARITY * rarity_frac(rv)))
		rows.append(row)
	return rows


# =====================================================================================  FILM
## How many plates a trip carries, and how a player gets more. AIM, in plain words: a route shows
## more sights than a plate load carries, on purpose — film is the resource that makes "did I wait
## for the good one" (safari_run.gd's own framing) cost something real. Unlimited film makes every
## miss free; this makes the overlap safari_run.gd already ships (pod/ice, 8.5 s of forced choice)
## matter to more than just which haul-card line you read afterward.
##
## RE-SIZED FOR THE R4 REBUILD (SAFARI_FLIGHT_SPEC.md #6.3, 2026-09-22, G4). R4 (safari_lanes.gd,
## G3's file, being rewritten alongside this round) triples run length and raises the cast from
## 6-7 sights to 14-18. The old ratio - a base load noticeably short of a typical draw, about 0.8
## plates per sight (the live 5 vs 6 sights before this round, GameState's old FILM_BASE) - does
## not scale cleanly to a load THIS size without making the base itself the whole game, so the
## three numbers below are fixed by the spec table instead of solved backward from that one ratio:
## FILM_BASE 10 (unupgraded, a clear minority of a full 14-18 sight cast so the choice stays real),
## buyable in stardust to 14, upgradeable in scrap to 16 (a fully upgraded camera can just clear
## the busiest lane's low end, matching the old design's own rule that "by the time BOTH
## progression axes are paid for, film is meant to stop being the constraint at all").
##
## FILM_BASE = 10: well under the 14-18 sights a full lane can cast (SAFARI_FLIGHT_SPEC.md #6.3),
##   so a run always has sights you cannot take even with perfect play — the choice stays real, the
##   way it did at the old 4-5 base against 6-7 sights.
const FILM_BASE := 10

## FILM_DAILY_RESET = true: the load refills once per game day, at the same dawn boundary the rest
##   of the day's systems reset on (docs/CORE_LOOP.md's day boundary) — so a normal night of play
##   never needs a purchase just to fly the route once; buying is for a SECOND run or a better shot
##   at a route you already tried, not a toll on the first.
const FILM_DAILY_RESET := true

## FILM_BUY_PRICE = 23 stardust/plate, unchanged - see below. FILM_BUY_MAX = 4 extra per trip
##   (was 3): FILM_BASE(10) + FILM_BUY_MAX(4) = 14, the spec's "buyable to 14" (#6.3), so spending
##   everything in stardust alone still cannot reach even the low end of a full 14-18 sight cast.
## 23 is READ OFF the payout table rather than picked, and NOTHING about R4 changes that table (the
##   score/price formulas above are untouched by this round): the best BAD shot in the game pays 22
##   and the worst AVERAGE one pays 24, so 23 is the one number that sits above every bad catch and
##   below every average one. Buying a plate is then a genuine bet - it pays for itself only if you
##   expect that catch to be at least average, the same tension as swinging the scope for a moment
##   instead of playing safe. It moved 15 -> 25 -> 23 because the prices did; the RULE did not, and
##   tools/safari_selftest.gd re-checks the rule against the table rather than against this number.
const FILM_BUY_PRICE := 23
const FILM_BUY_MAX := 4

## FILM_UPGRADE_COSTS: scrap, one entry per tier. UNCHANGED THIS ROUND (400 then 850) - the lead's
##   #6.3 table fixes the PLATE numbers (10 -> 13 -> 16 across the two tiers, FILM_UPGRADE_STEP
##   below) but says nothing about re-pricing the scrap sink, and re-pricing it is a balance call,
##   not an arithmetic one - CLAUDE.md's "no fitted constants" cuts against inventing a new price
##   with nothing to derive it from. SAID PLAINLY, SO IT CAN BE ARGUED WITH: each tier now buys 3x
##   the plates (STEP 3 vs the old +1) for the same scrap, a real buff to the upgrade's value that
##   this file has NOT tried to price back out - flagged for the lead in this round's report.
## FILM_UPGRADE_STEP = 3: plates a single tier adds, so 2 tiers carries FILM_BASE from 10 to 16 -
##   the spec's "upgradeable to 16" (#6.3). Capped at 2 tiers, same as before: a fully upgraded
##   camera (16) still falls short of a busy lane's 18-sight high end, so "you still have to
##   choose" survives even maxed out, same as the old 6-vs-7 headroom did.
const FILM_UPGRADE_COSTS := [400, 850]
const FILM_UPGRADE_MAX_TIER := 2
const FILM_UPGRADE_STEP := 3


## Plates available for a trip today, given how many permanent upgrade tiers have been bought and
## how many extra plates were paid for on top (clamped to FILM_BUY_MAX).
static func film_for_trip(upgrade_tiers: int, bought_extra: int) -> int:
	var tiers := clampi(upgrade_tiers, 0, FILM_UPGRADE_MAX_TIER)
	var extra := clampi(bought_extra, 0, FILM_BUY_MAX)
	return FILM_BASE + tiers * FILM_UPGRADE_STEP + extra


## Scrap cost of the next upgrade tier, or -1 if already maxed.
static func film_upgrade_cost(current_tier: int) -> int:
	if current_tier < 0 or current_tier >= FILM_UPGRADE_MAX_TIER:
		return -1
	return FILM_UPGRADE_COSTS[current_tier]


## Stardust cost to buy N extra plates for one trip (bulk price is linear — no discount, so buying
## up is always exactly FILM_BUY_PRICE per plate, easy for a player to price in their head).
static func film_buy_cost(count: int) -> int:
	return FILM_BUY_PRICE * clampi(count, 0, FILM_BUY_MAX)


# =====================================================================================  PLANET PHOTOS
## THE PLANET SAFARI'S PHOTOS (docs/PLANET_SAFARI_SPEC.md 5.4, 11.1 and 13.1). A planet photo is graded
## on its CRAFT - CENTRED, SIZE, FOCUS and, when the subject has a front, FACING, each out of 10,
## measured by `src/planet_safari/safari_photo_scorer.gd` - plus whether it caught the subject's MOMENT
## (the flight's own 1.0..2.4 multiplier, from the subject's `moment` hook), and it is priced with its
## RARITY (1..4, the flight's scale).
##
## ADDED, NOT CHANGED. Nothing above this line moved: the flight calls grade_for / price_of /
## quality_of / skill_moment / table_price exactly as before and gets bit-identical answers (spec 13.1:
## "the space safari's grades and prices do not change"). The planet's GRADE has its own scale below
## (planet_grade); its PRICE is the flight's own price_of, fed the planet's craft.
##
## THE PLANET GRADE SCALE (spec 13.1, the lead's ruling after merge6's calibration FAILED: every Fine
## needed a caught moment, a no-moment photo topped out at Fair however perfect, and any single 0 made a
## photo worthless). The cut points are DESIGN CHOICES, stated as such by the lead:
##   CRAFT   the GEOMETRIC mean of the craft scores the subject has (3, or 4 with facing), each taken as
##           at least PLANET_SCORE_FLOOR (1 of 10) inside the mean - "one bad score hurts; it never makes
##           a photo worthless". Why geometric and not arithmetic: the ruling's own example, "a perfectly
##           framed photo of a creature's back is a Fair": geometric (10,10,10,1 -> 0.56) is a Fair;
##           arithmetic (0.78) would be a Fine, and the floor would barely matter. Three equal scores
##           still give back that score (7, 7, 7 -> 0.70).
##   GRADE   craft below PLANET_FAIR (0.35) Smudge, below PLANET_FINE (0.70) Fair, from 0.70 Fine; a
##           CAUGHT MOMENT (moment_mult above MOMENT_FLOOR) lifts it ONE grade, so a well-made photo of a
##           creature mid-moment is a Gallery and a Smudge with a moment is a Fair.
##   PRICE   price_of(rarity, craft, moment_mult) - the flight's formula unchanged, so the planet and
##           the sky keep one price list; only the craft that feeds it follows the new rule.
const PLANET_SCORE_FLOOR := 0.1
const PLANET_FAIR := 0.35
const PLANET_FINE := 0.70


## CRAFT, 0..1: the geometric mean of centred, size, focus and (when `facing10` >= 0) facing, each out of
## 10 and each counted as at least PLANET_SCORE_FLOOR. `facing10` < 0 = the subject has no front.
static func planet_craft(centred10: float, size10: float, focus10: float, facing10: float = -1.0) -> float:
	var c := clampf(centred10 / 10.0, PLANET_SCORE_FLOOR, 1.0)
	var s := clampf(size10 / 10.0, PLANET_SCORE_FLOOR, 1.0)
	var f := clampf(focus10 / 10.0, PLANET_SCORE_FLOOR, 1.0)
	if facing10 < 0.0:
		return pow(c * s * f, 1.0 / 3.0)
	var fa := clampf(facing10 / 10.0, PLANET_SCORE_FLOOR, 1.0)
	return pow(c * s * f * fa, 0.25)


## True when the shutter caught the subject's moment (anything above the flight's no-moment floor).
static func planet_caught_moment(moment_mult: float) -> bool:
	return moment_mult > MOMENT_FLOOR + 0.000001


## The grade's index in GRADES (0 Smudge .. 3 Gallery): craft cut at PLANET_FAIR / PLANET_FINE, then one
## step up for a caught moment.
static func planet_grade_index(craft: float, moment_mult: float) -> int:
	var i := 0
	if craft >= PLANET_FINE:
		i = 2
	elif craft >= PLANET_FAIR:
		i = 1
	if planet_caught_moment(moment_mult):
		i += 1
	return mini(i, GRADES.size() - 1)


static func planet_grade(craft: float, moment_mult: float) -> String:
	return GRADES[planet_grade_index(craft, moment_mult)]


## Everything the review shows for one planet photo:
##   craft         0..1, see planet_craft
##   skill         SafariScoring.skill_moment(craft, moment_mult) - kept for the price (and old readers)
##   grade         "Smudge" / "Fair" / "Fine" / "Gallery"  (planet_grade - NOT the flight's grade_for)
##   grade_idx     0..3, the same grade as a number
##   moment        true when the moment was caught (the grade's one-step lift)
##   price         stardust it is worth                     (price_of, the flight's formula)
##   rarity10      the rarity boost shown out of 10: round(10 * rarity_frac) = 0 / 3 / 7 / 10
##   rarity_dust   the stardust the rarity alone adds       (PAY_RARITY * rarity_frac)
##   moment_mult   echoed back, clamped to the flight's MOMENT_FLOOR..MOMENT_CEILING
static func planet_photo(centred10: float, size10: float, focus10: float, rarity: int,
		moment_mult: float = MOMENT_FLOOR, facing10: float = -1.0) -> Dictionary:
	var craft := planet_craft(centred10, size10, focus10, facing10)
	var mm := clampf(moment_mult, MOMENT_FLOOR, MOMENT_CEILING)
	var gi := planet_grade_index(craft, mm)
	return {
		"craft": craft,
		"skill": skill_moment(craft, mm),
		"grade": GRADES[gi],
		"grade_idx": gi,
		"moment": planet_caught_moment(mm),
		"price": price_of(rarity, craft, mm),
		"rarity10": int(round(10.0 * rarity_frac(rarity))),
		"rarity_dust": int(round(PAY_RARITY * rarity_frac(rarity))),
		"moment_mult": mm,
	}
