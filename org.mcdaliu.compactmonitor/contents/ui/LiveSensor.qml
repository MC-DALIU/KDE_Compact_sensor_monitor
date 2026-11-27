/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.ksysguard.sensors as Sensors

/*!
    One sensor, kept alive.

    \c Sensors.Sensor asks the statistics daemon for a sensor once, when its id is
    set, and then never again: it does not listen to the daemon's "sensor removed"
    or "sensor added" signals (only the model classes do). That breaks on hardware
    that comes and goes - a USB network adapter, a battery, a Bluetooth device:

    1. the sensor disappears, and `ksystemstats` forgets that this client was
       subscribed to it (`Client::sensorRemoved` drops the subscription),
    2. the sensor comes back, but nothing re-subscribes, so no value ever arrives
       again - the area shows "--" (or keeps its last value) until the widget is
       reloaded, which is why opening the settings "fixed" it.

    This wrapper repeats the two things that re-creation would do - subscribe and
    request a value - whenever the sensor is not delivering: when it is not Ready,
    or when no value has arrived for a few intervals. The attempts back off from
    two seconds to half a minute, so a permanently missing sensor costs almost
    nothing, and the normal state costs nothing at all.
*/
QtObject {
    id: live

    property string sensorId: ""
    property int updateInterval: 1000

    /*!
        Emitted when a new value arrives, after the properties are updated. Not
        called "valueChanged": that is already the change signal of ::value.
    */
    signal valueReceived()

    //! when the last value arrived, in ms since the epoch
    property double lastValueAt: 0
    //! when the last re-subscribe attempt happened
    property double lastAttemptAt: 0
    //! how long to wait before the next attempt, doubled on every attempt
    property int retryDelay: 2000

    readonly property var sensor: Sensors.Sensor {
        sensorId: live.sensorId
        updateRateLimit: Math.max(100, live.updateInterval)
        onValueChanged: {
            live.lastValueAt = Date.now();
            live.valueReceived();
        }
    }

    readonly property int status: sensor.status
    readonly property var value: sensor.value
    readonly property string formattedValue: sensor.formattedValue
    readonly property string name: sensor.name
    readonly property string shortName: sensor.shortName
    readonly property bool ready: sensor.status === Sensors.Sensor.Ready

    /*!
        How long a sensor may stay silent before it counts as dead. The daemon
        sends a value every backend tick (one second), but `updateRateLimit` drops
        some of them, hence a few intervals of slack.
    */
    readonly property int silenceLimit: Math.max(5000, live.updateInterval * 3 + 2000)

    /*!
        Asks the daemon for the sensor again.

        Toggling `enabled` is the supported way to do that: disabling it drops the
        subscription (which also removes the daemon side connections, so repeated
        attempts cannot pile up), and enabling it subscribes again and requests the
        metadata and a value. Those are the same two steps a freshly created Sensor
        performs, which is why re-opening the settings used to "fix" a sensor whose
        hardware had come back.
    */
    function resubscribe() {
        if (live.sensorId.length === 0) {
            return;
        }
        live.lastAttemptAt = Date.now();
        live.retryDelay = Math.min(30000, live.retryDelay * 2);
        live.sensor.enabled = false;
        live.sensor.enabled = true;
    }

    function check() {
        if (live.sensorId.length === 0) {
            return;
        }
        const now = Date.now();
        const silent = live.lastValueAt > 0 && (now - live.lastValueAt) > live.silenceLimit;
        const healthy = live.ready && live.formattedValue.length > 0;
        if (healthy && !silent) {
            live.retryDelay = 2000;
            return;
        }
        if (now - live.lastAttemptAt < live.retryDelay) {
            return;
        }
        live.resubscribe();
    }

    // a different sensor starts with a clean slate
    onSensorIdChanged: {
        live.lastAttemptAt = Date.now();
        live.retryDelay = 2000;
    }

    Component.onCompleted: live.lastAttemptAt = Date.now()

    property var watchdog: Timer {
        interval: 1000
        repeat: true
        running: live.sensorId.length > 0
        onTriggered: live.check()
    }
}
