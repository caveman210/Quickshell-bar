import Quickshell
import Quickshell.Io

import "../core"
import "../services"

IpcHandler {
    target: "luci"

    function focusToggle() {
        FocusService.toggle()
    }

    function openPowerMenu() {
        IslandController.openPowerMenu()
    }

    function openExpandedHome() {
        IslandController.openExpanded()
    }

    function reset() {
        IslandController.reset()
    }

    function openWallpaperSelector() {
        IslandController.openWallpaperSelector()
    }

    function openThemeSelector() {
        IslandController.openThemeSelector()
    }
}
