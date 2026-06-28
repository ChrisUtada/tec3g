@tool
extends ScrollContainer

var TYPE_LABELS: Dictionary
var TYPE_COLORS: Dictionary
var ZONE_LABELS: Dictionary
var POLICY_LABELS: Dictionary

var _root: VBoxContainer
var _initialized := false


func _ready():
	_init_labels()
	_build_ui()


func _init_labels() -> void:
	TYPE_LABELS = {
		0: "CHAR 角色卡", 1: "ITEM 物品卡", 2: "LOGIC 逻辑卡",
		3: "SCENE 场景卡", 4: "CLUE 线索卡", 5: "DEBUFF 减益卡",
	}
	TYPE_COLORS = {
		0: Color(0.7, 0.55, 0.25), 1: Color(0.4, 0.65, 0.9),
		2: Color(0.55, 0.35, 0.8), 3: Color(0.3, 0.7, 0.45),
		4: Color(0.6, 0.6, 0.3), 5: Color(0.8, 0.3, 0.3),
	}
	ZONE_LABELS = {0: "—", 1: "桌面", 2: "暂存区"}
	POLICY_LABELS = {0: "无限", 1: "场上唯一", 2: "全局唯一"}


func _build_ui() -> void:
	# Clean up previous UI tree
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 8)
	add_child(_root)

	_add_header()

	var cards = _scan_cards()
	var recipes = _scan_recipes()
	var recipes_by_group = _group_recipes(recipes)
	var dialogue_data = _scan_dialogues()

	# Group cards by type
	var grouped: Dictionary = {}
	for data in cards:
		var t = data.card_type
		if not grouped.has(t):
			grouped[t] = []
		grouped[t].append(data)

	# Display each type section
	for type_val in [0, 1, 2, 3, 4, 5]:
		if not grouped.has(type_val):
			continue
		_add_section(TYPE_LABELS.get(type_val, str(type_val)), TYPE_COLORS.get(type_val, Color.WHITE))
		for data in grouped[type_val]:
			_add_card_entry(data, recipes_by_group, dialogue_data)

	_add_separator()
	_add_recipes_section(recipes)
	_add_dialogue_section(dialogue_data)

	# Bottom spacer for scroll
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	_root.add_child(spacer)


# ── UI Building ──

func _add_header() -> void:
	var title = Label.new()
	title.text = "卡牌总览  Card Catalog"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_root.add_child(title)

	var btn = Button.new()
	btn.text = "刷新"
	btn.pressed.connect(_build_ui)
	_root.add_child(btn)

	var stats = Label.new()
	var card_count = _count_files("res://resources/cards/", ".tres")
	var recipe_count = _count_files("res://resources/recipes/", ".tres")
	stats.text = "卡牌: %d  |  配方: %d" % [card_count, recipe_count]
	stats.add_theme_font_size_override("font_size", 13)
	stats.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_root.add_child(stats)
	_add_separator()


func _add_section(title_text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = "── %s ──" % title_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	_root.add_child(lbl)


func _add_separator() -> void:
	var sep = HSeparator.new()
	_root.add_child(sep)


func _add_card_entry(data: CardData, recipes_by_group: Dictionary, dialogue_data: Dictionary) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_root.add_child(vbox)

	# Card name + basic info
	var name_lbl = Label.new()
	var zone_text = ZONE_LABELS.get(data.initial_zone, "?")
	var policy_text = POLICY_LABELS.get(data.spawn_policy, "?")
	name_lbl.text = "%s%s  [%s]  初始:%s  生成:%s" % [
		data.icon + " " if not data.icon.is_empty() else "",
		data.card_name, data.card_id, zone_text, policy_text
	]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(name_lbl)

	# Description
	if not data.description.is_empty():
		var desc = Label.new()
		desc.text = "   %s" % data.description.replace("\n", " ")
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc)

	# Relationships
	var rels: Array[String] = []
	# Recipes where this card is the group key
	if recipes_by_group.has(data.card_id):
		for r in recipes_by_group[data.card_id]:
			var target_names: Array[String] = []
			for c in r.target_cards:
				target_names.append(c.card_name if c else "?")
			var result = r.result_card.card_name if r.result_card else (r.label if not r.label.is_empty() else "无产出")
			var action = "消耗top" if r.consumes_top else ("销毁root" if r.destroys_target else "→")
			var extras: Array[String] = []
			if r.max_drops > 0:
				extras.append("×%d" % r.max_drops)
			if r.add_favorability != 0:
				extras.append("好感%+d" % r.add_favorability)
			if r.require_tags.size() > 0:
				extras.append("需tag:%s" % ",".join(r.require_tags))
			if r.require_favorability_min > 0:
				extras.append("需好感≥%d" % r.require_favorability_min)
			if not r.chain_id.is_empty():
				extras.append("链:%s" % r.chain_id)
			var extra_str = " [%s]" % ", ".join(extras) if extras.size() > 0 else ""
			rels.append("  合成: %s %s %s%s" % [", ".join(target_names), action, result, extra_str])
	# Recipes where this card is a target
	for group_key in recipes_by_group:
		for r in recipes_by_group[group_key]:
			for tc in r.target_cards:
				if tc and tc.card_id == data.card_id and group_key != data.card_id:
					var result = r.result_card.card_name if r.result_card else "销毁"
					rels.append("  被用于: [%s] → %s" % [group_key, result])
	# Dialogue
	if data.dialogue_config:
		var dlg_id = data.dialogue_config.dialogue_id
		var node_count = dialogue_data.get(dlg_id, {}).size()
		rels.append("  对话: %s (%d节点)" % [dlg_id, node_count])
	# Corruption
	if data.corruption_time > 0:
		rels.append("  腐化: %d秒" % data.corruption_time)

	if rels.size() > 0:
		for rel in rels:
			var lbl = Label.new()
			lbl.text = rel
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.55, 0.7, 0.55))
			vbox.add_child(lbl)


