# Compact Monitor

**A tiny hardware monitor for the KDE Plasma 6 panel.**

[English](README.md) · [简体中文](README.zh_CN.md)

CPU, memory, GPU, disk, network, battery, fan… rendered as plain text, in the spirit of
[TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) on Windows.

![Compact Monitor running in a Plasma panel](Screenshots/Main.png)

> [!IMPORTANT]
> **This is an AI-generated project.**
> Almost all of the code and documentation in this repository was written by an AI coding
> assistant from a series of prompts and screenshots, then reviewed, run and
> tested on real hardware (Manjaro Linux, Plasma 6.7.4, Wayland). It is *not* the work of a
> seasoned QML developer, so expect rough edges. Issues and pull requests are very welcome —
> just keep in mind that the maintainer is reading AI-written code as well.

## Why another system monitor?

Plasma's own *System Monitor* widget can already show sensors as text
(`org.kde.ksysguard.textonly` face), but every sensor drags along a thick colored bar and a
lot of padding, so a handful of them fills half the panel. Compact Monitor draws nothing but
text and hugs its content: the screenshot above is ten sensors in two lines.

```
↑ 1.2 KiB/s   CPU 6.9%    GPU 0%    RAM 31.9%   CPU 1.7 GHz
↓ 992 B/s     CPU 44.9 °C BAT 79%   DISK 27.6%  FAN 2,640.0 RPM
```

## Features

* **Compact**: only text, the width follows the content, one or two lines
* **Two layouts**
  * *Packed* — each line is centered on its own, the most compact result
  * *Aligned* — a table: sensors fill columns (1 3 5 / 2 4 6, so related sensors such as
    upload/download or temperature/usage stack vertically)
* **Names and values can be aligned independently** (left / center / right) in the table layout
* **Automatic short names**: leave a sensor's label empty and it becomes `CPU`, `RAM`,
  `DISK`, `FAN`, `BAT`, `↓`, … (3–4 characters, derived from the sensor id)
* **Font control**: family, bold, and either an explicit pixel size (6–48) or a size that
  fits the panel height automatically
* **Per-sensor colors** plus an optional color bar, and an **automatic light/dark contrast
  adjustment** that keeps the colors readable on any theme
* **Sensor management**: add / remove / reorder with a searchable sensor picker, per sensor
  label and color
* **Import / export** the sensor list as a JSON file; broken entries are skipped and reported
  instead of failing the whole import
* **Details**: hover tooltip listing every value, custom refresh interval (100 ms – 10 s),
  item spacing, an optional separator character, click for a larger popup view
* Right-click → *Configure Compact Monitor…* opens the standard Plasma configuration dialog
* UI strings are Chinese for now — an English translation is a welcome contribution

## Screenshots

| Panel                                        | Configuration → Appearance               |
| -------------------------------------------- | ----------------------------------------- |
| ![widget in the panel](Screenshots/Main.png) | ![appearance page](Screenshots/Menu1.png) |

| Configuration → Sensors               |
| -------------------------------------- |
| ![sensors page](Screenshots/Menu2.png) |

## Requirements

* KDE Plasma **6** (developed and tested on Plasma 6.7.4, Manjaro Linux, Wayland)
* `libksysguard` — provides the `org.kde.ksysguard.sensors` QML module the widget reads
* `ksystemstats` running (part of any normal Plasma session)
* `org.kde.plasma.plasma5support` — only used for import/export (ships with Plasma 6)

No compilation, no C++, no build system: it is a pure QML plasmoid.

## Installation

```bash
git clone https://github.com/MC-DALIU/KDE_Compact_sensor_monitor.git plasma-compact-monitor
cd plasma-compact-monitor
./install.sh
```

`install.sh` installs (or updates) the plasmoid and restarts `plasmashell`:

```bash
./install.sh               # install and restart plasmashell
./install.sh --no-restart  # install only
./install.sh --uninstall   # remove the widget
```

Or by hand:

```bash
kpackagetool6 --type Plasma/Applet --install org.mcdaliu.compactmonitor
# updating: use --upgrade, or --remove first
```

Then right-click the panel → **Add Widgets…** → search for *Compact Monitor*.

> [!WARNING]
> **Restart plasmashell after installing or updating.**
> plasmashell caches a widget's QML per plugin id, so simply removing and re-adding the
> widget does **not** pick up changed files:
>
> ```bash
> systemctl --user restart plasma-plasmashell
> ```
>
> or log out and back in.

## Configuration

Right-click the widget → *Configure Compact Monitor…*. There are two pages.

### Appearance

