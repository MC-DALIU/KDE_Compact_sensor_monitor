/*
    SPDX-FileCopyrightText: 2025 mcdaliu

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

    implicitWidth: view.tableMode ? gridLayout.implicitWidth : packedLayout.implicitWidth
    implicitHeight: view.tableMode ? gridLayout.implicitHeight : packedLayout.implicitHeight

    function entryCount() {
        return view.sensorIds ? view.sensorIds.length : 0;
    }

    function entriesInRange(from, to) {
        const result = [];
        const ids = view.sensorIds || [];
        const labels = view.sensorLabels || [];
        const colors = view.sensorColors || [];
        const showLabels = view.sensorShowLabels || [];
        for (let i = from; i < to && i < ids.length; ++i) {
            result.push({
                "sensorId": String(ids[i]),
                "label": labels[i] !== undefined && labels[i] !== null ? String(labels[i]) : "",
                "color": colors[i] !== undefined && colors[i] !== null ? String(colors[i]) : "",
                "showLabel": showLabels[i] !== undefined && showLabels[i] !== null ? showLabels[i] != 0 : true,
                "isLast": i === ids.length - 1
            });
        }
        return result;
    }

    function entryAt(index) {
        const ids = view.sensorIds || [];
        if (index < 0 || index >= ids.length) {
            return null;
        }
        return view.entriesInRange(index, index + 1)[0];
    }

    /*!
        The cells of the table layout: for every sensor column first all names,
        then all values. The grid is filled column by column, so this produces a
        name column and a value column per sensor column, which lets both be
        aligned independently.
    */
    function tableCells() {
        const cells = [];
        if (!view.tableMode) {
            return cells;
        }
        const rows = view.rows;
        for (let column = 0; column < view.tableColumns; ++column) {
            const lastColumn = column === view.tableColumns - 1;
            const start = column * rows;
            for (let r = 0; r < rows; ++r) {
                const entry = view.entryAt(start + r);
                if (entry) {
                    cells.push({"entry": entry, "part": "label", "firstColumn": column === 0, "lastColumn": false});
                }
            }
            for (let r = 0; r < rows; ++r) {
                const entry = view.entryAt(start + r);
                if (entry) {
                    cells.push({"entry": entry, "part": "value", "firstColumn": false, "lastColumn": lastColumn});
                }
            }
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

                delegate: SensorItem {
                    required property var modelData

                    sensorId: modelData.sensorId
                    customLabel: modelData.label
                    accentColor: modelData.color
                    showLabel: modelData.showLabel
                    isLast: modelData.isLast
                    showColorBar: view.showColorBar
                    showDefaultName: view.showNames
                    separator: view.separator
                    uniformTextColor: view.uniformTextColor
                    autoAdaptColors: view.autoAdaptColors
                    backgroundColor: view.backgroundColor
                    pixelSize: view.pixelSize
                    fontFamily: view.fontFamily
                    bold: view.bold
                    textColor: view.textColor
                    updateInterval: view.updateInterval
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

                delegate: SensorItem {
                    required property var modelData

                    sensorId: modelData.sensorId
                    customLabel: modelData.label
                    accentColor: modelData.color
                    showLabel: modelData.showLabel
                    isLast: modelData.isLast
                    showColorBar: view.showColorBar
                    showDefaultName: view.showNames
                    separator: view.separator
                    uniformTextColor: view.uniformTextColor
                    autoAdaptColors: view.autoAdaptColors
                    backgroundColor: view.backgroundColor
                    pixelSize: view.pixelSize
                    fontFamily: view.fontFamily
                    bold: view.bold
                    textColor: view.textColor
                    updateInterval: view.updateInterval
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

            delegate: SensorItem {
                required property var modelData

                Layout.alignment: (modelData.part === "label" ? view.labelAlign : view.valueAlign) | Qt.AlignVCenter
                // keep the space between two sensors visibly larger than the one
                // between a sensor and its own value
                Layout.leftMargin: (modelData.part === "label" && !modelData.firstColumn)
                                   ? Math.max(0, view.itemSpacing - view.tableGap) : 0

                sensorId: modelData.entry.sensorId
                customLabel: modelData.entry.label
                accentColor: modelData.entry.color
                showLabel: modelData.entry.showLabel
                part: modelData.part
                isLast: modelData.lastColumn
                showColorBar: view.showColorBar
                showDefaultName: view.showNames
                separator: view.separator
                uniformTextColor: view.uniformTextColor
                autoAdaptColors: view.autoAdaptColors
                backgroundColor: view.backgroundColor
                pixelSize: view.pixelSize
                fontFamily: view.fontFamily
                bold: view.bold
                textColor: view.textColor
                updateInterval: view.updateInterval
            }
        }
    }
}
