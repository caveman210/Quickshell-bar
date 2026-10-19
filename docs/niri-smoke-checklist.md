# niri smoke checklist

Run on a live niri session to make sure Luci works end to end.

Environment used for the last pass: **niri 26.04 (Nixpkgs)**, single output
`eDP-1` (1920×1200, scale 1.2), shell started with `qs`.

## Startup & reload

- [x] Shell starts and the island renders on the top edge.
- [x] Editing a file in the config dir hot-reloads: log shows
      `Reloading configuration…` → `Configuration Loaded`, no QML errors.
- [x] Layout/mode are in-memory: a reload returns the island to Pill (by design).

## IPC — `qs ipc call luci <command>`

All commands exit `0`.

| command | result |
|---|---|
| `openExpandedHome` | opens the expanded view |
| `openControlCenter` | opens the Control Center |
| `openPowerMenu` | opens the power menu |
| `openWallpaperSelector` | opens the wallpaper selector |
| `openThemeSelector` | opens the theme selector |
| `openWifiMenu` | opens the Wi-Fi menu |
| `openBluetoothMenu` | opens the Bluetooth menu |
| `openMedia` | opens the media controls |
| `openNotifications` | opens the notifications pane |
| `cycleLayout` | cycles Pill → Notch → Bar |
| `focusToggle` | toggles Focus |
| `reset` | returns to the idle island |

## Layouts

- [x] Pill: compact clock; hover expands.
- [x] Notch: capsule flush with the top edge.
- [x] Bar: full-width bar — media left, clock center, tray + status right;
      the clock and the right cluster each drop a panel.
- [x] `cycleLayout` ×3 returns to the starting layout.

## Views

- [x] Control Center (bar): card grid + storage card, and **no**
      volume/brightness sliders (they live in the clock dropdown).
- [ ] Control Center (pill/notch): card grid + volume/brightness sliders +
      notifications pane. Not driven in the last pass (the CC only opens over
      the IPC from the bar layout); guaranteed by construction — the same
      `ControlCenterView` gates the sliders on `!layoutIsBar`.
- [x] Night Light card present (`gammastep` installed) and toggles warm/neutral.
- [ ] Media controls: artwork, title/artist, waveform, progress, transport.
- [x] Notifications pane lists history; a record whose avatar has gone missing
      falls back to the app icon instead of breaking.

## Status / OSD

- [x] Volume / brightness (via `scripts/volume.sh` and `scripts/brightness.sh`)
      raise the status toast.
- [x] Bar, clock dropdown open: the OSD is suppressed — the slider on screen is
      the feedback.
- [ ] Workspace change toast.

## Process hygiene

- [x] No zombie/defunct children; the volume/brightness helpers exit cleanly.
- [x] Night Light OFF runs an unanchored `pkill gammastep` plus a one-shot
      `gammastep -x` reset, because niri keeps the last gamma ramp after the
      daemon exits.

## Known benign warnings

- `NotificationView.qml[111] Cannot open …/Screenshot from 2026-10-19 14-02-20.png`
  — the referenced notification image was moved out of `~/Pictures/Screenshots`;
  the view falls back to the app icon.
- `NotificationView.qml[111] Cannot open …/c4507d76f10ca0d4.png` — an old
  history record references an avatar blob that no longer exists; same fallback.
- `quickshell.bluetooth.adapter: Failed to start discovery … "Resource Not Ready"`
  — transient; fired while opening the Bluetooth menu as the adapter came up.

## Not covered here (needs Hyprland)

- Theme sync to the compositor (`scripts/compositor/hyprland-theme-sync.sh`).
- `HyprlandFocusGrabDismiss` for modal views.
- `HyprlandEdgeHoverMonitor` auto-hide reveal.
