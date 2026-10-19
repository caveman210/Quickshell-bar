import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../styles"
import "../shared"
import "../../components/sections"
import "../../services"
import "../../services/audio"
import "../../services/display"

// Expanded dropdown for the bar layout: expanded content minus
// anything the bar already shows (time, wifi/bluetooth/battery,
// privacy, power) — date plus the volume and brightness sliders.
Item {
    id: root
    implicitWidth: 460

    readonly property real maxViewHeight: 0.65 * (
        Quickshell.screens.length > 0
            ? Quickshell.screens[0].height
            : 1080
    )

    implicitHeight: Math.min(layout.implicitHeight + 44, maxViewHeight)

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        DateView {
            Layout.alignment: Qt.AlignHCenter
        }

        ControlSlider {
            Layout.fillWidth: true
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
            Layout.fillWidth: true
            icon: BrightnessService.brightnessIcon
            value: BrightnessService.brightness / 100

            onValueChangedByUser: function(value) {
                BrightnessService.setBrightness(
                    value * 100
                )
            }
        }
    }
}
