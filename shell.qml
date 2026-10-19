import QtQuick
import Quickshell
import "windows"
import "services"
import "services/compositor"
import "services/connectivity"
import "services/notification"
import "services/power"
import "services/shell"

ShellRoot {
    StatusWatcher {}
    WorkspaceService {}
    KeyboardService {}

    IslandIPC {}

    IslandWindow {}
    EdgeTriggerWindow {}

    // Singletons are lazy; referencing them here instantiates them at
    // startup. NotificationService must exist immediately so its
    // NotificationServer registers on the session bus before any
    // notification arrives. The device services must exist from
    // startup too: island connect/disconnect prompts and the
    // low-battery warning (visibility-gated in DefaultView) are
    // event-driven, so they have to observe transitions from boot.
    readonly property var _startupServices: [
        NotificationService,
        WifiService,
        BluetoothService,
        LowBatteryService
    ]
}

