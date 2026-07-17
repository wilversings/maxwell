# Unit Tests for Maxwell Plasmoid

This directory contains unit tests for the Maxwell KDE Plasma widget.

## Prerequisites

To run these tests, you need a Plasma development environment with QML testing support:

`MaxwellWidget.qml` (loaded by every test) unconditionally imports `QtMultimedia`, so it's required even though the tests don't touch audio playback directly - without it, `Loader.item` stays `null` and every test fails at the `widgetLoader.active = true` step. `QtQuick3D` is needed to meaningfully exercise the 3D Mesh mode test path (`view3d.qml` degrades gracefully without it at runtime, and the test for it technically still passes either way since it only checks the `Loader.active` flag - but with `QtQuick3D` missing there's nothing real being verified). Assimp is **not** needed to run these tests: the mocked `glbpath` matches the bundled default mesh, which loads through the native (non-Assimp) path - see `MEMORY_ANALYSIS.md`. Assimp only matters for the "bring your own mesh" path, which isn't covered by this suite.

### Arch Linux / Manjaro
```bash
sudo pacman -S qt6-declarative qt6-quickcontrols2 qt6-multimedia qt6-quick3d plasma-workspace
```

### Fedora
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia qt6-qtquick3d plasma-workspace
```

### Ubuntu / Debian
```bash
sudo apt install qtbase5-dev qtdeclarative5-dev qml6-module-qtmultimedia qml6-module-qtquick3d plasma-workspace
```

The Fedora command above is confirmed working (Fedora 44). Arch/Ubuntu package names follow the same distro's Qt6 module naming convention but haven't been verified against a real install the way Fedora's was - if one of them is wrong, `qmltestrunner`'s `module "X" is not installed` warning will name the missing module.

## Running Tests

```bash
./run_tests.sh
```

Or manually:

```bash
qmltestrunner -input tst_main.qml
```

## Test Files

| File | Description |
|------|-------------|
| `tst_main.qml` | Main test module using QML Unit Test framework |
| `MockPlasmoid.qml` | Mock component that simulates the Plasma shell environment |
| `CMakeLists.txt` | CMake configuration for building and running tests |

## Writing New Tests

Tests use Qt's QML Unit Test framework. Each test function should:

1. Use `compare()` to verify expected values
2. Use `verify()` to check boolean conditions
3. Use `tryCompare()` for properties that update asynchronously

Example:
```qml
function testDisplayModeDefault() {
    compare(plasmoid.configuration.displaymode, "GIF")
}
```

## Mocking the Plasmoid Environment

The `MockPlasmoid.qml` component provides a simulated `plasmoid` object for testing outside the Plasma shell. It mimics the configuration API and other Plasmoid-specific properties.