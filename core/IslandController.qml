pragma Singleton

import QtQuick

import "../island"

QtObject {
    id: root

    // =========================================================
    // NAVIGATION
    // Open a specific island view/mode.
    // =========================================================

    function openDefault() {
        IslandState.mode =
            IslandState.defaultMode
    }

    function openCalendar() {
        IslandState.mode = IslandState.calendarMode
    }

    function openExpanded() {
        IslandState.mode =
            IslandState.expandedMode
    }

    function openPowerMenu() {
        IslandState.mode =
            IslandState.powerMenuMode
    }

    function openControlCenter() {
        IslandState.mode =
            IslandState.controlCenterMode
    }

    function openThemeSelector() {
        IslandState.mode =
            IslandState.themeSelectorMode
    }

    function openWallpaperSelector() {
        IslandState.mode =
            IslandState.wallpaperSelectorMode
    }

    function openPrivacyMenu() {
        IslandState.mode =
            IslandState.privacyMenuMode
    }

    function openWifiMenu() {
        IslandState.mode =
            IslandState.wifiMenuMode
    }

    function openBluetoothMenu() {
        IslandState.mode =
            IslandState.bluetoothMenuMode
    }

    function openWeather() {
        IslandState.mode = IslandState.weatherMode
    }

    function openSettings() {
        IslandState.mode = IslandState.settingsMode
    }

    function openNightLight() {
        IslandState.mode = IslandState.nightLightMode
    }

    function openSystemMenu() {
        IslandState.mode =
            IslandState.systemMenuMode
    }

    function openMediaControls() {
        ignoreNextIslandTap()

        IslandState.islandPinned = true

        IslandState.mode =
            IslandState.mediaControlsMode
    }

    // =========================================================
    // CONTEXTUAL NAVIGATION
    // Open views from specific parts of the island while
    // preserving the current interaction state.
    // =========================================================

    function openMediaFromLeftSection() {
        ignoreNextIslandTap()

        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        IslandState.mode =
            IslandState.mediaControlsMode
    }

    function openControlCenterFromRightSection() {
        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        IslandState.mode =
            IslandState.controlCenterMode
    }

    function openPrivacyMenuFromRightSection() {
        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        IslandState.mode =
            IslandState.privacyMenuMode
    }

    function openNotifications() {
        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        IslandState.mode =
            IslandState.notificationsMode
    }

    function openQuote() {
        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        IslandState.mode =
            IslandState.quoteMode
    }

    // =========================================================
    // TRAY (bar layout)
    // =========================================================

    function openTrayOverflow(anchorX) {
        closeTrayItemMenu()
        IslandState.trayOverflowOpen = true
        IslandState.trayItemMenuAnchorX = anchorX || 0
        IslandState.returnToExpanded = false
        IslandState.islandPinned = false
        IslandState.mode = IslandState.defaultMode
    }

    function toggleTrayOverflow(anchorX) {
        if (IslandState.trayOverflowOpen || IslandState.trayItemMenu !== null) {
            closeTrayItemMenu()
        } else {
            openTrayOverflow(anchorX)
        }
    }
    // handle is normalized to the root menu item, which is what
    // QsMenuOpener consumes directly. anchorX is the icon's center in
    // scene coordinates so the dropdown can align right under it.
    function openTrayItemMenu(menu, anchorX) {
        if (!menu)
            return

        var overflowWasOpen = IslandState.trayOverflowOpen
        var overflowAnchorX = IslandState.trayItemMenuAnchorX
        closeTrayItemMenu()

        IslandState.trayItemMenu =
            menu.menu !== undefined && menu.menu !== null
                ? menu.menu
                : menu

        IslandState.trayItemMenuAnchorX = anchorX || overflowAnchorX || 0
        IslandState.trayOverflowOpen = overflowWasOpen
        IslandState.returnToExpanded = false
        IslandState.islandPinned = false
        IslandState.mode = IslandState.defaultMode
    }

    function closeTrayItemMenu() {
        var menu = IslandState.trayItemMenu

        if (menu && menu.sendClosed)
            menu.sendClosed()

        IslandState.trayItemMenu = null
        IslandState.trayOverflowOpen = false
    }

    // =========================================================
    // LAYOUT
    // Cycle pill → notch → bar (handy for testing via IPC).
    // =========================================================

    function cycleLayout() {
        IslandState.layout =
            (IslandState.layout + 1) % 3

        console.log("Layout now:", IslandState.layout, IslandState.layoutName, "dockBottom:", IslandState.dockBottom)
    }

    // =========================================================
    // INTERACTION
    // Small state changes caused by direct island interaction.
    // =========================================================

    function ignoreNextIslandTap() {
        IslandState.ignoreNextIslandTap = true

        Qt.callLater(function() {
            IslandState.ignoreNextIslandTap = false
        })
    }

    function clearIgnoredTap() {
        IslandState.ignoreNextIslandTap = false
    }

    function togglePin() {
        IslandState.islandPinned =
            !IslandState.islandPinned
    }

    function restoreExpanded() {
        IslandState.islandPinned = true
        IslandState.returnToExpanded = false

        openExpanded()
    }

    // =========================================================
    // RESET
    // Return the island to its normal initial state.
    // =========================================================

    function reset() {
        IslandState.ignoreNextIslandTap = false
        IslandState.returnToExpanded = false
        IslandState.islandPinned = false
        IslandState.trayDropdownOpen = false
        closeTrayItemMenu()
        IslandState.mode =
            IslandState.defaultMode
    }
}
