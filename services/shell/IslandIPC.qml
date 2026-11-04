import Quickshell
import Quickshell.Io

import "../../core"
import "../../island"
import "../../services"

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

    function openControlCenter() {
        IslandController.openControlCenter()
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

    function openWifiMenu() {
        IslandController.openWifiMenu()
    }

    function openBluetoothMenu() {
        IslandController.openBluetoothMenu()
    }

    function openMedia() {
        IslandController.openMediaFromLeftSection()
    }

    function openNotifications() {
        IslandController.openNotifications()
    }

    function cycleLayout() {
        IslandController.cycleLayout()
    }

    function togglePlacement() {
        Placement.toggle()
        console.log("Placement now:", Placement.subtitle, "dockBottom:", IslandState.dockBottom)
    }

    function testOsd() {
        StatusManager.show({
            mode: "volume",
            icon: "󰕾",
            title: "Volume",
            value: 42
        })
    }
}
