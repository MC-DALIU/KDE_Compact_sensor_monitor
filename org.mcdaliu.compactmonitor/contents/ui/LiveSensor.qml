/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.ksysguard.sensors as Sensors

/*!
    One sensor, kept alive.

    \c Sensors.Sensor asks the statistics daemon for a sensor once, when its id is
    set, and never again: it does not listen to the daemon's "sensor removed" or
    "sensor added" signals (only the model classes do). That breaks on hardware
    that comes and goes - a USB network adapter, a battery, a Bluetooth mouse:

    1. the sensor disappears, and `ksystemstats` forgets that this client was
       subscribed to it (`Client::sensorRemoved` drops the subscription),
    2. the sensor comes back, but nothing re-subscribes, so no value ever arrives
       again - the area keeps showing its last value or "--" until the widget is
       reloaded, which is why opening the settings "fixed" it.

    \c sensorPresent comes from a \c SensorDataModel in main.qml, which *does*
    follow additions and removals. A sensor that goes away is shown as "--" right
    away instead of keeping its last value, and one that comes back is subscribed
    again.

    Re-subscribing deliberately does *not* unsubscribe first: when the last client
    unsubscribes, `SensorProperty::unsubscribe` resets the value to the sensor's
    initial value, and a driver that only reports on change may then read 0 until
    the hardware changes again. Going through an empty id makes `Sensor` subscribe
    afresh without touching the old subscription, which the daemon has already
    dropped anyway (that is why we are here).
*/
QtObject {
    id: live

    property string sensorId: ""
    property int updateInterval: 1000
    //! whether the statistics daemon currently lists this sensor
    property bool sensorPresent: true

    /*!
        Emitted when a new value arrives, after the properties are updated. Not
        called "valueChanged": that is already the change signal of ::value.
    */
    signal valueReceived()

    //! true once the sensor has been seen present at least once
    property bool everPresent: false
    //! what the Sensor object is subscribed to; differs from sensorId mid-retry
    property string subscribedId: ""
    property double lastAttemptAt: 0
    //! how long to wait before the next attempt, doubled on every attempt
    property int retryDelay: 5000

    readonly property var sensor: Sensors.Sensor {
        sensorId: live.subscribedId
        updateRateLimit: Math.max(100, live.updateInterval)
        onValueChanged: live.valueReceived()
    }

    readonly property int status: sensor.status
    readonly property var value: sensor.value
    readonly property string formattedValue: sensor.formattedValue
    readonly property string name: sensor.name
    readonly property string shortName: sensor.shortName
    readonly property bool ready: sensor.status === Sensors.Sensor.Ready

    /*!
        Subscribes to the sensor again, without unsubscribing first (see above).
        Clearing the id makes `Sensor::setSensorId` run its subscription path once
        more; it returns early only when the id is unchanged.
    */
    function resubscribe() {
        const wanted = live.sensorId;
        if (wanted.length === 0) {
            return;
        }
        live.lastAttemptAt = Date.now();
        live.retryDelay = Math.min(60000, live.retryDelay * 2);
        live.subscribedId = "";
        live.subscribedId = wanted;
    }

    onSensorIdChanged: {
        live.subscribedId = live.sensorId;
        live.lastAttemptAt = Date.now();
        live.retryDelay = 5000;
    }

    /*!
        The sensor came back. This is the one case that needs new work: the daemon
        dropped the old subscription when the sensor went away.
    */
    onSensorPresentChanged: {
        if (live.sensorPresent) {
            live.retryDelay = 5000;
            if (live.everPresent) {
                live.resubscribe();
            } else {
                live.everPresent = true;
            }
        }
    }

    Component.onCompleted: {
        live.subscribedId = live.sensorId;
        live.lastAttemptAt = Date.now();
        live.everPresent = live.sensorPresent;
    }

    /*!
        A safety net for the odd state of "the daemon lists the sensor but never
        answers": try again, slowly. Sensors that simply do not report often - a
        battery reports on change - stay Ready and are left alone.
    */
    property var watchdog: Timer {
        interval: 10000
        repeat: true
        running: live.sensorId.length > 0
        onTriggered: {
            if (!live.sensorPresent || live.ready) {
                return;
            }
            if (Date.now() - live.lastAttemptAt < live.retryDelay) {
                return;
            }
            live.resubscribe();
        }
    }
}
