import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import QtQuick.Dialogs as QtDialogs

Kirigami.FormLayout {
    id: page

    property var cfg_displaymode
    property alias cfg_gifspeed: gifspeed.value
    property alias cfg_glbspeed: glbspeed.value
    property alias cfg_mirror: mirror.checked
    property alias cfg_hq: hq.checked
    property alias cfg_gifpath: gifpath.text
    property var cfg_gifpathDefault

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

    Slider {
        id: gifspeed
        visible: displaymode.currentIndex === 0
        Layout.preferredWidth: 15 * Kirigami.Units.gridUnit
        from: 0.6
        to: 10
        stepSize: 0.4
        Kirigami.FormData.label: i18n("Speed")
    }

    Slider {
        id: glbspeed
        visible: displaymode.currentIndex === 1
        Layout.preferredWidth: 15 * Kirigami.Units.gridUnit
        from: 0.6
        to: 10
        stepSize: 0.4
        Kirigami.FormData.label: i18n("Speed")
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