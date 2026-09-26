/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/*!
    The representation used inside the panel: as small as possible, just the
    plain text of the configured sensors.
*/
Item {
    id: rep

    readonly property var sensorIds: Plasmoid.configuration.sensorIds
    readonly property bool isEmpty: !rep.sensorIds || rep.sensorIds.length === 0
    readonly property int lines: Math.max(1, Math.min(2, Plasmoid.configuration.lineCount))

    readonly property int verticalPadding: 1
    readonly property int lineSpacingPixels: 1

    /*!
        When "auto font size" is enabled the text is scaled so that it fits the
        panel height, but never larger than a bit more than the system font.
    */
    readonly property int effectivePixelSize: {
        const configured = Plasmoid.configuration.fontSize;
        if (!Plasmoid.configuration.autoFontSize
                || Plasmoid.formFactor !== PlasmaCore.Types.Horizontal
                || rep.height <= 0) {
            return configured;
        }
        const usable = Math.floor(rep.height) - 2 * rep.verticalPadding - (rep.lines - 1) * rep.lineSpacingPixels;
        const fitted = Math.floor((usable / rep.lines) * 0.78);
        const maximum = Math.max(8, Math.round(Kirigami.Units.gridUnit * 0.8));
        return Math.max(7, Math.min(fitted, maximum));
    }

    implicitWidth: rep.isEmpty ? placeholder.implicitWidth : content.implicitWidth
    implicitHeight: rep.isEmpty ? placeholder.implicitHeight : content.implicitHeight

    // The panel layout only looks at the Layout attached properties of the
    // compact representation, so tell it to hug our content.
    Layout.minimumWidth: rep.implicitWidth
    Layout.preferredWidth: rep.implicitWidth
    Layout.maximumWidth: rep.implicitWidth

    SensorView {
        id: content

        anchors.centerIn: parent
        visible: !rep.isEmpty
        lineCount: rep.lines
        tableMode: Plasmoid.configuration.tableLayout
        labelAlignment: Plasmoid.configuration.labelAlignment
        valueAlignment: Plasmoid.configuration.valueAlignment
        uniformTextColor: Plasmoid.configuration.customTextColor
        autoAdaptColors: Plasmoid.configuration.autoAdaptColors
        backgroundColor: Kirigami.Theme.backgroundColor
        pixelSize: rep.effectivePixelSize
        fontFamily: Plasmoid.configuration.fontFamily
        bold: Plasmoid.configuration.bold
        showNames: Plasmoid.configuration.showNames
        showColorBar: Plasmoid.configuration.showColorBar
        itemSpacing: Plasmoid.configuration.itemSpacing
        lineSpacing: rep.lineSpacingPixels
        separator: Plasmoid.configuration.separator
        textColor: Plasmoid.configuration.customTextColor ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
        updateInterval: Plasmoid.configuration.updateInterval
        sensorIds: rep.sensorIds
        sensorLabels: Plasmoid.configuration.sensorLabels
        sensorColors: Plasmoid.configuration.sensorColors
        sensorShowLabels: Plasmoid.configuration.sensorShowLabels
    }

    Text {
        id: placeholder

        anchors.centerIn: parent
        visible: rep.isEmpty
        text: i18n("请添加传感器")
        textFormat: Text.PlainText
        color: Kirigami.Theme.textColor
        font.pixelSize: Math.max(8, Math.round(Kirigami.Units.gridUnit * 0.7))
    }
}
