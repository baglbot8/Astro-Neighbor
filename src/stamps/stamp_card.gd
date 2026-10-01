extends RefCounted
## NORM'S STAMP CARD: the rules and the saved state (docs/DAILY_STAMPS_SPEC.md 2). Static only, no
## `class_name` (loaded by path, like norm_lines.gd), nothing here draws or listens.
##
##   * A card of CARD_SIZE small tasks per REAL local day; any NEED of them earn that day's stamp.
##   * A week is Monday to Sunday (local). WEEK_NEED stamps in a week = one prize owed, claimed from
##     Norm. Extra stamps that week do nothing more. Owed prizes wait for ever. A missed week loses
##     nothing but that week's prize.
##   * Prizes are the catalog items with "source": "stamps", decorations first then outfits, in
##     catalog order. When every one has been given, a prize is a choice of any stamp decoration again.
##   * No penalties, no streaks, no timers. Changing the device clock can cheat it; accepted.
##
## SAVED: one Dictionary, GameState.flags["stamps"] (flags is already in the save file):
##   on        bool    Norm has handed over the first card (nothing is tracked before that)
##   date      String  "YYYY-MM-DD", the local day the card below belongs to
##   tasks     Array   [{id, n}] today's five, n = progress toward TASKS[id].goal
##   marks     Dictionary  {task id: [things already counted]} for the "3 different" tasks
##   stamped   bool    today's stamp is earned
##   week      String  the Monday of the week `stamps` belongs to
##   stamps    Array   the dates stamped this week
##   week_paid bool    this week's prize is already counted in `owed`
##   owed      int     prizes earned and not yet collected from Norm
##   given     Array   prize ids handed out so far, in order (repeats included)
##   chat      String  the date Norm last said his line of the day
##
## THE DATE: `today()` is the device's local date. A test sets it with `--stamp-date=YYYY-MM-DD`
## (after the `--`) or `debug_set_date()` / `debug_advance()`; the override is never saved.

const KEY := "stamps"
const SOURCE := "stamps"
const CARD_SIZE := 5
const NEED := 3
const WEEK_NEED := 5
## How many of the five come from the "easy" half of the pool (things any save can do on any day).
const EASY_SLOTS := 3

const PLANET_SAFARI := "res://src/planet_safari/planet_safari.gd"
const REPLAY_BOARD := "res://src/minigames/replay_board.gd"
const NORM_SYSTEM := "res://src/campaign/norm_system.gd"
const NEIGHBOURS: Array[String] = ["zorp", "bolt", "fen", "grig", "vela"]
const WORLDS: Array[String] = ["home", "hub", "zorp", "bolt", "fen", "grig", "vela", "jungle"]

## The pool. `goal` = how many; `easy` = always possible; `group` = at most one of a group per card.
const TASKS := {
	"deco": {"text": "Buy or place a decoration", "goal": 1, "easy": true},
	"talk3": {"text": "Talk to 3 neighbours", "goal": 3, "easy": true},
	"visit2": {"text": "Fly to 2 planets", "goal": 2, "easy": true},
	"outfit": {"text": "Change your outfit", "goal": 1, "easy": true},
	"scrap": {"text": "Pick up 10 scrap", "goal": 10, "easy": true},
	"materials": {"text": "Gather 5 materials", "goal": 5, "easy": true},
	"album": {"text": "Take a photo at home", "goal": 1, "easy": true},
	"minigame": {"text": "Play a mini-game", "goal": 1, "easy": false},
	"safari": {"text": "Finish a photo safari", "goal": 1, "easy": false},
	"fine_photo": {"text": "Take a Fine photo or better", "goal": 1, "easy": false, "group": "photo"},
	"new_photo": {"text": "Photograph something new", "goal": 1, "easy": false, "group": "photo"},
	"favour": {"text": "Do a favour for a neighbour", "goal": 1, "easy": false},
	"prints": {"text": "Bring prints to Gloop", "goal": 1, "easy": false},
	"quiz": {"text": "Win Norm's quiz", "goal": 1, "easy": false},
	"tidy": {"text": "Tidy 3 bits of space junk", "goal": 3, "easy": false},
}

