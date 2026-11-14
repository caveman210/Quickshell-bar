import QtQuick

import "../styles"
import "../core"
import "../components/bar"
import "../components/sections"
import "../views/bar"
import "../views/shared"
import "../services/notification"

Rectangle {
    id: root
    // Split mode: two separate rounded rects that handle their own bounds — no clip needed.
    clip: !(viewHost.currentItem && viewHost.currentItem.isSplitMode)

    readonly property bool notch: IslandState.layout === IslandState.layoutNotch

    // Bar layout: a floating full-width bar; views drop down into a
    // centered panel slot below it (or the tray app list, right
    // aligned under its button).
    readonly property bool barLayout: IslandState.layoutIsBar
    // Bar integration of the placement preference: a bottom-docked
    // bar grows its dropdowns upward instead of downward.
    readonly property bool bottomDock: IslandState.dockBottom
    readonly property bool panelOpen: IslandState.barPanelOpen
    readonly property bool trayOpen: IslandState.barTrayOpen

    // Geometry of the dropdown surfaces, read by IslandWindow to
    // build the window input mask (union of bar + open surface).
    readonly property real panelWidth: panelOpen ? viewHost.implicitWidth : 0
    readonly property real panelHeight: panelOpen ? viewHost.implicitHeight : 0
    readonly property real trayWidth: trayOpen
        ? (trayMenu && trayMenu.visible ? trayMenu.implicitWidth : (trayOverflow ? trayOverflow.implicitWidth : 0))
        : 0
    readonly property real trayHeight: trayOpen
        ? (trayMenu && trayMenu.visible ? trayMenu.implicitHeight : (trayOverflow ? trayOverflow.implicitHeight : 0))
        : 0

    // Centered under the tray icon that opened the menu, clamped
    // inside the bar with the same corner gap the docked panes keep,
    // so its edges get the flow treatment even when it lands against
    // a bar end.
    readonly property real trayX: {
        if (root.width <= 0)
            return 0

        if (!barLayout)
            return Math.max(8, Math.min(IslandState.trayItemMenuAnchorX - root.x - root.trayWidth / 2, root.width - root.trayWidth - 8))

        if (!barView)
            return 0

        var x = IslandState.trayItemMenuAnchorX - root.x - root.trayWidth / 2
        return Math.max(root.panelDockGap,
                        Math.min(x, root.width - root.trayWidth - root.panelDockGap))
    }

    // Panels that dock to a screen edge instead of the centered
    // dropdown slot. In the bar the media line, the notifications
    // pane and the quote drop down on the left under the bar's own
    // controls (the bell sits on the left, so its pane follows it);
    // the control center and its submenus (wifi / bluetooth / theme /
    // wallpaper) follow the control pill on the right, next to the
    // privacy pane that also lives on that side. The clock dropdown
    // drops down centered, like the OSD.
    // Docked panes keep a gap to the island edge wide enough that
    // the flow-corner arc lands on the bar's straight bottom edge,
    // clear of its rounded corner, so the fillets can join them.
    readonly property real panelDockGap: Theme.radiusLarge + Theme.capsuleRadius
    readonly property bool panelLeft: barLayout
        && (IslandState.mode === IslandState.mediaControlsMode
            || IslandState.mode === IslandState.quoteMode
            || IslandState.mode === IslandState.notificationsMode)
    readonly property bool panelWeather: barLayout && IslandState.mode === IslandState.weatherMode
    readonly property bool panelRight: barLayout
        && (IslandState.mode === IslandState.privacyMenuMode
            || IslandState.mode === IslandState.controlCenterMode
            || IslandState.mode === IslandState.wifiMenuMode
            || IslandState.mode === IslandState.bluetoothMenuMode)
    readonly property real panelX: !barLayout
        ? 0
        : panelWeather
            ? Math.max(panelDockGap, (barView ? barView.weatherCenterX : 80) - panelWidth / 2)
            : panelLeft
                ? panelDockGap
                : panelRight
                    ? width - panelWidth - panelDockGap
                    : (width - panelWidth) / 2

    // Call dropdown: drops down from the center like OSD
    readonly property bool callOpen: barLayout && NotificationService.activeCall !== null
    readonly property real callWidth: callView.implicitWidth
    readonly property real callHeight: callView.implicitHeight
    readonly property real callX: (width - callWidth) / 2

    // Transient OSD dropdown: in the bar the status toast (volume,
    // brightness, workspace, device prompts) drops down centered
    // under the clock instead of replacing it, and stays hidden
    // while another bar dropdown is open — those carry their own
    // feedback. A bottom-docked bar has no top edge to attach to,
    // so OsdWindow shows the toast as a top pill instead.
    readonly property bool osdOpen: barLayout && !bottomDock
        && StatusManager.visible
        && !panelOpen && !trayOpen && !callOpen
    readonly property real osdWidth: osdView.implicitWidth
    readonly property real osdHeight: osdView.implicitHeight
    readonly property real osdX: (width - osdWidth) / 2

    topLeftRadius: barLayout || notch ? 0 : Theme.capsuleRadius
    topRightRadius: barLayout || notch ? 0 : Theme.capsuleRadius
    bottomLeftRadius: Theme.capsuleRadius
    bottomRightRadius: Theme.capsuleRadius
    color: (barLayout || (viewHost.currentItem && viewHost.currentItem.isSplitMode)) ? "transparent" : Theme.background
    width: implicitWidth
    height: implicitHeight
    implicitWidth: barLayout
        ? (parent ? Math.max(0, parent.width - (IslandState.barFloating ? 2 * Theme.barSideMargin : 0)) : 0)
        : viewHost.implicitWidth
    implicitHeight: barLayout
        ? Theme.barHeight + Math.max(
            callOpen ? callHeight : 0,
            trayOpen ? trayHeight : 0,
            panelOpen ? panelHeight : 0,
            osdOpen ? osdHeight : 0
        )
        : (viewHost.implicitHeight + (trayOpen ? trayHeight + 16 : 0))

    Behavior on implicitWidth {
        // Disable during bubble hover: bubbleWidth already animates; a second behavior here lags.
        enabled: !(viewHost.currentItem && viewHost.currentItem.bubbleHovered)
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

    // ---------------------------------------------------------
    // BAR LAYOUT SURFACES
    // ---------------------------------------------------------

    Rectangle {
        id: barSurface
        visible: root.barLayout
        x: 0
        y: root.bottomDock ? root.height - height : 0
        width: root.width
        height: Theme.barHeight
        // Outer corners match the flow-corner fillets; inner corners
        // take the capsule radius when floating, flat when attached.
        topLeftRadius: !IslandState.barFloating ? 0 : (root.bottomDock ? Theme.capsuleRadius : Theme.radiusLarge)
        topRightRadius: !IslandState.barFloating ? 0 : (root.bottomDock ? Theme.capsuleRadius : Theme.radiusLarge)
        bottomLeftRadius: !IslandState.barFloating ? 0 : (root.bottomDock ? Theme.radiusLarge : Theme.capsuleRadius)
        bottomRightRadius: !IslandState.barFloating ? 0 : (root.bottomDock ? Theme.radiusLarge : Theme.capsuleRadius)
        color: Theme.background
    }

    // View dropdown: flush against the bar, flat on the bar side,
    // rounded on the free side — reads as the bar itself expanding.
    // Docked panes keep a fillet-sized gap to the island edge so the
    // flow corners join their outer sides too.
    Rectangle {
        id: panelSurface
        z: 2
        visible: root.barLayout && root.panelOpen
        x: root.panelX
        y: root.bottomDock ? 0 : Theme.barHeight
        width: viewHost.implicitWidth
        height: viewHost.implicitHeight
        topLeftRadius: root.bottomDock ? Theme.capsuleRadius : 0
        topRightRadius: root.bottomDock ? Theme.capsuleRadius : 0
        bottomLeftRadius: root.bottomDock ? 0 : Theme.capsuleRadius
        bottomRightRadius: root.bottomDock ? 0 : Theme.capsuleRadius
        color: Theme.background
    }

    // Call dropdown: slab treatment, centered in the bar
    Rectangle {
        id: callSurface
        z: 2
        visible: root.barLayout && root.callOpen
        x: root.callX
        y: root.bottomDock ? 0 : Theme.barHeight
        width: root.callWidth
        height: root.callHeight
        topLeftRadius: root.bottomDock ? Theme.capsuleRadius : 0
        topRightRadius: root.bottomDock ? Theme.capsuleRadius : 0
        bottomLeftRadius: root.bottomDock ? 0 : Theme.capsuleRadius
        bottomRightRadius: root.bottomDock ? 0 : Theme.capsuleRadius
        color: Theme.background
    }

    CallCard {
        id: callView
        z: 3
        visible: root.barLayout && root.callOpen
        x: root.callX
        y: root.bottomDock ? 0 : Theme.barHeight
    }

    // Transient OSD dropdown under the bar: same slab treatment as
    // the view panel, centered under the clock.
    Rectangle {
        id: osdSurface
        z: 2
        visible: root.osdOpen
        x: root.osdX
        y: Theme.barHeight
        width: root.osdWidth
        height: root.osdHeight
        radius: Theme.capsuleRadius
        topLeftRadius: 0
        topRightRadius: 0
        color: Theme.background
    }

    OverlayView {
        id: osdView
        z: 3
        visible: root.osdOpen
        x: root.osdX
        y: Theme.barHeight
    }

    // ---------------------------------------------------------
    // BAR FILLETS (FlowCorner)
    // ---------------------------------------------------------

    readonly property real filletY: root.bottomDock
        ? root.height - Theme.barHeight - Theme.radiusLarge
        : Theme.barHeight

    FlowCorner {
        visible: root.barLayout && root.panelOpen && root.panelWidth > 0
            && root.panelX >= root.panelDockGap
        x: root.panelX - Theme.radiusLarge
        y: root.filletY
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.panelOpen && root.panelWidth > 0
            && root.panelX + root.panelWidth <= root.width - root.panelDockGap
        x: root.panelX + root.panelWidth
        y: root.filletY
        mirror: true
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.trayOpen && root.trayWidth > 0
            && root.trayX >= root.panelDockGap
        x: root.trayX - Theme.radiusLarge
        y: root.filletY
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.trayOpen && root.trayWidth > 0
            && root.trayX + root.trayWidth <= root.width - root.panelDockGap
        x: root.trayX + root.trayWidth
        y: root.filletY
        mirror: true
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.callOpen && root.callWidth > 0
            && root.callX >= root.panelDockGap
        x: root.callX - Theme.radiusLarge
        y: root.filletY
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.callOpen && root.callWidth > 0
            && root.callX + root.callWidth <= root.width - root.panelDockGap
        x: root.callX + root.callWidth
        y: root.filletY
        mirror: true
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.osdOpen && root.osdWidth > 0
            && root.osdX >= root.panelDockGap
        x: root.osdX - Theme.radiusLarge
        y: root.filletY
        flip: root.bottomDock
    }

    FlowCorner {
        visible: root.barLayout && root.osdOpen && root.osdWidth > 0
            && root.osdX + root.osdWidth <= root.width - root.panelDockGap
        x: root.osdX + root.osdWidth
        y: root.filletY
        mirror: true
        flip: root.bottomDock
    }

    // ---------------------------------------------------------
    // CAPSULE (pill / notch layouts) + DROPDOWN CONTENT (bar)
    // ---------------------------------------------------------

    HoverHandler {
        id: islandHover

        onHoveredChanged: {
            // Don't expand the pill when the pointer is over the secondary detached bubble
            if (hovered && viewHost.currentItem && viewHost.currentItem.bubbleHovered)
                return
            islandInteraction.handleHoverChanged(hovered)
        }
    }

    IslandInteraction {
        id: islandInteraction
        anchors.fill: parent
    }

    // Bar content sits above IslandInteraction so its own handlers
    // (clock toggle, wifi/bt/battery -> control center, tray rows)
    // win over the full-capsule click catcher; empty bar areas still
    // fall through to it.
    // SNI menu slab: same treatment as the view panel and the OSD
    // dropdown, dropping right below the icon that opened it.
    Rectangle {
        id: traySurface
        visible: root.trayOpen
        x: root.trayX
        y: !root.barLayout ? viewHost.implicitHeight + 8 : (root.bottomDock ? 0 : Theme.barHeight)
        width: root.trayWidth
        height: root.trayHeight
        radius: !root.barLayout ? Theme.radiusLarge : 0
        topLeftRadius: root.barLayout && root.bottomDock ? Theme.capsuleRadius : (root.barLayout ? 0 : 12)
        topRightRadius: root.barLayout && root.bottomDock ? Theme.capsuleRadius : (root.barLayout ? 0 : 12)
        bottomLeftRadius: root.barLayout && root.bottomDock ? 0 : (root.barLayout ? Theme.capsuleRadius : 12)
        bottomRightRadius: root.barLayout && root.bottomDock ? 0 : (root.barLayout ? Theme.capsuleRadius : 12)
        color: !root.barLayout ? Theme.surface : Theme.background
        border.width: !root.barLayout ? 1 : 0
        border.color: Theme.border
    }

    TrayOverflowView {
        id: trayOverflow
        visible: IslandState.trayOverflowOpen && !IslandState.trayItemMenu
        x: root.trayX
        y: !root.barLayout ? viewHost.implicitHeight + 8 : (root.bottomDock ? 0 : Theme.barHeight)
    }

    TrayItemMenu {
        id: trayMenu
        visible: IslandState.trayItemMenu !== null
        x: root.trayX
        y: !root.barLayout ? viewHost.implicitHeight + 8 : (root.bottomDock ? 0 : Theme.barHeight)
    }

    BarView {
        id: barView
        visible: root.barLayout
        x: 0
        y: root.bottomDock ? parent.height - height : 0
        width: parent.width
        height: Theme.barHeight
    }

    ViewHost {
        id: viewHost
        z: 3
        visible: !root.barLayout || root.panelOpen
        y: !root.barLayout ? 0 : undefined
        anchors.horizontalCenter: !root.barLayout ? parent.horizontalCenter : undefined
        anchors.centerIn: root.barLayout ? parent : undefined
        anchors.verticalCenterOffset: root.barLayout
            ? (root.bottomDock ? -Theme.barHeight / 2 : Theme.barHeight / 2)
            : 0
        // Content follows the panel slot when it docks to an edge.
        anchors.horizontalCenterOffset: root.barLayout
            ? root.panelX + viewHost.implicitWidth / 2 - root.width / 2
            : 0
    }

    // Transient toast for modes without their own StatusManager
    // indicator (control-center / media / power / theme /
    // wallpaper). Default mode swaps in OverlayView (or, in bar
    // layout, the centered OSD dropdown below the bar) and expanded
    // mode shows RightSection's StatusChip, so this covers the rest and
    // queued toasts are never invisible. Non-interactive (no
    // handlers, no focus) so modal FocusScope keyboard nav and
    // IslandInteraction clicks are unaffected, and it floats
    // without changing the capsule's implicit size.
    StatusChip {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10
        visible: !IslandState.layoutIsBar
            && StatusManager.visible
            && IslandState.mode !== IslandState.defaultMode
            && IslandState.mode !== IslandState.expandedMode
        icon: StatusManager.icon
        title: StatusManager.title
    }
}
