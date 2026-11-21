/*
 * A Kirigami.FormLayout that doesn't paint its first, not-yet-laid-out frame.
 *
 * FormLayout only works out how wide it wants to be one event loop turn
 * after it is built: the grid holding the rows is centred in the form and
 * takes its width from wideImplicitWidth, which starts at 0 and is filled
 * in from a zero-interval Timer (see FormLayout.qml). Twinned layouts -
 * LabelColumnAnchor - land even later, via Qt.callLater. A page painted
 * before all that has settled shows its controls bunched in the middle of
 * an empty column and then snaps them outwards, which is the flicker seen
 * the first time a section of the settings dialog is opened.
 *
 * So stay transparent until the width has stopped moving for a full event
 * loop turn. opacity, not visible: ScrollablePage measures its content
 * height from its *visible* children, and an invisible form would collapse
 * the page - the same reason LabelColumnAnchor hides itself this way.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: form

    // True once the layout has settled, i.e. once the form is safe to show.
    property bool laidOut: false

    opacity: laidOut ? 1 : 0

    // Every width change pushes the reveal back to the next turn. NOTE: not
    // Component.onCompleted - an attached signal handler declared here would
    // *replace* FormLayout's own, which is where it lays its rows out.
    onImplicitWidthChanged: settleTimer.restart()

    Timer {
        id: settleTimer
        interval: 0
        running: true
        onTriggered: form.laidOut = true
    }
}
