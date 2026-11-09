# Spotlight Guide 1.0.0 QA Report

- Date: 2026-11-09
- Product version: 1.0.0
- Engine: Godot 4.7.2 stable
- Distribution: free and open source under the MIT License

## Automated checks

The Godot smoke test covers:

- all five desktop targets resolve
- callout bounds remain inside the viewport
- completion and persisted completion state
- skip behavior and pause-state restoration
- memory fallback with persistence disabled
- viewport resize re-anchoring
- a two-step Web sequence

Expected result:

```text
SMOKE_TEST_OK
ALL_CHECKS_PASSED
```

## Package checks

The packaging scripts verify required files, archive structure and SHA-256
checksums. The clean desktop package can be opened as a Godot project and run
without the development checkout.

## Compatibility statement

Only Godot 4.7.2 stable is claimed as directly tested in this release. The
addon uses Godot 4 APIs and is expected to work on nearby 4.x versions, but
those versions should be treated as unverified until CI or a user report
confirms them.

## Known limitations

- Only `Control` targets are supported.
- Targets must share the overlay's canvas coordinate space.
- Node2D, camera-space tracking and cross-canvas-layer transformations are not
  included.
- The built-in `ConfigFile` persistence is intentionally simple and can be
  replaced by connecting completion signals to a project's save system.