func _add_recipes_section(recipes: Array) -> void:
	_add_separator()
	_add_section("合成配方  Recipes", Color(0.5, 0.8, 0.6))
	for r in recipes:
		var lbl = Label.new()
		var target_names: Array[String] = []
		for c in r.target_cards:
			target_names.append(c.card_name if c else "?")
		var result = r.result_card.card_name if r.result_card else ("[%s]" % r.label if not r.label.is_empty() else "销毁")
		var drops = " (限%d次)" % r.max_drops if r.max_drops > 0 else ""
		# Behavior flags
		var flags: Array[String] = []
		if r.consumes_top:
			flags.append("消耗top")
		if r.destroys_target:
			flags.append("销毁root")
		if r.add_favorability != 0:
			flags.append("好感%+d" % r.add_favorability)
		# Conditions
		var conds: Array[String] = []
		if r.require_tags.size() > 0:
			conds.append("需tag[%s]" % ",".join(r.require_tags))
		if r.require_favorability_min > 0:
			conds.append("好感≥%d" % r.require_favorability_min)
		# Chain
		var chain = " [%s]" % r.chain_id if not r.chain_id.is_empty() else ""
		var flag_str = " (%s)" % " ".join(flags) if flags.size() > 0 else ""
		var cond_str = " {%s}" % " ".join(conds) if conds.size() > 0 else ""
		lbl.text = "  [%s] %s → %s  w:%.1f%s%s%s%s" % [r.group_key, " + ".join(target_names), result, r.weight, drops, flag_str, cond_str, chain]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
		_root.add_child(lbl)


func _add_dialogue_section(dialogue_data: Dictionary) -> void:
	_add_separator()
	_add_section("对话文件  Dialogues", Color(0.5, 0.6, 0.9))
	for dlg_id in dialogue_data:
		var data = dialogue_data[dlg_id]
		var node_count = data.size()
		var has_topics = data.has("topics")
		var lbl = Label.new()
		lbl.text = "  %s: %d节点%s" % [dlg_id, node_count, " (含topics)" if has_topics else ""]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.85))
		_root.add_child(lbl)
		# Validate
		var errors = _validate_dialogue_static(data, dlg_id)
		for e in errors:
			var elbl = Label.new()
			elbl.text = "    ⚠ %s" % e
			elbl.add_theme_font_size_override("font_size", 12)
			elbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
			_root.add_child(elbl)


# ── Data Scanning ──

func _scan_cards() -> Array:
	var cards: Array = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir == null:
		return cards
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var res = load("res://resources/cards/" + file)
			if res is CardData:
				cards.append(res)
		file = dir.get_next()
	cards.sort_custom(func(a, b): return a.card_id < b.card_id)
	return cards


func _scan_recipes() -> Array:
	var recipes: Array = []
	var dir = DirAccess.open("res://resources/recipes/")
	if dir == null:
		return recipes
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var r = load("res://resources/recipes/" + file)
			if r:
				recipes.append(r)
		file = dir.get_next()
	return recipes


func _group_recipes(recipes: Array) -> Dictionary:
	var grouped: Dictionary = {}
	for r in recipes:
		var key = r.group_key if r.group_key is String else ""
		if key.is_empty():
			continue
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(r)
	return grouped


func _scan_dialogues() -> Dictionary:
	var result: Dictionary = {}
	var dir = DirAccess.open("res://resources/dialogues/")
	if dir == null:
		return result
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".json"):
			var text = FileAccess.get_file_as_string("res://resources/dialogues/" + file)
			if not text.is_empty():
				var json = JSON.parse_string(text)
				if json is Dictionary:
					result[file.replace(".json", "")] = json
		file = dir.get_next()
	return result


func _count_files(path: String, ext: String) -> int:
	var count := 0
	var dir = DirAccess.open(path)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(ext):
			count += 1
		file = dir.get_next()
	return count


# ── Inline Validation ──

static func _validate_dialogue_static(data: Dictionary, dlg_id: String) -> Array[String]:
	var errors: Array[String] = []
	if not data.has("start"):
		errors.append("Missing 'start' node")
	var node_ids: Dictionary = {}
	for key in data:
		if key == "topics":
			continue
		node_ids[key] = true
	var topics = data.get("topics", {})
	for topic_key in topics:
		if not node_ids.has(topics[topic_key]):
			errors.append("topics['%s'] → '%s' not found" % [topic_key, topics[topic_key]])
	var referenced: Dictionary = {"start": true}
	for node_id in node_ids:
		var node = data[node_id]
		if not node is Dictionary:
			continue
		var next_id = node.get("next_node_id", "")
		if not next_id.is_empty():
			referenced[next_id] = true
			if not node_ids.has(next_id):
				errors.append("'%s' → next '%s' not found" % [node_id, next_id])
		for opt in node.get("options", []):
			var opt_next = opt.get("next_node_id", "")
			if not opt_next.is_empty():
				referenced[opt_next] = true
				if not node_ids.has(opt_next):
					errors.append("'%s' option → '%s' not found" % [node_id, opt_next])
	for node_id in node_ids:
		if not referenced.has(node_id):
			errors.append("Node '%s' unreachable" % node_id)
	return errors