| Option                | Description                                                                           |
| --------------------- | ------------------------------------------------------------------------------------- |
| Lines                 | one or two text lines                                                                 |
| Layout                | *Packed*: each line centered on its own; *Aligned*: a table with lined-up columns |
| Key / value alignment | how names and values are aligned inside their column in the table layout              |
| Sensor spacing        | pixels between two sensors                                                            |
| Separator             | optional character drawn between sensors (never after the last column)                |
| Font / size / bold    | system font or any installed family; 6–48 px, or auto-fit to the panel               |
| Show names            | whether the name is drawn in front of the value                                       |
| Text color            | custom color for all text, otherwise every sensor uses its own color                  |
| Dark/light            | automatically darken colors on light themes and brighten them on dark ones            |
| Color bar             | draw a small colored bar in front of sensors that have a color                        |
| Refresh interval      | 100–10000 ms                                                                         |

The page starts with a live preview built from the *currently applied* sensor list, so
layout, font, alignment and color changes can be judged before pressing *Apply*.

### Sensors

Every row offers a color swatch, the sensor's own name, its live value and id, a label field
(the grey placeholder is the automatically recognized short name), a *Name* checkbox and
move up / move down / remove buttons. *Add sensor…* opens a searchable tree of everything
`ksystemstats` reports, *Restore defaults* brings back the shipped four, and
*Import…* / *Export…* read and write JSON files.

## Sensor IDs

The sensor list comes from `ksystemstats`. To list every id available on your machine:

```bash
qdbus6 --literal org.kde.ksystemstats1 /org/kde/ksystemstats1 \
    org.kde.ksystemstats1.allSensors | grep -o '"[a-z0-9/_-]*"'
```

Some useful ones:

| Sensor                              | ID                                                                              |
| ----------------------------------- | ------------------------------------------------------------------------------- |
| CPU usage / temperature / frequency | `cpu/all/usage`, `cpu/all/averageTemperature`, `cpu/all/averageFrequency` |
| Physical memory, swap               | `memory/physical/usedPercent`, `memory/swap/usedPercent`                    |
| Network up / down                   | `network/all/upload`, `network/all/download`                                |
| Disk read / write                   | `disk/all/read`, `disk/all/write`                                           |
| GPU                                 | `gpu/gpu0/usage`, `gpu/gpu0/temperature`, `gpu/gpu0/power`                |
| Fans and temperatures               | `lmsensors/<chip>/fan1`, `lmsensors/<chip>/temp1`                           |
| Battery                             | `power/<battery>/chargePercentage`, `power/<battery>/chargeRate`            |

The shipped default is `network/all/upload` (↑), `network/all/download` (↓),
`cpu/all/usage` (CPU) and `memory/physical/usedPercent` (RAM), on two lines.

## Automatic short names

When a sensor has no label of its own, its name is derived from the sensor id
(`contents/ui/SensorNames.js`) — first the first path component, then a few
metric-specific refinements:

| Sensor ID                                         | Name    |  | Sensor ID                     | Name |
| ------------------------------------------------- | ------- | - | ----------------------------- | ---- |
| `cpu/all/usage`, `cpu/all/averageTemperature` | CPU     |  | `power/…/chargePercentage` | BAT  |
| `gpu/gpu0/usage`                                | GPU     |  | `power/…/chargeRate`       | PWR  |
| `memory/physical/usedPercent`                   | RAM     |  | `lmsensors/…/fan1`         | FAN  |
| `memory/swap/usedPercent`                       | SWAP    |  | `lmsensors/…/temp1`        | TEMP |
| `disk/nvme0n1/read`                             | DISK    |  | `lmsensors/…/in0`          | VOLT |
| `network/all/download` / `upload`             | ↓ / ↑ |  | `network/wlp1s0/signal`     | WIFI |

Anything else is abbreviated to the first four upper-case characters
(`wifi/foo/bar` → `WIFI`). The three tables `GROUPS`, `METRICS` and `HARDWARE_PREFIXES` in
`SensorNames.js` are easy to extend.

## Import / export

*Export…* on the sensors page writes a file like this:

```json
{
  "applet": "org.mcdaliu.compactmonitor",
  "version": 1,
  "exportedAt": "2026-09-25T13:44:10.398Z",
  "sensors": [
    { "sensorId": "network/all/upload", "label": "↑", "color": "#2ec27e", "showLabel": true },
    { "sensorId": "cpu/all/usage", "label": "CPU", "color": "#e5a50a", "showLabel": true }
  ]
}
```

