pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string vpnName: ""
    readonly property bool connected: vpnName.length > 0
    property string icon: connected ? "󰌾" : "󰌿"

    function check() {
        checkProc.running = false
        checkProc.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Process {
        id: checkProc
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,NAME con show --active | awk -F: '($1==\"vpn\"||$1==\"wireguard\") && $2==\"activated\"{print $3; exit}'"]

        stdout: StdioCollector {
            id: outCol
            waitForEnd: true
            onStreamFinished: {
                root.vpnName = outCol.text.trim()
            }
        }
    }
}
