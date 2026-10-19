pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../compositor"

Singleton {
    id: root

    SessionActions {
        id: sessionActions
    }

    Process {
        id: commandProcess
    }

    function run(cmd) {
        if (commandProcess.running) {
            console.warn("PowerService: command already running, ignoring request")

            return
        }

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
        var cmd = sessionActions.logoutCommand()

        if (cmd) {
            run(cmd)
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
