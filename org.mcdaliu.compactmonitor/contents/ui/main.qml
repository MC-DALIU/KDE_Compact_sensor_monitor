/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQml
import QtQuick.Layouts

import "SensorNames.js" as SensorNames

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

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
    Plasmoid.title: i18n("紧凑监视器")
    Plasmoid.configurationRequired: root.isEmpty

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

    toolTipMainText: i18n("紧凑监视器")
    toolTipSubText: root.buildToolTip()

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
