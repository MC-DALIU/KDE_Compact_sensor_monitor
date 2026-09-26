/*
    SPDX-FileCopyrightText: 2025 mcdaliu

    SPDX-License-Identifier: GPL-2.0-or-later

    Small helpers that keep the sensor colors readable on both dark and light
    backgrounds. Luminance and contrast follow the WCAG 2.x definitions.
*/

.pragma library

function linearize(channel) {
    return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
}

/*! Guards against values that are not really colors (e.g. a plain string). */
function isColor(color) {
    return color !== undefined && color !== null
        && typeof color.r === "number" && !isNaN(color.r)
        && typeof color.g === "number" && !isNaN(color.g)
        && typeof color.b === "number" && !isNaN(color.b);
}

function relativeLuminance(color) {
    return 0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b);
}

function contrastRatio(first, second) {
    const a = relativeLuminance(first);
    const b = relativeLuminance(second);
    return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

/*! True when the given (background) color is a dark one. */
function isDark(color) {
    return relativeLuminance(color) <= 0.5;
}

/*!
    Returns "color" with its brightness moved - keeping hue and saturation -
    until it contrasts enough with "background": darkened on a light
    background, brightened on a dark one. The color closest to the original
    one that still reaches the wanted contrast is returned.
*/
function adaptToBackground(color, background, minimumContrast) {
    const wanted = minimumContrast === undefined ? 4.0 : minimumContrast;

    if (!isColor(color) || !isColor(background) || color.a <= 0 || background.a <= 0) {
        return color;
    }
    if (contrastRatio(color, background) >= wanted) {
        return color;
    }

    const darken = !isDark(background);
    const hue = color.hsvHue < 0 ? 0 : color.hsvHue;
    const saturation = color.hsvSaturation;

    let low = 0.0;
    let high = 1.0;
    let best = darken ? Qt.rgba(0, 0, 0, color.a) : Qt.rgba(1, 1, 1, color.a);

    for (let i = 0; i < 16; ++i) {
        const middle = (low + high) / 2;
        const candidate = Qt.hsva(hue, saturation, middle, color.a);
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
