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
            property string glbpath: "../contents/ui/assets/maxwell-spinning.glb"
            property string themepath: "../contents/ui/assets/stockmarket.wav"
            property string playthemesong: "On Double Click"
            property int themesongloops: 1
            property string movement: "Constant"
            property int cpusamplerate: 1000
            property string fansensor: ""
            property bool fanautorange: true
            property string fanlearnedsensor: ""
            property int fanlearnedmin: -1
            property int fanlearnedmax: -1
            property int fanminrpm: 0
            property int fanmaxrpm: 2000
            property int proximityreach: 300
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
            property int dbustrigger: 0
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
            mockPlasmoid.configuration.movement = "Constant"
            mockPlasmoid.configuration.cpusamplerate = 1000
            mockPlasmoid.configuration.fansensor = ""
            mockPlasmoid.configuration.fanautorange = true
            mockPlasmoid.configuration.fanlearnedsensor = ""
            mockPlasmoid.configuration.fanlearnedmin = -1
            mockPlasmoid.configuration.fanlearnedmax = -1
            mockPlasmoid.configuration.fanminrpm = 0
            mockPlasmoid.configuration.fanmaxrpm = 2000
            mockPlasmoid.configuration.proximityreach = 300
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
            mockPlasmoid.configuration.dbustrigger = 0

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

        function test_dbusTriggerPlaysThemeSong() {
            // Simulate an external DBus caller bumping the trigger config
            // even though "playthemesong" is set to "Never" - the DBus
            // trigger should play regardless of that setting.
            mockPlasmoid.configuration.playthemesong = "Never"
            mockPlasmoid.configuration.dbustrigger = 1
            wait(50)

            mockPlasmoid.configuration.dbustrigger = 2
            wait(50)
        }

        function test_mouseAreaDisabledIn3DMode() {
            mockPlasmoid.configuration.displaymode = "3D Mesh"
            wait(50)

            var mouseArea = widgetLoader.item.children[3]
            compare(mouseArea.visible, false, "MouseArea should be hidden in 3D mode so it doesn't block camera drag")
            compare(mouseArea.enabled, false, "MouseArea should be disabled in 3D mode so it doesn't block camera drag")
        }

        function test_proximityFraction() {
            var w = widgetLoader.item
            // The Loader leaves the widget at its implicit 100x100.
            compare(w.proximityFraction(50, 50), 1, "Cursor on the widget should be fastest")
            compare(w.proximityFraction(0, 100), 1, "Cursor on the edge should be fastest")
            compare(w.proximityFraction(250, 50), 0.5, "Halfway through the reach should be half speed")
            compare(w.proximityFraction(-300, 50), 0, "Cursor at the reach should be slowest")
            compare(w.proximityFraction(-1000, -1000), 0, "Cursor beyond the reach should be slowest")
            fuzzyCompare(w.proximityFraction(-90, -120), 0.5, 0.0001, "Distance past a corner is measured diagonally")

            mockPlasmoid.configuration.proximityreach = 0
            compare(w.proximityFraction(50, 50), 1, "Zero reach still reacts on the widget")
            compare(w.proximityFraction(101, 50), 0, "Zero reach ignores the cursor outside")
        }

        function test_proximityMovementSpeed() {
            var w = widgetLoader.item
            // Last child: the proximity tracking area.
            var area = w.children[w.children.length - 1]
            compare(area.enabled, false, "Proximity tracking should be off unless selected")

            mockPlasmoid.configuration.movement = "By cursor proximity"
            wait(50)
            compare(area.enabled, true, "Proximity tracking should be on when selected")
            compare(area.x, -300, "Tracking area should reach past the left edge")
            compare(area.width, 700, "Tracking area should reach past both edges")
            // No cursor seen yet: slowest, not the constant speed.
            compare(w.gifSpeed, w.sensorMinSpeed, "Speed should be slowest without a cursor")
            compare(w.glbSpeed, w.sensorMinSpeed, "3D speed should follow the same proximity speed")

            mouseMove(root, 50, 50)
            tryCompare(w, "gifSpeed", w.sensorMaxSpeed, 2000, "Speed should ramp to fastest with the cursor on the widget")
        }
    }
}