static var _debug_date := ""
static var _args_read := false


# ============================================================================= the date
## The local date, "YYYY-MM-DD" (or the test override).
static func today() -> String:
	if not _args_read:
		_args_read = true
		for a: String in OS.get_cmdline_user_args():
			if a.begins_with("--stamp-date=") and _valid_date(a.substr(13)):
				_debug_date = a.substr(13)
	if _debug_date != "":
		return _debug_date
	return Time.get_date_string_from_system()


static func _valid_date(d: String) -> bool:
	return d.length() == 10 and d[4] == "-" and d[7] == "-" and date_of(day_number(d)) == d


## Whole days since 1970-01-01 for a "YYYY-MM-DD" date (pure calendar maths, no time zone).
static func day_number(date: String) -> int:
	return int(floor(float(Time.get_unix_time_from_datetime_string(date + "T00:00:00")) / 86400.0))


static func date_of(n: int) -> String:
	return Time.get_date_string_from_unix_time(n * 86400)


## 0 = Monday .. 6 = Sunday. 1970-01-01 was a Thursday.
static func weekday(date: String) -> int:
	return posmod(day_number(date) + 3, 7)


## The Monday of `date`'s week.
static func week_start(date: String) -> String:
	return date_of(day_number(date) - weekday(date))


# ============================================================================= state
## Read-only view ({} before Norm has handed over a card). Never writes the save.
static func peek() -> Dictionary:
	var v: Variant = GameState.flags.get(KEY, null)
	return v as Dictionary if v is Dictionary else {}


static func _s() -> Dictionary:
	var v: Variant = GameState.flags.get(KEY, null)
	if not (v is Dictionary):
		v = {}
		GameState.flags[KEY] = v
	return v as Dictionary


static func is_on() -> bool:
	return bool(peek().get("on", false))


## Norm hands over the first card.
static func start() -> void:
	var s := _s()
	s["on"] = true
	if not s.has("owed"):
		s["owed"] = 0
	if not (s.get("given") is Array):
		s["given"] = []
	roll()


## Brings the card up to today. Returns true when a NEW card was dealt (a new day). A new week
## clears the week's stamps; `owed` and `given` are never touched here.
static func roll() -> bool:
	if not is_on():
		return false
	var s := _s()
	# JSON turns every whole number into a float; put them back once per load.
	if s.get("owed") is float or (s.get("tasks") is Array and not (s["tasks"] as Array).is_empty() \
			and (s["tasks"] as Array)[0] is Dictionary and ((s["tasks"] as Array)[0] as Dictionary).get("n") is float):
		var fixed: Dictionary = GameState._deep_ints(s)
		GameState.flags[KEY] = fixed
		s = fixed
	var t := today()
	var wk := week_start(t)
	if str(s.get("week", "")) != wk:
		s["week"] = wk
		s["stamps"] = []
		s["week_paid"] = false
	if str(s.get("date", "")) == t and s.get("tasks") is Array and not (s["tasks"] as Array).is_empty():
		return false
	s["date"] = t
	s["tasks"] = pick_tasks(t)
	s["marks"] = {}
	s["stamped"] = (s.get("stamps", []) as Array).has(t)
	return true


static func tasks() -> Array:
	var v: Variant = peek().get("tasks", [])
	return v as Array if v is Array else []


static func goal(id: String) -> int:
	return int((TASKS.get(id, {}) as Dictionary).get("goal", 1))


static func text(id: String) -> String:
	return str((TASKS.get(id, {}) as Dictionary).get("text", id))


static func task_n(t: Dictionary) -> int:
	return clampi(int(t.get("n", 0)), 0, goal(str(t.get("id", ""))))


static func task_done(t: Dictionary) -> bool:
	return task_n(t) >= goal(str(t.get("id", "")))


static func done_count() -> int:
	var n := 0
	for t: Variant in tasks():
		if t is Dictionary and task_done(t as Dictionary):
			n += 1
	return n


