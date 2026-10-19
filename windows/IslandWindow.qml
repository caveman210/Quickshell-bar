import QtQuick
import Quickshell
import Quickshell.Wayland

import "../island"
import "../core"
import "../services"
import "../services/appearance"
import "../services/compositor"
import "../services/notification"
import "../services/shell"
import "../styles"
import "compositor"

PanelWindow {
    id: root
    visible: ThemeService.ready

    HyprlandFocusGrabDismiss {
        id: focusGrab
        enabled: ThemeService.ready && IslandState.modal
        targetWindow: root

        onDismissed: IslandController.reset()
    }

    // Without a focus grab (niri), a click anywhere on the bar surface
    // outside the island dismisses the modal view instead.
    readonly property bool modalClickCatcher: ThemeService.ready
        && IslandState.modal
        && !CompositorService.isHyprland

    FallbackClickCatcher {
        id: modalCatcher

        anchors.fill: parent
        enabled: root.modalClickCatcher

        onDismissed: IslandController.reset()
    }

    // Focusable whenever a modal view is open so keyboard navigation
    // (hjkl / arrows / Enter / Esc) works on all compositors.
    focusable: ThemeService.ready && IslandState.modal

    anchors {
        top: true
        left: true
        right: true
    }

    // Auto-hide overlays the desktop instead of reserving a gap, so
    // windows don't reflow every time focus changes. With the feature
    // off, reserve the usual 33px like before.
    exclusiveZone: ThemeService.ready && !AutoHideService.enabled ? 33 : 0

    // Top renders under fullscreen windows; Overlay renders above
    // them. Use Overlay whenever auto-hide is on so the revealed
    // island sits over everything, per the feature's contract.
    WlrLayershell.layer: AutoHideService.enabled ? WlrLayer.Overlay : WlrLayer.Top

    // Auto-hide reserves no exclusive zone, so the revealed island
    // sits a little further from the top edge; with the feature off
    // keep the original 10px inset.
    readonly property int revealedTop: AutoHideService.enabled ? 24 : 10

    // Tallest view is ControlCenterView (530). Keep the surface
    // height fixed so island size animations never resize the layer
    // surface every frame (configure/ack roundtrips = stutter).
    // Math.max falls back to the animated height if a view ever
    // grows past this instead of clipping it. Bar layout adds the
    // bar itself on top of the dropdown slot.
    readonly property int maxIslandHeight: 530 + (IslandState.layoutIsBar ? Theme.barHeight : 0)

    implicitHeight: Math.max(maxIslandHeight, capsule.implicitHeight) + revealedTop + 10
    color: "transparent"

    // The notch hangs flush from the screen's top edge (that is
    // what makes it read as a notch); the pill keeps its inset.
    // The bar keeps a floating inset like the pill.
    readonly property bool notchLayout: IslandState.layout === IslandState.layoutNotch

    Island {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter

        // Auto-hide slide: retract above the window's top edge (the
        // surface clips it away), same easing the expansion uses.
        // The bar floats: barMargin below the top edge, barSideMargin
        // in from the sides.
        y: AutoHideService.hidden
            ? -(height + 10)
            : notchLayout
                ? 0
                : IslandState.layoutIsBar
                    ? Theme.barMargin
                    : revealedTop

        Behavior on y {
            NumberAnimation {
                duration: Theme.animationNormal
                easing.type: Theme.animationVertical
            }
        }
    }

    // Flow-corner wings for the floating bar: at each screen corner
    // the top edge runs off the monitor's border, then a concave
    // fillet sweeps down into the bar's side edge. Decorative only
    // (kept out of the input mask).
    readonly property bool barFlow: ThemeService.ready
        && IslandState.layoutIsBar
        && !AutoHideService.hidden
    readonly property real flowRadius: Theme.radiusLarge

    Rectangle {
        visible: root.barFlow
        x: 0
        y: 0
        width: Math.max(0, capsule.x - root.flowRadius)
        height: Theme.barMargin
        color: Theme.background
    }

    FlowCorner {
        visible: root.barFlow
        x: capsule.x - root.flowRadius
        y: Theme.barMargin
        radius: root.flowRadius
    }

    Rectangle {
        visible: root.barFlow
        x: capsule.x + capsule.width + root.flowRadius
        y: 0
        width: Math.max(0, root.width - (capsule.x + capsule.width + root.flowRadius))
        height: Theme.barMargin
        color: Theme.background
    }

    FlowCorner {
        visible: root.barFlow
        x: capsule.x + capsule.width
        y: Theme.barMargin
        radius: root.flowRadius
        mirror: true
    }

    // Notch layout: the notch hangs flush from the screen's top
    // edge, so its side edges flow into the top border with the
    // same concave join and no wings. Follows the notch through
    // every expansion, since the fillets ride capsule's geometry.
    readonly property bool notchFlow: ThemeService.ready
        && root.notchLayout
        && !AutoHideService.hidden

    FlowCorner {
        visible: root.notchFlow
        x: capsule.x - root.flowRadius
        y: 0
        radius: root.flowRadius
    }

    FlowCorner {
        visible: root.notchFlow
        x: capsule.x + capsule.width
        y: 0
        radius: root.flowRadius
        mirror: true
    }

    Region {
        id: capsuleMask
        item: capsule
    }

    Region {
        id: surfaceMask
        item: modalCatcher
    }

    // Bar layout: the input region is the union of the bar and
    // whichever dropdown surface is open (zero-sized regions add
    // nothing). The empty space beside a narrower dropdown lets
    // clicks through to the desktop.
    Region {
        id: barMask

        Region {
            x: capsule.x
            y: capsule.y
            width: capsule.width
            height: Theme.barHeight
            radius: Theme.capsuleRadius
        }

        Region {
            x: capsule.x + capsule.panelX
            y: capsule.y + Theme.barHeight
            width: capsule.panelWidth
            height: capsule.panelHeight
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.capsuleRadius
            bottomRightRadius: Theme.capsuleRadius
        }

        Region {
            x: capsule.x + capsule.trayX
            y: capsule.y + Theme.barHeight
            width: capsule.trayWidth
            height: capsule.trayHeight
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.capsuleRadius
            bottomRightRadius: Theme.capsuleRadius
        }
    }

    mask: modalClickCatcher
        ? surfaceMask
        : IslandState.layoutIsBar ? barMask : capsuleMask

    // Hidden saver for notification profile pictures. NotificationStore
    // hands over an image URL + token; this Image decodes it (full-res —
    // the provider ignores requestedSize), checks that it is avatar
    // sized, then grabs to a tmp PNG which the store hashes and files
    // away under assets/. Kept offscreen but visible: grabs of
    // invisible items come back empty. Non-avatar images are discarded
    // without any disk write.
    Image {
        id: mediaSaver
        x: -10000
        y: 0
        width: Math.max(1, implicitWidth)
        height: Math.max(1, implicitHeight)
        cache: false
        asynchronous: false
        property string pendingSource: ""
        property int doneToken: -1

        // Imperative assignment (instead of a binding) avoids a
        // re-entrant binding loop while requests come and go.
        source: pendingSource

        function maybeGrab() {
            if (!NotificationStore.grabRequest)
                return

            // Wait for the right decode; a stale Ready from the
            // previous URL must not be grabbed.
            if (pendingSource !== NotificationStore.grabRequest.url)
                return

            if (status !== Image.Ready)
                return

            var token = NotificationStore.grabRequest.token

            if (doneToken === token)
                return

            doneToken = token

            var w = Math.max(1, implicitWidth)
            var h = Math.max(1, implicitHeight)

            // Only profile pictures are worth keeping; message photos
            // are dropped before anything touches the disk.
            if (!NotificationStore.isAvatarDim(w, h)) {
                NotificationStore.grabDiscarded(token)
                return
            }

            var scale = Math.min(1, 2048 / Math.max(w, h))
            var tw = Math.max(1, Math.round(w * scale))
            var th = Math.max(1, Math.round(h * scale))
            var path = NotificationStore.tmpPath()

            grabToImage(function(result) {
                var ok = result ? result.saveToFile(path) : false
                NotificationStore.grabResult(token, ok, path, w, h)
            }, Qt.size(tw, th))
        }

        onStatusChanged: maybeGrab()

        Connections {
            target: NotificationStore

            function onGrabRequestChanged() {
                mediaSaver.pendingSource = NotificationStore.grabRequest
                    ? NotificationStore.grabRequest.url
                    : ""
                Qt.callLater(mediaSaver.maybeGrab)
            }
        }
    }
}
