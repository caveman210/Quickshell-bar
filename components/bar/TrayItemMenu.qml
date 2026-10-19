import QtQuick

import Quickshell
import Quickshell.Widgets

import "../../styles"
import "../../core"
import "../../island"

// SNI / DBusMenu tree for one tray item, rendered in QML because
// native platform menus cannot attach to quickshell's layer-shell
// windows on wlroots compositors. Island draws the slab under the
// icon that opened it (see TrayItemMenu in Island.qml). Supports
// separators, disabled entries, checkbox / radio state, submenus
// (drill in, back out) and triggers.
Item {
    id: root

    // Kept narrow enough to read as a menu, not a panel.
    implicitWidth: 230

    readonly property var baseMenu: IslandState.trayItemMenu

    // Drilled-in submenu levels: [{ handle: QsMenuHandle, title }].
    property var stack: []

    // Handle the opener reads. Kept imperative: a binding through the
    // stack into QsMenuOpener trips QML's binding loop detector.
    property var currentMenu: null

    function updateCurrentMenu() {
        currentMenu = stack.length > 0
            ? stack[stack.length - 1].handle
            : baseMenu
    }
    readonly property string parentTitle: stack.length > 0
        ? stack[stack.length - 1].title
        : ""

    readonly property var entries: opener.children ? opener.children.values : []

    readonly property int maxListHeight: 320
    readonly property int contentHeight: {
        if (entries.length === 0)
            return 40

        var height = 0

        for (var i = 0; i < entries.length; ++i)
            height += entries[i].isSeparator ? 11 : 40

        return height - 2
    }
    readonly property int listHeight: Math.min(contentHeight, maxListHeight)
    readonly property int backHeight: stack.length > 0 ? 32 : 0

    implicitHeight: backHeight + listHeight + 16

    // Same checked-then-raw icon resolution as TrayIcon; cached so
    // repeated delegate re-evaluations skip the icon-path probes.
    property var _iconCache: ({})

    function iconSource(icon) {
        if (!icon)
            return ""

        var cached = root._iconCache[icon]

        if (cached !== undefined)
            return cached

        var checked = Quickshell.iconPath(icon, true)
        var result = checked !== "" ? checked : icon

        root._iconCache[icon] = result

        return result
    }

    // DBusMenu round trip: force a layout refresh so the tree is
    // populated, then tell the app the menu is open.
    function sendOpened(handle) {
        if (!handle)
            return

        if (handle.updateLayout)
            handle.updateLayout()

        if (handle.sendOpened)
            handle.sendOpened()
    }

    function push(entry) {
        root.stack = root.stack.concat([{ handle: entry, title: entry.text }])
        updateCurrentMenu()
        sendOpened(entry)
    }

    function pop() {
        if (root.stack.length === 0)
            return

        var top = root.stack[root.stack.length - 1]
        root.stack = root.stack.slice(0, root.stack.length - 1)
        updateCurrentMenu()

        if (top.handle && top.handle.sendClosed)
            top.handle.sendClosed()
    }

    onBaseMenuChanged: {
        root.stack = []
        updateCurrentMenu()

        if (root.baseMenu !== null)
            sendOpened(root.baseMenu)
    }

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    // Back row (submenu navigation).
    Item {
        id: backRow
        visible: root.stack.length > 0
        x: 8
        y: 8
        width: root.width - 16
        height: root.backHeight - 2

        Rectangle {
            anchors.fill: parent
            radius: 9
            color: backHover.hovered ? Theme.surface : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.animationFast }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "‹  " + root.parentTitle
            color: Theme.textPrimary
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        HoverHandler {
            id: backHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.pop()
        }
    }

    ListView {
        id: list
        x: 8
        y: 8 + root.backHeight
        width: root.width - 16
        height: root.listHeight
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.entries

        delegate: Item {
            id: row

            required property var modelData

            readonly property var entry: modelData
            readonly property bool isSeparator: entry.isSeparator
            readonly property bool isEnabled: !isSeparator && entry.enabled
            readonly property bool showCheck: !isSeparator
                && entry.buttonType !== QsMenuButtonType.None
            readonly property bool showIcon: !isSeparator && entry.icon !== ""

            readonly property real iconLeft: showCheck ? 32 : 10
            readonly property real textLeft:
                (showCheck ? 32 : 10) + (showIcon ? 24 : 0)

            width: list.width
            height: isSeparator ? 9 : 38

            Rectangle {
                visible: row.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 6
                height: 1
                color: Theme.border
            }

            Rectangle {
                visible: !row.isSeparator
                anchors.fill: parent
                radius: 9
                color: rowHover.hovered && row.isEnabled
                    ? Theme.surface
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.animationFast }
                }
            }

            Text {
                id: checkText
                visible: row.showCheck
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                horizontalAlignment: Text.AlignHCenter
                text: row.entry.checkState === Qt.Checked
                    ? row.entry.buttonType === QsMenuButtonType.RadioButton
                        ? "●"
                        : "✓"
                    : ""
                color: Theme.accent
                font.pixelSize: row.entry.buttonType === QsMenuButtonType.RadioButton
                    ? 9
                    : 12
            }

            IconImage {
                id: rowIcon
                visible: row.showIcon
                anchors.left: parent.left
                anchors.leftMargin: row.iconLeft
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                opacity: row.isEnabled ? 1 : 0.45
                source: root.iconSource(row.entry.icon)
            }

            Text {
                visible: !row.isSeparator
                x: row.textLeft
                width: parent.width - x - (chevron.visible ? 30 : 10)
                anchors.verticalCenter: parent.verticalCenter
                text: row.entry.text
                color: Theme.textPrimary
                opacity: row.isEnabled ? 1 : 0.45
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: chevron
                visible: !row.isSeparator && row.entry.hasChildren
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: Theme.textPrimary
                opacity: row.isEnabled ? 1 : 0.45
                font.pixelSize: 15
            }

            HoverHandler {
                id: rowHover
                enabled: row.isEnabled
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                enabled: row.isEnabled
                gesturePolicy: TapHandler.ReleaseWithinBounds

                onTapped: {
                    if (row.entry.hasChildren) {
                        root.push(row.entry)
                    } else {
                        row.entry.triggered()
                        IslandController.closeTrayItemMenu()
                    }
                }
            }
        }
    }

    // Layout not received yet, or the app publishes no actions.
    Text {
        visible: root.entries.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8 + root.backHeight + 13
        text: "No actions"
        color: Theme.textPrimary
        opacity: 0.5
        font.pixelSize: 13
    }
}
