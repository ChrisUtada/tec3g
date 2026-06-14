extends Control

var _content: MultimediaContent
var _audio_player: AudioStreamPlayer

@onready var dim_bg: ColorRect = $DimBg
@onready var content_panel: Control = $DimBg/ContentPanel
@onready var close_btn: Button = $DimBg/ContentPanel/CloseBtn
@onready var image_rect: TextureRect = $DimBg/ContentPanel/ImageRect
@onready var audio_row: Control = $DimBg/ContentPanel/AudioRow
@onready var play_btn: Button = $DimBg/ContentPanel/AudioRow/PlayBtn
@onready var text_label: Label = $DimBg/ContentPanel/TextLabel
@onready var scroll: ScrollContainer = $DimBg/ContentPanel/ScrollContainer

func _ready():
	close_btn.pressed.connect(_close)
	play_btn.pressed.connect(_toggle_audio)

func open(content: MultimediaContent) -> void:
	_content = content
	text_label.text = content.text

	if content.image:
		image_rect.texture = content.image
		var max_w = get_viewport().size.x - 80
		var max_h = get_viewport().size.y - 80
		var tex_size = content.image.get_size()
		var scale_f = min(1.0, min(max_w / tex_size.x, max_h / tex_size.y))
		var w = int(tex_size.x * scale_f)
		var h = int(tex_size.y * scale_f)
		image_rect.custom_minimum_size = Vector2(w, h)
		image_rect.size = Vector2(w, h)
		image_rect.show()
	else:
		image_rect.hide()

	if content.audio:
		_audio_player = AudioStreamPlayer.new()
		_audio_player.stream = content.audio
		add_child(_audio_player)
		audio_row.show()
	else:
		audio_row.hide()

	_center_panel()

func _center_panel():
	await get_tree().process_frame
	var vp = get_viewport().size
	var cs = content_panel.size
	content_panel.position = Vector2((vp.x - cs.x) * 0.5, (vp.y - cs.y) * 0.5)

func _toggle_audio():
	if _audio_player == null:
		return
	if _audio_player.playing:
		_audio_player.stop()
		play_btn.text = "▶ 播放语音"
	else:
		_audio_player.play()
		play_btn.text = "■ 停止"

func _close():
	if _audio_player:
		_audio_player.stop()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		_close()
