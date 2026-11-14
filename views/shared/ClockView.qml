import QtQuick
import "../../styles"

Item {
    id: root
    property bool expanded: false
    implicitWidth: clock.implicitWidth
    implicitHeight: clock.implicitHeight

    Text {
        id: clock
        anchors.centerIn: parent
        color: Theme.textPrimary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        font.bold: true
        font.features: { "tnum": 1 }
        text: Qt.formatTime(new Date(), "HH:mm")

        Timer {
            id: tick
            interval: 1000
            running: true
            repeat: true

            onTriggered: {
                var now = new Date()
                clock.text = Qt.formatTime(now, "HH:mm")
                tick.interval = Math.max(1000, (60 - now.getSeconds()) * 1000)
            }
        }
    }
}
