import QtQuick
import QtQuick.Layouts

import "../../core"
import "../../services/motivation"
import "../../styles"

// Quote-of-the-day panel, opened from the bar's greeting/quote line.
// Typographic hierarchy per the request: the quote as an italic H3,
// then a small H6 byline underneath.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: layout.implicitHeight + 56

    Component.onCompleted: {
        forceActiveFocus()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            IslandController.reset()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: "QUOTE OF THE DAY"
            color: Theme.textSecondary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.letterSpacing: 2
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: QuoteService.hasQuote
                    ? "“" + QuoteService.quote + "”"
                    : QuoteService.loading
                        ? "Fetching the quote of the day…"
                        : "No quote available right now."
            color: QuoteService.hasQuote
                    ? Theme.textPrimary
                    : Theme.textSecondary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            font.italic: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.3
        }

        Text {
            Layout.fillWidth: true
            visible: QuoteService.hasQuote
                    && QuoteService.author !== ""
            text: "- " + QuoteService.author
            color: Theme.textSecondary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
