import QtQuick
import QtQuick.Layouts
import QtMultimedia

Item {
    id: widget

    implicitWidth: 100
    implicitHeight: 100

    // AudioOutput's `device` doesn't follow the system default on its own -
    // it's a plain property, only ever set once at creation. Binding it to
    // MediaDevices.defaultAudioOutput (which does update live) keeps the
    // theme song following Plasma's active playback device instead of
    // getting stuck on whatever device was default when it started playing.
    MediaDevices {
        id: mediaDevices
    }

    MediaPlayer {
        id: themeSong
        source: plasmoid.configuration.themepath
        loops: plasmoid.configuration.themesongloops

        audioOutput: AudioOutput {
            device: mediaDevices.defaultAudioOutput
        }
    }

    // "dbustrigger" isn't shown in the config UI - it only exists so an
    // external DBus call (see tools/dbus_control.sh) can bump it and
    // play the theme song on demand, independent of the "Play theme song"
    // click setting.
    Connections {
        target: plasmoid.configuration
        function onDbustriggerChanged() {
            if (themeSong.playing) {
                themeSong.stop()
            }
            themeSong.play()
        }
    }

    // Check if 3D Mesh mode is active
    readonly property bool is3DMode: plasmoid.configuration.displaymode === "3D Mesh"

    // Sensor-driven movement ("By CPU usage", "By GPU usage", "By fan speed").
    // Each maps its reading onto 0-1, then linearly onto the same 0.6-10 range
    // the speed sliders in config/Movement.qml offer. Falls back to the
    // constant gifspeed/glbspeed whenever the sensor isn't usable: libksysguard
    // missing, no GPU, or the configured fan gone. The config dialog disables
    // unavailable types, but they can still be set externally (e.g. DBus).
    readonly property string movement: plasmoid.configuration.movement
    readonly property string sensorId: movement === "By CPU usage" ? "cpu/all/usage"
                                     : movement === "By GPU usage" ? "gpu/all/usage"
                                     : movement === "By fan speed" ? plasmoid.configuration.fansensor
                                     : ""
    readonly property bool sensorMovement: sensorId !== ""
                                           && sensorLoader.status === Loader.Ready
                                           && sensorLoader.item.ready

    readonly property real sensorMinSpeed: 0.6
    readonly property real sensorMaxSpeed: 10

    function sensorFraction(value) {
        let fraction
        if (movement === "By fan speed") {
            const autoRange = plasmoid.configuration.fanautorange
            const minRpm = autoRange ? fanRangeLearner.rangeMin : plasmoid.configuration.fanminrpm
            const maxRpm = autoRange ? fanRangeLearner.rangeMax : plasmoid.configuration.fanmaxrpm
            fraction = maxRpm > minRpm ? (value - minRpm) / (maxRpm - minRpm) : 0
        } else {
            fraction = value / 100
        }
        return Math.min(Math.max(fraction, 0), 1)
    }

    property real sensorSpeed: sensorMovement
                               ? sensorMinSpeed + (sensorMaxSpeed - sensorMinSpeed) * sensorFraction(sensorLoader.item.value)
                               : sensorMinSpeed

    // Smoothing: ramp towards each new sample over one sample period, so the
    // speed changes continuously instead of stepping every sample.
    Behavior on sensorSpeed {
        enabled: sensorMovement
        NumberAnimation {
            duration: plasmoid.configuration.cpusamplerate
            easing.type: Easing.InOutQuad
        }
    }

    // "By cursor proximity": the closer the cursor, the faster he spins -
    // slowest at `proximityreach` px away or further (or once it leaves),
    // fastest with the cursor on the widget itself. Plasma gives widgets no
    // global cursor position (and Wayland wouldn't allow it anyway), so this
    // only sees the cursor while it's over the same surface as the widget
    // and not over anything stacked on top: on the desktop that's the reach
    // around him, in a panel only the panel itself.
    readonly property bool proximityMovement: movement === "By cursor proximity"
    readonly property int proximityReach: Math.max(plasmoid.configuration.proximityreach, 0)

    // Distance from (x, y), in widget coordinates, to the widget's edge
    // (0 inside it), mapped onto 1 at the edge down to 0 at proximityReach.
    function proximityFraction(x, y) {
        const dx = Math.max(-x, 0, x - width)
        const dy = Math.max(-y, 0, y - height)
        const distance = Math.sqrt(dx * dx + dy * dy)
        if (proximityReach === 0) {
            return distance === 0 ? 1 : 0
        }
        return Math.min(Math.max(1 - distance / proximityReach, 0), 1)
    }

    property real proximitySpeed: proximityMovement && proximityTracker.hovered
                                  ? sensorMinSpeed + (sensorMaxSpeed - sensorMinSpeed) * proximityFraction(proximityTracker.cursorX, proximityTracker.cursorY)
                                  : sensorMinSpeed

    // Cursor positions arrive far more often than sensor samples, so ease at
    // a fixed rate instead of over a fixed duration: a full slowest-to-
    // fastest swing (either way) takes about half a second.
    Behavior on proximitySpeed {
        enabled: proximityMovement
        SmoothedAnimation {
            velocity: 18
        }
    }

    readonly property real gifSpeed: sensorMovement ? sensorSpeed
                                   : proximityMovement ? proximitySpeed
                                   : plasmoid.configuration.gifspeed
    readonly property real glbSpeed: sensorMovement ? sensorSpeed
                                   : proximityMovement ? proximitySpeed
                                   : plasmoid.configuration.glbspeed

    // Error handling properties
    readonly property bool hasQtQuick3DError: is3DMode && view3DLoader.status === Loader.Error
    readonly property bool hasAssimpError: is3DMode && view3DLoader.item && view3DLoader.item.hasError
    readonly property bool is3DError: hasQtQuick3DError || hasAssimpError

    // Loader for 3D view - dynamically loads view3d.qml only when needed
    Loader {
        id: view3DLoader
        anchors.fill: parent
        source: is3DMode ? "view3d.qml" : ""
        active: is3DMode

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("QtQuick3D view failed to load")
            }
        }

        onLoaded: {
            item.clicked.connect(function() { toggleThemeSong("On Click") })
            item.doubleClicked.connect(function() { toggleThemeSong("On Double Click") })
            item.speed = Qt.binding(function() { return widget.glbSpeed })
        }
    }

    // AnimatedImage for GIF mode
    AnimatedImage {
        id: animation
        source: plasmoid.configuration.gifpath
        visible: !is3DMode

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent

        speed: widget.gifSpeed
        mirror: plasmoid.configuration.mirror
        mipmap: plasmoid.configuration.hq
    }

    // Error message when 3D mode fails to load
    Rectangle {
        anchors.centerIn: parent
        width: childrenRect.width + 20
        height: childrenRect.height + 20

        visible: is3DError
        color: "#ffffff"
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: hasQtQuick3DError ? "3D Engine Failed to Load" : "3D Model Failed to Load"
                font.bold: true
                font.pixelSize: 14
                color: "#000000"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: hasQtQuick3DError ? "The QtQuick3D library is missing.\n\nInstall qt6-qtquick3d for your distribution" : 
                                          "The Assimp asset import plugin may be missing or the model file is invalid.\n\nInstall the Assimp plugin for your distribution\n\nhttps://github.com/wilversings/maxwell"
                font.pixelSize: 11
                color: "#000000"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }

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

    // MouseArea for click/double-click interactions in GIF mode.
    // In 3D mode, clicks are handled by view3d.qml instead so this
    // doesn't steal drag events from the orbit camera controller.
    MouseArea {
        anchors.fill: parent
        visible: !is3DMode
        enabled: !is3DMode
        z: 1

        onClicked: toggleThemeSong("On Click")
        onDoubleClicked: toggleThemeSong("On Double Click")
    }

    // Hardware sensor, isolated in HardwareSensor.qml so a missing
    // libksysguard only disables sensor-driven movement. Kept last among the
    // children so the children[] indices tests/tst_main.qml relies on stay
    // unchanged.
    Loader {
        id: sensorLoader
        source: "HardwareSensor.qml"
        active: widget.sensorId !== ""

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("Hardware sensor failed to load (libksysguard missing?), using constant speed")
            }
        }

        onLoaded: {
            item.sensorId = Qt.binding(function() { return widget.sensorId })
            item.sampleRate = Qt.binding(function() { return plasmoid.configuration.cpusamplerate })
        }
    }

    // Learned RPM range for "By fan speed" when fanautorange is on (the
    // default); see FanRangeLearner.qml.
    FanRangeLearner {
        id: fanRangeLearner
        sensorId: widget.movement === "By fan speed" ? plasmoid.configuration.fansensor : ""
        active: widget.sensorMovement && widget.movement === "By fan speed" && plasmoid.configuration.fanautorange
        rpm: widget.sensorMovement ? sensorLoader.item.value : 0
        sampleRate: plasmoid.configuration.cpusamplerate
    }

    // Cursor tracking for "By cursor proximity": an invisible item reaching
    // proximityReach past each edge, since hover is delivered by the item's
    // own geometry rather than its parent's. A HoverHandler (not a hover-
    // enabled MouseArea) doesn't block hover from what's underneath - desktop
    // icons still highlight - and a bare Item takes no clicks, so neither the
    // desktop nor the camera drag in 3D mode notice it. Kept last for the
    // same children[] reason as sensorLoader.
    Item {
        id: proximityArea
        anchors.fill: parent
        anchors.margins: -widget.proximityReach
        visible: widget.proximityMovement
        enabled: widget.proximityMovement

        HoverHandler {
            id: proximityTracker
            // In widget coordinates.
            readonly property real cursorX: point.position.x - widget.proximityReach
            readonly property real cursorY: point.position.y - widget.proximityReach
        }
    }
}
