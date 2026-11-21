import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    // SimpleKCM's own padding is 6px, which leaves the topmost control
    // almost touching the dialog's header. The category is already named in
    // the sidebar, so no per-page title bar either.
    topPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None

    property var cfg_playthemesong
    property alias cfg_themesongloops: themesongloops.value
    property alias cfg_themepath: themepath.text
    property var cfg_themepathDefault

    SettingsForm {
        ComboBox {
            id: playthemesong
            model: ["Never", "On Click", "On Double Click"]
            Kirigami.FormData.label: i18n("Play/Stop theme song")

            Component.onCompleted: {
                const selectedIndex = playthemesong.find(page.cfg_playthemesong)
                playthemesong.currentIndex = selectedIndex != -1 ? selectedIndex : 0
            }

            onActivated: {
                page.cfg_playthemesong = currentValue
            }
        }

        SpinBox {
            id: themesongloops
            enabled: page.cfg_playthemesong != "Never"
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
                            i18n("WAV (*.wav)"),
                            i18n("All files (*)"),
                        ]
                        onAccepted: {
                            themepath.text = themeFileDialog.selectedFile.toString().replace(/^file:\/\//, "")
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
                onClicked: themepath.text = page.cfg_themepathDefault
            }
        }
    }
}
