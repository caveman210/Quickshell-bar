pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root

    Process {
        id: commandProcess
    }

    function run(cmd) {
        commandProcess.command = cmd
        commandProcess.running = true
    }

    function lock() {
        run([
            "loginctl",
            "lock-session"
        ])
    }

    function logout() {
        if (CompositorService.isNiri) {
            run([
                "niri",
                "msg",
                "action",
                "quit",
                "--skip-confirmation"
            ])
        } else if (CompositorService.isHyprland) {
            run([
                "hyprctl",
                "dispatch",
                "exit"
            ])
        } else {
            console.warn("PowerService.logout: unknown compositor, logout unsupported")
        }
    }

    function suspend() {
        run([
            "systemctl",
            "suspend"
        ])
    }

    function reboot() {
        run([
            "systemctl",
            "reboot"
        ])
    }

    function poweroff() {
        run([
            "systemctl",
            "poweroff"
        ])
    }
}
