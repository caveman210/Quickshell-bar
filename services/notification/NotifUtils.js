.pragma library

// Pure, stateless helpers for notifications: grouped by concern,
// shared by NotificationModel (grouping, parsing) and the
// NotificationService facade (snapshot building, view delegates).

// ---- text helpers --------------------------------------------

function stripTags(s) {
    return String(s || "").replace(/<[^>]*>/g, "")
}

function previewText(s) {
    var t = stripTags(s).replace(/\s+/g, " ").trim()

    return t.length > 140 ? t.substring(0, 140) + "…" : t
}

function normalizeTitle(s) {
    return String(s || "")
        .replace(/\s*[\(\[]\d+[\)\]]\s*$/, "")
        .trim()
}

function escapeHtml(s) {
    return String(s || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
}

function messageText(msg) {
    if (!msg)
        return ""

    if (msg.sender)
        return "<b>" + escapeHtml(msg.sender) + "</b>: " + msg.body

    return msg.body !== "" ? msg.body : msg.summary
}

function formatTime(ts) {
    var d = new Date(ts)
    var now = new Date()
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var hh = ("0" + d.getHours()).slice(-2)
    var mm = ("0" + d.getMinutes()).slice(-2)

    if (
        d.getDate() === now.getDate() &&
        d.getMonth() === now.getMonth() &&
        d.getFullYear() === now.getFullYear()
    )
        return hh + ":" + mm

    var label = d.getDate() + " " + months[d.getMonth()]

    if (d.getFullYear() !== now.getFullYear())
        label += " " + d.getFullYear()

    return label
}

// ---- grouping -------------------------------------------------

function groupTitle(rec) {
    var t = normalizeTitle(rec.summary)

    if (t !== "")
        return t

    return String(rec.app || "") || "Notification"
}

function looksLikeCall(rec) {
    var combined = String(rec.summary || "") + " " + String(rec.body || "")

    if (!/\b(call|calling)\b/i.test(combined))
        return false

    if (/\b(incoming|missed|outgoing|declined|voice|video)\b/i.test(combined))
        return true

    return String(rec.urgency || "") === "critical"
}

function groupKey(rec) {
    // Calls get their own section so they never mix with the
    // chat's message bundle. Keyed by seq (durable across
    // sessions) instead of the session-scoped notification id.
    if (looksLikeCall(rec))
        return "call:" + rec.seq

    var norm = normalizeTitle(rec.summary)

    if (norm !== "")
        return "g:" + String(rec.app || "") + "|" + norm

    return "nid:" + rec.id
}

// Group messages arrive as "Name: message" — split so the
// sender can be highlighted in the message list.
function parseSender(body) {
    var m = String(body || "").match(/^([^:\n]{1,40}):\s+([\s\S]+)$/)

    if (m)
        return { sender: m[1].trim(), text: m[2].trim() }

    return { sender: "", text: String(body || "") }
}

// Small square images (e.g. 96x96 from WhatsApp Web via
// Firefox) are chat profile pictures, not message media.
function isAvatarImage(w, h) {
    var ww = Number(w)
    var hh = Number(h)

    if (!(ww > 0) || !(hh > 0))
        return false

    return Math.abs(ww - hh) <= 8 && Math.max(ww, hh) <= 256
}

// ---- snapshot helpers -----------------------------------------

function urgencyName(u) {
    if (u === 0)
        return "low"

    if (u === 2)
        return "critical"

    return "normal"
}

// Store only JSON-safe primitives (image-data hinth already gone:
// Quickshell strips it after decoding into the qsimage URL).
function jsonHints(map) {
    var out = ({})

    if (!map)
        return out

    for (var k in map) {
        var v = map[k]
        var t = typeof v

        if (t === "string" || t === "number" || t === "boolean") {
            out[k] = v
        } else if (v instanceof Array) {
            var arr = []
            var ok = true

            for (var j = 0; j < v.length; j++) {
                var vt = typeof v[j]

                if (vt === "string" || vt === "number" || vt === "boolean")
                    arr.push(v[j])
                else {
                    ok = false
                    break
                }
            }

            if (ok)
                out[k] = arr
        }
    }

    return out
}
