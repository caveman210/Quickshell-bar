import QtQuick

import "../styles"
import "../services"

Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    Rectangle {
        id: pill
        color: Theme.surface
        radius: 10
        implicitWidth: icons.implicitWidth + 18
        implicitHeight: icons.implicitHeight + 10
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: icons
            anchors.centerIn: parent
            spacing: 6

            HoverHandler {
                id: batteryHover
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: LowBatteryService.icon
                color: LowBatteryService.percentage <= 10 ? Theme.danger : Theme.warning
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: batteryHover.visible
                text: LowBatteryService.displayText
                color: Theme.textPrimary
                font.pixelSize: 12
            }
        }
    }
}
