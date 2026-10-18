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
        IslandState.mode =
            IslandState.defaultMode
    }
}
