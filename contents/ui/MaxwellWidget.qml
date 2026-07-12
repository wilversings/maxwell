import QtQuick
import QtQuick.Layouts
import QtMultimedia

Item {
    id: widget

    implicitWidth: 100
    implicitHeight: 100

    MediaPlayer {
        id: themeSong
        source: plasmoid.configuration.playthemesong != "Never" ? plasmoid.configuration.themepath : ""
        loops: plasmoid.configuration.themesongloops

        audioOutput: AudioOutput {}
    }

    // Check if 3D Mesh mode is active
    readonly property bool is3DMode: plasmoid.configuration.displaymode === "3D Mesh"

    // Loader for 3D view - dynamically loads view3d.qml only when needed
    // If QtQuick3D is missing, the Loader will fail gracefully and GIF mode is used
    Loader {
        id: view3DLoader
        anchors.fill: parent
        source: is3DMode ? "view3d.qml" : ""
        active: is3DMode

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("QtQuick3D view failed to load - falling back to GIF mode")
            }
        }
    }

    // AnimatedImage for GIF mode (also serves as fallback if 3D fails)
    AnimatedImage {
        id: animation
        source: plasmoid.configuration.gifpath
        visible: !is3DMode || view3DLoader.status === Loader.Error

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent

        speed: plasmoid.configuration.gifspeed
        mirror: plasmoid.configuration.mirror
        mipmap: plasmoid.configuration.hq
    }

    // MouseArea for interactions (shared across both modes)
    MouseArea {
        anchors.fill: parent
        visible: true
        z: 1

        function toggleThemeSong(config) {
            if (plasmoid.configuration.playthemesong != config) {
                return
            }

            if (themeSong.playing) {
                themeSong.stop()
            }
            else {
                themeSong.play()
            }
        }

        onClicked: toggleThemeSong("On Click")
        onDoubleClicked: toggleThemeSong("On Double Click")
    }
}
