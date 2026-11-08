import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../styles"
import "../panels"

// Standalone Calendar Dropdown for Bar mode when clicking the time
Item {
    id: root
    implicitWidth: 320
    implicitHeight: calendar.implicitHeight

    CalendarView {
        id: calendar
        anchors.fill: parent
    }
}
