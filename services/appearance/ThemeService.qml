pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../../styles"

Singleton {
    id: root
    property string currentTheme: "monochrome"

    // The theme list is generated from styles/themes/ at startup so the
    // theme files stay the single source of truth for preview colors.
    property ListModel themes: ListModel {}

    property bool initialized: false
    property bool ready: false

    property string _queuedThemeScript: ""
    property bool _modelBuilt: false

    Process {
        id: process

        onExited: {
            if (root._queuedThemeScript !== "") {
                let next = root._queuedThemeScript

                root._queuedThemeScript = ""
                root._runThemeScript(next)
            }
        }
    }

    Process {
        id: themeLister
        command: [
            "bash",
            "-c",
            "find \"" + Quickshell.env("HOME")
                + "/.config/quickshell/styles/themes\" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' | sort"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.buildThemeModel(text)
        }
    }

    function _prettyName(themeId) {
        const prettyNames = {
            "monochrome": "Monochrome",
            "catppuccin": "Catppuccin",
            "catppuccinlatte": "Catppuccin Latte",
            "gruvbox": "Gruvbox",
            "gruvboxlight": "Gruvbox Light",
            "tokyonight": "Tokyo Night",
            "dracula": "Dracula",
            "nord": "Nord",
            "everforest": "Everforest",
            "solarized": "Solarized",
            "rosepine": "Rosé Pine",
            "githublight": "GitHub Light"
        }

        return prettyNames[themeId] !== undefined
            ? prettyNames[themeId]
            : themeId.charAt(0).toUpperCase() + themeId.slice(1)
    }

    function buildThemeModel(text) {
        if (_modelBuilt)
            return

        _modelBuilt = true

        const themeIds = text.split("\n")
            .map(line => line.trim())
            .filter(line => line.length > 0)

        for (const themeId of themeIds)
            _addThemeEntry(themeId)
    }

    function _addThemeEntry(themeId) {
        const component = Qt.createComponent(
            "../../styles/themes/" + themeId + "/Theme.qml"
        )

        function finalize() {
            if (component.status !== Component.Ready) {
                console.warn(
                    "Theme preview skipped for '" + themeId + "':",
                    component.errorString()
                )

                return
            }

            const theme = component.createObject()

            if (!theme) {
                console.warn("Theme preview object failed for:", themeId)

                return
            }

            themes.append({
                themeId: themeId,
                name: _prettyName(themeId),
                background: theme.background,
                color1: theme.accent,
                color2: theme.success !== undefined ? theme.success : theme.accent,
                color3: theme.warning !== undefined ? theme.warning : theme.accent,
                accent: theme.accent,
                text: theme.textPrimary
            })

            theme.destroy()
        }

        if (component.status === Component.Loading) {
            component.statusChanged.connect(function() {
                if (component.status !== Component.Loading)
                    finalize()
            })
        } else {
            finalize()
        }
    }

    function apply(themeName, isFallback) {
        var component = Qt.createComponent(
            "../../styles/themes/" + themeName + "/Theme.qml"
        )

        if (component.status !== Component.Ready) {
            console.error(
                "Theme load error for '" + themeName + "':",
                component.errorString()
            )

            if (!isFallback && themeName !== "monochrome") {
                console.warn("Falling back to 'monochrome'.")

                apply("monochrome", true)
            } else {
                // Even a broken fallback must not leave every window
                // gated on ThemeService.ready invisible forever.
                ready = true
            }

            return
        }

        var theme = component.createObject()

        if (!theme) {
            console.error("Failed to create theme object:", themeName)

            if (!isFallback && themeName !== "monochrome")
                apply("monochrome", true)
            else
                ready = true

            return
        }

        applyTheme(theme)

        theme.destroy()

        currentTheme = themeName

        WallpaperService.reload()

        _runThemeScript(themeName)

        ready = true
    }

    function _runThemeScript(themeName) {
        if (process.running) {
            // Queue the newest request: restarting mid-run can kill the
            // script between the Hyprland symlink and .current_theme
            // writes, leaving the two sides out of sync.
            _queuedThemeScript = themeName

            return
        }

        process.command = [
            "bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/theme.sh",
            themeName
        ]

        process.running = true
    }

    function applyTheme(themeObject) {
        const themeProperties = [
            "background",
            "surface",
            "surfaceVariant",
            "card",

            "overlayLight",
            "overlayMedium",
            "overlayStrong",

            "textPrimary",
            "textSecondary",
            "textMuted",

            "icon",
            "iconActive",
            "iconDisabled",

            "accent",
            "accentHover",
            "accentPressed",

            "border",
            "borderHover",
            "borderSelected",
            "borderSubtle",

            "buttonBackground",
            "buttonHover",
            "buttonPressed",
            "buttonSelected",
            "buttonText",
            "controlButtonHover",

            "danger",
            "dangerHover",
            "warning",
            "success",

            "sliderBackground",
            "sliderFill",
            "inputBackground",
            "inputBorder",

            "notificationBackground",
            "notificationUnread",

            "progress",
            "progressBackground",

            "wallpaperOverlay",
            "wallpaperSelection",

            "powerDanger",
            "powerWarning",

            "iconFont"
        ]

        for (const key of themeProperties) {
            if (themeObject[key] !== undefined)
                Theme[key] = themeObject[key]
            else
                console.warn("Theme is missing property '" + key + "'")
        }
    }

    Process {
        id: themeReader
        command: [
            "bash",
            "-c",
            "cat " + Quickshell.env("HOME") + "/.config/quickshell/.current_theme"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let savedTheme = text.trim()

                if (savedTheme !== "")
                    root.currentTheme = savedTheme

                apply(root.currentTheme)
            }
        }
    }

    function initialize() {
        if (initialized)
            return

        initialized = true

        themeLister.running = true
        themeReader.running = true
    }

    Component.onCompleted: {
        initialize()
    }
}
