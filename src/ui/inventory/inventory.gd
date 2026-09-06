class_name InventoryPanel
extends ItemGridPanel
## The player's bag. Tabs All / Decorations / Clothes / Materials, 5-column card grid built from
## GameState.inventory + Catalog, details column with Place / Wear / Drop.
##   open(tab)                      # "all" | "decorations" | "clothes" | "materials"
##   signal item_chosen(item_id, action)   # action: "place" | "wear" | "drop" | "use"
##   signal closed

signal item_chosen(item_id: String, action: String)

const TABS := [["all", "All"], ["decorations", "Decorations"], ["clothes", "Clothes"], ["materials", "Materials"]]
const KIND_ORDER := {"decoration": 0, "clothing": 1, "collectible": 2, "favor_item": 3}

func _hook_modal_name() -> String:
	return "inventory"

func _hook_title() -> String:
	return "Bag"

func _hook_tabs() -> Array:
	return TABS

func _hook_hints() -> Array:
	return [["interact", "Select"], ["cancel", "Close"], [["rotate_left", "rotate_right"], "Switch tab"]]

func _hook_empty_text() -> PackedStringArray:
	return ["Your bag is empty", "Explore the planet to find stardust and treasures!"]

## Opens the bag on a tab (idempotent: re-opening only switches the tab).
func open(tab: String = "all") -> void:
	var was_open := is_open
	if not was_open:
		_tab = maxi(0, _tab_ids.find(tab))
		_update_tab_visuals()
		_selected = 0
		_scroll.scroll_vertical = 0
		open_panel()
	else:
		set_tab_by_id(tab)

## Closes the bag.
func close() -> void:
	close_panel()

static func _matches_tab(def: Dictionary, tab_id: String) -> bool:
	var kind := str(def.get("kind", ""))
	match tab_id:
		"decorations":
			return kind == "decoration"
		"clothes":
			return kind == "clothing"
		"materials":
			return kind == "collectible" or kind == "favor_item" or str(def.get("category", "")) == "material"
	return true

func _hook_entries(tab_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in GameState.inventory.keys():
		var count := int(GameState.inventory[id])
		if count <= 0:
			continue
		var def := ItemGridPanel.def_for(str(id))
		if not _matches_tab(def, tab_id):
			continue
		out.append({"id": str(id), "def": def, "count": count, "price": int(def.get("price", 0))})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka := int(KIND_ORDER.get(str(a["def"].get("kind", "")), 9))
		var kb := int(KIND_ORDER.get(str(b["def"].get("kind", "")), 9))
		if ka != kb:
			return ka < kb
		return str(a["def"].get("name", "")) < str(b["def"].get("name", "")))
	return out

func _hook_fill_extra(extra: HBoxContainer, entry: Dictionary) -> void:
	var count := int(entry.get("count", 1))
	var l := UIStyle.make_label("You have %d" % count if count != 1 else "You have 1", "Soft", HORIZONTAL_ALIGNMENT_CENTER)
	extra.add_child(l)

func _hook_actions(entry: Dictionary) -> Array:
	var def: Dictionary = entry["def"]
	var kind := str(def.get("kind", ""))
	var actions: Array = []
	match kind:
		"decoration":
			actions.append({"id": "place", "label": "Place", "primary": true})
		"clothing":
			actions.append({"id": "wear", "label": "Wear", "primary": true})
		"favor_item":
			actions.append({"id": "use", "label": "Use", "primary": true})
	actions.append({"id": "drop", "label": "Drop"})
	return actions

func _hook_action(entry: Dictionary, action_id: String) -> void:
	var id := str(entry["id"])
	var def: Dictionary = entry["def"]
	var item_name := str(def.get("name", UIStyle.pretty_id(id)))
	match action_id:
		"place":
			item_chosen.emit(id, "place")
			close_panel()
		"wear":
			var style: Dictionary = def.get("style", {})
			if not style.is_empty():
				for k in style.keys():
					GameState.player_style[k] = style[k]
				EventBus.player_style_changed.emit()
			item_chosen.emit(id, "wear")
			EventBus.toast_requested.emit("You put on the %s!" % item_name, id)
			UIStyle.play_sfx("ui_buy")
			_leave_actions()
		"use":
			item_chosen.emit(id, "use")
			close_panel()
		"drop":
			if GameState.remove_item(id, 1):
				EventBus.toast_requested.emit("Dropped %s." % item_name, id)
				item_chosen.emit(id, "drop")
				UIStyle.play_cancel()
			_nav_state = NavState.GRID
			refresh()
