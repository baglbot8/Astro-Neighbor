class_name ShopPanel
extends ItemGridPanel
## Generic buy / sell / build grid for Cosmo Depot, Suit-Up, the crash-site Build Bench and any other
## stall.
##   open(items, "buy", "Cosmo Depot", "Pip & Pop")   # items: Array of Catalog defs or ids
##   open([], "sell", "Cosmo Depot", "Pip & Pop")     # empty list in sell mode = everything sellable in the bag
##   open([], "build", "Build Bench")                 # BUILD_PLAN Phase 2 builder F: entries are read
##                                                     # from ProjectSystem.bench_items() plus any unfitted
##                                                     # rocket-part gift in the bag - `items` is ignored
## Buying: confirm dialog -> GameState.spend_stardust + add_item + toast + "ui_buy".
## Selling pays SELL_RATIO of the price. Unaffordable items are greyed and wobble on attempt.
## Building spends GameState.scrap (+ stardust for some items, CampaignData/project_system.gd
## "stardust_cost") and adds the item to the bag. Fitting a rocket-part gift spends the gift plus
## scrap/stardust, then GameState.fit_rocket_part + EventBus.rocket_part_fitted (the part-celebration
## cutscene listens for that). Both read their costs off the Catalog def (see project_system.gd's
## schema header) - nothing here hardcodes a price for a specific project or part.
##   signal purchased(item_id)   signal sold(item_id)   signal built(item_id)   signal fitted(part_id)   signal closed

signal purchased(item_id: String)
signal sold(item_id: String)
signal built(item_id: String)
signal fitted(part_id: String)

const SELL_RATIO := 0.4
## BUILD_PLAN Phase 2 files ship separately from this panel (see "src/ui/pause/dev_menu.gd" for the
## same pattern). This file never types anything as `ProjectSystem` - the bench read below goes
## through `ResourceLoader.exists()` + `load(PATH).call(...)` so it still parses and runs with
## src/projects/** absent (the "build" grid then just stays empty, same as `_hook_empty_text()`
## already renders when no project is active).
const PROJECT_SYSTEM_PATH := "res://src/projects/project_system.gd"

var mode := "buy"
var shop_title := "Shop"
var shopkeeper := ""
var _stock: Array[Dictionary] = []
var _balance_pill: PanelContainer
var _balance_label: Label
var _balance_star: StarIcon
## Scrap balance pill (BUILD_PLAN Phase 2 "F"): built the same way as `_balance_pill` but hidden
## unless something on screen actually costs scrap, so Cosmo Depot and Suit-Up look exactly as they
## did before scrap existed.
var _scrap_pill: PanelContainer
var _scrap_label: Label

func _hook_modal_name() -> String:
	return "shop"

func _hook_title() -> String:
	return "Shop"

func _hook_hints() -> Array:
	return [["interact", "Select"], ["cancel", "Leave"]]

func _hook_empty_text() -> PackedStringArray:
	if mode == "build":
		return ["Nothing to build", "A neighbour's project will ask for something soon."]
	return ["Sold out!", "Come back tomorrow for new stock."]

func _ready() -> void:
	super()
	_balance_pill = PanelContainer.new()
	_balance_pill.theme_type_variation = "HudPill"
	_balance_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_balance_pill.add_child(row)
	_balance_star = StarIcon.new()
	_balance_star.icon_size = 26.0
	row.add_child(_balance_star)
	_balance_label = UIStyle.make_label("0", "Header")
	row.add_child(_balance_label)
	_header_right.add_child(_balance_pill)
	EventBus.stardust_changed.connect(func(amount: int, _delta: int) -> void:
		_balance_label.text = str(amount)
		if is_open:
			UIStyle.bump(_balance_pill, 1.15)
			_balance_star.spin_once()
			_refresh_affordability())
	_scrap_pill = PanelContainer.new()
	_scrap_pill.theme_type_variation = "HudPill"
	_scrap_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrap_pill.visible = false
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	_scrap_pill.add_child(srow)
	var scrap_icon := Hud.ScrapIcon.new()
	scrap_icon.icon_size = 26.0
	srow.add_child(scrap_icon)
	_scrap_label = UIStyle.make_label("0", "Header")
	srow.add_child(_scrap_label)
	_header_right.add_child(_scrap_pill)
	EventBus.scrap_changed.connect(func(amount: int, _delta: int) -> void:
		_scrap_label.text = str(amount)
		if is_open:
			UIStyle.bump(_scrap_pill, 1.15)
			_refresh_affordability())

