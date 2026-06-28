# Project Progress

## Completed

### High Priority Optimizations
- StyleBoxFlat caching in `card_base.gd` — `_make_stylebox()` cache dict prevents 20+ allocs per card
- Corruption timer null-safety — `corruption_component.gd` checks `is_inside_tree()` and scene validity
- Scene null checks in `PanelManager._close_group()` and `ObservationSystem`
- `STAGING_Y` deduplicated in `card_manager.gd`
- CardManager state encapsulation — added `cancel_combination()`, `cancel_observation()`, `cancel_dialogue()`, `cancel_all_pending()` lifecycle methods; `is_combo_in_progress()`, `is_dialogue_in_progress()`, `is_panel_open()` query helpers. `SceneDesktopManager._cleanup_card_manager_state()` reduced from 12 lines of direct field manipulation to single `cancel_all_pending()` call. `CardManager._on_card_broken()` uses cancel methods instead of scattered cleanup.
- `collect_stack_ids()` deduplicated — moved from `combination_system.gd` and `exploration_system.gd` (identical static methods) to `CardManager.collect_stack_ids()` public static method alongside `_stack_root()`
- `_pressed_self` safety valve in `card_base.gd` `_process()` — resets stuck press state when mouse button is no longer held (e.g. card reparented mid-press). Prevents "ghost drag" on next click.
- `register_card` dedup — `_enter_tree()` now self-resolves `_container` and is the sole registration point (paired with `_exit_tree()` unregister). Removed duplicate `register_card` call from `_ready()`. Eliminates stale entry in `_all_cards` array.
- Progress bar `resume()` — `pause()` now records `_remaining_ratio` at kill time; `resume()` uses recorded value instead of recalculating from visual width. Safe against size changes during pause.
- `_on_card_stacked` routing priority — documented 5-step dispatch chain: observe → scene guard → explore → dialogue → combination fallback.
- `_scene_bg_overlay` insertion — uses `bg.get_index() + 1` instead of hardcoded index 1, resilient to main.tscn node order changes.
- `class_name CardBase` added to `card_base.gd` — enables `is CardBase` type checks; `CardScene` inherits via path reference, unaffected.
- Card registry multi-instance — `EventBus._cards_by_id` changed from `card_id -> card` to `card_id -> Array[card]`, preventing silent overwrite when multiple cards share the same ID. `get_card_by_id()` returns latest instance (backward compatible), new `get_all_cards_by_id()` returns all instances. `unregister_card()` correctly removes single instance from array, only erases key when empty.
- Card instance ID — `CardBase` has `static var _next_instance_id` counter and `var instance_id: int`, assigned in `_ready()` (stable through reparenting). Sidebar and main.gd log messages now include `[#id]` suffix for debugging.
- Spawn Policy centralization — `CardData.SpawnPolicy` enum (`UNLIMITED`, `UNIQUE_ON_BOARD`, `UNIQUE_PER_GAME`) replaces dead fields `allow_duplicate`/`drop_once`. `CardManager.can_spawn(data)` gates all `spawn_card()` calls; `_per_game_spawned` dict tracks per-session limits; `reset_spawn_tracking()` clears it for new game. Callers in `combination_system.gd` and `exploration_system.gd` guard against null return (spawn rejected → skip emit/log).
- Data-driven initial spawn — `CardData.InitialZone` enum (`NONE`, `BOARD`, `STAGING`) + `initial_position: Vector2` on CardData. `main.gd._spawn_initial_cards()` scans `resources/cards/` directory, spawns cards with `initial_zone != NONE` at their configured positions. No more hardcoded preload lists. 10 cards configured: SCENE_plant_hunter on BOARD at (1220,80), 9 others in STAGING.
- DropRecipe → SpawnPolicy migration — `unique`/`no_duplicate` fields removed from `DropRecipe`; spawn gating now handled by `CardData.spawn_policy` on result cards. `ITEM_shadow.tres` set to `UNIQUE_PER_GAME`. `EventBus.can_drop()` simplified (removed `unique` special case), `has_dropped_unique()` removed. `exploration_system.gd` no longer checks `recipe.unique`/`recipe.no_duplicate`.
- Card state tracking — `CardBase.CardState` enum (`IDLE`, `DRAGGING`, `STACKED`, `STAGING`, `EXPLORING`, `IN_DIALOGUE`) + `var state` on CardBase. Transitions: `start_drag()`→DRAGGING, `_end_drag()`→IDLE, `_try_stack()`→STACKED, `set_staging_mode()`→STAGING/IDLE, `exploration_system`→EXPLORING/IDLE, `dialogue_system`→IN_DIALOGUE. `CardManager` tracks `dialogue_root_card` for cleanup; `cancel_dialogue()` resets both root and topic states.

