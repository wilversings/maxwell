# Changelog

## 2.2.0

### Added

- Theme song can now be triggered via DBus (see `tools/dbus_control.sh`), independent of the "Play theme song" click setting; the same script can also change any other widget setting live and target a specific instance
- Mouse-drag camera orbiting in 3D Mesh mode (drag to orbit, Ctrl+drag to pan)
- "Allow dragging the camera" setting
- "Reset default position" button
- Custom widget icon
- Bring your own 3D mesh (GLB) via "Path to 3D Mesh" setting

### Changed

- Unchecking "Allow dragging the camera" no longer resets camera position
- Recentered the 3D camera's default framing

### Fixed

- Theme song no longer gets stuck on the old audio device after switching playback device in Plasma