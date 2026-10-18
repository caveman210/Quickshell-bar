import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15

import Quickshell
import Quickshell.Bluetooth

import "../core"
import "../services"
import "../styles"

// Bluetooth device picker, opened from the control center card or
// via IPC. Paired devices first, then discovered ones while the
// pane (and its scanning window) is open.
FocusScope {
    id: root

    readonly property var adapter: BluetoothService.adapter
    readonly property bool scanning: !!adapter && adapter.discovering

    property var deviceList: []
    property int selectedRow: 0

    implicitWidth: 540

    readonly property real maxViewHeight: 0.65 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    implicitHeight: Math.min(layout.implicitHeight + 44, maxViewHeight)

    Component.onCompleted: {
        rebuild()
        forceActiveFocus()

        if (adapter) {
            adapter.discovering = true
            scanTimer.restart()
        }
    }

    Component.onDestruction: {
        if (adapter)
            adapter.discovering = false
    }

    // BlueZ drops unpaired devices a while after discovery stops, so
    // scans are time-boxed instead of left running.
    Timer {
        id: scanTimer
        interval: 15000
        repeat: false

        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false
        }
    }

    Connections {
        target: root.adapter ? root.adapter.devices : null

        function onValuesChanged() {
            Qt.callLater(root.rebuild)
        }
    }

    onSelectedRowChanged: {
        Qt.callLater(function() {
            deviceListView.positionViewAtIndex(
                root.selectedRow,
                ListView.Contain
            )
        })
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_K:

            if (root.selectedRow > 0)
                root.selectedRow--

            event.accepted = true
            break

        case Qt.Key_Down:
        case Qt.Key_J:

            if (root.selectedRow < root.deviceList.length - 1)
                root.selectedRow++

            event.accepted = true
            break

        case Qt.Key_Return:
        case Qt.Key_Enter:

            root.activateSelected()

            event.accepted = true
            break

        case Qt.Key_Escape:

            IslandController.reset()

            event.accepted = true
            break
        }
    }

    // =========================================================
    // LIST MODEL
    // =========================================================

    function rank(dev) {
        if (dev.connected)
            return 0

        return (dev.paired || dev.pairing) ? 1 : 2
    }

    function deviceLabel(dev) {
        return String(
            dev.name
            || dev.deviceName
            || dev.address
            || "Unknown device"
        )
    }

    function rebuild() {
        const list = []

        if (root.adapter) {
            const devs = root.adapter.devices.values

            for (let i = 0; i < devs.length; ++i) {
                const dev = devs[i]

                if (!dev || dev.blocked)
                    continue

                list.push(dev)
            }

            list.sort(function(a, b) {
                const ra = rank(a)
                const rb = rank(b)

                if (ra !== rb)
                    return ra - rb

                return deviceLabel(a).localeCompare(deviceLabel(b))
            })
        }

        root.deviceList = list

        if (root.selectedRow >= list.length)
            root.selectedRow = Math.max(0, list.length - 1)
    }

    // =========================================================
    // ACTIONS
    // =========================================================

    function primaryAction(dev) {
        if (!dev || !BluetoothService.enabled)
            return

        if (dev.pairing) {
            dev.cancelPair()
            return
        }

        if (dev.connected) {
            dev.disconnect()
            return
        }

        if (dev.paired) {
            dev.connect()
            return
        }

        dev.pair()
    }

    function activateSelected() {
        if (root.deviceList.length === 0)
            return

        primaryAction(
            root.deviceList[
                Math.min(root.selectedRow, root.deviceList.length - 1)
            ]
        )
    }

    function rescan() {
        if (!root.adapter)
            return

        root.adapter.discovering = false

        Qt.callLater(function() {
            if (root.adapter)
                root.adapter.discovering = true
        })

        scanTimer.restart()
    }

    // =========================================================
    // LABELS
    // =========================================================

    function deviceGlyph(dev) {
        const icon = String(dev.icon || "")

        if (icon.indexOf("audio") >= 0
            || icon.indexOf("headset") >= 0
            || icon.indexOf("headphone") >= 0)

            return "󰋋"

        if (icon.indexOf("keyboard") >= 0)
            return "󰌌"

        if (icon.indexOf("mouse") >= 0)
            return "󰍽"

        if (icon.indexOf("phone") >= 0)
            return "󰏲"

        if (icon.indexOf("computer") >= 0)
            return "󰟀"

        if (icon.indexOf("watch") >= 0)
            return "󰖉"

        if (icon.indexOf("gamepad") >= 0
            || icon.indexOf("joystick") >= 0)

            return "󰊴"

        return dev.connected ? "󰂱" : "󰂯"
    }

    function statusText(dev) {
        let state = ""

        switch (dev.state) {
        case BluetoothDeviceState.Connected:
            state = "Connected"
            break

        case BluetoothDeviceState.Connecting:
            state = "Connecting..."
            break

        case BluetoothDeviceState.Disconnecting:
            state = "Disconnecting..."
            break

        default:
            state = dev.paired ? "Paired" : "Available"
            break
        }

        if (dev.batteryAvailable) {
            const pct = Math.round(Number(dev.battery) * 100)

            if (!isNaN(pct))
                state += " · " + pct + "%"
        }

        return state
    }

    function primaryLabel(dev) {
        if (dev.pairing)
            return "Cancel"

        if (dev.connected)
            return "Disconnect"

        if (dev.paired)
            return "Connect"

        return "Pair"
    }

    function isNeutralAction(dev) {
        return dev.connected || dev.pairing
    }

    // =========================================================
    // UI
    // =========================================================

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Bluetooth"
                color: Theme.textPrimary
                font.pixelSize: 20
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: BluetoothService.enabled
                    && root.adapter
                    && root.adapter.discovering
                text: "Scanning..."
                color: Theme.textSecondary
                font.pixelSize: 12
            }

            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                visible: BluetoothService.enabled
                color: rescanHover.hovered
                    ? Theme.buttonHover
                    : Theme.buttonBackground

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }

                HoverHandler {
                    id: rescanHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.rescan()
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰑓"
                    color: Theme.textPrimary
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                    transformOrigin: Item.Center
                    rotation: 0

                    NumberAnimation on rotation {
                        running: root.scanning
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1100
                    }
                }
            }

            Rectangle {
                id: toggle
                implicitWidth: 44
                implicitHeight: 24
                radius: 12
                color: BluetoothService.enabled
                    ? Theme.accent
                    : Theme.buttonBackground

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: BluetoothService.toggle()
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    y: 3
                    x: BluetoothService.enabled
                        ? parent.width - width - 3
                        : 3
                    color: BluetoothService.enabled
                        ? Theme.background
                        : Theme.textSecondary

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animationFast
                        }
                    }
                }
            }
        }

        Text {
            visible: !BluetoothService.enabled || root.deviceList.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: !BluetoothService.enabled
                ? "Bluetooth is off"
                : root.adapter && root.adapter.discovering
                    ? "Searching for devices..."
                    : "No devices found"
            color: Theme.textSecondary
            font.pixelSize: 12
        }

        ListView {
            id: deviceListView
            visible: BluetoothService.enabled && root.deviceList.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 400)
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: root.deviceList

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                id: row

                required property int index
                required property var modelData

                width: deviceListView.width
                implicitHeight: 58
                radius: 14
                color: Theme.surface
                border.width: 1
                border.color: index === root.selectedRow
                    ? Theme.borderSelected
                    : Theme.border

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        root.selectedRow = row.index
                        root.primaryAction(row.modelData)
                    }
                }

                Connections {
                    target: row.modelData

                    function onConnectedChanged() {
                        Qt.callLater(root.rebuild)
                    }

                    function onPairedChanged() {
                        Qt.callLater(root.rebuild)
                    }

                    function onNameChanged() {
                        Qt.callLater(root.rebuild)
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: root.deviceGlyph(row.modelData)
                        color: row.modelData.connected
                            ? Theme.success
                            : Theme.textPrimary
                        font.family: Theme.iconFont
                        font.pixelSize: 18
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.deviceLabel(row.modelData)
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusText(row.modelData)
                            color: row.modelData.connected
                                ? Theme.success
                                : Theme.textSecondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        implicitHeight: 30
                        radius: 15
                        visible: row.modelData.paired || row.modelData.connected
                        color: forgetHover.hovered
                            ? Theme.buttonHover
                            : Theme.buttonBackground

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }

                        HoverHandler {
                            id: forgetHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: function(event) {
                                event.accepted = true
                                row.modelData.forget()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            color: Theme.textSecondary
                            font.family: Theme.iconFont
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 86
                        implicitHeight: 30
                        radius: 15
                        color: root.isNeutralAction(row.modelData)
                            ? Theme.buttonBackground
                            : Theme.accent

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animationFast
                            }
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: function(event) {
                                event.accepted = true
                                root.selectedRow = row.index
                                root.primaryAction(row.modelData)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.primaryLabel(row.modelData)
                            color: root.isNeutralAction(row.modelData)
                                ? Theme.textPrimary
                                : Theme.background
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
