import QtQuick
import QtQuick.Layouts

import Quickshell

import "../styles"
import "../components"
import "../core"
import "../views"
import "../services"
import "../island"

Item {
    id: root
    clip: true
    property Item wifiSvc
    property bool shapeDropdownOpen: false
    implicitWidth: 520

    // Grow with the notification list, but never past ~65-70% of
    // the screen height (the user set that ceiling).
    readonly property real maxViewHeight: 0.65 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    readonly property real notifPaneHeight: NotificationService.history.count === 0
        ? 150
        : Math.max(150, notifView.listContentHeight + 72)

    implicitHeight: Math.min(
        Math.max(layout.implicitHeight + 44, 530),
        maxViewHeight
    )

    // The user is looking at their notifications — clear the badge.
    Component.onCompleted: NotificationService.markRead()

    BatteryService {
        id: batteryService
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

            Row {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: batteryService ? batteryService.icon : "󰁺"
                    color: Theme.icon
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: batteryService ? batteryService.percentage + "%" : "--%"
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
                id: shapeCard
                icon: "󰐂"
                title: "Shape"
                subtitle: IslandState.shape === IslandState.shapeNotch ? "Notch" : "Pill"

                onClicked: {
                    var p = shapeCard.mapToItem(root, 0, shapeCard.height)
                    shapeDropdown.x = Math.max(
                        8,
                        Math.min(p.x, root.width - shapeDropdown.width - 8)
                    )
                    shapeDropdown.y = p.y + 6
                    root.shapeDropdownOpen = true
                }
            }
        }

        ControlSlider {
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
            icon: BrightnessService.brightnessIcon
            value: BrightnessService.brightness / 100

            onValueChangedByUser: function(value) {
                BrightnessService.setBrightness(
                    value * 100
                )
            }
        }

        Rectangle {
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

    // Tap-outside-to-close catcher for the shape dropdown. Only
    // present while the dropdown is open.
    MouseArea {
        anchors.fill: parent
        visible: root.shapeDropdownOpen
        z: 900

        onClicked: root.shapeDropdownOpen = false
    }

    ShapeDropdown {
        id: shapeDropdown
        z: 901
        visible: root.shapeDropdownOpen

        onClosed: root.shapeDropdownOpen = false
    }
}
