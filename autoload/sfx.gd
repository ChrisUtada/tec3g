extends Node

var _click: AudioStreamPlayer
var _drop: AudioStreamPlayer
var _button: AudioStreamPlayer
var _success: AudioStreamPlayer

func _ready():
	_click = _player(_mk_click(1500, 0.03))
	_drop = _player(_mk_click(800, 0.05))
	_button = _player(_mk_click(1200, 0.025))
	_success = _player(_mk_click(2000, 0.06))

	EventBus.card_drag_started.connect(func(_c): play_click())
	EventBus.card_placed_in_slot.connect(func(_s, _c): play_drop())
	EventBus.card_removed_from_slot.connect(func(_s, _c): play_click())
	EventBus.card_stacked.connect(func(_b, _t): play_drop())
	EventBus.card_broken.connect(func(_c): play_drop())
	EventBus.card_combined.connect(func(_b, _t, _r): play_success())

func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func play_click():
	_click.play()

func play_drop():
	_drop.play()

func play_button():
	_button.play()

func play_success():
	_success.play()

static func _mk_click(freq: float, dur: float) -> AudioStreamWAV:
	var rate = 22050
	var n = int(rate * dur)
	var data = PackedByteArray()
	data.resize(n)
	for i in range(n):
		var t = float(i) / rate
		var env = exp(-t * 120.0)
		var s = sin(t * TAU * freq) * env * 0.4 + sin(t * TAU * freq * 1.5) * env * 0.15
		data[i] = int(clamp((s + 1.0) * 0.5 * 255, 0, 255))
	return _finalize(data, rate)

static func _finalize(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.stereo = false
	w.mix_rate = rate
	w.data = data
	return w
