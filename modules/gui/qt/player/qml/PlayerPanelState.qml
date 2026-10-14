/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
pragma Singleton

import QtQuick

import VLC.MainInterface
import VLC.Playlist

// State of the player settings panel (Playback, Video, Audio and Subtitles
// tabs) and of the sleep timer set from it. The play queue panel keeps using
// MainCtx.playqueuePanel.
QtObject {
    id: root

    enum SettingsTab {
        Playback,
        Video,
        Audio,
        Subtitles
    }

    property bool settingsVisible: false
    property int settingsTab: PlayerPanelState.SettingsTab.Playback

    // Tab of the play queue panel: 0 queue, 1 bookmarks, 2 chapters.
    property int listsTab: 0

    // Opens the settings panel on `tab`, or closes it when it already shows `tab`.
    function toggleSettings(tab: int) {
        if (settingsVisible && settingsTab === tab) {
            settingsVisible = false
            return
        }
        settingsTab = tab
        settingsVisible = true
        // Both panels use the same place.
        MainCtx.playqueuePanel.visible = false
    }

    // Sleep timer, in minutes. 0 means off.
    readonly property var sleepTimerChoices: [0, 15, 30, 45, 60, 90]
    property int sleepTimerMinutes: 0
    readonly property alias sleepTimerRunning: sleepTimer.running

    onSleepTimerMinutesChanged: {
        if (sleepTimerMinutes > 0) {
            sleepTimer.interval = sleepTimerMinutes * 60 * 1000
            sleepTimer.restart()
        } else {
            sleepTimer.stop()
        }
    }

    readonly property Timer _sleepTimer: Timer {
        id: sleepTimer

        repeat: false
        onTriggered: {
            MainPlaylistController.pause()
            root.sleepTimerMinutes = 0
        }
    }
}
