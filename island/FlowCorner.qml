import QtQuick
import "../styles"

// Concave "flow corner": a quarter-circle gusset that smoothly joins
// a horizontal edge running along the top (y = 0) to a vertical edge
// running down the right side (x = radius). With mirror it flips for
// the opposite corner. Purely decorative.
Item {
    id: root

    property real radius: Theme.radiusLarge
    property color color: Theme.background
    property bool mirror: false

    implicitWidth: radius
    implicitHeight: radius

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            var r = root.radius

            ctx.reset()
            ctx.beginPath()

            if (root.mirror) {
                ctx.moveTo(r, 0)
                ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true)
                ctx.lineTo(0, 0)
            } else {
                ctx.moveTo(0, 0)
                ctx.arc(0, r, r, -Math.PI / 2, 0, false)
                ctx.lineTo(r, 0)
            }

            ctx.closePath()
            ctx.fillStyle = String(root.color)
            ctx.fill()
        }

        Connections {
            target: root

            function onRadiusChanged() { canvas.requestPaint() }
            function onMirrorChanged() { canvas.requestPaint() }
            function onColorChanged() { canvas.requestPaint() }
        }
    }
}
