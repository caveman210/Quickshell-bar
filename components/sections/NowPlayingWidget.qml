import QtQuick
import "../../services"

Item {
    id: root
    property bool hovered: false
    property bool cavaOnly: false
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter

        AlbumArt {
            visible: !root.cavaOnly
            anchors.verticalCenter: parent.verticalCenter
        }

        SongInfo {
            hovered: root.hovered
            textVisible: !root.cavaOnly
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}

