import QtQuick

// Bare Qt Quick runtime baseline (no Maxwell content at all) for
// measure_memory.sh - lets the RSS/VRAM numbers for gif/3d/3d-custom modes
// be attributed to the widget itself rather than qml-qt6/Qt Quick's own
// fixed overhead. See MEMORY_ANALYSIS.md.
Item {
    id: root
    width: 400
    height: 400
    visible: true
    Rectangle { anchors.fill: parent; color: "gray" }

    property int dwellMs: Qt.application.arguments.length > 2 ? parseInt(Qt.application.arguments[2]) : 8000

    Timer {
        interval: root.dwellMs
        running: true
        onTriggered: Qt.exit(0)
    }
}
