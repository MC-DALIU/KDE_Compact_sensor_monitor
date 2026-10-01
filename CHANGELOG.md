# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The version here
matches `KPlugin.Version` in
[`org.mcdaliu.compactmonitor/metadata.json`](org.mcdaliu.compactmonitor/metadata.json), which is
the version the widget reports to Plasma.

## [Unreleased]

## [1.3.0] - 2026-10-01

### Added

- **External content placeholder areas.** The widget can reserve any number of areas for content that
  other programs push in: a music player's current title, a script's output, a build status. Each area
  has a name, which is also the file it reads (`~/.cache/compact-monitor/<name>.json` by default), and
  a slot that places it in front of every sensor or right after any one of them, so areas and sensors
  can be **interleaved** instead of sitting at either end. An area has half or full height, a fixed /
  minimum / maximum width, a font size of its own, and can keep its space while it is empty. They live
  on their own *External content* page in the settings.
  - All files are read by **one** command per interval, and reading uses the shell's builtin instead of
    a `cat` process per area: measured 1.7 ms per poll for five areas, the same as for one, roughly
    0.17 % of one core per second — and nothing runs at all while no area is configured. The read
    interval is configurable.
  - `tools/compact-monitor-push` writes into an area by name (`--id music`, `--color`, `--align`,
    `--tooltip`, `--clear`).
  - The areas travel in the exported configuration, and the widget can run with only placeholder areas
    and no sensors at all.

### Changed

- Placeholder areas are measured against the sensors' own text block instead of the panel height, so a
  full-height area can no longer push the widget past the panel edge (two sensor rows plus a 36 px area
  used to make the widget 53 px tall). In the aligned layout a full-height area now gets a **column of
  its own**, with the sensors continuing on either side of it.
- The light/dark adjustment applies to the colour an external program pushes in, like it already did
  for the sensors' own colours.
- The widget's display is now built from one list that mixes sensors and placeholder areas, which is
  what makes the interleaving possible.

### Fixed

- **The widget did not load on Qt 6.8** (Debian 13 with Plasma 6.3, for example): the translation
  singleton used `short` as a variable name, and several other identifiers (`color`, `list`, `url`,
  `action`, and a property called `color`) were QML type keywords in older QML engines, which made the
  whole applet fail with "Type I18n unavailable". They have been renamed, and the applet, all
  configuration pages and the English translation were verified to parse and instantiate on
  Plasma 6.3.6 / Qt 6.8 again.
- **The text colour chosen in the configuration was not applied.** Renaming the colour dialog's
  property for the Qt 6.8 keyword fix (`color` → `selectedColor`) missed one call site, so accepting
  the dialog silently did nothing and the colour stayed whatever it had been. Both call sites use the
  new name now, and an empty colour ("use the theme colour") falls back to the Plasma theme colour
  instead of being passed on as an invalid one. The released 1.2.0 is *not* affected by this.
- Tool tips in the configuration dialog time out after four seconds: Plasma's tool tip style never
  hides them by itself, so the hint on an area's interface file could stay on screen.
- The configuration preview gives its content an explicit size before centring it. An `Item` that only
  sets `implicitWidth` keeps an actual width of zero, which made the preview sit off-centre.

## [1.2.0] - 2026-09-27

### Added

- **Translations.** The interface follows the system language by default and can also be chosen per
  widget on the *Appearance* page; English ships with the widget. Chinese is the source language, so
  a missing entry falls back to it and an unfinished translation is still usable. Adding a language
  is one QML file — see *Translating* in the README.
- `contents/i18n/en.qml` (130 entries) and the singleton that looks them up.

### Changed

- Export and import now default to `compact-monitor-config.json`, which is what the file actually
  holds, and the buttons and tool tips say "configuration" instead of "sensor configuration".
- `package.sh` names its output after the version in `metadata.json`
  (`compact-monitor-<version>.plasmoid`) so that downloads can be told apart; the file name was and
  is irrelevant for installing and updating.
- Documentation: the installation instructions start with downloading the package file from
  store.kde.org, and state explicitly that Plasma's *Add Widgets… → Get New Widgets…* does not list
  this widget, so the file has to be installed by hand.

## [1.1.0] - 2026-09-27

### Added

- **Deadband (hysteresis) for threshold alerts.** After firing, a rule is disarmed until the value
  has come back past the threshold by the configured margin (5% of the threshold by default,
  `0` disables it), so a sensor hovering around the threshold - 81, 79, 81, 79 around 80 - notifies
  once instead of on every crossing. The margin travels in the exported JSON as `hysteresis`.
- The tool tip is drawn by the widget itself, so it lists **every** configured sensor. Plasma's own
  tool tip layout stops after eight lines (`core/DefaultToolTip.qml`).
- `package.sh`, which builds the distributable `compact-monitor.plasmoid` archive used by GitHub
  releases and store.kde.org, and `.gitignore` for it.
- Screenshots of the alerts page and of a fired notification; the changelog itself.

### Changed

- Configuration pages no longer rely on anything outside their own `cfg_*` properties, and the
  sensors page now also declares the appearance settings and alert rules, because the JSON it
  exports contains them.
- Documentation: how to install the packaged file, the release procedure, and two new pitfalls
  (config pages have no `Plasmoid` object; `toolTipItem` belongs to `PlasmoidItem`, not to
  `Plasmoid`).

### Fixed

- **Export and import did nothing** in the configuration dialog: `Plasmoid` does not exist in a
  config page, so reading `Plasmoid.configuration` raised `ReferenceError: Plasmoid is not defined`
  and aborted the function before any file was touched. Both pages now use the `cfg_*` mechanism the
  dialog provides.
- The appearance page's preview listed no sensors, for the same reason.
- The preview shrank with a `scale` transform, which made the glyphs look uneven; it now reduces the
  font size, measures the natural width on a hidden copy, stretches across the dialog and is clipped
  as a safety net.
- An alert could fire again after an unrelated configuration change, because the "already notified"
  state was reset whenever the rule list was re-evaluated; it is now keyed by the rule's own content.

## [1.0.0] - 2026-09-26

First public release. Repository: <https://github.com/MC-DALIU/KDE_Compact_sensor_monitor>

### Added

- Compact, text-only sensor display for the Plasma 6 panel: one or two lines, width follows the
  content
- Two layouts: *packed* (each line centred) and *aligned* (a table filled by columns, 1 3 5 / 2 4 6)
- Independent alignment of names and values (left / centre / right) in the table layout
- Automatic short names for sensors without a label (`CPU`, `RAM`, `DISK`, `FAN`, `BAT`, `↓`, …)
- Font family, bold, and either an explicit size (6–48 px) or a size that fits the panel height
- Per-sensor colours with an optional colour bar, and automatic contrast adaptation for light and
  dark themes
- Sensor management with a searchable picker: add, remove, reorder, rename, recolour
- Import and export of the whole setup as JSON — sensors, appearance settings and alert rules —
  skipping and reporting broken entries
- Threshold alerts with desktop notifications, a deadband (hysteresis) and a cooldown, so a value
  hovering around the threshold does not notify over and over
- Tool tip listing every configured sensor
- Hover tool tip, click-to-expand popup view, configurable refresh interval, item spacing and
  separator
- Chinese user interface; English and Chinese documentation

[Unreleased]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/releases/tag/v1.0.0
