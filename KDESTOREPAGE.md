# Maxwell — The Desktop Cat

**Maxwell the carryable cat**, now living on your KDE Plasma desktop.

Bring a touch of charm to your workspace with Maxwell, a configurable desktop widget featuring the iconic internet cat. Watch him spin, play his theme song, and brighten your day — right on your Plasma desktop.

---

## ✨ Features

- **Two display modes** — Choose between a classic animated GIF or a smooth 3D mesh rendering (GLB)
- **Customizable animations** — Swap in your own GIF file
- **Theme song playback** — Play the iconic Maxwell theme song (or any audio file) on click, double click, or disable it entirely
- **Fully configurable** — Adjust animation speed, enable horizontal mirroring, control rendering quality, set theme song loop count, and more

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
- **QtQuick3D** (optional) — Required for 3D Mesh display mode. If unavailable, an informative error message is displayed instead of silently falling back to GIF mode.
- **Assimp asset import plugin** (required for 3D Mesh mode) — Needed to load `.glb` 3D models. On some distributions (notably Arch Linux), this is not installed by default alongside QtQuick3D. Without it, an error message will guide you to install the missing plugin. Install it via your package manager (e.g., `qt6-assimp` on Arch Linux, `qt6-qtquick3d-assets` on Fedora).

---

## 🔗 Links

- **Source code:** [https://github.com/wilversings/maxwell](https://github.com/wilversings/maxwell)
- **Report issues:** [https://github.com/wilversings/maxwell/issues](https://github.com/wilversings/maxwell/issues)

---