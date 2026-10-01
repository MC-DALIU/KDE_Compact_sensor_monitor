/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Threshold alerts.

    A rule is stored in a KConfig StringList as one string per rule:

        sensorId|condition|threshold|cooldownSeconds|enabled|hysteresis

    for example

        cpu/all/usage|above|90|300|1|5

    which means: notify when cpu/all/usage goes above 90, at most once every
    300 seconds, and only arm again once it drops to 85 or below.

    The hysteresis (deadband) is what keeps a value that hovers around the
    threshold - 81, 79, 81, 79 around 80 - from notifying over and over. It is
    optional: without it, or with a negative value, a fifth of the threshold
    (5%) is used, and 0 disables the deadband altogether.
*/

.pragma library

function encode(rule) {
    return [
        String(rule.sensorId),
        rule.condition === "below" ? "below" : "above",
        String(rule.threshold),
        String(rule.cooldown),
        rule.enabled ? "1" : "0",
        (rule.hysteresis === undefined || rule.hysteresis === null || rule.hysteresis < 0) ? "-1" : String(rule.hysteresis)
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
        "enabled": parts.length > 4 ? String(parts[4]) !== "0" : true,
        "hysteresis": decodeHysteresis(parts.length > 5 ? parts[5] : "")
    };
}

/*! Decodes a whole StringList, silently dropping entries that make no sense. */
function decodeList(entries) {
    const result = [];
    if (!entries) {
        return result;
    }
    for (let i = 0; i < entries.length; ++i) {
        const rule = decode(entries[i]);
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

/*! -1 (or anything negative, or nothing at all) means "work it out yourself". */
function decodeHysteresis(text) {
    if (text === undefined || text === null || String(text).length === 0) {
        return -1;
    }
    const number = Number(text);
    if (isNaN(number) || number < 0) {
        return -1;
    }
    return number;
}

/*!
    The deadband actually used: the configured one, or 5% of the threshold when
    the rule leaves it to us (a percentage alert is then 5 points wide, a
    temperature alert 4 degrees at 80, and so on).
*/
function effectiveHysteresis(rule) {
    if (rule === null) {
        return 0;
    }
    if (rule.hysteresis !== undefined && rule.hysteresis !== null && rule.hysteresis >= 0) {
        return rule.hysteresis;
    }
    const threshold = Math.abs(Number(rule.threshold));
    if (!(threshold > 0)) {
        return 0;
    }
    return Math.max(1, Math.round(threshold * 0.05));
}

/*!
    True when the value has come back far enough past the threshold for the rule
    to arm again - the other half of the hysteresis.
*/
function hasRecovered(rule, value, hysteresis) {
    const number = Number(value);
    if (rule === null || isNaN(number)) {
        return false;
    }
    const margin = (hysteresis === undefined || hysteresis === null)
        ? effectiveHysteresis(rule)
        : hysteresis;
    return rule.condition === "below" ? number >= rule.threshold + margin
                                      : number <= rule.threshold - margin;
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

/*! Value a newly added rule starts with: let the deadband be worked out. */
function defaultHysteresis() {
    return -1;
}
