/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

/*!
    Content of the widget's tool tip.

    Plasma's own tool tip layout caps the text at eight lines
    (plasma-framework's core/DefaultToolTip.qml, maximumLineCount: 8), so a
    sensor list longer than that is silently cut off. The widget therefore sets
    Plasmoid.toolTipItem to this item, which lists every sensor.
*/
Item {
    id: root

    property string title
    property string body

    // the same theme the default tool tip uses
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    implicitWidth: mainLayout.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2

    ColumnLayout {
        id: mainLayout

        anchors.centerIn: parent
        spacing: 0

        Kirigami.Heading {
            level: 3
            Layout.fillWidth: true
            text: root.title
            visible: text.length > 0
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: root.body
            textFormat: Text.PlainText
            // no maximumLineCount on purpose: everything the user configured has
            // to show up, however many sensors there are
            wrapMode: Text.NoWrap
            opacity: 0.75
            visible: text.length > 0
        }
    }
}
