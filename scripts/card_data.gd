class_name CardData extends Resource

enum CardType { ITEM, CHAR, CLUE, LOGIC, SCENE, DEBUFF }
enum SenseType { NONE, TASTE, TOUCH, SMELL, HEARING, VISION }

@export var card_id: String = ""
@export var card_name: String = "未命名"
@export_multiline var description: String = ""
@export var card_type: CardType = CardType.ITEM
@export var tags: Array[String] = []
@export var consumable: bool = false
@export var allow_duplicate: bool = false
@export var drop_once: bool = false

@export var bg_color: Color = Color(0.15, 0.35, 0.7, 1.0)
@export var border_color: Color = Color(0.3, 0.55, 0.9, 1.0)
@export var text_color: Color = Color(1, 1, 1, 1)
@export var icon: String = ""

@export var sense_type: SenseType = SenseType.NONE
@export var recycle_value: int = 0
@export var interact_text: String = ""
@export var favorability: int = 0
@export var max_favorability: int = 100
@export var corruption_time: int = 0
@export var fatigue_trigger: bool = false
@export var is_gift: bool = false
@export var art: Texture2D = null

@export var dialogue_config: DialogueConfig = null
