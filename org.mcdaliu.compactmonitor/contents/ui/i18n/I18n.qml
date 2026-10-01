/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma Singleton

import QtQuick

/*!
    Translations.

    The Chinese text in the user interface *is* the source string and the lookup
    key, which has two nice consequences: Chinese needs no translation file, and
    a key that a translation is missing falls back to the source string, so an
    incomplete translation is still usable.

    Every other language is a single file in `contents/i18n/`, for example
    `en.qml`, holding one object with all of them:

        readonly property var strings: {
            "外观": "Appearance",
            "%1 秒": "%1 seconds"
        }

    Adding a language is: copy `en.qml`, translate the values, and add the
    language to `supportedLanguages` below.

    Why not Qt's own translations (.po/.mo)? A plasmoid cannot change the
    language of `i18n()` at runtime from QML, and this widget lets the user pick
    a language instead of only following the system one. JSON files were not an
    option either: reading a local file needs XMLHttpRequest, which Qt refuses
    unless QML_XHR_ALLOW_FILE_READ is set - and the first read happens while the
    applet loads, so it has to be synchronous.

    `strings` is an ordinary property, so any binding that calls text() is
    re-evaluated when the language is loaded or changed.
*/
QtObject {
    id: root

    //! the loaded translations; empty means "use the source strings" (Chinese)
    property var strings: ({})
    //! the language in use, e.g. "en"
    property string language: "zh_CN"

    /*! Languages we have a file for; zh_CN is the source language. */
    readonly property var supportedLanguages: [
        {"code": "zh_CN", "name": "简体中文"},
        {"code": "en", "name": "English"}
    ]

    /*! The language to use when the setting says "follow the system". */
    function systemLanguage() {
        const locale = String(Qt.locale().name || "");
        const shortCode = locale.split("_")[0];
        for (let i = 0; i < root.supportedLanguages.length; ++i) {
            if (root.supportedLanguages[i].code === locale) {
                return root.supportedLanguages[i].code;
            }
        }
        for (let i = 0; i < root.supportedLanguages.length; ++i) {
            if (root.supportedLanguages[i].code.split("_")[0] === shortCode) {
                return root.supportedLanguages[i].code;
            }
        }
        // an unknown language: English is a better guess than the Chinese source
        for (let i = 0; i < root.supportedLanguages.length; ++i) {
            if (root.supportedLanguages[i].code === "en") {
                return "en";
            }
        }
        return "zh_CN";
    }

    /*!
        Loads \a code, or the system language when it is empty. Unknown languages
        and unreadable files quietly fall back to the source strings.
    */
    function setLanguage(code) {
        const wanted = (code === undefined || code === null || String(code).length === 0)
                ? root.systemLanguage()
                : String(code);

        if (wanted === "zh_CN") {
            root.strings = ({});
            root.language = "zh_CN";
            return;
        }

        const component = Qt.createComponent(Qt.resolvedUrl("../../i18n/" + wanted + ".qml"));
        if (component.status !== Component.Error) {
            const translations = component.createObject(null);
            if (translations && translations.strings) {
                root.strings = translations.strings;
                root.language = wanted;
                return;
            }
        }

        console.warn("Compact Monitor: no usable translation for", wanted,
                     component.errorString ? component.errorString() : "");
        root.strings = ({});
        root.language = "zh_CN";
    }

    /*!
        Translates \a source, replacing %1, %2, ... with the extra arguments.

        The replacement is a literal string, so "$" in a value is not special.
    */
    function text(source) {
        let translated = root.strings[source];
        if (translated === undefined || translated === null || translated === "") {
            translated = source;
        }
        for (let i = 1; i < arguments.length; ++i) {
            translated = translated.replace("%" + i, String(arguments[i]));
        }
        return translated;
    }
}
