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

### Staging Layout
- Card positions no longer calculated in `card_base` — moved to `CardManager` via `EventBus.staging_repositioned`
- Stack/tile toggle button added for staging area (`CardManager`)

### Sidebar
- Tween-based ejection (20px gap) — `sidebar.gd`
- Clamping fixed with `BOARD_MIN_X` constant

### Rest Mode
- Fatigue bug fixed (count _before_ removal, restore count after action)

### Fatigue
- Tag check changed to `card_data.fatigue_trigger` boolean

### Cards Initial Positions
- Moved from `x=100` to `x=300`

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
- `CHAR_zhu_sui.tres` — `art = res://assets/zs.png` assigned for portrait display
- `CHAR_tec.tres` and `CHAR_junior_investigator.tres` — no art set yet (portrait area hidden, name only)

### Dialogue Configs
- `res://resources/dialogues/dlg_tec.tres` — `dialogue_id = "dlg_tec"`, `title = "TEC"`
- `res://resources/dialogues/dlg_zhu_sui.tres` — `dialogue_id = "dlg_zhu_sui"`, `title = "朱穗"`
- `res://resources/dialogues/dlg_junior_investigator.tres` — `dialogue_id = "dlg_junior_investigator"`, `title = "初级调查员"`

### Key Constants
- `BOARD_MIN_X = -100` in sidebar clamping
- `TYPE_SPEED = 0.035` in dialogue typewriter
- Cards spawn at `randi_range(200, 600)`, `randi_range(300, 600)`

## In Progress
- Dialog system migration — old `scripts/dialogue/dialogue_panel.gd` replaced with new AVG-style version

## To Do
- Additional dialog json files for other characters
- Portrait art for TEC and junior investigator
- Dialogue node editor tooling
- Save/load dialogue state
- Audio cues for dialogue advancement
