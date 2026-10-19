pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Minimal fastfetch data for the Control Center system pane.
//
// fastfetch is the single source of truth: `--format json` gives the
// fields, and `--structure none` gives the distro logo exactly as
// fastfetch draws it. Keeping both in fastfetch means the pane stays
// correct on other machines/distros without a hand-maintained table.
//
// Results are cached to disk so the pane costs nothing to open. The
// cache is refreshed at most once a week, or on demand via the pane's
// refresh button.
Singleton {
    id: root

    // True once we have any data, cached or freshly fetched.
    property bool loaded: false

    // { os, kernel, wm, cpu, gpu, memory } — empty strings until loaded.
    property var details: ({})

    // Raw ASCII/Unicode-block logo from fastfetch, trailing spaces
    // stripped per line (leading spaces are part of the drawing).
    property string logo: ""

    // /etc/os-release ID, used to pick the Nerd Font distro glyph.
    property string osId: ""

    // Epoch milliseconds of the last successful fetch.
    property double updatedAt: 0

    // A fetch is in flight (the refresh button shows a busy label).
    property bool refreshing: false

    readonly property string osIcon: root.iconFor(root.osId)

    readonly property bool available: root.loaded

    // One week.
    readonly property double maxAge: 7 * 24 * 60 * 60 * 1000

    readonly property string cachePath: Quickshell.cacheDir + "/system-info.json"

    // --- internal run bookkeeping ---
    property int _pending: 0
    property bool _gotDetails: false
    property bool _gotLogo: false

    // Ensure the cache directory exists before the first write on a
    // fresh install.
    Process {
        command: ["mkdir", "-p", Quickshell.cacheDir]
        Component.onCompleted: running = true
    }

    // Read the cache once at startup. A missing file just yields empty
    // text, which falls through to a fetch.
    Process {
        id: cacheReadProc
        running: true
        command: ["cat", root.cachePath]

        stdout: StdioCollector {
            id: cacheOut
            waitForEnd: true

            onStreamFinished: root.loadCache(cacheOut.text)
        }
    }

    // Use the cache if it is present and fresh. Otherwise show whatever
    // is cached (if anything) and kick off a fetch in the background.
    function loadCache(text) {
        var data = null

        try {
            data = JSON.parse(String(text || ""))
        } catch (e) {
            data = null
        }

        if (!data || !data.details) {
            root.refresh(true)
            return
        }

        root.details = data.details
        root.logo = data.logo || ""
        root.osId = data.osId || ""
        root.updatedAt = Number(data.updated) || 0
        root.loaded = true

        if (!root.logo || Date.now() - root.updatedAt > root.maxAge)
            root.refresh(true)
    }

    // Kicked off when the pane's refresh button is pressed.
    function refreshNow() {
        root.refresh(true)
    }

    // force: refetch even if the cache is still fresh. Without it the
    // call is a no-op unless the cache is missing or stale.
    function refresh(force) {
        if (force !== true && root.loaded
                && Date.now() - root.updatedAt <= root.maxAge)
            return

        if (detailsProc.running || logoProc.running)
            return

        root._pending = 2
        root._gotDetails = false
        root._gotLogo = false
        root.refreshing = true
        detailsProc.running = true
        logoProc.running = true
    }

    function _runFinished() {
        root._pending = Math.max(0, root._pending - 1)

        if (root._pending > 0)
            return

        root.refreshing = false

        if (root._gotDetails)
            root.save()
    }

    function save() {
        root.updatedAt = Date.now()
        root.loaded = true

        var json = JSON.stringify({
            updated: root.updatedAt,
            osId: root.osId,
            details: root.details,
            logo: root.logo
        })

        // printf keeps the JSON verbatim; passing it as an argv entry
        // (never re-parsed by the shell) avoids any quoting issues.
        cacheWriteProc.command = [
            "sh", "-c", 'printf %s "$1" > "$2"', "sh", json, root.cachePath
        ]
        cacheWriteProc.running = true
    }

    Process {
        id: cacheWriteProc

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("SystemService: failed to write cache")
        }
    }

    // Distro glyphs from the Nerd Font "linux" range. Fall back to
    // Tux for anything we don't map.
    function iconFor(id) {
        switch (String(id || "").toLowerCase()) {
        case "nixos":
            return "\uf313"
        case "arch":
        case "archarm":
        case "endeavouros":
        case "manjaro":
        case "cachyos":
            return "\uf303"
        case "debian":
            return "\uf306"
        case "ubuntu":
        case "pop":
        case "linuxmint":
            return "\uf31b"
        case "fedora":
        case "nobara":
            return "\uf30a"
        case "gentoo":
            return "\uf30c"
        case "opensuse":
        case "opensuse-tumbleweed":
        case "opensuse-leap":
            return "\uf314"
        case "void":
            return "\uf32e"
        default:
            return "\uf17c"
        }
    }

    function gib(bytes) {
        var b = Number(bytes)

        if (!(b > 0))
            return ""

        return (b / 1073741824).toFixed(2)
    }

    function ghz(mhz) {
        var m = Number(mhz)

        if (!(m > 0))
            return ""

        return (m / 1000).toFixed(2) + " GHz"
    }

    function parseDetails(text) {
        var data

        try {
            data = JSON.parse(String(text || ""))
        } catch (e) {
            console.warn("SystemService: bad fastfetch JSON:", e)
            return
        }

        if (!Array.isArray(data))
            return

        var out = {
            os: "",
            kernel: "",
            wm: "",
            cpu: "",
            gpu: "",
            memory: ""
        }

        for (var i = 0; i < data.length; i++) {
            var entry = data[i]
            var r = entry ? entry.result : null

            if (!r)
                continue

            switch (entry.type) {
            case "OS":
                out.os = r.prettyName || r.name || ""
                root.osId = String(r.id || "").toLowerCase()
                break

            case "Kernel":
                out.kernel = ((r.name || "") + " " + (r.release || "")).trim()
                break

            case "WM":
                out.wm = r.prettyName || r.processName || ""

                if (r.version)
                    out.wm += " " + r.version

                if (r.protocolName)
                    out.wm += " (" + r.protocolName + ")"

                break

            case "CPU":
                out.cpu = r.cpu || ""

                if (r.cores && r.cores.logical > 0)
                    out.cpu += " (" + r.cores.logical + ")"

                if (r.frequency && r.frequency.max > 0)
                    out.cpu += " @ " + root.ghz(r.frequency.max)

                break

            case "GPU":
                if (Array.isArray(r) && r.length > 0) {
                    var gpu = r[0]

                    out.gpu = gpu.name || ""

                    if (gpu.type)
                        out.gpu += " [" + gpu.type + "]"
                }
                break

            case "Memory":
                var used = root.gib(r.used)
                var total = root.gib(r.total)

                if (total !== "") {
                    out.memory = used !== ""
                        ? used + " GiB / " + total + " GiB"
                        : total + " GiB"

                    if (r.total > 0) {
                        out.memory += " ("
                            + Math.round((r.used / r.total) * 100)
                            + "%)"
                    }
                }
                break
            }
        }

        root.details = out
        root._gotDetails = true
        root._runFinished()
    }

    function cleanLogo(text) {
        return String(text || "")
            .replace(/\r/g, "")
            .replace(/[ \t]+$/gm, "")
            .replace(/\n+$/, "")
    }

    function parseLogo(text) {
        var art = root.cleanLogo(text)

        if (art !== "") {
            root.logo = art
            root._gotLogo = true
        }

        root._runFinished()
    }

    Process {
        id: detailsProc

        command: [
            "fastfetch",
            "--format", "json",
            "--structure", "os:kernel:wm:cpu:gpu:memory"
        ]

        stdout: StdioCollector {
            id: detailsOut
            waitForEnd: true

            onStreamFinished: root.parseDetails(detailsOut.text)
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("SystemService: fastfetch exited with code", exitCode)
        }
    }

    Process {
        id: logoProc

        // No modules: only the distro logo is printed. fastfetch picks
        // the distro itself, so this works on any machine.
        command: ["fastfetch", "--structure", "none"]

        stdout: StdioCollector {
            id: logoOut
            waitForEnd: true

            onStreamFinished: root.parseLogo(logoOut.text)
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("SystemService: fastfetch logo exited with code", exitCode)
        }
    }

    // Weekly background refresh so long-lived shells don't show
    // months-old numbers.
    Timer {
        interval: 7 * 24 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh(true)
    }
}
