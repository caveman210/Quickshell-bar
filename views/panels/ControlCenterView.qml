import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../styles"
import "../../components/sections"
import "../../core"
import "../shared"
import "../../services"
import "../../services/audio"
import "../../services/connectivity"
import "../../services/display"
import "../../services/notification"
import "../../services/power"
import "../../services/shell"
import "../../services/system"
import "../../island"

Item {
    id: root
    clip: true
    property bool layoutDropdownOpen: false
    implicitWidth: 520

    // Never past ~65-70% of the screen height (the user set that
    // ceiling).
    readonly property real maxViewHeight: 0.65 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    // The bar's control center shows disk usage; pill and notch keep
    // the notifications pane.
    readonly property bool showStorage: IslandState.layoutIsBar

    readonly property string systemSubtitle: {
        var d = SystemService.details

        if (!SystemService.loaded)
            return "Reading system…"

        var parts = []

        if (d.os)
            parts.push(d.os)

        if (d.wm)
            parts.push(d.wm)

        return parts.length > 0 ? parts.join("  ·  ") : "Hardware & OS"
    }

    readonly property real notifPaneHeight: NotificationService.conversations.count === 0
        ? 150
        : Math.max(150, notifView.listContentHeight + 72)

    implicitHeight: Math.min(
        Math.max(layout.implicitHeight + 44, showStorage ? 400 : 530),
        maxViewHeight
    )

    // Opening the pill/notch pane marks notifications as read; the
    // bar's pane does not show them.
    Component.onCompleted: {
        if (!root.showStorage)
            NotificationService.markRead()
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Control Center"
                color: Theme.textPrimary
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: BatteryService.icon
                    color: Theme.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: BatteryService.percentage + "%"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 12

            ControlCard {
                icon: WifiService.icon
                title: "Wi-Fi"
                subtitle: WifiService.subtitle
                active: WifiService.connected
                onClicked: IslandController.openWifiMenu()
            }

            ControlCard {
                icon: BluetoothService.icon
                title: "Bluetooth"
                subtitle: BluetoothService.subtitle
                active: BluetoothService.enabled
                onClicked: IslandController.openBluetoothMenu()
            }

            ControlCard {
                icon: MicrophoneService.icon
                title: "Mic"
                subtitle: MicrophoneService.subtitle
                active: !MicrophoneService.muted
                onClicked: MicrophoneService.toggle()
            }

            ControlCard {
                visible: NightLightService.available
                icon: NightLightService.icon
                title: "Night Light"
                subtitle: NightLightService.subtitle
                active: NightLightService.enabled
                onClicked: NightLightService.toggle()
            }

            ControlCard {
                icon: "󰸉"
                title: "Wallpaper"
                onClicked: IslandController.openWallpaperSelector()
            }

            ControlCard {
                icon: FocusService.icon
                title: "Focus"
                subtitle: FocusService.subtitle
                active: FocusService.enabled
                onClicked: FocusService.toggle()
            }

            ControlCard {
                icon: AutoHideService.icon
                title: "Auto-Hide"
                subtitle: AutoHideService.subtitle
                active: AutoHideService.enabled
                onClicked: AutoHideService.toggle()
            }

            ControlCard {
                id: layoutCard
                icon: "󰐂"
                title: "Layout"
                subtitle: IslandState.layoutName

                onClicked: {
                    var p = layoutCard.mapToItem(root, 0, layoutCard.height)
                    layoutDropdown.x = Math.max(
                        8,
                        Math.min(p.x, root.width - layoutDropdown.width - 8)
                    )
                    layoutDropdown.y = p.y + 6
                    root.layoutDropdownOpen = true
                }
            }
        }

        // Bar layout keeps the sliders in the clock dropdown only
        // (BarExpandedView); pill and notch keep them here.
        ControlSlider {
            visible: !IslandState.layoutIsBar
            icon: AudioService.volumeIcon
            value: AudioService.volume / 100

            onIconClicked: AudioService.toggleMute()

            onValueChangedByUser: function(value) {
                AudioService.setVolume(
                    value * 100
                )
            }
        }

        ControlSlider {
            visible: !IslandState.layoutIsBar
            icon: BrightnessService.brightnessIcon
            value: BrightnessService.brightness / 100

            onValueChangedByUser: function(value) {
                BrightnessService.setBrightness(
                    value * 100
                )
            }
        }

        Rectangle {
            visible: root.showStorage
            Layout.fillWidth: true
            radius: 14
            color: Theme.surface
            clip: true
            implicitHeight: storageCol.implicitHeight + 28

            ColumnLayout {
                id: storageCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "Storage"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    visible: StorageService.devices.length === 0
                    text: StorageService.loaded ? "No mounted disks" : "Scanning disks…"
                    color: Theme.textMuted
                    font.pixelSize: 12
                }

                Repeater {
                    model: StorageService.devices

                    delegate: StorageRow {
                        required property var modelData

                        Layout.fillWidth: true
                        device: modelData

                        onEjectRequested: StorageService.eject(modelData.path)
                    }
                }
            }
        }

        // Entry point to the fastfetch pane. Sits below Storage so the
        // system details stay one click away without making the
        // control center itself any taller than it has to be.
        Rectangle {
            id: systemCard
            visible: root.showStorage
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 14
            color: systemHover.hovered ? Theme.buttonHover : Theme.surface
            border.width: 1
            border.color: Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationFast
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: SystemService.osIcon
                    color: Theme.accent
                    font.family: Theme.iconFont
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: "System"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.systemSubtitle
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: "󰅂"
                    color: Theme.textMuted
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                }
            }

            HoverHandler {
                id: systemHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: IslandController.openSystemMenu()
            }
        }

        Rectangle {
            visible: !root.showStorage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120
            Layout.preferredHeight: root.notifPaneHeight
            radius: 14
            color: Theme.surface
            clip: true

            NotificationView {
                id: notifView
                anchors.fill: parent
                anchors.margins: 14
            }
        }
    }

    // Tap-outside-to-close catcher for the layout dropdown. Only
    // present while the dropdown is open.
    MouseArea {
        anchors.fill: parent
        visible: root.layoutDropdownOpen
        z: 900

        onClicked: root.layoutDropdownOpen = false
    }

    LayoutDropdown {
        id: layoutDropdown
        z: 901
        visible: root.layoutDropdownOpen

        onClosed: root.layoutDropdownOpen = false
    }
}
