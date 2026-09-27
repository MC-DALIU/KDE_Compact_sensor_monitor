/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import "i18n"
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/*!
    The representation used when the widget is clicked (popup) or when it lives
    on the desktop: the same sensors, but with a comfortable font size.
*/
Item {
    id: rep

    readonly property var sensorIds: Plasmoid.configuration.sensorIds
    readonly property bool isEmpty: !rep.sensorIds || rep.sensorIds.length === 0
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    implicitWidth: Math.max(Kirigami.Units.gridUnit * 8, content.implicitWidth) + 2 * Kirigami.Units.largeSpacing
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 2, content.implicitHeight) + 2 * Kirigami.Units.largeSpacing

    Rectangle {
        anchors.fill: parent
        visible: rep.onDesktop
        color: Kirigami.Theme.backgroundColor
        opacity: 0.8
        radius: Kirigami.Units.smallSpacing

        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
    }

    SensorView {
        id: content

        anchors.centerIn: parent
        lineCount: Math.max(1, Math.min(2, Plasmoid.configuration.lineCount))
        tableMode: Plasmoid.configuration.tableLayout
        labelAlignment: Plasmoid.configuration.labelAlignment
        valueAlignment: Plasmoid.configuration.valueAlignment
        uniformTextColor: Plasmoid.configuration.customTextColor
        autoAdaptColors: Plasmoid.configuration.autoAdaptColors
        backgroundColor: Kirigami.Theme.backgroundColor
        pixelSize: Plasmoid.configuration.autoFontSize ? Math.max(12, Math.round(Kirigami.Units.gridUnit * 0.85)) : Plasmoid.configuration.fontSize
        fontFamily: Plasmoid.configuration.fontFamily
        bold: Plasmoid.configuration.bold
        showNames: Plasmoid.configuration.showNames
        showColorBar: Plasmoid.configuration.showColorBar
        itemSpacing: Math.max(Plasmoid.configuration.itemSpacing, 6)
        lineSpacing: 2
        separator: Plasmoid.configuration.separator
        textColor: Plasmoid.configuration.customTextColor ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
        updateInterval: Plasmoid.configuration.updateInterval
        sensorIds: rep.sensorIds
        sensorLabels: Plasmoid.configuration.sensorLabels
        sensorColors: Plasmoid.configuration.sensorColors
        sensorShowLabels: Plasmoid.configuration.sensorShowLabels
    }

    Text {
        anchors.centerIn: parent
        visible: rep.isEmpty
        text: I18n.text("请添加传感器")
        textFormat: Text.PlainText
        color: Kirigami.Theme.textColor
        font.pixelSize: Math.max(10, Math.round(Kirigami.Units.gridUnit * 0.8))
    }
}
