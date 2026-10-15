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

import VLC.MediaLibrary

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util

Widgets.PageLoader {
    id: root

    pageModel: [{
        name: "base",
        component: homeComponent,
        default: true
    }, {
        name: "continueWatching",
        component: continueWatchingComponent
    }, {
        name: "listenAgain",
        component: listenAgainComponent
    }]

    property int displayMarginBeginning: 0
    property int displayMarginEnd: 0

    property bool enableBeginningFade: true
    property bool enableEndFade: true

    Accessible.role: Accessible.Client
    Accessible.name: qsTr("Home View")
    AccessibleCompat.id: "homeDisplay"


    Component {
        id: homeComponent

        HomePage {
            focus: true

            onSeeAllButtonClicked: (name, reason) => {
                // The folders are listed in the videos page
                if (name === "folders")
                    History.push(["video"], reason)
                else
                    History.push([...root.pagePrefix, name], reason)
            }
        }
    }

    Component {
        id: continueWatchingComponent

        Widgets.PageExt {
            id: continueWatchingPage

            title: qsTr("Continue Watching")

            VideoAll {
                id: continueWatching

                anchors.fill: parent

                focus: true

                model: MLRecentVideoModel {
                    ml: MediaLib

                    sortCriteria: continueWatchingPage.sort.criteria
                    sortOrder: continueWatchingPage.sort.order
                    searchPattern: continueWatchingPage.search.pattern

                    readonly property bool needToNavigateBack: !loading && count === 0
                                                               && continueWatchingPage.search.pattern === ""

                    onNeedToNavigateBackChanged: {
                        if (needToNavigateBack)
                            History.previous(Qt.BacktabFocusReason)
                    }
                }

                sectionProperty: model.sortCriteria === "title" ? "title_first_symbol" : ""

                contextMenu: MLContextMenu {
                    model: continueWatching.model

                    showPlayAsAudioAction: true
                }

                displayMarginBeginning: root.displayMarginBeginning
                displayMarginEnd: root.displayMarginEnd

                enableBeginningFade: root.enableBeginningFade
                enableEndFade: root.enableEndFade
            }
        }
    }

    Component {
        id: listenAgainComponent

        Widgets.PageExt {
            id: listenAgainPage

            title: qsTr("Listen Again")

            MediaView {
                focus: true

                anchors.fill: parent

                model: MLRecentAudioModel {
                    ml: MediaLib

                    sortCriteria: listenAgainPage.sort.criteria
                    sortOrder: listenAgainPage.sort.order
                    searchPattern: listenAgainPage.search.pattern
                }

                displayMarginBeginning: root.displayMarginBeginning
                displayMarginEnd: root.displayMarginEnd

                enableBeginningFade: root.enableBeginningFade
                enableEndFade: root.enableEndFade
            }
        }
    }

}
