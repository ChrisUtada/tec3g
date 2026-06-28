# Project Progress

## Completed

### High Priority Optimizations
- StyleBoxFlat caching in `card_base.gd` — `_make_stylebox()` cache dict prevents 20+ allocs per card
- Corruption timer null-safety — `corruption_component.gd` checks `is_inside_tree()` and scene validity
- Scene null checks in `PanelManager._close_group()` and `ObservationSystem`
- `STAGING_Y` deduplicated in `card_manager.gd`
- CardManager state encapsulation — added `cancel_combination()`, `cancel_observation()`, `cancel_dialogue()`, `cancel_all_pending()` lifecycle methods; `is_combo_in_progress()`, `is_dialogue_in_progress()`, `is_panel_open()` query helpers. `SceneDesktopManager._cleanup_card_manager_state()` reduced from 12 lines of direct field manipulation to single `cancel_all_pending()` call. `CardManager._on_card_broken()` uses cancel methods instead of scattered cleanup.
- `collect_stack_ids()` deduplicated — moved from `combination_system.gd` (static method) to `CardManager.collect_stack_ids()` public static method alongside `_stack_root()`
- `_pressed_self` safety valve in `card_base.gd` `_process()` — resets stuck press state when mouse button is no longer held (e.g. card reparented mid-press). Prevents "ghost drag" on next click.
- `register_card` dedup — `_enter_tree()` now self-resolves `_container` and is the sole registration point (paired with `_exit_tree()` unregister). Removed duplicate `register_card` call from `_ready()`. Eliminates stale entry in `_all_cards` array.
- Progress bar `resume()` — `pause()` now records `_remaining_ratio` at kill time; `resume()` uses recorded value instead of recalculating from visual width. Safe against size changes during pause.
- `_on_card_stacked` routing priority — documented 4-step dispatch chain: observe → scene guard → dialogue → combination fallback.
- `_scene_bg_overlay` insertion — uses `bg.get_index() + 1` instead of hardcoded index 1, resilient to main.tscn node order changes.
- `class_name CardBase` added to `card_base.gd` — enables `is CardBase` type checks; `CardScene` inherits via path reference, unaffected.
- Card registry multi-instance — `EventBus._cards_by_id` changed from `card_id -> card` to `card_id -> Array[card]`, preventing silent overwrite when multiple cards share the same ID. `get_card_by_id()` returns latest instance (backward compatible), new `get_all_cards_by_id()` returns all instances. `unregister_card()` correctly removes single instance from array, only erases key when empty.
- Card instance ID — `CardBase` has `static var _next_instance_id` counter and `var instance_id: int`, assigned in `_ready()` (stable through reparenting). Sidebar and main.gd log messages now include `[#id]` suffix for debugging.
- Spawn Policy centralization — `CardData.SpawnPolicy` enum (`UNLIMITED`, `UNIQUE_ON_BOARD`, `UNIQUE_PER_GAME`) replaces dead fields `allow_duplicate`/`drop_once`. `CardManager.can_spawn(data)` gates all `spawn_card()` calls; `_per_game_spawned` dict tracks per-session limits; `reset_spawn_tracking()` clears it for new game. `combination_system.gd` guards against null return (spawn rejected → skip emit).
- Data-driven initial spawn — `CardData.InitialZone` enum (`NONE`, `BOARD`, `STAGING`) + `initial_position: Vector2` on CardData. `main.gd._spawn_initial_cards()` scans `resources/cards/` directory, spawns cards with `initial_zone != NONE` at their configured positions. No more hardcoded preload lists. 10 cards configured: SCENE_plant_hunter on BOARD at (1220,80), 9 others in STAGING.
- DropRecipe → SpawnPolicy migration — `unique`/`no_duplicate` fields removed from `DropRecipe`; spawn gating now handled by `CardData.spawn_policy` on result cards. `ITEM_shadow.tres` set to `UNIQUE_PER_GAME`. `EventBus.can_drop()` simplified (removed `unique` special case), `has_dropped_unique()` removed.
- Card state tracking — `CardBase.CardState` enum (`IDLE`, `DRAGGING`, `STACKED`, `STAGING`, `IN_DIALOGUE`) + `var state` on CardBase. Transitions: `start_drag()`→DRAGGING, `_end_drag()`→IDLE, `_try_stack()`→STACKED, `set_staging_mode()`→STAGING/IDLE, `dialogue_system`→IN_DIALOGUE. `CardManager` tracks `dialogue_root_card` for cleanup; `cancel_dialogue()` resets both root and topic states.

