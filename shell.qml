import QtQuick
import Quickshell
import "windows"
import "services"

ShellRoot {
    StatusWatcher {}
    WorkspaceService {}
    KeyboardService {}

    IslandIPC {}

    IslandWindow {}
    EdgeTriggerWindow {}

    Component.onCompleted: {
        // Force the NotificationService singleton to instantiate at
        // startup so its NotificationServer registers on the session
        // bus immediately. Singletons are lazy — without this,
        // notifications sent before first opening the Control Center
        // would never reach the shell.
        NotificationService.markRead()

        // Same for the device services: island connect/disconnect
        // prompts are event-driven, so the singletons must exist
        // from startup to observe transitions. update() is a
        // compat no-op; the call itself forces instantiation.
        WifiService.update()
        BluetoothService.update()

        // Low-battery warning on the default bar is visibility-gated
        // (DefaultView binds to LowBatteryService.active), so force
        // instantiation here to keep polling even while the island
        // shows another view. update() triggers a refresh.
        LowBatteryService.update()
    }
}
