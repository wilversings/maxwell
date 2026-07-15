# Maxwell — The Desktop Cat

**Maxwell the carryable cat**, now living on your KDE Plasma desktop.

Bring a touch of charm to your workspace with Maxwell, a configurable desktop widget featuring the iconic internet cat. Watch him spin, play his theme song, and brighten your day — right on your Plasma desktop.

---

## 🚀 Installation

Right-click on your Plasma desktop → **Add Widgets** → search for **Maxwell** → **Install**

---

## ✨ Features

- **Two display modes** — Choose between a classic animated GIF or a smooth 3D mesh rendering (GLB).
- **Mouse-controlled camera** — In 3D Mesh mode, drag to orbit the camera around Maxwell and scroll to zoom.
- **Customizable animations** — Swap in your own GIF file.
- **Theme song playback** — Play the iconic Maxwell theme song (or any audio file) on click, double click, or disable it entirely.
- **Fully configurable** — Adjust animation speed, enable horizontal mirroring, control rendering quality, set theme song loop count, and more.

---

## ⚙️ Configuration

Right-click the Maxwell widget and select **Configure...** to access all settings:

| Setting | Description |
|---------|-------------|
| **Display mode** | Switch between `GIF` and `3D Mesh` modes |
| **Path to GIF** | Browse and select a custom GIF |
| **Theme song path** | Choose a custom audio file (WAV recommended) |
| **Play/Stop theme song** | Toggle sound on `Click`, `Double Click`, or `Never` |
| **Theme song loops** | Set how many times the song repeats |
| **Speed** | Adjust animation or rotation speed (0.6–10×) |
| **Mirror** | Horizontally flip the GIF animation |
| **High render quality** | Enable mipmap filtering for smoother GIF rendering |

---

## ⚠️ Requirements

- **KDE Plasma 6.0** or later
- **QtQuick3D** & **Assimp asset import plugin**: Both are required if you want to use the **3D Mesh** display mode. Install them via your package manager:
  - **Arch Linux / Manjaro:** `qt6-3d` and `qt6-assimp`
  - **Fedora:** `qt6-qtquick3d` and `qt6-qtquick3d-assets`
  - **openSUSE:** `libqt6qtquick3d` and `libqt6qtquick3d-assets`
  - **Debian / Ubuntu:** `libqt6qtquick3d6` and `libqt6qtquick3d6-assets`

---

## 🔗 Links

- **Source code:** [https://github.com/wilversings/maxwell](https://github.com/wilversings/maxwell)
- **Report issues:** [https://github.com/wilversings/maxwell/issues](https://github.com/wilversings/maxwell/issues)
