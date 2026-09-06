extends Node
## Opens the favours journal on the `journal` action (J / D-pad down).
##
## The journal previously lived only behind pause -> Favours, which the onboarding builder flagged
## as too well hidden for the one thing a player needs to look up mid-session ("what did I agree
## to, and where do I find it?"). This node lives under /root/World and owns nothing else, so the
## hotkey works on every planet without touching the UI or pause-menu owners' files.
##
## NOTE: this POLLS Input rather than using _unhandled_input, matching the rest of the project.
## The Director drives automated tests with Input.action_press(), which sets the action state but
## emits no InputEvent, so an event-based handler is invisible to every test timeline.

const JOURNAL_PANEL := preload("res://src/ui/journal/journal_panel.gd")

var _was_pressed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var pressed: bool = Input.is_action_pressed("journal")
	var just_pressed: bool = pressed and not _was_pressed
	_was_pressed = pressed
	if not just_pressed:
		return
	# Never steal the key from a dialogue, shop, bag or pause menu, and never open during a
	# scene transition. The pause menu keeps its own Favours entry for players who look there.
	if EventBus.is_modal_open() or SceneRouter.is_busy():
		return
	JOURNAL_PANEL.open_over(self)
