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
import VLC.Dialogs
import VLC.MediaLibrary

// "New Playlist" of the design: the name of the playlist and the files to
// put in it. The files can be dropped on the box or chosen with a file dialog.
ModalDialog {
    id: root

    title: qsTr("New Playlist")

    width: Math.min(VLCStyle.dp(713, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.width : 713) - 2 * VLCStyle.margin_large)

    padding: VLCStyle.dp(20, VLCStyle.scale)
    topPadding: VLCStyle.dp(22, VLCStyle.scale)

    property var files: []

    function _fileName(url) {
        const parts = decodeURIComponent(String(url)).split("/")
        return parts[parts.length - 1]
    }

    function _addFiles(list) {
        let all = files.slice()
        for (const url of list) {
            if (all.indexOf(String(url)) < 0)
                all.push(String(url))
        }
        files = all
    }

    onOpened: {
        nameField.text = ""
        files = []
        nameField.forceActiveFocus()
    }

    onAccepted: {
        if (nameField.text.trim() === "")
            return
        playlistModel.create(nameField.text.trim(), files)
    }

    MLPlaylistListModel {
        id: playlistModel
        ml: MediaLib
    }

    readonly property ColorContext boxContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(20, VLCStyle.scale)

        DialogParts.Heading {
            text: qsTr("Playlist Details")
            help: qsTr("The playlist will be saved and displayed with this title.")
        }

        DialogParts.TextField {
            id: nameField

            placeholderText: qsTr("e.g., Favorite Videos")
            Accessible.name: qsTr("Playlist name")
            onAccepted: if (text.trim() !== "") root.accept()
        }

        DialogParts.Heading {
            Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
            text: qsTr("Select Files")
            help: qsTr("These files will be added to the playlist.")
        }

        DialogParts.Box {
            id: dropBox

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(186, VLCStyle.scale)

            border.color: dropArea.containsDrag ? theme.accent : Qt.lighter(borderContext.bg.primary, 1.2)

            DropArea {
                id: dropArea
                anchors.fill: parent
                onDropped: (drop) => {
                    if (drop.hasUrls) {
                        root._addFiles(drop.urls)
                        drop.accept()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: root.files.length === 0
                cursorShape: Qt.PointingHandCursor
                onClicked: root._addFiles(DialogsProvider.getOpenMediaUrls(qsTr("Select Files")))
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: root.files.length === 0
                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Widgets.LabelExt {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Drag files into the box or click here to select files.")
                    font.pixelSize: VLCStyle.fontSize_normal
                    color: Qt.rgba(theme.fg.secondary.r, theme.fg.secondary.g, theme.fg.secondary.b, 0.6)
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: VLCStyle.dp(84, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
                    radius: VLCStyle.dp(5, VLCStyle.scale)
                    color: Qt.darker(theme.bg.primary, 1.1)

                    Widgets.IconLabel {
                        anchors.centerIn: parent
                        text: VLCIcons.add
                        color: theme.fg.secondary
                        font.pixelSize: VLCStyle.icon_normal
                    }
                }
            }

            ListView {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                visible: root.files.length > 0
                clip: true
                model: root.files

                delegate: RowLayout {
                    required property int index
                    required property string modelData

                    width: ListView.view.width
                    height: VLCStyle.dp(30, VLCStyle.scale)

                    Widgets.LabelExt {
                        Layout.fillWidth: true
                        leftPadding: VLCStyle.dp(6, VLCStyle.scale)
                        text: root._fileName(modelData)
                        elide: Text.ElideMiddle
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: theme.fg.primary
                    }

                    Widgets.SvgToolButton {
                        Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                        Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)
                        iconName: "close"
                        description: qsTr("Remove")
                        onClicked: {
                            let all = root.files.slice()
                            all.splice(index, 1)
                            root.files = all
                        }
                    }
                }

                footer: Widgets.TextToolButton {
                    text: qsTr("Add files")
                    onClicked: root._addFiles(DialogsProvider.getOpenMediaUrls(qsTr("Select Files")))
                }

                T.ScrollBar.vertical: Widgets.ScrollBarExt { }
            }
        }
    }

    footer: DialogParts.Footer {
        acceptEnabled: nameField.text.trim() !== ""
        onAccepted: root.accept()
        onRejected: root.reject()
    }
}
