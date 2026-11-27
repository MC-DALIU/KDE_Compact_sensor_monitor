/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.ksysguard.sensors as Sensors

/*!
    One sensor, kept alive and probed.

    \c Sensors.Sensor asks the statistics daemon for a sensor once, when its id is
    set, and then never again. That is not enough for hardware that comes and goes
    (a USB network adapter, a battery, a Bluetooth mouse):

    * the daemon forgets the subscription when the sensor disappears
      (`Client::sensorRemoved` drops it), and nothing subscribes again when the
      sensor returns, so no value ever arrives again - that is why reopening the
      widget's settings used to "fix" it;
    * and nothing in QML reports the disappearance. `SensorDaemonInterface` does
      forward the daemon's `sensorRemoved` signal, but `ksystemstats` fills it with
      `SensorProperty::path()`, which is `parent->path() + "/" + id` - and by the
      time the object is gone that parent path is empty, so the signal carries only
      "/chargePercentage" instead of "power/…/chargePercentage". Every consumer that
      matches it against a sensor id (the models included, and Plasma's own system
      monitor) silently fails to notice.

    So this wrapper probes instead, and does not depend on that signal at all: every
    \c probeInterval it subscribes to the sensor again, which makes `Sensor` request
    the metadata, and the metadata either arrives (the sensor exists) or it does
    not (it is gone). While a probe is running the previous value stays on screen,
    so nothing flickers; a probe that times out marks the sensor as gone and the
    value becomes "--".
*/
QtObject {
    id: live

    property string sensorId: ""
    property int updateInterval: 1000
    //! how often to check that the sensor is still there
    property int probeInterval: 10000
    //! how long a probe may take before the sensor counts as gone
    property int probeTimeout: 2500

    /*!
        Emitted when a new value arrives, after the properties are updated. Not
        called "valueChanged": that is already the change signal of ::value.
    */
    signal valueReceived()

    //! what the Sensor object is subscribed to; differs from sensorId mid-probe
    property string subscribedId: ""
    //! whether the daemon still knows this sensor
    property bool alive: true
    //! true while a probe is waiting for the metadata
    property bool probing: false
    property double probeDeadline: 0

    readonly property var sensor: Sensors.Sensor {
        sensorId: live.subscribedId
        updateRateLimit: Math.max(100, live.updateInterval)
        onValueChanged: live.valueReceived()
    }

    /*!
        A second subscription that exists only while a probe runs.

        Re-subscribing has to unsubscribe first (the daemon would otherwise get a
        duplicate subscription every probe), but when the last client unsubscribes
        `SensorProperty` resets the value to the sensor's initial value - a driver
        that only reports on change then reads that value until the hardware changes
        again, which is how a returned device ended up showing 0 %. Holding this
        subscription for the duration of the probe keeps the count above zero, so
        the value survives.
    */
    readonly property var pin: Sensors.Sensor {
        sensorId: live.subscribedId
        enabled: false
        updateRateLimit: 60000
    }

    readonly property int status: sensor.status
    readonly property var value: sensor.value
    readonly property string formattedValue: sensor.formattedValue
    readonly property string name: sensor.name
    readonly property string shortName: sensor.shortName
    readonly property bool ready: sensor.status === Sensors.Sensor.Ready

    /*!
        What to draw: the last value while a probe is running, nothing at all once
        the sensor is known to be gone.
    */
    readonly property bool displayReady: live.alive && (live.ready || live.probing)
    readonly property string displayText: live.displayReady ? live.formattedValue : ""

    function beginProbe() {
        if (live.sensorId.length === 0) {
            return;
        }
        live.probing = true;
        live.probeDeadline = Date.now() + live.probeTimeout;
        // keep one subscription alive across the unsubscribe below
        live.pin.enabled = true;
        live.sensor.enabled = false;
        live.subscribedId = "";
        live.subscribedId = live.sensorId;
        live.sensor.enabled = true;
    }

    function endProbe(found) {
        if (found !== live.alive && live.sensorId.length > 0) {
            // one line per plug/unplug: the journal then says what happened
            console.log("Compact Monitor: " + live.sensorId
                        + (found ? " is back" : " is gone"));
        }
        live.alive = found;
        live.probing = false;
        live.pin.enabled = false;
    }

    // a different sensor starts with a clean slate
    onSensorIdChanged: {
        live.subscribedId = live.sensorId;
        live.alive = true;
        live.probing = false;
    }

    Component.onCompleted: live.subscribedId = live.sensorId

    property var probeTimer: Timer {
        // faster while the sensor is missing, so it comes back quickly
        interval: live.alive ? live.probeInterval : Math.max(3000, live.probeInterval / 3)
        repeat: true
        running: live.sensorId.length > 0 && !live.probing
        onTriggered: live.beginProbe()
    }

    property var probeWatch: Timer {
        interval: 250
        repeat: true
        running: live.probing
        onTriggered: {
            if (live.ready) {
                live.endProbe(true);
            } else if (Date.now() > live.probeDeadline) {
                live.endProbe(false);
            }
        }
    }
}
