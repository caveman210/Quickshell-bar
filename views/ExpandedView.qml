import QtQuick

import "../components"
import "../services"

Item {
    id: root

    // The privacy cluster adds a third control to the right of the
    // states pill, so the bar grew from 520 to 560 to keep the centre
    // from being squeezed.
    //
    // Both side columns MUST be the same width: the clock sits at the
    // midpoint of whatever is left between them, so any difference
    // between the left and right columns drags the clock off the
    // capsule's true centre. Keeping one shared value makes that
    // impossible to break by accident.
    readonly property int totalWidth: 560
    readonly property int sideWidth: 172
    readonly property int gutter: 28

    implicitWidth: totalWidth
    implicitHeight: 75

    BatteryService {
        id: batteryService
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 0

        LeftSection {
            width: root.sideWidth
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: root.totalWidth - root.sideWidth * 2 - root.gutter
            height: parent.height

            CenterSection {
                expanded: true
                anchors.centerIn: parent
            }
        }

        RightSection {
            width: root.sideWidth
            anchors.verticalCenter: parent.verticalCenter
            batteryService: batteryService
        }
    }
}