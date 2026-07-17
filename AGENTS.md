# AGENTS.md

## Project Overview

**Maxwell** is a KDE Plasma widget (Plasmoid) that displays "Maxwell the carryable cat" on the desktop. It supports two display modes: a classic animated GIF and a 3D mesh rendering. A configurable theme song can be played on click or double click.

- **Plugin ID:** `maxwell`
- **Version:** 1.3.0
- **Category:** Fun and Games
- **License:** GPL3
- **Minimum Plasma API:** 6.0
- **Repository:** https://github.com/wilversings/maxwell

## Technology Stack

- **QML/QtQuick** – UI framework for Plasma applets
- **QtMultimedia** – Sound playback via `SoundEffect`
- **QtQuick3D** – 3D scene rendering (camera, lighting; native `Model`/balsam-converted mesh for the bundled default, `RuntimeLoader` + Assimp for user-supplied GLB files)
- **KDE Frameworks (Kirigami, Plasma Shell APIs, KCMUtils)** – Plugin integration & configuration UI
- **build.sh** – Shell script for packaging (uses `jq`, `tar`)

## Project Structure

```
.
├── build.sh                  # Packaging script (creates .tar.xz)
├── metadata.json             # Plasma plugin metadata (ID, version, author, etc.)
├── README.md                 # User-facing documentation
├── KDESTOREPAGE.md           # KDE Store listing page content
├── CHANGELOG.md              # Per-version changelog
├── MEMORY_ANALYSIS.md        # Memory/GPU footprint analysis, GIF vs 3D mode, leak check
├── .gitignore
├── build/                    # Packaged .tar.xz output from build.sh (gitignored)
├── contents/
│   ├── config/
│   │   ├── config.qml        # Config page model (registers "General" category)
│   │   └── main.xml          # Configuration schema (defines user-settable options)
│   └── ui/
│       ├── main.qml          # Entry point, delegates to MaxwellWidget.qml
│       ├── MaxwellWidget.qml # Core widget UI logic (GIF/3D switching, sound)
│       ├── view3d.qml        # Isolated 3D scene (QtQuick3D)
│       ├── CustomMeshLoader.qml # RuntimeLoader wrapper for user-supplied GLB files (Assimp-dependent)
│       ├── assets/
│       │   ├── maxwell.png            # Widget icon (metadata.json) & README/store screenshot
│       │   ├── maxwell-spinning.gif   # Default animated GIF
│       │   ├── maxwell-spinning.glb   # Default 3D model (GLB format, source for mesh/ below)
│       │   ├── mesh/                  # Default model pre-converted to native Qt Quick 3D format via balsam
│       │   │   ├── MaxwellMesh.qml    # Generated scene graph (materials, textures, node hierarchy)
│       │   │   ├── meshes/*.mesh      # Generated binary geometry
│       │   │   └── maps/*             # Generated textures
│       │   └── stockmarket.wav        # Default theme song
│       └── config/
│           └── General.qml  # Configuration dialog UI
├── tests/
│   ├── CMakeLists.txt        # CMake test configuration
│   ├── MockPlasmoid.qml      # Simulated Plasmoid environment for tests
│   ├── README.md             # Testing documentation
│   ├── run_tests.sh          # Script to execute tests
│   ├── tst_main.qml          # Unit tests using QML Test framework
│   ├── mock/                 # Mock Plasma modules for isolated testing
│   │   └── org/kde/plasma/   # Mock implementations of core/plasmoid
│   └── org/                  # Plasma module overrides for test environment
│       └── org/kde/plasma/   # Real Plasma module shims
└── tools/
    ├── README.md              # Usage docs for grab_screenshot.qml and measure_memory.*
    ├── grab_screenshot.qml    # Renders view3d.qml offscreen to a transparent PNG (store/README screenshots)
    ├── measure_memory.qml     # Drives MaxwellWidget.qml for RSS/GPU measurement (see MEMORY_ANALYSIS.md)
    ├── measure_memory_bare.qml # Bare Qt Quick baseline for measure_memory.sh
    └── measure_memory.sh      # Samples RSS + AMD GPU usage of a measure_memory.qml run
```

