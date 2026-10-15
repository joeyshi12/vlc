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

// Floating panel of the player, with a row of tabs on top. Each child item is
// the page of the tab with the same index.
T.Pane {
    id: root

    // List of { text, icon } objects, one per page.
    property var tabs: []
    property int currentIndex: 0

    default property alias pages: stack.data

    signal closeRequested()

    implicitWidth: VLCStyle.dp(400, VLCStyle.scale)

    padding: 0

    focus: true

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)
    Navigation.cancelAction: () => root.closeRequested()

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    readonly property real radius: VLCStyle.dp(10, VLCStyle.scale)

    background: Rectangle {
        radius: root.radius
        color: theme.bg.primary.alpha(0.95)
        border.width: VLCStyle.border
        border.color: theme.border

        Widgets.RoundedRectangleShadow {
            z: -1
            blurRadius: VLCStyle.dp(12, VLCStyle.scale)
            yOffset: VLCStyle.dp(4, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Tab row
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: VLCStyle.dp(50, VLCStyle.scale)

            color: theme.bg.secondary
            radius: root.radius

            // Square bottom corners
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.radius
                color: parent.color
            }

            Row {
                id: tabRow

                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)

                Repeater {
                model: root.tabs

                delegate: T.TabButton {
                    id: tabButton

                    required property var modelData
                    required property int index

                    width: tabRow.width / Math.max(1, root.tabs.length)
                    height: tabRow.height

                    checked: index === root.currentIndex
                    focusPolicy: Qt.StrongFocus
                    focus: checked

                    Accessible.name: modelData.text

                    onClicked: root.currentIndex = index

                    Keys.onLeftPressed: root.currentIndex = Math.max(0, root.currentIndex - 1)
                    Keys.onRightPressed: root.currentIndex = Math.min(root.tabs.length - 1, root.currentIndex + 1)

                    readonly property ColorContext colorContext: ColorContext {
                        id: tabTheme
                        colorSet: ColorContext.TabButton

                        focused: tabButton.visualFocus
                        hovered: tabButton.hovered
                    }

                    contentItem: Item {
                        Row {
                            anchors.centerIn: parent
                            spacing: VLCStyle.margin_xsmall

                            Widgets.IconLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButton.modelData.icon
                                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                                color: tabButton.checked ? tabTheme.fg.secondary : tabTheme.fg.primary
                            }

                            Widgets.ListLabel {
                                font.weight: Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButton.modelData.text
                                font.pixelSize: VLCStyle.fontSize_normal
                                color: tabButton.checked ? tabTheme.fg.secondary : tabTheme.fg.primary
                            }
                        }
                    }

                    background: Item {
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: VLCStyle.margin_xxsmall
                            radius: VLCStyle.dp(4, VLCStyle.scale)
                            color: (tabButton.hovered || tabButton.visualFocus) ? tabTheme.bg.primary : "transparent"
                        }

                        // Line under the selected tab
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: VLCStyle.margin_xsmall
                            anchors.rightMargin: VLCStyle.margin_xsmall

                            height: VLCStyle.dp(2, VLCStyle.scale)
                            visible: tabButton.checked
                            color: theme.accent
                        }
                    }
                }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: VLCStyle.border
            color: theme.separator
        }

        StackLayout {
            id: stack

            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: root.currentIndex
        }
    }
}
