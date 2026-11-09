# Using Spotlight Guide

## Requirements

- Godot 4.7.2 stable (the tested version) or a compatible newer Godot 4.x release
- A `Control` target in the same canvas coordinate space as the overlay

Version 1.0.0 does not support `Node2D`, camera tracking or targets on
different canvas layers.

## Add the overlay

1. Copy `addons/spotlight_guide` into your project.
2. Enable **Spotlight Guide** under **Project Settings > Plugins**.
3. Add a `SpotlightGuide_Overlay` node to the scene that owns the tutorial.
4. Set `target_root_path` to the node from which each step's target path is
   resolved.

For a step with `target_path = "MapPanel"` and
`target_root_path = "../GameUI"`, the addon resolves
`../GameUI/MapPanel` from the overlay.

## Create a guide

1. Create a new `SpotlightGuide_Step` resource for each step.
2. Set `title`, `body`, `target_path`, `placement` and `focus_padding`.
3. Create a new `SpotlightGuide_Sequence`.
4. Give the sequence a stable `id`.
5. Add the step resources in the desired order.
6. Assign the sequence to the overlay's `sequence` property.
7. Call `start()` when the game is ready to show the guide.

The example resources are in:

```text
example/spotlight_guide_sequence.tres
example/steps/01_settings.tres
example/steps/02_objective.tres
example/steps/03_inventory.tres
example/steps/04_build.tres
example/steps/05_end_turn.tres
```

## Runtime API

```gdscript
@onready var guide: SpotlightGuide_Overlay = $SpotlightGuideOverlay

func show_tutorial() -> void:
	guide.start()

func skip_tutorial() -> void:
	guide.skip()

func reset_tutorial() -> void:
	guide.reset_saved_progress()
```

Useful methods:

- `start(sequence_override = null)` starts a sequence.
- `advance()` moves to the next step.
- `skip()` closes the active guide and restores the previous pause state.
- `is_completed(sequence_id)` checks the current completion state.
- `reset_saved_progress()` clears local and in-memory completion state.

## Signals

```gdscript
guide.step_changed.connect(_on_guide_step_changed)
guide.step_completed.connect(_on_guide_step_completed)
guide.guide_finished.connect(_on_guide_finished)
guide.guide_skipped.connect(_on_guide_skipped)
```

`step_completed` is intended to be the bridge to a game-specific save system.
The built-in `ConfigFile` is a convenient default, not a required save system.

## Persistence

When `save_progress` is enabled, completion is written to:

```text
user://spotlight_guide_progress.cfg
```

When persistence is disabled or the file cannot be saved, completion remains
available in memory for the current session. This is the intended behavior for
the public browser demo.

## Web demo behavior

When run with the `web` feature:

- Only the first two demo steps are exposed.
- Persistent storage is disabled.
- A notice explains that browser progress is not saved.

The actual Web export still requires the matching Godot export templates.

