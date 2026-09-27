import QtQuick

import "../ui/i18n"
import org.kde.plasma.configuration
import org.kde.plasma.plasmoid

ConfigModel {
    ConfigCategory {
        name: I18n.text("外观")
        icon: "preferences-desktop-font"
        source: "config/ConfigAppearance.qml"
    }
    ConfigCategory {
        name: I18n.text("传感器")
        icon: "ksysguardd"
        source: "config/ConfigSensors.qml"
    }
    ConfigCategory {
        name: I18n.text("告警")
        icon: "notifications"
        source: "config/ConfigAlerts.qml"
    }

    // the dialog has no access to the applet configuration, so the page names
    // follow the system language
    Component.onCompleted: I18n.setLanguage("")
}
