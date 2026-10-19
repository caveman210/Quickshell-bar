pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mounted disks and their usage, for the Control Center storage pane.
//
// Polls `lsblk --json` for the device list (no UDisks dependency for
// reading) and uses `udisksctl` (polkit-backed) to unmount/eject
// removable media.
Singleton {
    id: root

    // True after the first successful poll.
    property bool loaded: false

    // [{ name, path, label, model, fsType, mountpoint, size, used,
    //    free, usedPercent, removable }]
    property var devices: []

    readonly property int pollInterval: 10000

    function formatBytes(bytes) {
        var b = Number(bytes)

        if (!(b > 0))
            return ""

        var units = ["B", "K", "M", "G", "T", "P"]
        var i = 0

        while (b >= 1024 && i < units.length - 1) {
            b /= 1024
            i++
        }

        return (b >= 100 ? b.toFixed(0)
                         : b >= 10 ? b.toFixed(1)
                                   : b.toFixed(2)) + units[i]
    }

    function refresh() {
        lsblkProc.running = false
        lsblkProc.running = true
    }

    function eject(path) {
        ejectProc.command = [
            "sh", "-c",
            'dev="$1"\n' +
            'udisksctl unmount -b "$dev" || exit 1\n' +
            'disk=$(lsblk -no PKNAME "$dev" | head -n1)\n' +
            '[ -n "$disk" ] || exit 0\n' +
            'udisksctl power-off -b "/dev/$disk"',
            "_", path
        ]
        ejectProc.running = false
        ejectProc.running = true
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: lsblkProc
        command: ["lsblk", "--json", "-b", "-o",
                  "NAME,PATH,TYPE,RM,RO,SIZE,FSTYPE,LABEL,MOUNTPOINTS,FSUSE%,FSUSED,FSAVAIL,MODEL"]

        stdout: StdioCollector {
            id: lsblkOut
            waitForEnd: true
            onStreamFinished: root.parse(lsblkOut.text)
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("StorageService: lsblk exited with code", exitCode)
        }
    }

    function wanted(n) {
        if (n.type !== "part" && n.type !== "disk"
                && n.type !== "crypt" && n.type !== "lvm")
            return false

        var mps = n.mountpoints || []

        for (var i = 0; i < mps.length; i++) {
            if (mps[i] && mps[i][0] !== "[" && mps[i].indexOf("/") === 0)
                return true
        }

        return false
    }

    // Boot/ESP mounts are small and always present; the control
    // center leaves them out so the storage card and the system card
    // below it fit without scrolling.
    function isBootMount(mp) {
        return mp === "/boot" || mp.indexOf("/boot/") === 0
            || mp === "/efi" || mp.indexOf("/efi/") === 0
    }

    // A device can carry several mount paths (btrfs subvolumes); the
    // shortest one ("/home" over "/home/user/x") is the real mount.
    function shortestMount(n) {
        var mps = n.mountpoints || []
        var best = ""

        for (var i = 0; i < mps.length; i++) {
            var mp = mps[i]

            if (!mp || mp[0] === "[" || mp.indexOf("/") !== 0)
                continue

            if (best === "" || mp.length < best.length)
                best = mp
        }

        return best
    }

    function parse(text) {
        var data

        try {
            data = JSON.parse(String(text || ""))
        } catch (e) {
            console.warn("StorageService: bad lsblk output:", e)
            return
        }

        var out = []
        var seen = ({})

        function walk(nodes) {
            for (var i = 0; i < nodes.length; i++) {
                var n = nodes[i]

                if (root.wanted(n)) {
                    var mp = root.shortestMount(n)

                    if (mp !== "" && !root.isBootMount(mp) && !seen[mp]) {
                        seen[mp] = true

                        var used = Number(n.fsused) || 0
                        var free = Number(n.fsavail) || 0
                        var total = used + free
                        var pct = total > 0
                            ? (used / total) * 100
                            : (parseFloat(String(n["fsuse%"] || "0")) || 0)

                        out.push({
                            name: n.name,
                            path: n.path,
                            label: n.label || "",
                            model: n.model || "",
                            fsType: n.fstype || "",
                            mountpoint: mp,
                            size: Number(n.size) || 0,
                            used: used,
                            free: free,
                            usedPercent: Math.max(0, Math.min(100, pct)),
                            removable: n.rm === true
                        })
                    }
                }

                if (n.children && n.children.length > 0)
                    walk(n.children)
            }
        }

        walk(data.blockdevices || [])

        out.sort(function(a, b) {
            return a.mountpoint < b.mountpoint ? -1 : 1
        })

        root.devices = out
        root.loaded = true
    }

    Process {
        id: ejectProc

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("StorageService: eject failed with code", exitCode)

            refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }
}
