pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../../core"

// Append-only notification history on disk.
//
// Layout: ~/.cache/quickshell/notifications/
//   history/YYYY-MM-DD.jsonl  one file per local day, append-only;
//                             prune() drops whole day files once they
//                             fall out of the retention window
//   assets/<hash>.png         content-addressed media (sha256, first
//                             16 hex), immutable: written once, never
//                             renamed or rewritten
//   assets/.tmp-*             scratch files while a grab copy is in
//                             flight
//
// Record types: new | update | media | close.
//
// Media rules:
//  - identical content is stored once; later references reuse the
//    existing blob and the fresh grab is discarded
//  - a notification's newer avatar becomes a new blob; older records
//    keep resolving to the blob they were written with
//
// Writes stream through a single `tee -a` process (stdin queue) bound
// to the day file of the current local day; the writer is restarted
// when the day rolls over. The files themselves are owned by the shell.
Singleton {
    id: store

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.cache/quickshell/notifications"
    readonly property string historyDir: dir + "/history"
    readonly property string assetsDir: dir + "/assets"

    // 30 days of history. Must stay double: 30d in ms exceeds int32.
    property double retentionMs: 30 * 24 * 60 * 60 * 1000

    // Smallest saved avatar dimension; smaller grabs are discarded.
    property int minGrabDim: 48

    // Long-edge cap for grabbed avatars.
    property int maxGrabDim: 2048

    property bool loaded: false

    // True only after the day files were actually listed and read.
    // Guards prune() so a missing/broken directory can never mark
    // live assets as unreferenced.
    property bool historyReadable: false
    property int maxSeq: 0
    property var records: []

    // Day files present at load time, sorted (YYYY-MM-DD.jsonl).
    property var dayFiles: []

    // hash -> asset path, notification id -> last media {asset, hash}
    property var assetByHash: ({})
    property var lastAssetByNid: ({})

    // Local day the writer appends to.
    property string writeDay: store.dayOf(Date.now())

    // ---- signals -------------------------------------------------
    signal historyLoaded(var records)
    signal mediaReady(var info)

    // ---- date helpers --------------------------------------------
    function pad2(n) {
        return (n < 10 ? "0" : "") + n
    }

    function dayOf(ts) {
        var d = new Date(ts)

        return d.getFullYear() + "-" + store.pad2(d.getMonth() + 1)
                + "-" + store.pad2(d.getDate())
    }

    function dayPath(day) {
        return store.historyDir + "/" + day + ".jsonl"
    }

    // ---- writer --------------------------------------------------
    readonly property int maxQueueLength: 200

    property var queue: []
    property int writerFailures: 0
    property double writerStartedAt: 0

    // Set while the writer is being stopped on purpose (day rollover)
    // so the expected exit is not treated as a failure.
    property bool writerSwitching: false

    // True while the writer is failing; drives a single user-visible
    // hint (and resets on success) so a broken history file cannot
    // degrade silently.
    property bool writerDegraded: false

    function append(partial) {
        var rec = partial
        rec.v = 1
        rec.seq = ++maxSeq
        rec.ts = Date.now()
        store.records.push(rec)
        store.maybeSwitchDay()
        store.queue.push(JSON.stringify(rec) + "\n")

        while (store.queue.length > store.maxQueueLength) {
            store.queue.shift()

            console.warn("NotificationStore: queue full, dropping oldest pending line")
        }

        store.pump()
        return rec
    }

    function pump() {
        if (store.queue.length === 0) {
            store.writerDegraded = false

            return
        }

        if (!writer.running) {
            if (writerBackoffTimer.running)
                return

            writer.running = true
        } else {
            store.drain()
        }
    }

    function drain() {
        while (store.queue.length > 0)
            writer.write(store.queue.shift())
    }

    function notifyDegraded() {
        if (store.writerDegraded)
            return

        store.writerDegraded = true

        StatusManager.showQueued({
            mode: "notification",
            icon: "󰂚",
            title: "Notification history paused - retrying",
            statusWidth: 280,
            statusHeight: 33
        })
    }

    function maybeSwitchDay() {
        if (store.queue.length > 0)
            return

        var today = store.dayOf(Date.now())

        if (today === store.writeDay)
            return

        store.writeDay = today

        // A running tee is bound to the old day file; stop it (the
        // exit is expected, not a failure) so the next write starts
        // against the new one.
        if (writer.running) {
            store.writerSwitching = true
            writer.running = false
        }
    }

    Timer {
        id: writerBackoffTimer
        repeat: false

        onTriggered: store.pump()
    }

    // Midnight tick: retries the day rollover until the queue drains.
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true

        onTriggered: store.maybeSwitchDay()
    }

    Process {
        id: writer
        command: ["tee", "-a", store.dayPath(store.writeDay)]
        stdinEnabled: true

        onStarted: {
            store.writerStartedAt = Date.now()
            store.drain()
        }

        onExited: function(exitCode, exitStatus) {
            if (store.writerSwitching) {
                store.writerSwitching = false
                store.writerFailures = 0
                store.pump()
                return
            }

            if (exitCode === 0) {
                store.writerFailures = 0
                store.writerDegraded = false
            } else {
                // Writer was healthy for a while before dying? Then
                // treat this failure as fresh instead of compounding.
                if (Date.now() - store.writerStartedAt > 60000)
                    store.writerFailures = 0

                store.writerFailures++
                store.notifyDegraded()

                // Exponential backoff 1s -> 30s, retrying forever
                // instead of silently giving up after three failures.
                writerBackoffTimer.interval = Math.min(
                            30000,
                            1000 * Math.pow(2, Math.min(store.writerFailures, 5)))
                writerBackoffTimer.restart()
                return
            }

            store.pump()
        }
    }

    // ---- startup / load ------------------------------------------

    Component.onCompleted: {
        mkdirProc.running = true
    }

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", store.dir, store.assetsDir, store.historyDir]

        onExited: {
            listProc.running = false
            listProc.running = true
        }
    }

    Process {
        id: listProc
        command: ["ls", "-1", store.historyDir]

        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
            onStreamFinished: store.loadDayFiles(listOut.text)
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                store.records = []
                store.loaded = true
                store.historyLoaded([])
            }
        }
    }

    function loadDayFiles(text) {
        var names = String(text || "").split("\n")
        var files = []

        for (var i = 0; i < names.length; i++) {
            var n = names[i].trim()

            if (/^\d{4}-\d{2}-\d{2}\.jsonl$/.test(n))
                files.push(n)
        }

        files.sort()
        store.dayFiles = files

        if (files.length === 0) {
            store.records = []
            store.loaded = true
            store.historyReadable = true
            store.historyLoaded([])
            return
        }

        var paths = []

        for (i = 0; i < files.length; i++)
            paths.push(store.historyDir + "/" + files[i])

        catProc.command = ["cat"].concat(paths)
        catProc.running = false
        catProc.running = true
    }

    Process {
        id: catProc

        stdout: StdioCollector {
            id: catOut
            waitForEnd: true
            onStreamFinished: store.parseHistoryText(catOut.text)
        }
    }

    function parseHistoryText(text) {
        var prev = store.records
        var lines = String(text || "").split("\n")
        var recs = []

        store.maxSeq = 0
        store.assetByHash = ({})
        store.lastAssetByNid = ({})

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            if (!line)
                continue

            var rec

            try {
                rec = JSON.parse(line)
            } catch (e) {
                continue
            }

            if (!rec || typeof rec !== "object")
                continue

            recs.push(rec)

            if (rec.seq && rec.seq > store.maxSeq)
                store.maxSeq = rec.seq
        }

        // Runtime appends may not have hit the files yet (tee still
        // flushing); keep them so nothing can be dropped.
        var seen = ({})

        for (i = 0; i < recs.length; i++)
            seen[recs[i].seq] = true

        for (i = 0; i < prev.length; i++) {
            if (!seen[prev[i].seq]) {
                recs.push(prev[i])

                if (prev[i].seq > store.maxSeq)
                    store.maxSeq = prev[i].seq
            }
        }

        store.records = recs
        store.loaded = true
        store.historyReadable = true
        store.rebuildRegistries()
        store.historyLoaded(recs)
    }

    function rebuildRegistries() {
        store.assetByHash = ({})
        store.lastAssetByNid = ({})

        for (var i = 0; i < store.records.length; i++) {
            var r = store.records[i]

            if (r.type === "media") {
                if (r.hash)
                    store.assetByHash[r.hash] = r.asset

                store.lastAssetByNid[r.id] = {
                    asset: r.asset,
                    hash: r.hash
                }
            }
        }
    }

    function filePath(rel) {
        return store.dir + "/" + rel
    }

    function tmpPath() {
        return store.assetsDir + "/.tmp-" +
               Date.now() + "-" +
               Math.floor(Math.random() * 1000000) + ".png"
    }

    // ---- media pipeline ------------------------------------------

    property var mediaQueue: []
    property var activeJob: null
    property var grabRequest: null
    property int grabTokenCounter: 0

    // Only profile pictures are persisted. An image is kept only when
    // it looks like an avatar: square-ish and not larger than 256px.
    // Message photos are decoded just far enough to measure them,
    // then dropped without ever touching the disk.
    function isAvatarDim(w, h) {
        var a = Number(w)
        var b = Number(h)

        if (!(a > 0) || !(b > 0))
            return false

        if (Math.abs(a - b) > 8)
            return false

        return Math.max(a, b) <= 256
    }

    function enqueueMedia(id, ref, url) {
        var u = String(url || "")

        if (u === "")
            return

        if (u.indexOf("image://icon") === 0)
            return

        if (u.indexOf("image://qsimage/") === 0) {
            store.mediaQueue.push({ id: id, ref: ref, url: u, kind: "grab" })
            store.pumpMedia()
            return
        }

        if (u.indexOf("file://") === 0) {
            store.mediaQueue.push({ id: id, ref: ref, url: u, kind: "file" })
            store.pumpMedia()
        }
    }

    function pumpMedia() {
        if (store.activeJob !== null)
            return

        if (store.mediaQueue.length === 0)
            return

        store.activeJob = store.mediaQueue.shift()
        store.grabTokenCounter++
        store.activeJob.token = store.grabTokenCounter

        // Both qsimage and file:// payloads are decoded through the
        // saver Image so avatars can be measured before anything is
        // written.
        store.grabRequest = {
            token: store.activeJob.token,
            url: store.activeJob.url
        }
    }

    // Called from the hidden saver Image in IslandWindow: the image
    // was rendered to tmpPath (or the grab failed).
    function grabResult(token, ok, tmpPath, w, h) {
        var job = store.activeJob

        if (!job || job.token !== token)
            return

        store.grabRequest = null

        if (!ok || !tmpPath) {
            console.log("NotificationStore: grab failed for", job.url)
            store.mediaFailed()
            return
        }

        if (!store.isAvatarDim(w, h) || w < store.minGrabDim || h < store.minGrabDim) {
            console.log("NotificationStore: discarding non-avatar image", w + "x" + h)
            store.rm(tmpPath)
            store.mediaFailed()
            return
        }

        job.srcPath = tmpPath
        job.grabW = w
        job.grabH = h
        store.hashActiveJob()
    }

    function hashActiveJob() {
        hashProc.command = [
            "sh", "-c",
            'printf "TOKEN:%s\\n" "$5"; sha256sum -- "$1" 2>/dev/null; stat -c %s -- "$1" 2>/dev/null',
            "_", store.activeJob.srcPath, "", "", "",
            String(store.activeJob.token)
        ]
        hashProc.running = false
        hashProc.running = true
    }

    Process {
        id: hashProc

        stdout: StdioCollector {
            id: hashOut
            waitForEnd: true
            onStreamFinished: store.mediaHashed(hashOut.text)
        }
    }

    function tailBlock(text, token) {
        var lines = String(text || "").split("\n")
        var start = -1
        var marker = "TOKEN:" + token

        for (var i = 0; i < lines.length; i++) {
            if (lines[i] === marker)
                start = i
        }

        return start >= 0 ? lines.slice(start + 1) : lines
    }

    function mediaHashed(text) {
        var job = store.activeJob

        if (!job)
            return

        var lines = store.tailBlock(text, String(job.token))
        var hash = String(lines[0] || "").split(" ")[0] || ""
        var bytes = parseInt(lines[1] || "0", 10)

        if (isNaN(bytes))
            bytes = 0

        if (hash.length < 16) {
            console.log("NotificationStore: hash failed for", job.srcPath)
            store.mediaFailed()
            return
        }

        job.hash16 = hash.substring(0, 16)
        job.bytes = bytes
        store.completeMedia()
    }

    function completeMedia() {
        var job = store.activeJob
        var existing = store.assetByHash[job.hash16] || ""
        var dstRel = existing
        var op

        if (existing !== "") {
            dstRel = existing
            op = "rm"
        } else {
            dstRel = "assets/" + job.hash16 + ".png"
            op = "move"
            store.assetByHash[job.hash16] = dstRel
        }

        fileOp.job = {
            id: job.id,
            ref: job.ref,
            hash16: job.hash16,
            bytes: job.bytes,
            w: job.grabW || 0,
            h: job.grabH || 0,
            kind: job.kind,
            op: op,
            dstRel: dstRel,
            token: job.token
        }

        fileOp.command = [
            "sh", "-c",
            [
                'op="$1"; src="$2"; dst="$3"',
                'printf "TOKEN:%s\\n" "$4"',
                'case "$op" in',
                '  move) mv -- "$src" "$dst" || exit 1 ;;',
                '  rm) rm -f -- "$src" ;;',
                'esac',
                'printf "DONE\\n"'
            ].join("\n"),
            "_",
            fileOp.job.op,
            job.srcPath,
            store.dir + "/" + dstRel,
            String(job.token)
        ]

        fileOp.running = false
        fileOp.running = true
    }

    Process {
        id: fileOp
        property var job: null

        stdout: StdioCollector {
            id: fileOpOut
            waitForEnd: true
            onStreamFinished: store.fileOpDone(fileOpOut.text, fileOp.job)
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.log("NotificationStore: file op failed, code", exitCode)
        }
    }

    function fileOpDone(text, job) {
        if (!job)
            return

        var lines = store.tailBlock(text, String(job.token))
        var done = false

        for (var i = 0; i < lines.length; i++) {
            if (lines[i] === "DONE")
                done = true
        }

        // The script only prints DONE after every step succeeded; a
        // missing marker means the file op failed and no record may
        // be written (it would point at a nonexistent asset).
        if (!done) {
            console.log("NotificationStore: file op incomplete for notification", job.id)

            if (job.op === "move" && store.assetByHash[job.hash16] === job.dstRel)
                delete store.assetByHash[job.hash16]

            fileOp.job = null
            store.mediaFailed()
            return
        }

        store.lastAssetByNid[job.id] = {
            asset: job.dstRel,
            hash: job.hash16
        }

        store.append({
            type: "media",
            id: job.id,
            ref: job.ref,
            hash: job.hash16,
            asset: job.dstRel,
            w: job.w,
            h: job.h,
            bytes: job.bytes,
            source: job.kind === "grab" ? "qsimage" : "file"
        })

        store.mediaReady({
            id: job.id,
            ref: job.ref,
            asset: job.dstRel,
            w: job.w,
            h: job.h
        })

        store.activeJob = null
        fileOp.job = null
        store.pumpMedia()
    }

    function mediaFailed() {
        store.grabRequest = null
        store.activeJob = null
        store.pumpMedia()
    }

    // Called by the saver when the decoded image is not avatar-sized.
    // Nothing was written to disk yet; just drop the job.
    function grabDiscarded(token) {
        var job = store.activeJob

        if (!job || job.token !== token)
            return

        console.log("NotificationStore: ignoring message media", job.url)
        store.grabRequest = null
        store.activeJob = null
        store.pumpMedia()
    }

    // ---- small command helpers -----------------------------------

    Process {
        id: rmProc

        property var pending: []
        property bool busy: false

        onExited: {
            busy = false
            runNextRm()
        }

        function runNextRm() {
            if (busy || pending.length === 0)
                return

            busy = true
            command = pending.shift()
            running = false
            running = true
        }
    }

    function rm(path) {
        rmProc.pending.push(["rm", "-f", "--", path])
        rmProc.runNextRm()
    }

    // ---- prune ---------------------------------------------------

    Timer {
        interval: 24 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: store.prune()
    }

    function prune() {
        if (!store.loaded || !store.historyReadable)
            return

        if (store.retentionMs <= 0) {
            console.log("NotificationStore: retentionMs is",
                        store.retentionMs, "— skipping prune")
            return
        }

        var cutoff = Date.now() - store.retentionMs

        store.sweepAssets(cutoff)
        store.pruneDayFiles(cutoff)
    }

    function pruneDayFiles(cutoff) {
        var cutoffDay = store.dayOf(cutoff) + ".jsonl"
        var today = store.dayOf(Date.now()) + ".jsonl"
        var doomed = []

        for (var i = 0; i < store.dayFiles.length; i++) {
            var name = store.dayFiles[i]

            if (name !== today && name < cutoffDay)
                doomed.push(store.historyDir + "/" + name)
        }

        if (doomed.length > 0 && doomed.length === store.dayFiles.length) {
            console.log("NotificationStore: refusing to prune all",
                        store.dayFiles.length, "day files")
            return
        }

        if (doomed.length > 0) {
            console.log("NotificationStore: pruning", doomed.length, "day files")
            rmProc.pending.push(["rm", "-f", "--"].concat(doomed))
            rmProc.runNextRm()
        }
    }

    Process {
        id: findProc

        stdout: StdioCollector {
            id: findOut
            waitForEnd: true
            onStreamFinished: store.sweepListed(findOut.text)
        }
    }

    property var sweepRefs: ({})

    function sweepAssets(cutoff) {
        store.sweepRefs = ({})

        for (var i = 0; i < store.records.length; i++) {
            var r = store.records[i]

            if (r.type === "media" && r.asset && r.ts >= cutoff)
                store.sweepRefs[String(r.asset).split("/").pop()] = true
        }

        findProc.command = ["find", store.assetsDir, "-maxdepth", "1", "-type", "f", "-printf", "%f\\n"]
        findProc.running = false
        findProc.running = true
    }

    function sweepListed(text) {
        var names = String(text || "").split("\n")
        var doomed = []

        for (var i = 0; i < names.length; i++) {
            var n = names[i].trim()

            if (!n)
                continue

            if (n.indexOf(".tmp-") === 0 || !store.sweepRefs[n])
                doomed.push(store.assetsDir + "/" + n)
        }

        if (doomed.length > 0) {
            console.log("NotificationStore: pruning", doomed.length, "unreferenced assets")
            rmProc.pending.push(["rm", "-f", "--"].concat(doomed))
            rmProc.runNextRm()
        }
    }
}
