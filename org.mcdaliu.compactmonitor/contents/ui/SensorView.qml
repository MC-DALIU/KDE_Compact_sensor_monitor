/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
    Lays out the configured sensors as one or two lines of "name value" pairs.

    Two arrangements are supported:

    * packed (default): every line is centered on its own, the most compact
      result, the widths of the two lines are independent of each other;
    * table: columns line up vertically like a small table (TrafficMonitor's
      "aligned" look), the whole grid is still centered in the applet.

    The component is completely passive: it does not read the configuration
    itself, everything is passed in as properties so that it can be reused both
    by the compact (panel) and the full (popup) representation.
*/
Item {
    id: view

    property var sensorIds: []
    property var sensorLabels: []
    property var sensorColors: []
    property var sensorShowLabels: []
    //! the placeholder areas and what they currently show, interleaved below
    property var placeholders: []
    property var placeholderContents: ({})
    /*!
        How tall the sensors' own text block is - the room a placeholder area gets.
        Measuring against the panel height instead used to push the widget past the
        panel edge once an area asked for the full height.
    */
    readonly property real textBlockHeight: view.rows * viewMetrics.height
            + (view.rows - 1) * view.lineSpacing

    property int lineCount: 1
    property bool tableMode: false
    //! 0 = left, 1 = centered, 2 = right (only used by the table layout)
    property int labelAlignment: 0
    property int valueAlignment: 0
    property bool uniformTextColor: false
    property bool autoAdaptColors: false
    property color backgroundColor: Kirigami.Theme.backgroundColor
    property int pixelSize: 12
    property string fontFamily: ""
    property bool bold: false
    property bool showNames: true
    property bool showColorBar: false
    property int itemSpacing: 8
    property int lineSpacing: 1
    property string separator: ""
    property color textColor: "white"
    property int updateInterval: 1000

    readonly property int rows: Math.max(1, Math.min(2, view.lineCount))
    readonly property int tableColumns: Math.max(1, Math.ceil(view.entryCount() / view.rows))
    readonly property int labelAlign: view.labelAlignment === 1 ? Qt.AlignHCenter
                                      : (view.labelAlignment === 2 ? Qt.AlignRight : Qt.AlignLeft)
    readonly property int valueAlign: view.valueAlignment === 1 ? Qt.AlignHCenter
                                      : (view.valueAlignment === 2 ? Qt.AlignRight : Qt.AlignLeft)
    //! gap between a name and its value, the space between sensors stays itemSpacing
    readonly property int tableGap: Math.max(2, Math.round(view.pixelSize * 0.25))

    FontMetrics {
        id: viewMetrics

        font.family: view.fontFamily.length > 0 ? view.fontFamily : Kirigami.Theme.defaultFont.family
        font.pixelSize: view.pixelSize
        font.bold: view.bold
    }

    implicitWidth: view.tableMode ? gridLayout.implicitWidth : packedLayout.implicitWidth
    implicitHeight: view.tableMode ? gridLayout.implicitHeight : packedLayout.implicitHeight

    /*!
        The display list: sensors and placeholder areas interleaved by the
        placeholders' slots. Slot 0 is in front of every sensor, slot n sits right
        after sensor n, and anything at or past the last sensor goes to the end.
    */
    function displayEntries() {
        const entries = [];
        const ids = view.sensorIds || [];
        const labels = view.sensorLabels || [];
        const colors = view.sensorColors || [];
        const showLabels = view.sensorShowLabels || [];
        for (let slot = 0; slot <= ids.length; ++slot) {
            for (let p = 0; p < view.placeholders.length; ++p) {
                const rule = view.placeholders[p];
                const wanted = (rule.slot === undefined || rule.slot === null || rule.slot < 0)
                        ? ids.length
                        : Math.min(rule.slot, ids.length);
                if (wanted === slot) {
                    entries.push({"kind": "placeholder", "rule": rule});
                }
            }
            if (slot < ids.length) {
                entries.push({
                    "kind": "sensor",
                    "sensorId": String(ids[slot]),
                    "label": labels[slot] !== undefined && labels[slot] !== null ? String(labels[slot]) : "",
                    "color": colors[slot] !== undefined && colors[slot] !== null ? String(colors[slot]) : "",
                    "showLabel": showLabels[slot] !== undefined && showLabels[slot] !== null ? showLabels[slot] != 0 : true,
                    "isLast": slot === ids.length - 1
                });
            }
        }
        return entries;
    }

    //! whether an area asked for the whole height (and therefore a column of its own)
    function placeholderIsFullHeight(entry) {
        return entry !== null && entry !== undefined && entry.kind === "placeholder"
                && entry.rule !== undefined && Number(entry.rule.height) === 1;
    }

    function entryCount() {
        return view.displayEntries().length;
    }

    function entriesInRange(from, to) {
        return view.displayEntries().slice(from, to);
    }

    function entryAt(index) {
        const entries = view.displayEntries();
        return index >= 0 && index < entries.length ? entries[index] : null;
    }

    /*!
        The cells of the table layout.

        Entries are packed into columns of \c rows items; a full-height area always
        gets a column of its own, with the sensors continuing on either side of it.
        A sensor contributes two grid columns (its name and its value) so that both
        can be aligned independently, an area only one.

        Every cell carries explicit Layout.row/Layout.column instead of relying on
        the grid's fill order: a cell that spans rows cannot be placed reliably by
        the flow, and getting it wrong moves every following sensor.
    */
    function tableCells() {
        const cells = [];
        if (!view.tableMode) {
            return cells;
        }
        const rows = view.rows;
        const entries = view.displayEntries();

        const columns = [];
        let current = [];
        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i];
            if (view.placeholderIsFullHeight(entry)) {
                if (current.length > 0) {
                    columns.push(current);
                    current = [];
                }
                columns.push([entry]);
                continue;
            }
            current.push(entry);
            if (current.length === rows) {
                columns.push(current);
                current = [];
            }
        }
        if (current.length > 0) {
            columns.push(current);
        }

        let gridColumn = 0;
        for (let c = 0; c < columns.length; ++c) {
            const column = columns[c];
            const lastColumn = c === columns.length - 1;
            const endsColumn = (part) => (part === "value" || part === "filler") && lastColumn;

            if (column.length === 1 && view.placeholderIsFullHeight(column[0])) {
                cells.push({
                    "entry": column[0],
                    "part": "content",
                    "row": 0,
                    "column": gridColumn,
                    "rowSpan": rows,
                    "firstColumn": gridColumn === 0,
                    "lastColumn": lastColumn
                });
                gridColumn += 1;
                continue;
            }

            for (let r = 0; r < column.length; ++r) {
                const entry = column[r];
                const part = entry.kind === "placeholder" ? "content" : "label";
                cells.push({
                    "entry": entry,
                    "part": part,
                    "row": r,
                    "column": gridColumn,
                    "rowSpan": 1,
                    "firstColumn": gridColumn === 0,
                    "lastColumn": endsColumn(part)
                });
            }
            for (let r = 0; r < column.length; ++r) {
                const entry = column[r];
                const part = entry.kind === "placeholder" ? "filler" : "value";
                cells.push({
                    "entry": entry,
                    "part": part,
                    "row": r,
                    "column": gridColumn + 1,
                    "rowSpan": 1,
                    "firstColumn": false,
                    "lastColumn": endsColumn(part)
                });
            }
            gridColumn += 2;
        }
        return cells;
    }

    function rowEntries(row) {
        const count = view.entryCount();
        if (view.rows < 2) {
            return row === 0 ? view.entriesInRange(0, count) : [];
        }
        const split = Math.ceil(count / 2);
        return row === 0 ? view.entriesInRange(0, split) : view.entriesInRange(split, count);
    }

    // --------------------------------------------------------- packed (default)
    ColumnLayout {
        id: packedLayout

        visible: !view.tableMode
        anchors.centerIn: parent
        spacing: view.lineSpacing

        RowLayout {
            id: firstRow

            Layout.alignment: Qt.AlignHCenter
            spacing: view.itemSpacing

            Repeater {
                model: view.tableMode ? [] : view.rowEntries(0)

                delegate: DisplayEntry {
                    required property var modelData

                    entry: modelData
                    showColorBar: view.showColorBar
                    showNames: view.showNames
                    separator: view.separator
                    uniformTextColor: view.uniformTextColor
                    autoAdaptColors: view.autoAdaptColors
                    backgroundColor: view.backgroundColor
                    pixelSize: view.pixelSize
                    fontFamily: view.fontFamily
                    bold: view.bold
                    textColor: view.textColor
                    updateInterval: view.updateInterval
                    placeholderContents: view.placeholderContents
                    placeholderHeight: view.textBlockHeight
                }
            }
        }

        RowLayout {
            id: secondRow

            visible: view.rows > 1
            Layout.alignment: Qt.AlignHCenter
            spacing: view.itemSpacing

            Repeater {
                model: view.tableMode ? [] : view.rowEntries(1)

                delegate: DisplayEntry {
                    required property var modelData

                    entry: modelData
                    showColorBar: view.showColorBar
                    showNames: view.showNames
                    separator: view.separator
                    uniformTextColor: view.uniformTextColor
                    autoAdaptColors: view.autoAdaptColors
                    backgroundColor: view.backgroundColor
                    pixelSize: view.pixelSize
                    fontFamily: view.fontFamily
                    bold: view.bold
                    textColor: view.textColor
                    updateInterval: view.updateInterval
                    placeholderContents: view.placeholderContents
                    placeholderHeight: view.textBlockHeight
                }
            }
        }
    }

    // ------------------------------------------------------------- table layout
    // Filled column by column, so with two lines the sensors are ordered
    //   1 3 5
    //   2 4 6
    // which keeps related sensors (up/down, temperature/usage, ...) stacked.
    // Every sensor contributes two cells (name and value) so that both can be
    // aligned independently inside their own grid column.
    GridLayout {
        id: gridLayout

        visible: view.tableMode
        anchors.centerIn: parent
        flow: GridLayout.TopToBottom
        rows: view.rows
        rowSpacing: view.lineSpacing
        columnSpacing: view.tableGap

        Repeater {
            model: view.tableMode ? view.tableCells() : []

            delegate: DisplayEntry {
                required property var modelData

                Layout.alignment: (modelData.part === "value" ? view.valueAlign : view.labelAlign) | Qt.AlignVCenter
                Layout.rowSpan: modelData.rowSpan !== undefined ? modelData.rowSpan : 1
                Layout.row: modelData.row !== undefined ? modelData.row : -1
                Layout.column: modelData.column !== undefined ? modelData.column : -1
                // keep the space between two sensors visibly larger than the one
                // between a sensor and its own value
                Layout.leftMargin: (modelData.part !== "value" && !modelData.firstColumn)
                                   ? Math.max(0, view.itemSpacing - view.tableGap) : 0

                entry: modelData.entry
                part: modelData.part
                showColorBar: view.showColorBar
                showNames: view.showNames
                separator: view.separator
                uniformTextColor: view.uniformTextColor
                autoAdaptColors: view.autoAdaptColors
                backgroundColor: view.backgroundColor
                pixelSize: view.pixelSize
                fontFamily: view.fontFamily
                bold: view.bold
                textColor: view.textColor
                updateInterval: view.updateInterval
                placeholderContents: view.placeholderContents
                placeholderHeight: view.textBlockHeight
            }
        }
    }
}
