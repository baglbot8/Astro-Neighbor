class_name SafariTransit
extends RefCounted
## MODE round (2026-09-21, scratch only), REWIRED by the WIRE round the same day. Carries a
## "Photo time!" request across the scene change from the pad to `safari_flight.tscn`, the same way
## `RocketJourney` (src/rocket/journey_state.gd) carries a normal flight's seam frame across ITS
## scene changes. Everything here is static so the record outlives the pad node that wrote it;
## `safari_flight.gd` reads it once in `_ready()` and nothing else needs to know it exists.
##
## WHAT THE WIRE ROUND CHANGED. This file used to ask safari_cast.gd's two-entry ROUTES table
## whether a pair was "flyable", and only home<->zorp ever was - which is why the pad's mode card
## came up with a dead tile on every other trip. SafariLanes covers all 21 pairs and all 42
## directed trips, so there is no such thing as an uncast pair any more, and the question the pad
## has to ask changed with it: not "is there a route" but "IS A PHOTO RUN POSSIBLE RIGHT NOW".

## THE SPACE SAFARI IS RETIRED (docs/PLANET_SAFARI_SPEC.md 15.1, user ruling 2026-09-26: "retire it
## but switch the code off for now in case we want to do something with it"). ONE SWITCH. While it is
## false no trip is a photo trip: `photo_possible` is false for every one of the 42 directed trips, the
## pad (rocket_pad.gd `_on_destination_chosen`) never opens the mode card and runs the plain one-tap
## launch on every trip - including an old save that still holds an open sky ask or the Professor's
## old lantern-fish ask - and an ordinary hop bills its real seconds through environment.gd's own
## `_charge_absence` (only `safari_flight.gd` ever sets the 6-hour override, and it is never entered).
## The flight code, catalog, lanes and the flight tutorial stay on disk, untouched.
## A `static var`, not a `const`, only so the dev menu's World tab can flip it for a test (spec 15.1:
## "a dev-menu row can turn the switch on for a test (not saved)"). Nothing writes it to the save, so
## every launch of the game starts with it false.
const SPACE_SAFARI_DEFAULT := false
static var SPACE_SAFARI: bool = SPACE_SAFARI_DEFAULT

static var origin_id: String = ""
static var dest_id: String = ""
static var route_id: String = ""
static var hour: float = 9.5


## The lane that flies this pair, in either direction, or "" if either id is not a world or the
## trip goes nowhere.
static func route_id_for(origin: String, dest: String) -> String:
	if origin == dest:
		return ""
	return SafariLanes.lane_id_for(origin, dest)


## IS A PHOTO RUN POSSIBLE ON THIS TRIP? Two clauses now, and both are things a player can see:
##
##   1. A LANE. SafariLanes has one for every pair of the seven worlds, so this is only false for a
##      destination that is not a world, or for a trip to where you already are.
##   2. NOT AN ERRAND - UNLESS SOMEONE IS WAITING THERE. A trip TO the Commons is never a photo
##      run. The user's rule is that "a quick errand must stay quick", and the Commons is where the
##      errands are - the shops, Gloop's table, the game board. Going there, you leave the camera
##      at home. MEASURED before this clause existed: with plates in hand the Commons trip opened
##      the mode card and cost the extra tap on every errand of the day (the WIRE round's report,
##      `wire_commons.json`).
##
##      THE ERRAND EXCEPTION (S4 round, docs/STORY_SPINE_SPEC.md 2.5, user ruling 2026-09-22:
##      "yes the professor can give a task to start, but it should be only available en route to
##      the commons where you meet him"). The Professor's opening radio call opens a one-way ask
##      pointed at the Commons (`PhotoAsks`, written by `src/onboarding/intro_director.gd`), and a
##      neighbour's own ask could point there too one day - so BOTH rulings hold at once: a trip to
##      the Commons offers "Photo time!" ONLY while `PhotoAsks.any_to(ERRAND_WORLD, hour)` is true
##      for the hour you would leave at. The moment every open ask pointed at the Commons is closed
##      (`PhotoAsks.remove`, done in person by whoever asked - the Professor, at the Commons,
##      `src/campaign/professor_ask.gd`), this clause goes false again and a Commons trip is back to
##      being the exact one-tap errand it always was - same code path below, nothing byte-different.
##
##      WHAT IT COSTS, said out loud so the lead can overrule it: six of the forty-two directed
##      trips (home/zorp/bolt/fen/grig/vela -> hub) lose their photo option WHILE NO ASK POINTS
##      THERE. No LANE is lost - the Commons Run still flies hub->zorp, hub->bolt and zorp<->bolt,
##      and every other lane still flies both ways on its other pairs - but a sight gated `dir: in`
##      on one of those six trips has to be caught on a different pair of the same lane.
##
##      THE OTHER SIDE OF THE SAME RULING (S5 round, STORY_SPINE_SPEC.md 6.3, 2026-09-22): "while
##      the Professor's ask is open, 'Photo time!' is offered only on trips to the Commons." As S4
##      shipped it, a new player could still fly to Zorp or Bolt in photo mode BEFORE ever going to
##      the Commons - no ask on board, and the flight-tutorial that is supposed to run on the
##      Professor's own first flight (SAFARI_FLIGHT_SPEC.md R14) would run on the wrong trip
##      instead. So the gate below runs BOTH ways: while `is_professor_ask_open()` is true, every
##      trip that does NOT end at the Commons is refused even though its lane exists and would
##      otherwise fly. The moment he collects the photo in person and closes the ask
##      (`ProfessorAsk.run`, the only place that ever removes it), this clause goes false again and
##      every trip is exactly as before. A save already past his radio call never gets this ask at
##      all (`PhotoAsks.add` runs only from `intro_director.gd::_campaign_call`), so nothing is
##      gated for it - STORY_SPINE_SPEC 6.3's own closing line.
##
## THE THIRD CLAUSE, FILM, IS GONE (DAY round, 2026-09-21). The WIRE round made an empty day box
## the reason "Photo time!" could be a dead tile. The lead's ruling deleted the day box: every
## photo flight loads a full magazine (GameState.film_capacity()), so film can never be the reason
## you cannot fly one. THE CLOCK IS THE LIMIT INSTEAD - see PHOTO_TRIP_HOURS below. The clock never
## BLOCKS a flight either; it charges for it, which is the difference between a wall and a price.
## THE PAD ASKS THIS BEFORE IT OPENS ANY CARD, which is the whole of "a plain errand is one tap
## again": where this is false the pad runs exactly the shipped one-tap launch, byte for byte.
static func photo_possible(origin: String, dest: String) -> bool:
	if not SPACE_SAFARI:
		return false
	if route_id_for(origin, dest) == "":
		return false
	if is_professor_ask_open() and dest != ERRAND_WORLD:
		return false
	if dest != ERRAND_WORLD:
		return true
	return PhotoAsks.any_to(ERRAND_WORLD, GameState.time_of_day)


