import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../services"

// One mounted disk in the Control Center storage card: mount point,
// usage bar and an eject action for removable media.
Item {
    id: root

    property var device

    signal ejectRequested()

    readonly property bool isRemovable: root.device ? root.device.removable : false
    readonly property real fraction: root.device
        ? Math.max(0, Math.min(1, root.device.usedPercent / 100))
        : 0

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "󰋊"
                color: Theme.icon
                font.family: Theme.iconFont
                font.pixelSize: 15
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.device && root.device.label !== ""
                        ? root.device.label
                        : root.device.mountpoint
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.device
                        ? StorageService.formatBytes(root.device.used)
                          + " of " + StorageService.formatBytes(root.device.size)
                          + "  ·  " + root.device.fsType
                        : ""
                    color: Theme.textMuted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: root.device ? Math.round(root.device.usedPercent) + "%" : ""
                color: root.fraction > 0.9 ? Theme.danger : Theme.textSecondary
                font.pixelSize: 12
            }

            Rectangle {
                visible: root.isRemovable
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: ejectLabel.implicitWidth + 18
                implicitHeight: 22
                radius: Theme.radiusSmall
                color: ejectMouse.containsMouse ? Theme.surfaceVariant
                                                : Theme.buttonBackground

                Text {
                    id: ejectLabel
                    anchors.centerIn: parent
                    text: "Eject"
                    color: Theme.buttonText
                    font.pixelSize: 11
                }

                MouseArea {
                    id: ejectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.ejectRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.surfaceVariant

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.fraction
                radius: 3
                color: root.fraction > 0.9 ? Theme.danger : Theme.accent
            }
        }
    }
}
