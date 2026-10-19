import QtQuick

import "../views/bar"
import "../views/pill"
import "../views/notch"
import "../views/panels"
import "../views/shared"
import "../core"

Item {
    id: root
    implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
    implicitHeight: viewLoader.item ? viewLoader.item.implicitHeight : 0

    Loader {
        id: viewLoader
        anchors.centerIn: parent
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0

        sourceComponent: {
            if (IslandState.mode === IslandState.defaultMode) {
                // Bar layout keeps its default content in BarView;
                // the dropdown slot is empty until a mode opens.
                if (IslandState.layoutIsBar)
                    return null

                if (StatusManager.visible)
                    return overlayView

                return IslandState.layout === IslandState.layoutNotch
                    ? notchView
                    : defaultView
            }

            switch (IslandState.mode) {
            case IslandState.expandedMode:
                return IslandState.layoutIsBar
                    ? barExpandedView
                    : expandedView

            case IslandState.powerMenuMode:
                return powerMenuView

            case IslandState.controlCenterMode:
                return controlCenterView

            case IslandState.themeSelectorMode:
                return themeSelectorView

            case IslandState.wallpaperSelectorMode:
                return wallpaperSelectorView

            case IslandState.mediaControlsMode:
                return mediaView

            case IslandState.privacyMenuMode:
                return privacyMenuView

            case IslandState.wifiMenuMode:
                return wifiMenuView

            case IslandState.bluetoothMenuMode:
                return bluetoothMenuView

            case IslandState.systemMenuMode:
                return systemMenuView

            case IslandState.notificationsMode:
                return notificationsView

            case IslandState.quoteMode:
                return quoteView
            }

            return null
        }
    }

    Component {
        id: defaultView
        DefaultView { }
    }

    Component {
        id: notchView
        NotchView { }
    }

    Component {
        id: overlayView
        OverlayView { }
    }

    Component {
        id: expandedView
        ExpandedView { }
    }

    Component {
        id: barExpandedView
        BarExpandedView { }
    }

    Component {
        id: powerMenuView
        PowerMenuView { }
    }

    Component {
        id: controlCenterView
        ControlCenterView { }
    }

    Component {
        id: themeSelectorView
        ThemeSelectorView { }
    }

    Component {
        id: wallpaperSelectorView
        WallpaperSelectorView { }
    }

    Component {
        id: mediaView
        MediaView { }
    }

    Component {
        id: privacyMenuView
        PrivacyMenuView { }
    }

    Component {
        id: wifiMenuView
        WifiMenuView { }
    }

    Component {
        id: bluetoothMenuView
        BluetoothMenuView { }
    }

    Component {
        id: systemMenuView
        SystemMenuView { }
    }

    Component {
        id: notificationsView
        NotificationsView { }
    }

    Component {
        id: quoteView
        QuoteView { }
    }
}
