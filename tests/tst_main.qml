import QtQuick
import QtTest

Item {
    id: root
    width: 400
    height: 400

    // Mock the 'plasmoid' context property expected by main.qml
    property var plasmoid: QtObject {
        id: mockPlasmoid
        property var configuration: QtObject {
            property string displaymode: "GIF"
            property string gifpath: "../contents/ui/assets/maxwell-spinning.gif"
            // Must match main.xml's literal kcfg default exactly - view3d.qml
            // compares against this string to decide whether to load the
            // bundled default mesh (no Assimp needed) or treat it as a
            // custom mesh (RuntimeLoader + Assimp). See MEMORY_ANALYSIS.md.
            property string glbpath: "assets/maxwell-spinning.glb"
            property string themepath: "../contents/ui/assets/stockmarket.wav"
            property string playthemesong: "On Double Click"
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
        source: "../contents/ui/MaxwellWidget.qml"
        active: false
    }

    TestCase {
        name: "MaxwellWidgetTests"
        when: windowShown

        function init() {
            // Reset config to defaults before each test
            mockPlasmoid.configuration.displaymode = "GIF"
            mockPlasmoid.configuration.playthemesong = "On Double Click"
            mockPlasmoid.configuration.themesongloops = 1
            mockPlasmoid.configuration.gifspeed = 1.0
            mockPlasmoid.configuration.glbspeed = 2.0
            mockPlasmoid.configuration.mirror = false
            mockPlasmoid.configuration.hq = true
            mockPlasmoid.configuration.allowcameradrag = true
            mockPlasmoid.configuration.camposx = 10
            mockPlasmoid.configuration.camposy = 8
            mockPlasmoid.configuration.camposz = 5
            mockPlasmoid.configuration.camrotx = -20
            mockPlasmoid.configuration.camroty = 0
            mockPlasmoid.configuration.camzoom = 33

            widgetLoader.active = true
            verify(widgetLoader.item !== null, "Widget should load successfully")
            wait(50) // Wait for initial bindings to evaluate
        }

        function cleanup() {
            widgetLoader.active = false
        }

        function test_is3DModeProperty() {
            compare(widgetLoader.item.is3DMode, false, "is3DMode should be false for GIF")
            
            mockPlasmoid.configuration.displaymode = "3D Mesh"
            compare(widgetLoader.item.is3DMode, true, "is3DMode should be true for 3D Mesh")
        }

        function test_gifModeVisibility() {
            mockPlasmoid.configuration.displaymode = "GIF"
            wait(50) // Wait for bindings
            
            // children[0] is view3DLoader, children[1] is AnimatedImage
            var view3DLoader = widgetLoader.item.children[0]
            var animation = widgetLoader.item.children[1]

            verify(view3DLoader !== undefined, "3D Loader should exist")
            verify(animation !== undefined, "AnimatedImage should exist")

            compare(view3DLoader.active, false, "3D Loader should not be active")
            compare(animation.visible, true, "Animation should be visible")
        }

        function test_3dModeVisibility() {
            mockPlasmoid.configuration.displaymode = "3D Mesh"
            wait(50)
            
            var view3DLoader = widgetLoader.item.children[0]
            compare(view3DLoader.active, true, "3D Loader should be active")
        }

        function test_gifProperties() {
            mockPlasmoid.configuration.gifspeed = 2.5
            mockPlasmoid.configuration.mirror = true
            mockPlasmoid.configuration.hq = false

            wait(50)
            
            var animation = widgetLoader.item.children[1]
            
            compare(animation.speed, 2.5, "Animation speed should update from config")
            compare(animation.mirror, true, "Animation mirror should update from config")
            compare(animation.mipmap, false, "Animation mipmap should update from config")
        }

        function test_mouseAreaInteraction() {
            // children[0] view3DLoader, [1] animation, [2] error Rectangle, [3] MouseArea
            var mouseArea = widgetLoader.item.children[3]
            verify(mouseArea !== undefined, "MouseArea should exist")

            // themeSong is not directly in children (MediaPlayer is not an Item),
            // but we can ensure toggleThemeSong can be called without errors.
            widgetLoader.item.toggleThemeSong("On Click")
            widgetLoader.item.toggleThemeSong("On Double Click")
            widgetLoader.item.toggleThemeSong("Never")

            // In GIF mode (the default set by init()), the MouseArea handles clicks directly.
            compare(mouseArea.visible, true, "MouseArea should be visible in GIF mode")
            compare(mouseArea.z, 1, "MouseArea should be on top (z=1)")
        }

        function test_mouseAreaDisabledIn3DMode() {
            mockPlasmoid.configuration.displaymode = "3D Mesh"
            wait(50)

            var mouseArea = widgetLoader.item.children[3]
            compare(mouseArea.visible, false, "MouseArea should be hidden in 3D mode so it doesn't block camera drag")
            compare(mouseArea.enabled, false, "MouseArea should be disabled in 3D mode so it doesn't block camera drag")
        }
    }
}
