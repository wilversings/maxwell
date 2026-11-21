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
- **Customizable animations** — Swap in your own GIF file or 3D mesh (GLB).
- **Spins with your hardware** — Optionally let CPU usage, GPU usage or a fan's RPM set the pace: Maxwell naps when idle and goes feral while compiling (or gaming).
- **Notices you** — Or let the cursor set the pace: the closer you get, the more excited he spins.
- **Theme song playback** — Play the iconic Maxwell theme song (or any audio file) on click, double click, or disable it entirely.
- **Fully configurable** — Adjust animation speed, enable horizontal mirroring, control rendering quality, set theme song loop count, and more.

---

## ⚙️ Configuration

Right-click the Maxwell widget and select **Configure...** to access all settings, grouped into three pages:

| Page | Setting | Description |
|------|---------|-------------|
| **General** | **Display mode** | Switch between `GIF` and `3D Mesh` modes |
| | **Path to GIF** / **Path to 3D Mesh** | Browse and select a custom GIF or GLB model |
| | **Mirror** | Horizontally flip the GIF animation |
| | **High render quality** | Enable mipmap filtering for smoother GIF rendering |
| | **Allow dragging the camera** | Toggle mouse-drag camera orbiting in 3D Mesh mode. Your camera angle is remembered between sessions — use the **Reset default position** button next to it to snap back |
| **Movement** | **Type** | `Constant`, `By CPU usage`, `By GPU usage`, `By fan speed` or `By cursor proximity` — anything but constant goes from 0.6× when idle up to 10× flat out, smoothly eased |
| | **Fan** / **RPM range** | Which fan to follow (found automatically) and the RPM range mapped onto that speed range — learned automatically by default, or set by hand |
| | **Reach** | How far from the widget (in px) `By cursor proximity` starts noticing the cursor — it only sees it on the desktop or panel Maxwell lives on |
| | **Sample rate** | How often the sensor is read (500–10000 ms) |
| | **Speed** | Animation or rotation speed (0.6–10×) for `Constant` |
| **Sound** | **Play/Stop theme song** | Toggle sound on `Click`, `Double Click`, or `Never` |
| | **Theme song loops** | Set how many times the song repeats |
| | **Path to theme song** | Choose a custom audio file (WAV recommended) |

---

## ⚠️ Requirements

- **KDE Plasma 6.0** or later
- **QtQuick3D** & **Assimp asset import plugin**: Both are required if you want to use the **3D Mesh** display mode. Install them via your package manager:
  - **Arch Linux / Manjaro:** `qt6-3d` and `qt6-assimp`
  - **Fedora:** `qt6-qtquick3d` and `assimp`
  - **openSUSE:** `libqt6qtquick3d` and `libqt6qtquick3d-assets`
  - **Debian / Ubuntu:** `libqt6qtquick3d6` and `libqt6qtquick3d6-assets`
- **libksysguard**: Needed for the CPU, GPU and fan speed movement types. Ships with Plasma, so you most likely have it already.

---

## 🔗 Links

- **Source code:** [https://github.com/wilversings/maxwell](https://github.com/wilversings/maxwell)
- **Report issues:** [https://github.com/wilversings/maxwell/issues](https://github.com/wilversings/maxwell/issues)
