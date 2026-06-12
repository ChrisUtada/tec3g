extends Control

var _pending_color: Color = Color(0.3, 0.8, 0.3, 1)
var _tween: Tween
var _on_complete: Callable = func(): pass
var _duration: float = 0.0

func _ready():
	$Fill.color = _pending_color

func set_fill_color(c: Color) -> void:
	_pending_color = c

func set_label(text: String) -> void:
	$BarLabel.text = text

func start(pos: Vector2, duration: float, on_complete: Callable) -> void:
	custom_minimum_size = Vector2(80, 8)
	size = Vector2(80, 8)
	global_position = pos + Vector2(40, -60)
	_duration = duration
	_on_complete = on_complete
	$Fill.size = Vector2(0, size.y)
	_start_tween(duration, true)

func start_local(duration: float, on_complete: Callable) -> void:
	custom_minimum_size = Vector2(80, 8)
	size = Vector2(80, 8)
	_duration = duration
	_on_complete = on_complete
	$Fill.size = Vector2(0, size.y)
	_start_tween(duration, false)

func attach_to(parent: Control, duration: float, on_complete: Callable) -> void:
	custom_minimum_size = Vector2(80, 8)
	size = Vector2(80, 8)
	position = Vector2((parent.size.x - 80) * 0.5, -60)
	z_index = 1000
	_duration = duration
	_on_complete = on_complete
	$Fill.size = Vector2(0, size.y)
	parent.add_child(self)
	_start_tween(duration, false)

func _start_tween(duration: float, auto_free: bool) -> void:
	var current_w = $Fill.size.x
	var target_w = size.x
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_method(func(w): $Fill.size = Vector2(w, $Fill.size.y), current_w, target_w, duration)
	_tween.tween_callback(_on_complete)
	if auto_free:
		_tween.tween_callback(queue_free)

func pause() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

func resume() -> void:
	if _tween:
		return
	var remaining = 1.0 - ($Fill.size.x / size.x)
	if remaining <= 0.001:
		_on_complete.call()
		return
	_start_tween(_duration * remaining, false)

func cancel() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null
	queue_free()
