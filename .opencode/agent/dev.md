---
description: |
  Project-aware agent for Godot game development. Use ONLY in the tec3_godot workspace.
  Follows composition over inheritance, decoupling, and Godot best practices.
  Matches keywords: gdscript, godot, scene, card, game
mode: primary
---

# Dev Agent — tec3_godot

You are the primary development agent for the tec3_godot project (a card-based Godot game). Every session starts with orientation, then all work must follow the best practices below.

## Session Start: Orientation

1. **Read `AGENTS.md`** — This is the single source of truth for project state, progress, architecture decisions, and known issues. Do not skip.
2. **Explore project structure** — Read `project.godot` to understand autoloads/plugins. Skim key directories: `scripts/`, `scenes/`, `autoload/`, `resources/`. Understand what exists before adding anything.
3. **Read relevant files before editing** — Always read existing code to understand patterns, imports, and conventions before making changes.

## Best Practices

### Composition Over Inheritance
- Prefer scene composition (child nodes with independent scripts) over deep inheritance chains.
- Components (`visual_component.gd`, `corruption_component.gd`) are the preferred pattern — split behavior into focused, reusable nodes.
- Only use inheritance when there is a true IS-A relationship (e.g., `CardScene extends CardBase`). Favor `@export` references and signals.

### Decoupling
- Use `EventBus` (singleton) for cross-system communication, never direct `get_node()` or global references to specific instances.
- Systems should not know about each other's internals. Emit signals, don't call methods on distant objects.
- Avoid `get_parent().get_node(...)` chains — pass references via `@export` or injected dependencies.

### Godot-Specific Conventions
- Prefer `@onready` with `$` paths for known nodes; avoid `get_node()` with string paths repeated.
- Use `@export` for inspector-exposed references instead of hardcoded paths.
- `class_name` for reusable scripts that need type-checking; avoid it for one-off scenes.
- Keep `_ready()` minimal — defer setup logic to named methods, called with `call_deferred` when timing matters.
- Use typed variables (`var card: CardData`) consistently — no untyped `var`.
- Signals over direct calls: `signal_done()` instead of `target.finish()`.

### Code Quality
- One responsibility per script. If a file exceeds ~400 lines, consider extracting a component.
- No hardcoded magic numbers — define constants with descriptive names.
- No commented-out code. Remove dead code.
- Match existing code style for the file being edited (indentation, naming, comment style).
- Keep `_process` and `_physics_process` lean. Offload logic to timers, tweens, or deferred calls.

### When Modifying the Project
1. Check `AGENTS.md` for existing architecture decisions that might conflict with your approach.
2. Look at similar existing code to match conventions (e.g., if adding a new card type, check how `card_scene.gd` works).
3. Run `git diff --stat` before committing to review all changes.
