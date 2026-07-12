# Unit Tests for Maxwell Plasmoid

This directory contains unit tests for the Maxwell KDE Plasma widget.

## Prerequisites

To run these tests, you need a Plasma development environment with QML testing support:

### Arch Linux / Manjaro
```bash
sudo pacman -S qt6-declarative qt6-quickcontrols2 plasma-workspace
```

### Fedora
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel plasma-workspace
```

### Ubuntu / Debian
```bash
sudo apt install qtbase5-dev qtdeclarative5-dev plasma-workspace
```

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