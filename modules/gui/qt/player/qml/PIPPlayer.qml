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
import VLC.Player
import VLC.Util

// Small player that floats over the library while a video or an audio file is playing: the
// video with buttons shown on hover, the seek bar, the title, the folder and
// the artist. The queue button controls the separate PIPQueue card.
T.Control {
    id: root

    width: Math.round(VLCStyle.dp(391, VLCStyle.scale))
    height: implicitHeight

    implicitHeight: content.implicitHeight

    objectName: "pip window"

    property real dragXMin: 0
    property real dragXMax: 0
    property real dragYMin: undefined
    property real dragYMax: undefined

    // `hideControls` being `false` does not necessarily mean that the buttons are shown:
    property bool hideControls: MainCtx.usingTouch // By default controls are hidden with touch

    property bool queueVisible: false

    signal queueToggled()

    readonly property bool _controlsShown: !root.hideControls &&
                                          (hoverHandler.hovered ||
                                           playButton.hovered ||
                                           previousButton.hovered ||
                                           nextButton.hovered ||
                                           closeButton.hovered ||
                                           popoutButton.hovered)

    readonly property string _displayTitle: {
        const title = Player.title.trim()
        if (title !== "")
            return title

        // Local videos often have no title metadata. The design shows their
        // file name, including the extension.
        const url = Player.url.toString()
        if (url !== "") {
            try {
                const cleanUrl = decodeURIComponent(url.split(/[?#]/)[0])
                const fileName = cleanUrl.substring(cleanUrl.lastIndexOf("/") + 1)
                if (fileName !== "")
                    return fileName
            } catch (error) {
                // Keep the player usable for malformed remote URLs.
            }
        }

        return Player.name
    }

    readonly property string _folderName: {
        const url = Player.url.toString()
        if (!url.startsWith("file:"))
            return ""
        const parts = decodeURIComponent(url).split("/")
        return (parts.length > 1) ? parts[parts.length - 2] : ""
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Accessible.role: Accessible.Graphic
    Accessible.focusable: false
    Accessible.name: qsTr("video content")

    Drag.active: dragHandler.active

    Drag.onActiveChanged: {
        root.anchors.left = undefined
        root.anchors.right = undefined
        root.anchors.top = undefined
        root.anchors.bottom = undefined
        root.anchors.verticalCenter = undefined
        root.anchors.horizontalCenter = undefined
    }

    // The card can be moved by dragging any part that is not a control.
    DragHandler {
        id: dragHandler

        target: root

        cursorShape: Qt.DragMoveCursor

        dragThreshold: 0

        grabPermissions: PointerHandler.CanTakeOverFromAnything

        xAxis.minimum: root.dragXMin
        xAxis.maximum: root.dragXMax
        yAxis.minimum: root.dragYMin
        yAxis.maximum: root.dragYMax
    }

    background: Rectangle {
        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: theme.bg.primary

        Widgets.RoundedRectangleShadow {
            z: -1
            blurRadius: VLCStyle.dp(12, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.38)
        }
    }

    contentItem: ColumnLayout {
        id: content

        spacing: 0

        // Video
        Item {
            id: videoFrame

            readonly property real radius: VLCStyle.dp(8, VLCStyle.scale)
            readonly property real borderWidth: VLCStyle.dp(2, VLCStyle.scale)

            Layout.fillWidth: true
            Layout.margins: VLCStyle.dp(8, VLCStyle.scale)
            Layout.bottomMargin: 0
            implicitHeight: Math.round(width * 9 / 16)

            // Background and cover, when there is no video (audio files)
            Rectangle {
                anchors.fill: parent
                visible: !Player.hasVideoOutput
                radius: videoFrame.radius
                color: Qt.lighter(theme.bg.primary, 1.3)

                Image {
                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(16, VLCStyle.scale)

                    visible: Player.artwork.toString() !== ""
                    source: Player.artwork
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false

                    Accessible.ignored: true
                }
            }

            VideoSurface {
                id: videoSurface

                anchors.fill: parent
                videoSurfaceProvider: MainCtx.videoSurfaceProvider

                color: "transparent"
            }

            // Darkens the video while the controls are shown.
            Rectangle {
                anchors.fill: parent
                radius: videoFrame.radius
                color: Qt.rgba(0, 0, 0, 0.65)
                opacity: root._controlsShown ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: VLCStyle.duration_veryShort }
                }
            }

            // The video is shown through a transparent part of the interface,
            // so clipping and rounding in QML do not apply to it. Instead, paint
            // the corners outside the rounded border in the card colour, with a
            // ring around the frame. The ring's inner edge sits under the border
            // stroke, so its anti-aliased edge does not let the video through.
            // To cover a corner, the ring has to reach (sqrt(2) - 1) * radius
            // beyond the frame's rounded edge.
            Rectangle {
                readonly property real inset: videoFrame.borderWidth / 2
                readonly property real thickness: Math.ceil(videoFrame.radius / 2) + inset

                anchors.fill: parent
                anchors.margins: inset - thickness
                radius: videoFrame.radius - inset + thickness
                color: "transparent"
                border.width: thickness
                border.color: theme.bg.primary
                antialiasing: true
            }

            // Border of the video
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: videoFrame.radius
                border.width: videoFrame.borderWidth
                border.color: theme.bg.secondary
            }

            DoubleClickIgnoringItem {
                anchors.fill: parent

                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds

                    onDoubleTapped: (eventPoint, button) => {
                        // Docs are lying, there is no `deviceType`: QTBUG-135104
                        if (eventPoint.device.type !== PointerDevice.TouchScreen)
                            MainCtx.playerView = true
                    }

                    onTapped: (eventPoint, button) => {
                        // Docs are lying, there is no `deviceType`: QTBUG-135104
                        if (eventPoint.device.type === PointerDevice.TouchScreen) {
                            // Breaking the initial binding is intentional here:
                            root.hideControls = !root.hideControls
                        } else {
                            MainPlaylistController.togglePlayPause()
                        }
                    }
                }

                HoverHandler {
                    id: hoverHandler

                    grabPermissions: PointerHandler.CanTakeOverFromAnything
                    cursorShape: Qt.ArrowCursor

                    Component.onCompleted: {
                        if (typeof blocking === 'boolean')
                            blocking = true // Qt 6.3 feature
                    }
                }
            }

            Item {
                anchors.fill: parent

                visible: root._controlsShown

                // Raise the controls so that the handlers of the video do
                // not handle their events.
                z: 1

                Widgets.SvgToolButton {
                    id: closeButton

                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: VLCStyle.margin_small
                    }

                    iconName: "close"
                    iconSize: VLCStyle.dp(24, VLCStyle.scale)
                    color: "white"
                    description: qsTr("close video")

                    AccessibleCompat.id: "pipCloseButton"

                    onClicked: MainPlaylistController.stop()
                }

                Widgets.SvgToolButton {
                    id: popoutButton

                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: VLCStyle.margin_small
                    }

                    iconName: "open"
                    iconSize: VLCStyle.dp(24, VLCStyle.scale)
                    color: "white"
                    description: qsTr("maximize player")

                    AccessibleCompat.id: "pipFullscreenButton"

                    onClicked: MainCtx.playerView = true
                }

                Row {
                    anchors.centerIn: parent
                    spacing: VLCStyle.dp(60, VLCStyle.scale)

                    Widgets.SvgToolButton {
                        id: previousButton

                        anchors.verticalCenter: parent.verticalCenter

                        iconName: "previous"
                        iconSize: VLCStyle.dp(40, VLCStyle.scale)
                        color: "white"
                        enabled: MainPlaylistController.hasPrev
                        description: qsTr("Previous")

                        onClicked: MainPlaylistController.prev()
                    }

                    Widgets.SvgToolButton {
                        id: playButton

                        anchors.verticalCenter: parent.verticalCenter

                        iconName: (Player.playingState !== Player.PLAYING_STATE_PAUSED
                                   && Player.playingState !== Player.PLAYING_STATE_STOPPED) ? "pause" : "play"
                        iconSize: VLCStyle.dp(56, VLCStyle.scale)
                        color: "white"
                        description: qsTr("play/pause")

                        AccessibleCompat.id: "pipPlayButton"

                        onClicked: MainPlaylistController.togglePlayPause()
                    }

                    Widgets.SvgToolButton {
                        id: nextButton

                        anchors.verticalCenter: parent.verticalCenter

                        iconName: "next"
                        iconSize: VLCStyle.dp(40, VLCStyle.scale)
                        color: "white"
                        enabled: MainPlaylistController.hasNext
                        description: qsTr("Next")

                        onClicked: MainPlaylistController.next()
                    }
                }
            }
        }

        // Seek bar
        SliderBar {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)

            blockStyle: true
            barHeight: VLCStyle.dp(16, VLCStyle.scale)

            enabled: Player.playingState === Player.PLAYING_STATE_PLAYING
                     || Player.playingState === Player.PLAYING_STATE_PAUSED

            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Progress")
        }

        // Title
        Widgets.ListLabel {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(16, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(16, VLCStyle.scale)

            font.weight: Font.Normal
            font.pixelSize: VLCStyle.fontSize_xlarge
            color: theme.fg.secondary
            text: root._displayTitle
        }

        // Folder, artist and the queue button
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: VLCStyle.dp(12, VLCStyle.scale)
            Layout.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
            Layout.topMargin: VLCStyle.dp(8, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(12, VLCStyle.scale)

            spacing: VLCStyle.dp(8, VLCStyle.scale)

            component Detail : RowLayout {
                id: detail

                property string iconName
                property alias text: label.text

                visible: label.text !== ""
                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Widgets.SvgToolButton {
                    iconName: detail.iconName
                    description: label.text
                    paintOnly: true
                }

                Widgets.ListLabel {
                    id: label

                    font.weight: Font.Normal
                    font.pixelSize: VLCStyle.fontSize_xlarge
                    color: theme.fg.secondary
                }
            }

            Detail {
                iconName: "folder"
                text: root._folderName
            }

            Detail {
                iconName: "artist"
                text: Player.artist
            }

            Item { Layout.fillWidth: true }

            Widgets.SvgToolButton {
                iconName: "lists"
                checked: root.queueVisible
                description: qsTr("Play queue")

                onClicked: root.queueToggled()
            }
        }
    }
}
