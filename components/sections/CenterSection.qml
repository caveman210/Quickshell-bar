import QtQuick
import QtQuick.Layouts
import "../../views/shared"
import "../../styles"
import "../../services"
import "../../core"
import "../../island"

Item {
    id: root
    property bool expanded: false
    implicitWidth: row.implicitWidth
    implicitHeight: expanded
        ? column.implicitHeight
        : row.implicitHeight

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: Theme.clockSpacing

        RowLayout {
            id: row
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            Cava {
                visible: MediaService.hasPlayer && !root.expanded
                Layout.alignment: Qt.AlignVCenter
            }

            ClockView {
                id: clock
            }
        }

        DateView {
            visible: root.expanded
            Layout.alignment: Qt.AlignHCenter
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true
            IslandController.ignoreNextIslandTap()
            if (IslandState.mode === IslandState.calendarMode) {
                if (IslandState.returnToExpanded)
                    IslandController.restoreExpanded()
                else
                    IslandController.reset()
            } else {
                IslandState.returnToExpanded = IslandState.islandPinned
                IslandState.islandPinned = false
                IslandController.openCalendar()
            }
        }
    }
}
