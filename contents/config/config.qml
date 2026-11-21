import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
         name: i18n("General")
         icon: "configure"
         source: "config/General.qml"
    }
    ConfigCategory {
         name: i18n("Movement")
         icon: "speedometer"
         source: "config/Movement.qml"
    }
    ConfigCategory {
         name: i18n("Sound")
         icon: "audio-volume-high"
         source: "config/Sound.qml"
    }
}
