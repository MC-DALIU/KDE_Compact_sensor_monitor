/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.ksysguard.sensors as Sensors

/*!
    A searchable tree of all sensors known to ksystemstats. Clicking a leaf
    sensor emits sensorChosen(); clicking a group descends into it.
*/
Kirigami.Dialog {
    id: picker

    title: i18n("添加传感器")
    preferredWidth: Kirigami.Units.gridUnit * 28
    preferredHeight: Kirigami.Units.gridUnit * 28
    padding: Kirigami.Units.smallSpacing
    standardButtons: Kirigami.Dialog.Close

    property var addedIds: []

    signal sensorChosen(string sensorId)

    onClosed: {
        while (delegateModel.rootIndex.valid) {
            delegateModel.rootIndex = delegateModel.parentModelIndex();
        }
        searchField.text = "";
    }

    /*!
        All sensor ids that exist on this machine, as a lookup object.
        Used to validate imported configurations.
    */
    function availableSensorIds() {
        const result = {};
        let count = 0;
        try {
            count = flatModel.rowCount();
        } catch (e) {
            return result;
        }
        for (let row = 0; row < count; ++row) {
            const id = flatModel.data(flatModel.index(row, 0), Sensors.SensorTreeModel.SensorId);
            if (id !== undefined && id !== null && String(id).length > 0) {
                result[String(id)] = true;
            }
        }
        return result;
    }


    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("点击条目即可添加，打勾的表示已经添加过了。")
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            wrapMode: Text.WordWrap
        }

        Kirigami.SearchField {
            id: searchField

            Layout.fillWidth: true
            placeholderText: i18n("搜索传感器…")
            onTextChanged: listView.searchString = text
        }

        RowLayout {
            Layout.fillWidth: true
            visible: delegateModel.rootIndex.valid

            QQC2.ToolButton {
                icon.name: "go-previous"
                text: i18n("返回")
                onClicked: delegateModel.rootIndex = delegateModel.parentModelIndex()
            }

            QQC2.Label {
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                text: delegateModel.rootIndex.valid && delegateModel.rootIndex.model
                      ? delegateModel.rootIndex.model.data(delegateModel.rootIndex)
                      : ""
            }

            Item {
                Layout.fillWidth: true
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Kirigami.Units.gridUnit * 18
            clip: true
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

            ListView {
                id: listView

                property string searchString: ""

                implicitHeight: contentHeight
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                model: DelegateModel {
                    id: delegateModel

                    model: listView.searchString.length > 0 ? searchModel : treeModel

                    delegate: QQC2.ItemDelegate {
                        id: listItem

                        readonly property string sensorId: (model.SensorId === undefined || model.SensorId === null) ? "" : String(model.SensorId)
                        readonly property bool leaf: listItem.sensorId.length > 0
                        readonly property bool alreadyAdded: listItem.leaf && (picker.addedIds || []).indexOf(listItem.sensorId) >= 0

                        width: listView.width
                        text: model.display
                        enabled: !listItem.alreadyAdded
                        icon.name: listItem.leaf ? (listItem.alreadyAdded ? "checkmark" : "list-add") : ""

                        indicator: Kirigami.Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: "go-next-symbolic"
                            opacity: listItem.leaf ? 0 : 1
                        }

                        onClicked: {
                            if (listItem.leaf) {
                                picker.sensorChosen(listItem.sensorId);
                            } else {
                                delegateModel.rootIndex = delegateModel.modelIndex(index);
                            }
                        }
                    }
                }

                Sensors.SensorTreeModel {
                    id: treeModel
                }

                KItemModels.KSortFilterProxyModel {
                    id: searchModel

                    filterCaseSensitivity: Qt.CaseInsensitive
                    filterString: listView.searchString

                    sourceModel: KItemModels.KSortFilterProxyModel {
                        id: leafOnlyModel

                        filterRowCallback: function(row, parent) {
                            const sensorId = sourceModel.data(sourceModel.index(row, 0), Sensors.SensorTreeModel.SensorId);
                            return sensorId !== undefined && sensorId !== null && sensorId.length > 0;
                        }

                        sourceModel: KItemModels.KDescendantsProxyModel {
                            model: listView.searchString.length > 0 ? treeModel : null
                        }
                    }
                }
            }
        }
    }

    KItemModels.KDescendantsProxyModel {
        id: flatModel
        model: treeModel
    }
}
