import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../../island"
import "../../components/bar"
import "../../services"
import "../../services/motivation"
import "../../config"

Item {
    id: root
    property bool interactive: true
    readonly property bool hasMedia: MediaService.hasPlayer
    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(nowPlaying.implicitHeight, privacy.implicitHeight, 33)

    // Track cycle state between 0 (Weather) and 1 (Motivation)
    property int currentSlot: 0

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: {
            root.currentSlot = (root.currentSlot === 0) ? 1 : 0
        }
    }

    readonly property bool showWeatherNow: {
        if (ConfigStore.barInfoMode === "weather") return true
        if (ConfigStore.barInfoMode === "motivation") return false
        return root.currentSlot === 0
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        NotificationBell {
            id: notifBell
            visible: !IslandState.layoutIsBar
            Layout.alignment: Qt.AlignVCenter
            HoverHandler {
                id: bellHover
            }
        }

        PrivacyCluster {
            id: privacy
            visible: !IslandState.layoutIsBar && privacy.anyActive
            Layout.alignment: Qt.AlignVCenter
        }

        NowPlayingWidget {
            id: nowPlaying
            visible: root.hasMedia
            cavaOnly: !IslandState.layoutIsBar
            hovered: sectionHover.hovered
            Layout.alignment: Qt.AlignVCenter
        }

        // Weather display (when no media is playing and cycled to weather)
        RowLayout {
            id: weatherRow
            visible: !root.hasMedia && root.showWeatherNow
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                text: WeatherService.icon
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            Column {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                // In pill/notch mode, total side column is 172. LeftSection margin is 8.
                // NotifBell takes 28 + spacing 10 = 38. Weather icon takes 18 + spacing 8 = 26.
                // Total fixed = ~72. So available width when privacy is NOT active is ~100px.
                // When privacy IS active, it takes privacy.implicitWidth + spacing 10.
                readonly property real maxCityWidth: !IslandState.layoutIsBar
                    ? Math.max(40, (privacy.visible ? (100 - privacy.implicitWidth - 10) : 100))
                    : 160

                Text {
                    text: WeatherService.temp
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    id: cityText
                    visible: WeatherService.city !== ""
                    text: WeatherService.city
                    color: Theme.textPrimary
                    opacity: 0.7
                    font.pixelSize: 11
                    elide: privacy.visible ? Text.ElideRight : Text.ElideNone
                    width: privacy.visible ? Math.min(implicitWidth, parent.maxCityWidth) : implicitWidth
                }
            }
        }

        // Motivation display (when no media is playing and cycled to motivation)
        RowLayout {
            id: motivRow
            visible: !root.hasMedia && !root.showWeatherNow
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Text {
                text: "✦"
                color: Theme.accent
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: GreetingService.text
                maxWidth: 140
                fontSize: 12
                hovered: sectionHover.hovered
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    HoverHandler {
        id: sectionHover
        enabled: root.interactive && (!notifBell.visible || !bellHover.hovered)
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive && (!notifBell.visible || !bellHover.hovered)
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {
            event.accepted = true

            if (root.hasMedia) {
                IslandController.openMediaFromLeftSection()
            } else if (root.showWeatherNow) {
                IslandController.openWeather()
            } else {
                IslandController.openQuote()
            }
        }
    }
}