*Import…* accepts that object or a plain array of entries. Only `sensorId` is required —
`label`, `color` and `showLabel` may be omitted. `color` accepts `#rrggbb` as well as KDE's
`r,g,b` form, `showLabel` accepts `true/false/1/0`. The list is validated entry by entry and
bad entries are **skipped and reported** in a message bar at the top of the page (up to eight
details; everything also goes to the plasmashell log):

| Problem                           | Behaviour                              |
| --------------------------------- | -------------------------------------- |
| not an object, or no`sensorId`  | skipped                                |
| sensor id unknown on this machine | skipped                                |
| the same id twice                 | the later one is skipped               |
| unparsable`color`               | entry kept, color ignored (reported)   |
| broken JSON / unreadable file     | red error message, nothing is imported |

Importing **replaces** the current sensor list.

## How it works

A few notes for anyone who wants to hack on it (or write a similar widget):

* Sensor data comes from libksysguard's QML modules (`org.kde.ksysguard.sensors`: `Sensor`,
  `SensorTreeModel`), which talk to `ksystemstats` — the same data the System Monitor uses,
  no C++ required.
* **Panel width**: the panel layout only reads `Layout.preferredWidth` / `implicitWidth` of
  the *applet item itself* (see plasma-desktop `containments/panel/contents/ui/main.qml`), so
  `main.qml` mirrors the compact representation's width onto the root object. Sizing only the
  compact representation makes the applet fall back to a minimum width (28 px).
* **Automatic font size** is derived from the height the panel gives us:
  `min(height / lines × 0.78, gridUnit × 0.8)`, clamped to 7–28 px.
* **Dark/light adaptation** (`contents/ui/ColorUtils.js`) uses WCAG relative luminance and
  contrast: hue and saturation are kept and the brightness is binary-searched until it just
  reaches a 4.0:1 contrast ratio against the background. A green therefore stays green,
  instead of turning magenta as a plain RGB invert would. The background is
  `Kirigami.Theme.backgroundColor`, which Plasma fills in from the real panel background (so
  a dark panel on a light theme also works).
* **Files** (`export` / `import`) go through `org.kde.plasma.plasma5support`'s `executable`
  data source, because QML has no file API. Commands run through a shell, so
  `printf %s … > file` works; completion is signalled by an `"exit code"` key (with a space)
  and output may arrive in several chunks.
* **Config pages** receive `cfg_<key>` initial properties which are read back when saving, so
  every editable value is named `cfg_*`.
* `Kirigami.FormLayout` sizes its rows by the children's `implicitHeight`, and a `QQC2.Label`
  with `wrapMode` still reports its full unwrapped width as `implicitWidth`. Both behaviours
  bit the configuration pages — see the comments in `HintLabel.qml` and
  `ConfigAppearance.qml`.

## Troubleshooting

| Symptom                                                       | Cause / fix                                                                                     |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| After an update the widget shows nothing, or is a tiny square | plasmashell's QML cache — restart plasmashell                                                  |
| A sensor always shows`--`                                   | that sensor id does not exist on this machine; check the picker                                 |
| Colors look washed out                                        | that is the automatic contrast adjustment; turn*Dark/light* off to keep your colors untouched |
| The widget is too wide                                        | fewer sensors, hide the names, smaller font, or the*Packed* layout                            |
| Want to get rid of it                                         | `./install.sh --uninstall`, then remove the leftover icon from the panel                      |

## Known limitations / roadmap

* Sensors are split by count (packed) or by column (aligned); a sensor cannot be pinned to a
  specific row or column
* Values are not padded to a fixed width, so their length can change as the numbers grow (the
  *aligned* layout at least keeps the columns themselves stable)
* No graphs, thresholds or history yet
* UI strings are Chinese only so far

## Contributing

Issues, screenshots of your own panel setup and pull requests are welcome. If you touch QML
files, please run at least

```bash
qmllint org.mcdaliu.compactmonitor/contents/ui/*.qml
```

and restart plasmashell while testing. Keep in mind that the project is AI-generated: expect
inconsistencies, and feel free to point them out.

## Credits

* [KDE](https://kde.org) Plasma, [libksysguard](https://invent.kde.org/plasma/libksysguard)
  and `ksystemstats` for the sensor infrastructure this widget is built on
* [TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) for the original idea and
  the look this widget tries to match
* The screenshots use the Breeze Plasma theme

## License

GPL-2.0-or-later — see [LICENSE](LICENSE). Every source file carries an SPDX header; the
`LICENSE` file contains the GPL-2.0 text and the "or later" option is expressed in those
headers.
