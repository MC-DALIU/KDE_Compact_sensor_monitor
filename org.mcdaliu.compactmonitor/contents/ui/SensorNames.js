/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Short (3-4 character) names derived from a sensor id, used when the user did
    not give a sensor a label of their own.

    Sensor ids look like <group>/<device>/<metric>, for example
        cpu/all/usage                 -> CPU
        memory/physical/usedPercent   -> RAM
        power/1B38/chargePercentage   -> BAT
        disk/nvme0n1/read             -> DISK
        lmsensors/acpi_fan-isa-0000/fan1 -> FAN
        network/all/download          -> ↓
*/

.pragma library

//! name for the first component of the id
var GROUPS = {
    "cpu": "CPU",
    "gpu": "GPU",
    "disk": "DISK",
    "network": "NET",
    "memory": "RAM",
    "power": "BAT",
    "battery": "BAT",
    "os": "OS",
    "pressure": "PRES",
    "temperature": "TEMP",
    "fan": "FAN",
    "lmsensors": ""     // filled in from the metric below
};

//! metrics that are clearer than their group (traffic direction, battery, ...)
var METRICS = {
    "download": "↓",
    "downloadBits": "↓",
    "upload": "↑",
    "uploadBits": "↑",
    "chargePercentage": "BAT",
    "chargeRate": "PWR",
    "capacity": "BAT",
    "health": "BAT",
    "power": "PWR",
    "energy": "ENRG",
    "signal": "WIFI",
    "voltage": "VOLT"
};

//! for lmsensors the metric prefix is the interesting part (fan1, temp1, in0...)
var HARDWARE_PREFIXES = {
    "fan": "FAN",
    "temp": "TEMP",
    "in": "VOLT",
    "curr": "CURR",
    "power": "PWR",
    "energy": "ENRG",
    "humidity": "HUM",
    "intrusion": "INTR"
};

function abbreviate(value) {
    const text = String(value).replace(/[^A-Za-z0-9]+/g, "").toUpperCase();
    return text.length > 4 ? text.substring(0, 4) : text;
}

function shortName(sensorId) {
    if (sensorId === undefined || sensorId === null) {
        return "";
    }
    const parts = String(sensorId).split("/").filter(function (part) {
        return part.length > 0;
    });
    if (parts.length === 0) {
        return "";
    }

    const group = parts[0].toLowerCase();
    const device = parts.length > 1 ? parts[1].toLowerCase() : "";
    const metric = parts.length > 1 ? parts[parts.length - 1] : "";

    if (METRICS[metric] !== undefined) {
        return METRICS[metric];
    }

    if (group === "memory") {
        return device === "swap" ? "SWAP" : "RAM";
    }

    if (group === "lmsensors") {
        const prefix = metric.replace(/[0-9]+.*$/, "").toLowerCase();
        if (HARDWARE_PREFIXES[prefix] !== undefined) {
            return HARDWARE_PREFIXES[prefix];
        }
        return abbreviate(metric);
    }

    const known = GROUPS[group];
    if (known !== undefined && known.length > 0) {
        return known;
    }
    return abbreviate(group);
}
