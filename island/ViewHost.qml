import QtQuick

import "../views"
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
            if (
                IslandState.mode === IslandState.defaultMode &&
                StatusManager.visible
            )
                return overlayView

            switch (IslandState.mode) {
            case IslandState.expandedMode:
                return expandedView

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

            default:
                return IslandState.shape === IslandState.shapeNotch
                    ? notchView
                    : defaultView
            }
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
}
