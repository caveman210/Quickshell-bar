pragma Singleton

import QtQuick

QtObject {
    // =========================================================
    // MODES
    // =========================================================

    readonly property int defaultMode: 0
    readonly property int expandedMode: 1
    readonly property int powerMenuMode: 2
    readonly property int controlCenterMode: 3
    readonly property int themeSelectorMode: 4
    readonly property int wallpaperSelectorMode: 5
    readonly property int mediaControlsMode: 6
    readonly property int privacyMenuMode: 7
    readonly property int wifiMenuMode: 8
    readonly property int bluetoothMenuMode: 9
    readonly property int notificationsMode: 10

    // =========================================================
    // LAYOUT
    // =========================================================

    readonly property int layoutPill: 0
    readonly property int layoutNotch: 1
    readonly property int layoutBar: 2

    // In-memory only (like AutoHideService) — resets on reload.
    // The bar is the default; pill and notch are opt-in.
    property int layout: layoutBar

    readonly property bool layoutIsBar: layout === layoutBar

    readonly property string layoutName: {
        if (layout === layoutBar)
            return "Bar"
        if (layout === layoutNotch)
            return "Notch"
        return "Pill"
    }

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode
    property bool islandPinned: false
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false
    property bool islandHovered: false

    // Bar layout only: when set, the dropdown slot under the bar
    // renders this tray item's SNI menu (a QsMenuHandle). Mutually
    // exclusive with any non-default mode.
    property var trayItemMenu: null

    // Scene x of the icon center that opened it, so the menu lands
    // right below that icon.
    property real trayItemMenuAnchorX: 0

    onModeChanged: {
        if (mode !== defaultMode)
            trayItemMenu = null
    }

    onLayoutChanged: {
        trayItemMenu = null
    }

    // Centered card in the wallpaper carousel, kept across opens.
    property int wallpaperSelection: 0

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool modal:
        mode === powerMenuMode ||
        mode === themeSelectorMode ||
        mode === wallpaperSelectorMode ||
        mode === privacyMenuMode ||
        mode === wifiMenuMode ||
        mode === bluetoothMenuMode

    // Bar layout: a view drops down below the bar in the panel slot.
    readonly property bool barPanelOpen: layoutIsBar && mode !== defaultMode

    // Bar layout: a tray item's SNI menu drops down below its icon.
    readonly property bool barTrayOpen: layoutIsBar
        && trayItemMenu !== null
}
