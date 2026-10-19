import QtQuick
import QtQuick.Layouts

import "../shared"
import "../../styles"
import "../../services"
import "../../services/power"
import "../../components/bar"

Item {
    id: root
    // Notch reads as a notch only with a flat top hanging from the
    // screen edge; bottom corners keep the capsule radius. Pill
    // keeps the uniform radius from before.
    //
    // The right end already belongs to the battery glyph, so privacy
    // indicators stay grouped on the left (split: false). Activating
    // one adds the full three-slot run to the base 210 so the run
    // never resizes as individual devices come and go.
    implicitWidth: indicators.anyActive
                       ? 210 + indicators.leftWidth + indicators.rightWidth
                       : 210
    implicitHeight: 33

    PrivacyIndicators {
        id: indicators
        split: false
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        id: row
        spacing: 8
        anchors.centerIn: parent

        ClockView {
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: BatteryService.icon
        color: Theme.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
    }
}