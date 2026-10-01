/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import "ColorUtils.js" as ColorUtils

import org.kde.kirigami as Kirigami

/*!
    The reserved area that shows what an external program pushed in.

    The widget reads a file (see main.qml) and hands the parsed message over as
    \c content: an object with the keys "text", "color", "tooltip" and "align",
    or null when there is nothing to show.

    Its size follows the placeholder settings: the height is half of what is
    available or all of it, and the width is either fixed, a floor or a ceiling -
    the width in the settings is the configured value, the text is measured
    without wrapping to decide whether it needs more or less room.
*/
Item {
    id: root

    property var content: null
    //! 0 = half of the available height, 1 = all of it
    property int heightMode: 0
    //! 0 = fixed width, 1 = at least this wide, 2 = at most this wide
    property int widthMode: 0
    property int widthValue: 120
    //! keep the space even when there is nothing to show
    property bool reserve: false
    //! how tall the placeholder may be (the panel height, or the sensors' height)
    property real availableHeight: 0
    //! draw a faint outline while it is empty (used by the configuration preview)
    property bool showOutline: false

    property int pixelSize: 12
    property string fontFamily
    property bool bold: false
    property color textColor
    //! adapt the pushed-in colour to the background, like the sensors' colours
    property bool autoAdaptColors: false
    property color backgroundColor: "transparent"

    readonly property string messageText: (root.content !== null && root.content !== undefined
                                           && root.content.text !== undefined && root.content.text !== null)
            ? String(root.content.text) : ""
    readonly property bool hasContent: root.messageText.length > 0
    readonly property bool show: root.hasContent || root.reserve

    readonly property int padding: Math.max(2, Math.round(root.pixelSize * 0.4))
    readonly property real lineHeight: metrics.height > 0 ? metrics.height : root.pixelSize * 1.25

    //! what the message asks for, or the widget's own text colour
    readonly property color requestedColor: {
        const value = String((root.content !== null && root.content !== undefined ? root.content.color : "") || "").trim();
        if (/^#[0-9a-fA-F]{3}$/.test(value) || /^#[0-9a-fA-F]{6}$/.test(value) || /^#[0-9a-fA-F]{8}$/.test(value)) {
            return value;
        }
        return root.textColor;
    }

    //! the same light/dark adjustment the sensor colours get
    readonly property color messageColor: root.autoAdaptColors
            ? ColorUtils.adaptToBackground(root.requestedColor, root.backgroundColor)
            : root.requestedColor

    readonly property int messageAlignment: {
        const value = String((root.content !== null && root.content !== undefined ? root.content.align : "") || "").toLowerCase();
        if (value === "center" || value === "centre") {
            return Text.AlignHCenter;
        }
        if (value === "right") {
            return Text.AlignRight;
        }
        return Text.AlignLeft;
    }

    readonly property real fittedWidth: {
        if (!root.show) {
            return 0;
        }
        const wanted = root.widthMode === 1
                ? Math.max(root.widthValue, measure.contentWidth)
                : root.widthMode === 2
                  ? Math.min(root.widthValue, measure.contentWidth)
                  : root.widthValue;
        return Math.max(1, Math.ceil(wanted)) + 2 * root.padding;
    }

    readonly property real fittedHeight: {
        if (!root.show || root.availableHeight <= 0) {
            return 0;
        }
        return Math.max(1, Math.ceil(root.heightMode === 1
                                      ? root.availableHeight
                                      : Math.max(root.lineHeight, root.availableHeight / 2)));
    }

    visible: root.show
    implicitWidth: root.fittedWidth
    implicitHeight: root.fittedHeight

    Layout.minimumWidth: root.fittedWidth
    Layout.preferredWidth: root.fittedWidth
    Layout.maximumWidth: root.fittedWidth
    Layout.preferredHeight: root.fittedHeight
    Layout.alignment: Qt.AlignVCenter

    FontMetrics {
        id: metrics

        font.family: root.fontFamily.length > 0 ? root.fontFamily : Kirigami.Theme.defaultFont.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
    }

    //! measures the message as written (one line per "\n", no wrapping)
    Text {
        id: measure

        visible: false
        text: root.messageText
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        font.family: metrics.font.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showOutline && !root.hasContent
        color: "transparent"
        radius: Kirigami.Units.smallSpacing
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.35)
    }

    Text {
        anchors.centerIn: parent
        width: Math.max(1, root.fittedWidth - 2 * root.padding)
        text: root.messageText
        textFormat: Text.PlainText
        color: root.messageColor
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: Math.max(1, Math.floor(root.fittedHeight / root.lineHeight))
        horizontalAlignment: root.messageAlignment
        verticalAlignment: Text.AlignVCenter
        font.family: metrics.font.family
        font.pixelSize: root.pixelSize
        font.bold: root.bold
    }
}
