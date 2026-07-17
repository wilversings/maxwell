import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    property url textureData: "maps/textureData.jpg"
    property url textureData14: "maps/textureData14.png"
    Texture {
        id: _0_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData
    }
    Texture {
        id: _1_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData14
    }
    PrincipledMaterial {
        id: dingus_material
        objectName: "dingus"
        baseColorMap: _0_texture
        roughness: 0.8211145401000977
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }
    PrincipledMaterial {
        id: whiskers_material
        objectName: "whiskers"
        baseColorMap: _1_texture
        roughness: 0.8211145401000977
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Blend
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Node {
            id: node4208413c13314acba8c009c728471fae_fbx
            objectName: "4208413c13314acba8c009c728471fae.fbx"
            rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
            scale: Qt.vector3d(0.01, 0.01, 0.01)
            Node {
                id: rootNode
                objectName: "RootNode"
                Node {
                    id: dingus
                    objectName: "dingus"
                    rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
                    scale: Qt.vector3d(100, 100, 100)
                    Model {
                        id: dingus_dingus_0
                        objectName: "dingus_dingus_0"
                        source: "meshes/dingus_dingus_0_mesh.mesh"
                        materials: [
                            dingus_material
                        ]
                    }
                    Model {
                        id: dingus_whiskers_0
                        objectName: "dingus_whiskers_0"
                        source: "meshes/dingus_whiskers_0_mesh.mesh"
                        materials: [
                            whiskers_material
                        ]
                    }
                }
            }
        }
    }

    // Animations:
}
