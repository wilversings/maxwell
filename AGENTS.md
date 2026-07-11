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
- **QtQuick3D** – 3D scene rendering (camera, lighting, `RuntimeLoader` for GLB models)
- **KDE Frameworks (Kirigami, Plasma Shell APIs, KCMUtils)** – Plugin integration & configuration UI
- **build.sh** – Shell script for packaging (uses `jq`, `tar`)

## Project Structure

```
.
├── build.sh                  # Packaging script (creates .tar.xz)
├── metadata.json             # Plasma plugin metadata (ID, version, author, etc.)
├── README.md                 # User-facing documentation
├── screenshot.png            # Preview image
├── .gitignore
└── contents/
    ├── config/
    │   ├── config.qml        # Config page model (registers "General" category)
    │   └── main.xml          # Configuration schema (defines user-settable options)
    └── ui/
        ├── main.qml          # Main widget UI (GIF mode + 3D Mesh mode + SoundEffect)
        ├── maxwell-spinning.gif   # Default animated GIF
        ├── maxwell-spinning.glb   # Default 3D model (GLB format)
        ├── stockmarket.wav        # Default theme song
        └── config/
            └── General.qml  # Configuration dialog UI
```

## Key Files

| File | Purpose |
|------|---------|
| `metadata.json` | Plugin identity, versioning, author info, and Plasma API requirements |
| `contents/ui/main.qml` | Main widget: switches between GIF (`AnimatedImage`) and 3D Mesh (`View3D` + `RuntimeLoader`) modes, handles click/double-click to play sound |
| `contents/config/main.xml` | Defines all configurable settings (display mode, paths, speeds, loops, mirror, quality) |
| `contents/config/config.qml` | Registers config pages with Plasma's settings dialog |
| `contents/ui/config/General.qml` | UI for the configuration dialog (conditionals per display mode, file browsers, sliders) |
| `build.sh` | Packages the widget into a `.tar.xz` archive for distribution |

## Configuration Options

The widget exposes the following user-configurable settings (defined in `contents/config/main.xml`):

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `displaymode` | String | `GIF` | Display mode: `"GIF"` or `"3D Mesh"` |
| `gifpath` | Path | `maxwell-spinning.gif` | Path to the animated GIF to display |
| `themepath` | Path | `stockmarket.wav` | Path to the theme song audio file |
| `playthemesong` | String | `On Double Click` | When to play theme song (`Never`, `On Click`, `On Double Click`) |
| `themesongloops` | Int | `1` | Number of times to loop the theme song |
| `gifspeed` | Double | `1` | GIF animation playback speed multiplier |
| `glbspeed` | Double | `2` | 3D model rotation speed multiplier |
| `mirror` | Bool | `false` | Whether to mirror the GIF horizontally |
| `hq` | Bool | `true` | Whether to use mipmap for higher quality GIF rendering |

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
    - `PerspectiveCamera` for viewpoint
    - `DirectionalLight` with ambient fill for illumination
    - `RuntimeLoader` to load the GLB model, with `NumberAnimation` on `eulerRotation.y` for continuous spinning
  - If QtQuick3D is missing, the `Loader` fails silently and the widget falls back to GIF mode without crashing.
- Sound is managed through QtMultimedia's `SoundEffect` component (shared across both modes)
- Configuration UI uses property aliases bound to KCM settings, with conditional visibility (`displaymode.currentIndex`)
- File selection uses lazy-loaded `FileDialog` via `Loader` components
- New config options should be added to all three places:
  1. `contents/config/main.xml` (schema with default value)
  2. `contents/ui/config/General.qml` (UI control with property alias)
  3. `contents/ui/main.qml` (consume via `plasmoid.configuration.<name>`)
- Version bumps should be made in `metadata.json` under `KPlugin.Version`

## Testing

To test the widget locally, install it into Plasma:

```bash
plasma-applywidgetfiles .
# Or copy to ~/.local/share/plasma/plasmoids/maxwell/
```

Then right-click the Plasma desktop → Add Widgets → search for "Maxwell".

## Git Conventions

- Remote: `origin` → `git@github.com:wilversings/maxwell.git`
- Commit messages should describe the feature or fix clearly
- Tag releases to match `KPlugin.Version` in `metadata.json`