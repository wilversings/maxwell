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
            property string themepath: "../contents/ui/assets/stockmarket.wav"
            property string playthemesong: "On Double Click"
            property int themesongloops: 1
            property double gifspeed: 1.0
            property double glbspeed: 2.0
            property bool mirror: false
            property bool hq: true
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
            var mouseArea = widgetLoader.item.children[2]
            verify(mouseArea !== undefined, "MouseArea should exist")
            
            // themeSong is not directly in children (MediaPlayer is not an Item), 
            // but we can ensure toggleThemeSong can be called without errors.
            mouseArea.toggleThemeSong("On Click")
            mouseArea.toggleThemeSong("On Double Click")
            mouseArea.toggleThemeSong("Never")
            
            // Check visibility
            compare(mouseArea.visible, true, "MouseArea should always be visible")
            compare(mouseArea.z, 1, "MouseArea should be on top (z=1)")
        }
    }
}
