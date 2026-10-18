pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Append-only notification history on disk.
//
// Layout: ~/.cache/quickshell/notifications/
//   history.jsonl        one JSON record per line; lines are never
//                        rewritten (prune() compacts, dropping records
//                        older than retentionMs and unreferenced assets)
//   assets/<hash>.<ext>  content-addressed media (sha256, first 16 hex)
//   assets/.tmp-*        scratch files while a grab copy is in flight
//
// Record types: new | update | media | rename | close.
//
// Media rules:
//  - identical content is stored once; later references link to the
//    existing (older) file, no copy
//  - when a notification's media is replaced, the old file is renamed
//    <name>-old.<ext>; if that name is taken the suffix stacks
//    (-old-old.<ext>). A rename record keeps every old reference
//    resolvable through the replay path map.
//
// Writes stream through a single `tee -a` process (stdin queue), so app
// tag-replacements only ever append; the file itself is owned by the shell.
Singleton {
    id: store

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.cache/quickshell/notifications"
    readonly property string historyPath: dir + "/history.jsonl"
    readonly property string assetsDir: dir + "/assets"

    // 30 days of history. Must stay double: 30d in ms exceeds int32.
    property double retentionMs: 30 * 24 * 60 * 60 * 1000

    // Smallest saved avatar dimension; smaller grabs are discarded.
    property int minGrabDim: 48

    // Long-edge cap for grabbed avatars.
    property int maxGrabDim: 2048

    property bool loaded: false

    // True only after history.jsonl was actually read. Guards
    // prune() so a missing/broken file can never mark live assets
    // as unreferenced.
    property bool historyReadable: false
    property int maxSeq: 0
    property var records: []

    // asset path -> current path (renames), hash -> current asset path,
    // notification id -> last media {asset, hash}
    property var pathMap: ({})
    property var assetByHash: ({})
    property var lastAssetByNid: ({})

    // ---- signals -------------------------------------------------
    signal historyLoaded(var records)
    signal mediaReady(var info)
    signal assetRenamed(string from, string to)

    // ---- writer --------------------------------------------------
    property var queue: []
    property int writerFailures: 0
    property bool compactPending: false
    property var compactKept: []
    property int compactQueueLen: 0

    function append(partial) {
        var rec = partial
        rec.v = 1
        rec.seq = ++maxSeq
        rec.ts = Date.now()
        store.records.push(rec)
        store.queue.push(JSON.stringify(rec) + "\n")
        store.pump()
        return rec
    }

    function pump() {
        if (store.queue.length === 0)
            return

        if (!writer.running) {
            if (store.writerFailures >= 3) {
                console.log("NotificationStore: writer repeatedly failed,", store.queue.length, "lines pending")
                return
            }

            writer.running = true
        } else {
            store.drain()
        }
    }

    function drain() {
        writerFailures = 0

        while (store.queue.length > 0)
            writer.write(store.queue.shift())
    }

    Process {
        id: writer
        command: ["tee", "-a", store.historyPath]
        stdinEnabled: true

        onStarted: store.drain()

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                store.writerFailures++

            if (store.compactPending) {
                store.finishCompact()
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
        command: ["mkdir", "-p", store.dir, store.assetsDir]

        onExited: store.reloadHistory()
    }

    FileView {
        id: historyFile
        path: store.historyPath

        blockAllReads: true
        atomicWrites: true

        onLoaded: store.parseHistory()

        onLoadFailed: function(error) {
            store.records = []
            store.loaded = true
            store.historyLoaded([])
        }

        onSaved: {
            if (store.compactQueueLen > 0) {
                store.queue = store.queue.slice(store.compactQueueLen)
                store.compactQueueLen = 0
            }

            store.pump()
        }

        onSaveFailed: function(error) {
            console.log("NotificationStore: compaction write failed:", error)
            store.compactQueueLen = 0
            store.pump()
        }
    }

    function reloadHistory() {
        historyFile.reload()
    }

    function parseHistory() {
        var prev = store.records
        var text = historyFile.text() || ""
        var lines = text.split("\n")
        var recs = []

        store.maxSeq = 0
        store.pathMap = ({})
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

            if (rec.type === "rename" && rec.from && rec.to)
                store.pathMap[rec.from] = rec.to
        }

        // Runtime appends may not have hit the file yet (tee still
        // flushing); keep them so compaction can never drop a line.
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
        store.pathMap = ({})
        store.assetByHash = ({})
        store.lastAssetByNid = ({})

        var i

        for (i = 0; i < store.records.length; i++) {
            var r = store.records[i]

            if (r.type === "rename" && r.from && r.to)
                store.pathMap[r.from] = r.to
        }

        for (i = 0; i < store.records.length; i++) {
            r = store.records[i]

            if (r.type === "media") {
                r.resolvedAsset = store.resolvePath(r.asset)

                if (r.hash)
                    store.assetByHash[r.hash] = r.resolvedAsset

                store.lastAssetByNid[r.id] = {
                    asset: r.resolvedAsset,
                    hash: r.hash
                }
            }
        }
    }

    function resolvePath(p) {
        var guard = 0

        while (p && store.pathMap[p] && guard < 64) {
            p = store.pathMap[p]
            guard++
        }

        return p
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

    function urlToPath(u) {
        var p = u

        if (p.indexOf("file://") === 0)
            p = p.substring(7)

        return decodeURIComponent(p)
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

        var prev = store.lastAssetByNid[job.id]
        var prevAsset = ""
        var prevHash = ""

        if (prev && prev.hash !== job.hash16 && prev.asset !== dstRel) {
            prevAsset = prev.asset
            prevHash = prev.hash
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
            prevAsset: prevAsset,
            prevHash: prevHash,
            token: job.token
        }

        fileOp.command = [
            "sh", "-c",
            [
                'op="$1"; src="$2"; dst="$3"; prev="$4"',
                'printf "TOKEN:%s\\n" "$5"',
                'case "$op" in',
                '  move) mv -- "$src" "$dst" || exit 1 ;;',
                '  copy) cp -- "$src" "$dst" || exit 1 ;;',
                '  rm) rm -f -- "$src" ;;',
                '  skip) : ;;',
                'esac',
                'if [ -n "$prev" ] && [ -e "$prev" ]; then',
                '  t="${prev%.*}-old.${prev##*.}"',
                '  while [ -e "$t" ]; do t="${t%.*}-old.${t##*.}"; done',
                '  if mv -- "$prev" "$t" 2>/dev/null; then printf "OLD:%s\\n" "$t"; fi',
                'fi',
                'printf "DONE\\n"'
            ].join("\n"),
            "_",
            fileOp.job.op,
            fileOp.job.op === "skip" ? "" : job.srcPath,
            store.dir + "/" + dstRel,
            prevAsset !== "" ? store.filePath(prevAsset) : "",
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
        var renamedTo = ""

        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("OLD:") === 0)
                renamedTo = lines[i].substring(4)
        }

        if (renamedTo !== "" && job.prevAsset !== "") {
            var rel = renamedTo.indexOf(store.dir + "/") === 0
                ? renamedTo.substring(store.dir.length + 1)
                : renamedTo

            store.pathMap[job.prevAsset] = rel

            if (store.assetByHash[job.prevHash] === job.prevAsset)
                store.assetByHash[job.prevHash] = rel

            store.append({
                type: "rename",
                id: job.id,
                from: job.prevAsset,
                to: rel
            })

            store.assetRenamed(job.prevAsset, rel)
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

    // ---- prune / compaction --------------------------------------

    Timer {
        interval: 24 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: store.prune()
    }

    function prune() {
        if (!store.loaded || !store.historyReadable)
            return

        var cutoff = Date.now() - store.retentionMs
        var kept = []

        for (var i = 0; i < store.records.length; i++) {
            if (store.records[i].ts >= cutoff)
                kept.push(store.records[i])
        }

        // A healthy 30-day window never drops everything at once; if
        // it would, something is wrong with retentionMs — keep the
        // data and shout instead of wiping the history.
        if (kept.length === 0 && store.records.length > 0) {
            console.log("NotificationStore: refusing to prune all",
                        store.records.length, "records (retentionMs =",
                        store.retentionMs + ")")
            return
        }

        store.sweepAssets(kept)

        if (kept.length === store.records.length)
            return

        store.compactKept = kept
        store.compactPending = true

        if (writer.running)
            writer.running = false
        else
            store.finishCompact()
    }

    function finishCompact() {
        if (!store.compactPending)
            return

        store.compactPending = false

        var parts = []

        for (var i = 0; i < store.compactKept.length; i++)
            parts.push(JSON.stringify(store.compactKept[i]))

        var text = parts.length > 0
            ? parts.join("\n") + "\n"
            : ""

        // Lines still in the queue are included above (their records
        // are in compactKept); drop them once the file is written.
        store.compactQueueLen = store.queue.length
        store.records = store.compactKept

        historyFile.setText(text)
        store.rebuildRegistries()
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

    function sweepAssets(kept) {
        store.sweepRefs = ({})

        for (var i = 0; i < kept.length; i++) {
            var r = kept[i]

            if (r.type === "media" && r.asset) {
                var resolved = store.resolvePath(r.asset)
                store.sweepRefs[String(resolved).split("/").pop()] = true
            }
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
