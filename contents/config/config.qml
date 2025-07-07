import QtQuick 2.15
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "../ui/configGeneral.qml"
    }
    ConfigCategory {
        name: "Appearance"
        icon: "preferences-desktop-theme"
        source: "../ui/configAppearance.qml"
    }
}
