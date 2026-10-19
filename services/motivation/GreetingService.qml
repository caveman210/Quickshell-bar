pragma Singleton

import QtQuick
import Quickshell

import "MotivationUtils.js" as MotivationUtils

// Bar idle line: a time-of-day greeting or one of the short
// motivational tidbits, chosen per local day with a 70/30 split in
// favour of the greeting. This is the small text in the bar's empty
// media slot; the full online quote of the day is QuoteService and
// opens from that same line.
Singleton {
    id: root

    readonly property var tidbits: [
        "Cross your limits",
        "Make it count",
        "One thing at a time",
        "Stay curious",
        "Keep moving",
        "Small steps, big change",
        "Breathe and begin",
        "Own the day",
        "Less noise, more focus",
        "Start where you are",
        "Do the brave thing",
        "You've got this"
    ]

    property string text: ""
    property bool showingTidbit: false

    function timeOfDayGreeting(d) {
        var h = d.getHours()

        if (h >= 5 && h < 12)
            return "Good morning"

        if (h >= 12 && h < 17)
            return "Good afternoon"

        if (h >= 17 && h < 22)
            return "Good evening"

        return "Good night"
    }

    function refresh() {
        var now = new Date()
        var seed = MotivationUtils.dailySeed(now.getTime())

        // 70/30 in favour of the greeting, not 50/50.
        showingTidbit = seed % 10 >= 7

        text = showingTidbit
                ? tidbits[(seed >>> 8) % tidbits.length]
                : timeOfDayGreeting(now)
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true

        onTriggered: root.refresh()
    }
}
