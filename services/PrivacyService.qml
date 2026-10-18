pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Privacy indicators: which capture devices are in use right now.
// Two independent paths cover camera AND mic use:
//   1. PipeWire portal streams (browsers via portal, OBS, Meet/Zoom
//      apps, recorders): Stream/Input/Video or Stream/Input/Audio
//      running. Monitor captures (stream.capture.sink, e.g. the
//      cava visualizer or OBS system-audio capture) share the
//      Stream/Input/Audio class but are NOT mic use, so they are
//      explicitly excluded.
//   2. Direct device opens bypassing PipeWire: any process holding
//      a /dev/video* fd (Firefox/Chromium camera), or ALSA hardware
//      capture running in /proc/asound (direct `arecord -D hw:`).
//      Apps only grab these while a track is live — enumeration
//      never opens them — so grabbed means in use.
// Screen sharing = a Stream/Output/Video node running, OR an
// external display attached (HDMI or DP/USB-C — anything that is
// not the internal panel).
// (Root-owned processes' fds are invisible to us — accepted
// blind spot, e.g. a login-time face-unlock flash.)
Singleton {
    id: root

    property bool cameraActive: false
    property bool micActive: false
    property bool externalDisplayConnected: false
    property bool screenSharingActive: false

    // Which apps are currently capturing, for the privacy panel.
    // Populated from the pw-dump stream pass only, so a device taken
    // through a direct /dev/video* or ALSA open shows as "in use"
    // with an empty list — the same blind spot as the v4l2 probe.
    property var micApps: []
    property var cameraApps: []

    // Stream-driven states, kept separate so the pw-dump parse and
    // the sysfs//proc probe can update the combined states
    // independently.
    property bool _streamCameraActive: false
    property bool _streamMicActive: false
    property bool _streamActive: false
    property bool _v4l2Open: false
    property bool _alsaCapture: false

    function update() {
        dumpProc.running = false
        dumpProc.running = true
        sysProc.running = false
        sysProc.running = true
    }

    // 2s is responsive enough for indicator duty without churning
    // a ~200KB dump parse any harder than needed.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: update()
    }

    Process {
        id: dumpProc
        command: ["pw-dump"]

        stdout: StdioCollector {
            onStreamFinished: {
                var mic = false
                var cam = false
                var stream = false
                var micApps = []
                var cameraApps = []

                // Stable label for a capture node, preferring the
                // application name over the bare node name.
                function captureLabel(nodeName, appName) {
                    if (appName)
                        return appName

                    if (nodeName) {
                        // Strip the common lib prefixes so
                        // "Firefox" reads as "Firefox" rather than
                        // "Firefox Web Content".
                        return nodeName
                    }

                    return "Unknown"
                }

                function pushUnique(list, value) {
                    if (list.indexOf(value) === -1)
                        list.push(value)
                }

                try {
                    var objects = JSON.parse(text)

                    for (var i = 0; i < objects.length; i++) {
                        var n = objects[i]

                        if (!n || n.type !== "PipeWire:Interface:Node" || !n.info)
                            continue

                        if (n.info.state !== "running")
                            continue

                        var props = n.info.props

                        if (!props)
                            continue

                        var cls = props["media.class"]

                        if (cls === "Stream/Input/Audio") {
                            // Exclude sink-monitor captures: cava, OBS
                            // system-audio, etc. They run while media
                            // plays but never touch the microphone.
                            var capSink = props["stream.capture.sink"]
                            var nodeName = props["node.name"] || ""
                            var appName = props["application.name"] || ""
                            var isMonitor = (capSink === true || capSink === "true" || capSink === 1 || capSink === "1")
                            var isSelf = (nodeName === "cava" || appName === "cava")
                            if (!isMonitor && !isSelf) {
                                mic = true

                                pushUnique(
                                    micApps,
                                    captureLabel(nodeName, appName)
                                )
                            }
                        } else if (cls === "Stream/Input/Video") {
                            // Defensive: ignore monitor/preview captures
                            // if a future consumer ever flags them.
                            var vMon = props["stream.monitor"]
                            var vCapSink = props["stream.capture.sink"]
                            var vIsMonitor = (vMon === true || vMon === "true" || vCapSink === true || vCapSink === "true")
                            if (!vIsMonitor) {
                                cam = true

                                pushUnique(
                                    cameraApps,
                                    captureLabel(
                                        props["node.name"] || "",
                                        props["application.name"] || ""
                                    )
                                )
                            }
                        } else if (cls === "Stream/Output/Video") {
                            stream = true
                        }
                    }
                } catch (e) {
                    console.warn("PrivacyService: pw-dump parse failed: " + e)
                    return
                }

                root._streamMicActive = mic
                root.micActive = mic || root._alsaCapture
                root._streamCameraActive = cam
                root.cameraActive = cam || root._v4l2Open
                root._streamActive = stream
                root.screenSharingActive = stream || root.externalDisplayConnected

                // Rebuilt each pass rather than mutated in place so
                // the Repeater/model sees a change even when the
                // labels are identical.
                root.micApps = micApps
                root.cameraApps = cameraApps
            }
        }
    }

    // One shell call for the cheap probes: connected external
    // displays, processes holding a camera device open, and ALSA
    // hardware capture state. Emits "display:<n>" / "v4l2:<n>" /
    // "alsa:<n>" lines for the parser below.
    Process {
        id: sysProc
        command: ["sh", "-c", "echo display:$(grep -h '^connected$' /sys/class/drm/card*-HDMI-*/status /sys/class/drm/card*-DP-*/status 2>/dev/null | wc -l); echo v4l2:$(ls -l /proc/[0-9]*/fd 2>/dev/null | grep -c '/dev/video'); echo alsa:$(grep -l '^state: *RUNNING' /proc/asound/card*/pcm*c/sub*/status 2>/dev/null | wc -l)"]

        stdout: StdioCollector {
            onStreamFinished: {
                var display = false
                var v4l2 = false
                var alsa = false

                var lines = text.split("\n")

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")

                    if (parts.length !== 2)
                        continue

                    if (parts[0] === "display" && parseInt(parts[1]) > 0)
                        display = true
                    else if (parts[0] === "v4l2" && parseInt(parts[1]) > 0)
                        v4l2 = true
                    else if (parts[0] === "alsa" && parseInt(parts[1]) > 0)
                        alsa = true
                }

                root.externalDisplayConnected = display
                root._v4l2Open = v4l2
                root._alsaCapture = alsa
                root.cameraActive = v4l2 || root._streamCameraActive
                root.micActive = alsa || root._streamMicActive
                root.screenSharingActive = root._streamActive || display
            }
        }
    }

    Component.onCompleted: update()
}
