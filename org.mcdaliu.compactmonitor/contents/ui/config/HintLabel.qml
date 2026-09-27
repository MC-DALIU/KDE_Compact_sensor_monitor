/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
    Small dimmed explanatory text for the configuration pages.

    The preferred/minimum widths are set explicitly: a wrapping label otherwise
    reports its full unwrapped width as its implicit width, which makes the
    whole Kirigami.FormLayout wider than the window (content then overflows on
    the right when the window is narrower than that).
*/
QQC2.Label {
    Layout.fillWidth: true
    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
    Layout.preferredWidth: Kirigami.Units.gridUnit * 16

    opacity: 0.7
    font: Kirigami.Theme.smallFont
    wrapMode: Text.WordWrap
}
