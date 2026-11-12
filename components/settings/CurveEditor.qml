import QtQuick
import QtQuick.Layouts

import "../../styles"
import "../../config"
import "../../services/display"

Rectangle {
    id: root

    implicitWidth: parent ? parent.width : 400
    implicitHeight: 250
    radius: 12
    color: Theme.background
    border.width: 1
    border.color: Theme.border
    clip: true

    readonly property string activeCurve: ConfigStore.nightLightCurveType
    readonly property int durationMins: ConfigStore.nightLightTransitionMins

    function applyPreset(name) {
        ConfigStore.nightLightCurveType = name
        if (name === "scurve") {
            ConfigStore.nightLightControlPoints = [
                {"x": 0.0, "y": 0.0},
                {"x": 0.35, "y": 0.08},
                {"x": 0.65, "y": 0.92},
                {"x": 1.0, "y": 1.0}
            ]
        } else if (name === "linear") {
            ConfigStore.nightLightControlPoints = [
                {"x": 0.0, "y": 0.0},
                {"x": 0.33, "y": 0.33},
                {"x": 0.66, "y": 0.66},
                {"x": 1.0, "y": 1.0}
            ]
        } else if (name === "ease_in") {
            ConfigStore.nightLightControlPoints = [
                {"x": 0.0, "y": 0.0},
                {"x": 0.40, "y": 0.10},
                {"x": 0.80, "y": 0.45},
                {"x": 1.0, "y": 1.0}
            ]
        } else if (name === "ease_out") {
            ConfigStore.nightLightControlPoints = [
                {"x": 0.0, "y": 0.0},
                {"x": 0.20, "y": 0.55},
                {"x": 0.60, "y": 0.90},
                {"x": 1.0, "y": 1.0}
            ]
        }
        ConfigStore.save()
        canvas.requestPaint()
        NightLightService.recheckSchedule()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header: Preset selection chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Progression Curve"
                color: Theme.textSecondary
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 4

                Repeater {
                    model: [
                        { "id": "scurve", "label": "S-Curve" },
                        { "id": "linear", "label": "Linear" },
                        { "id": "ease_in", "label": "Ease In" },
                        { "id": "ease_out", "label": "Ease Out" }
                    ]

                    Rectangle {
                        required property var modelData
                        width: presetText.implicitWidth + 12
                        height: 22
                        radius: 6
                        color: root.activeCurve === modelData.id ? Theme.accent : Theme.surface
                        border.width: 1
                        border.color: root.activeCurve === modelData.id ? Theme.accent : Theme.border

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: root.activeCurve === parent.modelData.id ? Theme.background : Theme.textPrimary
                            font.pixelSize: 10
                            font.bold: root.activeCurve === parent.modelData.id
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: root.applyPreset(parent.modelData.id)
                        }
                    }
                }
            }
        }

        // Graph Area (Fully contained and padded)
        Item {
            id: graphArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            readonly property real padLeft: 34
            readonly property real padRight: 18
            readonly property real padTop: 12
            readonly property real padBottom: 22

            readonly property real plotW: Math.max(10, width - padLeft - padRight)
            readonly property real plotH: Math.max(10, height - padTop - padBottom)

            // Canvas strictly within bounded coordinate system
            Canvas {
                id: canvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var ox = graphArea.padLeft
                    var oy = graphArea.padTop
                    var pw = graphArea.plotW
                    var ph = graphArea.plotH

                    // Background plot fill
                    ctx.fillStyle = Theme.card
                    ctx.beginPath()
                    ctx.rect(ox, oy, pw, ph)
                    ctx.fill()

                    // Grid lines & plot border
                    ctx.strokeStyle = Theme.borderSubtle
                    ctx.lineWidth = 1
                    for (var gi = 0; gi <= 4; gi++) {
                        var gy = oy + (ph * gi) / 4
                        ctx.beginPath()
                        ctx.moveTo(ox, gy)
                        ctx.lineTo(ox + pw, gy)
                        ctx.stroke()

                        var gx = ox + (pw * gi) / 4
                        ctx.beginPath()
                        ctx.moveTo(gx, oy)
                        ctx.lineTo(gx, oy + ph)
                        ctx.stroke()
                    }

                    // Outer graph boundary
                    ctx.strokeStyle = Theme.border
                    ctx.lineWidth = 1
                    ctx.strokeRect(ox, oy, pw, ph)

                    // Curve path
                    ctx.strokeStyle = Theme.accent
                    ctx.lineWidth = 2.5
                    ctx.beginPath()

                    var steps = 80
                    for (var s = 0; s <= steps; s++) {
                        var t = s / steps
                        var v = NightLightService.evaluateCurveProgress(t)
                        var cx = ox + t * pw
                        var cy = oy + (1.0 - v) * ph
                        if (s === 0) ctx.moveTo(cx, cy)
                        else ctx.lineTo(cx, cy)
                    }
                    ctx.stroke()

                    // Subtle gradient fill under curve
                    ctx.lineTo(ox + pw, oy + ph)
                    ctx.lineTo(ox, oy + ph)
                    ctx.closePath()
                    ctx.fillStyle = "#E5E7EB12"
                    ctx.fill()
                }

                Connections {
                    target: ConfigStore
                    function onNightLightCurveTypeChanged() { canvas.requestPaint() }
                    function onNightLightControlPointsChanged() { canvas.requestPaint() }
                }
            }

            // Labels with Theme colors
            Text {
                x: graphArea.padLeft - 28
                y: graphArea.padTop - 4
                text: "100%"
                color: Theme.textMuted
                font.pixelSize: 9
            }

            Text {
                x: graphArea.padLeft - 22
                y: graphArea.padTop + graphArea.plotH - 8
                text: "0%"
                color: Theme.textMuted
                font.pixelSize: 9
            }

            Text {
                x: graphArea.padLeft - 4
                y: graphArea.padTop + graphArea.plotH + 4
                text: "0m"
                color: Theme.textMuted
                font.pixelSize: 9
            }

            Text {
                x: graphArea.padLeft + graphArea.plotW - 18
                y: graphArea.padTop + graphArea.plotH + 4
                text: root.durationMins + "m"
                color: Theme.textMuted
                font.pixelSize: 9
            }

            // Interactive Draggable Nodes
            Repeater {
                id: handleRepeater
                model: ConfigStore.nightLightControlPoints ? ConfigStore.nightLightControlPoints.length : 0

                Item {
                    id: pointHandle
                    required property int index

                    readonly property var ptData: (ConfigStore.nightLightControlPoints && index < ConfigStore.nightLightControlPoints.length)
                        ? ConfigStore.nightLightControlPoints[index]
                        : ({"x": 0, "y": 0})

                    x: graphArea.padLeft + (ptData.x * graphArea.plotW) - width / 2
                    y: graphArea.padTop + ((1.0 - ptData.y) * graphArea.plotH) - height / 2
                    width: 18
                    height: 18
                    z: 5

                    Rectangle {
                        anchors.centerIn: parent
                        width: mouseHandle.containsMouse || mouseHandle.drag.active ? 13 : 9
                        height: width
                        radius: width / 2
                        color: mouseHandle.drag.active ? Theme.textPrimary : Theme.accent
                        border.width: 2
                        border.color: Theme.background
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        id: mouseHandle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: graphArea.padLeft - parent.width / 2
                        drag.maximumX: graphArea.padLeft + graphArea.plotW - parent.width / 2
                        drag.minimumY: graphArea.padTop - parent.height / 2
                        drag.maximumY: graphArea.padTop + graphArea.plotH - parent.height / 2

                        onPositionChanged: {
                            if (drag.active) {
                                var relX = Math.max(0.0, Math.min(1.0, (parent.x + parent.width / 2 - graphArea.padLeft) / graphArea.plotW))
                                var relY = Math.max(0.0, Math.min(1.0, 1.0 - (parent.y + parent.height / 2 - graphArea.padTop) / graphArea.plotH))

                                var points = JSON.parse(JSON.stringify(ConfigStore.nightLightControlPoints))
                                points[pointHandle.index] = {
                                    "x": Math.round(relX * 100) / 100,
                                    "y": Math.round(relY * 100) / 100
                                }

                                if (pointHandle.index === 0) points[0].x = 0.0
                                if (pointHandle.index === points.length - 1) points[points.length - 1].x = 1.0

                                ConfigStore.nightLightControlPoints = points
                                ConfigStore.nightLightCurveType = "custom"
                                ConfigStore.save()
                                canvas.requestPaint()
                                NightLightService.recheckSchedule()
                            }
                        }
                    }
                }
            }
        }

        // Bottom Bar: Duration adjust and Target Warmth readout
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Transition Duration:"
                color: Theme.textSecondary
                font.pixelSize: 11
            }

            Rectangle {
                width: 24
                height: 22
                radius: 5
                color: Theme.buttonBackground
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "-"
                    color: Theme.buttonText
                    font.pixelSize: 12
                    font.bold: true
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (ConfigStore.nightLightTransitionMins > 1) {
                            ConfigStore.nightLightTransitionMins = Math.max(1, ConfigStore.nightLightTransitionMins - 5)
                            ConfigStore.save()
                            canvas.requestPaint()
                            NightLightService.recheckSchedule()
                        }
                    }
                }
            }

            Text {
                text: ConfigStore.nightLightTransitionMins + "m"
                color: Theme.textPrimary
                font.bold: true
                font.pixelSize: 11
            }

            Rectangle {
                width: 24
                height: 22
                radius: 5
                color: Theme.buttonBackground
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: Theme.buttonText
                    font.pixelSize: 12
                    font.bold: true
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (ConfigStore.nightLightTransitionMins < 120) {
                            ConfigStore.nightLightTransitionMins = Math.min(120, ConfigStore.nightLightTransitionMins + 5)
                            ConfigStore.save()
                            canvas.requestPaint()
                            NightLightService.recheckSchedule()
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 22
                implicitWidth: tempRow.implicitWidth + 12
                radius: 6
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: tempRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "󰔎"; font.family: Theme.iconFont; font.pixelSize: 11; color: Theme.accent }
                    Text { text: ConfigStore.nightLightTargetTemp + "K"; color: Theme.textPrimary; font.pixelSize: 10; font.bold: true }
                }
            }
        }
    }
}
