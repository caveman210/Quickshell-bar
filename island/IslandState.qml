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
    readonly property int quoteMode: 11
    readonly property int systemMenuMode: 12
    readonly property int calendarMode: 13
    readonly property int settingsMode: 14
    readonly property int weatherMode: 15
    readonly property int nightLightMode: 16

    // =========================================================
    // LAYOUT
    // =========================================================

    readonly property int layoutPill: 0
    readonly property int layoutNotch: 1
    readonly property int layoutBar: 2

    // Pill is the default layout
    property int layout: layoutPill

    readonly property bool layoutIsBar: layout === layoutBar

    // Bar style: floating (margin around bar, rounded corners) or attached
    // (flush against screen edge, full width).
    property bool barFloating: true

    // Effective docking edge: the user's placement preference where the
    // current layout supports it. Only the bar docks to the bottom edge
    // so far; pill and notch stay top-only.
    readonly property bool dockBottom: layoutIsBar && Placement.bottom

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
    property bool trayOverflowOpen: false

    // Scene x of the icon center that opened it, so the menu lands
    // right below that icon.
    property real trayItemMenuAnchorX: 0

    // Tray dropdown state for pill / notch layouts
    property bool trayDropdownOpen: false

    onModeChanged: {
        if (mode !== defaultMode) {
            trayItemMenu = null
            trayOverflowOpen = false
            trayDropdownOpen = false
        }
    }

    onLayoutChanged: {
        trayItemMenu = null
        trayOverflowOpen = false
        trayDropdownOpen = false
    }

    // Centered card in the wallpaper carousel, kept across opens.
    property int wallpaperSelection: 0

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool modal:
        trayOverflowOpen ||
        trayDropdownOpen ||
        trayItemMenu !== null ||
        mode === powerMenuMode ||
        mode === themeSelectorMode ||
        mode === wallpaperSelectorMode ||
        mode === privacyMenuMode ||
        mode === wifiMenuMode ||
        mode === bluetoothMenuMode ||
        mode === notificationsMode ||
        mode === controlCenterMode ||
        mode === quoteMode ||
        mode === systemMenuMode ||
        mode === calendarMode ||
        mode === settingsMode ||
        mode === weatherMode ||
        mode === nightLightMode

    // Bar layout: a view drops down below the bar in the panel slot.
    readonly property bool barPanelOpen: layoutIsBar && mode !== defaultMode

    // A tray item's SNI menu drops down below its icon or the overflow tray.
    readonly property bool barTrayOpen: trayOverflowOpen || trayItemMenu !== null
}
