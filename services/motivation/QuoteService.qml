pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "MotivationUtils.js" as MotivationUtils

// Quote of the day, pulled from ZenQuotes' free `/api/today`
// endpoint (no API key). The quote is fetched at startup, again
// after a local day rollover, and retried with a 15 minute backoff
// if the request fails so an offline moment does not leave the bar
// without a quote until the next login.
Singleton {
    id: root

    property string quote: ""
    property string author: ""
    property string sourceDate: ""
    property bool loading: false

    readonly property bool hasQuote: quote !== ""

    // Local day the successful fetch belonged to, and the earliest
    // time a failed fetch may be retried.
    property string fetchedDay: ""
    property double nextAttempt: 0

    function refresh() {
        if (fetchProcess.running)
            return

        loading = true
        fetchProcess.running = true
    }

    function ensureToday() {
        var today = MotivationUtils.dayKey(Date.now())

        if (fetchedDay === today)
            return

        if (Date.now() < nextAttempt)
            return

        refresh()
    }

    function parse(text) {
        var data

        try {
            data = JSON.parse(text)
        } catch (e) {
            return false
        }

        var item = Array.isArray(data) ? data[0] : data

        if (!item)
            return false

        var body = (item.q || item.quote || "").trim()
        var byline = (item.a || item.author || "").trim()

        if (body === "")
            return false

        quote = body
        author = byline
        sourceDate = item.date || ""
        fetchedDay = MotivationUtils.dayKey(Date.now())

        return true
    }

    Component.onCompleted: ensureToday()

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true

        onTriggered: root.ensureToday()
    }

    Process {
        id: fetchProcess
        command: [
            "curl", "-fsSL", "--max-time", "20",
            "https://zenquotes.io/api/today"
        ]

        stdout: StdioCollector {
            id: fetchOut
            waitForEnd: true

            onStreamFinished: {
                if (!root.parse(fetchOut.text))
                    root.nextAttempt = Date.now() + 15 * 60 * 1000
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false

            if (exitCode !== 0)
                root.nextAttempt = Date.now() + 15 * 60 * 1000
        }
    }
}
