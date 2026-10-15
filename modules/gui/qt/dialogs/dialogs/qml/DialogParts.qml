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

// Parts of the dialogs of the design (Open Network Stream, New Playlist).
QtObject {

    // Heading in 16 px with a line of help under it
    component Heading : ColumnLayout {
        id: heading

        property string text
        property string help

        Layout.fillWidth: true
        spacing: VLCStyle.dp(5, VLCStyle.scale)

        readonly property ColorContext colorContext: ColorContext {
            id: headingTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        Widgets.LabelExt {
            Layout.fillWidth: true
            text: heading.text
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            color: headingTheme.fg.primary
            elide: Text.ElideRight
        }

        Widgets.LabelExt {
            Layout.fillWidth: true
            visible: heading.help !== ""
            text: heading.help
            font.pixelSize: VLCStyle.fontSize_normal
            color: headingTheme.fg.secondary
            wrapMode: Text.WordWrap
        }
    }

    // Input box in the darkest colour of the theme
    component Box : Rectangle {
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: boxTheme.bg.secondary
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.color: boxBorderTheme.bg.primary

        readonly property ColorContext colorContext: ColorContext {
            id: boxTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Slider
        }
        readonly property ColorContext borderContext: ColorContext {
            id: boxBorderTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }
    }

    component TextField : T.TextField {
        id: field

        Layout.fillWidth: true
        implicitHeight: VLCStyle.dp(37, VLCStyle.scale)
        leftPadding: VLCStyle.dp(14, VLCStyle.scale)
        rightPadding: VLCStyle.dp(14, VLCStyle.scale)
        verticalAlignment: Text.AlignVCenter

        font.pixelSize: VLCStyle.fontSize_normal
        color: fieldTheme.fg.primary
        placeholderTextColor: Qt.rgba(fieldTheme.fg.secondary.r, fieldTheme.fg.secondary.g, fieldTheme.fg.secondary.b, 0.6)
        selectionColor: fieldTheme.accent
        selectByMouse: true

        readonly property ColorContext colorContext: ColorContext {
            id: fieldTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        background: Box {
            border.color: field.activeFocus ? fieldTheme.accent : borderContext.bg.primary
            border.width: VLCStyle.dp(field.activeFocus ? 1 : 2, VLCStyle.scale)
        }
    }

    // Button of the footer. `accent` is the button that confirms.
    component Button : T.Button {
        id: button

        property bool accent: false

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), implicitContentWidth + 2 * VLCStyle.dp(16, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        focusPolicy: Qt.StrongFocus

        readonly property ColorContext colorContext: ColorContext {
            id: buttonTheme
            palette: VLCStyle.palette
            colorSet: button.accent ? ColorContext.ButtonAccent : ColorContext.Window
            enabled: button.enabled
        }

        opacity: enabled ? 1 : 0.5

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: button.accent
                   ? (VLCStyle.palette.isDark ? Qt.rgba(buttonTheme.bg.primary.r * 0.26, buttonTheme.bg.primary.g * 0.26, buttonTheme.bg.primary.b * 0.26, 1)
                                              : Qt.rgba(buttonTheme.bg.primary.r * 0.45 + 0.44, buttonTheme.bg.primary.g * 0.45 + 0.44, buttonTheme.bg.primary.b * 0.45 + 0.44, 1))
                   : Qt.lighter(buttonTheme.bg.primary, button.hovered ? 1.25 : 1.08)
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: buttonTheme.visualFocus
        }

        contentItem: Text {
            text: button.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: VLCStyle.fontSize_normal
            font.weight: Font.DemiBold
            color: button.accent ? buttonTheme.bg.primary : buttonTheme.fg.secondary
        }
    }

    // Cancel on the left, the confirming button on the right
    component Footer : T.Control {
        id: footer

        property string acceptText: qsTr("Save")
        property bool acceptEnabled: true
        signal accepted()
        signal rejected()

        padding: VLCStyle.dp(20, VLCStyle.scale)

        implicitWidth: implicitContentWidth + leftPadding + rightPadding
        implicitHeight: implicitContentHeight + topPadding + bottomPadding

        contentItem: RowLayout {
            Button {
                text: qsTr("Cancel")
                onClicked: footer.rejected()
            }

            Item { Layout.fillWidth: true }

            Button {
                accent: true
                text: footer.acceptText
                enabled: footer.acceptEnabled
                onClicked: footer.accepted()
            }
        }
    }
}
