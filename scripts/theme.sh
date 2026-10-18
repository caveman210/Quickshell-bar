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

link_if_exists() {
    local source="$1"
    local target="$2"

    if [[ -f "$source" ]]; then
        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
        echo "✓ $(basename "$target")"
    else
        echo "✗ Missing: $source"
    fi
}

# -------------------------
# Wallpapers
# -------------------------

case "$THEME" in
    monochrome)
        WP="art11.png"
        ;;

    githublight)
        WP="Totoro.png"
        ;;

    gruvbox)
        WP="gruvbox_astro.jpg"
        ;;

    gruvboxlight)
        WP="anime-girl3.jpg"
        ;;

    dracula)
        WP="art13.jpeg"
        ;;

    everforest)
        WP="foggy_valley_2.png"
        ;;

    catppuccin)
        WP="arch-black-4k.png"
        ;;

    catppuccinlatte)
        WP="7.jpg"
        ;;

    nord)
        WP="chainsaw-man.png"
        ;;

    rosepine)
        WP="dark-fantasy.jpg"
        ;;

    solarized)
        WP="sleeping.jpg"
        ;;

    tokyonight)
        WP="aesthetic-anime2.jpg"
        ;;

    *)
        WP="default.jpg"
        ;;
esac

# -------------------------
# Wallpaper
# -------------------------

awww img \
"$HOME/Pictures/wallpapers/$WP" \
--transition-type grow

# -------------------------
# Hyprland (opt-out via ENABLE_HYPR_THEME=0; auto = only on Hyprland)
# Niri theming is intentionally a no-op for now — Luci + Kitty +
# wallpaper still apply. See config/niri/ for the future hook.
# -------------------------

ENABLE_HYPR_THEME="${ENABLE_HYPR_THEME:-auto}"
SHOULD_SYNC_HYPR=0

if [[ "$ENABLE_HYPR_THEME" == "1" ]]; then
    SHOULD_SYNC_HYPR=1
elif [[ "$ENABLE_HYPR_THEME" == "auto" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    SHOULD_SYNC_HYPR=1
fi

if [[ "$SHOULD_SYNC_HYPR" == "1" ]]; then
    link_if_exists \
        "$THEME_DIR/HyprTheme.lua" \
        "$HOME/.config/hypr/current-theme/theme.lua"
else
    echo "○ Hyprland theme sync skipped (Niri or disabled)"
fi

echo

echo "$THEME" > "$HOME/.config/quickshell/.current_theme"
