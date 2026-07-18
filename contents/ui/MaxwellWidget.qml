import QtQuick
import QtQuick.Layouts
import QtMultimedia

Item {
    id: widget

    implicitWidth: 100
    implicitHeight: 100

    // AudioOutput's `device` doesn't follow the system default on its own -
    // it's a plain property, only ever set once at creation. Binding it to
    // MediaDevices.defaultAudioOutput (which does update live) keeps the
    // theme song following Plasma's active playback device instead of
    // getting stuck on whatever device was default when it started playing.
    MediaDevices {
        id: mediaDevices
    }

    MediaPlayer {
        id: themeSong
        source: plasmoid.configuration.playthemesong != "Never" ? plasmoid.configuration.themepath : ""
        loops: plasmoid.configuration.themesongloops

        audioOutput: AudioOutput {
            device: mediaDevices.defaultAudioOutput
        }
    }

    // Check if 3D Mesh mode is active
    readonly property bool is3DMode: plasmoid.configuration.displaymode === "3D Mesh"

    // Error handling properties
    readonly property bool hasQtQuick3DError: is3DMode && view3DLoader.status === Loader.Error
    readonly property bool hasAssimpError: is3DMode && view3DLoader.item && view3DLoader.item.hasError
    readonly property bool is3DError: hasQtQuick3DError || hasAssimpError

    // Loader for 3D view - dynamically loads view3d.qml only when needed
    Loader {
        id: view3DLoader
        anchors.fill: parent
        source: is3DMode ? "view3d.qml" : ""
        active: is3DMode

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("QtQuick3D view failed to load")
            }
        }

        onLoaded: {
            item.clicked.connect(function() { toggleThemeSong("On Click") })
            item.doubleClicked.connect(function() { toggleThemeSong("On Double Click") })
        }
    }

    // AnimatedImage for GIF mode
    AnimatedImage {
        id: animation
        source: plasmoid.configuration.gifpath
        visible: !is3DMode

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent

        speed: plasmoid.configuration.gifspeed
        mirror: plasmoid.configuration.mirror
        mipmap: plasmoid.configuration.hq
    }

    // Error message when 3D mode fails to load
    Rectangle {
        anchors.centerIn: parent
        width: childrenRect.width + 20
        height: childrenRect.height + 20

        visible: is3DError
        color: "#ffffff"
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: hasQtQuick3DError ? "3D Engine Failed to Load" : "3D Model Failed to Load"
                font.bold: true
                font.pixelSize: 14
                color: "#000000"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: hasQtQuick3DError ? "The QtQuick3D library is missing.\n\nInstall qt6-qtquick3d for your distribution" : 
                                          "The Assimp asset import plugin may be missing or the model file is invalid.\n\nInstall the Assimp plugin for your distribution\n\nhttps://github.com/wilversings/maxwell"
                font.pixelSize: 11
                color: "#000000"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }

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

    // MouseArea for click/double-click interactions in GIF mode.
    // In 3D mode, clicks are handled by view3d.qml instead so this
    // doesn't steal drag events from the orbit camera controller.
    MouseArea {
        anchors.fill: parent
        visible: !is3DMode
        enabled: !is3DMode
        z: 1

        onClicked: toggleThemeSong("On Click")
        onDoubleClicked: toggleThemeSong("On Double Click")
    }
}
