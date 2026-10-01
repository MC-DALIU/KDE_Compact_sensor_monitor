/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import "../AlertRules.js" as AlertRules
import "../SensorNames.js" as SensorNames

import "../i18n"
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.formatter
import org.kde.ksysguard.sensors as Sensors

/*!
    Threshold alerts: notify when a sensor goes above or below a value.
*/
KCM.SimpleKCM {
    id: root

    property string cfg_uiLanguage: ""

    property var cfg_alerts: []

    /*!
        Single source of truth while the page is open: an array of
        {sensorId, condition, threshold, cooldown, enabled} objects.
    */
    property var rules: []

    onCfg_uiLanguageChanged: I18n.setLanguage(root.cfg_uiLanguage)

    Component.onCompleted: {
        I18n.setLanguage(root.cfg_uiLanguage);
        root.loadFromConfig();
    }

    // ------------------------------------------------------------------ helpers

    function loadFromConfig() {
        root.rules = AlertRules.decodeList(root.cfg_alerts || []);
    }

    function pushToConfig() {
        root.cfg_alerts = AlertRules.encodeList(root.rules);
    }

    // called by the applet configuration dialog right before it saves
    function saveConfig() {
        root.pushToConfig();
    }

    function addRule(sensorId) {
        const items = root.rules.slice();
        items.push({
            "sensorId": sensorId,
            "condition": "above",
            "threshold": AlertRules.defaultThreshold(sensorId),
            "cooldown": 300,
            "hysteresis": AlertRules.defaultHysteresis(),
            "enabled": true
        });
        root.rules = items;
        root.pushToConfig();
    }

    // changed in place so that the controls keep their state while editing
    function updateRule(index, changes) {
        if (index < 0 || index >= root.rules.length) {
            return;
        }
        const rule = root.rules[index];
        for (const key in changes) {
            rule[key] = changes[key];
        }
        root.pushToConfig();
    }

    function removeRule(index) {
        const items = root.rules.slice();
        items.splice(index, 1);
        root.rules = items;
        root.pushToConfig();
    }

    /*!
        Text explaining when a rule arms again, e.g. "降到 76.0 °C 以下才重新提醒".
    */
    function recoveryText(rule, unit, unitKnown) {
        const margin = AlertRules.effectiveHysteresis(rule);
        if (margin <= 0) {
            return I18n.text("回差为 0：数值贴着阈值抖动时会反复提醒");
        }
        const limit = rule.condition === "below" ? rule.threshold + margin : rule.threshold - margin;
        const text = unitKnown ? Formatter.formatValue(limit, unit) : String(limit);
        return rule.condition === "below"
            ? I18n.text("升到 %1 以上才重新提醒", text)
            : I18n.text("降到 %1 以下才重新提醒", text);
    }

    // --------------------------------------------------------------------- UI

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        HintLabel {
            text: I18n.text("达到阈值时发送桌面通知。提醒过一次后规则会先「解除武装」：数值要退回到阈值以外（退回的幅度由「回差」决定，默认按阈值的 5% 自动计算）才会再次提醒，所以数值在阈值附近来回跳动时不会反复通知。冷却时间则保证无论如何都不会比它更频繁地提醒。")
        }

        HintLabel {
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: root.rules.length === 0
            text: I18n.text("还没有告警规则，点下面的「添加告警…」选一个传感器。")
        }

        Repeater {
            model: root.rules

            delegate: Rectangle {
                id: row

                required property int index
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.alternateBackgroundColor

                Sensors.Sensor {
                    id: rowSensor
                    sensorId: row.modelData.sensorId
                    updateRateLimit: 2000
                }

                readonly property string sensorName: rowSensor.shortName.length > 0 ? rowSensor.shortName : rowSensor.name
                readonly property bool sensorReady: rowSensor.status === Sensors.Sensor.Ready
                readonly property string sensorValue: (row.sensorReady && rowSensor.formattedValue.length > 0) ? rowSensor.formattedValue : "--"
                readonly property string thresholdText: (row.sensorReady && rowSensor.formattedValue.length > 0)
                    ? Formatter.formatValue(row.modelData.threshold, rowSensor.unit)
                    : ""

                ColumnLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing * 0.5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 0

                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: {
                                    const auto = SensorNames.shortName(row.modelData.sensorId);
                                    if (auto.length > 0) {
                                        return auto;
                                    }
                                    return row.sensorName.length > 0 ? row.sensorName : row.modelData.sensorId;
                                }
                                elide: Text.ElideRight
                                font.bold: true
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: row.sensorValue + "  ·  " + row.modelData.sensorId
                                elide: Text.ElideMiddle
                                opacity: 0.6
                                font: Kirigami.Theme.smallFont
                            }
                        }

                        QQC2.ComboBox {
                            model: [I18n.text("高于"), I18n.text("低于")]
                            currentIndex: row.modelData.condition === "below" ? 1 : 0
                            onActivated: root.updateRule(row.index, {"condition": currentIndex === 1 ? "below" : "above"})

                            QQC2.ToolTip.text: I18n.text("高于阈值提醒，还是低于阈值提醒")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.Label {
                            text: I18n.text("阈值")
                            opacity: 0.8
                        }

                        QQC2.SpinBox {
                            id: thresholdBox

                            from: -1000000
                            to: 1000000000
                            value: row.modelData.threshold
                            onValueModified: root.updateRule(row.index, {"threshold": value})

                            QQC2.ToolTip.text: I18n.text("与传感器原始数值比较；右面显示它换算后的样子")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.Label {
                            visible: row.thresholdText.length > 0
                            text: row.thresholdText
                            opacity: 0.6
                            font: Kirigami.Theme.smallFont
                        }

                        QQC2.CheckBox {
                            text: I18n.text("启用")
                            checked: row.modelData.enabled
                            onToggled: root.updateRule(row.index, {"enabled": checked})
                        }

                        QQC2.ToolButton {
                            icon.name: "edit-delete-remove"
                            onClicked: root.removeRule(row.index)

                            QQC2.ToolTip.text: I18n.text("删除这条告警")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Item {
                            Layout.fillWidth: true
                        }

                        QQC2.Label {
                            text: I18n.text("冷却")
                            opacity: 0.8
                        }

                        QQC2.SpinBox {
                            from: 10
                            to: 86400
                            stepSize: 10
                            value: row.modelData.cooldown
                            textFromValue: (value) => I18n.text("%1 秒", value)
                            valueFromText: (text) => parseInt(text)
                            onValueModified: root.updateRule(row.index, {"cooldown": value})

                            QQC2.ToolTip.text: I18n.text("冷却时间：这段时间内绝不会重复通知")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.Label {
                            text: I18n.text("回差")
                            opacity: 0.8
                        }

                        QQC2.SpinBox {
                            from: 0
                            to: 1000000000
                            value: AlertRules.effectiveHysteresis(row.modelData)
                            onValueModified: root.updateRule(row.index, {"hysteresis": value})

                            QQC2.ToolTip.text: I18n.text("死区：数值要退回这么多才会再次提醒。默认按阈值的 5% 自动计算，0 表示关闭")
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.Label {
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
                            text: root.recoveryText(row.modelData, rowSensor.unit, row.sensorReady)
                            elide: Text.ElideRight
                            opacity: 0.6
                            font: Kirigami.Theme.smallFont
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                icon.name: "list-add"
                text: I18n.text("添加告警…")
                onClicked: picker.open()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        HintLabel {
            text: I18n.text("提示：同一条规则可以给同一个传感器加多条（例如电量低于 20 和高于 90）。通知由 org.freedesktop.Notifications 发送，所以桌面通知的样式取决于你的通知设置。")
        }
    }

    SensorPickerDialog {
        id: picker
        addedIds: []
        onSensorChosen: (sensorId) => root.addRule(sensorId)
    }
}
