/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import ".." as Ui  // for the SensorView preview
import "../ColorUtils.js" as ColorUtils

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    /*!
        The sensor list, used only for the preview.

        It is declared here (and not read from the applet) because a config page
        has no Plasmoid object: the configuration dialog hands every cfg_ key to
        the page it shows, and writes back the ones the page declares.
    */
    property var cfg_sensorIds: []
    property var cfg_sensorLabels: []
    property var cfg_sensorColors: []
    property var cfg_sensorShowLabels: []

    readonly property var appliedSensorIds: root.cfg_sensorIds || []
    readonly property var appliedSensorLabels: root.cfg_sensorLabels || []
    readonly property var appliedSensorColors: root.cfg_sensorColors || []
    readonly property var appliedSensorShowLabels: root.cfg_sensorShowLabels || []

    //! whether the Plasma theme we are drawn on is a dark one
    readonly property bool themeIsDark: ColorUtils.isDark(Kirigami.Theme.backgroundColor)

    property alias cfg_autoFontSize: autoFontSizeBox.checked
    property alias cfg_bold: boldBox.checked
    property alias cfg_showNames: showNamesBox.checked
    property alias cfg_showColorBar: colorBarBox.checked
    property alias cfg_customTextColor: customTextColorBox.checked
    property alias cfg_autoAdaptColors: autoAdaptBox.checked
    property alias cfg_separator: separatorField.text

    property int cfg_lineCount: 2
    property bool cfg_tableLayout: false
    property int cfg_labelAlignment: 0
    property int cfg_valueAlignment: 0
    property int cfg_fontSize: 12
    property string cfg_fontFamily: ""
    property string cfg_textColor: "#ffffff"
    property int cfg_itemSpacing: 8
    property int cfg_updateInterval: 1000

    /*!
        The preview lives outside the Kirigami.FormLayout on purpose: a
        FormLayout section item does not stretch to the page width, so the
        preview would stay as narrow as the form's implicit width.
    */
    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            text: i18n("预览")
        }

        // ---------------------------------------------------------------- preview
        Item {
            id: previewBox

            // stretches to the full page width (it is a ColumnLayout child),
            // and is clipped so it can never paint over the rest of the page
            Layout.fillWidth: true

            //! font size the widget itself would use, before fitting the preview
            readonly property int basePixelSize: root.cfg_autoFontSize
                ? Math.max(10, Math.round(Kirigami.Units.gridUnit * 0.8))
                : root.cfg_fontSize

            /*!
                A configured sensor list can be wider than the configuration
                window. Instead of drawing outside this box - or scaling the item,
                which makes the glyphs fuzzy and uneven - the font is made smaller
                until the content fits.

                The width is measured on a hidden copy that always uses
                basePixelSize, so the measurement cannot depend on the result of
                the calculation (which would oscillate).
            */
            readonly property real rawScale: (width > Kirigami.Units.largeSpacing * 2 && measurePreview.implicitWidth > 0)
                ? (width - Kirigami.Units.largeSpacing * 2) / measurePreview.implicitWidth
                : 1
            // a little slack, text metrics do not scale perfectly linearly
            readonly property real previewScale: rawScale >= 1 ? 1 : rawScale * 0.97
            readonly property int pixelSize: Math.max(6, Math.floor(basePixelSize * previewScale))

            clip: true // belt and braces: never paint over the rest of the page
            // Kirigami.FormLayout sizes its children by their implicitHeight, a
            // Layout.preferredHeight on its own is ignored (and evaluated too
            // early to see the child), so set both.
            implicitHeight: Math.max(preview.implicitHeight + Kirigami.Units.largeSpacing * 2,
                                     Kirigami.Units.gridUnit * 2.5)
            Layout.preferredHeight: implicitHeight

            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.alternateBackgroundColor
            }

            // hidden, only used to measure how wide the content wants to be
            Item {
                width: 0
                height: 0
                visible: false

                Ui.SensorView {
                    id: measurePreview

                    lineCount: root.cfg_lineCount
                    tableMode: root.cfg_tableLayout
                    labelAlignment: root.cfg_labelAlignment
                    valueAlignment: root.cfg_valueAlignment
                    uniformTextColor: root.cfg_customTextColor
                    autoAdaptColors: root.cfg_autoAdaptColors
                    backgroundColor: Kirigami.Theme.alternateBackgroundColor
                    pixelSize: previewBox.basePixelSize
                    fontFamily: root.cfg_fontFamily
                    bold: root.cfg_bold
                    showNames: root.cfg_showNames
                    showColorBar: root.cfg_showColorBar
                    itemSpacing: root.cfg_itemSpacing
                    separator: root.cfg_separator
                    textColor: root.cfg_customTextColor ? root.cfg_textColor : Kirigami.Theme.textColor
                    updateInterval: Math.max(500, root.cfg_updateInterval)
                    sensorIds: root.appliedSensorIds
                    sensorLabels: root.appliedSensorLabels
                    sensorColors: root.appliedSensorColors
                    sensorShowLabels: root.appliedSensorShowLabels
                }
            }

            Ui.SensorView {
                id: preview

                anchors.centerIn: parent
                lineCount: root.cfg_lineCount
                tableMode: root.cfg_tableLayout
                labelAlignment: root.cfg_labelAlignment
                valueAlignment: root.cfg_valueAlignment
                uniformTextColor: root.cfg_customTextColor
                autoAdaptColors: root.cfg_autoAdaptColors
                backgroundColor: Kirigami.Theme.alternateBackgroundColor
                pixelSize: previewBox.pixelSize
                fontFamily: root.cfg_fontFamily
                bold: root.cfg_bold
                showNames: root.cfg_showNames
                showColorBar: root.cfg_showColorBar
                itemSpacing: root.cfg_itemSpacing
                separator: root.cfg_separator
                textColor: root.cfg_customTextColor ? root.cfg_textColor : Kirigami.Theme.textColor
                updateInterval: Math.max(500, root.cfg_updateInterval)
                sensorIds: root.appliedSensorIds
                sensorLabels: root.appliedSensorLabels
                sensorColors: root.appliedSensorColors
                sensorShowLabels: root.appliedSensorShowLabels
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

        // ---------------------------------------------------------------- layout
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("布局")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("显示行数：")

            QQC2.RadioButton {
                id: oneLineBox
                text: i18n("单行")
                checked: root.cfg_lineCount !== 2
                onToggled: if (checked) root.cfg_lineCount = 1
            }

            QQC2.RadioButton {
                id: twoLinesBox
                text: i18n("双行")
                checked: root.cfg_lineCount === 2
                onToggled: if (checked) root.cfg_lineCount = 2
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("排列方式：")

            QQC2.RadioButton {
                id: packedModeBox
                text: i18n("紧凑")
                checked: !root.cfg_tableLayout
                onToggled: if (checked) root.cfg_tableLayout = false

                QQC2.ToolTip.text: i18n("每一行各自居中，最省空间（默认）")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            QQC2.RadioButton {
                id: tableModeBox
                text: i18n("整齐对齐")
                checked: root.cfg_tableLayout
                onToggled: if (checked) root.cfg_tableLayout = true

                QQC2.ToolTip.text: i18n("按列对齐，像表格一样")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        QQC2.ComboBox {
            id: labelAlignBox

            Kirigami.FormData.label: i18n("键对齐：")
            visible: root.cfg_tableLayout
            model: [i18n("左对齐"), i18n("居中"), i18n("右对齐")]
            currentIndex: root.cfg_labelAlignment
            onActivated: root.cfg_labelAlignment = currentIndex

            QQC2.ToolTip.text: i18n("整齐对齐时，传感器名称在其列内的对齐方式")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        QQC2.ComboBox {
            id: valueAlignBox

            Kirigami.FormData.label: i18n("值对齐：")
            visible: root.cfg_tableLayout
            model: [i18n("左对齐"), i18n("居中"), i18n("右对齐")]
            currentIndex: root.cfg_valueAlignment
            onActivated: root.cfg_valueAlignment = currentIndex

            QQC2.ToolTip.text: i18n("整齐对齐时，数值在其列内的对齐方式")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        QQC2.SpinBox {
            id: itemSpacingBox
            Kirigami.FormData.label: i18n("传感器间距：")
            from: 0
            to: 40
            value: root.cfg_itemSpacing
            textFromValue: (value) => i18n("%1 像素", value)
            valueFromText: (text) => parseInt(text)
            onValueModified: root.cfg_itemSpacing = value
        }

        QQC2.TextField {
            id: separatorField
            Kirigami.FormData.label: i18n("分隔符：")
            placeholderText: i18n("留空则不显示")
            maximumLength: 3
        }

        // ---------------------------------------------------------------- font
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("字体")
        }

        QQC2.ComboBox {
            id: fontFamilyBox

            Kirigami.FormData.label: i18n("字体：")
            Layout.fillWidth: true
            model: [i18n("跟随系统")].concat(Qt.fontFamilies())

            Component.onCompleted: {
                const index = model.indexOf(root.cfg_fontFamily);
                currentIndex = index > 0 ? index : 0;
            }

            onActivated: root.cfg_fontFamily = currentIndex === 0 ? "" : currentText
        }

        RowLayout {
            Kirigami.FormData.label: i18n("字号：")

            QQC2.CheckBox {
                id: autoFontSizeBox
                text: i18n("自动适应面板高度")
            }

            QQC2.SpinBox {
                id: fontSizeBox
                enabled: !autoFontSizeBox.checked
                from: 6
                to: 48
                value: root.cfg_fontSize
                textFromValue: (value) => i18n("%1 像素", value)
                valueFromText: (text) => parseInt(text)
                onValueModified: root.cfg_fontSize = value
            }
        }

        QQC2.CheckBox {
            id: boldBox
            Kirigami.FormData.label: i18n("字形：")
            text: i18n("粗体")
        }

        QQC2.CheckBox {
            id: showNamesBox
            Kirigami.FormData.label: i18n("名称：")
            text: i18n("在数值前显示传感器名称")
        }

        // ---------------------------------------------------------------- color
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("颜色")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("文字颜色：")

            QQC2.CheckBox {
                id: customTextColorBox
                text: i18n("自定义")
            }

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                radius: 3
                color: root.cfg_textColor.length > 0 ? root.cfg_textColor : "transparent"
                border.width: 1
                border.color: Kirigami.Theme.textColor
                opacity: customTextColorBox.checked ? 1 : 0.4
            }

            QQC2.Button {
                id: textColorButton

                enabled: customTextColorBox.checked
                text: root.cfg_textColor.length > 0 ? root.cfg_textColor : i18n("主题颜色")
                onClicked: textColorDialog.openWithColor(root.cfg_textColor)

                QQC2.ToolTip.text: i18n("点击选择颜色")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("深浅色：")

            QQC2.CheckBox {
                id: autoAdaptBox
                text: i18n("根据主题自动调整颜色明暗")

                QQC2.ToolTip.text: i18n("浅色主题下把颜色调暗、深色主题下把颜色调亮，保持色相不变")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            QQC2.Label {
                text: root.themeIsDark ? i18n("（当前：深色主题）") : i18n("（当前：浅色主题）")
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }
        }

        QQC2.CheckBox {
            id: colorBarBox
            Kirigami.FormData.label: i18n("颜色条：")
            text: i18n("在设置了颜色的传感器前显示一条色条")
        }

        HintLabel {
            text: i18n("勾选“自定义”后所有文字都用该颜色，传感器自己的颜色只用于颜色条；不勾选时名称和数值使用各自传感器的颜色。自动调整对两者都生效。")
        }

        // ---------------------------------------------------------------- update
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("刷新")
        }

        QQC2.SpinBox {
            id: updateIntervalBox
            Kirigami.FormData.label: i18n("刷新间隔：")
            from: 100
            to: 10000
            stepSize: 100
            value: root.cfg_updateInterval
            textFromValue: (value) => i18n("%1 毫秒", value)
            valueFromText: (text) => parseInt(text)
            onValueModified: root.cfg_updateInterval = value
        }
        }
    }

    ColorSwatchDialog {
        id: textColorDialog
        onAccepted: root.cfg_textColor = color
    }
}
