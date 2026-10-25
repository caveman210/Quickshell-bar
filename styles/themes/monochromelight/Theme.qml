pragma Singleton

import QtQuick

// =========================================================
// MONOCHROME LIGHT
// =========================================================
// Inverted counterpart of "monochrome". Color swap mapping
// (dark -> light), for portability across themes:
//   background        #120C0B  ->  #C98B73   (accent becomes bg)
//   surface           #170F0E  ->  #D59A80
//   surfaceVariant    #211513  ->  #E0A88F
//   card              #2B1B17  ->  #D59A80
//   textPrimary       #F1E9E4  ->  #120C0B   (bg becomes text)
//   textSecondary     #D0C0B9  ->  #2B1B17
//   textMuted         #9D8980  ->  #493029
//   accent            #C98B73  ->  #2B1B17   (brown becomes accent)
//   accentHover       #D59A80  ->  #120C0B
//   accentPressed     #B57E63  ->  #493029
//   border            #493029  ->  #B57E63
//   borderHover       #6E4E46  ->  #9D8980
//   danger            #E6A29B  ->  #C98785
//   warning           #D9AE78  ->  #B57614
//   success           #A8BF96  ->  #7A8F6E

QtObject {
    // =========================================================
    // BACKGROUNDS
    // =========================================================

    property color background: "#C98B73"
    property color surface: "#D59A80"
    property color surfaceVariant: "#E0A88F"
    property color card: "#D59A80"

    // =========================================================
    // OVERLAYS
    // =========================================================

    property color overlayLight: "#00000010"
    property color overlayMedium: "#00000022"
    property color overlayStrong: "#00000044"

    // =========================================================
    // TEXT
    // =========================================================

    property color textPrimary: "#120C0B"
    property color textSecondary: "#2B1B17"
    property color textMuted: "#493029"

    // =========================================================
    // ICONS
    // =========================================================

    property color icon: "#2B1B17"
    property color iconActive: "#120C0B"
    property color iconDisabled: "#493029"

    // =========================================================
    // ACCENT
    // =========================================================

    property color accent: "#2B1B17"
    property color accentHover: "#120C0B"
    property color accentPressed: "#493029"

    // =========================================================
    // BORDERS
    // =========================================================

    property color border: "#B57E63"
    property color borderHover: "#9D8980"
    property color borderSelected: accent
    property color borderSubtle: "#00000015"

    // =========================================================
    // BUTTONS
    // =========================================================

    property color buttonBackground: "#D59A80"
    property color buttonHover: "#C98B73"
    property color buttonPressed: "#B57E63"
    property color buttonSelected: accent
    property color buttonText: textPrimary
    property color controlButtonHover: "#B57E63"

    // =========================================================
    // DESTRUCTIVE ACTIONS
    // =========================================================

    property color danger: "#C98785"
    property color dangerHover: "#B51D17"
    property color warning: "#B57614"
    property color success: "#7A8F6E"

    // =========================================================
    // INPUTS / SLIDERS
    // =========================================================

    property color sliderBackground: "#B57E63"
    property color sliderFill: accent
    property color inputBackground: "#D59A80"
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
    property color progressBackground: "#B57E63"

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
