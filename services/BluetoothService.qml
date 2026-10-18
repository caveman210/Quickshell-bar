pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

import "../core"

Singleton {
    id: root

    // =========================================================
    // D-BUS SOURCE (BlueZ via Quickshell.Bluetooth)
    // =========================================================
    // Event-driven. No polling, no `bluetoothctl` Processes.
    // Battery comes from org.bluez.Battery1 via
    // BluetoothDevice.batteryAvailable / battery (0.0-1.0).

    readonly property var adapter: Bluetooth.defaultAdapter
    property bool enabled: adapter ? adapter.enabled : false

    readonly property var nativeDevices: Bluetooth.devices
        ? Bluetooth.devices.values
        : []

    // Bluetooth.devices lists connected devices; filter guards
    // against backends that also expose disconnected entries.
    readonly property var connectedDevices: nativeDevices.filter(function(dev) {
        return dev && dev.connected !== false
    })

    property int connectedCount: connectedDevices.length
    property bool connected: connectedCount > 0

    function displayName(dev) {
        if (!dev)
            return ""

        return String(dev.name || dev.deviceName || dev.address || "")
    }

    // Compat: first connected device (ControlCenter uses this).
    property string deviceName: connected
        ? displayName(connectedDevices[0])
        : ""

    property string subtitle: {
        if (connectedCount > 1)
            return connectedCount + " connected"

        if (connected)
            return deviceName

        return enabled ? "On" : "Off"
    }

    property string icon: !enabled
        ? "󰂲"
        : connected
            ? "󰂱"
            : "󰂯"

    // =========================================================
    // ISLAND POPUP STATE
    // =========================================================

    // Previous poll of connected addresses, used for set-diff.
    property var _prevAddrs: []
    // address -> last seen display name (disconnects vanish from
    // Bluetooth.devices, so the name must come from cache).
    property var _knownNames: ({})
    property bool _initialized: false
    property bool _prevEnabled: false

    // Connect grace: Battery1 often arrives just after
    // connected=true. Hold connects briefly so `(YY%)` can be
    // included; flush reads the live device object.
    property var _pendingAddrs: []
    property var _pendingNames: ({})

    // Settle-based init: Quickshell.Bluetooth enumerates BlueZ
    // async (adapters/devices appear seconds after load). Every
    // pre-init change pushes init out, so already-connected
    // devices never spam on boot/reload. Capped so init is
    // guaranteed.
    property int _initRestarts: 0

    Timer {
        id: initTimer
        interval: 4000
        repeat: false

        onTriggered: {
            root._prevAddrs = root._currentAddrs()
            root._prevEnabled = root.enabled
            root._initialized = true

            console.log(
                "Bluetooth initial state:",
                root.connectedCount > 0
                    ? root.connectedCount + " connected"
                    : (root.enabled ? "On" : "Off")
            )
        }
    }

    Timer {
        id: connectGraceTimer
        interval: 800
        repeat: false

        onTriggered: {
            root._flushPendingConnects()
        }
    }

    function _currentAddrs() {
        var out = []

        for (let i = 0; i < root.connectedDevices.length; ++i) {
            let dev = root.connectedDevices[i]

            if (dev && dev.address)
                out.push(String(dev.address))
        }

        return out
    }

    function _findDevice(addr) {
        for (let i = 0; i < root.connectedDevices.length; ++i) {
            let dev = root.connectedDevices[i]

            if (dev && String(dev.address) === addr)
                return dev
        }

        return null
    }

    function _batteryPct(dev) {
        if (!dev || !dev.batteryAvailable)
            return -1

        if (typeof dev.battery === "undefined" || dev.battery === null)
            return -1

        let pct = Math.round(Number(dev.battery) * 100)

        if (isNaN(pct) || pct < 0 || pct > 100)
            return -1

        return pct
    }

    function _cacheNames() {
        var cache = root._knownNames

        for (let i = 0; i < root.connectedDevices.length; ++i) {
            let dev = root.connectedDevices[i]

            if (dev && dev.address)
                cache[String(dev.address)] = displayName(dev)
        }

        // Reassign so QML var change propagates if ever bound.
        root._knownNames = cache
    }

    onNativeDevicesChanged: _handleDiff()
    onConnectedDevicesChanged: _handleDiff()
    onEnabledChanged: _handleDiff()

    function _handleDiff() {
        _cacheNames()

        let cur = _currentAddrs()
        let prev = root._prevAddrs

        // Pre-init: track enumeration without notifying so
        // already-connected devices at boot don't spam. Push
        // init out on every change (settle-based, capped).
        if (!root._initialized) {
            root._prevAddrs = cur
            root._prevEnabled = root.enabled

            if (root._initRestarts < 5) {
                root._initRestarts++
                initTimer.restart()
            }

            return
        }

        let added = cur.filter(function(a) {
            return prev.indexOf(a) === -1
        })

        let removed = prev.filter(function(a) {
            return cur.indexOf(a) === -1
        })

        // Adapter just powered off: all devices drop at once.
        // Snapshot silently instead of N disconnect prompts.
        if (root._prevEnabled && !root.enabled) {
            // Cancel any connects that never flushed.
            root._pendingAddrs = []
            root._pendingNames = {}
            connectGraceTimer.stop()

            root._prevAddrs = cur
            root._prevEnabled = root.enabled
            return
        }

        root._prevEnabled = root.enabled

        // While the adapter is off, never prompt for devices.
        if (!root.enabled) {
            root._pendingAddrs = []
            root._pendingNames = {}
            connectGraceTimer.stop()

            root._prevAddrs = cur
            return
        }

        // Fast connect->disconnect inside the grace window:
        // cancel the pending connect, show nothing.
        for (let i = 0; i < removed.length; ++i) {
            let addr = removed[i]
            let pi = root._pendingAddrs.indexOf(addr)

            if (pi !== -1) {
                root._pendingAddrs.splice(pi, 1)
                delete root._pendingNames[addr]
            } else {
                let name = root._knownNames[addr] || "device"

                console.log("Bluetooth disconnected:", name)

                StatusManager.showQueued({
                    mode: "device",
                    icon: "󰂨",
                    title: "Disconnected from " + name,
                    value: 0,
                    statusWidth: 0,
                    statusHeight: 33
                })
            }
        }

        for (let j = 0; j < added.length; ++j) {
            let addr = added[j]

            if (root._pendingAddrs.indexOf(addr) === -1) {
                root._pendingAddrs.push(addr)
                root._pendingNames[addr] = root._knownNames[addr]
                    || "device"
            }
        }

        if (root._pendingAddrs.length > 0)
            connectGraceTimer.restart()

        root._prevAddrs = cur
    }

    function _flushPendingConnects() {
        // Copy: disconnects during flush mutate the live arrays.
        let due = root._pendingAddrs.slice()

        root._pendingAddrs = []
        let names = root._pendingNames
        root._pendingNames = {}

        for (let i = 0; i < due.length; ++i) {
            let addr = due[i]
            let dev = _findDevice(addr)

            // Gone before grace expired: skip (disconnect path
            // already cancelled it, this is a safety net).
            if (!dev)
                continue

            let name = displayName(dev) || names[addr] || "device"
            let pct = _batteryPct(dev)
            let title = pct >= 0
                ? "Connected to " + name + " (" + pct + "%)"
                : "Connected to " + name

            console.log(
                "Bluetooth connected:",
                name,
                pct >= 0 ? pct + "%" : "no battery"
            )

            // One prompt per device; StatusManager drains them
            // sequentially so none overwrite another.
            StatusManager.showQueued({
                mode: "device",
                icon: "󰂯",
                title: title,
                value: 0,
                statusWidth: 0,
                statusHeight: 33
            })
        }
    }

    // =========================================================
    // CONTROLS (D-Bus, no bluetoothctl Process)
    // =========================================================

    function toggle() {
        if (!root.adapter) {
            console.log("Bluetooth toggle ignored: no adapter")
            return
        }

        root.adapter.enabled = !root.adapter.enabled
    }

    // Compat no-op: event-driven, nothing to poll. Kept so old
    // callers (ControlCenter, StatusWatcher) don't break.
    function update() {
    }

    Component.onCompleted: {
        console.log("BluetoothService loaded (BlueZ D-Bus backend)")
        _cacheNames()
        root._prevAddrs = _currentAddrs()
        root._prevEnabled = root.enabled
        initTimer.start()
    }
}
