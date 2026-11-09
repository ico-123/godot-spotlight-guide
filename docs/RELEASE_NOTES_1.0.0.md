# Godot Spotlight Guide v1.0.0

The first stable, free and open-source release of Godot Spotlight Guide.

## What is included

- MIT-licensed Godot 4 addon for resource-driven onboarding and spotlight
  guidance.
- Five-step desktop demo with inspector-editable step and sequence resources.
- Two-step browser demo with in-memory progress.
- Installation guide, API reference, QA report and contribution templates.
- Automated smoke test for target resolution, layout, persistence, skip, pause
  restoration and Web-sequence behavior.

## Install

1. Download `godot-spotlight-guide-1.0.0.zip`.
2. Extract it.
3. Open the extracted project in Godot 4.7.2 and press `F5`.

To add the addon to another project, copy `addons/spotlight_guide` into that
project's `addons/` directory and enable **Spotlight Guide** in
**Project Settings > Plugins**. See the README and `docs/INSTALL.md` for setup.

## Compatibility

Godot 4.7.2 stable is the directly tested version. Nearby Godot 4.x releases
are expected to work but remain unverified.

Supported targets are `Control` nodes in the same canvas coordinate space as
the guide overlay. `Node2D`, camera-space targets and cross-canvas-layer
transformations are not supported in 1.0.0.

## Downloads

- `godot-spotlight-guide-1.0.0.zip`: source, addon and desktop demo.
- `godot-spotlight-guide-web-demo-1.0.0.zip`: static Web demo; serve over HTTP
  rather than opening `index.html` with a `file://` URL.
- Each archive has a matching `.sha256.txt` checksum.

## License

Released under the MIT License. Commercial games, internal tools and
redistributed modifications are permitted with the license notice included.
