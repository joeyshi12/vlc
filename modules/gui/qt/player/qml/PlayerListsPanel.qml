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

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Playlist
import VLC.Util

// Play queue panel of the player, with the Queue, Bookmarks and Chapters tabs.
PanelCard {
    id: root

    readonly property alias playlistPane: queuePage

    tabs: [
        { text: qsTr("Queue"), icon: VLCIcons.playlist },
        { text: qsTr("Bookmarks"), icon: VLCIcons.bookmark },
        { text: qsTr("Chapters"), icon: VLCIcons.list }
    ]

    currentIndex: PlayerPanelState.listsTab
    onCurrentIndexChanged: PlayerPanelState.listsTab = currentIndex

    readonly property ColorContext listsColorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    PlaylistPane {
        id: queuePage

        compactHeader: true
        useAcrylic: false
        background: null

        topPadding: 0
        bottomPadding: VLCStyle.margin_small
        leftPadding: 0
        rightPadding: 0

        focus: root.currentIndex === 0
        wheelEnabled: true
    }

    Loader {
        id: bookmarksPage

        focus: root.currentIndex === 1
        active: MainCtx.mediaLibraryAvailable && root.currentIndex === 1
        source: "qrc:///qt/qml/VLC/MediaLibrary/BookmarksPanelPage.qml"

        Widgets.ListLabel {
            font.weight: Font.Normal
            anchors.centerIn: parent
            width: parent.width - 2 * VLCStyle.margin_large
            visible: !MainCtx.mediaLibraryAvailable
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Bookmarks are saved in the media library, which is not available.")
            color: theme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }
    }

    FocusScope {
        id: chaptersPage

        focus: root.currentIndex === 2

        ListView {
            id: chapterList

            anchors.fill: parent
            anchors.topMargin: VLCStyle.margin_large
            anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

            clip: true
            focus: true
            spacing: VLCStyle.margin_small
            boundsBehavior: Flickable.StopAtBounds

            model: Player.chapters

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            delegate: T.ItemDelegate {
                id: chapter

                required property int index
                required property var model

                // Current chapter
                readonly property bool current: model.checked

                width: chapterList.width
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                focusPolicy: Qt.StrongFocus

                Accessible.name: qsTr("Chapter %1, %2").arg(index + 1).arg(model.display)

                onClicked: Player.chapters.selectChapter(index)

                readonly property ColorContext colorContext: ColorContext {
                    id: chapterTheme
                    colorSet: ColorContext.Item
                    hovered: chapter.hovered
                    focused: chapter.visualFocus
                }

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: chapter.current ? chapterTheme.bg.highlight : chapterTheme.bg.primary
                    border.width: chapter.visualFocus ? VLCStyle.focus_border : 0
                    border.color: chapterTheme.visualFocus
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.margin_small

                    Widgets.ListLabel {
                        Layout.preferredWidth: VLCStyle.dp(34, VLCStyle.scale)
                        leftPadding: VLCStyle.margin_xxsmall
                        text: chapter.index + 1
                        // Chapters after the current one use the accent colour.
                        color: (chapter.index > Player.chapters.currentIndex) ? theme.accent : theme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_large
                        font.weight: Font.Medium
                    }

                    Widgets.ListLabel {
                        font.weight: Font.Normal
                        Layout.fillWidth: true
                        text: chapter.model.display
                        color: theme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideRight
                    }

                    Widgets.ListLabel {
                        font.weight: Font.Normal
                        rightPadding: VLCStyle.margin_xxsmall
                        text: chapter.model.time.formatHMS(0)
                        color: theme.fg.secondary
                        font.pixelSize: VLCStyle.fontSize_large
                    }
                }
            }

            Widgets.ListLabel {
                font.weight: Font.Normal
                anchors.centerIn: parent
                visible: chapterList.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("This media has no chapters.")
                color: theme.fg.secondary
                font.pixelSize: VLCStyle.fontSize_large
            }
        }
    }
}
