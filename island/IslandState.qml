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

    // =========================================================
    // SHAPE
    // =========================================================

    readonly property int shapePill: 0
    readonly property int shapeNotch: 1

    // In-memory only (like AutoHideService) — resets on reload.
    property int shape: shapePill

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode
    property bool islandPinned: false
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false
    property bool islandHovered: false

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool modal:
        mode === powerMenuMode ||
        mode === themeSelectorMode ||
        mode === wallpaperSelectorMode ||
        mode === privacyMenuMode
}
