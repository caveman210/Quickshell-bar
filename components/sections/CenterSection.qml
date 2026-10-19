import QtQuick
import QtQuick.Layouts
import "../../views/shared"
import "../../styles"
import "../../services"

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
}
