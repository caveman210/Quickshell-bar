import QtQuick
import "../../services"

Item {
    id: root
    property bool hovered: false
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        AlbumArt {
            anchors.verticalCenter: parent.verticalCenter
        }

        SongInfo {
            hovered: root.hovered
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
