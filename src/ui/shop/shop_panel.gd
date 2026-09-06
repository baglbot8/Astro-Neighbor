class_name ShopPanel
extends ItemGridPanel
## Generic buy / sell grid for Cosmo Depot, Suit-Up and any other stall.
##   open(items, "buy", "Cosmo Depot", "Pip & Pop")   # items: Array of Catalog defs or ids
##   open([], "sell", "Cosmo Depot", "Pip & Pop")     # empty list in sell mode = everything sellable in the bag
## Buying: confirm dialog -> GameState.spend_stardust + add_item + toast + "ui_buy".
## Selling pays SELL_RATIO of the price. Unaffordable items are greyed and wobble on attempt.
##   signal purchased(item_id)   signal sold(item_id)   signal closed

signal purchased(item_id: String)
signal sold(item_id: String)

const SELL_RATIO := 0.4

var mode := "buy"
var shop_title := "Shop"
var shopkeeper := ""
var _stock: Array[Dictionary] = []
var _balance_pill: PanelContainer
var _balance_label: Label
var _balance_star: StarIcon

func _hook_modal_name() -> String:
	return "shop"

func _hook_title() -> String:
	return "Shop"

func _hook_hints() -> Array:
	return [["interact", "Select"], ["cancel", "Leave"]]

func _hook_empty_text() -> PackedStringArray:
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

## Re-reads GameState.stardust into every price tag and into the action button.
##
## Affordability used to be sampled ONCE, when the details column was built, so a favour reward or a
## sale that landed while the shop was open left the card greyed and the button reading "Need 1 more"
## at 120 / 120 stardust until the player moved the cursor. Driven by EventBus.stardust_changed.
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

## Opens the shop. items = Array of Catalog definitions (Dictionary) or ids (String).
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
	_subtitle_label.text = keeper if keeper != "" else ("Sell your items" if mode == "sell" else "")
	_subtitle_label.visible = _subtitle_label.text != ""
	_balance_label.text = str(GameState.stardust)
	_selected = 0
	_scroll.scroll_vertical = 0
	open_panel()

## Price this shop pays / charges for a definition.
func price_for(def: Dictionary) -> int:
	var base := int(def.get("price", 0))
	return int(round(base * SELL_RATIO)) if mode == "sell" else base

func _hook_entries(_tab_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
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

func _hook_decorate_card(card: ItemCard, entry: Dictionary) -> void:
	var p := int(entry["price"])
	card.set_price(p, mode == "sell" or GameState.can_afford(p))

func _hook_fill_extra(extra: HBoxContainer, entry: Dictionary) -> void:
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

func _hook_actions(entry: Dictionary) -> Array:
	if mode == "sell":
		return [{"id": "sell", "label": "Sell", "primary": true}]
	# Unaffordable items get a disabled button that says exactly how short the player is, instead of an
	# inviting yellow "Buy" that only wobbles once it is pressed.
	var short := int(entry.get("price", 0)) - GameState.stardust
	if short > 0:
		return [{"id": "buy", "label": "Need %d more" % short, "primary": true, "disabled": true}]
	return [{"id": "buy", "label": "Buy", "primary": true}]

func _hook_action(entry: Dictionary, action_id: String) -> void:
	match action_id:
		"buy":
			_try_buy(entry)
		"sell":
			_try_sell(entry)

func _enter_actions() -> void:
	# Can't-afford feedback happens right on the card, before the action list.
	var e := selected_entry()
	if mode == "buy" and not e.is_empty() and not GameState.can_afford(int(e["price"])):
		_cant_afford()
		return
	super()

## "Too expensive" feedback: the card and the balance pill wobble. No toast — the disabled
## "Need N more" button already says it, and a toast would only queue up behind the open panel.
func _cant_afford() -> void:
	if _selected >= 0 and _selected < _cards.size():
		_cards[_selected].wobble()
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
