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

    // Camera pose (position/rotation/zoom) persists across sessions via
    // plasmoid.configuration, and is the single source of truth for both
    // the initial pose and the "Reset default position" button in
    // General.qml (which just writes the kcfg defaults back into these same
    // entries). Applied imperatively rather than via a live binding because
    // OrbitCameraController drags/pans by imperatively assigning
    // cameraOrigin.position/eulerRotation, which would tear down a
    // declarative binding on first use anyway.
    function applyCameraFromConfig() {
        cameraOrigin.position = Qt.vector3d(
            plasmoid.configuration.camposx,
            plasmoid.configuration.camposy,
            plasmoid.configuration.camposz
        )
        cameraOrigin.eulerRotation = Qt.vector3d(
            plasmoid.configuration.camrotx,
            plasmoid.configuration.camroty,
            0
        )
        camera.z = plasmoid.configuration.camzoom
    }

    Component.onCompleted: applyCameraFromConfig()

    // Reapplies whenever campos*/camrot*/camzoom change from outside this
    // item - i.e. the config dialog's "Reset default position" button.
    // Re-setting values that already match (e.g. our own debounced writes
    // below round-tripping through config) is a no-op, so this can't loop.
    Connections {
        target: plasmoid.configuration
        function onCamposxChanged() { applyCameraFromConfig() }
        function onCamposyChanged() { applyCameraFromConfig() }
        function onCamposzChanged() { applyCameraFromConfig() }
        function onCamrotxChanged() { applyCameraFromConfig() }
        function onCamrotyChanged() { applyCameraFromConfig() }
        function onCamzoomChanged() { applyCameraFromConfig() }
    }

    // OrbitCameraController's FrameAnimation reassigns cameraOrigin's
    // position/eulerRotation (and camera.z) every frame while dragging, so
    // writing straight to plasmoid.configuration on every change would spam
    // KConfig with writes for the whole drag. Debounce: each change just
    // restarts this timer, and only the value after a drag has settled
    // (interval ms of no further change) actually gets persisted.
    Timer {
        id: saveCameraTimer
        interval: 400
        onTriggered: {
            plasmoid.configuration.camposx = cameraOrigin.position.x
            plasmoid.configuration.camposy = cameraOrigin.position.y
            plasmoid.configuration.camposz = cameraOrigin.position.z
            plasmoid.configuration.camrotx = cameraOrigin.eulerRotation.x
            plasmoid.configuration.camroty = cameraOrigin.eulerRotation.y
            plasmoid.configuration.camzoom = camera.z
        }
    }

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: 'transparent'
            backgroundMode: SceneEnvironment.Transparent
        }

        Node {
            id: cameraOrigin

            onPositionChanged: saveCameraTimer.restart()
            onEulerRotationChanged: saveCameraTimer.restart()

            PerspectiveCamera {
                id: camera
                onZChanged: saveCameraTimer.restart()
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
            source: plasmoid.configuration.glbpath
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

    // Unchecking "Allow dragging the camera" only stops further dragging -
    // it leaves the current pose alone (persisted, see applyCameraFromConfig
    // above). Resetting to the default pose is a separate, explicit action:
    // the "Reset default position" button in General.qml.
    OrbitCameraController {
        anchors.fill: parent
        origin: cameraOrigin
        camera: camera
        mouseEnabled: plasmoid.configuration.allowcameradrag
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onSingleTapped: container.clicked()
        onDoubleTapped: container.doubleClicked()
    }
}
