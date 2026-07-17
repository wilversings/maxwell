# tools/

## grab_screenshot.qml

Renders `view3d.qml` (3D Mesh mode) offscreen at a chosen pose and saves
it as a **transparent** PNG. Useful for KDE Store listing screenshots,
README images, etc. — anywhere you want Maxwell without a background to
crop or key out by hand.

Adapted from the equivalent tool in
[contriburg](https://github.com/wilversings/contriburg). It doesn't touch
a live Plasmoid, panel, or `plasmoidviewer` at all — it supplies its own
minimal mock `plasmoid` context property (the same one `tests/tst_main.qml`
uses) so `view3d.qml` loads standalone. The transparency comes from
`view3d.qml`'s own `SceneEnvironment.Transparent` setup — this script just
grabs the rendered frame with `Item.grabToImage()`, which preserves alpha,
instead of screenshotting a real window (desktop screenshot tools flatten
transparency against whatever's behind the window, so they won't work for
this).

Unlike contriburg's tool, the root `Item` here is `visible: true`, not
`false`. `view3d.qml`'s 3D content renders through QtQuick3D's own
internal render pass, which only picks up a property change once the
window has actually been shown and the render loop has run at least one
real frame — with `visible: false` (contriburg's approach, fine for its
plain 2D content), `grabToImage()` keeps grabbing whatever the 3D scene's
texture happened to be at its very first sync, no matter what you change
afterwards. This cost some debugging time (see git history if curious),
so: don't "fix" this back to `visible: false`.

### Usage

Requires the `qml-qt6` binary (ships with `qt6-qtdeclarative`/
`qt6-qtdeclarative-devel`, same as `tests/`), plus QtQuick3D. Assimp is
**not** required — the mock `plasmoid.configuration.glbpath` here matches
the bundled default mesh, which renders through the native (non-Assimp)
path (see `MEMORY_ANALYSIS.md`); it'd only come into play if this mock
were pointed at a custom GLB. Also needs a real windowing backend (a live
desktop session, or Xvfb) — the Qt `offscreen` QPA platform doesn't
support QtQuick3D's RHI-based rendering at all. Run from the `tools/`
directory (the script's `Loader` source path is relative to it):

```bash
cd tools
qml-qt6 grab_screenshot.qml
```

This saves `maxwell-3d.png` (500x500, posed at a 45° yaw) into the
current directory.

All arguments are optional and positional:

```bash
qml-qt6 grab_screenshot.qml [outputPath] [width] [height] [rotationY]
```

Examples:

```bash
# Custom output path and size
qml-qt6 grab_screenshot.qml store-listing.png 1200 900

# Face Maxwell the other way
qml-qt6 grab_screenshot.qml turned-shot.png 500 500 180
```

The tool pauses `view3d.qml`'s spin animation (`modelSpinning`) and poses
the model directly (`modelEulerRotation`) before grabbing, so the pose is
fully controlled by `rotationY` (degrees) and reproducible — the same
arguments always produce a byte-identical image. This is intentional:
the spin animation itself never actually advances during an offscreen
`grabToImage()` capture (it's driven by the render loop, which a
never-shown window doesn't run), so waiting longer or changing
`glbspeed` before grabbing can't change the captured pose — only setting
`modelEulerRotation` directly can.

### Troubleshooting

- **Blank/empty image, exit code 1, "failed to load view3d.qml"**: Qt
  Quick 3D isn't installed in this environment. Same requirement as
  running the actual widget — see `AGENTS.md`.
- **Exit code 1, "GLB model failed to load"**: only possible if the mock
  `plasmoid.configuration.glbpath` in this script has been pointed at a
  custom GLB — in that case, the Assimp asset import plugin is missing,
  same failure mode `MaxwellWidget.qml` shows in the live widget via
  `hasError`. With the default mock (the bundled mesh), this can't happen.
- **Same pose every time regardless of `rotationY`**: check that
  `visible: true` wasn't reverted to `false` — see above.
- **No output at all**: `console.log` doesn't reliably surface from
  `qml-qt6` in some sandboxed environments — check the exit code
  (`echo $?`) and whether the output file was actually created instead of
  relying on the printed "Saved ..." message.

## measure_memory.qml / measure_memory.sh

Reproduces the measurements in `MEMORY_ANALYSIS.md`: RSS and AMD GPU
(VRAM/GTT) usage for GIF mode, 3D mode (default mesh), 3D mode (custom
mesh via `RuntimeLoader`+Assimp), and a multi-cycle GIF↔3D switching test
to check for leaks.

`measure_memory.qml` drives the real `MaxwellWidget.qml` (same mock
`plasmoid` pattern as `grab_screenshot.qml`/`tests/tst_main.qml`) in a
visible window. `measure_memory.sh` launches it as its own **direct
child** process and polls `/proc/<pid>/status` and `/proc/<pid>/fdinfo`
every `interval` seconds, writing a CSV. It must be the direct parent —
reading another process's `fdinfo` is blocked on this kind of system
regardless of matching uid, which is also why the two scripts are separate
rather than one self-sampling script.

The `fdinfo` parsing (`drm-memory-vram`/`drm-memory-gtt`) is AMD/`amdgpu`-
specific; adapt `measure_memory.sh` for other GPU vendors' `fdinfo` keys.

```bash
cd tools
./measure_memory.sh bare 0.5 -- qml-qt6 measure_memory_bare.qml
./measure_memory.sh gif_steady 0.5 -- qml-qt6 measure_memory.qml gif 1 8000
./measure_memory.sh 3d_steady 0.5 -- qml-qt6 measure_memory.qml 3d 1 8000
./measure_memory.sh 3d_custom_steady 0.5 -- qml-qt6 measure_memory.qml 3d-custom 1 8000
./measure_memory.sh cycle_test 0.5 -- qml-qt6 measure_memory.qml cycle 7 12000
```

Each run produces `<label>.csv` (`ts_ms,vmrss_kb,vmhwm_kb,vram_kb,gtt_kb`)
and `<label>.log` in the current directory (gitignored). To check whether
Assimp actually loaded for a given run, grep the process's own `maps`
while it's running:

```bash
qml-qt6 measure_memory.qml 3d 1 8000 &
grep -i assimp /proc/$!/maps   # should be empty for "3d" (default mesh)
```
