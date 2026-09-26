/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Small shell helpers.

    The import/export and the desktop notifications go through
    org.kde.plasma.plasma5support's "executable" data source, which runs the
    command through a shell - so everything that comes from the user or from a
    sensor has to be quoted properly.
*/

.pragma library

/*! Single quote a value for the shell, keeping embedded quotes intact. */
function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
}
