pragma Singleton

import QtQuick

// =========================================================
// SAMURAI — Warm Cinematic Forest Dark (wallpaper-derived)
// Migrated from monochrome to wallpaper palette:
// Window #120C0B, View #170F0E, Sidebar #211513,
// Popover #2B1B17, Borders #493029, Accent #C98B73
// =========================================================

QtObject {
    // =========================================================
    // BACKGROUNDS
    // =========================================================

    property color background: "#120C0B"
    property color surface: "#170F0E"
    property color surfaceVariant: "#211513"
    property color card: "#2B1B17"

    // =========================================================
    // OVERLAYS
    // =========================================================

    property color overlayLight: "#00000022"
    property color overlayMedium: "#00000044"
    property color overlayStrong: "#00000066"

    // =========================================================
    // TEXT
    // =========================================================

    property color textPrimary: "#F1E9E4"
    property color textSecondary: "#D0C0B9"
    property color textMuted: "#9D8980"

    // =========================================================
    // ICONS
    // =========================================================

    property color icon: "#D0C0B9"
    property color iconActive: "#F1E9E4"
    property color iconDisabled: "#9D8980"

    // =========================================================
    // ACCENT
    // =========================================================

    property color accent: "#C98B73"
    property color accentHover: "#D59A80"
    property color accentPressed: "#B57E63"

    // =========================================================
    // BORDERS
    // =========================================================

    property color border: "#493029"
    property color borderHover: "#6E4E46"
    property color borderSelected: accent
    property color borderSubtle: "#00000020"

    // =========================================================
    // BUTTONS
    // =========================================================

    property color buttonBackground: "#2B1B17"
    property color buttonHover: "#36211D"
    property color buttonPressed: "#493029"
    property color buttonSelected: accent
    property color buttonText: textPrimary
    property color controlButtonHover: "#493029"

    // =========================================================
    // DESTRUCTIVE ACTIONS
    // =========================================================

    property color danger: "#E6A29B"
    property color dangerHover: "#C98785"
    property color warning: "#D9AE78"
    property color success: "#A8BF96"

    // =========================================================
    // INPUTS / SLIDERS
    // =========================================================

    property color sliderBackground: "#211513"
    property color sliderFill: accent
    property color inputBackground: "#211513"
    property color inputBorder: border

    // =========================================================
    // NOTIFICATIONS
    // =========================================================

    property color notificationBackground: card
    property color notificationUnread: surfaceVariant

    // =========================================================
    // MEDIA
    // =========================================================

    property color progress: accent
    property color progressBackground: "#493029"

    // =========================================================
    // WALLPAPER SELECTOR
    // =========================================================

    property color wallpaperOverlay: overlayStrong
    property color wallpaperSelection: accent

    // =========================================================
    // POWER MENU
    // =========================================================

    property color powerDanger: danger
    property color powerWarning: warning

    // =========================================================
    // FONTS
    // =========================================================

    property string iconFont: "JetBrainsMono Nerd Font"
}
