/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import ".." as Ui
import "../PlaceholderRules.js" as PlaceholderRules
import "../i18n"

import org.kde.kirigami as Kirigami

/*!
    What the *Appearance* page shows as a preview: the sensors and the placeholder
    areas, laid out the way the widget would lay them out — the placeholders are
    interleaved with the sensors by SensorView itself.

    The page puts one of these into the preview box, and a second, hidden one at
    the untweaked font size to measure how wide the result is: measuring the
    visible one would feed the scale back into itself.
*/
Item {
    id: preview

    //! the configuration page, read for its cfg_* properties
    property var settings: null
    //! font size to draw the text with
    property int pixelSize: 12
    readonly property var placeholderRules: preview.settings ? preview.settings.placeholderEntries : []

    //! what the areas show while configuring: the same sample text for all of them
    readonly property var sampleContents: {
        const map = {};
        const sample = {"text": I18n.text("示例内容"), "color": "", "tooltip": "", "align": ""};
        for (let i = 0; i < preview.placeholderRules.length; ++i) {
            map[PlaceholderRules.encode(preview.placeholderRules[i])] = sample;
        }
        return map;
    }

    implicitWidth: sensors.implicitWidth
    implicitHeight: sensors.implicitHeight

    Ui.SensorView {
        id: sensors

        anchors.centerIn: parent
        lineCount: preview.settings.cfg_lineCount
        tableMode: preview.settings.cfg_tableLayout
        labelAlignment: preview.settings.cfg_labelAlignment
        valueAlignment: preview.settings.cfg_valueAlignment
        uniformTextColor: preview.settings.cfg_customTextColor
        autoAdaptColors: preview.settings.cfg_autoAdaptColors
        backgroundColor: Kirigami.Theme.alternateBackgroundColor
        pixelSize: preview.pixelSize
        fontFamily: preview.settings.cfg_fontFamily
        bold: preview.settings.cfg_bold
        showNames: preview.settings.cfg_showNames
        showColorBar: preview.settings.cfg_showColorBar
        itemSpacing: preview.settings.cfg_itemSpacing
        separator: preview.settings.cfg_separator
        textColor: preview.effectiveTextColor
        updateInterval: Math.max(500, preview.settings.cfg_updateInterval)
        sensorIds: preview.settings.appliedSensorIds
        sensorLabels: preview.settings.appliedSensorLabels
        sensorColors: preview.settings.appliedSensorColors
        sensorShowLabels: preview.settings.appliedSensorShowLabels
        placeholders: preview.placeholderRules
        placeholderContents: preview.sampleContents
    }

    //! the same colour rule the widget uses: an empty custom colour follows the theme
    readonly property color effectiveTextColor: (preview.settings && preview.settings.cfg_customTextColor
            && String(preview.settings.cfg_textColor).length > 0)
            ? preview.settings.cfg_textColor : Kirigami.Theme.textColor
}
