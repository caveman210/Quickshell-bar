import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 2.15

import Quickshell
import Quickshell.Networking

import "../core"
import "../services"
import "../styles"

// Wi-Fi network picker, opened from the control center card or via
// IPC. Lists visible networks (connected -> saved -> rest), with an
// inline password prompt for new secured networks. Scanning only
// runs while this pane is open.
FocusScope {
    id: root

    readonly property var device: WifiService.wifiDevice

    property var networkList: []
    property int selectedRow: 0

    property bool scanning: false

    property var pskNetwork: null
    property string pskText: ""
    property string pskError: ""

    property string errorName: ""
    property string errorText: ""

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

        if (device) {
            device.scannerEnabled = true
            startScanFeedback()
        }
    }

    Component.onDestruction: {
        if (device)
            device.scannerEnabled = false
    }

    // The backend scan is fire-and-forget: results trickle in via
    // networks.valuesChanged. Keep the rescan icon spinning until
    // results stop arriving, with a hard cap so it can never hang.
    Timer {
        id: scanSpinTimer
        interval: 5000
        repeat: false

        onTriggered: root.scanning = false
    }

    Timer {
        id: scanMaxTimer
        interval: 12000
        repeat: false

        onTriggered: root.scanning = false
    }

    // Add/remove of network objects goes through the ObjectModel.
    // Property-level changes (connected/known) are caught in the
    // delegates so rows re-rank without a polling timer.
    Connections {
        target: root.device ? root.device.networks : null

        function onValuesChanged() {
            if (root.scanning)
                scanSpinTimer.restart()

            Qt.callLater(root.rebuild)
        }
    }

    onSelectedRowChanged: {
        Qt.callLater(function() {
            networkListView.positionViewAtIndex(
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

            if (root.selectedRow < root.networkList.length - 1)
                root.selectedRow++

            event.accepted = true
            break

        case Qt.Key_Return:
        case Qt.Key_Enter:

            root.activateSelected()

            event.accepted = true
            break

        case Qt.Key_Escape:

            if (root.pskNetwork !== null)
                root.cancelPsk()
            else
                IslandController.reset()

            event.accepted = true
            break
        }
    }

    // =========================================================
    // LIST MODEL
    // =========================================================

    function rank(net) {
        return net.connected
            ? 0
            : (net.known ? 1 : 2)
    }

    function strengthOf(net) {
        return typeof net.signalStrength === "number"
            ? net.signalStrength
            : -1
    }

    function better(a, b) {
        if (rank(a) !== rank(b))
            return rank(a) < rank(b)

        return strengthOf(a) > strengthOf(b)
    }

    // Collapse multiple APs sharing an SSID down to the best backing
    // network, then sort connected -> saved -> name.
    function rebuild() {
        const list = []

        if (root.device) {
            const nets = root.device.networks.values
            const byName = {}

            for (let i = 0; i < nets.length; ++i) {
                const net = nets[i]

                if (!net || !net.name || net.name === "")
                    continue

                const prev = byName[net.name]

                if (!prev || better(net, prev))
                    byName[net.name] = net
            }

            for (const key in byName)
                list.push(byName[key])

            list.sort(function(a, b) {
                if (rank(a) !== rank(b))
                    return rank(a) - rank(b)

                return String(a.name).localeCompare(String(b.name))
            })
        }

        root.networkList = list

        if (root.selectedRow >= list.length)
            root.selectedRow = Math.max(0, list.length - 1)
    }

    // =========================================================
    // ACTIONS
    // =========================================================

    function isOpen(net) {
        return net
            && (net.security === WifiSecurityType.Open
                || net.security === WifiSecurityType.Owe)
    }

    function locked(net) {
        return !isOpen(net)
    }

    function primaryAction(net) {
        if (!net || !WifiService.enabled)
            return

        root.errorName = ""
        root.errorText = ""

        if (net.connected) {
            net.disconnect()
            return
        }

        if (net.state === ConnectionState.Connecting) {
            net.disconnect()
            return
        }

        if (net.known || isOpen(net)) {
            net.connect()
            return
        }

        openPskPrompt(net)
    }

    function openPskPrompt(net) {
        root.pskNetwork = net
        root.pskText = ""
        root.pskError = ""
    }

    function submitPsk() {
        if (!root.pskNetwork || root.pskText === "")
            return

        const net = root.pskNetwork

        root.pskNetwork = null
        root.pskError = ""
        net.connectWithPsk(root.pskText)
        root.forceActiveFocus()
    }

    function cancelPsk() {
        root.pskNetwork = null
        root.pskText = ""
        root.pskError = ""
        root.forceActiveFocus()
    }

    function activateSelected() {
        if (root.networkList.length === 0)
            return

        primaryAction(
            root.networkList[
                Math.min(root.selectedRow, root.networkList.length - 1)
            ]
        )
    }

    function startScanFeedback() {
        root.scanning = true
        scanSpinTimer.restart()
        scanMaxTimer.restart()
    }

    function rescan() {
        if (!root.device)
            return

        startScanFeedback()

        root.device.scannerEnabled = false

        Qt.callLater(function() {
            if (root.device)
                root.device.scannerEnabled = true
        })
    }

    // =========================================================
    // LABELS
    // =========================================================

    function signalGlyph(strength) {
        if (strength >= 0.8)
            return "󰤨"

        if (strength >= 0.6)
            return "󰤥"

        if (strength >= 0.4)
            return "󰤢"

        if (strength >= 0.2)
            return "󰤟"

        return "󰤯"
    }

    function securityLabel(net) {
        if (!net)
            return ""

        switch (net.security) {
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3 Enterprise"

        case WifiSecurityType.Sae:
            return "WPA3"

        case WifiSecurityType.Wpa2Eap:
            return "WPA2 Enterprise"

        case WifiSecurityType.Wpa2Psk:
            return "WPA2"

        case WifiSecurityType.WpaEap:
            return "WPA Enterprise"

        case WifiSecurityType.WpaPsk:
            return "WPA"

        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP"

        case WifiSecurityType.Leap:
            return "LEAP"

        case WifiSecurityType.Owe:
            return "OWE"

        case WifiSecurityType.Open:
            return "Open"

        default:
            return ""
        }
    }

    function statusText(net) {
        if (root.errorName === net.name && root.errorText !== "")
            return root.errorText

        if (net.connected) {
            const pct = typeof net.signalStrength === "number"
                ? Math.round(net.signalStrength * 100) + "%"
                : ""

            return pct !== ""
                ? "Connected · " + pct
                : "Connected"
        }

        if (net.state === ConnectionState.Connecting)
            return "Connecting..."

        if (net.state === ConnectionState.Disconnecting)
            return "Disconnecting..."

        const sec = securityLabel(net)

        if (net.known)
            return sec !== ""
                ? "Saved · " + sec
                : "Saved"

        return sec
    }

    function primaryLabel(net) {
        if (net.connected)
            return "Disconnect"

        if (net.state === ConnectionState.Connecting)
            return "Cancel"

        if (net.known || isOpen(net))
            return "Connect"

        return "Join"
    }

    function isNeutralAction(net) {
        return net.connected
            || net.state === ConnectionState.Connecting
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
                text: "Wi-Fi"
                color: Theme.textPrimary
                font.pixelSize: 20
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                Layout.maximumWidth: 150
                visible: WifiService.enabled
                text: WifiService.subtitle
                color: Theme.textSecondary
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                visible: WifiService.enabled
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
                color: WifiService.enabled
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
                    onTapped: WifiService.toggle()
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    y: 3
                    x: WifiService.enabled
                        ? parent.width - width - 3
                        : 3
                    color: WifiService.enabled
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

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 14
            color: Theme.surface
            border.width: 1
            border.color: root.pskError !== ""
                ? Theme.danger
                : Theme.borderSelected
            visible: root.pskNetwork !== null

            onVisibleChanged: {
                if (visible) {
                    pskInput.text = ""
                    pskInput.forceActiveFocus()
                } else {
                    root.forceActiveFocus()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: "󰌾"
                    color: Theme.textSecondary
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.pskError !== ""
                            ? root.pskError
                            : (root.pskNetwork
                                ? "Password for " + root.pskNetwork.name
                                : "")
                        color: root.pskError !== ""
                            ? Theme.danger
                            : Theme.textSecondary
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    TextInput {
                        id: pskInput
                        Layout.fillWidth: true
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        selectByMouse: true
                        clip: true
                        inputMethodHints: Qt.ImhHiddenText
                            | Qt.ImhNoPredictiveText

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pskInput.text === ""
                            text: "Password"
                            color: Theme.textMuted
                            font.family: pskInput.font.family
                            font.pixelSize: pskInput.font.pixelSize
                        }

                        onTextEdited: root.pskText = text

                        Keys.onReturnPressed: function(event) {
                            root.submitPsk()
                            event.accepted = true
                        }

                        Keys.onEnterPressed: function(event) {
                            root.submitPsk()
                            event.accepted = true
                        }

                        Keys.onEscapePressed: function(event) {
                            root.cancelPsk()
                            event.accepted = true
                        }

                        Keys.onUpPressed: function(event) {
                            if (root.selectedRow > 0)
                                root.selectedRow--

                            event.accepted = true
                        }

                        Keys.onDownPressed: function(event) {
                            if (root.selectedRow < root.networkList.length - 1)
                                root.selectedRow++

                            event.accepted = true
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 64
                    implicitHeight: 30
                    radius: 15
                    color: cancelHover.hovered
                        ? Theme.buttonHover
                        : Theme.buttonBackground

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animationFast
                        }
                    }

                    HoverHandler {
                        id: cancelHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: function(event) {
                            event.accepted = true
                            root.cancelPsk()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 86
                    implicitHeight: 30
                    radius: 15
                    color: Theme.accent
                    opacity: root.pskText.length > 0 ? 1 : 0.4

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animationFast
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: function(event) {
                            event.accepted = true
                            root.submitPsk()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: Theme.background
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Text {
            visible: !WifiService.enabled || root.networkList.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: !WifiService.enabled
                ? "Wi-Fi is off"
                : root.scanning
                    ? "Scanning..."
                    : "No networks found"
            color: Theme.textSecondary
            font.pixelSize: 12
        }

        ListView {
            id: networkListView
            visible: WifiService.enabled && root.networkList.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 400)
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: root.networkList

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                id: row

                required property int index
                required property var modelData

                width: networkListView.width
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

                    function onConnectionFailed(reason) {
                        root.errorName = row.modelData.name
                        root.errorText = "Connection failed"

                        if (
                            reason === ConnectionFailReason.NoSecrets
                            || reason === ConnectionFailReason.WifiAuthTimeout
                        ) {
                            root.errorText = "Incorrect password"
                            root.openPskPrompt(row.modelData)
                            root.pskError = "Authentication failed — check the password"
                        }
                    }

                    function onConnectedChanged() {
                        if (row.modelData.connected
                            && root.errorName === row.modelData.name) {

                            root.errorName = ""
                            root.errorText = ""
                        }

                        Qt.callLater(root.rebuild)
                    }

                    function onKnownChanged() {
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

                    Row {
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.signalGlyph(row.modelData.signalStrength)
                            color: row.modelData.connected
                                ? Theme.success
                                : Theme.textPrimary
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.locked(row.modelData)
                            text: "󰌾"
                            color: Theme.iconDisabled
                            font.family: Theme.iconFont
                            font.pixelSize: 11
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.statusText(row.modelData)
                            color: root.errorName === row.modelData.name
                                ? Theme.danger
                                : row.modelData.connected
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
                        visible: row.modelData.known || row.modelData.connected
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
