import QtQuick
import Quickshell
import Quickshell.Widgets

import "../../styles"
import "../../core"

// One inline system tray item for the bar layout. Left click activates
// the item (or opens its menu when it is menu-only); right click opens
// the menu whenever the item has one. The menu drops down right below
// this icon, themed like the bar (native platform menus cannot attach
// to layer-shell windows on wlroots compositors).
Item {
    id: root

    property var item

    implicitWidth: 26
    implicitHeight: 26

    function openMenu(menu) {
        var p = root.mapToItem(null, root.width / 2, 0)

        IslandController.openTrayItemMenu(menu, p.x)
    }

    // Some items (e.g. stremio's ayatana icon) hand out image:// URLs
    // directly; the checked lookup rejects those, so fall back to the
    // raw value. Cached per icon string — resolution is pure.
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

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: trayIconHover.hovered ? Theme.surface : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animationFast }
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: root.iconSource(root.item ? root.item.icon : "")
    }

    HoverHandler {
        id: trayIconHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton

        onTapped: {
            if (!root.item)
                return

            if (root.item.onlyMenu)
                root.openMenu(root.item.menu)
            else
                root.item.activate()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton

        onTapped: {
            if (root.item && root.item.hasMenu)
                root.openMenu(root.item.menu)
        }
    }
}
