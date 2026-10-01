/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    The placeholder areas.

    One placeholder per entry of the configuration's StringList, encoded as

        id|slot|height|widthMode|width|reserve|fontSize|file

    for example

        music|-1|0|2|160|0|

    which is a placeholder called "music", half the available height, at most 160
    pixels wide, that disappears while it is empty and reads whatever the file
    named after its id contains. A font size of 0 means "follow the widget", which
    is what a half-height area normally wants; a full-height one usually looks
    better with a size of its own.

    The slot says where it sits among the sensors: 0 is in front of all of them,
    n means right after sensor n, and -1 (or anything past the last sensor) means
    at the very end. That is what lets a placeholder sit between two sensors
    instead of only on one side of the whole list. The file comes last because it
    is the only field that may contain a "|" itself.

    Reading the files happens in one shell command for all placeholders at once;
    the output is framed with the ASCII record separator so that a file's content
    can contain anything, including the paths and contents of the other ones.
*/

.pragma library

//! ASCII record separator, used to frame the output of the reader command
var SEPARATOR = "\u001e";

//! how a placeholder file is found when the entry does not name one
var DEFAULT_DIRECTORY = "~/.cache/compact-monitor";

function encode(rule) {
    return [
        String(rule.id),
        String(rule.slot),
        String(rule.height),
        String(rule.widthMode),
        String(rule.width),
        rule.reserve ? "1" : "0",
        String(Number(rule.fontSize) > 0 ? Math.round(Number(rule.fontSize)) : 0),
        String(rule.file)
    ].join("|");
}

function decode(text) {
    if (text === undefined || text === null || String(text).length === 0) {
        return null;
    }
    const parts = String(text).split("|");
    if (parts.length < 7) {
        return null;
    }
    // the file is last on purpose, so a path may contain "|". An entry written
    // before the font size existed has one field fewer and simply follows the
    // widget's font.
    const file = parts.length > 7 ? parts.slice(7).join("|") : parts[6];
    const fontSize = parts.length > 7 ? clampInt(parts[6], 0, 200, 0) : 0;
    return {
        "id": parts[0],
        "slot": clampInt(parts[1], -1, 1000, -1),
        "height": clampInt(parts[2], 0, 1, 0),
        "widthMode": clampInt(parts[3], 0, 2, 0),
        "width": clampInt(parts[4], 8, 2000, 120),
        "reserve": parts[5] !== "0",
        "fontSize": fontSize,
        "file": file
    };
}

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

function clampInt(value, minimum, maximum, fallback) {
    const number = Number(value);
    if (isNaN(number)) {
        return fallback;
    }
    return Math.min(maximum, Math.max(minimum, Math.round(number)));
}

/*! A name (and file name) for a placeholder that was just added. */
function defaultId(rules) {
    const taken = {};
    for (let i = 0; i < rules.length; ++i) {
        taken[rules[i].id] = true;
    }
    if (taken["content"] !== true) {
        return "content";
    }
    for (let n = 2; n < 1000; ++n) {
        if (taken["content" + n] !== true) {
            return "content" + n;
        }
    }
    return "content";
}

/*!
    The file a placeholder reads.

    An entry may name a file itself (absolute, or starting with "~/"); otherwise
    the file is the placeholder's id inside \a directory, with ".json" appended.
    A leading "~/" is expanded with \a home, which the caller has to look up.
*/
function resolveFile(rule, directory, home) {
    const configured = String(rule && rule.file ? rule.file : "").trim();
    const base = String(directory && directory.length > 0 ? directory : DEFAULT_DIRECTORY);
    let path = configured.length > 0 ? configured : base + "/" + fileNameFor(rule) + ".json";
    if (path.indexOf("~/") === 0) {
        path = (home && home.length > 0 ? home : "~") + path.substring(1);
    }
    return path;
}

function fileNameFor(rule) {
    let name = String(rule && rule.id ? rule.id : "").trim();
    if (name.length === 0) {
        name = "content";
    }
    // keep it a plain file name, whatever the user typed as the id
    return name.replace(/[\/\\\s]+/g, "-");
}

/*!
    The command that prints every file, framed so that the result can be split
    again: the separator, the path, the separator, the content, and so on. The
    quoting is done by the caller.
*/
function frameCommand(quotedFiles) {
    if (quotedFiles.length === 0) {
        return "";
    }
    // The files are read with the shell's own `read` instead of `cat`: a `cat`
    // would be a process of its own for every placeholder, while a builtin costs
    // almost nothing. Measured with five files: 1.7 ms per poll instead of 5.4 ms,
    // the empty shell alone being 1.4 ms - so the cost no longer grows with the
    // number of placeholder areas.
    return "for f in " + quotedFiles.join(" ") + "; do printf '\\036%s\\036' \"$f\"; "
            + "while IFS= read -r line || [ -n \"$line\" ]; do printf '%s\\n' \"$line\"; done "
            + "< \"$f\" 2>/dev/null; done";
}

/*!
    Splits what frameCommand printed into { "<path>": "<content>" }.
*/
function parseFramed(text) {
    const result = {};
    const parts = String(text === undefined || text === null ? "" : text).split(SEPARATOR);
    // parts[0] is what came before the first separator, usually empty
    for (let i = 1; i + 1 < parts.length; i += 2) {
        result[parts[i]] = parts[i + 1];
    }
    return result;
}
