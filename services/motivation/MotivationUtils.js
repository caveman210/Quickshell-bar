.pragma library

// Shared local-day helpers for the motivation services: the bar's
// daily greeting/tidbit and the online quote of the day both roll
// over at local midnight.

function dayKey(ts) {
    var d = new Date(ts)

    return "" + d.getFullYear() + "-" + (d.getMonth() + 1)
            + "-" + d.getDate()
}

function dailySeed(ts) {
    var key = dayKey(ts)
    var hash = 0

    for (var i = 0; i < key.length; i++)
        hash = ((hash << 5) - hash + key.charCodeAt(i)) | 0

    var mixed = Math.sin(hash) * 10000

    return Math.floor((mixed - Math.floor(mixed)) * 1000000)
}
