#!/usr/bin/env bash
# Zen only reads userChrome.css at startup, so a matugen run needs a
# restart to show the new palette. Do nothing if Zen is not running.
set -euo pipefail

bin="$(command -v zen-beta || command -v zen || true)"
[[ -z "$bin" ]] && exit 0

if pgrep -x zen-beta >/dev/null 2>&1; then
    pkill -TERM -x zen-beta || true
    sleep 1
fi

if pgrep -x zen >/dev/null 2>&1; then
    pkill -TERM -x zen || true
    sleep 1
fi

nohup "$bin" >/dev/null 2>&1 &
