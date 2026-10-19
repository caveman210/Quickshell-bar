#!/usr/bin/env bash
# Hyprland theme sync — links the active theme's HyprTheme.lua into
# ~/.config/hypr/current-theme/theme.lua.
#
# Called by scripts/theme.sh with the resolved theme directory.
# Opt-out via ENABLE_HYPR_THEME=0; default "auto" syncs only when
# HYPRLAND_INSTANCE_SIGNATURE is set (i.e. running on Hyprland).

THEME_DIR="$1"

if [[ -z "$THEME_DIR" || ! -d "$THEME_DIR" ]]; then
    echo "Usage: hyprland-theme-sync.sh <theme-dir>"
    exit 1
fi

ENABLE_HYPR_THEME="${ENABLE_HYPR_THEME:-auto}"
SHOULD_SYNC=0

if [[ "$ENABLE_HYPR_THEME" == "1" ]]; then
    SHOULD_SYNC=1
elif [[ "$ENABLE_HYPR_THEME" == "auto" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    SHOULD_SYNC=1
fi

if [[ "$SHOULD_SYNC" != "1" ]]; then
    echo "○ Hyprland theme sync skipped (Niri or disabled)"
    exit 0
fi

SOURCE="$THEME_DIR/HyprTheme.lua"
TARGET="$HOME/.config/hypr/current-theme/theme.lua"

if [[ -f "$SOURCE" ]]; then
    mkdir -p "$(dirname "$TARGET")"
    ln -sf "$SOURCE" "$TARGET"
    echo "✓ $(basename "$TARGET")"
else
    echo "✗ Missing: $SOURCE"
fi
