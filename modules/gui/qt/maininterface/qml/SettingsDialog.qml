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
import VLC.Util

// Settings of VLC, as in the design: search field and title at the top,
// categories on the left, the options of the category on the right. The
// configuration file is written when the dialog is closed.
T.Popup {
    id: root

    modal: true
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

    anchors.centerIn: T.Overlay.overlay

    width: Math.min(VLCStyle.dp(1048, VLCStyle.scale), (parent ? parent.width : 1048) - 2 * VLCStyle.margin_large)
    height: Math.min(VLCStyle.dp(865, VLCStyle.scale), (parent ? parent.height : 865) - 2 * VLCStyle.margin_large)

    padding: 0

    readonly property SettingsWidgets.Pal pal: SettingsWidgets.Pal { }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    readonly property var categories: [
        { group: qsTr("App") },
        { text: qsTr("General"), title: qsTr("Global Settings"), icon: "set-preferences", page: generalPageLoader },
        { text: qsTr("Interface"), title: qsTr("Interface Settings"), icon: "set-interface", page: interfacePageLoader },
        { text: qsTr("Privacy"), title: qsTr("Privacy Settings"), icon: "set-privacy", page: privacyPageLoader },
        { text: qsTr("Controls"), title: qsTr("Mouse, Keyboard & Remote Controls"), icon: "set-hotkeys", page: controlsPageLoader },
        { group: qsTr("Media") },
        { text: qsTr("Playback"), title: qsTr("Playback Preferences"), icon: "set-playback", page: playbackPageLoader },
        { text: qsTr("Video"), title: qsTr("Video Defaults"), icon: "set-video", page: videoPageLoader },
        { text: qsTr("Audio"), title: qsTr("Audio Defaults"), icon: "set-audio", page: audioPageLoader },
        { text: qsTr("Subtitles"), title: qsTr("Subtitle Defaults"), icon: "set-subtitles", page: subtitlesPageLoader },
        { text: qsTr("Library"), title: qsTr("Playlists, Folders & Files"), icon: "set-folder", page: libraryPageLoader },
        { group: qsTr("System") },
        { text: qsTr("Network"), title: qsTr("Network Connections & Security"), icon: "nav-streaming", page: networkPageLoader },
        { text: qsTr("Performance"), title: qsTr("Performance Settings"), icon: "set-preferences", page: performancePageLoader },
        { text: qsTr("Recording"), title: qsTr("Recording, Casting & Streaming Out"), icon: "set-record", page: recordingPageLoader },
        { text: qsTr("Extensions"), title: qsTr("Add-ons & Scripts"), icon: "set-plugins", page: extensionsPageLoader }
    ]

    property int currentCategory: 1

    readonly property string filter: searchField.searchPattern

    // When searching, go to the first category that has a match
    onFilterChanged: Qt.callLater(_showMatchingCategory)

    function _showMatchingCategory() {
        const currentPage = categories[currentCategory].page?.item
        if (filter === "" || currentPage?.hasMatches)
            return
        for (let i = 0; i < categories.length; ++i) {
            if (categories[i].page?.item?.hasMatches) {
                currentCategory = i
                return
            }
        }
    }

    // Hide the popup first. Saving the complete VLC configuration and
    // reloading preferences can take long enough to delay the next frame.
    onClosed: saveTimer.restart()

    ConfigOption { id: saver }

    Timer {
        id: saveTimer
        interval: VLCStyle.duration_short
        repeat: false
        onTriggered: saver.save(MainCtx)
    }

    T.Overlay.modal: Rectangle {
        // The Settings mock is an isolated surface. Keeping this backdrop
        // opaque prevents the main interface from being blended again for
        // every category hover frame.
        color: VLCStyle.palette.isDark ? "#080808" : "#999999"
    }

    background: Rectangle {
        radius: VLCStyle.dp(14, VLCStyle.scale)
        color: root.pal.window

        border.width: VLCStyle.dp(1, VLCStyle.scale)
        border.color: VLCStyle.palette.isDark ? "#222222" : "#ACACAC"
    }

    contentItem: ColumnLayout {
        spacing: 0

        // The popup is not a child of the main view, so the colours of the
        // controls come from here
        readonly property ColorContext colorContext: ColorContext {
            colorSet: ColorContext.Window
            palette: VLCStyle.palette
        }

        // Header: search field, title, close button
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)

            color: root.pal.header
            // Round the top corners like the dialog
            radius: VLCStyle.dp(14, VLCStyle.scale)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Widgets.SearchField {
                id: searchField

                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter

                width: VLCStyle.dp(200, VLCStyle.scale)
                height: VLCStyle.dp(34, VLCStyle.scale)

                focus: true
            }

            Widgets.LabelExt {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(216 + 24, VLCStyle.scale)
                anchors.right: closeButton.left
                anchors.verticalCenter: parent.verticalCenter

                text: root.categories[root.currentCategory].title
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                color: root.pal.title
                elide: Text.ElideRight
            }

            Widgets.SvgToolButton {
                id: closeButton

                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter

                width: VLCStyle.dp(32, VLCStyle.scale)
                height: width
                iconName: "close"
                description: qsTr("Close")
                onClicked: root.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Categories
            Rectangle {
                Layout.preferredWidth: VLCStyle.dp(200, VLCStyle.scale)
                Layout.fillHeight: true
                Layout.margins: VLCStyle.dp(8, VLCStyle.scale)

                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: root.pal.panel

                Flickable {
                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                    contentHeight: categoryColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: categoryColumn
                        width: parent.width
                        spacing: VLCStyle.dp(8, VLCStyle.scale)

                        Repeater {
                            model: root.categories

                            delegate: Loader {
                                id: categoryLoader

                                required property int index
                                required property var modelData

                                Layout.fillWidth: true

                                visible: modelData.group !== undefined || root.filter === ""
                                         || (modelData.page?.item?.hasMatches ?? true)

                                sourceComponent: modelData.group !== undefined ? groupComponent : itemComponent

                                Component {
                                    id: groupComponent

                                    Widgets.LabelExt {
                                        height: VLCStyle.dp(33, VLCStyle.scale)
                                        leftPadding: VLCStyle.dp(10, VLCStyle.scale)
                                        verticalAlignment: Text.AlignVCenter
                                        text: categoryLoader.modelData.group
                                        font.pixelSize: VLCStyle.fontSize_normal
                                        color: root.pal.groupText
                                    }
                                }

                                Component {
                                    id: itemComponent

                                    T.ItemDelegate {
                                        id: item

                                        readonly property bool current: root.currentCategory === categoryLoader.index

                                        width: categoryLoader.width
                                        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)
                                        padding: VLCStyle.dp(4, VLCStyle.scale)
                                        focusPolicy: Qt.StrongFocus
                                        hoverEnabled: false

                                        HoverHandler {
                                            id: itemHover
                                            acceptedDevices: PointerDevice.Mouse | PointerDevice.Stylus
                                        }

                                        onClicked: root.currentCategory = categoryLoader.index

                                        Accessible.name: categoryLoader.modelData.text
                                        Accessible.role: Accessible.PageTab
                                        Accessible.selected: current

                                        background: Rectangle {
                                            radius: VLCStyle.dp(2, VLCStyle.scale)
                                            // The current and hovered categories use the
                                            // same neutral surface. The accent icon marks
                                            // the current category.
                                            color: item.current ? root.pal.selected
                                                                : (itemHover.hovered
                                                                   ? (VLCStyle.palette.isDark ? "#2A2A2A" : "#E0E0E0")
                                                                   : "transparent")
                                            border.width: item.visualFocus ? VLCStyle.focus_border : 0
                                            border.color: theme.visualFocus
                                        }

                                        contentItem: RowLayout {
                                            spacing: VLCStyle.dp(8, VLCStyle.scale)

                                            Item {
                                                Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                                                Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                                                SettingsWidgets.Icon {
                                                    anchors.centerIn: parent
                                                    name: categoryLoader.modelData.icon + ((item.current && categoryLoader.modelData.icon.startsWith("set-")) ? "-active" : "")
                                                    color: item.current ? theme.accent : root.pal.label
                                                }
                                            }

                                            Widgets.LabelExt {
                                                Layout.fillWidth: true
                                                text: categoryLoader.modelData.text
                                                font.pixelSize: VLCStyle.fontSize_normal
                                                color: root.pal.itemText
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                currentIndex: [1, 2, 3, 4, 6, 7, 8, 9, 10, 12, 13, 14, 15].indexOf(root.currentCategory)

                Loader {
                    id: generalPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.General { filter: root.filter }
                }
                Loader {
                    id: interfacePageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Interface { filter: root.filter }
                }
                Loader {
                    id: privacyPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Privacy { filter: root.filter }
                }
                Loader {
                    id: controlsPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Controls { filter: root.filter }
                }
                Loader {
                    id: playbackPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Playback { filter: root.filter }
                }
                Loader {
                    id: videoPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Video { filter: root.filter }
                }
                Loader {
                    id: audioPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Audio { filter: root.filter }
                }
                Loader {
                    id: subtitlesPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Subtitles { filter: root.filter }
                }
                Loader {
                    id: libraryPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Library { filter: root.filter }
                }
                Loader {
                    id: networkPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Network { filter: root.filter }
                }
                Loader {
                    id: performancePageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Performance { filter: root.filter }
                }
                Loader {
                    id: recordingPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Recording { filter: root.filter }
                }
                Loader {
                    id: extensionsPageLoader
                    active: StackLayout.isCurrentItem || root.filter !== ""
                    sourceComponent: SettingsPages.Extensions { filter: root.filter }
                }
            }
        }
    }
}