### Dialogue JSON Validation
- `dialogue_panel.gd` — `_validate_dialogue(data, path)` static function runs on every JSON load via `_load_json()`. Checks: `start` node exists, topic references valid, all `next_node_id` and option references resolve, action types recognized (`favorability`/`spawn_card`), action fields non-empty, unreachable nodes warned. Errors emitted as `push_warning()` with file tag prefix.
- Inline validation also available in `catalog.gd` `_validate_dialogue_static()` for editor-time checks.

### Card Catalog (@tool)
- `scenes/tools/catalog.tscn` + `scripts/tools/catalog.gd` — editor-only `@tool` scene for visual card overview. Open in Godot editor to see:
  - All cards grouped by type (CHAR/ITEM/LOGIC/SCENE/CLUE/DEBUFF) with properties, initial zone, spawn policy
  - Per-card relationship summary: recipes (as input/output), dialogue configs, corruption timers
  - Full recipe list with group keys, targets, results, weights, drop limits
  - Dialogue file summary with node counts and inline validation warnings
  - Refresh button to reload after editing .tres/.json files

### CardBase Refactor (scripts/card_base/)
- `visual_component.gd` — StyleBoxFlat, labels, art, icon (620 lines → component)
- `corruption_component.gd` — Timer, pause/resume (250 lines → component)
- `card_base.gd` dropped from ~830 to ~260 lines

### Card Scene Customization
- `CardScene` class (`card_scene.gd`) — extends `card_base.gd` with `class_name`; overrides `_gui_input` for scene double-click
- `CardPlaceholder` tool (`card_placeholder.gd`) — editor-only visual placeholder showing card name/type for layout design
- `card_scene_path` mechanism removed — all cards use `card_base.tscn` (non-scene) or `card_scene.tscn` (SCENE type) based on `card_type`; visual customization via `CardData.art` (Texture2D) and color fields in Inspector
- Per-card custom `.tscn` files (`zhu_sui_card.tscn`, `plant_hunter_card.tscn`) deleted; `scenes/cards/card_scenes/` directory removed
- Layout scenes: `layout_library.tscn`, `layout_plant_hunter.tscn` with `CardPlaceholder` nodes
- `clip_contents = true` removed from `card_base.tscn`, `card_scene.tscn`
- `card_base.gd` no longer loads `card_scene.gd` or does runtime `set_script()` swap — SCENE cards are always instantiated with `card_scene.tscn` which already has `CardScene` script

### Staging Layout
- Card positions no longer calculated in `card_base` — moved to `CardManager` via `EventBus.staging_repositioned`
- Stack/tile toggle button added for staging area (`CardManager`)
- `_was_in_staging` uses `_staging_mode` flag instead of Y-position threshold (reliable for board-stacked children near staging boundary)
- `_end_drag()` staging threshold uses `card_bottom = global_position.y + size.y` instead of bare `global_position.y`

### Sidebar
- Tween-based ejection (20px gap) — `sidebar.gd`
- Clamping fixed with `BOARD_MIN_X` constant

### Rest Mode
- LOGIC_rest.tres deleted — replaced by `ITEM_bench` card + `recipe_bench_rest.tres` (consumes_top behavior: bench stays, fatigue consumed)
- Fatigue bug fixed (count _before_ removal, restore count after action)

### Fatigue
- Tag check changed to `card_data.fatigue_trigger` boolean

### Cards Initial Positions
- Moved from `x=100` to `x=300`

### Progress Bar Prefixes
- Dialogue: `bar.set_label("交谈中...")` with 1.5s blue progress bar before dialogue panel opens, with three cancel guards (topic card nulled, instance invalid, tree removed)
- Combination: `bar.set_label("组合中...")` — green bar, 3.0s
- Observation: `bar.set_label("观察中...")` — purple bar, 3.0s

### Dialogue Close Behavior
- Removed pop-apart (reparent + random position) from `CardManager._on_dialogue_closed()` — dialogue cards stay stacked after close

### Scene Desktop
- `_flatten_stack` changed to recursive traversal for nested card stacks when moving all cards to staging
- `SceneDesktopManager` reads `layout_scene` directly from `CardData` (no longer depends on `ExplorationConfig`/`SceneConfigRegistry`)
- `CardData.layout_scene: PackedScene` — set in Inspector on scene-type card .tres files

