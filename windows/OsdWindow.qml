import QtQuick
import Quickshell
import Quickshell.Wayland

import "../core"
import "../island"
import "../services/appearance"
import "../services/shell"
import "../styles"
import "../views/shared"

// Status toasts stay on the top edge even when the island docks
// elsewhere (currently a bottom bar). Same pill as the auto-hidden
// island: it slides down into view and StatusManager's timer hides it.
PanelWindow {
    id: root

    visible: ThemeService.ready && IslandState.dockBottom

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    // The toast is non-interactive; an empty input region keeps the
    // whole top strip click-through.
    mask: Region {}

    readonly property int topInset: AutoHideService.enabled ? 24 : 10
    implicitHeight: topInset + osdCapsule.height

    Rectangle {
        id: osdCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        width: osdView.implicitWidth
        height: osdView.implicitHeight
        radius: Theme.capsuleRadius
        color: Theme.background

        // Off-screen above the surface when hidden; the auto-hide
        // pill's slide brings it in from the top.
        y: StatusManager.visible ? root.topInset : -(height + 10)

        Behavior on y {
            NumberAnimation {
                duration: Theme.animationNormal
                easing.type: Theme.animationVertical
            }
        }

        OverlayView {
            id: osdView
            anchors.fill: parent
        }
    }
}