## True while the Professor's own lantern-fish ask is still open (STORY_SPINE_SPEC 6.3) - the one
## ask that ever carries "by": "professor". A neighbour's own ask never gates a trip this way.
static func is_professor_ask_open() -> bool:
	return str(PhotoAsks.get_ask("lantern_fish").get("by", "")) == "professor"


## The Commons. `hub` is its code id (GameState.PLANET_IDS); CORE_LOOP.md renamed Starport Plaza to
## the Commons but the save's id never changed.
const ERRAND_WORLD := "hub"


## Kept for callers that only want to know a lane exists.
static func is_flyable(origin: String, dest: String) -> bool:
	return route_id_for(origin, dest) != ""


## Why "Photo time!" cannot be picked, in player words under 60 characters, or "" when it can.
## S4 round: only says "an errand" when it actually is one right now - see `photo_possible`'s
## header comment for the errand exception. While an open ask points at the Commons, this returns
## "" for a Commons trip exactly like it would for any other reachable world.
## S5 round (STORY_SPINE_SPEC.md 6.3): a new reason for the Professor's own gate - every non-Commons
## trip while his ask is open.
static func photo_blocked_reason(origin: String, dest: String) -> String:
	if not SPACE_SAFARI:
		return "photo flights are switched off"
	if route_id_for(origin, dest) == "":
		return "no lane that way yet"
	if is_professor_ask_open() and dest != ERRAND_WORLD:
		return "fly to the Commons for the Professor first"
	if dest == ERRAND_WORLD and not PhotoAsks.any_to(ERRAND_WORLD, GameState.time_of_day):
		return "the Commons run is an errand"
	return ""


