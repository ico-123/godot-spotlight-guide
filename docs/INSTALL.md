# Installation

## Try the included demo

1. Install Godot 4.7.2 stable or another Godot 4.x release.
2. Open the repository directory as a project.
3. Open `example/demo.tscn` if it is not already the main scene.
4. Press `F5`.
5. Use `Next`, `Skip` and `Replay Guide` to exercise the guide.

## Install only the addon

Copy this directory into the target project:

```text
addons/spotlight_guide
```

The resulting structure must be:

```text
your-project/
└── addons/
    └── spotlight_guide/
        ├── plugin.cfg
        ├── plugin.gd
        └── ...
```

Open **Project Settings > Plugins** and enable **Spotlight Guide**.

The editor prints a warning if a project-owned autoload or input action uses
one of the reserved `SpotlightGuide_` names. Rename the conflicting action if
the warning is unrelated to this addon.

## Configure a guide

1. Create a `SpotlightGuide_Step` resource for every tutorial step.
2. Set its title, body, target path, placement and focus padding.
3. Create a `SpotlightGuide_Sequence` and give it a stable unique `id`.
4. Add the steps to the sequence in display order.
5. Add a `SpotlightGuide_Overlay` node to the tutorial scene.
6. Assign the sequence to the overlay.
7. Set `target_root_path` to the node from which target paths are resolved.
8. Call `start()` after the target controls are ready.

The resources under `example/` are complete working examples.

## First-run behavior

When `skip_if_completed` is enabled, a sequence with saved completion state does
not start automatically. Call `reset_saved_progress()` before `start()` when the
player explicitly requests a replay.

When `save_progress` is enabled, completion is stored at:

```text
user://spotlight_guide_progress.cfg
```

Use the `step_completed` and `guide_finished` signals if progress should live in
an existing save system instead.

## Troubleshooting

**The overlay starts, but the callout is centered and no target is outlined**

Check that `target_root_path` and the step's `target_path` resolve to a
`Control`. Node2D targets are not supported in 1.0.0.

**The target does not line up with the focus area**

Keep the overlay and target in the same canvas coordinate space. Canvas-layer
transforms and camera movement require application-specific conversion that is
outside the current scope.

**The guide is skipped automatically**

The sequence is already completed. Disable `skip_if_completed` or call
`reset_saved_progress()` before `start()`.

**Clicking the rest of the game does nothing while the guide is active**

This is intentional. The transparent input-blocking surface prevents accidental
interaction during the tutorial.
