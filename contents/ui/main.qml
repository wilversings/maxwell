import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: widget

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    implicitWidth: 100
    implicitHeight: 100

    MaxwellWidget {
        anchors.fill: parent
    }
}