### Exploration System Removal
- Entire exploration system removed — scene desktop mode + combination system replaces all exploration functionality
- Deleted files: `exploration_system.gd`, `scene_config_registry.gd/.tscn`, `exploration_config.gd`, `slot_branch_recipe.gd`, `panel_slot_config.gd`, `drop_recipe.gd`, `exploration_panel.gd/.tscn`, 3 exploration `.tres` configs
- `CardData.layout_scene` replaces `ExplorationConfig.layout_scene`; `SceneDesktopManager` checks `card_data.layout_scene` instead of `SceneConfigRegistry.get_config()`
- Exploration branches migrated to `StackRecipe` `.tres`: `recipe_scene_ph_gather.tres` (采集: sdt+coin→plant, 1次), `recipe_scene_ph_investigate.tres` (调查: junior_investigator+sdt→shadow)
- Routing chain simplified: observe → scene guard → dialogue → combination (4 steps, was 5)
- `CardState.EXPLORING` removed from enum; `CardManager.exploring` variable removed
- `EventBus.exploration_requested` signal removed; `PanelManager` no longer handles exploration panels
- `RecipeRegistry` converted from scene-based autoload (inspector array) to script-based autoload with `DirAccess` directory scanning of `resources/recipes/`; `recipe_registry.tscn` deleted; added `reload()` method

### Data-Driven RecipeRegistry
- `recipe_registry.gd` — script-based autoload, auto-scans `res://resources/recipes/` directory via `DirAccess` at `_ready()`. No more inspector array or `.tscn` wrapper.
- `stack_recipe.gd` — `group_key: String` field for registry grouping; additional fields: `consumes_top` (destroy top card only), `add_favorability` (modify CHAR favorability on combine), `require_tags` (tag gate), `require_favorability_min` (favorability gate), `chain_id` (chain/phase grouping metadata)
- `resources/recipes/` — directory for individual StackRecipe `.tres` files
  - `recipe_sdt_observe_peek.tres` — group_key=ITEM_sdt, LOGIC_observe→ITEM_peek_truth (w:1.0, unlimited)
  - `recipe_sdt_observe_coin.tres` — group_key=ITEM_sdt, LOGIC_observe→ITEM_coin (w:0.4, unlimited)
  - `recipe_sdt_coin_plant.tres` — group_key=ITEM_sdt, ITEM_coin→ITEM_plant (w:1.0, 1 drop)
  - `recipe_sdt_peek_corrupt.tres` — group_key=ITEM_sdt, ITEM_peek_truth→ITEM_corrupted_sample (w:1.0, 1 drop)
  - `recipe_sdt_shadow_purify.tres` — group_key=ITEM_sdt, ITEM_shadow→destroys target (w:1.0, unlimited)
  - `recipe_capture_zhusui.tres` — group_key=LOGIC_capture, CHAR_zhu_sui→ITEM_handwritten_note (w:1.0, 1 drop)
  - `recipe_scene_ph_gather.tres` — group_key=ITEM_sdt, ITEM_coin→ITEM_plant (w:1.0, 1 drop, 采集)
  - `recipe_scene_ph_investigate.tres` — group_key=CHAR_junior_investigator, ITEM_sdt→ITEM_shadow (w:1.0, unlimited, 调查)
  - `recipe_bench_rest.tres` — group_key=ITEM_bench, ITEM_fatigue→consumes_top (unlimited, 坐下休息)
- Adding new recipes: create StackRecipe `.tres` → set group_key → drop into `resources/recipes/` (auto-scanned)

### Combination System Behaviors
`combination_system.gd` — stack recipe dispatch with 5 behavior modes, executed in the bar callback:
- **Spawn Result** (default) — `result_card` set → spawn `randi_range(min_count, max_count)` copies at `base_pos + (i*30, 0)`. Emits `EventBus.card_combined`.
- **Destroys Target** (`destroys_target`) — root is `queue_free()`'d; all stacked children reparented to container and scattered at `root.pos + (0, 80)`.
- **Consumes Top** (`consumes_top`) — top card is `queue_free()`'d; its stacked children reparented to container with randomized offset. Root preserved (e.g. bench stays, fatigue consumed).
- **Favorability Side Effect** (`add_favorability`) — finds CHAR card in stack, modifies `card_data.favorability` clamped to `[0, max_favorability]`, emits `EventBus.favorability_changed`.
- **Conditional Recipes** — `require_tags` (each tag must exist on at least one card in stack) and `require_favorability_min` (CHAR card in stack must meet threshold). Checked in `_recipe_matches_stack()` before recipe is considered a hit.
- **Chain Tracking** (`chain_id`) — metadata string for grouping related recipes into evolution/phase chains. Displayed in catalog; not used in runtime logic yet.
- Matching: `_collect_stack_cards()` recursive traversal, `_find_char_card_in()` locates CHAR card for favorability operations.

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
- `CHAR_zhu_sui.tres` — `art = res://assets/zs.png` assigned for portrait display and card face
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
