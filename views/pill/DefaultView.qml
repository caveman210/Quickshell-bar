import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import "../shared"
import "../../styles"
import "../../services"
import "../../services/audio"
import "../../services/power"
import "../../components/bar"
import "../../components/sections"
import "../../core"
import "../../island"

Item {
    id: root

    // Privacy indicators state
    readonly property bool micActive: PrivacyService.micActive
    readonly property bool camActive: PrivacyService.cameraActive
    readonly property bool castActive: PrivacyService.screenSharingActive
    readonly property bool privacyLive: micActive || camActive || castActive

    // Media state
    readonly property bool hasMedia: MediaService.hasPlayer && MediaService.isPlaying

    // True physical islandcn split mode:
    // When Media is active AND Privacy is active simultaneously,
    // the island splits: Media stays in the main pill, and privacy detaches into the secondary capsule.
    readonly property bool isSplitMode: hasMedia && privacyLive

    readonly property bool showPrivacyInline: privacyLive && !isSplitMode
    readonly property bool showMedia: hasMedia

    // Dynamic width for the secondary split bubble so all active privacy indicators fit comfortably
    // with equal padding and breathing room
    readonly property int activeCount: (micActive ? 1 : 0) + (camActive ? 1 : 0) + (castActive ? 1 : 0)
    readonly property int bubbleWidth: Math.max(34, activeCount * 22 + (activeCount - 1) * 10 + 20)
    readonly property int bubbleSize: 33
    readonly property int bubbleGap: 8

    implicitHeight: 33
    implicitWidth: {
        var base = Math.max(160, row.implicitWidth + 32)

        if (showPrivacyInline) {
            base += indicators.leftWidth + indicators.rightWidth
        } else if (showMedia) {
            base = Math.max(186, row.implicitWidth + 72)
        }

        if (isSplitMode) {
            base += bubbleWidth + bubbleGap
        }

        return base
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    // ---------------------------------------------------------
    // PRIMARY ATTACHED PILL (Standalone physical capsule)
    // ---------------------------------------------------------
    Rectangle {
        id: primaryPillBody
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.isSplitMode ? (parent.width - root.bubbleWidth - root.bubbleGap) : parent.width
        radius: Theme.capsuleRadius
        color: Theme.background

        // In split mode, the primary pill clips and contains media & clock
        Item {
            anchors.fill: parent

            // -----------------------------------------------------
            // LEADING REGION: Privacy (inline) or Album Art
            // -----------------------------------------------------
            PrivacyIndicators {
                id: indicators
                visible: root.showPrivacyInline
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            ClippingRectangle {
                id: compactArt
                visible: root.showMedia
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 6
                color: Theme.surface

                Image {
                    anchors.fill: parent
                    source: MediaService.artUrl
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !compactArt.children[0].visible
                    text: "♪"
                    font.pixelSize: 12
                    color: Theme.textPrimary
                }
            }

            // -----------------------------------------------------
            // CENTER REGION: Clock (+ Low Battery indicator)
            // -----------------------------------------------------
            RowLayout {
                id: row
                spacing: 8
                anchors.centerIn: parent

                ClockView {
                    Layout.alignment: Qt.AlignVCenter
                }

                LowBatteryIndicator {
                    visible: LowBatteryService.active
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // -----------------------------------------------------
            // TRAILING REGION: Cava LevelMeter (dot baseline)
            // -----------------------------------------------------
            Cava {
                id: trailingCava
                visible: root.showMedia
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                barCount: 4
                barWidth: 3
                spacingSize: 2
                dotBaseline: true
                barColor: Theme.accent
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.showMedia) {
                    IslandController.openMediaFromLeftSection()
                } else {
                    IslandController.openCalendar()
                }
            }
        }
    }

    // Exposed so Island.qml can skip expand when hover is on the bubble, not the primary pill
    readonly property bool bubbleHovered: bubbleHoverHandler.hovered

    // ---------------------------------------------------------
    // SECONDARY DETACHED BUBBLE / CAPSULE
    // Floats completely detached across a true transparent gap
    // ---------------------------------------------------------
    Rectangle {
        id: detachedBubble
        visible: root.isSplitMode
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.bubbleWidth
        height: root.bubbleSize
        radius: root.bubbleSize / 2
        color: Theme.background

        HoverHandler {
            id: bubbleHoverHandler
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            // Webcam Indicator
            Text {
                visible: root.camActive
                anchors.verticalCenter: parent.verticalCenter
                text: "󰄀"
                color: Theme.success
                font.family: Theme.iconFontMono
                font.pixelSize: 15
            }

            // Microphone Indicator
            Text {
                visible: root.micActive
                anchors.verticalCenter: parent.verticalCenter
                text: MicrophoneService.muted ? "󰍭" : "󰍬"
                color: MicrophoneService.muted ? Theme.danger : Theme.success
                font.family: Theme.iconFontMono
                font.pixelSize: 15
            }

            // Screen Sharing Indicator
            Text {
                visible: root.castActive
                anchors.verticalCenter: parent.verticalCenter
                text: "󰄘"
                color: Theme.danger
                font.family: Theme.iconFontMono
                font.pixelSize: 15
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: IslandController.openPrivacyMenuFromRightSection()
        }
    }
}