## Key Files

| File | Purpose |
|------|---------|
| `metadata.json` | Plugin identity, versioning, author info, and Plasma API requirements |
| `contents/ui/main.qml` | Entry point for the Plasmoid, delegates to `MaxwellWidget.qml` |
| `contents/ui/MaxwellWidget.qml` | Core widget: switches between GIF (`AnimatedImage`) and 3D Mesh (`View3D`) modes, handles click/double-click to play sound |
| `contents/ui/CustomMeshLoader.qml` | `RuntimeLoader` wrapper for user-supplied GLB files - the only place `QtQuick3D.AssetUtils`/Assimp is used |
| `contents/ui/assets/mesh/MaxwellMesh.qml` | Bundled default mesh, pre-converted from the GLB via `balsam` - no Assimp needed to load it |
| `contents/config/main.xml` | Defines all configurable settings (display mode, paths, speeds, loops, mirror, quality) |
| `contents/config/config.qml` | Registers config pages with Plasma's settings dialog |
| `contents/ui/config/General.qml` | UI for the configuration dialog (conditionals per display mode, file browsers, sliders) |
| `build.sh` | Packages the widget into a `.tar.xz` archive for distribution |
| `KDESTOREPAGE.md` | KDE Store listing page content (features, configuration, requirements) |

## Configuration Options

The widget exposes the following user-configurable settings (defined in `contents/config/main.xml`):

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `displaymode` | String | `GIF` | Display mode: `"GIF"` or `"3D Mesh"` |
| `gifpath` | Path | `assets/maxwell-spinning.gif` | Path to the animated GIF to display |
| `glbpath` | Path | `assets/maxwell-spinning.glb` | Path to the 3D model (GLB) to display |
| `themepath` | Path | `assets/stockmarket.wav` | Path to the theme song audio file |
| `playthemesong` | String | `On Double Click` | When to play theme song (`Never`, `On Click`, `On Double Click`) |
| `themesongloops` | Int | `1` | Number of times to loop the theme song |
| `gifspeed` | Double | `1` | GIF animation playback speed multiplier |
| `glbspeed` | Double | `2` | 3D model rotation speed multiplier |
| `mirror` | Bool | `false` | Whether to mirror the GIF horizontally |
| `hq` | Bool | `true` | Whether to use mipmap for higher quality GIF rendering |
| `allowcameradrag` | Bool | `true` | Whether dragging in 3D Mesh mode orbits the camera |
| `camposx`/`camposy`/`camposz` | Double | `10`/`8`/`5` | Persisted 3D camera orbit target (`cameraOrigin.position`) |
| `camrotx`/`camroty` | Double | `-20`/`0` | Persisted 3D camera orbit angle (`cameraOrigin.eulerRotation.x`/`.y`) |
| `camzoom` | Double | `33` | Persisted 3D camera distance (`camera.z`) |

## Building & Packaging

```bash
./build.sh
```

This creates `build/maxwell-<version>.tar.xz` containing `contents/` and `metadata.json`, ready for installation as a Plasma widget.

**Dependencies for build:** `jq`, `tar`

## Development Guidelines

