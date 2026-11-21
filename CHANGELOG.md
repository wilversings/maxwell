# Changelog

## 2.3.0

### Added

- Movement "Type" setting: constant speed, or speed driven by CPU usage, GPU usage, fan speed or cursor proximity (smoothed, requires libksysguard)
- Automatic fan discovery, with an automatically learned (or manual) RPM range
- "Sample rate" setting for sensor-driven movement
- "By cursor proximity" movement type: spins faster the closer the cursor gets, with a configurable "Reach"

### Changed

- Settings split into General, Movement and Sound pages; existing settings carry over
- Settings pages keep a margin below the dialog header, scroll when they don't fit, and no longer shift sideways when switching movement type or display mode
- Settings pages no longer flicker into place when a section is first shown
- 3D Mesh rotation speed changes no longer make the model jump

### Fixed

- De-URLized custom paths (file:///home/x/a.gif to /home/x/a.gif)
- Fixed file picker filter

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