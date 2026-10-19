import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../services"
import "../../services/power"

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

        RowLayout {
            id: icons
            anchors.centerIn: parent
            spacing: 6

            HoverHandler {
                id: batteryHover
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: LowBatteryService.icon
                color: LowBatteryService.percentage <= 10 ? Theme.danger : Theme.warning
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: batteryHover.hovered
                text: LowBatteryService.displayText
                color: Theme.textPrimary
                font.pixelSize: 12
            }
        }
    }
}
