import QtQuick
import QtQuick.Layouts
import QtMultimedia
import QtQuick3D // Required for rendering 3D scenes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import QtQuick.Controls
import QtQuick3D.AssetUtils

PlasmoidItem {
    id: widget

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    implicitWidth: 100
    implicitHeight: 100

    SoundEffect {
        id: themeSong
        source: plasmoid.configuration.playthemesong != "Never" ? plasmoid.configuration.themepath : ""
        loops: plasmoid.configuration.themesongloops
        muted: plasmoid.configuration.playthemesong == "Never"

        onMutedChanged: {
            if(muted) stop()
        }
    }

    View3D {
        id: view3D
        anchors.fill: parent
        visible: plasmoid.configuration.displaymode === "3D Mesh"

        environment: SceneEnvironment {
            clearColor: "transparent"
            backgroundMode: SceneEnvironment.Transparent
        }

        PerspectiveCamera {
            id: camera
            x: 10
            y: 17
            z: 37 // Move camera back to see the model (adjust based on model size)
            eulerRotation.x: -15
        }

        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
            
            // The main color of the directional light (e.g., sunlight)
            color: Qt.rgba(1.0, 1.0, 1.0, 1.0)
            
            // Ambient light is applied here to illuminate the shadows
            ambientColor: Qt.rgba(0.4, 0.4, 0.4, 1.0) 
        }

        RuntimeLoader {
            id: myModel
            
            source: "maxwell-spinning.glb"
            
            scale: Qt.vector3d(1, 1, 1)
            position: Qt.vector3d(10, 2, 5)

            NumberAnimation on eulerRotation.y {
                loops: Animation.Infinite
                from: 360
                to: 0
                duration: 10000 / plasmoid.configuration.glbspeed
                running: true
            }
        }

        MouseArea {
            anchors.fill: parent

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

    AnimatedImage {
        id: animation
        source: plasmoid.configuration.gifpath
        visible: plasmoid.configuration.displaymode === "GIF"

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent

        speed: plasmoid.configuration.gifspeed
        mirror: plasmoid.configuration.mirror
        mipmap: plasmoid.configuration.hq

        MouseArea {
            anchors.fill: parent

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
}