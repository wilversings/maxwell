import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: page

    // SimpleKCM's own padding is 6px, which leaves the topmost control
    // almost touching the dialog's header. The category is already named in
    // the sidebar, so no per-page title bar either.
    topPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None

    property var cfg_movement
    property alias cfg_cpusamplerate: samplerate.value
    property var cfg_cpusamplerateDefault
    property var cfg_fansensor
    property alias cfg_fanautorange: fanautorange.checked
    property alias cfg_fanminrpm: fanminrpm.value
    property alias cfg_fanmaxrpm: fanmaxrpm.value
    property alias cfg_proximityreach: proximityreach.value
    property var cfg_proximityreachDefault
    property alias cfg_gifspeed: gifspeed.value
    property var cfg_gifspeedDefault
    property alias cfg_glbspeed: glbspeed.value
    property var cfg_glbspeedDefault

    // The display mode is set on the General page. Read it live instead of
    // declaring cfg_displaymode here, which would make this page write its
    // own (possibly stale) copy back on Apply.
    readonly property bool is3DMode: Plasmoid.configuration.displaymode === "3D Mesh"

    // null when libksysguard is missing (the Loader errors on its import).
    readonly property var discovery: discoveryLoader.status === Loader.Ready ? discoveryLoader.item : null
    readonly property bool sensorsAvailable: discovery !== null
    readonly property bool scanned: discovery ? discovery.scanned : true

    function isAvailable(type) {
        switch (type) {
        case "Constant":
            return true
        case "By CPU usage":
            return sensorsAvailable
        case "By GPU usage":
            return sensorsAvailable && discovery.gpuAvailable
        case "By fan speed":
            return sensorsAvailable && discovery.fans.count > 0
        case "By cursor proximity":
            return true
        }
        return false
    }

    // What the widget will actually do: an unavailable type falls back to
    // constant speed. cfg_movement itself is left untouched, so it comes back
    // on its own if e.g. the GPU shows up again. Until the first sensor scan
    // finishes, trust the configured type rather than flashing "Constant".
    readonly property string effectiveMovement: !scanned || isAvailable(cfg_movement) ? cfg_movement : "Constant"

    // Learned values are written by the widget itself (FanRangeLearner.qml),
    // so they're read live from Plasmoid.configuration rather than as cfg_
    // properties - which also keeps Apply from writing a stale copy back.
    readonly property bool hasLearnedRange: Plasmoid.configuration.fanlearnedsensor === cfg_fansensor
                                            && cfg_fansensor !== ""
                                            && Plasmoid.configuration.fanlearnedmin >= 0

    function selectMovement(type) {
        cfg_movement = type
        if (type === "By fan speed" && discovery.indexOfFan(cfg_fansensor) === -1) {
            const fan = discovery.defaultFan()
            if (fan) {
                selectFan(fan)
            }
        }
    }

    function selectFan(fan) {
        cfg_fansensor = fan.sensorId
        // Most motherboard fans don't report a maximum, but when one does
        // (e.g. GPU fans), it's a better upper bound than a guess.
        if (fan.maximum > 0) {
            fanmaxrpm.value = fan.maximum
        }
    }

    SettingsForm {
        // Every movement type shows a different set of rows, so without this
        // the label column - and with it every control on the page - would
        // shift sideways on each switch.
        twinFormLayouts: [labelWidths]

        ColumnLayout {
            Kirigami.FormData.label: i18n("Type")
            Kirigami.FormData.buddyFor: constantMovement

            // Probes libksysguard and discovers the GPU and fans. Invisible, so
            // it takes no space in the layout.
            Loader {
                id: discoveryLoader
                source: "SensorDiscovery.qml"
                visible: false
            }

            RadioButton {
                id: constantMovement
                readonly property string type: "Constant"
                text: i18n("Constant")
                checked: page.effectiveMovement === type
                onToggled: if (checked) page.selectMovement(type)
            }
            RadioButton {
                readonly property string type: "By CPU usage"
                text: i18n("By CPU usage")
                enabled: page.isAvailable(type)
                checked: page.effectiveMovement === type
                onToggled: if (checked) page.selectMovement(type)
            }
            RadioButton {
                readonly property string type: "By GPU usage"
                text: page.sensorsAvailable && page.scanned && !enabled ? i18n("By GPU usage (no GPU found)") : i18n("By GPU usage")
                enabled: page.isAvailable(type)
                checked: page.effectiveMovement === type
                onToggled: if (checked) page.selectMovement(type)
            }
            RadioButton {
                readonly property string type: "By fan speed"
                text: page.sensorsAvailable && page.scanned && !enabled ? i18n("By fan speed (no fans found)") : i18n("By fan speed")
                enabled: page.isAvailable(type)
                checked: page.effectiveMovement === type
                onToggled: if (checked) page.selectMovement(type)
            }
            RadioButton {
                readonly property string type: "By cursor proximity"
                text: i18n("By cursor proximity")
                checked: page.effectiveMovement === type
                onToggled: if (checked) page.selectMovement(type)
            }
            Label {
                visible: !page.sensorsAvailable
                text: i18n("CPU, GPU and fan speed need libksysguard, which wasn't found.")
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 20 * Kirigami.Units.gridUnit
            }
        }

        RowLayout {
            visible: page.effectiveMovement === "By fan speed"
            Kirigami.FormData.label: i18n("Fan")
            ComboBox {
                id: fanCombo
                Layout.minimumWidth: 20 * Kirigami.Units.gridUnit
                model: page.discovery ? page.discovery.fans : null
                textRole: "label"
                currentIndex: page.discovery && page.discovery.fans.count >= 0 ? page.discovery.indexOfFan(page.cfg_fansensor) : -1
                displayText: currentIndex === -1 && page.cfg_fansensor ? i18n("%1 (not found)", page.cfg_fansensor) : currentText
                onActivated: index => page.selectFan(page.discovery.fans.get(index))
            }
        }

        CheckBox {
            id: fanautorange
            visible: page.effectiveMovement === "By fan speed"
            Kirigami.FormData.label: i18n("RPM range")
            text: i18n("Learn automatically")
        }

        RowLayout {
            visible: page.effectiveMovement === "By fan speed" && fanautorange.checked
            Label {
                text: page.hasLearnedRange
                      ? i18n("Learned so far: %1–%2 RPM", Plasmoid.configuration.fanlearnedmin, Plasmoid.configuration.fanlearnedmax)
                      : i18n("Nothing learned yet")
            }
            Button {
                text: i18n("Reset learned range")
                icon.name: "edit-reset"
                enabled: page.hasLearnedRange
                // Takes effect immediately rather than on Apply, like "Reset
                // default position" on the General page.
                onClicked: Plasmoid.configuration.fanlearnedsensor = ""
            }
        }

        Label {
            visible: page.effectiveMovement === "By fan speed" && fanautorange.checked
            text: i18n("Maxwell learns the lowest and highest speed this fan holds and spans slowest to fastest across it. He starts out calm and livens up once the fan ramps up.")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 25 * Kirigami.Units.gridUnit
        }

        RowLayout {
            visible: page.effectiveMovement === "By fan speed" && !fanautorange.checked
            SpinBox {
                id: fanminrpm
                // Fixed ranges rather than bounding each box by the other: the
                // cfg_ values are assigned one at a time when the page opens, so
                // a dependent bound could clamp (and then save) a stored value.
                from: 0
                to: 20000
                stepSize: 100
                editable: true
            }
            Label {
                text: i18nc("RPM range, e.g. 0 to 2000", "to")
            }
            SpinBox {
                id: fanmaxrpm
                from: 1
                to: 20000
                stepSize: 100
                editable: true
            }
        }

        Label {
            visible: page.effectiveMovement === "By fan speed" && !fanautorange.checked
            text: fanminrpm.value < fanmaxrpm.value
                  ? i18n("Maxwell spins slowest at or below the lower bound and fastest at or above the upper one.")
                  : i18n("The lower bound must be below the upper one, otherwise Maxwell stays at his slowest.")
            color: fanminrpm.value < fanmaxrpm.value ? Kirigami.Theme.textColor : Kirigami.Theme.negativeTextColor
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 25 * Kirigami.Units.gridUnit
        }

        RowLayout {
            visible: page.effectiveMovement === "By cursor proximity"
            Kirigami.FormData.label: i18n("Reach")
            SpinBox {
                id: proximityreach
                from: 0
                to: 2000
                stepSize: 50
                editable: true
                textFromValue: function(value) { return i18n("%1 px", value) }
                valueFromText: function(text) { return parseInt(text.replace(/\D/g, "")) || 0 }
            }
            Button {
                text: i18n("Reset default")
                icon.name: "edit-reset"
                onClicked: proximityreach.value = page.cfg_proximityreachDefault
            }
        }

        Label {
            visible: page.effectiveMovement === "By cursor proximity"
            text: i18n("Maxwell spins faster the closer the cursor gets, and fastest right on top of him. He only notices it on the desktop or panel he lives on, not over other windows.")
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 25 * Kirigami.Units.gridUnit
        }

        RowLayout {
            visible: page.effectiveMovement !== "Constant" && page.effectiveMovement !== "By cursor proximity"
            Kirigami.FormData.label: i18n("Sample rate")
            SpinBox {
                id: samplerate
                from: 500
                to: 10000
                stepSize: 500
                textFromValue: function(value) { return i18n("%1 ms", value) }
                valueFromText: function(text) { return parseInt(text.replace(/\D/g, "")) }
            }
            Button {
                text: i18n("Reset default")
                icon.name: "edit-reset"
                onClicked: samplerate.value = page.cfg_cpusamplerateDefault
            }
        }

        RowLayout {
            visible: !page.is3DMode && page.effectiveMovement === "Constant"
            Kirigami.FormData.label: i18n("Speed")
            Slider {
                id: gifspeed
                Layout.preferredWidth: 15 * Kirigami.Units.gridUnit
                from: 0.6
                to: 10
                stepSize: 0.4
            }
            Button {
                text: i18n("Reset default")
                icon.name: "edit-reset"
                onClicked: gifspeed.value = page.cfg_gifspeedDefault
            }
        }

        RowLayout {
            visible: page.is3DMode && page.effectiveMovement === "Constant"
            Kirigami.FormData.label: i18n("Speed")
            Slider {
                id: glbspeed
                Layout.preferredWidth: 15 * Kirigami.Units.gridUnit
                from: 0.6
                to: 10
                stepSize: 0.4
            }
            Button {
                text: i18n("Reset default")
                icon.name: "edit-reset"
                onClicked: glbspeed.value = page.cfg_glbspeedDefault
            }
        }
    }

    // Keeps the label column the same width in every movement type.
    LabelColumnAnchor {
        id: labelWidths
        labels: [
            i18n("Type"),
            i18n("Fan"),
            i18n("RPM range"),
            i18n("Reach"),
            i18n("Sample rate"),
            i18n("Speed"),
        ]
    }
}
