# Web Demo Verification

The Web package must be served over HTTP. Opening `index.html` directly with a
`file://` URL is not supported by Godot Web exports.

## Serve locally

Extract:

```text
builds/godot-spotlight-guide-web-demo-1.0.0.zip
```

From the project directory, run:

```powershell
.\tools\serve_web.ps1
```

Open:

```text
http://127.0.0.1:8765/
```

## Expected result

- The main scene loads and the guide opens on the Settings button.
- A notice says browser progress is not saved.
- The counter says `1 / 2`, not `1 / 5`.
- Clicking `Next` moves the spotlight to the map panel.
- Clicking `Finish` closes the guide and restores the demo.
- Refreshing the browser starts from the first step again.
- The browser developer console contains no uncaught resource or script errors.

The HTTP artifact checks are automated. Visual browser checks should be repeated
after deployment because browser, GPU and storage behavior can vary by machine.

