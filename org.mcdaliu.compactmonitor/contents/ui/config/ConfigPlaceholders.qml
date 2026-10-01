/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import ".." as Ui
import "../PlaceholderRules.js" as PlaceholderRules
import "../SensorNames.js" as SensorNames
import "../i18n"

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

/*!
    The placeholder areas: one or more reserved spaces that show what external
    programs push in. Each area has a name - which is also the file it reads - and
    a slot that says where it sits among the sensors, so the areas can be
    interleaved with them instead of only sitting at either end.
*/
KCM.SimpleKCM {
    id: root

    property string cfg_uiLanguage: ""
    property var cfg_placeholders: []
    property string cfg_placeholderDirectory: ""
    property int cfg_placeholderInterval: 1000

    //! the sensors the slots refer to, read only, for the position selector
    property var cfg_sensorIds: []
    property var cfg_sensorLabels: []

    /*!
        The areas while the page is open: an array of
        {id, slot, height, widthMode, width, reserve, file} objects, kept in step
        with cfg_placeholders by pushToConfig().
    */
    property var entries: []

    function loadFromConfig() {
        root.entries = PlaceholderRules.decodeList(root.cfg_placeholders || []);
    }

    function pushToConfig() {
        root.cfg_placeholders = PlaceholderRules.encodeList(root.entries);
    }

    function saveConfig() {
        root.pushToConfig();
    }

    function addEntry() {
        const list = root.entries.slice();
        list.push({
            "id": PlaceholderRules.defaultId(list),
            "slot": -1,
            "height": 0,
            "widthMode": 0,
            "width": 120,
            "reserve": false,
            "fontSize": 0,
            "file": ""
        });
        root.entries = list;
        root.pushToConfig();
    }

    // changed in place so the controls keep their state while editing
    function updateEntry(index, changes) {
        if (index < 0 || index >= root.entries.length) {
            return;
        }
        const entry = root.entries[index];
        for (const key in changes) {
            entry[key] = changes[key];
        }
        root.pushToConfig();
    }

    function removeEntry(index) {
        const list = root.entries.slice();
        list.splice(index, 1);
        root.entries = list;
        root.pushToConfig();
    }

    function moveEntry(index, delta) {
        const target = index + delta;
        const list = root.entries.slice();
        if (target < 0 || target >= list.length) {
            return;
        }
        list.splice(target, 0, list.splice(index, 1)[0]);
        root.entries = list;
        root.pushToConfig();
    }

    //! the file an area reads, shown to the user (with "~" left readable)
    function entryFile(entry) {
        return PlaceholderRules.resolveFile(entry, root.cfg_placeholderDirectory, "~");
    }

    /*!
        What the position selector offers: in front of everything, and after each
        sensor. "after the last sensor" and "at the end" are the same thing, which
        is what an empty slot means.
    */
    function positionModel() {
        const model = [{"slot": 0, "text": I18n.text("排在最前面")}];
        const ids = root.cfg_sensorIds || [];
        const labels = root.cfg_sensorLabels || [];
        for (let i = 0; i < ids.length; ++i) {
            let name = labels[i] !== undefined && labels[i] !== null ? String(labels[i]).trim() : "";
            if (name.length === 0) {
                name = SensorNames.shortName(ids[i]);
            }
            if (name.length === 0) {
                name = String(ids[i]);
            }
            model.push({"slot": i + 1, "text": I18n.text("在 %1 之后", name)});
        }
        return model;
    }

    function positionIndex(entry) {
        const model = root.positionModel();
        const wanted = model.length - 1;
        const slot = (entry.slot === undefined || entry.slot === null || entry.slot < 0) ? wanted : entry.slot;
        return Math.min(wanted, Math.max(0, slot));
    }

    onCfg_uiLanguageChanged: I18n.setLanguage(root.cfg_uiLanguage)

    Component.onCompleted: {
        I18n.setLanguage(root.cfg_uiLanguage);
        root.loadFromConfig();
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        HintLabel {
            text: I18n.text("给每个占位符起一个名字——它同时决定接口文件的名字，外部程序把内容写进那个文件即可。内容可以是纯文本，或者一个 JSON 对象（字段 text、color、tooltip、align）。")
        }

        Repeater {
            model: root.entries

            delegate: Rectangle {
                id: entryRow

                required property int index
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: entryColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.alternateBackgroundColor

                ColumnLayout {
                    id: entryColumn

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing * 0.5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.TextField {
                            Layout.fillWidth: true
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 5
                            text: entryRow.modelData.id
                            placeholderText: I18n.text("名称")
                            onTextEdited: root.updateEntry(entryRow.index, {"id": text})
                        }

                        QQC2.ComboBox {
                            id: positionBox

                            textRole: "text"
                            model: root.positionModel()
                            currentIndex: root.positionIndex(entryRow.modelData)

                            onModelChanged: currentIndex = root.positionIndex(entryRow.modelData)
                            onActivated: root.updateEntry(entryRow.index, {
                                "slot": model[currentIndex] !== undefined ? model[currentIndex].slot : -1
                            })

                            QQC2.ToolTip.text: I18n.text("插到传感器的哪个位置，可以和传感器混排")
                            QQC2.ToolTip.visible: positionBox.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.ComboBox {
                            id: heightBox

                            model: [I18n.text("半高"), I18n.text("全高")]
                            currentIndex: entryRow.modelData.height
                            onActivated: root.updateEntry(entryRow.index, {"height": currentIndex})

                            QQC2.ToolTip.text: I18n.text("占位的高度：可用高度的一半或全部")
                            QQC2.ToolTip.visible: heightBox.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.ToolButton {
                            id: upButton

                            icon.name: "go-up"
                            enabled: entryRow.index > 0
                            onClicked: root.moveEntry(entryRow.index, -1)

                            QQC2.ToolTip.text: I18n.text("上移")
                            QQC2.ToolTip.visible: upButton.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.ToolButton {
                            id: downButton

                            icon.name: "go-down"
                            enabled: entryRow.index < root.entries.length - 1
                            onClicked: root.moveEntry(entryRow.index, 1)

                            QQC2.ToolTip.text: I18n.text("下移")
                            QQC2.ToolTip.visible: downButton.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.ToolButton {
                            id: removeButton

                            icon.name: "edit-delete-remove"
                            onClicked: root.removeEntry(entryRow.index)

                            QQC2.ToolTip.text: I18n.text("移除")
                            QQC2.ToolTip.visible: removeButton.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            text: I18n.text("宽度：")
                            opacity: 0.8
                        }

                        QQC2.ComboBox {
                            model: [I18n.text("固定"), I18n.text("至少"), I18n.text("至多")]
                            currentIndex: entryRow.modelData.widthMode
                            onActivated: root.updateEntry(entryRow.index, {"widthMode": currentIndex})
                        }

                        QQC2.SpinBox {
                            from: 8
                            to: 2000
                            stepSize: 4
                            value: entryRow.modelData.width
                            textFromValue: (value) => I18n.text("%1 像素", value)
                            valueFromText: (text) => parseInt(text)
                            onValueModified: root.updateEntry(entryRow.index, {"width": value})
                        }

                        QQC2.Label {
                            text: I18n.text("字号：")
                            opacity: 0.8
                        }

                        QQC2.SpinBox {
                            id: fontBox

                            from: 0
                            to: 200
                            stepSize: 1
                            value: Number(entryRow.modelData.fontSize) || 0
                            textFromValue: (value) => value === 0 ? I18n.text("跟随") : I18n.text("%1 像素", value)
                            valueFromText: (text) => parseInt(text) || 0
                            onValueModified: root.updateEntry(entryRow.index, {"fontSize": value})

                            QQC2.ToolTip.text: I18n.text("这块区域的字号；「跟随」表示和传感器一样")
                            QQC2.ToolTip.visible: fontBox.hovered
                            QQC2.ToolTip.timeout: 4000
                            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }

                        QQC2.CheckBox {
                            text: I18n.text("没有内容时也保留")
                            checked: entryRow.modelData.reserve
                            onToggled: root.updateEntry(entryRow.index, {"reserve": checked})
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: root.entryFile(entryRow.modelData)
                            elide: Text.ElideMiddle
                            opacity: 0.6
                            font: Kirigami.Theme.smallFont
                        }
                    }
                }
            }
        }

        HintLabel {
            visible: root.entries.length === 0
            text: I18n.text("还没有占位符，点下面的「添加占位符」即可添加。")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                icon.name: "list-add"
                text: I18n.text("添加占位符")
                onClicked: root.addEntry()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: I18n.text("接口文件目录：")
                opacity: 0.8
            }

            QQC2.TextField {
                Layout.fillWidth: true
                placeholderText: "~/.cache/compact-monitor"
                text: root.cfg_placeholderDirectory
                onTextEdited: root.cfg_placeholderDirectory = text
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: I18n.text("读取间隔：")
                opacity: 0.8
            }

            QQC2.SpinBox {
                from: 200
                to: 60000
                stepSize: 100
                value: root.cfg_placeholderInterval
                textFromValue: (value) => I18n.text("%1 毫秒", value)
                valueFromText: (text) => parseInt(text)
                onValueModified: root.cfg_placeholderInterval = value
            }

            Item {
                Layout.fillWidth: true
            }
        }

        HintLabel {
            text: I18n.text("所有占位文件由同一条命令统一读取：每个间隔只启动一个进程，与占位符数量无关；没有配置占位符时完全不读取。把读取间隔调大可以进一步降低占用。")
        }
    }
}
