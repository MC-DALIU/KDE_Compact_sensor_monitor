/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import "ColorUtils.js" as ColorUtils
import "SensorNames.js" as SensorNames

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

/*!
    A single "name value" pair, showing one system monitor sensor.
*/
RowLayout {
    id: item

    // Sensor id, e.g. "cpu/all/usage"
    property string sensorId: ""
    /*!
        Which part to draw: "both" (default), or only "label" / "value".
        In the table layout the two parts live in separate grid columns so that
        they can be aligned independently.
    */
    property string part: "both"
    // User defined label, empty means "use the sensor's own short name"
    property string customLabel: ""
    // Hex color like "#2ec27e", empty means "use the text color"
    property string accentColor: ""
    // Whether the label should be shown at all
    property bool showLabel: true
    // Global "show sensor names" switch
    property bool showDefaultName: true
    // Whether the small colored bar should be painted
    property bool showColorBar: false
    // Whether this is the very last entry (no separator is drawn after it)
    property bool isLast: false
    property string separator: ""

    /*!
        When a custom text color is configured, it wins over the color of the
        individual sensors: those are then only used for the color bar.
    */
    property bool uniformTextColor: false

    /*!
        When enabled, colors that would be hard to read on the current
        background are darkened (light theme) or brightened (dark theme).
    */
    property bool autoAdaptColors: false
    property color backgroundColor: Kirigami.Theme.backgroundColor

    property int pixelSize: 12
    property string fontFamily: ""
    property bool bold: false
    property color textColor: Kirigami.Theme.textColor
    property int updateInterval: 1000

    readonly property bool hasAccent: item.accentColor.length > 0
    readonly property color accentColorValue: item.hasAccent ? item.accentColor : "transparent"
    readonly property color adaptedAccent: item.autoAdaptColors
        ? ColorUtils.adaptToBackground(item.accentColorValue, item.backgroundColor)
        : item.accentColorValue
    readonly property color adaptedTextColor: item.autoAdaptColors
        ? ColorUtils.adaptToBackground(item.textColor, item.backgroundColor)
        : item.textColor
    readonly property color labelColor: (!item.uniformTextColor && item.hasAccent) ? item.adaptedAccent : item.adaptedTextColor
    readonly property color valueColor: (!item.uniformTextColor && item.hasAccent) ? item.adaptedAccent : item.adaptedTextColor

    spacing: Math.max(2, Math.round(item.pixelSize * 0.25))

    Sensors.Sensor {
        id: sensor
        sensorId: item.sensorId
        updateRateLimit: Math.max(100, item.updateInterval)
    }

    //! short name recognised from the sensor id, e.g. "CPU", "RAM", "DISK"
    readonly property string autoName: SensorNames.shortName(item.sensorId)
    readonly property string defaultName: item.autoName.length > 0
        ? item.autoName
        : (sensor.shortName.length > 0 ? sensor.shortName : sensor.name)
    readonly property string labelText: {
        if (item.customLabel.length > 0) {
            return item.showLabel ? item.customLabel : "";
        }
        if (!item.showLabel || !item.showDefaultName) {
            return "";
        }
        return item.defaultName;
    }
    readonly property bool sensorReady: sensor.status === Sensors.Sensor.Ready
    readonly property string valueText: {
        if (item.sensorId.length === 0) {
            return "";
        }
        if (!item.sensorReady || sensor.formattedValue.length === 0) {
            return "--";
        }
        return sensor.formattedValue;
    }

    Rectangle {
        id: colorBar

        visible: (item.part !== "value") && item.showColorBar && item.hasAccent
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 1
        Layout.preferredWidth: Math.max(2, Math.round(item.pixelSize / 6))
        Layout.preferredHeight: Math.max(8, Math.round(item.pixelSize * 0.85))
        radius: width / 2
        color: item.adaptedAccent
    }

    Text {
        id: label

        visible: (item.part !== "value") && item.labelText.length > 0
        Layout.alignment: Qt.AlignVCenter
        text: item.labelText
        textFormat: Text.PlainText
        color: item.labelColor
        opacity: 0.8
        font.family: item.fontFamily.length > 0 ? item.fontFamily : Kirigami.Theme.defaultFont.family
        font.pixelSize: item.pixelSize
        font.bold: item.bold
    }

    Text {
        id: value

        visible: item.part !== "label"
        Layout.alignment: Qt.AlignVCenter
        text: item.valueText
        textFormat: Text.PlainText
        color: item.valueColor
        font.family: item.fontFamily.length > 0 ? item.fontFamily : Kirigami.Theme.defaultFont.family
        font.pixelSize: item.pixelSize
        font.bold: item.bold
    }

    Text {
        id: separatorText

        visible: (item.part !== "label") && !item.isLast && item.separator.length > 0
        Layout.alignment: Qt.AlignVCenter
        text: item.separator
        textFormat: Text.PlainText
        color: item.adaptedTextColor
        opacity: 0.35
        font.family: item.fontFamily.length > 0 ? item.fontFamily : Kirigami.Theme.defaultFont.family
        font.pixelSize: item.pixelSize
    }
}
