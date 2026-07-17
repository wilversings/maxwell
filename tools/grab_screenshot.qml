import QtQuick

// Renders view3d.qml (3D Mesh mode) offscreen and saves it as a transparent
// PNG - useful for KDE Store listing screenshots, README images, etc.
// Adapted from contriburg's tools/grab_screenshot.qml.
//
// Unlike contriburg's Scene3D.qml, view3d.qml reads
// plasmoid.configuration.glbspeed/allowcameradrag directly, so this script
// provides a minimal mock 'plasmoid' context property - the same one
// tests/tst_main.qml uses - rather than a live Plasmoid/panel or
// plasmoidviewer.
//
// It also can't grab on the next tick the way contriburg's tool does:
// Scene3D.qml's geometry is parametric and ready immediately, but here the
// GLB model loads asynchronously via RuntimeLoader/Assimp, so this script
// still waits before grabbing (see the Timer below) - but that wait is only
// for the model to finish loading, not for a specific pose: the spin
// NumberAnimation is paused and the model posed directly (modelEulerRotation)
// for a deterministic shot instead.
//
// Unlike contriburg's 2D Scene3D.qml content, view3d.qml's 3D content
// (View3D) renders through QtQuick3D's own internal render pass, which only
// gets synced to a property change once the window has actually been shown
// and the render loop has run at least one real frame - a plain, never-shown
// Item (visible: false, contriburg's approach) grabs whatever the 3D scene's
// texture happened to be at its very first sync and never updates it, no
// matter what properties get changed afterwards. So this stays `visible:
// true`, unlike contriburg's tool.
Item {
    id: root
    // Qt.application.arguments is [executable, this script's path, ...args],
    // so user-supplied args start at index 2. Usage:
    //   qml-qt6 grab_screenshot.qml [outputPath] [width] [height] [rotationY]
    width: Qt.application.arguments.length > 3 ? parseInt(Qt.application.arguments[3]) : 500
    height: Qt.application.arguments.length > 4 ? parseInt(Qt.application.arguments[4]) : 500
    visible: true

    property string outputPath: Qt.application.arguments.length > 2 ? Qt.application.arguments[2] : "maxwell-3d.png"
    property real rotationY: Qt.application.arguments.length > 5 ? parseFloat(Qt.application.arguments[5]) : 45

    property var plasmoid: QtObject {
        property var configuration: QtObject {
            property double glbspeed: 2.0
            property bool allowcameradrag: true
            // Resolved relative to view3d.qml's own location (contents/ui/),
            // not this script's - matches main.xml's kcfg default verbatim.
            property string glbpath: "assets/maxwell-spinning.glb"
            property double camposx: 10
            property double camposy: 8
            property double camposz: 5
            property double camrotx: -20
            property double camroty: 0
            property double camzoom: 33
        }
    }

    Loader {
        id: scene
        anchors.fill: parent
        source: "../contents/ui/view3d.qml"
    }

    Component.onCompleted: {
        if (scene.status !== Loader.Ready) {
            console.log("ERROR: failed to load view3d.qml (status " + scene.status + ") - is QtQuick3D installed?")
            Qt.exit(1)
        }
    }

    // The GLB model loads asynchronously via RuntimeLoader/Assimp, so this
    // waits for that to finish before posing the model and grabbing.
    Timer {
        interval: 800
        running: true
        onTriggered: {
            if (scene.item && scene.item.hasError) {
                console.log("ERROR: GLB model failed to load - is the Assimp asset import plugin installed?")
                Qt.exit(1)
                return
            }
            scene.item.modelSpinning = false
            scene.item.modelEulerRotation = Qt.vector3d(0, root.rotationY, 0)
            root.grabToImage(function(result) {
                if (!result.saveToFile(root.outputPath)) {
                    console.log("ERROR: failed to save " + root.outputPath)
                    Qt.exit(1)
                    return
                }
                console.log("Saved " + root.outputPath)
                Qt.exit(0)
            })
        }
    }
}
