pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

import "../core"

Singleton {
    id: root

    // =========================================================
    // D-BUS SOURCE (NetworkManager via Quickshell.Networking)
    // =========================================================
    // Event-driven. No polling, no `nmcli dev wifi` scans.
    // Quickshell.Networking uses org.freedesktop.NetworkManager
    // over D-Bus and emits change signals - this is what fixes
    // the phantom connect/disconnect flapping caused by the old
    // 5s `nmcli dev wifi | grep '^yes:'` poller (empty scan
    // results were misread as disconnects, and forced rescans
    // every 5s destabilise some drivers).

    readonly property var wifiDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; ++i) {
            if (devs[i].type === DeviceType.Wifi)
                return devs[i];
        }
        return null;
    }

    readonly property var activeNetwork: {
        if (!wifiDevice)
            return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; ++i) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    // Public state - kept API-compatible with the old service.
    property bool enabled: Networking.wifiEnabled
    property bool available: wifiDevice !== null
    property bool connected: enabled && activeNetwork !== null && activeNetwork.connected
    property bool connecting: !connected && enabled && wifiDevice !== null
        && wifiDevice.state === ConnectionState.Connecting
    property int strength: (connected && activeNetwork && typeof activeNetwork.signalStrength !== "undefined")
        ? Math.round(activeNetwork.signalStrength * 100)
        : 0
    property string ssid: (connected && activeNetwork) ? activeNetwork.name : ""
    property string icon: {
        if (!connected)
            return "󰤮";
        if (strength >= 80)
            return "󰤨";
        if (strength >= 60)
            return "󰤥";
        if (strength >= 40)
            return "󰤢";
        if (strength >= 20)
            return "󰤟";
        return "󰤯";
    }
    property string subtitle:
        connected
            ? ssid
            : (connecting
                ? "Connecting..."
                : "Disconnected")

    // =========================================================
    // ISLAND STATE (transient only, no notification history)
    // =========================================================

    // Used so Luci doesn't show an island prompt when
    // the service first starts and reads the current state.
    property bool initialized: false
    property bool previousConnected: false
    property string previousSsid: ""

    // Connects arrive in D-Bus stages (connected=true before the
    // network name/signal settle), which used to produce two
    // prompts: "Connected to " then "Connected to xxxx". Hold
    // connects briefly so name + strength settle, then show once
    // with the live strength icon.
    property bool _pendingConnect: false

    Timer {
        id: connectGraceTimer
        interval: 600
        repeat: false

        onTriggered: {
            root._flushPendingConnect()
        }
    }

    // Strength-tier icon snapshot at flush time. Falls back to
    // full bars when connected but strength hasn't arrived yet,
    // so connects never show the wifi-off glyph.
    function signalIcon() {
        if (!root.connected)
            return "󰤮"

        if (root.strength >= 80)
            return "󰤨"

        if (root.strength >= 60)
            return "󰤥"

        if (root.strength >= 40)
            return "󰤢"

        if (root.strength >= 20)
            return "󰤟"

        if (root.strength > 0)
            return "󰤯"

        return "󰤨"
    }

    function _flushPendingConnect() {
        if (!root._pendingConnect)
            return

        root._pendingConnect = false

        if (!root.connected || root.ssid === "")
            return

        console.log(
            "Wi-Fi connected:",
            root.ssid,
            root.strength + "%"
        )

        StatusManager.showQueued({
            mode: "device",
            icon: root.signalIcon(),
            title: "Connected to " + root.ssid,
            value: 0,
            statusWidth: 0,
            statusHeight: 33
        })
    }

    // React to D-Bus driven changes only. Strength-only
    // changes never notify - only connected/ssid transitions.
    onConnectedChanged: handleStateChange()
    onSsidChanged: handleStateChange()

    // =========================================================
    // STATE CHANGE DETECTION
    // =========================================================

    function isStable() {
        // D-Bus enumerates in stages (devices -> network -> name).
        // Don't snapshot half-loaded state as "initial", otherwise
        // the follow-up name load looks like a network change.
        if (root.wifiDevice === null)
            return false;
        if (Networking.devices.values.length === 0)
            return false;
        if (root.connected && root.ssid === "")
            return false;
        return true;
    }

    function handleStateChange() {
        // First stable reading after Luci starts.
        // Don't send a notification.
        // NOTE: Networking.devices populates async (~2s) - the first
        // D-Bus sync is treated as init so we never spam on boot/reload.
        if (!root.initialized) {
            if (!isStable())
                return;

            root.previousConnected =
                root.connected

            root.previousSsid =
                root.ssid

            root.initialized = true

            console.log(
                "Wi-Fi initial state:",
                root.connected
                    ? root.ssid
                    : "Disconnected"
            )

            return
        }

        // -------------------------------------------------
        // Connected → Disconnected (immediate, cancels any
        // pending connect from a fast flap)
        // -------------------------------------------------

        if (
            root.previousConnected &&
            !root.connected
        ) {
            root._pendingConnect = false
            connectGraceTimer.stop()

            let lastSsid = root.previousSsid !== ""
                ? root.previousSsid
                : "Wi-Fi"

            console.log(
                "Wi-Fi disconnected from:",
                lastSsid
            )

            StatusManager.showQueued({
                mode: "device",
                icon: "󰤮",
                title: "Disconnected from " + lastSsid,
                value: 0,
                statusWidth: 0,
                statusHeight: 33
            })
        }

        // -------------------------------------------------
        // Disconnected → Connected, or roam to a different
        // network: debounce through the grace timer so the
        // staged D-Bus updates (connected=true, then name,
        // then strength) collapse into ONE prompt with the
        // live strength icon. Empty-SSID stages are skipped
        // without saving, so the later name arrival still
        // counts as the connect event.
        // -------------------------------------------------

        else if (root.connected && root.ssid === "") {
            return
        }

        else if (
            (!root.previousConnected && root.connected)
            || (root.previousConnected
                && root.connected
                && root.previousSsid !== root.ssid)
        ) {
            root._pendingConnect = true
            connectGraceTimer.restart()
        }

        // -------------------------------------------------
        // Save current state
        // -------------------------------------------------

        root.previousConnected =
            root.connected

        root.previousSsid =
            root.ssid
    }

    // =========================================================
    // UPDATE (compat no-op)
    // =========================================================
    // Kept so old callers don't break. D-Bus is event-driven,
    // there is nothing to poll.

    function update() {
    }

    // =========================================================
    // TOGGLE WIFI (D-Bus rfkill, no nmcli Process)
    // =========================================================

    function toggle() {
        if (!Networking.wifiHardwareEnabled) {
            console.log("Wi-Fi toggle ignored: hardware blocked (rfkill)");
            return;
        }
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // =========================================================
    // STARTUP
    // =========================================================

    Component.onCompleted: {
        console.log(
            "WifiService loaded (D-Bus backend:",
            Networking.backend,
            ")"
        )

        // Sync initial state without notifying, but only if D-Bus
        // has already settled. Otherwise onConnected/onSsid
        // handlers will init on the first stable D-Bus event.
        if (isStable()) {
            root.previousConnected = root.connected;
            root.previousSsid = root.ssid;
            root.initialized = true;
            console.log(
                "Wi-Fi initial state:",
                root.connected ? root.ssid : "Disconnected"
            );
        }
    }
}