### CardBase Refactor (scripts/card_base/)
- `visual_component.gd` — StyleBoxFlat, labels, art, icon (620 lines → component)
- `corruption_component.gd` — Timer, pause/resume (250 lines → component)
- `card_base.gd` dropped from ~830 to ~260 lines

### Card Scene Customization
- `CardScene` class (`card_scene.gd`) — extends `card_base.gd` with `class_name`; overrides `_gui_input` for scene double-click
- `CardPlaceholder` tool (`card_placeholder.gd`) — editor-only visual placeholder showing card name/type for layout design
- `card_scene_path: String` on `CardData` — replaces `card_scene: PackedScene` with lazy `get_card_scene()` to avoid compile-time preload type errors
- Per-card tscn examples: `zhu_sui_card.tscn` (with ArtSprite for zs.png), `plant_hunter_card.tscn`
- Layout scenes: `layout_library.tscn`, `layout_plant_hunter.tscn` with `CardPlaceholder` nodes
- `clip_contents = true` removed from `card_base.tscn`, `card_scene.tscn`, `plant_hunter_card.tscn`

### Staging Layout
- Card positions no longer calculated in `card_base` — moved to `CardManager` via `EventBus.staging_repositioned`
- Stack/tile toggle button added for staging area (`CardManager`)
- `_was_in_staging` uses `_staging_mode` flag instead of Y-position threshold (reliable for board-stacked children near staging boundary)
- `_end_drag()` staging threshold uses `card_bottom = global_position.y + size.y` instead of bare `global_position.y`

### Sidebar
- Tween-based ejection (20px gap) — `sidebar.gd`
- Clamping fixed with `BOARD_MIN_X` constant

### Rest Mode
- Fatigue bug fixed (count _before_ removal, restore count after action)

### Fatigue
- Tag check changed to `card_data.fatigue_trigger` boolean

### Cards Initial Positions
- Moved from `x=100` to `x=300`

### Progress Bar Prefixes
- Dialogue: `bar.set_label("交谈中...")` with 1.5s blue progress bar before dialogue panel opens, with three cancel guards (topic card nulled, instance invalid, tree removed)
- Exploration: `bar.set_label("探索中...")` — green bar, `config.explore_duration`
- Combination: `bar.set_label("组合中...")` — green bar, 3.0s
- Observation: `bar.set_label("观察中...")` — purple bar, 3.0s
- Rest (fatigue): `bar.set_label("恢复中...")` — green bar, `config.explore_duration`

### Dialogue Close Behavior
- Removed pop-apart (reparent + random position) from `CardManager._on_dialogue_closed()` — dialogue cards stay stacked after close

### Scene Desktop
- `_flatten_stack` changed to recursive traversal for nested card stacks when moving all cards to staging

### Data-Driven SceneConfigRegistry
- `scene_config_registry.gd` — replaced hardcoded factory functions with `@export var configs: Array[ExplorationConfig]`
- `scene_config_registry.tscn` — new scene-based autoload (replaces `.gd` autoload), enables inspector editing
- `resources/exploration/` — directory for individual ExplorationConfig `.tres` files
  - `SCENE_plant_hunter.tres` — 2 branches (采集→plant, 调查→shadow), layout_plant_hunter
  - `SCENE_library.tres` — 1 branch (研读→+10 favorability), layout_library
  - `LOGIC_rest.tres` — rest_mode=true, 1 branch (休息→fatigue card)
- Adding new scenes: create ExplorationConfig `.tres` → drag into registry inspector array

