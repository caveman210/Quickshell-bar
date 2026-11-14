import QtQuick

import "../../styles"
import "../../services"
import "../../services/audio"

// Animated level indicator for audio mirroring islandcn LevelMeter:
// Center-scaled, dot-like pill baseline, continuous physics,
// and smooth falloff to avoid placeholder aesthetics.
Item {
    id: root
    property int barCount: 4
    property int barWidth: 3
    property int spacingSize: 2
    property int baseHeight: 3
    property int extraHeight: 13
    property color barColor: Theme.accent
    property bool active: MediaService.isPlaying
    // If dotBaseline is true, at rest or quiet audio the bars rest as circular dots (height = barWidth)
    property bool dotBaseline: true

    implicitWidth: (barCount * barWidth) + ((barCount - 1) * spacingSize)
    implicitHeight: baseHeight + extraHeight

    // Speech & music balanced frequency bin distribution
    readonly property var binDistribution: [4, 12, 22, 36]

    // islandcn pseudo-random harmonic baseline
    function hash(n) {
        var x = Math.sin(n * 127.1 + 311.7) * 43758.5453
        return x - Math.floor(x)
    }

    Row {
        id: barsRow
        anchors.centerIn: parent
        spacing: root.spacingSize

        Repeater {
            model: root.barCount

            Item {
                id: barContainer
                required property int index
                width: root.barWidth
                height: root.implicitHeight

                property int barIndex: index < root.binDistribution.length
                    ? Math.min(CavaService.bars.length - 1, root.binDistribution[index])
                    : Math.min(CavaService.bars.length - 1, index * 6)

                property real rawLevel: (barIndex >= 0 && barIndex < CavaService.bars.length)
                    ? CavaService.bars[barIndex] / 100
                    : 0

                // Gamma curve 0.75 for voice & commentary + music dynamic balance
                property real dynamicLevel: Math.min(1.0, Math.pow(rawLevel, 0.75) * 1.25)
                // Resting baseline: circular dot height if quiet or inactive
                property real idleWave: root.active ? (root.hash(index) * 0.12) : 0
                property real effectiveLevel: Math.max(idleWave, dynamicLevel)

                Rectangle {
                    id: bar
                    width: root.barWidth
                    // When quiet, height equals width (dot shape)
                    height: Math.max(
                        root.dotBaseline ? root.barWidth : root.baseHeight,
                        root.implicitHeight * barContainer.effectiveLevel
                    )
                    radius: root.barWidth / 2
                    color: root.barColor
                    anchors.centerIn: parent

                    Behavior on height {
                        NumberAnimation {
                            duration: 75
                            easing.type: Easing.OutCubic
                        }
                    }

                    // islandcn inner core highlight
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(1, parent.width - 1.5)
                        height: Math.max(1.5, parent.height * 0.4)
                        radius: width / 2
                        color: "#ffffff"
                        opacity: 0.35
                        visible: parent.height > (root.barWidth + 2)
                    }
                }
            }
        }
    }

    Component.onCompleted: CavaService.viewers++
    Component.onDestruction: CavaService.viewers--
}
