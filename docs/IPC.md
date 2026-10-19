# IPC

Luci exposes one IPC target, `luci`. Call it from anywhere:

```bash
qs ipc call luci <command>
```

| Command | Effect |
|---|---|
| `openExpandedHome` | open the expanded view (home) |
| `openControlCenter` | open the Control Center |
| `openPowerMenu` | open the power menu |
| `openWallpaperSelector` | open the wallpaper selector |
| `openThemeSelector` | open the theme selector |
| `openWifiMenu` | open the Wi-Fi menu |
| `openBluetoothMenu` | open the Bluetooth menu |
| `openMedia` | open the media controls (left section) |
| `openNotifications` | open the notifications pane |
| `cycleLayout` | cycle the island layout: Pill → Notch → Bar |
| `focusToggle` | toggle the Focus state |
| `reset` | return to the idle island |

## Compositor binds

Hyprland (`hyprland.lua`):

```lua
hl.bind("SUPER + P", hl.dsp.exec_cmd("qs ipc call luci openPowerMenu"))
hl.bind("SUPER + W", hl.dsp.exec_cmd("qs ipc call luci openWallpaperSelector"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("qs ipc call luci openThemeSelector"))
```

niri (`config.kdl`):

```kdl
Mod+P { spawn "qs" "ipc" "call" "luci" "openPowerMenu"; }
Mod+W { spawn "qs" "ipc" "call" "luci" "openWallpaperSelector"; }
Mod+T { spawn "qs" "ipc" "call" "luci" "openThemeSelector"; }
```

`config/niri/luci.kdl` in this repo is a ready-made block you can `include`.
