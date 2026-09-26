/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Threshold alerts.

    A rule is stored in a KConfig StringList as one string per rule:

        sensorId|condition|threshold|cooldownSeconds|enabled

    for example

        cpu/all/usage|above|90|300|1

    which means: notify when cpu/all/usage goes above 90, at most once every
    300 seconds.
*/

.pragma library

function encode(rule) {
    return [
        String(rule.sensorId),
        rule.condition === "below" ? "below" : "above",
        String(rule.threshold),
        String(rule.cooldown),
        rule.enabled ? "1" : "0"
    ].join("|");
}

/*! Returns a rule object, or null when the entry cannot be understood. */
function decode(text) {
    if (text === undefined || text === null) {
        return null;
    }
    const parts = String(text).split("|");
    if (parts.length < 3) {
        return null;
    }
    const sensorId = parts[0].trim();
    if (sensorId.length === 0) {
        return null;
    }
    const threshold = Number(parts[2]);
    if (isNaN(threshold)) {
        return null;
    }
    let cooldown = parts.length > 3 ? Number(parts[3]) : 300;
    if (isNaN(cooldown) || cooldown < 1) {
        cooldown = 300;
    }
    return {
        "sensorId": sensorId,
        "condition": parts[1] === "below" ? "below" : "above",
        "threshold": threshold,
        "cooldown": cooldown,
        "enabled": parts.length > 4 ? String(parts[4]) !== "0" : true
    };
}

/*! Decodes a whole StringList, silently dropping entries that make no sense. */
function decodeList(list) {
    const result = [];
    if (!list) {
        return result;
    }
    for (let i = 0; i < list.length; ++i) {
        const rule = decode(list[i]);
        if (rule !== null) {
            result.push(rule);
        }
    }
    return result;
}

function encodeList(rules) {
    const result = [];
    for (let i = 0; i < rules.length; ++i) {
        result.push(encode(rules[i]));
    }
    return result;
}

function isTriggered(rule, value) {
    const number = Number(value);
    if (rule === null || isNaN(number)) {
        return false;
    }
    return rule.condition === "below" ? number < rule.threshold : number > rule.threshold;
}

/*! A sensible starting threshold for a freshly added rule. */
function defaultThreshold(sensorId) {
    const text = String(sensorId).toLowerCase();
    if (text.indexOf("percent") >= 0 || text.indexOf("usage") >= 0
            || text.indexOf("signal") >= 0 || text.indexOf("capacity") >= 0
            || text.indexOf("health") >= 0 || text.indexOf("charge") >= 0) {
        return 90;
    }
    return 0;
}
