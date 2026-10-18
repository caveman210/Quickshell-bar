import QtQuick

import "../views"
import "../styles"
import "../services"
import "../components"

Item {
    id: root
    // Base 160 fits the centered clock. Nothing live collapses to
    // exactly that. As soon as any indicator activates, both flanks
    // are added to the base — enough for mic on the left and
    // camera/cast on the right — so the clock stays centered and a
    // second device filling the opposite slot never resizes the bar
    // again.
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

    Row {
        id: row
        spacing: 8
        anchors.centerIn: parent

        ClockView {
            anchors.verticalCenter: parent.verticalCenter
        }

        LowBatteryIndicator {
            visible: LowBatteryService.active
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}