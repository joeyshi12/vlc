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
import VLC.Dialogs
import VLC.Style
import VLC.Widgets as Widgets

// Main overflow menu. It uses the same surfaces, spacing, rounded corners and
// focus treatment as the rest of the redesigned interface.
T.Popup {
    id: root

    x: 0
    y: parent ? parent.height + VLCStyle.dp(4, VLCStyle.scale) : 0

    implicitWidth: VLCStyle.dp(265, VLCStyle.scale)
    implicitHeight: contentColumn.implicitHeight + topPadding + bottomPadding

    padding: VLCStyle.dp(4, VLCStyle.scale)

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    focus: true

    readonly property bool _dark: VLCStyle.palette.isDark
    readonly property color _surface: _dark ? Qt.rgba(25 / 255, 25 / 255, 25 / 255, 0.96)
                                            : Qt.rgba(213 / 255, 213 / 255, 213 / 255, 0.96)
    readonly property color _hoverSurface: _dark ? "#222222" : "#E7E7E7"
    readonly property color _text: _dark ? "#EAEAEA" : "#2E2E2E"
    readonly property color _mutedText: _dark ? "#8F8F8F" : "#3C3C3C"
    readonly property color _divider: _dark ? "#222222" : "#ACACAC"

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        palette: VLCStyle.palette
    }

    component MenuEntry : T.ItemDelegate {
        id: entry

        required property string iconText
        signal triggered()

        width: root.availableWidth
        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        topPadding: VLCStyle.dp(8, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(8, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus
        hoverEnabled: true

        onClicked: {
            root.close()
            triggered()
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: entry.down || entry.hovered ? root._hoverSurface : "transparent"
            border.width: entry.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.IconLabel {
                Layout.preferredWidth: VLCStyle.dp(24, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(24, VLCStyle.scale)

                text: entry.iconText
                color: entry.hovered || entry.visualFocus ? theme.accent : root._mutedText
                font.pixelSize: VLCStyle.icon_normal
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Widgets.LabelExt {
                Layout.fillWidth: true

                text: entry.text
                color: root._text
                font.pixelSize: VLCStyle.fontSize_normal
                font.weight: Font.Normal
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }

    component MenuSeparator : Rectangle {
        implicitHeight: VLCStyle.dp(1, VLCStyle.scale)
        color: root._divider

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
        Layout.topMargin: VLCStyle.dp(4, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(4, VLCStyle.scale)
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._surface

        Widgets.RoundedRectangleShadow {
            z: -1
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
            color: Qt.rgba(0, 0, 0, 0.46)
        }
    }

    contentItem: ColumnLayout {
        id: contentColumn

        spacing: 0

        MenuEntry {
            iconText: VLCIcons.add
            text: qsTr("Open File...")
            onTriggered: DialogsProvider.simpleOpenDialog()
        }

        MenuEntry {
            iconText: VLCIcons.dvd_menu
            text: qsTr("Open Disc...")
            onTriggered: DialogsProvider.openDiscDialog()
        }

        MenuEntry {
            iconText: VLCIcons.stream
            text: qsTr("Open Network Stream...")
            onTriggered: DialogsProvider.openNetDialog()
        }

        MenuSeparator { }

        MenuEntry {
            iconText: VLCIcons.effect_filter
            text: qsTr("Customize Player")
            onTriggered: DialogsProvider.showToolbarEditorDialog()
        }

        MenuEntry {
            iconText: VLCIcons.settings
            text: qsTr("Settings")
            onTriggered: settingsDialog.open()
        }

        MenuSeparator { }

        MenuEntry {
            iconText: VLCIcons.info
            text: qsTr("About VLC")
            onTriggered: DialogsProvider.aboutDialog()
        }

        MenuEntry {
            iconText: VLCIcons.close
            text: qsTr("Quit VLC")
            onTriggered: DialogsProvider.quit()
        }
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: VLCStyle.duration_veryShort }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: VLCStyle.duration_veryShort }
    }

    SettingsDialog {
        id: settingsDialog
        parent: T.Overlay.overlay
    }
}
