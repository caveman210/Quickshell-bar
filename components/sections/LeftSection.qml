import QtQuick

import "../../styles"
import "../../core"

Item {
    id: root
    property bool interactive: true
    implicitWidth: Theme.leftSectionWidth
    implicitHeight: nowPlaying.implicitHeight

    NowPlayingWidget {
        id: nowPlaying
        hovered: sectionHover.hovered
        anchors.left: parent.left
        anchors.leftMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
    }

    HoverHandler {
        id: sectionHover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            IslandController.openMediaFromLeftSection()
        }
    }
}
