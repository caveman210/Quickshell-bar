# Architecture

Luci is a single Quickshell `ShellRoot` (`shell.qml`). It instantiates a few
long-lived services and two layer-shell windows; everything else is QML items
composed on demand.

```
shell.qml                 entry point (ShellRoot)
├── core/                 singletons: shared state + controller
├── island/               dynamic island: state, interaction, view host
├── services/             data providers (never create UI)
├── windows/              layer-shell surfaces
├── views/                what fills the island, per layout
├── components/           reusable UI pieces
├── styles/               theme constants + theme definitions
├── scripts/              helpers the shell shells out to
├── config/               example compositor configs (Hyprland, niri)
└── assets/               icons and images
```

## core/

- **`IslandState`** — the island's `mode` (`default`, `expanded`,
  `controlCenter`, `powerMenu`, `wifiMenu`, …) and `layout` (`pill`, `notch`,
  `bar`), plus transient flags (pinning, tray open, hover). Mode and layout are
  in-memory and reset on reload.
- **`IslandController`** — every state transition in one place
  (`openExpanded`, `openControlCenter`, `openMediaControls`, `cycleLayout`,
  `togglePin`, `reset`, …). Views and IPC call this, never `IslandState`
  directly.
- **`StatusManager`** — the transient status toast (OSD): mode, icon, title,
  value, plus a small queue for device events (wifi/bluetooth).

## island/

- **`Island`** — the visual island: the bar/pill/notch surfaces, the dropdown
  panels and the flow-corner fillets that blend surfaces into the screen edges.
- **`ViewHost`** — maps `IslandState.mode` (and layout) to the view that fills
  the island.
- **`IslandInteraction`** — hover/click behaviour: expand on hover (pill/notch),
  collapse on leave, pin/unpin, tray handling in the bar.
- **`FlowCorner`** — reusable concave fillet used to join the bar and its
  dropdowns to the monitor borders.

## services/

Data providers, one concern each, no UI.

- Audio / brightness / microphone, wifi / bluetooth, battery + low-battery.
- `MediaService` (MPRIS) and `CavaService` (visualizer).
- `NotificationService` + `NotificationStore` — per-day JSONL history under
  `~/.cache/quickshell/notifications/`, immutable avatar blobs, 30-day prune.
- `CompositorService` — abstracts Hyprland vs niri (workspaces, keyboard, edge
  hover) behind `services/compositor/hyprland/` and `services/compositor/niri/`.
- `ThemeService`, `WallpaperService`, `StorageService`, `NightLightService`.
- `StatusWatcher` — watches the event file written by `scripts/` (volume,
  brightness, workspace) and drives the OSD. The shell never polls for these.
- `IslandIPC` — the `qs ipc call luci <fn>` surface (see `docs/IPC.md`).

## views/

One file per mode, grouped where the layout differs:

- `bar/` — `BarView` (idle bar) and `BarExpandedView` (clock dropdown).
- `pill/`, `notch/` — compact layouts.
- `panels/` — control center, power menu, selectors, menus, media, notifications.
- `shared/` — clock, date, status overlay, notification list.

## windows/

- `IslandWindow` — the layer-shell surface the island lives in (anchored to the
  top edge; exclusive zone 33 unless auto-hide is on).
- `EdgeTriggerWindow` — the auto-hide reveal strip.
- `compositor/` — Hyprland focus-grab dismiss and the niri fallback click
  catcher.

## styles/

`Theme.qml` is the single source of visual constants (colors, spacing, radii,
timings). `styles/themes/<name>/` holds each theme's `Theme.qml`,
`HyprTheme.lua` and `kitty.conf`.

## scripts/

Helpers that touch the OS: `volume.sh`, `brightness.sh`, `theme.sh`
(→ `compositor/hyprland-theme-sync.sh`), `cava.conf`. Volume and brightness
write an event file that `StatusWatcher` watches, so the OSD is event-driven.

## Conventions

- Singletons use `pragma Singleton` at the top level only.
- Components are defined before their consumers (hot reload depends on it).
- Services never create UI; views never shell out directly.
- Compositor-specific code lives under `services/compositor/` and
  `windows/compositor/`.
