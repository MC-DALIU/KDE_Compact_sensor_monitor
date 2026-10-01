/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import "PlaceholderRules.js" as PlaceholderRules
import "i18n"
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/*!
    The representation used when the widget is clicked (popup) or when it lives on
    the desktop: the same sensors and placeholder, but with a comfortable font
    size.
*/
Item {
    id: rep

    //! handed over by main.qml: { "<encoded rule>": message }
    property var placeholderContents: ({})

    readonly property var sensorIds: Plasmoid.configuration.sensorIds
    readonly property bool isEmpty: !rep.sensorIds || rep.sensorIds.length === 0
    readonly property bool onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    //! an empty custom colour means "follow the Plasma theme"
    readonly property color effectiveTextColor: (Plasmoid.configuration.customTextColor
            && String(Plasmoid.configuration.textColor).length > 0)
            ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor

    readonly property var placeholderRules: PlaceholderRules.decodeList(Plasmoid.configuration.placeholders)

    //! whether any placeholder has something to show (or keeps its space)
    readonly property bool placeholdersVisible: {
        for (let i = 0; i < rep.placeholderRules.length; ++i) {
            const rule = rep.placeholderRules[i];
            const message = rep.placeholderContents[PlaceholderRules.encode(rule)];
            if (message !== null && message !== undefined && String(message.text || "").length > 0) {
                return true;
            }
            if (rule.reserve) {
                return true;
            }
        }
        return false;
    }
    readonly property bool emptyHintVisible: rep.isEmpty && !rep.placeholdersVisible

    readonly property int pixelSize: Plasmoid.configuration.autoFontSize
            ? Math.max(12, Math.round(Kirigami.Units.gridUnit * 0.85))
            : Plasmoid.configuration.fontSize

    //! how much room the placeholder has: as much as the sensors need
    readonly property real placeholderHeight: Math.max(Kirigami.Units.gridUnit * 2, content.implicitHeight)

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
        visible: !rep.isEmpty || rep.placeholderRules.length > 0
        lineCount: Math.max(1, Math.min(2, Plasmoid.configuration.lineCount))
        tableMode: Plasmoid.configuration.tableLayout
        labelAlignment: Plasmoid.configuration.labelAlignment
        valueAlignment: Plasmoid.configuration.valueAlignment
        uniformTextColor: Plasmoid.configuration.customTextColor
        autoAdaptColors: Plasmoid.configuration.autoAdaptColors
        backgroundColor: Kirigami.Theme.backgroundColor
        pixelSize: rep.pixelSize
        fontFamily: Plasmoid.configuration.fontFamily
        bold: Plasmoid.configuration.bold
        showNames: Plasmoid.configuration.showNames
        showColorBar: Plasmoid.configuration.showColorBar
        itemSpacing: Math.max(Plasmoid.configuration.itemSpacing, 6)
        lineSpacing: 2
        separator: Plasmoid.configuration.separator
        textColor: rep.effectiveTextColor
        updateInterval: Plasmoid.configuration.updateInterval
        sensorIds: rep.sensorIds
        sensorLabels: Plasmoid.configuration.sensorLabels
        sensorColors: Plasmoid.configuration.sensorColors
        sensorShowLabels: Plasmoid.configuration.sensorShowLabels
        placeholders: rep.placeholderRules
        placeholderContents: rep.placeholderContents
    }

    Text {
        id: emptyHint

        anchors.centerIn: parent
        visible: rep.emptyHintVisible
        text: I18n.text("请添加传感器")
        textFormat: Text.PlainText
        color: Kirigami.Theme.textColor
        font.pixelSize: Math.max(10, Math.round(Kirigami.Units.gridUnit * 0.8))
    }
}