- All UI code is written in **QML** following KDE Plasma applet conventions
- The main component extends `PlasmoidItem` with `Plasmoid.backgroundHints: NoBackground` for transparency
- Configuration is accessed via `plasmoid.configuration.<settingName>`
- **Display modes** are mutually exclusive – `AnimatedImage` (GIF) and `View3D` (3D Mesh) toggle `visible` based on `plasmoid.configuration.displaymode`
- **GIF mode** uses `AnimatedImage` with configurable speed (`gifspeed`), mirror, and mipmap options
- **3D Mesh mode** is loaded dynamically via a `Loader` component that loads `view3d.qml`. This isolates the `import QtQuick3D` statement so the widget still loads if QtQuick3D is unavailable.
  - `view3d.qml` contains a `View3D` with:
    - `SceneEnvironment` set to transparent background
    - A `Node` (`cameraOrigin`) holding the `PerspectiveCamera` as a child positioned along local Z, so the camera orbits around `cameraOrigin` rather than moving independently
    - `DirectionalLight` with ambient fill for illumination
    - **Two statically-declared, always-present mesh sources**, toggled via `visible` based on `usingCustomMesh` (`plasmoid.configuration.glbpath !== "assets/maxwell-spinning.glb"`), with `NumberAnimation` on whichever one's `eulerRotation.y` for continuous spinning:
      - `MaxwellMesh` (from `assets/mesh/`, brought in via `import "assets/mesh"` - a directory import, not a `Loader`) for the bundled default: the GLB pre-converted once at dev time via Qt's `balsam` tool (ships with `qt6-qtquick3d-devel`) into native Qt Quick 3D `Model`/`.mesh`/textures. No Assimp needed to load it at runtime - see `MEMORY_ANALYSIS.md`.
      - `CustomMeshLoader` (`contents/ui/CustomMeshLoader.qml`, a `RuntimeLoader` wrapper) for a user-supplied GLB (`plasmoid.configuration.glbpath`, set via `General.qml`'s "Path to 3D Mesh", same Browse/Reset pattern as `gifpath`). Gated by its own `active` property (`container.usingCustomMesh`): while inactive, `source` stays `""` so the Assimp plugin is never pulled into the process - it only loads lazily the moment `source` is actually set to a real file.
      - **Both are declared statically, never through a `Loader`.** `QQuick3DModel`/`RuntimeLoader` custom-geometry loading (`Model.source`/`RuntimeLoader.source` pointing at a `.mesh` or `.glb` file) silently produces zero-size geometry (`Model.bounds` stays `(0,0,0)`, nothing renders, no error signaled) when the `Model`/`RuntimeLoader` itself is the object a `Loader` dynamically instantiates - confirmed empirically, not documented anywhere obvious. A `Loader` picking between `MaxwellMesh`/`CustomMeshLoader` files (the original design) looks correct and loads without error, but never actually shows anything. Toggling `visible`/`active` on two statically-declared siblings instead sidesteps it entirely.
  - Mouse camera control is provided by `QtQuick3D.Helpers`' `OrbitCameraController`, bound to `cameraOrigin`/`camera`: drag to orbit, scroll to zoom (Ctrl+drag to pan). `allowcameradrag` only toggles `OrbitCameraController.mouseEnabled` — it no longer resets the pose
  - The camera pose (`cameraOrigin.position`/`eulerRotation`, `camera.z`) persists across sessions in `plasmoid.configuration` (`campos{x,y,z}`, `camrot{x,y}`, `camzoom`). `view3d.qml`'s `applyCameraFromConfig()` is the single source of truth: it runs once on load, and again via `Connections` on `plasmoid.configuration` whenever those entries change externally. It's applied imperatively rather than as a live QML binding, since `OrbitCameraController` mutates `cameraOrigin.position`/`eulerRotation` imperatively on every drag/pan, which would tear down a declarative binding on first use anyway
  - Writes the other direction (live pose → `plasmoid.configuration`) are debounced through a single `saveCameraTimer` (400ms): `OrbitCameraController`'s `FrameAnimation` reassigns the pose every frame while dragging, so writing straight to `plasmoid.configuration` on every change would spam KConfig for the whole drag; each change just restarts the timer, and only the value after the pose has settled gets persisted
  - The "Reset default position" button in `General.qml` writes each `cfg_camposx`/etc. (the KCM dialog's staged copy, so Cancel/Apply/OK bookkeeping for other pending edits stays correct) *and* the matching `Plasmoid.configuration.camposx`/etc. directly (`import org.kde.plasma.plasmoid`; `Plasmoid` is an attached property, so it resolves to the same live applet instance `view3d.qml` reads from, not a per-engine copy) — the second write is what makes the reset take effect immediately instead of waiting for Apply/OK, since normally `cfg_*` properties in a config page are only staged and don't touch the live config until Apply/OK
  - `General.qml` also keeps `cfg_camposx`/etc. mirrored live to `Plasmoid.configuration` the whole time the dialog is open (another `Connections` block, same six keys). This isn't optional: `AppletConfiguration.qml`'s `saveConfig()` unconditionally writes *every* `cfg_*` property back into the live config on Apply/OK, not just ones the user touched in this dialog — so without this sync, dragging the camera live while the dialog happened to be open, then applying some unrelated change (e.g. unchecking "Allow dragging the camera"), would silently revert the camera to wherever it was when the dialog was first opened
  - `view3d.qml` exposes a `hasError` property (`usingCustomMesh && customMesh.hasError`, i.e. only meaningful on the `RuntimeLoader` path - the bundled default mesh is assumed always present) to signal model loading failures back to the parent widget, and `clicked()`/`doubleClicked()` signals (from an internal `TapHandler`) so `MaxwellWidget.qml` can still toggle the theme song in 3D mode without a `MouseArea` stealing drag input from the orbit controller
  - **Error handling:** The widget distinguishes between two failure modes when 3D mode is selected:
    - **QtQuick3D missing:** The `Loader` fails with `Loader.Error` status. An error message is displayed informing the user to install `qt6-qtquick3d`.
    - **Assimp plugin missing:** Only relevant once a custom mesh is configured - the `Loader` loads successfully but `CustomMeshLoader`'s `RuntimeLoader` fails to load the GLB model (`hasError` is true). An error message is displayed informing the user to install the Assimp plugin. The bundled default mesh doesn't need Assimp at all, so this can't happen for users who haven't set a custom mesh.
  - When either error occurs, a `Rectangle` overlay is shown with descriptive error text (title + details) instead of displaying the GIF or 3D view.
- Sound is managed through QtMultimedia's `SoundEffect` component. The click/double-click `MouseArea` in `MaxwellWidget.qml` only handles GIF mode (`enabled`/`visible: !is3DMode`); in 3D mode it would otherwise grab drag events before the `OrbitCameraController` in `view3d.qml`, so clicks are instead delivered via the loaded item's `clicked()`/`doubleClicked()` signals
- Configuration UI uses property aliases bound to KCM settings, with conditional visibility (`displaymode.currentIndex`)
- File selection uses lazy-loaded `FileDialog` via `Loader` components
- New config options should be added to all three places:
  1. `contents/config/main.xml` (schema with default value)
  2. `contents/ui/config/General.qml` (UI control with property alias)
  3. `contents/ui/main.qml` (consume via `plasmoid.configuration.<name>`)

- **Git Conventions:**
  - Remote: `origin` → `git@github.com:wilversings/maxwell.git`
  - Commit messages should describe the feature or fix clearly
  - Tag releases to match `KPlugin.Version` in `metadata.json`
- **KDE Store:**
  - `KDESTOREPAGE.md` contains the KDE Store listing page content
  - Update this file when adding features or changing requirements
- **Documentation style:**
  - `README.md`, `KDESTOREPAGE.md`, and `CHANGELOG.md` should stay concise — don't over-explain, keep entries short
  - `README.md` and `KDESTOREPAGE.md` specifically should keep a light, witty tone (not `CHANGELOG.md`, which stays plain/factual)

## Testing

To run the unit tests provided in the `tests/` directory:
```bash
./tests/run_tests.sh
```
This requires `qmltestrunner-qt6` and standard Plasma testing dependencies. See `tests/README.md` for more details.

**Test Infrastructure:**
- `MockPlasmoid.qml` provides a simulated Plasmoid environment for isolated testing
- `mock/` directory contains mock implementations of Plasma modules (`org.kde.plasma.core`, `org.kde.plasma.plasmoid`)
- `org/` directory contains Plasma module shims that override imports during test execution
- Tests use the QML Test framework (`QtTest`) with `tst_main.qml` as the test entry point
