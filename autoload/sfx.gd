extends Node

@export var click_path: String = "res://assets/sfx/click.ogg"
@export var drop_path: String = "res://assets/sfx/drop.ogg"
@export var button_path: String = "res://assets/sfx/button.ogg"
@export var success_path: String = "res://assets/sfx/success.ogg"

var _click: AudioStreamPlayer
var _drop: AudioStreamPlayer
var _button: AudioStreamPlayer
var _success: AudioStreamPlayer

func _ready():
	_click = _player(_load(click_path))
	_drop = _player(_load(drop_path))
	_button = _player(_load(button_path))
	_success = _player(_load(success_path))

	EventBus.card_drag_started.connect(func(_c): play_click())
	EventBus.card_placed_in_slot.connect(func(_s, _c): play_drop())
	EventBus.card_removed_from_slot.connect(func(_s, _c): play_click())
	EventBus.card_stacked.connect(func(_b, _t): play_drop())
	EventBus.card_broken.connect(func(_c): play_drop())
	EventBus.card_combined.connect(func(_b, _t, _r): play_success())

func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func play_click():
	if _click.stream:
		_click.play()

func play_drop():
	if _drop.stream:
		_drop.play()

func play_button():
	if _button.stream:
		_button.play()

func play_success():
	if _success.stream:
		_success.play()
