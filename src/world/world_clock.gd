class_name WorldClock
extends RefCounted
## CLOCK spike (2026-09-21, scratch only, off the round-2 sky-review2 merge). THE DAY IS STILL 20
## REAL MINUTES; NIGHT IS NOW EXACTLY HALF OF IT. One place owns that arithmetic so the forecast
## and the environment cannot disagree.
##
## THE USER'S CALL, verbatim: "the night should only be 10 minutes with a full day as 20 minutes."
## Round 2 pinned the whole cycle to 20 minutes but only CHOSE the dark-time multiplier (0.5),
## which let dark fall out at 11.60 real min (58% of the cycle) - close, not exact, and not the
## even day/night split asked for now.
##
## THE FIX IS ONE SUBSTITUTION, NOT A NEW KNOB. DARK_TIME_SCALE stops being chosen and becomes
## DERIVED, from the constraint that the two halves of the cycle take equal real time:
##
##   lit_real  = LIT_HOURS  / 24 * DAY_LENGTH_SEC
##   dark_real = DARK_HOURS / 24 * DAY_LENGTH_SEC / DARK_TIME_SCALE
##   want lit_real == dark_real  =>  DARK_TIME_SCALE = DARK_HOURS / LIT_HOURS
##
## With the sun arc UNCHANGED (SUN_RISE_HOUR/SUN_SET_HOUR still 5.6/19.8, same as round 2 and the
## same reason: 19.8 not 18.0 keeps the 18-20 "dusk" phase a real golden hour), LIT_HOURS = 14.2,
## DARK_HOURS = 9.8, both exact fifths (71/5 and 49/5), so the fraction is exact too:
##   DARK_TIME_SCALE = 9.8 / 14.2 = 49/71 = 0.690141 (was 0.5)
## DAY_LENGTH_SEC keeps the SAME formula as round 2 (still an inversion of DAY_REAL_SEC, nothing
## fitted) - only the DARK_TIME_SCALE it is fed changed:
##   DAY_LENGTH_SEC = 1200 * 24 / (14.2 + 9.8 / (49/71)) = 1200 * 24 / 28.4 = 72000/71 = 1014.085 s
## (9.8 / (49/71) = 14.2 exactly - the dark stretch now costs precisely as many "lit-equivalent"
## hours as the lit half has, which is what makes the two halves equal by construction.)
##
## WHAT THAT BUYS (arithmetic on the constants, confirmed headless - see this round's report):
##   dark  9.8 game h at 0.690141x -> 600.00 s = 10.00 real min  (50.0% of the day)
##   lit  14.2 game h at 1.0x      -> 600.00 s = 10.00 real min  (50.0%)
##   day  24.0 game h              -> 1200.00 s = 20.00 real min
##   one dark game hour = 61.22 s      one lit game hour = 42.25 s
##
## The speed still changes only at SUN_RISE_HOUR and SUN_SET_HOUR, both with the sun on the rim and
## the frame already dark, so dusk and dawn stay smooth and no phase edge moved. The stars are up
## all day either way (environment.gd STAR_DAY_SCALE), so the morning hours stay watchable.
##
## EVERY CADENCE KEYED TO GAME HOURS OR GAME DAYS NOW LANDS SOMEWHERE ELSE IN REAL TIME AGAIN (the
## dark-hour cost dropped from 71.01 s to 61.22 s). Re-measured and reported; NOT re-tuned here -
## the lead rules on those. See this round's report.

## A whole day, in real seconds. The user's number, unchanged this round.
const DAY_REAL_SEC := 1200.0
## The sun arc that was already in environment.gd. These are the only "dark" boundary there is,
## and they are UNCHANGED this round (dusk/dawn stay exactly where round 2 left them).
const SUN_RISE_HOUR := 5.6
const SUN_SET_HOUR := 19.8

const LIT_HOURS := SUN_SET_HOUR - SUN_RISE_HOUR
const DARK_HOURS := 24.0 - LIT_HOURS
## Clock speed while the sun is below the horizon. DERIVED, not chosen (see header): the multiplier
## that makes the dark half of the cycle cost exactly as many real seconds as the lit half.
const DARK_TIME_SCALE := DARK_HOURS / LIT_HOURS
## Real seconds a whole day would take if the clock never slowed. Same inversion as round 2, fed
## the new DARK_TIME_SCALE.
const DAY_LENGTH_SEC := DAY_REAL_SEC * 24.0 / (LIT_HOURS + DARK_HOURS / DARK_TIME_SCALE)


## How fast the clock runs at `hour`, relative to DAY_LENGTH_SEC.
static func rate(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	return 1.0 if (h >= SUN_RISE_HOUR and h <= SUN_SET_HOUR) else DARK_TIME_SCALE


## Real seconds one game hour takes at `hour`. 35.50 in daylight, 71.01 in the dark.
static func sec_per_hour(hour: float) -> float:
	return DAY_LENGTH_SEC / 24.0 / rate(hour)


## Real seconds of play between two clock readings, going FORWARD (wrapping past midnight).
## Integrates the two speeds properly instead of assuming one of them.
static func real_seconds_between(h0: float, h1: float) -> float:
	var a := fposmod(h0, 24.0)
	var span := fposmod(h1 - a, 24.0)
	var out := 0.0
	var left := span
	var h := a
	# Walk segment by segment; the only boundaries are sunrise and sunset.
	while left > 0.0001:
		var step: float = minf(left, _hours_to_next_edge(h))
		# Sample the speed in the MIDDLE of the segment. Sampling at `h` reads the wrong side of a
		# boundary when the span starts exactly at sunset (19.8 counts as lit), which silently
		# charged a whole 9.8 h night at the daylight rate - measured, 2026-09-20.
		out += step * sec_per_hour(fposmod(h + step * 0.5, 24.0))
		h = fposmod(h + step, 24.0)
		left -= step
	return out


## Game hours from `h` to the next speed change (sunrise or sunset).
static func _hours_to_next_edge(h: float) -> float:
	var x := fposmod(h, 24.0)
	var d_rise := fposmod(SUN_RISE_HOUR - x, 24.0)
	var d_set := fposmod(SUN_SET_HOUR - x, 24.0)
	if d_rise <= 0.0001:
		d_rise = 24.0
	if d_set <= 0.0001:
		d_set = 24.0
	return minf(d_rise, d_set)


## Game hours that `seconds` of play buys, starting at `hour`. The inverse of the above.
static func hours_for_seconds(hour: float, seconds: float) -> float:
	var left := maxf(seconds, 0.0)
	var h := fposmod(hour, 24.0)
	var out := 0.0
	var guard := 0
	while left > 0.001 and guard < 64:
		guard += 1
		var edge := _hours_to_next_edge(h)
		var sph := sec_per_hour(fposmod(h + edge * 0.5, 24.0))
		var can := edge * sph
		if can >= left:
			out += left / sph
			return out
		out += edge
		left -= can
		h = fposmod(h + edge, 24.0)
	return out


## "2m 10s" / "45s". Player-facing, so it is real minutes, never game hours.
static func short_time(seconds: float) -> String:
	var s := int(round(maxf(seconds, 0.0)))
	if s < 60:
		return "%ds" % s
	return "%dm %02ds" % [s / 60, s % 60]
