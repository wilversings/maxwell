import QtQuick
import QtQuick3D
import QtQuick3D.AssetUtils
import QtQuick3D.Helpers

Item {
    id: container

    readonly property bool hasError: modelLoader.status === RuntimeLoader.Error

    // Exposed for tools/grab_screenshot.qml: the spin animation only
    // advances in real time when something is actually driving frame
    // rendering (a visible window), which an offscreen grabToImage() capture
    // never does - so the tool needs a way to pose the model deterministically
    // instead of waiting for the animation to reach some point in time.
    property alias modelSpinning: spinAnimation.running
    property alias modelEulerRotation: modelLoader.eulerRotation

    signal clicked()
    signal doubleClicked()

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: 'transparent'
            backgroundMode: SceneEnvironment.Transparent
        }

        Node {
            id: cameraOrigin
            readonly property vector3d defaultPosition: Qt.vector3d(10, 8, 5)
            readonly property vector3d defaultEulerRotation: Qt.vector3d(-20, 0, 0)

            position: defaultPosition
            eulerRotation: defaultEulerRotation

            PerspectiveCamera {
                id: camera
                readonly property real defaultZ: 33
                z: defaultZ
            }
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

    OrbitCameraController {
        anchors.fill: parent
        origin: cameraOrigin
        camera: camera
        mouseEnabled: plasmoid.configuration.allowcameradrag

        onMouseEnabledChanged: {
            if (!mouseEnabled) {
                cameraOrigin.position = cameraOrigin.defaultPosition
                cameraOrigin.eulerRotation = cameraOrigin.defaultEulerRotation
                camera.z = camera.defaultZ
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onSingleTapped: container.clicked()
        onDoubleTapped: container.doubleClicked()
    }
}
