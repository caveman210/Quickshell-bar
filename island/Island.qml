import QtQuick

import "../styles"
import "../core"
import "../components/bar"
import "../components/sections"
import "../views/bar"
import "../views/shared"

Rectangle {
    id: root
    clip: true

    readonly property bool notch: IslandState.layout === IslandState.layoutNotch

    // Bar layout: a floating full-width bar; views drop down into a
    // centered panel slot below it (or the tray app list, right
    // aligned under its button).
    readonly property bool barLayout: IslandState.layoutIsBar
    readonly property bool panelOpen: IslandState.barPanelOpen
    readonly property bool trayOpen: IslandState.barTrayOpen

    // Geometry of the dropdown surfaces, read by IslandWindow to
    // build the window input mask (union of bar + open surface).
    readonly property real panelWidth: panelOpen ? viewHost.implicitWidth : 0
    readonly property real panelHeight: panelOpen ? viewHost.implicitHeight : 0
    readonly property real trayWidth: trayOpen && trayMenu ? trayMenu.implicitWidth : 0
    readonly property real trayHeight: trayOpen && trayMenu ? trayMenu.implicitHeight : 0

    // Centered under the tray icon that opened the menu, clamped
    // inside the bar with the same corner gap the docked panes keep,
    // so its edges get the flow treatment even when it lands against
    // a bar end.
    readonly property real trayX: {
        if (!barView || root.width <= 0)
            return 0

        var x = IslandState.trayItemMenuAnchorX - root.x - root.trayWidth / 2
        return Math.max(root.panelDockGap,
                        Math.min(x, root.width - root.trayWidth - root.panelDockGap))
    }

    // Panels that dock to a screen edge instead of the centered
    // dropdown slot. In the bar the media line, the control center,
    // its submenus (wifi / bluetooth / theme / wallpaper) dock to the
    // left under the bar's own controls; the privacy pane docks to
    // the right, under the privacy cluster that opens it. The
    // notifications pane and the clock dropdown drop down centered,
    // like the OSD.
    // Docked panes keep a gap to the island edge wide enough that
    // the flow-corner arc lands on the bar's straight bottom edge,
    // clear of its rounded corner, so the fillets can join them.
    readonly property real panelDockGap: Theme.radiusLarge + Theme.capsuleRadius
    readonly property bool panelLeft: barLayout
        && (IslandState.mode === IslandState.mediaControlsMode
            || IslandState.mode === IslandState.controlCenterMode
            || IslandState.mode === IslandState.wifiMenuMode
            || IslandState.mode === IslandState.bluetoothMenuMode
            || IslandState.mode === IslandState.themeSelectorMode
            || IslandState.mode === IslandState.wallpaperSelectorMode)
    readonly property bool panelRight: barLayout
        && IslandState.mode === IslandState.privacyMenuMode
    readonly property real panelX: !barLayout
        ? 0
        : panelLeft
            ? panelDockGap
            : panelRight
                ? width - panelWidth - panelDockGap
                : (width - panelWidth) / 2

    // Transient OSD dropdown: in the bar the status toast (volume,
    // brightness, workspace, device prompts) drops down centered
    // under the clock instead of replacing it, and stays hidden
    // while another bar dropdown is open — those carry their own
    // feedback.
    readonly property bool osdOpen: barLayout && StatusManager.visible
        && !panelOpen && !trayOpen
    readonly property real osdWidth: osdView.implicitWidth
    readonly property real osdHeight: osdView.implicitHeight
    readonly property real osdX: (width - osdWidth) / 2

    topLeftRadius: barLayout || notch ? 0 : Theme.capsuleRadius
    topRightRadius: barLayout || notch ? 0 : Theme.capsuleRadius
    bottomLeftRadius: Theme.capsuleRadius
    bottomRightRadius: Theme.capsuleRadius
    color: barLayout ? "transparent" : Theme.background
    width: implicitWidth
    height: implicitHeight
    implicitWidth: barLayout
        ? (parent ? Math.max(0, parent.width - 2 * Theme.barSideMargin) : 0)
        : viewHost.implicitWidth
    implicitHeight: barLayout
        ? Theme.barHeight + (trayOpen
            ? trayHeight
            : panelOpen
                ? panelHeight
                : osdOpen ? osdHeight : 0)
        : viewHost.implicitHeight

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

    // ---------------------------------------------------------
    // BAR LAYOUT SURFACES
    // ---------------------------------------------------------

    Rectangle {
        id: barSurface
        visible: root.barLayout
        x: 0
        y: 0
        width: root.width
        height: Theme.barHeight
        // Top corners match the flow-corner fillets so the two
        // curves join tangent at the bar's side edges.
        topLeftRadius: Theme.radiusLarge
        topRightRadius: Theme.radiusLarge
        bottomLeftRadius: Theme.capsuleRadius
        bottomRightRadius: Theme.capsuleRadius
        color: Theme.background
    }

    // View dropdown: flush under the bar, flat top, rounded bottom —
    // reads as the bar itself dropping down. Docked panes keep a
    // fillet-sized gap to the island edge so the flow corners join
    // their outer sides too.
    Rectangle {
        id: panelSurface
        visible: root.barLayout && root.panelOpen
        x: root.panelX
        y: Theme.barHeight
        width: viewHost.implicitWidth
        height: viewHost.implicitHeight
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.capsuleRadius
        bottomRightRadius: Theme.capsuleRadius
        color: Theme.background
    }

    // OSD dropdown: same slab treatment, centered under the clock.
    Rectangle {
        id: osdSurface
        visible: root.osdOpen
        x: root.osdX
        y: Theme.barHeight
        width: root.osdWidth
        height: root.osdHeight
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.capsuleRadius
        bottomRightRadius: Theme.capsuleRadius
        color: Theme.background
    }

    OverlayView {
        id: osdView
        visible: root.osdOpen
        x: root.osdX
        y: Theme.barHeight
    }

    // Concave fillets where every bar dropdown (view panel, tray
    // list) meets the bar's bottom edge, sweeping down into the
    // dropdown's side edges. A side needs the full dock gap to the
    // island edge so its arc lands on the bar's straight bottom
    // edge, clear of the rounded corner.
    FlowCorner {
        visible: root.barLayout && root.panelOpen && root.panelWidth > 0
            && root.panelX >= root.panelDockGap
        x: root.panelX - Theme.radiusLarge
        y: Theme.barHeight
    }

    FlowCorner {
        visible: root.barLayout && root.panelOpen && root.panelWidth > 0
            && root.panelX + root.panelWidth <= root.width - root.panelDockGap
        x: root.panelX + root.panelWidth
        y: Theme.barHeight
        mirror: true
    }

    FlowCorner {
        visible: root.barLayout && root.trayOpen && root.trayWidth > 0
            && root.trayX >= root.panelDockGap
        x: root.trayX - Theme.radiusLarge
        y: Theme.barHeight
    }

    FlowCorner {
        visible: root.barLayout && root.trayOpen && root.trayWidth > 0
            && root.trayX + root.trayWidth <= root.width - root.panelDockGap
        x: root.trayX + root.trayWidth
        y: Theme.barHeight
        mirror: true
    }

    FlowCorner {
        visible: root.barLayout && root.osdOpen && root.osdWidth > 0
            && root.osdX >= root.panelDockGap
        x: root.osdX - Theme.radiusLarge
        y: Theme.barHeight
    }

    FlowCorner {
        visible: root.barLayout && root.osdOpen && root.osdWidth > 0
            && root.osdX + root.osdWidth <= root.width - root.panelDockGap
        x: root.osdX + root.osdWidth
        y: Theme.barHeight
        mirror: true
    }

    // ---------------------------------------------------------
    // CAPSULE (pill / notch layouts) + DROPDOWN CONTENT (bar)
    // ---------------------------------------------------------

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

    // Bar content sits above IslandInteraction so its own handlers
    // (clock toggle, wifi/bt/battery -> control center, tray rows)
    // win over the full-capsule click catcher; empty bar areas still
    // fall through to it.
    // SNI menu slab: same treatment as the view panel and the OSD
    // dropdown, dropping right below the icon that opened it.
    Rectangle {
        id: traySurface
        visible: root.barLayout && root.trayOpen
        x: root.trayX
        y: Theme.barHeight
        width: root.trayWidth
        height: root.trayHeight
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.capsuleRadius
        bottomRightRadius: Theme.capsuleRadius
        color: Theme.background
    }

    TrayItemMenu {
        id: trayMenu
        visible: root.barLayout && root.trayOpen
        x: root.trayX
        y: Theme.barHeight
    }

    BarView {
        id: barView
        visible: root.barLayout
        x: 0
        y: 0
        width: parent.width
        height: Theme.barHeight
    }

    ViewHost {
        id: viewHost
        visible: !root.barLayout || root.panelOpen
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.barLayout ? Theme.barHeight / 2 : 0
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
