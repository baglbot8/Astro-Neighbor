class_name StarIcon
extends Control
## Procedurally drawn stardust star (yellow fill, warm outline, highlight). Optional twinkle / spin.

@export var fill: Color = UIStyle.STARDUST: set = _set_fill
@export var edge: Color = UIStyle.STARDUST_EDGE: set = _set_edge
@export var twinkle: bool = false
@export var icon_size: float = 28.0:
	set(v):
		icon_size = v
		custom_minimum_size = Vector2(v, v)
		queue_redraw()

var _spin := 0.0
var _phase := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase = randf() * TAU
	set_process(twinkle)

func _process(delta: float) -> void:
	_phase += delta * 2.4
	var s := 1.0 + sin(_phase) * 0.08
	pivot_offset = size * 0.5
	scale = Vector2(s, s)

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.48
	UIDraw.star(self, c, r, fill, edge, maxf(1.5, r * 0.09), _spin)

func _set_fill(v: Color) -> void:
	fill = v
	queue_redraw()

func _set_edge(v: Color) -> void:
	edge = v
	queue_redraw()

## One happy spin (used when stardust changes).
func spin_once(duration: float = 0.5) -> void:
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_spin = v
		queue_redraw(), 0.0, TAU, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void:
		_spin = 0.0
		queue_redraw())
