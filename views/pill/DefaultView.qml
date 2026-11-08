import QtQuick
import QtQuick.Layouts

import "../shared"
import "../../styles"
import "../../services"
import "../../services/power"
import "../../components/bar"

Item {
    id: root
    implicitWidth: indicators.anyActive
                       ? Math.max(160, row.implicitWidth + 32)
                         + indicators.leftWidth + indicators.rightWidth
                       : Math.max(160, row.implicitWidth + 32)
    implicitHeight: 33

    PrivacyIndicators {
        id: indicators
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        id: row
        spacing: 8
        anchors.centerIn: parent

        ClockView {
            Layout.alignment: Qt.AlignVCenter
        }

        LowBatteryIndicator {
            visible: LowBatteryService.active
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
