#!/usr/bin/env bash

THEME="$1"

if [[ -z "$THEME" ]]; then
    echo "Usage: theme-switch.sh <theme>"
    exit 1
fi

THEMES_DIR="$HOME/.config/quickshell/styles/themes"
THEME_DIR="$THEMES_DIR/$THEME"

if [[ ! -d "$THEME_DIR" ]]; then
    echo "Theme '$THEME' not found."
    exit 1
fi

# -------------------------
# Wallpaper & theming
# Wallpapers are listed straight from ~/Pictures/Wallpapers and picked
# manually in the selector; there is no per-theme mapping anymore.
# Roadmap (not implemented): move styling/theming to a matugen-style
# dynamic color pipeline instead of hardcoded per-theme values, at
# which point wallpapers/colors would be derived rather than mapped.
# -------------------------

# -------------------------
# Compositor theme sync hooks (Hyprland only for now; opt-out via
# ENABLE_HYPR_THEME=0). Niri theming is intentionally a no-op for now —
# Luci keeps its own theme. See config/niri/ for the future hook.
# -------------------------

"$(dirname "$0")/compositor/hyprland-theme-sync.sh" "$THEME_DIR"

echo

echo "$THEME" > "$HOME/.config/quickshell/.current_theme"
