# KM Goal Tracker

A Garmin Connect IQ widget for tracking yearly or monthly running distance goals directly on your wrist.

**[Download from the Garmin Connect IQ Store](https://apps.garmin.com/apps/f96c20da-9ce0-4027-a56f-f143b5a1dfd1)**

## Features

- **Yearly or monthly** distance goal tracking
- **Kilometers or miles** — your choice
- **Visual progress arc** with ahead/behind pace coloring
- **Required pace breakdown** — per day, per week, per month
- **Customizable colors** — accent, ahead, and behind pace indicators
- **Glance view** for the widget carousel (SDK 3.2+ devices)
- **3 swipeable pages**: Overview, Pace Details, Settings Info

## Screenshots

| Overview | Pace Details | Settings |
|----------|-------------|----------|
| Progress arc with completed/remaining distance | Required daily, weekly, and monthly pace | Current goal and configuration summary |

## Supported Devices

- Fenix 8 (43mm, 47mm, Pro, Solar)
- Fenix 7 / 7S / 7X
- Fenix 6 / 6S / 6X Pro
- Forerunner 245 Music, 255, 265, 945, 955, 965
- Venu 2 / 2S / 3 / 3S

## Getting Started

1. Install from the [Connect IQ Store](https://apps.garmin.com/apps/f96c20da-9ce0-4027-a56f-f143b5a1dfd1)
2. Open the widget settings in the Garmin Connect app on your phone
3. Set your distance goal
4. Choose yearly or monthly tracking
5. **Enter your distance completed so far this period** — the app tracks from install day forward, so enter what you've already done this year/month for an accurate total
6. Pick kilometers or miles
7. Customize your colors

## Settings

| Setting | Options | Default |
|---------|---------|---------|
| Goal Type | Yearly / Monthly | Yearly |
| Goal | 1 – 50,000 | 2,026 |
| Distance completed so far | 0 – 50,000 | 0 |
| Units | Kilometers / Miles | Kilometers |
| Accent Color | Blue, Green, Orange, Red, Purple, Cyan, Yellow, White | Blue |
| Behind Pace Color | Red, Orange, Yellow, Purple | Red |
| Ahead Pace Color | Green, Blue, Cyan, White | Green |

## How It Works

The widget tracks your distance using `ActivityMonitor` data from your watch. It accumulates daily totals in persistent storage, so your progress is maintained across reboots and app restarts.

Since Garmin's on-device history is limited to 7–30 days, the app cannot pull your full year-to-date distance automatically. Use the **"Distance completed so far"** setting to enter your existing progress when you first install.

## Building from Source

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (8.4.1+)
- A developer key (`.der` file) — [generate one](https://developer.garmin.com/connect-iq/programmers-guide/getting-started/)
- Java Runtime (required by SDK tools)

### Build Commands

```bash
# Build for a specific device (simulator/sideload)
monkeyc -w -d fenix847mm -o bin/KMGoalTracker.prg -f monkey.jungle -y /path/to/developer_key.der

# Build store package (all devices)
monkeyc -e -w -o bin/KMGoalTracker.iq -f monkey.jungle -y /path/to/developer_key.der
```

### Run in Simulator

```bash
# Launch the simulator
simulator.exe

# Deploy to simulator
monkeydo bin/KMGoalTracker.prg fenix847mm
```

## Project Structure

```
KMGoalTracker/
├── manifest.xml              # App identity, devices, permissions
├── monkey.jungle             # Build configuration
├── resources/
│   ├── drawables.xml         # Drawable resources (launcher icon)
│   ├── launcher_icon.png     # App icon
│   ├── properties.xml        # Default setting values
│   ├── settings.xml          # Settings UI (Garmin Connect app)
│   └── strings.xml           # Localized strings
└── source/
    ├── KMGoalApp.mc          # App entry point
    ├── KMGoalView.mc         # Main widget view (3 pages)
    ├── KMGoalGlanceView.mc   # Glance view for widget carousel
    └── KMGoalDelegate.mc     # Input handler (swipe/tap navigation)
```

## License

MIT
