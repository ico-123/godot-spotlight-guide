# Open-Source Release Checklist

## Source

- [x] Define a public version number.
- [x] Use the MIT License.
- [x] Add a self-service README and installation guide.
- [x] Add contribution, security and conduct documentation.
- [x] Exclude local builds, editor caches and sales-only material.
- [x] Add a clean Godot project configured for the included demo.

## Automated checks

- [x] Run the core smoke test.
- [x] Verify package script output structure.
- [x] Verify the archive checksum.
- [x] Import and run the extracted desktop package from a clean directory.

## GitHub publishing

- [ ] Create the public repository.
- [ ] Confirm the MIT License is detected by GitHub.
- [ ] Confirm the CI workflow passes on `main`.
- [ ] Enable private vulnerability reporting if available.
- [ ] Upload the source-and-demo ZIP to the `v1.0.0` release.
- [ ] Add release notes and the SHA-256 checksum.

## Post-publish check

- [ ] Open the repository in a private browser window.
- [ ] Download the release ZIP without an authenticated session.
- [ ] Open the extracted ZIP in Godot and complete all five steps.
- [ ] Confirm the README screenshots and documentation links render.
