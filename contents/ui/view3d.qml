import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import QtQuick3D.Helpers

Item {
    id: container

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: 'transparent'
            backgroundMode: SceneEnvironment.Transparent
        }

        PerspectiveCamera {
            id: camera
            x: 10
            y: 20
            z: 37
            eulerRotation.x: -20
        }

        DirectionalLight {
            id: light
            eulerRotation.x: -40
            eulerRotation.y: -30
            color: Qt.rgba(1.0, 1.0, 1.0, 1.0)
            ambientColor: Qt.rgba(0.4, 0.4, 0.4, 1.0)
        }

        RuntimeLoader {
            id: modelLoader
            source: 'assets/maxwell-spinning.glb'
            scale: Qt.vector3d(1, 1, 1)
            position: Qt.vector3d(10, 2, 5)

            NumberAnimation {
                id: spinAnimation
                target: modelLoader
                property: "eulerRotation.y"
                from: 360
                to: 0
                duration: 15000 / plasmoid.configuration.glbspeed
                loops: Animation.Infinite
                running: true
            }
        }
    }
}