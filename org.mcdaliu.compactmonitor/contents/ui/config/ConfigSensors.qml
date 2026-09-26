/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as Dialogs
import QtQuick.Layouts

import "../AlertRules.js" as AlertRules
import "../SensorNames.js" as SensorNames
import "../ShellUtils.js" as ShellUtils

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: root

    property var cfg_sensorIds: []
    property var cfg_sensorLabels: []
    property var cfg_sensorColors: []
    property var cfg_sensorShowLabels: []

    /*!
        Single source of truth while the page is open: an array of
        {sensorId, label, color, showLabel} objects.
    */
    property var entries: []

    readonly property var defaultIds: [
        "network/all/upload",
        "network/all/download",
        "cpu/all/usage",
        "memory/physical/usedPercent"
    ]
    readonly property var defaultLabels: ["↑", "↓", "CPU", "RAM"]
    readonly property var defaultColors: ["#2ec27e", "#3584e4", "#e5a50a", "#c061cb"]

    /*!
        Appearance entries that are exported and imported together with the
        sensors, with the validation used when reading them back.
    */
    readonly property var appearanceSpec: [
        {"key": "lineCount", "type": "int", "min": 1, "max": 2},
        {"key": "tableLayout", "type": "bool"},
        {"key": "labelAlignment", "type": "int", "min": 0, "max": 2},
        {"key": "valueAlignment", "type": "int", "min": 0, "max": 2},
        {"key": "autoFontSize", "type": "bool"},
        {"key": "fontSize", "type": "int", "min": 6, "max": 48},
        {"key": "fontFamily", "type": "string"},
        {"key": "bold", "type": "bool"},
        {"key": "showNames", "type": "bool"},
        {"key": "itemSpacing", "type": "int", "min": 0, "max": 40},
        {"key": "separator", "type": "string", "maxLength": 3},
        {"key": "showColorBar", "type": "bool"},
        {"key": "customTextColor", "type": "bool"},
        {"key": "textColor", "type": "string", "color": true},
        {"key": "autoAdaptColors", "type": "bool"},
        {"key": "updateInterval", "type": "int", "min": 100, "max": 10000}
    ]

    // import / export state
    property bool busy: false
    property string pendingAction: ""
    property string shellOutput: ""
    property string homePath: ""
    property string exportedPath: ""
    property string importedPath: ""

    readonly property url defaultExportUrl: root.homePath.length > 0
        ? "file://" + root.homePath + "/compact-monitor-sensors.json"
        : ""

    Component.onCompleted: {
        root.loadFromConfig();
        // only used to give the file dialogs a sensible starting folder
        root.runShell("home", "printf %s \"$HOME\"");
    }

    /*!
        Runs a shell command (the "executable" data source runs it through a
        shell) and calls handleShellResult() when it finished.
    */
    function runShell(action, command) {
        if (root.busy) {
            return;
        }
        root.busy = true;
        root.pendingAction = action;
        root.shellOutput = "";
        shell.connectSource(command);
    }

    Plasma5Support.DataSource {
        id: shell

        engine: "executable"
        connectedSources: []

        onNewData: function (source, data) {
            if (data.stdout !== undefined) {
                root.shellOutput += data.stdout;
            }
            if (data["exit code"] !== undefined) {
                const code = data["exit code"];
                const error = data.stderr !== undefined ? String(data.stderr) : "";
                shell.disconnectSource(source);
                root.busy = false;
                const action = root.pendingAction;
                root.pendingAction = "";
                root.handleShellResult(action, code, root.shellOutput, error);
            }
        }
    }

    function handleShellResult(action, exitCode, output, error) {
        if (action === "home") {
            root.homePath = output.trim();
            return;
        }
        if (action === "export") {
            if (exitCode !== 0) {
                root.showMessage(Kirigami.MessageType.Error,
                                 i18n("导出失败：%1", error.trim().length > 0 ? error.trim() : i18n("未知错误")));
            } else {
                root.showMessage(Kirigami.MessageType.Positive,
                                 i18n("已导出 %1 个传感器到 %2", root.entries.length, root.exportedPath));
            }
            return;
        }
        if (action === "import") {
            if (exitCode !== 0) {
                root.showMessage(Kirigami.MessageType.Error,
                                 i18n("读取文件失败：%1", error.trim().length > 0 ? error.trim() : i18n("未知错误")));
                return;
            }
            root.applyImported(root.importedPath, output);
        }
    }

    // ------------------------------------------------------------ import/export

    function showMessage(type, text) {
        resultMessage.type = type;
        resultMessage.text = text;
        resultMessage.visible = true;
    }

    function toLocalPath(url) {
        let text = String(url);
        if (text.indexOf("file://") === 0) {
            text = text.substring(7);
        }
        try {
            return decodeURIComponent(text);
        } catch (e) {
            return text;
        }
    }

    /*! accepts "#rrggbb" as well as KDE's "r,g,b" */
    function normalizeColor(value) {
        const text = String(value).trim();
        if (/^#[0-9a-fA-F]{6}$/.test(text)) {
            return text;
        }
        const parts = /^(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})$/.exec(text);
        if (parts) {
            const numbers = [parseInt(parts[1]), parseInt(parts[2]), parseInt(parts[3])];
            if (numbers[0] <= 255 && numbers[1] <= 255 && numbers[2] <= 255) {
                return "#" + numbers.map(function (number) {
                    const hex = number.toString(16);
                    return hex.length < 2 ? "0" + hex : hex;
                }).join("");
            }
        }
        return "";
    }

    function problemText(problems) {
        if (problems.length === 0) {
            return "";
        }
        const shown = problems.slice(0, 8);
        let text = "\n• " + shown.join("\n• ");
        if (problems.length > shown.length) {
            text += "\n…";
        }
        return text;
    }

    function exportAppearance() {
        const result = {};
        for (let i = 0; i < root.appearanceSpec.length; ++i) {
            const key = root.appearanceSpec[i].key;
            const value = Plasmoid.configuration[key];
            if (value !== undefined) {
                result[key] = value;
            }
        }
        return result;
    }

    /*! Writes the appearance part of an imported file, clamped to sane values. */
    function applyAppearance(data, problems) {
        let applied = 0;
        for (let i = 0; i < root.appearanceSpec.length; ++i) {
            const spec = root.appearanceSpec[i];
            const raw = data[spec.key];
            if (raw === undefined || raw === null) {
                continue;
            }
            let value = null;
            if (spec.type === "bool") {
                value = !(raw === false || raw === 0 || raw === "0" || raw === "false");
            } else if (spec.type === "int") {
                const number = Number(raw);
                if (isNaN(number)) {
                    problems.push(i18n("外观设置 %1 不是数字，已忽略", spec.key));
                    continue;
                }
                value = Math.round(number);
                const clamped = Math.min(spec.max, Math.max(spec.min, value));
                if (clamped !== value) {
                    problems.push(i18n("外观设置 %1 超出范围，已调整为 %2", spec.key, clamped));
                    value = clamped;
                }
            } else if (spec.color === true) {
                value = root.normalizeColor(raw);
                if (value.length === 0) {
                    problems.push(i18n("外观设置 %1 颜色无效，已忽略", spec.key));
                    continue;
                }
            } else {
                value = String(raw);
                if (spec.maxLength !== undefined && value.length > spec.maxLength) {
                    value = value.substring(0, spec.maxLength);
                }
            }
            Plasmoid.configuration[spec.key] = value;
            applied++;
        }
        return applied;
    }

    function applyImportedAlerts(list, problems) {
        const known = picker.availableSensorIds();
        const knownCount = Object.keys(known).length;
        const result = [];
        for (let i = 0; i < list.length; ++i) {
            const raw = list[i];
            const position = i + 1;
            if (raw === null || typeof raw !== "object") {
                problems.push(i18n("告警第 %1 项不是对象", position));
                continue;
            }
            const id = (raw.sensorId === undefined || raw.sensorId === null) ? "" : String(raw.sensorId);
            if (id.length === 0) {
                problems.push(i18n("告警第 %1 项缺少 sensorId", position));
                continue;
            }
            if (knownCount > 0 && known[id] !== true) {
                problems.push(i18n("告警第 %1 项：本机没有传感器 %2", position, id));
                continue;
            }
            const threshold = Number(raw.threshold);
            if (isNaN(threshold)) {
                problems.push(i18n("告警第 %1 项：阈值无效", position));
                continue;
            }
            let cooldown = Number(raw.cooldown);
            if (isNaN(cooldown) || cooldown < 1) {
                cooldown = 300;
            }
            result.push({
                "sensorId": id,
                "condition": raw.condition === "below" ? "below" : "above",
                "threshold": threshold,
                "cooldown": Math.min(86400, Math.round(cooldown)),
                "enabled": !(raw.enabled === false || raw.enabled === 0 || raw.enabled === "0" || raw.enabled === "false")
            });
        }
        Plasmoid.configuration.alerts = AlertRules.encodeList(result);
        return result.length;
    }

    function exportToFile(path) {
        const payload = {
            "applet": "org.mcdaliu.compactmonitor",
            "version": 2,
            "exportedAt": new Date().toISOString(),
            "appearance": root.exportAppearance(),
            "sensors": root.entries.map(function (entry) {
                return {
                    "sensorId": entry.sensorId,
                    "label": entry.label,
                    "color": entry.color,
                    "showLabel": entry.showLabel
                };
            }),
            "alerts": AlertRules.decodeList(Plasmoid.configuration.alerts)
        };
        root.exportedPath = path;
        root.runShell("export", "printf %s " + ShellUtils.quote(JSON.stringify(payload, null, 2))
                      + " > " + ShellUtils.quote(path));
    }

    function importFromFile(path) {
        root.importedPath = path;
        root.runShell("import", "cat " + ShellUtils.quote(path));
    }

    function applyImported(path, text) {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            root.showMessage(Kirigami.MessageType.Error, i18n("无法解析 %1：%2", path, e.message));
            return;
        }

        let list = null;
        if (Array.isArray(data)) {
            list = data;
        } else if (data !== null && typeof data === "object" && Array.isArray(data.sensors)) {
            list = data.sensors;
        }
        if (list === null) {
            root.showMessage(Kirigami.MessageType.Error, i18n("文件 %1 里没有找到传感器列表。", path));
            return;
        }

        const known = picker.availableSensorIds();
        const knownCount = Object.keys(known).length;
        const problems = [];
        const entries = [];
        const seen = {};

        for (let i = 0; i < list.length; ++i) {
            const raw = list[i];
            const position = i + 1;
            if (raw === null || typeof raw !== "object") {
                problems.push(i18n("第 %1 项不是对象", position));
                continue;
            }
            const id = (raw.sensorId === undefined || raw.sensorId === null) ? "" : String(raw.sensorId);
            if (id.length === 0) {
                problems.push(i18n("第 %1 项缺少 sensorId", position));
                continue;
            }
            if (knownCount > 0 && known[id] !== true) {
                problems.push(i18n("第 %1 项：本机没有传感器 %2", position, id));
                continue;
            }
            if (seen[id] === true) {
                problems.push(i18n("第 %1 项：%2 重复", position, id));
                continue;
            }
            seen[id] = true;

            let color = "";
            if (raw.color !== undefined && raw.color !== null && String(raw.color).length > 0) {
                color = root.normalizeColor(raw.color);
                if (color.length === 0) {
                    problems.push(i18n("第 %1 项：颜色 %2 无法识别，已忽略", position, String(raw.color)));
                }
            }

            let showLabel = true;
            if (raw.showLabel !== undefined && raw.showLabel !== null) {
                const flag = raw.showLabel;
                showLabel = !(flag === false || flag === 0 || flag === "0" || flag === "false");
            }

            const label = (raw.label === undefined || raw.label === null) ? "" : String(raw.label);
            entries.push(root.makeEntry(id, label, color, showLabel));
        }

        if (entries.length === 0) {
            root.showMessage(Kirigami.MessageType.Error,
                             i18n("没有可导入的传感器。") + root.problemText(problems));
            return;
        }

        root.entries = entries;
        root.pushToConfig();

        // appearance settings and alert rules travel in the same file (version 2
        // and later); older files simply do not have them
        let appearanceCount = 0;
        if (data !== null && typeof data === "object" && data.appearance !== null
                && typeof data.appearance === "object") {
            appearanceCount = root.applyAppearance(data.appearance, problems);
        }
        let alertCount = 0;
        if (data !== null && typeof data === "object" && Array.isArray(data.alerts)) {
            alertCount = root.applyImportedAlerts(data.alerts, problems);
        }

        const summary = appearanceCount > 0
                ? i18n("已导入 %1 个传感器，外观设置也已更新。", entries.length)
                : i18n("已导入 %1 个传感器。", entries.length);
        const alerts = alertCount > 0 ? i18n("告警规则 %1 条。", alertCount) : "";

        if (problems.length === 0) {
            root.showMessage(Kirigami.MessageType.Positive, summary + (alerts.length > 0 ? " " + alerts : ""));
        } else {
            root.showMessage(Kirigami.MessageType.Warning,
                             i18n("已导入 %1 个传感器，%2 项被跳过或修正：", entries.length, problems.length)
                             + root.problemText(problems));
        }
    }

    // ------------------------------------------------------------------ helpers

    function makeEntry(sensorId, label, color, showLabel) {
        return {
            "sensorId": String(sensorId),
            "label": label === undefined || label === null ? "" : String(label),
            "color": color === undefined || color === null ? "" : String(color),
            "showLabel": showLabel === undefined || showLabel === null ? true : (showLabel != 0)
        };
    }

    function copyEntry(entry, overrides) {
        const result = root.makeEntry(entry.sensorId, entry.label, entry.color, entry.showLabel);
        for (const key in overrides) {
            result[key] = overrides[key];
        }
        return result;
    }

    function loadFromConfig() {
        const ids = root.cfg_sensorIds || [];
        const labels = root.cfg_sensorLabels || [];
        const colors = root.cfg_sensorColors || [];
        const showLabels = root.cfg_sensorShowLabels || [];
        const result = [];
        for (let i = 0; i < ids.length; ++i) {
            result.push(root.makeEntry(ids[i], labels[i], colors[i], showLabels[i]));
        }
        root.entries = result;
    }

    function pushToConfig() {
        const ids = [];
        const labels = [];
        const colors = [];
        const showLabels = [];
        for (let i = 0; i < root.entries.length; ++i) {
            const entry = root.entries[i];
            ids.push(entry.sensorId);
            labels.push(entry.label);
            colors.push(entry.color);
            showLabels.push(entry.showLabel ? "1" : "0");
        }
        root.cfg_sensorIds = ids;
        root.cfg_sensorLabels = labels;
        root.cfg_sensorColors = colors;
        root.cfg_sensorShowLabels = showLabels;
    }

    // Called by the applet configuration dialog right before it saves.
    function saveConfig() {
        root.pushToConfig();
    }

    function entryIds() {
        const ids = [];
        for (let i = 0; i < root.entries.length; ++i) {
            ids.push(root.entries[i].sensorId);
        }
        return ids;
    }

    function setEntryLabel(index, label) {
        if (index < 0 || index >= root.entries.length) {
            return;
        }
        root.entries[index].label = label;
        root.pushToConfig();
    }

    function setEntryShowLabel(index, showLabel) {
        if (index < 0 || index >= root.entries.length) {
            return;
        }
        root.entries[index].showLabel = showLabel;
        root.pushToConfig();
    }

    // Colors are changed from a dialog, so the delegates can safely be recreated.
    function setEntryColor(index, color) {
        const list = root.entries.slice();
        list[index] = root.copyEntry(list[index], {"color": color});
        root.entries = list;
        root.pushToConfig();
    }

    function moveEntry(index, delta) {
        const target = index + delta;
        if (index < 0 || index >= root.entries.length || target < 0 || target >= root.entries.length) {
            return;
        }
        const list = root.entries.slice();
        const moved = list[index];
        list[index] = list[target];
        list[target] = moved;
        root.entries = list;
        root.pushToConfig();
    }

    function removeEntry(index) {
        const list = root.entries.slice();
        list.splice(index, 1);
        root.entries = list;
        root.pushToConfig();
    }

    function addSensor(sensorId) {
        if (root.entryIds().indexOf(sensorId) >= 0) {
            return;
        }
        const list = root.entries.slice();
        list.push(root.makeEntry(sensorId, "", "", true));
        root.entries = list;
        root.pushToConfig();
    }

    function resetToDefaults() {
        const list = [];
        for (let i = 0; i < root.defaultIds.length; ++i) {
            list.push(root.makeEntry(root.defaultIds[i], root.defaultLabels[i], root.defaultColors[i], true));
        }
        root.entries = list;
        root.pushToConfig();
    }

    // --------------------------------------------------------------------- UI

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.InlineMessage {
            id: resultMessage

            Layout.fillWidth: true
            visible: false
            showCloseButton: true
            type: Kirigami.MessageType.Information
        }

        HintLabel {
            text: i18n("用右侧的箭头调整顺序。文字框中可以给传感器起一个短名字，留空则使用自动识别的短名称（如 CPU、RAM、DISK）。")
        }

        HintLabel {
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: root.entries.length === 0
            text: i18n("还没有添加任何传感器，点击下面的“添加传感器…”开始吧。")
        }

        Repeater {
            model: root.entries

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

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.ToolButton {
                        implicitWidth: Kirigami.Units.iconSizes.medium
                        implicitHeight: Kirigami.Units.iconSizes.medium
                        onClicked: {
                            colorDialog.targetIndex = row.index;
                            colorDialog.openWithColor(row.modelData.color);
                        }

                        QQC2.ToolTip.text: i18n("设置该传感器的颜色")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                        contentItem: Rectangle {
                            radius: 4
                            color: row.modelData.color.length > 0 ? row.modelData.color : "transparent"
                            border.width: 1
                            border.color: Kirigami.Theme.textColor
                            opacity: row.modelData.color.length > 0 ? 1 : 0.4
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        // the rows must be able to shrink below the full text width,
                        // otherwise a long sensor id makes the page wider than the window
                        Layout.minimumWidth: 0
                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: row.sensorName.length > 0 ? row.sensorName : row.modelData.sensorId
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

                    QQC2.TextField {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        text: row.modelData.label
                        placeholderText: {
                            const auto = SensorNames.shortName(row.modelData.sensorId);
                            if (auto.length > 0) {
                                return auto;
                            }
                            return row.sensorName.length > 0 ? row.sensorName : i18n("默认名称");
                        }
                        onTextEdited: root.setEntryLabel(row.index, text)

                        QQC2.ToolTip.text: i18n("留空则使用传感器自带名称")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.CheckBox {
                        text: i18n("名称")
                        checked: row.modelData.showLabel
                        onToggled: root.setEntryShowLabel(row.index, checked)

                        QQC2.ToolTip.text: i18n("是否显示名称，只显示数值时可以更紧凑")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.ToolButton {
                        icon.name: "arrow-up"
                        enabled: row.index > 0
                        onClicked: root.moveEntry(row.index, -1)
                        QQC2.ToolTip.text: i18n("上移")
                        QQC2.ToolTip.visible: hovered
                    }

                    QQC2.ToolButton {
                        icon.name: "arrow-down"
                        enabled: row.index < root.entries.length - 1
                        onClicked: root.moveEntry(row.index, 1)
                        QQC2.ToolTip.text: i18n("下移")
                        QQC2.ToolTip.visible: hovered
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-delete-remove"
                        onClicked: root.removeEntry(row.index)
                        QQC2.ToolTip.text: i18n("移除")
                        QQC2.ToolTip.visible: hovered
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
                text: i18n("添加传感器…")
                onClicked: picker.open()
            }

            QQC2.Button {
                icon.name: "edit-undo"
                text: i18n("恢复默认")
                onClicked: root.resetToDefaults()
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.Button {
                icon.name: "document-import"
                text: i18n("导入…")
                enabled: !root.busy
                onClicked: importDialog.open()

                QQC2.ToolTip.text: i18n("从 JSON 文件导入传感器配置（会替换当前列表）")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            QQC2.Button {
                icon.name: "document-export"
                text: i18n("导出…")
                enabled: !root.busy && root.entries.length > 0
                onClicked: exportDialog.open()

                QQC2.ToolTip.text: i18n("把当前传感器配置保存为 JSON 文件")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        HintLabel {
            text: i18n("提示：紧凑排列时前半部分在第一行、后半部分在第二行；整齐对齐时按列填充（1 3 5 / 2 4 6）。")
        }
    }

    SensorPickerDialog {
        id: picker
        addedIds: root.entryIds()
        onSensorChosen: (sensorId) => root.addSensor(sensorId)
    }

    Dialogs.FileDialog {
        id: exportDialog

        title: i18n("导出传感器配置")
        fileMode: Dialogs.FileDialog.SaveFile
        defaultSuffix: "json"
        acceptLabel: i18n("导出")
        currentFile: root.defaultExportUrl
        nameFilters: [i18n("JSON 文件 (*.json)"), i18n("所有文件 (*)")]
        onAccepted: root.exportToFile(root.toLocalPath(selectedFile))
    }

    Dialogs.FileDialog {
        id: importDialog

        title: i18n("导入传感器配置")
        fileMode: Dialogs.FileDialog.OpenFile
        acceptLabel: i18n("导入")
        currentFolder: root.homePath.length > 0 ? "file://" + root.homePath : ""
        nameFilters: [i18n("JSON 文件 (*.json)"), i18n("所有文件 (*)")]
        onAccepted: root.importFromFile(root.toLocalPath(selectedFile))
    }

    ColorSwatchDialog {
        id: colorDialog

        property int targetIndex: -1

        onAccepted: {
            if (colorDialog.targetIndex >= 0) {
                root.setEntryColor(colorDialog.targetIndex, colorDialog.color);
            }
        }
    }
}
