import QtQuick

import org.kde.plasma.configuration
import org.kde.plasma.plasmoid

ConfigModel {
    ConfigCategory {
        name: i18n("外观")
        icon: "preferences-desktop-font"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("传感器")
        icon: "ksysguardd"
        source: "config/ConfigSensors.qml"
    }
}
