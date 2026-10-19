import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../services"

Column {
    id: root
    property bool showCava: true
    property int titleWidth: 80
    property int artistWidth: 130
    property int titleFontSize: 13
    property int artistFontSize: 11
    spacing: 2
    readonly property bool hasMedia: MediaService.hasPlayer

    RowLayout {
        spacing: 6

        Cava {
            visible: hasMedia && root.showCava
            Layout.alignment: Qt.AlignVCenter
        }

        ScrollingText {
            text: hasMedia
                    ? (MediaService.title || "No Title")
                    : "Nothing"
            maxWidth: root.titleWidth
            fontSize: root.titleFontSize
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ScrollingText {
        text: hasMedia
                ? (MediaService.artist || "Unknown Artist")
                : "Playing"
        maxWidth: root.artistWidth
        fontSize: root.artistFontSize
        opacity: 0.7
    }
}
