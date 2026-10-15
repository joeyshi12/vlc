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
import QtQuick.Window

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

// A tool button that shows one of the SVG icons of the design (assets.qrc,
// prefix /redesign). The icon is drawn in the colour of the button.
T.ToolButton {
    id: control

    // Properties

    property bool paintOnly: false

    required property string description

    // Name of the file in pixmaps/redesign, without ".svg"
    required property string iconName

    property real iconSize: VLCStyle.icon_toolbar

    property color color: (control.checked) ? theme.accent : theme.fg.primary

    property color backgroundColor: theme.bg.primary

    property real radius: VLCStyle.button_radius

    // Settings

    padding: 0

    enabled: !paintOnly

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    // Keys

    Keys.priority: Keys.AfterItem

    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    // Accessible

    Accessible.onPressAction: control.clicked()

    Accessible.name: description

    // Tooltip

    T.ToolTip.visible: (hovered || visualFocus)

    T.ToolTip.delay: VLCStyle.delayToolTipAppear

    T.ToolTip.text: description

    // Children

    readonly property ColorContext colorContext : ColorContext {
        id: theme
        colorSet: ColorContext.ToolButton

        enabled: control.paintOnly || control.enabled
        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
    }

    background: Widgets.AnimatedBackground {
        implicitWidth: control.iconSize
        implicitHeight: control.iconSize

        enabled: theme.initialized

        color: control.backgroundColor

        border.color: visualFocus ? theme.visualFocus : theme.border

        radius: control.radius
    }

    contentItem: Item {
        implicitWidth: control.iconSize
        implicitHeight: control.iconSize

        Image {
            anchors.fill: parent

            property real _eDPR: MainCtx.effectiveDevicePixelRatio(Window.window)

            sourceSize: Qt.size(control.iconSize * _eDPR, control.iconSize * _eDPR)
            fillMode: Image.PreserveAspectFit

            // SVG colours can not be transparent, so the transparency of the
            // button colour is applied to the image.
            opacity: control.color.a

            source: SVGColorImage.colorize("qrc:///redesign/" + control.iconName + ".svg")
                                 .any({ "#8F8F8F": Qt.rgba(control.color.r, control.color.g, control.color.b, 1.0) })
                                 .uri()

            Accessible.ignored: true
        }
    }
}