# ------------------------------------------------------------------ WHAT A PHOTO TRIP COSTS
## THE CLOCK IS THE LIMIT (DAY round, 2026-09-21, scratch only).
##
## THE USER: "Playing the game should take up real time in the day as you fly through, so you cant
## infinitely play the safari." So a photo flight does not cost plates, it costs DAYLIGHT - and it
## costs far more of it than the 63 seconds it takes, because you were not travelling, you were
## stopping and waiting and lining up shots the whole way.
##
## WHAT IT COST BEFORE THE R4 REBUILD, MEASURED AT THE TIME (`showcase/rocket_pad.tscn
## --photo=zorp --auto`, that round's report, lanes still 52-78 s - STALE COMMENT FIXED THIS ROUND,
## S5, docs/STORY_SPINE_SPEC.md carried item: this paragraph used to read as if it were still
## current): the whole leg - the 6 s pad beat, the 56 s lane, the haul card - billed the day 63.5
## real seconds, which `_charge_absence` turned into 1.50 game hours at the daylight rate. A 20
## real-minute day is 1200 s, so one photo flight cost 5.3% of a day and the day held about fourteen
## of them. That is the reviewer's "4 percent of a day" from the other side: the film box held one
## flight, and the CLOCK held fourteen. THAT LANE LENGTH IS GONE - lanes run 156-234 s now (R4,
## below), so this specific 56 s/63.5 s/fourteen-a-day arithmetic is history, kept only so nobody
## re-derives the old, now-wrong PHOTO_TRIP_HOURS a second time.
##
## THE OLD NUMBER, AND WHY IT BROKE (kept so nobody re-derives 4.9 and re-introduces the bug):
##   PHOTO_TRIP_HOURS = WorldClock.DARK_HOURS / 2  =  9.8 / 2  =  4.9 game hours
## solved when lanes ran 52-78 s. SAFARI_FLIGHT_SPEC.md R4 (2026-09-21) triples run length to
## 156-234 s (`safari_lanes.gd`'s own values x3), and the flat charge has to clear the LONGEST lane
## flown in DAYLIGHT (the cheapest rate the clock has, `WorldClock.rate` 1.0x) or the surcharge in
## `safari_flight.gd::_begin_clock_burn` (`_extra_hours_total = maxf(0.0, trip_hours() - wall_hours)`)
## clamps to zero and `trip_cost_line()` understates the true charge. RE-DERIVED HERE, 2026-09-22,
## from the clock's own constants (`WorldClock.DAY_LENGTH_SEC`, 2026-09-21's CLOCK spike; a lit
## game hour costs `WorldClock.sec_per_hour(9.5)` = 1014.085/24 = 42.2535 real s, unchanged since):
##   longest lane at 3x (SafariLanes' "longhome", 78 s x 3 today)      =  234.0 s   flight
##   + SafariRun.PAD_SEC (the leaving-the-pad beat safari_flight.gd already bills)  =    6.0 s   pad
##   + HAUL_READ_SEC (safari_flight.gd's own assumed haul-card read)   =   10.0 s   haul card
##   = 250.0 s, in daylight: 250.0 / 42.2535 = 5.917 game hours
## 4.9 h is BELOW 5.917 h - the old flat charge could never cover the rebuilt longest lane, the
## surcharge always clamped to 0, and the card's "about five hours" line was already wrong before a
## single frame of the rebuild shipped. PHOTO_TRIP_HOURS = 6.0 is the number SAFARI_FLIGHT_SPEC.md
## #6.3 fixes for this reason: it is the smallest round figure that still clears 5.917 h, leaving a
## sliver of real surcharge (0.083 h, ~3.5 daylight seconds) on even the longest, brightest run, so
## the loadout card's promise stays true on every lane, not just the short ones.
##
## WHAT THAT COSTS THE DAY, at 2026-09-21's clock (unchanged by this round: a lit game hour is
## 42.25 real s, a dark one 61.22 s, a whole day 1200 real s = 20 real minutes, 10 of it dark):
##   a night flight costs 6.0 x 61.22 = 367.3 real s of the 600 s (10-min) night -> 1.63 per night
##   a day flight   costs 6.0 x 42.25 = 253.5 real s of the 600 s (10-min) day   -> 2.37 per day
##   dawn-to-dawn, flights only, ignoring ground time between legs               -> 4.00 a day
## Section 3's ruling of "2 to 3 photo flights a day" (SAFARI_FLIGHT_SPEC.md, unchanged) is a
## PLAYED number, not the clock's raw capacity: a day also holds errands, the Commons and sleep, so
## a player who actually flies 2-3 (12-18 h) still has 6-12 h of the day for the rest of it - see
## this round's report for the measured day ledger (`safari_flight.tscn --auto --hour=H --trips=N`,
## `DAYLEDGER` lines) on the longest and shortest lane, day and night.
##
## IT IS A FLAT COST, NOT ONE PER LANE SECOND (unchanged reasoning from the 4.9 h round). The lanes
## run 156-234 s now, and a longer lane already pays more (`pay_band`); charging it more day as well
## would make the short lanes the only sensible flight. One flight, one price, the way a player can
## hold it in their head: a safari costs you about six hours.
const PHOTO_TRIP_HOURS := 6.0


## Game hours a photo trip costs the day clock, INCLUDING the real seconds it takes - the flight
## scene bills the difference itself (src/sky/safari_flight.gd). One number for every lane.
static func trip_hours() -> float:
	return PHOTO_TRIP_HOURS


## What it costs, in player words, <= 60 characters. Shown on the flight's own loadout card before
## anything takes off; anything else that wants to warn a player can call the same line.
static func trip_cost_line() -> String:
	return "This trip costs about %d hours of the day." % int(round(PHOTO_TRIP_HOURS))


static func begin(origin: String, dest: String) -> void:
	origin_id = origin
	dest_id = dest
	route_id = route_id_for(origin, dest)
	hour = GameState.time_of_day


static func clear() -> void:
	origin_id = ""
	dest_id = ""
	route_id = ""
