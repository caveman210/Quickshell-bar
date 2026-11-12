import QtQuick

import "../../styles"
import "../../services"
import "../../services/audio"

Item {
    id: root
    property int barCount: 5
    property int barWidth: 3
    property int spacingSize: 2
    property int baseHeight: 3
    property int extraHeight: 10
    implicitWidth:
        (barCount * barWidth) +
        ((barCount - 1) * spacingSize)

    implicitHeight:
        baseHeight + extraHeight

    Row {
        id: barsRow
        anchors.fill: parent
        spacing: root.spacingSize

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                width: root.barWidth
                radius: width / 2
                anchors.bottom: parent.bottom
                color: Theme.textPrimary
                property int barIndex: Math.min(
                    CavaService.bars.length - 1,
                    Math.round(2 + (index * (CavaService.bars.length - 1 - 2)) / Math.max(1, root.barCount - 1))
                )
                property real level:
                    barIndex >= 0 && barIndex < CavaService.bars.length
                        ? CavaService.bars[barIndex] / 100
                        : 0
                height:
                    root.baseHeight +
                    (level * root.extraHeight)

                Behavior on height {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Component.onCompleted: CavaService.viewers++
    Component.onDestruction: CavaService.viewers--
}
