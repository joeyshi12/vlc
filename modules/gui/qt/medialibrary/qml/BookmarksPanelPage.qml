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

import VLC.MediaLibrary
import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player

// Bookmarks tab of the player play queue panel. Bookmarks are stored in the
// media library, so this page is only loaded when it is available.
FocusScope {
    id: root

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    MLBookmarkModel {
        id: bookmarks

        player: Player
        ml: MediaLib
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(64, VLCStyle.scale)
            Layout.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

            spacing: VLCStyle.margin_small

            Widgets.ListLabel {
                font.weight: Font.Normal
                Layout.fillWidth: true
                text: (list.count === 1) ? qsTr("1 bookmark") : qsTr("%1 bookmarks").arg(list.count)
                color: theme.fg.secondary
                font.pixelSize: VLCStyle.fontSize_large
            }

            Widgets.IconToolButton {
                font.pixelSize: VLCStyle.icon_normal
                enabled: list.count > 0
                text: VLCIcons.remove
                description: (list.currentIndex >= 0) ? qsTr("Remove the selected bookmark")
                                                      : qsTr("Remove all bookmarks")
                onClicked: {
                    if (list.currentIndex >= 0)
                        bookmarks.removeAt(list.currentIndex)
                    else
                        bookmarks.clear()
                    list.currentIndex = -1
                }
            }

            Widgets.IconToolButton {
                font.pixelSize: VLCStyle.icon_normal
                enabled: Player.isStarted
                text: VLCIcons.add
                description: qsTr("Add a bookmark at the current time")
                onClicked: bookmarks.add()
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

            clip: true
            focus: true
            spacing: VLCStyle.margin_small
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds

            model: bookmarks

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            delegate: T.ItemDelegate {
                id: item

                required property int index
                required property string name
                required property string time

                width: list.width
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                highlighted: ListView.isCurrentItem

                onClicked: {
                    list.currentIndex = index
                    bookmarks.select(bookmarks.index(index, 0))
                }

                readonly property ColorContext colorContext: ColorContext {
                    id: itemTheme
                    colorSet: ColorContext.Item
                    hovered: item.hovered
                    focused: item.visualFocus
                }

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: item.highlighted ? itemTheme.bg.highlight : itemTheme.bg.primary
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.margin_small

                    Widgets.ListLabel {
                        font.weight: Font.Normal
                        Layout.fillWidth: true
                        leftPadding: VLCStyle.margin_xxsmall
                        text: item.name
                        color: theme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideRight
                    }

                    Widgets.ListLabel {
                        font.weight: Font.Normal
                        rightPadding: VLCStyle.margin_xxsmall
                        text: item.time
                        color: theme.fg.secondary
                        font.pixelSize: VLCStyle.fontSize_large
                    }
                }
            }

            Widgets.ListLabel {
                font.weight: Font.Normal
                anchors.centerIn: parent
                visible: list.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("No bookmarks. Use the + button to add one at the current time.")
                color: theme.fg.secondary
                font.pixelSize: VLCStyle.fontSize_large
            }
        }
    }
}
