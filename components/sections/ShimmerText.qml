import QtQuick
import "../../styles"

// Subtle indeterminate work indicator mirroring islandcn ShimmerText
Item {
    id: root
    property string text: ""
    property int fontSize: 13
    property bool running: true

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        text: root.text
        color: Theme.textMuted
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
    }

    Text {
        id: shimmerOverlay
        text: root.text
        color: Theme.textPrimary
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
        opacity: shimmerAnim.shimmerVal

        SequentialAnimation {
            id: shimmerAnim
            running: root.running
            loops: Animation.Infinite
            property real shimmerVal: 0.2

            NumberAnimation {
                target: shimmerAnim
                property: "shimmerVal"
                from: 0.2
                to: 1.0
                duration: 900
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: shimmerAnim
                property: "shimmerVal"
                from: 1.0
                to: 0.2
                duration: 900
                easing.type: Easing.InOutQuad
            }
        }
    }
}
