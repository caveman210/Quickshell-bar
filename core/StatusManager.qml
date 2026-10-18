pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    property bool visible: false
    property string mode: ""
    property string icon: ""
    property string title: ""
    property var value
    // 0 = auto: OverlayView falls back to the per-mode Theme width.
    // All current callers pass an explicit width.
    property int statusWidth: 0
    property int statusHeight: 33

    function show(data) {
        mode = data.mode
        icon = data.icon
        title = data.title
        value = data.value

        statusWidth = data.statusWidth ?? 0
        statusHeight = data.statusHeight ?? 33

        visible = true

        hideTimer.restart()
    }

    // Sequential queue for device events (wifi/bluetooth). Each
    // entry gets its own island prompt. show() stays immediate
    // (volume/brightness overwrite) and is untouched.
    property var _queue: []

    function showQueued(data) {
        // Bound the queue so a flapping adapter can't grow it forever.
        if (_queue.length >= 10)
            _queue.shift()

        _queue.push({
            mode: data.mode ?? "notification",
            icon: data.icon ?? "",
            title: data.title ?? "",
            value: data.value ?? 0,
            statusWidth: data.statusWidth ?? 0,
            statusHeight: data.statusHeight ?? 33
        })

        _pump()
    }

    function _pump() {
        if (root.visible)
            return

        if (gapTimer.running)
            return

        if (_queue.length === 0)
            return

        _showNext()
    }

    function _showNext() {
        if (root.visible)
            return

        if (_queue.length === 0)
            return

        var next = _queue.shift()

        root.show(next)
    }

    Timer {
        id: gapTimer
        interval: 180
        repeat: false

        onTriggered: {
            root._showNext()
        }
    }

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false

        onTriggered: {
            root.visible = false

            if (root._queue.length > 0)
                gapTimer.restart()
        }
    }
}
