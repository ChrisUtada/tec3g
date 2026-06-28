class_name CardData extends Resource

enum CardType { ITEM, CHAR, CLUE, LOGIC, SCENE, DEBUFF }
enum SenseType { NONE, TASTE, TOUCH, SMELL, HEARING, VISION }
enum SpawnPolicy { UNLIMITED, UNIQUE_ON_BOARD, UNIQUE_PER_GAME }
enum InitialZone { NONE, BOARD, STAGING }

@export var card_id: String = ""
@export var card_name: String = "未命名"
@export_multiline var description: String = ""
@export var card_type: CardType = CardType.ITEM
@export var tags: Array[String] = []

@export var consumable: bool = false
@export var spawn_policy: SpawnPolicy = SpawnPolicy.UNLIMITED
@export var initial_zone: InitialZone = InitialZone.NONE
@export var initial_position: Vector2 = Vector2.ZERO

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
@export var corruption_spawn_fatigue: bool = true
@export var corruption_bar_label: String = ""
@export var fatigue_trigger: bool = false
@export var is_gift: bool = false
@export var art: Texture2D = null
@export var card_scene_path: String = ""
var _card_scene_cache: PackedScene = null

func get_card_scene() -> PackedScene:
	if _card_scene_cache:
		return _card_scene_cache
	if not card_scene_path.is_empty():
		_card_scene_cache = load(card_scene_path)
		return _card_scene_cache
	return null

@export var multimedia_content: MultimediaContent = null

@export var dialogue_config: DialogueConfig = null
