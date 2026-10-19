import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../../island"
import "../../services"
import "../bar"

Item {
    id: root
    // Bar layout passes false: the bar's center section swaps the
    // clock for the status overlay instead, so the chip would only
    // duplicate the OSD next to the systray icons.
    property bool showStatusChip: true
    // Bar layout passes false: it shows the pill in its own left
    // cluster next to the notification bell instead.
    property bool showControlPill: true
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        StatusChip {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showStatusChip && StatusManager.visible
            icon: StatusManager.icon
            title: StatusManager.title
        }

        ControlPill {
            id: pill
            visible: root.showControlPill
            Layout.alignment: Qt.AlignVCenter
        }

        PrivacyCluster {
            id: privacy
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: powerButton
            color: powerHover.hovered ? Theme.buttonHover : Theme.surface
            radius: 10
            implicitWidth: 32
            implicitHeight: pill.implicitHeight
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            HoverHandler {
                id: powerHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: function(event) {
                    event.accepted = true

                    if (
                        IslandState.mode === IslandState.powerMenuMode
                    )
                        return

                    IslandController.openPowerMenu()
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: powerHover.hovered ? Theme.iconActive : Theme.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
        }
    }
}
