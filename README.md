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
        ├── main.qml          # Main widget (GIF + 3D modes)
        ├── maxwell-spinning.gif   # Default GIF animation
        ├── maxwell-spinning.glb   # Default 3D model
        ├── stockmarket.wav        # Default theme song
        └── config/
            └── General.qml  # Configuration dialog UI
```

## 🧱 Technology Stack

- **QML/QtQuick** — UI framework for Plasma applets
- **QtMultimedia** — Sound playback
- **QtQuick3D** — 3D scene rendering with GLB model support
- **KDE Frameworks** — Kirigami, Plasma Shell APIs, KCMUtils

## 🐛 Reporting Issues

Found a bug or have a feature request? Please open an issue on [GitHub](https://github.com/wilversings/maxwell/issues).