## Re-reads GameState.stardust/scrap into every price tag and into the action button.
##
## Affordability used to be sampled ONCE, when the details column was built, so a favour reward or a
## sale that landed while the shop was open left the card greyed and the button reading "Need 1 more"
## at 120 / 120 stardust until the player moved the cursor. Driven by EventBus.stardust_changed /
## scrap_changed.
func _refresh_affordability() -> void:
	for i in mini(_cards.size(), _entries.size()):
		_hook_decorate_card(_cards[i], _entries[i])
	if _selected < 0 or _selected >= _entries.size():
		return
	var was_actions := _nav_state == NavState.ACTIONS
	var wanted := _action_index
	# _show_details rebuilds the action buttons, which frees the focused one - put the focus back.
	_show_details(_selected)
	if not was_actions:
		return
	var pick := clampi(wanted, 0, maxi(0, _action_buttons.size() - 1))
	if _action_buttons.is_empty() or _action_buttons[pick].disabled:
		pick = _first_enabled_action()
	if pick < 0:
		_leave_actions()
		return
	_action_index = pick
	UIFocus.focus(_action_buttons[pick])

## Opens the shop. items = Array of Catalog definitions (Dictionary) or ids (String); ignored in
## "build" mode, where the grid is always read live from ProjectSystem + the bag (see `_bench_entries`).
func open(items: Array, shop_mode: String = "buy", title: String = "Shop", keeper: String = "") -> void:
	mode = shop_mode
	shop_title = title
	shopkeeper = keeper
	_stock.clear()
	for it in items:
		var def: Dictionary = it if it is Dictionary else ItemGridPanel.def_for(str(it))
		if not def.is_empty():
			_stock.append(def)
	_title_label.text = title
	var default_sub := ""
	if mode == "sell":
		default_sub = "Sell your items"
	elif mode == "build":
		default_sub = "Scrap becomes fixes"
	_subtitle_label.text = keeper if keeper != "" else default_sub
	_subtitle_label.visible = _subtitle_label.text != ""
	_balance_label.text = str(GameState.stardust)
	_scrap_label.text = str(GameState.scrap)
	_scrap_pill.visible = mode == "build" or _stock_has_scrap_cost()
	# ItemGridPanel (src/ui/common/item_grid_panel.gd, not owned this phase) reads `_hook_empty_text()`
	# only once, in `_build()` at _ready() time - before `open()` has ever set `mode`, so every panel
	# that reuses this base class shows whatever text was cached at construction (the "buy"/"sell"
	# default here) no matter what `_hook_empty_text()` would return now. MEASURED 2026-09-11: an
	# empty "build" grid showed "Sold out! Come back tomorrow for new stock." instead of "Nothing to
	# build" (captures_desktop/s10_bench_empty_after_fit.png). `_empty_title`/`_empty_sub` are plain
	# Labels on this base class (no real access control in GDScript), so re-stamping them here - every
	# time THIS mode is (re)opened - is a same-file fix rather than a change to a class other Phase 2
	# work also depends on.
	var empty_copy := _hook_empty_text()
	_empty_title.text = empty_copy[0]
	_empty_sub.text = empty_copy[1] if empty_copy.size() > 1 else ""
	_selected = 0
	_scroll.scroll_vertical = 0
	open_panel()

func _stock_has_scrap_cost() -> bool:
	for def in _stock:
		if int(def.get("scrap_cost", 0)) > 0:
			return true
	return false

