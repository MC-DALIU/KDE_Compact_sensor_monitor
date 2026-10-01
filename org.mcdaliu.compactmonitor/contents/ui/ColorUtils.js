/*
    SPDX-FileCopyrightText: 2026 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Small helpers that keep the sensor colors readable on both dark and light
    backgrounds. Luminance and contrast follow the WCAG 2.x definitions.
*/

.pragma library

function linearize(channel) {
    return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
}

/*! Guards against values that are not really colors (e.g. a plain string). */
function isColor(colorValue) {
    return colorValue !== undefined && colorValue !== null
        && typeof colorValue.r === "number" && !isNaN(colorValue.r)
        && typeof colorValue.g === "number" && !isNaN(colorValue.g)
        && typeof colorValue.b === "number" && !isNaN(colorValue.b);
}

function relativeLuminance(colorValue) {
    return 0.2126 * linearize(colorValue.r) + 0.7152 * linearize(colorValue.g) + 0.0722 * linearize(colorValue.b);
}

function contrastRatio(first, second) {
    const a = relativeLuminance(first);
    const b = relativeLuminance(second);
    return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

/*! True when the given (background) color is a dark one. */
function isDark(colorValue) {
    return relativeLuminance(colorValue) <= 0.5;
}

/*!
    Returns "colorValue" with its brightness moved - keeping hue and saturation -
    until it contrasts enough with "background": darkened on a light
    background, brightened on a dark one. The colorValue closest to the original
    one that still reaches the wanted contrast is returned.
*/
function adaptToBackground(colorValue, background, minimumContrast) {
    const wanted = minimumContrast === undefined ? 4.0 : minimumContrast;

    if (!isColor(colorValue) || !isColor(background) || colorValue.a <= 0 || background.a <= 0) {
        return colorValue;
    }
    if (contrastRatio(colorValue, background) >= wanted) {
        return colorValue;
    }

    const darken = !isDark(background);
    const hue = colorValue.hsvHue < 0 ? 0 : colorValue.hsvHue;
    const saturation = colorValue.hsvSaturation;

    let low = 0.0;
    let high = 1.0;
    let best = darken ? Qt.rgba(0, 0, 0, colorValue.a) : Qt.rgba(1, 1, 1, colorValue.a);

    for (let i = 0; i < 16; ++i) {
        const middle = (low + high) / 2;
        const candidate = Qt.hsva(hue, saturation, middle, colorValue.a);
        if (contrastRatio(candidate, background) >= wanted) {
            best = candidate;
            if (darken) {
                low = middle;
            } else {
                high = middle;
            }
        } else if (darken) {
            high = middle;
        } else {
            low = middle;
        }
    }

    return best;
}
