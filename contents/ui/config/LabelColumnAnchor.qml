/*
 * Reserves room in a form's label column for labels that aren't on screen.
 *
 * Kirigami sizes a FormLayout's label column to the widest *visible* label,
 * so a page whose rows come and go - Movement's, as the movement type
 * changes, or General's, as the display mode does - slides every control
 * sideways the moment the widest visible label changes. Listing every label
 * a page can show here and naming this item in that page's
 * FormLayout.twinFormLayouts pins the column to a constant width: twinned
 * layouts size their label column to the widest label across the whole
 * group, and this one holds all of them at all times.
 *
 * It draws nothing and takes up no space, but is still "visible" as far as
 * that width calculation goes - which is the entire point of it.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    // The labels to reserve room for, as a list of strings.
    property alias labels: labelRepeater.model

    implicitHeight: 0
    clip: true
    opacity: 0
    enabled: false

    Repeater {
        id: labelRepeater

        delegate: Item {
            required property string modelData

            Kirigami.FormData.label: modelData
        }
    }
}
