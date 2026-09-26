/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
    Small dialog used to pick a color out of a preset palette or as a hex value.
    An empty color means "use the color of the current Plasma theme".
*/
Kirigami.Dialog {
    id: dialog

    title: i18n("选择颜色")
    preferredWidth: Kirigami.Units.gridUnit * 15
    padding: Kirigami.Units.smallSpacing
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

    property string color: ""
    property var presets: [
        "#e01b24", "#ff7800", "#f6d32d", "#2ec27e", "#26a269", "#62a0ea",
        "#3584e4", "#9141ac", "#c061cb", "#e66100", "#986a44", "#f66151",
        "#99c1f1", "#8ff0a4", "#9a9996", "#ffffff"
    ]

    function openWithColor(value) {
        dialog.color = (value === undefined || value === null) ? "" : String(value);
        dialog.open();
    }

    onAccepted: {
        if (!/^#[0-9a-fA-F]{6}$/.test(dialog.color)) {
            dialog.color = "";
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        GridLayout {
            columns: 8
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: dialog.presets

                delegate: QQC2.ToolButton {
                    id: swatch

                    required property string modelData

                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    checkable: true
                    checked: dialog.color.toLowerCase() === modelData.toLowerCase()
                    onClicked: dialog.color = modelData

                    QQC2.ToolTip.text: modelData
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    contentItem: Rectangle {
                        radius: 3
                        color: swatch.modelData
                        border.width: swatch.checked ? 2 : 1
                        border.color: swatch.checked ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }
                }
            }
        }

        QQC2.TextField {
            id: hexField

            Layout.fillWidth: true
            text: dialog.color
            placeholderText: "#rrggbb"
            onTextEdited: dialog.color = text
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("留空表示跟随 Plasma 主题颜色")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }

        QQC2.Button {
            Layout.fillWidth: true
            text: i18n("使用主题颜色")
            onClicked: {
                dialog.color = "";
                dialog.accept();
            }
        }
    }
}
