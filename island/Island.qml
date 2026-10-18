import QtQuick

import "../styles"
import "../core"
import "../components"

Rectangle {
    id: root
    clip: true
    readonly property bool notch: IslandState.shape === IslandState.shapeNotch
    // Notch reads as a notch only with a flat top hanging from the
    // screen edge; bottom corners keep the capsule radius. Pill
    // keeps the uniform radius from before.
    topLeftRadius: notch ? 0 : Theme.capsuleRadius
    topRightRadius: notch ? 0 : Theme.capsuleRadius
    bottomLeftRadius: Theme.capsuleRadius
    bottomRightRadius: Theme.capsuleRadius
    color: Theme.background
    width: implicitWidth
    height: implicitHeight
    implicitWidth: viewHost.implicitWidth
    implicitHeight: viewHost.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animationNormal
            easing.type: Theme.animationHorizontal
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.animationNormal
            easing.type: Theme.animationVertical
        }
    }

    HoverHandler {
        id: islandHover

        onHoveredChanged: {
            islandInteraction.handleHoverChanged(hovered)
        }
    }

    IslandInteraction {
        id: islandInteraction
        anchors.fill: parent
    }

    ViewHost {
        id: viewHost
        anchors.centerIn: parent
    }

    // Transient toast for modes without their own StatusManager
    // indicator (control-center / media / power / theme /
    // wallpaper). Default mode swaps in OverlayView and expanded
    // mode shows RightSection's StatusChip, so this covers the
    // rest and queued toasts are never invisible. Non-interactive
    // (no handlers, no focus) so modal FocusScope keyboard nav and
    // IslandInteraction clicks are unaffected, and it floats without
    // changing the capsule's implicit size.
    StatusChip {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10
        visible: StatusManager.visible
            && IslandState.mode !== IslandState.defaultMode
            && IslandState.mode !== IslandState.expandedMode
        icon: StatusManager.icon
        title: StatusManager.title
    }
}