static func stamped_today() -> bool:
	return bool(peek().get("stamped", false))


## The dates stamped this week.
static func week_stamps() -> Array:
	var v: Variant = peek().get("stamps", [])
	return v as Array if v is Array else []


static func owed() -> int:
	return int(peek().get("owed", 0))


## True once this week's five stamps have earned its prize (collected or not).
static func week_won() -> bool:
	return bool(peek().get("week_paid", false))


static func has_task(id: String) -> bool:
	for t: Variant in tasks():
		if t is Dictionary and str((t as Dictionary).get("id", "")) == id:
			return true
	return false


# ============================================================================= progress
## Adds `amount` to task `id` if it is on today's card. Returns what happened:
##   {"task": true}   that task just reached its goal
##   {"stamp": true}  ... and it was the NEED-th, so today's stamp is earned
##   {"prize": true}  ... and it was the week's WEEK_NEED-th stamp, so a prize is owed
## {} when nothing changed (not on, not on the card, already done).
static func progress(id: String, amount: int = 1) -> Dictionary:
	if not is_on() or amount <= 0:
		return {}
	roll()
	for t: Variant in tasks():
		if not (t is Dictionary) or str((t as Dictionary).get("id", "")) != id:
			continue
		var d := t as Dictionary
		if task_done(d):
			return {}
		d["n"] = mini(goal(id), int(d.get("n", 0)) + amount)
		if not task_done(d):
			return {"moved": true}
		var out := {"task": true}
		out.merge(_check_stamp())
		return out
	return {}


## Counts `what` once for task `id` (three DIFFERENT neighbours, two DIFFERENT planets).
static func mark(id: String, what: String) -> Dictionary:
	if not is_on() or what == "" or not has_task(id):
		return {}
	roll()
	var s := _s()
	if not (s.get("marks") is Dictionary):
		s["marks"] = {}
	var marks := s["marks"] as Dictionary
	if not (marks.get(id) is Array):
		marks[id] = []
	var seen := marks[id] as Array
	if seen.has(what):
		return {}
	seen.append(what)
	return progress(id, 1)


static func _check_stamp() -> Dictionary:
	var s := _s()
	if bool(s.get("stamped", false)) or done_count() < NEED:
		return {}
	s["stamped"] = true
	if not (s.get("stamps") is Array):
		s["stamps"] = []
	var st := s["stamps"] as Array
	var out := {"stamp": true}
	if not st.has(str(s.get("date", ""))):
		st.append(str(s.get("date", "")))
	if st.size() >= WEEK_NEED and not bool(s.get("week_paid", false)):
		s["week_paid"] = true
		s["owed"] = int(s.get("owed", 0)) + 1
		out["prize"] = true
	return out


# ============================================================================= prizes
## Every stamp prize, decorations first then outfits, each in catalog order.
static func prize_list() -> Array[String]:
	var decos: Array[String] = []
	var wear: Array[String] = []
	for d: Variant in Catalog.all_items():
		if not (d is Dictionary) or str((d as Dictionary).get("source", "")) != SOURCE:
			continue
		if str((d as Dictionary).get("kind", "")) == "decoration":
			decos.append(str((d as Dictionary)["id"]))
		elif str((d as Dictionary).get("kind", "")) == "clothing":
			wear.append(str((d as Dictionary)["id"]))
	decos.append_array(wear)
	return decos


static func given() -> Array:
	var v: Variant = peek().get("given", [])
	return v as Array if v is Array else []


## The prizes not handed out yet, in order.
static func ungiven() -> Array[String]:
	var g := given()
	var out: Array[String] = []
	for id: String in prize_list():
		if not g.has(id):
			out.append(id)
	return out


## The next new prize, or "" when every one has been given (then it is a choice, `repeat_choices`).
static func next_prize() -> String:
	var u := ungiven()
	return u[0] if not u.is_empty() else ""


