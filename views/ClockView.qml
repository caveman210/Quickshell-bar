import QtQuick
import "../styles"

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
        text: Qt.formatTime(new Date(), "HH:mm")

        // Minute-aligned ticker: fires once, then re-arms for the next
        // minute boundary instead of waking the QML engine every second
        // to redraw an identical string 60x per minute.
        Timer {
            id: tick
            interval: 1000
            running: true
            repeat: true

            onTriggered: {
                var now = new Date()

                clock.text = Qt.formatTime(now, "HH:mm")

                tick.interval = Math.max(
                    1000,
                    (60 - now.getSeconds()) * 1000
                )
            }
        }
    }
}
