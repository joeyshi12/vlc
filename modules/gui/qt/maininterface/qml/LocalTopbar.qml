/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQml.Models
import QtQuick.Window


import VLC.MainInterface
import VLC.Style
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Util

T.ToolBar {
    id: root

    Accessible.name: qsTr("Local top bar")
    AccessibleCompat.id: "localTopbar"

    property bool useAcrylic: true

    // For now, used for d&d functionality
    // Not strictly necessary to set
    property Item plListView

    property bool _showCSD: MainCtx.clientSideDecoration
        && !(MainCtx.intfMainWindow.visibility === Window.FullScreen)
        && !MainCtx.hasToolbarMenu

    //whether the navigation pannel is actually visible or not
    property bool navigationVisible: false
    property alias playqueueVisible: playlistBtn.checked

    signal toggleNavigationVisibility()
    signal togglePlayqueueVisibility()

    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                             implicitContentWidth + leftPadding + rightPadding + (_showCSD ? csdButtons.implicitWidth : 0))

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background:  Widgets.AcrylicBackground {
        enabled: root.useAcrylic
        tintColor: theme.bg.primary
    }

    contentItem: Item {

        implicitHeight: VLCStyle.globalToolbar_height
        implicitWidth: navigationButtons.implicitWidth
                     + playqueueButtonsTop.implicitWidth
                     + VLCStyle.margin_xsmall * 2

        Item {
            id: navigationButtons

            implicitWidth: navigationButtonsRow.implicitWidth

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: VLCStyle.margin_xsmall
            }

            Navigation.parentItem: root

            Row {
                id: navigationButtonsRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.margin_normal

                Navigation.parentItem: root
                Navigation.rightItem: playqueueButtonsTop

                Widgets.BannerCone {
                    id: logo

                    anchors.verticalCenter: parent.verticalCenter

                    sourceSize.width: VLCStyle.icon_normal
                    sourceSize.height: VLCStyle.icon_normal
                    color: theme.accent
                }

                Widgets.SvgToolButton {
                    id: menuBtn

                    anchors.verticalCenter: parent.verticalCenter

                    visible: !MainCtx.hasToolbarMenu
                    focus: true

                    iconName: "more"
                    description: qsTr("Menu")
                    checked: overflowMenu.opened

                    Navigation.parentItem: navigationButtons
                    Navigation.rightItem: playlistBtn

                    onClicked: overflowMenu.opened ? overflowMenu.close() : overflowMenu.open()

                    TopBarMenu {
                        id: overflowMenu
                        parent: menuBtn
                    }
                }
            }
        }

        Item {
            id: playqueueButtonsTop

            implicitWidth: playqueueButtonsTopRow.implicitWidth

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                //put the buttons below the CSD if we have enough space
                rightMargin: VLCStyle.margin_xsmall
                    + ((root._showCSD && root.topPadding < csdButtons.height)
                        ? Math.max(csdButtons.width - root.rightPadding, 0)
                        : 0)
            }

            Navigation.parentItem: root

            Row {
                id: playqueueButtonsTopRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.margin_normal

                Navigation.parentItem: root
                Navigation.leftItem: navigationButtons

                PlaylistPane.PlaylistToggleButton {
                    id: playlistBtn

                    plListView: root.plListView

                    Navigation.parentItem: playqueueButtonsTop
                    Navigation.leftItem: menuBtn

                    onClicked:  root.togglePlayqueueVisibility()
                }
            }
        }

        // Title of the window, centred. It is only drawn when the window
        // has no title bar of the system.
        Widgets.LabelExt {
            anchors.centerIn: parent

            width: Math.min(implicitWidth, parent.width - 2 * Math.max(navigationButtons.width, playqueueButtonsTop.width + csdButtons.width) - VLCStyle.margin_large)

            visible: root._showCSD
            text: MainCtx.intfMainWindow.title
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            color: theme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_normal

            Accessible.ignored: true
        }

        Loader {
            z: -1

            anchors.fill: parent
            active: root._showCSD
            sourceComponent: Widgets.CSDTitlebarTapNDrapHandler {
            }
        }
    }

    Loader {
        id: csdButtons

        //csd button are
        parent:  root
        anchors {
            right: parent.right
            top: parent.top
        }

        height: VLCStyle.globalToolbar_height
        active: root._showCSD
        source: VLCStyle.palette.hasCSDImage
                  ? "qrc:///qt/qml/VLC/Widgets/CSDThemeButtonSet.qml"
                  : "qrc:///qt/qml/VLC/Widgets/CSDWindowButtonSet.qml"
    }
}