## Price this shop pays / charges for a definition, in STARDUST. Meaningless in "build" mode, whose
## entries carry their own "scrap_cost"/"stardust_cost" straight from the Catalog def instead.
func price_for(def: Dictionary) -> int:
	var base := int(def.get("price", 0))
	return int(round(base * SELL_RATIO)) if mode == "sell" else base

func _hook_entries(_tab_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mode == "build":
		return _bench_entries()
	if mode == "sell":
		# Fresh array every refresh: aliasing _stock here made the first pass append the bag's defs INTO
		# the stock, so later refreshes stopped rescanning the inventory.
		var defs: Array[Dictionary] = _stock.duplicate()
		if defs.is_empty():
			for id in GameState.inventory.keys():
				defs.append(ItemGridPanel.def_for(str(id)))
		for def in defs:
			var id := str(def.get("id", ""))
			var count := GameState.item_count(id)
			if count <= 0 or int(def.get("price", 0)) <= 0:
				continue
			out.append({"id": id, "def": def, "count": count, "price": price_for(def)})
	else:
		for def in _stock:
			out.append({"id": str(def.get("id", "")), "def": def, "count": 1, "price": price_for(def)})
	return out

## Entries for "build" mode: one per craftable item from every started, unfinished project
## (ProjectSystem.bench_items(), "kind": "build") plus one per unfitted rocket-part gift sitting in
## the bag ("kind": "fit") - a project's items and its part read as one "what can I do at the bench"
## list, since both spend scrap/stardust here. "price" stays -1 (see `_hook_decorate_card`): a
## stardust price tag on the card would misreport a scrap cost.
func _bench_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if ResourceLoader.exists(PROJECT_SYSTEM_PATH):
		var raw: Variant = load(PROJECT_SYSTEM_PATH).call("bench_items")
		if typeof(raw) == TYPE_ARRAY:
			for def: Dictionary in raw:
				var id := str(def.get("id", ""))
				out.append({"id": id, "def": def, "count": GameState.item_count(id), "price": -1, "kind": "build"})
	for item_id in GameState.inventory.keys():
		var id := str(item_id)
		if GameState.rocket_parts.has(id):
			continue
		var def := Catalog.get_item(id)
		if str(def.get("kind", "")) != "rocket_part":
			continue
		out.append({"id": id, "def": def, "count": GameState.item_count(id), "price": -1, "kind": "fit"})
	return out

func _hook_decorate_card(card: ItemCard, entry: Dictionary) -> void:
	if mode == "build":
		# ItemCard (src/ui/common/item_card.gd, not owned this phase) draws its price row as a
		# stardust star; putting a scrap number through it would read as a stardust price that is not
		# true. The card face stays plain here and the real cost lives in the details column instead
		# (_hook_fill_extra), the same place "you have N" already lives for sell mode.
		card.set_price(-1)
		return
	var p := int(entry["price"])
	card.set_price(p, mode == "sell" or GameState.can_afford(p))

func _hook_fill_extra(extra: HBoxContainer, entry: Dictionary) -> void:
	if mode == "build":
		var def: Dictionary = entry["def"]
		_fill_cost_row(extra, int(def.get("scrap_cost", 0)), int(def.get("stardust_cost", 0)))
		if str(entry.get("kind", "")) == "fit":
			extra.add_child(UIStyle.make_label("  + the gift", "Soft"))
		elif int(entry.get("count", 0)) > 0:
			extra.add_child(UIStyle.make_label("  (you have %d)" % int(entry["count"]), "Soft"))
		return
	var p := int(entry["price"])
	var affordable := mode == "sell" or GameState.can_afford(p)
	var star := StarIcon.new()
	star.icon_size = 26.0
	extra.add_child(star)
	var l := UIStyle.make_label(str(p), "Header")
	if not affordable:
		l.add_theme_color_override("font_color", UIStyle.RED)
	extra.add_child(l)
	if mode == "sell":
		var owned := UIStyle.make_label("  (you have %d)" % int(entry.get("count", 0)), "Soft")
		extra.add_child(owned)
	else:
		# A regular shop item that ALSO carries a scrap cost (none ship yet - every project item is
		# "build"-only per project_system.gd's schema - but a future stall could sell one for
		# stardust + scrap, so the same row this file uses for the bench works here too).
		var scrap_cost := int((entry["def"] as Dictionary).get("scrap_cost", 0))
		if scrap_cost > 0:
			extra.add_child(UIStyle.make_label("  +", "Header"))
			var icon := Hud.ScrapIcon.new()
			icon.icon_size = 26.0
			_append_cost(extra, icon, scrap_cost, GameState.can_afford_scrap(scrap_cost))

## One "<icon> <amount>" pair, painted red when unaffordable.
func _append_cost(extra: HBoxContainer, icon: Control, amount: int, affordable: bool) -> void:
	extra.add_child(icon)
	var l := UIStyle.make_label(str(amount), "Header")
	if not affordable:
		l.add_theme_color_override("font_color", UIStyle.RED)
	extra.add_child(l)

## Scrap icon + stardust star, only the ones that are actually > 0, "Free" if neither is.
func _fill_cost_row(extra: HBoxContainer, scrap_cost: int, stardust_cost: int) -> void:
	var wrote := false
	if scrap_cost > 0:
		var icon := Hud.ScrapIcon.new()
		icon.icon_size = 26.0
		_append_cost(extra, icon, scrap_cost, GameState.can_afford_scrap(scrap_cost))
		wrote = true
	if stardust_cost > 0:
		if wrote:
			extra.add_child(UIStyle.make_label("  +", "Header"))
		var star := StarIcon.new()
		star.icon_size = 26.0
		_append_cost(extra, star, stardust_cost, GameState.can_afford(stardust_cost))
		wrote = true
	if not wrote:
		extra.add_child(UIStyle.make_label("Free", "Header"))

func _hook_actions(entry: Dictionary) -> Array:
	if mode == "sell":
		return [{"id": "sell", "label": "Sell", "primary": true}]
	if mode == "build":
		return _build_actions(entry)
	# Unaffordable items get a disabled button that says exactly how short the player is, instead of an
	# inviting yellow "Buy" that only wobbles once it is pressed.
	var short := int(entry.get("price", 0)) - GameState.stardust
	if short > 0:
		return [{"id": "buy", "label": "Need %d more" % short, "primary": true, "disabled": true}]
	return [{"id": "buy", "label": "Buy", "primary": true}]

func _build_actions(entry: Dictionary) -> Array:
	var def: Dictionary = entry["def"]
	var fitting := str(entry.get("kind", "")) == "fit"
	var action_id := "fit" if fitting else "build"
	var label := "Fit part" if fitting else "Build"
	var short_scrap := int(def.get("scrap_cost", 0)) - GameState.scrap
	var short_star := int(def.get("stardust_cost", 0)) - GameState.stardust
	if short_scrap > 0 or short_star > 0:
		return [{"id": action_id, "label": _short_label(short_scrap, short_star), "primary": true, "disabled": true}]
	return [{"id": action_id, "label": label, "primary": true}]

## "Need 4 scrap", "Need 4 scrap + 10 stardust" or "Need 10 stardust" - whichever of the two the
## player is actually short on.
static func _short_label(short_scrap: int, short_star: int) -> String:
	var parts: PackedStringArray = []
	if short_scrap > 0:
		parts.append("%d scrap" % short_scrap)
	if short_star > 0:
		parts.append("%d stardust" % short_star)
	return "Need " + " + ".join(parts)

## "4 scrap", "4 scrap + 10 stardust", "10 stardust" or "" (nothing costs anything).
static func _cost_words(scrap_cost: int, stardust_cost: int) -> String:
	var parts: PackedStringArray = []
	if scrap_cost > 0:
		parts.append("%d scrap" % scrap_cost)
	if stardust_cost > 0:
		parts.append("%d stardust" % stardust_cost)
	return " + ".join(parts)

func _hook_action(entry: Dictionary, action_id: String) -> void:
	match action_id:
		"buy":
			_try_buy(entry)
		"sell":
			_try_sell(entry)
		"build":
			_try_build(entry)
		"fit":
			_try_fit(entry)

func _enter_actions() -> void:
	# Can't-afford feedback happens right on the card, before the action list.
	var e := selected_entry()
	if not e.is_empty():
		if mode == "buy" and not GameState.can_afford(int(e["price"])):
			_cant_afford()
			return
		if mode == "build":
			var def: Dictionary = e["def"]
			var short_scrap := int(def.get("scrap_cost", 0)) - GameState.scrap
			var short_star := int(def.get("stardust_cost", 0)) - GameState.stardust
			if short_scrap > 0 or short_star > 0:
				_cant_afford_build(short_scrap > 0, short_star > 0)
				return
	super()

## "Too expensive" feedback: the card and the balance pill wobble. No toast — the disabled
## "Need N more" button already says it, and a toast would only queue up behind the open panel.
func _cant_afford() -> void:
	if _selected >= 0 and _selected < _cards.size():
		_cards[_selected].wobble()
	UIStyle.wobble(_balance_pill, 4.0)
	UIStyle.play_cancel()

## Same feedback for "build" mode, but wobbles whichever currency pill(s) the player is actually
## short on rather than always the stardust one - most bench items cost only scrap.
func _cant_afford_build(scrap_short: bool, star_short: bool) -> void:
	if _selected >= 0 and _selected < _cards.size():
		_cards[_selected].wobble()
	if scrap_short:
		UIStyle.wobble(_scrap_pill, 4.0)
	if star_short:
		UIStyle.wobble(_balance_pill, 4.0)
	UIStyle.play_cancel()

func _try_buy(entry: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	var id := str(entry["id"])
	var p := int(entry["price"])
	var item_name := str(def.get("name", UIStyle.pretty_id(id)))
	if not GameState.can_afford(p):
		_cant_afford()
		return
	var ok: bool = await _confirm.ask("Buy %s for %d?" % [item_name, p], "Buy", "No", p)
	if not ok or not is_open:
		_leave_actions()
		return
	if not GameState.spend_stardust(p):
		_cant_afford()
		return
	GameState.add_item(id, 1)
	UIStyle.play_sfx("ui_buy")
	EventBus.toast_requested.emit("You bought a %s!" % item_name, id)
	purchased.emit(id)
	_leave_actions()
	refresh()

func _try_sell(entry: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	var id := str(entry["id"])
	var p := int(entry["price"])
	var item_name := str(def.get("name", UIStyle.pretty_id(id)))
	var ok: bool = await _confirm.ask("Sell %s for %d?" % [item_name, p], "Sell", "No", p)
	if not ok or not is_open:
		_leave_actions()
		return
	if GameState.remove_item(id, 1):
		GameState.add_stardust(p)
		UIStyle.play_sfx("ui_buy")
		EventBus.toast_requested.emit("Sold %s for %d stardust!" % [item_name, p], "stardust")
		sold.emit(id)
	_nav_state = NavState.GRID
	refresh()

## Spends scrap (+ stardust for some items, see project_system.gd's ITEM schema) and adds the built
## item to the bag. Scrap is charged first, matching `_try_fit` below, so the two share one refund
## path if a future item ever charges both currencies and the second spend fails.
func _try_build(entry: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	var id := str(entry["id"])
	var item_name := str(def.get("name", UIStyle.pretty_id(id)))
	var scrap_cost := int(def.get("scrap_cost", 0))
	var stardust_cost := int(def.get("stardust_cost", 0))
	if not GameState.can_afford_scrap(scrap_cost) or not GameState.can_afford(stardust_cost):
		_cant_afford_build(scrap_cost > GameState.scrap, stardust_cost > GameState.stardust)
		return
	var cost := _cost_words(scrap_cost, stardust_cost)
	var question := ("Build %s?" % item_name) if cost == "" else ("Build %s for %s?" % [item_name, cost])
	var ok: bool = await _confirm.ask(question, "Build", "No")
	if not ok or not is_open:
		_leave_actions()
		return
	if not GameState.spend_scrap(scrap_cost):
		_cant_afford_build(true, false)
		return
	if stardust_cost > 0 and not GameState.spend_stardust(stardust_cost):
		GameState.add_scrap(scrap_cost)  # refund - nothing ships that charges both today, stay correct if it ever does
		_cant_afford_build(false, true)
		return
	GameState.add_item(id, 1)
	UIStyle.play_sfx("ui_buy")
	EventBus.toast_requested.emit("You built a %s!" % item_name, id)
	built.emit(id)
	_leave_actions()
	refresh()

## Fits a rocket-part gift: the gift itself (removed from the bag) plus scrap/stardust
## (Catalog "scrap_cost"/"stardust_cost" on the part, set from the project definition's
## "part_fit_scrap"/"part_fit_stardust" - see project_system.gd `_register_part`).
## GameState.fit_rocket_part does the actual fitting; EventBus.rocket_part_fitted is what starts the
## part-celebration cutscene (BUILD_PLAN Phase 2 builder N) - never emitted on load, only here.
func _try_fit(entry: Dictionary) -> void:
	var def: Dictionary = entry["def"]
	var part_id := str(entry["id"])
	var part_display := str(def.get("name", UIStyle.pretty_id(part_id)))
	var scrap_cost := int(def.get("scrap_cost", 0))
	var stardust_cost := int(def.get("stardust_cost", 0))
	if not GameState.has_item(part_id):
		# The gift left the bag some other way (dropped, or already fitted from a second bench)
		# between opening this panel and pressing Fit - just re-read the grid, nothing to refund.
		refresh()
		return
	if not GameState.can_afford_scrap(scrap_cost) or not GameState.can_afford(stardust_cost):
		_cant_afford_build(scrap_cost > GameState.scrap, stardust_cost > GameState.stardust)
		return
	var cost := _cost_words(scrap_cost, stardust_cost)
	var question := ("Fit the %s?" % part_display) if cost == "" \
		else ("Fit the %s for the gift + %s?" % [part_display, cost])
	var ok: bool = await _confirm.ask(question, "Fit", "No")
	if not ok or not is_open:
		_leave_actions()
		return
	if not GameState.remove_item(part_id, 1):
		refresh()
		return
	if not GameState.spend_scrap(scrap_cost):
		GameState.add_item(part_id, 1)
		_cant_afford_build(true, false)
		return
	if stardust_cost > 0 and not GameState.spend_stardust(stardust_cost):
		GameState.add_scrap(scrap_cost)
		GameState.add_item(part_id, 1)
		_cant_afford_build(false, true)
		return
	GameState.fit_rocket_part(part_id)
	EventBus.rocket_part_fitted.emit(part_id)
	UIStyle.play_sfx("ui_buy")
	EventBus.toast_requested.emit("You fit the %s!" % part_display, part_id)
	fitted.emit(part_id)
	# A successful fit closes the bench (docs/OPEN_ISSUES.md 42) so the part celebration - which waits
	# for no modal to be open - starts right away instead of waiting for the player to close the bench
	# by hand. That is the payoff moment of a whole neighbour project; a refused fit (see the early
	# returns above) leaves the panel open instead, same as a shop. The first attempt at this
	# (close_panel() here, with no other change) re-opened the bench one physics frame later on a
	# keyboard/pad "Yes" because the still-held interact key read as a NEW press once player.gd's modal
	# gate lifted. player.gd's `_on_modal_changed` now seeds `_interact_was_pressed` from the held key
	# the instant a modal closes, and item_grid_panel.gd's `open_panel()` kills any still-running close
	# tween, so a re-open inside the 0.18 s pop-out can no longer land invisible either.
	close_panel()
