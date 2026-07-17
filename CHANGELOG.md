# Changelog

## 2.2.0

### Added

- Mouse-drag camera orbiting in 3D Mesh mode (drag to orbit, Ctrl+drag to pan)
- "Allow dragging the camera" setting
- "Reset default position" button
- Camera pose now persists across sessions
- Custom widget icon
- `tools/grab_screenshot.qml`

### Changed

- Disabled scroll-wheel/touchpad zoom in 3D Mesh mode
- Unchecking "Allow dragging the camera" no longer resets camera position
- Recentered the 3D camera's default framing
- Debounced camera pose writes to preferences

### Fixed

- Config dialog no longer reverts in-progress camera drags when applying unrelated changes
