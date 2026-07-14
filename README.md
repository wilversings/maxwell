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
- If `QtQuick3D` is **missing**: Selecting 3D Mesh mode will display an error message informing you to install the required library, rather than silently falling back to GIF mode.

GIF mode, sound playback, and all other features work regardless of `QtQuick3D` availability.

### Installing QtQuick3D

If you want to use 3D Mesh mode and don't have `QtQuick3D` installed already, install the module for your distribution:

**Fedora / Fedora KDE Spin:**
```bash
sudo dnf install qt6-qtquick3d
```

**openSUSE Tumbleweed / Leap:**
```bash
sudo zypper install libqt6qtquick3d
```

**Arch Linux / Manjaro:**
```bash
sudo pacman -S qt6-3d
```

**Debian / Ubuntu (with KDE backports):**
```bash
sudo apt install libqt6qtquick3d6
```

**Void Linux:**
```bash
sudo xbps-install qt6-qt3d
```

After installation, reload the Plasma shell (`kquitapp6 plasmashell && kstart12 plasmashell`) or log out and back in for the changes to take effect.

### Assimp Asset Import Plugin (Required for 3D Mesh Mode)

**3D Mesh mode also requires the Assimp asset import plugin** to load `.glb` models. Without this plugin, an error message will be displayed informing you to install the required plugin, even if `QtQuick3D` is installed. You may see an error like `Failed to load asset import plugin with key: "assimp"` in the debug logs.

On some distributions (notably **Arch Linux**), the QtQuick3D package does not include the asset import plugins by default. Install the Assimp plugin for your distribution:

**Arch Linux / Manjaro:**
```bash
sudo pacman -S qt6-assimp
```

**Fedora / Fedora KDE Spin:**
```bash
sudo dnf install qt6-qtquick3d-assets
```

**openSUSE Tumbleweed / Leap:**
```bash
sudo zypper install libqt6qtquick3d-assets
```

**Debian / Ubuntu:**
```bash
sudo apt install libqt6qtquick3d6-assets
```

After installation, reload the Plasma shell or log out and back in for the changes to take effect.

## 🛠️ Building

To package the widget for distribution:

```bash
./build.sh
```

This creates `build/maxwell-<version>.tar.xz` ready for installation.

**Build dependencies:** `jq`, `tar`

## 🧪 Testing

The project includes a suite of unit tests for the widget UI logic using the QML Test framework. To run the tests:

```bash
cd tests
./run_tests.sh
```

**Testing prerequisites:** `qmltestrunner-qt6` (from `qt6-declarative-devel` or equivalent). See `tests/README.md` for detailed instructions.

## 📂 Project Structure

```
.
├── build.sh                  # Packaging script
├── metadata.json             # Plasma plugin metadata
├── screenshot.png            # Preview image
├── contents/
│   ├── config/
│   │   ├── config.qml        # Config page registry
│   │   └── main.xml          # Configuration schema
│   └── ui/
│       ├── main.qml          # Entry point, delegates to MaxwellWidget
│       ├── MaxwellWidget.qml # Main widget logic (GIF/3D + sound)
│       ├── view3d.qml        # Isolated 3D scene (QtQuick3D import isolated here)
│       ├── assets/
│       │   ├── maxwell-spinning.gif   # Default GIF animation
│       │   ├── maxwell-spinning.glb   # Default 3D model
│       │   └── stockmarket.wav        # Default theme song
│       └── config/
│           └── General.qml   # Configuration dialog UI
└── tests/
    ├── run_tests.sh          # Test execution script
    └── tst_main.qml          # QML Unit tests
```

## 🧱 Technology Stack

- **QML/QtQuick** — UI framework for Plasma applets
- **QtMultimedia** — Sound playback
- **QtQuick3D** (optional) — 3D scene rendering with GLB model support. Required only for 3D Mesh display mode. If unavailable, an informative error message is displayed when 3D mode is selected.
- **KDE Frameworks** — Kirigami, Plasma Shell APIs, KCMUtils

## ⚠️ Known Issues

- **Adding the widget to the taskbar in 3D Mesh mode** requires a Plasmashell restart. After adding the widget to the taskbar while in 3D Mesh mode, either log out and back in, or run:
  ```bash
  plasmashell --replace
  ```
- **Adjusting the widget width in 3D Mesh mode** will not grow or shrink the 3D model. The model size remains fixed regardless of widget width adjustments.

## 🐛 Reporting Issues

Found a bug or have a feature request? Please open an issue on [GitHub](https://github.com/wilversings/maxwell/issues).
