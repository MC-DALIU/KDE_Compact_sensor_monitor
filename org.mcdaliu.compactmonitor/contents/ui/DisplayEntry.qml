/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import "PlaceholderRules.js" as PlaceholderRules

/*!
    One entry of the widget's display: either a sensor or a placeholder area.

    The layout in SensorView builds a single list of these, so a placeholder can
    sit anywhere among the sensors instead of only at either end. Keeping both
    kinds in one wrapper is what makes a single Repeater able to draw them.
*/
Item {
    id: entryRoot

    //! the entry from SensorView's display list
    property var entry: null
    //! "both", "label" or "value" - the table layout asks for one part at a time
    property string part: "both"

    // view settings the children need
    property bool showColorBar: false
    property bool showNames: true
    property string separator: ""
    property bool uniformTextColor: false
    property bool autoAdaptColors: false
    property color backgroundColor: "transparent"
    property int pixelSize: 12
    property string fontFamily: ""
    property bool bold: false
    property color textColor: "white"
    property int updateInterval: 1000

    // placeholder settings
    property var placeholderContents: ({})
    property real placeholderHeight: 0

    readonly property bool isPlaceholder: entryRoot.entry !== null && entryRoot.entry !== undefined
            && entryRoot.entry.kind === "placeholder"
    // in the table layout a placeholder also takes the value cell of its column
    // pair, as an empty cell that keeps the following sensors aligned
    readonly property bool showsPlaceholder: entryRoot.isPlaceholder && entryRoot.part !== "filler"

    implicitWidth: entryRoot.showsPlaceholder ? placeholderItem.implicitWidth : sensorItem.implicitWidth
    implicitHeight: entryRoot.showsPlaceholder ? placeholderItem.implicitHeight : sensorItem.implicitHeight

    SensorItem {
        id: sensorItem

        anchors.centerIn: parent
        visible: !entryRoot.isPlaceholder

        sensorId: entryRoot.entry !== null && entryRoot.entry !== undefined ? String(entryRoot.entry.sensorId || "") : ""
        customLabel: entryRoot.entry !== null && entryRoot.entry !== undefined ? String(entryRoot.entry.label || "") : ""
        accentColor: entryRoot.entry !== null && entryRoot.entry !== undefined ? String(entryRoot.entry.color || "") : ""
        showLabel: entryRoot.entry !== null && entryRoot.entry !== undefined ? entryRoot.entry.showLabel !== false : true
        part: entryRoot.part
        isLast: entryRoot.entry !== null && entryRoot.entry !== undefined && entryRoot.entry.isLast === true
        showColorBar: entryRoot.showColorBar
        showDefaultName: entryRoot.showNames
        separator: entryRoot.separator
        uniformTextColor: entryRoot.uniformTextColor
        autoAdaptColors: entryRoot.autoAdaptColors
        backgroundColor: entryRoot.backgroundColor
        pixelSize: entryRoot.pixelSize
        fontFamily: entryRoot.fontFamily
        bold: entryRoot.bold
        textColor: entryRoot.textColor
        updateInterval: entryRoot.updateInterval
    }

    PlaceholderView {
        id: placeholderItem

        anchors.centerIn: parent
        visible: entryRoot.showsPlaceholder

        content: entryRoot.isPlaceholder
                 ? entryRoot.placeholderContents[PlaceholderRules.encode(entryRoot.entry.rule)]
                 : null
        heightMode: entryRoot.isPlaceholder ? entryRoot.entry.rule.height : 0
        widthMode: entryRoot.isPlaceholder ? entryRoot.entry.rule.widthMode : 0
        widthValue: entryRoot.isPlaceholder ? entryRoot.entry.rule.width : 0
        reserve: entryRoot.isPlaceholder ? entryRoot.entry.rule.reserve : false
        availableHeight: entryRoot.placeholderHeight
        // a full-height area may use a size of its own, otherwise follow the widget
        pixelSize: (entryRoot.entry !== null && entryRoot.entry !== undefined
                    && entryRoot.entry.rule !== undefined
                    && Number(entryRoot.entry.rule.fontSize) > 0)
                   ? Number(entryRoot.entry.rule.fontSize) : entryRoot.pixelSize
        autoAdaptColors: entryRoot.autoAdaptColors
        backgroundColor: entryRoot.backgroundColor
        fontFamily: entryRoot.fontFamily
        bold: entryRoot.bold
        textColor: entryRoot.textColor
    }
}
