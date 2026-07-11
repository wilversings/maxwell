# 🐱 Maxwell — The Desktop Cat

> **Maxwell the carryable cat**, now living on your KDE Plasma desktop.

[![Plasma API](https://img.shields.io/badge/Plasma%20API-6.0+-blue)](https://kde.org)

![Maxwell Screenshot](./screenshot.png)

## ✨ Features

- **Two display modes** — Choose between a classic animated GIF or a smooth 3D mesh rendering
- **Customizable animation** — Swap in your own GIF and adjust playback speed
- **Theme song** — Play the iconic Maxwell theme song (or any audio file) on click or double click
- **Fully configurable** — Adjust speed, enable mirroring, control rendering quality, and more

## 🚀 Installation

The easiest way to install Maxwell is via the [KDE Store](https://store.kde.org/p/2274580):

Right-click on your Plasma desktop → **Add Widgets** → search for **Maxwell** → **Install**

## ⚙️ Configuration

Right-click the Maxwell widget and select **Configure...** to access all settings:

| Setting | Description |
|---------|-------------|
| **Display mode** | Switch between `GIF` and `3D Mesh` modes |
| **GIF / Model path** | Browse and select a custom animation file |
| **Theme song path** | Choose a custom audio file (WAV recommended) |
| **Play/Stop theme song** | Toggle sound on `Click`, `Double Click`, or `Never` |
| **Theme song loops** | Set how many times the song repeats |
| **Speed** | Adjust animation or rotation speed (0.6–10×) |
| **Mirror** | Horizontally flip the GIF animation |
| **High render quality** | Enable mipmap filtering for smoother GIF rendering |

## ⚠️ QtQuick3D (Optional)

**3D Mesh mode requires the `QtQuick3D` module.** This module is included in Plasma 6.0+ but may be absent on some installations (e.g., minimal or container-based environments).

- If `QtQuick3D` is **available**: Both GIF and 3D Mesh modes work normally.
- If `QtQuick3D` is **missing**: The widget will load and operate in GIF mode. Selecting 3D Mesh mode will fall back to GIF mode without crashing. The 3D option remains visible in configuration but will not display a 3D scene.

GIF mode, sound playback, and all other features work regardless of `QtQuick3D` availability.

## 🛠️ Building

To package the widget for distribution:

```bash
./build.sh
```

This creates `build/maxwell-<version>.tar.xz` ready for installation.

**Build dependencies:** `jq`, `tar`

## 📂 Project Structure

```
.
├── build.sh                  # Packaging script
├── metadata.json             # Plasma plugin metadata
├── screenshot.png            # Preview image
└── contents/
    ├── config/
    │   ├── config.qml        # Config page registry
    │   └── main.xml          # Configuration schema
    └── ui/
        ├── main.qml          # Main widget (GIF mode + SoundEffect + Loader for 3D)
        ├── view3d.qml        # Isolated 3D scene (QtQuick3D import isolated here)
        ├── maxwell-spinning.gif   # Default GIF animation
        ├── maxwell-spinning.glb   # Default 3D model
        ├── stockmarket.wav        # Default theme song
        └── config/
            └── General.qml  # Configuration dialog UI
```

## 🧱 Technology Stack

- **QML/QtQuick** — UI framework for Plasma applets
- **QtMultimedia** — Sound playback
- **QtQuick3D** (optional) — 3D scene rendering with GLB model support. Required only for 3D Mesh display mode. Widget gracefully falls back to GIF mode if unavailable.
- **KDE Frameworks** — Kirigami, Plasma Shell APIs, KCMUtils

## 🐛 Reporting Issues

Found a bug or have a feature request? Please open an issue on [GitHub](https://github.com/wilversings/maxwell/issues).
