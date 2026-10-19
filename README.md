# Luci

Luci is a minimalist Dynamic Island built with Quickshell for Hyprland and niri.

Unlike many desktop shell projects that aim to manage every aspect of the desktop, Luci focuses on a small set of everyday interactions. It provides quick access to the features you use most while remaining lightweight, keyboard-friendly, and easy to extend.

The goal is simplicity rather than feature overload.

## Features

-  Three island layouts — Pill, Notch and Bar — cycled at runtime
-  Flow corners: the bar and its dropdowns blend into the monitor edges
-  Dynamic theme switching
-  Wallpaper selector
-  Rich media controls with waveform progress
-  Control Center with Wi-Fi / Bluetooth / Mic / Night Light / Focus cards and a storage card in the bar
-  Volume and brightness sliders
-  Volume and brightness notifications (OSD)
-  Status notifications (workspace, device connect/disconnect)
-  Notification history (per-day, with avatars)
-  Battery status
-  Wi-Fi status
-  Real-time CAVA visualizer
-  Power menu
-  Vim-inspired keyboard navigation

## Requirements

Luci is developed and tested with:

- **Hyprland** 0.56.1 **or niri** 26.04
- **Quickshell** 0.3.0
- **Cava** (audio visualizer)
- **Awww** (wallpaper backend)
- **hyprsunset** *(optional, Night Light on Hyprland)*
- **gammastep** *(optional, Night Light on niri)*

These are the versions currently used during development and testing.

> **Note:** Night Light is optional. Install `hyprsunset` on Hyprland or `gammastep` on niri — the Control Center card only appears once the matching tool is installed.

## Installation

### 1. Clone the repository

If you already use Quickshell, it's recommended to back up your existing configuration before replacing it.

```bash
mv ~/.config/quickshell ~/.config/quickshell.backup
```

Clone Luci into your Quickshell configuration directory:

```bash
cd ~/.config
git clone https://github.com/ElhamSadiqi/Luci.git quickshell
```

---

### 2. Launch Luci

Start Luci manually:

```bash
qs -c ~/.config/quickshell & disown
```

At this point, Luci is fully functional as a standalone Quickshell shell.

The Dynamic Island, media controls, clock, status indicators, and all core components will work immediately.

> **Tip**
>
> If you're currently using a bar at the top of your screen, you may want to stop it temporarily while testing Luci. This simply provides a cleaner preview — if your current bar is positioned elsewhere, you can safely ignore this step.

---

### 3. Configure your compositor

Luci does not register compositor keybindings by itself. Views such as the Power Menu, Wallpaper Selector and Theme Selector are opened through Luci's IPC interface, and the volume/brightness keys are routed through Luci's helper scripts.

#### Hyprland

If you use **`hyprland.conf`**, add:

```ini
bind = mainMod, P, exec, qs ipc call luci openPowerMenu
bind = mainMod, W, exec, qs ipc call luci openWallpaperSelector
bind = mainMod, T, exec, qs ipc call luci openThemeSelector
```

If you use **`hyprland.lua`**, add:

```lua
hl.bind(mainMod .. " + P",
    hl.dsp.exec_cmd("qs ipc call luci openPowerMenu"))

hl.bind(mainMod .. " + W",
    hl.dsp.exec_cmd("qs ipc call luci openWallpaperSelector"))

hl.bind(mainMod .. " + T",
    hl.dsp.exec_cmd("qs ipc call luci openThemeSelector"))
```

#### niri

A ready-made block ships in [`config/niri/luci.kdl`](config/niri/luci.kdl). Include it from your config:

```kdl
include "~/.config/quickshell/config/niri/luci.kdl"
```

Or copy the blocks into your own `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "qs"
spawn-at-startup "awww-daemon"

binds {
    Mod+P { spawn "qs" "ipc" "call" "luci" "openPowerMenu"; }
    Mod+W { spawn "qs" "ipc" "call" "luci" "openWallpaperSelector"; }
    Mod+T { spawn "qs" "ipc" "call" "luci" "openThemeSelector"; }
}
```

> niri's `spawn` does not expand `~`, so the volume/brightness binds below use `spawn-sh`.

#### Volume & Brightness

Luci displays a temporary status notification whenever your volume or brightness changes. To enable this, route your multimedia keys through Luci's helper scripts.

Hyprland — **`hyprland.conf`**:

```ini
# Volume
bindel = , XF86AudioRaiseVolume, exec, ~/.config/quickshell/scripts/volume.sh up
bindel = , XF86AudioLowerVolume, exec, ~/.config/quickshell/scripts/volume.sh down
bindl  = , XF86AudioMute, exec, ~/.config/quickshell/scripts/volume.sh mute

# Brightness
bindel = , XF86MonBrightnessUp, exec, ~/.config/quickshell/scripts/brightness.sh +5%
bindel = , XF86MonBrightnessDown, exec, ~/.config/quickshell/scripts/brightness.sh 5%-
```

