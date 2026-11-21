import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
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

    property var cfg_displaymode
    property alias cfg_gifpath: gifpath.text
    property var cfg_gifpathDefault
    property alias cfg_glbpath: glbpath.text
    property var cfg_glbpathDefault
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

    // True while the widget is in 3D Mesh mode. Read off the combo box below
    // rather than the saved config so the camera row appears and disappears
    // as soon as the display mode is switched, without waiting for Apply/OK.
    readonly property bool is3DMode: displaymode.currentIndex === 1

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
        function onCamposxChanged() { page.cfg_camposx = Plasmoid.configuration.camposx }
        function onCamposyChanged() { page.cfg_camposy = Plasmoid.configuration.camposy }
        function onCamposzChanged() { page.cfg_camposz = Plasmoid.configuration.camposz }
        function onCamrotxChanged() { page.cfg_camrotx = Plasmoid.configuration.camrotx }
        function onCamrotyChanged() { page.cfg_camroty = Plasmoid.configuration.camroty }
        function onCamzoomChanged() { page.cfg_camzoom = Plasmoid.configuration.camzoom }
    }

    SettingsForm {
        // The rows swap as the display mode changes, and their labels aren't
        // the same width - without this the whole page would shift sideways
        // on each switch.
        twinFormLayouts: [labelWidths]

        ComboBox {
            id: displaymode
            model: ["GIF", "3D Mesh"]
            Kirigami.FormData.label: i18n("Display mode")

            Component.onCompleted: {
                const selectedIndex = displaymode.find(page.cfg_displaymode)
                displaymode.currentIndex = selectedIndex != -1 ? selectedIndex : 0
            }

            onActivated: {
                page.cfg_displaymode = currentValue
            }
        }

        RowLayout {
            visible: !page.is3DMode
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
                            i18n("GIF (*.gif)"),
                            i18n("All files (*)"),
                        ]
                        onAccepted: {
                            gifpath.text = gifFileDialog.selectedFile.toString().replace(/^file:\/\//, "")
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
                onClicked: gifpath.text = page.cfg_gifpathDefault
            }
        }

        RowLayout {
            visible: page.is3DMode
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
                            i18n("GLB (*.glb)"),
                            i18n("All files (*)"),
                        ]
                        onAccepted: {
                            glbpath.text = glbFileDialog.selectedFile.toString().replace(/^file:\/\//, "")
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
                onClicked: glbpath.text = page.cfg_glbpathDefault
            }
        }

        CheckBox {
            id: mirror
            visible: !page.is3DMode

            Kirigami.FormData.label: i18n("Mirror")
        }

        CheckBox {
            id: hq
            visible: !page.is3DMode

            Kirigami.FormData.label: i18n("High render quality")
        }

        RowLayout {
            visible: page.is3DMode
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
                    page.cfg_camposx = page.cfg_camposxDefault
                    page.cfg_camposy = page.cfg_camposyDefault
                    page.cfg_camposz = page.cfg_camposzDefault
                    page.cfg_camrotx = page.cfg_camrotxDefault
                    page.cfg_camroty = page.cfg_camrotyDefault
                    page.cfg_camzoom = page.cfg_camzoomDefault
                    Plasmoid.configuration.camposx = page.cfg_camposxDefault
                    Plasmoid.configuration.camposy = page.cfg_camposyDefault
                    Plasmoid.configuration.camposz = page.cfg_camposzDefault
                    Plasmoid.configuration.camrotx = page.cfg_camrotxDefault
                    Plasmoid.configuration.camroty = page.cfg_camrotyDefault
                    Plasmoid.configuration.camzoom = page.cfg_camzoomDefault
                }
            }
        }
    }

    // Keeps the label column the same width in both display modes.
    LabelColumnAnchor {
        id: labelWidths
        labels: [
            i18n("Display mode"),
            i18n("Path to GIF:"),
            i18n("Path to 3D Mesh:"),
            i18n("Mirror"),
            i18n("High render quality"),
            i18n("Allow dragging the camera"),
        ]
    }
}
