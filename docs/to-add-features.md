# Quickshell Dynamic Island: Pending Features from islandcn

Backlog of features identified from the `islandcn` reference audit to be brought into Quickshell in future passes:

## 1. Timers & Countdown Ring (`CountdownRing` / `TimerActivity`)
- **Compact presentation**: Circular SVG ring counting down in seconds with ticking time beside it.
- **Expanded presentation**: Full-width countdown with pause, resume, and cancel buttons.
- **Backend**: Integration with system clock alarms or a CLI timer service.

## 2. File Transfer & Download Progress (`LinearProgress` / `StepProgress`)
- **Compact presentation**: Inline miniature progress bar indicating active transfer.
- **Expanded presentation**: Multi-stage progress tracking (e.g., download percentage, ETA, network throughput).
- **Backend**: Hooks into browser download indicators or background CLI job wrappers.

## 3. Dedicated Recording Indicator (`RecordingActivity`)
- **Compact presentation**: Pulsing red dot with elapsed recording counter (`MM:SS`).
- **Expanded presentation**: Active voice waveform with stop/pause actions.
- **Backend**: Audio monitor hook detecting active microphone capture sinks.

## 4. Multi-Activity Split Bubble Engine
- **Presentation**: Attached pill on the left (primary) and detached circular bubble on the right (secondary) when two tasks run concurrently.
- **Priority Stack**: Incoming Call > Active Media > Background Tasks.
