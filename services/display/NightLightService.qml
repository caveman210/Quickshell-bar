pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."
import "../compositor"
import "../../config"

Singleton {
    id: root

    // hyprsunset is Hyprland-only; niri gets gammastep via
    // wlr-gamma-control, which must be installed separately.
    readonly property string backend: {
        if (CompositorService.isHyprland)
            return "hyprsunset"

        if (CompositorService.isNiri)
            return "gammastep"

        return ""
    }

    readonly property string probeScript: "pgrep " + root.backend
        + " >/dev/null && echo on || echo off"

    readonly property string killScript: root.backend === "gammastep"
        ? "pkill -9 gammastep 2>/dev/null; " +
          "i=0; while [ $i -lt 16 ] && pgrep gammastep >/dev/null; do sleep 0.1; i=$((i+1)); done; " +
          "setsid --fork gammastep -x >/dev/null 2>&1; sleep 0.5; " +
          "pkill -9 gammastep 2>/dev/null"
        : "pkill hyprsunset"

    property bool gammastepInstalled: false

    onGammastepInstalledChanged: {
        if (gammastepInstalled)
            root.update()
    }

    property bool available: backend === "hyprsunset"
        || (backend === "gammastep" && gammastepInstalled)

    property bool enabled: false
    property string subtitle: !available ? "N/A" : (enabled ? "On" : "Off")
    property string icon: enabled
        ? "󰔎"
        : "󰃞"

    property int currentTemp: 6500

    property bool wantOn: false
    property bool hasWant: false
    property bool probing: false
    property bool acting: false
    property int retries: 0
    property var lastScheduledTarget: null

    // -------------------------------------------------------------
    // Curve evaluation (dy/dx progression)
    // -------------------------------------------------------------
    function evaluateCurveProgress(t) {
        var clampedT = Math.max(0.0, Math.min(1.0, t))
        var curve = ConfigStore.nightLightCurveType

        if (curve === "linear") {
            return clampedT
        } else if (curve === "ease_in") {
            return clampedT * clampedT
        } else if (curve === "ease_out") {
            return 1.0 - (1.0 - clampedT) * (1.0 - clampedT)
        } else if (curve === "custom") {
            var pts = ConfigStore.nightLightControlPoints
            if (pts && pts.length >= 2) {
                // Find segment
                for (var i = 0; i < pts.length - 1; i++) {
                    var p0 = pts[i]
                    var p1 = pts[i + 1]
                    if (clampedT >= p0.x && clampedT <= p1.x) {
                        var segSpan = Math.max(0.0001, p1.x - p0.x)
                        var localT = (clampedT - p0.x) / segSpan
                        // Smooth cubic interpolation between p0.y and p1.y
                        var smooth = localT * localT * (3.0 - 2.0 * localT)
                        return Math.max(0.0, Math.min(1.0, p0.y + smooth * (p1.y - p0.y)))
                    }
                }
                return Math.max(0.0, Math.min(1.0, pts[pts.length - 1].y))
            }
            return clampedT
        } else {
            // Default: S-Curve (Smoothstep)
            return clampedT * clampedT * (3.0 - 2.0 * clampedT)
        }
    }

    // -------------------------------------------------------------
    // Schedule Calculation
    // -------------------------------------------------------------
    function getScheduleState(startStr, endStr, durationMins) {
        var now = new Date()
        var curMin = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60.0

        var s = (startStr || "20:00").split(":")
        var e = (endStr || "07:00").split(":")
        var startMin = parseInt(s[0], 10) * 60 + parseInt(s[1] || "0", 10)
        var endMin = parseInt(e[0], 10) * 60 + parseInt(e[1] || "0", 10)
        var dur = Math.max(1, durationMins || 15)

        var inSchedule = false
        var elapsedSinceStart = 0

        if (startMin <= endMin) {
            inSchedule = curMin >= startMin && curMin < endMin
            elapsedSinceStart = curMin - startMin
        } else {
            inSchedule = curMin >= startMin || curMin < endMin
            if (curMin >= startMin) {
                elapsedSinceStart = curMin - startMin
            } else {
                elapsedSinceStart = (24 * 60 - startMin) + curMin
            }
        }

        if (!inSchedule) {
            return { "active": false, "progress": 0.0, "targetTemp": 6500 }
        }

        var progress = Math.min(1.0, Math.max(0.0, elapsedSinceStart / dur))
        var curveVal = evaluateCurveProgress(progress)

        var targetWarmth = ConfigStore.nightLightTargetTemp || 4500
        var neutral = 6500
        var calculatedTemp = Math.round(neutral - curveVal * (neutral - targetWarmth))

        return {
            "active": true,
            "progress": progress,
            "curveValue": curveVal,
            "targetTemp": calculatedTemp
        }
    }

    // Timer checking every 15 seconds for smooth stepped transitions
    Timer {
        id: scheduleTimer
        interval: 15000
        repeat: true
        running: ConfigStore.nightLightSchedule && root.available
        triggeredOnStart: true
        onTriggered: root.checkSchedule()
    }

    function recheckSchedule() {
        root.lastScheduledTarget = null
        root.checkSchedule()
    }

    function checkSchedule() {
        if (!ConfigStore.nightLightSchedule || !root.available)
            return

        var state = getScheduleState(
            ConfigStore.nightLightStart,
            ConfigStore.nightLightEnd,
            ConfigStore.nightLightTransitionMins
        )

        if (!state.active) {
            if (root.enabled || root.currentTemp !== 6500) {
                root.wantOn = false
                root.hasWant = true
                root.retries = 0
                root.enabled = false
                root.currentTemp = 6500
                root.reconcile()
            }
            return
        }

        // Active schedule: check if temp needs update
        if (!root.enabled || Math.abs(root.currentTemp - state.targetTemp) >= 50) {
            root.wantOn = true
            root.hasWant = true
            root.retries = 0
            root.enabled = true
            root.currentTemp = state.targetTemp
            root.reconcile()
        }
    }

    Process {
        id: whichProcess
        command: ["bash", "-c", "command -v gammastep >/dev/null 2>&1"]

        onExited: (exitCode, exitStatus) => {
            root.gammastepInstalled = exitCode === 0
        }
    }

    Process {
        id: stateProcess
        command: ["bash", "-c", root.probeScript]

        stdout: StdioCollector {
            onStreamFinished: {
                root.probing = false
                root.handleActual(text.trim() === "on")
            }
        }
    }

    Process {
        id: actProcess

        onExited: (exitCode, exitStatus) => {
            root.acting = false
            settleTimer.restart()
        }
    }

    Timer {
        id: settleTimer
        interval: 350
        repeat: false

        onTriggered: {
            root.reconcile()
        }
    }

    function update() {
        root.reconcile()
    }

    function toggle() {
        if (!root.available)
            return

        root.wantOn = root.hasWant ? !root.wantOn : !root.enabled
        root.hasWant = true
        root.retries = 0
        root.enabled = root.wantOn
        root.currentTemp = root.wantOn ? (ConfigStore.nightLightTargetTemp || 4500) : 6500
        root.reconcile()
    }

    function reconcile() {
        if (!root.available || root.probing || root.acting)
            return

        root.probing = true
        stateProcess.running = false
        stateProcess.running = true
    }

    function handleActual(actual) {
        if (!root.hasWant) {
            root.enabled = actual
            return
        }

        if (actual === root.wantOn && (!actual || root.currentTemp === (ConfigStore.nightLightTargetTemp || 4500))) {
            root.enabled = actual
            root.hasWant = false
            return
        }

        if (root.retries >= 3) {
            root.enabled = actual
            root.hasWant = false
            return
        }

        root.retries += 1

        if (root.wantOn) {
            var temp = root.currentTemp || (ConfigStore.nightLightTargetTemp || 4500)
            actProcess.command = root.backend === "gammastep"
                ? ["bash", "-c", "pkill -9 gammastep 2>/dev/null; setsid --fork gammastep -m wayland -t " + temp + ":" + temp + " -l 0:0 >/dev/null 2>&1"]
                : ["bash", "-c", "pkill hyprsunset 2>/dev/null; setsid --fork hyprsunset --temperature " + temp + " >/dev/null 2>&1"]
        } else {
            actProcess.command = ["bash", "-c", root.killScript]
        }

        root.acting = true
        actProcess.running = true
    }

    Component.onCompleted: {
        if (root.backend === "gammastep")
            whichProcess.running = true

        update()
        if (ConfigStore.nightLightSchedule)
            checkSchedule()
    }
}
