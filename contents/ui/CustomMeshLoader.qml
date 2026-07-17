import QtQuick3D
import QtQuick3D.AssetUtils

// Handles user-supplied "bring your own mesh" files (General.qml's "Path
// to 3D Mesh" setting) via RuntimeLoader, which needs the Assimp plugin to
// parse an arbitrary GLB at runtime - there's no way to pre-convert a file
// the user might pick at any time the way the bundled default mesh is
// pre-converted offline (see assets/mesh/MaxwellMesh.qml, generated via
// balsam - AGENTS.md).
//
// This is declared as a static, always-present sibling of the default mesh
// in view3d.qml (NOT instantiated through a Loader) - QQuick3DModel/
// RuntimeLoader's custom-geometry loading silently fails to produce any
// geometry when the Model/RuntimeLoader itself is the object a Loader
// dynamically instantiates, even given a correct absolute source URL. Kept
// statically present but inert (`active: false`, `source: ""`) instead:
// the Assimp plugin is only pulled into the process the moment `source` is
// actually set to a real file (confirmed empirically - a statically
// declared RuntimeLoader with an empty source never maps libassimp.so into
// the process), so default-mesh users still never pay Assimp's ~37MB RSS
// cost even though this type is always instantiated. See
// MEMORY_ANALYSIS.md.
RuntimeLoader {
    id: root
    property bool active: false
    readonly property bool hasError: active && status === RuntimeLoader.Error
    source: active ? plasmoid.configuration.glbpath : ""
    position: Qt.vector3d(10, 2, 5)
    scale: Qt.vector3d(1, 1, 1)
}
