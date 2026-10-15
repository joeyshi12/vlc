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
import VLC.Playlist

// "Open Network Stream" of the design: one or more URLs, played when the
// dialog is accepted, and saved as a playlist of the media library when a
// name is given.
ModalDialog {
    id: root

    title: qsTr("Open Network Stream")

    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.width : 1048) - 2 * VLCStyle.margin_large)

    padding: VLCStyle.dp(20, VLCStyle.scale)
    topPadding: VLCStyle.dp(22, VLCStyle.scale)

    readonly property var urls: urlField.text.split(/\s+/).map((u) => u.trim()).filter((u) => u.length > 0)
    property var playlistModel: null

    onOpened: {
        urlField.text = ""
        nameField.text = ""
        urlField.forceActiveFocus()
    }

    onAccepted: {
        if (urls.length === 0)
            return
        if (nameField.text.trim() !== "" && MainCtx.mediaLibraryAvailable) {
            // Created here because the type only exists with the media library.
            // Keep one model for the life of the dialog, so accepting repeatedly
            // does not leave a model behind each time.
            if (!playlistModel)
                playlistModel = Qt.createQmlObject("import VLC.MediaLibrary; MLPlaylistListModel { ml: MediaLib }", root)
            playlistModel.create(nameField.text.trim(), urls)
        }
        MainPlaylistController.append(urls, true)
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(20, VLCStyle.scale)

        DialogParts.Heading {
            text: qsTr("Network URL")
            help: qsTr("You can enter multiple links to load, one per line.")
        }

        DialogParts.Box {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(194, VLCStyle.scale)

            border.color: urlField.activeFocus ? urlTheme.accent : borderContext.bg.primary
            border.width: VLCStyle.dp(urlField.activeFocus ? 1 : 2, VLCStyle.scale)

            readonly property ColorContext urlContext: ColorContext {
                id: urlTheme
                palette: VLCStyle.palette
                colorSet: ColorContext.Window
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                clip: true
                contentHeight: urlField.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                T.TextArea.flickable: T.TextArea {
                    id: urlField

                    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                    rightPadding: VLCStyle.dp(12, VLCStyle.scale)
                    topPadding: VLCStyle.dp(8, VLCStyle.scale)
                    bottomPadding: VLCStyle.dp(8, VLCStyle.scale)

                    font.pixelSize: VLCStyle.fontSize_normal
                    color: urlTheme.fg.primary
                    placeholderText: qsTr("e.g., https://www.example.com/stream.avi")
                    placeholderTextColor: Qt.rgba(urlTheme.fg.secondary.r, urlTheme.fg.secondary.g, urlTheme.fg.secondary.b, 0.6)
                    selectionColor: urlTheme.accent
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere

                    Accessible.name: qsTr("Network URL")
                }

                T.ScrollBar.vertical: Widgets.ScrollBarExt { }
            }
        }

        DialogParts.Heading {
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            visible: MainCtx.mediaLibraryAvailable
            text: qsTr("Playlist Name (optional)")
            help: qsTr("The playlist will be saved and displayed with this title.")
        }

        DialogParts.TextField {
            id: nameField

            visible: MainCtx.mediaLibraryAvailable
            placeholderText: qsTr("e.g., Favorite TV Channels")
            Accessible.name: qsTr("Playlist name")

            onAccepted: if (root.urls.length > 0) root.accept()
        }
    }

    footer: DialogParts.Footer {
        acceptText: qsTr("Play")
        acceptEnabled: root.urls.length > 0
        onAccepted: root.accept()
        onRejected: root.reject()
    }
}
