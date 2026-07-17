import QtQuick

// Drives MaxwellWidget.qml in a real visible window (so 3D content actually
// renders through the GPU, not an offscreen/software path) for memory/GPU
// measurement. Paired with measure_memory.sh, which launches this as its
// own child process and samples RSS (/proc/<pid>/status) and AMD GPU VRAM/
// GTT usage (/proc/<pid>/fdinfo, drm-memory-* keys) while it runs. See
// MEMORY_ANALYSIS.md for methodology and results.
//
// Usage: qml-qt6 measure_memory.qml <mode> [cycles] [dwellMs]
//   mode:
//     gif        - steady-state GIF mode only, exits after one dwell
//     3d         - steady-state 3D mode, bundled default mesh (no Assimp)
//     3d-custom  - steady-state 3D mode, custom mesh path (RuntimeLoader + Assimp)
//     cycle      - alternates GIF -> 3D (default mesh) -> GIF -> ... `cycles` times,
//                  to check whether memory/GPU usage returns to baseline on
//                  every switch (leak detection)
//   cycles: number of mode switches for "cycle" mode (default 6)
//   dwellMs: time to stay in each mode/phase before switching or exiting (default 8000)
Item {
    id: root
    width: 400
    height: 400
    visible: true

    property string runMode: Qt.application.arguments.length > 2 ? Qt.application.arguments[2] : "cycle"
    property int totalCycles: Qt.application.arguments.length > 3 ? parseInt(Qt.application.arguments[3]) : 6
    property int dwellMs: Qt.application.arguments.length > 4 ? parseInt(Qt.application.arguments[4]) : 8000

    property int cycleCount: 0

    // gifpath/glbpath/themepath are consumed as `url` properties inside
    // files that live in contents/ui/ (MaxwellWidget.qml, view3d.qml,
    // CustomMeshLoader.qml), so relative values here must resolve against
    // THAT directory, not this script's own (tools/) - matches
    // contents/config/main.xml's defaults exactly. glbpath in particular
    // must be the literal default string for "3d" mode: view3d.qml
    // string-compares against it to decide whether to load the bundled
    // mesh (no Assimp) or treat it as a custom one (RuntimeLoader +
    // Assimp) - "3d-custom" mode deliberately uses an absolute path
    // instead, pointing at the same file but not string-equal to the
    // default, to force the custom-mesh path for comparison.
    property var mockRepoRoot: Qt.resolvedUrl("..")
    property var plasmoid: QtObject {
        id: mockPlasmoid
        property var configuration: QtObject {
            property string displaymode: root.runMode === "gif" ? "GIF" : "3D Mesh"
            property string gifpath: "assets/maxwell-spinning.gif"
            property string glbpath: root.runMode === "3d-custom"
                ? (root.mockRepoRoot + "/contents/ui/assets/maxwell-spinning.glb")
                : "assets/maxwell-spinning.glb"
            property string themepath: "assets/stockmarket.wav"
            property string playthemesong: "Never"
            property int themesongloops: 1
            property double gifspeed: 1.0
            property double glbspeed: 2.0
            property bool mirror: false
            property bool hq: true
            property bool allowcameradrag: true
            property double camposx: 10
            property double camposy: 8
            property double camposz: 5
            property double camrotx: -20
            property double camroty: 0
            property double camzoom: 33
        }
    }

    Loader {
        id: widgetLoader
        anchors.fill: parent
        source: "../contents/ui/MaxwellWidget.qml"
    }

    Timer {
        id: dwellTimer
        interval: root.dwellMs
        repeat: false
        onTriggered: root.advance()
    }

    function advance() {
        if (root.runMode !== "cycle") {
            // Steady-state single-mode run: exit after one dwell period.
            Qt.exit(0)
            return
        }

        root.cycleCount++
        if (root.cycleCount > root.totalCycles) {
            Qt.exit(0)
            return
        }

        mockPlasmoid.configuration.displaymode = (mockPlasmoid.configuration.displaymode === "GIF") ? "3D Mesh" : "GIF"
        dwellTimer.restart()
    }

    Component.onCompleted: dwellTimer.start()
}
