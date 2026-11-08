import QtQuick
import QtQuick.Layouts

import "../shared"
import "../../styles"
import "../../services"
import "../../services/power"
import "../../components/bar"
import "../../core"
import "../../island"

Item {
    id: root
    implicitWidth: indicators.anyActive
                       ? 240 + indicators.leftWidth + indicators.rightWidth
                       : 240
    implicitHeight: 33

    PrivacyIndicators {
        id: indicators
        split: false
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    // Centered Clock — clicking expands the Calendar alone
    RowLayout {
        id: row
        spacing: 8
        anchors.centerIn: parent

        ClockView {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (IslandState.mode === IslandState.calendarMode)
                IslandController.reset()
            else
                IslandController.openCalendar()
        }
    }

    // Right end: Battery readout
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: BatteryService.icon
        color: Theme.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
    }
}
