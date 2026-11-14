import QtQuick
import "../../services"

Item {
    id: root
    property bool hovered: false
    property bool cavaOnly: false
    property bool hideCover: false
    property int availableTextWidth: 95

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        AlbumArt {
            visible: !root.cavaOnly && !root.hideCover
            anchors.verticalCenter: parent.verticalCenter
        }

        SongInfo {
            hovered: root.hovered
            textVisible: !root.cavaOnly
            showCava: true
            titleWidth: root.availableTextWidth
            artistWidth: root.availableTextWidth + 30
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
