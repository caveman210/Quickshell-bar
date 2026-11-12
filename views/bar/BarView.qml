import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../core"
import "../shared"
import "../../components/bar"
import "../../components/sections"
import "../../services"
import "../../services/motivation"
import "../../services/connectivity"
import "../../island"
import "../../config"

// Idle content of the bar layout: notification bell, cycled single-slot info,
// clock center, control pill (with active VPN lock) + tray + power right.
Item {
    id: root

    implicitHeight: Theme.barHeight

    // Track cycle state: switches between 0 (Weather) and 1 (Motivation) every 30 mins
    property int currentSlot: 0

    readonly property real weatherCenterX: mediaSection.x + mediaSection.width / 2

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

    // Bar's left cluster: Notification bell only
    RowLayout {
        id: leftCluster
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        NotificationBell {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Media Line OR Cycled Single-Line Slot (Weather OR Motivation - no conflict, no overlap)
    Item {
        id: mediaSection
        anchors.left: leftCluster.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: MediaService.hasPlayer
            ? mediaRow.implicitWidth
            : (root.showWeatherNow ? weatherRow.implicitWidth : motivRow.implicitWidth)
        implicitHeight: Theme.barHeight

        // Priority 1: When media is playing, show track
        RowLayout {
            id: mediaRow
            visible: MediaService.hasPlayer
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "♪"
                color: Theme.textPrimary
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: MediaService.title || "No Title"
                maxWidth: 240
                fontSize: 13
                hovered: mediaHover.hovered
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Priority 2: Weather alone (when cycled to Weather or forced in settings)
        RowLayout {
            id: weatherRow
            visible: !MediaService.hasPlayer && root.showWeatherNow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                text: WeatherService.icon
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 15
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: WeatherService.temp + (WeatherService.city ? " " + WeatherService.city : "")
                color: Theme.textPrimary
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Priority 3: Motivation alone (when cycled to Motivation or forced in settings)
        RowLayout {
            id: motivRow
            visible: !MediaService.hasPlayer && !root.showWeatherNow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                text: "✦"
                color: Theme.accent
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: GreetingService.text
                maxWidth: 240
                fontSize: 12
                hovered: mediaHover.hovered
                Layout.alignment: Qt.AlignVCenter
            }
        }

        HoverHandler {
            id: mediaHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                if (MediaService.hasPlayer) {
                    IslandController.openMediaFromLeftSection()
                } else if (root.showWeatherNow) {
                    IslandController.openWeather()
                } else {
                    IslandController.openQuote()
                }
            }
        }
    }

    // Center Section: Clock — clicking drops the Calendar
    Item {
        id: centerSection
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: centerRow.implicitWidth + 24
        implicitHeight: Theme.barHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 10
            color: centerHover.hovered || IslandState.mode === IslandState.calendarMode
                ? Theme.surface
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }
        }

        HoverHandler {
            id: centerHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds

            onTapped: function(event) {
                event.accepted = true

                if (IslandState.mode === IslandState.calendarMode)
                    IslandController.reset()
                else
                    IslandController.openCalendar()
            }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 10

            Item {
                id: centerSlot
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clock.implicitWidth
                implicitHeight: Theme.barHeight

                ClockView {
                    id: clock
                    anchors.centerIn: parent
                }
            }
        }
    }

    RightSection {
        id: rightSection
        showStatusChip: false
        showControlPill: true
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
    }
}
