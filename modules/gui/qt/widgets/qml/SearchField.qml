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
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Util

// A search field that is always visible, with a magnifier icon at the left
// and a button that clears the text.
FocusScope {
    id: root

    property string searchPattern

    property alias textField: textField

    implicitWidth: VLCStyle.dp(326, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

    function expandAndFocus() {
        textField.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    Binding on searchPattern {
        delayed: true
        value: textField.text
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
        enabled: root.enabled
    }

    opacity: enabled ? 1.0 : 0.5

    Rectangle {
        anchors.fill: parent

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: theme.bg.primary

        border.width: textField.activeFocus ? VLCStyle.dp(1, VLCStyle.scale) : 0
        border.color: theme.accent
    }

    Image {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
        anchors.verticalCenter: parent.verticalCenter

        width: VLCStyle.dp(20, VLCStyle.scale)
        height: width

        property real _eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

        sourceSize: Qt.size(width * _eDPR, height * _eDPR)
        source: SVGColorImage.colorize("qrc:///redesign/search.svg")
                             .any({ "#8F8F8F": Qt.rgba(theme.fg.secondary.r, theme.fg.secondary.g, theme.fg.secondary.b, 1.0) })
                             .uri()

        Accessible.ignored: true
    }

    T.TextField {
        id: textField

        anchors {
            left: icon.right
            right: clearButton.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: VLCStyle.dp(8, VLCStyle.scale)
        }

        focus: true
        padding: 0
        verticalAlignment: Text.AlignVCenter

        font.pixelSize: VLCStyle.fontSize_normal
        color: theme.fg.primary
        selectedTextColor: theme.fg.highlight
        selectionColor: theme.bg.highlight
        placeholderText: qsTr("Search")
        placeholderTextColor: Qt.rgba(theme.fg.primary.r, theme.fg.primary.g, theme.fg.primary.b, 0.5)

        selectByMouse: true

        Accessible.name: qsTr("Search")

        Navigation.parentItem: root

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape && text.length > 0) {
                text = ""
                event.accepted = true
            } else {
                Navigation.defaultKeyAction(event)
            }
        }
    }

    MouseArea {
        id: clearButton

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }

        width: visible ? height : 0
        visible: textField.text.length > 0

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            textField.text = ""
            textField.forceActiveFocus()
        }

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Clear")
        Accessible.onPressAction: clicked(null)

        Text {
            anchors.centerIn: parent
            text: VLCIcons.close
            font.family: VLCIcons.fontFamily
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            color: theme.fg.secondary
        }
    }
}
