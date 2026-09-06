class_name HintChannel
extends Node
## The game's ONE hint channel. Every "here is how this works" nudge goes through it, so hints can
## never stack, never interrupt a conversation, and never nag.
##
## Rules it enforces for you (this is the whole point of the class):
##   * **Once, ever.** A hint is keyed. Once it has been shown, `GameState.flags["hint_<key>"]` is
##     set, so it survives save/load and never appears again — not this session, not next week.
##   * **Never over a modal.** Queued hints wait while a dialogue box, shop, bag, pause menu or
##     cutscene is open, and while `SceneRouter` is fading between scenes.
##   * **Never two at once.** At least `MIN_GAP` seconds between hints.
##   * **Never after the player worked it out.** `mark_acted(key)` retires a hint the moment the
##     player does the thing, even if it was still queued.
##   * **Never stale.** A hint that has waited longer than `EXPIRY` seconds is dropped rather than
##     appearing minutes after it was relevant.
##
## Usage (this is the whole API):
##
##   HintChannel.request("rocket_pad", "Follow the arrows to the rocket pad.", "star")
##   HintChannel.mark_acted("rocket_pad")        # the player boarded — retire it
##   if HintChannel.was_shown("rocket_pad"): ...
##
## `request` is safe to call every frame; repeats are ignored. It is also safe to call before the
## node exists (it creates itself under /root/World, like FavorSystem) and from any domain.

const NODE_NAME := "HintChannel"
const FLAG_PREFIX := "hint_"
## Minimum seconds between two hints. Longer than Toast.LIFETIME (3.0) on purpose, so a queue
## drains one card at a time and two hints are never on screen together.
const MIN_GAP := 3.6
## A queued hint older than this is dropped: it is no longer about what the player is doing.
const EXPIRY := 60.0
## Grace period after a modal closes before a queued hint appears, so the toast does not land on
## the dialogue box's own closing animation.
const AFTER_MODAL_GRACE := 0.7

var _queue: Array[Dictionary] = []
var _time := 0.0
var _gap := 0.0


# ============================================================================= static entry points
## Finds the world's HintChannel, creating it under /root/World the first time. Mirrors
## FavorSystem.get_or_create so any domain can reach it without a scene reference.
static func get_or_create() -> HintChannel:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var host: Node = tree.root.get_node_or_null("World")
	if host == null:
		host = tree.current_scene
	if host == null:
		host = tree.root
	if host == null:
		return null
	var existing := host.get_node_or_null(NODE_NAME)
	if existing is HintChannel:
		return existing as HintChannel
	var ch := HintChannel.new()
	ch.name = NODE_NAME
	host.add_child(ch)
	return ch


## Asks for a hint to be shown once, when the screen is free. Returns true if it was accepted.
## `key` identifies the hint forever — pick a stable one ("rocket_pad", "intro_place").
## `delay` holds it back that many seconds after it becomes relevant.
static func request(key: String, text: String, icon: String = "star", delay: float = 0.0) -> bool:
	if key == "" or text == "":
		return false
	if was_shown(key):
		return false
	var ch := get_or_create()
	if ch == null:
		return false
	return ch.enqueue(key, text, icon, delay)


## Retires a hint because the player already did the thing (or never needs telling). Persisted, so
## it will not come back after a save/load. Safe to call for a hint that was never requested.
static func mark_acted(key: String) -> void:
	if key == "":
		return
	GameState.set_flag(FLAG_PREFIX + key)
	var ch := _find()
	if ch != null:
		ch.drop(key)


## True once this hint has been shown (or retired with `mark_acted`).
static func was_shown(key: String) -> bool:
	return GameState.flag(FLAG_PREFIX + key)


## Removes a hint from the queue WITHOUT marking it seen, so it can become relevant again later.
static func cancel(key: String) -> void:
	var ch := _find()
	if ch != null:
		ch.drop(key)


## Forgets every hint this save has seen. Debug / test hook only.
static func reset_all() -> void:
	var keys: Array = GameState.flags.keys()
	for k: String in keys:
		if str(k).begins_with(FLAG_PREFIX):
			GameState.flags.erase(k)
	var ch := _find()
	if ch != null:
		ch._queue.clear()


static func _find() -> HintChannel:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for host: Node in [tree.root.get_node_or_null("World"), tree.current_scene, tree.root]:
		if host == null:
			continue
		var n := host.get_node_or_null(NODE_NAME)
		if n is HintChannel:
			return n as HintChannel
	return null


# ============================================================================= instance
func _ready() -> void:
	# Deliberately PAUSABLE: while the pause menu holds the tree, the queue simply stops, which is
	# exactly the behaviour we want (no hint timers running behind a menu).
	EventBus.ui_modal_closed.connect(_on_modal_closed)


## Queues one hint. Returns false if it is already seen or already waiting.
func enqueue(key: String, text: String, icon: String, delay: float) -> bool:
	if GameState.flag(FLAG_PREFIX + key):
		return false
	for e: Dictionary in _queue:
		if str(e["key"]) == key:
			return false
	_queue.append({
		"key": key,
		"text": text,
		"icon": icon,
		"at": _time + maxf(delay, 0.0),
		"expires": _time + maxf(delay, 0.0) + EXPIRY,
	})
	return true


## Removes a queued hint by key.
func drop(key: String) -> void:
	for i in range(_queue.size() - 1, -1, -1):
		if str(_queue[i]["key"]) == key:
			_queue.remove_at(i)


## Hints waiting to be shown (tests / debugging).
func pending_keys() -> PackedStringArray:
	var out: PackedStringArray = []
	for e: Dictionary in _queue:
		out.append(str(e["key"]))
	return out


func _on_modal_closed(_modal_name: String) -> void:
	# Let the closing panel finish its animation before a toast slides in behind it.
	_gap = maxf(_gap, AFTER_MODAL_GRACE)


func _process(delta: float) -> void:
	_time += delta
	# Tick the gap even while nothing is queued, so the post-modal grace is measured from the modal
	# closing rather than from the next request. (It was the other way round, and a hint earned two
	# seconds after a conversation ended arrived a further 0.7 s late.)
	_gap -= delta
	if _queue.is_empty():
		return
	for i in range(_queue.size() - 1, -1, -1):
		var e: Dictionary = _queue[i]
		if GameState.flag(FLAG_PREFIX + str(e["key"])) or _time > float(e["expires"]):
			_queue.remove_at(i)
	if _queue.is_empty():
		return
	if _gap > 0.0:
		return
	# The three "not now" gates: a menu or conversation owns the screen, the tree is paused, or a
	# scene transition is fading. A hint during any of those is the nagging we are replacing.
	if EventBus.is_modal_open() or get_tree().paused or SceneRouter.is_busy():
		return
	for i in _queue.size():
		var e: Dictionary = _queue[i]
		if _time < float(e["at"]):
			continue
		_queue.remove_at(i)
		_show(e)
		return


func _show(e: Dictionary) -> void:
	GameState.set_flag(FLAG_PREFIX + str(e["key"]))
	_gap = MIN_GAP
	EventBus.toast_requested.emit(str(e["text"]), str(e["icon"]))
