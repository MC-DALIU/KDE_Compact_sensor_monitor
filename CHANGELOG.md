# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The version here
matches `KPlugin.Version` in
[`org.mcdaliu.compactmonitor/metadata.json`](org.mcdaliu.compactmonitor/metadata.json), which is
the version the widget reports to Plasma.

## [Unreleased]

_Nothing yet — add user-visible changes here before releasing, and move them into a new version
section when the version in `metadata.json` is bumped._

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

[Unreleased]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/releases/tag/v1.0.0
