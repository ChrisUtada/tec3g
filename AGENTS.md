# Project Progress

## Completed

### High Priority Optimizations
- StyleBoxFlat caching in `card_base.gd` — `_make_stylebox()` cache dict prevents 20+ allocs per card
- Corruption timer null-safety — `corruption_component.gd` checks `is_inside_tree()` and scene validity
- Scene null checks in `PanelManager._close_group()` and `ObservationSystem`
- `STAGING_Y` deduplicated in `card_manager.gd`

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
