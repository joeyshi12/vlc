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

// Associates subtitle files with the videos in the media library. Subtitle
// files are matched to videos by file name first. A subtitle can also be
// changed or removed in its row.
ModalDialog {
    id: root

    title: qsTr("Add Subtitles")

    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.width : 1048) - 2 * VLCStyle.margin_large)
    height: Math.min(VLCStyle.dp(800, VLCStyle.scale), (T.Overlay.overlay ? T.Overlay.overlay.height : 800) - 2 * VLCStyle.margin_large)

    padding: VLCStyle.dp(20, VLCStyle.scale)
    topPadding: VLCStyle.dp(22, VLCStyle.scale)

    // id.toString() -> { id, subtitle URL }
    property var assignments: ({})

    readonly property ColorContext bodyContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }
    readonly property ColorContext boxContext: ColorContext {
        id: boxTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.Slider
    }

    function _name(url) {
        const parts = decodeURIComponent(String(url)).split("/")
        return parts[parts.length - 1]
    }

    function _stem(name) {
        return name.replace(/\.[^.]*$/, "").toLowerCase()
    }

    function _key(id) {
        return id.toString()
    }

    function _subtitleFor(id) {
        return assignments[_key(id)]?.subtitle ?? ""
    }

    function _set(id, url) {
        let map = Object.assign({}, assignments)
        if (url === "")
            delete map[_key(id)]
        else
            map[_key(id)] = ({ id: id, subtitle: String(url) })
        assignments = map
    }

    function _pickFor(id) {
        const files = DialogsProvider.getOpenMediaUrls(qsTr("Select a subtitle file"))
        if (files.length > 0)
            _set(id, files[0])
    }

    // The list model loads its rows in chunks. getDataFlat loads every row
    // before matching or saving, so large libraries work as well.
    function _withAllVideos(callback) {
        let indexes = []
        for (let i = 0; i < videos.count; ++i)
            indexes.push(i)
        videos.getDataFlat(indexes, callback)
    }

    function _addFiles() {
        const files = DialogsProvider.getOpenMediaUrls(qsTr("Select subtitle files"))
        if (files.length === 0)
            return

        _withAllVideos((items) => {
            let map = Object.assign({}, assignments)
            let unused = files.slice()
            for (let i = 0; i < items.length; ++i) {
                const item = items[i]
                if (!item.id)
                    continue
                const stem = _stem(String(item.fileName ?? item.title ?? ""))
                const match = unused.findIndex((url) => {
                    const subStem = _stem(_name(url))
                    return subStem === stem || subStem.startsWith(stem + ".") || stem.startsWith(subStem + ".")
                })
                if (match >= 0) {
                    map[_key(item.id)] = ({ id: item.id, subtitle: String(unused[match]) })
                    unused.splice(match, 1)
                }
            }

            // When exactly one file and one video remain, pair them as the
            // useful manual fallback for names that do not match.
            if (unused.length === 1) {
                let freeId = null
                for (let i = 0; i < items.length; ++i) {
                    const id = items[i].id
                    if (id && !map[_key(id)]) {
                        if (freeId !== null) { freeId = null; break }
                        freeId = id
                    }
                }
                if (freeId !== null)
                    map[_key(freeId)] = ({ id: freeId, subtitle: String(unused[0]) })
            }
            assignments = map
        })
    }

    function _save() {
        // The assignments carry their IDs, so changing the search does not
        // omit assignments that are currently filtered out.
        DialogsProvider.attachSubtitles(Object.values(assignments))
        accept()
    }

    onOpened: {
        assignments = ({})
        videos.searchPattern = ""
    }

    MLVideoModel {
        id: videos
        ml: MediaLib
        sortCriteria: "title"
        sortOrder: Qt.AscendingOrder
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(14, VLCStyle.scale)

        readonly property ColorContext colorContext: ColorContext {
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.SearchField {
                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)
                textField.placeholderText: qsTr("Search videos")
                onSearchPatternChanged: videos.searchPattern = searchPattern
            }

            DialogParts.Button {
                text: qsTr("From Computer")
                onClicked: root._addFiles()
            }
        }

        // Column headings
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.dp(6, VLCStyle.scale)
            spacing: VLCStyle.dp(20, VLCStyle.scale)

            Widgets.LabelExt {
                Layout.fillWidth: true
                text: qsTr("Video")
                font.pixelSize: VLCStyle.fontSize_normal
                color: theme.fg.secondary
            }
            Widgets.LabelExt {
                Layout.preferredWidth: VLCStyle.dp(400, VLCStyle.scale)
                text: qsTr("Subtitle file")
                font.pixelSize: VLCStyle.fontSize_normal
                color: theme.fg.secondary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: VLCStyle.dp(1, VLCStyle.scale)
            color: theme.separator
        }

        ListView {
            id: videoList

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            model: videos
            spacing: VLCStyle.dp(8, VLCStyle.scale)
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            delegate: RowLayout {
                id: row

                required property int index
                required property var id
                required property string title
                required property string fileName
                required property string thumbnail

                width: ListView.view.width
                height: VLCStyle.dp(54, VLCStyle.scale)
                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: rowMouse.containsMouse ? Qt.rgba(theme.fg.primary.r, theme.fg.primary.g, theme.fg.primary.b, 0.05) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                        anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                        spacing: VLCStyle.dp(10, VLCStyle.scale)

                        Rectangle {
                            Layout.preferredWidth: VLCStyle.dp(64, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(36, VLCStyle.scale)
                            radius: VLCStyle.dp(4, VLCStyle.scale)
                            color: boxTheme.bg.secondary
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: row.thumbnail
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Widgets.LabelExt {
                            Layout.fillWidth: true
                            text: row.title || row.fileName
                            elide: Text.ElideMiddle
                            font.pixelSize: VLCStyle.fontSize_normal
                            color: theme.fg.primary
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._pickFor(row.id)
                    }
                }

                Rectangle {
                    Layout.preferredWidth: VLCStyle.dp(400, VLCStyle.scale)
                    Layout.fillHeight: true
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: boxTheme.bg.secondary
                    border.width: root._subtitleFor(row.id) !== "" ? VLCStyle.dp(1, VLCStyle.scale) : 0
                    border.color: theme.accent

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
                        anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)

                        Widgets.LabelExt {
                            Layout.fillWidth: true
                            text: root._subtitleFor(row.id) !== "" ? root._name(root._subtitleFor(row.id)) : qsTr("No subtitle selected")
                            elide: Text.ElideMiddle
                            font.pixelSize: VLCStyle.fontSize_normal
                            color: root._subtitleFor(row.id) !== "" ? theme.fg.primary : theme.fg.secondary
                        }

                        Widgets.SvgToolButton {
                            visible: root._subtitleFor(row.id) !== ""
                            Layout.preferredWidth: VLCStyle.dp(28, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)
                            iconName: "close"
                            description: qsTr("Remove subtitle")
                            onClicked: root._set(row.id, "")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._pickFor(row.id)
                    }
                }
            }

            Widgets.EmptyLabel {
                anchors.centerIn: parent
                visible: videos.count === 0 && !videos.loading
                text: qsTr("No videos found")
            }
        }
    }

    footer: DialogParts.Footer {
        acceptEnabled: Object.keys(root.assignments).length > 0
        onAccepted: root._save()
        onRejected: root.reject()
    }
}