Hyprland — **`hyprland.lua`**:

```lua
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("~/.config/quickshell/scripts/volume.sh up"),
    { locked = true, repeating = true })

hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("~/.config/quickshell/scripts/volume.sh down"),
    { locked = true, repeating = true })

hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("~/.config/quickshell/scripts/volume.sh mute"),
    { locked = true })

hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("~/.config/quickshell/scripts/brightness.sh +5%"),
    { locked = true, repeating = true })

hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/quickshell/scripts/brightness.sh 5%-"),
    { locked = true, repeating = true })
```

niri — **`config.kdl`**:

```kdl
binds {
    XF86AudioRaiseVolume repeat=true allow-when-locked=true { spawn-sh "~/.config/quickshell/scripts/volume.sh up"; }
    XF86AudioLowerVolume repeat=true allow-when-locked=true { spawn-sh "~/.config/quickshell/scripts/volume.sh down"; }
    XF86AudioMute allow-when-locked=true { spawn-sh "~/.config/quickshell/scripts/volume.sh mute"; }
    XF86MonBrightnessUp repeat=true allow-when-locked=true { spawn-sh "~/.config/quickshell/scripts/brightness.sh +5%"; }
    XF86MonBrightnessDown repeat=true allow-when-locked=true { spawn-sh "~/.config/quickshell/scripts/brightness.sh 5%-"; }
}
```

Without these bindings, your volume and brightness keys may still function, but Luci won't receive the events required to display its notifications.

You are free to use any keybindings that fit your workflow — Luci only exposes the IPC commands and helper scripts, and how they are triggered is up to your compositor configuration.

### 4. Wallpaper Backend

Luci uses **Awww** to apply wallpapers.

If you want the Wallpaper Selector to update your wallpaper, make sure the daemon is running.

If you use **`hyprland.conf`**, add:

```ini
exec-once = awww-daemon
```

If you use **`hyprland.lua`**, add:

```lua
hl.exec_cmd("awww-daemon")
```

On niri, `spawn-at-startup "awww-daemon"` (already in `config/niri/luci.kdl`).

Without the daemon, the Wallpaper Selector will still display your wallpapers, but selecting one will have no effect.

## Layouts

Luci's island has three layouts, cycled with:

```bash
qs ipc call luci cycleLayout
```

- **Pill** — a compact clock capsule. Hovering expands it in place.
- **Notch** — a wider capsule flush with the top edge, for a notch-style display.
- **Bar** — a full-width bar: media on the left, the clock in the center, tray + status on the right.

In the bar layout the clock and the right cluster each drop a panel; the panels dock to the bar with the same flow-corner treatment as the bar itself edges into the monitor.

## Theme Synchronization (Hyprland only, optional)

By default, Luci only changes its own appearance.

If you want Luci to also update **Hyprland's appearance** (borders, gaps, rounding, blur, shadows, opacity, etc.), your Hyprland configuration **must be modular**.

Luci cannot modify a single `hyprland.conf` or `hyprland.lua` containing all of your settings.

Instead, your main `hyprland.lua` should simply load smaller modules, for example:

```lua
require("core.monitors")
require("core.env")
require("core.appearance")
require("core.keybinds")
require("core.programs")
require("core.input")
require("core.windows")
require("core.misc")
require("core.autostart")
```

A complete modular Hyprland configuration is included in:

```text
~/.config/quickshell/config/hypr/
```

If you don't already have a modular setup, simply move it to:

```text
~/.config/hypr/
```

and reload Hyprland:

```bash
hyprctl reload
```

### First Theme Switch

The first time you switch a theme from Luci, it automatically creates:

```text
~/.config/hypr/current-theme/theme.lua
```

This file is a symbolic link pointing to the currently selected theme.

Until this first theme switch happens, Hyprland may report an error because `current-theme/theme.lua` does not yet exist.

This is expected.

Simply open the Theme Selector and switch to any theme once. Luci will automatically create the required symbolic link and the error will disappear.

After that, every theme change will automatically update Hyprland's appearance.

> **Note**
>
> The `~/.config/quickshell/config/hypr/` directory is only an example configuration included with Luci.
>
> If you already have your own modular Hyprland setup, you can ignore it and integrate Luci however you prefer.
>
> On niri, theme switching restyles Luci itself; niri has no equivalent theme sync.

## Wallpaper Selector

Luci lists wallpapers straight from:

```text
~/Pictures/Wallpapers
```

Copy your wallpapers there (`.jpg`, `.jpeg`, `.png`, `.webp` or `.gif`) and they'll appear in the selector automatically.

