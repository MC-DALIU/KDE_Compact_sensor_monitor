/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import "../AlertRules.js" as AlertRules
import "../SensorNames.js" as SensorNames

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.formatter
import org.kde.ksysguard.sensors as Sensors

/*!
    Threshold alerts: notify when a sensor goes above or below a value.
*/
KCM.SimpleKCM {
    id: root

    property var cfg_alerts: []

    /*!
        Single source of truth while the page is open: an array of
        {sensorId, condition, threshold, cooldown, enabled} objects.
    */
    property var rules: []

    Component.onCompleted: root.loadFromConfig()

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
        const list = root.rules.slice();
        list.push({
            "sensorId": sensorId,
            "condition": "above",
            "threshold": AlertRules.defaultThreshold(sensorId),
            "cooldown": 300,
            "enabled": true
        });
        root.rules = list;
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
        const list = root.rules.slice();
        list.splice(index, 1);
        root.rules = list;
        root.pushToConfig();
    }

    // --------------------------------------------------------------------- UI

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        HintLabel {
            text: i18n("达到阈值时发送桌面通知。同一条规则只在开始超出/低于阈值时通知一次，之后每过冷却时间最多再提醒一次，避免刷屏。")
        }

        HintLabel {
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: root.rules.length === 0
            text: i18n("还没有告警规则，点下面的「添加告警…」选一个传感器。")
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

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
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
                        model: [i18n("高于"), i18n("低于")]
                        currentIndex: row.modelData.condition === "below" ? 1 : 0
                        onActivated: root.updateRule(row.index, {"condition": currentIndex === 1 ? "below" : "above"})
                    }

                    QQC2.SpinBox {
                        id: thresholdBox

                        from: -1000000
                        to: 1000000000
                        value: row.modelData.threshold
                        onValueModified: root.updateRule(row.index, {"threshold": value})

                        QQC2.ToolTip.text: i18n("与传感器原始数值比较；右面显示它换算后的样子")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.Label {
                        visible: row.thresholdText.length > 0
                        text: row.thresholdText
                        opacity: 0.6
                        font: Kirigami.Theme.smallFont
                    }

                    QQC2.SpinBox {
                        from: 10
                        to: 86400
                        stepSize: 10
                        value: row.modelData.cooldown
                        textFromValue: (value) => i18n("%1 秒", value)
                        valueFromText: (text) => parseInt(text)
                        onValueModified: root.updateRule(row.index, {"cooldown": value})

                        QQC2.ToolTip.text: i18n("冷却时间：这段时间内不重复通知")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.CheckBox {
                        text: i18n("启用")
                        checked: row.modelData.enabled
                        onToggled: root.updateRule(row.index, {"enabled": checked})
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-delete-remove"
                        onClicked: root.removeRule(row.index)

                        QQC2.ToolTip.text: i18n("删除这条告警")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
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
                text: i18n("添加告警…")
                onClicked: picker.open()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        HintLabel {
            text: i18n("提示：同一条规则可以给同一个传感器加多条（例如电量低于 20 和高于 90）。通知由 org.freedesktop.Notifications 发送，所以桌面通知的样式取决于你的通知设置。")
        }
    }

    SensorPickerDialog {
        id: picker
        addedIds: []
        onSensorChosen: (sensorId) => root.addRule(sensorId)
    }
}
