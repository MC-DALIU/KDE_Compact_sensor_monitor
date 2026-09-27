/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQml
import QtQuick.Layouts

import "AlertRules.js" as AlertRules
import "SensorNames.js" as SensorNames
import "ShellUtils.js" as ShellUtils

import "i18n"
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

/*!
    Compact Monitor - a TrafficMonitor-like hardware monitor for the Plasma panel.

    Everything the widget shows is a ksysguard sensor, the list of sensors, their
    order, labels and colors are configurable through the usual "Configure
    Compact Monitor..." entry of the widget's context menu.
*/
PlasmoidItem {
    id: root

    readonly property var sensorIds: Plasmoid.configuration.sensorIds
    readonly property var sensorLabels: Plasmoid.configuration.sensorLabels
    readonly property bool isEmpty: !root.sensorIds || root.sensorIds.length === 0

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.title: I18n.text("紧凑监视器")
    Plasmoid.configurationRequired: root.isEmpty

    readonly property string uiLanguage: Plasmoid.configuration.uiLanguage

    // the applet follows the configured language, or the system one when it is empty
    onUiLanguageChanged: I18n.setLanguage(root.uiLanguage)
    Component.onCompleted: I18n.setLanguage(root.uiLanguage)

    // The panel's applet container asks the applet item itself for its size
    // hints, so mirror what the compact representation needs.
    Layout.preferredWidth: (root.compactRepresentationItem && root.compactRepresentationItem.implicitWidth > 0)
                           ? root.compactRepresentationItem.implicitWidth
                           : Kirigami.Units.gridUnit * 3

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    compactRepresentation: CompactRepresentation {
    }

    fullRepresentation: FullRepresentation {
    }

    toolTipMainText: I18n.text("紧凑监视器")
    toolTipSubText: root.buildToolTip()

    /*!
        Plasma's default tool tip layout shows at most eight lines of subText
        (core/DefaultToolTip.qml, maximumLineCount: 8), which quietly hides every
        sensor after the eighth one. A tool tip item replaces that layout and has
        no such limit.

        The item lives inside an invisible host so that it cannot paint over the
        widget before the tool tip takes it over.
    */
    toolTipItem: toolTipHost.content

    Item {
        id: toolTipHost

        visible: false

        readonly property alias content: toolTipContent

        ToolTipContent {
            id: toolTipContent

            title: root.toolTipMainText
            body: root.toolTipSubText
        }
    }

    // Sensors that are only used to build the tool tip, the visible
    // representations create their own ones.
    Instantiator {
        id: tipSensors

        model: root.sensorIds

        delegate: Sensors.Sensor {
            required property string modelData

            sensorId: modelData
            updateRateLimit: Math.max(500, Plasmoid.configuration.updateInterval)
        }
    }

    function labelFor(index) {
        const labels = root.sensorLabels || [];
        if (labels[index] !== undefined && labels[index] !== null && String(labels[index]).length > 0) {
            return String(labels[index]);
        }
        const sensorId = (root.sensorIds || [])[index];
        const auto = SensorNames.shortName(sensorId);
        if (auto.length > 0) {
            return auto;
        }
        const sensor = tipSensors.objectAt(index);
        if (!sensor) {
            return "";
        }
        return sensor.shortName.length > 0 ? sensor.shortName : sensor.name;
    }

    // ------------------------------------------------------------ threshold alerts

    readonly property var alertRules: AlertRules.decodeList(Plasmoid.configuration.alerts)

    /*!
        Alert state, keyed by the rule itself rather than by its position.

        Reading Plasmoid.configuration can re-evaluate this binding even when the
        rules did not change (a config map is not a normal property), and keying
        by content keeps the "already notified" state across those re-evaluations
        instead of firing again.
    */
    property var alertState: ({})

    //! rules are evaluated as soon as a value arrives, even while the widget is not expanded
    onAlertRulesChanged: {
        const alive = {};
        for (let i = 0; i < root.alertRules.length; ++i) {
            alive[AlertRules.encode(root.alertRules[i])] = true;
        }
        const kept = {};
        for (const key in root.alertState) {
            if (alive[key] === true) {
                kept[key] = root.alertState[key];
            }
        }
        root.alertState = kept;
    }

    Instantiator {
        id: alertSensors

        model: root.alertRules

        delegate: Sensors.Sensor {
            required property var modelData
            required property int index

            sensorId: modelData.sensorId
            updateRateLimit: Math.max(500, Plasmoid.configuration.updateInterval)
            onValueChanged: root.evaluateAlert(index)
        }
    }

    Plasma5Support.DataSource {
        id: notifier

        engine: "executable"
        connectedSources: []

        onNewData: function (source, data) {
            if (data["exit code"] !== undefined) {
                notifier.disconnectSource(source);
            }
        }
    }

    /*!
        Name to use for a sensor in a notification: the label from the sensor
        list when it is configured there, otherwise the recognized short name.
    */
    function sensorLabel(sensorId, sensor) {
        const ids = root.sensorIds || [];
        const labels = root.sensorLabels || [];
        const position = ids.indexOf(sensorId);
        if (position >= 0 && labels[position] !== undefined && labels[position] !== null
                && String(labels[position]).length > 0) {
            return String(labels[position]);
        }
        const auto = SensorNames.shortName(sensorId);
        if (auto.length > 0) {
            return auto;
        }
        if (sensor && sensor.name.length > 0) {
            return sensor.name;
        }
        return sensorId;
    }

    /*!
        Notifies when a rule starts to match. A value that hovers around the
        threshold does not notify over and over: after firing, the rule is
        disarmed until the value comes back past the threshold by the rule's
        deadband (hysteresis), and on top of that a notification is never sent
        more often than once per cooldown.
    */
    function evaluateAlert(index) {
        const rules = root.alertRules;
        if (index < 0 || index >= rules.length) {
            return;
        }
        const rule = rules[index];
        if (!rule.enabled) {
            return;
        }
        const sensor = alertSensors.objectAt(index);
        if (!sensor || sensor.status !== Sensors.Sensor.Ready) {
            return;
        }
        const value = Number(sensor.value);
        if (isNaN(value)) {
            return;
        }

        const hysteresis = AlertRules.effectiveHysteresis(rule);
        const triggered = AlertRules.isTriggered(rule, value);
        const recovered = AlertRules.hasRecovered(rule, value, hysteresis);

        const key = AlertRules.encode(rule);
        const state = root.alertState[key] !== undefined
                ? root.alertState[key]
                : {"armed": true, "lastNotified": 0};
        const now = Date.now();

        if (triggered && state.armed) {
            // disarm first: the deadband has to be crossed before this rule may
            // fire again, however often the value wobbles over the threshold
            state.armed = false;
            if ((now - state.lastNotified) >= rule.cooldown * 1000) {
                state.lastNotified = now;
                root.notifyAlert(root.sensorLabel(rule.sensorId, sensor), rule, sensor);
            }
        } else if (!triggered && recovered) {
            state.armed = true;
        }
        root.alertState[key] = state;
    }

    /*!
        Sends a desktop notification through the freedesktop notification service
        (there is no QML API for it, so this uses gdbus through the executable
        data source, like other Plasma widgets do).
    */
    function notifyAlert(label, rule, sensor) {
        const title = rule.condition === "below"
                ? I18n.text("%1 低于阈值", label)
                : I18n.text("%1 超过阈值", label);
        const body = I18n.text("当前 %1（阈值 %2）", sensor.formattedValue, String(rule.threshold));
        const command = "gdbus call --session"
                + " --dest org.freedesktop.Notifications"
                + " --object-path /org/freedesktop/Notifications"
                + " --method org.freedesktop.Notifications.Notify"
                + " " + ShellUtils.quote(I18n.text("紧凑监视器"))
                + " 0 " + ShellUtils.quote("utilities-system-monitor")
                + " " + ShellUtils.quote(title)
                + " " + ShellUtils.quote(body)
                + " " + ShellUtils.quote("[]")
                + " " + ShellUtils.quote("{}")
                + " 5000";
        notifier.connectSource(command);
    }

    function buildToolTip() {
        const lines = [];
        for (let i = 0; i < tipSensors.count; ++i) {
            const sensor = tipSensors.objectAt(i);
            if (!sensor) {
                continue;
            }
            const ready = sensor.status === Sensors.Sensor.Ready && sensor.formattedValue.length > 0;
            const value = ready ? sensor.formattedValue : "--";
            const label = root.labelFor(i);
            lines.push(label.length > 0 ? label + " " + value : value);
        }
        return lines.join("\n");
    }
}