### Data-Driven RecipeRegistry
- `recipe_registry.gd` — replaced hardcoded `_register()` + `preload()` with `@export var recipes: Array[StackRecipe]`
- `recipe_registry.tscn` — new scene-based autoload (replaces `.gd` autoload), enables inspector editing
- `stack_recipe.gd` — added `group_key: String` field for registry grouping (previously implicit in `_register(key, ...)` call)
- `resources/recipes/` — directory for individual StackRecipe `.tres` files
  - `recipe_sdt_observe_peek.tres` — group_key=ITEM_sdt, LOGIC_observe→ITEM_peek_truth (w:1.0, unlimited)
  - `recipe_sdt_observe_coin.tres` — group_key=ITEM_sdt, LOGIC_observe→ITEM_coin (w:0.4, unlimited)
  - `recipe_sdt_coin_plant.tres` — group_key=ITEM_sdt, ITEM_coin→ITEM_plant (w:1.0, 1 drop)
  - `recipe_sdt_peek_corrupt.tres` — group_key=ITEM_sdt, ITEM_peek_truth→ITEM_corrupted_sample (w:1.0, 1 drop)
  - `recipe_sdt_shadow_purify.tres` — group_key=ITEM_sdt, ITEM_shadow→destroys target (w:1.0, unlimited)
  - `recipe_capture_zhusui.tres` — group_key=LOGIC_capture, CHAR_zhu_sui→ITEM_handwritten_note (w:1.0, 1 drop)
- Adding new recipes: create StackRecipe `.tres` → set group_key → drag into registry inspector array

### Dialogue System — Redesigned as AVG-Style Bottom Panel
- `scenes/dialogue/dialogue_panel.tscn` — full-screen overlay with bottom-anchored text box
  - `BgOverlay` (ColorRect, 55% black) — click to advance
  - `TextBox` (Panel, ~80% width, 260px tall, bottom-anchored)
  - `PortraitMargin` + `PortraitBg` + `Portrait` (TextureRect, 130×230)
  - `SpeakerName` (Label, cyan colored)
  - `TextLabel` (Label, autowrap, visible_characters typewriter)
  - `BranchContainer` (VBoxContainer, replaces text when choices)
  - `ContinueIndicator` (Label, blinking "▼" / "结束")
  - `CloseBtn` (Button, "✕")
- `scripts/dialogue/dialogue_panel.gd` — typewriter effect with `_process` + `visible_characters`
  - Click to advance (BgOverlay `gui_input`)
  - `speaker` field in JSON overrides portrait + name dynamically
  - `_set_speaker_by_id()` loads card art, name, border_color
  - Actions: `favorability`, `spawn_card`
  - Branch selection (VBoxContainer of Buttons)
  - No longer extends `DraggablePanel`
  - Layout set via editor anchors (not script)

### Dialogue JSON Speaker Support
- `dlg_tec.json` — `"speaker": "CHAR_tec"` on all nodes
- `dlg_junior_investigator.json` — `"speaker": "CHAR_junior_investigator"` on all nodes
- `dlg_zhu_sui.json` — `"speaker": "CHAR_zhu_sui"` on all nodes; cleaned up inline name prefixes
- `CHAR_zhu_sui.tres` — `art = res://assets/zs.png` assigned for portrait display; `card_scene_path` set to `zhu_sui_card.tscn`
- `CHAR_tec.tres` and `CHAR_junior_investigator.tres` — no art set yet (portrait area hidden, name only)

### Dialogue Configs
- `res://resources/dialogues/dlg_tec.tres` — `dialogue_id = "dlg_tec"`, `title = "TEC"`
- `res://resources/dialogues/dlg_zhu_sui.tres` — `dialogue_id = "dlg_zhu_sui"`, `title = "朱穗"`
- `res://resources/dialogues/dlg_junior_investigator.tres` — `dialogue_id = "dlg_junior_investigator"`, `title = "初级调查员"`

### Key Constants
- `BOARD_MIN_X = -100` in sidebar clamping
- `TYPE_SPEED = 0.035` in dialogue typewriter
- Cards spawn at `randi_range(200, 600)`, `randi_range(300, 600)`
- `STAGING_Y = 820`, `STAGING_FIRST_X = 300`, `STAGING_BAR_LEFT = 280`, `STAGING_VISIBLE = 1418`

## In Progress
- Staging re-insertion verification — may still fail for cards dropped in the middle of the pile

## To Do
- Additional dialog json files for other characters
- Portrait art for TEC and junior investigator
- Dialogue node editor tooling
- Save/load dialogue state
- Audio cues for dialogue advancement
