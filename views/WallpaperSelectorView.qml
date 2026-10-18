import QtQuick

import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

// Carousel wallpaper picker. Images are whatever lives in
// ~/Pictures/Wallpapers; the centered card is the selection and
// Apply pushes it through WallpaperService (toast included there).
FocusScope {
    id: root
    implicitWidth: 550
    implicitHeight: 352
    focus: true

    readonly property int count: WallpaperService.wallpapers.count
    readonly property int currentIndex: IslandState.wallpaperSelection

    Component.onCompleted: {
        forceActiveFocus()

        if (currentIndex >= count)
            IslandState.wallpaperSelection = 0
    }

    function offsetFor(index) {
        if (count <= 0)
            return 0

        var d = (index - currentIndex) % count

        if (d > count / 2)
            d -= count
        else if (d < -count / 2)
            d += count

        return d
    }

    function step(delta) {
        if (count <= 1)
            return

        IslandState.wallpaperSelection =
            ((currentIndex + delta) % count + count) % count
    }

    function applyCurrent() {
        if (count <= 0)
            return

        var item = WallpaperService.wallpapers.get(currentIndex)

        if (item)
            WallpaperService.apply(item.path)

        IslandController.reset()
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 22
        anchors.bottomMargin: 22
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 24

        Item {
            id: header
            width: parent.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpapers"
                font.pixelSize: 20
                color: Theme.textPrimary
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.count > 0
                    ? (root.currentIndex + 1) + " / " + root.count
                    : ""
                font.pixelSize: 13
                color: Theme.textSecondary
            }
        }

        Item {
            id: carousel
            width: parent.width
            height: 196

            Text {
                anchors.centerIn: parent
                visible: root.count === 0
                text: "No wallpapers in ~/Pictures/Wallpapers"
                font.pixelSize: 13
                color: Theme.textSecondary
            }

            Repeater {
                model: WallpaperService.wallpapers

                delegate: Item {
                    id: card
                    required property int index
                    required property string path

                    readonly property int offset: root.offsetFor(index)
                    readonly property int distance: Math.abs(offset)

                    width: 290
                    height: 175
                    x: carousel.width / 2 - width / 2 + offset * 170
                    y: carousel.height / 2 - height / 2 + distance * 8
                    z: 20 - distance
                    scale: offset === 0 ? 1 : 0.64
                    opacity: offset === 0
                        ? 1
                        : (distance === 1 ? 0.85 : 0.55)

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animationNormal
                            easing.type: Theme.animationHorizontal
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animationNormal
                            easing.type: Theme.animationHorizontal
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animationFast
                        }
                    }

                    // Slight Y-rotation reads the row as a drum; the
                    // outer cards also sit a touch lower.
                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: card.offset * 28

                        Behavior on angle {
                            NumberAnimation {
                                duration: Theme.animationNormal
                                easing.type: Theme.animationHorizontal
                            }
                        }
                    }

                    WallpaperCard {
                        anchors.fill: parent
                        imageSource: card.path
                        selected: card.offset === 0
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (card.offset !== 0)
                                IslandState.wallpaperSelection = card.index
                        }
                    }
                }
            }

            Rectangle {
                id: leftArrow
                visible: root.count > 1
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                z: 40
                width: 32
                height: 32
                radius: 16
                color: leftHover.hovered
                    ? Theme.surfaceVariant
                    : Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: Theme.textPrimary
                }

                HoverHandler {
                    id: leftHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.step(-1)
                }
            }

            Rectangle {
                id: rightArrow
                visible: root.count > 1
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                z: 40
                width: 32
                height: 32
                radius: 16
                color: rightHover.hovered
                    ? Theme.surfaceVariant
                    : Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: Theme.textPrimary
                }

                HoverHandler {
                    id: rightHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.step(1)
                }
            }
        }

        Item {
            id: applyRow
            width: parent.width
            height: 36

            Rectangle {
                id: applyButton
                anchors.centerIn: parent
                width: 150
                height: 36
                radius: 18
                opacity: root.count === 0 ? 0.5 : 1
                color: root.count === 0
                    ? Theme.surface
                    : (applyHover.hovered
                        ? Qt.lighter(Theme.accent, 1.15)
                        : Theme.accent)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animationFast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Apply"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.background
                }

                HoverHandler {
                    id: applyHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.applyCurrent()
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Escape:
            IslandController.reset()
            event.accepted = true
            break

        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.applyCurrent()
            event.accepted = true
            break

        case Qt.Key_Left:
        case Qt.Key_H:
            root.step(-1)
            event.accepted = true
            break

        case Qt.Key_Right:
        case Qt.Key_L:
            root.step(1)
            event.accepted = true
            break
        }
    }
}
