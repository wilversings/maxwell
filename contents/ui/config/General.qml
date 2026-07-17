import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Dialogs as QtDialogs
import org.kde.plasma.plasmoid

Kirigami.FormLayout {
    id: page

    property var cfg_displaymode
    property alias cfg_gifspeed: gifspeed.value
    property var cfg_gifspeedDefault
    property alias cfg_glbspeed: glbspeed.value
    property var cfg_glbspeedDefault
    property alias cfg_mirror: mirror.checked
    property alias cfg_hq: hq.checked
    property alias cfg_allowcameradrag: allowcameradrag.checked

    // No visible controls for these - the camera pose is only ever set by
    // dragging in the 3D view itself. Declaring bare cfg_ properties (with
    // their kcfg-supplied *Default counterparts) is enough for the KCM
    // loader to wire them up; see the "Reset default position" button below.
    property var cfg_camposx
    property var cfg_camposxDefault
    property var cfg_camposy
    property var cfg_camposyDefault
    property var cfg_camposz
    property var cfg_camposzDefault
    property var cfg_camrotx
    property var cfg_camrotxDefault
    property var cfg_camroty
    property var cfg_camrotyDefault
    property var cfg_camzoom
    property var cfg_camzoomDefault

    // cfg_campos*/cfg_camrot*/cfg_camzoom above are only ever initialized
    // once, when the dialog opens. But the live view3d.qml camera keeps
    // writing straight to Plasmoid.configuration whenever the user drags it
    // - including while this dialog is still open. AppletConfiguration.qml's
    // saveConfig() unconditionally writes every cfg_* property back into the
    // live config on Apply/OK, regardless of what the user actually touched
    // in this dialog. Without this, dragging the camera live, then applying
    // some unrelated change (e.g. unchecking "Allow dragging the camera")
    // would silently revert the camera to wherever it was when the dialog
    // was opened. So: keep these mirrored to the live value the whole time
    // the dialog is open, so that blind writeback is always a no-op for them.
    Connections {
        target: Plasmoid.configuration
        function onCamposxChanged() { cfg_camposx = Plasmoid.configuration.camposx }
        function onCamposyChanged() { cfg_camposy = Plasmoid.configuration.camposy }
        function onCamposzChanged() { cfg_camposz = Plasmoid.configuration.camposz }
        function onCamrotxChanged() { cfg_camrotx = Plasmoid.configuration.camrotx }
        function onCamrotyChanged() { cfg_camroty = Plasmoid.configuration.camroty }
        function onCamzoomChanged() { cfg_camzoom = Plasmoid.configuration.camzoom }
    }

    property alias cfg_gifpath: gifpath.text
    property var cfg_gifpathDefault
    property alias cfg_glbpath: glbpath.text
    property var cfg_glbpathDefault

    property var cfg_playthemesong
    property alias cfg_themesongloops: themesongloops.value
    property alias cfg_themepath: themepath.text
    property var cfg_themepathDefault

    ComboBox {
        id: displaymode
        model: ["GIF", "3D Mesh"]
        Kirigami.FormData.label: i18n("Display mode")

        Component.onCompleted: {
            const selectedIndex = displaymode.find(cfg_displaymode)
            displaymode.currentIndex = selectedIndex != -1 ? selectedIndex : 0
        }

        onActivated: {
            cfg_displaymode = currentValue
        }
    }

    RowLayout {
        visible: displaymode.currentIndex === 0
        Kirigami.FormData.label: i18n("Path to GIF:")
        TextField {
            id: gifpath
            placeholderText: i18n("No file selected.")
        }
        Button {
            text: i18n("Browse")
            icon.name: "folder-symbolic"
            onClicked: gifFileDialogLoader.active = true

            Loader {
                id: gifFileDialogLoader
                active: false

                sourceComponent: FileDialog {
                    id: gifFileDialog
                    nameFilters: [
                        i18n("GIF", "*.gif"),
                        i18n("All files", "*"),
                    ]
                    onAccepted: {
                        gifpath.text = gifFileDialog.selectedFile
                        gifFileDialogLoader.active = false
                    }
                    onRejected: {
                        gifFileDialogLoader.active = false
                    }
                    Component.onCompleted: open()
                }
            }
        }
        Button {
            text: i18n("Reset default")
            icon.name: "edit-reset"
            onClicked: gifpath.text = cfg_gifpathDefault
        }
    }

    RowLayout {
        visible: displaymode.currentIndex === 0
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
            onClicked: gifspeed.value = cfg_gifspeedDefault
        }
    }

    RowLayout {
        visible: displaymode.currentIndex === 1
        Kirigami.FormData.label: i18n("Path to 3D Mesh:")
        TextField {
            id: glbpath
            placeholderText: i18n("No file selected.")
        }
        Button {
            text: i18n("Browse")
            icon.name: "folder-symbolic"
            onClicked: glbFileDialogLoader.active = true

            Loader {
                id: glbFileDialogLoader
                active: false

                sourceComponent: FileDialog {
                    id: glbFileDialog
                    nameFilters: [
                        i18n("GLB", "*.glb"),
                        i18n("All files", "*"),
                    ]
                    onAccepted: {
                        glbpath.text = glbFileDialog.selectedFile
                        glbFileDialogLoader.active = false
                    }
                    onRejected: {
                        glbFileDialogLoader.active = false
                    }
                    Component.onCompleted: open()
                }
            }
        }
        Button {
            text: i18n("Reset default")
            icon.name: "edit-reset"
            onClicked: glbpath.text = cfg_glbpathDefault
        }
    }

    RowLayout {
        visible: displaymode.currentIndex === 1
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
            onClicked: glbspeed.value = cfg_glbspeedDefault
        }
    }

    CheckBox {
        id: mirror
        visible: displaymode.currentIndex === 0

        Kirigami.FormData.label: i18n("Mirror")
    }

    CheckBox {
        id: hq
        visible: displaymode.currentIndex === 0

        Kirigami.FormData.label: i18n("High render quality")
    }

    RowLayout {
        visible: displaymode.currentIndex === 1
        Kirigami.FormData.label: i18n("Allow dragging the camera")

        CheckBox {
            id: allowcameradrag
        }
        Button {
            text: i18n("Reset default position")
            icon.name: "edit-reset"
            onClicked: {
                // Write both: cfg_* keeps this dialog's Cancel/Apply/OK
                // bookkeeping correct for any other pending edits, while
                // Plasmoid.configuration.* (the live config - Plasmoid is an
                // attached property, so it resolves to the same applet
                // instance view3d.qml reads from) makes the reset take
                // effect immediately instead of waiting for Apply/OK.
                cfg_camposx = cfg_camposxDefault
                cfg_camposy = cfg_camposyDefault
                cfg_camposz = cfg_camposzDefault
                cfg_camrotx = cfg_camrotxDefault
                cfg_camroty = cfg_camrotyDefault
                cfg_camzoom = cfg_camzoomDefault
                Plasmoid.configuration.camposx = cfg_camposxDefault
                Plasmoid.configuration.camposy = cfg_camposyDefault
                Plasmoid.configuration.camposz = cfg_camposzDefault
                Plasmoid.configuration.camrotx = cfg_camrotxDefault
                Plasmoid.configuration.camroty = cfg_camrotyDefault
                Plasmoid.configuration.camzoom = cfg_camzoomDefault
            }
        }
    }

    ComboBox {
        id: playthemesong
        model: ["Never", "On Click", "On Double Click"]
        Kirigami.FormData.label: i18n("Play/Stop theme song")

        Component.onCompleted: {
            const selectedIndex = playthemesong.find(cfg_playthemesong)
            playthemesong.currentIndex = selectedIndex != -1 ? selectedIndex : 0
        }

        onActivated: {
            cfg_playthemesong = currentValue
        }
    }

    SpinBox {
        id: themesongloops
        enabled: cfg_playthemesong != "Never"
        from: 1

        Kirigami.FormData.label: i18n("Theme song loops")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Path to theme song:")

        TextField {
            id: themepath
            placeholderText: i18n("No file selected.")
        }
        Button {
            text: i18n("Browse")
            icon.name: "folder-symbolic"
            onClicked: themeFileDialogLoader.active = true

            Loader {
                id: themeFileDialogLoader
                active: false

                sourceComponent: FileDialog {
                    id: themeFileDialog
                    nameFilters: [
                        i18n("WAV", "*.wav"),
                        i18n("All files", "*"),
                    ]
                    onAccepted: {
                        themepath.text = themeFileDialog.selectedFile
                        themeFileDialogLoader.active = false
                    }
                    onRejected: {
                        themeFileDialogLoader.active = false
                    }
                    Component.onCompleted: open()
                }
            }
        }
        Button {
            text: i18n("Reset default")
            icon.name: "edit-reset"
            onClicked: themepath.text = cfg_themepathDefault
        }
    }
}