## The silhouette on the card: the prize this week's stamps earn - the first one not given and not
## already spoken for by an older owed prize. Once this week's prize is won AND collected it is next
## week's. "" when the list has run out (a choice instead).
static func week_prize() -> String:
	var u := ungiven()
	var ahead := maxi(0, owed() - (1 if week_won() else 0))
	return u[ahead] if ahead < u.size() else ""


## What a repeat prize may be: any stamp DECORATION (a second copy of an outfit is no prize).
static func repeat_choices() -> Array[String]:
	var out: Array[String] = []
	for id: String in prize_list():
		if str(Catalog.get_item(id).get("kind", "")) == "decoration":
			out.append(id)
	return out


## Hands over one owed prize: the next new one, or `choice` (a repeat). Puts it in the bag (an
## outfit also goes in the wardrobe, as the cave chest does). Returns the id, "" when none is owed
## or nothing can be given.
static func claim(choice: String = "") -> String:
	if owed() <= 0:
		return ""
	var id := next_prize()
	if id == "":
		id = choice if repeat_choices().has(choice) else ""
	if id == "" or not Catalog.has_item(id):
		return ""
	var s := _s()
	s["owed"] = int(s.get("owed", 0)) - 1
	if not (s.get("given") is Array):
		s["given"] = []
	(s["given"] as Array).append(id)
	if str(Catalog.get_item(id).get("kind", "")) == "clothing":
		if not GameState.wardrobe.has(id):
			GameState.wardrobe.append(id)
		if GameState.item_count(id) <= 0:
			GameState.add_item(id, 1)
	else:
		GameState.add_item(id, 1)
	return id


# ============================================================================= the pool
## Today's five for `date`: only tasks this save can reach now, EASY_SLOTS from the easy half, the
## rest from the other half, at most one per group. Seeded by the date, so one day gives one card.
static func pick_tasks(date: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["astro_stamps", date])
	var easy: Array[String] = []
	var rest: Array[String] = []
	for id: String in TASKS:
		if not reachable(id):
			continue
		if bool((TASKS[id] as Dictionary).get("easy", false)):
			easy.append(id)
		else:
			rest.append(id)
	_shuffle(easy, rng)
	_shuffle(rest, rng)
	var picked: Array[String] = []
	var groups := {}
	_take(picked, groups, easy, EASY_SLOTS)
	_take(picked, groups, rest, CARD_SIZE - picked.size())
	_take(picked, groups, easy, CARD_SIZE - picked.size())
	_shuffle(picked, rng)
	var out: Array = []
	for id: String in picked:
		out.append({"id": id, "n": 0})
	return out


static func _take(picked: Array[String], groups: Dictionary, from: Array[String], n: int) -> void:
	for id: String in from:
		if n <= 0:
			return
		if picked.has(id):
			continue
		var g := str((TASKS[id] as Dictionary).get("group", ""))
		if g != "" and groups.has(g):
			continue
		if g != "":
			groups[g] = true
		picked.append(id)
		n -= 1


