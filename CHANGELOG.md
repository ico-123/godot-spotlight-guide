# Changelog

All notable changes to this project are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## 1.0.0 - 2026-11-09

- Released the first stable open-source version.
- Changed the distribution license from a commercial draft to the MIT License.
- Reworked the README for free GitHub distribution and self-service setup.
- Added detailed installation, contribution, security and QA documentation.
- Added GitHub Actions continuous integration for the Godot smoke test.
- Updated package scripts and exported metadata to version 1.0.0.
- Removed sales-only files and assets from the public GitHub repository.

## 0.9.0

- Converted the five demo steps into inspector-editable `.tres` resources.
- Added `example/spotlight_guide_sequence.tres` and five external step resources.
- Added Web demo behavior that exposes only two steps and disables persistent
  storage.
- Added in-memory completion fallback when saving is disabled or fails.
- Added skip, pause restoration, resize and persistence coverage to the smoke
  test.
- Moved the runnable demo into `example/`.
- Added documentation for resource configuration, signals and current
  limitations.
- Added a clean package script with ZIP validation and a SHA-256 checksum.
- Added a Godot Web export preset and a public Web demo package script.
- Added cover, screenshots, icons, a demo GIF and store copy drafts.

## 0.1.0

- Created the first playable prototype.
- Added spotlight masking, target outline, arrow, callout and step controls.
- Added pause handling, input blocking and `ConfigFile` completion state.