There is no metadata file and no per-theme wallpaper mapping — wallpapers are just whatever sits in that folder. Selecting one applies it with **Awww** and shows a short toast with the file name on the island.

> **Roadmap**
>
> Styling and theming are planned to move to a matugen-style dynamic color pipeline — colors (and possibly the wallpaper) derived from your current wallpaper instead of hardcoded per-theme values. Not implemented yet; the selector above is the current behavior.

## Using Luci

Luci is designed around a simple interaction model. Most actions can be performed using either the keyboard or the mouse.

## Dynamic Island

When Luci starts, the Dynamic Island displays the compact clock.

### Expanding the Island

- Hover over the island to reveal the expanded view (Pill and Notch layouts).
- Clicking an **empty area** of the expanded view toggles whether it is pinned.

When the expanded view is:

- **Pinned:** it stays open even after moving the mouse away.
- **Unpinned:** it automatically returns to the compact clock when the cursor leaves the island.

In the **Bar** layout the island is always visible. The clock and the right-hand status cluster each open their own dropdown panel; clicking an empty area of the bar dismisses them.

## Media Controls

When an MPRIS-compatible media player (such as Firefox, Spotify, VLC, etc.) is playing media, Luci makes Media Controls available.

To open the Media Controls:

- **Pill / Notch:** hover to expand, then click the **left section** (the Now Playing area).
- **Bar:** click the media line on the left of the bar.
- From anywhere: `qs ipc call luci openMedia`.

The Media Controls display:

- Album artwork
- Song title and artist
- Animated waveform visualizer
- Playback progress
- Previous / Play-Pause / Next controls

## Control Center

The Control Center holds the everyday toggles: **Wi-Fi**, **Bluetooth**, **Mic**, **Night Light**, **Wallpaper**, **Focus**, **Auto-Hide** and the **Layout** switcher.

- **Pill / Notch:** open it from the right-hand cluster of the expanded view. It also shows the volume and brightness sliders and your notifications.
- **Bar:** click the Wi-Fi/Bluetooth/battery cluster on the right. The bar's Control Center shows the storage card; the volume and brightness sliders live in the clock dropdown instead.

## Keyboard Navigation

Luci supports Vim-inspired keyboard navigation in supported views such as the Theme Selector, Wallpaper Selector, and Power Menu.

| Action | Keys |
|--------|------|
| Move Left | **H** or **←** |
| Move Right | **L** or **→** |
| Move Up | **K** or **↑** |
| Move Down | **J** or **↓** |
| Confirm / Apply | **Enter** |
| Close View | **Esc** |

Pressing **Enter** activates the currently selected item.

For example:

- Apply a theme in the Theme Selector.
- Apply a wallpaper in the Wallpaper Selector.
- Confirm an action in the Power Menu.

## Status Notifications

Luci provides temporary notifications whenever your system volume, brightness, or workspace changes.

The behavior depends on the current layout:

- **Pill / Notch:** the clock is temporarily replaced with the notification.
- **Bar:** the notification appears as a **Status Chip** on the right side of the bar, leaving the rest of the interface visible.
- **Bar, clock dropdown open:** while the volume/brightness sliders are on screen they are the feedback, so the status notification is skipped.

After a short delay, the notification automatically disappears and Luci returns to its normal state.

## Night Light

The Night Light card toggles a warm color temperature:

- **Hyprland:** `hyprsunset`
- **niri:** `gammastep`

Luci checks the actual backend state before toggling, so the card always reflects whether the screen is warm or neutral, and it won't leave duplicate or zombie processes behind.

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — module map and conventions.
- [`docs/IPC.md`](docs/IPC.md) — the full `luci` IPC surface.

## Daily Driver

If you've finished testing Luci and would like it to start automatically whenever you log in, configure your compositor to launch it during startup.

### If you use `hyprland.conf`, add:

```ini
exec-once = qs -c ~/.config/quickshell
```

### If you use `hyprland.lua`, add the following line inside your existing `hyprland.start` callback:

```lua
hl.exec_cmd("qs -c ~/.config/quickshell")
```

For example:

```lua
hl.on("hyprland.start", function()
    -- your existing startup commands

    hl.exec_cmd("qs -c ~/.config/quickshell")
end)
```

On niri, `spawn-at-startup "qs"` (already in `config/niri/luci.kdl`).

Once configured, Luci will automatically start every time you begin a session.

If you're still experimenting or prefer running it manually, you can launch it at any time:

```bash
qs -c ~/.config/quickshell & disown
```

## Credits

Luci is designed and built by **[Elham Sadiqi](https://github.com/ElhamSadiqi)** — upstream repository: <https://github.com/ElhamSadiqi/Luci>.

All credit for the original project goes to the author.

## License

Luci is released under the MIT License.

See the [LICENSE](LICENSE) file for the full license text.