static func _shuffle(a: Array[String], rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := a[i]
		a[i] = a[j]
		a[j] = t


## True when this save can do task `id` today. Nothing here writes the save.
static func reachable(id: String) -> bool:
	match id:
		"deco", "scrap", "materials", "album":
			return true
		"talk3", "visit2":
			return CampaignData.planet_in_range("hub")
		"outfit":
			return GameState.wardrobe.size() >= 2
		"minigame":
			if not ResourceLoader.exists(REPLAY_BOARD) or not CampaignData.planet_in_range("hub"):
				return false
			var e: Variant = load(REPLAY_BOARD).call("entries")
			return e is Array and not (e as Array).is_empty()
		"safari", "fine_photo":
			return not safari_worlds().is_empty()
		"new_photo":
			return _unseen_subject()
		"favour":
			for n: String in NEIGHBOURS:
				if GameState.flag("met_" + n) and CampaignData.planet_in_range(n):
					return true
			return false
		"prints":
			var bag: Variant = GameState.flags.get("spike_prints", [])
			return bag is Array and not (bag as Array).is_empty() and CampaignData.planet_in_range("hub")
		"quiz":
			if not ResourceLoader.exists(NORM_SYSTEM):
				return false
			var ns: Variant = load(NORM_SYSTEM)
			# The pure preview (never writes the save): he is standing somewhere today.
			return bool(ns.call("norm_on")) and str((ns.call("plan_today") as Dictionary).get("world", "")) != "" \
				and not bool(ns.call("quiz_ended_today"))
		"tidy":
			return GameState.trash_home.size() >= 3
	return false


## The worlds whose safari this save can take: in range, with a safari, host already met.
static func safari_worlds() -> Array[String]:
	var out: Array[String] = []
	if not ResourceLoader.exists(PLANET_SAFARI):
		return out
	var ps: Variant = load(PLANET_SAFARI)
	for w: String in WORLDS:
		if w != "home" and not CampaignData.planet_in_range(w):
			continue
		var m: Variant = ps.call("manifest", w)
		if not (m is Dictionary) or (m as Dictionary).is_empty():
			continue
		var host := str((m as Dictionary).get("host", ""))
		if host != "" and not GameState.flag("met_" + host) and not GameState.story_done:
			continue
		out.append(w)
	return out


static func _unseen_subject() -> bool:
	var ps: Variant = load(PLANET_SAFARI) if ResourceLoader.exists(PLANET_SAFARI) else null
	if ps == null:
		return false
	for w: String in safari_worlds():
		var m: Dictionary = ps.call("manifest", w)
		for e: Variant in m.get("roster", []):
			# The always-there ones only: a rare or night subject may not show up today.
			if e is Dictionary and ["creature", "common", "neighbour"].has(str((e as Dictionary).get("tier", ""))) \
					and not photographed(str((e as Dictionary).get("id", ""))):
				return true
	return false


## True when the planet scrapbook already holds (or ever graded) a photo of subject `key`.
static func photographed(key: String) -> bool:
	var blob: Variant = GameState.flags.get("planet_journal", null)
	if not (blob is Dictionary):
		return false
	for part: String in ["top", "records"]:
		var d: Variant = (blob as Dictionary).get(part, {})
		if d is Dictionary and (d as Dictionary).has(key):
			return true
	return false


# ============================================================================= dev / test
## Sets the date the card sees ("" = the real one again). Never saved.
static func debug_set_date(date: String) -> String:
	_args_read = true
	if date != "" and not _valid_date(date):
		return "Not a date: %s (want YYYY-MM-DD)." % date
	_debug_date = date
	return "Stamp date: %s (%s)." % [today(), "real" if date == "" else "set by hand"]


## Moves the card's date on by `days` (from the override, or from the real date).
static func debug_advance(days: int = 1) -> String:
	return debug_set_date(date_of(day_number(today()) + days))


## Ticks the first `n` unfinished tasks on today's card (through `progress`, so stamps and prizes
## follow exactly as in play). Returns the merged result.
static func debug_tick(n: int = NEED) -> Dictionary:
	var out := {}
	for t: Variant in tasks():
		if n <= 0:
			break
		if t is Dictionary and not task_done(t as Dictionary):
			var id := str((t as Dictionary)["id"])
			out.merge(progress(id, goal(id)), true)
			n -= 1
	return out


static func debug_reset() -> String:
	GameState.flags.erase(KEY)
	return "Stamp card wiped."


## One line a probe can assert against.
static func debug_line() -> String:
	var ids := PackedStringArray()
	for t: Variant in tasks():
		if t is Dictionary:
			ids.append("%s %d/%d" % [(t as Dictionary)["id"], task_n(t as Dictionary), goal(str((t as Dictionary)["id"]))])
	return "STAMPS on=%s date=%s wd=%d week=%s tasks=[%s] done=%d stamped=%s stamps=%s owed=%d given=%s next=%s" % [
		str(is_on()), today(), weekday(today()), str(peek().get("week", "")), ", ".join(ids), done_count(),
		str(stamped_today()), str(week_stamps()), owed(), str(given()), week_prize()]
