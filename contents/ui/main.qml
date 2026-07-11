/*
 * SPDX-FileCopyrightText: 2012 Reza Fatahilah Shah <rshah0385@kireihana.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import QtQuick.Controls

PlasmoidItem {
    id: widget

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    implicitWidth: 100
    implicitHeight: 100

    SoundEffect {
        id: themeSong
        source: plasmoid.configuration.playthemesong != "Never" ? plasmoid.configuration.themepath : ""
        loops: plasmoid.configuration.themesongloops
        muted: plasmoid.configuration.playthemesong == "Never"

        onMutedChanged: {
            if(muted) stop()
        }
    }

    AnimatedImage {
        id: animation
        source: plasmoid.configuration.gifpath

        fillMode: Image.PreserveAspectFit
        anchors.fill: parent

        speed: plasmoid.configuration.speed
        mirror: plasmoid.configuration.mirror
        mipmap: plasmoid.configuration.hq

        MouseArea {
            anchors.fill: parent

            function toggleThemeSong(config) {
                if (plasmoid.configuration.playthemesong != config) {
                    return
                }

                if (themeSong.playing) {
                    themeSong.stop()
                }
                else {
                    themeSong.play()
                }
            }

            onClicked: toggleThemeSong("On Click")
            onDoubleClicked: toggleThemeSong("On Double Click")
        }
    }
    
}


