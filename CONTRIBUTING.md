# Contributing

Thanks for helping improve Godot Spotlight Guide.

## Before opening an issue

- Search existing issues and pull requests.
- Run the demo and automated test with the latest `main` branch.
- Include your Godot version, operating system and renderer.
- Provide the smallest scene or code sample that reproduces the problem.

## Development workflow

1. Fork the repository and create a focused branch.
2. Make the smallest change that solves the problem.
3. Preserve the public `SpotlightGuide_` naming convention.
4. Add or update demo coverage for user-visible behavior.
5. Run the smoke test.
6. Document public API or compatibility changes.
7. Open a pull request describing the behavior before and after the change.

Run the local test:

```powershell
godot --headless --path . --script res://tests/smoke_test.gd
```

Expected result:

```text
SMOKE_TEST_OK
ALL_CHECKS_PASSED
```

## Compatibility policy

- 1.x releases preserve the documented public API where practical.
- Breaking changes require a major version and a migration note.
- New target types or coordinate-space support must include automated or
  reproducible manual coverage.
- Keep the addon usable without a paid dependency or closed-source service.

## Pull request scope

Good pull requests are narrowly scoped and include a verification story. Large
refactors, visual redesigns and new subsystems should start with an issue so the
compatibility impact can be discussed before implementation.

By contributing, you agree that your contribution is licensed under the
repository's MIT License.
