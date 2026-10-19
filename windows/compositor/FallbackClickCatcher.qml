import QtQuick

// Fallback for compositors without a focus grab (e.g. Niri): a click
// anywhere on the bar surface outside the island dismisses the modal
// view instead. Gated by Item.enabled from the host window.
Item {
    id: root

    signal dismissed()

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: root.dismissed()
    }
}
