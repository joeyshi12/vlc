/******************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * Author: Ash <ashutoshv191@gmail.com>
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
 ******************************************************************************/
import QtQuick

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Style

// The videos that were played last, as a page of the sidebar
Widgets.PageExt {
    id: root

    title: qsTr("Recent")

    VideoAll {
        id: recentVideos

        anchors.fill: parent

        focus: true

        model: MLRecentVideoModel {
            ml: MediaLib

            sortCriteria: root.sort.criteria
            sortOrder: root.sort.order
            searchPattern: root.search.pattern
        }

        sectionProperty: model.sortCriteria === "title" ? "title_first_symbol" : ""

        contextMenu: MLContextMenu {
            model: recentVideos.model

            showPlayAsAudioAction: true
        }

        displayMarginBeginning: root.displayMarginBeginning
        displayMarginEnd: root.displayMarginEnd

        enableBeginningFade: root.enableBeginningFade
        enableEndFade: root.enableEndFade
    }
}
