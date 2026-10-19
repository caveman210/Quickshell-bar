pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import ".."
import "../compositor"

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

    // The daemon's live process name can differ from the binary
    // name: nix wraps gammastep, so the running process shows up as
    // .gammastep-wrap and an exact-match probe sees nothing. The
    // unanchored pattern matches both names, so the check never goes
    // blind (a blind probe made every ON click spawn another daemon
    // and every OFF click lie).
    readonly property string probeScript: "pgrep " + root.backend
        + " >/dev/null && echo on || echo off"

    // gammastep restores the white point before it exits, which can
    // take several seconds, and niri keeps the last ramp a daemon
    // applied — so killing the process alone can leave the screen
    // warm. The kill pkills every name gammastep runs under, waits
    // for it to really exit (SIGKILL escalation), then runs a
    // one-shot reset instance that re-applies the neutral ramp and
    // is killed right after, so the re-probe sees a clean slate.
    readonly property string killScript: root.backend === "gammastep"
        ? "pkill gammastep 2>/dev/null; " +
          "i=0; while [ $i -lt 32 ] && pgrep gammastep >/dev/null; do sleep 0.25; i=$((i+1)); done; " +
          "if pgrep gammastep >/dev/null; then pkill -9 gammastep 2>/dev/null; sleep 0.5; fi; " +
          "setsid --fork gammastep -x >/dev/null 2>&1; sleep 1; " +
          "pkill gammastep 2>/dev/null; " +
          "j=0; while [ $j -lt 16 ] && pgrep gammastep >/dev/null; do sleep 0.25; j=$((j+1)); done; " +
          "if pgrep gammastep >/dev/null; then pkill -9 gammastep 2>/dev/null; sleep 0.5; fi"
        : "pkill hyprsunset"

    // On niri the Control Center card only shows once gammastep is
    // actually installed (probed at startup); elsewhere the card
    // never lies about something it cannot do.
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

    // Check-first reconcile machine: every toggle probes the real
    // process state first and only runs a command when reality
    // disagrees with the last requested state. Rapid clicks keep
    // flipping the request; the loop converges on the final click
    // without ever spawning a duplicate daemon.
    property bool wantOn: false
    property bool hasWant: false
    property bool probing: false
    property bool acting: false
    property int retries: 0

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

    // Carries one start/kill command at a time. starts are fully
    // detached via setsid --fork, so the gamma daemon outlives shell
    // reloads (and this Process exits immediately instead of
    // tracking the daemon forever). Kills run killScript: pkill on
    // every known process name, then wait for the daemon to really
    // exit (gammastep can take seconds to restore the white point),
    // escalating to SIGKILL so no stray survives a click.
    Process {
        id: actProcess

        onExited: (exitCode, exitStatus) => {
            root.acting = false
            settleTimer.restart()
        }
    }

    // Give a start/kill a moment to actually take effect before the
    // re-probe, so confirmation never races the daemon's exec.
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

        // Flip from the last request while one is pending, so a
        // burst of clicks stays deterministic. The icon mirrors the
        // request immediately and snaps to the truth once the
        // machine confirms it.
        root.wantOn = root.hasWant ? !root.wantOn : !root.enabled
        root.hasWant = true
        root.retries = 0
        root.enabled = root.wantOn
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

        if (actual === root.wantOn) {
            // Confirmed: the request is satisfied.
            root.enabled = actual
            root.hasWant = false
            return
        }

        if (root.retries >= 2) {
            // The daemon will not hold the requested state (start
            // failed, kill blocked). Show the truth and drop the
            // request — the toggle bounces back instead of lying.
            root.enabled = actual
            root.hasWant = false
            return
        }

        root.retries += 1

        if (root.wantOn) {
            // -l/-t values skip geolocation; day and night temps
            // are equal, so the result is a constant 4500K.
            actProcess.command = root.backend === "gammastep"
                ? ["setsid", "--fork", "gammastep",
                   "-m", "wayland",
                   "-t", "4500:4500",
                   "-l", "0:0"]
                : ["setsid", "--fork", "hyprsunset",
                   "--temperature", "4500"]
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
    }
}
