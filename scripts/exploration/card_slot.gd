extends Control

var placed_card = null
var placed_data = null
var _config: PanelSlotConfig = null
var hint: String = "放入卡牌"

@onready var bg: ColorRect = $Bg
@onready var label: Label = $Label


func _ready():
	label.text = hint

func set_config(cfg: PanelSlotConfig) -> void:
	_config = cfg
	hint = cfg.hint if cfg else "放入卡牌"

func can_accept(card) -> bool:
	if placed_card != null:
		return false
	if _config == null:
		return true
	return _config.matches(card)

func place_card(card) -> void:
	placed_card = card
	placed_data = card.card_data
	card.reparent(self, false)
	var card_w = card.size.x * 0.6
	var card_h = card.size.y * 0.6
	card.position = Vector2((size.x - card_w) * 0.5, (size.y - card_h) * 0.5)
	card.enter_slot()
	bg.color = Color(0.2, 0.5, 0.2, 0.6)
	label.text = card.card_data.card_name
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(0.6, 0.6), 0.25).from(Vector2(0.8, 0.8))

func remove_card():
	if placed_card == null:
		return
	var card = placed_card
	placed_card = null
	placed_data = null
	card.exit_slot()
	bg.color = Color(0.3, 0.3, 0.4, 0.4)
	label.text = hint
	return card

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if placed_card != null:
			get_viewport().set_input_as_handled()
			var card = remove_card()
			if card:
				var container = EventBus.get_card_container()
				card.reparent(container, true)
				EventBus.card_removed_from_slot.emit(self, card)
				card.start_drag()

func lock() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func unlock() -> void:
	mouse_filter = MOUSE_FILTER_STOP

func is_empty() -> bool:
	return placed_card == null
